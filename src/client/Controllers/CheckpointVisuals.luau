--[[
	CheckpointVisuals
	Local colouring of checkpoint discs: cleared (green), current (white,
	pulsing light), not reached yet (dim). Your progress is readable in the world.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Palette"))

local player = Players.LocalPlayer

local CheckpointVisuals = {}

local function paint(disc: Instance)
	if not disc:IsA("BasePart") then
		return
	end
	local level = disc:GetAttribute("Level") or 0
	local checkpoint = player:GetAttribute("Checkpoint") or 1
	local light = disc:FindFirstChild("CheckpointLight") :: PointLight?
	if level < checkpoint then
		disc.Color = Palette.CheckpointClaimed
		disc.Transparency = 0.2
	elseif level == checkpoint then
		disc.Color = Palette.CheckpointNext
		disc.Transparency = 0
		if not light then
			light = Instance.new("PointLight")
			light.Name = "CheckpointLight"
			light.Range = 12
			light.Brightness = 1.5
			light.Color = Palette.CheckpointClaimed
			light.Parent = disc
		end
	else
		disc.Color = Palette.Checkpoint.Color
		disc.Transparency = 0.45
	end
	if light and level ~= checkpoint then
		light:Destroy()
	end
end

local function paintAll()
	for _, disc in CollectionService:GetTagged("CheckpointDisc") do
		paint(disc)
	end
end

function CheckpointVisuals.init(_controllers) end

function CheckpointVisuals.start()
	CollectionService:GetInstanceAddedSignal("CheckpointDisc"):Connect(paint)
	player:GetAttributeChangedSignal("Checkpoint"):Connect(paintAll)
	paintAll()
end

return CheckpointVisuals
