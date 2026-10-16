--[[
	MuseumBuilder
	All museum geometry, generated from code. Every function builds in PLOT
	space (the `origin` CFrame is the plot centre at ground level; the museum
	entrance faces local -Z).

	Want a nicer museum later? Replace the inside of any Builders.<upgradeId>
	function, or build a model in Studio and clone it here instead.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Upgrades = require(Shared.Upgrades)
local Build = require(script.Parent.Build)

local MuseumBuilder = {}

local V = Vector3.new
local CF = CFrame.new
local rad = math.rad
local UP = CFrame.Angles(0, 0, rad(90))

local M = Enum.Material
local COLORS = {
	Stone = Color3.fromRGB(228, 216, 192),
	StoneDark = Color3.fromRGB(190, 176, 150),
	Marble = Color3.fromRGB(240, 236, 228),
	Wood = Color3.fromRGB(142, 96, 58),
	WoodDark = Color3.fromRGB(96, 62, 38),
	Roof = Color3.fromRGB(78, 64, 56),
	Gold = Color3.fromRGB(214, 172, 60),
	Green = Color3.fromRGB(32, 78, 60),
	Blue = Color3.fromRGB(34, 54, 98),
	Red = Color3.fromRGB(128, 32, 42),
	Metal = Color3.fromRGB(70, 72, 78),
	Warm = Color3.fromRGB(255, 214, 160),
}

local WALL = { Color = COLORS.Stone, Material = M.Sandstone }
local function props(color: Color3, material: Enum.Material?, extra: { [string]: any }?): Build.PartProps
	local p: any = { Color = color, Material = material or M.SmoothPlastic }
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	return p
end

local function ceilingLight(parent: Instance, origin: CFrame, x: number, y: number, z: number, range: number?)
	local lamp = Build.Part(parent, origin, V(2, 0.3, 2), CF(x, y, z), props(COLORS.Warm, M.Neon, { CanCollide = false }))
	Build.Light(lamp, COLORS.Warm, range or 40, 1.4, false)
end

local function roomSign(parent: Instance, origin: CFrame, min: Vector3, max: Vector3, face: Enum.NormalId, text: string)
	local sign = Build.Box(parent, origin, min, max, props(COLORS.Green, M.SmoothPlastic, { CanCollide = false }))
	Build.Label(sign, face, text, COLORS.Gold)
end

-- ── Base museum (free) ──────────────────────────────────────────────────────
export type BaseRefs = { Desk: BasePart, SignLabel: TextLabel }

function MuseumBuilder.BuildBase(parent: Instance, origin: CFrame): BaseRefs
	local f = Build.Folder(parent, "Base")
	-- Floor, entrance path and step
	Build.Box(f, origin, V(-20.5, 0, -10.5), V(20.5, 1, 30.5), props(COLORS.Wood, M.WoodPlanks))
	Build.Box(f, origin, V(-5, 0, -30), V(5, 0.2, -10.5), props(COLORS.StoneDark, M.Cobblestone))
	Build.Box(f, origin, V(-6, 0, -12.5), V(6, 0.6, -10.5), props(COLORS.Marble, M.Marble))
	-- Walls (doorways to future wings are closed by barriers until purchased)
	Build.Wall(f, origin, -20.5, -10, 20.5, -10, 1, 19, 1, WALL, { Center = 0, Width = 10, Height = 12 })
	Build.Wall(f, origin, -20.5, 30, 20.5, 30, 1, 19, 1, WALL, { Center = 0, Width = 10, Height = 12 })
	Build.Wall(f, origin, 20, -9.5, 20, 29.5, 1, 19, 1, WALL, { Center = 10, Width = 10, Height = 12 })
	Build.Wall(f, origin, -20, -9.5, -20, 29.5, 1, 19, 1, WALL, { Center = 10, Width = 10, Height = 12 })
	-- Roof + gold cornice
	Build.Box(f, origin, V(-21, 19, -11), V(21, 20, 31), props(COLORS.Roof, M.Slate))
	Build.Box(f, origin, V(-21.4, 18.2, -11.4), V(21.4, 19, 31.4), props(COLORS.Gold, M.Metal))
	-- Carpet
	Build.Box(f, origin, V(-4, 1, -9.5), V(4, 1.05, 24), props(COLORS.Red, M.Fabric, { CanCollide = false }))
	-- Lighting
	ceilingLight(f, origin, 0, 18.7, 4, 45)
	ceilingLight(f, origin, 0, 18.7, 22, 45)

	-- Ticket desk (revenue collection point)
	local desk = Build.Box(f, origin, V(10, 1, -7), V(17, 4, -5), props(COLORS.WoodDark, M.Wood))
	desk.Name = "TicketDesk"
	Build.Box(f, origin, V(9.8, 4, -7.2), V(17.2, 4.3, -4.8), props(COLORS.Gold, M.Metal))
	local deskSign = Build.Box(f, origin, V(11, 4.3, -6.2), V(16, 6.3, -6), props(COLORS.Green, M.SmoothPlastic, { CanCollide = false }))
	Build.Label(deskSign, Enum.NormalId.Front, "TICKETS", COLORS.Gold)

	-- Name sign above the entrance
	local sign = Build.Box(f, origin, V(-9, 13.2, -10.9), V(9, 17.6, -10.5), props(COLORS.Green))
	local label = Build.Label(sign, Enum.NormalId.Front, "Available Museum", COLORS.Gold)

	return { Desk = desk, SignLabel = label }
end

-- ── Barriers ("coming soon" walls in front of locked wings) ────────────────
-- Upgrade = what removes it; Host = what must be built for it to exist.
local BARRIERS = {
	{ Upgrade = "east_wing", Host = "base", Min = V(19.6, 1, 5), Max = V(20.4, 13, 15), Face = Enum.NormalId.Left },
	{ Upgrade = "west_wing", Host = "base", Min = V(-20.4, 1, 5), Max = V(-19.6, 13, 15), Face = Enum.NormalId.Right },
	{ Upgrade = "grand_gallery", Host = "base", Min = V(-5, 1, 29.6), Max = V(5, 13, 30.4), Face = Enum.NormalId.Front },
	{ Upgrade = "fossil_hall", Host = "east_wing", Min = V(30, 1, 24.6), Max = V(40, 11, 25.4), Face = Enum.NormalId.Front },
	{ Upgrade = "treasure_vault", Host = "west_wing", Min = V(-40, 1, 24.6), Max = V(-30, 11, 25.4), Face = Enum.NormalId.Front },
}

function MuseumBuilder.BuildBarriers(parent: Instance, origin: CFrame, owned: { [string]: boolean })
	for _, b in BARRIERS do
		local hostBuilt = b.Host == "base" or owned[b.Host]
		if hostBuilt and not owned[b.Upgrade] then
			local up = Upgrades.ById[b.Upgrade]
			local part = Build.Box(parent, origin, b.Min, b.Max, props(COLORS.WoodDark, M.WoodPlanks))
			part.Name = "Barrier_" .. b.Upgrade
			Build.Label(part, b.Face, ("LOCKED\n%s"):format(up.Name), COLORS.Gold)
		end
	end
end

-- ── Upgrade pads (stand on them to buy) ────────────────────────────────────
function MuseumBuilder.BuildPad(parent: Instance, origin: CFrame, up: Upgrades.UpgradeDef, costText: string): BasePart
	local pad = Build.Part(parent, origin, V(6, 0.4, 6), CF(up.Pad.X, 0.2, up.Pad.Z), props(Color3.fromRGB(70, 200, 120), M.Neon, { Name = "Pad_" .. up.Id }))
	pad:SetAttribute("UpgradeId", up.Id)
	local ring = Build.Part(parent, origin, V(6.8, 0.3, 6.8), CF(up.Pad.X, 0.15, up.Pad.Z), props(COLORS.Gold, M.Metal, { CanCollide = false }))
	ring.Name = "PadRing"
	ring.Parent = pad
	Build.Billboard(pad, ("<b>%s</b>\n<font color=\"#8CF5AA\">%s</font>"):format(up.Name, costText), 4, 80, 9, 3)
	return pad
end

-- ── Display slot fixtures ──────────────────────────────────────────────────
export type Fixture = { Model: Model, PromptPart: BasePart, Anchor: CFrame, Scale: number }

function MuseumBuilder.BuildSlot(parent: Instance, origin: CFrame, slot: Upgrades.SlotDef): Fixture
	local model = Instance.new("Model")
	model.Name = "Slot_" .. slot.Id
	model:SetAttribute("SlotId", slot.Id)
	model:SetAttribute("SlotType", slot.Type)
	local frame = origin * CF(slot.X, 0, slot.Z) * CFrame.Angles(0, rad(slot.Face), 0)

	local promptPart: BasePart
	local anchor: CFrame
	local scale = 1

	if slot.Type == "Pedestal" then
		promptPart = Build.Part(model, frame, V(3, 3.5, 3), CF(0, 2.75, 0), props(COLORS.Marble, M.Marble))
		Build.Part(model, frame, V(3.4, 0.3, 3.4), CF(0, 4.6, 0), props(COLORS.Gold, M.Metal))
		Build.Part(model, frame, V(3.6, 0.5, 3.6), CF(0, 1.25, 0), props(COLORS.Marble, M.Marble))
		anchor = frame * CF(0, 4.75, 0)
	elseif slot.Type == "Case" then
		promptPart = Build.Part(model, frame, V(3.4, 3, 3.4), CF(0, 2.5, 0), props(COLORS.WoodDark, M.Wood))
		Build.Part(model, frame, V(3, 3, 3), CF(0, 5.5, 0), props(Color3.fromRGB(200, 230, 255), M.Glass, { Transparency = 0.75, Name = "Glass" }))
		Build.Part(model, frame, V(3.4, 0.2, 3.4), CF(0, 7.1, 0), props(COLORS.Gold, M.Metal, { Name = "Frame" }))
		anchor = frame * CF(0, 4.05, 0)
		scale = 0.85
	elseif slot.Type == "Wall" then
		promptPart = Build.Part(model, frame, V(5, 4.6, 0.3), CF(0, 8, 0.35), props(COLORS.Blue, M.Fabric))
		Build.Part(model, frame, V(5.4, 0.3, 0.5), CF(0, 5.6, 0.2), props(COLORS.Gold, M.Metal))
		anchor = frame * CF(0, 5.9, -0.1)
	elseif slot.Type == "Platform" then
		promptPart = Build.Part(model, frame, V(8, 1.2, 8), CF(0, 1.6, 0), props(COLORS.StoneDark, M.Slate))
		for _, p in { V(-3.8, 0, -3.8), V(3.8, 0, -3.8), V(-3.8, 0, 3.8), V(3.8, 0, 3.8) } do
			Build.Part(model, frame, V(0.4, 2.6, 0.4), CF(p.X, 3.5, p.Z), props(COLORS.Gold, M.Metal))
		end
		for _, side in { { V(0, 0, -3.8), 7.6, 0.15 }, { V(0, 0, 3.8), 7.6, 0.15 }, { V(-3.8, 0, 0), 0.15, 7.6 }, { V(3.8, 0, 0), 0.15, 7.6 } } do
			local pos = side[1] :: Vector3
			Build.Part(model, frame, V(side[2] :: number, 0.15, side[3] :: number), CF(pos.X, 4.3, pos.Z), props(COLORS.Red, M.Fabric, { CanCollide = false }))
		end
		anchor = frame * CF(0, 2.2, 0)
		scale = 1.8
	else -- Vault
		promptPart = Build.Part(model, frame, V(4, 3, 4), CF(0, 2.5, 0), props(COLORS.Metal, M.DiamondPlate))
		Build.Part(model, frame, V(3.6, 4, 3.6), CF(0, 6, 0), props(Color3.fromRGB(255, 220, 200), M.Glass, { Transparency = 0.8, Name = "Glass" }))
		Build.Part(model, frame, V(4.2, 0.3, 4.2), CF(0, 8.1, 0), props(COLORS.Gold, M.Metal, { Name = "Frame" }))
		Build.Part(model, frame, V(4.2, 0.3, 4.2), CF(0, 4.05, 0), props(COLORS.Gold, M.Metal))
		anchor = frame * CF(0, 4.2, 0)
		scale = 1.1
	end
	promptPart.Name = "PromptPart"
	model.PrimaryPart = promptPart
	model:SetAttribute("Anchor", anchor)
	model:SetAttribute("Scale", scale)
	model.Parent = parent
	return { Model = model, PromptPart = promptPart, Anchor = anchor, Scale = scale }
end

-- ── Upgrade geometry ───────────────────────────────────────────────────────
local Builders: { [string]: (Instance, CFrame) -> () } = {}

Builders.grand_entrance = function(f, o)
	for _, x in { -15, -9, 9, 15 } do
		Build.Part(f, o, V(17, 2.2, 2.2), CF(x, 10, -12.5) * UP, props(COLORS.Marble, M.Marble, { Shape = Enum.PartType.Cylinder }))
		Build.Box(f, o, V(x - 1.6, 0, -14.1), V(x + 1.6, 1.5, -10.9), props(COLORS.Marble, M.Marble))
	end
	local pediment = Build.Box(f, o, V(-17.5, 18.5, -14), V(17.5, 21, -10.5), props(COLORS.Marble, M.Marble))
	Build.Box(f, o, V(-12, 21, -13.5), V(12, 22.5, -10.5), props(COLORS.Marble, M.Marble))
	Build.Box(f, o, V(-17.7, 18.2, -14.2), V(17.7, 18.5, -10.5), props(COLORS.Gold, M.Metal))
	Build.Label(pediment, Enum.NormalId.Front, "MUSEUM OF LOST TREASURES", COLORS.Gold)
	for _, x in { -8, 8 } do
		Build.Box(f, o, V(x - 0.3, 0, -24.3), V(x + 0.3, 8, -23.7), props(Color3.fromRGB(40, 40, 40), M.Metal))
		local bulb = Build.Part(f, o, V(1.2, 1.2, 1.2), CF(x, 8.6, -24), props(COLORS.Warm, M.Neon, { Shape = Enum.PartType.Ball }))
		Build.Light(bulb, COLORS.Warm, 22, 1.5)
	end
	Build.Box(f, o, V(-3, 0.2, -30), V(3, 0.3, -12.5), props(COLORS.Red, M.Fabric, { CanCollide = false }))
end

Builders.hall_cases = function(f, o)
	-- The cases themselves are display slots; add small information stands beside them.
	for _, x in { -16.5, 16.5 } do
		Build.Box(f, o, V(x - 0.3, 1, 15.7), V(x + 0.3, 3.2, 16.3), props(COLORS.Gold, M.Metal))
		local plaque = Build.Box(f, o, V(x - 1, 3.2, 15.9), V(x + 1, 4.6, 16.1), props(COLORS.Blue, M.SmoothPlastic, { CanCollide = false }))
		Build.Label(plaque, Enum.NormalId.Front, "Treasures of the Ancients", COLORS.Gold)
	end
end

Builders.east_wing = function(f, o)
	Build.Box(f, o, V(20.5, 0, -5.5), V(50.5, 1, 25.5), props(COLORS.Wood, M.WoodPlanks))
	Build.Wall(f, o, 20.5, -5, 50.5, -5, 1, 15, 1, WALL)
	Build.Wall(f, o, 50, -4.5, 50, 24.5, 1, 15, 1, WALL)
	Build.Wall(f, o, 20.5, 25, 50.5, 25, 1, 15, 1, WALL, { Center = 35, Width = 10, Height = 10 })
	Build.Box(f, o, V(20.5, 15, -5.5), V(50.5, 16, 25.5), props(COLORS.Roof, M.Slate))
	Build.Box(f, o, V(20.5, 14.4, -5.9), V(50.9, 15, 25.9), props(COLORS.Gold, M.Metal))
	Build.Box(f, o, V(26, 1, 0), V(44, 1.05, 20), props(COLORS.Green, M.Fabric, { CanCollide = false }))
	ceilingLight(f, o, 35, 14.7, 10, 35)
	roomSign(f, o, V(19.3, 13.2, 6), V(19.5, 15.4, 14), Enum.NormalId.Left, "EAST GALLERY")
end

Builders.benches_plants = function(f, o)
	local function bench(x: number, z: number, alongZ: boolean)
		local sx, sz = if alongZ then 2 else 6, if alongZ then 6 else 2
		Build.Box(f, o, V(x - sx / 2, 2.2, z - sz / 2), V(x + sx / 2, 2.7, z + sz / 2), props(COLORS.Wood, M.Wood))
		for _, d in { -1, 1 } do
			local lx = if alongZ then x else x + d * 2.4
			local lz = if alongZ then z + d * 2.4 else z
			Build.Box(f, o, V(lx - 0.3, 1, lz - 0.3), V(lx + 0.3, 2.2, lz + 0.3), props(COLORS.Metal, M.Metal))
		end
	end
	local function plant(x: number, z: number)
		Build.Part(f, o, V(2, 2.4, 2.4), CF(x, 2.2, z) * UP, props(Color3.fromRGB(170, 90, 60), M.Slate, { Shape = Enum.PartType.Cylinder }))
		Build.Part(f, o, V(0.5, 4, 0.5), CF(x, 4.5, z), props(COLORS.Wood, M.Wood))
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			Build.Part(f, o, V(1.8, 1.8, 1.8), CF(x + math.cos(a) * 1.1, 6.5 + (i % 2) * 0.6, z + math.sin(a) * 1.1), props(Color3.fromRGB(60, 140, 70), M.Grass, { Shape = Enum.PartType.Ball, CanCollide = false }))
		end
	end
	bench(-16, 23, true)
	bench(16, 23, true)
	bench(42, 20, false)
	plant(-17.5, -7.5)
	plant(17.5, 28)
	plant(-17.5, 28)
	plant(46.5, -1.5)
	plant(46.5, 22.5)
end

Builders.fossil_hall = function(f, o)
	Build.Box(f, o, V(21, 0, 25.5), V(50.5, 1, 55.5), props(Color3.fromRGB(200, 180, 140), M.Slate))
	Build.Wall(f, o, 21, 25.5, 21, 55, 1, 17, 1, props(Color3.fromRGB(205, 190, 160), M.Sandstone))
	Build.Wall(f, o, 50, 25.5, 50, 55, 1, 17, 1, props(Color3.fromRGB(205, 190, 160), M.Sandstone))
	Build.Wall(f, o, 20.5, 55, 50.5, 55, 1, 17, 1, props(Color3.fromRGB(205, 190, 160), M.Sandstone))
	Build.Box(f, o, V(20.5, 15, 24.5), V(50.5, 17, 25.5), props(COLORS.Stone, M.Sandstone)) -- header above the east wing roof
	Build.Box(f, o, V(20.5, 17, 24.5), V(50.5, 18, 55.5), props(COLORS.Roof, M.Slate))
	-- Sand pit decoration with a big decorative skeleton
	Build.Box(f, o, V(26, 1, 46), V(46, 1.3, 52), props(Color3.fromRGB(220, 195, 140), M.Sand, { CanCollide = false }))
	for i = 0, 6 do
		Build.Part(f, o, V(0.6, 0.6, 2.2 - i * 0.15), CF(28 + i * 2.6, 2 + math.sin(i / 6 * math.pi) * 1.5, 49), props(Color3.fromRGB(235, 225, 200), M.Limestone, { CanCollide = false }))
	end
	Build.Part(f, o, V(2.4, 2, 1.6), CF(46.5, 3.4, 49), props(Color3.fromRGB(235, 225, 200), M.Limestone, { CanCollide = false }))
	ceilingLight(f, o, 36, 16.7, 40, 40)
	roomSign(f, o, V(31, 11.4, 24.3), V(39, 13.6, 24.5), Enum.NormalId.Front, "FOSSIL HALL")
end

Builders.chandeliers = function(f, o)
	local function chandelier(x: number, y: number, z: number, ceiling: number)
		Build.Box(f, o, V(x - 0.15, y, z - 0.15), V(x + 0.15, ceiling, z + 0.15), props(COLORS.Gold, M.Metal, { CanCollide = false }))
		Build.Part(f, o, V(0.4, 6, 6), CF(x, y, z) * UP, props(COLORS.Gold, M.Metal, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			Build.Part(f, o, V(0.7, 0.7, 0.7), CF(x + math.cos(a) * 2.8, y + 0.6, z + math.sin(a) * 2.8), props(COLORS.Warm, M.Neon, { Shape = Enum.PartType.Ball, CanCollide = false }))
		end
		local core = Build.Part(f, o, V(1.4, 1.4, 1.4), CF(x, y - 0.6, z), props(Color3.fromRGB(255, 240, 200), M.Glass, { Shape = Enum.PartType.Ball, CanCollide = false }))
		Build.Light(core, COLORS.Warm, 32, 1.6, true)
	end
	chandelier(0, 14.5, 10, 19)
	chandelier(35, 11.5, 10, 15)
	chandelier(36, 13, 40, 17)
end

Builders.security = function(f, o)
	-- The control room console. The actual cameras, locks and alarm pads are
	-- built by SecurityService from the owner's real security levels, so what
	-- you see always matches what a thief has to beat.
	Build.Box(f, o, V(10, 1, -1), V(14, 3.5, 1), props(COLORS.Metal, M.Metal))
	local screen = Build.Box(f, o, V(10.3, 3.5, -0.2), V(13.7, 5.5, 0), props(Color3.fromRGB(20, 60, 40), M.Neon, { CanCollide = false }))
	Build.Label(screen, Enum.NormalId.Front, "SECURITY ONLINE", Color3.fromRGB(140, 255, 170), Enum.Font.Code)
end

Builders.west_wing = function(f, o)
	Build.Box(f, o, V(-50.5, 0, -5.5), V(-20.5, 1, 25.5), props(COLORS.Wood, M.WoodPlanks))
	Build.Wall(f, o, -50.5, -5, -20.5, -5, 1, 15, 1, WALL)
	Build.Wall(f, o, -50, -4.5, -50, 24.5, 1, 15, 1, WALL)
	Build.Wall(f, o, -50.5, 25, -20.5, 25, 1, 15, 1, WALL, { Center = -35, Width = 10, Height = 10 })
	Build.Box(f, o, V(-50.5, 15, -5.5), V(-20.5, 16, 25.5), props(COLORS.Roof, M.Slate))
	Build.Box(f, o, V(-50.9, 14.4, -5.9), V(-20.5, 15, 25.9), props(COLORS.Gold, M.Metal))
	Build.Box(f, o, V(-44, 1, 0), V(-26, 1.05, 20), props(COLORS.Blue, M.Fabric, { CanCollide = false }))
	-- Half columns along the walls
	for _, z in { 0, 10, 20 } do
		Build.Part(f, o, V(14, 1.6, 1.6), CF(-49, 8, z) * UP, props(COLORS.Marble, M.Marble, { Shape = Enum.PartType.Cylinder }))
	end
	ceilingLight(f, o, -35, 14.7, 10, 35)
	roomSign(f, o, V(-19.5, 13.2, 6), V(-19.3, 15.4, 14), Enum.NormalId.Right, "ANCIENT HISTORY")
end

Builders.grand_gallery = function(f, o)
	Build.Box(f, o, V(-20.5, 0, 30.5), V(20.5, 1, 62.5), props(COLORS.Marble, M.Marble))
	Build.Wall(f, o, -20, 30.5, -20, 62, 1, 21, 1, props(Color3.fromRGB(150, 40, 50), M.Fabric))
	Build.Wall(f, o, 20, 30.5, 20, 62, 1, 21, 1, props(Color3.fromRGB(150, 40, 50), M.Fabric))
	Build.Wall(f, o, -20.5, 62, 20.5, 62, 1, 21, 1, props(Color3.fromRGB(150, 40, 50), M.Fabric))
	Build.Box(f, o, V(-21, 19, 29.5), V(21, 21, 30.5), props(COLORS.Stone, M.Sandstone)) -- header above the hall roof
	Build.Box(f, o, V(-21, 21, 29.5), V(21, 22, 63), props(COLORS.Roof, M.Slate))
	Build.Box(f, o, V(-21.4, 20.2, 29.5), V(21.4, 21, 63.4), props(COLORS.Gold, M.Metal))
	-- Skylight strip
	Build.Box(f, o, V(-4, 20.6, 34), V(4, 20.9, 58), props(Color3.fromRGB(255, 245, 225), M.Neon, { CanCollide = false }))
	for _, z in { 36, 46, 56 } do
		Build.Box(f, o, V(-19.4, 1, z - 0.8), V(-18.6, 20, z + 0.8), props(COLORS.Gold, M.Metal))
		Build.Box(f, o, V(18.6, 1, z - 0.8), V(19.4, 20, z + 0.8), props(COLORS.Gold, M.Metal))
	end
	ceilingLight(f, o, 0, 20.5, 40, 45)
	ceilingLight(f, o, 0, 20.5, 54, 45)
	roomSign(f, o, V(-4, 13.4, 29.3), V(4, 15.6, 29.5), Enum.NormalId.Front, "GRAND GALLERY")
end

Builders.fountain_facade = function(f, o)
	local function fountain(x: number, z: number)
		Build.Part(f, o, V(1.4, 12, 12), CF(x, 0.7, z) * UP, props(COLORS.Marble, M.Marble, { Shape = Enum.PartType.Cylinder }))
		Build.Part(f, o, V(0.2, 10.6, 10.6), CF(x, 1.35, z) * UP, props(Color3.fromRGB(80, 160, 220), M.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.25, CanCollide = false }))
		Build.Part(f, o, V(5, 1.2, 1.2), CF(x, 3.5, z) * UP, props(COLORS.Marble, M.Marble, { Shape = Enum.PartType.Cylinder }))
		local top = Build.Part(f, o, V(0.6, 4, 4), CF(x, 6.1, z) * UP, props(COLORS.Gold, M.Metal, { Shape = Enum.PartType.Cylinder }))
		local water = Instance.new("ParticleEmitter")
		water.Color = ColorSequence.new(Color3.fromRGB(170, 220, 255))
		water.Size = NumberSequence.new(0.35)
		water.Transparency = NumberSequence.new(0.3)
		water.Lifetime = NumberRange.new(0.8, 1.1)
		water.Rate = 40
		water.Speed = NumberRange.new(8, 10)
		water.SpreadAngle = Vector2.new(18, 18)
		water.Acceleration = Vector3.new(0, -25, 0)
		water.EmissionDirection = Enum.NormalId.Top
		water.Parent = top
	end
	fountain(56, -20)
	fountain(-56, -20)
	for _, x in { -17, 17 } do
		Build.Box(f, o, V(x - 1.2, 4, -10.8), V(x + 1.2, 16, -10.5), props(COLORS.Blue, M.Fabric, { CanCollide = false }))
		Build.Part(f, o, V(1.2, 1.2, 0.3), CF(x, 13, -10.95) * CFrame.Angles(0, 0, rad(45)), props(COLORS.Gold, M.Metal, { CanCollide = false }))
	end
	Build.Box(f, o, V(-20.8, 1, -10.9), V(20.8, 1.6, -10.5), props(COLORS.Gold, M.Metal))
end

Builders.treasure_vault = function(f, o)
	local metal = props(Color3.fromRGB(85, 88, 96), M.DiamondPlate)
	Build.Box(f, o, V(-50.5, 0, 25.5), V(-21, 1, 55.5), props(Color3.fromRGB(60, 60, 66), M.DiamondPlate))
	Build.Wall(f, o, -21, 25.5, -21, 55, 1, 13, 1, metal)
	Build.Wall(f, o, -50, 25.5, -50, 55, 1, 13, 1, metal)
	Build.Wall(f, o, -50.5, 55, -20.5, 55, 1, 13, 1, metal)
	Build.Box(f, o, V(-50.5, 13, 24.5), V(-20.5, 14, 55.5), props(COLORS.Metal, M.DiamondPlate))
	-- The giant open vault door
	Build.Part(f, o, V(1.4, 9, 9), CF(-27.5, 5.6, 27.5) * CFrame.Angles(0, rad(-60), 0), props(Color3.fromRGB(150, 150, 160), M.Metal, { Shape = Enum.PartType.Cylinder }))
	Build.Part(f, o, V(1.6, 3, 3), CF(-27.5, 5.6, 27.5) * CFrame.Angles(0, rad(-60), 0), props(COLORS.Gold, M.Metal, { Shape = Enum.PartType.Cylinder }))
	-- Gold piles
	for i, p in { V(-46, 0, 52), V(-25, 0, 52), V(-36, 0, 53) } do
		Build.Part(f, o, V(3 + i * 0.4, 1.4, 2.6), CF(p.X, 1.6, p.Z), props(Color3.fromRGB(250, 205, 70), M.Metal, { CanCollide = false }))
	end
	local lamp = Build.Part(f, o, V(2, 0.3, 2), CF(-36, 12.7, 40), props(Color3.fromRGB(255, 200, 150), M.Neon, { CanCollide = false }))
	Build.Light(lamp, Color3.fromRGB(255, 190, 120), 35, 1.6)
	roomSign(f, o, V(-39, 11.4, 24.3), V(-31, 13.6, 24.5), Enum.NormalId.Front, "TREASURE VAULT")
end

-- Builds the geometry for one upgrade into its own folder. Returns the folder.
function MuseumBuilder.BuildUpgrade(parent: Instance, origin: CFrame, upgradeId: string): Folder
	local folder = Build.Folder(parent, "Upgrade_" .. upgradeId)
	local builder = Builders[upgradeId]
	if builder then
		builder(folder, origin)
	else
		warn("[MuseumBuilder] No geometry for upgrade " .. upgradeId)
	end
	return folder
end

-- Sanity check: every upgrade must have geometry.
for _, up in Upgrades.List do
	assert(Builders[up.Id], "MuseumBuilder is missing a builder for upgrade " .. up.Id)
end

return MuseumBuilder
