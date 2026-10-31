
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local TIKI = v3(-16000, 20, 600)
local HYDRA = v3(5300, 1000, 100)
local function reset()
    POS, SEA, epoch = TIKI, 3, 0
    ROUTES, NESTED, BOOM, MOVE_TO, LEGS, SAID = {}, false, false, nil, 0, {}
    CFG.TravelRoutes = true
    P.inRoute = false
    stats.flights, stats.hops = 0, 0
end

-- THE USER'S TRIP: a long one with no options = routed
reset()
P.flyTo(HYDRA)
check("Tiki -> Hydra, no options: routed (every trip, not only the fruit hunt)", #ROUTES == 1, #ROUTES)

reset()
flyTo(HYDRA, { stream = "Hydra Enforcer" })
check("...other options, no portal said: routed", #ROUTES == 1, #ROUTES)

reset()
flyTo(HYDRA, { portal = false })
check("portal = false (the boat, the sea hunts, raids): never routed", #ROUTES == 0, #ROUTES)

reset()
CFG.TravelRoutes = false
flyTo(HYDRA)
check("switch off: not routed", #ROUTES == 0, #ROUTES)
flyTo(HYDRA, { portal = true })
check("...but a trip that asks (the fruit hunt's own switch): routed", #ROUTES == 1, #ROUTES)

reset()
POS = v3(4500, 1000, 100)
flyTo(HYDRA)
check("a short trip (under 1500): never routed", #ROUTES == 0, #ROUTES)

-- The route's own legs fly too (into a pad): never routed again.
reset()
NESTED = true
flyTo(HYDRA)
check("a flight inside a route: not routed again", #ROUTES == 1, #ROUTES)
check("...and routing is open again after", P.inRoute == false)

-- A route that breaks: said, routing open again, the trip goes on.
reset()
BOOM = true
local ok = pcall(flyTo, HYDRA)
check("a route that errors: the trip goes on (no error out of flyTo)", ok)
check("...said", string.find(table.concat(SAID, "|"), "route broke", 1, true) ~= nil, table.concat(SAID, "|"))
check("...routing open again", P.inRoute == false)
BOOM = false
flyTo(HYDRA)
check("...the next trip routed", #ROUTES == 2, #ROUTES)

-- Moved by the route: the flight goes on from where it put you.
reset()
MOVE_TO = v3(5250, 1000, 100)
flyTo(HYDRA)
check("moved next to the goal: an instant hop the rest, no flight", stats.flights == 0 and stats.hops == 1,
    string.format("flights %d hops %d", stats.flights, stats.hops))

-- The Third Sea has no requestEntrance leg; the First / Second still try it.
reset()
flyTo(HYDRA)
check("Third Sea, route did nothing: no requestEntrance leg", LEGS == 0, LEGS)
reset()
SEA = 2
flyTo(HYDRA)
check("Second Sea, route did nothing: the portal leg tried", LEGS == 1, LEGS)

-- Under the sea: never routed (the submarine's way).
reset()
POS = v3(-16000, -2000, 600)
flyTo(HYDRA + v3(0, -3000, 0))
check("down at Submerged Island: not routed", #ROUTES == 0, #ROUTES)

realPrint(all and "ALL PASS" or "SOME FAILED")
