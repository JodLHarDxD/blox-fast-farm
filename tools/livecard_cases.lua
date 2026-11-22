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

print(all and "ALL PASS" or "SOME FAILED")
