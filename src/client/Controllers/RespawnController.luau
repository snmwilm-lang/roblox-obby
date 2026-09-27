--[[
	RespawnController
	Fast fail: death -> 0.2 s effect -> back on the checkpoint, same character.
	Also routes the Roblox reset button to the same fast path.
]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local player = Players.LocalPlayer

local RespawnController = {}

local controllers
local reportDeath: RemoteEvent
local dying = false
local invulnerableUntil = 0

function RespawnController.canDie(): boolean
	return not dying and os.clock() >= invulnerableUntil
end

local function deathBurst(position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 70, 60), Color3.fromRGB(255, 200, 120))
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(12, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Enabled = false
	emitter.Parent = anchor
	anchor.Parent = workspace.CurrentCamera
	emitter:Emit(24)
	task.delay(0.6, function()
		anchor:Destroy()
	end)
end

-- Instantly moves the character to the active checkpoint (no effect).
function RespawnController.returnToCheckpoint()
	local character, _, root = controllers.CharacterState.get()
	local target = player:GetAttribute("RespawnCFrame")
	if not character or not root or typeof(target) ~= "CFrame" then
		return
	end
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	controllers.ObstacleRuntime.resetLocal()
	controllers.GravityController.reset()
end

function RespawnController.die(reason: string)
	if not RespawnController.canDie() then
		return
	end
	local character, humanoid, root = controllers.CharacterState.get()
	if not character or not humanoid or not root then
		return
	end
	dying = true
	reportDeath:FireServer(reason)
	controllers.AudioController.play("Death")
	controllers.UIController.flashDeath()
	deathBurst(root.Position)
	root.Anchored = true

	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = 1
		end
	end

	task.delay(Config.Respawn.EffectTime, function()
		local target = player:GetAttribute("RespawnCFrame")
		if typeof(target) == "CFrame" then
			pcall(function()
				player:RequestStreamAroundAsync(target.Position, 2)
			end)
		end
		if root.Parent then
			RespawnController.returnToCheckpoint()
			root.Anchored = false
		end
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				d.LocalTransparencyModifier = 0
			end
		end
		invulnerableUntil = os.clock() + Config.Respawn.Invulnerable
		dying = false
	end)
end

function RespawnController.init(allControllers)
	controllers = allControllers
end

function RespawnController.start()
	reportDeath = Net.event("ReportDeath")

	-- Reset button = fast respawn instead of a full character reload
	local resetBindable = Instance.new("BindableEvent")
	resetBindable.Event:Connect(function()
		RespawnController.die("Reset")
	end)
	task.spawn(function()
		for _ = 1, 20 do
			local ok = pcall(function()
				StarterGui:SetCore("ResetButtonCallback", resetBindable)
			end)
			if ok then
				return
			end
			task.wait(0.5)
		end
	end)

	controllers.CharacterState.Changed:Connect(function()
		dying = false
		invulnerableUntil = os.clock() + Config.Respawn.Invulnerable
		controllers.GravityController.reset()
	end)

	Net.event("Notify").OnClientEvent:Connect(function(message)
		if message.Kind == "Teleported" then
			controllers.ObstacleRuntime.resetLocal()
			controllers.GravityController.reset()
			invulnerableUntil = os.clock() + Config.Respawn.Invulnerable
		end
	end)
end

return RespawnController
