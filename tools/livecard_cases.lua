local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function up(key) return { key = key, tone = "up", title = "T", body = "" } end

-- mapping
local e = liveEventOf(up("mirage"))
check("mirage -> mirage / sea", e and e.mode == "mirage" and e.pack == "sea", e)
e = liveEventOf(up("prehistoric"))
check("prehistoric -> prehistoric", e and e.mode == "prehistoric" and e.pack == "prehistoric", e)
e = liveEventOf(up("boss:Diablo"))
check("elite boss -> elite / raid pack", e and e.mode == "elite" and e.pack == "raid" and e.title == "Diablo is up", e)
-- 2026-11-25 (user: "raid bosses are not raids"): a raid boss's card is
-- that boss's own fight - never the raid.
for _, b in ipairs({ "Dough King", "Cake Prince", "rip_indra True Form", "Soul Reaper",
        "Tyrant of the Skies", "Darkbeard" }) do
    e = liveEventOf(up("boss:" .. b))
    check(b .. " -> its own boss fight, not the raid", e and e.mode == "boss" and e.boss == b
        and e.pack == "raid" and e.title == b .. " is up", e and e.mode)
end
check("an elite pirate's card names no boss (the elite hunt)", liveEventOf(up("boss:Diablo")).boss == nil)
for _, k in ipairs({ "boss:Dough King", "boss:Soul Reaper", "boss:Darkbeard", "boss:Diablo", "castle", "cake" }) do
    local x = liveEventOf(up(k))
    check("no card turns the raid on: " .. k, x == nil or x.mode ~= "raid", x and x.mode)
end
e = liveEventOf(up("frozen"))
check("frozen -> levi / sea", e and e.mode == "levi" and e.pack == "sea", e)
e = liveEventOf(up("fruit"), { name = "Ice", spot = "Ice-Ice@3,4" })
check("fruit -> fruit / fruits, named", e and e.mode == "fruit" and e.pack == "fruits"
    and e.title == "Ice fruit is up" and e.key == "fruit:Ice-Ice@3,4", e)
e = liveEventOf(up("fruit"), { spot = "x" })
check("fruit with no name still a card", e and e.title == "A fruit spawned", e)
check("dim tone -> nothing", liveEventOf({ key = "mirage", tone = "dim" }) == nil)
check("kitsune (no hunt) -> nothing", liveEventOf(up("kitsune")) == nil)
check("cake / moon / server -> nothing", liveEventOf(up("cake")) == nil and liveEventOf(up("moon")) == nil)
check("junk -> nothing", liveEventOf(nil) == nil and liveEventOf({}) == nil and liveEventOf({ key = 5, tone = "up" }) == nil)

-- priority: fruit > mirage > prehistoric > boss > other
local items = { up("frozen"), up("boss:Diablo"), up("prehistoric"), up("mirage"), up("fruit") }
local m = liveMoment(items, { name = "Ice", spot = "a" })
check("fruit wins", m and m.mode == "fruit", m)
m = liveMoment(items, { name = "Ice", spot = "a" }, { ["fruit:a"] = true })
check("fruit put away -> mirage", m and m.mode == "mirage", m)
m = liveMoment({ up("frozen"), up("boss:Diablo"), up("prehistoric") })
check("prehistoric before boss", m and m.mode == "prehistoric", m)
m = liveMoment({ up("frozen"), up("boss:Diablo") })
check("boss before frozen", m and m.mode == "elite", m)
m = liveMoment({ up("boss:Diablo"), up("boss:Dough King") })
check("two bosses: first listed", m and m.key == "boss:Diablo", m)
m = liveMoment({ up("mirage") }, nil, { mirage = true })
check("all put away -> none", m == nil)
check("no items -> none", liveMoment({}) == nil and liveMoment(nil) == nil)
m = liveMoment({ { key = "mirage", tone = "dim" }, { key = "server", tone = "dim" } })
check("only dim news -> none (event ended)", m == nil)

-- the tap
local function stub()
    local log = {}
    local a = {
        cover = function(p) table.insert(log, "cover:" .. p) end,
        setMode = function(id, on) table.insert(log, "mode:" .. id .. ":" .. tostring(on)) end,
        start = function() table.insert(log, "start") end,
    }
    return a, log
