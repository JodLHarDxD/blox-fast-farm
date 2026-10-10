-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
local function vnear(a, b, eps) return a and b and (a - b).Magnitude <= (eps or 1e-6) end
local function vs(v) return v and string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) or "nil" end
local function said(text)
    for _, l in ipairs(PRINTED) do if string.find(l, text, 1, true) then return true end end
    return false
end
local function reset()
    PRINTED, SAYS, STATES, FLIGHTS, FIGHTS, CALLS = {}, {}, {}, {}, {}, {}
    FIGHT_HOOK, ON_CLICK, ON_WAIT = nil, nil, nil
end
local RD = P.raid
local T = RD._t

-- ---------------------------------------------------------------- PURE
check("spot 1: straight over it, close", vnear(T.spotFor(vec(0, 0, 0), 1), vec(0, 8, 0)))
check("spot 2: beside it (0 deg), 14 out, 5 up", vnear(T.spotFor(vec(0, 0, 0), 2), vec(14, 5, 0), 1e-6))
check("spot 3: 120 deg round", vnear(T.spotFor(vec(0, 0, 0), 3), vec(14 * math.cos(math.rad(120)), 5, 14 * math.sin(math.rad(120))), 1e-6))
check("spot 5: over it again", vnear(T.spotFor(vec(1, 2, 3), 5), vec(1, 10, 3)))
local PR = { ["Rocket-Rocket"] = 5000, ["Spike-Spike"] = 180000, ["Kitsune-Kitsune"] = 8000000, ["Flame-Flame"] = 250000 }
local function pr(n) return PR[n] end
check("cheapest: Rocket of Rocket / Spike / Kitsune under 200k",
    (T.cheapest({ ["Spike-Spike"] = 2, ["Rocket-Rocket"] = 1, ["Kitsune-Kitsune"] = 1 }, 200000, pr)) == "Rocket-Rocket")
check("cheapest: a count of 0 is not yours", (T.cheapest({ ["Rocket-Rocket"] = 0, ["Spike-Spike"] = 1 }, 200000, pr)) == "Spike-Spike")
check("cheapest: unpriced never; over the cap never", T.cheapest({ ["Mystery-Mystery"] = 1, ["Flame-Flame"] = 1 }, 200000, pr) == nil)
check("origOf: \"Rocket Fruit\" -> Rocket-Rocket, \"T-Rex Fruit\" -> T-Rex-T-Rex, the attribute first",
    T.origOf(inst("Rocket Fruit", "Tool")) == "Rocket-Rocket" and T.origOf(inst("T-Rex Fruit", "Tool")) == "T-Rex-T-Rex"
    and T.origOf(inst("Odd Fruit", "Tool", { attrs = { OriginalName = "Spin-Spin" } })) == "Spin-Spin")

