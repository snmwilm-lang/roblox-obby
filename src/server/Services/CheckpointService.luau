--[[
	CheckpointService
	Authoritative progression. Applies CheckpointRules to stage-gate touches.

	Player attributes it owns (replicated, read by UI and overhead tags):
	  Checkpoint     active checkpoint (speedrun run checkpoint while speedrunning)
	  CurrentLevel   level the player is standing in (for "LEVEL x / 200")
	  BestLevel      highest level reached (200 only once the game is beaten)
	  Completions    number of times level 200 was completed
	  RespawnCFrame  where the client puts the character after a death
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local CheckpointRules = require(Shared.CheckpointRules)
local Net = require(Shared.Net)

local CheckpointService = {}

local services
local notify: RemoteEvent

function CheckpointService.init(allServices)
	services = allServices
end

-- Checkpoint currently used for respawning (speedrun run or casual progress)
function CheckpointService.getActiveCheckpoint(player: Player): number
	local run = services.SpeedrunService.getRun(player)
	if run then
		return run.Checkpoint
	end
	local data = services.DataService.get(player)
	return data and data.Checkpoint or 1
end

function CheckpointService.refresh(player: Player)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	local cp = CheckpointService.getActiveCheckpoint(player)
	player:SetAttribute("Checkpoint", cp)
	player:SetAttribute("BestLevel", CheckpointRules.displayLevel(data.BestLevel))
	player:SetAttribute("Completions", data.Completions)
	player:SetAttribute("Deaths", data.Deaths)
	player:SetAttribute("RespawnCFrame", services.StageService.getSpawn(cp))
	if player:GetAttribute("CurrentLevel") == nil then
		player:SetAttribute("CurrentLevel", CheckpointRules.displayLevel(cp))
	end
	services.LeaderboardService.updateStats(player)
end

local function setCurrentLevel(player: Player, level: number)
	player:SetAttribute("CurrentLevel", CheckpointRules.displayLevel(level))
end

local function claim(player: Player, level: number, data)
	local run = services.SpeedrunService.getRun(player)

	if run then
		run.Checkpoint = level
	end
	-- Casual progress also advances when a speedrun goes further than it.
	if CheckpointRules.canClaim(data.Checkpoint, level) then
		data.Checkpoint = level
	end
	data.BestLevel = math.max(data.BestLevel, level)

	setCurrentLevel(player, level)

	for _, completed in CheckpointRules.levelsCompletedByClaiming(level) do
		notify:FireClient(player, { Kind = "LevelComplete", Level = completed })
	end

	local previous = level - 1
	if CheckpointRules.isFinalStage(previous) then
		local zone = CheckpointRules.zoneOf(previous)
		notify:FireClient(player, { Kind = "ZoneComplete", Zone = zone, Level = previous })
		services.SpeedrunService.onZoneComplete(player, zone)
	end

	if level == Config.FINISH_LEVEL then
		data.Completions += 1
		notify:FireClient(player, { Kind = "Victory", Completions = data.Completions })
		services.SpeedrunService.onFinish(player)
	end

	CheckpointService.refresh(player)
end

function CheckpointService.onGateTouched(player: Player, level: number)
	local data = services.DataService.get(player)
	if not data then
		return
	end
	local cp = CheckpointService.getActiveCheckpoint(player)

	if CheckpointRules.canClaim(cp, level) then
		claim(player, level, data)
	elseif CheckpointRules.isFinalStage(level) and cp == level - 1 then
		-- Entering a final stage: UI shows it, respawn stays on the pre-final.
		if player:GetAttribute("CurrentLevel") ~= level then
			setCurrentLevel(player, level)
			notify:FireClient(player, { Kind = "FinalStage", Level = level })
		end
	elseif level <= cp then
		-- Walking back through already cleared levels
		setCurrentLevel(player, level)
	end
	-- Anything else is an attempt to skip ahead: ignored.
end

-- Victory room: start again from level 1 (best level and completions are kept).
function CheckpointService.restart(player: Player)
	local data = services.DataService.get(player)
	if not data or data.Checkpoint ~= Config.FINISH_LEVEL then
		return
	end
	data.Checkpoint = 1
	player:SetAttribute("CurrentLevel", 1)
	CheckpointService.refresh(player)
	services.RespawnService.sendToCheckpoint(player)
end

function CheckpointService.start()
	notify = Net.event("Notify")

	services.DataService.Loaded:Connect(function(player: Player, data)
		data.Checkpoint = CheckpointRules.sanitize(data.Checkpoint, services.StageService.getHighestCheckpoint())
		data.BestLevel = math.max(data.BestLevel, data.Checkpoint)
		player:SetAttribute("CurrentLevel", CheckpointRules.displayLevel(data.Checkpoint))
		CheckpointService.refresh(player)
		player:SetAttribute("DataLoaded", true)
	end)

	Net.event("RestartRequest").OnServerEvent:Connect(function(player)
		CheckpointService.restart(player)
	end)
end

return CheckpointService
