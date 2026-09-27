--[[
	SpeedrunService
	Optional timed mode, parallel to casual progress. Never changes the level
	design: a run simply restarts from level 1 with its own checkpoint and a
	server-side clock.

	  - 3 s countdown, character held in place (fair start for everyone)
	  - checkpoints still work inside a run (the clock keeps running)
	  - splits at the end of every zone (BestZoneRuns), full run at level 200
	  - casual progress is kept aside and restored when the run is cancelled
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)

local SpeedrunService = {}

local COUNTDOWN = 3
local TOGGLE_COOLDOWN = 2

type Run = { Checkpoint: number, Start: number }

local services
local notify: RemoteEvent
local runs: { [Player]: Run } = {}
local lastToggle: { [Player]: number } = {}

function SpeedrunService.init(allServices)
	services = allServices
end

function SpeedrunService.getRun(player: Player): Run?
	return runs[player]
end

local function elapsed(run: Run): number
	return math.max(0, workspace:GetServerTimeNow() - run.Start)
end

local function endRun(player: Player)
	runs[player] = nil
	player:SetAttribute("SpeedrunActive", false)
	player:SetAttribute("SpeedrunStart", nil)
	player:SetAttribute("SpeedrunHoldUntil", nil)
end

function SpeedrunService.setEnabled(player: Player, enabled: boolean)
	local data = services.DataService.get(player)
	if not data or enabled == (runs[player] ~= nil) then
		return
	end
	local now = os.clock()
	if lastToggle[player] and now - lastToggle[player] < TOGGLE_COOLDOWN then
		return
	end
	lastToggle[player] = now

	if enabled then
		local start = workspace:GetServerTimeNow() + COUNTDOWN
		runs[player] = { Checkpoint = 1, Start = start }
		player:SetAttribute("SpeedrunActive", true)
		player:SetAttribute("SpeedrunStart", start)
		player:SetAttribute("SpeedrunHoldUntil", start)
		player:SetAttribute("CurrentLevel", 1)
		services.CheckpointService.refresh(player)
		services.RespawnService.sendToCheckpoint(player, COUNTDOWN)
	else
		endRun(player)
		player:SetAttribute("CurrentLevel", math.min(data.Checkpoint, 200))
		services.CheckpointService.refresh(player)
		services.RespawnService.sendToCheckpoint(player)
	end
end

function SpeedrunService.onZoneComplete(player: Player, zone: number)
	local run = runs[player]
	local data = services.DataService.get(player)
	if not run or not data then
		return
	end
	local time = elapsed(run)
	local key = tostring(zone)
	local best = data.BestZoneRuns[key]
	local record = best == nil or time < best
	if record then
		data.BestZoneRuns[key] = time
	end
	notify:FireClient(player, { Kind = "Split", Zone = zone, Time = time, Best = data.BestZoneRuns[key], Record = record })
end

function SpeedrunService.onFinish(player: Player)
	local run = runs[player]
	local data = services.DataService.get(player)
	if not run or not data then
		return
	end
	local time = elapsed(run)
	local record = data.BestFullRun == nil or time < data.BestFullRun
	if record then
		data.BestFullRun = time
	end
	notify:FireClient(player, { Kind = "RunFinished", Time = time, Best = data.BestFullRun, Record = record })
	endRun(player)
	services.LeaderboardService.updateStats(player, true)
end

function SpeedrunService.start()
	notify = Net.event("Notify")

	Net.event("SpeedrunRequest").OnServerEvent:Connect(function(player, enabled)
		if typeof(enabled) ~= "boolean" then
			return
		end
		SpeedrunService.setEnabled(player, enabled)
	end)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("SpeedrunActive", false)
	end)
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
		lastToggle[player] = nil
	end)
end

return SpeedrunService
