
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- 1. the game's own hit sender reachable: tried FIRST, kept when it lands
reset() P.reprobe() GAME = true LANDS = { game = true, new = true }
local way = probeM1("Bisento", {})
check("game's sender tried first and kept", way and way.variant == "game" and TRIED[1] == "game",
    table.concat(TRIED, ","))

-- 2. not reachable: the raw remote first, as before
reset() P.reprobe() LANDS = { new = true }
way = probeM1("Bisento", {})
check("no game sender: raw remote (new) first", way and way.variant == "new" and TRIED[1] == "new",
    table.concat(TRIED, ","))
check("a way that landed is kept: no probe due", m1Due("Bisento") == false)

-- 3. THE BUG: nothing lands (just arrived, bad moment) - not final any more
reset() P.reprobe() GAME = true
way = probeM1("Bisento", {})
check("nothing landed: false, every way tried", way == false and #TRIED == 4, table.concat(TRIED, ","))
check("right after: no probe due (no hammering)", m1Due("Bisento") == false)
CLOCK += 12
check("12 s later: tried again - the server is not written off", m1Due("Bisento") == true)
LANDS = { game = true }
way = probeM1("Bisento", {})
check("the second probe finds it", way and way.variant == "game")

-- 4. "Try the M1 ways again" / an elite not losing HP: everything forgotten
P.reprobe()
check("reprobe: due at once", m1Due("Bisento") == true)

-- 5. never tried: due
reset() P.reprobe()
check("new weapon: due", m1Due("Other") == true)

-- 6. A GUN (user, 2026-10-07: Dragonstorm "should hold down"; the aim missed)
reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = true }, { hold = true }
way = probeM1("Dragonstorm", {})
check("gatling gun: held like a player first, kept", way and way.path == "hold" and TRIED[1] == "hold",
    table.concat(TRIED, ","))
check("held from above: range 400, never down close", way and way.pose == "safe")
check("a hold that landed is kept held (not let go)", RELEASED == 0, RELEASED)

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = true }, { keys = true }
way = probeM1("Dragonstorm", {})
check("hold landed nothing: let go, THEN the click", way and way.path == "keys" and TRIED[1] == "hold"
    and TRIED[2] == "keys" and RELEASED == 1, table.concat(TRIED, ",") .. "  released " .. RELEASED)

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = true }, { keys = true, hold = true }
CFG.GunHold = false
way = probeM1("Dragonstorm", {})
check("hold switched off: the click only", way and way.path == "keys" and TRIED[1] == "keys",
    table.concat(TRIED, ","))

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = true }, { gunshot = true, hold = true }
CFG.GunFast, SHOTFN = true, true
way = probeM1("Dragonstorm", {})
check("past the heat on + the game's shot found: tried first", way and way.path == "gunshot"
    and TRIED[1] == "gunshot", table.concat(TRIED, ","))

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = true }, { hold = true }
CFG.GunFast = true
way = probeM1("Dragonstorm", {})
check("past the heat on, the shot NOT found: held", way and way.path == "hold" and TRIED[1] == "hold",
    table.concat(TRIED, ","))

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = false }, { keys = true }
way = probeM1("Flintlock", {})
check("a gun that does not fire while held: the click", way and way.path == "keys" and #TRIED == 1,
    table.concat(TRIED, ","))

reset() P.reprobe() TYPE, GUN, LANDS = "Gun", { gatling = false, custom = true }, { keys = true }
CFG.GunFast, SHOTFN = true, true
way = probeM1("Skull Guitar", {})
check("a gun with its own way (Skull Guitar): never the game's shot", way and TRIED[1] == "keys",
    table.concat(TRIED, ","))

reset() P.reprobe() TYPE, GUN = "Sword", { gatling = true }
LANDS = { new = true }
way = probeM1("Bisento", {})
check("a sword is never held or shot as a gun", way and way.variant == "new" and TRIED[1] == "new",
    table.concat(TRIED, ","))

-- 7. A FRUIT'S OWN M1 (user, 2026-10-24: Lightning's M1 "never clicks")
reset() P.reprobe() TYPE, LANDS = "Blox Fruit", { tap = true, new = true }
way = probeM1("Lightning-Lightning", fruitTool({ Holding = true }))
check("a moveset fruit: its own M1 (tap) before a sword's remote hit", way and way.path == "tap"
    and TRIED[1] == "tap", table.concat(TRIED, ","))
reset() P.reprobe() TYPE, LANDS = "Blox Fruit", { tap = true, click = true }
way = probeM1("Kitsune-Kitsune", fruitTool({ Holding = true, LeftClickRemote = true }))
check("...an old LeftClickRemote fruit: the click (the whole pile a tick) still first", way
    and way.path == "click" and TRIED[1] == "click", table.concat(TRIED, ","))
reset() P.reprobe() TYPE, LANDS = "Blox Fruit", { tap = true, new = true }
way = probeM1("Spin-Spin", fruitTool({}))
check("...no Holding on the tool (no M1 bound): no tap tried", way and way.variant == "new"
    and TRIED[1] == "new", table.concat(TRIED, ","))

-- 8. THE BUG: a skill's storm still hurting the pile was read as the M1 landing
reset() P.reprobe() TYPE, DOT = "Blox Fruit", 20
way = probeM1("Lightning-Lightning", fruitTool({ Holding = true }))
check("HP lost to a skill (nothing fired lands): no way credited", way == false, table.concat(TRIED, ","))
reset() P.reprobe() TYPE, DOT, LANDS = "Blox Fruit", 20, { tap = true }
way = probeM1("Lightning-Lightning", fruitTool({ Holding = true }))
check("...the M1 landing on top of it: still found", way and way.path == "tap", table.concat(TRIED, ","))
reset() P.reprobe() TYPE, DOT, LANDS = "Sword", 20, { keys = true }
way = probeM1("Bisento", {})
check("...a sword too: the remote hit is not credited with the storm's HP, the click is",
    way and way.path == "keys" and TRIED[1] == "new", table.concat(TRIED, ","))

-- 9. the move that was cast ends first: no M1 fired inside it
reset() P.reprobe() LANDS = { new = true }
P.lastCastAt = 0
local busyTill = 0.2           -- the move itself over fast: its storm still lands
P.canCast = function() return CLOCK >= busyTill end
way = probeM1("Bisento", {})
check("just cast: the first M1 at least 1.5 s after the cast", way and FIRST_AT and FIRST_AT >= 1.5,
    tostring(FIRST_AT))
reset() P.reprobe() LANDS = { new = true }
P.lastCastAt, P.canCast = 0, function() return false end
way = probeM1("Bisento", {})
check("...never longer than 2.5 s (a move that never ends)", way and FIRST_AT and FIRST_AT < 3.5,
    tostring(FIRST_AT))

-- 10. nothing lands again and again: tried again later each time (12, 24, ... 120 s)
reset() P.reprobe()
probeM1("Bisento", {})
CLOCK += 12
check("first miss: again in 12 s", m1Due("Bisento") == true)
probeM1("Bisento", {})
CLOCK += 12
check("second miss: not after 12 s", m1Due("Bisento") == false)
CLOCK += 12
check("...but after 24 s", m1Due("Bisento") == true)
for _ = 1, 6 do probeM1("Bisento", {}) CLOCK += 120 end
check("never longer than 2 min", m1Due("Bisento") == true)
LANDS = { new = true }
probeM1("Bisento", {})
LANDS = {}
probeM1("Bisento", {})
CLOCK += 12
check("a find starts the wait over at 12 s", m1Due("Bisento") == true)

print(all and "ALL PASS" or "SOME FAILED")
