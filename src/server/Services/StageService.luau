--[[
	StageService
	Builds the world at server start and exposes stage data:
	spawn CFrames, void heights, highest built level. Routes stage-gate touches
	to CheckpointService.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local CheckpointRules = require(Shared.CheckpointRules)

local World = script.Parent.Parent:WaitForChild("World")
local WorldBuilder = require(World.WorldBuilder)

local StageService = {}

local services
local stages = {}
local highestBuilt = 0
local highestCheckpoint = 1
local touchDebounce: { [Player]: { [number]: number } } = {}

function StageService.init(allServices)
	services = allServices

	local root = Instance.new("Folder")
	root.Name = Config.World.FolderName
	local levelsFolder = Instance.new("Folder")
	levelsFolder.Name = "Levels"
	levelsFolder.Parent = root

	local started = os.clock()
	stages, highestBuilt = WorldBuilder.build(levelsFolder)
	root.Parent = workspace

	highestCheckpoint = CheckpointRules.sanitize(highestBuilt, highestBuilt)
	if stages[Config.FINISH_LEVEL] then
		highestCheckpoint = Config.FINISH_LEVEL
	end

	-- Replicated so the client knows the extent of the playable content
	root:SetAttribute("HighestBuilt", highestBuilt)
	for level, stage in stages do
		stage.Model:SetAttribute("SpawnCFrame", stage.Spawn)
	end

	local parts = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	print(("[StageService] built %d levels, %d parts in %.2f s"):format(highestBuilt, parts, os.clock() - started))
end

function StageService.start()
	for level, stage in stages do
		local gate = stage.Gate
		gate.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			local perPlayer = touchDebounce[player]
			if not perPlayer then
				perPlayer = {}
				touchDebounce[player] = perPlayer
			end
			local now = os.clock()
			if perPlayer[level] and now - perPlayer[level] < 0.5 then
				return
			end
			perPlayer[level] = now
			services.CheckpointService.onGateTouched(player, level)
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		touchDebounce[player] = nil
	end)
end

function StageService.getStage(level: number)
	return stages[level]
end

function StageService.getSpawn(level: number): CFrame
	local stage = stages[level] or stages[1]
	return stage.Spawn
end

function StageService.getHighestBuilt(): number
	return highestBuilt
end

-- Highest checkpoint a saved profile may point to in this build of the game.
function StageService.getHighestCheckpoint(): number
	return highestCheckpoint
end

return StageService
