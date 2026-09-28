-- The pile, its no-damage clock and the spawn spots, faked, for checkPutBack.
local clock = 0
local os = { clock = function() return clock end }
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local CFrame = { new = function(p) return { p = p } end }
local attacking, probing, actions = true, false, 0
local CFG = { Magnet = true, PutBackAfter = 3, LearnLeash = true }
local pile, pileCentre = {}, v3(0, 0, 0)
local pileJoin, putBack, homePos = {}, {}, {}
local stats = { putBack = 0 }
local P = { leash = {}, pileInPlace = false, forceClose = false, randomSkip = {}, randomCant = 0 }
local function enemy(name, home)
    local m = {}
    homePos[m] = home
    return { model = m, name = name, hum = { Health = 100, Parent = true }, root = { Position = v3(0, 0, 0) } }
end
