--[[
	HazardController
	Kill detection for the local character, every frame, after obstacles moved.

	- Hitbox: a fixed 1.6 x 5.6 x 1.6 box standing on the character's feet,
	  slightly SMALLER than the visual avatar. Near misses stay near misses,
	  and every avatar has exactly the same hitbox.
	- Exact geometry (GetPartsInPart) instead of bounding boxes: a rotated
	  laser kills only where it is drawn.
	- Void: falling VoidDepth studs below the lowest platform of the level.
	Detection is client-side because obstacles are animated client-side: what
	you see is what kills you, independent of ping.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local player = Players.LocalPlayer

local HazardController = {}

local HITBOX_SIZE = Vector3.new(1.6, 5.6, 1.6)
local FEET_MARGIN = 0.2 -- hitbox reaches this far below the soles (standing on a kill brick kills)

local controllers
local hitbox: Part
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
overlap.MaxParts = 8
local hazards: { BasePart } = {}
local disabled: { [BasePart]: boolean } = {}
local listDirty = true

-- Lasers (and future toggled hazards) switch lethality locally.
function HazardController.setLethal(part: BasePart, lethal: boolean)
	disabled[part] = if lethal then nil else true
end

local function rebuildList()
	table.clear(hazards)
	for _, part in CollectionService:GetTagged("Hazard") do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			table.insert(hazards, part)
		end
	end
	overlap.FilterDescendantsInstances = hazards
	listDirty = false
end

local function voidY(): number
	local levels = workspace:FindFirstChild(Config.World.FolderName)
	levels = levels and levels:FindFirstChild("Levels")
	local lowest = math.huge
	for _, attribute in { "CurrentLevel", "Checkpoint" } do
		local level = player:GetAttribute(attribute)
		local model = levels and level and levels:FindFirstChild(("Level_%03d"):format(level))
		local y = model and model:GetAttribute("VoidY")
		if typeof(y) == "number" then
			lowest = math.min(lowest, y)
		end
	end
	if lowest == math.huge then
		local respawn = player:GetAttribute("RespawnCFrame")
		lowest = if typeof(respawn) == "CFrame" then respawn.Position.Y - 80 else -500
	end
	return lowest
end

local function check()
	local RespawnController = controllers.RespawnController
	if not RespawnController.canDie() then
		return
	end
	local _, _, root = controllers.CharacterState.get()
	if not root or root.Anchored then
		return
	end
	local feet = controllers.CharacterState.feetY()
	if not feet then
		return
	end

	if root.Position.Y < voidY() then
		RespawnController.die("Void")
		return
	end

	if listDirty then
		rebuildList()
	end
	if #hazards == 0 then
		return
	end
	local center = Vector3.new(root.Position.X, feet - FEET_MARGIN + HITBOX_SIZE.Y / 2, root.Position.Z)
	local _, yaw = root.CFrame:ToOrientation()
	hitbox.CFrame = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
	for _, part in workspace:GetPartsInPart(hitbox, overlap) do
		if not disabled[part] then
			RespawnController.die("Hazard")
			return
		end
	end
end

function HazardController.init(allControllers)
	controllers = allControllers
end

function HazardController.start()
	hitbox = Instance.new("Part")
	hitbox.Name = "LocalHitbox"
	hitbox.Size = HITBOX_SIZE
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanQuery = false
	hitbox.CanTouch = false
	hitbox.Transparency = 1
	hitbox.Parent = workspace.CurrentCamera

	local function markDirty()
		listDirty = true
	end
	CollectionService:GetInstanceAddedSignal("Hazard"):Connect(markDirty)
	CollectionService:GetInstanceRemovedSignal("Hazard"):Connect(function(part)
		disabled[part] = nil
		listDirty = true
	end)

	RunService.PostSimulation:Connect(check)
end

return HazardController
