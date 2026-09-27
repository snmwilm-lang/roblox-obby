--[[
	Themes
	Per-zone decoration. Decoration never collides, never blocks the camera on
	the route, and never uses reserved semantic colours (see Shared/Palette).

	Each theme exposes:
	  decorateStart(L, padSize)  -- dressing of every start pad of the zone
	  scenery(L, pos, scale)     -- optional background landmark
]]

local rgb = Color3.fromRGB

local Themes = {}

local function floatingIsland(L, top: Vector3, size: Vector3, rockColor: Color3)
	-- Two stacked, slightly rotated rock blocks under the pad = floating island
	L:Decor(top - Vector3.new(0, size.Y + 2.5, 0), Vector3.new(size.X * 0.85, 5, size.Z * 0.85), {
		name = "IslandRock",
		color = rockColor,
		material = Enum.Material.Rock,
		rot = Vector3.new(0, 45 * (L.Level % 2), 0),
	})
	L:Decor(top - Vector3.new(0, size.Y + 7, 0), Vector3.new(size.X * 0.45, 5, size.Z * 0.45), {
		name = "IslandRock",
		color = rockColor:Lerp(Color3.new(0, 0, 0), 0.15),
		material = Enum.Material.Rock,
		rot = Vector3.new(0, 20 + 45 * (L.Level % 2), 0),
	})
end

local function tree(L, base: Vector3, scale: number)
	local trunkHeight = 6 * scale
	L:Decor(base + Vector3.new(0, trunkHeight / 2, 0), Vector3.new(1.2 * scale, trunkHeight, 1.2 * scale), {
		name = "Trunk",
		shape = "Cylinder",
		color = rgb(110, 78, 52),
		material = Enum.Material.Wood,
	})
	local foliage = L.Zone.Foliage
	L:Decor(base + Vector3.new(0, trunkHeight + 1.2 * scale, 0), Vector3.new(5, 5, 5) * scale, {
		name = "Leaves",
		shape = "Ball",
		color = foliage,
		material = Enum.Material.Grass,
	})
	L:Decor(base + Vector3.new(0.9 * scale, trunkHeight + 3 * scale, 0.4 * scale), Vector3.new(3.4, 3.4, 3.4) * scale, {
		name = "Leaves",
		shape = "Ball",
		color = foliage:Lerp(Color3.new(1, 1, 0.6), 0.12),
		material = Enum.Material.Grass,
		shadow = false,
	})
end

Themes[1] = {
	decorateStart = function(L, padSize: Vector3)
		floatingIsland(L, Vector3.zero, padSize, rgb(120, 104, 88))
		-- A tree on a back corner, alternating sides, never over the exit edge
		local side = if L.Level % 2 == 0 then 1 else -1
		tree(L, Vector3.new(side * (padSize.X / 2 - 1.5), 0, -padSize.Z / 2 + 1.5), 0.8 + (L.Level % 3) * 0.1)
		-- Flower tufts
		for i = 1, 3 do
			local x = L:Random(-padSize.X / 2 + 1, padSize.X / 2 - 1)
			local z = L:Random(-padSize.Z / 2 + 1, -2)
			L:Decor(Vector3.new(x, 0.25, z), Vector3.new(0.5, 0.5, 0.5), {
				name = "Flower",
				shape = "Ball",
				color = ({ rgb(255, 230, 120), rgb(255, 170, 200), rgb(220, 200, 255) })[i],
				material = Enum.Material.SmoothPlastic,
				shadow = false,
			})
		end
	end,
	scenery = function(L, pos: Vector3, scale: number)
		-- Distant floating island with trees: gives depth to the plateau
		local size = Vector3.new(24, 4, 20) * scale
		L:Decor(pos, size, { name = "FarIsland", color = L.Zone.Safe.Color, material = Enum.Material.Grass })
		floatingIsland(L, pos + Vector3.new(0, size.Y / 2, 0), size, rgb(120, 104, 88))
		tree(L, pos + Vector3.new(-size.X * 0.2, size.Y / 2, 0), 1.3 * scale)
		tree(L, pos + Vector3.new(size.X * 0.25, size.Y / 2, size.Z * 0.2), scale)
	end,
}

local function gear(L, center: Vector3, radius: number)
	-- Decorative brass gear standing upright, axis along local X (seen from the side)
	local color = rgb(170, 128, 60)
	local disc = L:Decor(center, Vector3.new(0.8, radius * 2, radius * 2), {
		name = "GearDisc",
		color = color,
		material = Enum.Material.Metal,
	})
	disc.Shape = Enum.PartType.Cylinder
	local teeth = 8
	for i = 1, teeth do
		local a = i * 360 / teeth
		local r = math.rad(a)
		L:Decor(center + Vector3.new(0, math.sin(r) * radius, math.cos(r) * radius), Vector3.new(0.8, 1.4, 1.4), {
			name = "GearTooth",
			color = color,
			material = Enum.Material.Metal,
			rot = Vector3.new(a, 0, 0),
			shadow = false,
		})
	end
end

Themes[2] = {
	decorateStart = function(L, padSize: Vector3)
		-- Iron substructure + a brass gear behind the pad
		L:Decor(Vector3.new(0, -padSize.Y - 3, 0), Vector3.new(padSize.X * 0.6, 6, padSize.Z * 0.6), {
			name = "Pylon",
			color = L.Zone.Structure.Color,
			material = Enum.Material.Metal,
		})
		local side = if L.Level % 2 == 0 then 1 else -1
		gear(L, Vector3.new(side * (padSize.X / 2 + 2), 3, -2), 4)
		L:Decor(Vector3.new(-side * (padSize.X / 2 - 1), 3, -padSize.Z / 2 + 1), Vector3.new(0.6, 6, 0.6), {
			name = "LampPost",
			color = L.Zone.Structure.Color,
			material = Enum.Material.Metal,
		})
		L:Decor(Vector3.new(-side * (padSize.X / 2 - 1), 6.4, -padSize.Z / 2 + 1), Vector3.new(1, 1, 1), {
			name = "Lamp",
			shape = "Ball",
			color = rgb(255, 200, 120),
			material = Enum.Material.Neon,
		})
	end,
	scenery = function(L, pos: Vector3, scale: number)
		gear(L, pos, 10 * scale)
	end,
}

-- Zones 3-10 fall back to a neutral treatment until they are built.
local neutral = {
	decorateStart = function(L, padSize: Vector3)
		L:Decor(Vector3.new(0, -padSize.Y - 3, 0), Vector3.new(padSize.X * 0.7, 6, padSize.Z * 0.7), {
			name = "Foundation",
			color = L.Zone.Structure.Color,
			material = L.Zone.Structure.Material,
		})
	end,
}

function Themes.get(zoneId: number)
	return Themes[zoneId] or neutral
end

return Themes
