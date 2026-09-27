--[[
	Client entry point (StarterPlayerScripts, runs once per session).
	Controllers expose init(controllers) then start(); they reach each other
	through the shared `controllers` table.
]]

local Controllers = script:WaitForChild("Controllers")

local ORDER = {
	"CharacterState",
	"AudioController",
	"UIController",
	"SettingsController",
	"ZoneController",
	"GravityController",
	"ObstacleRuntime",
	"HazardController",
	"RespawnController",
	"CheckpointVisuals",
}

local controllers = {}
for _, name in ORDER do
	controllers[name] = require(Controllers:WaitForChild(name))
end
for _, name in ORDER do
	controllers[name].init(controllers)
end
for _, name in ORDER do
	controllers[name].start()
end
