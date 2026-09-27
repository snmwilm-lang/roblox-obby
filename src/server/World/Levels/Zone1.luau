--[[
	ZONE 1 — INTRODUCTION — Verdant Plateau (levels 1-20)

	Movement reference (Config.Character: WalkSpeed 16, JumpPower 50):
	  flat jump ≈ 8 studs of travel, max rise ≈ 6.3 studs.
	Zone 1 budget: gaps ≤ 4.5 (≤ 4 in levels 1-5), rises ≤ 2, platforms ≥ 3 wide
	(1.5 only in level 15). Nothing requires shift-lock or a camera trick, so
	every jump is comfortable on a touchscreen.

	Conventions: see World/LevelBuilder (Step/Mover/Ghost... pos = TOP-CENTRE,
	Kill/Wall... pos = CENTRE). The start pad occupies z = -7..7 (14 x 14).
	Limbo bars sit 6.3+ studs above the floor: walking under is always safe,
	any jump touches them.
]]

local V = Vector3.new

local Levels = {}

-- 1 · First Steps — huge platforms, 2-3 stud gaps. Also hosts the spawn hub.
Levels[1] = function(L)
	-- Hub behind the start pad (spawn area, leaderboards)
	L:Pad(V(0, 0, -25), V(40, 2, 36), { name = "Hub" })
	L:Decor(V(0, -6, -25), V(34, 8, 30), { name = "HubRock", material = Enum.Material.Rock })
	L:Sign(V(0, 7, -41), "200 LEVELS\nDIFFICULTY OBBY", { width = 20, height = 6, groundY = 0, yaw = 180 })

	local boards = {
		{ "HighestLevel", V(-19.5, 5.5, -32), -90 },
		{ "Completions", V(-19.5, 5.5, -17), -90 },
		{ "BestFullRun", V(19.5, 5.5, -32), 90 },
		{ "Deaths", V(19.5, 5.5, -17), 90 },
	}
	for _, b in boards do
		local board = L:Wall(b[2], V(12, 9, 0.6), { rot = V(0, b[3], 0), name = "Leaderboard_" .. b[1] })
		board:SetAttribute("Board", b[1])
		board:AddTag("LeaderboardBoard")
	end

	local spawn = L:_part({
		ClassName = "SpawnLocation",
		Name = "FallbackSpawn",
		Size = V(6, 1, 6),
		CFrame = L:ToWorld(V(0, -0.45, 0)),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
	})
	spawn.Neutral = true
	spawn.Duration = 0

	L.Theme.scenery(L, V(-55, -8, -10), 1)
	L.Theme.scenery(L, V(60, 4, 30), 0.8)

	-- Course
	L:Sign(V(-4.5, 2, 5), "Reach the glowing pad.\nRed kills. Yellow moves.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 13), V(10, 2, 8))
	L:Step(V(0, 0, 24), V(10, 2, 8))
	L:Step(V(0, 1, 35), V(10, 2, 8))
	L:Exit(V(0, 1, 49))
end

-- 2 · Stairway — rising steps, one stud of air between them.
Levels[2] = function(L)
	L:Sign(V(-4.5, 2, 5), "Hold forward and jump\nto climb", { width = 6, height = 2.2 })
	L:Step(V(0, 1, 11), V(8, 2, 6))
	L:Step(V(0, 3, 18), V(8, 2, 6))
	L:Step(V(0, 5, 25), V(8, 2, 6))
	L:Step(V(0, 7, 33), V(8, 2, 6))
	L:Step(V(0, 9, 41), V(8, 2, 6))
	L:Step(V(0, 9, 50), V(8, 2, 8))
	L.Theme.scenery(L, V(45, -5, 30), 0.7)
	L:Exit(V(0, 9, 63))
end

-- 3 · Red Means No — lava bands flush with the floor, 2 -> 3 -> 4 studs, then a hurdle.
Levels[3] = function(L)
	L:Sign(V(-4.5, 2, 5), "RED = DANGER\nNever touch it", { width = 6, height = 2.2, color = Color3.fromRGB(255, 120, 110) })
	L:Step(V(0, 0, 12), V(12, 2, 10))
	L:Kill(V(0, -0.45, 18), V(12, 1, 2))
	L:Step(V(0, 0, 23), V(12, 2, 8))
	L:Kill(V(0, -0.45, 28.5), V(12, 1, 3))
	L:Step(V(0, 0, 34), V(12, 2, 8))
	L:Kill(V(0, -0.45, 40), V(12, 1, 4))
	L:Step(V(0, 0, 47), V(12, 2, 10))
	L:Kill(V(0, 0.5, 47), V(12, 1, 1), { name = "Hurdle" })
	L:Exit(V(0, 0, 63))
end

-- 4 · Stepping Stones — 4x4 stones zig-zagging and slowly rising: aim sideways.
Levels[4] = function(L)
	L:Step(V(-3, 0, 12), V(4, 1, 4))
	L:Step(V(3, 0, 19), V(4, 1, 4))
	L:Step(V(-2, 1, 26), V(4, 1, 4))
	L:Step(V(3, 1, 33), V(4, 1, 4))
	L:Step(V(-1, 2, 40), V(4, 1, 4))
	L:Step(V(2, 2, 47), V(5, 1, 5))
	L.Theme.scenery(L, V(-45, -12, 25), 0.9)
	L:Exit(V(0, 2, 60))
end

-- 5 · The Walkway — 3-stud beam with an L-turn and small kill hurdles.
Levels[5] = function(L)
	L:Step(V(0, 0, 20), V(3, 1, 26))
	L:Kill(V(0, 0.5, 15), V(3, 1, 1), { name = "Hurdle" })
	L:Kill(V(0, 0.5, 24), V(3, 1, 1), { name = "Hurdle" })
	L:Step(V(8, 0, 31.5), V(13, 1, 3))
	L:Step(V(13, 0, 44), V(3, 1, 22))
	L:Kill(V(13, 0.5, 44), V(3, 1, 1), { name = "Hurdle" })
	L:Exit(V(13, 0, 65))
end

-- 6 · Moving Along — two slow ferries. First contact with "yellow = moves".
Levels[6] = function(L)
	L:Sign(V(-4.5, 2, 5), "Yellow platforms move.\nWait - ride - hop off", { width = 6, height = 2.2 })
	L:Mover(V(0, 0, 12), V(8, 1, 8), V(0, 0, 22), { period = 10, pause = 1.5 })
	L:Step(V(0, 0, 43), V(10, 2, 8))
	L:Mover(V(0, 0, 52), V(8, 1, 8), V(0, 0, 18), { period = 9, pause = 1.5, phase = 0.5 })
	L.Theme.scenery(L, V(50, -10, 40), 1)
	L:Exit(V(0, 0, 82))
end

-- 7 · Pillar Hop — cylinder tops (round edges) while climbing.
Levels[7] = function(L)
	local pillars = {
		{ V(0, 0, 11), 4 },
		{ V(0, 1, 18), 4 },
		{ V(4, 2, 24), 4 },
		{ V(0, 3, 31), 4 },
		{ V(-4, 3, 38), 4 },
		{ V(0, 4, 45), 4 },
		{ V(0, 4, 52), 5 },
	}
	for _, p in pillars do
		L:Step(p[1], V(p[2], 30, p[2]), { shape = "Cylinder", material = Enum.Material.Slate, color = L.Zone.Structure.Color:Lerp(L.Zone.Safe.Color, 0.5) })
	end
	L:Exit(V(0, 4, 65))
end

-- 8 · Lava Floor — read a winding path of tiles across a lava room.
Levels[8] = function(L)
	L:Kill(V(0, -0.5, 30), V(20, 1, 46), { name = "LavaFloor" })
	local tiles = {
		V(-3, 0.8, 11),
		V(3, 0.8, 16),
		V(5, 0.8, 23),
		V(0, 0.8, 28),
		V(-5, 0.8, 33),
		V(-3, 0.8, 40),
		V(2, 0.8, 45),
		V(0, 0.8, 51),
	}
	for _, t in tiles do
		L:Step(t, V(4, 1, 4))
	end
	-- Rim of the pit (decor, below route height so it cannot be used as a shortcut)
	L:Decor(V(-10.75, -1, 30), V(1.5, 3, 46), { name = "PitRim" })
	L:Decor(V(10.75, -1, 30), V(1.5, 3, 46), { name = "PitRim" })
	L:Exit(V(0, 0, 63))
end

-- 9 · Elevator — lift up, then cross two ferries moving in opposite directions.
Levels[9] = function(L)
	L:Step(V(0, 0, 12), V(8, 2, 8))
	L:Mover(V(0, 0, 22), V(8, 1, 8), V(0, 14, 0), { period = 8, pause = 1.5 })
	L:Step(V(0, 14, 32), V(8, 2, 6))
	L:Mover(V(-6, 14, 41), V(6, 1, 6), V(12, 0, 0), { period = 6, pause = 0.8 })
	L:Mover(V(6, 14, 50), V(6, 1, 6), V(-12, 0, 0), { period = 6, pause = 0.8 })
	L:Decor(V(0, 5, 32), V(6, 16, 4), { name = "Cliff", material = Enum.Material.Rock })
	L:Exit(V(0, 14, 64))
end

-- 10 · First Wraparound — jump off the side, around the wall's edge, land behind it.
Levels[10] = function(L)
	L:Sign(V(-4.5, 2, 5), "Jump AROUND the wall edge.\nShift lock helps (Shift).", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 16), V(6, 1, 18), { keepSize = true })
	L:Wrap(0, 25.5, 6, { overhang = 0.5, side = 1 })
	L:Step(V(0, 0, 36), V(6, 1, 20), { keepSize = true })
	L:Wrap(0, 46.5, 6, { overhang = 1, side = -1 })
	L:Step(V(0, 0, 54), V(6, 1, 14), { keepSize = true })
	L:Exit(V(0, 0, 71))
