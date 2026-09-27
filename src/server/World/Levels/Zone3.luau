--[[
	ZONE 3 — MOMENTUM — Velocity Canyon (levels 41-60)

	Lesson: speed is a resource. Belts push you (and never keep pushing in
	the air, Roblox rule), jump pads launch you to a fixed height, orange
	boost strips raise your walk speed for 2 s: the gap right after a strip
	is impossible without it (momentum gate), comfortable with it.
	Budget: jumps ≤ 75 % of the maximum (pad power and boost speed included).
]]

local V = Vector3.new

local FORWARD = V(0, 0, 1)
local BACK = V(0, 0, -1)
local RIGHT = V(1, 0, 0)
local LEFT = V(-1, 0, 0)

local Levels = {}

-- 41 · Conveyor 101 — ride a belt, then walk against one.
Levels[41] = function(L)
	L:Sign(V(-4.5, 2, 5), "Belts push you.\nWalk against them.", { width = 6, height = 2.2 })
	L:Conveyor(V(0, 0, 20), V(6, 1, 26), FORWARD, 10)
	L:Step(V(0, 0, 39), V(6, 1, 6))
	L:Conveyor(V(0, 0, 55), V(6, 1, 20), BACK, 6)
	L.Theme.scenery(L, V(40, -10, 30), 1)
	L:Exit(V(0, 0, 75))
end

-- 42 · Launch Pad — green pads throw you to the next ledge.
Levels[42] = function(L)
	L:Sign(V(-4.5, 2, 5), "Green pads launch you.\nSteer in the air.", { width = 6, height = 2.2 })
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:JumpPad(V(0, 0, 20), V(6, 1, 6), 75)
	L:Step(V(0, 12, 31), V(8, 1, 6))
	L:JumpPad(V(0, 12, 40), V(6, 1, 6), 75)
	L:Step(V(0, 24, 51), V(8, 1, 6))
	L:Decor(V(0, 5.5, 31), V(6, 12, 4), { name = "Cliff", material = Enum.Material.Sandstone })
	L:Decor(V(0, 17.5, 51), V(6, 12, 4), { name = "Cliff", material = Enum.Material.Sandstone })
	L:Exit(V(0, 24, 64))
end

-- 43 · Downhill — descending belts carry you into hurdles: jump on the move.
Levels[43] = function(L)
	L:Conveyor(V(0, 0, 16), V(6, 1, 18), FORWARD, 8)
	L:Conveyor(V(0, -3, 34), V(6, 1, 12), FORWARD, 8)
	L:Kill(V(0, -2.5, 35), V(6, 1, 1), { name = "Hurdle" })
	L:Conveyor(V(0, -6, 50), V(6, 1, 14), FORWARD, 9)
	L:Kill(V(0, -5.5, 51), V(6, 1, 1), { name = "Hurdle" })
	L:Conveyor(V(0, -9, 66), V(6, 1, 12), FORWARD, 10)
	L:Exit(V(0, -9, 82))
end

-- 44 · Reverse Belt — every platform pushes you back toward the gap.
Levels[44] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Conveyor(V(0, 0, 20), V(6, 1, 12), BACK, 8)
	L:Conveyor(V(0, 1, 34), V(5, 1, 8), BACK, 8)
	L:Conveyor(V(0, 2, 47), V(5, 1, 10), BACK, 10)
	L:Exit(V(0, 2, 62))
end

-- 45 · Speed Strip — first momentum gates: the gap only works with a boost.
Levels[45] = function(L)
	L:Sign(V(-4.5, 2, 5), "Orange strips = speed.\nJump at the end of it.", { width = 6, height = 2.2 })
	L:Boost(V(0, 0, 18), V(6, 1, 14), 30)
	L:Step(V(0, 0, 39), V(8, 1, 6))
	L:Boost(V(0, 0, 50), V(6, 1, 10), 30)
	L:Step(V(0, 3, 68), V(8, 1, 6))
	L:Exit(V(0, 3, 81))
