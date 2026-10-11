-- What the lock and a flight read, faked: vectors (Unit, scaling), yaw-only
-- CFrames, the root (a write to its CFrame moves it; the lowest Y ever
-- written is kept in MINY), the sea slab (workspace.Map["WaterBase-Plane"]:
-- middle at Y -56, 20,000 studs wide, raised to 112 = its top is the surface,
-- Y 0), the clock (Heartbeat:Wait = one 1/60 s frame) and what a flight calls.
local CLOCK = 0
local os = { clock = function() return CLOCK end }

local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__index = function(v, k)
    local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
    if k == "Magnitude" then return m end
    if k == "Unit" then return vec(v.X / m, v.Y / m, v.Z / m) end
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__mul = function(a, b)
    if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
    return vec(a.X * b, a.Y * b, a.Z * b)
end
local Vector3 = { new = vec, zero = vec(0, 0, 0) }

local CF = {}
local function cf(pos, yaw) return setmetatable({ Position = pos, yaw = yaw or 0 }, CF) end
CF.__mul = function(a, b) return cf(a.Position + b.Position, a.yaw + b.yaw) end
CF.__add = function(a, v) return cf(a.Position + v, a.yaw) end
CF.__sub = function(a, v) return cf(a.Position - v, a.yaw) end
local CFrame = {
    new = function(p) return cf(p or vec(0, 0, 0), 0) end,
    lookAt = function(p, at) return cf(p, math.atan2(-(at.X - p.X), -(at.Z - p.Z))) end,
    identity = cf(vec(0, 0, 0), 0),
}

-- The root is a proxy (its store is RSTORE), so EVERY write goes through
-- __newindex: a CFrame write moves Position and is counted in MINY.
-- place(p) puts the body somewhere without counting it as the script's write.
local MINY = math.huge
local RSTORE = { Position = vec(0, 50, 0), AssemblyLinearVelocity = vec(0, 0, 0), AssemblyAngularVelocity = vec(0, 0, 0) }
RSTORE.CFrame = cf(RSTORE.Position)
local ROOT = setmetatable({}, {
    __index = RSTORE,
    __newindex = function(_, k, v)
        if k == "CFrame" then
            RSTORE.Position = v.Position
            MINY = math.min(MINY, v.Position.Y)
        end
        RSTORE[k] = v
    end,
})
local function place(p)
    RSTORE.CFrame = cf(p)
    RSTORE.Position = p
end
local HUM = { AutoRotate = true }
local player = { Character = nil }
local function parts() return {}, ROOT, HUM end
local P = { running = true, handsOff = false }

-- The sea: one slab, axis-aligned here.
local SLAB = { Name = "WaterBase-Plane", Position = vec(0, -56, 0), Size = vec(20000, 112, 20000) }
SLAB.CFrame = { PointToObjectSpace = function(_, p) return p - SLAB.Position end }
function SLAB:IsA(c) return c == "BasePart" end
local MAP = { FindFirstChild = function(_, n) return n == "WaterBase-Plane" and SLAB or nil end }
SLAB.Parent = MAP
local workspace = { FindFirstChild = function(_, n) return n == "Map" and MAP or nil end }

-- What a flight calls.
local RunService = { Heartbeat = { Wait = function() CLOCK += 1 / 60 return 1 / 60 end } }
local game = { GetService = function() return {} end }
local CFG = { TravelSpeed = 330, InstantHop = 150 }
local stats = { flights = 0, hops = 0, pulledBack = 0 }
local epoch, moveEnabled = 0, true
local function stale(e) return e ~= epoch end
local function say() end
local function netRemote() return nil end
