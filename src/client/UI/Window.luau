--[[
	Window
	Creates the menu windows (Inventory, Museum, Journal...) and makes sure
	only one is open at a time. Each window is a centred panel with a title
	bar, a close button and a Content frame.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Sounds = require(script.Parent.Sounds)

local Window = {}

type WindowRecord = { Frame: Frame, Content: Frame, Title: TextLabel, OnOpen: (() -> ())? }

local windows: { [string]: WindowRecord } = {}
local openName: string? = nil
local screen: ScreenGui
local changedCallbacks: { (string?) -> () } = {}

function Window.Init(screenGui: ScreenGui)
	screen = screenGui
end

function Window.Create(name: string, title: string, onOpen: (() -> ())?): Frame
	local frame = Theme.New("Frame", {
		Name = name .. "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.86, 0.78),
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		ZIndex = 5,
		Parent = screen,
	})
	Theme.New("UISizeConstraint", { MaxSize = Vector2.new(860, 580), Parent = frame })
	Theme.Corner(frame, 14)
	Theme.Stroke(frame, Theme.Colors.Gold, 3)
	Theme.New("UIScale", { Name = "OpenScale", Parent = frame })

	local titleBar = Theme.New("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = Theme.Colors.PanelLight,
		Size = UDim2.new(1, 0, 0, 46),
		Parent = frame,
	})
	Theme.Corner(titleBar, 14)
	local titleLabel = Theme.Label(title, {
		Font = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -80, 1, -12),
	}, 26)
	titleLabel.Parent = titleBar
	local close = Theme.Button("X", Theme.Colors.Danger, function()
		Window.Close()
	end, 22)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -8, 0.5, 0)
	close.Size = UDim2.fromOffset(40, 36)
	close.Parent = titleBar

	local content = Theme.New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 54),
		Size = UDim2.new(1, -24, 1, -64),
		Parent = frame,
	})

	windows[name] = { Frame = frame, Content = content, Title = titleLabel, OnOpen = onOpen }
	return content
end

function Window.SetTitle(name: string, title: string)
	local w = windows[name]
	if w then
		w.Title.Text = title
	end
end

function Window.Open(name: string)
	local w = windows[name]
	if not w then
		return
	end
	if openName and openName ~= name and windows[openName] then
		windows[openName].Frame.Visible = false
	end
	openName = name
	w.Frame.Visible = true
	local scale = w.Frame:FindFirstChild("OpenScale") :: UIScale
	scale.Scale = 0.9
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	Sounds.Play("Open", 0.3)
	if w.OnOpen then
		task.spawn(w.OnOpen)
	end
	for _, cb in changedCallbacks do
		task.spawn(cb, openName)
	end
end

function Window.Toggle(name: string)
	if openName == name then
		Window.Close()
	else
		Window.Open(name)
	end
end

function Window.Close()
	if openName and windows[openName] then
		windows[openName].Frame.Visible = false
	end
	openName = nil
	for _, cb in changedCallbacks do
		task.spawn(cb, nil)
	end
end

function Window.IsOpen(name: string): boolean
	return openName == name
end

function Window.OnChanged(callback: (string?) -> ())
	table.insert(changedCallbacks, callback)
end

return Window
