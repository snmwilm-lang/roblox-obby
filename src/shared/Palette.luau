--[[
	Palette
	Semantic visual language. These colours/materials are RESERVED: zone themes
	never use them for safe ground or decoration, so a player can always read
	a surface at a glance, in any zone:

	  red neon ............ kills you
	  amber/yellow ........ moves
	  cyan, translucent ... ghost platform (phases in/out)
	  cracked orange ...... falls when touched
	  lime neon ........... jump pad
	  mint / white glow ... checkpoint
	  gold ................ final stage / zone gate
]]

local rgb = Color3.fromRGB

local Palette = {
	Hazard = { Color = rgb(255, 40, 40), Material = Enum.Material.Neon },
	HazardWarning = rgb(255, 150, 60),
	Moving = { Color = rgb(248, 196, 44), Material = Enum.Material.SmoothPlastic },
	MovingTrim = rgb(40, 34, 20),
	Ghost = { Color = rgb(90, 230, 255), Material = Enum.Material.Glass, Transparency = 0.25 },
	Falling = { Color = rgb(214, 120, 54), Material = Enum.Material.Slate },
	FallingWarning = rgb(255, 80, 40),
	JumpPad = { Color = rgb(140, 255, 60), Material = Enum.Material.Neon },
	Conveyor = { Color = rgb(52, 56, 64), Material = Enum.Material.DiamondPlate },
	ConveyorArrow = rgb(255, 230, 120),
	Ice = { Color = rgb(190, 230, 255), Material = Enum.Material.Glacier },
	Gravity = { Color = rgb(170, 90, 255), Material = Enum.Material.ForceField },
	Checkpoint = { Color = rgb(235, 255, 245), Material = Enum.Material.Neon },
	CheckpointClaimed = rgb(90, 255, 150),
	CheckpointNext = rgb(255, 255, 255),
	Final = { Color = rgb(255, 196, 60), Material = Enum.Material.Neon },
	Barrier = { Color = rgb(120, 200, 255), Material = Enum.Material.ForceField },
	Sign = { Color = rgb(70, 52, 40), Material = Enum.Material.Wood, Text = rgb(255, 250, 235) },
}

return Palette
