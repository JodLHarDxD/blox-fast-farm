-- A fake hookmetamethod that keeps the game's metamethods in a table, so the
-- cases can see what is hooked when, and call through it like a game script.
local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z, kind = "Vector3" }, V) end
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then
        local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return vec(v.X / m, v.Y / m, v.Z / m)
    end
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = vec }
local function cfr(p, look) return { Position = p, look = look, kind = "CFrame" } end
local CFrame = { new = function(p) return cfr(p, nil) end, lookAt = function(p, at) return cfr(p, at) end }
local Ray = { new = function(o, d) return { Origin = o, Direction = d } end }

local MOUSE = { name = "mouse" }
local REAL_HIT = cfr(vec(999, 0, 0), nil)
local function gameIndex(self, key)        -- the game's own __index
    if self == MOUSE and key == "Hit" then return REAL_HIT end
    return "real:" .. tostring(key)
end
local game = { name = "game" }
local META = { __index = gameIndex, __namecall = function() return "nc" end }
local HOOKS = { index = 0, namecall = 0 }
local hookmetamethod = function(obj, name, f)
    local old = META[name]
    META[name] = f
    if name == "__index" then HOOKS.index += 1 else HOOKS.namecall += 1 end
    return old
end
local checkcaller = function() return false end
local newcclosure = function(f) return f end
local workspace = { CurrentCamera = { CFrame = { Position = vec(0, 0, 0) } } }
local player = { GetMouse = function() return MOUSE end }
local CFG = { SilentAim = true }
local AIM = nil
local P = { running = true }
function P.aimTarget() return AIM end
local _G = {}