end

-- 11 · The Sweeper — a slow low bar sweeps a disc: jump it or wait for it.
Levels[11] = function(L)
	L:Step(V(0, 0, 11), V(4, 1, 8))
	L:Step(V(0, 0, 27), V(22, 1, 22), { shape = "Cylinder" })
	L:Spinner(V(0, 1.6, 27), { length = 10.5, arms = 1, speed = 45, floorY = 0 })
	L:Step(V(0, 0, 43), V(4, 1, 8))
	L.Theme.scenery(L, V(-50, -6, 30), 1.1)
	L:Exit(V(0, 0, 56))
end

-- 12 · Don't Jump — limbo bars (walk under) alternating with hurdles (jump over).
Levels[12] = function(L)
	L:Sign(V(-4.5, 2, 5), "Sometimes the best jump\nis no jump.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 30), V(8, 1, 46))
	for _, z in { 14, 30, 46 } do
		L:Kill(V(0, 6.8, z), V(8, 1, 1), { name = "LimboBar" })
		-- posts make the bar read as an obstacle you pass under
		L:Decor(V(-4.5, 3.4, z), V(0.8, 6.8, 0.8), { name = "LimboPost" })
		L:Decor(V(4.5, 3.4, z), V(0.8, 6.8, 0.8), { name = "LimboPost" })
	end
	for _, z in { 22, 38 } do
		L:Kill(V(0, 0.5, z), V(8, 1, 1), { name = "Hurdle" })
	end
	L:Exit(V(0, 0, 60))
end

-- 13 · Ferry Line — three ferries that meet at the ends of their runs.
Levels[13] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	-- F1 and F3 share a phase; F2 is half a cycle later so each pair meets while paused.
	L:Mover(V(-7, 0, 20), V(5, 1, 5), V(14, 0, 0), { period = 5, pause = 0.7, phase = 0 })
	L:Mover(V(7, 0, 27), V(5, 1, 5), V(-14, 0, 0), { period = 5, pause = 0.7, phase = 0.5 })
	L:Mover(V(-7, 0, 34), V(5, 1, 5), V(14, 0, 0), { period = 5, pause = 0.7, phase = 0 })
	L:Step(V(0, 0, 42), V(20, 1, 6))
	L:Exit(V(0, 0, 54))
end

-- 14 · Twin Sweepers — a low bar (jumpable) then a tall blade (must be timed).
Levels[14] = function(L)
	L:Sign(V(-4.5, 2, 5), "Watch the cycle\nbefore you move.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 26), V(4, 1, 38))
	L:Spinner(V(7, 1.6, 16), { length = 11, arms = 1, speed = 60, floorY = -8 })
	L:Spinner(V(-7, 2.5, 33), { length = 11, arms = 1, speed = -45, bladeHeight = 4, floorY = -8 })
	L:Exit(V(0, 0, 54))
end

-- 15 · Tightrope — 1.5-stud beams, rising, with a 90° turn.
Levels[15] = function(L)
	L:Step(V(0, 0, 15), V(1.5, 1, 16))
	L:Step(V(0, 1, 29.5), V(1.5, 1, 10))
	L:Step(V(6, 2, 36), V(10, 1, 1.5))
	L:Step(V(12.5, 3, 43), V(1.5, 1, 10))
	L:Step(V(12.5, 4, 56), V(1.5, 1, 12))
	L.Theme.scenery(L, V(-35, -15, 40), 1)
	L:Exit(V(12.5, 4, 71))
end

-- 16 · Wraparound Ridge — three wraps, alternating sides, each a bit longer.
Levels[16] = function(L)
	L:Step(V(0, 0, 13), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 19.5, 4, { overhang = 1, side = 1 })
	L:Step(V(0, 0, 26), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 32.5, 4, { overhang = 1.5, side = -1 })
	L:Step(V(0, 0, 39), V(4, 1, 12), { keepSize = true })
	L:Wrap(0, 45.5, 4, { overhang = 1.5, side = 1 })
	L:Step(V(0, 0, 52), V(4, 1, 12), { keepSize = true })
	L:Exit(V(0, 0, 68))
end

-- 17 · Piston Alley — four pistons firing in a wave: read the rhythm, walk through.
Levels[17] = function(L)
	L:Step(V(0, 0, 30), V(10, 1, 46))
	local pistons = {
		{ 15, -1, 0 },
		{ 24, 1, 0.25 },
		{ 33, -1, 0.5 },
		{ 42, 1, 0.75 },
	}
	for _, p in pistons do
		local side = p[2]
		L:Mover(V(side * 11, 5, p[1]), V(10, 5, 3), V(-side * 11, 0, 0), { kill = true, period = 4, pause = 0.8, phase = p[3] })
		-- housing the piston retracts into (decor, off-route)
		L:Decor(V(side * 12, 2.5, p[1]), V(10, 6, 4.5), { name = "PistonHousing", transparency = 0.6 })
	end
	L:Exit(V(0, 0, 63))
end

-- 18 · Sky Circuit — jump a sweeper while riding a ferry, then stones.
Levels[18] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 20), V(6, 1, 6), V(0, 0, 18), { period = 8, pause = 1 })
	L:Spinner(V(8, 2, 29), { length = 12, arms = 1, speed = 50, floorY = -10 })
	L:Step(V(0, 1, 46), V(6, 1, 6))
	L:Step(V(4, 2, 54), V(4, 1, 4))
	L:Step(V(-1, 3, 61), V(4, 1, 4))
	L:Step(V(0, 3, 69), V(6, 1, 6))
	L:Kill(V(0, 3.5, 69), V(2, 1, 2), { name = "Stud" })
	L:Exit(V(0, 3, 82))
