
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    io_print((cond and "PASS " or "FAIL ") .. name)
    if not cond then io_print("  " .. tostring(detail)) all = false end
end
local function calls()
    local out = {}
    for _, l in ipairs(LOG) do if not string.find(l, "^print") then table.insert(out, l) end end
    return table.concat(out, ",")
end

reset()
UP["Cake Prince"] = { "pos", "parked" }
check("up: fought, the hunt stays on", bossStep(0) == true and calls() == "fight Cake Prince" and CFG.Hunt, calls())

reset()
UP["Cake Prince"] = { "pos", "here" }
KILL = true
P.bossBack = "circuit"
bossStep(0)
check("down: the hunt ends, the mode you had comes back (the circuit)",
    calls() == "fight Cake Prince,hunt false,mode circuit true", calls())
check("...and it is remembered once only", P.bossBack == nil)

reset()
UP["Soul Reaper"] = { "pos", "parked" }
CFG.HuntBoss = "Soul Reaper"
KILL = true
bossStep(0)
check("down, no mode before the card: the hunt ends, nothing else (the farm stops itself)",
    calls() == "fight Soul Reaper,hunt false", calls())

reset()
P.bossBack = "elite"
check("not up, just looked: waits a moment (the world arriving)", bossStep(0) == true and calls() == "", calls())
NOW += 10
bossStep(0)
check("...not up 8 s on: done, back to your mode - never a hop", calls() == "hunt false,mode elite true", calls())

reset()
UP["Darkbeard"] = { "pos", "parked" }
CFG.HuntBoss = "Darkbeard"
bossStep(0)
UP["Darkbeard"] = nil
NOW += 5
bossStep(0)
check("seen, then gone: a moment from when it was last seen", not string.find(calls(), "hunt false", 1, true), calls())
NOW += 10
bossStep(0)
check("...then done", string.find(calls(), "hunt false", 1, true) ~= nil, calls())

reset()
CFG.HuntBoss = ""
P.bossBack = "random"
bossStep(0)
check("no boss named: off at once, back to your mode", calls() == "hunt false,mode random true", calls())

reset()
UP["Cake Prince"] = { "pos", "parked" }
KILL = true
P.bossBack = "raid"
bossStep(0)
check("raid comes back ONLY when it was your mode before the card", calls()
    == "fight Cake Prince,hunt false,mode raid true", calls())

io_print(all and "ALL PASS" or "SOME FAILED")
