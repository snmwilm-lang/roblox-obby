--[[
	ZONE 5 — DYNAMIC — Shifting Ruins (levels 81-100)

	Lesson: the level itself is the threat. Platforms crack and fall (local to
	each player), wind pushes (particles show it, gusts whistle first),
	seesaws tilt, drawbridges rise, crushers drop, lava chases you.
	Budget: jumps ≤ 80 % of the maximum; jumps inside wind stay ≤ 50 %.
	Chasers never exceed 65 % of walking speed and always wait 3 s.
]]

local V = Vector3.new

local Levels = {}

local STONE = Enum.Material.Limestone

-- Ring of ledges around a tower (same layout as zone 4 spirals)
local RING = { V(0, 0, -1), V(-1, 0, -1), V(-1, 0, 0), V(-1, 0, 1), V(0, 0, 1), V(1, 0, 1), V(1, 0, 0), V(1, 0, -1) }

local function towerClimb(L, center: Vector3, count: number, rise: number)
	local radius, size = 6, 3
	local last
	for i = 1, count do
		local dir = RING[(i - 1) % 8 + 1]
		last = V(center.X + dir.X * radius, center.Y + (i - 1) * rise, center.Z + dir.Z * radius)
		L:Step(last, V(size, 1, size), { name = "Ledge" })
	end
	local half = radius - size / 2 - 1.2
	local top = last.Y + rise
	L:Step(V(center.X, top, center.Z), V(half * 2, top - center.Y + 20, half * 2), { name = "Tower", material = STONE })
	return top, half
end

local function crusher(L, y: number, z: number, width: number, phase: number)
	L:Mover(V(0, y + 11, z), V(width, 4, 5), V(0, -6, 0), { kill = true, period = 3.5, pause = 0.8, phase = phase })
	L:Decor(V(-width / 2 - 0.6, y + 7, z), V(1, 14, 1), { name = "CrusherRail", material = Enum.Material.Metal })
	L:Decor(V(width / 2 + 0.6, y + 7, z), V(1, 14, 1), { name = "CrusherRail", material = Enum.Material.Metal })
end

local function piston(L, y: number, z: number, side: number, phase: number)
	L:Mover(V(side * 11, y + 5, z), V(8, 5, 3), V(-side * 11, 0, 0), { kill = true, period = 4, pause = 0.8, phase = phase })
end

-- 81 · Crumble — orange platforms crack and fall after you land: keep moving.
Levels[81] = function(L)
	L:Sign(V(-4.5, 2, 5), "Orange platforms crack,\nthen fall. Keep moving.", { width = 6, height = 2.2 })
	for _, p in { V(0, 0, 12), V(0, 0, 19), V(0, 1, 26), V(0, 2, 33), V(0, 2, 40) } do
		L:Falling(p, V(5, 1, 5), { fallDelay = 0.8 })
	end
	L:Step(V(0, 2, 49), V(6, 1, 6))
	L:Exit(V(0, 2, 62))
end

