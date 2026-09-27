--[[
	ZONE 2 — TIMING — Clockwork Foundry (levels 21-40)

	Lesson: watch one cycle, then move. Everything here is periodic and
	deterministic (server clock): ghost platforms, timed doors, laser gates,
	pendulums, sweeping blades, circling ferries.
	Budget: jumps ≤ 70 % of the maximum; every rhythm is checked by the route
	simulator in tests/run.luau (a timing must exist that chains the route).
]]

local V = Vector3.new

local Levels = {}

-- Corridor with side walls so doors / lasers cannot be walked around.
local function corridor(L, y: number, z0: number, z1: number, width: number?)
	local w = width or 8
	local length = z1 - z0
	L:Step(V(0, y, (z0 + z1) / 2), V(w, 1, length))
	L:Wall(V(-w / 2 - 0.5, y + 4.5, (z0 + z1) / 2), V(1, 9, length), { name = "CorridorWall" })
	L:Wall(V(w / 2 + 0.5, y + 4.5, (z0 + z1) / 2), V(1, 9, length), { name = "CorridorWall" })
end

local function laserGate(L, y: number, z: number, width: number, opts)
	L:Laser(V(0, y + 3.5, z), V(width, 7, 0.3), opts)
	L:Decor(V(-width / 2 - 0.4, y + 3.6, z), V(0.8, 7.2, 0.8), { name = "Emitter", material = Enum.Material.Metal })
	L:Decor(V(width / 2 + 0.4, y + 3.6, z), V(0.8, 7.2, 0.8), { name = "Emitter", material = Enum.Material.Metal })
end

local function door(L, y: number, z: number, width: number, opts)
	L:Door(V(0, y + 4, z), V(width, 8, 1), V(0, 8.5, 0), opts)
end

-- 21 · Now You See It — alternating ghosts, then a sequential wave.
Levels[21] = function(L)
	L:Sign(V(-4.5, 2, 5), "Cyan platforms phase out.\nThey blink before vanishing.", { width = 6, height = 2.2 })
	L:Ghost(V(0, 0, 12), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0 })
	L:Ghost(V(0, 0, 21), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0.5 })
	L:Ghost(V(0, 0, 30), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0 })
	L:Step(V(0, 0, 40), V(8, 1, 8))
	L:Ghost(V(0, 1, 50), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 0 })
	L:Ghost(V(0, 2, 58), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 1 / 3 })
	L:Ghost(V(0, 3, 66), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 2 / 3 })
	L.Theme.scenery(L, V(-30, 4, 40), 0.8)
	L:Exit(V(0, 3, 77))
end

-- 22 · Clockwork Doors — three doors opening in a wave down a corridor.
Levels[22] = function(L)
	L:Sign(V(-4.5, 2, 5), "Yellow doors open\non a rhythm.", { width = 6, height = 2.2 })
	corridor(L, 0, 7, 53)
	for i, z in { 16, 28, 40 } do
		door(L, 0, z, 8, { period = 4, pause = 1.2, phase = (i - 1) * 0.25 })
	end
	L:Exit(V(0, 0, 63))
end

-- 23 · Metronome — four laser gates, each a quarter cycle after the previous one.
Levels[23] = function(L)
	L:Sign(V(-4.5, 2, 5), "Lasers hum before firing.\nCross while they are off.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 30), V(8, 1, 46))
	for i, z in { 15, 24, 33, 42 } do
		laserGate(L, 0, z, 8, { on = 1.5, off = 2, phase = (i - 1) * 0.25 })
	end
	L:Exit(V(0, 0, 63))
end

-- 24 · Tick-Tock Path — follow the wave: each ghost appears a quarter cycle later.
Levels[24] = function(L)
	for i, z in { 12, 20, 28, 36 } do
		L:Ghost(V(0, 0, z), V(5, 1, 5), { visible = 2.6, invisible = 1.4, phase = (i - 1) * 0.25 })
	end
	L:Step(V(0, 0, 46), V(8, 1, 8))
	for i, z in { 56, 64, 72 } do
		L:Ghost(V(0, i, z), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = (i - 1) / 3 })
	end
	L:Exit(V(0, 3, 84))
