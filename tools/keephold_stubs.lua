-- What keepHold() touches, faked. LEFT = the keepers keepersLeft() answers
-- (each try logged with its tryStore); SEA, the body's place ROOT, the
-- game's InSafeZone flag SAFE; every flight / lock / state / notice logged.
local V = {}
V.__index = V
local Vector3
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V.__index = function(t, k)
    if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
    return rawget(V, k)
end
Vector3 = { new = function(x, y, z) return v3(x or 0, y or 0, z or 0) end }

local MANSION = v3(-12471, 375, -7551)
local P = { PORTALS = { [3] = {
    { name = "the Castle on the Sea", pos = v3(-5072, 314, -3151) },
    { name = "the Mansion", pos = MANSION },
} } }
local NOW = 1000
local os = { clock = function() return NOW end, time = function() return NOW end, date = os.date }
local task = { wait = function() end }
local epoch = 0
local function stale(e) return e ~= epoch end
local E, LEFT, TRIES, LOG, SEA, ROOT, SAFE, FLIGHTS, FLIGHT_OPTS, LOCKS, STATES, NOTES, HOME
local function reset()
    E = { tally = { joins = 4 } }
    LEFT, TRIES, LOG, SEA, SAFE = {}, {}, {}, 3, nil
    ROOT = { Position = v3(100, 50, 100) }
    FLIGHTS, FLIGHT_OPTS, LOCKS, STATES, NOTES, HOME = {}, {}, {}, {}, {}, nil
    NOW = 1000
end
reset()
local function keepersLeft(tryStore) table.insert(TRIES, tryStore) return LEFT end
function P.keepWords(list)
    local w = {}
    for _, k in ipairs(list) do table.insert(w, k.orig) end
    return table.concat(w, ", ")
end
function P.fruitLogSet(orig, state, from)
    table.insert(LOG, "set " .. orig .. " " .. state)
    return (from and from.held and orig ~= "Fresh-Fresh") and {} or nil
end
function P.fruitLogAdd(e) table.insert(LOG, "add " .. e.orig .. " " .. e.state .. " " .. tostring(e.from)) return e end
local function parts() return {}, ROOT, {} end
local function mySea() return SEA end
local function flyTo(goal, opts) table.insert(FLIGHTS, goal) table.insert(FLIGHT_OPTS, opts or {}) ROOT.Position = goal end
-- Your Home Point (ROUTES): HOME, nil = none in this sea.
P.route = { homeAt = function() return HOME, HOME and "Castle on the Sea" or nil end }
local function lockAt(pos) table.insert(LOCKS, pos) end
local function setState(s) table.insert(STATES, s) end
local function say() end
local function notify(s) table.insert(NOTES, s) end
local function releasePile() end
local player = { GetAttribute = function(_, n) if n == "InSafeZone" then return SAFE end return nil end }
