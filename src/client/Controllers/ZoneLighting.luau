--[[
	ZoneLighting
	Changes the mood when you travel: warm afternoon at the museums, a hazy
	golden dusk in the Forgotten Ruins. Only changes YOUR screen.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local ZoneLighting = {}

local PRESETS = {
	Museum = {
		Lighting = { ClockTime = 15.5, Brightness = 2.5, Ambient = Color3.fromRGB(69, 64, 56), OutdoorAmbient = Color3.fromRGB(140, 128, 115) },
		Atmosphere = { Density = 0.28, Haze = 1.2, Color = Color3.fromRGB(255, 236, 210) },
	},
	JungleTemple = {
		Lighting = { ClockTime = 16.2, Brightness = 1.7, Ambient = Color3.fromRGB(52, 70, 50), OutdoorAmbient = Color3.fromRGB(95, 125, 90) },
		Atmosphere = { Density = 0.48, Haze = 2.2, Color = Color3.fromRGB(190, 225, 180) },
	},
	ForgottenRuins = {
		Lighting = { ClockTime = 17.4, Brightness = 2.1, Ambient = Color3.fromRGB(80, 62, 48), OutdoorAmbient = Color3.fromRGB(150, 115, 85) },
		Atmosphere = { Density = 0.42, Haze = 2.4, Color = Color3.fromRGB(255, 205, 150) },
	},
}

local function apply(zoneId: string)
	local preset = PRESETS[zoneId] or PRESETS.Museum
	local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, preset.Lighting):Play()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, preset.Atmosphere):Play()
	end
end

function ZoneLighting.Init()
	Remotes.Event("ZoneChanged").OnClientEvent:Connect(function(zoneId)
		if type(zoneId) == "string" then
			apply(zoneId)
		end
	end)
end

return ZoneLighting
