
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local G = P.gun
P.silentTick = function() ev("silent in") end
local function logged() local s = table.concat(LOG, " | ") table.clear(LOG) return s end

-- ---------------------------------------------------------------- what a gun is
local DS = tool("Dragonstorm")
local gi = P.gunInfo(DS)
check("Dragonstorm: fires while held, heat 3, range 400 (the game's WeaponData)",
    gi and gi.gatling and gi.limit == 3 and gi.range == 400 and not gi.custom)
check("Skull Guitar: a way of its own (never the game's shot)", P.gunInfo(tool("Skull Guitar")).custom == true)
local DF = P.gunInfo(tool("Dual Flintlock"))
check("a name with a space: found as the game spells it (DualFlintlock)", DF and DF.range == 200 and not DF.gatling)
check("a sword is not a gun", P.gunInfo(tool("Yama", "Sword")) == nil)
local saved = WEAPONDATA.Dragonstorm
WEAPONDATA.Dragonstorm = nil
check("Dragonstorm missing from the game's table: still held, by its name", P.gunInfo(DS).gatling == true)
WEAPONDATA.Dragonstorm = saved

-- ---------------------------------------------------------------- the one enemy
local pick = G.pickFocus
local a, b, c = enemy("A", 500), enemy("B", 200), enemy("C", 900)
local from = v3(0, 20, 0)
check("the weakest first (a kill sooner)", pick({ a, b, c }, nil, from, 400) == b.root)
check("the one being shot is kept while it lives, a weaker newcomer or not",
    pick({ a, b, c }, c.root, from, 400) == c.root)
c.hum.Health = 0
check("...it died: the weakest of the rest", pick({ a, b, c }, c.root, from, 400) == b.root)
c.hum.Health = 900
local far = enemy("Far", 1, v3(0, 0, 900))
check("out of the gun's reach: never the target", pick({ a, far }, nil, from, 400) == a.root)
check("...and the one being shot, gone out of reach, is dropped", pick({ a, far }, far.root, from, 400) == a.root)
b.model.Parent = nil
check("a removed model is skipped", pick({ a, b }, nil, from, 400) == a.root)
b.model.Parent = true
check("nobody: nil", pick({}, nil, from, 400) == nil and pick({ a }, nil, nil, 400) == nil)

-- ---------------------------------------------------------------- the button
local step = G.holdStep
check("free gun, cool: press", step(false, false, false, 0, 3, 0) == "press")
check("locked (overheated): wait", step(false, false, true, 2.9, 3, 0) == "wait")
check("hot to the limit: wait (the game would refuse the press)", step(false, false, false, 2.97, 3, 0) == "wait")
check("after the lockout (heat 2): press - 1 s more of fire", step(false, false, false, 2, 3, 0) == "press")
check("held and its loop firing: keep", step(true, true, false, 1, 3, 2) == "keep")
check("held, loop not started yet (0.2 s): keep - give it its frame", step(true, false, false, 0, 3, 0.2) == "keep")
check("held, the loop ended (heat / a skill / a stun): let go", step(true, false, true, 3, 3, 3) == "release")

-- ---------------------------------------------------------------- held, through a whole heat cycle
TOOLS.Dragonstorm = DS
HELD = DS
local e1, e2 = enemy("Reef Bandit", 800), enemy("Reef Bandit", 300)
pile = { e1, e2 }
clock = 100
table.clear(LOG)
check("tick 1: it can fire - pressed", P.gunHoldTick(DS) == true and logged() == "silent in | down")
check("...every shot at ONE enemy, the weakest", P.gunFocus == e2.root)
check("...the silent aim held through the next shots (not only the press)", aimUntil >= clock + 0.4, aimUntil - clock)
DS.attrs.IsAutoShooting = true
clock += 0.3 DS.attrs.LocalOverheat = 0.3
P.gunHoldTick(DS)
check("firing: kept held, no new press", logged() == "silent in")
clock += 2.7 DS.attrs.LocalOverheat = 3
DS.attrs.IsAutoShooting = nil
DS.Enabled = false
P.gunHoldTick(DS)
check("overheated, its loop over: let go", logged() == "silent in | up")
check("...counted once", G.locks == 1, G.locks)
clock += 0.5 DS.attrs.LocalOverheat = 2.5
P.gunHoldTick(DS)
check("locked: no press", logged() == "silent in")
clock += 0.5 DS.attrs.LocalOverheat = 2
DS.Enabled = true
P.gunHoldTick(DS)
check("lock over (heat 2): pressed again", logged() == "silent in | down")
check("...locks still counted once", G.locks == 1, G.locks)
clock += 0.1
P.gunHoldTick(DS)
check("press not answered yet (0.1 s): kept", logged() == "silent in")
clock += 0.4
P.gunHoldTick(DS)
check("press never answered (0.5 s): let go, tried again next tick", logged() == "silent in | up")
P.gunHoldTick(DS)
check("...and pressed again", logged() == "silent in | down")
e2.hum.Health = 0
DS.attrs.IsAutoShooting = true
clock += 0.1
P.gunHoldTick(DS)
check("its enemy died: the next one, button still held", P.gunFocus == e1.root and logged() == "silent in")
local other = tool("Dragonheart", "Sword")
HELD = other
P.gunRelease()
logged()
P.gunHoldTick(DS)
check("another weapon in hand: never pressed (that click would be its)", logged() == "silent in")
HELD = DS
DS.attrs.IsAutoShooting = nil
pile = {}
P.gunHoldTick(DS)
P.gunHoldTick(DS)
check("nobody in reach: nothing pressed, the note says so",
    logged() == "" and P.gunNote:find("nobody in reach", 1, true) ~= nil, P.gunNote)