-- ---------------------------------------------------------------- IN A RAID
local ISLE = vec(1000, 20, 0)
ROOT.Position = ISLE + vec(0, 45, 0)
local i2 = LOCS:add(inst("Island 2", "Part", { Position = ISLE }))
TIMER.Visible = true
local a = ENEMY("Raider", ISLE + vec(30, 0, 0), 1000)
reset()
raidStep()
check("in a raid: the island's enemy fought, the raid's own fight (the stuck watch in it)",
    FIGHTS[1] and FIGHTS[1].raid and FIGHTS[1].breakIf ~= nil and RD.inside and said("Island 2"), #FIGHTS)

-- THE STUCK FIGHT inside a fight: no HP off for 12 s -> the fight breaks, relocated.
reset()
FIGHT_HOOK = function(cur)
    for _ = 1, 60 do
        CLOCK += 0.5
        if cur.breakIf() then return "break" end
    end
    return "sweep"
end
local t0 = CLOCK
raidStep()
check("stuck in a fight: broken after 12 s with no HP off - relocated onto it, said",
    P.raidFocus == a.model and RD.streak == 1 and said("relocating (1): Raider") and CLOCK - t0 >= 12 and CLOCK - t0 < 14,
    string.format("%.1f s %s", CLOCK - t0, tostring(RD.note)))
check("...the pile let go", RELEASED > 0)
check("...the new spot: straight over it, close", vnear(T.RAID_CUR.pose(), a.root.Position + vec(0, 8, 0)), vs(T.RAID_CUR.pose()))
-- Still nothing: the next spot round it.
reset()
FIGHT_HOOK = function(cur)
    for _ = 1, 60 do
        CLOCK += 0.5
        if cur.breakIf() then return "break" end
    end
    return "sweep"
end
raidStep()
check("still stuck: relocated again, beside it this time (spot 2)", RD.streak == 2
    and vnear(T.RAID_CUR.pose(), a.root.Position + vec(14, 5, 0), 1e-6), vs(T.RAID_CUR.pose()))
-- HP comes off: progress - the clock starts again.
reset()
FIGHT_HOOK = function(cur)
    for _ = 1, 40 do
        CLOCK += 0.5
        a.hum.Health -= 10
        if cur.breakIf() then return "break" end
    end
    return "sweep"
end
raidStep()
check("HP coming off: never relocated (20 s of hits)", RD.streak == 2 and RD.moves == 2, RD.moves)
-- The kill: the streak over, the target gone.
a.hum.Health = 0
stats.kills += 1
FIGHT_HOOK = nil
reset()
raidStep()
check("its kill: the streak reset, no target left", RD.streak == 0 and P.raidFocus == nil, RD.streak)

-- THE STRAGGLER: one 800 from the island (out of RaidRadius 450) and one
-- skipped (could not hurt) - the pile empty, so wait over the island; 12 s
-- with no HP off = THE target, fought where it stands, its skip forgotten.
local far = ENEMY("Straggler", ISLE + vec(800, 0, 0), 500)
local sk = ENEMY("Skipped", ISLE + vec(0, 0, 900), 500)
P.randomSkip[sk.model] = CLOCK + 60
reset()
raidStep()
check("stragglers only: nothing in the pile - over the island, waiting", #FIGHTS == 0 and said == said
    and STATES[#STATES] == "WAIT", #FIGHTS)
CLOCK += 13
ROOT.Position = ISLE + vec(0, 45, 0)
reset()
raidStep()
check("13 s, no HP off: THE target = the nearest straggler, every skip forgotten", P.raidFocus == far.model
    and P.randomSkip[sk.model] == nil, tostring(P.raidFocus and P.raidFocus.Name))
reset()
raidStep()
check("...fought where it stands, out of the pull radius (the real buildRaidPile)", FIGHTS[1] and FIGHTS[1].raid
    and #FIGHTS == 1, #FIGHTS)
local list, centre, inPlace = buildRaidPile()
check("...buildRaidPile: only it, in place", #list == 1 and list[1] == far and inPlace == true and vnear(centre, far.root.Position))
far.hum.Health, sk.hum.Health = 0, 0
reset()
list = buildRaidPile()
check("...dead: the target let go", P.raidFocus == nil and #list == 0)
stats.kills += 2

-- ---------------------------------------------------------------- THE RAID OVER
-- The game puts you back at the castle; Island 2's marker stays, far away.
TIMER.Visible = false
ROOT.Position = vec(-5000, 315, -3000)
CFG.RaidLoop = false
reset()
raidStep()
check("raid over: said and counted, no flight anywhere, nothing fought", RD.done == 1 and not RD.inside
    and #FLIGHTS == 0 and #FIGHTS == 0 and said("raid: over (Island 2)"), tostring(RD.done) .. " " .. #FLIGHTS)
local stray = ENEMY("Castle Pirate", vec(-5000, 315, -2950), 1000)
reset()
for _ = 1, 4 do raidStep() end
check("outside a raid, loop off: stays put - the stale island never flown to, a pirate near not fought",
    #FLIGHTS == 0 and #FIGHTS == 0 and string.find(tostring(P.raidNote), "staying here", 1, true) ~= nil, P.raidNote)
stray.hum.Health = 0

-- ---------------------------------------------------------------- THE LOOP
-- The button at the castle; the server's answers.
local castle = MAP:add(inst("Boat Castle", "Model"))
local main = castle:add(inst("RaidSummon2", "Model")):add(inst("Button", "Model")):add(inst("Main", "Part",
    { Position = vec(-5040, 315, -3175) }))
local CD = main:add(inst("ClickDetector", "ClickDetector"))
local STORED = { { Name = "Kitsune-Kitsune" }, { Name = "Rocket-Rocket" }, { Name = "Spike-Spike" } }
SERVER.getInventoryFruits = function() return STORED end
SERVER.GetFruits = function()
    return { { Name = "Rocket-Rocket", Price = 5000 }, { Name = "Spike-Spike", Price = 180000 },
        { Name = "Kitsune-Kitsune", Price = 8000000 } }
end
SERVER.LoadFruit = function(name)
    local base = string.match(name, "^(.-)%-") or name
    BP:add(inst(base .. " Fruit", "Tool"))
    return true
end
-- He takes the physical fruit you carry, gives the chip.
local SELECT_ANSWER = nil
SERVER.RaidsNpc = function(what, theme)
    if what ~= "Select" then return nil end
    if SELECT_ANSWER ~= nil then return SELECT_ANSWER end
    for _, t in ipairs(BP:GetChildren()) do
        if string.find(t.Name, " Fruit$") then
            BP:remove(t.Name)
            BP:add(inst("Special Microchip", "Tool"))
            return 1
        end
    end
    return "You can only purchase a microchip with Beli once every 2 hours."
end
local function startsRaid()
    ON_CLICK = function()
        BP:remove("Special Microchip")
        TIMER.Visible = true
        LOCS:remove("Island 2")
        LOCS:add(inst("Island 1", "Part", { Position = vec(-4000, 20, -3000) }))
    end
end
local function callsOf(what)
    local out = {}
    for _, c in ipairs(CALLS) do if c[1] == what then table.insert(out, c) end end
    return out
end

CFG.RaidLoop = true
RD.overAt = CLOCK
reset()
raidStep()
check("loop: the first 5 s after the raid - staying, nothing bought", #CALLS == 0 and #FLIGHTS == 0)
CLOCK += 6
reset()
startsRaid()
raidStep()
local loads, selects = callsOf("LoadFruit"), callsOf("RaidsNpc")
check("loop: the CHEAPEST stored fruit loaded (Rocket, never Kitsune), then a Flame chip",
    #loads == 1 and loads[1][2] == "Rocket-Rocket" and #selects == 1 and selects[1][2] == "Select" and selects[1][3] == "Flame"
    and said("a Flame chip - paid with Rocket-Rocket ($5000"), loads[1] and loads[1][2])
check("...the button: flown to, clicked, the raid on", CLICKS == 1 and vnear(FLIGHTS[#FLIGHTS], main.Position + vec(0, 4, 0))
    and said("the raid started") and RD.loop.note == "raid started", tostring(RD.loop.note))
reset()
raidStep()
check("...the next step: in the raid again (Island 1)", RD.inside and said("Island 1"))

-- The raid over again; this time a Kitsune Fruit sits in your backpack: nothing traded.
TIMER.Visible = false
LOCS:remove("Island 1")
reset()
raidStep()
CLOCK += 6
BP:add(inst("Kitsune Fruit", "Tool"))
reset()
raidStep()
check("a dear fruit in your backpack: nothing loaded, nothing traded, said why - you stay",
    #callsOf("LoadFruit") == 0 and #callsOf("RaidsNpc") == 0 and #FLIGHTS == 0 and CLICKS == 1
    and string.find(tostring(RD.loop.note), "Kitsune Fruit is in your backpack", 1, true) ~= nil, RD.loop.note)
reset()
raidStep()
check("...tried again only after 60 s", #CALLS == 0 and string.find(tostring(P.raidNote), "again in", 1, true) ~= nil, P.raidNote)
BP:remove("Kitsune Fruit")

-- No cheap fruit stored: the $100,000 way - his answer said, you stay.
STORED = { { Name = "Kitsune-Kitsune" } }
CLOCK += 61
reset()
raidStep()
check("no stored fruit under the cap: no load, the chip asked anyway ($100,000 way); refused = said, you stay",
    #callsOf("LoadFruit") == 0 and #callsOf("RaidsNpc") == 1 and #FLIGHTS == 0
    and string.find(tostring(RD.loop.note), "once every 2 hours", 1, true) ~= nil, RD.loop.note)

-- getInventoryFruits empty: the game's item list (PhysicalFruit 1411 = Spin).
STORED = {}
NET["RF/GetAllItemValues"] = { InvokeServer = function()
    return { { Key = "Quantity", ItemId = 1411, Value = 2 }, { Key = "Quantity", ItemId = 1423, Value = 1 },
        { Key = "Mastery", ItemId = 1390, Value = 50 } }
end }
PR["Spin-Spin"] = 7500
SERVER.GetFruits = function()
    return { { Name = "Spin-Spin", Price = 7500 }, { Name = "Kitsune-Kitsune", Price = 8000000 } }
end
CLOCK += 61
reset()
startsRaid()
raidStep()
loads = callsOf("LoadFruit")
check("the hubs' list empty: the game's item list read - Spin loaded (never Kitsune), chip, raid",
    #loads == 1 and loads[1][2] == "Spin-Spin" and CLICKS == 2 and said("from the game's item list"), loads[1] and loads[1][2])
TIMER.Visible = false
LOCS:remove("Island 1")
reset()
raidStep()

-- The button pressed, no raid in 20 s: again in 10 s; the third time 2 min. You stay.
BP:add(inst("Special Microchip", "Tool"))
CLOCK += 6
reset()
raidStep()
check("pressed, no raid in 20 s: said, again in 10 s", CLICKS == 3 and RD.loop.tries == 1
    and string.find(tostring(RD.loop.note), "no raid in 20 s", 1, true) ~= nil, RD.loop.note)
CLOCK += 11
reset()
raidStep()
CLOCK += 11
reset()
raidStep()
check("...the third: again only in 2 min", RD.loop.tries == 3 and RD.loop.nextAt - CLOCK > 100, RD.loop.nextAt - CLOCK)

-- No fireclickdetector: press it yourself.
local keepFire = fireclickdetector
fireclickdetector = nil
RD.loop.nextAt, RD.loop.tries = 0, 0
reset()
raidStep()
check("no fireclickdetector: said - press the button yourself", string.find(tostring(RD.loop.note),
    "press the raid button yourself", 1, true) ~= nil, RD.loop.note)
fireclickdetector = keepFire

-- The button not streamed in (Third Sea): flown to the castle's button spot first.
MAP:remove("Boat Castle")
RD.loop.nextAt = 0
ROOT.Position = vec(-9000, 300, 0)
reset()
raidStep()
check("button not loaded: flown to the castle's raid button spot, said it did not load",
    vnear(FLIGHTS[1], vec(-5036, 315, -3179)) and string.find(tostring(RD.loop.note), "did not load", 1, true) ~= nil,
    vs(FLIGHTS[1]) .. " " .. tostring(RD.loop.note))
BP:remove("Special Microchip")

-- Under level 1100: the loop goes off.
SELECT_ANSWER = 0
STORED = { { Name = "Spin-Spin" } }
RD.loop.nextAt = 0
reset()
raidStep()
check("level under 1100 (0): the loop off, said", CFG.RaidLoop == false
    and string.find(tostring(RD.loop.note), "level 1100", 1, true) ~= nil, RD.loop.note)
SELECT_ANSWER = nil

realPrint(all and "ALL PASS" or "SOME FAILED")
