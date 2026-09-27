--[[
	Bakes the world into the place file so the map is visible (and editable)
	in Roblox Studio edit mode, and the game does not depend on building it
	at runtime.

	    rojo build -o build/place.rbxlx
	    lune run tools/bake.luau build/place.rbxlx Obby200.rbxl

	At runtime StageService re-indexes this baked world (WorldBuilder.index).
	If the folder is deleted, the server rebuilds the world from code.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Loader = require("../tests/loader")

local roblox = Loader.roblox
local input = process.args[1] or "build/place.rbxlx"
local output = process.args[2] or "Obby200.rbxl"

local place = roblox.deserializePlace(fs.readFile(input))
local workspace = place:GetService("Workspace")

local existing = workspace:FindFirstChild("Obby")
if existing then
	existing:Destroy()
end

local WorldBuilder = Loader.get("ServerScriptService", "Server", "World", "WorldBuilder")

local root = roblox.Instance.new("Folder")
root.Name = "Obby"
local levels = roblox.Instance.new("Folder")
levels.Name = "Levels"
levels.Parent = root
local _, highest = WorldBuilder.build(levels)
root.Parent = workspace

local parts = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	end
end

fs.writeFile(output, roblox.serializePlace(place))
print(("baked %d levels (%d parts) into %s"):format(highest, parts, output))
