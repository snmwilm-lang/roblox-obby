--[[
	LeaderboardService
	- leaderstats (player list): Level, Deaths
	- global boards (OrderedDataStore) rendered on the hub's board parts:
	    Highest Level, Total Completions, Best Full Run (ascending), Deaths
	Writes are throttled per player; boards refresh every couple of minutes.
	Nothing here can be bought: every stat comes from play.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local CheckpointRules = require(Shared.CheckpointRules)
local Palette = require(Shared.Palette)

local LeaderboardService = {}

local BOARDS = {
	HighestLevel = { Title = "HIGHEST LEVEL", Ascending = false },
	Completions = { Title = "COMPLETIONS", Ascending = false },
	BestFullRun = { Title = "BEST FULL RUN", Ascending = true },
	Deaths = { Title = "MOST DEATHS", Ascending = false },
}

local services
local stores: { [string]: OrderedDataStore } = {}
local lastWrite: { [Player]: number } = {}
local lastWritten: { [Player]: { [string]: number } } = {}
local nameCache: { [number]: string } = {}

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	if minutes >= 60 then
		return ("%d:%02d:%05.2f"):format(minutes // 60, minutes % 60, rest)
	end
	return ("%d:%05.2f"):format(minutes, rest)
end

local function statsFor(player: Player): { [string]: number }?
	local data = services.DataService.get(player)
	if not data then
		return nil
	end
	return {
		HighestLevel = CheckpointRules.displayLevel(data.BestLevel),
		Completions = data.Completions,
		BestFullRun = if data.BestFullRun then math.floor(data.BestFullRun * 1000) else nil,
		Deaths = data.Deaths,
	}
end

local function ensureLeaderstats(player: Player)
	local folder = player:FindFirstChild("leaderstats")
	if folder then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	for _, name in { "Level", "Deaths" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = folder
	end
	folder.Parent = player
	return folder
end

-- Refresh leaderstats immediately; push to global boards when throttling allows.
function LeaderboardService.updateStats(player: Player, force: boolean?)
	local stats = statsFor(player)
	if not stats then
		return
	end
	local folder = ensureLeaderstats(player)
	folder.Level.Value = CheckpointRules.displayLevel(player:GetAttribute("Checkpoint") or 1)
	folder.Deaths.Value = stats.Deaths

	if next(stores) == nil then
		return
	end
	local now = os.clock()
	if not force and lastWrite[player] and now - lastWrite[player] < Config.Leaderboards.WriteInterval then
		return
	end
	lastWrite[player] = now
	local previous = lastWritten[player] or {}
	lastWritten[player] = previous
	local key = tostring(player.UserId)
	task.spawn(function()
		for boardName, store in stores do
			local value = stats[boardName]
			if value ~= nil and previous[boardName] ~= value then
				local ok, err = pcall(function()
					store:SetAsync(key, value)
				end)
				if ok then
					previous[boardName] = value
				else
					warn("[LeaderboardService] write failed: " .. tostring(err))
				end
			end
		end
	end)
end

local function getName(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = if ok then name else ("#" .. userId)
	return nameCache[userId]
end

local function renderBoard(part: BasePart, title: string, rows: { { string } }?, message: string?)
	local gui = part:FindFirstChild("BoardGui") :: SurfaceGui?
	if not gui then
		gui = Instance.new("SurfaceGui")
		gui.Name = "BoardGui"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.MaxDistance = 100
		gui.Parent = part
	end
	gui:ClearAllChildren()

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	background.BackgroundTransparency = 0.1
	background.Parent = gui

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromScale(1, 0.14)
	header.Font = Enum.Font.GothamBlack
	header.TextScaled = true
	header.TextColor3 = Palette.Final.Color
	header.Text = title
	header.Parent = background

	if message then
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.05, 0.4)
		label.Size = UDim2.fromScale(0.9, 0.2)
		label.Font = Enum.Font.GothamMedium
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.Text = message
		label.Parent = background
		return
	end

	for i, row in rows or {} do
		local line = Instance.new("TextLabel")
		line.BackgroundTransparency = 1
		line.Position = UDim2.fromScale(0.06, 0.16 + (i - 1) * 0.082)
		line.Size = UDim2.fromScale(0.88, 0.075)
		line.Font = if i <= 3 then Enum.Font.GothamBold else Enum.Font.GothamMedium
		line.TextScaled = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextColor3 = if i == 1 then Palette.Final.Color else Color3.new(1, 1, 1)
		line.Text = ("%d.  %s"):format(i, row[1])
		line.Parent = background

		local value = line:Clone()
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.Text = row[2]
		value.Parent = background
	end
end

local function refreshBoards()
	for _, part in CollectionService:GetTagged("LeaderboardBoard") do
		local boardName = part:GetAttribute("Board")
		local board = BOARDS[boardName]
		local store = stores[boardName]
		if board and part:IsA("BasePart") then
			if not store then
				renderBoard(part, board.Title, nil, "Leaderboards need DataStore access\n(publish the place / enable API services)")
			else
				local ok, pages = pcall(function()
					return store:GetSortedAsync(board.Ascending, Config.Leaderboards.Size)
				end)
				if ok then
					local rows = {}
					for _, entry in pages:GetCurrentPage() do
						local text = if boardName == "BestFullRun" then formatTime(entry.value / 1000) else tostring(entry.value)
						if boardName == "HighestLevel" and entry.value >= Config.TOTAL_LEVELS then
							text = "★ " .. text
						end
						table.insert(rows, { getName(tonumber(entry.key) or 0), text })
					end
					renderBoard(part, board.Title, rows, if #rows == 0 then "No entries yet" else nil)
				else
					warn("[LeaderboardService] read failed: " .. tostring(pages))
				end
			end
		end
	end
end

function LeaderboardService.init(allServices)
	services = allServices
	for boardName, storeName in Config.Leaderboards.Stores do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(storeName)
		end)
		if ok then
			stores[boardName] = store
		end
	end
end

function LeaderboardService.start()
	Players.PlayerAdded:Connect(ensureLeaderstats)
	for _, player in Players:GetPlayers() do
		ensureLeaderstats(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastWrite[player] = nil
		lastWritten[player] = nil
	end)

	task.spawn(function()
		while true do
			refreshBoards()
			task.wait(Config.Leaderboards.RefreshInterval)
		end
	end)
end

return LeaderboardService
