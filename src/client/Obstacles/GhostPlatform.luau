--[[
	GhostPlatform component (tag "GhostPlatform")
	Solid for VisibleDuration, intangible for InvisibleDuration, deterministic
	from server time (every player sees the same rhythm).
	Readability:
	  - blinks during the last WarnTime seconds before vanishing (+ tick sound)
	  - while intangible a faint outline stays visible: you always know where
	    it will come back
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Timing = require(Shared.Timing)

local GhostPlatform = {}
GhostPlatform.Tag = "GhostPlatform"

local OFF_TRANSPARENCY = 0.88

local controllers

function GhostPlatform.init(allControllers)
	controllers = allControllers
end

function GhostPlatform.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local config = ObstacleTypes.read(instance, "GhostPlatform")
	return {
		Part = instance,
		Config = config,
		BaseTransparency = instance.Transparency,
		Solid = nil,
		Warned = false,
	}
end

local function setSolid(state, solid: boolean)
	if state.Solid == solid then
		return
	end
	state.Solid = solid
	local part = state.Part
	part.CanCollide = solid
	part.CanQuery = solid
	if not solid then
		part.Transparency = OFF_TRANSPARENCY
	end
end

function GhostPlatform.update(state, t: number)
	local c = state.Config
	local on, left = Timing.onOff(t, c.VisibleDuration, c.InvisibleDuration, c.PhaseOffset)
	setSolid(state, on)
	if on then
		if left < c.WarnTime then
			-- 4 blinks per second, getting clearer as the end approaches
			local blink = math.floor(left * 8) % 2 == 0
			state.Part.Transparency = if blink then 0.7 else state.BaseTransparency
			if not state.Warned then
				state.Warned = true
				controllers.AudioController.playAt("GhostWarn", state.Part.Position)
			end
		else
			state.Part.Transparency = state.BaseTransparency
			state.Warned = false
		end
	end
end

return GhostPlatform
