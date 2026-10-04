local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local R = P.rot

-- ---------------------------------------------------------------- EVERY WEAPON YOU CARRY
CARRY = { ["Dragon-Dragon"] = "Blox Fruit", ["Hallow Scythe"] = "Sword", ["Dragon Talon"] = "Melee", ["Kabucha"] = "Gun" }
local list = P.autoWeapons()
check("auto: every weapon you carry is in", #list == 4, #list)
check("auto: M1 with the SWORD (user: Hallow Scythe 3755 a swing, the fighting style far less)",
    P.m1Of(list).name == "Hallow Scythe", P.m1Of(list).name)
-- YOUR PICK (CFG.M1Weapon) beats everything.
CFG.M1Weapon = "Dragon Talon"
check("pick: the weapon you picked swings M1", P.m1Of(P.autoWeapons()).name == "Dragon Talon")
CFG.M1Weapon = "Soul Cane"
check("pick: one you do not carry - auto again (the sword)", P.m1Of(P.autoWeapons()).name == "Hallow Scythe")
CFG.M1Weapon = ""
-- The Attack page's own list (auto off): several with M1 on, the fighting
-- style listed first and switched on for you - the sword still swings.
local manual = {
    { name = "Dragon Talon", tool = tool("Dragon Talon", "Melee"), cfg = { M1 = true } },
    { name = "Dragon-Dragon", tool = tool("Dragon-Dragon", "Blox Fruit"), cfg = { M1 = true } },
    { name = "Hallow Scythe", tool = tool("Hallow Scythe", "Sword"), cfg = { M1 = true } },
}
check("manual: fighting style first in the list, the sword still swings (the bug)", P.m1Of(manual).name == "Hallow Scythe")
manual[3].cfg.M1 = false
check("manual: the sword's M1 off - the fighting style", P.m1Of(manual).name == "Dragon Talon")
CFG.M1Weapon = "Hallow Scythe"
check("manual: picked even with its own M1 switch off", P.m1Of(manual).name == "Hallow Scythe")
CFG.M1Weapon = ""
list = P.autoWeapons()
check("auto: the M1 sword is kept (never swapped by the rotation)", P.keepSword == "Hallow Scythe", P.keepSword)
check("auto: Z X C on, V off, F (flight) never", list[2].cfg.Z and list[2].cfg.X and list[2].cfg.C
    and not list[2].cfg.V and not list[2].cfg.F)
CFG.AutoKeys.V = true
check("auto: V on when you switch it on", P.autoWeapons()[1].cfg.V == true)
CFG.AutoKeys.V = false
CARRY = { ["Dragon Talon"] = "Melee", ["Kabucha"] = "Gun" }
check("auto: no sword - M1 with the fighting style", P.autoWeapons()[1].name == "Dragon Talon" and P.keepSword == nil)

-- ---------------------------------------------------------------- PICK NEXT (pure)
local inv = { { name = "Yama", type = "Sword" }, { name = "Tushita", type = "Sword" }, { name = "Kabucha", type = "Gun" },
    { name = "Bazooka", type = "Gun" }, { name = "Cutlass", type = "Sword" } }
local yes = function() return true end
local pick = R.pickNext(inv, { Kabucha = true }, {}, {}, {}, 100, yes)
check("pick: never loaded goes first, in inventory order", pick and pick.name == "Yama", pick and pick.name)
pick = R.pickNext(inv, { Kabucha = true }, { Yama = true }, {}, { Tushita = 90 }, 100, yes)
check("pick: one you switched off is never loaded; never-loaded before loaded", pick.name == "Bazooka", pick.name)
pick = R.pickNext(inv, {}, {}, {}, { Yama = 50, Tushita = 10, Kabucha = 80, Bazooka = 60, Cutlass = 70 }, 100, yes)
check("pick: the one loaded longest ago", pick.name == "Tushita", pick.name)
pick = R.pickNext(inv, {}, {}, { Yama = 200 }, {}, 100, function(n) return n ~= "Tushita" end)
check("pick: not one that failed lately, not one still cooling", pick.name == "Kabucha", pick.name)
check("pick: nothing fits = nil", R.pickNext(inv, {}, {}, {}, {}, 100, function() return false end) == nil)

-- rested: by our own cast clock.
cd["Yama"] = { Z = { lastCast = 95, learned = 10 } }
check("rested: a key cast 5 s ago with a 10 s cooldown = not rested", not R.rested("Yama", 100))
check("rested: 11 s later = rested", R.rested("Yama", 106))
cd["Yama"] = { Z = { lastCast = 95 } }
check("rested: cooldown unknown = 8 s", not R.rested("Yama", 102) and R.rested("Yama", 104))
cd = {}

-- ---------------------------------------------------------------- ROTATE (the game's LoadItem)
-- (what you carry is in the inventory list too, as in the game)
INV = { { Name = "Yama", Type = "Sword" }, { Name = "Tushita", Type = "Sword" }, { Name = "Bazooka", Type = "Gun" },
    { Name = "Leather", Type = "Material" }, { Name = "Hallow Scythe", Type = "Sword" }, { Name = "Kabucha", Type = "Gun" } }
CARRY = { ["Dragon Talon"] = "Melee", ["Hallow Scythe"] = "Sword", ["Kabucha"] = "Gun" }
P.keepSword = "Hallow Scythe"
check("rotate: the M1 sword kept - a GUN is loaded, never a sword over it", P.rotate(false) == true
    and LOADS[1] == "Bazooka" and CARRY["Hallow Scythe"] == "Sword", LOADS[1])
P.keepSword = nil
R.original, R.lastLoad, R.loadedAt = nil, -100, {}
LOADS = {}
CARRY = { ["Dragon Talon"] = "Melee", ["Hallow Scythe"] = "Sword", ["Kabucha"] = "Gun" }
T += 2
check("rotate: loads the next sword from your inventory", P.rotate(false) == true and LOADS[1] == "Yama"
    and CARRY.Yama == "Sword" and CARRY["Hallow Scythe"] == nil, LOADS[1])
check("rotate: what you carried is remembered", R.original and R.original.Sword == "Hallow Scythe" and R.original.Gun == "Kabucha")
check("rotate: not again within the gap", P.rotate(false) == false and #LOADS == 1)
T += 2
P.rotate(false)
check("rotate: then the next one, never a material", LOADS[2] == "Tushita", LOADS[2])
T += 2
LOAD_WORKS = false
check("rotate: one that does not come = false, left 2 min", P.rotate(false) == false and R.failUntil[LOADS[3]] ~= nil, LOADS[3])
LOAD_WORKS = true
CFG.AutoAttack = false
T += 2
check("rotate: off with the Attack page mode for the farm...", P.rotate(false) == false)
check("rotate: ...but the volcano still asks (any mode)", P.rotate(true) == true)
CFG.AutoAttack = true
CFG.InvSwap = false
T += 2
check("rotate: inventory switch off = never", P.rotate(true) == false)
CFG.InvSwap = true

-- ---------------------------------------------------------------- THE VENT GUN
R.original, R.lastLoad = nil, -100
INV = { { Name = "Bazooka", Type = "Gun" }, { Name = "Skull Guitar", Type = "Gun" }, { Name = "Yama", Type = "Sword" },
    { Name = "Hallow Scythe", Type = "Sword" }, { Name = "Kabucha", Type = "Gun" } }
R.inv = nil
CARRY = { ["Dragon Talon"] = "Melee", ["Hallow Scythe"] = "Sword", ["Kabucha"] = "Gun" }
check("invHas: the Skull Guitar is in your inventory", P.invHas("Skull Guitar") and not P.invHas("Soul Cane"))
check("loadItem: it comes into your hands (the gun slot)", P.loadItem("Skull Guitar") and CARRY["Skull Guitar"] == "Gun"
    and CARRY.Kabucha == nil)
check("loadItem: what you carried is remembered for the stop", R.original and R.original.Gun == "Kabucha")
P.keepGun = "Skull Guitar"
R.loadedAt, R.failUntil = {}, {}
T += 5
P.rotate(true)
check("keepGun: the rotation loads a SWORD, never a gun over the vent gun", CARRY["Skull Guitar"] == "Gun"
    and LOADS[#LOADS] == "Yama", LOADS[#LOADS])
P.keepGun = nil
R.original = nil
CARRY = { ["Dragon Talon"] = "Melee", ["Hallow Scythe"] = "Sword", ["Kabucha"] = "Gun" }
R.original = { Sword = "Hallow Scythe", Gun = "Kabucha" }
R.originalText = "Hallow Scythe, Kabucha"

-- ---------------------------------------------------------------- RESTORE
-- Swapped away from both by now (a sword and a gun from the inventory in hand).
CARRY = { ["Dragon Talon"] = "Melee", ["Yama"] = "Sword", ["Bazooka"] = "Gun" }
local before = #LOADS
P.rotRestore()
check("stop: your sword and gun put back", CARRY["Hallow Scythe"] == "Sword" and CARRY["Kabucha"] == "Gun"
    and CARRY.Yama == nil and CARRY.Bazooka == nil and #LOADS == before + 2, #LOADS - before)
check("stop: only once", (function() local n = #LOADS P.rotRestore() return #LOADS == n end)())

-- ---------------------------------------------------------------- LEARNED KEYS, KEPT
local c = P.learnClean({ ["Kabucha Z"] = { casts = 5, closed = 3 }, ["bad"] = { casts = 1, closed = 4 },
    ["Dragon Talon C"] = { casts = 6, closed = 0 }, ["junk"] = "x", [3] = { casts = 1, closed = 0 } })
check("saved keys: good rows back, impossible ones dropped", c["Kabucha Z"] and c["Kabucha Z"].closed == 3
    and c["Dragon Talon C"] and c["Dragon Talon C"].casts == 6 and c.bad == nil and c.junk == nil and c[3] == nil)
check("saved keys: not a table = nothing", next(P.learnClean("oops")) == nil)

print(all and "ALL PASS" or "SOME FAILED")
