--[[
	ZONE 4 — VERTICALITY — Skyward Spire (levels 61-80)

	Lesson: control your body in 3D. Trusses (climb, then stand on top and
	jump), head hitters (a ceiling shortens the jump), wraparounds around wall
	corners (SHIFT LOCK makes them precise), spirals around towers.
	Budget: jumps ≤ 78 % of the maximum, ceilings included.
]]

local V = Vector3.new

local Levels = {}

-- Ring positions around a tower, counter-clockwise from the south (spawn) side
local RING = { V(0, 0, -1), V(-1, 0, -1), V(-1, 0, 0), V(-1, 0, 1), V(0, 0, 1), V(1, 0, 1), V(1, 0, 0), V(1, 0, -1) }

--[[
	Ledges spiralling around a square tower.
	center: tower centre (x, z) with center.Y = height of the first ledge.
	sizes: ledge size per ledge (number) or a function(i) -> number.
	Returns the top-centre of the last ledge and the tower half-size.
]]
local function spiral(L, center: Vector3, radius: number, rise: number, count: number, size, towerTop: number?, startIndex: number?)
	local last
	local maxSize = 0
	for i = 1, count do
		local s = if type(size) == "function" then size(i) else size
		maxSize = math.max(maxSize, s)
		local dir = RING[((startIndex or 1) + i - 2) % 8 + 1]
		last = V(center.X + dir.X * radius, center.Y + (i - 1) * rise, center.Z + dir.Z * radius)
		L:Step(last, V(s, 1, s), { name = "Ledge" })
	end
	local half = radius - maxSize / 2 - 1.2
	local top = towerTop or (last.Y + rise)
	local bottom = center.Y - 20
	L:Step(V(center.X, top, center.Z), V(half * 2, top - bottom, half * 2), { name = "Tower", route = towerTop ~= nil, material = Enum.Material.Marble, color = L.Zone.Structure.Color:Lerp(L.Zone.Safe.Color, 0.6) })
	return last, half
end

-- Wall with a corner to jump around. The ledges sit 7 studs out so the body
-- never clips the corner.
local function cornerWall(L, y: number, z: number, width: number)
	L:Wall(V(0, y + 6, z), V(width, 16, 2), { name = "CornerWall", material = Enum.Material.Marble })
end

-- 61 · Truss Climb — walk into a truss, climb, step off at the top.
Levels[61] = function(L)
	L:Sign(V(-4.5, 2, 5), "Walk into a truss to climb it.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 6, 15), 12, { route = true })
	L:Step(V(0, 12, 20), V(6, 1, 8))
	L:Step(V(0, 12, 31), V(6, 1, 6))
	L:Truss(V(0, 18, 35), 12, { route = true })
	L:Step(V(0, 24, 40), V(6, 1, 8))
	L:Exit(V(0, 24, 54))
end

-- 62 · Ladder Line — jump onto ladders hanging over the void.
Levels[62] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 4, 19), 16, { route = true })
	L:Step(V(0, 12, 24), V(6, 1, 8))
	L:Truss(V(0, 12, 33), 16, { route = true })
	L:Step(V(0, 20, 38), V(6, 1, 8))
	L:Exit(V(0, 20, 52))
end

