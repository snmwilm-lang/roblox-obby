--[[
	UIController
	Minimal HUD, built in code (no assets):
	  LEVEL 74 / 200
	  ZONE 4 — DIFFICULT
	  [zone progress: 20 segments, the final one in gold]
	plus zone banners, short toasts, the speedrun timer/countdown, a gravity
	indicator, the death flash and the victory screen.

	Touch-friendly: side buttons are ≥ 44 px, placed on the left edge, away
	from the thumbstick (bottom-left) and the jump button (bottom-right).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Zones = require(Shared.Zones)
local CheckpointRules = require(Shared.CheckpointRules)
local LevelPlan = require(Shared.LevelPlan)
local Palette = require(Shared.Palette)
local Net = require(Shared.Net)

local player = Players.LocalPlayer

local UIController = {}

local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(16, 16, 20)
local GOLD = Palette.Final.Color

local controllers
local gui: ScreenGui
local refs = {} :: { [string]: any }
local toastToken = 0
local bannerToken = 0
local lastLevel = 0
local lastCountdown = nil

----------------------------------------------------------------------------
-- Tiny UI helpers
----------------------------------------------------------------------------

local function create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextColor3 = WHITE,
		TextScaled = true,
		TextStrokeTransparency = 0.6,
	}
	for key, value in props do
		defaults[key] = value
	end
	return create("TextLabel", defaults)
end

local function corner(radius: number): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function fade(instance: GuiObject, visible: boolean, time: number)
	local goals = {}
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		goals.TextTransparency = if visible then 0 else 1
		goals.TextStrokeTransparency = if visible then 0.6 else 1
	end
	TweenService:Create(instance, TweenInfo.new(time), goals):Play()
end

local function formatTime(seconds: number): string
	seconds = math.max(0, seconds)
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	if minutes >= 60 then
		return ("%d:%02d:%05.2f"):format(minutes // 60, minutes % 60, rest)
	end
	return ("%d:%05.2f"):format(minutes, rest)
end

----------------------------------------------------------------------------
-- Build
----------------------------------------------------------------------------

local function buildTopPanel()
	local panel = create("Frame", {
		Name = "Top",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(340, 96),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	refs.Level = label({
		Name = "Level",
		Size = UDim2.new(1, 0, 0, 40),
		Text = "LEVEL 1 / 200",
		Parent = panel,
	})
	refs.Zone = label({
		Name = "Zone",
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = "ZONE 1 — EASY",
		Parent = panel,
	})

	local bar = create("Frame", {
		Name = "Progress",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 66),
		Size = UDim2.fromOffset(260, 6),
		BackgroundTransparency = 1,
		Parent = panel,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})
	refs.Segments = {}
	for i = 1, Config.LEVELS_PER_ZONE do
		refs.Segments[i] = create("Frame", {
			Name = "Segment" .. i,
			LayoutOrder = i,
			Size = UDim2.fromOffset(11, 6),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			Parent = bar,
		}, { corner(2) })
	end

	refs.Deaths = label({
		Name = "Deaths",
		Position = UDim2.fromOffset(0, 76),
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamMedium,
		TextTransparency = 0.25,
		Text = "",
		Parent = panel,
	})
	refs.Timer = label({
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 104),
		Size = UDim2.fromOffset(220, 30),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(140, 230, 255),
		Visible = false,
		Text = "0:00.00",
		Parent = gui,
	})
	refs.Gravity = label({
		Name = "Gravity",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 136),
		Size = UDim2.fromOffset(220, 22),
		Font = Enum.Font.GothamBold,
		TextColor3 = Palette.Gravity.Color,
		Visible = false,
		Text = "",
		Parent = gui,
	})
end

local function buildOverlays()
	refs.Flash = create("Frame", {
		Name = "DeathFlash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 40, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = gui,
	})
	refs.Toast = label({
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 34),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Text = "",
		Parent = gui,
	})
	refs.SubToast = label({
		Name = "SubToast",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 30),
		Size = UDim2.new(0.8, 0, 0, 20),
		Font = Enum.Font.GothamBold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Text = "",
		Parent = gui,
	})

	local banner = create("Frame", {
		Name = "ZoneBanner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(1, 0, 0, 150),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = gui,
	})
	refs.Banner = banner
	refs.BannerZone = label({ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 10), Font = Enum.Font.GothamBold, Parent = banner })
	refs.BannerName = label({ Size = UDim2.new(1, 0, 0, 64), Position = UDim2.fromOffset(0, 44), Parent = banner })
	refs.BannerRange = label({ Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 112), Font = Enum.Font.GothamMedium, Parent = banner })

	refs.Countdown = label({
		Name = "Countdown",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(300, 120),
		Visible = false,
		Text = "",
		Parent = gui,
	})

	refs.DataWarning = label({
		Name = "DataWarning",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(460, 18),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(255, 200, 120),
		Visible = false,
		Text = "Progress can't be saved right now (DataStores unavailable)",
		Parent = gui,
	})
