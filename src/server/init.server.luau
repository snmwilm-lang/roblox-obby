--[[
	Server entry point.
	Every service exposes init(services) (wire dependencies, no yielding) and
	start() (connect events, spawn loops). Services reference each other through
	the shared `services` table, which avoids circular requires.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local ServicesFolder = script:WaitForChild("Services")

local ORDER = {
	"StageService", -- builds the world first: everything else needs spawns
	"DataService",
	"LeaderboardService",
	"OverheadService",
	"SpeedrunService",
	"CheckpointService",
	"RespawnService",
}

Net.init()

local services = {}
for _, name in ORDER do
	services[name] = require(ServicesFolder:WaitForChild(name))
end
for _, name in ORDER do
	services[name].init(services)
end
-- Checkpoint/Respawn listen to DataService.Loaded, so they start before it loads anyone.
local START_ORDER = {
	"StageService",
	"LeaderboardService",
	"OverheadService",
	"SpeedrunService",
	"CheckpointService",
	"RespawnService",
	"DataService",
}
for _, name in START_ORDER do
	services[name].start()
end

print("[Server] ready")
