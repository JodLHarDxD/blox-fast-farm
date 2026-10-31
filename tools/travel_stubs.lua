-- The world flyTo sees, for TRAVEL (which trips are routed). The flight
-- itself is off (moveEnabled false): only the choice before it is tested.
local V = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__index = function(t, k)
    if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
    return nil
end
local Vector3 = { new = function(x, y, z) return v3(x or 0, y or 0, z or 0) end, zero = v3(0, 0, 0) }

local P = {}
local CFG = { TravelSpeed = 330, InstantHop = 150, TravelRoutes = true }
local NOW = 1000
local os = { clock = function() return NOW end }
local task = { wait = function(s) NOW += (s or 0.03) end }
local epoch = 0
local function stale(e) return e ~= epoch end
local function say() end
local SAID = {}
local realPrint = print
local function print(s) table.insert(SAID, tostring(s)) end
local SEA = 3
local function mySea() return SEA end
local SUB_Y = -1000
local TIKI_SUB = v3(-16900, 10, 400)
local function netRemote() return nil end

local POS = v3(0, 20, 0)
local root = setmetatable({}, { __index = function(_, k) if k == "Position" then return POS end return nil end,
    __newindex = function(_, k, v) if k == "CFrame" then POS = v.Position or POS end end })
local function parts() return {}, root, {} end
P.waterLine = function() return nil end
local LOCKS = {}
local function lockAt(p) table.insert(LOCKS, p) end
local function flatFace(p) return { Position = p } end
local function releaseCamera() end
local stats = { hops = 0, flights = 0, pulledBack = 0 }
local flying, lastWritten = false, nil
local moveEnabled = false
local RunService = { Heartbeat = { Wait = function() return 0.03 end } }

-- The First and Second Sea's entrances.
local LEGS = 0
local function portalLeg() LEGS += 1 return false end

-- ROUTES: records each long trip handed to it. NESTED = it flies inside
-- (as R.ride does, to a pad); BOOM = it errors; MOVE_TO = where it puts you.
local ROUTES, NESTED, BOOM, MOVE_TO = {}, false, false, nil
P.routeGo = function(goal)
    table.insert(ROUTES, goal)
    if BOOM then error("route broke") end
    if NESTED then P.flyTo(v3(-5000, 320, -3000)) end
    if MOVE_TO then POS = MOVE_TO return true end
    return false
end