end

local function sideButton(name: string, text: string, order: number, onClick: () -> ()): TextButton
	local button = create("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(104, 44),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.35,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = WHITE,
		TextSize = 14,
		Text = text,
		Parent = refs.Side,
	}, { corner(10) })
	button.Activated:Connect(function()
		controllers.AudioController.play("Click")
		onClick()
	end)
	return button
end

local function buildSideButtons()
	refs.Side = create("Frame", {
		Name = "Side",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.45, 0),
		Size = UDim2.fromOffset(104, 6 * 52),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	sideButton("Respawn", "RESPAWN", 1, function()
		controllers.RespawnController.die("Reset")
	end)
	sideButton("Shop", "SHOP", 6, function()
		refs.Shop.Visible = not refs.Shop.Visible
	end)
	refs.ShiftLockButton = sideButton("ShiftLock", "SHIFT LOCK", 5, function()
		controllers.ShiftLockController.toggle()
	end)
	controllers.ShiftLockController.Changed:Connect(function(on)
		refs.ShiftLockButton.Text = if on then "SHIFT LOCK ✓" else "SHIFT LOCK"
		refs.ShiftLockButton.BackgroundColor3 = if on then Color3.fromRGB(40, 110, 70) else DARK
	end)
	refs.SpeedrunButton = sideButton("Speedrun", "SPEEDRUN", 2, function()
		local active = player:GetAttribute("SpeedrunActive") == true
		Net.event("SpeedrunRequest"):FireServer(not active)
		if not active then
			UIController.toast("SPEEDRUN", "Timer starts at level 1 · your progress is kept", Color3.fromRGB(140, 230, 255), 3)
		end
	end)
	refs.MusicButton = sideButton("Music", "MUSIC ON", 3, function()
		controllers.SettingsController.set("Music", not controllers.SettingsController.get("Music"))
	end)
	refs.PlayersButton = sideButton("Players", "PLAYERS ON", 4, function()
		controllers.SettingsController.set("HideOthers", not controllers.SettingsController.get("HideOthers"))
	end)
end

local function buildShop()
	local panel = create("Frame", {
		Name = "Shop",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 124, 0.45, 0),
		Size = UDim2.fromOffset(260, 3 * 56 + 16),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = gui,
	}, {
		corner(12),
		create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	refs.Shop = panel
	local items = {
		{ "SkipLevel", "SKIP LEVEL", Color3.fromRGB(60, 150, 90) },
		{ "KillEveryone", "KILL EVERYONE", Color3.fromRGB(190, 50, 50) },
		{ "ResetEveryone", "EVERYONE TO LEVEL 1", Color3.fromRGB(120, 40, 160) },
	}
	for i, item in items do
		local product = Config.Products[item[1]]
		local button = create("TextButton", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = item[3],
			Font = Enum.Font.GothamBold,
			TextColor3 = WHITE,
			TextSize = 15,
			Text = ("%s   ·   %d R$"):format(item[2], product.Price),
			Parent = panel,
		}, { corner(10) })
		button.Activated:Connect(function()
			controllers.AudioController.play("Click")
			Net.event("PurchaseRequest"):FireServer(item[1])
		end)
	end
end

local function buildVictory()
	local panel = create("Frame", {
		Name = "Victory",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 300),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = gui,
	}, { corner(16), create("UIStroke", { Color = GOLD, Thickness = 2 }) })
	refs.Victory = panel
	label({ Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 18), Text = "LEVEL 200 COMPLETE", TextColor3 = GOLD, Parent = panel })
	label({ Size = UDim2.new(1, 0, 0, 90), Position = UDim2.fromOffset(0, 58), Text = "200 / 200", Parent = panel })
	refs.VictoryInfo = label({ Size = UDim2.new(1, -40, 0, 44), Position = UDim2.fromOffset(20, 152), Font = Enum.Font.GothamMedium, Text = "", Parent = panel })
	local restart = create("TextButton", {
		Size = UDim2.fromOffset(200, 44),
		Position = UDim2.new(0.5, -210, 1, -64),
		BackgroundColor3 = GOLD,
		Font = Enum.Font.GothamBlack,
		TextColor3 = DARK,
		TextSize = 16,
		Text = "PLAY AGAIN",
		Parent = panel,
	}, { corner(10) })
	restart.Activated:Connect(function()
		panel.Visible = false
		Net.event("RestartRequest"):FireServer()
	end)
	local close = create("TextButton", {
		Size = UDim2.fromOffset(200, 44),
		Position = UDim2.new(0.5, 10, 1, -64),
		BackgroundColor3 = Color3.fromRGB(60, 60, 70),
		Font = Enum.Font.GothamBold,
		TextColor3 = WHITE,
		TextSize = 16,
		Text = "STAY HERE",
		Parent = panel,
	}, { corner(10) })
	close.Activated:Connect(function()
		panel.Visible = false
	end)
