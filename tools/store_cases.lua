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

realPrint(all and "ALL PASS" or "SOME FAILED")