-- shots a second, off the game's own count
pile = { e1 }
DS.attrs.LocalTotalShots = 0
clock += 5
P.gunHoldTick(DS)
clock += 1 DS.attrs.LocalTotalShots = 12
P.gunHoldTick(DS)
check("shots a second off LocalTotalShots", math.abs(G.rate - 12) < 0.01, G.rate)
logged()

-- ---------------------------------------------------------------- the watchdog (every frame)
DS.attrs.IsAutoShooting = true
P.gunRelease() logged()
P.gunHoldTick(DS)
logged()
attacking = false
P.gunWatch()
check("the fight stopped calling (attacking off): let go", logged() == "up")
attacking = true
P.gunHoldTick(DS) logged()
clock += 0.5
P.gunWatch()
check("no gun tick for 0.5 s (a death, a skill, the pile done): let go, the aim off",
    logged() == "up" and P.gunFocus == nil)
P.gunHoldTick(DS) logged()
HELD = other
P.gunWatch()
check("a weapon swap: let go", logged() == "up")
HELD = DS
P.gunHoldTick(DS) logged()
P.running = false
P.gunWatch()
check("the farm stopped: let go", logged() == "up")
P.running = true
P.gunWatch()
check("let go once only (no stray up events)", logged() == "")

-- ---------------------------------------------------------------- the game's own shot
clock = 500
check("no getupvalues: not found, says why", P.gunShotFn() == nil
    and P.gunShotWhy == "this executor has no getupvalues", P.gunShotWhy)
debug.getupvalues = function(f) return UPS[f] or {} end
clock += 5
check("looked again only after 10 s (not every tick)", P.gunShotFn() == nil)
clock += 6
check("found: the upvalue that holds the mouse and the validator's numbers - not attackMelee",
    P.gunShotFn() == shootGun, P.gunShotWhy)
pile = { e1 }
clock += 10
table.clear(SHOTS)
P.gunShotTick(DS)
check("past the heat: 4 shots at most a tick", #SHOTS == 4, #SHOTS)
check("...each with a mouse click as its input, run as the game's own (silent aim answers)",
    SHOTS[1].input == "MouseButton1" and SHOTS[1].inGame == true and SHOTS[4].inGame == true)
check("...and the script's own reads see the real mouse again after", P.inGameShot == false)
clock += 0.17
P.gunShotTick(DS)
check("0.17 s later at 0.08 s a shot: 2 more", #SHOTS == 6, #SHOTS)
clock += 0.05
P.gunShotTick(DS)
check("0.05 s later: none yet", #SHOTS == 6, #SHOTS)
check("every shot at the one enemy", P.gunFocus == e1.root)
pile = {}
clock += 1
P.gunShotTick(DS)
check("nobody in reach: no shot", #SHOTS == 6, #SHOTS)

-- ---------------------------------------------------------------- the mastery farm
P.stop = function() ev("STOP") P.running = false end
local loads = 0
P.invHas = function(n) return n == "Dragonstorm" end
P.loadItem = function(n) loads += 1 TOOLS[n] = DS return true end
CFG.MasteryWeapon = ""
check("off: usedWeapons is not touched", P.masteryUsed() == nil)
P.masteryTick()
check("off: says off", P.masteryNote == "off")
CFG.MasteryWeapon = "Dragonstorm"
TOOLS.Dragonstorm = nil
check("on, not carried: no weapon at all (another would share the kills)", #P.masteryUsed() == 0)
clock = 1000
P.loadItem = function(n) loads += 1 return false end
P.masteryTick()
check("not carried, in your inventory: loaded", loads == 1 and P.masteryNote:find("loading", 1, true) ~= nil, P.masteryNote)
clock += 3
P.masteryTick()
check("...not hammered: once per 10 s", loads == 1, loads)
clock += 8
P.masteryTick()
check("...10 s later, tried again", loads == 2, loads)
P.invHas = function() return false end
clock += 11
P.masteryTick()
check("not in your inventory either: said", P.masteryNote:find("not in your inventory", 1, true) ~= nil, P.masteryNote)
TOOLS.Dragonstorm = DS
DS.kids.Level = { Value = 312 }
local used = P.masteryUsed()
local u = used[1]
check("carried: that weapon alone, M1 on", #used == 1 and u.name == "Dragonstorm" and u.tool == DS and u.cfg.M1 and u.cfg.use)
check("...its keys as \"Every weapon you carry\" says (Z X C on, V off, F never)",
    u.cfg.Z and u.cfg.X and u.cfg.C and not u.cfg.V and not u.cfg.F)
logged()
P.masteryTick()
check("mastery read off the tool's Level, the stop shown", P.masteryNote == "Dragonstorm  mastery 312  ·  stops at 500"
    and logged() == "", P.masteryNote)
DS.kids.Level = nil
P.rot = { inv = { { name = "Dragonstorm", type = "Gun", mastery = 420 } } }
P.masteryTick()
check("no Level on the tool: your inventory's number", P.masteryNote:find("mastery 420", 1, true) ~= nil, P.masteryNote)
DS.kids.Level = { Value = 500 }
P.masteryTick()
local got = logged()
check("500 reached: the farm stops, said, notified", got:find("STOP", 1, true) ~= nil
    and got:find("notify Dragonstorm reached 500 mastery", 1, true) ~= nil and P.running == false, got)
P.masteryTick()
check("...stopped once only", logged() == "")
P.running = true
CFG.MasteryStop = 0
DS.kids.Level = { Value = 600 }
P.masteryTick()
check("stop at 0: never stops", P.running == true and logged() == "" and P.masteryNote:find("stops at", 1, true) == nil,
    P.masteryNote)

print(all and "ALL PASS" or "SOME FAILED")
