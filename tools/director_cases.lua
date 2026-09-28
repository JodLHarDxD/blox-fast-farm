
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function run() LOG = {} huntStep() return table.concat(LOG, " | ") end

reset() HOLD = true FRUIT = { orig = "Kitsune-Kitsune" }
check("THE CHALICE: nothing else runs - no fruit, no elite, no hop", run() == "chalice")

reset() FRUIT = { orig = "Kitsune-Kitsune" } ELITE_BUSY = true
check("a fruit on the ground goes before an elite", run() == "grab Kitsune-Kitsune")

reset() ELITE_BUSY = true
check("no fruit, an elite to deal with: the elite, no hop", run() == "elite")

reset()
check("nothing here: hop, saying why", run() == "elite | hop: no elite up here")

reset() E.lookStart = NOW - 1
check("nothing here 1 s after a join: look a moment longer, no hop", run() == "elite")

reset() CFG.HuntHop = false
check("hop off: wait here", run() == "elite" and E.note:find("waiting", 1, true))

reset() CFG.HuntElite = false
check("elites off: not looked for; the fruit reason given", run() == "hop: no fruit worth it here")

print(all and "ALL PASS" or "SOME FAILED")
