
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local R = P.route
local SEA_OF_TEARS = v3(-9500, 20, 6000)
local HYDRA_TOWN = v3(5300, 1000, 100)
local function reset()
    R.pads, R.homes, R.bad, R.locked = {}, {}, {}, {}
    R.homeSecs, R.portalSecs, R.homeOutside, R.homeBad = 6, 2.5, nil, 0
    TAGGED = { CASTLE_HYDRA, CASTLE_MANSION, CASTLE_TIKI, HYDRA, MANSION, TIKI }
    POS, SAFE, SEA, SPAWN_NAME = SEA_OF_TEARS, false, 3, "Castle on the Sea"
    HOME_WORKS, HOME_DELAY, HOME_AT, PULL_TO = true, 5, nil, nil
    LOCKED, TOUCH_WORKS, MIMIC_WORKS, PULL_BACK, PULL_DELAY = {}, true, true, false, 0.3
    CALLS, FLIGHTS, LOCKS, SAID, TOUCHES, FILES = {}, {}, {}, {}, 0, {}
    CFG.TravelHome = true
    STREAM, FLY_SHORT, LOCK_MOVES = nil, false, false
    epoch = 0
end
local function called(w) for _, c in ipairs(CALLS) do if c == w then return true end end return false end
local function near(a, b, d) return a and b and (a - b).Magnitude < (d or 5) end
local function padOf(net, name, at)
    for _, p in ipairs(net.pads) do
        if p.name == name and (p.hit - at).Magnitude < 1 then return p end
    end
    return nil
end

-- THE PADS, by their tag: pairs by name, the Pivot, kept in the file
reset()
R.scan()
local n = 0
for _ in pairs(R.pads) do n += 1 end
check("six pads seen by their tag", n == 6, n)
local saved = FILES["bff_routes.json"]
local ns = 0
for _ in pairs(saved and saved.pads or {}) do ns += 1 end
check("...kept in bff_routes.json, with their Pivot", ns == 6, ns)
local net = R.net(false)
local ch = padOf(net, "HydraTP", CASTLE_HYDRA.hb.Position)
check("the Castle's Hydra pad comes out at Hydra's Pivot (its partner's)", ch and near(ch.out, HYDRA.attrs.Pivot.Position))
check("...and Hydra's back at the Castle's", near((padOf(net, "HydraTP", HYDRA.hb.Position) or {}).out,
    CASTLE_HYDRA.attrs.Pivot.Position))

-- a pad streamed out stays known
TAGGED = { CASTLE_HYDRA }
R.scan()
n = 0
for _ in pairs(R.pads) do n += 1 end
check("streamed out: still known (kept)", n == 6, n)
TAGGED = { CASTLE_HYDRA, CASTLE_MANSION, CASTLE_TIKI, HYDRA, MANSION, TIKI }

-- YOUR HOME POINT: this sea's only
local hp, name = R.homeAt()
check("Home: its spawn in this sea", near(hp, SPAWNS["Castle on the Sea"]) and name == "Castle on the Sea")
SPAWN_NAME = "Port Town"
hp, name = R.homeAt()
check("Home in another sea (no spawn here): never planned - a Home there would change server",
    hp == nil and name == "Port Town")
check("...not in the graph", R.net(false).home == nil)
R.homes["9:3:Port Town"] = v3(1, 2, 3)
check("...not even with a landing kept under this sea (its spawn is not here)", R.homeAt() == nil)
SPAWN_NAME = nil
check("no Home Point set: none", R.homeAt() == nil)
SPAWN_NAME = "Castle on the Sea"
CFG.TravelHome = false
check("\"Use the Home button\" off: no Home in the graph", R.net(false).home == nil)
CFG.TravelHome = true
check("...on: Home in the graph", R.net(false).home ~= nil)

