
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local CONTROL = { orig = "Control-Control", value = 120e6 }
local CASTLE = Vector3.new(-5072, 317, -3151)
local MANSION_SPOT = Vector3.new(-12471, 378, -7552)

-- nothing too good to lose: not held, nothing moves
reset()
check("no keeper: not held", keepHold(0) == false and #FLIGHTS == 0 and #LOCKS == 0 and #NOTES == 0)
check("...storage tried (the first look)", TRIES[1] == true)

-- a Control with no slot, Third Sea, no Home Point: to the Castle on the Sea
reset() LEFT = { CONTROL }
check("a keeper: held this step", keepHold(0) == true)
check("...no Home Point: flown to the Castle on the Sea (the shortest route)", #FLIGHTS == 1
    and FLIGHTS[1] == CASTLE and FLIGHT_OPTS[1] and FLIGHT_OPTS[1].portal == true, FLIGHTS[1] and FLIGHTS[1].X)
check("...locked there, state FRUIT HOLD", LOCKS[#LOCKS] == FLIGHTS[1] and STATES[#STATES] == "FRUIT HOLD")
check("...you are told once", #NOTES == 1 and string.find(NOTES[1], "Control-Control", 1, true) ~= nil, NOTES[1])
check("...its history entry turns HELD", LOG[1] == "set Control-Control held", LOG[1])
check("...the words: where, no hop, trade it", string.find(E.fruitNote, "the Castle on the Sea", 1, true)
    and string.find(E.fruitNote, "No hop", 1, true) and string.find(E.fruitNote, "other account", 1, true),
    E.fruitNote)

-- the next steps: held where it is, not flown again, told nothing new
NOW += 1
SAFE = true
keepHold(0)
check("next step: no second flight, no second notice", #FLIGHTS == 1 and #NOTES == 1 and #LOCKS == 2)
check("...the game says a safe zone: said", string.find(E.fruitNote, "In a safe zone", 1, true) ~= nil, E.fruitNote)
check("...no second HELD entry", #LOG == 1, #LOG)
check("...storage not tried again within 20 s", TRIES[2] == false, tostring(TRIES[2]))
NOW += 20
keepHold(0)
check("20 s on: storage tried again (a slot you freed counts)", TRIES[3] == true)

-- a respawn put you far away: flown back, never snapped there
ROOT.Position = Vector3.new(0, 10, 0)
keepHold(0)
check("far from the spot (a respawn): flown again, not snapped", #FLIGHTS == 2 and FLIGHTS[2] == CASTLE)

-- traded to your other account: gone from the backpack - logged, the hunt goes on
LEFT = {}
check("gone from the backpack: not held", keepHold(0) == false)
check("...its entry says gone (traded / stored by you)", LOG[#LOG] == "set Control-Control gone", LOG[#LOG])
check("...the hold forgotten", E.keepHeld == nil and E.keepAt == nil)
check("...told the hunt goes on", string.find(E.fruitNote, "goes on", 1, true) ~= nil, E.fruitNote)

-- already in a safe zone when it is picked: held right there
reset() LEFT = { CONTROL } SAFE = true
keepHold(0)
check("already in a safe zone: held where you are, no flight", #FLIGHTS == 0 and LOCKS[1] == Vector3.new(100, 50, 100)
    and string.find(E.fruitNote, "at where you are", 1, true) ~= nil, E.fruitNote)

-- your Home Point known: there first (the Home button gets you there)
reset() LEFT = { CONTROL } HOME = Vector3.new(-5000, 320, -3000)
keepHold(0)
check("a Home Point in this sea: to it first", FLIGHTS[1] == HOME and string.find(E.fruitNote, "your Home Point", 1, true) ~= nil,
    FLIGHTS[1] and FLIGHTS[1].X)

-- there, and the game says NOT a safe zone: the next spot
reset() LEFT = { CONTROL } SAFE = false
keepHold(0)
check("the Castle said not a safe zone: left, not held there", FLIGHTS[1] == CASTLE and #LOCKS == 0
    and E.keepTried and E.keepTried["the Castle on the Sea"] == true)
keepHold(0)
check("...the next step: the Mansion", FLIGHTS[2] == MANSION_SPOT, FLIGHTS[2] and FLIGHTS[2].X)

-- not the Third Sea, no Home Point: 300 up where you are
reset() LEFT = { CONTROL } SEA = 2
keepHold(0)
check("Second Sea, no Home: 300 up where you stand", FLIGHTS[1] == Vector3.new(100, 350, 100), FLIGHTS[1] and FLIGHTS[1].Y)
check("...the words say the safe zone is not known", string.find(E.fruitNote, "Safe zone not known", 1, true) ~= nil)

-- a keeper carried from before (no entry to turn): an entry of its own
reset() LEFT = { { orig = "Fresh-Fresh", value = nil } }
keepHold(0)
check("carried from before: its own HELD entry", LOG[2] == "add Fresh-Fresh held carried", table.concat(LOG, " | "))

-- stopped mid-flight: back at once, no lock
reset() LEFT = { CONTROL }
epoch = 1
check("stopped during the flight: back, still held, no lock", keepHold(0) == true and #LOCKS == 0)
epoch = 0

print(all and "ALL PASS" or "SOME FAILED")
