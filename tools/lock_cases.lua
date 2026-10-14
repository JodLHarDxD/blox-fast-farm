
-- A load of the script: the defaults as written, the section run once.
local function load(defaults)
    CFG = deep(defaults)
    P = { build = "test", cfgDefaults = deep(defaults) }
    _G_BFF = P
    runSection()
    return P.lock
end
local FILE = "bff_settings_42.json"
local DEF = {
    PvpLeadScale = 1.0, PvpRange = 300, PvpLead = false, Pvp = false,
    PvpAimKeys = { Sword = { M1 = true, Z = false, X = true }, ["Blox Fruit"] = { M1 = true, Z = true, X = true } },
    WeaponOrder = { "Katana", "Dragonstorm", "Godhuman" },
    Team = "Pirates",
}

-- ===== no file: unlocked, defaults =====
local K = load(DEF)
check("first load, no file: not locked", K.on == false and CFG.PvpRange == 300)
check("says a reload starts from the defaults", string.find(K.note, "defaults", 1, true) ~= nil)

-- ===== you change things and lock =====
CFG.PvpLeadScale = 1.4
CFG.PvpAimKeys.Sword.X = false
CFG.WeaponOrder = { "Buddy Sword" }
CFG.Team = "Marines"
CFG.Weird = function() end                       -- not something a file can hold
P.lockSet(true)
check("lock on: the file written", FS[FILE] ~= nil and K.on == true)
local saved = HttpService:JSONDecode(FS[FILE])
check("the file says locked", saved.locked == true)
check("what you changed is in it", saved.cfg.PvpLeadScale == 1.4 and saved.cfg.Team == "Marines"
    and saved.cfg.PvpAimKeys.Sword.X == false)
check("what you never touched is NOT in it", saved.cfg.PvpRange == nil and saved.cfg.PvpLead == nil)
check("a function is never written (no error either)", saved.cfg.Weird == nil)
check("the panel line counts them", string.find(K.note, "4 you changed", 1, true) ~= nil)

-- ===== the next load: yours back, a NEW default still reaches the rest =====
local DEF2 = deep(DEF)
DEF2.PvpRange = 350                              -- a later build changed this default
DEF2.PvpAimKeys.Gun = { M1 = true }              -- ...and added a weapon
DEF2.PvpAimKeys.Sword.C = true                   -- ...and a key
DEF2.NewThing = 7
K = load(DEF2)
check("reload: locked", K.on == true)
check("reload: your Lead strength back", CFG.PvpLeadScale == 1.4)
check("reload: your team back", CFG.Team == "Marines")
check("reload: your sword X still yours, its Z as it was", CFG.PvpAimKeys.Sword.X == false and CFG.PvpAimKeys.Sword.Z == false)
check("reload: a key the new build added keeps its default", CFG.PvpAimKeys.Sword.C == true)
check("reload: a weapon the new build added keeps its default", CFG.PvpAimKeys.Gun and CFG.PvpAimKeys.Gun.M1 == true)
check("reload: an untouched setting gets the NEW default", CFG.PvpRange == 350 and CFG.NewThing == 7)
check("reload: a list is yours whole (not mixed with the default's)", #CFG.WeaponOrder == 1 and CFG.WeaponOrder[1] == "Buddy Sword")
check("reload: the console says so", string.find(printed[#printed] or "", "settings lock", 1, true) ~= nil)

-- ===== a setting whose kind changed in a later build =====
local DEF3 = deep(DEF)
DEF3.PvpLeadScale = "auto"                        -- now a string
K = load(DEF3)
check("its kind changed: the new default, not your old number", CFG.PvpLeadScale == "auto" and CFG.Team == "Marines")

-- ===== unlock =====
P.lockSet(false)
check("unlock: the file says unlocked", HttpService:JSONDecode(FS[FILE]).locked == false and K.on == false)
K = load(DEF)
check("after unlock, the next load: defaults", K.on == false and CFG.PvpLeadScale == 1.0 and CFG.Team == "Pirates")

-- ===== a file that holds settings but says unlocked =====
FS[FILE] = HttpService:JSONEncode({ v = 1, locked = false, cfg = { Team = "Marines" } })
K = load(DEF)
check("settings in an UNLOCKED file: not used", K.on == false and CFG.Team == "Pirates")

-- ===== an executor that cannot write =====
CAN_WRITE = false
P.lockSet(true)
check("cannot write: said, NOT kept", string.find(K.note, "NOT kept", 1, true) ~= nil)
CAN_WRITE = true

-- ===== a broken file =====
FS[FILE] = "garbage"
K = load(DEF)
check("a broken file: ignored, defaults, no error", K.on == false and CFG.PvpRange == 300)

-- ===== plain (what a JSON file keeps) =====
local LK = K.LK
check("plain: numbers, strings, switches, nested", LK.plain(1) and LK.plain("a") and LK.plain(true)
    and LK.plain({ a = { b = { 1, 2 } } }))
check("plain: not a function, not NaN, not infinity", not LK.plain(function() end) and not LK.plain(0 / 0)
    and not LK.plain(math.huge))
check("plain: not a table mixing a list with names", not LK.plain({ 1, 2, a = 3 }))
check("same: deep", LK.same({ a = { 1, 2 } }, { a = { 1, 2 } }) and not LK.same({ a = { 1, 2 } }, { a = { 1 } }))

realPrint(string.format("%d checks, %d failed", count, fails))
if fails == 0 then realPrint("ALL PASS (lock)") end
