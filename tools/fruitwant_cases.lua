
-- ---------------------------------------------------------------- cases
-- WHICH FRUIT THE HUNT GOES FOR (2026-11-13): the real fruitWanted, with
-- the real pickFruit, P.fruitHold, P.fruitFull. The world: LIST = what
-- fruitsLying() gives this look.
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function fresh()
    E = { fruitSkip = {} }
    LIST, STOCK, STOCK_READS, NOW, SAID = {}, { ["Shadow-Shadow"] = 3, ["Spin-Spin"] = 1 }, 0, 100, {}
    CFG.Hunt, CFG.HuntKind, CFG.FruitMinPrice, CFG.FruitPlayerDrops = true, "fruit", 2800000, false
    CFG.FruitUnknownSpawn, CFG.FruitStore, CFG.FruitSkipFull, CFG.FruitKeepValue = true, true, true, 20000000
    CFG.FruitLoadWait = 8
    P.fruitCapSeen = nil
    CAP = 3
end
local function spawn(orig, price, extra)
    local f = { tool = {}, orig = orig, name = orig or "Fruit ", price = price }
    for k, v in pairs(extra or {}) do f[k] = v end
    return f
end

-- THE USER'S SHADOW: first seen still loading (ExpectedDescendants 123, no
-- mesh yet) - with "unknown spawn" on it used to be gone for at once.
fresh()
local shadow = spawn(nil, nil, { loading = true, isle = "Colosseum" })
LIST = { shadow }
local f, hold = fruitWanted()
check("a spawn still loading: NOT gone for as an unknown spawn", f == nil)
check("...the hunt holds (no hop either)", hold == true)
check("...and says so, with where it is", string.find(tostring(E.fruitHoldNote), "still loading", 1, true) ~= nil
    and string.find(tostring(E.fruitHoldNote), "Colosseum", 1, true) ~= nil, E.fruitHoldNote)
NOW += 3
f, hold = fruitWanted()
check("...3 s later, still loading: still held", f == nil and hold == true)
-- its meshes arrived: it is the Shadow, your storage holds 3 of 3
shadow.loading, shadow.orig, shadow.name, shadow.price = false, "Shadow-Shadow", "Shadow Fruit", 2900000
f, hold = fruitWanted()
check("...named: a Shadow, your storage full of it (3/3) - LEFT, not collected again", f == nil and hold == nil)
check("...why is in the hunt's line", string.find(tostring(E.fruitWhy), "Shadow: your storage is full of it (3/3)", 1, true) ~= nil,
    E.fruitWhy)
