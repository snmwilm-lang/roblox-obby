--[[
	Net
	Single place declaring every remote. The server creates them, clients wait.

	Replicated player state uses Player attributes instead of remotes:
	  Checkpoint, CurrentLevel, BestLevel, Deaths, Completions,
	  SpeedrunActive, SpeedrunStart, RespawnCFrame, DataLoaded
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local EVENTS = {
	"ReportDeath", -- client -> server (reason: string)
	"Notify", -- server -> client ({ Kind = string, ... })
	"SpeedrunRequest", -- client -> server (enable: boolean)
	"RestartRequest", -- client -> server (from the victory room)
	"SaveSetting", -- client -> server (key: string, value: any)
}

local Net = {}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not existing then
			existing = Instance.new("Folder")
			existing.Name = FOLDER_NAME
			existing.Parent = ReplicatedStorage
		end
		folder = existing
	else
		folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
	return folder :: Folder
end

function Net.init()
	assert(RunService:IsServer(), "Net.init is server only")
	local f = getFolder()
	for _, name in EVENTS do
		if not f:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = f
		end
	end
end

function Net.event(name: string): RemoteEvent
	assert(table.find(EVENTS, name), "Unknown remote " .. name)
	local f = getFolder()
	if RunService:IsServer() then
		local remote = f:FindFirstChild(name)
		assert(remote, "Net.init() must run before Net.event(" .. name .. ")")
		return remote :: RemoteEvent
	end
	return f:WaitForChild(name) :: RemoteEvent
end

return Net