-- 63 · Head Hitter — low ceilings cut your jumps short.
Levels[63] = function(L)
	L:Sign(V(-4.5, 2, 5), "Low ceiling = short jump.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 11), V(6, 1, 6), { keepSize = true })
	L:Step(V(0, 2, 20), V(6, 1, 6), { keepSize = true })
	L:Ceiling(V(0, 9.5, 12), V(6, 1, 8))
	L:Step(V(0, 4, 29), V(6, 1, 6), { keepSize = true })
	L:Ceiling(V(0, 12, 27.5), V(6, 1, 13))
	L:Step(V(0, 4, 38), V(6, 1, 6), { keepSize = true })
	L:Ceiling(V(0, 11, 36), V(6, 1, 10))
	L:Exit(V(0, 4, 50))
end

-- 64 · Spiral Stair — a full turn around a tower, then onto its roof.
Levels[64] = function(L)
	L:Step(V(0, 0, 14), V(6, 1, 6))
	spiral(L, V(0, 1.5, 29.5), 7, 1.5, 9, 3, 15)
	L:Exit(V(0, 15, 44))
end

-- 65 · Corner Kick — real wraparounds, 2 studs out: jump late, curve around.
Levels[65] = function(L)
	L:Sign(V(-4.5, 2, 5), "Tip: SHIFT LOCK (Shift key)\nfor precise wraparounds.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 13), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 19.5, 4, { overhang = 2, side = 1, material = Enum.Material.Marble })
	L:Step(V(0, 0, 26), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 32.5, 4, { overhang = 2, side = -1, material = Enum.Material.Marble })
	L:Step(V(0, 0, 39), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 45.5, 4, { overhang = 2.25, side = 1, material = Enum.Material.Marble })
	L:Step(V(0, 0, 52), V(4, 1, 12), { keepSize = true })
	L:Exit(V(0, 0, 68))
end

-- 66 · Truss Hop — stand on a truss top, jump to the next truss, climb again.
Levels[66] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 3, 16.5), 10, { route = true })
	L:Truss(V(0, 6, 23), 10, { route = true })
	L:Truss(V(0, 9, 29.5), 10, { route = true })
	L:Step(V(0, 14, 33.5), V(6, 1, 6))
	L:Exit(V(0, 14, 46))
end

-- Ledges climbing the four corners of a closed shaft. Same corner every
-- 10 studs, so a ledge never hangs over your head.
local SHAFT_CORNERS = { V(-3, 0, -3), V(3, 0, -3), V(3, 0, 3), V(-3, 0, 3) }

local function chimney(L, floorY: number, center: Vector3, count: number)
	local height = count * 2.5 + 6
	L:Wall(V(center.X - 5.5, floorY + height / 2, center.Z), V(1, height, 12), { name = "ShaftWall", material = Enum.Material.Marble })
	L:Wall(V(center.X + 5.5, floorY + height / 2, center.Z), V(1, height, 12), { name = "ShaftWall", material = Enum.Material.Marble })
	-- the back wall stops under the last ledge so the final jump clears it
	L:Wall(V(center.X, floorY + (height - 7) / 2, center.Z + 5.5), V(10, height - 7, 1), { name = "ShaftBack", material = Enum.Material.Marble })
	local last
	for i = 1, count do
		local corner = SHAFT_CORNERS[(i - 1) % 4 + 1]
		last = V(center.X + corner.X, floorY + i * 2.5, center.Z + corner.Z)
		L:Step(last, V(3, 1, 3), { name = "Ledge" })
	end
	return last, floorY + height - 3
end

-- 67 · Chimney — climb the four corners of a closed shaft.
Levels[67] = function(L)
	L:Step(V(0, 0, 20), V(10, 1, 18))
	local _, top = chimney(L, 0, V(0, 0, 24), 8)
	L:Step(V(0, top, 33), V(8, 1, 6))
	L:Exit(V(0, top, 46))
end

-- 68 · Overhang — wraparounds under a low roof: a short jump, so it must be exact.
Levels[68] = function(L)
	L:Step(V(0, 0, 13), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 19.5, 4, { overhang = 1, side = 1, material = Enum.Material.Marble })
	L:Ceiling(V(2, 8.9, 19.5), V(10, 1, 10))
	L:Step(V(0, 0, 26), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 32.5, 4, { overhang = 1, side = -1, material = Enum.Material.Marble })
	L:Ceiling(V(-2, 8.9, 32.5), V(10, 1, 10))
	L:Step(V(0, 0, 40), V(4, 1, 14), { keepSize = true })
	L:Exit(V(0, 0, 57))
end

-- 69 · Pillar Ascent — ledges shrink as you climb around the pillar.
Levels[69] = function(L)
	L:Step(V(0, 0, 13), V(6, 1, 6))
	spiral(L, V(0, 2, 28), 6, 2, 12, function(i)
		return if i <= 4 then 3 elseif i <= 8 then 2.5 else 2
	end, 26)
	L:Exit(V(0, 26, 41))
end

-- 70 · Tower Wrap — a narrow spiral with fins between the ledges.
Levels[70] = function(L)
	L:Step(V(0, 0, 13), V(6, 1, 6))
	local _, half = spiral(L, V(0, 2, 27), 6, 2, 10, 2.5, 22, 1)
	for i, dir in { V(-1, 0, -1), V(-1, 0, 1), V(1, 0, 1), V(1, 0, -1) } do
		L:Wall(V(dir.X * (half + 0.5), 8 + i * 4, 27 + dir.Z * (half + 0.5)), V(1, 3, 1), { name = "Fin", material = Enum.Material.Marble })
	end
	L:Exit(V(0, 22, 40))
