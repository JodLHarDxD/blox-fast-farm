-- Everything hop() touches, faked. HOLD = the chalice is in the backpack;
-- AFTER_JOIN runs after each join attempt (the join itself always "fails",
-- as a successful one would end the script).
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
local NOW = 100000
local os = { time = function() return NOW end, clock = function() return NOW end }
local task = { wait = function() end, spawn = function(f, ...) f(...) end }
local CFG = { EliteHunt = true, EliteRevisit = 10, EliteOrder = "fewest" }
local P = { running = true }
local epoch = 0
local function stale(e) return e ~= epoch end
local game = { JobId = "here", PlaceId = 1 }
local E, HOLD, AFTER_JOIN, ROWS, log
local function reset()
    E = { visited = {}, tally = { fails = 0 }, hopping = false, chalice = false }
    HOLD, AFTER_JOIN, ROWS = false, nil, {}
    log = { joins = {}, chaliceStops = 0, carries = 0 }
    epoch = 0
end
reset()
local function holdingChalice() return HOLD end
local function markChalice() log.chaliceStops += 1 E.chalice = true end
local function say() end
local function releasePile() end
local function setState() end
local function browserList() return ROWS end
local function robloxList() return {} end
local function carryState() log.carries += 1 return "carry" end
local function fileWrite() return true end
local function queueReload() end
local function joinServer(id)
    table.insert(log.joins, id)
    if AFTER_JOIN then AFTER_JOIN(id) end
    return false
end
local player = { UserId = 1 }
