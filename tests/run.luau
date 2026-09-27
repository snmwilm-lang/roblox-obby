--[[
	Headless test suite. Run from the repository root:
	    lune run tests/run.luau

	1. CheckpointRules  — the 19→20 continuous-trial contract, anti-skip, sanitising
	2. LevelPlan        — 200 levels, finals every 20, monotonic difficulty
	3. Timing           — cycle maths used by every obstacle
	4. World            — builds the REAL world with the real LevelBuilder, then:
	     - every jump of every route is within the character's jump envelope
	     - moving/ghost pairs actually line up for a usable time window
	     - limbo bars can be walked under and cannot be jumped under
	     - final stages are 3-5x longer than normal levels of their zone
	     - checkpoint gates exist exactly where the rules say
]]

local process = require("@lune/process")
local Loader = require("./loader")

local roblox = Loader.roblox
local Vector3 = roblox.Vector3

local Config = Loader.get("ReplicatedStorage", "Shared", "Config")
local CheckpointRules = Loader.get("ReplicatedStorage", "Shared", "CheckpointRules")
local LevelPlan = Loader.get("ReplicatedStorage", "Shared", "LevelPlan")
local Timing = Loader.get("ReplicatedStorage", "Shared", "Timing")
local ObstacleTypes = Loader.get("ReplicatedStorage", "Shared", "ObstacleTypes")

local failures = 0
local passes = 0
local currentSuite = ""

local function suite(name: string)
	currentSuite = name
	print(("\n== %s"):format(name))
end

local function check(condition: boolean, message: string)
	if condition then
		passes += 1
	else
		failures += 1
		print(("  FAIL [%s] %s"):format(currentSuite, message))
	end
end

local function eq(actual: any, expected: any, message: string)
	check(actual == expected, ("%s (expected %s, got %s)"):format(message, tostring(expected), tostring(actual)))
end

----------------------------------------------------------------------------
suite("CheckpointRules")
----------------------------------------------------------------------------

for level = 1, Config.TOTAL_LEVELS do
	local final = level % 20 == 0
	eq(CheckpointRules.isFinalStage(level), final, "isFinalStage " .. level)
	eq(CheckpointRules.hasCheckpoint(level), not final, "hasCheckpoint " .. level)
end
eq(CheckpointRules.hasCheckpoint(Config.FINISH_LEVEL), true, "finish is a checkpoint")

-- The examples of the design brief
eq(CheckpointRules.respawnLevelFor(17), 17, "die in 17 -> 17")
eq(CheckpointRules.respawnLevelFor(19), 19, "die in 19 -> 19")
eq(CheckpointRules.respawnLevelFor(20), 19, "die in 20 at 90% -> 19")
eq(CheckpointRules.respawnLevelFor(140), 139, "reached 140 without finishing -> 139")
eq(CheckpointRules.respawnLevelFor(200), 199, "die in 200 -> 199")

eq(CheckpointRules.nextCheckpoint(18), 19, "after 18 comes 19")
eq(CheckpointRules.nextCheckpoint(19), 21, "after 19 comes 21 (20 has none)")
eq(CheckpointRules.nextCheckpoint(199), Config.FINISH_LEVEL, "after 199 comes the finish")
check(not CheckpointRules.canClaim(19, 20), "cannot claim final stage 20")
check(CheckpointRules.canClaim(19, 21), "19 -> 21 claim")
check(not CheckpointRules.canClaim(17, 19), "cannot skip 18")
check(not CheckpointRules.canClaim(Config.FINISH_LEVEL, 1), "finished players do not re-claim")