end
local mir = liveEventOf(up("mirage"))
local a, log = stub()
check("held, idle: mode then start", liveTap(mir, "open", false, "none", a) == "hunt"
    and table.concat(log, ",") == "mode:mirage:true,start", table.concat(log, ","))
a, log = stub()
check("held, other mode running: mode switch, no restart", liveTap(mir, "open", true, "circuit", a) == "hunt"
    and table.concat(log, ",") == "mode:mirage:true", table.concat(log, ","))
a, log = stub()
check("held, already hunting it: nothing", liveTap(mir, "open", true, "mirage", a) == "none" and #log == 0)
a, log = stub()
check("locked: opens the cover", liveTap(mir, "locked", false, "none", a) == "cover"
    and table.concat(log, ",") == "cover:sea", table.concat(log, ","))
a, log = stub()
local fr = liveEventOf(up("fruit"), { name = "Ice", spot = "a" })
check("locked fruits: coming-soon cover", liveTap(fr, "locked", false, "none", a) == "cover"
    and table.concat(log, ",") == "cover:fruits", table.concat(log, ","))
check("running, not this mode, stopped farm of same id: idle start", liveTapOf(mir, "open", false, "mirage") == "hunt")

-- a boss's card: act.boss(name), never setMode (the raid), then start
local cake = liveEventOf(up("boss:Cake Prince"))
a, log = stub()
a.boss = function(n) table.insert(log, "boss:" .. n) end
check("boss card, idle: that boss, then start - no mode set", liveTap(cake, "open", false, "circuit", a) == "hunt"
    and table.concat(log, ",") == "boss:Cake Prince,start", table.concat(log, ","))
a, log = stub()
a.boss = function(n) table.insert(log, "boss:" .. n) end
check("boss card, a farm running: that boss, no restart", liveTap(cake, "open", true, "circuit", a) == "hunt"
    and table.concat(log, ",") == "boss:Cake Prince", table.concat(log, ","))
a, log = stub()
a.boss, a.nowBoss = function(n) table.insert(log, "boss:" .. n) end, "Cake Prince"
check("boss card, already fighting that boss: nothing", liveTap(cake, "open", true, "boss", a) == "none" and #log == 0)
a, log = stub()
a.boss, a.nowBoss = function(n) table.insert(log, "boss:" .. n) end, "Cake Prince"
local reaper = liveEventOf(up("boss:Soul Reaper"))
check("boss card, fighting ANOTHER boss: switches to this one", liveTap(reaper, "open", true, "boss", a) == "hunt"
    and table.concat(log, ",") == "boss:Soul Reaper", table.concat(log, ","))
check("sub line: hunting now only for the boss being fought",
    liveTapOf(cake, "open", true, "boss", "Cake Prince") == "none"
    and liveTapOf(reaper, "open", true, "boss", "Cake Prince") == "hunt")
a, log = stub()
a.boss = function(n) table.insert(log, "boss:" .. n) end
check("boss card, locked raid pack: cover only", liveTap(cake, "locked", false, "none", a) == "cover"
    and table.concat(log, ",") == "cover:raid", table.concat(log, ","))

-- sub line
check("sub held", liveSubOf("hunt", "SEA") == "Tap to hunt · SEA", liveSubOf("hunt", "SEA"))
check("sub locked", liveSubOf("cover", "SEA") == "Look inside · SEA")
check("sub hunting", liveSubOf("none", "SEA") == "Hunting now · SEA")

-- the news strip (R3 Task S): Home only, only while something is up
check("strip: nothing up = no strip", newsStripOf({ { key = "moon", tone = "night", title = "NIGHT 3/8" },
    { key = "fruit", tone = "dim", title = "NO FRUIT ON THE MAP" } }) == nil)
check("strip: no news = no strip", newsStripOf(nil) == nil and newsStripOf({}) == nil)
local st = newsStripOf({ { key = "moon", tone = "full", title = "FULL MOON" },
    { key = "mirage", tone = "up", title = "MIRAGE ISLAND UP", body = "came 2 min ago" } })
check("strip: the first thing up, the board's words", st and st.key == "mirage" and st.text == "MIRAGE ISLAND IS UP",
    st and st.text)
st = newsStripOf({ { key = "boss:Diablo", tone = "up", title = "ELITE UP", body = "Diablo, near you" } })
check("strip: a boss by name", st and st.text == "DIABLO IS UP", st and st.text)
st = newsStripOf({ { key = "fruit", tone = "up", title = "FRUIT ON THE MAP", body = "Dragon · Ice" } })
check("strip: a fruit with its names", st and st.text == "FRUIT ON THE MAP: DRAGON · ICE", st and st.text)

-- board px -> TextSize (Montserrat's em is TextSize / 1.21 in Roblox)
check("px: 15 -> 18", lookPx(15) == 18, tostring(lookPx(15)))
check("px: 11 -> 13", lookPx(11) == 13, tostring(lookPx(11)))
check("px: 9 -> 11", lookPx(9) == 11, tostring(lookPx(9)))
check("px: 21 -> 25", lookPx(21) == 25, tostring(lookPx(21)))
check("type colours: melee red, sword blue, fruit orange, gun violet",
    TYPE_ACCENT.Melee == "raid" and TYPE_ACCENT.Sword == "sea" and TYPE_ACCENT["Blox Fruit"] == "prehistoric"
    and TYPE_ACCENT.Gun == "pvp")

-- R4 F1: the pirates in the castle
e = liveEventOf(up("castle"))
check("castle -> random / farm (GRIND)", e and e.mode == "random" and e.pack == "farm"
    and e.title == "Pirates are in the castle" and e.strongest == true, e)
m = liveMoment({ up("frozen"), up("castle"), up("boss:Diablo") })
check("castle after the boss", m and m.key == "boss:Diablo", m and m.key)
m = liveMoment({ up("frozen"), up("castle") })
check("castle before the Frozen Dimension", m and m.key == "castle", m and m.key)
local function stubW()
    local a, lg = stub()
    a.weapon = function(md) table.insert(lg, "weapon:" .. md) end
    return a, lg
end
local cas = liveEventOf(up("castle"))
a, log = stubW()
check("castle, idle: mode, strongest weapon, then start", liveTap(cas, "open", false, "none", a) == "hunt"
    and table.concat(log, ",") == "mode:random:true,weapon:random,start", table.concat(log, ","))
a, log = stubW()
liveTap(mir, "open", false, "none", a)
check("mirage: no weapon pick", table.concat(log, ",") == "mode:mirage:true,start", table.concat(log, ","))
a, log = stubW()
check("castle, locked GRIND: cover, no weapon", liveTap(cas, "locked", false, "none", a) == "cover"
    and table.concat(log, ",") == "cover:farm", table.concat(log, ","))

-- the strongest M1: sword, then melee, fruit, gun; mastery breaks a tie
local bag = { { name = "Kabucha", type = "Gun", mastery = 600 }, { name = "Dragon Talon", type = "Melee", mastery = 500 },
    { name = "Kitsune-Kitsune", type = "Blox Fruit", mastery = 600 } }
check("no sword: melee first", strongestM1(bag) == "Dragon Talon", strongestM1(bag))
table.insert(bag, { name = "Yama", type = "Sword", mastery = 100 })
table.insert(bag, { name = "Cursed Dual Katana", type = "Sword", mastery = 350 })
check("swords: the higher mastery", strongestM1(bag) == "Cursed Dual Katana", strongestM1(bag))
check("not weapons are skipped", strongestM1({ { name = "Awakening", type = "?" },
    { name = "Shark Rod", type = "Tool" } }) == nil)
check("nothing carried: nil", strongestM1({}) == nil and strongestM1(nil) == nil)
check("only a gun: the gun", strongestM1({ { name = "Kabucha", type = "Gun" } }) == "Kabucha")
check("Random has no pick: strongest", onceWeaponOf({}, "random", bag) == "Cursed Dual Katana")
check("Random on MIX: strongest", onceWeaponOf({ random = "MIX" }, "random", bag) == "Cursed Dual Katana")
check("FightWith unset table: strongest", onceWeaponOf(nil, "random", bag) == "Cursed Dual Katana")
check("Random's own pick stays: nothing chosen", onceWeaponOf({ random = "Yama" }, "random", bag) == nil)
check("another mode's pick does not count", onceWeaponOf({ circuit = "Yama" }, "random", bag) == "Cursed Dual Katana")

-- the castle raid signal: up at the first pirate, over after CASTLE_GRACE s with none
local st = { up = false }
check("no pirate: nothing", castleRaidFeed(st, 0, 0) == nil and not st.up)
check("first pirate: up", castleRaidFeed(st, 4, 10) == "up" and st.up and st.since == 10)
check("more pirates: no second up", castleRaidFeed(st, 9, 11) == nil)
check("between waves (59 s none): still up", castleRaidFeed(st, 0, 11 + CASTLE_GRACE - 1) == nil and st.up)
check("a new wave keeps it", castleRaidFeed(st, 2, 80) == nil and st.lastSeen == 80)
check("none for the grace: gone", castleRaidFeed(st, 0, 80 + CASTLE_GRACE) == "gone" and not st.up)
check("gone: no second gone", castleRaidFeed(st, 0, 500) == nil)
-- WHO IS A RAID PIRATE (2026-11-26: the alarm in every server joined)
for _, n in ipairs({ "Horned Warrior", "Magma Ninja", "Lava Pirate", "Ship Deckhand", "Ship Engineer",
        "Ship Steward", "Ship Officer", "Arctic Warrior", "Snow Lurker", "Sea Soldier" }) do
    check("raid pirate (Fandom's list): " .. n, isCastleRaider(n, nil))
end
check("a Second Sea species not on the list (lv 1250): a raid pirate", isCastleRaider("Some New Pirate", 1250))
check("a Second Sea boss (the raid's last, lv 1475): a raid pirate", isCastleRaider("Tide Keeper", 1475))
check("the castle's Elite Hunter (an NPC, no level): not a pirate", not isCastleRaider("Elite Hunter", nil))
check("an elite pirate (Diablo, no level row): not a raid pirate", not isCastleRaider("Diablo", nil))
check("a Third Sea species (lv 1500+): not", not isCastleRaider("Pirate Millionaire", 1500)
    and not isCastleRaider("Reborn Skeleton", 1975))
check("a First Sea species (lv < 700): not", not isCastleRaider("Bandit", 1))
check("junk: not", not isCastleRaider(nil, 1000) and not isCastleRaider(5, 1000))
local st2 = newsStripOf({ { key = "castle", tone = "up", title = "PIRATES IN THE CASTLE", body = "x" } })
check("strip: the castle raid", st2 and st2.text == "PIRATES IN THE CASTLE", st2 and st2.text)

-- R4 F3: the carousel - every live event, rolled through
local all5 = { up("frozen"), up("castle"), up("boss:Diablo"), up("prehistoric"), up("mirage"),
    up("boss:Dough King"), up("fruit") }
local L = liveMoments(all5, { name = "Ice", spot = "a" })
local keys = {}
for _, x in ipairs(L) do table.insert(keys, x.key) end
check("every event, priority order (two bosses in the news's order)",
    table.concat(keys, ",") == "fruit:a,mirage,prehistoric,boss:Diablo,boss:Dough King,castle,frozen",
    table.concat(keys, ","))
check("liveMoment is the first of them", liveMoment(all5, { name = "Ice", spot = "a" }).key == "fruit:a")
check("put away ones are left out", #liveMoments(all5, { spot = "a" }, { mirage = true, frozen = true }) == 5)
check("dim / no hunt: not in the list", #liveMoments({ { key = "mirage", tone = "dim" }, up("kitsune") }) == 0)
check("short titles", liveEventOf(up("boss:Diablo")).title == "Diablo is up"
    and liveEventOf(up("mirage")).title == "Mirage is up"
    and liveEventOf(up("prehistoric")).title == "Prehistoric is up")
check("short sub line", liveSubOf("hunt", "BOSSES + RAIDS") == "Tap to hunt · BOSSES + RAIDS")

local three = liveMoments({ up("mirage"), up("boss:Diablo"), up("frozen") })
local cs = {}
local cm, step = carouselTick(cs, three, 0)
check("first look: the first event, no roll yet", cm.key == "mirage" and step == 0 and cs.idx == 1)
cm, step = carouselTick(cs, three, 1.9)
check("before 2 s: still the first", cm.key == "mirage" and step == 0)
cm, step = carouselTick(cs, three, 2)
check("2 s: rolls to the next", cm.key == "boss:Diablo" and step == 1 and cs.idx == 2)
carouselTick(cs, three, 4)
cm = carouselTick(cs, three, 6)
check("loops: after the last, the first again", cm.key == "mirage" and cs.idx == 1, cm.key)
cm = carouselStep(cs, three, -1, 6.5, true)
check("back from the first wraps to the last", cm.key == "frozen" and cs.idx == 3)
cm = carouselStep(cs, three, 1, 6.6, true)
check("on from the last wraps to the first", cm.key == "mirage")
-- the pause after a manual step
cm, step = carouselTick(cs, three, 6.6 + 7.9)
check("an arrow holds the roll 8 s", cm.key == "mirage" and step == 0)
cm, step = carouselTick(cs, three, 6.6 + LIVE_PAUSE)
check("...then it rolls again", cm.key == "boss:Diablo" and step == 1)
carouselTouch(cs, 20)
cm, step = carouselTick(cs, three, 27.9)
check("a touch on the card holds it 8 s too", cm.key == "boss:Diablo" and step == 0)
cm, step = carouselTick(cs, three, 28)
check("...then on", cm.key == "frozen" and step == 1)
-- the list changes under it: the same event keeps showing
local cs2 = { }
carouselTick(cs2, three, 0)
carouselStep(cs2, three, 1, 0, false)       -- Diablo
local grown = liveMoments({ up("fruit"), up("mirage"), up("boss:Diablo"), up("frozen") }, { spot = "z" })
cm = carouselSync(cs2, grown)
check("a new event in front: still Diablo showing", cm.key == "boss:Diablo" and cs2.idx == 3)
-- x: only the event showing goes, the next one shows
local dis = {}
local rest
rest, cm = carouselDismiss(cs2, grown, dis)
check("x puts away only Diablo", #rest == 3 and dis["boss:Diablo"] and not dis.mirage and not dis.frozen)
check("...the next one shows (its place)", cm.key == "frozen", cm and cm.key)
check("...and it stays away on the next look",
    #liveMoments({ up("fruit"), up("mirage"), up("boss:Diablo"), up("frozen") }, { spot = "z" }, dis) == 3)
rest, cm = carouselDismiss(cs2, rest, dis)
check("x on the last: wraps to the first", cm.key == "fruit:z" and #rest == 2, cm and cm.key)
-- an event ends: the one at its place takes over
local cs3 = {}
carouselTick(cs3, three, 0)
carouselStep(cs3, three, 1, 0, false)       -- Diablo
cm = carouselSync(cs3, liveMoments({ up("mirage"), up("frozen") }))
check("the event showing ended: the one at its place", cm.key == "frozen")
-- one event: no arrows, no marker, no roll
local one = liveMoments({ up("mirage") })
local cs4 = {}
cm, step = carouselTick(cs4, one, 0)
local cm2, step2 = carouselTick(cs4, one, 100)
check("one event: never rolls", cm.key == "mirage" and step == 0 and cm2.key == "mirage" and step2 == 0)
check("one event: no arrows / marker", carouselChrome(1) == false and carouselChrome(0) == false
    and carouselChrome(2) == true)
check("one event: an arrow does nothing", carouselStep(cs4, one, 1, 0, true).key == "mirage")
rest, cm = carouselDismiss(cs4, one, {})
check("x on the only one: nothing left", #rest == 0 and cm == nil and cs4.key == nil)
check("nothing: no card", carouselTick({}, {}, 0) == nil)

print(all and "ALL PASS" or "SOME FAILED")
