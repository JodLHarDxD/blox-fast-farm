
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function reset()
    CFG.HeightMode, CFG.StayHigh, CFG.HeightSafe = "auto", true, 60
    wantPose, pileSide, LOCK = "safe", v3(1, 0, 0), nil
end

-- 1. PORT TOWN: the pile held over the pond at Y 40 -> you 60 over them
reset()
pileCentre = v3(0, 40, 0)
pile = { enemy(v3(3, 40, 0)), enemy(v3(-3, 40, 0)) }
check("Port Town: 60 set = 60 over the pile (Y 100)", poseTarget().Y == 100, poseTarget().Y)

-- 2. one the magnet does not own stays up on the ledge (Y 80): 60 over IT
pile = { enemy(v3(3, 40, 0)), enemy(v3(40, 80, 10)) }
check("an enemy left on the ledge (Y 80): 60 over the highest one (Y 140)", poseTarget().Y == 140, poseTarget().Y)

-- 3. always stay above: a melee skill / key M1 asks for close -> still high
pile = { enemy(v3(3, 40, 0)) }
setPose("melee")
check("staying above: 'close' is refused, still 60 over", wantPose == "safe" and poseTarget().Y == 100, wantPose)

-- 4. switch off: close comes back (3 up, 5 out)
CFG.StayHigh = false
setPose("melee")
local t = poseTarget()
check("switch off: close = 3 up, 5 to the side", wantPose == "melee" and t.Y == 43 and t.X == 5, t.Y .. "," .. t.X)

-- 5. 120 up is possible now, and holds
reset()
CFG.HeightSafe = 120
check("120 over the pile", poseTarget().Y == 160, poseTarget().Y)

-- 5b. a fight with its own height (SEA EVENTS: 30 over a Terrorshark), then back to yours
pileCur = { height = function() return 30 end }
check("a sea event's own height: 30 over it, not your 120", poseTarget().Y == 70, poseTarget().Y)
pileCur = nil
check("...the fight over: your 120 again", poseTarget().Y == 160, poseTarget().Y)

-- 6. fixed mode counts from the highest enemy too
CFG.HeightMode, CFG.HeightFixed = "fixed", 30
pile = { enemy(v3(0, 40, 0)), enemy(v3(0, 55, 0)) }
check("fixed: 30 over the highest (Y 85)", poseTarget().Y == 85, poseTarget().Y)

-- 7. THE REMOTE HIT: 60 up with a 60 reach used to name nobody
reset()
pileCentre = v3(0, 40, 0)
pile = { enemy(v3(3, 40, 0)), enemy(v3(-3, 40, 0)), enemy(v3(0, 40, 3)) }
ME.Position = v3(0, 100, 0)
check("60 up: the remote hit names the whole pile (was 0)", #hitTargets() == 3, #hitTargets())
ME.Position = v3(0, 160, 0)
check("120 up: still the whole pile", #hitTargets() == 3, #hitTargets())

-- 8. an enemy that is not in the pile is never named, however far the reach
pileCentre = v3(0, 40, 0)
pile = { enemy(v3(3, 40, 0)) }
check("only pile members are named", #hitTargets() == 1)

-- 9. WHO IS NAMED FIRST TAKES TURNS. The pile is ordered nearest-spawn first,
--    so a hit path that lands on the first few only (one fruit click per
--    swing, a cap per call) starved the back of the pile: 3 s with no damage
--    = put back to its spawn mid-fight (the scatter), and the nearer ones
--    that were hit "proved" a pull limit that was never there.
pileCentre = v3(0, 40, 0)
ME.Position = v3(0, 100, 0)
local a9, b9, c9 = enemy(v3(3, 40, 0)), enemy(v3(-3, 40, 0)), enemy(v3(0, 40, 3))
pile = { a9, b9, c9 }
local firsts = {}
for _ = 1, 3 do
    local t9 = hitTargets()
    firsts[t9[1]] = true
    if #t9 ~= 3 then firsts.short = true end
end
check("three swings: each of the three is named first once, all three named every time",
    firsts[a9] and firsts[b9] and firsts[c9] and not firsts.short)

print(all and "ALL PASS" or "SOME FAILED")
