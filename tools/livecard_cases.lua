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
check("elite boss -> elite / raid pack", e and e.mode == "elite" and e.pack == "raid" and e.title == "Diablo is up in this server", e)
e = liveEventOf(up("boss:Dough King"))
check("raid boss -> raid", e and e.mode == "raid", e)
e = liveEventOf(up("boss:rip_indra True Form"))
check("rip_indra -> raid", e and e.mode == "raid", e)
e = liveEventOf(up("frozen"))
check("frozen -> levi / sea", e and e.mode == "levi" and e.pack == "sea", e)
e = liveEventOf(up("fruit"), { name = "Ice", spot = "Ice-Ice@3,4" })
check("fruit -> fruit / fruits, named", e and e.mode == "fruit" and e.pack == "fruits"
    and e.title == "Ice fruit is up in this server" and e.key == "fruit:Ice-Ice@3,4", e)
e = liveEventOf(up("fruit"), { spot = "x" })
check("fruit with no name still a card", e and e.title == "A fruit spawned in this server", e)
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

-- sub line
check("sub held", liveSubOf("hunt", "SEA") == "Tap to hunt it · SEA", liveSubOf("hunt", "SEA"))
check("sub locked", liveSubOf("cover", "SEA") == "SEA runs it for you · look inside")
check("sub hunting", liveSubOf("none", "SEA") == "Hunting it now · SEA")

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

print(all and "ALL PASS" or "SOME FAILED")
