--[[
	DataService
	Player persistence with DataStoreService.

	- UpdateAsync everywhere (never SetAsync) so saves are atomic
	- session lock: a profile open on another server is not loaded until that
	  server releases it (or the lock times out), which prevents rollbacks and
	  duplicated progress when a player hops servers quickly
	- a server that lost its lock never overwrites the profile
	- autosave + save on leave + BindToClose
	- if DataStores are unavailable (Studio without API access, outage) the
	  player plays with a temporary profile and is told progress won't save;
	  the stored profile is never overwritten with blank data
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local DataService = {}

local SCHEMA_VERSION = 1

export type Profile = {
	Version: number,
	Checkpoint: number,
	BestLevel: number,
	Deaths: number,
	PlayTime: number,
	Completions: number,
	BestFullRun: number?, -- seconds, speedrun level 1 -> 200
	BestZoneRuns: { [string]: number }, -- seconds from level 1 to the end of zone N
	FirstJoin: number,
	Settings: { [string]: any },
}

type Session = {
	Data: Profile,
	Persist: boolean,
	LastTick: number,
	Released: boolean,
}

local services
local store: DataStore? = nil
local sessions: { [Player]: Session } = {}
local loadedEvent = Instance.new("BindableEvent")

DataService.Loaded = loadedEvent.Event -- (player, profile)

local function defaultProfile(): Profile
	return {
		Version = SCHEMA_VERSION,
		Checkpoint = 1,
		BestLevel = 1,
		Deaths = 0,
		PlayTime = 0,
		Completions = 0,
		BestFullRun = nil,
		BestZoneRuns = {},
		FirstJoin = os.time(),
		Settings = { Music = true, Sfx = true, HideOthers = false },
	}
end

-- Fills missing fields and upgrades old versions in place.
local function reconcile(data: any): Profile
	local defaults = defaultProfile()
	if typeof(data) ~= "table" then
		return defaults
	end
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	if typeof(data.Settings) ~= "table" then
		data.Settings = defaults.Settings
	end
	for key, value in defaults.Settings do
		if data.Settings[key] == nil then
			data.Settings[key] = value
		end
	end
	data.Version = SCHEMA_VERSION
	return data
end

local function keyFor(player: Player): string
	return Config.Data.KeyPrefix .. player.UserId
end

local function deepCopy(t: any): any
	if typeof(t) ~= "table" then
		return t
	end
	local copy = {}
	for k, v in t do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function loadAsync(player: Player): (Profile?, boolean)
	if not store then
		return defaultProfile(), false
	end
	local key = keyFor(player)
	local retries = Config.Data.LoadRetries
	for attempt = 1, retries do
		local lockedElsewhere = false
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(key, function(old)
				local data = reconcile(old)
				local session = (old and old.Session) or nil
				local lockAge = session and (os.time() - (session.Time or 0)) or math.huge
				if session and session.JobId ~= game.JobId and lockAge < Config.Data.SessionLockTimeout and attempt < retries then
					lockedElsewhere = true
					return nil -- cancel the write, try again shortly
				end
				data.Session = { JobId = game.JobId, Time = os.time() }
				return data
			end)
		end)
		if ok and result then
			result.Session = nil
			return reconcile(result), true
		end
		if not ok then
			warn(("[DataService] load attempt %d for %s failed: %s"):format(attempt, player.Name, tostring(result)))
		end
		if not player.Parent then
			return nil, false
		end
		task.wait(if lockedElsewhere then 5 else 2 ^ attempt)
	end
	return nil, false
end

local function saveAsync(player: Player, release: boolean): boolean
	local session = sessions[player]
	if not session or not session.Persist or not store then
		return false
	end
	local now = os.clock()
	session.Data.PlayTime += now - session.LastTick
	session.LastTick = now

	local snapshot = deepCopy(session.Data)
	local key = keyFor(player)
	for attempt = 1, Config.Data.SaveRetries do
		local lostLock = false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key, function(old)
				local lock = old and old.Session
				if lock and lock.JobId ~= game.JobId then
					lostLock = true
					return nil -- another server owns this profile now
				end
				snapshot.Session = if release then nil else { JobId = game.JobId, Time = os.time() }
				return snapshot
			end)
		end)
		if ok then
			if lostLock then
				warn(("[DataService] %s: session lock lost, save skipped"):format(player.Name))
				session.Persist = false
				return false
			end
			return true
		end
		warn(("[DataService] save attempt %d for %s failed: %s"):format(attempt, player.Name, tostring(err)))
		task.wait(attempt)
	end
	return false
end

function DataService.init(allServices)
	services = allServices
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable, progress will not be saved: " .. tostring(result))
	end
end

function DataService.start()
	local function onPlayerAdded(player: Player)
		local data, persist = loadAsync(player)
		if not player.Parent then
			return
		end
		if not data then
			data = defaultProfile()
			persist = false
		end
		sessions[player] = {
			Data = data,
			Persist = persist,
			LastTick = os.clock(),
			Released = false,
		}
		player:SetAttribute("DataPersistent", persist)
		for key, value in data.Settings do
			player:SetAttribute("Setting_" .. key, value)
		end
		loadedEvent:Fire(player, data)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Only whitelisted keys with the default's type can be written by clients
	local defaults = defaultProfile().Settings
	Net.event("SaveSetting").OnServerEvent:Connect(function(player, key, value)
		local data = DataService.get(player)
		if not data or typeof(key) ~= "string" or defaults[key] == nil or typeof(value) ~= typeof(defaults[key]) then
			return
		end
		data.Settings[key] = value
		player:SetAttribute("Setting_" .. key, value)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session and not session.Released then
			session.Released = true
			services.LeaderboardService.updateStats(player, true)
			saveAsync(player, true)
		end
		sessions[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Config.Data.AutosaveInterval)
			for player in sessions do
				task.spawn(saveAsync, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, session in sessions do
			if not session.Released then
				session.Released = true
				pending += 1
				task.spawn(function()
					saveAsync(player, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- Live profile table (mutate it directly; it is saved periodically).
function DataService.get(player: Player): Profile?
	local session = sessions[player]
	return session and session.Data
end

function DataService.isLoaded(player: Player): boolean
	return sessions[player] ~= nil
end

-- Total play time including the current session, in seconds.
function DataService.getPlayTime(player: Player): number
	local session = sessions[player]
	if not session then
		return 0
	end
	return session.Data.PlayTime + (os.clock() - session.LastTick)
end

return DataService
