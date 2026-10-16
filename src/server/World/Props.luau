--[[
	Props
	Reusable environment models built from parts, shared by the Forgotten
	Ruins and the Jungle Temple so both zones have one consistent style:
	weathered stone, readable silhouettes, a little wear and moss — no
	floating detail, nothing smaller than the camera will notice.

	Every function takes (parent, origin, ...) where positions are local to
	`origin`. Decorative props have no scripts.
]]

local Build = require(script.Parent.Build)

local Props = {}

local V = Vector3.new
local CF = CFrame.new
local rad = math.rad
local UP = CFrame.Angles(0, 0, rad(90))
local M = Enum.Material
local C = Color3.fromRGB

export type Palette = { Stone: Color3, StoneDark: Color3, Moss: Color3?, Accent: Color3 }

Props.Sand = { Stone = C(205, 186, 150), StoneDark = C(160, 140, 112), Moss = nil, Accent = C(214, 172, 60) } :: Palette
Props.Jungle = { Stone = C(128, 132, 116), StoneDark = C(92, 96, 84), Moss = C(70, 110, 60), Accent = C(196, 160, 70) } :: Palette

local function P(color: Color3, material: Enum.Material?, extra: { [string]: any }?): Build.PartProps
	local p: any = { Color = color, Material = material or M.SmoothPlastic }
	if extra then
		for k, v in extra do
			p[k] = v
		end
	end
	return p
end
Props.P = P

-- Thin moss cap on top of a stone (only for palettes with moss).
local function moss(parent: Instance, origin: CFrame, pal: Palette, cf: CFrame, size: Vector3)
	if pal.Moss then
		Build.Part(parent, origin, V(size.X * 0.9, 0.25, size.Z * 0.9), cf * CF(0, size.Y / 2 + 0.1, 0), P(pal.Moss, M.Grass, { CanCollide = false }))
	end
end

-- Column with base and capital. broken = jagged short top, no capital.
function Props.Column(parent: Instance, origin: CFrame, x: number, z: number, height: number, pal: Palette, broken: boolean?, lean: number?)
	local f = origin * CF(x, 0, z) * CFrame.Angles(rad(lean or 0), 0, rad((lean or 0) * 0.5))
	Build.Part(parent, f, V(4.2, 1.2, 4.2), CF(0, 0.6, 0), P(pal.StoneDark, M.Slate))
	Build.Part(parent, f, V(height, 3, 3), CF(0, 1.2 + height / 2, 0) * UP, P(pal.Stone, M.Sandstone, { Shape = Enum.PartType.Cylinder }))
	-- Fluting: two thin darker bands give the column a carved look
	Build.Part(parent, f, V(0.3, 3.1, 3.1), CF(0, 1.6, 0) * UP, P(pal.StoneDark, M.Sandstone, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
	if broken then
		Build.Part(parent, f, V(2.2, 1.4, 2.6), CF(0.3, 1.2 + height + 0.3, 0.2) * CFrame.Angles(rad(18), rad(30), rad(-12)), P(pal.Stone, M.Sandstone))
		moss(parent, f, pal, CF(0, 1.2 + height, 0), V(3, 0.2, 3))
	else
		Build.Part(parent, f, V(0.6, 3.6, 3.6), CF(0, 1.2 + height - 0.3, 0) * UP, P(pal.StoneDark, M.Sandstone, { Shape = Enum.PartType.Cylinder }))
		Build.Part(parent, f, V(4.6, 1, 4.6), CF(0, 1.2 + height + 0.5, 0), P(pal.Stone, M.Slate))
		moss(parent, f, pal, CF(0, 1.2 + height + 0.5, 0), V(4.6, 1, 4.6))
	end
end

-- A column lying on its side, half sunk into the ground.
function Props.FallenColumn(parent: Instance, origin: CFrame, x: number, z: number, length: number, yaw: number, pal: Palette)
	local f = origin * CF(x, 0.6, z) * CFrame.Angles(0, rad(yaw), 0)
	Build.Part(parent, f, V(length, 3, 3), CF(0, 0, 0), P(pal.Stone, M.Sandstone, { Shape = Enum.PartType.Cylinder }))
	Build.Part(parent, f, V(1.2, 4.2, 4.2), CF(length / 2 + 0.4, 0.5, 0), P(pal.StoneDark, M.Slate))
end

-- The top of a buried archway poking out of the ground.
function Props.BuriedArch(parent: Instance, origin: CFrame, x: number, z: number, yaw: number, pal: Palette)
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)
	Build.Part(parent, f, V(3, 5, 3), CF(-6, 1.5, 0), P(pal.Stone, M.Sandstone))
	Build.Part(parent, f, V(3, 5, 3), CF(6, 1.5, 0), P(pal.Stone, M.Sandstone))
	Build.Part(parent, f, V(15, 2.4, 3.2), CF(0, 4.6, 0), P(pal.StoneDark, M.Sandstone))
	Build.Part(parent, f, V(3, 1.6, 3.4), CF(0, 6.4, 0), P(pal.Accent:Lerp(pal.Stone, 0.6), M.Sandstone)) -- keystone
	moss(parent, f, pal, CF(0, 4.6, 0), V(15, 2.4, 3.2))
end

-- Simple low rock.
function Props.Rock(parent: Instance, origin: CFrame, x: number, z: number, size: number, rng: Random, color: Color3?)
	Build.Part(parent, origin, V(size, size * 0.7, size * 0.9), CF(x, size * 0.25, z) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), P(color or C(150, 135, 115), M.Rock))
