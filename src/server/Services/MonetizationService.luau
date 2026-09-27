--[[
	MonetizationService
	Robux developer products (ids and prices: Config.Products):
	  SkipLevel      the buyer moves to his next checkpoint
	  KillEveryone   every other player is sent back to his checkpoint
	  ResetEveryone  every other player goes back to level 1

	Receipts are processed idempotently: a purchase id is only granted once
	(remembered in the buyer's profile, so it also holds across servers).
	Skips never count for leaderboards or the ★200 tag: BestLevel only grows
	from levels actually reached on foot (see CheckpointService).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local CheckpointRules = require(Shared.CheckpointRules)
local Net = require(Shared.Net)

local MonetizationService = {}

local MAX_REMEMBERED_RECEIPTS = 50

local services
local notify: RemoteEvent

local function announce(text: string)
	for _, player in Players:GetPlayers() do
		notify:FireClient(player, { Kind = "Announcement", Text = text })
	end
end

local GRANTS = {}

function GRANTS.SkipLevel(buyer: Player): boolean
	local data = services.DataService.get(buyer)
	if not data or services.SpeedrunService.getRun(buyer) then
		return false
	end
	local nextCp = CheckpointRules.nextCheckpoint(data.Checkpoint)
	if nextCp > services.StageService.getHighestCheckpoint() then
		return false -- nothing further is built yet
	end
	services.CheckpointService.skipTo(buyer, nextCp)
	return true
end

function GRANTS.KillEveryone(buyer: Player): boolean
	for _, player in Players:GetPlayers() do
		if player ~= buyer then
			notify:FireClient(player, { Kind = "ForcedDeath" })
		end
	end
	announce(("%s killed everyone!"):format(buyer.DisplayName))
	return true
end

function GRANTS.ResetEveryone(buyer: Player): boolean
	for _, player in Players:GetPlayers() do
		if player ~= buyer then
			services.CheckpointService.resetToStart(player)
		end
	end
	announce(("%s sent everyone back to level 1!"):format(buyer.DisplayName))
	return true
end

local function productKeyFor(productId: number): string?
	for key, product in Config.Products do
		if product.Id ~= 0 and product.Id == productId then
			return key
		end
	end
	return nil
end

local function processReceipt(receipt)
	local buyer = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = buyer and services.DataService.get(buyer)
	if not buyer or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.Receipts = data.Receipts or {}
	if table.find(data.Receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = productKeyFor(receipt.ProductId)
	local grant = key and GRANTS[key]
	if not grant then
		warn("[MonetizationService] unknown product " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, granted = pcall(grant, buyer)
	if not ok or not granted then
		warn("[MonetizationService] grant failed: " .. tostring(granted))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.Receipts, receipt.PurchaseId)
	while #data.Receipts > MAX_REMEMBERED_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.init(allServices)
	services = allServices
end

function MonetizationService.start()
	notify = Net.event("Notify")
	MarketplaceService.ProcessReceipt = processReceipt

	Net.event("PurchaseRequest").OnServerEvent:Connect(function(player, key)
		local product = typeof(key) == "string" and Config.Products[key]
		if not product then
			return
		end
		if product.Id == 0 then
			notify:FireClient(player, { Kind = "Announcement", Text = "This product is not set up yet (Config.Products)." })
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end)
end

return MonetizationService
