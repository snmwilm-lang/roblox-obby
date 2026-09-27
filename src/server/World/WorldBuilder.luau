--[[
	WorldBuilder
	Chains every defined level: each level starts where the previous one exits.
	Pure world construction (no player logic) so tests/ can run it headlessly.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local CheckpointRules = require(Shared.CheckpointRules)

local LevelBuilder = require(script.Parent.LevelBuilder)
local Themes = require(script.Parent.Themes)
local LevelRegistry = require(script.Parent.LevelRegistry)

local WorldBuilder = {}

export type Stage = {
	Level: number,
	Model: Model,
	Gate: BasePart,
	Spawn: CFrame,
	Exit: CFrame?,
	Route: { any },
	VoidY: number,
}

-- Returns stages indexed by level (plus FINISH_LEVEL when level 200 exists)
-- and the highest level whose start pad exists.
function WorldBuilder.build(parent: Instance): ({ [number]: Stage }, number)
	local stages = {}
	local highest = 0
	local cursor = Config.World.Origin

	for level = 1, Config.TOTAL_LEVELS do
		local build = LevelRegistry[level]
		if not build then
			break
		end
		local zone = Zones[CheckpointRules.zoneOf(level)]
		local builder = LevelBuilder.new({
			level = level,
			origin = cursor,
			parent = parent,
			zone = zone,
			theme = Themes.get(zone.Id),
		})
		build(builder)
		local stage = builder:Finish()
		stages[level] = stage
		highest = level

		if stage.FinishGate then
			stages[Config.FINISH_LEVEL] = {
				Level = Config.FINISH_LEVEL,
				Model = stage.Model,
				Gate = stage.FinishGate,
				Spawn = stage.FinishSpawn,
				Route = {},
				VoidY = stage.VoidY,
			}
		end

		if not stage.Exit then
			break
		end
		cursor = stage.Exit
	end

	return stages, highest
end

--[[
	Re-indexes a world that was already built (baked into the place file by
	tools/bake.luau, possibly edited in Studio). Only gameplay data is read:
	spawn, gate and void height of each level.
]]
function WorldBuilder.index(levelsFolder: Instance): ({ [number]: Stage }, number)
	local stages = {}
	local highest = 0
	for _, model in levelsFolder:GetChildren() do
		local level = model:GetAttribute("Level")
		local spawn = model:GetAttribute("SpawnCFrame")
		local gate = model:FindFirstChild("StageGate")
		if typeof(level) == "number" and typeof(spawn) == "CFrame" and gate then
			stages[level] = {
				Level = level,
				Model = model,
				Gate = gate,
				Spawn = spawn,
				Route = {},
				VoidY = model:GetAttribute("VoidY") or (spawn.Position.Y - 60),
			}
			highest = math.max(highest, level)
			local finishGate = model:FindFirstChild("FinishGate")
			local finishSpawn = model:GetAttribute("FinishSpawn")
			if finishGate and typeof(finishSpawn) == "CFrame" then
				stages[Config.FINISH_LEVEL] = {
					Level = Config.FINISH_LEVEL,
					Model = model,
					Gate = finishGate,
					Spawn = finishSpawn,
					Route = {},
					VoidY = model:GetAttribute("VoidY"),
				}
			end
		end
	end
	-- only a contiguous run of levels from 1 is playable
	local contiguous = 0
	while stages[contiguous + 1] do
		contiguous += 1
	end
	return stages, contiguous
end

return WorldBuilder
