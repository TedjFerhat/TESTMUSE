--[[
	Sounds
	Plays short UI sounds locally. Sound ids live in Shared/Config.Sounds.
]]

local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local Sounds = {}

local cache: { [string]: Sound } = {}

function Sounds.Play(name: string, volume: number?, pitch: number?)
	local id = Config.Sounds[name]
	if not id then
		return
	end
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "UISound_" .. name
		sound.SoundId = id
		sound.Parent = SoundService
		cache[name] = sound
	end
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	SoundService:PlayLocalSound(sound)
end

return Sounds