end

-- 46 · Bounce House — pad to pad without touching the ground.
Levels[46] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:JumpPad(V(0, 0, 19), V(5, 1, 5), 65)
	L:JumpPad(V(0, 2, 31), V(5, 1, 5), 65)
	L:JumpPad(V(0, 4, 43), V(5, 1, 5), 65)
	L:Step(V(0, 6, 55), V(6, 1, 6))
	L:Exit(V(0, 6, 68))
end

-- 47 · Crosswind Belts — belts push you sideways toward the void.
Levels[47] = function(L)
	L:Conveyor(V(0, 0, 16), V(8, 1, 14), RIGHT, 6)
	L:Conveyor(V(0, 0, 32), V(8, 1, 14), LEFT, 6)
	L:Conveyor(V(0, 0, 48), V(6, 1, 14), RIGHT, 8)
	L:Exit(V(0, 0, 65))
end

-- 48 · Momentum Gate — two gates, the second one also climbs.
Levels[48] = function(L)
	L:Boost(V(0, 0, 14), V(6, 1, 10), 30)
	L:Step(V(0, 0, 33), V(6, 1, 6))
	L:Boost(V(0, 0, 44), V(6, 1, 10), 30)
	L:Step(V(0, 2, 61), V(6, 1, 6))
	for _, z in { 24.5, 54 } do
		L:Decor(V(-4, 5, z), V(1, 10, 1), { name = "GatePost", color = Color3.fromRGB(255, 180, 90), material = Enum.Material.Neon })
		L:Decor(V(4, 5, z), V(1, 10, 1), { name = "GatePost", color = Color3.fromRGB(255, 180, 90), material = Enum.Material.Neon })
	end
	L:Exit(V(0, 2, 74))
end

-- 49 · Pad Ladder — climb a canyon wall with pads, left and right.
Levels[49] = function(L)
	L:JumpPad(V(0, 0, 16), V(6, 1, 6), 70)
	L:Step(V(4, 10, 26), V(6, 1, 6))
	L:JumpPad(V(4, 10, 35), V(6, 1, 6), 70)
	L:Step(V(-2, 20, 45), V(6, 1, 6))
	L:JumpPad(V(-2, 20, 54), V(6, 1, 6), 70)
	L:Step(V(0, 30, 64), V(8, 1, 6))
	L:Decor(V(0, 15, 70), V(20, 34, 2), { name = "CanyonWall", material = Enum.Material.Sandstone })
	L:Exit(V(0, 30, 77))
end

-- 50 · Canyon Crossing — belt, pad and boost in one run.
Levels[50] = function(L)
	L:Conveyor(V(0, 0, 15), V(6, 1, 16), FORWARD, 8)
	L:JumpPad(V(0, 0, 28), V(6, 1, 6), 65)
	L:Step(V(0, 6, 40), V(6, 1, 6))
	L:Boost(V(0, 6, 52), V(6, 1, 12), 30)
	L:Step(V(0, 6, 71), V(6, 1, 6))
	L.Theme.scenery(L, V(-45, -10, 40), 1.2)
	L:Exit(V(0, 6, 84))
end

-- 51 · Slingshot — fast ferries: jump off while they move to fly further.
Levels[51] = function(L)
	L:Step(V(0, 0, 11), V(6, 1, 6))
	L:Mover(V(0, 0, 18), V(6, 1, 6), V(0, 0, 20), { period = 5, pause = 1 })
	L:Step(V(0, 0, 48), V(6, 1, 6))
	L:Mover(V(0, 0, 58), V(6, 1, 6), V(0, 8, 16), { period = 5, pause = 1 })
	L:Step(V(0, 8, 82), V(6, 1, 6))
	L:Exit(V(0, 8, 95))
end