end

-- 25 · Laser Turnstile — a tall blade sweeps a disc: time your crossing.
Levels[25] = function(L)
	L:Step(V(0, 0, 11), V(4, 1, 8))
	L:Step(V(0, 0, 28), V(24, 1, 24), { shape = "Cylinder" })
	L:Spinner(V(0, 2.5, 28), { length = 11.5, arms = 1, speed = 30, bladeHeight = 4.5, floorY = 0 })
	L:Step(V(0, 0, 45), V(4, 1, 8))
	L.Theme.scenery(L, V(40, -6, 30), 0.9)
	L:Exit(V(0, 0, 58))
end

-- 26 · Door & Ferry — the door opens exactly when the ferry arrives.
Levels[26] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 20), V(6, 1, 6), V(0, 0, 16), { period = 6, pause = 1.2 })
	L:Step(V(0, 0, 44), V(8, 1, 8))
	door(L, 0, 49.5, 8, { period = 6, pause = 1.4, phase = 0 })
	L:Wall(V(-6, 4.5, 49.5), V(4, 9, 1), { name = "DoorWing" })
	L:Wall(V(6, 4.5, 49.5), V(4, 9, 1), { name = "DoorWing" })
	L:Step(V(0, 0, 58), V(8, 1, 16))
	L:Exit(V(0, 0, 76))
end

-- 27 · Half Beat — shorter windows on a ghost zig-zag.
Levels[27] = function(L)
	for i, p in { V(-2, 0, 11), V(2, 0, 18), V(-2, 0, 25), V(2, 0, 32), V(-2, 0, 39) } do
		L:Ghost(p, V(4, 1, 4), { visible = 2.2, invisible = 0.8, phase = if i % 2 == 0 then 0.5 else 0 })
	end
	L:Step(V(0, 0, 48), V(6, 1, 6))
	L:Exit(V(0, 0, 61))
end

-- 28 · Gearworks — ride rotating crosses; hop when two arms line up.
Levels[28] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	for i, z in { 23, 38, 53 } do
		L:Rotor(V(0, 0, z), { length = 12, width = 3, speed = if i == 2 then -30 else 30 })
		L:Decor(V(0, -8, z), V(2, 16, 2), { name = "Axle", shape = "Cylinder", material = Enum.Material.Metal })
	end
	L:Step(V(0, 0, 65), V(6, 1, 6))
	L:Exit(V(0, 0, 78))
end

-- 29 · Crossfire — laser pairs in opposite phase: wait in the pocket between them.
Levels[29] = function(L)
	L:Step(V(0, 0, 30), V(8, 1, 46))
	for _, pair in { { 15, 20, 1.5 }, { 30, 35, 1.5 }, { 44, 48, 1.2 } } do
		laserGate(L, 0, pair[1], 8, { on = pair[3], off = pair[3], phase = 0 })
		laserGate(L, 0, pair[2], 8, { on = pair[3], off = pair[3], phase = 0.5 })
	end
	L:Exit(V(0, 0, 63))
end

-- 30 · Syncopation — two ghost rows on the off-beat of each other.
Levels[30] = function(L)
	local zs = { 11, 15, 19, 23, 27, 31, 35, 39 }
	for i, z in zs do
		local left = i % 2 == 1
		L:Ghost(V(if left then -3 else 3, 0, z), V(4, 1, 4), { visible = 2.4, invisible = 1.2, phase = if left then 0 else 0.5 })
	end
	L:Exit(V(0, 0, 50))
end

-- 31 · Pendulum Hall — four axes swinging across a corridor, staggered.
Levels[31] = function(L)
	L:Step(V(0, 0, 30), V(6, 1, 46))
	for i, z in { 14, 23, 32, 41 } do
		L:Pendulum(V(0, 12, z), 10.5, { axis = "Z", amplitude = 55, period = 3, phase = (i - 1) * 0.25 })
	end
	L:Exit(V(0, 0, 63))
end

