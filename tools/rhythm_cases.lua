
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
print(all and "ALL PASS" or "SOME FAILED")
