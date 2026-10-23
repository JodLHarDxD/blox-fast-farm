-- The portal choice needs Vector3 with + - and Magnitude; nothing else of the game.
local V = {}
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, V) end
V.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }, V) end
local Vector3 = { new = function(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end }
local P = {}