-- 32 · Sweep Stair — climb while a tall blade sweeps every step.
Levels[32] = function(L)
	for i, z in { 12, 19, 26, 33, 40 } do
		L:Step(V(0, i * 1.5 - 0.5, z), V(6, 1, 4))
	end
	L:Spinner(V(9, 5, 26), { length = 14, arms = 1, speed = 30, bladeHeight = 10, floorY = -10 })
	L:Step(V(0, 7, 50), V(8, 1, 6))
	L:Exit(V(0, 7, 63))
end

-- 33 · Countdown Bridge — long ghost bridges: start walking the moment they appear.
Levels[33] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Ghost(V(0, 0, 31), V(4, 1, 30), { visible = 3.2, invisible = 2.4 })
	L:Step(V(0, 0, 51), V(6, 1, 6))
	L:Ghost(V(0, 1, 65), V(4, 1, 16), { visible = 2, invisible = 2, phase = 0.3 })
	L:Exit(V(0, 1, 82))
end

-- 34 · Shutters — door then laser: the laser switches off as the door opens.
Levels[34] = function(L)
	corridor(L, 0, 7, 53)
	door(L, 0, 15, 8, { period = 5, pause = 1.5, phase = 0 })
	laserGate(L, 0, 23, 8, { on = 1.5, off = 3.5, phase = 0 })
	door(L, 0, 33, 8, { period = 5, pause = 1.5, phase = 0.5 })
	laserGate(L, 0, 41, 8, { on = 1.5, off = 3.5, phase = 0.5 })
	L:Exit(V(0, 0, 63))
end

-- 35 · Clock Face — an hour hand you can jump, a minute hand you must dodge.
Levels[35] = function(L)
	L:Step(V(0, 0, 11), V(4, 1, 8))
	L:Step(V(0, 0, 30), V(30, 1, 30), { shape = "Cylinder" })
	L:Spinner(V(0, 1.6, 30), { length = 8, arms = 1, speed = 20, floorY = 0 })
	L:Spinner(V(0, 3.2, 30), { length = 14, arms = 1, speed = -50, floorY = 0, hubRadius = 1 })
	for i = 0, 11 do
		local a = math.rad(i * 30)
		L:Decor(V(math.sin(a) * 14, 0.1, 30 + math.cos(a) * 14), V(0.6, 0.2, 1.6), { name = "Tick", rot = V(0, i * 30, 0), color = Color3.fromRGB(255, 220, 150), material = Enum.Material.Neon })
	end
	L:Step(V(0, 0, 49), V(4, 1, 8))
	L:Exit(V(0, 0, 62))
end

-- 36 · Staccato — electrified floor strips pulse in alternation.
Levels[36] = function(L)
	L:Step(V(0, 0, 30), V(8, 1, 46))
	for i, z in { 13, 21, 29, 37, 45 } do
		L:Laser(V(0, 0.15, z), V(8, 0.3, 4), { on = 1.2, off = 1.8, warn = 0.5, phase = if i % 2 == 0 then 0.5 else 0 })
	end
	L:Exit(V(0, 0, 63))
end

-- 37 · Assembly Line — two ferries orbiting in circles, half a turn apart.
Levels[37] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 18), V(5, 1, 5), V(0, 0, 12), { loop = "Circle", period = 8 })
	L:Mover(V(0, 0, 34), V(5, 1, 5), V(0, 0, 12), { loop = "Circle", period = 8, phase = 0.5 })
	L:Step(V(0, 0, 52), V(6, 1, 6))
	L:Exit(V(0, 0, 65))
end

-- 38 · Polyrhythm — back-to-back gates on 3 s and 4 s cycles: wait for both.
Levels[38] = function(L)
	L:Step(V(0, 0, 30), V(8, 1, 46))
	laserGate(L, 0, 20, 8, { on = 1, off = 2, phase = 0 })
	laserGate(L, 0, 21.5, 8, { on = 1.5, off = 2.5, phase = 0 })
	laserGate(L, 0, 38, 8, { on = 1.2, off = 1.8, phase = 0 })
	laserGate(L, 0, 39.5, 8, { on = 0.8, off = 2.2, phase = 0.3 })
	L:Exit(V(0, 0, 63))