end

-- Scattered small stones (debris).
function Props.Debris(parent: Instance, origin: CFrame, x: number, z: number, radius: number, count: number, rng: Random, color: Color3)
	for _ = 1, count do
		local s = rng:NextNumber(0.6, 1.6)
		Build.Part(parent, origin, V(s, s * 0.6, s), CF(x + rng:NextNumber(-radius, radius), s * 0.25, z + rng:NextNumber(-radius, radius)) * CFrame.Angles(0, rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)), P(color, M.Slate, { CanCollide = false }))
	end
end

-- Weathered humanoid statue on a plinth. `holding` adds a disc above the head.
function Props.Statue(parent: Instance, origin: CFrame, x: number, z: number, yaw: number, pal: Palette, emblemColor: Color3?, headless: boolean?): BasePart
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)
	local plinth = Build.Part(parent, f, V(5, 3, 5), CF(0, 1.5, 0), P(pal.StoneDark, M.Slate))
	Build.Part(parent, f, V(1.2, 4, 1.4), CF(-0.7, 5, 0), P(pal.Stone, M.Sandstone)) -- legs
	Build.Part(parent, f, V(1.2, 4, 1.4), CF(0.7, 5, 0), P(pal.Stone, M.Sandstone))
	Build.Part(parent, f, V(3.4, 4.4, 1.8), CF(0, 9.2, 0), P(pal.Stone, M.Sandstone)) -- torso (robe)
	Build.Part(parent, f, V(1, 3.8, 1), CF(-2.2, 9.3, -0.3) * CFrame.Angles(rad(-20), 0, rad(8)), P(pal.Stone, M.Sandstone))
	Build.Part(parent, f, V(1, 3.8, 1), CF(2.2, 9.3, -0.3) * CFrame.Angles(rad(-20), 0, rad(-8)), P(pal.Stone, M.Sandstone))
	if not headless then
		Build.Part(parent, f, V(2, 2.2, 2), CF(0, 12.6, 0), P(pal.Stone, M.Sandstone))
		Build.Part(parent, f, V(0.4, 0.7, 0.5), CF(0, 12.4, -1.1), P(pal.StoneDark, M.Sandstone, { CanCollide = false })) -- nose
	else
		Build.Part(parent, f, V(1.4, 0.8, 1.2), CF(0.2, 11.7, 0) * CFrame.Angles(0, 0, rad(25)), P(pal.StoneDark, M.Sandstone))
	end
	if emblemColor then
		local emblem = Build.Part(parent, f, V(0.4, 2.6, 2.6), CF(0, 9.4, -1.6) * CFrame.Angles(0, rad(90), 0), P(emblemColor, M.Metal, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
		Build.Light(emblem, emblemColor, 10, 0.8)
	end
	moss(parent, f, pal, CF(0, 1.5, 0), V(5, 3, 5))
	return plinth
end

-- A standing inscription stone (stele). Returns the face part for labels/prompts.
function Props.Stele(parent: Instance, origin: CFrame, x: number, z: number, yaw: number, pal: Palette, text: string?): BasePart
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)
	Build.Part(parent, f, V(5, 1, 2.4), CF(0, 0.5, 0), P(pal.StoneDark, M.Slate))
	local face = Build.Part(parent, f, V(4, 6, 1), CF(0, 4, 0), P(pal.Stone, M.Slate))
	Build.Part(parent, f, V(4.4, 1, 1.4), CF(0, 7.4, 0) * CFrame.Angles(0, 0, rad(3)), P(pal.StoneDark, M.Slate))
	moss(parent, f, pal, CF(0, 7.4, 0), V(4.4, 1, 1.4))
	if text then
		Build.Label(face, Enum.NormalId.Front, text, C(70, 50, 30), Enum.Font.Fondamento)
	end
	return face
end

-- Wall-mounted torch with real fire and light.
function Props.Torch(parent: Instance, origin: CFrame, x: number, y: number, z: number)
	Build.Box(parent, origin, V(x - 0.25, y, z - 0.25), V(x + 0.25, y + 4, z + 0.25), P(C(90, 60, 40), M.Wood))
	local head = Build.Part(parent, origin, V(0.9, 0.7, 0.9), CF(x, y + 4.3, z), P(C(60, 45, 35), M.Metal))
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 6
	fire.Parent = head
	Build.Light(head, C(255, 160, 80), 22, 1.6)
end

-- Sealed urn (round body, neck, wax seal).
function Props.Urn(parent: Instance, origin: CFrame, x: number, z: number, color: Color3, rng: Random): BasePart
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rng:NextNumber(0, 6), rng:NextNumber(-0.08, 0.08))
	local body = Build.Part(parent, f, V(3.4, 3.8, 3.4), CF(0, 1.9, 0), P(color, M.Slate, { Shape = Enum.PartType.Ball }))
	Build.Part(parent, f, V(1.6, 1.7, 1.7), CF(0, 4, 0) * UP, P(color, M.Slate, { Shape = Enum.PartType.Cylinder }))
	Build.Part(parent, f, V(0.4, 2.1, 2.1), CF(0, 4.85, 0) * UP, P(color:Lerp(Color3.new(0, 0, 0), 0.2), M.Slate, { Shape = Enum.PartType.Cylinder }))
	Build.Part(parent, f, V(0.3, 1.5, 1.5), CF(0, 5.1, 0) * UP, P(C(150, 40, 40), M.SmoothPlastic, { Shape = Enum.PartType.Cylinder }))
	Build.Part(parent, f, V(0.25, 3.5, 3.5), CF(0, 2.5, 0) * UP, P(color:Lerp(Color3.new(0, 0, 0), 0.35), M.Slate, { Shape = Enum.PartType.Cylinder, CanCollide = false })) -- painted band
	return body
