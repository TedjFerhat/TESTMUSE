--[[
	Theme
	Colours, fonts and small helpers so every screen looks consistent:
	deep green panels, warm parchment text, gold accents.
]]

local TweenService = game:GetService("TweenService")

local Theme = {}

Theme.Colors = {
	Panel = Color3.fromRGB(24, 38, 33),
	PanelLight = Color3.fromRGB(36, 56, 48),
	PanelLighter = Color3.fromRGB(50, 74, 64),
	Gold = Color3.fromRGB(222, 180, 70),
	GoldDark = Color3.fromRGB(160, 120, 40),
	Text = Color3.fromRGB(250, 244, 230),
	TextDim = Color3.fromRGB(185, 178, 160),
	Success = Color3.fromRGB(80, 175, 110),
	Danger = Color3.fromRGB(205, 80, 70),
	Blue = Color3.fromRGB(52, 92, 160),
	Disabled = Color3.fromRGB(80, 84, 82),
	Parchment = Color3.fromRGB(242, 230, 200),
}

Theme.Fonts = {
	Title = Enum.Font.Merriweather,
	Body = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
}

-- Generic instance creator: Theme.New("Frame", { Size = ... }, { children })
function Theme.New(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(inst :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Theme.Corner(parent: Instance, radius: number?): UICorner
	return Theme.New("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

function Theme.Stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	return Theme.New("UIStroke", {
		Color = color or Theme.Colors.Gold,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Theme.Padding(parent: Instance, px: number)
	Theme.New("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

-- Text label with sensible defaults. maxTextSize keeps scaled text readable.
function Theme.Label(text: string, props: { [string]: any }?, maxTextSize: number?): TextLabel
	local label = Theme.New("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Fonts.Body,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		RichText = true,
		Size = UDim2.fromScale(1, 1),
	})
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	Theme.New("UITextSizeConstraint", { MaxTextSize = maxTextSize or 22, MinTextSize = 9, Parent = label })
	return label
end

local clickCallback: (() -> ())? = nil
function Theme.SetClickSound(callback: () -> ())
	clickCallback = callback
end

-- Big friendly button (works with mouse, touch and gamepad).
function Theme.Button(text: string, color: Color3?, onClick: (() -> ())?, maxTextSize: number?): TextButton
	local button = Theme.New("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color or Theme.Colors.Gold,
		Text = text,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		RichText = true,
		Size = UDim2.fromOffset(120, 40),
	})
	Theme.Corner(button, 8)
	Theme.New("UITextSizeConstraint", { MaxTextSize = maxTextSize or 20, MinTextSize = 9, Parent = button })
	Theme.New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = button })
	local scale = Theme.New("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1.04 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	if onClick then
		button.Activated:Connect(function()
			if button:GetAttribute("Disabled") then
				return
			end
			if clickCallback then
				clickCallback()
			end
			onClick()
		end)
	end
	return button
end

function Theme.SetButtonEnabled(button: TextButton, enabled: boolean, enabledColor: Color3)
	button:SetAttribute("Disabled", not enabled)
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = if enabled then enabledColor else Theme.Colors.Disabled
end

function Theme.ListLayout(parent: Instance, padding: number?, horizontal: boolean?): UIListLayout
	return Theme.New("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- Scrolling list whose canvas grows with its content.
function Theme.Scroller(props: { [string]: any }?): ScrollingFrame
	local frame = Theme.New("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Colors.Gold,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = UDim2.fromScale(1, 1),
	})
	if props then
		for key, value in props do
			(frame :: any)[key] = value
		end
	end
	return frame
end

function Theme.Hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

return Theme
