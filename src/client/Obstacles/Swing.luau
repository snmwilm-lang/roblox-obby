--[[
	Swing component (tag "Swing"): pendulums, seesaws, drawbridges.
	angle(t) = Offset + Amplitude * sin(2π · loop(t, Period, Phase)) around the
	pivot's Axis. Deterministic from server time; the pivot is read from the
	"Pivot" attribute (saved in the place file).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Timing = require(Shared.Timing)

local Swing = {}
Swing.Tag = "Swing"
Swing.Carry = true

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

function Swing.register(instance: Instance, record, runtime)
	local pivot = instance:GetAttribute("Pivot")
	local base = if typeof(pivot) == "CFrame" then pivot elseif instance:IsA("Model") then instance:GetPivot() else (instance :: BasePart).CFrame
	local parts = {}
	local function add(part: BasePart)
		table.insert(parts, { Part = part, Offset = base:ToObjectSpace(part.CFrame), Carry = not part:HasTag("Hazard") })
		runtime.claimPart(part, record)
	end
	if instance:IsA("BasePart") then
		add(instance)
	else
		for _, d in instance:GetDescendants() do
			if d:IsA("BasePart") then
				add(d)
			end
		end
	end
	local config = ObstacleTypes.read(instance, "Swing")
	return {
		Base = base,
		Parts = parts,
		Rotate = AXES[config.Axis] or AXES.Z,
		Config = config,
	}
end

function Swing.update(state, t: number, _dt: number, runtime)
	local c = state.Config
	local wave = math.sin(Timing.loop(t, c.Period, c.Phase) * math.pi * 2)
	local cf = state.Base * state.Rotate(math.rad(c.Offset + c.Amplitude * wave))
	for _, entry in state.Parts do
		runtime.move(entry.Part, cf * entry.Offset, entry.Carry)
	end
end

return Swing
