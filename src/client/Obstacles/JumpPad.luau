--[[
	JumpPad component (tag "JumpPad")
	Landing on it launches the local character: vertical velocity = Power,
	plus an optional world-space Boost. Same height every time (no physics
	randomness), with a squash animation and a sound.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObstacleTypes = require(Shared.ObstacleTypes)

local JumpPad = {}
JumpPad.Tag = "JumpPad"

local COOLDOWN = 0.35

local controllers

function JumpPad.init(allControllers)
	controllers = allControllers
end

function JumpPad.register(instance: Instance)
	if not instance:IsA("BasePart") then
		return nil
	end
	return {
		Part = instance,
		Config = ObstacleTypes.read(instance, "JumpPad"),
		Last = 0,
	}
end

function JumpPad.onGround(state)
	local now = os.clock()
	if now - state.Last < COOLDOWN then
		return
	end
	local _, humanoid, root = controllers.CharacterState.get()
	if not humanoid or not root then
		return
	end
	state.Last = now
	local v = root.AssemblyLinearVelocity
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	root.AssemblyLinearVelocity = Vector3.new(v.X, state.Config.Power, v.Z) + state.Config.Boost
	controllers.AudioController.playAt("JumpPad", state.Part.Position)
end

function JumpPad.update() end

return JumpPad
