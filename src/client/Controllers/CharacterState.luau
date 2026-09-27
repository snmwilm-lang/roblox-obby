--[[
	CharacterState
	Single source of truth for the local character references.
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local CharacterState = {}

local character: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local changed = Instance.new("BindableEvent")

CharacterState.Changed = changed.Event -- (character?)

function CharacterState.get(): (Model?, Humanoid?, BasePart?)
	if character and humanoid and root and root.Parent and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil, nil, nil
end

-- Y of the soles of the feet (works for R6 and R15, any hip height).
function CharacterState.feetY(): number?
	local _, hum, rootPart = CharacterState.get()
	if not hum or not rootPart then
		return nil
	end
	local hip = if hum.RigType == Enum.HumanoidRigType.R6 then 2 else hum.HipHeight
	return rootPart.Position.Y - rootPart.Size.Y / 2 - hip
end

function CharacterState.init(_controllers) end

function CharacterState.start()
	local function onCharacter(newCharacter: Model)
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
		root = newCharacter:WaitForChild("HumanoidRootPart") :: BasePart
		changed:Fire(newCharacter)
	end
	player.CharacterAdded:Connect(onCharacter)
	player.CharacterRemoving:Connect(function()
		character, humanoid, root = nil, nil, nil
		changed:Fire(nil)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return CharacterState
