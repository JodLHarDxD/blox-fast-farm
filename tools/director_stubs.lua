-- The director's world: every target and the hop faked, each call logged.
local NOW = 100
local os = { clock = function() return NOW end, time = function() return NOW end }
local task = { wait = function() end }
local epoch = 0
local CFG, E, LOG, HOLD, FRUIT, ELITE_BUSY
local function reset()
    CFG = { Hunt = true, HuntFruit = true, HuntElite = true, HuntHop = true }
    E = { chalice = false, used = false, lookStart = NOW - 10, note = "", why = nil }
    LOG, HOLD, FRUIT, ELITE_BUSY = {}, false, nil, false
end
reset()
local function log(s) table.insert(LOG, s) end
local function holdingChalice() return HOLD end
local function chaliceStop() log("chalice") end
local function lookAgain() E.lookStart = NOW end
local function readProgress() end
local function fruitWanted() return FRUIT end
local function grabFruit(f) log("grab " .. f.orig) end
local function eliteLook() log("elite") if not ELITE_BUSY then E.why = "no elite up here" end return ELITE_BUSY end
local function hop(why) log("hop: " .. tostring(why)) return false end
local function say() end
local function setState() end
local huntStep
