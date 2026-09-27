--[[
	LevelBuilder
	Small DSL used by every level definition. A level is authored in its own
	local frame:
	  - origin (0,0,0) = top-centre of the level's start pad
	  - +Z = forward, +Y = up, +X = right (seen from the spawn)

	Position conventions (important):
	  Step / Pad / Mover / Ghost / Falling / Conveyor / JumpPad  -> pos = TOP-CENTRE
	      (the surface you stand on, so heights read like a staircase)
	  Kill / Wall / Truss / decoration / volumes                   -> pos = CENTRE

	Every "route" platform is recorded in order so tests/ can check that each
	jump of the intended path is physically possible (see tests/validate_levels).
	Route parts must only use yaw rotations that are multiples of 90°.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Palette = require(Shared.Palette)
local ObstacleTypes = require(Shared.ObstacleTypes)
local CheckpointRules = require(Shared.CheckpointRules)
local LevelPlan = require(Shared.LevelPlan)

local START_PAD_SIZE = Vector3.new(14, 2, 14)

export type RouteNode = {
	Kind: string, -- "Static" | "Mover" | "Ghost" | "Falling"
	Top: Vector3, -- level-local top-centre
	Size: Vector3, -- footprint (X, thickness, Z) in level-local axes
	Travel: Vector3?, -- level-local travel for movers
	Part: BasePart?,
}

local LevelBuilder = {}
LevelBuilder.__index = LevelBuilder

LevelBuilder.START_PAD_SIZE = START_PAD_SIZE

local function rotationFrom(rot: Vector3?): CFrame
	if not rot then
		return CFrame.identity
	end
	return CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
end

local function footprint(size: Vector3, rot: Vector3?): Vector3
	if rot and math.abs(rot.Y % 180 - 90) < 1 then
		return Vector3.new(size.Z, size.Y, size.X)
	end
	return size
end

function LevelBuilder.new(params: { level: number, origin: CFrame, parent: Instance, zone: any, theme: any? })
	local self = setmetatable({}, LevelBuilder)
	self.Level = params.level
	self.Zone = params.zone
	self.Theme = params.theme
	self.Origin = params.origin
	self.Plan = LevelPlan.get(params.level)
	self.Route = {} :: { RouteNode }
	self.ExitCFrame = nil :: CFrame?
	self._seed = params.level * 7919

	local model = Instance.new("Model")
	model.Name = ("Level_%03d"):format(params.level)
	model:SetAttribute("Level", params.level)
	model:SetAttribute("Zone", params.zone.Id)
	model.Parent = params.parent
	self.Model = model

	self:_buildStart()
	return self
end

-- Deterministic pseudo-random for decoration (same world on every server)
function LevelBuilder:Random(min: number, max: number): number
	self._seed = (self._seed * 1103515245 + 12345) % 2147483648
	return min + (self._seed / 2147483648) * (max - min)
end

function LevelBuilder:ToWorld(pos: Vector3, rot: Vector3?): CFrame
	return self.Origin * CFrame.new(pos) * rotationFrom(rot)
end

function LevelBuilder:_part(props: { [string]: any }, parent: Instance?): BasePart
	local className = props.ClassName or "Part"
	local part = Instance.new(className) :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "ClassName" then
			(part :: any)[key] = value
		end
	end
	part.Parent = parent or self.Model
	return part
end

local function makeDecor(part: BasePart)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

-- Shape-aware part (Block / Cylinder standing upright / Ball) at a CENTRE position
function LevelBuilder:_shaped(center: Vector3, size: Vector3, opts: { [string]: any }): BasePart
	local rot = opts.rot
	local cf = self:ToWorld(center, rot)
	local partSize = size
	local shape = opts.shape or "Block"
	if shape == "Cylinder" then
		-- Roblox cylinders extend along X: stand them upright
		partSize = Vector3.new(size.Y, size.X, size.Z)
		cf = cf * CFrame.Angles(0, 0, math.rad(90))
	end
	local part = self:_part({
		Name = opts.name or "Part",
		Size = partSize,
		CFrame = cf,
		Color = opts.color,
		Material = opts.material,
		Transparency = opts.transparency or 0,
	})
	if shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	elseif shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	end
	return part
end

function LevelBuilder:_route(kind: string, top: Vector3, size: Vector3, rot: Vector3?, part: BasePart?, travel: Vector3?)
	table.insert(self.Route, {
		Kind = kind,
		Top = top,
		Size = footprint(size, rot),
		Travel = travel,
		Part = part,
	})
end

----------------------------------------------------------------------------
-- Start pad, checkpoint, stage gate
----------------------------------------------------------------------------

function LevelBuilder:_buildStart()
	local level = self.Level
	local zone = self.Zone
	local isFinal = CheckpointRules.isFinalStage(level)
	local hasCheckpoint = CheckpointRules.hasCheckpoint(level)

	local pad = self:Step(Vector3.zero, START_PAD_SIZE, {
		name = "StartPad",
		color = zone.Structure.Color:Lerp(zone.Safe.Color, 0.35),
		material = Enum.Material.Cobblestone,
	})
	pad:SetAttribute("StartPad", level)

	-- Trigger covering the whole pad: impossible to walk past it without claiming.
	local gate = self:_part({
		Name = "StageGate",
		Size = Vector3.new(START_PAD_SIZE.X, 9, START_PAD_SIZE.Z),
		CFrame = self:ToWorld(Vector3.new(0, 4.5, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = true,
	})
	gate:SetAttribute("Level", level)
	gate:SetAttribute("Checkpoint", hasCheckpoint)
	gate:AddTag("StageGate")
	self.Gate = gate

	if hasCheckpoint then
		local disc = self:_shaped(Vector3.new(0, 0.06, 0), Vector3.new(9, 0.2, 9), {
			name = "CheckpointDisc",
			shape = "Cylinder",
			color = Palette.Checkpoint.Color,
			material = Palette.Checkpoint.Material,
		})
		makeDecor(disc)
		disc:SetAttribute("Level", level)
		disc:AddTag("CheckpointDisc")
		self:_levelLabel(disc, isFinal)
	else
		-- Final stage: no checkpoint. Gold frame + arch make it unmistakable.
		local marker = self:_part({
			Name = "FinalMarker",
			Size = Vector3.new(1, 1, 1),
			CFrame = self:ToWorld(Vector3.new(0, 0.5, 0)),
			Transparency = 1,
		})
		makeDecor(marker)
		self:_levelLabel(marker, true)
		self:GoldFrame(Vector3.zero, START_PAD_SIZE)
		self:Arch(Vector3.new(0, 0, START_PAD_SIZE.Z / 2 - 1), 12, "FINAL STAGE", Palette.Final.Color, "NO CHECKPOINT")
	end

	if CheckpointRules.isZoneStart(level) and level > 1 then
		self:GoldFrame(Vector3.zero, START_PAD_SIZE)
		self:Arch(Vector3.new(0, 0, -START_PAD_SIZE.Z / 2 + 1), 12, "ZONE " .. zone.Id, zone.Accent, zone.Name)
	end

	if CheckpointRules.isPreFinal(level) then
		self:Sign(Vector3.new(-5, 2.5, 5), ("%d → %d\nNO CHECKPOINT IN BETWEEN"):format(level, level + 1), {
			color = Palette.Final.Color,
		})
	end

	if self.Theme and self.Theme.decorateStart then
		self.Theme.decorateStart(self, START_PAD_SIZE)
	end
end

function LevelBuilder:_levelLabel(adornee: BasePart, isFinal: boolean)
	local gui = Instance.new("BillboardGui")
	gui.Name = "LevelLabel"
	gui.Size = UDim2.fromScale(10, 3.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Adornee = adornee
	gui.Parent = adornee

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.BackgroundTransparency = 1
	number.Size = UDim2.fromScale(1, 0.68)
	number.Font = Enum.Font.GothamBlack
	number.TextScaled = true
	number.Text = tostring(self.Level)
	number.TextColor3 = if isFinal then Palette.Final.Color else Color3.new(1, 1, 1)
	number.TextStrokeTransparency = 0.4
	number.Parent = gui

	local name = Instance.new("TextLabel")
	name.Name = "Title"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromScale(0, 0.68)
	name.Size = UDim2.fromScale(1, 0.32)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.Text = string.upper(self.Plan.Name)
	name.TextColor3 = Color3.fromRGB(235, 235, 235)
	name.TextStrokeTransparency = 0.5
	name.Parent = gui
end

----------------------------------------------------------------------------
-- Gameplay primitives
----------------------------------------------------------------------------

-- Safe platform on the intended route. pos = top-centre.
function LevelBuilder:Step(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = o.name or "Step",
		shape = o.shape,
		rot = o.rot,
		color = o.color or self.Zone.Safe.Color,
		material = o.material or self.Zone.Safe.Material,
	})
	if o.route ~= false then
		self:_route("Static", pos, size, o.rot, part)
	end
	return part
end

-- Safe platform that is NOT part of the validated route (side areas, hub).
function LevelBuilder:Pad(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = table.clone(opts or {})
	o.route = false
	return self:Step(pos, size, o)
end

-- Kill brick. pos = centre.
function LevelBuilder:Kill(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos, size, {
		name = o.name or "Kill",
		shape = o.shape,
		rot = o.rot,
		color = Palette.Hazard.Color,
		material = Palette.Hazard.Material,
	})
	part.CanTouch = false
	part:AddTag("Hazard")
	return part
end

-- Solid, safe, non-route geometry (walls, frames). pos = centre.
function LevelBuilder:Wall(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos, size, {
		name = o.name or "Wall",
		shape = o.shape,
		rot = o.rot,
		color = o.color or self.Zone.Structure.Color,
		material = o.material or self.Zone.Structure.Material,
		transparency = o.transparency,
	})
	part.CanTouch = false
	return part
end

--[[
	Moving platform (or moving hazard with opts.kill = true).
	pos = top-centre at alpha 0, travel = level-local offset of the far end.
	opts: period, pause, phase, easing, loop ("PingPong" | "Circle"), kill, route
]]
function LevelBuilder:Mover(pos: Vector3, size: Vector3, travel: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local isKill = o.kill == true
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = if isKill then "MovingHazard" else "MovingPlatform",
		shape = o.shape,
		rot = o.rot,
		color = if isKill then Palette.Hazard.Color else Palette.Moving.Color,
		material = if isKill then Palette.Hazard.Material else Palette.Moving.Material,
	})
	part.CanTouch = false
	ObstacleTypes.apply(part, "MovingPlatform", {
		Travel = self.Origin:VectorToWorldSpace(travel),
		Period = o.period or 6,
		Pause = o.pause or 0.5,
		Phase = o.phase or 0,
		Easing = o.easing or "Sine",
		LoopType = o.loop or "PingPong",
	})
	if isKill then
		part:AddTag("Hazard")
	elseif o.route ~= false then
		self:_route("Mover", pos, size, o.rot, part, travel)
	end
	return part
end

--[[
	Spinner: a hub with 1..4 kill arms rotating around the vertical axis.
	center = rotation centre at ARM height.
	opts: length, arms, speed (deg/s), phase (deg), thickness, bladeHeight, floorY, hubRadius
]]
function LevelBuilder:Spinner(center: Vector3, opts: { [string]: any }?): Model
	local o = opts or {}
	local length = o.length or 10
	local arms = o.arms or 1
	local thickness = o.thickness or 1
	local bladeHeight = o.bladeHeight or thickness
	local floorY = o.floorY or (center.Y - 1.6)
	local hubRadius = o.hubRadius or 1.5
	local hubTop = math.max(center.Y + bladeHeight / 2 + 0.5, floorY + 2)

	local model = Instance.new("Model")
	model.Name = "Spinner"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = self.Model

	local hubHeight = hubTop - floorY
	local hub = self:_part({
		Name = "Hub",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(hubHeight, hubRadius * 2, hubRadius * 2),
		CFrame = self:ToWorld(Vector3.new(center.X, floorY + hubHeight / 2, center.Z)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = self.Zone.Structure.Color,
		Material = Enum.Material.Metal,
		CanTouch = false,
	}, model)

	for i = 1, arms do
		local angle = (i - 1) * (360 / arms)
		local arm = self:_part({
			Name = "Arm",
			Size = Vector3.new(length, bladeHeight, thickness),
			CFrame = self:ToWorld(center, Vector3.new(0, angle, 0)) * CFrame.new(length / 2, 0, 0),
			Color = Palette.Hazard.Color,
			Material = Palette.Hazard.Material,
			CanTouch = false,
		}, model)
		arm:AddTag("Hazard")
	end

	model.PrimaryPart = hub
	model.WorldPivot = self:ToWorld(center)
	ObstacleTypes.apply(model, "Rotator", {
		Axis = "Y",
		Speed = o.speed or 45,
		Phase = o.phase or 0,
	})
	return model
end

-- Ghost platform (phases in and out). pos = top-centre.
function LevelBuilder:Ghost(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = "GhostPlatform",
		shape = o.shape,
		rot = o.rot,
		color = Palette.Ghost.Color,
		material = Palette.Ghost.Material,
		transparency = Palette.Ghost.Transparency,
	})
	part.CanTouch = false
	ObstacleTypes.apply(part, "GhostPlatform", {
		VisibleDuration = o.visible or 2.5,
		InvisibleDuration = o.invisible or 1.5,
		PhaseOffset = o.phase or 0,
		WarnTime = o.warn or 0.6,
	})
	if o.route ~= false then
		self:_route("Ghost", pos, size, o.rot, part)
	end
	return part
end

-- Falling platform. pos = top-centre.
function LevelBuilder:Falling(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = "FallingPlatform",
		shape = o.shape,
		rot = o.rot,
		color = Palette.Falling.Color,
		material = Palette.Falling.Material,
	})
	part.CanTouch = false
	ObstacleTypes.apply(part, "FallingPlatform", {
		FallDelay = o.fallDelay or 0.6,
		ShakeDuration = o.shake or 0.45,
		RespawnDelay = o.respawn or 3,
	})
	if o.route ~= false then
		self:_route("Falling", pos, size, o.rot, part)
	end
	return part
end

-- Conveyor belt. pos = top-centre, direction = level-local.
function LevelBuilder:Conveyor(pos: Vector3, size: Vector3, direction: Vector3, speed: number, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = "Conveyor",
		rot = o.rot,
		color = Palette.Conveyor.Color,
		material = Palette.Conveyor.Material,
	})
	part.CanTouch = false
	ObstacleTypes.apply(part, "Conveyor", {
		Speed = speed,
		Direction = self.Origin:VectorToWorldSpace(direction.Unit),
	})
	if o.route ~= false then
		self:_route("Static", pos, size, o.rot, part)
	end
	return part
end

-- Jump pad. pos = top-centre.
function LevelBuilder:JumpPad(pos: Vector3, size: Vector3, power: number, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos - Vector3.new(0, size.Y / 2, 0), size, {
		name = "JumpPad",
		shape = o.shape,
		color = Palette.JumpPad.Color,
		material = Palette.JumpPad.Material,
	})
	part.CanTouch = false
	ObstacleTypes.apply(part, "JumpPad", {
		Power = power,
		Boost = self.Origin:VectorToWorldSpace(o.boost or Vector3.zero),
	})
	if o.route ~= false then
		self:_route("Static", pos, size, nil, part)
	end
	return part
end

-- Gravity volume. pos = centre.
function LevelBuilder:GravityZone(pos: Vector3, size: Vector3, multiplier: number, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_part({
		Name = "GravityZone",
		Size = size,
		CFrame = self:ToWorld(pos),
		Color = Palette.Gravity.Color,
		Material = Palette.Gravity.Material,
		Transparency = 0.6,
		CanCollide = false,
		CanTouch = false,
		CanQuery = true,
	})
	ObstacleTypes.apply(part, "GravityZone", {
		GravityMultiplier = multiplier,
		TransitionTime = o.transition or 0.25,
	})
	return part
end

-- Truss. pos = centre.
function LevelBuilder:Truss(pos: Vector3, height: number, opts: { [string]: any }?): BasePart
	local o = opts or {}
	return self:_part({
		ClassName = "TrussPart",
		Name = "Truss",
		Size = Vector3.new(2, height, 2),
		CFrame = self:ToWorld(pos, o.rot),
		Color = o.color or self.Zone.Structure.Color,
		Material = Enum.Material.Metal,
	})
end

-- Solid force-field barrier (end of available content).
function LevelBuilder:Barrier(pos: Vector3, size: Vector3, text: string?): BasePart
	local part = self:_part({
		Name = "Barrier",
		Size = size,
		CFrame = self:ToWorld(pos),
		Color = Palette.Barrier.Color,
		Material = Palette.Barrier.Material,
		Transparency = 0.2,
		CanTouch = false,
	})
	if text then
		self:Sign(pos + Vector3.new(0, 0, -size.Z / 2 - 1.5), text, { width = math.min(size.X - 2, 14), height = 4 })
	end
	return part
end

----------------------------------------------------------------------------
-- Readability / signage
----------------------------------------------------------------------------

local function addSurfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3, pixelsPerStud: number)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = 0
	gui.MaxDistance = 120
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.84)
	label.Position = UDim2.fromScale(0.04, 0.08)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
	return gui
end

-- Wooden sign facing the player (front face looks toward -Z). pos = board centre.
function LevelBuilder:Sign(pos: Vector3, text: string, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local width = o.width or 8
	local height = o.height or 3
	local board = self:_part({
		Name = "Sign",
		Size = Vector3.new(width, height, 0.4),
		CFrame = self:ToWorld(pos, Vector3.new(0, o.yaw or 0, 0)),
		Color = Palette.Sign.Color,
		Material = Palette.Sign.Material,
	})
	makeDecor(board)
	addSurfaceText(board, Enum.NormalId.Front, text, o.color or Palette.Sign.Text, 40)
	if o.post ~= false then
		local postHeight = pos.Y - height / 2 - (o.groundY or 0)
		if postHeight > 0.2 then
			local post = self:_part({
				Name = "SignPost",
				Size = Vector3.new(0.4, postHeight, 0.4),
				CFrame = self:ToWorld(Vector3.new(pos.X, (o.groundY or 0) + postHeight / 2, pos.Z + 0.3)),
				Color = Palette.Sign.Color,
				Material = Palette.Sign.Material,
			})
			makeDecor(post)
		end
	end
	return board
end

-- Arch spanning the path, text on the approaching side. pos = bottom-centre.
function LevelBuilder:Arch(pos: Vector3, width: number, text: string, color: Color3, subtitle: string?)
	local height = 11
	for _, side in { -1, 1 } do
		local pillar = self:_part({
			Name = "ArchPillar",
			Size = Vector3.new(1.4, height, 1.4),
			CFrame = self:ToWorld(pos + Vector3.new(side * width / 2, height / 2, 0)),
			Color = self.Zone.Structure.Color,
			Material = self.Zone.Structure.Material,
		})
		makeDecor(pillar)
	end
	local beam = self:_part({
		Name = "ArchBeam",
		Size = Vector3.new(width + 1.4, 2.6, 1.4),
		CFrame = self:ToWorld(pos + Vector3.new(0, height + 1.3, 0)),
		Color = color,
		Material = Enum.Material.Neon,
	})
	makeDecor(beam)
	local label = self:_part({
		Name = "ArchLabel",
		Size = Vector3.new(width - 1, 2.4, 0.2),
		CFrame = self:ToWorld(pos + Vector3.new(0, height + 1.3, -0.8)),
		Color = Color3.fromRGB(20, 18, 16),
		Material = Enum.Material.SmoothPlastic,
	})
	makeDecor(label)
	local fullText = if subtitle then (text .. "  ·  " .. subtitle) else text
	addSurfaceText(label, Enum.NormalId.Front, fullText, color, 30)
end

-- Neon gold frame around a pad (final stages, zone gates). pos = top-centre of the pad.
function LevelBuilder:GoldFrame(pos: Vector3, size: Vector3)
	local t = 0.3
	local y = pos.Y + 0.05
	local strips = {
		{ Vector3.new(pos.X, y, pos.Z - size.Z / 2 + t / 2), Vector3.new(size.X, 0.12, t) },
		{ Vector3.new(pos.X, y, pos.Z + size.Z / 2 - t / 2), Vector3.new(size.X, 0.12, t) },
		{ Vector3.new(pos.X - size.X / 2 + t / 2, y, pos.Z), Vector3.new(t, 0.12, size.Z) },
		{ Vector3.new(pos.X + size.X / 2 - t / 2, y, pos.Z), Vector3.new(t, 0.12, size.Z) },
	}
	for _, s in strips do
		local strip = self:_part({
			Name = "GoldTrim",
			Size = s[2],
			CFrame = self:ToWorld(s[1]),
			Color = Palette.Final.Color,
			Material = Palette.Final.Material,
		})
		makeDecor(strip)
	end
end

-- Small plaque announcing a section of a final stage. pos = plaque centre.
function LevelBuilder:SectionLabel(pos: Vector3, text: string)
	return self:Sign(pos, text, { width = 7, height = 1.6, color = Palette.Final.Color, post = false })
end

----------------------------------------------------------------------------
-- Decoration helpers (non-colliding, non-queryable)
----------------------------------------------------------------------------

function LevelBuilder:Decor(pos: Vector3, size: Vector3, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local part = self:_shaped(pos, size, {
		name = o.name or "Decor",
		shape = o.shape,
		rot = o.rot,
		color = o.color or self.Zone.Structure.Color,
		material = o.material or self.Zone.Structure.Material,
		transparency = o.transparency,
	})
	makeDecor(part)
	if o.shadow == false then
		part.CastShadow = false
	end
	return part
end

----------------------------------------------------------------------------
-- Level end
----------------------------------------------------------------------------

-- Victory trigger + victory room spawn (level 200 only). pos = top-centre of the floor.
function LevelBuilder:FinishLine(pos: Vector3, size: Vector3)
	local gate = self:_part({
		Name = "FinishGate",
		Size = Vector3.new(size.X, 9, size.Z),
		CFrame = self:ToWorld(pos + Vector3.new(0, 4.5, 0)),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = true,
	})
	gate:SetAttribute("Level", Config.FINISH_LEVEL)
	gate:SetAttribute("Checkpoint", true)
	gate:AddTag("StageGate")
	local forward = self.Origin:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local spawnPos = (self:ToWorld(pos)).Position + Vector3.new(0, 3.4, 0)
	self.FinishGate = gate
	self.FinishSpawn = CFrame.lookAt(spawnPos, spawnPos + forward)
end

-- The next level's start pad will be placed at pos (top-centre), turned by yaw degrees.
function LevelBuilder:Exit(pos: Vector3, yaw: number?)
	self.ExitCFrame = self.Origin * CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	self.ExitLocal = pos
end

function LevelBuilder:Finish()
	local minY = math.huge
	for _, node in self.Route do
		minY = math.min(minY, node.Top.Y)
		if node.Travel then
			minY = math.min(minY, node.Top.Y + node.Travel.Y)
		end
	end
	if self.ExitLocal then
		minY = math.min(minY, self.ExitLocal.Y)
	end
	local voidY = (self.Origin * CFrame.new(0, minY, 0)).Position.Y - Config.Respawn.VoidDepth
	self.Model:SetAttribute("VoidY", voidY)

	local forward = self.Origin:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local spawnPos = self.Origin.Position + self.Origin.UpVector * 3.4
	local spawn = CFrame.lookAt(spawnPos, spawnPos + forward)
	-- Stored on the model so a baked (pre-built) world can be re-indexed
	self.Model:SetAttribute("SpawnCFrame", spawn)
	if self.FinishSpawn then
		self.Model:SetAttribute("FinishSpawn", self.FinishSpawn)
	end
	return {
		Level = self.Level,
		Model = self.Model,
		Gate = self.Gate,
		Spawn = spawn,
		Origin = self.Origin,
		Exit = self.ExitCFrame,
		ExitLocal = self.ExitLocal,
		Route = self.Route,
		VoidY = voidY,
		FinishGate = self.FinishGate,
		FinishSpawn = self.FinishSpawn,
	}
end

return LevelBuilder
