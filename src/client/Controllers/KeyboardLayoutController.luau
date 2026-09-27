--[[
	KeyboardLayoutController
	AZERTY support: Z / Q also move forward / left, on top of the default
	WASD + arrows. Runs right after the default ControlModule each frame and
	adds ZQ to its move vector (S and D are already bound by default).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local KeyboardLayoutController = {}

function KeyboardLayoutController.init(_controllers) end

function KeyboardLayoutController.start()
	local controls = nil
	task.spawn(function()
		local ok, result = pcall(function()
			local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
			return module and require(module):GetControls()
		end)
		if ok then
			controls = result
		end
	end)

	RunService:BindToRenderStep("AzertyMovement", Enum.RenderPriority.Character.Value + 1, function()
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local forward = UserInputService:IsKeyDown(Enum.KeyCode.Z)
		local left = UserInputService:IsKeyDown(Enum.KeyCode.Q)
		if not forward and not left then
			return
		end
		local base = if controls then controls:GetMoveVector() else Vector3.zero
		local extra = Vector3.new(if left then -1 else 0, 0, if forward then -1 else 0)
		local move = base + extra
		move = Vector3.new(math.clamp(move.X, -1, 1), 0, math.clamp(move.Z, -1, 1))
		if move.Magnitude > 1 then
			move = move.Unit
		end
		player:Move(move, true)
	end)
end

return KeyboardLayoutController
