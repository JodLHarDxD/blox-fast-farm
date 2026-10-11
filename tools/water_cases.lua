-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1e-6 end
local function at(p)
    place(p)
    lockCF, lastWritten = cf(p), p
end
local LINE = 4          -- the sea's top (Y 0) + 4: the root over the feet

-- THE WATER LINE: where the sea is, its top + 4.
check("over the sea: the line is its top + 4", near(P.waterLine(vec(100, 50, 100)), LINE), P.waterLine(vec(100, 50, 100)))
check("off the slab (no sea there): no line", P.waterLine(vec(15000, 50, 0)) == nil)
check("down in the deep sea (Submerged Island): no line - it has its own floor",
    P.waterLine(vec(0, -1900, 0)) == nil)
SLAB.Size = vec(20000, 80, 20000)
check("before walk on water raises the slab (80): still the surface", near(P.waterLine(vec(0, 0, 0)), LINE),
    P.waterLine(vec(0, 0, 0)))
SLAB.Size = vec(20000, 112, 20000)

-- THE LOCK, EVERY MODE (not only a sea fight).
P.floorY = nil
lockAt(vec(10, -30, 10))
check("any mode: asked to hold under the water - held ON it", near(lockCF.Position.Y, LINE), lockCF.Position.Y)
lockAt(vec(10, 60, 10))
check("...above it: held where asked", near(lockCF.Position.Y, 60))
P.floorY = 9
lockAt(vec(10, -30, 10))
check("a sea fight's own floor is higher: that one", near(lockCF.Position.Y, 9))
P.floorY = nil
lockAt(vec(0, -1950, 0))
check("the deep sea: held where asked (not lifted 2,000 studs)", near(lockCF.Position.Y, -1950))

-- Every frame: the game throws the body under the water (adopted: > 50 studs).
at(vec(0, 40, 0))
place(vec(0, -80, 0))
bodyHeartbeat()
check("thrown under the water: followed, then lifted onto it", near(ROOT.Position.Y, LINE), ROOT.Position.Y)

-- A FLIGHT to a point under the water (the Legendary Sword Dealer's model
-- under Kingdom of Rose): never written under the water, on the way or at the end.
at(vec(0, 100, 0))
MINY = math.huge
local ok = flyTo(vec(2000, -60, 0))
check("a flight to a point under the water: never under it on the way (lowest " .. MINY .. ")", MINY >= LINE - 1e-6)
-- (a flight stops writing within its 3-stud arrival; the lock holds the exact point)
check("...it arrives over that point, on the water", ok and (ROOT.Position - vec(2000, LINE, 0)).Magnitude < 3
    and ROOT.Position.Y >= LINE - 1e-6, ROOT.Position.X .. ", " .. ROOT.Position.Y)
check("...and is held there", near(lockCF.Position.Y, LINE), lockCF.Position.Y)

-- A flight that starts under the water: lifted on the first frame.
at(vec(0, -40, 0))
MINY = math.huge
flyTo(vec(1500, 80, 0))
check("a flight that starts under the water: every frame on or over it (lowest " .. MINY .. ")", MINY >= LINE - 1e-6)

-- An instant hop (under 150 studs) to a point under the water.
at(vec(0, 50, 0))
MINY = math.huge
flyTo(vec(60, -40, 0))
check("an instant hop under the water: written on it", near(MINY, LINE) and near(lockCF.Position.Y, LINE), MINY)

-- No sea there: a low point is reached as asked.
at(vec(15000, 50, 0))
flyTo(vec(15100, -30, 0))
check("off the slab: a low point reached as asked", near(ROOT.Position.Y, -30), ROOT.Position.Y)

-- The deep sea: Submerged Island has its own floor - nothing lifted.
at(vec(9900, -1900, 9600))
MINY = math.huge
flyTo(vec(10500, -1950, 9600))
check("the deep sea: a flight down there stays down there", MINY < -1890 and math.abs(ROOT.Position.Y + 1950) < 3
    and near(lockCF.Position.Y, -1950), MINY)

print(all and "ALL PASS" or "SOME FAILED")
