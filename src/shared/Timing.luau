--[[
	Timing
	Deterministic cycle maths. Every periodic obstacle derives its state from
	the SERVER clock (workspace:GetServerTimeNow()), so:
	  - all clients see the same phase (fair, readable, learnable patterns)
	  - no network traffic is needed to keep obstacles in sync
	  - an obstacle that streams in / out resumes at the right phase
]]

local Timing = {}

function Timing.now(): number
	return workspace:GetServerTimeNow()
end

function Timing.ease(style: string, a: number): number
	if style == "Linear" then
		return a
	end
	-- Sine in-out: soft departure and arrival, readable and easy to land on
	return (1 - math.cos(math.pi * a)) / 2
end

-- Position in [0, 1) of a loop of length `period`, DELAYED by `phase` (0..1):
-- an obstacle with phase 0.25 does everything a quarter of a cycle later than
-- one with phase 0. Chaining phases 0, 1/3, 2/3 makes a wave moving forward.
function Timing.loop(t: number, period: number, phase: number?): number
	if period <= 0 then
		return 0
	end
	return ((t / period) - (phase or 0)) % 1
end

--[[
	Ping-pong with holds at both ends. Cycle layout (length = period):
	  [ travel out | hold at 1 | travel back | hold at 0 ]
	Returns the eased alpha (0..1).
]]
function Timing.pingPong(t: number, period: number, pause: number, phase: number?, easing: string?): number
	pause = math.clamp(pause, 0, period / 2 - 0.05)
	local leg = (period - 2 * pause) / 2
	local u = Timing.loop(t, period, phase) * period
	local raw
	if u < leg then
		raw = u / leg
	elseif u < leg + pause then
		raw = 1
	elseif u < 2 * leg + pause then
		raw = 1 - (u - leg - pause) / leg
	else
		raw = 0
	end
	return Timing.ease(easing or "Sine", raw)
end

--[[
	Two-state cycle: ON for onTime, then OFF for offTime.
	Returns isOn, secondsUntilSwitch.
]]
function Timing.onOff(t: number, onTime: number, offTime: number, phase: number?): (boolean, number)
	local period = onTime + offTime
	local u = Timing.loop(t, period, phase) * period
	if u < onTime then
		return true, onTime - u
	end
	return false, period - u
end

return Timing
