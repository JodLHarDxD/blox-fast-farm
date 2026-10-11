-- Vector3 for L.lead, and the checker.
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__mul = function(a, n) return v3(a.X * n, a.Y * n, a.Z * n) end
local Vector3 = { new = v3 }

local fails, count = 0, 0
local function check(name, cond)
    count += 1
    if not cond then
        fails += 1
        print("FAIL  " .. name)
    end
end
local function near(a, b, eps) return a ~= nil and b ~= nil and math.abs(a - b) < (eps or 1e-6) end
