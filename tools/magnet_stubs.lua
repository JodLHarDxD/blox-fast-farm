-- The pile, faked, for the magnet's frame: enemies whose root takes CFrame
-- writes, a Humanoid with the fields the freeze sets.
local clock = 0
local os = { clock = function() return clock end }
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = v3, zero = v3(0, 0, 0) }
local CFrame = { new = function(p) return { Position = p } end }

local function rootPart(pos)
    local s = { Position = pos }
    return setmetatable({}, {
        __index = function(_, k)
            if k == "GetChildren" then return function() return {} end end
            return s[k]
        end,
        __newindex = function(_, k, v)
            s[k] = v
            if k == "CFrame" then s.Position = v.Position end
        end,
    })
end
local function enemy(pos)
    return { model = { Parent = true },
             hum = { Health = 100, WalkSpeed = 16, JumpPower = 50, PlatformStand = false },
             root = rootPart(pos) }
end

local P = { running = true }
local CFG = { Magnet = true, PileSpread = 3 }
local player = {}
local sethiddenproperty = nil
local pileActive = true
local pile, pileCentre = {}, v3(0, 0, 0)
local pileScanAt, simAt = 0, 0
local lastDest = setmetatable({}, { __mode = "k" })
local function refreshPile() pileScanAt = os.clock() end
