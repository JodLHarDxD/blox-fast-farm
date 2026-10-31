-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function said(w) for _, s in ipairs(PRINTED) do if string.find(s, w, 1, true) then return true end end return false end

local rocket = tool("Rocket Fruit", { OriginalName = "Rocket-Rocket" }, true)
local dough = tool("Dough Fruit", {}, true)                -- named off its name
local sword = tool("Katana", {}, false)
local spin = tool("Spin Fruit", { OriginalName = "Spin-Spin" }, true)
for _, t in ipairs({ rocket, dough, sword, spin }) do t.Parent = BACKPACK table.insert(BACKPACK.kids, t) end
STORE_OK["Spin-Spin"] = false
P.storeBeforeHop()
check("before a hop: every fruit in the backpack stored, by the game's name or its own",
    table.concat(STORED, ",") == "Rocket-Rocket,Dough-Dough,Spin-Spin", table.concat(STORED, ","))
check("...never a sword or anything not a fruit", not said("Katana"))
check("...the fruit in your hand put away first", UNEQUIPS == 1)
check("...each said; one the game refused said with why", said("stored Rocket-Rocket before leaving")
    and said("could NOT store Spin-Spin (you already have one)"))
check("...the history: stored before a hop / LOST at the hop", table.concat(LOGSET, ",")
    == "Rocket-Rocket hopstored,Dough-Dough hopstored,Spin-Spin lost", table.concat(LOGSET, ","))

