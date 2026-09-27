--[[
	Config
	Global tuning values shared by server and client.
	Anything a designer may want to tweak without touching logic lives here.
]]

local Config = {}

Config.TOTAL_LEVELS = 200
Config.LEVELS_PER_ZONE = 20
Config.ZONE_COUNT = 10

-- Sentinel checkpoint meaning "level 200 completed" (the victory room spawn).
Config.FINISH_LEVEL = Config.TOTAL_LEVELS + 1

-- Character movement. Every jump in the game is designed against these numbers,
-- so they must never be modified by gameplay code (no paid speed/jump boosts).
Config.Character = {
	WalkSpeed = 16,
	JumpPower = 50,
	Gravity = 196.2,
}

-- Jump envelope derived from the character settings. Used by the level
-- validator (tests/) and documented in docs/MECHANICS.md.
do
	local c = Config.Character
	local airTime = 2 * c.JumpPower / c.Gravity
	Config.Jump = {
		MaxHeight = c.JumpPower ^ 2 / (2 * c.Gravity), -- ~6.37 studs
		AirTime = airTime, -- ~0.51 s on flat ground
		FlatDistance = c.WalkSpeed * airTime, -- ~8.15 studs travelled by the root part
		EdgeAllowance = 1.0, -- feet may hang over both edges a little
	}
end

Config.Respawn = {
	EffectTime = 0.2, -- death effect duration before the character is moved back
	Debounce = 0.35, -- minimum time between two deaths
	Invulnerable = 0.3, -- grace period after respawn
	VoidDepth = 40, -- studs below the lowest platform of a level = death
	HardRespawnTime = 0.5, -- Players.RespawnTime for real humanoid deaths
}

Config.Data = {
	StoreName = "Obby200_PlayerData_v1",
	KeyPrefix = "player_",
	AutosaveInterval = 60,
	SessionLockTimeout = 30 * 60,
	LoadRetries = 4,
	SaveRetries = 3,
}

Config.Leaderboards = {
	RefreshInterval = 120,
	WriteInterval = 150,
	Size = 10,
	Stores = {
		HighestLevel = "Obby200_LB_HighestLevel_v1",
		Completions = "Obby200_LB_Completions_v1",
		BestFullRun = "Obby200_LB_BestFullRun_v1", -- stored as milliseconds, ascending
		Deaths = "Obby200_LB_Deaths_v1",
	},
}

--[[
	Robux developer products. Create them on the Creator Hub
	(Creations → your experience → Monetization → Developer Products), set the
	price there, then paste each product id below. 0 = not configured (the
	button tells the player the product is unavailable).
]]
Config.Products = {
	SkipLevel = { Id = 0, Price = 17 }, -- move to the next checkpoint
	KillEveryone = { Id = 0, Price = 2500 }, -- everyone else back to their checkpoint
	ResetEveryone = { Id = 0, Price = 15000 }, -- everyone else back to level 1
}
-- ResetEveryone resets the SAVED checkpoint of the victims; their best level,
-- leaderboard entries and completions are kept.

Config.World = {
	-- World CFrame of level 1's start pad (top surface centre). Local +Z of every
	-- level frame is "forward".
	Origin = CFrame.new(0, 120, 0),
	FolderName = "Obby",
}

Config.Obstacles = {
	-- Client obstacles further than this from the camera are not animated.
	-- Their state is a pure function of server time, so they snap back into
	-- the correct phase as soon as they are in range again.
	ActiveRadius = 260,
	ActiveRefresh = 0.25,
	SoundRadius = 55,
}

return Config
