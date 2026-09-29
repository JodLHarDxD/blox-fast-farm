
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

print(all and "ALL PASS" or "SOME FAILED")
