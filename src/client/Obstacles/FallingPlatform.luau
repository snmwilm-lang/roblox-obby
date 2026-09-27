--[[
	FallingPlatform component (tag "FallingPlatform")
	LOCAL to each player: landing on it only drops YOUR copy, so nobody can
	grief others, and it is always back after RespawnDelay (or when you respawn).
	Sequence: touch -> crack sound + colour change + shake (ShakeDuration)
	          -> falls (FallDelay reached) -> hidden -> fades back in.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Palette = require(Shared.Palette)

local FallingPlatform = {}
FallingPlatform.Tag = "FallingPlatform"

local FALL_TIME = 0.8
local FALL_DISTANCE = 40

local controllers

function FallingPlatform.init(allControllers)
	controllers = allControllers
end

function FallingPlatform.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	return {
		Part = instance,
		Config = ObstacleTypes.read(instance, "FallingPlatform"),
		Base = instance.CFrame,
		Color = instance.Color,
		Transparency = instance.Transparency,
		Phase = "Idle", -- Idle | Triggered | Falling | Hidden
		Clock = 0,
		Dirty = false,
	}
end

local function restore(state)
	local part = state.Part
	part.Color = state.Color
	part.Transparency = state.Transparency
	part.CanCollide = true
	part.CanQuery = true
	state.Phase = "Idle"
	state.Clock = 0
	state.Dirty = true
end

function FallingPlatform.onGround(state)
	if state.Phase ~= "Idle" then
		return
	end
	state.Phase = "Triggered"
	state.Clock = 0
	state.Part.Color = Palette.FallingWarning
	controllers.AudioController.playAt("Crack", state.Part.Position)
end

function FallingPlatform.update(state, _t: number, dt: number, runtime)
	local c = state.Config
	local part = state.Part
	if state.Phase == "Idle" then
		if state.Dirty then
			state.Dirty = false
			runtime.move(part, state.Base)
		end
		return
	end
	state.Clock += dt
	if state.Phase == "Triggered" then
		local shakeStart = c.FallDelay - c.ShakeDuration
		if state.Clock >= c.FallDelay then
			state.Phase = "Falling"
			state.Clock = 0
			part.CanCollide = false
			part.CanQuery = false
		elseif state.Clock >= shakeStart then
			local amount = 0.12
			local offset = Vector3.new((math.random() - 0.5) * amount, 0, (math.random() - 0.5) * amount)
			runtime.move(part, state.Base + offset)
		end
	elseif state.Phase == "Falling" then
		local a = math.clamp(state.Clock / FALL_TIME, 0, 1)
		runtime.move(part, state.Base - Vector3.new(0, FALL_DISTANCE * a * a, 0))
		part.Transparency = state.Transparency + (1 - state.Transparency) * a
		if a >= 1 then
			state.Phase = "Hidden"
			state.Clock = 0
		end
	elseif state.Phase == "Hidden" then
		if state.Clock >= c.RespawnDelay then
			restore(state)
		end
	end
end

function FallingPlatform.reset(state)
	if state.Phase ~= "Idle" then
		restore(state)
	end
end

return FallingPlatform
