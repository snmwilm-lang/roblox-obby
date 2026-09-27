--[[
	Conveyor component (tag "Conveyor")
	Uses the engine's surface velocity (AssemblyLinearVelocity on an anchored
	part): reliable, network-free, identical for every player.
	Visual: scrolling chevrons so the direction and speed are readable.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)
local Palette = require(Shared.Palette)

local Conveyor = {}
Conveyor.Tag = "Conveyor"

function Conveyor.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	local config = ObstacleTypes.read(instance, "Conveyor")
	local direction: Vector3 = config.Direction.Magnitude > 0 and config.Direction.Unit or Vector3.zAxis
	instance.AssemblyLinearVelocity = direction * config.Speed

	-- chevrons on the top face, rotated to point along the belt
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.ClipsDescendants = true
	local localDir = instance.CFrame:VectorToObjectSpace(direction)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(3, 3)
	label.Position = UDim2.fromScale(-1, -1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextTransparency = 0.25
	label.TextColor3 = Palette.ConveyorArrow
	label.Text = string.rep("›  ", 12)
	-- Top face: surface X = part X, surface Y = part Z
	label.Rotation = math.deg(math.atan2(localDir.Z, localDir.X))
	label.Parent = gui
	gui.Parent = instance

	return { Part = instance, Label = label, Speed = config.Speed, Gui = gui }
end

function Conveyor.update(state, t: number)
	local shift = (t * state.Speed * 0.02) % (1 / 12)
	state.Label.Position = UDim2.fromScale(-1 + shift, -1)
end

function Conveyor.unregister(state)
	state.Gui:Destroy()
end

return Conveyor
