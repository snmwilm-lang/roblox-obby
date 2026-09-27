--[[
	ZONE 6 — CONTROL — Frost Circuit (levels 101-120)

	Not built yet: level 101's start pad exists so that finishing level 100
	claims a real checkpoint (zone 5 completed, progress saved). A barrier
	closes the rest until the zone is built.
]]

local V = Vector3.new

local Levels = {}

Levels[101] = function(L)
	L:Barrier(V(0, 6, 7.5), V(14, 12, 1), "ZONE 6 CONTINUES IN THE NEXT UPDATE\nLevels 101-120")
end

return Levels
