--[[
	ShiftLockController
	Custom shift lock, available on every device:
	  - PC: Shift (left or right) toggles it
	  - mobile / gamepad: the SHIFT LOCK button of the HUD (gamepad: L2 / ButtonL2)
	While on: the mouse is locked in the centre, the camera sits over the
	right shoulder and the character always faces where the camera looks.
	That is what makes precise side jumps along walls (wraparounds) easy.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local ShiftLockController = {}

local CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0)

local controllers
local enabled = false
local changed = Instance.new("BindableEvent")
ShiftLockController.Changed = changed.Event

function ShiftLockController.isEnabled(): boolean
	return enabled
end

function ShiftLockController.set(on: boolean)
	if on == enabled then
		return
	end
	enabled = on
	local _, humanoid = controllers.CharacterState.get()
	if humanoid then
		humanoid.AutoRotate = not on
		humanoid.CameraOffset = if on then CAMERA_OFFSET else Vector3.zero
	end
	if not on then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	UserInputService.MouseIconEnabled = not on or UserInputService.TouchEnabled
	changed:Fire(on)
end

function ShiftLockController.toggle()
	ShiftLockController.set(not enabled)
end

function ShiftLockController.init(allControllers)
	controllers = allControllers
end

function ShiftLockController.start()
	ContextActionService:BindAction("ObbyShiftLock", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			ShiftLockController.toggle()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL2)

	controllers.CharacterState.Changed:Connect(function(character)
		if character and enabled then
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.AutoRotate = false
			humanoid.CameraOffset = CAMERA_OFFSET
		end
	end)

	-- After the default camera (priority Camera) so our mouse lock sticks
	RunService:BindToRenderStep("ObbyShiftLock", Enum.RenderPriority.Camera.Value + 1, function()
		if not enabled then
			return
		end
		if not UserInputService.TouchEnabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		local _, humanoid, root = controllers.CharacterState.get()
		local camera = workspace.CurrentCamera
		if not humanoid or not root or root.Anchored or not camera then
			return
		end
		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 1e-3 then
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
		end
	end)
end

return ShiftLockController