-- 52 · Belt Maze — every tile pushes a different way.
Levels[52] = function(L)
	local directions = { RIGHT, LEFT, BACK, RIGHT, BACK, LEFT }
	for i, dir in directions do
		local z = 5 + i * 7
		L:Conveyor(V(0, 0, z), V(6, 1, 6), dir, 6)
		-- side tiles: alternative (harder) lanes, not required
		L:Conveyor(V(-7, 0, z), V(6, 1, 6), directions[(i % 6) + 1], 6, { route = false })
		L:Conveyor(V(7, 0, z), V(6, 1, 6), directions[((i + 2) % 6) + 1], 6, { route = false })
	end
	L:Exit(V(0, 0, 57))
end

-- 53 · Ricochet — pads alternate sides up a shaft.
Levels[53] = function(L)
	L:JumpPad(V(-4, 0, 14), V(5, 1, 5), 70)
	L:JumpPad(V(4, 8, 20), V(5, 1, 5), 70)
	L:JumpPad(V(-4, 16, 26), V(5, 1, 5), 70)
	L:JumpPad(V(4, 24, 32), V(5, 1, 5), 70)
	L:Step(V(0, 32, 40), V(8, 1, 6))
	L:Wall(V(-9, 20, 24), V(1, 40, 24), { name = "ShaftWall", material = Enum.Material.Sandstone })
	L:Wall(V(9, 20, 24), V(1, 40, 24), { name = "ShaftWall", material = Enum.Material.Sandstone })
	L:Exit(V(0, 32, 53))
end

-- 54 · Rolling Hills — belts up and down, one hurdle on the way.
Levels[54] = function(L)
	L:Conveyor(V(0, 0, 15), V(6, 1, 14), FORWARD, 8)
	L:Step(V(0, 3, 28), V(6, 1, 6))
	L:Conveyor(V(0, 1, 40), V(6, 1, 12), FORWARD, 10)
	L:Kill(V(0, 1.5, 41), V(6, 1, 1), { name = "Hurdle" })
	L:Step(V(0, 4, 52), V(6, 1, 6))
	L:Conveyor(V(0, 2, 65), V(6, 1, 14), FORWARD, 10)
	L:Exit(V(0, 2, 82))
end

-- 55 · Speed Trap — boost over a gap, then through a laser window.
Levels[55] = function(L)
	L:Boost(V(0, 0, 15), V(6, 1, 12), 30)
	L:Step(V(0, 0, 33), V(8, 1, 6))
	L:Step(V(0, 0, 45), V(6, 1, 12))
	L:Laser(V(0, 3.5, 45), V(6, 7, 0.3), { on = 1.5, off = 2 })
	L:Boost(V(0, 0, 58), V(6, 1, 10), 30)
	L:Step(V(0, 0, 75), V(6, 1, 6))
	L:Exit(V(0, 0, 88))
end

-- 56 · Catapult Chain — pads onto small targets, three times.
Levels[56] = function(L)
	L:JumpPad(V(0, 0, 14), V(5, 1, 5), 70)
	L:Step(V(0, 6, 25), V(4, 1, 4))
	L:JumpPad(V(0, 6, 32), V(4, 1, 4), 70)
	L:Step(V(3, 12, 42), V(4, 1, 4))
	L:JumpPad(V(3, 12, 49), V(4, 1, 4), 70)
	L:Step(V(0, 18, 59), V(5, 1, 5))
	L:Exit(V(0, 18, 72))
end

-- 57 · Treadmill Tower — every step is a belt pushing you back down.
Levels[57] = function(L)
	for i = 1, 6 do
		L:Conveyor(V(0, i * 2 - 1, 4 + i * 9), V(6, 1, 8), BACK, 6)
	end
	L:Exit(V(0, 11, 71))
end

