--[[
	OverheadService
	Name + best level above every character. The number is coloured with the
	zone the player reached; 200 (game beaten) is gold with a star, so it reads
	instantly as "this person finished the game".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local CheckpointRules = require(Shared.CheckpointRules)
local Palette = require(Shared.Palette)

local OverheadService = {}

local connections: { [Player]: RBXScriptConnection } = {}

local function styleFor(best: number): (string, Color3)
	if best >= Config.TOTAL_LEVELS then
		return "★ " .. best, Palette.Final.Color
	end
	local zone = Zones[CheckpointRules.zoneOf(best)]
	return tostring(best), zone.DifficultyColor
end

function OverheadService.init(_services) end

function OverheadService.start() end

function OverheadService.attach(player: Player, character: Model)
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Overhead"
	gui.Size = UDim2.fromOffset(200, 48)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Adornee = head

	local name = Instance.new("TextLabel")
	name.Name = "PlayerName"
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.45)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.5
	name.Text = player.DisplayName
	name.Parent = gui

	local level = Instance.new("TextLabel")
	level.Name = "BestLevel"
	level.BackgroundTransparency = 1
	level.Position = UDim2.fromScale(0, 0.45)
	level.Size = UDim2.fromScale(1, 0.55)
	level.Font = Enum.Font.GothamBlack
	level.TextScaled = true
	level.TextStrokeTransparency = 0.3
	level.Parent = gui

	local function update()
		local text, color = styleFor(player:GetAttribute("BestLevel") or 1)
		level.Text = text
		level.TextColor3 = color
	end
	update()
	if connections[player] then
		connections[player]:Disconnect()
	end
	connections[player] = player:GetAttributeChangedSignal("BestLevel"):Connect(update)
	player.AncestryChanged:Once(function()
		if connections[player] then
			connections[player]:Disconnect()
			connections[player] = nil
		end
	end)

	gui.Parent = head
end

return OverheadService
