-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
local function vnear(a, b, eps)
    return a and b and near(a.X, b.X, eps or 0.01) and near(a.Y, b.Y, eps or 0.01) and near(a.Z, b.Z, eps or 0.01)
end
local function vs(v) return v and string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) or "nil" end
local function horiz(a, b) return vec(a.X - b.X, 0, a.Z - b.Z).Magnitude end

-- A count saved by an earlier session: loaded when the hunt is built.
FILES["bff_sea_events.json"] = HS:JSONEncode({ total = 7, kinds = { ["Sea Beast"] = 7 }, since = 5, log = { "12:00 Sea Beast" },
    learn = { ["Kitsune-Kitsune C"] = { casts = 3, closed = 2 }, bad = { casts = 1, closed = 5 } } })
SECTION()
useFiles()
local SE = P.seaev
local SEA_CAST = SE.caster        -- the real one (its own cases below)
SE.caster = CASTER                -- the fights' cases: a recorder
local T = SE._t
check("load: the count kept from the last session (7) and its kinds", SE.count.total == 7 and SE.count.kinds["Sea Beast"] == 7,
    SE.count.total)
check("load: the learned keys kept, a bad row dropped", SE.learn["Kitsune-Kitsune C"] and SE.learn["Kitsune-Kitsune C"].closed == 2
    and SE.learn.bad == nil)
check("the wheel's hook is the hunt's steering", S.steerFn == SE.steer)

-- ---------------------------------------------------------------- ARITHMETIC
local a, b = T.parseHP("12,500/100,000")
check("HP text: \"12,500/100,000\" = 12500 of 100000", a == 12500 and b == 100000, tostring(a) .. " " .. tostring(b))
a, b = T.parseHP(" 99 / 175 000 ")
check("HP text: spaces are no trouble", a == 99 and b == 175000, tostring(a) .. " " .. tostring(b))
check("HP text: not one - nil", T.parseHP("Sea Beast") == nil and T.parseHP(nil) == nil)
check("names: Terrorshark (and an anchored one) - not a Shark",
    T.kindOf("Terrorshark") == "Terrorshark" and T.kindOf("Anchored Terrorshark") == "Terrorshark")
check("names: Piranha, Shark", T.kindOf("Piranha") == "Piranha" and T.kindOf("Shark") == "Shark")
check("names: every ship raid is a ship - brigades, the Fish Boat, its crew",
    T.kindOf("PirateBrigade") == "ship" and T.kindOf("PirateGrandBrigade") == "ship" and T.kindOf("FishBoat") == "ship"
    and T.kindOf("Fish Crew Member") == "ship" and T.kindOf("Haunted Crew") == "ship")
check("names: anything else is nothing to this hunt", T.kindOf("Forest Pirate") == nil and T.kindOf("Sharkman") == nil)
check("Rumbling Waters = three beasts or more", T.beastKind(1) == "Sea Beast" and T.beastKind(2) == "Sea Beast"
    and T.beastKind(3) == "Rumbling Waters")
