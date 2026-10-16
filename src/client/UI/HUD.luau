--[[
	HUD
	Always-visible interface:
	  • top bar: cash, museum level, prestige, ticket-desk earnings, income
	  • goal banner (the tutorial — always tells you a useful next step)
	  • big menu buttons on the left (touch-friendly)
]]

local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Upgrades = require(Shared.Upgrades)
local ItemCatalog = require(Shared.ItemCatalog)
local Format = require(Shared.Format)

local Theme = require(script.Parent.Theme)
local ClientState = require(script.Parent.Parent.ClientState)

local HUD = {}

local cashLabel: TextLabel
local levelLabel: TextLabel
local prestigeLabel: TextLabel
local deskLabel: TextLabel
local goalLabel: TextLabel
local saveWarning: TextLabel
local lastCash: number? = nil

local function pill(parent: Instance, widthScale: number, order: number): TextLabel
	local frame = Theme.New("Frame", {
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.08,
		Size = UDim2.new(widthScale, -6, 1, 0),
		LayoutOrder = order,
		Parent = parent,
	})
	Theme.Corner(frame, 12)
	Theme.Stroke(frame, Theme.Colors.Gold, 2)
	local label = Theme.Label("", { Font = Theme.Fonts.Bold, Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -6) }, 20)
	label.Parent = frame
	return label
end

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

