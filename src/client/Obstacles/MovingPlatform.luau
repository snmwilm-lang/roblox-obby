--[[
	MovingPlatform component (tag "MovingPlatform", also used for moving hazards)
	Attributes: Travel, Period, Pause, Phase, Easing, LoopType  (see Shared/ObstacleTypes)
	Works on a Part or a Model (every part of the model follows the pivot).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Timing = require(Shared.Timing)

local MovingPlatform = {}
MovingPlatform.Tag = "MovingPlatform"
MovingPlatform.Carry = true

local function collectParts(instance: Instance, base: CFrame, record, runtime)
	local parts = {}
	if instance:IsA("BasePart") then
		table.insert(parts, { Part = instance, Offset = CFrame.identity })
	else
		for _, d in instance:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, { Part = d, Offset = base:ToObjectSpace(d.CFrame) })
				runtime.claimPart(d, record)
			end
		end
	end
	return parts
end

function MovingPlatform.register(instance: Instance, record, runtime)
	local base = if instance:IsA("Model") then instance:GetPivot() else (instance :: BasePart).CFrame
	local config = ObstacleTypes.read(instance, "MovingPlatform")
	return {
		Config = config,
		Base = base,
		Parts = collectParts(instance, base, record, runtime),
		Hazard = instance:HasTag("Hazard"),
	}
end

function MovingPlatform.position(state, t: number): CFrame
	local c = state.Config
	if c.LoopType == "Circle" then
		local a = Timing.loop(t, c.Period, c.Phase) * math.pi * 2
		local travel: Vector3 = c.Travel
		local radius = travel.Magnitude / 2
		if radius < 1e-3 then
			return state.Base
		end
		local u = travel.Unit
		local v = u:Cross(Vector3.yAxis)
		if v.Magnitude < 1e-3 then
			v = Vector3.xAxis
		end
		v = v.Unit
		local center = state.Base.Position + travel / 2
		local p = center - u * radius * math.cos(a) + v * radius * math.sin(a)
		return state.Base.Rotation + p
	end
	local alpha = Timing.pingPong(t, c.Period, c.Pause, c.Phase, c.Easing)
	return state.Base + c.Travel * alpha
end

function MovingPlatform.update(state, t: number, _dt: number, runtime)
	local cf = MovingPlatform.position(state, t)
	for _, entry in state.Parts do
		runtime.move(entry.Part, cf * entry.Offset, not state.Hazard)
	end
end

return MovingPlatform