-- THE HOME BUTTON, from out at sea
reset()
local t0 = NOW
check("Home from out at sea: there", R.goHome(0) == true)
check("...by TeleportToSpawn", called("TeleportToSpawn"))
check("...where it landed learned", near(R.homes["9:3:Castle on the Sea"], SPAWNS["Castle on the Sea"] + v3(0, 5, 0)))
check("...its seconds learned (6 -> nearer 5)", R.homeSecs < 6 and R.homeSecs > 5, R.homeSecs)
check("...it works from outside a safe zone: remembered", R.homeOutside == true)
check("...took about the countdown", NOW - t0 < 7, NOW - t0)
CALLS = {}
check("already Home: true, nothing pressed", R.goHome(0) == true and #CALLS == 0)

-- the Home button does nothing from outside a safe zone
reset()
HOME_WORKS = false
check("Home did not move you: false", R.goHome(0) == false)
check("...gave up after 15 s", NOW >= 1015)
check("...remembered: only from a safe zone now", R.homeOutside == false)
NOW += 200
check("...out at sea: not planned", R.net(false).home == nil)
check("...in a safe zone: planned", R.net(true).home ~= nil)
reset()
HOME_WORKS, SAFE = false, true
R.goHome(0)
check("failed FROM a safe zone: left 2 min, nothing learned about outside", R.homeOutside == nil
    and R.net(true).home == nil)

-- THROUGH A PAD: stood in, touched - the game's handler
reset()
R.scan()
POS = v3(-5300, 320, -3300)
local p = padOf(R.net(false), "HydraTP", CASTLE_HYDRA.hb.Position)
check("touched: through", R.ride(p, 0) == true)
check("...flown into its Hitbox first, held there", near(FLIGHTS[1], CASTLE_HYDRA.hb.Position, 3)
    and near(LOCKS[1], CASTLE_HYDRA.hb.Position))
check("...asked whether it is unlocked", called("GetInfo HydraTP"))
check("...out at Hydra's Pivot", near(POS, HYDRA.attrs.Pivot.Position))
check("...where the ride ended learned", near(R.pads[p.id].landed, HYDRA.attrs.Pivot.Position))
check("...no client steps needed", not called("InitiateTeleport HydraTP"))

-- the touch did nothing: the game's client's own steps
reset()
R.scan()
TOUCH_WORKS = false
p = padOf(R.net(false), "MansionTP", CASTLE_MANSION.hb.Position)
check("touch did nothing: the client's steps take you", R.ride(p, 0) == true and called("InitiateTeleport MansionTP"))
check("...out at the Mansion", near(POS, MANSION.attrs.Pivot.Position))

-- a server that pulls you back: refused, left 5 min
reset()
R.scan()
TOUCH_WORKS, PULL_BACK = false, true
p = padOf(R.net(false), "MansionTP", CASTLE_MANSION.hb.Position)
check("pulled back: refused", R.ride(p, 0) == false)
check("...left out of the next plans", padOf(R.net(false), "MansionTP", CASTLE_MANSION.hb.Position) == nil)

-- pulled back a moment later (after it looked taken): refused
reset()
R.scan()
TOUCH_WORKS, PULL_BACK, PULL_DELAY = false, true, 0.8
p = padOf(R.net(false), "MansionTP", CASTLE_MANSION.hb.Position)
check("pulled back late: refused, nothing learned", R.ride(p, 0) == false and R.pads[p.id].landed == nil)

-- not unlocked on this account: never again
reset()
R.scan()
LOCKED.TikiTP = true
p = padOf(R.net(false), "TikiTP", CASTLE_TIKI.hb.Position)
check("locked: refused, never touched", R.ride(p, 0) == false and TOUCHES == 0)
check("...both its ends gone from the graph", padOf(R.net(false), "TikiTP", CASTLE_TIKI.hb.Position) == nil
    and padOf(R.net(false), "TikiTP", TIKI.hb.Position) == nil)

-- the pad is not where it was kept (gone from the world)
reset()
R.scan()
p = padOf(R.net(false), "HydraTP", HYDRA.hb.Position)
TAGGED = { CASTLE_HYDRA, CASTLE_MANSION, CASTLE_TIKI }
check("not there when you arrive: refused", R.ride(p, 0) == false)

-- A LONG TRIP, end to end: Sea of Tears -> Hydra = Home, then the Castle's Hydra pad
reset()
check("Sea of Tears -> Hydra: moved by the route", R.go(HYDRA_TOWN, 0) == true)
check("...Home pressed, then the Castle's Hydra pad", called("TeleportToSpawn") and called("GetInfo HydraTP"))
check("...out at Hydra (the flight goes on from there)", near(POS, HYDRA.attrs.Pivot.Position))
check("...said in words", string.find(R.last, "Home -> HydraTP pad", 1, true) ~= nil, R.last)

-- Home fails on the way: planned again without it
reset()
HOME_WORKS = false
check("Home did nothing: planned again, the pads instead", R.go(HYDRA_TOWN, 0) == true
    and near(POS, HYDRA.attrs.Pivot.Position), tostring(R.last))
local homes = 0
for _, c in ipairs(CALLS) do if c == "TeleportToSpawn" then homes += 1 end end
check("...Home pressed once only", homes == 1, homes)

-- a short trip: nothing
reset()
POS = v3(5000, 1000, 0)
check("a short trip: no route, false", R.go(HYDRA_TOWN, 0) == false and #CALLS == 0)
check("...said: straight flight", string.find(R.last, "straight", 1, true) ~= nil, R.last)

-- Home would save only ~1 s: straight, nothing pressed (worth it at 3 s+)
reset()
POS = v3(-2900, 320, -3000)
check("saves under 3 s: straight", R.go(SPAWNS["Castle on the Sea"], 0) == false and not called("TeleportToSpawn"))

-- A flight that fell short of the pad, then the lock's jump onto it: not a
-- ride (bff_routes.json had the Castle's pad "landing" on itself).
reset()
R.scan()
POS = v3(-6500, 320, -3300)
FLY_SHORT, LOCK_MOVES, TOUCH_WORKS, PULL_BACK = true, true, false, true
p = padOf(R.net(false), "HydraTP", CASTLE_HYDRA.hb.Position)
check("flight fell short, lock jumped onto the pad: not a ride", R.ride(p, 0) == false
    and R.pads[p.id].landed == nil, tostring(R.pads[p.id].landed))

-- THE USER'S TRIP (2026-10-31): Tiki -> Hydra. Known from before: the Tiki
-- pad pair and Hydra's pad - the Castle's Hydra pad streams in only at the
-- Castle. Tiki pad to the Castle, planned again there, the Hydra pad.
reset()
TAGGED = { TIKI, CASTLE_TIKI, HYDRA }
R.scan()
TAGGED = { CASTLE_HYDRA, CASTLE_MANSION, CASTLE_TIKI, HYDRA, MANSION, TIKI }
STREAM, POS = 2000, v3(-16000, 20, 600)
check("Tiki -> Hydra: moved by the route", R.go(HYDRA_TOWN, 0) == true)
check("...the Castle's Hydra pad, seen at the Castle, ridden", called("GetInfo HydraTP"), table.concat(CALLS, ","))
check("...out at Hydra, not a 22k flight", near(POS, HYDRA.attrs.Pivot.Position), tostring(R.last))

-- stopped mid-route: back at once
reset()
epoch = 1
check("stopped: nothing done", R.go(HYDRA_TOWN, 0) == false and #CALLS == 0)
epoch = 0

-- the panel's line
reset()
R.scan()
local w = R.words()
check("panel: the Home Point and the pads known", string.find(w, "home      Castle on the Sea", 1, true)
    and string.find(w, "pads 6 known", 1, true), w)

realPrint(all and "ALL PASS" or "SOME FAILED")