end

----------------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------------

function UIController.toast(text: string, subtitle: string?, color: Color3?, duration: number?)
	toastToken += 1
	local token = toastToken
	refs.Toast.Text = text
	refs.Toast.TextColor3 = color or WHITE
	refs.SubToast.Text = subtitle or ""
	fade(refs.Toast, true, 0.15)
	fade(refs.SubToast, subtitle ~= nil, 0.15)
	task.delay(duration or 2, function()
		if token == toastToken then
			fade(refs.Toast, false, 0.5)
			fade(refs.SubToast, false, 0.5)
		end
	end)
end

function UIController.flashDeath()
	refs.Flash.BackgroundTransparency = 0.55
	TweenService:Create(refs.Flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
end

function UIController.setGravity(multiplier: number)
	if not refs.Gravity then
		return
	end
	refs.Gravity.Visible = math.abs(multiplier - 1) > 0.01
	refs.Gravity.Text = ("GRAVITY %s×"):format((("%.2f"):format(multiplier)):gsub("%.?0+$", ""))
end

function UIController.zoneBanner(zoneId: number)
	local zone = Zones[zoneId]
	if not zone then
		return
	end
	bannerToken += 1
	local token = bannerToken
	local first, last = CheckpointRules.zoneRange(zoneId)
	refs.BannerZone.Text = "ZONE " .. zoneId
	refs.BannerZone.TextColor3 = zone.Accent
	refs.BannerName.Text = zone.Name
	refs.BannerRange.Text = ("LEVELS %d–%d  ·  %s"):format(first, last, zone.Difficulty)
	refs.Banner.Visible = true
	refs.Banner.BackgroundTransparency = 1
	for _, text in { refs.BannerZone, refs.BannerName, refs.BannerRange } do
		text.TextTransparency = 1
		fade(text, true, 0.4)
	end
	TweenService:Create(refs.Banner, TweenInfo.new(0.4), { BackgroundTransparency = 0.45 }):Play()
	controllers.AudioController.play("ZoneBanner")
	task.delay(2.6, function()
		if token ~= bannerToken then
			return
		end
		for _, text in { refs.BannerZone, refs.BannerName, refs.BannerRange } do
			fade(text, false, 0.6)
		end
		local out = TweenService:Create(refs.Banner, TweenInfo.new(0.6), { BackgroundTransparency = 1 })
		out:Play()
		out.Completed:Once(function()
			if token == bannerToken then
				refs.Banner.Visible = false
			end
		end)
	end)
end

function UIController.setButtonState(name: string, on: boolean)
	if name == "Music" then
		refs.MusicButton.Text = if on then "MUSIC ON" else "MUSIC OFF"
	elseif name == "HideOthers" then
		refs.PlayersButton.Text = if on then "PLAYERS OFF" else "PLAYERS ON"
	end
end

----------------------------------------------------------------------------
-- State binding
----------------------------------------------------------------------------

local function refreshLevel()
	local level = player:GetAttribute("CurrentLevel") or 1
	local zoneId = CheckpointRules.zoneOf(level)
	local zone = Zones[zoneId]
	local isFinal = CheckpointRules.isFinalStage(level)

	refs.Level.Text = ("LEVEL %d / %d"):format(level, Config.TOTAL_LEVELS)
	refs.Level.TextColor3 = if isFinal then GOLD else WHITE
	refs.Zone.Text = ("ZONE %d — %s"):format(zoneId, zone.Difficulty)
	refs.Zone.TextColor3 = zone.DifficultyColor

	local index = CheckpointRules.indexInZone(level)
	for i, segment in refs.Segments do
		local final = i == Config.LEVELS_PER_ZONE
		if i < index then
			segment.BackgroundColor3 = zone.DifficultyColor
			segment.BackgroundTransparency = 0.05
		elseif i == index then
			segment.BackgroundColor3 = WHITE
			segment.BackgroundTransparency = 0
		else
			segment.BackgroundColor3 = if final then GOLD else WHITE
			segment.BackgroundTransparency = if final then 0.3 else 0.75
		end
	end

	if level > lastLevel and lastLevel ~= 0 and not isFinal then
		UIController.toast(string.upper(LevelPlan.name(level)), nil, WHITE, 1.8)
	end
	lastLevel = level
end

local function refreshDeaths()
	local deaths = player:GetAttribute("Deaths")
	refs.Deaths.Text = if deaths then ("DEATHS %d"):format(deaths) else ""
end

local function onNotify(message)
	local kind = message.Kind
	if kind == "LevelComplete" then
		if CheckpointRules.isFinalStage(message.Level) then
			return -- ZoneComplete handles it
		end
		controllers.AudioController.play("Checkpoint")
	elseif kind == "ZoneComplete" then
		controllers.AudioController.play("FinalComplete")
		UIController.toast(("LEVEL %d COMPLETE"):format(message.Level), ("ZONE %d CLEARED"):format(message.Zone), GOLD, 3.5)
	elseif kind == "FinalStage" then
		controllers.AudioController.play("FinalStage")
		UIController.toast("FINAL STAGE", ("LEVEL %d · NO CHECKPOINT"):format(message.Level), GOLD, 2.5)
	elseif kind == "Split" then
		local text = ("ZONE %d SPLIT  %s"):format(message.Zone, formatTime(message.Time))
		UIController.toast(text, if message.Record then "NEW PERSONAL BEST" else ("best " .. formatTime(message.Best)), Color3.fromRGB(140, 230, 255), 3)
	elseif kind == "RunFinished" then
		refs.VictoryInfo.Text = ("Full run: %s%s"):format(formatTime(message.Time), if message.Record then "  (NEW BEST)" else "")
	elseif kind == "Announcement" then
		UIController.toast(string.upper(message.Text), nil, Color3.fromRGB(255, 210, 120), 3)
	elseif kind == "Victory" then
		controllers.AudioController.play("Victory")
		refs.VictoryInfo.Text = ("Completions: %d"):format(message.Completions)
		refs.Victory.Visible = true
	end
end

local function updateTimer()
	local active = player:GetAttribute("SpeedrunActive") == true
	local start = player:GetAttribute("SpeedrunStart")
	refs.SpeedrunButton.Text = if active then "STOP RUN" else "SPEEDRUN"
	refs.Timer.Visible = active and typeof(start) == "number"
	if not refs.Timer.Visible then
		refs.Countdown.Visible = false
		lastCountdown = nil
		return
	end
	local elapsed = workspace:GetServerTimeNow() - start
	if elapsed < 0 then
		local n = math.ceil(-elapsed)
		refs.Countdown.Visible = true
		refs.Countdown.Text = tostring(n)
		if lastCountdown ~= n then
			lastCountdown = n
			controllers.AudioController.play("Countdown")
		end
		refs.Timer.Text = formatTime(0)
	else
		if lastCountdown ~= 0 and lastCountdown ~= nil then
			lastCountdown = 0
			controllers.AudioController.play("Go")
		end
		refs.Countdown.Visible = elapsed < 0.7
		refs.Countdown.Text = "GO!"
		refs.Timer.Text = formatTime(elapsed)
	end
end

function UIController.init(allControllers)
	controllers = allControllers
end

function UIController.start()
	gui = create("ScreenGui", {
		Name = "ObbyHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local scale = create("UIScale", { Parent = gui })
	local function rescale()
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(viewport.X / 1100, viewport.Y / 700), 0.62, 1.15)
	end
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	buildTopPanel()
	buildOverlays()
	buildSideButtons()
	buildShop()
	buildVictory()

	player:GetAttributeChangedSignal("CurrentLevel"):Connect(refreshLevel)
	player:GetAttributeChangedSignal("Deaths"):Connect(refreshDeaths)
	player:GetAttributeChangedSignal("DataPersistent"):Connect(function()
		refs.DataWarning.Visible = player:GetAttribute("DataPersistent") == false
	end)
	refreshLevel()
	refreshDeaths()
	refs.DataWarning.Visible = player:GetAttribute("DataPersistent") == false

	Net.event("Notify").OnClientEvent:Connect(onNotify)
	RunService.RenderStepped:Connect(updateTimer)
end

return UIController