end

-- 71 · Low Bridge — a rising corridor of head hitters over the void.
Levels[71] = function(L)
	for i = 1, 5 do
		local z = 5 + i * 7
		L:Step(V(0, i - 1, z), V(4, 1, 4), { keepSize = true })
		L:Ceiling(V(0, i + 6.5, z - 3.5), V(6, 1, 7))
	end
	L:Step(V(0, 4, 48), V(6, 1, 6), { keepSize = true })
	L:Exit(V(0, 4, 61))
end

-- 72 · Ferry Ladder — a ferry takes you to a ladder, twice.
Levels[72] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 18), V(6, 1, 6), V(0, 0, 12), { period = 6, pause = 1.5 })
	L:Truss(V(0, 8, 34.5), 16, { route = true })
	L:Step(V(0, 16, 39.5), V(6, 1, 8))
	L:Mover(V(0, 16, 50), V(6, 1, 6), V(0, 0, 10), { period = 6, pause = 1.5 })
	L:Truss(V(0, 24, 64.5), 16, { route = true })
	L:Step(V(0, 32, 69.5), V(6, 1, 8))
	L:Exit(V(0, 32, 83))
end

-- 73 · Scaffolding — read the right way up; two branches are dead ends.
Levels[73] = function(L)
	L:Step(V(0, 0, 12), V(6, 1, 6))
	L:Truss(V(0, 6, 16), 12, { route = true })
	L:Step(V(0, 12, 20), V(6, 1, 6))
	L:Step(V(6, 14, 24), V(4, 1, 4))
	L:Step(V(6, 16, 31), V(4, 1, 4))
	L:Truss(V(6, 22, 34), 12, { route = true })
	L:Step(V(6, 28, 38), V(6, 1, 6))
	L:Step(V(0, 28, 46), V(6, 1, 6))
	-- dead ends
	L:Pad(V(-6, 14, 24), V(4, 1, 4))
	L:Pad(V(-6, 16, 31), V(4, 1, 4))
	for _, x in { -9, 9 } do
		for _, z in { 18, 42 } do
			L:Decor(V(x, 14, z), V(0.8, 30, 0.8), { name = "ScaffoldPole", material = Enum.Material.Metal })
		end
	end
	L:Exit(V(0, 28, 59))
end

-- 74 · Corner Hops — 3x3 blocks in an L-shaped zig-zag, rising.
Levels[74] = function(L)
	local points = { V(0, 0, 12), V(5, 1, 12), V(5, 2, 18), V(0, 3, 18), V(0, 4, 24), V(5, 5, 24), V(5, 6, 30), V(0, 7, 30) }
	for _, p in points do
		L:Step(p, V(3, 1, 3), { name = "Block" })
	end
	L:Step(V(0, 7, 38), V(6, 1, 6))
	L:Exit(V(0, 7, 51))
end

-- 75 · Lift Shaft — two elevators; the landings have low ceilings.
Levels[75] = function(L)
	L:Mover(V(0, 0, 14), V(6, 1, 6), V(0, 14, 0), { period = 7, pause = 1.5 })
	L:Step(V(0, 14, 23), V(6, 1, 6))
	L:Ceiling(V(0, 22.5, 23), V(6, 1, 6))
	L:Mover(V(0, 14, 32), V(6, 1, 6), V(0, 14, 0), { period = 7, pause = 1.5, phase = 0.5 })
	L:Step(V(0, 28, 41), V(6, 1, 6))
	L:Exit(V(0, 28, 54))
end

-- 76 · Double Wrap — two wraparounds with a 3-stud landing in between.
Levels[76] = function(L)
	L:Step(V(0, 0, 13), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 19.5, 4, { overhang = 2, side = 1, material = Enum.Material.Marble })
	L:Step(V(0, 0, 21.5), V(4, 1, 3), { keepSize = true })
	L:Wrap(0, 23.5, 4, { overhang = 2, side = -1, material = Enum.Material.Marble })
	L:Step(V(0, 0, 30), V(4, 1, 12), { keepSize = true })
	L:Exit(V(0, 0, 46))
