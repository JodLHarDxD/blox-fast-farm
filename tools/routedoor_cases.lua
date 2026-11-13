
-- ---------------------------------------------------------------- cases
-- THE DOORS (2026-11-13), on the REAL seeds (P.ROUTE_SEEDS, cut out of
-- fast_farm.lua) and the user's REAL bff_routes.json of that day: the Tiki
-- pad pair ridden, and an undated "Home only from a safe zone".
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local R = P.route
local CASTLE = v3(-5072, 314.5, -3151)
local MANSION_AT = v3(-12471.17, 374.94, -7551.68)
local HYDRA_AT = v3(5661.53, 1013.09, -334.96)
local FLOATING_TURTLE = v3(-13274, 332, -7632)
local HAUNTED_CASTLE = v3(-9515, 142, 5533)
local function near(a, b, d) return a and b and (a - b).Magnitude < (d or 5) end
local function called(w) for _, c in ipairs(CALLS) do if c == w then return true end end return false end
local function count(w) local n = 0 for _, c in ipairs(CALLS) do if c == w then n += 1 end end return n end
local function linkOf(net, name, at)
    for _, p in ipairs(net.pads) do
        if p.name == name and (p.hit - at).Magnitude < 150 then return p end
    end
    return nil
end

-- The Third Sea's doors, where they really stand (a little off their seeds).
local CASTLE_A = doorPart("Boat Castle/MapTeleportA/Hitbox", -5060, 315, -3165)
local CASTLE_B = doorPart("Boat Castle/MapTeleportB/Hitbox", -5085, 315, -3138)
local MANSION_DOOR = doorPart("Turtle/MapTeleportB/Hitbox", -12471, 375, -7552)
local HYDRA_DOOR = doorPart("Waterfall/MapTeleportA/Hitbox", 5661, 1013, -335)
-- The Second Sea's Cursed Ship: its door outside, its door inside.
local SHIP_OUT = doorPart("GhostShip/Teleport", -6530, 92, -140)
local SHIP_IN = doorPart("GhostShipInterior/Teleport", 930, 127, 32870)
local SHIP_OUT_AT = v3(-6508.56, 89.03, -132.84)
local SHIP_IN_AT = v3(923.21, 126.98, 32852.83)
local THIRD = {
    { entry = CASTLE_A.Position, ask = MANSION_AT }, { entry = MANSION_DOOR.Position, ask = CASTLE },
    { entry = CASTLE_B.Position, ask = HYDRA_AT }, { entry = HYDRA_DOOR.Position, ask = CASTLE },
}
local SECOND = { { entry = SHIP_OUT.Position, ask = SHIP_IN_AT }, { entry = SHIP_IN.Position, ask = SHIP_OUT_AT } }
SPAWNS["Castle on the Sea"] = v3(-5018, 318, -3014)

local function reset()
    for _, p in pairs(R.pads) do
        if p.kind == "door" then p.landed = nil end
    end
    R.bad, R.locked = {}, {}
    R.homeSecs, R.portalSecs, R.farSecs, R.homeBad = 5.6, 2.5, 1.5, 0
    R.homeOutside, R.homeOutNo, R.farYes, R.farNo, R.farBad, R.farMiss = nil, nil, nil, nil, 0, false
    NOW += 1000                       -- GetUnlockables is read again (kept 5 min)
    POS, SAFE, SEA, SPAWN_NAME = FLOATING_TURTLE, false, 3, "Castle on the Sea"
    HOME_WORKS, HOME_DELAY, HOME_AT, PULL_TO, HOME_ANSWER = true, 5, nil, nil, nil
    DOORS, FAR_OK, DOOR_OK, DOOR_PULL, SERVER_MOVES, DOOR_TOUCH_WORKS = THIRD, false, true, false, false, false
    UNLOCKS = { DefeatedIndraTrueForm = true, FlamingoAccess = true }
    LEVEL = 2600
    CALLS, FLIGHTS, LOCKS, SAID, TOUCHES = {}, {}, {}, {}, 0
    CFG.TravelHome, CFG.TravelFar = true, true
    MAP_STREAM, STREAM, FLY_SHORT, LOCK_MOVES = 2000, nil, false, false
    TAGGED = {}
    epoch = 0
end

