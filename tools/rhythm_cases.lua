
local function W(t) t.hold = {} t.use = true for _, k in ipairs(KEYS) do t[k] = t[k] or false end t.M1 = t.M1 or false return t end
local function run(name, cfg, ticks, expect)
    CFG = cfg; LOG = {}; clock = 0; held = nil; CD = {}; m1Count = (cfg.StartWith == "M1") and 0 or cfg.M1Between
    for _ = 1, ticks do attackTick() end
    local got = table.concat(LOG, " | ")
    local ok = got == expect
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then print("  got:    " .. got) print("  expect: " .. expect) end
    return ok
end
local base = { M1Every = 1, CastWait = 0.5, M1Between = 4, StartWith = "Skills", HeightMode = "auto", AimSkills = false, WeaponOrder = { "Kitsune", "Sanguine Art", "Sword" } }
local function cfg(over, weapons) local c = {} for k, v in pairs(base) do c[k] = v end for k, v in pairs(over) do c[k] = v end c.Weapons = weapons return c end
local all = true
all = run("Kitsune M1 only", cfg({}, { Kitsune = W{ M1 = true }, ["Sanguine Art"] = W{}, Sword = W{} }), 3,
    "swap Kitsune | M1 Kitsune | M1 Kitsune | M1 Kitsune") and all
all = run("Sanguine Art M1 only", cfg({}, { Kitsune = W{}, ["Sanguine Art"] = W{ M1 = true }, Sword = W{} }), 2,
    "swap Sanguine Art | M1 Sanguine Art | M1 Sanguine Art") and all
all = run("sword M1 only", cfg({}, { Kitsune = W{}, ["Sanguine Art"] = W{}, Sword = W{ M1 = true } }), 2,
    "swap Sword | M1 Sword | M1 Sword") and all
all = run("skills only, both weapons, then all cooling", cfg({}, { Kitsune = W{ Z = true, X = true }, ["Sanguine Art"] = W{ Z = true }, Sword = W{} }), 5,
    "swap Kitsune | cast Kitsune Z | cast Kitsune X | swap Sanguine Art | cast Sanguine Art Z") and all
all = run("both: Kitsune M1 + SA Z X, 2 between, skills first", cfg({ M1Between = 2 }, { Kitsune = W{ M1 = true }, ["Sanguine Art"] = W{ Z = true, X = true }, Sword = W{} }), 7,
    "swap Sanguine Art | cast Sanguine Art Z | swap Kitsune | M1 Kitsune | M1 Kitsune | swap Sanguine Art | cast Sanguine Art X | swap Kitsune | M1 Kitsune | M1 Kitsune | swap Sanguine Art | cast Sanguine Art Z") and all
all = run("both, M1 first", cfg({ M1Between = 2, StartWith = "M1" }, { Kitsune = W{ M1 = true, Z = true }, ["Sanguine Art"] = W{}, Sword = W{} }), 4,
    "swap Kitsune | M1 Kitsune | M1 Kitsune | cast Kitsune Z | M1 Kitsune") and all
all = run("0 between: skill whenever ready, M1 while cooling", cfg({ M1Between = 0 }, { Kitsune = W{ M1 = true, Z = true }, ["Sanguine Art"] = W{}, Sword = W{} }), 4,
    "swap Kitsune | cast Kitsune Z | M1 Kitsune | M1 Kitsune | M1 Kitsune") and all
all = run("skill comes back after cooldown (5s)", cfg({ M1Between = 0, M1Every = 1 }, { Kitsune = W{ M1 = true, Z = true }, ["Sanguine Art"] = W{}, Sword = W{} }), 7,
    "swap Kitsune | cast Kitsune Z | M1 Kitsune | M1 Kitsune | M1 Kitsune | M1 Kitsune | M1 Kitsune | cast Kitsune Z") and all
all = run("use off = weapon fires nothing", cfg({}, { Kitsune = (function() local w = W{ M1 = true } w.use = false return w end)(), ["Sanguine Art"] = W{ M1 = true }, Sword = W{} }), 1,
    "swap Sanguine Art | M1 Sanguine Art") and all
-- Every carried skill cooling: the next sword from your inventory (P.rotate), fired.
TOOLS.Yama = { kind = "Sword" }
P.rotate = function(vents)
    if vents or CFG.Weapons.Yama.use then return false end
    ev("load Yama")
    CFG.Weapons.Yama = W{ Z = true }
    table.insert(CFG.WeaponOrder, "Yama")
    return true
end
local rc = cfg({}, { Kitsune = W{ Z = true }, ["Sanguine Art"] = W{}, Sword = W{} })
rc.WeaponOrder = { "Kitsune", "Sanguine Art", "Sword" }
rc.Weapons.Yama = W{}
rc.Weapons.Yama.use = false
all = run("every skill cooling: a sword from the inventory, then its skill", rc, 3,
    "swap Kitsune | cast Kitsune Z | load Yama | swap Yama | cast Yama Z") and all
P.rotate = nil
-- A key sent whose skill never fires: left alone for a minute.
local realHold = holdKey
holdKey = function(code, _) ev("cast " .. held .. " " .. code) end       -- no cooldown starts: it did not fire
cdStore = {}
all = run("a key that does not fire is sent once", cfg({ M1Between = 0 }, { Kitsune = W{ Z = true }, ["Sanguine Art"] = W{}, Sword = W{} }), 1,
    "swap Kitsune | cast Kitsune Z") and all
local dead = cdStore["KitsuneZ"] and cdStore["KitsuneZ"].deadUntil
local okDead = dead ~= nil and dead >= clock + 59
print((okDead and "PASS " or "FAIL ") .. "...and marked: left alone for a minute")
all = okDead and all
holdKey = realHold
-- The M1 weapon is the pick (P.m1Of), not the first in the list with M1 on.
P.m1Of = function(used)
    for _, u in ipairs(used) do if u.name == "Sword" then return u end end
    return nil
end
all = run("M1: the picked sword swings although Kitsune is listed first with M1 on",
    cfg({}, { Kitsune = W{ M1 = true }, ["Sanguine Art"] = W{ M1 = true }, Sword = W{ M1 = true } }), 2,
    "swap Sword | M1 Sword | M1 Sword") and all
local kept = P.keepSword == "Sword"
print((kept and "PASS " or "FAIL ") .. "...and that sword is kept from the rotation (any attack mode)")
all = kept and all
P.m1Of, P.keepSword = nil, nil
print(all and "ALL PASS" or "SOME FAILED")
