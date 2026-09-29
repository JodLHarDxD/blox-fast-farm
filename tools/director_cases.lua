
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function run() LOG = {} huntStep() return table.concat(LOG, " | ") end
local KITSUNE = { orig = "Kitsune-Kitsune" }
local PIG = { names = { "Pink Pig Berry" } }

-- THE CHALICE, whichever hunt is on
for _, k in ipairs({ "elite", "fruit", "berry" }) do
    reset() CFG.HuntKind = k HOLD = true FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true
    check("THE CHALICE (" .. k .. " hunt): nothing else runs, no hop", run() == "chalice")
end

-- ONE HUNT AT A TIME: the one switched on, nothing else, whatever is lying about
reset() CFG.HuntKind = "elite" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true
local got = run()
check("elite hunt: the elite - a fruit and a berry lying here are left alone", got == "elite", got)
reset() CFG.HuntKind = "fruit" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true
got = run()
check("fruit hunt: the fruit - no elite looked for, no berry", got == "grab Kitsune-Kitsune", got)
reset() CFG.HuntKind = "berry" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true
got = run()
check("berry hunt: the berry - no fruit, no elite", got == "berry Pink Pig Berry", got)

-- nothing for the chosen hunt: hop, saying why
reset()
got = run()
check("elite hunt, none up: hop", got == "elite | hop: no elite up here", got)
reset() CFG.HuntKind = "fruit" BERRY = PIG
got = run()
check("fruit hunt, no fruit (a berry here): hop", got == "hop: no fruit worth it here", got)
reset() CFG.HuntKind = "berry" FRUIT = KITSUNE
got = run()
check("berry hunt, no berry (a fruit here): hop", got == "hop: no berry you want here", got)

reset() CFG.HuntKind = "berry" E.lookStart = NOW - 1
check("1 s after a join: look a moment longer, no hop", run() == "")

reset() CFG.HuntKind = "berry" CFG.HuntHop = false
check("hop off: wait here", run() == "" and E.note:find("waiting", 1, true))

print(all and "ALL PASS" or "SOME FAILED")
