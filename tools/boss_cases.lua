
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
local function has(s) return string.find(calls(), s, 1, true) ~= nil end
local REAPER_AT = vec(-9500, 140, 6000)

reset()
ME = INSIDE
UP["Cake Prince"] = { SKY, "parked" }
check("up, you near it: fought, the hunt stays on", bossStep(0) == true and calls() == "fight Cake Prince" and CFG.Hunt, calls())

reset()
ME = INSIDE
UP["Cake Prince"] = { SKY, "here" }
KILL = true
P.bossBack = "circuit"
bossStep(0)
check("down: the hunt ends, the mode you had comes back (the circuit)",
    calls() == "fight Cake Prince,hunt false,mode circuit true", calls())
check("...and it is remembered once only", P.bossBack == nil)

reset()
UP["Soul Reaper"] = { REAPER_AT, "parked" }
CFG.HuntBoss = "Soul Reaper"
KILL = true
bossStep(0)
check("Soul Reaper far off: fought where it is (no mirror); down, no mode before: the hunt ends",
    calls() == "fight Soul Reaper,hunt false", calls())

reset()
P.bossBack = "elite"
check("not up, just looked: waits a moment (the world arriving)", bossStep(0) == true and calls() == "", calls())
NOW += 10
bossStep(0)
check("...not up 8 s on: done, back to your mode - never a hop", calls() == "hunt false,mode elite true", calls())

reset()
UP["Darkbeard"] = { vec(3800, 20, -3500), "parked" }
CFG.HuntBoss = "Darkbeard"
bossStep(0)
UP["Darkbeard"] = nil
NOW += 5
bossStep(0)
check("seen, then gone: a moment from when it was last seen", not has("hunt false"), calls())
NOW += 10
bossStep(0)
check("...then done", has("hunt false"), calls())

reset()
CFG.HuntBoss = ""
P.bossBack = "random"
bossStep(0)
check("no boss named: off at once, back to your mode", calls() == "hunt false,mode random true", calls())

reset()
ME = INSIDE
UP["Cake Prince"] = { SKY, "parked" }
KILL = true
P.bossBack = "raid"
bossStep(0)
check("raid comes back ONLY when it was your mode before the card", calls()
    == "fight Cake Prince,hunt false,mode raid true", calls())

-- THE CAKE LOAF MIRROR (2026-11-26): never a flight to the sky spot.
for _, b in ipairs({ "Cake Prince", "Dough King" }) do
    reset()
    CFG.HuntBoss = b
    UP[b] = { SKY, "parked" }
    bossStep(0)
    check(b .. ", far: to the Cake Loaf, into the mirror, touched - not fought from outside",
        calls() == "fly -2124,89,-12401,fly -2100,150,-12420 noroute,touch 0,touch 1", calls())
    check("...inside the dimension now", (ME - SKY).Magnitude < 1500)
    bossStep(0)
    check("...then fought there", has("fight " .. b))
    check("...and never a flight to its spot in the sky", not has("fly -2000,4533"), calls())
end

reset()
ME = vec(-2120, 70, -12400)
MIRROR = { Position = MIRROR_AT, IsA = function(_, c) return c == "BasePart" end }
UP["Cake Prince"] = { SKY, "parked" }
bossStep(0)
check("at the Cake Loaf, the mirror loaded: straight into it", calls()
    == "fly -2100,150,-12420 noroute,touch 0,touch 1", calls())

reset()
OPEN = false
UP["Dough King"] = { SKY, "parked" }
CFG.HuntBoss = "Dough King"
P.bossBack = "circuit"
bossStep(0)
check("mirror shut: tried, not fought, the hunt still on (1/3)", not has("fight") and CFG.Hunt
    and string.find(E.note, "1/3", 1, true) ~= nil, E.note)
bossStep(0)
bossStep(0)
check("...three times: given up, back to your mode - never the sky spot",
    has("hunt false,mode circuit true") and not has("fly -2000,4533"), calls())

reset()
STREAMS = false
UP["Cake Prince"] = { SKY, "parked" }
bossStep(0)
check("the mirror never loads: said, counted as a try", string.find(E.note, "did not load", 1, true) ~= nil
    and not has("touch"), E.note)

reset()
UP["Cake Prince"] = { SKY, "parked" }
local fly0 = flyTo
flyTo = function(pos, opts) fly0(pos, opts) epoch += 1 end
bossStep(0)
flyTo = fly0
check("stopped on the way: nothing touched, no try counted", not has("touch") and (E.mirrorFails or 0) == 0, calls())
epoch = 0

reset()
ME = vec(-2120, 70, -12400)
MIRROR = { Position = MIRROR_AT, IsA = function(_, c) return c == "BasePart" end }
UP["Cake Prince"] = { SKY, "parked" }
flyTo = function(pos, opts) fly0(pos, opts) epoch += 1 end
bossStep(0)
flyTo = fly0
check("stopped on the flight INTO the mirror: not touched", not has("touch") and (E.mirrorFails or 0) == 0, calls())
epoch = 0

io_print(all and "ALL PASS" or "SOME FAILED")
