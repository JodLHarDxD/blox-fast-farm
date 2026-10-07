
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function printed(s)
    for _, l in ipairs(PRINTED) do if string.find(l, s, 1, true) then return true end end
    return false
end
local function has(str, s) return type(str) == "string" and string.find(str, s, 1, true) ~= nil end
local function near(a, b, tol) return a ~= nil and b ~= nil and math.abs(a - b) <= (tol or 1e-6) end
local N
local function fresh(o) reset(o) SECTION() N = P.news return N end
local function items() return N.headlines(CLOCK) end
local function item(key)
    for i, it in ipairs(items()) do if it.key == key then return it, i end end
    return nil
end
-- t real seconds pass; the game clock runs `rate` game hours a real second
-- (default: a game hour a minute)
local function pass(t, rate)
    CLOCK += t
    LIGHT.ClockTime = (LIGHT.ClockTime + t * (rate or 1 / 60)) % 24
end
local function S(s)
    return string.format("night=%s no=%s full=%s nights=%s toFull=%s edge=%s", tostring(s.night), tostring(s.no),
        tostring(s.full), tostring(s.nights), tostring(s.toFull), tostring(s.edge))
end

-- ---------------------------------------------------------------- THE MOON, AS THE SERVER SAYS IT
fresh()
LIGHT.attrs.MoonPhase = 3
local p, blue, src = N.moonRead()
check("moon: the server's attribute MoonPhase = 3 is read as 3", p == 3 and blue == false and src == "server",
    tostring(p) .. " " .. tostring(src))
LIGHT.attrs.MoonPhase = 9
decal("9709149431")
p, blue, src = N.moonRead()
check("moon: an attribute outside 1-8 -> the decal (moon5 = full)", p == 5 and src == "decal",
    tostring(p) .. " " .. tostring(src))
LIGHT.attrs.MoonPhase = 4.5
decal("9709150401")
p = N.moonRead()
check("moon: a fractional attribute is not a phase -> the decal (moon8)", p == 8, p)
LIGHT.attrs.MoonPhase = nil
SKY = { Name = "Sky", MoonTextureId = "rbxassetid://9709149052" }
p = N.moonRead()
check("moon: the rbxassetid:// form of moon4", p == 4, p)
decal("15493317929")
p, blue = N.moonRead()
check("moon: the blue moon decal = full + blue", p == 5 and blue == true, tostring(p) .. " " .. tostring(blue))
decal("9709139597", "FantasySky")
p = N.moonRead()
check("moon: Seas 1-2 keep it in Lighting.FantasySky (moon2)", p == 2, p)
SKY = nil
p, blue, src = N.moonRead()
check("moon: nothing readable -> nil, and says why", p == nil and src == "nothing", src)
LIGHT.attrs.MoonPhase = 5
LIGHT.attrs.IsBlueMoon = true
p, blue = N.moonRead()
check("moon: the IsBlueMoon attribute", p == 5 and blue == true)

-- ---------------------------------------------------------------- DAY / NIGHT NUMBER AND THE FULL MOON
fresh()
local s = N.skyAt(20, 3)
check("20:00, phase 3: NIGHT 3, full moon in 2 nights", s.night and s.no == 3 and s.nights == 2 and not s.full, S(s))
check("20:00, phase 3: dawn in 9 min, full moon rises in 46 min (1 game hour a minute)",
    near(s.edge, 540) and near(s.toFull, 2760), S(s))
s = N.skyAt(2, 4)
check("02:00, phase 4: NIGHT 4, full moon NEXT NIGHT in 16 min, dawn in 3 min",
    s.night and s.no == 4 and s.nights == 1 and near(s.toFull, 960) and near(s.edge, 180), S(s))
s = N.skyAt(8, 4)
check("08:00, phase 4 (before the noon turn): DAY 5, full moon TONIGHT in 10 min",
    not s.night and s.no == 5 and s.nights == 0 and near(s.toFull, 600), S(s))
s = N.skyAt(14, 4)
check("14:00, phase 4 (turned at noon): DAY 4, full moon next night in 28 min",
    s.no == 4 and s.nights == 1 and near(s.toFull, 1680), S(s))
