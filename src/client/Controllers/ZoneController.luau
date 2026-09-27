--[[
	ZoneController
	Visual identity per zone, applied locally with smooth transitions when the
	player's CurrentLevel enters another zone: lighting, atmosphere, colour
	grading, bloom, clouds, music. Also triggers the zone banner.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared.Zones)
local CheckpointRules = require(Shared.CheckpointRules)

local player = Players.LocalPlayer

local ZoneController = {}

local TRANSITION = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local controllers
local currentZone = 0
local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local bloom: BloomEffect
local clouds: Clouds?

local function getOrCreate(parent: Instance, className: string, name: string): any
	local existing = parent:FindFirstChildOfClass(className)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

local function apply(zoneId: number, instant: boolean)
	local zone = Zones[zoneId]
	if not zone then
		return
	end
	local preset = zone.Lighting
	local info = if instant then TweenInfo.new(0) else TRANSITION
	local function tween(instance: Instance, goals)
		TweenService:Create(instance, info, goals):Play()
	end
	tween(Lighting, {
		ClockTime = preset.ClockTime,
		Brightness = preset.Brightness,
		Ambient = preset.Ambient,
		OutdoorAmbient = preset.OutdoorAmbient,
		ExposureCompensation = preset.ExposureCompensation,
	})
	tween(atmosphere, preset.Atmosphere)
	tween(colorCorrection, preset.ColorCorrection)
	tween(bloom, preset.Bloom)
	if clouds then
		clouds.Enabled = preset.Clouds.Cover > 0
		tween(clouds, preset.Clouds)
	end
end

local function onLevelChanged()
	local level = player:GetAttribute("CurrentLevel")
	if typeof(level) ~= "number" then
		return
	end
	local zoneId = CheckpointRules.zoneOf(level)
	if zoneId == currentZone then
		return
	end
	local first = currentZone == 0
	currentZone = zoneId
	apply(zoneId, first)
	controllers.AudioController.playZoneMusic(zoneId)
	controllers.UIController.zoneBanner(zoneId)
end

function ZoneController.getZone(): number
	return currentZone
end

function ZoneController.init(allControllers)
	controllers = allControllers
end

function ZoneController.start()
	atmosphere = getOrCreate(Lighting, "Atmosphere", "ZoneAtmosphere")
	colorCorrection = getOrCreate(Lighting, "ColorCorrectionEffect", "ZoneGrade")
	bloom = getOrCreate(Lighting, "BloomEffect", "ZoneBloom")
	local ok, result = pcall(getOrCreate, workspace.Terrain, "Clouds", "ZoneClouds")
	clouds = if ok then result else nil

	player:GetAttributeChangedSignal("CurrentLevel"):Connect(onLevelChanged)
	onLevelChanged()
end

return ZoneController