-- 58 · Afterburner — boost lanes with a 90° turn.
Levels[58] = function(L)
	L:Boost(V(0, 0, 16), V(6, 1, 18), 30)
	L:Step(V(0, 0, 38), V(8, 1, 6))
	L:Boost(V(10, 0, 38), V(12, 1, 6), 30)
	L:Step(V(27, 0, 38), V(6, 1, 6))
	L:Step(V(27, 0, 48), V(6, 1, 6))
	L:Boost(V(27, 0, 60), V(6, 1, 14), 30)
	L:Step(V(27, 0, 80), V(6, 1, 6))
	L:Exit(V(27, 0, 93))
end

-- 59 · Terminal Velocity — pre-final: belt, pads, gate, laser, lift.
Levels[59] = function(L)
	L:Conveyor(V(0, 0, 15), V(6, 1, 16), FORWARD, 8)
	L:Kill(V(0, 0.5, 18), V(6, 1, 1), { name = "Hurdle" })
	L:JumpPad(V(0, 0, 28), V(6, 1, 6), 70)
	L:Step(V(0, 8, 39), V(6, 1, 6))
	L:Boost(V(0, 8, 51), V(6, 1, 12), 30)
	L:Step(V(0, 8, 70), V(6, 1, 6))
	L:Step(V(0, 8, 84), V(6, 1, 16))
	L:Laser(V(0, 11.5, 84), V(6, 7, 0.3), { on = 1.5, off = 2 })
	L:Mover(V(0, 8, 97), V(6, 1, 6), V(0, 4, 14), { period = 5, pause = 1 })
	L:Step(V(0, 12, 119), V(6, 1, 6))
	L:Exit(V(0, 12, 133))
end

-- 60 · Canyon Run — FINAL STAGE: belts, pads, gate, crosswind, lasers, slingshot, pad ladder.
Levels[60] = function(L)
	L:SectionLabel(V(-4, 1.5, 6.5), "I · BELTS")
	L:Conveyor(V(0, 0, 16), V(6, 1, 18), FORWARD, 10)
	L:Kill(V(0, 0.5, 14), V(6, 1, 1), { name = "Hurdle" })
	L:Kill(V(0, 0.5, 21), V(6, 1, 1), { name = "Hurdle" })
	L:Conveyor(V(0, 0, 37), V(6, 1, 14), BACK, 6)
	-- II · pads
	L:JumpPad(V(0, 0, 50), V(6, 1, 6), 70)
	L:Step(V(0, 8, 61), V(6, 1, 6))
	L:JumpPad(V(0, 8, 70), V(6, 1, 6), 70)
	L:Step(V(0, 16, 81), V(8, 1, 6))
	-- III · momentum gate
	L:Boost(V(0, 16, 93), V(6, 1, 12), 30)
	L:Step(V(0, 16, 112), V(6, 1, 6))
	-- IV · crosswind belts
	L:Conveyor(V(0, 16, 126), V(8, 1, 14), RIGHT, 6)
	L:Conveyor(V(0, 16, 142), V(8, 1, 14), LEFT, 6)
	-- V · lasers
	L:Step(V(0, 16, 164), V(6, 1, 24))
	for i, z in { 158, 166, 173 } do
		L:Laser(V(0, 19.5, z), V(6, 7, 0.3), { on = 1.5, off = 2, phase = (i - 1) / 3 })
	end
	-- VI · slingshot
	L:Mover(V(0, 16, 182), V(6, 1, 6), V(0, 0, 18), { period = 5, pause = 1 })
	L:Step(V(0, 16, 208), V(6, 1, 6))
	-- VII · pad ladder
	L:JumpPad(V(0, 16, 217), V(6, 1, 6), 70)
	L:Step(V(4, 24, 227), V(6, 1, 6))
	L:JumpPad(V(4, 24, 236), V(6, 1, 6), 70)
	L:Step(V(0, 32, 246), V(8, 1, 6))
	L.Theme.scenery(L, V(-50, 0, 100), 1.4)
	L.Theme.scenery(L, V(55, 10, 200), 1.2)
	L:Exit(V(0, 32, 260))
end

return Levels
