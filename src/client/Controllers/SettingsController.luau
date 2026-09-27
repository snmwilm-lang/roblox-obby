--[[
	SettingsController
	Per-player comfort settings, saved in the profile:
	  Music       zone music on/off
	  HideOthers  hide other players locally (readability + performance on
	              crowded servers; they still exist and still can't collide)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local player = Players.LocalPlayer

local SettingsController = {}

local controllers
local values = { Music = true, HideOthers = false }

local function applyHidden(character: Model?, hidden: boolean)
	if not character then
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		elseif d:IsA("BillboardGui") then
			d.Enabled = not hidden
		end
	end
end

local function applyAll()
	for _, other in Players:GetPlayers() do
		if other ~= player then
			applyHidden(other.Character, values.HideOthers)
		end
	end
end

local function apply(key: string)
	if key == "Music" then
		controllers.AudioController.setMusicEnabled(values.Music)
	elseif key == "HideOthers" then
		applyAll()
	end
	controllers.UIController.setButtonState(key, values[key])
end

function SettingsController.get(key: string): any
	return values[key]
end

function SettingsController.set(key: string, value: any)
	if values[key] == nil or typeof(value) ~= typeof(values[key]) then
		return
	end
	values[key] = value
	apply(key)
	Net.event("SaveSetting"):FireServer(key, value)
end

function SettingsController.init(allControllers)
	controllers = allControllers
end

function SettingsController.start()
	local function load()
		for key in values do
			local saved = player:GetAttribute("Setting_" .. key)
			if typeof(saved) == typeof(values[key]) then
				values[key] = saved
			end
			apply(key)
		end
	end
	load()
	player:GetAttributeChangedSignal("DataLoaded"):Connect(load)

	local function watch(other: Player)
		if other == player then
			return
		end
		other.CharacterAdded:Connect(function(character)
			task.wait(0.5) -- let accessories load
			applyHidden(character, values.HideOthers)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, other in Players:GetPlayers() do
		watch(other)
	end
end

return SettingsController
