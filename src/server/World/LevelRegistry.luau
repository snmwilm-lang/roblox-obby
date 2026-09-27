--[[
	LevelRegistry
	Merges every zone file into one { [level] = buildFunction } table.
	Adding a zone = adding its module to ZONE_MODULES.
]]

local Levels = script.Parent:WaitForChild("Levels")

local ZONE_MODULES = {
	"Zone1",
	"Zone2",
	"Zone3",
	"Zone4",
	"Zone5",
	"Zone6",
}

local registry: { [number]: (any) -> () } = {}

for _, moduleName in ZONE_MODULES do
	local zoneLevels = require(Levels:WaitForChild(moduleName))
	for level, build in zoneLevels do
		assert(registry[level] == nil, ("Level %d defined twice"):format(level))
		registry[level] = build
	end
end

return registry
