
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local CONTROL = { orig = "Control-Control", value = 120e6 }

-- nothing too good to lose: not held, nothing moves
reset()
check("no keeper: not held", keepHold(0) == false and #FLIGHTS == 0 and #LOCKS == 0 and #NOTES == 0)
check("...storage tried (the first look)", TRIES[1] == true)

-- a Control with no slot, Third Sea: to the Mansion, held there
reset() LEFT = { CONTROL } SAFE = true
check("a keeper: held this step", keepHold(0) == true)
check("...flown to the Mansion (a portal when it beats flying)", #FLIGHTS == 1
    and FLIGHTS[1] == MANSION + Vector3.new(0, 3, 0), FLIGHTS[1] and FLIGHTS[1].X)
check("...locked there, state FRUIT HOLD", LOCKS[#LOCKS] == FLIGHTS[1] and STATES[#STATES] == "FRUIT HOLD")
check("...you are told once", #NOTES == 1 and string.find(NOTES[1], "Control-Control", 1, true) ~= nil, NOTES[1])
check("...its history entry turns HELD", LOG[1] == "set Control-Control held", LOG[1])
check("...the words: no hop, trade it, in a safe zone", string.find(E.fruitNote, "No hop", 1, true)
    and string.find(E.fruitNote, "other account", 1, true) and string.find(E.fruitNote, "In a safe zone", 1, true),
    E.fruitNote)

-- the next steps: held where it is, not flown again, told nothing new
NOW += 1
keepHold(0)
check("next step: no second flight, no second notice", #FLIGHTS == 1 and #NOTES == 1 and #LOCKS == 2)
check("...no second HELD entry", #LOG == 1, #LOG)
check("...storage not tried again within 20 s", TRIES[2] == false, tostring(TRIES[2]))
NOW += 20
keepHold(0)
check("20 s on: storage tried again (a slot you freed counts)", TRIES[3] == true)

-- a respawn put you far away: flown back, never snapped there
ROOT.Position = Vector3.new(0, 10, 0)
keepHold(0)
check("far from the spot (a respawn): flown again, not snapped", #FLIGHTS == 2
    and FLIGHTS[2] == MANSION + Vector3.new(0, 3, 0))

-- traded to your other account: gone from the backpack - logged, the hunt goes on
LEFT = {}
check("gone from the backpack: not held", keepHold(0) == false)
check("...its entry says gone (traded / stored by you)", LOG[#LOG] == "set Control-Control gone", LOG[#LOG])
check("...the hold forgotten", E.keepHeld == nil and E.keepAt == nil)
check("...told the hunt goes on", string.find(E.fruitNote, "goes on", 1, true) ~= nil, E.fruitNote)

-- not the Third Sea: 300 up where you are
reset() LEFT = { CONTROL } SEA = 2 SAFE = false
keepHold(0)
check("Second Sea: 300 up where you stand", FLIGHTS[1] == Vector3.new(100, 350, 100), FLIGHTS[1] and FLIGHTS[1].Y)
check("...the words say NOT in a safe zone", string.find(E.fruitNote, "NOT in a safe zone", 1, true) ~= nil)

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