s = N.skyAt(14, 5)
check("14:00, phase 5: DAY 5, FULL MOON TONIGHT in 4 min", s.no == 5 and s.nights == 0 and near(s.toFull, 240), S(s))
s = N.skyAt(19, 5)
check("19:00, phase 5: the FULL MOON is up, 10 min left", s.full and s.nights == 0 and s.toFull == 0
    and near(s.edge, 600), S(s))
s = N.skyAt(4.5, 5)
check("04:30, phase 5: still the full moon, 30 s left", s.full and near(s.edge, 30), S(s))
s = N.skyAt(6, 5)
check("06:00, phase 5 (the morning after): DAY 6, the next full moon in 7 nights = 3 h",
    not s.full and s.no == 6 and s.nights == 7 and near(s.toFull, 10800), S(s))
s = N.skyAt(11, nil)
check("no phase readable: still day or night and the time to dusk", not s.night and s.no == nil
    and near(s.edge, 420), S(s))
s = N.skyAt(18, 3)
check("18:00 exactly is night (11 game hours to dawn)", s.night and near(s.edge, 660), S(s))
s = N.skyAt(5, 3)
check("05:00 exactly is day (13 game hours to dusk)", not s.night and near(s.edge, 780), S(s))

-- the measured speeds, day and night apart
N.cal.rateDay, N.cal.rateNight = 1 / 30, 1 / 60
s = N.skyAt(17, 5)
check("day at 2 game hours a minute: FULL MOON TONIGHT in 30 s", near(s.toFull, 30), S(s))
s = N.skyAt(20, 4)
check("20:00 -> the next dusk: 9 night hours (540 s) + 13 day hours (390 s)", near(s.toFull, 930), S(s))
N.cal.rateDay, N.cal.rateNight = nil, 1 / 120
s = N.skyAt(10, 3)
check("only the night measured: the day uses it too", near(s.edge, 8 * 120), S(s))

-- what was learned: the order the moon turns in, the hour it turns
fresh()
N.cal.succ = { [7] = 2, [2] = 1, [1] = 8, [8] = 3 }
s = N.skyAt(20, 8)
check("learned order 8 -> 3 -> 4 -> 5: NIGHT 8 = full moon in 3 nights", s.nights == 3, S(s))
N.cal.succ = { [1] = 2, [2] = 1 }
s = N.skyAt(20, 1)
check("an order that never reaches 5: no count, no crash", s.nights == nil and s.toFull == nil, S(s))
s.blue, s.src = false, "server"
N.sky = s
local okH, list0 = pcall(function() return N.headlines(CLOCK) end)
check("... and the headline says the order is not known", okH and has(list0[1].body, "order not known"),
    okH and list0[1].body or list0)
N.cal.succ = {}
N.cal.flipAt = 18
s = N.skyAt(14, 4)
check("learned: the phase turns at 18:00 -> at 14:00 phase 4 is last night's: DAY 5, full tonight",
    s.no == 5 and s.nights == 0, S(s))

-- ---------------------------------------------------------------- THE CLOCK'S SPEED, MEASURED
fresh({ at = 10 })
LIGHT.attrs.MoonPhase = 3
N.tick()
for _ = 1, 3 do pass(20) N.tick() end
check("speed measured by day: a game hour a minute", near(N.cal.rateDay, 1 / 60, 1e-9) and N.cal.rateNight == nil,
    tostring(N.cal.rateDay))
