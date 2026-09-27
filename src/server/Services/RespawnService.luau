--[[
	RespawnService
	Character lifecycle on the server.

	Fast-fail design: deaths from obstacles never kill the Humanoid. The client
	detects the hazard, plays a ~0.2 s effect and moves its own character back
	to Player.RespawnCFrame (no character reload, no black screen). It then
	reports the death here for the statistics.

	Real Humanoid deaths (reset button fallback, falling out of the world...)
	still work: RespawnTime is short and CharacterAdded places the new
	character on the checkpoint.

	Fairness: other players never collide with you, and R15 avatar scales are
	normalised so every player has the same body for wraparounds and limbo bars.
]]

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local RespawnService = {}

local PLAYER_GROUP = "Players"
local NORMALIZE_AVATAR_SCALE = true

local services
local notify: RemoteEvent
local lastDeath: { [Player]: number } = {}

local function setCollisionGroup(character: Model)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = PLAYER_GROUP
		end
	end
	character.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = PLAYER_GROUP
		end
	end)
end

local function normalizeScale(humanoid: Humanoid)
	if not NORMALIZE_AVATAR_SCALE or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	local ok, desc = pcall(function()
		return humanoid:GetAppliedDescription()
	end)
	if not ok or not desc then
		return
	end
	if desc.HeightScale == 1 and desc.WidthScale == 1 and desc.DepthScale == 1 and desc.HeadScale == 1 and desc.BodyTypeScale == 0 and desc.ProportionScale == 0 then
		return
	end
	desc.HeightScale = 1
	desc.WidthScale = 1
	desc.DepthScale = 1
	desc.HeadScale = 1
	desc.BodyTypeScale = 0
	desc.ProportionScale = 0
	pcall(function()
		humanoid:ApplyDescription(desc)
	end)
end

local function countDeath(player: Player)
	local now = os.clock()
	if lastDeath[player] and now - lastDeath[player] < Config.Respawn.Debounce then
		return
	end
	lastDeath[player] = now
	local data = services.DataService.get(player)
	if data then
		data.Deaths += 1
		player:SetAttribute("Deaths", data.Deaths)
	end
end

local function targetFor(player: Player): CFrame
	local cf = player:GetAttribute("RespawnCFrame")
	if typeof(cf) == "CFrame" then
		return cf
	end
	return services.StageService.getSpawn(1)
end

local function onCharacterAdded(player: Player, character: Model)
	setCollisionGroup(character)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	root.Anchored = true

	normalizeScale(humanoid)

	local waited = 0
	while not player:GetAttribute("DataLoaded") and player.Parent and waited < 30 do
		waited += task.wait(0.1)
	end
	if character.Parent == nil then
		return
	end

	local target = targetFor(player)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 5)
	end)
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	local hold = player:GetAttribute("SpeedrunHoldUntil")
	if typeof(hold) == "number" and hold > workspace:GetServerTimeNow() then
		task.delay(hold - workspace:GetServerTimeNow(), function()
			if root.Parent then
				root.Anchored = false
			end
		end)
	else
		root.Anchored = false
	end

	humanoid.Died:Connect(function()
		countDeath(player)
	end)

	services.OverheadService.attach(player, character)
end

function RespawnService.init(allServices)
	services = allServices
	Players.RespawnTime = Config.Respawn.HardRespawnTime
	pcall(function()
		PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
	end)
	PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)
end

--[[
	Server-side teleport to the active checkpoint (restart, speedrun toggle).
	hold: optional seconds during which the character stays anchored.
]]
function RespawnService.sendToCheckpoint(player: Player, hold: number?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end
	local target = targetFor(player)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 5)
	end)
	root.Anchored = true
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	notify:FireClient(player, { Kind = "Teleported" })
	task.delay(hold or 0.1, function()
		if root.Parent then
			root.Anchored = false
		end
	end)
end

function RespawnService.start()
	notify = Net.event("Notify")

	Net.event("ReportDeath").OnServerEvent:Connect(function(player, reason)
		if typeof(reason) ~= "string" then
			return
		end
		countDeath(player)
	end)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastDeath[player] = nil
	end)
end

return RespawnService
