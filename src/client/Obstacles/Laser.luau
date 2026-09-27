--[[
	Laser component (tag "Laser", the part is also tagged "Hazard")
	OnTime lethal / OffTime harmless, with a WarnTime charge-up at the end of
	the off window: the beam reappears thin and flickering with a rising hum,
	so a player who watches one cycle can always predict the next.
	Combine with "Rotator" on a parent model for laser sweeps.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Timing = require(Shared.Timing)

local Laser = {}
Laser.Tag = "Laser"

local controllers

function Laser.init(allControllers)
	controllers = allControllers
end

function Laser.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	return {
		Part = instance,
		Config = ObstacleTypes.read(instance, "Laser"),
		Transparency = instance.Transparency,
		State = nil,
	}
end

local function setState(state, newState: string)
	if state.State == newState then
		return
	end
	state.State = newState
	local part = state.Part
	controllers.HazardController.setLethal(part, newState == "On")
	if newState == "On" then
		part.Transparency = state.Transparency
	elseif newState == "Warn" then
		controllers.AudioController.playAt("LaserCharge", part.Position)
	else
		part.Transparency = 0.95
	end
end

function Laser.update(state, t: number)
	local c = state.Config
	local on, left = Timing.onOff(t, c.OnTime, c.OffTime, c.Phase)
	if on then
		setState(state, "On")
	elseif left <= c.WarnTime then
		setState(state, "Warn")
		state.Part.Transparency = if math.floor(left * 12) % 2 == 0 then 0.55 else 0.8
	else
		setState(state, "Off")
	end
end

function Laser.unregister(state)
	controllers.HazardController.setLethal(state.Part, true)
end

return Laser