-- 82 · Gust — a steady side wind over a narrow path.
Levels[82] = function(L)
	L:Sign(V(-4.5, 2, 5), "Wind pushes you.\nLean against it.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 16), V(4, 1, 18))
	L:Step(V(0, 0, 33), V(4, 1, 12))
	L:Step(V(0, 0, 47), V(4, 1, 12))
	L:Wind(V(0, 5, 31), V(24, 12, 46), V(5, 0, 0))
	L:Exit(V(0, 0, 63))
end

-- 83 · Seesaw — tilting platforms, each a quarter cycle behind the last.
Levels[83] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	for i, z in { 20, 29, 38, 47 } do
		L:Seesaw(V(0, 0, z), V(6, 1, 6), { axis = "X", amplitude = 12, period = 4, phase = (i - 1) * 0.25 })
	end
	L:Step(V(0, 0, 56), V(6, 1, 6))
	L:Exit(V(0, 0, 69))
end

-- 84 · Closing In — crushers drop from the ceiling in a wave.
Levels[84] = function(L)
	L:Step(V(0, 0, 30), V(6, 1, 46))
	for i, z in { 15, 26, 37, 48 } do
		crusher(L, 0, z, 6, (i - 1) * 0.25)
	end
	L:Exit(V(0, 0, 63))
end

-- 85 · Crumble Run — eight fast-falling platforms, weaving.
Levels[85] = function(L)
	local points = { V(0, 0, 11), V(2, 0, 17.5), V(-1, 1, 24), V(2, 1, 30.5), V(-2, 2, 37), V(1, 2, 43.5), V(-1, 3, 50), V(1, 3, 56.5) }
	for _, p in points do
		L:Falling(p, V(4, 1, 4), { fallDelay = 0.55 })
	end
	L:Step(V(0, 3, 65), V(6, 1, 6))
	L:Exit(V(0, 3, 78))
end

-- 86 · Headwind — every jump fights a wind blowing back at you.
Levels[86] = function(L)
	for i, z in { 12, 21, 30, 39, 48 } do
		L:Step(V(0, math.min(i - 1, 3), z), V(6, 1, 6))
	end
	L:Wind(V(0, 6, 30), V(20, 14, 44), V(0, 0, -5))
	L:Exit(V(0, 3, 60))
end

-- 87 · Drawbridge — cross while the bridges are down.
Levels[87] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Drawbridge(V(0, 0, 14), V(5, 1, 12), { period = 6 })
	L:Step(V(0, 0, 29), V(6, 1, 6))
	L:Drawbridge(V(0, 0, 32), V(5, 1, 12), { period = 6, phase = 0.5 })
	L:Step(V(0, 0, 47), V(6, 1, 6))
	L:Drawbridge(V(0, 0, 50), V(5, 1, 14), { period = 5 })
	L:Exit(V(0, 0, 71))
end

-- 88 · Collapse — a lava wall follows you over crumbling stones.
Levels[88] = function(L)
	L:Sign(V(-4.5, 2, 5), "Don't look back.", { width = 6, height = 2.2 })
	L:Chaser(V(0, 5, -12), V(16, 20, 2), V(0, 0, 70), 6, { delay = 3 })
	for _, p in { V(0, 0, 12), V(0, 1, 19), V(0, 1, 26), V(0, 2, 33), V(0, 2, 40), V(0, 3, 47) } do
		L:Falling(p, V(5, 1, 5), { fallDelay = 0.8 })
	end
	L:Step(V(0, 3, 56), V(6, 1, 6))
	L:Exit(V(0, 3, 70))
end

-- 89 · Tilt Maze — seesaws tilting on alternating axes over lava.
Levels[89] = function(L)
	L:Kill(V(0, -3, 30), V(18, 1, 46), { name = "LavaFloor" })
	local points = { { V(0, 0, 12), "X" }, { V(4, 0, 19), "Z" }, { V(0, 0, 26), "X" }, { V(-4, 0, 33), "Z" }, { V(0, 0, 40), "X" } }
	for i, p in points do
		L:Seesaw(p[1], V(5, 1, 5), { axis = p[2], amplitude = 10, period = 3.5, phase = i * 0.2 })
	end
	L:Step(V(0, 0, 50), V(6, 1, 6))
	L:Exit(V(0, 0, 63))
end

-- 90 · Storm Front — gusts every few seconds: rest on wide pads, cross beams in the calm.
Levels[90] = function(L)
	L:Step(V(0, 0, 12), V(12, 1, 6))
	L:Step(V(0, 0, 24), V(3, 1, 14))
	L:Step(V(0, 0, 38), V(12, 1, 8))
	L:Step(V(0, 0, 51), V(3, 1, 12))
	L:Step(V(0, 0, 63), V(12, 1, 6))
	L:Wind(V(0, 5, 38), V(40, 12, 60), V(8, 0, 0), { on = 1.5, off = 3, warn = 0.8 })
	L:Exit(V(0, 0, 76))
end

-- 91 · Rising Lava — climb a tower while lava rises from below.
Levels[91] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	local top = towerClimb(L, V(0, 2, 24), 12, 2)
	-- starts only once you are at the foot of the tower
	L:Chaser(V(0, -4, 24), V(30, 2, 30), V(0, 24, 0), 2.5, { delay = 3, startRadius = 14 })
	L:Exit(V(0, top, 37))
end

-- 92 · Shifting Floor — tiles slide sideways in a staggered wave.
Levels[92] = function(L)
	for i, z in { 12, 18, 24, 30, 36 } do
		L:Mover(V(-4, 0, z), V(4, 1, 4), V(8, 0, 0), { period = 4, pause = 0.6, phase = (i - 1) * 0.2 })
	end
	L:Step(V(0, 0, 45), V(6, 1, 6))
	L:Exit(V(0, 0, 58))
end

-- 93 · Crusher Hall — crushers from above, pistons from the sides.
Levels[93] = function(L)
	L:Step(V(0, 0, 30), V(8, 1, 46))
	crusher(L, 0, 14, 8, 0)
	piston(L, 0, 23, -1, 0.25)
	crusher(L, 0, 32, 8, 0.5)
	piston(L, 0, 41, 1, 0.75)
	L:Exit(V(0, 0, 63))
end

-- 94 · Falling Stair — a staircase that collapses under your feet.
Levels[94] = function(L)
	for i = 0, 7 do
		L:Falling(V(0, i * 1.5, 11 + i * 6), V(4, 1, 4), { fallDelay = 0.7 })
	end
	L:Step(V(0, 10.5, 64), V(6, 1, 6))
	L:Exit(V(0, 10.5, 77))
end

-- 95 · Wind Tunnel — ride ferries through a side wind.
Levels[95] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 18), V(6, 1, 6), V(0, 0, 14), { period = 6, pause = 1 })
	L:Step(V(0, 0, 42), V(6, 1, 6))
	L:Mover(V(0, 0, 52), V(6, 1, 6), V(0, 0, 14), { period = 6, pause = 1, phase = 0.5 })
	L:Step(V(0, 0, 76), V(6, 1, 6))
	L:Wind(V(0, 5, 44), V(30, 12, 70), V(4, 0, 0))
	L:Exit(V(0, 0, 89))
