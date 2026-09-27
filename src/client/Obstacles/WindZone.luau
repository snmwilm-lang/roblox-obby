--[[
	WindZone component (tag "WindZone"): pushes the LOCAL character while it is
	inside the volume. Constant wind, or gusts (OnTime/OffTime) announced by
	faster particles and a whistle during WarnTime.
	The push moves the character directly (like the platform carry): exact,
	identical on every device, independent of physics settings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Timing = require(Shared.Timing)

local WindZone = {}
WindZone.Tag = "WindZone"

local controllers

function WindZone.init(allControllers)
	controllers = allControllers
end

local function inside(part: BasePart, position: Vector3): boolean
	local p = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

function WindZone.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local config = ObstacleTypes.read(instance, "WindZone")
	local velocity: Vector3 = config.Velocity
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
	emitter.LightEmission = 0.3
	emitter.Transparency = NumberSequence.new(0.4, 1)
	emitter.Size = NumberSequence.new(0.25, 0.05)
	emitter.Lifetime = NumberRange.new(1, 1.5)
	emitter.Rate = 25
	emitter.Speed = NumberRange.new(0)
	emitter.Acceleration = velocity * 2
	emitter.Parent = instance
	return {
		Part = instance,
		Config = config,
		Emitter = emitter,
		Velocity = Vector3.new(velocity.X, 0, velocity.Z),
		Warned = false,
	}
end

function WindZone.update(state, t: number, dt: number)
	local c = state.Config
	local on = true
	local warning = false
	if c.OnTime > 0 and c.OffTime > 0 then
		local isOn, left = Timing.onOff(t, c.OnTime, c.OffTime, c.Phase)
		on = isOn
		warning = not isOn and left <= c.WarnTime
	end
	state.Emitter.Rate = if on then 40 elseif warning then 25 else 4
	if warning and not state.Warned then
		state.Warned = true
		controllers.AudioController.playAt("GravitySwitch", state.Part.Position)
	elseif not warning then
		state.Warned = false
	end
	if not on then
		return
	end
	local _, _, root = controllers.CharacterState.get()
	if root and not root.Anchored and inside(state.Part, root.Position) then
		root.CFrame += state.Velocity * dt
	end
end

return WindZone
