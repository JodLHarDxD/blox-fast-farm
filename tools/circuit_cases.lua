
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- 1. nothing picked: the species for your level, alone (max level: the last row)
SEA = 3
CFG.Targets = {}
local l = circuit()
check("nothing picked: your level's species", #l == 1 and l[1].name == "Grand Devotee" and l[1].spot.X == 9591)

-- 2. another sea's species is skipped and named; this sea's kept, in order
SEA = 2
CFG.Targets = { "Stone", "Diamond" }
l = circuit()
check("Second Sea: Stone (Third Sea) skipped, Diamond kept with its boss spot",
    #l == 1 and l[1].name == "Diamond" and l[1].spot.X == -1569 and P.circuitSkipped[1] == "Stone")

-- 3. everything elsewhere: an empty circuit that says why
CFG.Targets = { "Stone" }
l = circuit()
check("all in another sea: empty, and the note names them", #l == 0 and P.circuitNote:find("Stone", 1, true))

-- 4. your order is the order it runs in
SEA = 3
CFG.Targets = { "Stone", "Pirate Millionaire" }
l = circuit()
check("order kept", #l == 2 and l[1].name == "Stone" and l[2].name == "Pirate Millionaire")

print(all and "ALL PASS" or "SOME FAILED")