end

-- 96 · Toppling Pillars — stone pillars fall to form a bridge, then rise again.
Levels[96] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Drawbridge(V(0, 0, 14), V(4, 2, 14), { period = 7, material = STONE, color = Color3.fromRGB(150, 160, 150), name = "Pillar" })
	L:Step(V(0, 0, 31), V(6, 1, 6))
	L:Drawbridge(V(0, 0, 34), V(4, 2, 16), { period = 7, phase = 0.4, material = STONE, color = Color3.fromRGB(150, 160, 150), name = "Pillar" })
	L:Step(V(0, 0, 53), V(6, 1, 6))
	L:Exit(V(0, 0, 66))
end

-- 97 · Earthquake — very fast crumbling platforms among fallen rubble.
Levels[97] = function(L)
	local points = { V(0, 0, 11), V(-3, 0, 17), V(0, 1, 23), V(3, 1, 29), V(0, 2, 35), V(-3, 2, 41), V(0, 3, 47) }
	for _, p in points do
		L:Falling(p, V(4, 1, 4), { fallDelay = 0.45, respawn = 2.5 })
	end
	L:Step(V(0, 3, 56), V(6, 1, 6))
	for i = 1, 5 do
		L:Decor(V(L:Random(-14, 14), L:Random(-8, -2), 10 + i * 9), V(3, 3, 3) * L:Random(0.7, 1.4), { name = "Rubble", material = STONE, rot = V(L:Random(0, 90), L:Random(0, 90), 0) })
	end
	L:Exit(V(0, 3, 69))
end

-- 98 · Ruins Chase — the lava wall is back, over crumbling stones in the wind.
Levels[98] = function(L)
	L:Chaser(V(0, 5, -12), V(16, 20, 2), V(0, 0, 80), 6, { delay = 3 })
	for _, p in { V(0, 0, 12), V(2, 1, 19), V(-1, 1, 26), V(1, 2, 33), V(-1, 2, 40), V(0, 3, 47), V(0, 3, 54) } do
		L:Falling(p, V(5, 1, 5), { fallDelay = 0.7 })
	end
	L:Wind(V(0, 5, 30), V(24, 12, 30), V(3, 0, 0))
	L:Step(V(0, 3, 63), V(6, 1, 6))
	L:Exit(V(0, 3, 76))
end

