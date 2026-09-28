-- The world, faked, for "where a species is" and the pile: loaded enemies,
-- EnemySpawns parts, parked enemies in ReplicatedStorage, your position.
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
V3.__div = function(a, n) return v3(a.X / n, a.Y / n, a.Z / n) end
local Vector3 = { new = v3, zero = v3(0, 0, 0) }

local function part(name, pos)
    return { Name = name, Position = pos, IsA = function(_, c) return c == "BasePart" end }
end
local function model(name, pos)
    local hrp = part("HumanoidRootPart", pos)
    return { Name = name, IsA = function(_, c) return c == "Model" end,
             FindFirstChild = function(_, n) if n == "HumanoidRootPart" then return hrp end end }
end
local WORLD = { spawns = {}, parked = {}, loaded = {} }
local spawnsFolder = { GetChildren = function() return WORLD.spawns end }
local worldOrigin = { FindFirstChild = function(_, n) if n == "EnemySpawns" then return spawnsFolder end end }
local workspace = { FindFirstChild = function(_, n) if n == "_WorldOrigin" then return worldOrigin end end }
local RS = { GetChildren = function() return WORLD.parked end }

local ME = { Position = v3(0, 0, 0) }
local function parts() return {}, ME, {} end
local function liveEnemies(names)
    local out = {}
    for _, e in ipairs(WORLD.loaded) do
        if (not names) or names[e.name] then table.insert(out, e) end
    end
    return out
end
local function enemy(name, pos)
    return { model = { Name = name }, hum = { Health = 100 }, root = { Position = pos }, name = name }
end
local function releaseCamera() end
local P = {}
local CFG = { Magnet = true, GrabRadius = 300, GrabMax = 12, PullOthers = true, OthersRadius = 100, MaxPull = 300, LearnLeash = true }