end

-- 77 · Sky Ladder — hop from truss top to truss top, sideways and up.
Levels[77] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 6, 15), 16, { route = true })
	L:Truss(V(4.5, 10, 15), 16, { route = true })
	L:Truss(V(9, 14, 15), 16, { route = true })
	L:Step(V(9, 22, 20), V(4, 1, 8))
	L:Step(V(9, 22, 31), V(4, 1, 6))
	L:Exit(V(9, 22, 44))
end

-- 78 · Wrap Tower — tall spiral with fins, tiny ledges near the top.
Levels[78] = function(L)
	L:Step(V(0, 0, 13), V(6, 1, 6))
	spiral(L, V(0, 2, 27), 6, 2, 14, function(i)
		return if i <= 7 then 2.5 else 2
	end, 30)
	L:Exit(V(0, 30, 40))
end

-- 79 · The Spire — pre-final: truss, head hitters, wraparound, spiral.
Levels[79] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 6, 15), 12, { route = true })
	L:Step(V(0, 12, 20), V(6, 1, 8))
	L:Step(V(0, 14, 29), V(6, 1, 6))
	L:Ceiling(V(0, 21.5, 27), V(6, 1, 12))
	L:Step(V(0, 14, 40), V(4, 1, 10), { keepSize = true })
	L:Wrap(14, 45.5, 4, { overhang = 2, side = 1, material = Enum.Material.Marble })
	L:Step(V(0, 14, 52), V(4, 1, 12), { keepSize = true })
	spiral(L, V(0, 15.5, 70), 7, 1.5, 9, 3, 29)
	L:Exit(V(0, 29, 85))
end

-- 80 · Summit Ascent — FINAL STAGE: the great climb (+60 studs).
Levels[80] = function(L)
	L:SectionLabel(V(-4, 1.5, 6.5), "I · LADDERS")
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Truss(V(0, 6, 15), 12, { route = true })
	L:Step(V(0, 12, 20), V(6, 1, 8))
	L:Truss(V(0, 12, 29), 16, { route = true })
	L:Step(V(0, 20, 34), V(6, 1, 8))
	-- II · head hitters
	L:Step(V(0, 22, 43), V(6, 1, 6))
	L:Ceiling(V(0, 29.5, 35), V(6, 1, 8))
	L:Step(V(0, 24, 52), V(6, 1, 6))
	L:Ceiling(V(0, 32, 49), V(6, 1, 10))
	-- III · double wrap
	L:Step(V(0, 24, 63), V(4, 1, 16), { keepSize = true })
	L:Wrap(24, 71.5, 4, { overhang = 2, side = 1, material = Enum.Material.Marble })
	L:Step(V(0, 24, 73.5), V(4, 1, 3), { keepSize = true })
	L:Wrap(24, 75.5, 4, { overhang = 2, side = -1, material = Enum.Material.Marble })
	L:Step(V(0, 24, 83), V(4, 1, 14), { keepSize = true })
	-- IV · truss hop
	L:Truss(V(0, 27, 95.5), 10, { route = true })
	L:Truss(V(0, 30, 102), 10, { route = true })
	L:Step(V(0, 35, 106), V(6, 1, 6))
	-- V · corner blocks
	for i, p in { V(0, 36, 114), V(5, 37, 114), V(5, 38, 120), V(0, 39, 120) } do
		L:Step(p, V(3, 1, 3), { name = "Block" })
	end
	L:Step(V(0, 39, 128), V(6, 1, 6))
	-- VI · chimney
	L:Step(V(0, 39, 140), V(10, 1, 12))
	local _, top = chimney(L, 39, V(0, 0, 141), 8)
	L:Step(V(0, top, 150), V(8, 1, 6))
	-- VII · summit spiral
	L:SectionLabel(V(0, top + 2, 152.5), "VII · SUMMIT")
	spiral(L, V(0, top + 1.5, 167), 7, 1.5, 9, 3, top + 15)
	L.Theme.scenery(L, V(-45, 20, 90), 1.4)
	L.Theme.scenery(L, V(40, 30, 160), 1.2)
	L:Exit(V(0, top + 15, 182))
end

return Levels