local completed = CheckpointRules.levelsCompletedByClaiming(21)
check(#completed == 2 and completed[1] == 19 and completed[2] == 20, "claiming 21 completes 19 and 20")

eq(CheckpointRules.sanitize(20), 19, "stored 20 sanitised to 19")
eq(CheckpointRules.sanitize(137, 22), 22, "clamped to highest built")
eq(CheckpointRules.sanitize(21, 22), 21, "valid checkpoint kept")
eq(CheckpointRules.sanitize("garbage"), 1, "garbage -> 1")
eq(CheckpointRules.sanitize(9999), Config.FINISH_LEVEL, "overflow -> finish")
eq(CheckpointRules.sanitize(40, 60), 39, "40 -> 39")
eq(CheckpointRules.displayLevel(Config.FINISH_LEVEL), 200, "finish displays 200")
eq(CheckpointRules.displayLevel(199), 199, "199 displays 199")

-- Full journey: touch every gate in order, respawn level never lands on a final stage
do
	local cp = 1
	local neverFinal = true
	for level = 2, Config.FINISH_LEVEL do
		if CheckpointRules.canClaim(cp, level) then
			cp = level
		end
		if CheckpointRules.isFinalStage(cp) then
			neverFinal = false
		end
	end
	eq(cp, Config.FINISH_LEVEL, "a full run ends on the finish checkpoint")
	check(neverFinal, "a final stage is never a checkpoint")
end

----------------------------------------------------------------------------
suite("LevelPlan")
----------------------------------------------------------------------------

do
	local names = {}
	local previous = 0
	for level = 1, Config.TOTAL_LEVELS do
		local info = LevelPlan.get(level)
		check(info.Name ~= "" and names[info.Name] == nil, "unique name for level " .. level)
		names[info.Name] = true
		check(info.Difficulty >= previous, ("difficulty never goes down (level %d)"):format(level))
		previous = info.Difficulty
		eq(info.FinalStage, level % 20 == 0, "final flag " .. level)
		eq(info.Zone, math.ceil(level / 20), "zone of " .. level)
		if info.FinalStage then
			eq(info.Main, "FINAL STAGE", "final stage main mechanic " .. level)
		end
	end
end

----------------------------------------------------------------------------
suite("Timing")
----------------------------------------------------------------------------

eq(Timing.pingPong(0, 6, 1, 0, "Linear"), 0, "pingPong starts at 0")
eq(Timing.pingPong(2, 6, 1, 0, "Linear"), 1, "pingPong reaches 1 after a leg")
eq(Timing.pingPong(2.5, 6, 1, 0, "Linear"), 1, "pingPong holds at 1")
eq(Timing.pingPong(5.5, 6, 1, 0, "Linear"), 0, "pingPong holds at 0")
check(math.abs(Timing.pingPong(1, 6, 1, 0, "Linear") - 0.5) < 1e-9, "pingPong linear midpoint")
do
	local on, left = Timing.onOff(0.5, 2, 1, 0)
	check(on and math.abs(left - 1.5) < 1e-9, "onOff on window")
	on = Timing.onOff(2.5, 2, 1, 0)
	check(not on, "onOff off window")
	-- phase = delay: phase 0.25 of a 4 s cycle is 1 s later
	check(math.abs(Timing.loop(1, 4, 0.25)) < 1e-9, "loop phase is a delay")
end
do
	local defaults = ObstacleTypes.read(roblox.Instance.new("Part"), "MovingPlatform")
	eq(defaults.Period, 6, "ObstacleTypes defaults")
end

----------------------------------------------------------------------------
suite("World build")
----------------------------------------------------------------------------

local WorldBuilder = Loader.get("ServerScriptService", "Server", "World", "WorldBuilder")
local LevelBuilder = Loader.get("ServerScriptService", "Server", "World", "LevelBuilder")

local folder = roblox.Instance.new("Folder")
local stages, highest = WorldBuilder.build(folder)
check(highest >= 21, "V1 builds at least levels 1-21 (got " .. highest .. ")")

-- A baked world (tools/bake.luau) must re-index to exactly the same stages
do
	local indexed, indexedHighest = WorldBuilder.index(folder)
	eq(indexedHighest, highest, "baked world re-index: level count")
	for level = 1, highest do
		local a, b = stages[level], indexed[level]
		check(b ~= nil and b.Gate == a.Gate and (b.Spawn.Position - a.Spawn.Position).Magnitude < 1e-3, "baked world re-index: level " .. level)
	end
end
for level = 1, highest do
	check(stages[level] ~= nil, "stage exists " .. level)
end

local J = Config.Jump
local C = Config.Character

-- Horizontal reach for a jump that lands dh studs higher (negative = lower).
local function maxGap(dh: number): number
	local v = C.JumpPower
	local g = C.Gravity
	local disc = v * v - 2 * g * dh
	if disc < 0 then
		return -1
	end
	local t = (v + math.sqrt(disc)) / g
	return C.WalkSpeed * t + J.EdgeAllowance
end

-- Edge-to-edge distance of two footprints (XZ rectangles)
local function gap(aTop: Vector3, aSize: Vector3, bTop: Vector3, bSize: Vector3): number
	local dx = math.max(0, math.abs(aTop.X - bTop.X) - (aSize.X + bSize.X) / 2)
	local dz = math.max(0, math.abs(aTop.Z - bTop.Z) - (aSize.Z + bSize.Z) / 2)
	return math.sqrt(dx * dx + dz * dz)
end

local function positionsOf(node): { Vector3 }
	if node.Kind == "Mover" and node.Travel then
		return { node.Top, node.Top + node.Travel }
	end
	return { node.Top }
end

-- Per-zone budget: fraction of the maximum jump a normal level may ask for.
local BUDGET = { [1] = 0.62, [2] = 0.7 }

local function jumpRatio(a, b): (number, number, number)
	local best = math.huge
	local bestGap, bestDh = 0, 0
	for _, pa in positionsOf(a) do
		for _, pb in positionsOf(b) do
			local d = gap(pa, a.Size, pb, b.Size)
			local dh = pb.Y - pa.Y
			local reach = maxGap(dh)
			local ratio = if d <= 0 and dh <= 0.6 then 0 elseif reach <= 0 or dh > J.MaxHeight - 0.4 then math.huge else d / reach
			if ratio < best then
				best, bestGap, bestDh = ratio, d, dh
			end
		end
	end
	return best, bestGap, bestDh
end

-- Local-frame position of a moving/ghost node at time t
local function nodeAt(node, t: number): (Vector3?, boolean)
	local part = node.Part
	if node.Kind == "Mover" then
		local c = ObstacleTypes.read(part, "MovingPlatform")
		local alpha = Timing.pingPong(t, c.Period, c.Pause, c.Phase, c.Easing)
		return node.Top + node.Travel * alpha, true
	elseif node.Kind == "Ghost" then
		local c = ObstacleTypes.read(part, "GhostPlatform")
		local on, left = Timing.onOff(t, c.VisibleDuration, c.InvisibleDuration, c.PhaseOffset)
		-- a ghost about to vanish is not a safe landing
		return node.Top, on and left > 0.25
	end
	return node.Top, true
end

-- For dynamic pairs, measure how long per cycle the jump is actually possible.
local function usableWindow(a, b, budget: number): number
	local dynamic = a.Kind == "Mover" or a.Kind == "Ghost" or b.Kind == "Mover" or b.Kind == "Ghost"
	if not dynamic then
		return math.huge
	end
	local horizon, step = 60, 0.02
	local total = 0
	local t = 0
	while t < horizon do
		local pa, okA = nodeAt(a, t)
		local pb, okB = nodeAt(b, t)
		if okA and okB then
			local d = gap(pa, a.Size, pb, b.Size)
			local dh = pb.Y - pa.Y
			local reach = maxGap(dh)
			if (d <= 0 and dh <= 0.6) or (reach > 0 and dh <= J.MaxHeight - 0.4 and d / reach <= budget) then
				total += step
			end
		end
		t += step
	end
	return total / horizon -- fraction of time the jump is on
end

--[[
	Sequential feasibility: simulate a player walking the whole route over time.
	reach[i][k] = the player can be standing on node i at time step k.
	- he can stay on a node while it is solid (ghosts vanish, movers carry him)
	- a jump from i to i+1 started at step k lands JUMP_STEPS later, and needs
	  the jump to be within budget at take-off and node i+1 solid on landing
	This catches rhythm bugs pairwise checks miss (each pair has a window, but
	no timing lets you chain them).
]]
local STEP = 0.05
local JUMP_STEPS = 10 -- 0.5 s of air time
local HORIZON = 90

local function jumpPossible(a, b, t: number, budget: number): boolean
	local pa, okA = nodeAt(a, t)
	local pb = nodeAt(b, t + JUMP_STEPS * STEP)
	local _, okB = nodeAt(b, t + JUMP_STEPS * STEP)
	if not okA or not okB then
		return false
	end
	local d = gap(pa, a.Size, pb, b.Size)
	local dh = pb.Y - pa.Y
	if d <= 0 and dh <= 0.6 then
		return true
	end
	local reach = maxGap(dh)
	return reach > 0 and dh <= J.MaxHeight - 0.4 and d / reach <= budget
end

local function routeFeasible(route, budget: number): (boolean, number)
	local steps = math.floor(HORIZON / STEP)
	local current = table.create(steps, false)
	for k = 1, steps // 2 do
		current[k] = true -- the start pad can be left at any moment
	end
	for i = 1, #route - 1 do
		local a, b = route[i], route[i + 1]
		-- propagate "stay on a" forward in time
		for k = 2, steps do
			if not current[k] and current[k - 1] then
				local _, solid = nodeAt(a, k * STEP)
				current[k] = solid
			end
		end
		local nextReach = table.create(steps, false)
		local any = false
		for k = 1, steps - JUMP_STEPS do
			if current[k] and jumpPossible(a, b, k * STEP, budget) then
				nextReach[k + JUMP_STEPS] = true
				any = true
			end
		end
		if not any then
			return false, i
		end
		current = nextReach
	end
	return true, 0
end

-- Self-test of the simulator: every pair below has a usable window, but the
-- chain is impossible (G5 vanishes before G6's window comes back).
do
	local function ghost(z: number, visible: number, invisible: number, phase: number)
		local part = roblox.Instance.new("Part")
		part:SetAttribute("VisibleDuration", visible)
		part:SetAttribute("InvisibleDuration", invisible)
		part:SetAttribute("PhaseOffset", phase)
		return { Kind = "Ghost", Top = Vector3.new(0, 0, z), Size = Vector3.new(5, 1, 5), Part = part }
	end
	local g4 = ghost(0, 1.8, 2.7, 2.0 / 4.5)
	local g5 = ghost(8, 3.5, 1.0, 0)
	local g6 = ghost(16, 1.5, 3.0, 0.5 / 4.5)
	check(usableWindow(g4, g5, 0.62) >= 0.08 and usableWindow(g5, g6, 0.62) >= 0.08, "simulator self-test: pairs look fine")
	check(not routeFeasible({ g4, g5, g6 }, 0.62), "simulator self-test: impossible chain is detected")
	local w4 = ghost(0, 3, 1.5, 0)
	local w5 = ghost(8, 3, 1.5, 1 / 3)
	local w6 = ghost(16, 3, 1.5, 2 / 3)
	check(routeFeasible({ w4, w5, w6 }, 0.62), "simulator self-test: forward wave is feasible")
end

local lengths = {}
for level = 1, highest do
	local stage = stages[level]
	local zone = CheckpointRules.zoneOf(level)
	local budget = BUDGET[zone] or 0.8
	if CheckpointRules.isFinalStage(level) then
		budget += 0.05
	end
	local route = table.clone(stage.Route)
	if stage.ExitLocal then
		-- the jump onto the next level's start pad belongs to this level
		table.insert(route, { Kind = "Static", Top = stage.ExitLocal, Size = LevelBuilder.START_PAD_SIZE })
	end

	local worst = 0
	for i = 1, #route - 1 do
		local a, b = route[i], route[i + 1]
		local ratio, d, dh = jumpRatio(a, b)
		worst = math.max(worst, ratio)
		check(ratio <= budget, ("level %d jump %d->%d too hard: gap %.2f rise %.2f ratio %.2f > %.2f"):format(level, i, i + 1, d, dh, ratio, budget))
		local window = usableWindow(a, b, budget)
		check(window >= 0.08, ("level %d jump %d->%d is only possible %.0f%% of the time"):format(level, i, i + 1, window * 100))
	end

	local feasible, stuckAt = routeFeasible(route, budget)
	check(feasible, ("level %d: no timing lets a player chain the route (stuck after node %d)"):format(level, stuckAt))

	-- level length along the route
	local first = route[1].Top
	local last = route[#route].Top
	lengths[level] = (last - first).Magnitude
	print(("  level %3d %-18s nodes %2d  length %6.1f  hardest jump %.2f"):format(level, LevelPlan.name(level), #route, lengths[level], worst))
end

-- Final stages: 3-5x the average normal level of the zone
for level = 20, highest, 20 do
	local zoneFirst = level - 19
	local sum, count = 0, 0
	for l = zoneFirst, level - 2 do
		if lengths[l] then
			sum += lengths[l]
			count += 1
		end
	end
	local ratio = lengths[level] / (sum / count)
	print(("  final stage %d is %.1fx the zone's average level"):format(level, ratio))
	check(ratio >= 3 and ratio <= 5, ("final stage %d length ratio %.2f not in [3, 5]"):format(level, ratio))
end

-- Gates: every built level has one; only final stages lack a checkpoint
for level = 1, highest do
	local gate = stages[level].Gate
	eq(gate:GetAttribute("Level"), level, "gate level " .. level)
	eq(gate:GetAttribute("Checkpoint"), CheckpointRules.hasCheckpoint(level), "gate checkpoint flag " .. level)
end

-- Limbo bars: walkable under (hitbox 5.6 tall from 0.2 below the feet), never jumpable under
do
	local count = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "LimboBar" then
			count += 1
			local level = d:FindFirstAncestorWhichIsA("Model")
			local stage = stages[level:GetAttribute("Level")]
			local localPos = stage.Origin:PointToObjectSpace(d.CFrame.Position)
			-- floor under the bar = highest route node containing it
			local floorY = -math.huge
			for _, node in stage.Route do
				if math.abs(localPos.X - node.Top.X) <= node.Size.X / 2 and math.abs(localPos.Z - node.Top.Z) <= node.Size.Z / 2 and node.Top.Y < localPos.Y then
					floorY = math.max(floorY, node.Top.Y)
				end
			end
			local clearance = localPos.Y - d.Size.Y / 2 - floorY
			check(clearance >= 5.4 + 0.5, ("limbo bar in level %d too low (%.2f)"):format(level:GetAttribute("Level"), clearance))
			check(clearance <= 5.4 - 0.2 + J.MaxHeight - 1, ("limbo bar in level %d can be jumped under (%.2f)"):format(level:GetAttribute("Level"), clearance))
		end
	end
	check(count > 0, "limbo bars found")
end

-- Part budget per level (mobile)
do
	for level = 1, highest do
		local parts = 0
		for _, d in stages[level].Model:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		local limit = if CheckpointRules.isFinalStage(level) or level == 1 then 400 else 150
		check(parts <= limit, ("level %d uses %d parts (limit %d)"):format(level, parts, limit))
	end
end

print(("\n%d passed, %d failed"):format(passes, failures))
process.exit(if failures == 0 then 0 else 1)
