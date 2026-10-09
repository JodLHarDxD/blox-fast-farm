-- The pile and your body, faked, for "where you hang" and the remote hit's reach.
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) return v3(v.X / m, v.Y / m, v.Z / m) end
    return nil
end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, n) return v3(a.X * n, a.Y * n, a.Z * n) end
local Vector3 = { new = v3, zero = v3(0, 0, 0) }
local task = { wait = function() end }
local ME = { Position = v3(0, 100, 0) }
local function parts() return {}, ME, {} end
local LOCK = nil
local function lockAt(pos, _) LOCK = pos end
local function flyTo(pos, _) LOCK = pos end
local attacking = false
local pile, pileCentre, pileSide = {}, nil, nil
local pileCur = nil      -- the fight's own rules (SEA EVENTS: its height)
local P = {}
local CFG = { HeightMode = "auto", StayHigh = true, HeightSafe = 60, HeightMelee = 3, MeleeDistance = 5,
    HeightFixed = 12, SideFixed = 0, InstantHop = 150, HitRange = 60, PileSpread = 3 }
local function enemy(pos) return { model = { Parent = true }, hum = { Health = 100 }, root = { Position = pos } } end
