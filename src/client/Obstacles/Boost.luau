--[[
	Boost component (tag "Boost"): standing on it raises the LOCAL player's
	WalkSpeed to `WalkSpeed` for `Duration` seconds (refreshed while on it).
	This is how momentum gates work: the gap after a boost strip is only
	reachable with the boosted speed. Scripted, so it is identical every time.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local ObstacleTypes = require(Shared.ObstacleTypes)
local Palette = require(Shared.Palette)

local Boost = {}
Boost.Tag = "Boost"

local controllers
local boostedUntil = 0
local watching = false

local function restore()
	boostedUntil = 0
	local _, humanoid = controllers.CharacterState.get()
	if humanoid then
		humanoid.WalkSpeed = Config.Character.WalkSpeed
	end
end

function Boost.init(allControllers)
	controllers = allControllers
end

function Boost.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	-- chevrons so the strip reads as "speed"
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Palette.Final.Color
	label.Text = "»»»"
	label.Rotation = -90
	label.Parent = gui
	gui.Parent = instance
	return { Part = instance, Config = ObstacleTypes.read(instance, "Boost"), Gui = gui }
end

function Boost.onGround(state)
	local _, humanoid = controllers.CharacterState.get()
	if not humanoid then
		return
	end
	if humanoid.WalkSpeed < state.Config.WalkSpeed then
		controllers.AudioController.play("JumpPad")
	end
	humanoid.WalkSpeed = state.Config.WalkSpeed
	boostedUntil = os.clock() + state.Config.Duration
	if not watching then
		watching = true
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if os.clock() >= boostedUntil then
				connection:Disconnect()
				watching = false
				restore()
			end
		end)
	end
end

function Boost.update() end

function Boost.reset()
	if boostedUntil > 0 then
		restore()
	end
end

function Boost.unregister(state)
	state.Gui:Destroy()
end

return Boost
