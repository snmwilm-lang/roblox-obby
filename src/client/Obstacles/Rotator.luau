--[[
	Rotator component (tag "Rotator"): spinners, gears, laser sweeps, rotating beams.
	Attributes: Axis ("X" | "Y" | "Z", pivot-local), Speed (deg/s), Phase (deg)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)

local Rotator = {}
Rotator.Tag = "Rotator"
Rotator.Carry = true

local AXES = {
	X = function(a)
		return CFrame.Angles(a, 0, 0)
	end,
	Y = function(a)
		return CFrame.Angles(0, a, 0)
	end,
	Z = function(a)
		return CFrame.Angles(0, 0, a)
	end,
}

function Rotator.register(instance: Instance, record, runtime)
	local pivot = instance:GetAttribute("Pivot")
	local base = if typeof(pivot) == "CFrame" then pivot elseif instance:IsA("Model") then instance:GetPivot() else (instance :: BasePart).CFrame
	local parts = {}
	if instance:IsA("BasePart") then
		table.insert(parts, { Part = instance, Offset = CFrame.identity, Carry = not instance:HasTag("Hazard") })
	else
		for _, d in instance:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, { Part = d, Offset = base:ToObjectSpace(d.CFrame), Carry = not d:HasTag("Hazard") })
				runtime.claimPart(d, record)
			end
		end
	end
	local config = ObstacleTypes.read(instance, "Rotator")
	return {
		Base = base,
		Parts = parts,
		Rotate = AXES[config.Axis] or AXES.Y,
		Speed = config.Speed,
		Phase = config.Phase,
	}
end

function Rotator.update(state, t: number, _dt: number, runtime)
	-- modulo before converting keeps precision with epoch-sized server times
	local degrees = (state.Phase + (state.Speed * t) % 360) % 360
	local cf = state.Base * state.Rotate(math.rad(degrees))
	for _, entry in state.Parts do
		runtime.move(entry.Part, cf * entry.Offset, entry.Carry)
	end
end

return Rotator