-- 99 · Eye of the Storm — pre-final: crumble, seesaws, drawbridge, gust, crushers.
Levels[99] = function(L)
	for _, p in { V(0, 0, 12), V(0, 1, 19), V(0, 1, 26) } do
		L:Falling(p, V(5, 1, 5), { fallDelay = 0.7 })
	end
	L:Step(V(0, 1, 35), V(6, 1, 6))
	L:Seesaw(V(0, 1, 44), V(6, 1, 6), { axis = "X", amplitude = 12, period = 4 })
	L:Seesaw(V(0, 1, 53), V(6, 1, 6), { axis = "Z", amplitude = 12, period = 4, phase = 0.5 })
	L:Step(V(0, 1, 62), V(6, 1, 6))
	L:Drawbridge(V(0, 1, 65), V(5, 1, 12), { period = 6 })
	L:Step(V(0, 1, 80), V(12, 1, 6))
	L:Step(V(0, 1, 92), V(3, 1, 12))
	L:Wind(V(0, 6, 92), V(30, 12, 14), V(8, 0, 0), { on = 1.5, off = 3 })
	L:Step(V(0, 1, 110), V(6, 1, 20))
	crusher(L, 1, 105, 6, 0)
	crusher(L, 1, 114, 6, 0.5)
	L:Exit(V(0, 1, 129))
end

-- 100 · Halfway Point — FINAL STAGE (100/200): the ruins collapse around you.
Levels[100] = function(L)
	L:SectionLabel(V(-4, 1.5, 6.5), "I · CRUMBLE")
	for _, p in { V(0, 0, 12), V(2, 1, 19), V(-1, 1, 26), V(1, 2, 33) } do
		L:Falling(p, V(5, 1, 5), { fallDelay = 0.7 })
	end
	L:Step(V(0, 2, 42), V(12, 1, 6))
	-- II · storm beams
	L:Step(V(0, 2, 54), V(3, 1, 14))
	L:Step(V(0, 2, 68), V(12, 1, 8))
	L:Wind(V(0, 7, 58), V(40, 12, 26), V(8, 0, 0), { on = 1.5, off = 3 })
	-- III · tilt over lava
	L:Kill(V(0, -1, 88), V(18, 1, 26), { name = "LavaFloor" })
	for i, p in { { V(0, 2, 78), "X" }, { V(4, 2, 85), "Z" }, { V(0, 2, 92), "X" }, { V(-4, 2, 99), "Z" } } do
		L:Seesaw(p[1], V(5, 1, 5), { axis = p[2], amplitude = 10, period = 3.5, phase = i * 0.2 })
	end
	L:Step(V(0, 2, 108), V(6, 1, 6))
	-- IV · crushers
	L:Step(V(0, 2, 128), V(6, 1, 34))
	for i, z in { 118, 128, 138 } do
		crusher(L, 2, z, 6, (i - 1) / 3)
	end
	-- V · drawbridges
	L:Drawbridge(V(0, 2, 145), V(5, 1, 12), { period = 6 })
	L:Step(V(0, 2, 160), V(6, 1, 6))
	L:Drawbridge(V(0, 2, 163), V(4, 2, 14), { period = 7, phase = 0.5, material = STONE, color = Color3.fromRGB(150, 160, 150), name = "Pillar" })
	L:Step(V(0, 2, 180), V(6, 1, 6))
	-- VI · rising lava tower
	L:SectionLabel(V(0, 4, 182.5), "VI · RISING LAVA")
	local top = towerClimb(L, V(0, 4, 195), 10, 2)
	L:Chaser(V(0, -2, 195), V(30, 2, 30), V(0, 24, 0), 2.5, { delay = 3, startRadius = 16 })
	-- VII · collapse run to the halfway gate
	L:Step(V(0, top, 203), V(8, 1, 8))
	L:SectionLabel(V(0, top + 2, 206), "VII · RUN")
	L:Chaser(V(0, top + 5, 184), V(16, 20, 2), V(0, 0, 90), 6, { delay = 2, startRadius = 22 })
	for i = 1, 6 do
		L:Falling(V(if i % 2 == 0 then 1 else -1, top, 203 + i * 8), V(5, 1, 5), { fallDelay = 0.8 })
	end
	L:Step(V(0, top, 262), V(10, 1, 6))
	L:Arch(V(0, top, 261), 9, "100 / 200", Color3.fromRGB(255, 200, 90), "HALFWAY")
	L.Theme.scenery(L, V(-45, 5, 110), 1.4)
	L.Theme.scenery(L, V(45, 10, 220), 1.2)
	L:Exit(V(0, top, 275))
end

return Levels
