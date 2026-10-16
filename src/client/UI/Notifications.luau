--[[
	Notifications
	Small toast messages that slide in at the top-right and fade away.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Sounds = require(script.Parent.Sounds)

local Notifications = {}

local container: Frame
local MAX_TOASTS = 4
local KIND_COLORS = {
	Info = Theme.Colors.PanelLight,
	Success = Color3.fromRGB(40, 110, 70),
	Error = Color3.fromRGB(130, 45, 40),
	Reward = Color3.fromRGB(150, 110, 30),
}

function Notifications.Init(screen: ScreenGui)
	container = Theme.New("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 110),
		Size = UDim2.new(0.34, 0, 0.5, 0),
		Parent = screen,
	})
	Theme.New("UISizeConstraint", { MaxSize = Vector2.new(380, 400), MinSize = Vector2.new(210, 0), Parent = container })
	local layout = Theme.ListLayout(container, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

local clueHandler: ((string, string) -> ())? = nil
function Notifications.SetClueHandler(fn: (string, string) -> ())
	clueHandler = fn
end

function Notifications.Show(text: string, kind: string?)
	if not container or text == "" then
		return
	end
	if kind == "Clue" and clueHandler then
		local title, body = string.match(text, "^(.-)\n(.*)$")
		clueHandler(title or "Inscription", body or text)
		return
	end
	kind = kind or "Info"
	if kind == "Error" then
		Sounds.Play("Error", 0.4)
	elseif kind == "Reward" then
		Sounds.Play("Discover", 0.6, 1.2)
	end
	local toasts = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts >= MAX_TOASTS then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end

	local toast = Theme.New("Frame", {
		BackgroundColor3 = KIND_COLORS[kind] or KIND_COLORS.Info,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = math.floor(os.clock() * 1000),
		Parent = container,
	})
	Theme.Corner(toast, 8)
	Theme.Stroke(toast, Theme.Colors.Gold, 1.5)
	Theme.Padding(toast, 8)
	local label = Theme.New("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextWrapped = true,
		RichText = true,
		Font = Theme.Fonts.Bold,
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toast,
	})
	local scale = Theme.New("UIScale", { Scale = 0.85, Parent = toast })
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	task.delay(if kind == "Reward" then 5 else 3.5, function()
		if toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			task.wait(0.3)
			toast:Destroy()
		end
	end)
end

return Notifications
