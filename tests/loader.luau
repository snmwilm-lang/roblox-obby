--[[
	Headless module loader for Lune (https://lune-org.github.io).
	Maps the Rojo tree (default.project.json) onto the file system so the real
	game modules can be required outside Roblox, with `script`, `game` and
	`require(instancePath)` emulated. Roblox datatypes come from @lune/roblox.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Loader = {}

local ROOTS = {
	ReplicatedStorage = { Shared = "src/shared" },
	ServerScriptService = { Server = "src/server" },
	StarterPlayerScripts = { Client = "src/client" },
}

local cache = {}

local function nodeMethods(node)
	node.WaitForChild = function(self, name)
		local child = rawget(self, "__kids")[name]
		if not child then
			error("WaitForChild: no child " .. name .. " under " .. tostring(rawget(self, "__path")))
		end
		return child
	end
	node.FindFirstChild = function(self, name)
		return rawget(self, "__kids")[name]
	end
	return node
end

local function stripName(file: string): string?
	for _, suffix in { ".server.luau", ".client.luau", ".luau" } do
		if file:sub(-#suffix) == suffix then
			return file:sub(1, -#suffix - 1)
		end
	end
	return nil
end

-- Eagerly mirror a directory as a tree of plain tables (fs calls cannot run
-- inside metamethods in Lune, so nothing is resolved lazily).
local function buildNode(name: string, path: string, parent: any)
	local node = nodeMethods({ Name = name, Parent = parent, __path = path, __kids = {} })
	if fs.isDir(path) then
		for _, entry in fs.readDir(path) do
			local full = path .. "/" .. entry
			local childName = if fs.isDir(full) then entry else stripName(entry)
			if childName and childName ~= "init" then
				local child = buildNode(childName, full, node)
				node.__kids[childName] = child
				node[childName] = child
			end
		end
	end
	return node
end

local services = {}
for serviceName, children in ROOTS do
	local service = nodeMethods({ Name = serviceName, __kids = {} })
	for childName, path in children do
		local child = buildNode(childName, path, service)
		service.__kids[childName] = child
		service[childName] = child
	end
	services[serviceName] = service
end

local fakeGame = {
	GetService = function(_, name)
		return services[name] or error("Service not emulated: " .. name)
	end,
}

local function sourcePath(node): string
	local path = node.__path
	if fs.isDir(path) then
		for _, init in { "/init.luau", "/init.server.luau", "/init.client.luau" } do
			if fs.isFile(path .. init) then
				return path .. init
			end
		end
		error("Folder is not a module: " .. path)
	end
	return path
end

local function loaderRequire(node)
	if type(node) == "string" then
		return require(node)
	end
	local path = sourcePath(node)
	if cache[path] ~= nil then
		return cache[path]
	end
	local source = fs.readFile(path)
	local env = setmetatable({
		script = node,
		game = fakeGame,
		workspace = { GetServerTimeNow = function() return os.clock() end },
		require = loaderRequire,
		Instance = roblox.Instance,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		CFrame = roblox.CFrame,
		Color3 = roblox.Color3,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		ColorSequence = roblox.ColorSequence,
		warn = function(...)
			print("[warn]", ...)
		end,
	}, { __index = _G })
	local chunk = luau.load(source, { debugName = path, environment = env })
	local result = chunk()
	cache[path] = result
	return result
end

Loader.require = loaderRequire
Loader.services = services
Loader.roblox = roblox

-- e.g. Loader.get("ReplicatedStorage", "Shared", "CheckpointRules")
function Loader.get(serviceName: string, ...: string)
	local node = services[serviceName]
	for _, name in { ... } do
		node = node:WaitForChild(name)
	end
	return loaderRequire(node)
end

return Loader
