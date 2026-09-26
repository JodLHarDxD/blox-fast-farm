-- Vector3 and CFrame, faked with plain matrices (Roblox's conventions:
-- right-handed, the camera looks down its own -Z, Angles = Rx * Ry * Rz).
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
local Vector3 = { new = v3 }
local function dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
local function cross(a, b) return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end

local CF = {}
local function cf(p, m) return setmetatable({ p = p, m = m }, CF) end
local function mmul(a, b)
    local r = {}
    for i = 1, 3 do
        r[i] = {}
        for j = 1, 3 do r[i][j] = a[i][1] * b[1][j] + a[i][2] * b[2][j] + a[i][3] * b[3][j] end
    end
    return r
end
local function mvec(m, v)
    return v3(m[1][1] * v.X + m[1][2] * v.Y + m[1][3] * v.Z,
              m[2][1] * v.X + m[2][2] * v.Y + m[2][3] * v.Z,
              m[3][1] * v.X + m[3][2] * v.Y + m[3][3] * v.Z)
end
local I = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
CF.__mul = function(a, b)
    if getmetatable(b) == CF then return cf(a.p + mvec(a.m, b.p), mmul(a.m, b.m)) end
    return a.p + mvec(a.m, b)
end
local CFrame = {}
function CFrame.new(p) return cf(p, I) end
function CFrame.Angles(x, y, z)
    local cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    local rx = { { 1, 0, 0 }, { 0, cx, -sx }, { 0, sx, cx } }
    local ry = { { cy, 0, sy }, { 0, 1, 0 }, { -sy, 0, cy } }
    local rz = { { cz, -sz, 0 }, { sz, cz, 0 }, { 0, 0, 1 } }
    return cf(v3(0, 0, 0), mmul(mmul(rx, ry), rz))
end
function CFrame.lookAt(at, target)
    local look = (target - at).Unit
    local right = cross(look, v3(0, 1, 0)).Unit
    local up = cross(right, look)
    return cf(at, { { right.X, up.X, -look.X }, { right.Y, up.Y, -look.Y }, { right.Z, up.Z, -look.Z } })
end
local function rot(c, v) return mvec(c.m, v) end

local CFG = { CamDistance = 30, CamPitch = 55 }

