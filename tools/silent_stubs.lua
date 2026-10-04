-- Vectors and CFrames with what the swap uses; no hooking functions (so the
-- section stops after defining the swap, as on an executor without them).
local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z, kind = "Vector3" }, V) end
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then
        local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return vec(v.X / m, v.Y / m, v.Z / m)
    end
    if k == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = vec }
local function cfr(p, look) return { Position = p, look = look, kind = "CFrame" } end
local CFrame = { new = function(p) return cfr(p, nil) end, lookAt = function(p, at) return cfr(p, at) end }
local typeof = function(v)
    if type(v) == "table" and v.kind then return v.kind end
    return type(v)
end
local P = {}
local CFG = {}
local player = {}
local hookmetamethod, getnamecallmethod = nil, nil
