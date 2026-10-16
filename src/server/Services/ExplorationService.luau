--[[
	ExplorationService
	• Travel between your museum and exploration zones (menu or portals)
	• Visiting other players' museums
	All eligibility (zone level requirements etc.) is checked here on the server.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Zones = require(Shared.Zones)
local Upgrades = require(Shared.Upgrades)

local PlayerDataService = require(script.Parent.PlayerDataService)
local PlotService = require(script.Parent.PlotService)
local ProgressionService = require(script.Parent.ProgressionService)
local DiscoveryService = require(script.Parent.DiscoveryService)
local Net = require(script.Parent.Parent.Util.Net)
local Notifier = require(script.Parent.Parent.Util.Notifier)

local ExplorationService = {}

local TRAVEL_COOLDOWN = 2
local currentZone: { [Player]: string } = {}
local lastTravel: { [Player]: number } = {}

local function setZone(player: Player, zoneId: string)
	currentZone[player] = zoneId
	player:SetAttribute("Zone", zoneId)
	Net.Fire("ZoneChanged", player, zoneId)
end

function ExplorationService.GetZone(player: Player): string
	return currentZone[player] or "Museum"
end

local function arrivalCFrame(zoneId: string): CFrame?
	local world = workspace:FindFirstChild("World")
	local zone = world and world:FindFirstChild(zoneId)
	local arrival = zone and zone:FindFirstChild("ArrivalPoint", true)
	if arrival and arrival:IsA("BasePart") then
		return arrival.CFrame
	end
	return nil
end

function ExplorationService.TravelTo(player: Player, zoneId: any): (boolean, string?)
	if not Net.IsString(zoneId, 40) then
		return false, "Invalid destination"
	end
	local now = os.clock()
	if (lastTravel[player] or 0) + TRAVEL_COOLDOWN > now then
		return false, "Please wait a moment before travelling again"
	end
	local data = PlayerDataService.GetData(player)
	if not data or not player.Character then
		return false, "You can't travel right now"
	end
	if player:GetAttribute("Jailed") then
		return false, "You're in the holding cell. Wait out your sentence."
	end
	if player:GetAttribute("InHeist") then
		return false, "Finish or abort your heist first."
	end

	if zoneId == "Museum" then
		lastTravel[player] = now
		DiscoveryService.Cancel(player)
		if not PlotService.TeleportHome(player) then
			return false, "You don't have a museum yet"
		end
		setZone(player, "Museum")
		return true, "Welcome back to your museum!"
	end

	local zone = Zones.ById[zoneId]
	if not zone then
		return false, "Unknown destination"
	end
	if not zone.Built then
		return false, zone.Name .. " is coming in a future update!"
	end
	local level = Upgrades.ComputeLevel(data.Upgrades)
	if level < zone.RequiredLevel then
		return false, ("Reach Museum Level %d to explore %s"):format(zone.RequiredLevel, zone.Name)
	end
	local target = arrivalCFrame(zoneId)
	if not target then
		return false, "That zone isn't available right now"
	end
	lastTravel[player] = now
	DiscoveryService.Cancel(player)
	player.Character:PivotTo(target * CFrame.Angles(0, math.pi, 0))
	setZone(player, zoneId)
	ProgressionService.RecordZoneVisit(player, zoneId)
	return true, "Welcome to the " .. zone.Name .. "!"
end

function ExplorationService.VisitMuseum(player: Player, userId: any): (boolean, string?)
	if not Net.IsInt(userId, 1, 2 ^ 53) then
		return false, "Invalid player"
	end
	local target = Players:GetPlayerByUserId(userId)
	local plot = target and PlotService.GetPlot(target)
	if not target or not plot then
		return false, "That museum isn't open right now"
	end
	if player:GetAttribute("Jailed") or player:GetAttribute("InHeist") then
		return false, "You can't travel right now."
	end
	local now = os.clock()
	if (lastTravel[player] or 0) + TRAVEL_COOLDOWN > now then
		return false, "Please wait a moment before travelling again"
	end
	lastTravel[player] = now
	DiscoveryService.Cancel(player)
	if not PlotService.TeleportToPlot(player, plot) then
		return false, "You can't travel right now"
	end
	setZone(player, "Museum")
	if target ~= player then
		Notifier.Send(target, player.DisplayName .. " is visiting your museum!", "Info")
		return true, ("Welcome to %s's museum! Press E on exhibits to inspect them."):format(target.DisplayName)
	end
	return true, "Welcome home!"
end

function ExplorationService.GetMuseumList(_player: Player): (boolean, string?, any)
	local list = {}
	for _, other in Players:GetPlayers() do
		local data = PlayerDataService.GetData(other)
		if data and PlotService.GetPlot(other) then
			local displays = 0
			for _ in data.Displays do
				displays += 1
			end
			table.insert(list, {
				UserId = other.UserId,
				Name = other.DisplayName,
				Level = Upgrades.ComputeLevel(data.Upgrades),
				Prestige = (other:GetAttribute("Prestige") :: number?) or 0,
				Title = (other:GetAttribute("Title") :: string?) or "",
				Displays = displays,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.Prestige > b.Prestige
	end)
	return true, nil, list
end

-- ── Portals ────────────────────────────────────────────────────────────────
local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

local function connectPortal(part: BasePart, destination: string)
	part.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end
		if (lastTravel[player] or 0) + TRAVEL_COOLDOWN > os.clock() then
			return
		end
		local ok, message = ExplorationService.TravelTo(player, destination)
		Notifier.Send(player, message or "", if ok then "Info" else "Error")
	end)
end

function ExplorationService.Init() end

function ExplorationService.Start()
	Net.Handle("TravelTo", ExplorationService.TravelTo)
	Net.Handle("VisitMuseum", ExplorationService.VisitMuseum)
	Net.Handle("GetMuseumList", ExplorationService.GetMuseumList)

	local world = workspace:WaitForChild("World")
	local hubPortal = world:FindFirstChild("RuinsPortal", true)
	if hubPortal and hubPortal:IsA("BasePart") then
		connectPortal(hubPortal, (hubPortal:GetAttribute("ZoneId") :: string?) or "ForgottenRuins")
	end
	local junglePortal = world:FindFirstChild("JunglePortal", true)
	if junglePortal and junglePortal:IsA("BasePart") then
		connectPortal(junglePortal, (junglePortal:GetAttribute("ZoneId") :: string?) or "JungleTemple")
	end
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "ReturnPortal" then
			connectPortal(d, "Museum")
		end
	end

	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			-- Respawning always brings you home (PlotService moves the character).
			setZone(player, "Museum")
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		currentZone[player] = nil
		lastTravel[player] = nil
	end)
end

return ExplorationService