check("...and in the log, once", #SAID == 1 and string.find(SAID[1], "left where it lies", 1, true) ~= nil, table.concat(SAID, "|"))
fruitWanted()
check("...not said again every look", #SAID == 1, #SAID)

-- a slot free: taken
fresh()
STOCK["Shadow-Shadow"] = 2
LIST = { spawn("Shadow-Shadow", 2900000) }
check("2 of 3 stored: a slot is free - taken", fruitWanted() == LIST[1])
-- the switch off: taken anyway
fresh()
CFG.FruitSkipFull = false
LIST = { spawn("Shadow-Shadow", 2900000) }
check("\"Leave a fruit my storage is full of\" off: taken anyway", fruitWanted() == LIST[1])
-- not storing at once (raid chips): storage does not matter
fresh()
CFG.FruitStore = false
LIST = { spawn("Shadow-Shadow", 2900000) }
check("\"Store it at once\" off (for raid chips): storage is not asked", fruitWanted() == LIST[1] and STOCK_READS == 0, STOCK_READS)
-- one too good to lose: taken though storage is full (held safe after)
fresh()
STOCK["Kitsune-Kitsune"] = 3
LIST = { spawn("Kitsune-Kitsune", 8000000) }
check("a Kitsune with storage full of it: still taken (too good to lose - held safe)", fruitWanted() == LIST[1])
-- the cap not known: nothing is left for it
fresh()
CAP = nil
LIST = { spawn("Shadow-Shadow", 2900000) }
check("storage size not read: nothing is left for being full", fruitWanted() == LIST[1])
-- ...then the game's own "storage full" answer gave it
P.fruitCapSeen = 3
check("...the game's 'storage full' answer gave the size: left", fruitWanted() == nil)
-- storage not readable: nothing is left for it
fresh()
STOCK = nil
LIST = { spawn("Shadow-Shadow", 2900000) }
check("storage not readable: taken (never left on a guess)", fruitWanted() == LIST[1])

-- the loading wait ends: the unknown-spawn switch decides, as before
fresh()
local slow = spawn(nil, nil, { loading = true })
LIST = { slow }
fruitWanted()
NOW += 8.5
f, hold = fruitWanted()
check("still not named after 8 s: the unknown-spawn switch decides (on = gone for)", f == slow and hold == nil)
fresh()
CFG.FruitUnknownSpawn = false
slow = spawn(nil, nil, { loading = true })
LIST = { slow }
f, hold = fruitWanted()
check("unknown-spawn off: a loading one is STILL waited for (a dear one must not be hopped away from)", f == nil and hold == true)
NOW += 8.5
f, hold = fruitWanted()
check("...after 8 s unnamed: left, the hunt moves on", f == nil and hold == nil)

-- a named dear one does not wait for a loading one next to it? It waits:
-- the loading one may be dearer - 8 s at most.
fresh()
local dough = spawn("Dough-Dough", 2800000)
LIST = { dough, spawn(nil, nil, { loading = true }) }
f, hold = fruitWanted()
check("a named fruit and a loading one: held until both are named (the other may be dearer)", f == nil and hold == true)
NOW += 9
check("...8 s on: the named one is taken", fruitWanted() == dough)

-- a player's drop still "loading" is never waited for when drops are off? It
-- has its name on it (OriginalName) - never loading.
fresh()
LIST = { spawn("Spin-Spin", 7500) }
f, hold = fruitWanted()
check("a cheap named spawn: left, no wait", f == nil and hold == nil)

-- storage is read again after something was stored
fresh()
LIST = { spawn("Dough-Dough", 2800000) }
fruitWanted()
local r0 = STOCK_READS
fruitWanted()
check("storage is not read at every look", STOCK_READS == r0, STOCK_READS)
E.fruitStockDirty = true
NOW += 6
fruitWanted()
check("...but again once something was stored", STOCK_READS == r0 + 1, STOCK_READS)

-- P.fruitLoading: the game's own attributes
do
    local function model(exp, n)
        return { GetAttribute = function(_, k) return k == "ExpectedDescendants" and exp or nil end,
            GetDescendants = function() local t = {} for i = 1, n do t[i] = i end return t end }
    end
    check("ExpectedDescendants 123, 40 here: loading", P.fruitLoading(model(123, 40)) == true)
    check("ExpectedDescendants 123, 123 here: loaded", P.fruitLoading(model(123, 123)) == false)
    check("no ExpectedDescendants (the game cleared it - all there): loaded", P.fruitLoading(model(nil, 5)) == false)
end
-- P.fruitFull
check("full: 3 of 3", P.fruitFull("Shadow-Shadow", { ["Shadow-Shadow"] = 3 }, 3, P.storedCount) == true)
check("not full: 2 of 3", P.fruitFull("Shadow-Shadow", { ["Shadow-Shadow"] = 2 }, 3, P.storedCount) == false)
check("not full: none stored", P.fruitFull("Shadow-Shadow", {}, 3, P.storedCount) == false)
check("no cap / no stock / no name: never full", P.fruitFull("Shadow-Shadow", { ["Shadow-Shadow"] = 9 }, nil, P.storedCount) == false
    and P.fruitFull("Shadow-Shadow", nil, 3, P.storedCount) == false and P.fruitFull(nil, {}, 3, P.storedCount) == false)

print(all and "ALL PASS" or "SOME FAILED")
