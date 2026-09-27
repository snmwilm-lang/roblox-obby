--[[
	CheckpointRules
	Pure functions describing the checkpoint contract of the game.
	No Roblox API usage: unit-tested headlessly in tests/.

	Fundamental rule:
	  - every level has a checkpoint at its start
	  - EXCEPT final stages (20, 40, ..., 200): the pre-final (X19) and the final
	    (X20) form one continuous trial. Dying anywhere in X20 sends the player
	    back to the start of X19.
	  - claiming checkpoint X21 (start of the next zone) completes the zone.
	  - FINISH_LEVEL (201) is the victory room, reached by completing level 200.
]]

local Config = require(script.Parent.Config)

local TOTAL = Config.TOTAL_LEVELS
local PER_ZONE = Config.LEVELS_PER_ZONE
local FINISH = Config.FINISH_LEVEL

local CheckpointRules = {}

function CheckpointRules.isValidLevel(level: number): boolean
	return typeof(level) == "number" and level % 1 == 0 and level >= 1 and level <= TOTAL
end

function CheckpointRules.zoneOf(level: number): number
	level = math.clamp(level, 1, TOTAL)
	return math.ceil(level / PER_ZONE)
end

function CheckpointRules.zoneRange(zone: number): (number, number)
	return (zone - 1) * PER_ZONE + 1, zone * PER_ZONE
end

-- Position of the level inside its zone, 1..20
function CheckpointRules.indexInZone(level: number): number
	return (level - 1) % PER_ZONE + 1
end

function CheckpointRules.isFinalStage(level: number): boolean
	return CheckpointRules.isValidLevel(level) and level % PER_ZONE == 0
end

function CheckpointRules.isPreFinal(level: number): boolean
	return CheckpointRules.isValidLevel(level) and level % PER_ZONE == PER_ZONE - 1
end

function CheckpointRules.isZoneStart(level: number): boolean
	return CheckpointRules.isValidLevel(level) and level % PER_ZONE == 1
end

-- Does a checkpoint pad exist at the start of this level?
function CheckpointRules.hasCheckpoint(level: number): boolean
	if level == FINISH then
		return true
	end
	return CheckpointRules.isValidLevel(level) and not CheckpointRules.isFinalStage(level)
end

-- Where does a player standing in `level` respawn?
function CheckpointRules.respawnLevelFor(level: number): number
	if CheckpointRules.isFinalStage(level) then
		return level - 1
	end
	return level
end

-- Next checkpoint a player holding checkpoint `cp` is allowed to claim.
function CheckpointRules.nextCheckpoint(cp: number): number
	local n = cp + 1
	if n > TOTAL then
		return FINISH
	end
	if CheckpointRules.isFinalStage(n) then
		n += 1
		if n > TOTAL then
			return FINISH
		end
	end
	return n
end

-- Anti-skip: only the very next checkpoint can be claimed.
function CheckpointRules.canClaim(cp: number, level: number): boolean
	return cp < FINISH and level == CheckpointRules.nextCheckpoint(cp)
end

-- Levels completed by claiming `level` (claiming 21 completes 19 and 20).
function CheckpointRules.levelsCompletedByClaiming(level: number): { number }
	local completed = {}
	local previous = level - 1
	if previous >= 1 and CheckpointRules.isFinalStage(previous) then
		table.insert(completed, previous - 1)
	end
	if previous >= 1 then
		table.insert(completed, previous)
	end
	return completed
end

-- "Best level" shown above heads and on leaderboards.
-- 200 is only ever displayed once level 200 has actually been completed.
function CheckpointRules.displayLevel(cp: number): number
	return math.clamp(cp, 1, TOTAL)
end

-- Turns any stored value into a valid checkpoint that exists in the built world.
function CheckpointRules.sanitize(cp: any, highestBuilt: number?): number
	local n = math.floor(tonumber(cp) or 1)
	n = math.clamp(n, 1, FINISH)
	if not CheckpointRules.hasCheckpoint(n) then
		n = CheckpointRules.respawnLevelFor(n)
	end
	if highestBuilt and n > highestBuilt then
		n = highestBuilt
		while n > 1 and not CheckpointRules.hasCheckpoint(n) do
			n -= 1
		end
	end
	return n
end

return CheckpointRules
