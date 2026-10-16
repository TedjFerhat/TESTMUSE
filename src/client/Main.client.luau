--[[
	Main (client entry point)
	Creates the screen, starts every UI module and connects server events.
	Nothing here can change game state — every button asks the server.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local ClientState = require(script.Parent.ClientState)
local ClientNet = require(script.Parent.ClientNet)
local UI = script.Parent.UI
local Theme = require(UI.Theme)
local Sounds = require(UI.Sounds)
local Notifications = require(UI.Notifications)
local Window = require(UI.Window)
local HUD = require(UI.HUD)
local InventoryPanel = require(UI.InventoryPanel)
local UpgradesPanel = require(UI.UpgradesPanel)
local JournalPanel = require(UI.JournalPanel)
local ShopPanel = require(UI.ShopPanel)
local TravelPanel = require(UI.TravelPanel)
local MuseumsPanel = require(UI.MuseumsPanel)
local SearchBar = require(UI.SearchBar)
local DiscoveryPopup = require(UI.DiscoveryPopup)
local Dialog = require(UI.Dialog)
local TimingBar = require(UI.TimingBar)
local ExpeditionUI = require(UI.ExpeditionUI)
local HeistUI = require(UI.HeistUI)
local SecurityPanel = require(UI.SecurityPanel)
local MarketPanel = require(UI.MarketPanel)
local TradePanel = require(UI.TradePanel)
local ZoneLighting = require(script.Parent.Controllers.ZoneLighting)
local HeistVisuals = require(script.Parent.Controllers.HeistVisuals)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "MuseumUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

Theme.SetClickSound(function()
	Sounds.Play("Click", 0.35)
end)

ClientState.Init()
Notifications.Init(screen)
ClientNet.SetToast(Notifications.Show)
Window.Init(screen)
Dialog.Init(screen)
Notifications.SetClueHandler(Dialog.Card)

InventoryPanel.Init()
UpgradesPanel.Init()
JournalPanel.Init()
ShopPanel.Init()
TravelPanel.Init()
MuseumsPanel.Init()
SecurityPanel.Init()
MarketPanel.Init()
TradePanel.Init()
HeistUI.Init(screen)

HUD.Init(screen, {
	{ Icon = "🎒", Text = "Items", OnClick = function()
		if Window.IsOpen("Inventory") then
			Window.Close()
		else
			InventoryPanel.Open()
		end
	end },
	{ Icon = "🏛️", Text = "Build", OnClick = function()
		Window.Toggle("Upgrades")
	end },
	{ Icon = "📖", Text = "Journal", OnClick = function()
		Window.Toggle("Journal")
	end },
	{ Icon = "🧭", Text = "Travel", OnClick = function()
		Window.Toggle("Travel")
	end },
	{ Icon = "⛏️", Text = "Tools", OnClick = function()
		Window.Toggle("Shop")
	end },
	{ Icon = "🛡️", Text = "Security", OnClick = function()
		Window.Toggle("Security")
	end },
	{ Icon = "🏪", Text = "Market", OnClick = function()
		Window.Toggle("Market")
	end },
	{ Icon = "🕵️", Text = "Heists", OnClick = function()
		Window.Toggle("Heists")
	end },
	{ Icon = "👥", Text = "Players", OnClick = function()
		if TradePanel.IsActive() then
			TradePanel.Open()
		else
			Window.Toggle("Museums")
		end
	end },
	{ Icon = "🏠", Text = "Home", OnClick = function()
		ClientNet.Call("TravelTo", true, "Museum")
	end },
})

SearchBar.Init(screen)
DiscoveryPopup.Init(screen)
TimingBar.Init(screen)
ExpeditionUI.Init(screen)
ZoneLighting.Init()
HeistVisuals.Init()

-- Server → client events
Remotes.Event("Notify").OnClientEvent:Connect(function(info)
	if type(info) == "table" and type(info.Text) == "string" then
		Notifications.Show(info.Text, info.Kind)
	end
end)

Remotes.Event("OpenPlacement").OnClientEvent:Connect(function(info)
	if type(info) == "table" and type(info.SlotId) == "string" and type(info.SlotType) == "string" then
		InventoryPanel.OpenForPlacement(info.SlotId, info.SlotType)
	end
end)

Remotes.Event("Purchased").OnClientEvent:Connect(function()
	Sounds.Play("Purchase", 0.6, 0.8)
end)


print("[MuseumTycoon] Client started.")
