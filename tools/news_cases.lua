
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
-- ONLY THE FRUITS YOU CARE ABOUT, DEAREST FIRST (user, 2026-11-08: "the
-- important fruits I wanna know before, and the unimportant fruits I don't
-- even need to know"; Eagle, Flame, Rocket, Rubber said, a T-Rex spawn lost).
local function lying(name, orig, o)
    o = o or {}
    local f = inst(name, o.class or "Tool", { attrs = { OriginalName = orig, DroppedBy = o.by } })
    f.kids.Handle = inst("Handle", "Part", { pos = o.pos })
    WS_KIDS[o.key or name] = f
    return f
end
local function said()
    local t = {}
    for _, f in ipairs(N.fruits) do table.insert(t, P.fruitNewsWords(f)) end
    return table.concat(t, " | ")
end
fresh()
local fr = lying("Rocket Fruit", "Rocket-Rocket", { by = "someone" })
N.tick()
check("a cheap fruit lying (Rocket, 5K, dropped): no breaking, not named, 'NO FRUIT WORTH IT'",
    not printed("FRUIT ON THE MAP") and #N.fruits == 0 and item("fruit").title == "NO FRUIT WORTH IT"
    and item("fruit").tone == "dim" and not has(item("fruit").body, "Rocket"), item("fruit").title)
local sword = inst("Sword", "Tool")
sword.kids.Handle = inst("Handle", "Part")
WS_KIDS.Sword = sword
pass(1)
N.tick()
check("a tool that is no fruit (no OriginalName): ignored", N.fruitsHidden == 1, N.fruitsHidden)
-- The user's server: 8 junk fruits, a T-Rex spawn among them.
fresh()
for i, n in ipairs({ "Eagle", "Flame", "Rocket", "Rubber", "Sand", "Ice", "Diamond", "Blade" }) do
    lying(n .. " Fruit", n .. "-" .. n, { by = "p" .. i, key = n })
end
lying("T-Rex Fruit", "T-Rex-T-Rex")
N.tick()
check("8 junk fruits and a T-Rex spawn: only the T-Rex, said first and alone", said() == "T-Rex 20M (server spawn)"
    and N.fruitsHidden == 8 and has(item("fruit").body, "T-Rex 20M (server spawn)") and not has(item("fruit").body, "Eagle"), said())
check("...breaking for the T-Rex, never for the junk", printed("FRUIT ON THE MAP: T-Rex 20M (server spawn)")
    and not printed("FRUIT ON THE MAP: Eagle") and not printed("FRUIT ON THE MAP: Rocket"))
pass(61)
N.tick()
check("...the fruits you care about lead the strip, a minute later too (not BREAKING any more)",
    select(2, item("fruit")) == 1 and not item("fruit").breaking and #items() > 3, select(2, item("fruit")))
-- The user's example: dearest first, whatever order they lie in.
fresh()
for _, n in ipairs({ "Dough", "Portal", "Tiger", "Yeti", "Kitsune", "Dragon", "Eagle", "Rubber" }) do lying(n .. " Fruit", n .. "-" .. n) end
N.tick()
check("Dragon, Kitsune, Tiger, Yeti, Dough, Portal - by value; Eagle, Rubber not at all",
    said() == "Dragon 2.97B (server spawn) | Kitsune 570M (server spawn) | Tiger 100M (server spawn) | Yeti 90M (server spawn)"
    .. " | Dough 30M (server spawn) | Portal 10M (server spawn)", said())
check("...the strip names the 3 dearest, +3",
    has(item("fruit").body, "Dragon 2.97B (server spawn) · Kitsune 570M (server spawn) · Tiger 100M (server spawn) +3"),
    item("fruit").body)
-- Your limit and your menu (the hunt's own rules), and the game's price.
fresh()
P.fruitCatalog = { ["T-Rex-T-Rex"] = 2.7e6, ["Buddha-Buddha"] = 1.2e6, ["Spider-Spider"] = 1.5e6, ["Dough-Dough"] = 2.8e6,
    ["Love-Love"] = 1.3e6, ["Portal-Portal"] = 1.9e6 }
CFG.FruitMinPrice = 2.8e6
CFG.FruitMenu = { Spider = "take", Dough = "skip" }
for _, n in ipairs({ "T-Rex", "Buddha", "Spider", "Dough", "Love", "Portal" }) do lying(n .. " Fruit", n .. "-" .. n) end
N.tick()
check("limit 2.8M: T-Rex (2.7M, a Mythical) and Spider (Take) said; Buddha, Love, Portal (under it), Dough (Skip) not",
    said() == "T-Rex 20M (server spawn) | Spider 1.5M (server spawn)" and N.fruitsHidden == 4, said())
CFG.FruitMinPrice = 1.25e6
pass(1)
N.tick()
check("limit 1.25M: Portal (1.9M) and Love (1.3M) join, by value", said()
    == "T-Rex 20M (server spawn) | Portal 10M (server spawn) | Love 1.5M (server spawn) | Spider 1.5M (server spawn)", said())
CFG.FruitMinPrice, CFG.FruitMenu = nil, {}
-- A server spawn before a player's drop of the same worth; one not named yet is said, last.
fresh()
lying("Gravity Fruit", "Gravity-Gravity", { by = "trader" })
lying("Pain Fruit", "Pain-Pain")
lying("Fruit ", nil, { class = "Model" })
N.tick()
check("same worth (10M): the spawn first; a spawn not named yet last",
    said() == "Pain 10M (server spawn) | Gravity 10M (dropped) | a fruit not named yet (server spawn)", said())
-- The same fruit made again by the game (it streams out and back in): news once.
fresh()
lying("Kitsune Fruit", "Kitsune-Kitsune", { pos = Vector3.new(100, 5, 100) })
N.tick()
WS_KIDS["Kitsune Fruit"] = nil
pass(1)
N.tick()
lying("Kitsune Fruit", "Kitsune-Kitsune", { pos = Vector3.new(101, 6, 99) })
pass(1)
N.tick()
local times = 0
for _, l in ipairs(PRINTED) do if string.find(l, "FRUIT ON THE MAP: Kitsune", 1, true) then times += 1 end end
check("the same Kitsune made again (a new instance, same spot): breaking once", times == 1, times)
lying("Kitsune Fruit", "Kitsune-Kitsune", { pos = Vector3.new(900, 5, 100), key = "k2" })
pass(1)
N.tick()
times = 0
for _, l in ipairs(PRINTED) do if string.find(l, "FRUIT ON THE MAP: Kitsune", 1, true) then times += 1 end end
check("...a second Kitsune elsewhere: its own news", times == 2, times)

-- THE GAME'S OWN SPAWNS (2026-10-12: only players' drops were ever seen -
-- the finder asked for a Tool with OriginalName). The public hubs' rule:
-- a Tool OR a Model named "...Fruit..." with a Handle.
check("which fruit, from the name: 'Kitsune Fruit', 'Bird: Falcon Fruit', 'Fruit ' (unknown)",
    P.fruitOrig("Kitsune Fruit") == "Kitsune-Kitsune" and P.fruitOrig("Bird: Falcon Fruit") == "Bird-Bird: Falcon"
    and P.fruitOrig("Human: Buddha Fruit") == "Human-Human: Buddha" and P.fruitOrig("Fruit ") == nil
    and P.fruitOrig("Sword") == nil)
do
    fresh()
    local spawnTool = inst("Dough Fruit", "Tool")                 -- no OriginalName, no DroppedBy
    spawnTool.kids.Handle = inst("Handle", "Part")
    WS_KIDS["Dough Fruit"] = spawnTool
    local spawnModel = inst("Fruit ", "Model")                    -- a Model, its fruit not named
    spawnModel.kids.Handle = inst("Handle", "Part")
    WS_KIDS["Fruit "] = spawnModel
    local wrapped = inst("Ice Fruit", "Model")                     -- a Model holding the Tool
    local inner = inst("Ice Fruit", "Tool")
    inner.kids.Handle = inst("Handle", "Part")
    wrapped.kids["Ice Fruit"] = inner
    WS_KIDS["Ice Fruit"] = wrapped
    local char = inst("FruitLord99", "Model")                      -- a player's character
    char.kids.Handle = inst("Handle", "Part")
    WS_KIDS.FruitLord99 = char
    Players.NAMES.FruitLord99 = {}
    local noHandle = inst("Fruit Crate", "Model")                  -- named a fruit, nothing to touch
    WS_KIDS["Fruit Crate"] = noHandle
    CFG.FruitMenu = { Ice = "take" }                               -- Ice is cheap: shown by Take
    N.tick()
    local list = said()
    check("a SPAWNED Tool with no OriginalName: on the map, a server spawn",
        has(list, "Dough 30M (server spawn)"), list)
    check("a spawned MODEL ('Fruit ', a Handle): on the map", has(list, "a fruit not named yet (server spawn)"), list)
    check("a Model holding the fruit's Tool: on the map", has(list, "Ice 550K (server spawn)"), list)
    check("a player called FruitLord99: never a fruit", not has(list, "FruitLord99"), list)
    check("which fruit a spawn is: read off its name ('Dough-Dough'); 'Fruit ' = unknown (nil)",
        P.groundFruit(spawnTool).orig == "Dough-Dough" and P.groundFruit(spawnModel).orig == nil
        and P.groundFruit(fr).orig == "Rocket-Rocket")
    check("breaking news for a spawn says so", printed("FRUIT ON THE MAP: Dough 30M (server spawn)"))
    check("named a fruit but not read as one: written down once, for the next fix",
        printed("[BFF] fruit seen (SPAWN - not read as a fruit): Name=\"Fruit Crate\""))
    local seen = 0
    for _, s in ipairs(PRINTED) do if string.find(s, "Fruit Crate", 1, true) then seen += 1 end end
    N.tick()
    local seen2 = 0
    for _, s in ipairs(PRINTED) do if string.find(s, "Fruit Crate", 1, true) then seen2 += 1 end end
    check("...once per shape, not every second", seen == 1 and seen2 == 1, seen .. " " .. seen2)
    check("every shape seen goes to workspace/bff_fruit_seen.txt",
        FILES["bff_fruit_seen.txt"] ~= nil and has(FILES["bff_fruit_seen.txt"], "Dough Fruit"))
    Players.NAMES.FruitLord99 = nil
    WS_KIDS["Dough Fruit"], WS_KIDS["Fruit "], WS_KIDS["Ice Fruit"], WS_KIDS.FruitLord99, WS_KIDS["Fruit Crate"] = nil, nil, nil, nil, nil
end

-- ---------------------------------------------------------------- WHICH FRUIT A SPAWN IS, AND WHERE
-- (2026-10-24: a spawn is Model "Fruit ", no attributes, children Fruit /
-- FruitAnimator / Handle - its name is its look.)
local function spawnOf(kids, pos)
    local s = inst("Fruit ", "Model")
    s.kids.Handle = inst("Handle", "Part", { pos = pos })
    s.kids.FruitAnimator = inst("FruitAnimator", "Script")
    local fm = inst("Fruit", "Model")
    for _, k in ipairs(kids) do fm.kids[k.Name] = k end
    s.kids.Fruit = fm
    return s
end
local function dropOf(orig, kids)
    local base = P.fruitBase(orig)
    local d = inst(base .. " Fruit", "Tool", { attrs = { OriginalName = orig, DroppedBy = "someone" } })
    d.kids.Handle = inst("Handle", "Part")
    local fm = inst("Fruit", "Model")
    for _, k in ipairs(kids) do fm.kids[k.Name] = k end
    d.kids.Fruit = fm
    return d
end
check("fruit base names: Kitsune-Kitsune, Bird-Bird: Falcon, T-Rex-T-Rex",
    P.fruitBase("Kitsune-Kitsune") == "Kitsune" and P.fruitBase("Bird-Bird: Falcon") == "Falcon"
    and P.fruitBase("T-Rex-T-Rex") == "T-Rex")
check("mesh names: 'Meshes/dragon_12' -> dragon, 'Meshes/magu_34' -> magma, 'Meshes/fruit_2' / 'Handle' -> nothing",
    P.meshToken("Meshes/dragon_12") == "dragon" and P.meshToken("Meshes/magu_34") == "magma"
    and P.meshToken("Meshes/fruit_2") == nil and P.meshToken("Handle") == nil and P.meshToken("Meshes/smouke") == "smoke")
local CAT = { ["Dragon-Dragon"] = 15000000, ["T-Rex-T-Rex"] = 2700000, ["Lightning-Lightning"] = 2100000, ["Spin-Spin"] = 7500 }
check("a mesh name -> the game's name from the price list (t-rex, an old name 'rumble')",
    P.fruitOfToken("dragon", CAT) == "Dragon-Dragon" and P.fruitOfToken("trex", CAT) == "T-Rex-T-Rex"
    and P.fruitOfToken("rumble", CAT) == "Lightning-Lightning")
check("...a name the list does not have: nil; no list yet: the usual X-X",
    P.fruitOfToken("banana", CAT) == nil and P.fruitOfToken("dragon", {}) == "Dragon-Dragon")
do
    fresh()
    P.fruitCatalog = CAT
    local s = spawnOf({ inst("Meshes/dragon_12", "MeshPart", { mesh = 111, tex = 222 }) }, Vector3.new(5600, 1000, -300))
    local g = P.groundFruit(s)
    check("a spawn with a mesh named after its fruit: read as it, shown as 'Dragon Fruit'",
        g.orig == "Dragon-Dragon" and g.how == "mesh name" and g.name == "Dragon Fruit", tostring(g.orig) .. " " .. tostring(g.name))
    local plain = spawnOf({ inst("FruitMesh", "MeshPart", { mesh = 501, tex = 502 }) })
    check("a spawn whose mesh says nothing, its look never seen: unknown, its look kept for learning",
        P.groundFruit(plain).orig == nil and #P.groundFruit(plain).looks == 2)
    -- A player's drop of the same fruit teaches the look.
    WS_KIDS["Spin Fruit"] = dropOf("Spin-Spin", { inst("FruitMesh", "MeshPart", { mesh = 501, tex = 502 }) })
    N.tick()
    local g2 = P.groundFruit(plain)
    check("...a player's drop with the same look teaches it: the spawn is now Spin, 'look learned'",
        g2.orig == "Spin-Spin" and g2.how == "look learned" and g2.name == "Spin Fruit", tostring(g2.orig))
    check("...the look is written to workspace/bff_fruit_looks.json", FILES["bff_fruit_looks.json"] ~= nil)
    fresh({ keepFiles = true })
    check("...and read back in the next server", P.groundFruit(plain).orig == "Spin-Spin")
    -- A glow both fruits share names neither; a new fruit with one unseen mesh is not named.
    local store = {}
    P.looksLearn(store, { "m1", "t9" }, "Spin-Spin")
    P.looksLearn(store, { "m2", "t9" }, "Kitsune-Kitsune")
    check("a look two fruits share (t9) names neither, each own mesh still names its fruit",
        store.t9 == false and P.looksName(store, { "m1", "t9" }) == "Spin-Spin" and P.looksName(store, { "m2", "t9" }) == "Kitsune-Kitsune")
    check("a key never seen = not named (a new fruit with a known glow is not taken for another)",
        P.looksName(store, { "m3", "t9" }) == nil and P.looksName(store, { "m1", "m2" }) == nil and P.looksName(store, {}) == nil)
    WS_KIDS["Spin Fruit"] = nil
end
do
    fresh()
    LOCS.kids["Hydra Island"] = inst("Hydra Island", "Part", { pos = Vector3.new(5228, 600, 345) })
    LOCS.kids["Castle on the Sea"] = inst("Castle on the Sea", "Part", { pos = Vector3.new(-5000, 300, -3000) })
    LOCS.kids["Island 1"] = inst("Island 1", "Part", { pos = Vector3.new(5600, 0, -300) })
    check("where: the nearest place the game names (a raid's 'Island 1' is no place)",
        P.isleOf(Vector3.new(5600, 1000, -300)) == "Hydra Island", tostring(P.isleOf(Vector3.new(5600, 1000, -300))))
    check("...far from every place: at sea, how far from the nearest",
        P.isleOf(Vector3.new(0, 0, 6000)) == "at sea, 7.7k from Hydra Island", tostring(P.isleOf(Vector3.new(0, 0, 6000))))
    P.fruitCatalog = CAT
    WS_KIDS["Fruit "] = spawnOf({ inst("Meshes/dragon_12", "MeshPart", { mesh = 111 }) }, Vector3.new(5600, 1000, -300))
    N.tick()
    check("the news names the spawn and its island",
        printed("FRUIT ON THE MAP: Dragon 2.97B (server spawn, Hydra Island)"), table.concat(PRINTED, " | "))
    WS_KIDS["Fruit "] = nil
end
check("a spawn's shape log says what is inside its Fruit model (mesh names and ids)",
    printed("inside Fruit: Meshes/dragon_12:MeshPart m=rbxassetid://111"))

-- ---------------------------------------------------------------- THE ORDER, AND BREAKING
fresh({ at = 10 })
LIGHT.attrs.MoonPhase = 3
N.tick()
pass(61)
N.tick()
local keys = {}
for _, x in ipairs(items()) do table.insert(keys, x.key) end
check("order: moon, mirage, prehistoric, elite, fruit, server", table.concat(keys, ",") == "moon,mirage,prehistoric,elite,fruit,server",
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

-- ---------------------------------------------------------------- YOU PICK THE NEWS
-- (user, 2026-11-07: "tick marks which news I wanna know ... If I select one
-- only about fruit, it gonna show only about the fruits.")
local TOPICS = { fruit = { "fruit" }, moon = { "moon" }, mirage = { "mirage" }, prehistoric = { "prehistoric" },
    kitsune = { "kitsune" }, frozen = { "frozen" }, elite = { "boss:Diablo" }, raid = { "boss:Dough King" },
    server = { "server" } }
local function only(...)
    for t in pairs(TOPICS) do CFG.NewsShow[t] = false end
    for _, t in ipairs({ ... }) do CFG.NewsShow[t] = true end
end
local function addFruit()
    local f = inst("Kitsune Fruit", "Tool", { attrs = { OriginalName = "Kitsune-Kitsune" } })
    f.kids.Handle = inst("Handle", "Part")
    WS_KIDS["Kitsune Fruit"] = f
end
-- A server with everything up at once.
local function busy()
    fresh()
    LIGHT.attrs.MoonPhase = 5
    MAP.kids.MysticIsland = inst("MysticIsland", "Model")
    MAP.kids.PrehistoricIsland = inst("PrehistoricIsland", "Model")
    MAP.kids.KitsuneIsland = inst("KitsuneIsland", "Model")
    MAP.kids.FrozenDimension = inst("FrozenDimension", "Model")
    BOSSES.Diablo = { pos = Vector3.new(0, 0, 0), where = "here" }
    BOSSES["Dough King"] = { pos = Vector3.new(0, 0, 0), where = "here" }
    addFruit()
    N.tick()
end
local function keysNow()
    local out = {}
    for _, it in ipairs(items()) do table.insert(out, it.key) end
    return out
end

busy()
check("nothing unticked: all of it, as before", #keysNow() >= 9, table.concat(keysNow(), " "))
for topic, want in pairs(TOPICS) do
    busy()
    only(topic)
    local got = keysNow()
    check("only " .. topic .. " ticked: only that shown", #got == 1 and got[1] == want[1], table.concat(got, " "))
    busy()
    only()
    for t in pairs(TOPICS) do CFG.NewsShow[t] = (t ~= topic) end
    check(topic .. " unticked: gone, the rest stay", item(want[1]) == nil and #keysNow() >= 8, table.concat(keysNow(), " "))
end
busy()
only()
check("nothing ticked: nothing shown", #keysNow() == 0, table.concat(keysNow(), " "))

fresh()
N.tick()
local nf = item("fruit")
check("no fruit on the map: said so (fruit ticked alone must not leave the strip empty)",
    nf and nf.title == "NO FRUIT ON THE MAP" and nf.tone == "dim", nf and nf.title)
fresh({ sea = 2 })
only("fruit")
N.tick()
check("...in the Second Sea too", #keysNow() == 1 and item("fruit").title == "NO FRUIT ON THE MAP", table.concat(keysNow(), " "))
addFruit()
N.tick()
check("...and the moment one lies there, named", has(item("fruit").body, "Kitsune 570M") and item("fruit").title == "FRUIT ON THE MAP")

fresh()
N.cake = { left = 5 }
only("raid")
check("Cake Prince counts as a raid boss", #keysNow() == 1 and keysNow()[1] == "cake", table.concat(keysNow(), " "))
only("elite")
check("'no elite' counts as elites, Cake Prince does not", #keysNow() == 1 and keysNow()[1] == "elite", table.concat(keysNow(), " "))

fresh({ at = 15 })
N.tick()
CLOCK += 100
only("fruit")
local cw, ct, ctone = N.chip(CLOCK)
check("moon unticked: the chip says no day, night or clock", cw == "NEWS" and ct == "" and ctone == "dim",
    tostring(cw) .. " " .. tostring(ct) .. " " .. tostring(ctone))
fresh()
only("fruit")
check("...before the first look too", (N.chip(CLOCK)) == "NEWS")

fresh()
N.tick()
CLOCK += 100
only("fruit")
local wasBreak = N.breakAt
BOSSES.Diablo = { pos = Vector3.new(0, 0, 0), where = "here" }
N.tick()
check("an unticked elite comes: no BREAKING, the crawl does not start over",
    N.breakAt == wasBreak and (N.chip(CLOCK)) ~= "BREAKING", tostring(N.chip(CLOCK)))
check("...still in the console", printed("DIABLO IS UP"))
CFG.NewsShow.elite = true
check("...read all the same: tick it and it is there, marked as just happened",
    item("boss:Diablo") ~= nil and item("boss:Diablo").breaking == true)
CFG.NewsShow.elite = false
CLOCK += 100
addFruit()
N.tick()
check("a ticked fruit comes: BREAKING", N.breakAt == CLOCK and (N.chip(CLOCK)) == "BREAKING", tostring(N.chip(CLOCK)))

-- ---------------------------------------------------------------- THE FRUIT MENU
-- (user, 2026-11-07: a limit, and "except these" both ways - "it's like a menu card".)
do
    fresh()
    check("menu name: a fruit's own, renamed ones, Dragon's kinds",
        P.fruitKey("Buddha-Buddha") == "Buddha" and P.fruitKey("T-Rex-T-Rex") == "T-Rex"
        and P.fruitKey("Rumble-Rumble") == "Lightning" and P.fruitKey("Leopard-Leopard") == "Tiger"
        and P.fruitKey("Bird-Bird: Falcon") == "Eagle" and P.fruitKey("Dragon-Dragon") == "Dragon"
        and P.fruitKey("Dragon (East)-Dragon (East)") == "Dragon",
        tostring(P.fruitKey("Rumble-Rumble")))
    check("menu name: a fruit newer than the list has none", P.fruitKey("Newone-Newone") == nil and P.fruitKey(nil) == nil)
    check("trade values read as before", P.tradeValue("Buddha-Buddha") == 10e6 and P.tradeValue("Rumble-Rumble") == 20e6
        and P.tradeValue("Dragon-Dragon") == 2.97e9 and P.tradeValue("Newone-Newone") == nil and P.tradeValue(nil) == nil)
    CFG.FruitMenu.Buddha, CFG.FruitMenu.Rocket = "take", "skip"
    check("your marks are read by the fruit, whatever its long name",
        P.fruitChoice("Buddha-Buddha") == "take" and P.fruitChoice("Rocket-Rocket") == "skip")
    check("no mark, a new fruit, no name: nothing", P.fruitChoice("Ice-Ice") == nil
        and P.fruitChoice("Newone-Newone") == nil and P.fruitChoice(nil) == nil)

    check("words: over your limit", P.menuWords(3e6, 2.8e6, nil) == "$3M  ·  taken", P.menuWords(3e6, 2.8e6, nil))
    check("words: exactly your limit counts", P.menuWords(2.8e6, 2.8e6, nil) == "$2.8M  ·  taken")
    check("words: under it", P.menuWords(1.2e6, 2.8e6, nil) == "$1.2M  ·  under your limit")
    check("words: Take beats the limit", P.menuWords(1.2e6, 2.8e6, "take") == "$1.2M  ·  always taken")
    check("words: Skip beats the limit", P.menuWords(3e6, 2.8e6, "skip") == "$3M  ·  never taken")
    check("words: prices not read yet", P.menuWords(nil, 2.8e6, nil) == "no price yet", P.menuWords(nil, 2.8e6, nil))
    check("words: your mark shows with no price too", P.menuWords(nil, 2.8e6, "take") == "always taken")

    local store = {}
    P.looksLearn(store, { "m1", "m2", "m3", "m4" }, "Buddha-Buddha")
    P.looksLearn(store, { "m9", "t9" }, "Spin-Spin")
    check("one new mesh on a known fruit: still named (4 of 5 keys)",
        P.looksName(store, { "m1", "m2", "m3", "m4", "m5" }) == "Buddha-Buddha")
    check("half the keys new: not named", P.looksName(store, { "m1", "m8" }) == nil)
    check("one shared key on a new fruit: not named", P.looksName(store, { "m9", "n1", "n2", "n3" }) == nil)
    check("two fruits in one look: not named", P.looksName(store, { "m1", "m2", "m3", "m9" }) == nil)
    check("nothing read yet: not named", P.looksName(store, {}) == nil)

    P.FRUIT_LOOKS = { m1 = "Buddha-Buddha", m2 = false, m3 = "Rumble-Rumble" }
    local miss = table.concat(P.looksMissing(), " ")
    check("not seen yet: no look learned", has(miss, "Dragon") and has(miss, "Kitsune"), miss)
    check("...a learned one is not listed, a renamed one counts", not has(miss, "Buddha") and not has(miss, "Lightning"), miss)
    check("...sorted, so the panel line holds still", P.looksMissing()[1] == "Blade", P.looksMissing()[1])

    fresh()
    local bag = 0
    P.looksFromBag = function() bag += 1 end
    N.tick()
    check("a fruit you carry teaches its look with no hunt on (the news looks every second)", bag == 1, bag)
end

realPrint(all and "ALL PASS" or "SOME FAILED")
