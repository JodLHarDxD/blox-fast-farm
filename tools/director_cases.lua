
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
for _, k in ipairs({ "elite", "fruit", "berry", "recipe", "flower", "sail" }) do
    reset() CFG.HuntKind = k HOLD = true FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true RECIPE_BUSY = true
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

reset() CFG.HuntKind = "recipe" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true RECIPE_BUSY = true
got = run()
check("recipe hunt: the Barista Cousin only - no fruit, berry, elite", got == "recipe", got)
reset() CFG.HuntKind = "recipe" FRUIT = KITSUNE
got = run()
check("recipe hunt, not the one picked: hop, naming it", got == "recipe | hop: he teaches Pure Red here - not one you picked", got)

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

-- THE FIRE FLOWER HUNT: only it; nothing here = hop; a flower came = hop, kept away longer
reset() CFG.HuntKind = "flower" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true FLOWER_BUSY = true
got = run()
check("flower hunt: the flowers only - no fruit, berry, elite", got == "flower", got)
reset() CFG.HuntKind = "flower"
got = run()
check("flower hunt, 2 min of killing and none: hop", got == "flower | hop: no Fire Flower in 2 min of killing", got)
reset() CFG.HuntKind = "flower" FLOWER_WHY = "Fire Flower picked - none here for 5-15 min" FLOWER_KEEP = 600
got = run()
check("flower picked: hop, this server kept away 600 s longer", got == "flower | hop: Fire Flower picked - none here for 5-15 min +600", got)

reset() CFG.HuntKind = "berry" CFG.HuntHop = false
check("hop off: wait here", run() == "" and E.note:find("waiting", 1, true))

-- SEA TRAVEL (user, 2026-10-10): the sea step with its kind, nothing else, never a hop
reset() CFG.HuntKind = "sail" FRUIT = KITSUNE BERRY = PIG ELITE_BUSY = true
got = run()
check("sea travel: the sea step (kind \"sail\") only - no fruit, berry, elite, hop", got == "sea sail", got)

print(all and "ALL PASS" or "SOME FAILED")