do
    local gs = {}
    local g1 = T.joinGroup(gs, "beast", 100)
    local g2 = T.joinGroup(gs, "beast", 115)
    local g3 = T.joinGroup(gs, "Piranha", 115)
    check("groups: a second beast 15 s later joins the first; a piranha is its own", g1 == g2 and g3 ~= g1 and #gs == 2)
    local g4 = T.joinGroup(gs, "beast", 140)
    check("groups: 25 s after the last one seen - a new event", g4 ~= g1 and #gs == 3)
    g4.closed = true
    check("groups: a closed one is never joined", T.joinGroup(gs, "beast", 141) ~= g4)
end
check("verdict: HP read 0 = killed", T.verdict(true, false, nil) == "killed")
check("verdict: gone at 8% = killed (it sinks on death)", T.verdict(false, true, 0.08) == "killed")
check("verdict: gone at 50% = lost; HP never read = lost", T.verdict(false, true, 0.5) == "lost" and T.verdict(false, true, nil) == "lost")
check("verdict: still there = alive", T.verdict(false, false, 0.5) == nil)
do
    local g = { killed = 0, lastSeen = 100 }
    check("a group with one alive: on (and seen now)", T.groupOver(g, 1, 130) == nil and g.lastSeen == 130)
    check("a group just emptied: on for 5 s more", T.groupOver(g, 0, 133) == nil)
    check("a group empty 5 s, nothing killed: lost", T.groupOver(g, 0, 136) == "lost")
    g.killed = 1
    check("a group empty 5 s, one killed: counted", T.groupOver(g, 0, 136) == "count")
end
do
    local c = vec(0, 0, 0)
    local d, s = T.patrolDir(vec(3000, 5, 0), c, 400, 60, 300)
    check("patrol: far off the circle - straight at it, full speed", vnear(d, vec(-1, 0, 0)) and s == 300, vs(d))
    d, s = T.patrolDir(vec(400, 5, 0), c, 400, 60, 300)
    check("patrol: on the circle - round it, slow", near(d:Dot(vec(1, 0, 0)), 0, 1e-6) and near(d.Magnitude, 1) and s == 60, vs(d))
    d = T.patrolDir(vec(100, 5, 0), c, 400, 60, 300)
    check("patrol: inside - out toward the edge as it goes round", d.X > 0, vs(d))
    d = T.patrolDir(vec(700, 5, 0), c, 400, 60, 300)
    check("patrol: outside - in toward the edge", d.X < 0, vs(d))
end
check("away: straight away from the ship, flat", vnear(T.fleeDir(vec(0, 5, 0), vec(0, 40, 100)), vec(0, 0, -1)))
check("the wheel: a threat inside 1,500 = away; 1,700 while away = still away; a ship at 2,000 = stopped",
    T.wheelMode(1000, "ship", false, 1500) == "flee" and T.wheelMode(1700, "ship", true, 1500) == "flee"
    and T.wheelMode(1700, "ship", false, 1500) == "hold" and T.wheelMode(2000, "ship", true, 1500) == "hold")
check("the wheel: a switched-off Terrorshark past 1,500 = the patrol; nothing = the patrol",
    T.wheelMode(1700, "Terrorshark", false, 1500) == "patrol" and T.wheelMode(nil, nil, false, 1500) == "patrol")
check("compass: too low = out, too high = in, right = stays, unread = stays",
    T.nudge(0, 4, 5) == 1 and T.nudge(0, 6, 5) == -1 and T.nudge(2, 5, 5) == 2 and T.nudge(1, nil, 5) == 1)
check("compass: never more than 4 steps", T.nudge(4, 1, 5) == 4 and T.nudge(-4, 6, 5) == -4)
check("the circle for danger 6 = the zone point", vnear(T.centreOf(6, 0), T.ZONES[6]))
check("one step out = 1,500 studs farther from Tiki", near(horiz(T.centreOf(5, 1), TIKI) - horiz(T.ZONES[5], TIKI), 1500, 0.01))
check("the Spy: 1 = cooldown, 2-4 = takes fragments, 5 = out there",
    string.find(T.spyText(1), "cooldown", 1, true) ~= nil and string.find(T.spyText(3), "fragments", 1, true) ~= nil
    and string.find(T.spyText(5), "out there", 1, true) ~= nil)

-- ---------------------------------------------------------------- THE WORLD
local Z5 = T.ZONES[5]
local function reset()
    FLIGHTS, LOCKS, SAYS, STATES, CASTS, FIGHTS, CALLS, SET_HUNT, PRINTED = {}, {}, {}, {}, {}, {}, {}, {}, {}
    STOPPED = 0
end
local function clearWorld()
    SEABEASTS.kids, ENEMIES.kids = {}, {}
    SE.members, SE.groups, SE.cur, SE.mode = {}, {}, nil, "-"
end
local function commas(n)
    local s = tostring(math.floor(n))
    while true do
        local k
        s, k = string.gsub(s, "^(%d+)(%d%d%d)", "%1,%2")
        if k == 0 then return s end
    end
end
local function beast(name, pos, hp, max, how)
    local m = inst(name, "Model")
    m:add(inst("HumanoidRootPart", "Part", { Position = pos, Size = vec(10, 10, 10), CanCollide = true, Transparency = 0 }))
    if how == "bbg" then
        local g = m:add(inst("HealthBBG", "BillboardGui"))
        local fr = g:add(inst("Frame", "Frame"))
        fr:add(inst("TextLabel", "TextLabel", { Text = commas(hp) .. "/" .. commas(max) }))
    elseif how == "attr" then
        m.attrs.Health, m.attrs.MaxHealth = hp, max
    else
        m:add(inst("Health", "NumberValue", { Value = hp }))
        m:add(inst("MaxHealth", "NumberValue", { Value = max }))
    end
    SEABEASTS:add(m)
    return m
end
local function gone(m)
    m.Parent.kids[m.key] = nil
    m.Parent = nil
end
local function fish(name, pos, hp)
    local m = inst(name, "Model", { Position = pos })
    m.hum = { Health = hp or 100 }
    m:add(inst("HumanoidRootPart", "Part", { Position = pos }))
    ENEMIES:add(m)
    return m
end
local function count() return SE.count.total end
-- A scan now, and again DONE_WAIT later.
local function settle()
    T.scan(CLOCK)
    CLOCK += 6
    return T.scan(CLOCK)
end

BOAT = makeBoat(Z5 + vec(0, 5, 0))
ROOT.Position = Z5 + vec(0, 10, 0)
SE.reset()
check("reset: the count is 0 and saved", count() == 0 and saved() and saved().total == 0)

-- ---------------------------------------------------------------- A SEA BEAST
reset()
local sb = beast("SeaBeast1", Z5 + vec(300, -10, 0), 100000, 100000)
local fights, threats = T.scan(CLOCK)
check("a beast near the boat: one to fight, named Sea Beast", #fights == 1 and fights[1].label == "Sea Beast"
    and fights[1].fight == true and #threats == 0, #fights)
check("the first beast: its HP source written to bff_beast_probe.txt", printed("its Health value")
    and FILES["bff_beast_probe.txt"] and string.find(FILES["bff_beast_probe.txt"], "its Health value", 1, true) ~= nil)
sb.kids.Health.Value = 0
settle()
check("the beast's HP read 0, all quiet 5 s: ONE Sea Beast counted, saved", count() == 1 and SE.count.kinds["Sea Beast"] == 1
    and saved().total == 1, count())
runSpawned()
check("a count asks the Spy - InfoLeviathan \"1\" (read only)", #CALLS >= 1 and CALLS[#CALLS][1] == "InfoLeviathan"
    and CALLS[#CALLS][2] == "1")
check("the dead one is not counted twice", (function() settle() return count() == 1 end)())

-- Vanished at 8%: it sank as it died.
reset()
clearWorld()
local sb2 = beast("SeaBeast2", Z5 + vec(200, 0, 0), 8000, 100000)
T.scan(CLOCK)
gone(sb2)
settle()
check("a beast gone at 8%: killed (it sinks the moment it dies) - counted", count() == 2, count())
-- Despawned at half: not a kill.
reset()
clearWorld()
local sb3 = beast("SeaBeast3", Z5 + vec(200, 0, 0), 50000, 100000)
T.scan(CLOCK)
gone(sb3)
settle()
check("a beast gone at 50%: lost, NOT counted", count() == 2 and printed("not counted"), count())

-- ---------------------------------------------------------------- RUMBLING WATERS
reset()
clearWorld()
local r1 = beast("SeaBeast1", Z5 + vec(300, 0, 0), 100000, 100000)
local r2 = beast("SeaBeast2", Z5 + vec(-300, 0, 0), 100000, 100000, "bbg")
local r3 = beast("SeaBeast3", Z5 + vec(0, 0, 300), 100000, 100000, "attr")
fights = T.scan(CLOCK)
local labels = 0
for _, x in ipairs(fights) do if x.label == "Rumbling Waters" then labels += 1 end end
check("three beasts at once: Rumbling Waters, all three to fight", #fights == 3 and labels == 3, #fights .. " " .. labels)
local hp2, max2, src2 = T.beastHP(r2)
check("HP from the HealthBBG text", hp2 == 100000 and max2 == 100000 and src2 == "its HealthBBG text", tostring(src2))
local hp3, _, src3 = T.beastHP(r3)
check("HP from the attribute", hp3 == 100000 and src3 == "its Health attribute", tostring(src3))
r1.kids.Health.Value = 0
CLOCK += 30
T.scan(CLOCK)
check("one of the three down: nothing counted yet", count() == 2, count())
gone(r2)                                    -- at 100% - sank? no: lost
r3.attrs.Health = 0
settle()
check("all three over, one killed: Rumbling Waters counted ONCE", count() == 3 and SE.count.kinds["Rumbling Waters"] == 1, count())
-- Rumbling Waters switched off: sailed away from.
reset()
clearWorld()
CFG.SeaEvFight["Rumbling Waters"] = false
beast("SeaBeast1", Z5 + vec(300, 0, 0), 1, 1)
beast("SeaBeast2", Z5 + vec(-300, 0, 0), 1, 1)
beast("SeaBeast3", Z5 + vec(0, 0, 300), 1, 1)
fights, threats = T.scan(CLOCK)
check("Rumbling Waters off: the three are to be sailed away from, not fought", #fights == 0 and #threats == 3)
CFG.SeaEvFight["Rumbling Waters"] = true

-- ---------------------------------------------------------------- FISH AND SHIPS
reset()
clearWorld()
local school = {}
for i = 1, 5 do school[i] = fish("Piranha [Lv. 1800]", Z5 + vec(i * 20, 0, 50), 500) end
fights = T.scan(CLOCK)
check("five piranhas: five to fight, one event", #fights == 5 and #SE.groups == 1, #fights)
for i = 1, 5 do school[i].hum.Health = 0 end
settle()
check("the school killed: ONE Piranha event counted (the wiki)", count() == 4 and SE.count.kinds.Piranha == 1, count())
reset()
local ts = fish("Terrorshark", Z5 + vec(100, 0, 0), 150000)
T.scan(CLOCK)
ts.hum.Health = 0
settle()
check("a Terrorshark killed: counted", count() == 5 and SE.count.kinds.Terrorshark == 1, count())
local ts2 = fish("Terrorshark", Z5 + vec(120, 0, 0), 150000)
T.scan(CLOCK)
ts2.hum.Health = 0
settle()
check("another Terrorshark after that one was over: counted too", count() == 6, count())
reset()
clearWorld()
fish("Shark", Z5 + vec(80, 0, 0), 300)
local brig = inst("PirateBrigade", "Model", { Position = Z5 + vec(900, 0, 0) })
ENEMIES:add(brig)
fish("Fish Crew Member [Lv. 2000]", Z5 + vec(850, 0, 0), 4000)
fights, threats = T.scan(CLOCK)
local ships, sharks = 0, 0
for _, t in ipairs(threats) do
    if t.kind == "ship" then ships += 1 end
    if t.kind == "Shark" then sharks += 1 end
end
check("a ship raid (the brigade, its crew): to be sailed away from; never fought", #fights == 0 and ships == 2, ships)
check("a Shark with its switch off: sailed away from", sharks == 1)
reset()
ENEMIES:add(inst("Kraken Thing", "Model", { Position = Z5 + vec(50, 0, 0) }))
SEABEASTS:add(inst("Leviathan", "Model", { Position = Z5 + vec(60, 0, 0) }))
fights = T.scan(CLOCK)
T.scan(CLOCK)
local said = 0
for _, s in ipairs(PRINTED) do if string.find(s, "Kraken Thing", 1, true) then said += 1 end end
check("an unknown name near the boat: said once, left alone", said == 1 and #fights == 0, said)
check("the Leviathan: never fought (user: no Leviathan code)", printed("Leviathan") and #fights == 0)
clearWorld()
beast("SeaBeast9", Z5 + vec(6000, 0, 0), 100, 100)
fights = T.scan(CLOCK)
check("a beast 6,000 studs off: not this hunt's", #fights == 0)

-- ---------------------------------------------------------------- THE STEP: THE WHEEL
clearWorld()
reset()
SEA = 2
SE.step(epoch)
check("Second Sea: the hunt goes off", SET_HUNT[1] == false and CFG.Hunt == false)
SEA, CFG.Hunt = 3, true
reset()
HUM.SeatPart, S.driving = nil, false
BOAT.pivot = cf(Z5 + vec(-3000, 5, 0), math.pi / 2)
BOAT.seat.Position = Z5 + vec(-3000, 5, 0)
ROOT.Position = Z5 + vec(-3000, 20, 0)
P.running = true
SE.step(epoch)
check("nothing near: at the wheel (sat, driving), patrolling danger 5", SITS >= 1 and S.driving == true and SE.mode == "patrol"
    and vnear(SE.centre, Z5), SE.mode .. " " .. vs(SE.centre))
local st = SE.steer(BOAT.pivot.Position, vec(-1, 0, 0))
check("3,000 studs off the circle: the wheel goes straight at it, at SeaSpeed",
    st and vnear(st.dir, vec(1, 0, 0)) and st.speed == 300, st and vs(st.dir))
st = SE.steer(Z5 + vec(400, 5, 0), vec(-1, 0, 0))
check("on the circle: round it at 60", st and st.speed == 60 and near(st.dir.X, 0, 1e-6), st and vs(st.dir))
CFG.Hunt = false
check("the hunt off: the hook gives the wheel back (nil)", SE.steer(Z5, vec(-1, 0, 0)) == nil)
CFG.Hunt = true
-- A ship raid comes: away from it.
reset()
BOAT.pivot = cf(Z5 + vec(400, 5, 0), math.pi / 2)
local ship = inst("PirateGrandBrigade", "Model", { Position = Z5 + vec(1200, 0, 0) })
ENEMIES:add(ship)
SE.step(epoch)
st = SE.steer(BOAT.pivot.Position, vec(-1, 0, 0))
check("a ship raid 800 studs off: sailing AWAY from it, at SeaSpeed", SE.mode == "flee" and st and vnear(st.dir, vec(-1, 0, 0))
    and st.speed == 300 and SE.flees == 1, SE.mode)
BOAT.pivot = cf(Z5 + vec(-500, 5, 0), math.pi / 2)        -- 1,700 off: still inside 1,500 + 300
SE.step(epoch)
check("1,700 studs off (past 1,500, inside the margin): still away", SE.mode == "flee" and SE.flees == 1)
BOAT.pivot = cf(Z5 + vec(-900, 5, 0), math.pi / 2)        -- 2,100 off
SE.step(epoch)
st = SE.steer(BOAT.pivot.Position, vec(-1, 0, 0))
check("2,100 studs off: stopped out of its way (the circle would lead back into it)", SE.mode == "hold"
    and st and st.speed == 0, SE.mode)
BOAT.pivot = cf(Z5 + vec(-2000, 5, 0), math.pi / 2)       -- 3,200 off
SE.step(epoch)
check("3,200 studs off (past twice 1,500): back to the patrol", SE.mode == "patrol", SE.mode)
ENEMIES.kids = {}
-- The compass disagrees (danger 4 at the zone point): the circle moves out.
reset()
BOAT.pivot = cf(Z5 + vec(400, 5, 0), math.pi / 2)
DANGER = 4
SE.checkAt, SE.wrong, SE.shift = 0, 0, 0
SE.step(epoch)
CLOCK += 11
SE.step(epoch)
check("compass says 4, twice: the circle moves 1,500 studs OUT", SE.shift == 1
    and near(horiz(SE.centre, TIKI) - horiz(Z5, TIKI), 1500, 0.01), SE.shift)
DANGER, SE.shift = 5, 0

-- ---------------------------------------------------------------- THE STEP: A BEAST FOUGHT
reset()
clearWorld()
S.driving, HUM.SeatPart = true, BOAT.seat
BOAT.pivot = cf(Z5 + vec(0, 5, 0), math.pi / 2)
S.drive.waterY = 5
SE.parkBoat, SE.parkAt = nil, nil
local fb = beast("SeaBeast1", Z5 + vec(300, 0, 0), 100000, 100000)
ROOT.Position = Z5 + vec(0, 20, 0)
DAMAGE = 1000
local stops0 = STOPS
SE.step(epoch)
check("a beast: off the seat (the wheel let go)", STOPS == stops0 + 1 and S.driving == false)
check("... the boat held 150 up where it was", vnear(SE.parkAt, vec(Z5.X, 155, Z5.Z)), vs(SE.parkAt))
beat()
check("... every frame: the boat written there", vnear(BOAT.pivot.Position, vec(Z5.X, 155, Z5.Z)), vs(BOAT.pivot.Position))
local last = LOCKS[#LOCKS]
check("... you hang 90 over the water (the boat's water line, 5), 50 to your side of it", last and near(last.Y, 5 + 90, 0.01)
    and near(horiz(last, fb.kids.HumanoidRootPart.Position), 50, 0.01), vs(last))
local v = CASTS[1]
check("... every key Z-F of its switches, credited by its HP, the M1 by the learned weapon",
    v and v.keys and #v.keys == 5 and v.keys[5] == "F" and v.keyOn == CFG.SeaEvKeys and v.learn == SE.learn
    and type(v.m1Tool) == "function" and type(v.dropped) == "function", v and #v.keys)
check("... a move that took HP off counts as landed", SE.lastHurt ~= nil and string.find(SE.lastKey, "hurt it", 1, true) ~= nil,
    tostring(SE.lastKey))
check("... the aim locked on its body", SE.lockPart == fb.kids.HumanoidRootPart)
aimUntil = CLOCK + 5
fb.kids.HumanoidRootPart.Position = Z5 + vec(320, 0, 10)
beat()
check("... it moves: the aim moves with it every frame", vnear(P.aimAt, Z5 + vec(320, 0, 10)), vs(P.aimAt))
aimUntil = 0
-- Nothing lands for 6 s: in close.
DAMAGE = 0
CLOCK += 7
SE.lastHurt = CLOCK - 7
reset()
SE.step(epoch)
last = LOCKS[#LOCKS]
check("nothing hurt it for 6 s from 90 up: in close (25 over, 20 off)", SE.closeOn == true and last and near(last.Y, 5 + 25, 0.01)
    and near(horiz(last, fb.kids.HumanoidRootPart.Position), 20, 0.01), vs(last))
-- Under the water: wait over it, nothing fired.
reset()
fb.kids.HumanoidRootPart.Position = Z5 + vec(320, -500, 10)
SE.step(epoch)
local over = LOCKS[#LOCKS] or FLIGHTS[#FLIGHTS]
check("it dived: no move fired, waiting 200 over the water above it", #CASTS == 0 and over and near(over.Y, 205, 0.01)
    and SE.lockPart == nil, vs(over))
fb.kids.HumanoidRootPart.Position = Z5 + vec(320, 0, 10)
-- Killed in the fight: back at the wheel, the boat down on the water.
fb.kids.Health.Value = 0
reset()
SE.step(epoch)
check("dead: counted after the quiet 5 s, not before", count() == 6)
CLOCK += 6
reset()
SE.step(epoch)
check("... then counted, and back at the wheel - the boat let down (no hold)", count() == 7 and S.driving == true
    and SE.parkAt == nil, count() .. " " .. tostring(S.driving))

-- ---------------------------------------------------------------- THE STEP: FISH FOUGHT
reset()
clearWorld()
local tsk = fish("Terrorshark", Z5 + vec(150, 0, 0), 150000)
fish("Shark", Z5 + vec(60, 0, 0), 300)                 -- nearer, but its switch is off
ENEMIES:add(inst("FishBoat", "Model", { Position = Z5 + vec(40, 0, 0) }))
SE.step(epoch)
local cur = FIGHTS[1]
check("a Terrorshark: the farm's own fight, with the sea event's rules", cur ~= nil and cur == SE.FISH_CUR)
check("... M1 AND every skill: its keys are SeaEvKeys, F included", cur and cur.allKeys() == CFG.SeaEvKeys)
check("... FishHeight over it", cur and cur.height() == 30)
check("... the Terrorshark, in place - not the Shark (off), not the ship",
    BUILT and BUILT[1][1] and BUILT[1][1].model == tsk and BUILT[3] == true, BUILT and BUILT[1][1] and BUILT[1][1].name)
CFG.FishHeight = 45
check("... the height follows the slider", cur.height() == 45)
CFG.FishHeight = 30
-- No target yet, you right on top of the Shark: still the Terrorshark (the Shark is off).
SE.cur = nil
ROOT.Position = Z5 + vec(60, 20, 0)
local list, _, inPlace = SE.FISH_CUR.build()
check("the pile builder: a switched-off Shark is never picked, however near", list[1] and list[1].model == tsk and inPlace == true,
    list[1] and list[1].name)
CFG.SeaEvFight.Terrorshark = false
SE.cur = nil
list = SE.FISH_CUR.build()
check("the pile builder: every fish switched off - nothing", #list == 0, #list)
CFG.SeaEvFight.Terrorshark = true

-- ---------------------------------------------------------------- THE GOAL AND THE SPY
reset()
clearWorld()
CFG.SeaEvGoal, CFG.SeaEvStopAtGoal = count() + 1, true
SPY_CODE = 1
SE.spy = nil
local g1 = fish("Terrorshark", Z5 + vec(100, 0, 0), 1)
T.scan(CLOCK)
g1.hum.Health = 0
T.scan(CLOCK)
CLOCK += 6
SPY_CODE = 2
SE.spy = { code = 1, at = CLOCK }
SE.step(epoch)
runSpawned()
check("the goal reached with \"stop at the goal\": hunt off, farm stopped, said", SET_HUNT[#SET_HUNT] == false and STOPPED == 1
    and #NOTES >= 1, STOPPED)
check("the Spy past his cooldown: said, and at which count", SE.spy and SE.spy.code == 2 and SE.spy.overAt == count(),
    SE.spy and SE.spy.overAt)
local bribes = 0
for _, c in ipairs(CALLS) do if c[1] == "InfoLeviathan" and c[2] ~= "1" then bribes += 1 end end
check("the Spy is only ever ASKED (\"1\") - never bribed (\"2\")", bribes == 0)
CFG.Hunt = true
reset()
clearWorld()
CFG.SeaEvGoal, CFG.SeaEvStopAtGoal = count() + 1, false
local g2 = fish("Piranha", Z5 + vec(100, 0, 0), 1)
T.scan(CLOCK)
g2.hum.Health = 0
T.scan(CLOCK)
CLOCK += 6
SE.step(epoch)
check("the goal reached, \"stop at the goal\" off: said, the hunt goes on", STOPPED == 0 and CFG.Hunt == true and SE.goalHit == true)
CFG.SeaEvGoal = 20

-- ---------------------------------------------------------------- WHOSE M1
TOOLS = { { Name = "Dragon Talon", ToolTip = "Melee" }, { Name = "Skull Guitar", ToolTip = "Gun" },
    { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" } }
SE.learn = {}
check("whose M1 on a beast: nothing learned - the fruit's first (Kitsune hits them)", T.bestM1() == "Kitsune-Kitsune")
SE.learn["M1 Kitsune-Kitsune"] = { casts = 4, closed = 0 }
check("the fruit's M1 never hurt it in 4: your fighting style next (guns off - your points)", T.bestM1() == "Dragon Talon",
    T.bestM1())
CFG.SeaEvWeapons.Gun = true
SE.learn["M1 Skull Guitar"] = { casts = 5, closed = 4 }
check("guns switched on: one that did hurt it goes first", T.bestM1() == "Skull Guitar", T.bestM1())
CFG.SeaEvWeapons.Gun = false
SE.learn = {}

-- ---------------------------------------------------------------- THE BOAT LOST
reset()
clearWorld()
BOAT.Parent = nil
HUM.SeatPart, S.driving = nil, false
local buys0 = BUYS
SE.step(epoch)
check("no boat: a new one bought (never the next server)", BUYS == buys0 + 1 and S.driving == true)
check("... its water line read off it (Y 4)", S.drive.waterY == 4, tostring(S.drive.waterY))
-- A boat still held up (a reload mid-fight): its water line is the sea's top, not 300.
reset()
BOAT = makeBoat(Z5 + vec(0, 300, 0))
HUM.SeatPart, S.driving = nil, false
SE.step(epoch)
check("a boat found held 300 up: the water line is the sea's top (Y 6), not its height", S.drive.waterY == 6,
    tostring(S.drive.waterY))

-- The hunt switched off mid-fight: nothing more is fired.
reset()
clearWorld()
local fx = beast("SeaBeast1", Z5 + vec(100, 0, 0), 1000, 1000)
local xs = T.scan(CLOCK)
CFG.Hunt = false
T.fightBeast(xs[1], epoch)
check("the hunt off mid-fight: no move fired", #CASTS == 0, #CASTS)
CFG.Hunt = true

-- ---------------------------------------------------------------- LANDING THE HITS (2026-10-09)
reset()
clearWorld()
CFG.Hunt, P.running = true, true
BOAT = makeBoat(Z5 + vec(0, 5, 0))
S.drive.waterY = 5
S.driving, HUM.SeatPart = true, BOAT.seat
local hb = beast("SeaBeast1", Z5 + vec(300, 0, 0), 100000, 100000)
local hroot = hb.kids.HumanoidRootPart
DAMAGE = 1000
SE.step(epoch)
check("the hitbox: the beast's root 60 a side on your client, see-through, no collisions (what the hubs do)",
    vnear(hroot.Size, vec(60, 60, 60)) and hroot.Transparency == 1 and hroot.CanCollide == false, vs(hroot.Size))
check("the camera 90 from it while it is fought (outside the grown box)", P.camDistance == 90)
hb.kids.Health.Value = 0
SE.step(epoch)
CLOCK += 6
SE.step(epoch)
check("the fight over: the root as it was, the camera back to yours",
    vnear(hroot.Size, vec(10, 10, 10)) and hroot.Transparency == 0 and hroot.CanCollide == true and P.camDistance == nil,
    vs(hroot.Size) .. " " .. tostring(P.camDistance))
-- The hunt switched off mid-fight: nothing of it stays.
reset()
clearWorld()
local hb2 = beast("SeaBeast2", Z5 + vec(300, 0, 0), 100000, 100000)
SE.step(epoch)
CFG.Hunt = false
beat()
check("the hunt off mid-fight: the box shrunk, the camera yours, no lock",
    vnear(hb2.kids.HumanoidRootPart.Size, vec(10, 10, 10)) and P.camDistance == nil and SE.lockPart == nil)
CFG.Hunt = true
-- Only a part named HumanoidRootPart is ever grown (another may be the body you see).
local body = inst("Body", "Part", { Size = vec(80, 20, 80) })
T.grow(body)
check("a part not named HumanoidRootPart: never grown", vnear(body.Size, vec(80, 20, 80)) and SE.grown == nil)
T.shrink()
-- TRANSFORMED: the game refuses every other weapon's key.
check("not transformed: every weapon's moves", T.toolOk("Skull Guitar") and T.toolOk("Kitsune-Kitsune"))
player.Character:add(inst("Kitsune", "Model"))
check("Kitsune form: only Kitsune's moves (the game refuses the rest)", T.toolOk("Kitsune-Kitsune")
    and not T.toolOk("Skull Guitar") and not T.toolOk("Sanguine Art"))
TOOLS = { { Name = "Skull Guitar", ToolTip = "Gun" }, { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" } }
SE.learn = { ["M1 Skull Guitar"] = { casts = 5, closed = 5 }, ["M1 Kitsune-Kitsune"] = { casts = 5, closed = 0 } }
check("Kitsune form: the M1 is Kitsune's, whatever was learned in base", T.bestM1() == "Kitsune-Kitsune", T.bestM1())
player.Character.kids.Kitsune = nil
CFG.SeaEvWeapons.Gun = true
check("...back in base (guns on): the learned best again", T.bestM1() == "Skull Guitar")
CFG.SeaEvWeapons.Gun = false
player.Character:add(inst("Dragon", "Model"))
check("Dragon form: Dragon-Dragon's moves, never Dragon Talon's (a different weapon)", T.toolOk("Dragon-Dragon")
    and not T.toolOk("Dragon Talon"))
player.Character.kids.Dragon = nil
reset()
clearWorld()
local hb3 = beast("SeaBeast3", Z5 + vec(300, 0, 0), 100000, 100000)
SE.step(epoch)
check("the beast's caster is given the transform rule", CASTS[1] and CASTS[1].toolOk ~= nil and CASTS[1].toolOk("Kitsune-Kitsune"))

-- ---------------------------------------------------------------- KITSUNE FORM FIRST (2026-10-09)
-- The verdict, pure.
check("form verdict: its M1 hurt it twice = form",
    T.verdictOf({ hits = 2, casts = 3, up = 2 }, 20) == "form")
check("form verdict: 20 s, 6 M1s, one hit = base",
    T.verdictOf({ hits = 1, casts = 6, up = 20 }, 20) == "base")
check("form verdict: 25 s but only 3 M1s = still testing (the skills took the turns)",
    T.verdictOf({ hits = 0, casts = 3, up = 25 }, 20) == nil)
check("form verdict: 10 M1s in 10 s = still testing (the time is not up)",
    T.verdictOf({ hits = 0, casts = 10, up = 10 }, 20) == nil)

local KIT = { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" }
local DT = { Name = "Dragon Talon", ToolTip = "Melee" }
local HS2 = { Name = "Hallow Scythe", ToolTip = "Sword" }
local SG = { Name = "Skull Guitar", ToolTip = "Gun" }
local function freshForm()
    SE.form = { beast = { hits = 0, casts = 0, up = 0, since = 0 }, fish = { hits = 0, casts = 0, up = 0, since = 0 } }
    SE.formRetryAt, SE.formFails = nil, 0
    player.Character.kids = {}
end
-- The game's answer to V: the rig comes (or goes).
local V_WORKS = true
ON_KEY = function(code)
    if code ~= "V" or not V_WORKS then return end
    if player.Character.kids.Kitsune then player.Character.kids.Kitsune = nil
    else player.Character:add(inst("Kitsune", "Model")) end
end

TOOLS = { DT }
freshForm()
check("no Kitsune fruit carried: never in form", T.formWanted("beast") == false)
TOOLS = { KIT, DT, HS2, SG }
CFG.SeaEvForm = "base"
check("\"never transformed\": no form", T.formWanted("beast") == false)
CFG.SeaEvForm = "form"
SE.form.beast.verdict = "base"
check("\"Kitsune form, always\": form, whatever the test said", T.formWanted("beast") == true)
CFG.SeaEvForm = "auto"
check("auto, its M1 found useless on beasts: no form for beasts", T.formWanted("beast") == false)
check("...but untested on Terrorshark etc.: form for them (the test)", T.formWanted("fish") == true)
freshForm()
check("auto, untested: form first", T.formWanted("beast") == true)

-- Into the form: Kitsune in hand, V, the rig.
KEYS_SENT, HELD = {}, nil
check("into the form: Kitsune in hand, V - the rig is on you", T.setForm(true, epoch) == true
    and HELD == "Kitsune-Kitsune" and KEYS_SENT[1] == "V" and SE.inForm())
check("in form: Dragon Talon refused (the game's rule), Kitsune's moves allowed",
    not T.seaOk("Dragon Talon") and T.seaOk("Kitsune-Kitsune"))
CFG.SeaEvWeapons["Blox Fruit"] = false
check("in form: the fruit's moves fight even with the fruit type off (the form takes nothing else)",
    T.seaOk("Kitsune-Kitsune"))
CFG.SeaEvWeapons["Blox Fruit"] = true
KEYS_SENT = {}
check("out of the form: V again - the rig gone", T.setForm(false, epoch) == true and KEYS_SENT[1] == "V" and not SE.inForm())
check("out of form: fruit + melee fight (your points); the sword and the gun do not",
    T.seaOk("Kitsune-Kitsune") and T.seaOk("Dragon Talon") and not T.seaOk("Hallow Scythe") and not T.seaOk("Skull Guitar"))
-- V cooling: no key.
BARS["Kitsune-Kitsune V"] = false
KEYS_SENT = {}
check("V's bar cooling: no key sent, not now", T.setForm(true, epoch) == false and #KEYS_SENT == 0)
BARS["Kitsune-Kitsune V"] = nil
SE.formRetryAt = nil
-- V that does nothing, three times: left alone a minute.
V_WORKS = false
for _ = 1, 3 do
    SE.formRetryAt = nil
    T.setForm(true, epoch)
end
check("V did nothing 3 times: left alone a minute (said)", SE.formRetryAt and SE.formRetryAt - CLOCK > 50
    and string.find(tostring(SE.formNote), "left alone", 1, true) ~= nil, tostring(SE.formNote))
V_WORKS = true
freshForm()

-- A beast, auto: into the form, its M1 tested - it lands = form for beasts.
reset()
clearWorld()
CFG.Hunt, P.running = true, true
BOAT = makeBoat(Z5 + vec(0, 5, 0))
S.drive.waterY = 5
S.driving, HUM.SeatPart = true, BOAT.seat
KEYS_SENT = {}
local fbx = beast("SeaBeast1", Z5 + vec(300, 0, 0), 100000, 100000)
CAST_KEY, DAMAGE = "M1 Kitsune-Kitsune (form)", 1000
SE.step(epoch)
check("a beast, auto: off the seat, into Kitsune form, fought in it", STOPS >= 1 and SE.inForm()
    and CASTS[1] and CASTS[1].suffix == " (form)", CASTS[1] and tostring(CASTS[1].suffix))
check("...its M1 hurt it (3 of 3): FORM for beasts, said", SE.form.beast.verdict == "form" and printed("HURTS Sea Beasts"),
    tostring(SE.form.beast.verdict))
-- Its M1 lands nothing: the test runs out, out of the form, base for them.
reset()
clearWorld()
freshForm()
player.Character:add(inst("Kitsune", "Model"))
local fb2 = beast("SeaBeast2", Z5 + vec(300, 0, 0), 100000, 100000)
DAMAGE = 0
for _ = 1, 20 do
    if SE.form.beast.verdict then break end
    SE.step(epoch)
end
check("its M1 hurt nothing for 20 s (6+ M1s): base for beasts, out of the form, said",
    SE.form.beast.verdict == "base" and not SE.inForm() and printed("does NOT hurt Sea Beasts"),
    tostring(SE.form.beast.verdict) .. " " .. tostring(SE.inForm()))
CASTS = {}
CAST_KEY = "Kitsune-Kitsune C"
SE.step(epoch)
check("...the next turns: untransformed - learned apart from the form (no suffix)", CASTS[1] and CASTS[1].suffix == nil
    and not SE.inForm())
-- Every 5th new beast since the verdict: tested again.
for _ = 1, 5 do T.newTarget("beast") end
check("5 beasts since the verdict: the form tested again", SE.form.beast.verdict == nil and printed("testing it again"))

-- A Terrorshark in form: the caster (credited by its Humanoid), its own learned table.
reset()
clearWorld()
freshForm()
local tsf = fish("Terrorshark", Z5 + vec(100, 0, 0), 150000)
CAST_KEY, DAMAGE = "M1 Kitsune-Kitsune (form)", 500
SE.step(epoch)
check("a Terrorshark, auto: in Kitsune form, the caster (not the farm's fight), the fish's own learning",
    SE.inForm() and CASTS[1] and CASTS[1].model == tsf and CASTS[1].learn == SE.learnFish and #FIGHTS == 0,
    #FIGHTS)
check("...its M1 hurt it (the Humanoid's HP): FORM for Terrorshark etc.", SE.form.fish.verdict == "form")
local last = LOCKS[#LOCKS]
check("...30 over it - over the WATER when it is under it (its root Y 0, the sea's top 5) - 15 off",
    last and near(last.Y, math.max(tsf.kids.HumanoidRootPart.Position.Y, 5) + 30, 0.01)
    and near(horiz(last, tsf.kids.HumanoidRootPart.Position), 15, 0.01), vs(last))
-- Base for fish: the farm's own fight, fighting style M1, fruit + melee only.
reset()
clearWorld()
freshForm()
SE.form.fish.verdict = "base"
fish("Terrorshark", Z5 + vec(100, 0, 0), 150000)
SE.step(epoch)
local fc = FIGHTS[1]
check("Terrorshark, base: the farm's own fight (remote-hit M1 lands from up there)", fc == SE.FISH_CUR and not SE.inForm())
check("...its M1: your fighting style (Dragon Talon)", fc and fc.m1Weapon() == "Dragon Talon", fc and fc.m1Weapon())
check("...the sword and the gun out (your points), the fruit and melee in",
    fc and fc.toolOk("Kitsune-Kitsune") and fc.toolOk("Dragon Talon") and not fc.toolOk("Hallow Scythe")
    and not fc.toolOk("Skull Guitar"))
check("...no sword / gun loaded from your inventory either", fc and fc.noRotate() == true)
CFG.SeaEvWeapons.Melee = false
check("melee switched off: the fruit swings M1", fc.m1Weapon() == "Kitsune-Kitsune", fc.m1Weapon())
CFG.SeaEvWeapons.Melee, CFG.SeaEvWeapons.Sword = true, true
check("a sword switched on: inventory loads allowed again", fc.noRotate() == false and fc.toolOk("Hallow Scythe"))
CFG.SeaEvWeapons.Sword = false
player.Character:add(inst("Kitsune", "Model"))
check("into the form mid-fight: the farm's fight hands over to the caster", fc.breakIf() == true)
player.Character.kids = {}
-- Nothing left to fight while in form: out of it before the wheel.
reset()
clearWorld()
freshForm()
player.Character:add(inst("Kitsune", "Model"))
HUM.SeatPart, S.driving = nil, false
KEYS_SENT = {}
SE.step(epoch)
check("nothing to fight, still in form: V - out of it, then the wheel", KEYS_SENT[1] == "V" and not SE.inForm()
    and S.driving == true)
-- The learned tables are kept, the fish's too.
SE.learnFish["M1 Dragon Talon"] = { casts = 3, closed = 3 }
SE.reset()
check("the fish's learned keys are saved with the count", saved() and saved().learnFish
    and saved().learnFish["M1 Dragon Talon"] and saved().learnFish["M1 Dragon Talon"].closed == 3)
CAST_KEY, DAMAGE, ON_KEY = "Kitsune-Kitsune C", 0, nil
freshForm()

-- ---------------------------------------------------------------- DODGING, THE WATER AS ROCK (2026-10-09)
;(function()
do
    local o = { r = 30, speed = 60, h = 30, up = 40, top = 5 }
    local e = { angle = 0, dir = 1, flipAt = 1e9, dodgeUntil = 0, lastT = 100 }
    local tp = vec(1000, -40, 2000)                      -- dived 45 under the sea's top
    local p1 = T.evadeSpot(e, tp, 100, function() return 0 end, o)
    check("the circle: 30 studs round it", near(horiz(p1, tp), 30, 0.01), horiz(p1, tp))
    check("...30 over the WATER while it is under it (never under with it)", near(p1.Y, 5 + 30, 0.01), p1.Y)
    local a0 = e.angle
    local p2 = T.evadeSpot(e, tp, 100.05, function() return 0 end, o)
    check("...moving round it at 60 studs/s (2 rad/s at 30 studs: 0.1 rad in 0.05 s)", near(e.angle - a0, 0.1, 1e-6), e.angle - a0)
    T.evadeSpot(e, tp, 105, function() return 0 end, o)
    check("...a long frame counts as 0.1 s at most (no jump across the circle)", near(e.angle - a0, 0.1 + 0.2, 1e-6), e.angle - a0)
    local tp2 = vec(1000, 50, 2000)                      -- leaping out
    check("...30 over IT when it is over the water", near(T.evadeSpot(e, tp2, 105.01, function() return 0 end, o).Y, 80, 0.01))
    e.dodgeUntil = 106
    check("...its attack: 40 higher for the dodge", near(T.evadeSpot(e, tp, 105.02, function() return 0 end, o).Y, 75, 0.01))
    check("...the dodge over: back down", near(T.evadeSpot(e, tp, 106.5, function() return 0 end, o).Y, 35, 0.01))
    e.flipAt = 107
    local before = e.dir
    T.evadeSpot(e, tp, 107, function() return 0.5 end, o)
    check("...the direction flips (1.2-3 s, at random)", e.dir == -before and near(e.flipAt, 107 + 1.2 + 0.9, 1e-6), e.flipAt)
end

-- The attack watch: a fish with an Animator.
local function animFish(name, pos)
    local m = fish(name, pos, 150000)
    local hum = m:add(inst("Humanoid", "Humanoid"))
    local animr = hum:add(inst("Animator", "Animator"))
    animr.tracks = {}
    function animr:GetPlayingAnimationTracks() return self.tracks end
    m.root = m.kids.HumanoidRootPart
    m.root.AssemblyLinearVelocity = vec(0, 0, 0)
    return m, animr
end
reset()
clearWorld()
local tsk2, animr = animFish("Terrorshark", Z5 + vec(100, 0, 0))
local swim = { Looped = true, Animation = { AnimationId = "rbxassetid://swim" } }
animr.tracks = { swim }
local ev = { root = tsk2.root, model = tsk2, name = "Terrorshark", seen = setmetatable({}, { __mode = "k" }) }
check("the watch: only its looping swim playing - no attack", T.attackWatch(ev, Z5 + vec(100, 40, 30), CLOCK, 5) == nil)
local bite = { Looped = false, Animation = { AnimationId = "rbxassetid://splash" } }
animr.tracks = { swim, bite }
local why = T.attackWatch(ev, Z5 + vec(100, 40, 30), CLOCK, 5)
check("the watch: a new animation that does not loop = an attack starting - dodge, its id said once",
    why ~= nil and string.find(why, "splash", 1, true) ~= nil and printed("rbxassetid://splash"), tostring(why))
check("...the same one playing on: not a new attack", T.attackWatch(ev, Z5 + vec(100, 40, 30), CLOCK, 5) == nil)
animr.tracks = { swim }
tsk2.root.AssemblyLinearVelocity = vec(-90, 0, 0)       -- toward you (you are on its -X side)
check("the watch: rushing at you over 60 studs/s = a charge", T.attackWatch(ev, Z5 + vec(40, 40, 0), CLOCK, 5) == "charge")
check("...the same speed AWAY from you = nothing", T.attackWatch(ev, Z5 + vec(160, 40, 0), CLOCK, 5) == nil)
tsk2.root.AssemblyLinearVelocity = vec(0, 30, 0)
tsk2.root.Position = Z5 + vec(100, 20, 0)
check("the watch: out of the water and rising = a leap", T.attackWatch(ev, Z5 + vec(100, 60, 30), CLOCK, 5) == "leap")
tsk2.root.Position, tsk2.root.AssemblyLinearVelocity = Z5 + vec(100, 0, 0), vec(0, 0, 0)

-- A fight on: the water a floor, knockback refused, no swimming, the circle.
CFG.Hunt, P.running = true, true
BOAT = makeBoat(Z5 + vec(0, 5, 0))
S.driving, HUM.SeatPart = false, nil
HUM.states = {}
T.fightOn({ root = tsk2.root, model = tsk2, label = "Terrorshark", kind = "Terrorshark" }, "fish")
check("a sea fight: the water is a floor (the sea's top + 4)", P.floorY ~= nil and near(P.floorY, T.seaTop() + 4, 1e-6),
    tostring(P.floorY))
check("...a knockback / pull is not adopted", P.keepLock == true)
check("...the Humanoid cannot swim", HUM.states.Swimming == false)
check("...round it: the circle, its watch fed with what plays already", SE.ev and SE.ev.root == tsk2.root
    and SE.ev.seen[swim] == true)
LOCKS = {}
aimUntil = 0
beat()
local l1 = LOCKS[#LOCKS]
check("every frame: on the circle round it, 30 over the water", l1 and near(horiz(l1, tsk2.root.Position), 30, 0.01)
    and near(l1.Y, math.max(tsk2.root.Position.Y, T.seaTop()) + 30, 0.01), vs(l1))
check("...the aim held on it the whole fight", aimUntil > CLOCK and P.aimAt and vnear(P.aimAt, tsk2.root.Position))
animr.tracks = { swim, { Looped = false, Animation = { AnimationId = "rbxassetid://tail" } } }
CLOCK += 0.06
beat()
local l2 = LOCKS[#LOCKS]
check("it starts an attack: up 40 the next frame, counted", l2 and near(l2.Y, l1.Y + 40, 0.01) and SE.dodges and SE.dodges >= 1,
    vs(l2))
CLOCK += 1.1
beat()
check("...a second later: back down to 30 over the water", near(LOCKS[#LOCKS].Y, l1.Y, 0.01), vs(LOCKS[#LOCKS]))
check("the farm's fight stands you on the same circle (its pose)", SE.FISH_CUR.pose() and
    near(horiz(SE.FISH_CUR.pose(), tsk2.root.Position), 30, 0.01))
check("...and presses every key the instant it can (fastCast)", SE.FISH_CUR.fastCast == true)
CFG.SeaDodge = false
local spotsBefore = #LOCKS
beat()
check("Dodge off: no circle (the fight's own spot instead)", #LOCKS == spotsBefore and SE.FISH_CUR.pose() == nil)
CFG.SeaDodge = true
-- A beast: the floor and the rest, no circle.
T.fightOn({ root = tsk2.root, model = tsk2, label = "Sea Beast", kind = "beast" }, "beast")
check("a beast: the floor, no circle (it hovers high)", P.floorY ~= nil and SE.ev == nil)
-- The hunt off mid-fight: all of it undone.
T.fightOn({ root = tsk2.root, model = tsk2, label = "Terrorshark", kind = "Terrorshark" }, "fish")
CFG.Hunt = false
beat()
check("the hunt off mid-fight: no floor, knockback adopted again, swimming back, no circle",
    P.floorY == nil and P.keepLock == nil and HUM.states.Swimming == true and SE.ev == nil and P.camDistance == nil)
CFG.Hunt = true

-- EVERY READY KEY: the rule.
local KIT2 = { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" }
local DT2 = inst("Dragon Talon", "Tool", { ToolTip = "Melee" })
DT2:add(inst("Level", "IntValue", { Value = 300 }))
TOOLS = { KIT2, DT2 }
player.PlayerGui = { Main = { Skills = { ["Dragon Talon"] = {
    C = (function() local f = inst("C", "Frame") f:add(inst("Level", "TextLabel", { Text = "Mastery 400" })) return f end)(),
    X = (function() local f = inst("X", "Frame") f:add(inst("Level", "TextLabel", { Text = "Mastery 200" })) return f end)(),
} } } }
check("keys: Kitsune's V never (it transforms)", T.keyOk("Kitsune-Kitsune", "V") == false)
check("keys: Dragon Talon's V yes (an attack)", T.keyOk("Dragon Talon", "V") == true)
check("keys: Kitsune's Z X C F yes", T.keyOk("Kitsune-Kitsune", "Z") and T.keyOk("Kitsune-Kitsune", "X")
    and T.keyOk("Kitsune-Kitsune", "C") and T.keyOk("Kitsune-Kitsune", "F"))
check("keys: a key its mastery has not unlocked (C at 400, you 300) - never pressed", T.keyOk("Dragon Talon", "C") == false)
check("keys: one it has (X at 200) - pressed", T.keyOk("Dragon Talon", "X") == true)
CFG.SeaEvKeys.X = false
check("keys: a switch off - not pressed", T.keyOk("Kitsune-Kitsune", "X") == false)
CFG.SeaEvKeys.X = true

-- THE CASTER: the first ready key, the one in hand first, the instant the game takes it.
local HPV = 100000
local FORM_M1 = true          -- the caster's v.m1Ok: in Kitsune form (an M1 allowed)
local function cv(extra)
    local v = { pos = Z5, part = tsk2.root, model = tsk2, learn = {}, hp = function() return HPV end,
        toolOk = function() return true end, keyOk = function(_, k) return k ~= "V" end,
        m1Tool = function() return "Kitsune-Kitsune" end, m1Ok = function() return FORM_M1 end }
    for k2, x in pairs(extra or {}) do v[k2] = x end
    return v
end
BARS, KEYS_SENT, KEYS_AT, M1S = {}, {}, {}, 0
ON_KEY = function(code) BARS[HELD .. " " .. code] = false end      -- the game: it fires, its bar cools
READY = { ["Kitsune-Kitsune Z"] = true, ["Dragon Talon Z"] = true, ["Kitsune-Kitsune V"] = true }
HELD, CAN = "Dragon Talon", true
local v1 = cv()
local t0 = CLOCK
local k1 = SEA_CAST(v1)
check("the caster: the weapon in hand first - Dragon Talon Z", k1 == "Dragon Talon Z" and KEYS_SENT[1] == "Z", tostring(k1))
check("...the next key the frame it fired - no 0.45 s wait", CLOCK - t0 < 0.05, CLOCK - t0)
READY["Dragon Talon Z"] = false
local k2 = SEA_CAST(v1)
check("...then the next ready one - Kitsune Z (swapped to)", k2 == "Kitsune-Kitsune Z" and HELD == "Kitsune-Kitsune", tostring(k2))
READY["Kitsune-Kitsune Z"] = false
local sentBefore = #KEYS_SENT
local k3 = SEA_CAST(v1)
check("...Kitsune's V is ready but NEVER pressed: nothing ready, in form = Kitsune's M1", string.sub(tostring(k3), 1, 3) == "M1 "
    and #KEYS_SENT == sentBefore and M1S == 1 and aimPixel == nil,
    tostring(k3) .. " sent " .. (#KEYS_SENT - sentBefore) .. " m1s " .. M1S .. " last " .. tostring(KEYS_SENT[#KEYS_SENT]))
-- The game busy (another move playing): pressed the moment it takes keys, not before.
READY["Kitsune-Kitsune X"] = true
BARS["Kitsune-Kitsune X"] = nil
CAN = CLOCK + 0.2
local tw = CLOCK
SEA_CAST(v1)
check("the game busy: the key goes the moment it takes keys (0.2 s), not before",
    KEYS_AT[#KEYS_AT] >= tw + 0.2 - 1e-9 and KEYS_AT[#KEYS_AT] < tw + 0.3, KEYS_AT[#KEYS_AT] - tw)
CAN = true
READY["Kitsune-Kitsune X"] = false
-- A key the game would not take: tried again at once, then 3 s off - and the next key goes meanwhile.
ON_KEY = function(code)
    if code ~= "C" then BARS[HELD .. " " .. code] = false end      -- C: refused (its bar stays ready)
end
READY["Kitsune-Kitsune C"], READY["Kitsune-Kitsune F"] = true, true
BARS["Kitsune-Kitsune C"], BARS["Kitsune-Kitsune F"] = true, nil
local k4 = SEA_CAST(v1)
check("a key refused: the next ready key goes in the same turn", k4 == "Kitsune-Kitsune F", tostring(k4))
READY["Kitsune-Kitsune F"] = false
local nC = 0
for _, c in ipairs(KEYS_SENT) do if c == "C" then nC += 1 end end
SEA_CAST(v1)
local nC2 = 0
for _, c in ipairs(KEYS_SENT) do if c == "C" then nC2 += 1 end end
check("...the refused key tried again at once (it may have been too early)", nC2 == nC + 1, nC2 - nC)
SEA_CAST(v1)
local nC3 = 0
for _, c in ipairs(KEYS_SENT) do if c == "C" then nC3 += 1 end end
check("...refused twice: left 3 s (the M1 meanwhile)", nC3 == nC2, nC3 - nC2)
READY["Kitsune-Kitsune C"] = false
ON_KEY = function(code) BARS[HELD .. " " .. code] = false end
-- The credit: the target's HP over the next second, without waiting.
local lv = {}
local v2 = cv({ learn = lv, suffix = " (form)" })
READY = { ["Kitsune-Kitsune Z"] = true }
BARS = {}
HELD = "Kitsune-Kitsune"
local kz = SEA_CAST(v2)
check("in form: the key learned apart - \"Kitsune-Kitsune Z (form)\"", kz == "Kitsune-Kitsune Z (form)", tostring(kz))
READY = {}
HPV = HPV - 900
local _, res = SEA_CAST(v2)
local credited = false
for _, rr in ipairs(res) do if rr.key == "Kitsune-Kitsune Z (form)" and rr.hit then credited = true end end
check("...its HP went down by the next turn: credited, without waiting for it", credited
    and lv["Kitsune-Kitsune Z (form)"] and lv["Kitsune-Kitsune Z (form)"].closed == 1)
-- An M1 with a key going off beside it does not count for the form's test.
FORM_M1 = true
local v3 = cv({ learn = {} })
READY = {}
SEA_CAST(v3)                                               -- an M1, pending
READY = { ["Kitsune-Kitsune X"] = true }
BARS = {}
SEA_CAST(v3)                                               -- a key while the M1 waits
READY = {}
HPV = HPV - 500
local _, res3 = SEA_CAST(v3)
local m1solo = nil
for _, rr in ipairs(res3) do if rr.m1 and rr.hit then m1solo = rr.solo end end
check("an M1 with a key going off beside it: not counted for the form's test (who hit is unclear)", m1solo == false,
    tostring(m1solo))
-- A LONG MOVE (user, 2026-10-09: "Kitsune Z and X missed, only C and F"): its bar starts at
-- its END; the game goes busy with it at once (Holding). Counted fired - never put aside.
FORM_M1 = false
CLOCK += 5                -- past the earlier cases' 3 s back-offs
local LONG_BUSY = 1.2
ON_KEY = function(code)
    if code == "Z" or code == "X" then
        CAN = CLOCK + LONG_BUSY                         -- busy with it; its bar stays "ready" for now
    else
        BARS[HELD .. " " .. code] = false
    end
end
READY = { ["Kitsune-Kitsune Z"] = true, ["Kitsune-Kitsune X"] = true, ["Kitsune-Kitsune C"] = true }
BARS = { ["Kitsune-Kitsune Z"] = true, ["Kitsune-Kitsune X"] = true, ["Kitsune-Kitsune C"] = true }
HELD, CAN = "Kitsune-Kitsune", true
local vl = cv()
local kz2 = SEA_CAST(vl)
check("a long move (Z: its bar still ready, the game busy with it): FIRED, not refused", kz2 == "Kitsune-Kitsune Z",
    tostring(kz2))
READY["Kitsune-Kitsune Z"] = false
local busyTill = CAN
local kx2 = SEA_CAST(vl)
check("...X waits for Z to end (never pressed into it), then goes - fired too", kx2 == "Kitsune-Kitsune X"
    and KEYS_AT[#KEYS_AT] >= busyTill - 1e-9, tostring(kx2) .. " at +" .. tostring(KEYS_AT[#KEYS_AT] - busyTill))
READY["Kitsune-Kitsune X"] = false
local kc2 = SEA_CAST(vl)
check("...then C: Z, X and C all pressed in turn", kc2 == "Kitsune-Kitsune C", tostring(kc2) .. " CAN " .. tostring(CAN) .. " CLOCK " .. CLOCK .. " readyC " .. tostring(READY["Kitsune-Kitsune C"]) .. " barC " .. tostring(BARS["Kitsune-Kitsune C"]) .. " sent " .. table.concat(KEYS_SENT, ",", math.max(1, #KEYS_SENT-3)))
-- Busy for more than 3 s (stunned): nothing pressed into it.
READY = { ["Kitsune-Kitsune Z"] = true }
BARS = {}
CAN = CLOCK + 10
local sentL = #KEYS_SENT
local kb = SEA_CAST(vl)
check("busy for long (stunned): nothing pressed into it - tried again next turn", kb == nil and #KEYS_SENT == sentL)
CAN = true
ON_KEY = function(code) BARS[HELD .. " " .. code] = false end

-- NO M1 OUT OF FORM (user, 2026-10-09: an untransformed M1 does nothing to a sea event).
FORM_M1 = false
READY, BARS = {}, {}
local m1Before, sentB = M1S, #KEYS_SENT
local kn, resn = SEA_CAST(cv())
check("out of Kitsune form, nothing ready: NO M1 (not even to test) - nothing pressed, wait for the next key",
    kn == nil and M1S == m1Before and #KEYS_SENT == sentB and type(resn) == "table", tostring(kn))
READY = { ["Kitsune-Kitsune Z"] = true }
local kk = SEA_CAST(cv())
check("...a key ready: it goes as always", kk == "Kitsune-Kitsune Z" and M1S == m1Before, tostring(kk))
FORM_M1 = true
READY = {}
SEA_CAST(cv())
check("in Kitsune form: its M1 between the keys", M1S == m1Before + 1)
-- The farm's fight (Terrorshark out of form) swings no M1; in form the caster takes over anyway.
player.Character.kids = {}
check("the farm's fight out of form: no M1 at all (noM1)", SE.FISH_CUR.noM1() == true)
player.Character:add(inst("Kitsune", "Model"))
check("...in Kitsune form it would (but the caster has it)", SE.FISH_CUR.noM1() == false)
-- The beast fight gives its caster that rule, live.
TOOLS = {}
player.Character.kids = {}
reset()
clearWorld()
CFG.Hunt, P.running = true, true
beast("SeaBeast7", Z5 + vec(300, 0, 0), 100000, 100000)
SE.step(epoch)
check("a beast fight out of form: its caster swings no M1", CASTS[1] and CASTS[1].m1Ok and CASTS[1].m1Ok() == false)
player.Character:add(inst("Kitsune", "Model"))
check("...in Kitsune form: Kitsune's M1 allowed", CASTS[1].m1Ok() == true)
player.Character.kids = {}
ON_KEY, READY, BARS, CAN = nil, {}, {}, true
TOOLS = {}
end)()

-- ---------------------------------------------------------------- THE LEVIATHAN (2026-10-09)
;(function()
-- The part to hit, pure.
local function px(name, kind, enabled, hp, max, pos)
    return { model = { Name = name }, kind = kind, enabled = enabled, hp = hp, max = max, pos = pos, label = name }
end
local A = px("segA", "segment", true, 100000, 100000, vec(0, 0, 0))
local B = px("segB", "segment", true, 100000, 100000, vec(500, 0, 0))
local H = px("head", "head", false, 300000, 300000, vec(10, 0, 0))
local share = {}
check("levi pick: the nearest segment short of your share", T.leviPick({ A, B, H }, nil, share, 0.15, vec(1, 0, 0)) == A)
share[A.model] = 16000
check("levi pick: your share of it reached (16% of 15%) - the next one, even far", T.leviPick({ A, B, H }, A.model, share, 0.15,
    vec(1, 0, 0)) == B)
share[A.model] = 5000
check("levi pick: the one being hit, while short - kept (nearer ones wait)", T.leviPick({ A, B, H }, B.model, share, 0.15,
    vec(1, 0, 0)) == B)
share[A.model], share[B.model] = 20000, 20000
check("levi pick: every share reached - the one being hit until it dies", T.leviPick({ A, B, H }, B.model, share, 0.15,
    vec(1, 0, 0)) == B)
check("levi pick: ...or the nearest", T.leviPick({ A, B, H }, nil, share, 0.15, vec(1, 0, 0)) == A)
check("levi pick: a part that takes no damage now (the head, before the segments) - never",
    T.leviPick({ H }, nil, {}, 0.15, vec(0, 0, 0)) == nil)
local Hon = px("head", "head", true, 300000, 300000, vec(10, 0, 0))
local Adead = px("segA", "segment", true, 0, 100000, vec(0, 0, 0))
check("levi pick: a dead segment skipped; the head, once it takes damage, has no share rule",
    T.leviPick({ Adead, Hon }, nil, {}, 0.15, vec(0, 0, 0)) == Hon)
local Ash = px("segA", "segment", true, 100000, 100000, vec(0, 0, 0))
check("levi pick: the head (no share rule) never pulls you off a segment you finished",
    T.leviPick({ Hon, Ash }, Ash.model, { [Ash.model] = 20000 }, 0.15, vec(10, 0, 0)) == Ash)

-- Its parts in workspace.SeaBeasts.
local function lpart(name, pos, hp, max, enabled)
    local m = inst(name, "Model")
    m:add(inst("HumanoidRootPart", "Part", { Position = pos, Size = vec(10, 10, 10), CanCollide = true, Transparency = 0 }))
    m:add(inst("Health", "NumberValue", { Value = hp }))
    if max then m:add(inst("MaxHealth", "NumberValue", { Value = max })) end
    if enabled ~= nil then m.attrs.HealthEnabled = enabled end
    SEABEASTS:add(m)
    return m
end
reset()
clearWorld()
TOOLS, READY, BARS = {}, {}, {}
player.Character.kids = {}
local headM = lpart("Leviathan", Z5 + vec(0, 0, 0), 300000, 300000, false)
local segA = lpart("Leviathan Segment", Z5 + vec(200, 0, 0), 100000, 100000, true)
local segB = lpart("Leviathan Segment", Z5 + vec(800, 0, 0), 100000, 100000, true)
local tailM = lpart("Leviathan Tail", Z5 + vec(1200, 0, 0), 100000, 100000, true)
local lp = T.leviParts()
local kinds = {}
for _, x in ipairs(lp) do kinds[x.kind] = (kinds[x.kind] or 0) + 1 end
check("its parts: the head, two segments, the tail - the head not taking damage yet",
    #lp == 4 and kinds.head == 1 and kinds.segment == 2 and kinds.tail == 1, #lp)
for _, x in ipairs(lp) do
    if x.kind == "head" then check("...the head: HealthEnabled off = not now", x.enabled == false) end
end
-- No part has the attribute at all (renamed?): every part taken.
local savedAttrs = {}
for _, m in ipairs({ headM, segA, segB, tailM }) do savedAttrs[m] = m.attrs.HealthEnabled m.attrs.HealthEnabled = nil end
local allOn = true
for _, x in ipairs(T.leviParts()) do if not x.enabled then allOn = false end end
check("no part has HealthEnabled at all: every part taken", allOn)
for m, a in pairs(savedAttrs) do m.attrs.HealthEnabled = a end

-- THE FIGHT: switch off = nothing.
CFG.LeviFight = false
CFG.Hunt = false
check("the switch off: the Leviathan left alone (the other modes run)", SE.leviStep() == false)
CFG.LeviFight = true
-- On: the nearest segment, no boat touched, the water a floor, round it at 75.
BOAT = makeBoat(Z5 + vec(0, 5, 0))
local pivot0 = BOAT.pivot
S.driving, HUM.SeatPart = true, BOAT.seat
SE.parkBoat, SE.parkAt = nil, nil
ROOT.Position = Z5 + vec(150, 40, 0)
CAST_KEY, DAMAGE = "Kitsune-Kitsune C", 5000
local stops0 = STOPS
check("on, the Leviathan up: it has the character (true), said", SE.leviStep() == true and printed("THE LEVIATHAN"))
check("...off the seat, but NO boat parked or moved (a group may ride it)", STOPS > stops0 and SE.parkAt == nil
    and BOAT.pivot == pivot0)
check("...the nearest segment that takes damage - not the head", CASTS[1] and CASTS[1].model == segA, CASTS[1] and CASTS[1].model.Name)
check("...the water a floor, knockback refused, round it at 75 over it", P.floorY ~= nil and P.keepLock == true
    and SE.ev and SE.ev.h == 75)
check("...its parts written to the probe file", FILES["bff_beast_probe.txt"]
    and string.find(FILES["bff_beast_probe.txt"], "[leviathan]", 1, true) ~= nil)
-- The sea events hunt is OFF: the fight's frame runs anyway (the circle at 75).
LOCKS = {}
beat()
local ll = LOCKS[#LOCKS]
check("the sea events hunt off: the circle round the segment still runs, 75 over the water",
    ll and near(ll.Y, math.max(segA.kids.HumanoidRootPart.Position.Y, T.seaTop()) + 75, 0.01)
    and near(horiz(ll, segA.kids.HumanoidRootPart.Position), 30, 0.01), vs(ll))
-- Your share: segment A's HP drop while your keys land; at 15% the next segment.
for _ = 1, 6 do
    SE.leviStep()
    if CASTS[#CASTS].model ~= segA then break end
end
check("segment A at your share (15% of it from your keys): on to the next segment",
    (SE.levi.share[segA] or 0) >= 15000 and CASTS[#CASTS].model ~= segA and printed("on the Leviathan"),
    tostring(SE.levi.share[segA]))
-- The head takes damage only now; it dies: the count back to 0, the kill kept.
SE.count.total, SE.count.kinds = 13, { ["Sea Beast"] = 13 }
headM.attrs.HealthEnabled = true
headM.kids.Health.Value = 0
SE.leviStep()
check("its head's HP 0: THE LEVIATHAN IS DOWN - the sea event count back to 0, the kill kept, said",
    SE.count.total == 0 and SE.count.kinds.Leviathan == 1 and SE.levi.kills == 1 and printed("LEVIATHAN IS DOWN")
    and saved() and saved().total == 0, SE.count.total)
SE.leviStep()
check("...counted once", SE.levi.kills == 1)
-- ITS HEART: the character is yours.
local heartPart = MAP:add(inst("FrozenHeart", "Model"))
P.handsOff = false
check("its heart (Map.FrozenHeart): the character is YOURS (hands off), nothing else runs, said",
    SE.leviStep() == true and P.handsOff == true and #NOTES >= 1 and P.floorY == nil and SE.ev == nil)
MAP.kids.FrozenHeart = nil
for _, m in ipairs({ headM, segA, segB, tailM }) do gone(m) end
check("the heart gone, nothing of it up: the switch on = still yours (hands off), nothing else runs - waiting, said",
    SE.leviStep() == true and P.handsOff == true and SE.levi.waiting == true and printed("waiting for it"))
-- A new one later; its head gone at 5% (it sank): down too.
local h2 = lpart("Leviathan", Z5, 300000, 300000, true)
SE.leviStep()
check("it shows: the fight has the character again (hands back, not waiting)", P.handsOff == false
    and SE.levi.waiting == false and SE.levi.active == true)
h2.kids.Health.Value = 12000
SE.leviStep()
gone(h2)
SE.leviStep()
check("a new Leviathan, its head gone at 4%: down (it sinks as it dies) - a second kill", SE.levi.kills == 2, SE.levi.kills)
-- It goes without a heart (under / despawned / left): held over the water 20 s, then yours.
local g1 = lpart("Leviathan Segment", Z5 + vec(300, 0, 0), 100000, 100000, true)
SE.leviStep()
check("(a fight on)", P.floorY ~= nil and SE.levi.active == true)
gone(g1)
LOCKS = {}
ROOT.Position = vec(Z5.X + 300, 0, Z5.Z)       -- low over the water when it went
check("it goes mid-fight (no heart): HELD over the water - the floor kept, 20+ over the sea, nothing else runs",
    SE.leviStep() == true and P.floorY ~= nil and SE.ev == nil and SE.levi.active == false and P.handsOff == false
    and LOCKS[#LOCKS] ~= nil and LOCKS[#LOCKS].Y >= T.seaTop() + 20 - 0.01, vs(LOCKS[#LOCKS]))
beat()
check("...the heartbeat leaves the hold's floor alone (the hold is a fight)", P.floorY ~= nil and P.keepLock == true)
CLOCK += 21
check("...20 s and nothing: the floor off, the character yours (hands off) - waiting for it",
    SE.leviStep() == true and P.floorY == nil and P.handsOff == true and SE.levi.waiting == true)
-- Its attacks: an AnimationController's Animator (no Humanoid) is watched too.
local lpa = lpart("Leviathan Segment", Z5 + vec(300, 0, 0), 100000, 100000, true)
local ac = lpa:add(inst("AnimationController", "AnimationController"))
local an = ac:add(inst("Animator", "Animator"))
an.tracks = {}
function an:GetPlayingAnimationTracks() return self.tracks end
local lev = { root = lpa.kids.HumanoidRootPart, model = lpa, name = "Leviathan segment", seen = setmetatable({}, { __mode = "k" }) }
an.tracks = { { Looped = false, Animation = { AnimationId = "rbxassetid://levi-beam" } } }
check("its attack seen on an AnimationController (no Humanoid): dodge",
    T.attackWatch(lev, Z5 + vec(300, 80, 30), CLOCK, 5) ~= nil)
gone(lpa)
-- Nothing takes damage (a phase change): over it, waiting, nothing fired.
reset()
local n1 = lpart("Leviathan Segment", Z5 + vec(300, -10, 0), 100000, 100000, false)
CASTS = {}
LOCKS = {}
SE.leviStep()
local lw = LOCKS[#LOCKS]
check("no part takes damage right now: waiting 75 over it, nothing fired", #CASTS == 0 and lw
    and near(lw.Y, math.max(-10, T.seaTop()) + 75, 0.01), vs(lw))
-- The switch off mid-fight: all of it undone.
n1.attrs.HealthEnabled = true
SE.leviStep()
CFG.LeviFight = false
SE.leviStep()
check("the switch off mid-fight: no floor, no circle - nothing of it stays (the step itself)",
    P.floorY == nil and SE.ev == nil and P.keepLock == nil and SE.levi.active == false)
beat()
gone(n1)
CAST_KEY, DAMAGE = "Kitsune-Kitsune C", 0
end)()

-- ---------------------------------------------------------------- THE LEVIATHAN v2 (2026-10-09.8)
;(function()
-- Out of an attack's reach, pure: sideways only.
local Cl = T.clearOf
local ball = { kind = "ball", c = vec(0, 0, 0), r = 100 }
local s1 = Cl(vec(30, 80, 40), { ball }, 15)
check("out of its red area: sideways to its edge + 15, the height kept (up does not leave it)",
    near(horiz(s1, vec(0, 0, 0)), 115, 0.01) and near(s1.Y, 80, 0.01) and near(s1.X / s1.Z, 30 / 40, 0.01), vs(s1))
check("...outside it: left alone", vnear(Cl(vec(200, 80, 0), { ball }, 15), vec(200, 80, 0)))
local line = { kind = "line", o = vec(0, 50, 0), dir = vec(1, 0, 0), w = 20 }
local s2 = Cl(vec(100, 50, 10), { line }, 15)
check("off its beam's line: sideways to 35 from it, as far along it (never up / down)",
    near(s2.X, 100, 0.01) and near(s2.Y, 50, 0.01) and near(s2.Z, 35, 0.01), vs(s2))
local s3 = Cl(vec(100, 60, 0), { line }, 15)
check("...right over it (10 up): sideways only, 35 from the line in all",
    near(s3.Y, 60, 0.01) and near(s3.X, 100, 0.01) and near(math.sqrt(100 + s3.Z * s3.Z), 35, 0.01), vs(s3))
local s3b = Cl(vec(100, 50, -10), { line }, 15)
check("...on its other side: out that side (the shorter way)", near(s3b.Z, -35, 0.01), vs(s3b))
check("...behind its mouth: left alone", vnear(Cl(vec(-50, 50, 5), { line }, 15), vec(-50, 50, 5)))
local s4 = Cl(vec(10, 50, 0), { ball, line }, 15)
check("two at once: out of both", horiz(s4, vec(0, 0, 0)) >= 115 - 0.01 and math.abs(s4.Z) >= 35 - 0.01, vs(s4))

-- THE HEAD LAST, whatever the attribute says (none at all = every part takes damage).
local function px(name, kind, enabled, hp, max, pos)
    return { model = { Name = name }, kind = kind, enabled = enabled, hp = hp, max = max, pos = pos, label = name }
end
local A2 = px("segA", "segment", true, 100000, 100000, vec(100, 0, 0))
local Hn = px("head", "head", true, 300000, 300000, vec(0, 0, 0))
check("levi pick: THE HEAD LAST - nearer and taking damage, still never while a segment is alive",
    T.leviPick({ Hn, A2 }, nil, { [A2.model] = 20000 }, 0.15, vec(0, 0, 0)) == A2)
check("...a segment back (they respawn) while the head is hit: back to the segment",
    T.leviPick({ Hn, A2 }, Hn.model, {}, 0.15, vec(0, 0, 0)) == A2)
local T2 = px("tail", "tail", true, 100000, 100000, vec(900, 0, 0))
check("...the tail too goes before the head", T.leviPick({ Hn, T2 }, Hn.model, { [T2.model] = 50000 }, 0.15,
    vec(0, 0, 0)) == T2)

-- Its HP: a Humanoid when nothing else has it (the game's SyncLeviathan gives each part one).
local hm = inst("Leviathan Segment", "Model")
hm:add(inst("Humanoid", "Humanoid", { Health = 150000, MaxHealth = 187500 }))
local hpa, hpm, hsrc = T.beastHP(hm)
check("its HP from its Humanoid when no value / text / attribute has it", hpa == 150000 and hpm == 187500
    and hsrc == "its Humanoid", tostring(hsrc))
local hm2 = inst("SeaBeast1", "Model")
hm2:add(inst("Health", "NumberValue", { Value = 5 }))
hm2:add(inst("Humanoid", "Humanoid", { Health = 100, MaxHealth = 100 }))
check("...a Health value first (the Humanoid only the last resort)", T.beastHP(hm2) == 5)

-- The hitbox never made smaller.
local big = inst("HumanoidRootPart", "Part", { Size = vec(100, 40, 120), CanCollide = true, Transparency = 0 })
T.grow(big)
check("the hitbox: a side already over 60 keeps its length - never made smaller", vnear(big.Size, vec(100, 60, 120)),
    vs(big.Size))
T.shrink()
check("...put back as it was", vnear(big.Size, vec(100, 40, 120)))

-- Its parts' attacks watched, every one: the head roars while you hit a segment.
local function lpart(name, pos, hp, max, enabled)
    local m = inst(name, "Model")
    m:add(inst("HumanoidRootPart", "Part", { Position = pos, Size = vec(10, 10, 10), CanCollide = true, Transparency = 0 }))
    m:add(inst("Health", "NumberValue", { Value = hp }))
    if max then m:add(inst("MaxHealth", "NumberValue", { Value = max })) end
    if enabled ~= nil then m.attrs.HealthEnabled = enabled end
    SEABEASTS:add(m)
    return m
end
reset()
clearWorld()
local wHead = lpart("Leviathan", Z5 + vec(0, 0, 0), 300000, 300000, false)
local wHum = wHead:add(inst("Humanoid", "Humanoid", { Health = 100, MaxHealth = 100 }))
local wAn = wHum:add(inst("Animator", "Animator"))
wAn.tracks = {}
function wAn:GetPlayingAnimationTracks() return self.tracks end
local wSeg = lpart("Leviathan Segment", Z5 + vec(150, 0, 0), 100000, 100000, true)
local ew = { root = wSeg.kids.HumanoidRootPart, model = wSeg, watch = { wSeg, wHead }, name = "Leviathan segment",
    seen = setmetatable({}, { __mode = "k" }) }
check("the watch: nothing new on any part - no attack", T.attackWatch(ew, Z5 + vec(150, 75, 30), CLOCK, 5) == nil)
wAn.tracks = { { Looped = false, Animation = { AnimationId = "rbxassetid://levi-roar" } } }
check("the watch: its HEAD starts an attack while you hit a segment - dodge",
    T.attackWatch(ew, Z5 + vec(150, 75, 30), CLOCK, 5) ~= nil)

-- THE FIGHT, its attacks out of reach: workspace._WorldOrigin, as the game fills it.
local WO = WS:add(inst("_WorldOrigin", "Folder"))
local WO_ADDED = nil
WO.ChildAdded = { Connect = function(_, f)
    WO_ADDED = f
    return { Disconnect = function() WO_ADDED = nil end }
end }
local function spawnFx(i)
    WO:add(i)
    if WO_ADDED then WO_ADDED(i) end
    return i
end
CFG.LeviFight, CFG.Hunt = true, false
CAST_KEY, DAMAGE = "Kitsune-Kitsune C", 3000
ROOT.Position = Z5 + vec(150, 80, 0)
SE.leviStep()
local segPos = wSeg.kids.HumanoidRootPart.Position
check("the fight on: the game's effects folder watched", WO_ADDED ~= nil and SE.ev ~= nil and SE.ev.dangers ~= nil)
check("...every part of it watched for an attack (the head too)", SE.ev.watch ~= nil and #SE.ev.watch == 2)
-- The tail's red area (Bubble), over the segment: out of it sideways, kept 7 s.
local bubble = spawnFx(inst("Bubble", "Part", { Position = segPos, Size = vec(200, 200, 200) }))
LOCKS = {}
beat()
local lb = LOCKS[#LOCKS]
check("ITS RED AREA (Bubble, 200 across) over the segment: the circle steps out of it - 115 from its middle",
    lb ~= nil and horiz(lb, segPos) >= 115 - 0.01 and SE.lastClear ~= nil, vs(lb))
check("...said, what it is", printed("the tail's red area") and printed("Bubble"))
runSpawned()
check("...its real size and place written to the probe file", FILES["bff_beast_probe.txt"] ~= nil
    and string.find(FILES["bff_beast_probe.txt"], "[leviathan attack] Bubble", 1, true) ~= nil)
gone(bubble)
CLOCK += 3
LOCKS = {}
beat()
check("...it goes (the game's Debris, 4 s): still kept out - the swipe comes after",
    LOCKS[#LOCKS] ~= nil and horiz(LOCKS[#LOCKS], segPos) >= 115 - 0.01)
CLOCK += 5
LOCKS = {}
beat()
check("...7 s on: back round the segment, 30 off", LOCKS[#LOCKS] ~= nil and near(horiz(LOCKS[#LOCKS], segPos), 30, 0.01),
    vs(LOCKS[#LOCKS]))
-- The beam: its charge on the mouth, then the beam - a line along its look.
local mouth = spawnFx(inst("MouthCharge", "Part", { Position = Z5 + vec(0, 40, 0), CFrame = cf(Z5 + vec(0, 40, 0), -math.pi / 2) }))
local ds = T.leviDangers()
local ln = nil
for _, d in ipairs(ds) do if d.kind == "line" then ln = d end end
check("ITS BEAM CHARGING (MouthCharge): a line from the mouth along its look",
    ln ~= nil and vnear(ln.o, Z5 + vec(0, 40, 0)) and vnear(ln.dir, vec(1, 0, 0)), ln and vs(ln.dir))
gone(mouth)
check("...the charge gone: no line (the beam has its own object)", #T.leviDangers() == 0)
local beam = inst("BeamModel", "Model")
beam:add(inst("BeamRoot", "Part", { Position = Z5 + vec(0, 40, 0) }))
beam:add(inst("BeamEnd", "Part", { Position = Z5 + vec(300, 40, 0), CFrame = cf(Z5 + vec(300, 40, 0), -math.pi / 2) }))
spawnFx(beam)
ds = T.leviDangers()
check("ITS BEAM (BeamModel): from its root along its end's look", #ds == 1 and ds[1].kind == "line"
    and vnear(ds[1].o, Z5 + vec(0, 40, 0)) and vnear(ds[1].dir, vec(1, 0, 0)))
CLOCK += 9
check("...over after 8 s even if left behind", #T.leviDangers() == 0)
gone(beam)
-- Its tornadoes: a column where it is now (it moves).
local torn = inst("IcyTornado", "Model")
torn:add(inst("Part", "Part", { Size = vec(10, 300, 10), Position = Z5 + vec(500, 0, 0) }))
torn.pivot = cf(Z5 + vec(500, 0, 0))
spawnFx(torn)
ds = T.leviDangers()
check("ITS TORNADO (IcyTornado): a column where it is, 15 across at least", #ds == 1 and ds[1].kind == "ball"
    and vnear(ds[1].c, Z5 + vec(500, 0, 0)) and near(ds[1].r, 15, 0.01))
torn.pivot = cf(Z5 + vec(520, 0, 0))
ds = T.leviDangers()
check("...followed as it moves", vnear(ds[1].c, Z5 + vec(520, 0, 0)))
gone(torn)
-- Its roar's ice spears: up, the moment one flies near.
SE.ev.dodgeUntil = 0
spawnFx(inst("IceSpear", "Part", { Position = ROOT.Position + vec(120, 0, 0) }))
check("ITS ICE SPEAR (the roar) near you: up now", SE.ev.dodgeUntil > CLOCK and SE.lastDodge == "its ice spear")
SE.ev.dodgeUntil = 0
spawnFx(inst("IceSpear", "Part", { Position = ROOT.Position + vec(900, 0, 0) }))
check("...one far off (900): not for you", SE.ev.dodgeUntil == 0)
-- A second red area: kept out of, said only the first time.
local bubble2 = spawnFx(inst("Bubble", "Part", { Position = segPos + vec(0, 0, 400), Size = vec(100, 100, 100) }))
local said = 0
for _, s in ipairs(PRINTED) do if string.find(s, "the tail's red area", 1, true) then said += 1 end end
check("...a second one: said only once (a kind is named the first time)", said == 1, said)
gone(bubble2)
-- A segment back (they respawn) while one is being hit: watched too, the target kept.
DAMAGE = 0
local wSeg2 = lpart("Leviathan Segment", Z5 + vec(900, 0, 0), 100000, 100000, true)
SE.leviStep()
check("a segment back mid-fight: its attacks watched too (the target kept)", SE.ev ~= nil
    and SE.ev.root == wSeg.kids.HumanoidRootPart and #SE.ev.watch == 3, SE.ev and #SE.ev.watch)
-- Nothing lands for 6 s: the circle comes in to 25 over it.
for _ = 1, 8 do SE.leviStep() end
check("nothing landed for 6 s: the Leviathan's circle down to 25 over the part", SE.ev ~= nil and SE.ev.h == 25,
    SE.ev and SE.ev.h)
-- A new copy of the script loaded (_G.BFF is not this one): the watch lets go by itself.
_G.BFF = {}
spawnFx(inst("Bubble", "Part", { Position = segPos, Size = vec(50, 50, 50) }))
check("a new copy loaded: the effects watch lets go by itself", WO_ADDED == nil)
_G.BFF = P
SE.leviStep()
check("...this copy again: watched again", WO_ADDED ~= nil)
-- The switch off: the watch let go.
CFG.LeviFight = false
SE.leviStep()
check("the switch off: the effects folder let go, nothing of the fight stays", WO_ADDED == nil and SE.ev == nil
    and P.floorY == nil)
WO.Parent.kids[WO.key] = nil
gone(wHead)
gone(wSeg)
gone(wSeg2)
-- Waiting for it (nothing up), then the switch off: the character back to the farm.
CFG.LeviFight = true
check("the switch on, nothing of it up: waiting, the character yours", SE.leviStep() == true and P.handsOff == true
    and SE.levi.waiting == true)
CFG.LeviFight = false
check("...the switch off while waiting: the farm drives again (hands back), the other modes run",
    SE.leviStep() == false and P.handsOff == false and SE.levi.waiting == false)
CAST_KEY, DAMAGE = "Kitsune-Kitsune C", 0
end)()

realPrint(all and "ALL PASS" or "SOME FAILED")
