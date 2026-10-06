
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function state(over)
    local t = {
        resume = true, build = "B2", freshUntil = NOW + 100, hopAt = NOW - 12, fromJob = "old",
        visited = { x = NOW - 5 }, tally = { joins = 4, found = 2, kills = 1, chalices = 0, joinSecs = 40, fails = 1, since = 1 },
        cfg = { TravelSpeed = 500, Hunt = true, NotAField = 1, QuestName = "Q" },
    }
    for k, v in pairs(over or {}) do t[k] = v end
    return t
end

-- 0. A copy of ANOTHER build hopped here: resumed, but its settings are not
--    taken (its old defaults would ride through every hop after it).
reset()
DB.f1 = state({ build = "B1", cfg = { TravelSpeed = 500, Hunt = true } })
FILE = "f1"
check("another build: still resumed", takeCarry() == true and CFG.Hunt == true)
check("another build: its settings NOT taken - this build's defaults", CFG.TravelSpeed == 330, CFG.TravelSpeed)
reset()
DB.f1 = state({ cfg = { TravelSpeed = 500, Hunt = true } })
DB.f1.build = nil
FILE = "f1"
takeCarry()
check("no build at all (older than the stamp): its settings not taken", CFG.TravelSpeed == 330, CFG.TravelSpeed)

-- 1. nothing carried
reset()
check("nothing: no resume", takeCarry() == false and E.carried == nil)

-- 2. a hop from another server, 12 s ago: resumed from the file
reset()
DB.f1 = state()
FILE = "f1"
local r = takeCarry()
check("resumed", r == true and CFG.Hunt and not CFG.RaidMode and E.carried == "file")
check("join counted with its time", E.tally.joins == 5 and E.tally.joinSecs == 52, E.tally.joins)
check("settings back; unknown keys ignored (QuestName too - the quest engine is gone)",
    CFG.TravelSpeed == 500 and CFG.NotAField == nil and CFG.QuestName == nil)
check("servers looked at carried", E.visited.x == NOW - 5)
check("file marked arrived here", #WRITES == 1 and DB[FILE].arrivedJob == "new")

-- 3. a second loader in the same server (autoexec AND the queue): no double count
r = takeCarry()
check("second copy here: resumes, join not counted twice", r == true and E.tally.joins == 5, E.tally.joins)

-- 4. written in THIS server (script run again by hand, nothing hopped)
reset()
DB.f1 = state({ fromJob = "new" })
FILE = "f1"
r = takeCarry()
check("same server: no resume, settings not touched", r == false and CFG.TravelSpeed == 330
    and not CFG.Hunt)

-- 5. an old hunt (over 5 minutes): not resumed, counts still kept
reset()
DB.f1 = state({ freshUntil = NOW - 1 })
FILE = "f1"
r = takeCarry()
check("stale: no resume, no settings, tally kept", r == false and CFG.TravelSpeed == 330
    and E.tally.found == 2)

-- 6. carried but stopped (resume false): settings yes, start no
reset()
DB.f1 = state({ resume = false })
FILE = "f1"
r = takeCarry()
check("resume off: settings carried, hunt not started", r == false and CFG.TravelSpeed == 500
    and E.tally.joins == 4)

-- 7. only the queued copy (no file functions)
reset()
DB.q1 = state()
_G.BFF_CARRY = "q1"
r = takeCarry()
check("queued copy only: resumed, marked, queue emptied", r == true and E.carried == "queued reload"
    and _G.BFF_CARRY == nil)

-- 8. a broken file and a good queued copy: the queued one
reset()
DB.q1 = state()
FILE, _G.BFF_CARRY = "garbage", "q1"
r = takeCarry()
check("broken file: the queued copy is used", r == true and E.carried == "queued reload")

-- 9. ANOTHER ACCOUNT's file (both share the executor folder): nothing taken -
--    not its settings (eating allowed on the second account must never reach
--    the main), not its counts, no resume
reset()
DB.f1 = state({ userId = 222, cfg = { TravelSpeed = 900, Hunt = true } })
FILE = "f1"
r = takeCarry()
check("other account's state: no resume, no settings, no counts", r == false and CFG.TravelSpeed == 330
    and not CFG.Hunt and E.tally.joins == 0 and E.visited.x == nil)

-- 10. this account's own (userId matches): resumed as usual
reset()
DB.f1 = state({ userId = 111 })
FILE = "f1"
check("own account's state: resumed", takeCarry() == true and CFG.TravelSpeed == 500)

print(all and "ALL PASS" or "SOME FAILED")