-- The tutorial: always one clear, useful next step.
local function computeGoal(state: any): string
	local displays = count(state.Displays)
	local stats = state.Stats
	if displays == 0 then
		return "Place your <b>Cracked Clay Pot</b> on a pedestal: walk up to a pedestal in your museum and press <b>E</b> (or tap the prompt)."
	end
	if stats.TotalCollected == 0 then
		if (state.PendingRevenue or 0) < 3 then
			return "Your exhibit is attracting visitors! In a few seconds, collect your earnings at the <b>Ticket Desk</b>."
		end
		return "Collect your earnings at the <b>Ticket Desk</b> inside your museum's entrance."
	end
	if stats.Searches == 0 then
		return "Go treasure hunting! Press <b>Travel</b> or walk through the blue portal in the plaza to reach the <b>Forgotten Ruins</b>."
	end
	if stats.Searches < 5 then
		return ("Search dig sites, urns and rubble in the ruins (%d/5). Better finds hide in chests and secret rooms..."):format(stats.Searches)
	end
	if not state.Upgrades.hall_cases then
		return "Build <b>Glass Display Cases</b>: step on the green pad in your front yard (or use the <b>Build</b> menu)."
	end
	if displays < 3 then
		return ("Fill your displays to earn more (%d/3 exhibits). Different categories earn a variety bonus!"):format(displays)
	end
	if count(state.Journal.CompletedSets) == 0 then
		return "Complete a collection set for a big reward — check your <b>Journal</b> to see what's missing."
	end
	local nextUp = nil
	for _, up in Upgrades.List do
		if not state.Upgrades[up.Id] and Upgrades.RequirementsMet(up, state.Upgrades) then
			if not nextUp or up.Cost < nextUp.Cost then
				nextUp = up
			end
		end
	end
	if nextUp then
		return ("Next construction: <b>%s</b> (%s). Solve the temple's glyph puzzle for rarer treasures!"):format(nextUp.Name, Format.Cash(nextUp.Cost))
	end
	local discovered = count(state.Journal.Discovered)
	return ("Your museum is complete! Discover every artefact: %d / %d found."):format(discovered, #ItemCatalog.Order)
end

local function update(state: any)
	cashLabel.Text = ("<font color=\"#DEB446\">%s</font>"):format(Format.Cash(state.Cash))
	if lastCash and state.Cash > lastCash then
		local scale = cashLabel.Parent and cashLabel.Parent:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 1.12
			TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	lastCash = state.Cash
	levelLabel.Text = ("Lv %d <font size=\"14\" color=\"#B9B2A0\">%s</font>"):format(state.Level or 1, state.LevelName or "")
	prestigeLabel.Text = ("%d <font size=\"14\" color=\"#B9B2A0\">prestige</font>"):format(state.Prestige or 0)
	local income = state.Income and state.Income.PerMinute or 0
	deskLabel.Text = ("Desk %s<font size=\"14\" color=\"#B9B2A0\"> / %s · +%s/min</font>"):format(Format.Cash(state.PendingRevenue or 0), Format.Cash(state.RevenueCap or 0), Format.Cash(income))
	goalLabel.Text = "<b>GOAL:</b> " .. computeGoal(state)
	saveWarning.Visible = state.SaveEnabled == false
end

export type MenuEntry = { Icon: string, Text: string, OnClick: () -> () }

function HUD.Init(screen: ScreenGui, menu: { MenuEntry })
	-- Top bar
	local top = Theme.New("Frame", {
		Name = "TopBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.new(0.72, 0, 0, 44),
		Parent = screen,
	})
	Theme.New("UISizeConstraint", { MaxSize = Vector2.new(820, 44), Parent = top })
	Theme.ListLayout(top, 6, true).HorizontalAlignment = Enum.HorizontalAlignment.Center
	cashLabel = pill(top, 0.22, 1)
	Theme.New("UIScale", { Parent = cashLabel.Parent })
	levelLabel = pill(top, 0.3, 2)
	prestigeLabel = pill(top, 0.18, 3)
	deskLabel = pill(top, 0.3, 4)

	-- Goal banner
	local goal = Theme.New("Frame", {
		Name = "Goal",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.new(0.6, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(60, 46, 20),
		BackgroundTransparency = 0.12,
		Parent = screen,
	})
	Theme.New("UISizeConstraint", { MaxSize = Vector2.new(700, 40), Parent = goal })
	Theme.Corner(goal, 10)
	Theme.Stroke(goal, Theme.Colors.Gold, 1.5)
	goalLabel = Theme.Label("", { TextWrapped = true, Position = UDim2.fromOffset(10, 3), Size = UDim2.new(1, -20, 1, -6) }, 16)
	goalLabel.Parent = goal

	saveWarning = Theme.Label("Progress is NOT being saved (Studio API access is off) — see the setup guide.", {
		BackgroundColor3 = Theme.Colors.Danger,
		BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 100),
		Size = UDim2.new(0.5, 0, 0, 22),
		Visible = false,
		Parent = screen,
	}, 14)
	Theme.Corner(saveWarning, 6)

	-- Menu buttons
	local menuFrame = Theme.New("Frame", {
		Name = "Menu",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.45, 0),
		Size = UDim2.fromOffset(146, math.ceil(#menu / 2) * 70),
		Parent = screen,
	})
	local menuScale = Theme.New("UIScale", { Parent = menuFrame })
	Theme.New("UIGridLayout", {
		CellSize = UDim2.fromOffset(68, 64),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menuFrame,
	})
	for i, entry in menu do
		local button = Theme.Button("", Theme.Colors.Panel, entry.OnClick)
		button.Size = UDim2.fromOffset(68, 64)
		button.LayoutOrder = i
		Theme.Stroke(button, Theme.Colors.Gold, 2)
		Theme.Label(entry.Icon, { Size = UDim2.new(1, 0, 0.6, 0), Parent = button }, 28)
		Theme.Label(entry.Text, { Font = Theme.Fonts.Bold, Position = UDim2.fromScale(0, 0.6), Size = UDim2.new(1, 0, 0.4, 0), TextColor3 = Theme.Colors.Gold, Parent = button }, 13)
		button.Parent = menuFrame
	end

	-- Shrink the menu on small (phone) screens
	local camera = workspace.CurrentCamera
	local function rescale()
		local height = camera.ViewportSize.Y
		menuScale.Scale = math.clamp((height - 120) / (math.ceil(#menu / 2) * 70), 0.55, 1)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	ClientState.OnChanged(update)
end

return HUD
