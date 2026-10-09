-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end
-- ROOT.Position mirrors writes to ROOT.CFrame (stubs); reset both.
local function at(p)
    rawset(ROOT, "CFrame", cf(p))
    rawset(ROOT, "Position", p)
end

-- THE LOCK, as before: no floor.
lockAt(vec(10, -30, 10))
check("no floor: held where asked (under the sea is allowed outside a sea fight)", near(lockCF.Position.Y, -30))

-- THE WATER AS ROCK (SEA EVENTS): a sea fight's floor.
P.floorY = 9
lockAt(vec(10, -30, 10))
check("a sea fight: asked to go under the water - held ON it (its floor)", near(lockCF.Position.Y, 9) and near(lockCF.Position.X, 10))
lockAt(vec(10, 40, 10), vec(50, 0, 10))
check("...above it: held where asked, facing the target", near(lockCF.Position.Y, 40))
lockAt(vec(10, 2, 10), vec(50, 0, 10))
check("...under it while facing a target: still held on the floor", near(lockCF.Position.Y, 9))

-- Every frame: whatever the lock says, never under the floor.
lockCF, lastWritten = cf(vec(0, -20, 0)), vec(0, -20, 0)
at(vec(0, -20, 0))
bodyHeartbeat()
check("every frame: a lock under the water is lifted onto it, the body written there",
    near(lockCF.Position.Y, 9) and near(ROOT.CFrame.Position.Y, 9), lockCF.Position.Y)

-- A KNOCKBACK / PULL (a Terrorshark's): 120 studs - adopted before, now refused in a sea fight.
lockCF, lastWritten = cf(vec(0, 40, 0)), vec(0, 40, 0)
P.keepLock = true
at(vec(120, 40, 0))
bodyHeartbeat()
check("a sea fight: thrown 120 studs - NOT adopted, the body back at the lock",
    near(ROOT.CFrame.Position.X, 0) and near(lockCF.Position.X, 0), ROOT.CFrame.Position.X)
-- A respawn / teleport (thousands of studs): still followed.
at(vec(20000, 40, 0))
bodyHeartbeat()
check("...a respawn far away (20,000): followed, never dragged back across the map", near(lockCF.Position.X, 20000))
-- Outside a sea fight: a 120-stud move is adopted as before.
P.keepLock, P.floorY = nil, nil
lockCF, lastWritten = cf(vec(0, 40, 0)), vec(0, 40, 0)
at(vec(120, 40, 0))
bodyHeartbeat()
check("outside a sea fight: a 120-stud move by the game adopted, as before", near(lockCF.Position.X, 120))

print(all and "ALL PASS" or "SOME FAILED")
