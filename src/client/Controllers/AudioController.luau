--[[
	AudioController
	Sound is gameplay information here: every obstacle state change that can
	kill you or change your movement has a sound (ghost blink, laser charge,
	crack before a fall, gravity switch...).

	Default ids are engine-bundled rbxasset sounds so the game has feedback out
	of the box. Swap any of them for Creator Store assets in this table.
	Zone music/ambience ids live in Shared/Zones (empty = silent).
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)

local AudioController = {}

local SOUNDS = {
	Death = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.45, Speed = 1.15 },
	Checkpoint = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Speed = 1 },
	FinalComplete = { Id = "rbxasset://sounds/victory.wav", Volume = 0.6, Speed = 1 },
	Victory = { Id = "rbxasset://sounds/victory.wav", Volume = 0.8, Speed = 0.9 },
	FinalStage = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Speed = 0.6 },
	GhostWarn = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Speed = 1.2 },
	LaserCharge = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.4, Speed = 0.5 },
	Crack = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.8, Speed = 0.55 },
	JumpPad = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.6, Speed = 1.2 },
	GravitySwitch = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.5, Speed = 0.6 },
	ZoneBanner = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.6, Speed = 0.45 },
	Countdown = { Id = "rbxasset://sounds/button.wav", Volume = 0.6, Speed = 1 },
	Go = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.7, Speed = 1.4 },
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.4, Speed = 1.1 },
}

local controllers
local sfxGroup: SoundGroup
local musicGroup: SoundGroup
local templates: { [string]: Sound } = {}
local musicSound: Sound? = nil
local ambienceSound: Sound? = nil
local currentZone = 0
local sfxEnabled = true
local musicEnabled = true

local function makeGroup(name: string, volume: number): SoundGroup
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = volume
	group.Parent = SoundService
	return group
end

local function template(name: string): Sound?
	local existing = templates[name]
	if existing then
		return existing
	end
	local def = SOUNDS[name]
	if not def or def.Id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = def.Id
	sound.Volume = def.Volume
	sound.PlaybackSpeed = def.Speed
	sound.SoundGroup = sfxGroup
	sound.Parent = sfxGroup
	templates[name] = sound
	return sound
end

function AudioController.play(name: string)
	if not sfxEnabled then
		return
	end
	local sound = template(name)
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

-- Positional sound, skipped when far from the camera (performance).
function AudioController.playAt(name: string, position: Vector3)
	if not sfxEnabled then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera or (camera.Focus.Position - position).Magnitude > Config.Obstacles.SoundRadius then
		return
	end
	local source = template(name)
	if not source then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	local sound = source:Clone()
	sound.RollOffMaxDistance = Config.Obstacles.SoundRadius
	sound.Parent = attachment
	sound:Play()
	task.delay(3, function()
		attachment:Destroy()
	end)
end

local function crossfade(old: Sound?, soundId: string, volume: number, looped: boolean): Sound?
	if old then
		local fade = TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 })
		fade:Play()
		fade.Completed:Once(function()
			old:Destroy()
		end)
	end
	if soundId == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Looped = looped
	sound.Volume = 0
	sound.SoundGroup = musicGroup
	sound.Parent = musicGroup
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(2), { Volume = volume }):Play()
	return sound
end

function AudioController.playZoneMusic(zoneId: number)
	if zoneId == currentZone then
		return
	end
	currentZone = zoneId
	local zone = Zones[zoneId]
	if not zone then
		return
	end
	musicSound = crossfade(musicSound, zone.Music.SoundId, zone.Music.Volume, true)
	ambienceSound = crossfade(ambienceSound, zone.Ambience.SoundId, zone.Ambience.Volume, true)
end

function AudioController.setMusicEnabled(enabled: boolean)
	musicEnabled = enabled
	musicGroup.Volume = if enabled then 1 else 0
end

function AudioController.isMusicEnabled(): boolean
	return musicEnabled
end

function AudioController.setSfxEnabled(enabled: boolean)
	sfxEnabled = enabled
end

function AudioController.init(allControllers)
	controllers = allControllers
end

function AudioController.start()
	sfxGroup = makeGroup("ObbySfx", 1)
	musicGroup = makeGroup("ObbyMusic", 1)
	for name in SOUNDS do
		template(name)
	end
end

return AudioController
