
-- race_test.py part 2: the RACE section on a fake game, real code.
local fails = 0
-- (the stubs' print only records the script's console lines)
local function check(name, ok, got)
    if ok then REAL_PRINT("PASS " .. name)
    else
        fails += 1
        REAL_PRINT("FAIL " .. name .. (got ~= nil and ("   got: " .. tostring(got)) or ""))
    end
end
local R = P.race
local function tick(dt)
    clock += (dt or 0.1)
    R.tick()
    runDelays()
end
local function count(list, s)
    local n = 0
    for _, x in ipairs(list) do if x == s then n += 1 end end
    return n
end
local function printed(sub)
    for _, x in ipairs(PRINTS) do if string.find(x, sub, 1, true) then return true end end
    return false
end
local function clear() CALLS, PRINTS = {}, {} end
CFG.RaceV3 = false        -- V4 first, alone

-- ---------------------------------------------------------------- V4
energy.Value = 0.5
tick()
check("V4: half a meter - nothing sent", #CALLS == 0)
check("...the panel says it fires when full", string.find(R.text(), "V4  meter 50 %  ·  fires when it is full", 1, true) ~= nil, R.text())
energy.Value = 1
tick()
check("V4: the meter full - the game's own Y, once", count(CALLS, "event") == 1 and #CALLS == 1, table.concat(CALLS, ","))
tick()
check("...transformed: said on the console, the way kept", printed("[BFF] race: V4 on - the game's Y") and R.v4.way == "event")
check("...every weapon now (allNow)", R.allNow() == true)
check("...nothing more is sent while it lasts", #CALLS == 1)
CFG.RaceAll = false
check("'Every weapon while V4' off: not every weapon, though transformed", R.allNow() == false)
CFG.RaceAll = true
-- it ends; the game refuses its own Y now, the hubs' call works
transformed.Value = false
tick()
check("V4 over: said with its length", printed("[BFF] race: V4 over after"))
check("...and the attack is the Attack page's again", R.allNow() == false)
clear()
SERVER.eventOk = false
energy.Value = 1
tick()
check("V4 again: the way that worked first (the game's Y)", CALLS[1] == "event", CALLS[1])
tick(1.0)
check("...no transform: nothing else for 1.5 s", #CALLS == 1)
tick(0.6)
check("...then the Awakening tool's own call", CALLS[2] == "call true", CALLS[2])
tick()
check("...transformed: the call is the way now", printed("V4 on - the Awakening call") and R.v4.way == "call")
transformed.Value = false
tick()
clear()
energy.Value = 1
tick()
check("next time the call goes first", CALLS[1] == "call true", CALLS[1])
tick()
transformed.Value = false
tick()
-- both refused
clear()
SERVER.eventOk, SERVER.callOk = false, false
energy.Value = 1
R.v4.way = nil
tick()
tick(1.6)
tick(1.6)
check("both ways refused: Y, then the call, then it says so", CALLS[1] == "event" and CALLS[2] == "call true"
    and printed("V4 refused") and string.find(R.v4.note, "both ways tried", 1, true) ~= nil, table.concat(CALLS, ","))
local n0 = #CALLS
tick(1) tick(1)
check("...nothing for 3 s", #CALLS == n0)
tick(1.1)
check("...then tried again", #CALLS == n0 + 1)
SERVER.eventOk, SERVER.callOk = true, true
tick(1.6)
tick()
check("...and on when the server takes it", transformed.Value == true)
transformed.Value = false
energy.Value = 0
tick()
-- no Awakening tool / dead / switched off
clear()
backpack:remove("Awakening")
energy.Value = 1
tick()
check("no Awakening tool: nothing sent, the panel says V4 is not unlocked", #CALLS == 0
    and string.find(R.text(), "no Awakening tool", 1, true) ~= nil, R.text())
backpack:add(awakening)
hum.Health = 0
tick()
check("dead: nothing sent", #CALLS == 0)
hum.Health = 100
CFG.RaceV4 = false
tick()
check("switched off: nothing sent, 'V4 off'", #CALLS == 0 and string.find(R.text(), "V4 off", 1, true) ~= nil)
CFG.RaceV4 = true
tick()
check("on again: sent (the way that worked last - the call)", #CALLS == 1 and CALLS[1] == "call true", table.concat(CALLS, ","))
tick()
transformed.Value = false
energy.Value = 0
tick()
-- a transform of your own (your own Y) is seen too
clear()
transformed.Value = true
tick()
check("your own Y: seen ('V4 on - your own Y'), nothing sent", printed("V4 on - your own Y") and #CALLS == 0)
transformed.Value = false
tick()

-- ---------------------------------------------------------------- V3, the user's clock
CFG.RaceV4 = false
CFG.RaceV3 = true
clear()
tick()
check("V3: the ability tool carried - a T at once (CommE ActivateAbility)", count(CALLS, "CommE ActivateAbility") == 1, table.concat(CALLS, ","))
tick(0.2)
check("...not again before 0.5 s", count(CALLS, "CommE ActivateAbility") == 1)
tick(0.3)
check("...0.5 s later the next", count(CALLS, "CommE ActivateAbility") == 2)
-- the game plays YOUR roar (at a round time, for the countdown below)
clock = 1000
fx.OnClientEvent:Fire(0, { Name = "DracoRace.Roar" }, { player = player, Duration = 10, BuffType = 1, Characters = { char } })
check("your roar on Remotes.FX: V3 seen going on (said once)", printed("[BFF] race: V3 on (DracoRace.Roar)") and R.v3.ever)
clear()
for i = 1, 27 do clock = 1000 + i R.tick() runDelays() end
check("no T for the 28 s after it went on", count(CALLS, "CommE ActivateAbility") == 0)
check("...the panel counts down", string.find(R.text(), "V3 on 27 s ago (DracoRace.Roar)  ·  next T in 1 s", 1, true) ~= nil, R.text())
clock = 1027.9 R.tick()
check("...still none at 27.9 s", count(CALLS, "CommE ActivateAbility") == 0)
clock = 1028 R.tick()
check("at 28 s: T again", count(CALLS, "CommE ActivateAbility") == 1)
tick(0.5)
tick(0.5)
check("...every 0.5 s while it does not go on", count(CALLS, "CommE ActivateAbility") == 3)
-- an ALLY's roar buffing you is not yours
local ally = inst("ally", "Player")
fx.OnClientEvent:Fire(0, { Name = "DracoRace.Roar" }, { player = ally, Characters = { char } })
tick(0.5)
check("an ally's roar (you in its Characters): not your V3 - still pressing", count(CALLS, "CommE ActivateAbility") == 4)
-- the ability marker on your root (how the game marks Mink's Agility)
root:add(inst("Agility", "Folder"))
tick(0.5)
local presses = count(CALLS, "CommE ActivateAbility")
check("a child named after the ability on your root: V3 seen going on", printed("V3 on (Agility)"))
tick(1)
check("...and the 28 s start there", count(CALLS, "CommE ActivateAbility") == presses)
root:remove("Agility")
-- an ability TOOL put in your hand is not the ability on
local before = R.v3.seenAt
clock += 30
char:add(inst("Energy Core", "Tool", { ToolTip = "" }))
check("an ability TOOL equipped: not V3 going on", R.v3.seenAt == before)
char:remove("Energy Core")
-- the moon: no T of the script's
clear()
P.handsOff, P.moonTurn = true, clock
tick(0.1)
check("your turn at the moon: no T, and the panel says why", #CALLS == 0
    and string.find(R.text(), "your turn at the moon", 1, true) ~= nil, R.text())
P.moonTurn = clock - 3          -- the Mirage moved on 3 s ago
tick(0.1)
check("...the moon turn over: T again", count(CALLS, "CommE ActivateAbility") == 1)
P.handsOff, P.moonTurn = false, nil
-- dead / no tool / off
clear()
hum.Health = 0
tick(1)
check("dead: no T", #CALLS == 0)
hum.Health = 100
backpack:remove("Primordial Reign")
tick(1)
check("no race ability tool: no T, 'V3 not unlocked'", #CALLS == 0
    and string.find(R.text(), "V3 not unlocked", 1, true) ~= nil, R.text())
backpack:add(ability)
CFG.RaceV3 = false
tick(1)
check("switched off: no T, 'V3 off'", #CALLS == 0 and string.find(R.text(), "V3 off", 1, true) ~= nil)
CFG.RaceV3 = true

-- ---------------------------------------------------------------- the probe file
check("the probe file written (the T's after a wait)", FILES["bff_race_probe.txt"] ~= nil
    and string.find(FILES["bff_race_probe.txt"], "[v3 #1] the T's after a wait", 1, true) ~= nil, FILES["bff_race_probe.txt"])
check("...V4 going on probed too", string.find(FILES["bff_race_probe.txt"] or "", "[v4 #1] V4 went on", 1, true) ~= nil)
-- what a probe sees: a child, an attribute, an effect of yours
local n = R.probes.v3 or 0
R.probes.v3 = 0
R.v3.anchor, R.v3.lastPress, R.v3.probed = nil, nil, false
tick(0.1)
root:add(inst("PrimordialBuff", "Folder"))
char:SetAttribute("DOT_ArrowBuff", true)
fx.OnClientEvent:Fire(0, { Name = "DracoRace.Roar" }, { player = player })
clock += 4
runDelays()
local file = FILES["bff_race_probe.txt"] or ""
check("the probe line: the child, the attribute, your effect", string.find(file, "root + PrimordialBuff (Folder)", 1, true)
    and string.find(file, "character attribute DOT_ArrowBuff = true", 1, true)
    and string.find(file, "effect DracoRace.Roar (YOURS)", 1, true), file)
R.probes.v3 = n

-- ---------------------------------------------------------------- V4's weapons, the panel line
backpack:add(inst("Dragon Talon", "Tool", { ToolTip = "Melee" }))
backpack:add(inst("Kitsune-Kitsune", "Tool", { ToolTip = "Blox Fruit" }))
backpack:add(inst("Cursed Dual Katana", "Tool", { ToolTip = "Sword" }))
local w = R.weapons()
local names = {}
for _, u in ipairs(w) do table.insert(names, u.name) end
check("V4's weapons: the real ones, sword first (the Awakening and the ability left out)",
    table.concat(names, ",") == "Cursed Dual Katana,Dragon Talon,Kitsune-Kitsune", table.concat(names, ","))
P.seaev = { transformFruit = function(nm) return nm == "Kitsune-Kitsune" end,
    unlocked = function(_, k) return k ~= "F" end,
    formOf = function() return nil end }
w = R.weapons()
check("...a transformation fruit's V never, a key not unlocked never", w[3].cfg.V == false and w[2].cfg.V == true
    and w[1].cfg.F == false and w[1].cfg.Z == true)
P.seaev.formOf = function() return "Kitsune" end
w = R.weapons()
check("...in the fox form: only the fruit", #w == 1 and w[1].name == "Kitsune-Kitsune")
P.seaev = nil
transformed.Value = true
tick()
check("the panel while V4 is on: ON, the meter, every weapon named", string.find(R.text(), "V4 ON", 1, true)
    and string.find(R.text(), "every weapon: Cursed Dual Katana, Dragon Talon, Kitsune-Kitsune", 1, true), R.text())
transformed.Value = false
tick()
-- M1s in turn through R (RaceM1Burst)
CFG.RaceM1Burst = 2
local used = R.weapons()
local seq = {}
for _ = 1, 6 do
    local u = R.m1Turn(used, nil)
    table.insert(seq, u.name)
    R.m1Swung()
end
check("M1 in turn through the switches' burst (2)", table.concat(seq, ",")
    == "Cursed Dual Katana,Cursed Dual Katana,Dragon Talon,Dragon Talon,Kitsune-Kitsune,Kitsune-Kitsune", table.concat(seq, ","))
R.m1Turn(used, nil)
R.m1Skip()
check("...a weapon whose M1 lands nowhere: the next one at once", R.m1Turn(used, nil).name == "Dragon Talon")

-- ---------------------------------------------------------------- a new character, unhook
local oldRoot = root
newChar()
tick()
check("a new character: watched (its root's children)", root.ChildAdded:live() == 1 and oldRoot.ChildAdded:live() == 0)
R.unhook()
check("unhook: nothing left connected", root.ChildAdded:live() == 0 and char.ChildAdded:live() == 0
    and fx.OnClientEvent:live() == 0)

REAL_PRINT(fails == 0 and "ALL PASS (live)" or (fails .. " FAILED (live)"))