-- THE FILE OF 2026-11-13 + THE SEEDS
local here = 0
for _, p in pairs(R.pads) do if p.sea == 3 then here += 1 end end
check("Third Sea: six link ends known from the start (Mansion, Hydra, Tiki - both ends each)", here == 6, here)
local tiki = 0
for _, p in pairs(R.pads) do if p.name == "MapTeleportC" then tiki += 1 end end
check("...the Tiki pad pair of the file is not doubled by its seed", tiki == 2, tiki)
check("the old file's undated 'Home only from a safe zone' is not believed", R.homeOutside ~= false and R.homeOutNo == nil)
reset()
check("...Home is in the plan from out at sea", R.net(false).home ~= nil)
local net = R.net(false)
check("the Mansion portal is known though never seen", linkOf(net, "the Mansion portal", MANSION_AT) ~= nil)
check("...its ride ends at the Castle on the Sea", near((linkOf(net, "the Mansion portal", MANSION_AT) or {}).out, CASTLE, 5))
check("the Tiki pad's ride end comes from the file", near((linkOf(net, "MapTeleportC", v3(-16799, 84, 291)) or {}).out,
    v3(-5085, 318, -3156), 5))

-- THE USER'S TRIP: Floating Turtle -> the Haunted Castle. A straight flight
-- is 13.7k studs; the Castle on the Sea is on the way by Home or the
-- Mansion's portal.
reset()
check("Floating Turtle -> Haunted Castle: NOT a straight flight", R.go(HAUNTED_CASTLE, 0) == true, tostring(R.last))
check("...you are at the Castle on the Sea now (the flight goes on from there)", (POS - CASTLE).Magnitude < 400, tostring(POS.X))
check("...said in the log", string.find(table.concat(SAID, "|"), "route:", 1, true) ~= nil)

