-- What the body lock reads, faked: vectors, yaw-only CFrames (with lookAt and
-- identity), the player's root and Humanoid, P (running, the water's floor,
-- keepLock). The cases read lockCF / lastWritten through the section's own
-- locals (the section is pasted in this same chunk).
local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
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

local ROOT = { Position = vec(0, 50, 0), AssemblyLinearVelocity = vec(0, 0, 0), AssemblyAngularVelocity = vec(0, 0, 0) }
ROOT.CFrame = cf(ROOT.Position)
setmetatable(ROOT, { __newindex = function(t, k, v)
    if k == "CFrame" then rawset(t, "Position", v.Position) end
    rawset(t, k, v)
end })
local HUM = { AutoRotate = true }
local player = { Character = nil }
local function parts() return {}, ROOT, HUM end
local P = { running = true, handsOff = false }

-- The sea: one slab (workspace.Map["WaterBase-Plane"]), its top at Y 0 ->
-- the water line (every mode, 2026-10-11) at Y 4.
local SLAB = { Name = "WaterBase-Plane", Position = vec(0, -56, 0), Size = vec(20000, 112, 20000) }
SLAB.CFrame = { PointToObjectSpace = function(_, p) return p - SLAB.Position end }
function SLAB:IsA(c) return c == "BasePart" end
local MAP = { FindFirstChild = function(_, n) return n == "WaterBase-Plane" and SLAB or nil end }
SLAB.Parent = MAP
local workspace = { FindFirstChild = function(_, n) return n == "Map" and MAP or nil end }
