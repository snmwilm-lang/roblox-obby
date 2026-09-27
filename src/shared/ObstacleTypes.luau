--[[
	ObstacleTypes
	Schema of every modular obstacle component.

	An obstacle is ANY Part or Model carrying a CollectionService tag equal to a
	component name below. Its parameters are Instance attributes; missing
	attributes fall back to these defaults. This is what lets 200 levels be built
	from a handful of generic, centrally updated systems instead of 200 scripts.

	Example (Studio or LevelBuilder):
	    part:AddTag("MovingPlatform")
	    part:SetAttribute("Travel", Vector3.new(0, 0, 20))
	    part:SetAttribute("Period", 6)
]]

local ObstacleTypes = {}

ObstacleTypes.Schemas = {
	-- Static kill brick. Also used on parts of other components (spinner arms...)
	Hazard = {},

	-- Ping-pong between its base position and base + Travel (world space)
	MovingPlatform = {
		Travel = Vector3.new(0, 0, 10), -- world-space offset of the far end
		Period = 6, -- seconds for a full out-and-back cycle
		Pause = 0.5, -- seconds held at each end (part of Period)
		Phase = 0, -- 0..1 delay of the cycle (0.5 = half a cycle later)
		Easing = "Sine", -- "Sine" | "Linear"
		LoopType = "PingPong", -- "PingPong" | "Circle" (orbits the circle whose diameter is Travel)
	},

	-- Continuous rotation around its pivot (spinners, gears, laser sweeps)
	Rotator = {
		Axis = "Y", -- "X" | "Y" | "Z" (pivot-local)
		Speed = 45, -- degrees per second, negative = reverse
		Phase = 0, -- degrees
	},

	-- Laser beam with on/off cycle and a visible + audible warning
	Laser = {
		OnTime = 2,
		OffTime = 1.5,
		WarnTime = 0.6, -- part of OffTime: beam flickers thin before firing
		Phase = 0, -- 0..1 delay
	},

	-- Alternates solid / intangible on a fixed rhythm, blinks before vanishing
	GhostPlatform = {
		VisibleDuration = 2.5,
		InvisibleDuration = 1.5,
		PhaseOffset = 0, -- 0..1 delay of the full cycle (sequential platforms)
		WarnTime = 0.6,
	},

	-- Cracks, shakes and drops when the LOCAL player lands on it; returns later.
	-- Purely client-side: a player can never drop a platform for someone else.
	FallingPlatform = {
		FallDelay = 0.6, -- seconds between touch and fall (shake happens inside it)
		ShakeDuration = 0.45,
		RespawnDelay = 3,
	},

	-- Surface velocity (belts)
	Conveyor = {
		Speed = 12,
		Direction = Vector3.new(0, 0, 1), -- world space, normalised at runtime
	},

	-- Sets the character's vertical velocity when landed on
	JumpPad = {
		Power = 85, -- vertical velocity (studs/s). 50 = a normal jump
		Boost = Vector3.new(0, 0, 0), -- extra world-space velocity
	},

	-- Volume that scales gravity for the local player only
	GravityZone = {
		GravityMultiplier = 0.5, -- 0.5x, 1.5x, 2x...
		TransitionTime = 0.25,
	},
}

local function coerce(default: any, value: any): any
	if value == nil then
		return default
	end
	if typeof(default) ~= typeof(value) then
		return default
	end
	return value
end

-- Reads a component config from an instance's attributes, filling defaults.
function ObstacleTypes.read(instance: Instance, componentName: string): { [string]: any }
	local schema = ObstacleTypes.Schemas[componentName]
	assert(schema, "Unknown obstacle component " .. tostring(componentName))
	local config = {}
	for key, default in schema do
		config[key] = coerce(default, instance:GetAttribute(key))
	end
	return config
end

-- Writes a config onto an instance (used by the LevelBuilder).
function ObstacleTypes.apply(instance: Instance, componentName: string, config: { [string]: any }?)
	local schema = ObstacleTypes.Schemas[componentName]
	assert(schema, "Unknown obstacle component " .. tostring(componentName))
	instance:AddTag(componentName)
	if config then
		for key, value in config do
			if schema[key] == nil then
				warn(("[ObstacleTypes] %s has no parameter %q"):format(componentName, key))
			else
				instance:SetAttribute(key, value)
			end
		end
	end
end

return ObstacleTypes
