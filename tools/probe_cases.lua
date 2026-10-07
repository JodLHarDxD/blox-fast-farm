
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

print(all and "ALL PASS" or "SOME FAILED")