end

-- 39 · The Escapement — pre-final: ghosts, door, pendulum, laser, lift.
Levels[39] = function(L)
	L:Ghost(V(0, 0, 12), V(5, 1, 5), { visible = 2.5, invisible = 1.5, phase = 0 })
	L:Ghost(V(0, 0, 20), V(5, 1, 5), { visible = 2.5, invisible = 1.5, phase = 0.5 })
	L:Step(V(0, 0, 30), V(8, 1, 8))
	corridor(L, 0, 34, 62)
	door(L, 0, 40, 8, { period = 4, pause = 1.2 })
	L:Pendulum(V(0, 12, 50), 10.5, { axis = "Z", amplitude = 55, period = 3 })
	laserGate(L, 0, 58, 8, { on = 1.5, off = 2 })
	L:Mover(V(0, 0, 67), V(6, 1, 6), V(0, 4, 14), { period = 6, pause = 1 })
	L:Step(V(0, 4, 90), V(6, 1, 6))
	L:Exit(V(0, 4, 104))
end

-- 40 · Grand Clockwork — FINAL STAGE: seven timing sections, ending on a rising ghost wave.
Levels[40] = function(L)
	-- I · wave
	L:SectionLabel(V(-4, 1.5, 6.5), "I · WAVE")
	for i, z in { 12, 20, 28, 36 } do
		L:Ghost(V(0, 0, z), V(5, 1, 5), { visible = 2.6, invisible = 1.4, phase = (i - 1) * 0.25 })
	end
	L:Step(V(0, 0, 46), V(8, 1, 8))
	-- II · doors
	corridor(L, 0, 50, 86)
	for i, z in { 58, 68, 78 } do
		door(L, 0, z, 8, { period = 4, pause = 1.2, phase = (i - 1) * 0.25 })
	end
	-- III · crossfire
	corridor(L, 0, 86, 114)
	laserGate(L, 0, 94, 8, { on = 1.5, off = 1.5, phase = 0 })
	laserGate(L, 0, 99, 8, { on = 1.5, off = 1.5, phase = 0.5 })
	laserGate(L, 0, 107, 8, { on = 1.2, off = 1.2, phase = 0 })
	laserGate(L, 0, 111, 8, { on = 1.2, off = 1.2, phase = 0.5 })
	-- IV · pendulums
	L:Step(V(0, 0, 130), V(6, 1, 32))
	for i, z in { 120, 130, 140 } do
		L:Pendulum(V(0, 12, z), 10.5, { axis = "Z", amplitude = 55, period = 3, phase = (i - 1) / 3 })
	end
	-- V · turnstile
	L:Step(V(0, 0, 160), V(24, 1, 24), { shape = "Cylinder" })
	L:Spinner(V(0, 2.5, 160), { length = 11.5, arms = 2, speed = 35, bladeHeight = 4.5, floorY = 0 })
	-- VI · ferry and door
	L:Mover(V(0, 0, 178), V(6, 1, 6), V(0, 0, 14), { period = 6, pause = 1.2 })
	L:Step(V(0, 0, 200), V(8, 1, 8))
	door(L, 0, 204.5, 8, { period = 6, pause = 1.4 })
	L:Wall(V(-6, 4.5, 204.5), V(4, 9, 1), { name = "DoorWing" })
	L:Wall(V(6, 4.5, 204.5), V(4, 9, 1), { name = "DoorWing" })
	L:Step(V(0, 0, 213), V(8, 1, 16))
	-- VII · rising wave
	L:SectionLabel(V(0, 2.5, 219), "VII · CLOCK TOWER")
	for i = 1, 5 do
		L:Ghost(V(0, i * 1.5, 221 + i * 7.5), V(5, 1, 5), { visible = 2.6, invisible = 1.4, phase = (i - 1) * 0.2 })
	end
	L:Step(V(0, 7.5, 267), V(8, 1, 8))
	L.Theme.scenery(L, V(-45, 10, 120), 1.4)
	L.Theme.scenery(L, V(50, 0, 220), 1.2)
	L:Exit(V(0, 7.5, 281))
end

return Levels
