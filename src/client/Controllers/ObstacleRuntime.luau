--[[
	ObstacleRuntime
	ONE loop animates every obstacle of the game on the client.

	- Components (client/Obstacles/*) register instances by CollectionService tag,
	  including instances that stream in later.
	- Only obstacles near the camera are updated (state is a pure function of
	  server time, so skipping far obstacles costs nothing in correctness).
	- All CFrame writes of a frame are batched into one workspace:BulkMoveTo.
	- Platform carry: when the local character stands on (or just jumped from)
	  a moving part, the part's frame-to-frame motion is applied to the
	  character. Deterministic, no physics tricks, works for sliding, lifting
	  and rotating platforms. Air-carry continues through a jump so jumping on
	  a ferry lands you back on the ferry, like real inertia.

	Why client-side? The server never moves obstacles: every player sees smooth
	motion with zero network cost, and a player can never affect obstacles of
	another player (falling platforms are per-player by construction).
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Timing = require(Shared.Timing)

local ObstaclesFolder = script.Parent.Parent:WaitForChild("Obstacles")

local ObstacleRuntime = {}

local AIR_CARRY_TIME = 1.2

type Record = {
	Instance: Instance,
	Component: any,
	State: any,
	Position: Vector3,
	Active: boolean,
}

local controllers
local records: { [Instance]: Record } = {}
local activeList: { Record } = {}
local partOwner: { [BasePart]: Record } = {}

-- per-frame batch
local moveParts: { BasePart } = {}
local moveCFrames: { CFrame } = {}
local carryMotion: { [BasePart]: { CFrame } } = {} -- part -> { previous, next }

local groundPart: BasePart? = nil
local carryPart: BasePart? = nil
local airTime = 0
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

----------------------------------------------------------------------------
-- API for components
----------------------------------------------------------------------------

-- Queue a CFrame write. carry = true lets the part transport the character.
function ObstacleRuntime.move(part: BasePart, cframe: CFrame, carry: boolean?)
	table.insert(moveParts, part)
	table.insert(moveCFrames, cframe)
	if carry then
		carryMotion[part] = { part.CFrame, cframe }
	end
end

-- Parts of an obstacle, so the runtime knows who owns what the player stands on.
function ObstacleRuntime.claimPart(part: BasePart, record: Record)
	partOwner[part] = record
end

function ObstacleRuntime.getGroundPart(): BasePart?
	return groundPart
end

function ObstacleRuntime.controllers()
	return controllers
end

-- Called on respawn: local-only obstacle state (falling platforms...) resets.
function ObstacleRuntime.resetLocal()
	for _, record in records do
		if record.Component.reset then
			record.Component.reset(record.State)
		end
	end
	carryPart = nil
	airTime = 0
end

----------------------------------------------------------------------------
-- Registration
----------------------------------------------------------------------------

local function pivotPosition(instance: Instance): Vector3
	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	end
	return Vector3.zero
end

local function add(component, instance: Instance)
	if records[instance] or not instance:IsDescendantOf(workspace) then
		return
	end
	local record: Record = {
		Instance = instance,
		Component = component,
		State = nil,
		Position = pivotPosition(instance),
		Active = false,
	}
	local ok, state = pcall(component.register, instance, record, ObstacleRuntime)
	if not ok then
		warn(("[ObstacleRuntime] %s failed on %s: %s"):format(component.Tag, instance:GetFullName(), tostring(state)))
		return
	end
	if state == nil then
		return
	end
	record.State = state
	records[instance] = record
	if instance:IsA("BasePart") then
		partOwner[instance] = record
	end
end

local function remove(instance: Instance)
	local record = records[instance]
	if not record then
		return
	end
	records[instance] = nil
	if record.Component.unregister then
		record.Component.unregister(record.State)
	end
	for part, owner in partOwner do
		if owner == record then
			partOwner[part] = nil
		end
	end
	local index = table.find(activeList, record)
	if index then
		table.remove(activeList, index)
	end
end

local function registerComponent(component)
	local tag = component.Tag
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		-- Models stream their children in after the container: wait a frame
		task.defer(add, component, instance)
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(remove)
	for _, instance in CollectionService:GetTagged(tag) do
		task.defer(add, component, instance)
	end
end

----------------------------------------------------------------------------
-- Loop
----------------------------------------------------------------------------

local function refreshActive()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local focus = camera.Focus.Position
	local radius = Config.Obstacles.ActiveRadius
	table.clear(activeList)
	for _, record in records do
		local active = (record.Position - focus).Magnitude < radius
		if active ~= record.Active and record.Component.setActive then
			record.Component.setActive(record.State, active)
		end
		record.Active = active
		if active then
			table.insert(activeList, record)
		end
	end
end

local function senseGround(): BasePart?
	local CharacterState = controllers.CharacterState
	local character, humanoid, root = CharacterState.get()
	if not character or not humanoid or not root then
		return nil
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return nil
	end
	groundParams.FilterDescendantsInstances = { character }
	local feet = CharacterState.feetY() or root.Position.Y
	local reach = root.Position.Y - feet + 1.2
	local result = workspace:Spherecast(root.Position, 0.9, Vector3.new(0, -reach, 0), groundParams)
	return result and result.Instance :: BasePart or nil
end

local function applyCarry(dt: number)
	local CharacterState = controllers.CharacterState
	local _, humanoid, root = CharacterState.get()
	if not humanoid or not root or root.Anchored then
		carryPart = nil
		return
	end

	if groundPart then
		carryPart = if carryMotion[groundPart] or (partOwner[groundPart] and partOwner[groundPart].Component.Carry) then groundPart else nil
		airTime = 0
	elseif carryPart then
		airTime += dt
		if airTime > AIR_CARRY_TIME then
			carryPart = nil
		end
	end

	local motion = carryPart and carryMotion[carryPart]
	if not motion then
		return
	end
	local previous, nextCFrame = motion[1], motion[2]
	local delta = nextCFrame * previous:Inverse()
	local newPosition = delta * root.Position
	-- keep the character upright: only transfer yaw
	local look = delta:VectorToWorldSpace(Vector3.xAxis)
	local yaw = math.atan2(-look.Z, look.X)
	root.CFrame = CFrame.new(newPosition) * CFrame.Angles(0, yaw, 0) * root.CFrame.Rotation
end

local function step(dt: number)
	local t = Timing.now()
	for _, record in activeList do
		record.Component.update(record.State, t, dt, ObstacleRuntime)
	end
	if #moveParts > 0 then
		workspace:BulkMoveTo(moveParts, moveCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	groundPart = senseGround()
	if groundPart then
		local owner = partOwner[groundPart]
		if owner and owner.Component.onGround then
			owner.Component.onGround(owner.State, groundPart, ObstacleRuntime)
		end
	end
	applyCarry(dt)

	table.clear(moveParts)
	table.clear(moveCFrames)
	table.clear(carryMotion)
end

function ObstacleRuntime.init(allControllers)
	controllers = allControllers
end

function ObstacleRuntime.start()
	for _, module in ObstaclesFolder:GetChildren() do
		if module:IsA("ModuleScript") then
			local component = require(module)
			if component.init then
				component.init(controllers)
			end
			registerComponent(component)
		end
	end

	task.spawn(function()
		while true do
			refreshActive()
			task.wait(Config.Obstacles.ActiveRefresh)
		end
	end)

	RunService.PreSimulation:Connect(step)
end

return ObstacleRuntime
