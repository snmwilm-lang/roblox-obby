--[[
	ZONE 2 — TIMING — Clockwork Foundry (levels 21-40)

	V1 ships the zone transition only:
	  - level 21 fully playable: introduction to ghost platforms
	  - level 22 start pad (a real checkpoint, so progress is kept) closed by a
	    barrier until the rest of the zone is built.
]]

local V = Vector3.new

local Levels = {}

-- 21 · Now You See It — alternating ghosts, then a sequential wave.
Levels[21] = function(L)
	L:Sign(V(-4.5, 2, 5), "Cyan platforms phase out.\nThey blink before vanishing.", { width = 6, height = 2.2 })
	-- Alternating pair: G1 / G3 in phase, G2 half a cycle later
	L:Ghost(V(0, 0, 12), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0 })
	L:Ghost(V(0, 0, 21), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0.5 })
	L:Ghost(V(0, 0, 30), V(6, 1, 6), { visible = 3, invisible = 1.5, phase = 0 })
	L:Step(V(0, 0, 40), V(8, 1, 8))
	-- Sequential wave: each ghost appears a third of a cycle after the previous one
	L:Ghost(V(0, 1, 50), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 0 })
	L:Ghost(V(0, 2, 58), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 1 / 3 })
	L:Ghost(V(0, 3, 66), V(5, 1, 5), { visible = 3, invisible = 1.5, phase = 2 / 3 })
	L.Theme.scenery(L, V(-30, 4, 40), 0.8)
	L:Exit(V(0, 3, 77))
end

-- 22 · Clockwork Doors — end of V1 content. The checkpoint is real.
Levels[22] = function(L)
	L:Barrier(V(0, 6, 7.5), V(14, 12, 1), "ZONE 2 CONTINUES IN THE NEXT UPDATE\nLevels 22-40")
	-- no Exit: last built level
end

return Levels
