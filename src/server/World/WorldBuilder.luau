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

return WorldBuilder