end

-- Iron-bound chest. Returns the body (search site part).
function Props.Chest(parent: Instance, origin: CFrame, cf: CFrame, wood: Color3?): BasePart
	local o = origin * cf
	local body = Build.Part(parent, o, V(4, 2.2, 2.6), CF(0, 1.1, 0), P(wood or C(110, 70, 40), M.Wood))
	Build.Part(parent, o, V(4, 1.6, 2.6), CF(0, 2.2, 0) * CFrame.Angles(0, rad(90), rad(90)) * UP, P(wood or C(110, 70, 40), M.WoodPlanks, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
	for _, x in { -1.5, 1.5 } do
		Build.Part(parent, o, V(0.3, 3.1, 2.7), CF(x, 1.55, 0), P(C(70, 70, 75), M.Metal, { CanCollide = false }))
	end
	Build.Part(parent, o, V(0.6, 0.7, 0.2), CF(0, 1.9, -1.35), P(C(214, 172, 60), M.Metal, { CanCollide = false }))
	return body
end

-- Archaeological dig site: dark mound, grid stakes and string, a sieve and a
-- bucket. Returns the mound (the search site part).
function Props.DigSite(parent: Instance, origin: CFrame, x: number, z: number, soil: Color3): BasePart
	local f = origin * CF(x, 0, z)
	local mound = Build.Part(parent, f, V(1.2, 9, 9), CF(0, 0.4, 0) * UP, P(soil, M.Ground, { Shape = Enum.PartType.Cylinder }))
	for _, p in { V(-5, 0, -5), V(5, 0, -5), V(-5, 0, 5), V(5, 0, 5) } do
		Build.Part(parent, f, V(0.3, 2.2, 0.3), CF(p.X, 1.1, p.Z), P(C(150, 110, 70), M.Wood, { CanCollide = false }))
	end
	for _, side in { { CF(0, 1.9, -5), V(10, 0.08, 0.08) }, { CF(0, 1.9, 5), V(10, 0.08, 0.08) }, { CF(-5, 1.9, 0), V(0.08, 0.08, 10) }, { CF(5, 1.9, 0), V(0.08, 0.08, 10) }, { CF(0, 1.9, 0), V(10, 0.08, 0.08) }, { CF(0, 1.9, 0), V(0.08, 0.08, 10) } } do
		Build.Part(parent, f, side[2] :: Vector3, side[1] :: CFrame, P(C(230, 220, 190), M.Fabric, { CanCollide = false }))
	end
	Build.Part(parent, f, V(0.3, 2.4, 2.4), CF(6.5, 0.6, 2) * CFrame.Angles(0, 0, rad(80)) * UP, P(C(140, 100, 60), M.Wood, { Shape = Enum.PartType.Cylinder, CanCollide = false })) -- sieve
	Build.Part(parent, f, V(1.4, 1.2, 1.2), CF(6.4, 0.6, -2) * UP, P(C(90, 90, 100), M.Metal, { Shape = Enum.PartType.Cylinder, CanCollide = false })) -- bucket
	return mound
end

-- Palm tree (desert).
function Props.Palm(parent: Instance, origin: CFrame, x: number, z: number, rng: Random)
	local h = rng:NextNumber(12, 18)
	local lean = rng:NextNumber(-8, 8)
	local f = origin * CF(x, 0, z) * CFrame.Angles(rad(lean), rng:NextNumber(0, 6), 0)
	for i = 0, 3 do
		Build.Part(parent, f, V(h / 4 + 0.2, 1.4 - i * 0.12, 1.4 - i * 0.12), CF(i * 0.15, h / 8 + i * h / 4, 0) * UP, P(C(120 - i * 6, 88, 58), M.Wood, { Shape = Enum.PartType.Cylinder }))
	end
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2
		Build.Part(parent, f, V(7.5, 0.3, 2), CF(math.cos(a) * 3.2, h + 0.1, math.sin(a) * 3.2) * CFrame.Angles(0, -a, rad(-18)), P(C(70, 130, 60), M.Grass, { CanCollide = false }))
	end
end

-- Dry desert shrub.
function Props.Shrub(parent: Instance, origin: CFrame, x: number, z: number, rng: Random, color: Color3?)
	local col = color or C(140, 130, 70)
	for _ = 1, 3 do
		local s = rng:NextNumber(1.2, 2.4)
		Build.Part(parent, origin, V(s, s * 0.7, s), CF(x + rng:NextNumber(-1, 1), s * 0.3, z + rng:NextNumber(-1, 1)), P(col, M.Grass, { Shape = Enum.PartType.Ball, CanCollide = false }))
	end
end

-- Giant jungle tree: buttress roots, tall trunk, layered dark canopy, hanging vines.
function Props.JungleTree(parent: Instance, origin: CFrame, x: number, z: number, rng: Random, scale: number?)
	local s = scale or 1
	local h = rng:NextNumber(34, 46) * s
	local w = rng:NextNumber(4, 6) * s
	local trunk = C(92, 70, 50)
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
	Build.Part(parent, f, V(h, w, w), CF(0, h / 2, 0) * UP, P(trunk, M.Wood, { Shape = Enum.PartType.Cylinder }))
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		Build.Part(parent, f, V(1.3 * s, 6 * s, w * 1.2), CF(math.cos(a) * w * 0.7, 2.6 * s, math.sin(a) * w * 0.7) * CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, rad(18)), P(trunk:Lerp(Color3.new(0, 0, 0), 0.1), M.Wood))
	end
	local leaves = { C(34, 80, 45), C(46, 96, 52), C(28, 70, 40) }
	for i = 1, 6 do
		local r = rng:NextNumber(10, 16) * s
		Build.Part(parent, f, V(r, r * 0.55, r), CF(rng:NextNumber(-7, 7) * s, h + rng:NextNumber(-3, 4) * s, rng:NextNumber(-7, 7) * s), P(leaves[(i % 3) + 1], M.Grass, { Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = true }))
	end
	for _ = 1, 4 do
		local len = rng:NextNumber(8, 18) * s
		Build.Part(parent, f, V(0.25, len, 0.25), CF(rng:NextNumber(-8, 8) * s, h - 3 * s - len / 2, rng:NextNumber(-8, 8) * s), P(C(60, 110, 50), M.Grass, { CanCollide = false, CastShadow = false }))
	end
end

-- Fern / undergrowth clump.
function Props.Fern(parent: Instance, origin: CFrame, x: number, z: number, rng: Random)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 + rng:NextNumber(0, 0.5)
		Build.Part(parent, origin, V(3.2, 0.2, 1), CF(x + math.cos(a) * 1.2, 0.9, z + math.sin(a) * 1.2) * CFrame.Angles(0, -a, rad(28)), P(C(60, 120, 55), M.Grass, { CanCollide = false, CastShadow = false }))
	end
end

-- Thick root arching over the ground.
function Props.Root(parent: Instance, origin: CFrame, x: number, z: number, yaw: number, length: number)
	local f = origin * CF(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)
	Build.Part(parent, f, V(length * 0.55, 1.4, 1.4), CF(-length * 0.22, 0.8, 0) * CFrame.Angles(0, 0, rad(18)), P(C(88, 66, 46), M.Wood, { Shape = Enum.PartType.Cylinder }))
	Build.Part(parent, f, V(length * 0.55, 1.2, 1.2), CF(length * 0.22, 0.8, 0) * CFrame.Angles(0, 0, rad(-18)), P(C(88, 66, 46), M.Wood, { Shape = Enum.PartType.Cylinder }))
end

-- Hanging vines on a wall/edge: a row of strands from (x1..x2, y, z).
function Props.Vines(parent: Instance, origin: CFrame, cf: CFrame, width: number, length: number, rng: Random)
	for i = 0, math.floor(width / 1.5) do
		local len = length * rng:NextNumber(0.4, 1)
		Build.Part(parent, origin * cf, V(0.25, len, 0.25), CF(-width / 2 + i * 1.5, -len / 2, 0), P(C(58, 112, 52), M.Grass, { CanCollide = false, CastShadow = false }))
	end
end

-- Generic clue object: an "unusual soil pattern" — darker, damp-looking ground.
function Props.SoilPattern(parent: Instance, origin: CFrame, x: number, z: number, color: Color3)
	Build.Part(parent, origin, V(0.15, 5, 7), CF(x, 0.05, z) * CFrame.Angles(0, rad(20), 0) * UP, P(color, M.Ground, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
	Build.Part(parent, origin, V(0.16, 2.4, 3), CF(x + 1.6, 0.06, z - 0.8) * UP, P(color:Lerp(Color3.new(0, 0, 0), 0.15), M.Mud, { Shape = Enum.PartType.Cylinder, CanCollide = false }))
end

-- Clue: a pottery shard sticking out of the ground.
function Props.PotteryShard(parent: Instance, origin: CFrame, x: number, z: number, color: Color3)
	Build.Part(parent, origin, V(1.8, 1.4, 0.25), CF(x, 0.35, z) * CFrame.Angles(rad(-25), rad(40), rad(15)), P(color, M.Slate, { CanCollide = false }))
	Build.Part(parent, origin, V(1.6, 0.25, 0.3), CF(x, 0.55, z) * CFrame.Angles(rad(-25), rad(40), rad(15)) * CF(0, 0.5, -0.1), P(color:Lerp(Color3.new(0, 0, 0), 0.4), M.Slate, { CanCollide = false }))
end

-- Clue: a ring of deliberately placed stones.
function Props.StoneRing(parent: Instance, origin: CFrame, x: number, z: number, color: Color3)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		Build.Part(parent, origin, V(1.4, 1, 1.2), CF(x + math.cos(a) * 3.2, 0.35, z + math.sin(a) * 3.2) * CFrame.Angles(0, -a, 0), P(color, M.Slate))
	end
end

-- Clue: glinting rocks (often a mineral deposit — a false lead).
function Props.GlintingRocks(parent: Instance, origin: CFrame, x: number, z: number)
	for i = 0, 3 do
		Build.Part(parent, origin, V(1.2, 0.9, 1), CF(x + i * 1.3 - 2, 0.3, z + (i % 2) * 1.1) * CFrame.Angles(0, i, 0.3), P(C(150, 160, 170), M.Foil, { CanCollide = false, Reflectance = 0.3 }))
	end
end

return Props
