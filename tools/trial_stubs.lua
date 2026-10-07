-- A Vector3 just big enough for v4_trial.lua's PURE block.
local realPrint = print
local V3 = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
    if k == "Magnitude" then return m end
    if k == "Unit" then return vec(v.X / m, v.Y / m, v.Z / m) end
    return nil
end
V3.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
    if type(a) == "number" then a, b = b, a end
    return vec(a.X * b, a.Y * b, a.Z * b)
end
local Vector3 = { new = vec }