end

-- 19 · The Threshold — pre-final review. Leads straight into 20 with no checkpoint.
Levels[19] = function(L)
	L:Step(V(-3, 0, 12), V(4, 1, 4))
	L:Step(V(3, 1, 19), V(4, 1, 4))
	L:Step(V(-2, 2, 26), V(4, 1, 4))
	L:Step(V(0, 2, 33), V(4, 1, 4), { shape = "Cylinder" })
	L:Mover(V(0, 2, 42), V(5, 1, 5), V(0, 0, 16), { period = 6, pause = 0.8 })
	L:Step(V(0, 2, 72), V(4, 1, 20))
	L:Spinner(V(7, 3.6, 72), { length = 11, arms = 1, speed = 70, floorY = -6 })
	L:Step(V(0, 2, 90), V(4, 1, 16))
	L:Kill(V(0, 2.5, 87), V(4, 1, 1), { name = "Hurdle" })
	L:Kill(V(0, 2.5, 94), V(4, 1, 1), { name = "Hurdle" })
	L.Theme.scenery(L, V(45, -8, 60), 1.2)
	L:Exit(V(0, 2, 108))
end

-- 20 · Verdant Trial — FINAL STAGE (~4x a normal level). Seven sections, each an
-- exam of a Zone 1 lesson, ending with a climb to the Zone 2 gate.
Levels[20] = function(L)
	-- I · Stones & hurdles
	L:SectionLabel(V(-4, 1.5, 6.5), "I · STONES")
	L:Step(V(0, 0, 12), V(4, 1, 4))
	L:Step(V(4, 1, 19), V(4, 1, 4), { shape = "Cylinder" })
	L:Step(V(0, 2, 26), V(4, 1, 4))
	L:Step(V(-4, 2, 33), V(4, 1, 4))
	L:Step(V(0, 2, 44), V(4, 1, 14), { keepSize = true })
	L:Kill(V(0, 2.5, 41), V(4, 1, 1), { name = "Hurdle" })
	L:Kill(V(0, 2.5, 47), V(4, 1, 1), { name = "Hurdle" })

	-- II · Wraparound
	L:Wrap(2, 51.5, 4, { overhang = 1.5, side = 1 })
	L:Step(V(0, 2, 59.5), V(4, 1, 15), { keepSize = true })
	L:SectionLabel(V(-3, 3.5, 56), "II · AROUND")

	-- III · Ferries (diagonal lift, then a lateral ferry)
	L:Mover(V(0, 2, 72), V(5, 1, 5), V(0, 4, 10), { period = 5, pause = 0.8 })
	L:Mover(V(-6, 6, 90), V(5, 1, 5), V(12, 0, 0), { period = 5, pause = 0.7 })
	L:Step(V(0, 6, 99), V(8, 1, 6))
	L:SectionLabel(V(0, 8, 101.5), "IV · SWEEPERS")

	-- IV · Sweepers (double bar on a disc, then a tall blade over a bridge)
	L:Step(V(0, 6, 114), V(20, 1, 20), { shape = "Cylinder" })
	L:Spinner(V(0, 7.6, 114), { length = 9.5, arms = 2, speed = 55 })
	L:Step(V(0, 6, 131), V(4, 1, 12))
	L:Spinner(V(-7, 8.5, 131), { length = 11, arms = 1, speed = 45, bladeHeight = 4, floorY = -2 })

	-- V · Lava tiles, then limbo / hurdle / limbo
	L:Step(V(0, 6, 141), V(8, 1, 6))
	L:SectionLabel(V(0, 8, 143.5), "V · LAVA")
	L:Kill(V(0, 5.5, 159.75), V(14, 1, 30.5), { name = "LavaFloor" })
	for _, t in { V(-3, 6.8, 148), V(2, 6.8, 153), V(4, 6.8, 159), V(-1, 6.8, 164), V(-4, 6.8, 170) } do
		L:Step(t, V(3, 1, 3))
	end
	L:Step(V(0, 6, 186), V(6, 1, 26))
	for _, z in { 181, 197 } do
		L:Kill(V(0, 12.8, z), V(6, 1, 1), { name = "LimboBar" })
		L:Decor(V(-3.5, 9.4, z), V(0.8, 6.8, 0.8), { name = "LimboPost" })
		L:Decor(V(3.5, 9.4, z), V(0.8, 6.8, 0.8), { name = "LimboPost" })
	end
	L:Kill(V(0, 6.5, 189), V(6, 1, 1), { name = "Hurdle" })

	-- VI · Piston alley
	L:Step(V(0, 6, 218), V(10, 1, 38))
	for i, p in { { 207, -1 }, { 217, 1 }, { 227, -1 } } do
		L:Mover(V(p[2] * 11, 11, p[1]), V(10, 5, 3), V(-p[2] * 11, 0, 0), { kill = true, period = 4, pause = 0.8, phase = (i - 1) / 3 })
		L:Decor(V(p[2] * 12, 8.5, p[1]), V(10, 6, 4.5), { name = "PistonHousing", transparency = 0.6 })
	end

	-- VII · Final climb to the Zone 2 gate
	L:Mover(V(0, 6, 242), V(6, 1, 6), V(0, 12, 0), { period = 7, pause = 1.2 })
	L:Step(V(0, 18, 250.5), V(6, 1, 6))
	L:SectionLabel(V(0, 20, 253), "VII · ASCENT")
	L:Step(V(-3, 20, 257.5), V(4, 1, 4), { shape = "Cylinder" })
	L:Step(V(2, 22, 263.5), V(4, 1, 4), { shape = "Cylinder" })
	L:Step(V(0, 24, 270), V(4, 1, 4))
	L.Theme.scenery(L, V(-50, 10, 120), 1.4)
	L.Theme.scenery(L, V(55, 0, 200), 1.2)
	L:Exit(V(0, 24, 282))
end

return Levels