-- the same with the Home button off and far asks off: the Mansion's portal, at the door
reset()
CFG.TravelHome, CFG.TravelFar = false, false
check("Home off, far off: through the Mansion's portal", R.go(HAUNTED_CASTLE, 0) == true and near(POS, CASTLE, 5), tostring(R.last))
check("...flown into the door where it REALLY stands, not its seed", near(FLIGHTS[#FLIGHTS], MANSION_DOOR.Position, 4),
    FLIGHTS[#FLIGHTS] and tostring(FLIGHTS[#FLIGHTS].X))
check("...touched first (the game's own handler)", TOUCHES >= 1, TOUCHES)
check("...then its question asked there, the answer written by us", called("ask at the door") and not called("ask from afar"))
check("...where it stands is kept", near(R.pads[linkOf(R.net(false), "the Mansion portal", MANSION_AT).id].hit, MANSION_DOOR.Position, 2))

-- the game's own handler takes the touch: no question needed
reset()
CFG.TravelHome, CFG.TravelFar, DOOR_TOUCH_WORKS = false, false, true
check("the door's own handler took the touch: through, nothing asked", R.go(HAUNTED_CASTLE, 0) == true and near(POS, CASTLE, 5)
    and not called("requestEntrance"))

-- A FAR ASK that the server answers: no flight at all
reset()
CFG.TravelHome, FAR_OK = false, true
check("far ask answered: at the Castle", R.go(HAUNTED_CASTLE, 0) == true and near(POS, CASTLE, 5), tostring(R.last))
check("...without one flight", #FLIGHTS == 0, #FLIGHTS)
check("...remembered that it works, with its date", R.farYes ~= nil and R.farNo == nil)
check("...kept in the file", FILES["bff_routes.json"].farYes == R.farYes)

-- A far ask the server does NOT answer: the door itself, and the far ask left
reset()
CFG.TravelHome = false
check("far ask refused: through at the door instead", R.go(HAUNTED_CASTLE, 0) == true and near(POS, CASTLE, 5), tostring(R.last))
check("...asked from afar ONCE, then at the door", count("ask from afar") == 1 and called("ask at the door"), table.concat(CALLS, ","))
check("...proven at a door: far asks left, with the date", R.farNo ~= nil)
POS = FLOATING_TURTLE
CALLS = {}
R.go(HAUNTED_CASTLE, 0)
check("...the next trip does not ask from afar again", not called("ask from afar"), table.concat(CALLS, ","))
NOW += 6 * 3600 + 700
POS = FLOATING_TURTLE
CALLS = {}
R.go(HAUNTED_CASTLE, 0)
check("...6 h later it is tried again (no verdict is for ever)", called("ask from afar"), table.concat(CALLS, ","))

-- a far ask refused where NO door then works: nothing is concluded about far asks
reset()
CFG.TravelHome, DOOR_OK = false, false
R.go(HAUNTED_CASTLE, 0)
check("far refused and the door too: no 6 h verdict on far asks", R.farNo == nil)
check("...that door left 5 min", linkOf(R.net(false), "the Mansion portal", MANSION_AT) == nil)

-- a server that answers, then pulls you back
reset()
CFG.TravelHome, CFG.TravelFar, DOOR_PULL = false, false, true
local mp = linkOf(R.net(false), "the Mansion portal", MANSION_AT)
check("pulled back after the answer: refused", R.ride(mp, 0, false) == false and R.pads[mp.id].landed == nil)

-- an old server that moves you itself and answers nothing
reset()
CFG.TravelHome, CFG.TravelFar, SERVER_MOVES = false, false, true
mp = linkOf(R.net(false), "the Mansion portal", MANSION_AT)
check("a server that moves you itself: through all the same", R.ride(mp, 0, false) == true and near(POS, CASTLE, 5))

-- NOT UNLOCKED (rip_indra not beaten): the doors are not planned, the pad is
reset()
UNLOCKS = { DefeatedIndraTrueForm = false }
net = R.net(false)
check("rip_indra not beaten: the Mansion and Hydra portals are not in the plan",
    linkOf(net, "the Mansion portal", MANSION_AT) == nil and linkOf(net, "the Hydra portal", HYDRA_AT) == nil)
check("...the Tiki pad still is", linkOf(net, "MapTeleportC", v3(-16799, 84, 291)) ~= nil)
check("...never asked", not called("requestEntrance"))

-- Castle -> Hydra: the Hydra portal, in the same room
reset()
POS = v3(-5018, 320, -3014)
CFG.TravelFar = false
check("Castle on the Sea -> Hydra: the Hydra portal", R.go(v3(5300, 1000, 100), 0) == true and near(POS, HYDRA_AT, 5),
    tostring(R.last))

-- THE SECOND SEA: the Cursed Ship by its door (user: "it flies the far ocean")
reset()
SEA, DOORS = 2, SECOND
POS = v3(-400, 70, 300)
net = R.net(false)
check("Second Sea: only its own links (no Third Sea portal)", #net.pads == 4 and linkOf(net, "the Mansion portal", MANSION_AT) == nil,
    #net.pads)
check("Kingdom of Rose -> inside the Cursed Ship: by its door", R.go(v3(900, 130, 32800), 0) == true
    and near(POS, SHIP_IN_AT, 5), tostring(R.last))
check("...flown to the ship's door (6k), not the 32k ocean", near(FLIGHTS[#FLIGHTS], SHIP_OUT.Position, 4),
    FLIGHTS[#FLIGHTS] and tostring(FLIGHTS[#FLIGHTS].Z))
check("...the old bug: the server's answer was thrown away - now you ARE moved", (POS - SHIP_IN_AT).Magnitude < 5)
-- and back out
CALLS, FLIGHTS = {}, {}
check("inside the Cursed Ship -> Kingdom of Rose: out by the door", R.go(v3(-400, 70, 300), 0) == true
    and near(POS, SHIP_OUT_AT, 5), tostring(R.last))
-- under level 1000 the game refuses the door: not planned
reset()
SEA, DOORS, LEVEL = 2, SECOND, 800
POS = v3(-400, 70, 300)
check("under level 1000: the ship's door is not planned (straight)", R.go(v3(900, 130, 32800), 0) == false
    and not called("requestEntrance"), tostring(R.last))
check("...and the log says how many links it knew", string.find(tostring(R.last), "straight flight", 1, true) ~= nil, R.last)

-- the panel's line
reset()
local w = R.words()
check("panel: links of this sea, the far ask's state", string.find(w, "links here 6", 1, true) ~= nil
    and string.find(w, "far ask", 1, true) ~= nil, w)

realPrint(all and "ALL PASS" or "SOME FAILED")
