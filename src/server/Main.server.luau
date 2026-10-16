--[[
	Main (server entry point)
	Builds the world, then initialises and starts every service in order.
	PlayerDataService starts LAST so every other service has registered its
	"when a player's data loads" callbacks before anyone's data loads.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Services = script.Parent.Services
local WorldBuilder = require(script.Parent.World.WorldBuilder)

-- 1. Create all RemoteEvents/RemoteFunctions
Remotes.Event("StateUpdated")

-- 2. Generate the map
WorldBuilder.Build()

-- 3. Services
local order = {
	"PlayerDataService",
	"StateSync",
	"EconomyService",
	"AchievementService",
	"ProgressionService",
	"InventoryService",
	"LedgerService",
	"PlotService",
	"MuseumService",
	"SecurityService",
	"DiscoveryService",
	"ChallengeService",
	"ExcavationService",
	"PuzzleService",
	"ExplorationService",
	"VisitorService",
	"EquipmentService",
	"JailService",
	"HeistService",
	"MarketService",
	"TradeService",
	"HubService",
}

local modules = {}
for _, name in order do
	modules[name] = require(Services:WaitForChild(name)) :: any
end
for _, name in order do
	modules[name].Init()
end
for _, name in order do
	if name ~= "PlayerDataService" then
		modules[name].Start()
	end
end
modules.PlayerDataService.Start()

print("[MuseumTycoon] Server started.")
