local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local MIX = { { name = "CDK" }, { name = "Godhuman" } }
local carried = { "Dragon Talon", "CDK", "Tiger" }

-- MIX: today's list, untouched
local l, missing = fightPick("MIX", carried, MIX)
check("MIX returns the mix list itself", l == MIX and missing == false)
l, missing = fightPick(nil, carried, MIX)
check("no value is MIX", l == MIX and missing == false)
l, missing = fightPick("", carried, MIX)
check("empty string is MIX", l == MIX and missing == false)

-- a carried name: only it, and no other decider can add to it
l, missing = fightPick("Dragon Talon", carried, MIX)
check("a carried name returns just it", #l == 1 and l[1] == "Dragon Talon" and missing == false)
check("a carried name is not the mix list", l ~= MIX)

-- a name not carried: the mix, flagged
l, missing = fightPick("Dragonstorm", carried, MIX)
check("a missing name falls back to the mix list", l == MIX)
check("a missing name is flagged", missing == true)
l, missing = fightPick("Tiger", {}, MIX)
check("nothing carried: the mix and the flag", l == MIX and missing == true)

-- a name is exact
l, missing = fightPick("tiger", carried, MIX)
check("names are exact", l == MIX and missing == true)

-- the mastery goal
check("goal: below the target", fightGoalDone(339, 500) == false)
check("goal: at the target", fightGoalDone(500, 500) == true)
check("goal: past the target", fightGoalDone(612, 500) == true)
check("goal: stop 0 = never", fightGoalDone(9999, 0) == false)
check("goal: mastery unreadable = not done", fightGoalDone(nil, 500) == false)

-- Home's and the Fights-with rows' words
check("label: one weapon", fightLabel("Dragon Talon") == "Dragon Talon only")
check("label: mix", fightLabel(nil) == "Mix")

-- ---------- the engine: P.weaponsFor, P.fightWeapon, the goal ----------
CARRIED["Dragon Talon"] = { Level = 339 }
CARRIED["CDK"] = { Level = 100 }
CARRIED["Tiger"] = { Level = 50 }
local w = wcfg("Dragon Talon")
w.Z, w.X = true, true

check("default config: MIX", P.weaponsFor() == "MIX" and P.fightWeapon() == nil)
check("an empty table costs no answer: MIX for a named mode", P.weaponsFor("seaevents") == "MIX")

CFG.FightWith.random = "Dragon Talon"
local one = P.weaponsFor()
check("random = Dragon Talon: only it", type(one) == "table" and #one == 1 and one[1].name == "Dragon Talon")
check("its M1 is on, its lit moves fire, the others do not",
    one[1].cfg.M1 == true and one[1].cfg.Z == true and one[1].cfg.X == true
    and one[1].cfg.C == false and one[1].cfg.V == false and one[1].cfg.F == false)
check("a mode keeps its own pick: seaevents is still MIX", P.weaponsFor("seaevents") == "MIX")
CFG.FightWith.seaevents = "Tiger"
check("seaevents = Tiger", P.fightWeapon("seaevents") == "Tiger" and P.fightWeapon("random") == "Dragon Talon")
MODE = "seaevents"
check("the mode running now decides (P.modeNow)", P.fightWeapon() == "Tiger")
MODE = "none"
check("no mode: MIX", P.weaponsFor() == "MIX")
MODE = "random"

-- not carried: the mix, said once
CFG.FightWith.random = "Dragonstorm"
check("not carried: MIX", P.weaponsFor() == "MIX")
P.weaponsFor() P.weaponsFor()
local said = 0
for _, s in ipairs(STATUS) do if string.find(s, "Dragonstorm is not carried", 1, true) then said += 1 end end
check("not carried: said once", said == 1, said)
check("quiet read says nothing and answers MIX", P.fightWeapon("random", true) == nil)

-- the goal: back to MIX at the target, goal off
CFG.FightWith.random = "Dragon Talon"
CFG.FightGoal.random = true
P.fightGoalTick()
check("goal below the target: still Dragon Talon", CFG.FightWith.random == "Dragon Talon" and CFG.FightGoal.random == true)
CARRIED["Dragon Talon"].Level = 500
P.fightGoalTick()
check("goal at the target: back to MIX", CFG.FightWith.random == nil and P.weaponsFor() == "MIX")
check("goal at the target: the goal is off", CFG.FightGoal.random == nil)
check("goal at the target: Tiger's mode is untouched", CFG.FightWith.seaevents == "Tiger")
CFG.FightWith.random = "Dragon Talon"
CFG.FightGoal.random = nil
P.fightGoalTick()
check("goal off: nothing happens at 500", CFG.FightWith.random == "Dragon Talon")
CFG.FightGoal.random = true
CFG.MasteryStop = 0
P.fightGoalTick()
check("stop 0 = never", CFG.FightWith.random == "Dragon Talon")

print(all and "ALL PASS" or "SOME FAILED")
