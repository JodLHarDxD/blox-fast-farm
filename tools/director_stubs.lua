-- The director's world: every hunt and the hop faked, each call logged.
local NOW = 100
local os = { clock = function() return NOW end, time = function() return NOW end }
local task = { wait = function() end }
local epoch = 0
local CFG, E, LOG, HOLD, FRUIT, BERRY, ELITE_BUSY, RECIPE_BUSY, FLOWER_BUSY, FLOWER_WHY, FLOWER_KEEP
local function reset()
    CFG = { Hunt = true, HuntKind = "elite", HuntHop = true }
    E = { chalice = false, used = false, lookStart = NOW - 10, note = "", why = nil }
    LOG, HOLD, FRUIT, BERRY, ELITE_BUSY, RECIPE_BUSY = {}, false, nil, nil, false, false
    FLOWER_BUSY, FLOWER_WHY, FLOWER_KEEP = false, nil, nil
end
reset()
local function log(s) table.insert(LOG, s) end
local function holdingChalice() return HOLD end
local function chaliceStop() log("chalice") end
local function lookAgain() E.lookStart = NOW end
local function readProgress() end
local function berryCounts() end
local function fruitWanted() return FRUIT end
local function grabFruit(f) log("grab " .. f.orig) end
local function berryWanted() return BERRY end
local function grabBerry(b) log("berry " .. b.names[1]) end
local function eliteLook() log("elite") if not ELITE_BUSY then E.why = "no elite up here" end return ELITE_BUSY end
local function recipeStep() log("recipe") if not RECIPE_BUSY then E.why = "he teaches Pure Red here - not one you picked" end return RECIPE_BUSY end
local function flowerCount() end
local function flowerStep() log("flower") if not FLOWER_BUSY then E.why = FLOWER_WHY or "no Fire Flower in 2 min of killing" E.keepAway = FLOWER_KEEP end return FLOWER_BUSY end
local function hop(why, keep) log("hop: " .. tostring(why) .. (keep and (" +" .. keep) or "")) return false end
local function say() end
local function setState() end
-- The sea hunts' own step (SEA HUNT): logged with its kind; true = busy.
local P = { sea = { huntStep = function(_, kind) log("sea " .. tostring(kind)) return true end } }
local huntStep
