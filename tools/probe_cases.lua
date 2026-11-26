
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

-- HOW M1 LANDS IS NO SETTING (user, 2026-11-26: "it should be locked how it
-- lands a hit"). A left-over M1Method in a saved file changes nothing: each
-- weapon's own ways, in their own order.
reset() P.reprobe() TYPE, GAME, LANDS = "Melee", true, { game = true, keys = true }
CFG.M1Method = "keys"
way = probeM1("Combat", {})
check("a saved 'Key press' pick is ignored: Combat's game sender first, kept",
    way and way.variant == "game" and TRIED[1] == "game", table.concat(TRIED, ","))
reset() P.reprobe() TYPE, LANDS = "Blox Fruit", { new = true }
CFG.M1Method = "tap"
way = probeM1("Spin-Spin", fruitTool({}))
check("...a saved 'Fruit M1' pick: no tap made up for a fruit without one",
    way and way.variant == "new" and not table.find(TRIED, "tap"), table.concat(TRIED, ","))
CFG.M1Method = nil

-- A FRUIT WITH NO M1 IN THE GAME (user, 2026-11-26, the second account: "fruit
-- M1 not landing"). Its own table (GetFruitData) lists Z X C V and no TAP -
-- Ice. Nothing is tried, no 2 s probes every 12 / 24 / 48 s: false for good.
reset() P.reprobe()
CLOCK = 1000                               -- past the unreadable table's 30 s wait
FRUIT_TABLE = {
    ["Ice-Ice"] = { Cooldown = { Z = 6, X = 9, C = 10, V = 16 }, Cost = { Z = 15 }, Lvl = { Z = 1 } },
    ["Lightning-Lightning"] = { Cooldown = { TAP = 0.5, Z = 4 }, Cost = { TAP = 0 }, Lvl = { TAP = 0 } },
}
TYPE, LANDS = "Blox Fruit", { tap = true, new = true, keys = true }
local asked0 = FRUIT_ASKED
way = probeM1("Ice-Ice", fruitTool({ Holding = true }))
check("Ice (no TAP): false at once, not one way fired", way == false and #TRIED == 0, table.concat(TRIED, ","))
check("...the game's table asked once", FRUIT_ASKED == asked0 + 1, FRUIT_ASKED - asked0)
check("...never due again (no probing in the fight)", m1Due("Ice-Ice") == false)
CLOCK += 100000
check("...not even much later", m1Due("Ice-Ice") == false)
check("...the note says why", string.find(P.m1Notes["Ice-Ice"] or "", "no M1 in the game", 1, true) ~= nil,
    P.m1Notes["Ice-Ice"])
check("P.fruitM1: Ice false, Lightning true, an unknown name nil",
    P.fruitM1("Ice-Ice", fruitTool({})) == false and P.fruitM1("Lightning-Lightning", fruitTool({})) == true
    and P.fruitM1("Spin-Spin", fruitTool({})) == nil)
check("P.fruitM1: a LeftClickRemote fruit has one, whatever its table says",
    P.fruitM1("Ice-Ice", fruitTool({ LeftClickRemote = true })) == true)
check("...the table read once per server, not per question", FRUIT_ASKED == asked0 + 1, FRUIT_ASKED - asked0)

reset() P.reprobe()
TYPE, LANDS = "Blox Fruit", { tap = true }
way = probeM1("Lightning-Lightning", fruitTool({ Holding = true }))
check("a fruit WITH a TAP: its own M1 tried and kept as before", way and way.path == "tap" and TRIED[1] == "tap",
    table.concat(TRIED, ","))

reset() P.reprobe()
TYPE, LANDS = "Blox Fruit", { new = true }
way = probeM1("Spin-Spin", fruitTool({}))
check("a fruit the table does not name: tried as before", way and way.variant == "new", table.concat(TRIED, ","))

reset()
TYPE = "Blox Fruit"
P.reprobe()
check("reprobe: Ice due again (looked at again)", m1Due("Ice-Ice") == true)
way = probeM1("Ice-Ice", fruitTool({ Holding = true }))
check("...and found to have none again, nothing fired", way == false and #TRIED == 0, table.concat(TRIED, ","))

print(all and "ALL PASS" or "SOME FAILED")