STORED, PRINTED = {}, {}
CFG.FruitStoreOnHop = false
P.storeBeforeHop()
check("switch off: nothing stored before a hop", #STORED == 0)

local ok, orig = storeTool(tool("Ice Fruit", { OriginalName = "Ice-Ice" }, true), nil)
check("one store: true + the game's name", ok == true and orig == "Ice-Ice")
local _, odd = storeTool(tool("Odd Fruit", { OriginalName = "Kitsune-Kitsune" }, true), nil)
check("the game's OriginalName wins over the name on it", odd == "Kitsune-Kitsune", odd)
STORE_OK["Ice-Ice"] = false
local ice2 = tool("Ice Fruit", { OriginalName = "Ice-Ice" }, true)
ice2.Parent = BACKPACK                                     -- still in your backpack after the refusal
local ok2, orig2, why = storeTool(ice2, nil)
check("refused: false + its name + the game's words", ok2 == false and orig2 == "Ice-Ice" and why == "you already have one", why)

-- A FRUIT TOO GOOD TO LOSE (user, 2026-10-25): keepersLeft
local function bag(list)
    BACKPACK.kids = {}
    for _, t in ipairs(list) do t.Parent = BACKPACK table.insert(BACKPACK.kids, t) end
end
STORED, LOGSET, STORE_OK = {}, {}, {}
local d1 = tool("Dough Fruit", { OriginalName = "Dough-Dough" }, true)
local b1 = tool("Buddha Fruit", { OriginalName = "Buddha-Buddha" }, true)
bag({ d1, b1 })
local left = keepersLeft(false)
check("keepers: the Dough (30M), not the Buddha (10M) - the market's value, no store tried",
    #left == 1 and left[1].orig == "Dough-Dough" and left[1].value == 30e6 and #STORED == 0, #left)
STORE_OK["Dough-Dough"] = false
left = keepersLeft(true)
check("no slot: tried, still carried", #left == 1 and table.concat(STORED, ",") == "Dough-Dough",
    table.concat(STORED, ","))
STORE_OK["Dough-Dough"] = nil
STORED = {}
left = keepersLeft(true)
check("a slot freed: stored, none left, its entry says so", #left == 0 and STORED[1] == "Dough-Dough"
    and LOGSET[#LOGSET] == "Dough-Dough slot", LOGSET[#LOGSET])

STORED, LOGSET, UNEQUIPS = {}, {}, 0
BACKPACK.kids = {}
local c1 = tool("Control Fruit", { OriginalName = "Control-Control" }, true)
c1.Parent = CHAR
CHAR.kids = { c1 }
left = keepersLeft(false)
check("one in your hand: counted, put away first (a click with it held eats it)", #left == 1
    and left[1].orig == "Control-Control" and UNEQUIPS == 1 and c1.Parent == BACKPACK)

bag({ tool("Moon Fruit", { OriginalName = "Moon-Moon" }, true) })
check("a fruit newer than the list: counted", #keepersLeft(false) == 1)
bag({ tool("Dough Fruit", {}, true) })
check("named off its own name when it has no OriginalName", (keepersLeft(false)[1] or {}).orig == "Dough-Dough")

CFG.FruitKeepValue = 0
STORED = {}
bag({ tool("Dough Fruit", { OriginalName = "Dough-Dough" }, true) })
check("line 0 = off: none, nothing tried", #keepersLeft(true) == 0 and #STORED == 0)
CFG.FruitKeepValue = 20000000
check("in words: Control (120M)", P.keepWords({ { orig = "Control-Control", value = 120e6 } }) == "Control (120M)",
    P.keepWords({ { orig = "Control-Control", value = 120e6 } }))

-- STORED AND CONFIRMED (user, 2026-10-31: the volcano's Dragon fruit "totally
-- in my inventory" before the hop): the tool gone AND the storage count up.
VALUES["Dragon-Dragon"] = 2.97e9
local function dragonIn(where)
    local d = tool("Dragon Fruit", { OriginalName = "Dragon-Dragon" }, true)
    BACKPACK.kids, CHAR.kids = {}, {}
    d.Parent = where
    table.insert(where.kids, d)
    return d
end
STORED, PRINTED, LOGADD = {}, {}, {}
STORAGE, STORAGE_LAGS = { ["Kitsune-Kitsune"] = 1 }, false
local d = dragonIn(BACKPACK)
local okS, o, words = P.fruitSecure(d, "volcano egg")
check("the Dragon stored: CONFIRMED by the storage count 0 -> 1", okS == true and o == "Dragon-Dragon"
    and string.find(words, "STORED - confirmed: your storage has 1 (was 0)", 1, true) ~= nil, words)
check("...said in the console, logged as from the volcano egg, stored", said("[BFF] fruit: Dragon-Dragon")
    and LOGADD[1] and LOGADD[1].from == "volcano egg" and LOGADD[1].state == "stored" and LOGADD[1].server == 7,
    LOGADD[1] and LOGADD[1].state)

STORAGE = { ["Dragon-Dragon"] = 1 }
STORE_FULL["Dragon-Dragon"] = 1
LOGADD = {}
d = dragonIn(BACKPACK)
okS, o, words = P.fruitSecure(d, "volcano")
check("storage full (the game answers a number): NOT stored, still with you, says why", okS == false
    and d.Parent == BACKPACK and string.find(words, "storage full - it holds 1 of each fruit", 1, true) ~= nil, words)
check("...logged as held", LOGADD[1] and LOGADD[1].state == "held")
STORE_FULL["Dragon-Dragon"] = nil

STORAGE = nil
d = dragonIn(BACKPACK)
okS, o, words = P.fruitSecure(d, "volcano")
check("storage not readable: gone from your backpack, said as not confirmed", okS == true
    and string.find(words, "is not readable here", 1, true) ~= nil and not string.find(words, "confirmed", 1, true), words)

STORAGE, STORAGE_LAGS = { ["Dragon-Dragon"] = 1 }, true
local t0 = CLOCK
d = dragonIn(BACKPACK)
okS, o, words = P.fruitSecure(d, "volcano")
check("the count never rises: read again for 5 s, then said (not claimed)", okS == true
    and string.find(words, "did not show it yet", 1, true) ~= nil and CLOCK - t0 >= 5, words)
STORAGE_LAGS = false

UNEQUIPS = 0
STORAGE = { ["Dragon-Dragon"] = 0 }
d = dragonIn(CHAR)
okS = P.fruitSecure(d, "volcano")
check("in your hand: put away first, then stored", UNEQUIPS == 1 and okS == true and STORAGE["Dragon-Dragon"] == 1)

check("a stored name read either way ('Dragon Fruit' / 'Dragon-Dragon')",
    P.storedCount({ ["Dragon Fruit"] = 1, ["Dragon-Dragon"] = 2, ["Spin-Spin"] = 4 }, "Dragon-Dragon") == 3
    and P.storedCount(nil, "Dragon-Dragon") == nil)

realPrint(all and "ALL PASS" or "SOME FAILED")
