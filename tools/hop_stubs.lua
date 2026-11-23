-- Everything hop() touches, faked. HOLD = the chalice is in the backpack;
-- AFTER_JOIN runs after each join attempt (the join itself always "fails",
-- as a successful one would end the script).
local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }
local NOW = 100000
local os = { time = function() return NOW end, clock = function() return NOW end }
local task = { wait = function() end, spawn = function(f, ...) f(...) end }
local CFG = { Hunt = true, HopRevisit = 10, HopOrder = "fewest" }
local P = { running = true }
local epoch = 0
local function stale(e) return e ~= epoch end
local game = { JobId = "here", PlaceId = 1 }
local E, HOLD, AFTER_JOIN, ROWS, log, LIST_HOOK
local function reset()
    E = { visited = {}, tally = { fails = 0 }, hopping = false, chalice = false }
    HOLD, AFTER_JOIN, ROWS, LIST_HOOK = false, nil, {}, nil
    log = { joins = {}, chaliceStops = 0, carries = 0, stores = 0, files = 0 }
    P.storeBeforeHop = function() log.stores += 1 log.storedBeforeJoin = (#log.joins == 0) end
    epoch = 0
end
reset()
local function holdingChalice() return HOLD end
local function markChalice() log.chaliceStops += 1 E.chalice = true end
local function say() end
local function releasePile() end
local function setState() end
local function browserList() if LIST_HOOK then LIST_HOOK() end return ROWS end
local function robloxList() return {} end
local function carryState(resume) log.carries += 1 log.lastResume = resume return "carry" end
local function fileWrite() log.files += 1 return true end
local function queueReload() end
local function joinServer(id, myEpoch, gone)
    log.goneGiven = gone ~= nil
    -- the real one asks gone() right before the teleport call: no call then
    if (gone and gone()) or myEpoch ~= epoch then return false end
    table.insert(log.joins, id)
    if AFTER_JOIN then AFTER_JOIN(id) end
    return false
end
local player = { UserId = 1 }
