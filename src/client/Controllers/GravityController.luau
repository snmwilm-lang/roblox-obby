--[[
	GravityController
	Local gravity for the local player only (workspace.Gravity set on the
	client affects only this client's simulation). Zones are volumes tagged
	"GravityZone" (GravityMultiplier, TransitionTime). The HUD shows the
	current multiplier whenever it is not 1x.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ObstacleTypes = require(Shared.ObstacleTypes)

local GravityController = {}

local controllers
local zones: { BasePart } = {}
local current = 1
local target = 1
local transition = 0.25

local function inside(part: BasePart, position: Vector3): boolean
	local p = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(p.X) <= half.X and math.abs(p.Y) <= half.Y and math.abs(p.Z) <= half.Z
end

function GravityController.reset()
	current = 1
	target = 1
	workspace.Gravity = Config.Character.Gravity
	if controllers then
		controllers.UIController.setGravity(1)
	end
end

function GravityController.init(allControllers)
	controllers = allControllers
end

function GravityController.start()
	local function add(part)
		if part:IsA("BasePart") and not table.find(zones, part) then
			table.insert(zones, part)
		end
	end
	CollectionService:GetInstanceAddedSignal("GravityZone"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("GravityZone"):Connect(function(part)
		local i = table.find(zones, part)
		if i then
			table.remove(zones, i)
		end
	end)
	for _, part in CollectionService:GetTagged("GravityZone") do
		add(part)
	end

	RunService.PreSimulation:Connect(function(dt)
		local _, _, root = controllers.CharacterState.get()
		local newTarget = 1
		if root then
			for _, zone in zones do
				if inside(zone, root.Position) then
					local config = ObstacleTypes.read(zone, "GravityZone")
					newTarget = config.GravityMultiplier
					transition = config.TransitionTime
				end
			end
		end
		if newTarget ~= target then
			target = newTarget
			controllers.UIController.setGravity(target)
			controllers.AudioController.play("GravitySwitch")
		end
		if current ~= target then
			local step = dt / math.max(transition, 0.01)
			if current < target then
				current = math.min(target, current + step)
			else
				current = math.max(target, current - step)
			end
			workspace.Gravity = Config.Character.Gravity * current
		end
	end)
end

return GravityController
