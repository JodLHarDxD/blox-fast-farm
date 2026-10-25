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

realPrint(all and "ALL PASS" or "SOME FAILED")
