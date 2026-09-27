--[[
	Chaser component (tag "Chaser", also "Hazard"): lava / wall advancing
	behind the LOCAL player. Starts Delay seconds after the player enters the
	chaser's level (or respawns in it), moves at Speed along Travel. Each
	player has his own chaser; it resets on respawn.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)

local player = Players.LocalPlayer

local Chaser = {}
Chaser.Tag = "Chaser"

function Chaser.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local config = ObstacleTypes.read(instance, "Chaser")
	return {
		Part = instance,
		Base = instance.CFrame,
		Config = config,
		Length = config.Travel.Magnitude,
		Direction = if config.Travel.Magnitude > 0 then config.Travel.Unit else Vector3.zero,
		Start = nil,
		Progress = 0,
	}
end

function Chaser.update(state, _t: number, _dt: number, runtime)
	local c = state.Config
	if player:GetAttribute("CurrentLevel") ~= c.Level then
		state.Start = nil
		if state.Progress ~= 0 then
			state.Progress = 0
			runtime.move(state.Part, state.Base)
		end
		return
	end
	if not state.Start then
		if c.StartRadius > 0 then
			local _, _, root = runtime.controllers().CharacterState.get()
			if not root or (root.Position - state.Base.Position).Magnitude > c.StartRadius then
				return
			end
		end
		state.Start = os.clock() + c.Delay
	end
	local progress = math.clamp((os.clock() - state.Start) * c.Speed, 0, state.Length)
	if progress ~= state.Progress then
		state.Progress = progress
		runtime.move(state.Part, state.Base + state.Direction * progress)
	end
end

function Chaser.reset(state)
	state.Start = nil
end

return Chaser
