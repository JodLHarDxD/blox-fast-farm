
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function logged(s)
    for _, l in ipairs(LOG) do if string.find(l, s, 1, true) then return true end end
    return false
end
local FOREST = { name = "Forest Pirate", root = { Position = Vector3.new(-13220, 428, -7750) } }

-- ---------------------------------------------------------------- WHERE IT LIES
reset({ noFolder = true })
check("no FireFlowers folder: nothing lying", #flowersLying() == 0)

reset()
local nested = addFlower(Vector3.new(5, 1, 5), { part = "nested" })
local list = flowersLying()
check("a flower with no PrimaryPart (MeshPart inside): found, at its part",
    #list == 1 and list[1].model == nested and list[1].pos.X == 5)
addFlower(Vector3.new(9, 1, 9), { part = "none" })
check("a model with no part at all: not a flower to fly to", #flowersLying() == 1)
E.flowerSkip[nested] = true
check("one given up on (3 grabs): not lying any more", #flowersLying() == 0)

-- ---------------------------------------------------------------- THE GRAB
-- 1. held like a player: picked, counted, said
reset()
local m = addFlower(Vector3.new(0, 0, 0))
local res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("held: picked, your count 2 -> 3", res == "picked" and HAVE == 3 and E.flowerHave == 3, res)
check("picked: tallied and a toast", (E.tally.flowers or 0) == 1 and logged("notify Fire Flower"),
    tostring(E.tally.flowers))
check("picked: the note says how", string.find(E.flowerNote, "PICKED", 1, true) ~= nil
    and string.find(E.flowerNote, "hold", 1, true) ~= nil, E.flowerNote)

-- 2. the game refuses a held prompt, takes the instant fire: third try
reset({ hold = false, fire = true })
m = addFlower(Vector3.new(0, 0, 0))
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("hold refused, fireproximityprompt every third try: picked",
    res == "picked" and string.find(E.flowerNote, "fireproximityprompt", 1, true) ~= nil, E.flowerNote)

-- 3. nothing picks it: stuck after ~15 s, and says so
reset({ hold = false, fire = false })
m = addFlower(Vector3.new(0, 0, 0))
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("never picked: stuck, gave up within ~16 s", res == "stuck" and CLOCK < 17 and CLOCK > 14, CLOCK)
check("stuck: the note says it", string.find(E.flowerNote, "could not pick", 1, true) ~= nil, E.flowerNote)

-- 4. no prompt in it at all: stuck, named
reset({ hold = true })
m = addFlower(Vector3.new(0, 0, 0), { prompt = false })
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("no prompt in the flower: stuck, '(no prompt in it)'", res == "stuck"
    and string.find(E.flowerNote, "no prompt", 1, true) ~= nil, E.flowerNote)

-- 5. inventory not readable, the flower left the folder: picked
reset({ readable = false })
m = addFlower(Vector3.new(0, 0, 0))
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("count unreadable, flower gone: picked", res == "picked", res)

-- 6. the count goes up a second after the flower flies to you: still picked
reset({ late = 1.2 })
m = addFlower(Vector3.new(0, 0, 0))
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("count up 1.2 s after the flower left: picked (waited for it)", res == "picked" and HAVE == 3, res)

-- 7. stopped mid-grab
reset({ hold = false })
m = addFlower(Vector3.new(0, 0, 0))
epoch = 1
res = grabFlower({ model = m, pos = Vector3.new(0, 0, 0) }, 0)
check("stopped: out at once", res == "stopped", res)

-- ---------------------------------------------------------------- THE STEP
-- 8. not the Third Sea: the hunt stops, saying why (a hop cannot change seas)
reset({ sea = 2 })
local busy = flowerStep(0)
check("Second Sea: stopped, saying why", busy == true and logged("stop") and #FIGHTS == 0)

-- 9. a flower lying: picked, then leave this server for longer
reset()
addFlower(Vector3.new(0, 0, 0))
busy = flowerStep(0)
check("flower picked: leave, kept away 10 min longer", busy == false and E.keepAway == 600
    and string.find(E.why, "picked", 1, true) ~= nil, tostring(E.why))

-- 10. one that cannot be picked: tried 3 times, then leave (a flower came:
--     none here for 5-15 min anyway)
reset({ hold = false, fire = false })
local stuckOne = addFlower(Vector3.new(0, 0, 0))
local a, b = flowerStep(0), flowerStep(0)
local c3 = flowerStep(0)
check("unpickable: again, again, then leave", a == true and b == true and c3 == false
    and E.flowerSkip[stuckOne] == true and E.keepAway == 600, tostring(c3))

-- 11. nothing lying, enemies here: fought one at a time, no magnet
reset()
LOADED["Forest Pirate"] = FOREST
busy = flowerStep(0)
local f1 = FIGHTS[1]
check("no flower: a fight - flower kind, both species, a break check", busy == true and f1
    and f1.cur.flower == true and type(f1.cur.breakIf) == "function"
    and f1.names["Forest Pirate"] and f1.names["Mythological Pirate"])

-- 12. THE CLOCK STARTS AT THE FIRST KILL, not the join
reset()
LOADED["Forest Pirate"] = FOREST
flowerStep(0)                                  -- at the camp, t = 0
CLOCK = 100
check("100 s in, nothing killed yet: stay", flowerStep(0) == true)
stats.kills = 1                                -- the first kill, at t = 100
check("first kill at 100 s: stay", flowerStep(0) == true and E.flowerFirstKill == 100,
    tostring(E.flowerFirstKill))
CLOCK = 219
check("119 s after the first kill (219 s after arriving): stay", flowerStep(0) == true)
CLOCK = 220
busy = flowerStep(0)
check("120 s after the first kill: leave, 'no Fire Flower in 2 min of killing'", busy == false
    and string.find(E.why or "", "2 min", 1, true) ~= nil and E.keepAway == nil, tostring(E.why))

-- 13. the slider: 3 min
reset()
CFG.FlowerGiveUp = 3
LOADED["Forest Pirate"] = FOREST
stats.kills = 1
flowerStep(0)
CLOCK = 179
check("3 min set: 179 s after the first kill, stay", flowerStep(0) == true)
CLOCK = 181
check("3 min set: 181 s, leave", flowerStep(0) == false)

-- 14. nothing ever dies: the clock would never start - leave after 3 min at the camp
reset()
LOADED["Forest Pirate"] = FOREST
flowerStep(0)
CLOCK = 179
check("no kill, 179 s at the camp: stay", flowerStep(0) == true)
CLOCK = 181
busy = flowerStep(0)
check("no kill, 181 s at the camp: leave, 'nothing died here in 3 min'", busy == false
    and string.find(E.why or "", "nothing died", 1, true) ~= nil, tostring(E.why))

-- 15. hop off: never leave - keep killing here, the clock starts again
reset()
CFG.HuntHop = false
LOADED["Forest Pirate"] = FOREST
stats.kills = 1
flowerStep(0)
CLOCK = 130
busy = flowerStep(0)
check("hop off, 2 min passed: still here, still fighting, clock restarted", busy == true
    and #FIGHTS == 2 and E.flowerFirstKill == nil, tostring(E.flowerFirstKill))
addFlower(Vector3.new(0, 0, 0))
busy = flowerStep(0)
check("hop off, flower picked: stay here", busy == true and HAVE == 3)

-- 16. the fight breaks off: a flower lying, or the time is up
reset()
LOADED["Forest Pirate"] = FOREST
flowerStep(0)
local brk = FIGHTS[1].cur.breakIf
check("break check: nothing yet = keep fighting", brk() == false)
addFlower(Vector3.new(0, 0, 0))
check("break check: a flower lies there = break off now", brk() == true)
reset()
LOADED["Forest Pirate"] = FOREST
stats.kills = 1
flowerStep(0)
brk = FIGHTS[1].cur.breakIf
CLOCK = 121
check("break check: 2 min since the first kill = break off", brk() == true)

-- 17. none of them loaded: fly to their camps in turn
reset()
flowerStep(0)
flowerStep(0)
check("none loaded: to the Forest Pirates, then the Mythological Pirates",
    LOG[1] == "fly Forest Pirate" and LOG[2] == "fly Mythological Pirate" and #FIGHTS == 0,
    table.concat(LOG, " | "))

-- 18. THEY NEVER LOAD: the camps flown between for ever would never start the
--     clock - 3 min after first reaching them, the next server
reset()
flowerStep(0)                                  -- arrives at t = 0
CLOCK = 179
check("never loaded, 179 s after arriving: still looking", flowerStep(0) == true)
CLOCK = 181
busy = flowerStep(0)
check("never loaded, 181 s: leave ('nothing died here in 3 min')", busy == false
    and string.find(E.why or "", "nothing died", 1, true) ~= nil, tostring(E.why))

realPrint(all and "ALL PASS" or "SOME FAILED")