check("... said in the console", printed("1.00 game hours a minute by day"), PRINTED[#PRINTED])
check("... and saved for the next server", FILES["bff_sky.json"] ~= nil)
for _ = 1, 6 do pass(20, 1 / 30) N.tick() end
check("the speed follows a change (2 h a minute now)", N.cal.rateDay > 1 / 40 and N.cal.rateDay <= 1 / 30 + 1e-9,
    tostring(N.cal.rateDay))

fresh({ at = 23.9 })
LIGHT.attrs.MoonPhase = 3
N.tick()
pass(20)
N.tick()
check("across midnight (23:54 -> 00:14): counted, as the night's", near(N.cal.rateNight, 1 / 60, 1e-9)
    and N.cal.rateDay == nil, tostring(N.cal.rateNight) .. " " .. tostring(N.cal.rateDay))

fresh({ at = 10 })
N.tick()
CLOCK += 20
LIGHT.ClockTime = 15
N.tick()
check("a jump (5 game hours in 20 s) is not a speed", N.cal.rateDay == nil, tostring(N.cal.rateDay))
CLOCK += 20
N.tick()
check("a clock standing still is not a speed", N.cal.rateDay == nil)
CLOCK += 300
LIGHT.ClockTime = 15.5
N.tick()
check("a 5-min gap (loading) is not a speed", N.cal.rateDay == nil)
pass(5)
N.tick()
check("under 20 s is not a sample yet", N.cal.rateDay == nil)

-- ---------------------------------------------------------------- THE TURN OF THE MOON, LEARNED
fresh({ at = 11.9 })
LIGHT.attrs.MoonPhase = 4
N.tick()
pass(8)
LIGHT.attrs.MoonPhase = 5
N.tick()
check("the turn is learned: 4 -> 5 at 12:02 -> turns at 12.0", N.cal.succ[4] == 5 and near(N.cal.flipAt, 12.0)
    and N.cal.flips == 1, tostring(N.cal.flipAt))
check("... printed with the clock it came at", printed("the moon turned 4 -> 5 at 12:02"), PRINTED[#PRINTED])
pass(30)
LIGHT.attrs.MoonPhase = 2
N.tick()
check("a turn out of order (5 -> 2) is learned and flagged", N.cal.succ[5] == 2 and printed("(not the next number)"))

fresh({ at = 0.5 })
LIGHT.attrs.MoonPhase = 3
N.tick()
pass(5)
LIGHT.attrs.MoonPhase = 4
N.tick()
check("a turn at night does not move the turn hour, and says so", N.cal.flipAt == 12
    and printed("(at night: night numbers may be off)"), tostring(N.cal.flipAt))

-- ---------------------------------------------------------------- bff_sky.json
fresh({ at = 11.9 })
LIGHT.attrs.MoonPhase = 4
N.tick()
pass(8)
LIGHT.attrs.MoonPhase = 5
N.tick()
N.cal.rateDay = 1 / 50
N.save()
fresh({ keepFiles = true })
check("read at load: the turn hour, the order, the speed", near(N.cal.flipAt, 12.0) and N.cal.succ[4] == 5
    and near(N.cal.rateDay, 1 / 50) and N.cal.flips == 1)
FILES["bff_sky.json"] = "garbage"
fresh({ keepFiles = true })
check("a broken file: the defaults, no error", N.cal.flipAt == 12 and next(N.cal.succ) == nil and N.cal.rateDay == nil)
FILES["bff_sky.json"] = HttpService:JSONEncode({ rateDay = 5, rateNight = -1, flipAt = 23,
    succ = { ["9"] = 1, ["3"] = 3, ["2"] = 3 } })
fresh({ keepFiles = true })
check("nonsense in the file is dropped (speed 5, turn at 23:00, phase 9, 3 -> 3); 2 -> 3 kept",
    N.cal.rateDay == nil and N.cal.rateNight == nil and N.cal.flipAt == 12 and N.cal.succ[9] == nil
    and N.cal.succ[3] == nil and N.cal.succ[2] == 3)
writefile, readfile = nil, nil
local okNoFile = pcall(function()
    fresh()
    N.save()
end)
check("an executor without file calls: no error", okNoFile)
writefile = function(name, s) FILES[name] = s end
readfile = function(name)
    local x = FILES[name]
    if x == nil then error("file not found") end
    return x
end

-- ---------------------------------------------------------------- ISLANDS
fresh()
LIGHT.attrs.MoonPhase = 3
MAP.kids.MysticIsland = inst("MysticIsland", "Model", { attrs = { SpawnedAt = 123 },
    pos = Vector3.new(3000, 0, 4000) })
N.tick()
local st = N.isles.mirage
check("Mirage up at the join: up, its age unknown", st.up and st.atJoin)
local it = item("mirage")
check("headline: MIRAGE ISLAND UP · already up when you joined · lives 15 min at most · 5000 studs away",
    it and it.title == "MIRAGE ISLAND UP" and has(it.body, "already up when you joined")
    and has(it.body, "lives 15 min at most") and has(it.body, "5000 studs away"), it and it.body)
check("up at the join is breaking news too", it and it.breaking and printed("MIRAGE ISLAND IS UP"))
check("its attributes are printed once (a spawn time may be there)", printed("SpawnedAt=123"))
MAP.kids.MysticIsland = nil
pass(30)
N.tick()
it = item("mirage")
check("Mirage gone: GONE, no 'after' (its start was not seen)", it and it.title == "MIRAGE ISLAND GONE"
    and not has(it.body, "after"), it and (it.title .. " / " .. it.body))
pass(301)
N.tick()
it = item("mirage")
check("5 min later: NO MIRAGE ISLAND", it and it.title == "NO MIRAGE ISLAND", it and it.title)
LOCS.kids["Mirage Island"] = inst("Mirage Island", "Part", { pos = Vector3.new(0, 0, 100) })
N.tick()
check("Mirage SPAWNED while you are here (the Locations part)", printed("MIRAGE ISLAND SPAWNED")
    and not N.isles.mirage.atJoin)
pass(120)
N.tick()
it = item("mirage")
check("2 min later: came 2 min ago · gone within 13 min · 100 studs away", has(it.body, "came 2 min ago")
    and has(it.body, "gone within 13 min") and has(it.body, "100 studs away"), it.body)
check("the distance is said to be the island's MIDDLE (user read it as the dealer's)",
    has(it.body, "its middle 100 studs away") and not has(it.body, "Advanced Fruit Dealer 1"), it.body)
-- The dealer read by the sea hunt's finder: his own distance in the strip.
P.sea = { findDealer = function() return { cf = { Position = Vector3.new(0, 0, 400) } } end }
N.tick()
it = item("mirage")
check("dealer held by the client: 'Advanced Fruit Dealer 400 studs away' of his own",
    has(it.body, "Advanced Fruit Dealer 400 studs away"), it.body)
P.sea = nil
pass(14 * 60)
N.tick()
it = item("mirage")
check("past 15 min: says so, never a negative time", has(it.body, "up longer than 15 min"), it.body)
LOCS.kids["Mirage Island"] = nil
N.tick()
it = item("mirage")
check("gone after a life it saw start: 'after 16 min'", has(it.body, "after 16 min"), it.body)

fresh()
N.tick()
it = item("prehistoric")
check("no Prehistoric Island: said, every lap", it and it.title == "NO PREHISTORIC ISLAND")
WS_KIDS.PrehistoricIsland = inst("PrehistoricIsland", "Model")
pass(5)
N.tick()
check("Prehistoric at workspace's top level is found too", N.isles.prehistoric.up)
check("Prehistoric has no clock: no 'gone within'", not has(item("prehistoric").body, "gone within"),
    item("prehistoric").body)

fresh({ at = 10 })
LIGHT.attrs.MoonPhase = 3
N.tick()
check("no Kitsune, no full moon near: not in the news", item("kitsune") == nil)
fresh({ at = 20 })
LIGHT.attrs.MoonPhase = 5
N.tick()
it = item("kitsune")
check("full moon up, no Kitsune: the hint (Sea Danger 6)", it and has(it.body, "Sea Danger 6"), it and it.body)
MAP.kids.KitsuneIsland = inst("KitsuneIsland", "Model")
pass(5)
N.tick()
check("Kitsune up", item("kitsune") and item("kitsune").title == "KITSUNE ISLAND UP")

fresh()
LOCS.kids["Frozen Dimension"] = inst("Frozen Dimension", "Part")
N.tick()
check("the Frozen Dimension, through Locations", item("frozen") and item("frozen").title == "FROZEN DIMENSION UP")

fresh({ sea = 2 })
MAP.kids.MysticIsland = inst("MysticIsland", "Model")
LIGHT.attrs.MoonPhase = 3
N.tick()
check("Second Sea: no islands, no elites; the moon still", item("mirage") == nil and item("elite") == nil
    and item("moon") ~= nil)

-- ---------------------------------------------------------------- BOSSES
fresh()
BOSSES.Deandre = { pos = Vector3.new(1, 1, 1), where = "parked" }
N.tick()
it = item("boss:Deandre")
check("an elite parked far off: ELITE UP · Deandre, far off", it and it.title == "ELITE UP"
    and has(it.body, "Deandre, far off"), it and it.body)
check("... breaking, once", printed("DEANDRE IS UP"))
local before = #PRINTED
pass(1)
N.tick()
check("the next look: no second breaking", #PRINTED == before, PRINTED[#PRINTED])
BOSSES.Deandre = nil
pass(1)
N.tick()
check("the elite gone: NO ELITE", item("elite") and item("elite").title == "NO ELITE")
BOSSES["Dough King"] = { pos = Vector3.new(0, 0, 0), where = "here" }
pass(1)
N.tick()
check("Dough King near you", item("boss:Dough King") and has(item("boss:Dough King").body, "near you"))

fresh()
CAKE_ANSWER = "Defeat 324 more Cake Island enemies to summon the Cake Prince."
N.tick()
check("the strip not on screen: Cake Prince is never asked", CAKE_CALLS == 0)
N.shown = { Parent = {} }
pass(1)
N.tick()
check("on screen: asked once, 324 kills to go", CAKE_CALLS == 1 and item("cake")
    and has(item("cake").body, "324 kills to go"), CAKE_CALLS)
pass(30)
N.tick()
check("asked at most once a minute", CAKE_CALLS == 1)
pass(31)
CAKE_ANSWER = "Do you want to open the portal now?"
N.tick()
check("ready: the portal can open", CAKE_CALLS == 2 and has(item("cake").body, "ready"))
N.shown = { Parent = nil }
pass(61)
N.tick()
check("the panel closed: not asked", CAKE_CALLS == 2)
check("an answer with no number and no portal: nothing shown", N.cakeNote("hmm") == nil and N.cakeNote(nil) == nil)

-- ---------------------------------------------------------------- FRUIT ON THE MAP
fresh()
local fr = inst("Rocket Fruit", "Tool", { attrs = { OriginalName = "Rocket-Rocket" } })
fr.kids.Handle = inst("Handle", "Part")
WS_KIDS["Rocket Fruit"] = fr
N.tick()
check("a fruit lying on the map: breaking, and named", printed("FRUIT ON THE MAP: Rocket Fruit") and item("fruit")
    and has(item("fruit").body, "Rocket Fruit"))
local sword = inst("Sword", "Tool")
sword.kids.Handle = inst("Handle", "Part")
WS_KIDS.Sword = sword
pass(1)
N.tick()
check("a tool that is no fruit (no OriginalName): ignored", #N.fruits == 1, #N.fruits)

-- ---------------------------------------------------------------- THE ORDER, AND BREAKING
fresh({ at = 10 })
LIGHT.attrs.MoonPhase = 3
N.tick()
pass(61)
N.tick()
local keys = {}
for _, x in ipairs(items()) do table.insert(keys, x.key) end
check("order: moon, mirage, prehistoric, elite, server", table.concat(keys, ",") == "moon,mirage,prehistoric,elite,server",
    table.concat(keys, ","))
it = item("moon")
-- 61 s after 10:00 = 11:01: dusk 6.98 h away, the full moon 30.98 h
check("moon headline by day (11:01): DAY 4/8 · tonight gibbous · night in 7 min · full moon NEXT NIGHT, in 31 min",
    it.title == "DAY 4/8" and has(it.body, "tonight gibbous") and has(it.body, "night in 7 min")
    and has(it.body, "full moon NEXT NIGHT, in 31 min"), it.title .. " / " .. it.body)
it = item("server")
check("server line: players, and how long you have been here", has(it.body, "7/12 players")
    and has(it.body, "you joined 10 min ago"), it.body)
MAP.kids.MysticIsland = inst("MysticIsland", "Model")
pass(1)
N.tick()
local list = items()
check("a Mirage just spawned leads, marked BREAKING", list[1].key == "mirage" and list[1].breaking, list[1].key)
check("the chip says BREAKING for 8 s", N.chip(CLOCK) == "BREAKING")
pass(9)
N.tick()
check("after 8 s the chip is the clock again", N.chip(CLOCK) ~= "BREAKING", N.chip(CLOCK))
pass(52)
N.tick()
list = items()
check("after a minute it is back in its place, no BREAKING", list[2].key == "mirage" and not list[2].breaking,
    list[2].key)

fresh({ at = 17.9 })
LIGHT.attrs.MoonPhase = 5
N.tick()
check("17:54, phase 5: no full moon yet, no breaking", not printed("FULL MOON"))
pass(10)
N.tick()
check("18:04: FULL MOON RISING", printed("FULL MOON RISING"))
it = item("moon")
check("moon headline: FULL MOON · night 5/8 · race trials, Kitsune", it.title == "FULL MOON"
    and has(it.body, "night 5/8") and has(it.body, "race trials") and it.breaking, it.title .. " / " .. it.body)

fresh({ at = 20 })
LIGHT.attrs.MoonPhase = 5
N.tick()
check("joined during a full moon: FULL MOON IS UP", printed("FULL MOON IS UP"))

fresh({ at = 10 })
N.tick()
it = item("moon")
check("no moon readable: DAY, and says the phase is not readable", it.title == "DAY" and has(it.body, "not readable"),
    it.title .. " / " .. it.body)

-- ---------------------------------------------------------------- THE CHIP
fresh({ at = 10 })
LIGHT.attrs.MoonPhase = 3
N.tick()
local w, t, tone = N.chip(CLOCK)
check("chip by day: DAY 4 (phase 3 before noon), 8:00 to dusk", w == "DAY 4" and t == "8:00" and tone == "day",
    tostring(w) .. " " .. tostring(t) .. " " .. tostring(tone))
fresh({ at = 20 })
LIGHT.attrs.MoonPhase = 3
N.tick()
w, t, tone = N.chip(CLOCK)
check("chip by night: NIGHT 3, 9:00 to dawn", w == "NIGHT 3" and t == "9:00" and tone == "night",
    tostring(w) .. " " .. tostring(t) .. " " .. tostring(tone))
fresh({ at = 19 })
LIGHT.attrs.MoonPhase = 5
N.tick()
pass(9)
N.tick()
w, t, tone = N.chip(CLOCK)
check("chip in the full moon: FULL MOON, 9:51 left", w == "FULL MOON" and t == "9:51" and tone == "full",
    tostring(w) .. " " .. tostring(t) .. " " .. tostring(tone))
LIGHT.attrs.IsBlueMoon = true
pass(9)
N.tick()
pass(9)
N.tick()
w = N.chip(CLOCK)
check("chip in the blue moon: BLUE MOON", w == "BLUE MOON", w)
fresh({ at = 15 })
LIGHT.attrs.MoonPhase = 5
N.tick()
w, t, tone = N.chip(CLOCK)
check("chip on the day of a full moon: FULL IN 3:00", w == "FULL IN" and t == "3:00" and tone == "full",
    tostring(w) .. " " .. tostring(t) .. " " .. tostring(tone))
fresh()
w = N.chip(CLOCK)
check("chip before the first look: SKY", w == "SKY", w)

-- ---------------------------------------------------------------- FORMATS
check("dur: m:ss, then h mm", N.dur(59.6) == "1:00" and N.dur(3725) == "1h 02m" and N.dur(-5) == "0:00",
    N.dur(59.6) .. " " .. N.dur(3725) .. " " .. N.dur(-5))
check("mins: whole minutes for the crawl", N.mins(29) == "under a minute" and N.mins(90) == "2 min"
    and N.mins(3720) == "1 h 02 min", N.mins(29) .. " / " .. N.mins(90) .. " / " .. N.mins(3720))
check("clockText", N.clockText(12.0333) == "12:02" and N.clockText(23.999) == "00:00",
    N.clockText(12.0333) .. " " .. N.clockText(23.999))

realPrint(all and "ALL PASS" or "SOME FAILED")
