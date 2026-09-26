
-- ---------------------------------------------------------------- cases
local function reset(over)
    LOG = {}
    clock = 1000
    SERVER.current, SERVER.refuse, SERVER.unreadable, SERVER.asks = nil, false, false, 0
    SERVER.db = {
        BanditQuest1 = { { "Bandit", 5 } },
        MarineQuest2 = { { "Chief Petty Officer", 8 } },
        MarineQuest  = { { "Trainee", 5 }, { "Chief Petty Officer", 8 } },
        JungleQuest  = { { "Monkey", 6 }, { "Gorilla", 8 } },
    }
    table.clear(P.learnedQuests)
    table.clear(P.giverSpots)
    table.clear(lastAskAt)
    questSpecies, questNeed, questKills, questBlind = nil, nil, 0, false
    trackerSeen = false
    ROOT.Position = Vector3.new(0, 0, 0)
    CFG.GiverMode, CFG.QuestName, CFG.QuestTier = "never", nil, nil
    for k, v in pairs(over or {}) do
        if k == "db" then SERVER.db = v elseif SERVER[k] ~= nil then SERVER[k] = v else CFG[k] = v end
    end
end

local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then
        print("  " .. tostring(detail))
        print("  log: " .. table.concat(LOG, " | "))
        all = false
    end
end
local function flew()
    for _, e in ipairs(LOG) do if string.sub(e, 1, 3) == "fly" then return true end end
    return false
end

-- 1. never: asks from here, takes it, never moves you
reset()
local ok = acceptFor("Bandit")
check("never: quest taken from here, nobody moves", ok and not flew() and questSpecies == "Bandit"
    and not questBlind and questNeed == 5, "ok=" .. tostring(ok))
check("never: the tier that worked is locked", P.learnedQuests["Bandit"] and P.learnedQuests["Bandit"].tier == 1)

-- 2. never, tracker unreadable: NOT a failure, counted here with the game's count
reset({ unreadable = true })
ok = acceptFor("Bandit")
check("never + unreadable tracker: counts kills here, no flight", ok and questBlind and questNeed == 5
    and not flew(), "blind=" .. tostring(questBlind) .. " need=" .. tostring(questNeed))

-- 3. never, server refuses: still never moves
reset({ refuse = true })
ok = acceptFor("Bandit")
check("never + refused: never flies to the giver", not flew())

-- 4. auto, giver far: asks from range first; refused -> goes up, asks again
reset({ refuse = true, GiverMode = "auto" })
ROOT.Position = Vector3.new(5000, 0, 0)          -- giver is 4000 away
ok = acceptFor("Bandit")
check("auto + far + refused: asks here, then flies up and asks again",
    LOG[1] == "ask BanditQuest1 t1" and flew(), "")

-- 5. auto, giver near: goes first
reset({ GiverMode = "auto" })
ROOT.Position = Vector3.new(1100, 0, 0)          -- giver 100 away
ok = acceptFor("Bandit")
check("auto + near: flies to the giver before asking", string.sub(LOG[1] or "", 1, 3) == "fly" and ok)

-- 6. always: goes every time
reset({ GiverMode = "always" })
ROOT.Position = Vector3.new(5000, 0, 0)
ok = acceptFor("Bandit")
check("always: flies to the giver", string.sub(LOG[1] or "", 1, 3) == "fly" and ok)

-- 7. Chief Petty Officer: the corrected id works first time
reset()
ok = acceptFor("Chief Petty Officer")
check("Chief Petty Officer: MarineQuest2 t1 taken", ok and LOG[1] == "ask MarineQuest2 t1"
    and P.learnedQuests["Chief Petty Officer"].name == "MarineQuest2", "")

-- 8. Chief Petty Officer when the game only knows the OLD id: the fallback id is tried
reset({ db = { MarineQuest = { { "Trainee", 5 }, { "Chief Petty Officer", 8 } } } })
trackerSeen = true                                -- trackers are readable here
ok = acceptFor("Chief Petty Officer")
check("fallback id: MarineQuest t2 found after MarineQuest2 refused", ok
    and P.learnedQuests["Chief Petty Officer"] and P.learnedQuests["Chief Petty Officer"].name == "MarineQuest"
    and P.learnedQuests["Chief Petty Officer"].tier == 2, "learned=" .. tostring(P.learnedQuests["Chief Petty Officer"]
    and P.learnedQuests["Chief Petty Officer"].name))

-- 9. wrong tier in the table: probed and locked on the right one
reset()
ok = acceptFor("Gorilla")
check("wrong tier: tier 1 wants Monkey, tier 2 found and locked", ok
    and P.learnedQuests["Gorilla"] and P.learnedQuests["Gorilla"].tier == 2, "")

-- 10. retry throttle: a second ask straight away is not sent
reset({ refuse = true })
acceptFor("Bandit")
local asks = SERVER.asks
acceptFor("Bandit")
check("no re-ask within QuestRetrySeconds", SERVER.asks == asks)

-- 11. syncQuest follows a quest already running for species #2
reset()
SERVER.current = { enemy = "Chief Petty Officer", have = 3, need = 8 }
circuitIdx = 1
local list = { { name = "Bandit" }, { name = "Chief Petty Officer" } }
local running = syncQuest(list)
check("syncQuest: running quest moves the circuit to its species, no ask",
    running and circuitIdx == 2 and SERVER.asks == 0 and questKills == 3, "idx=" .. circuitIdx)

-- 12. syncQuest drops a quest for something not on the circuit
reset()
SERVER.current = { enemy = "Monkey", have = 1, need = 6 }
running = syncQuest({ { name = "Bandit" } })
check("syncQuest: foreign quest dropped", not running and LOG[1] == "abandon")

-- 13. stalled count: unchanged for QuestStallSeconds -> fresh one
reset()
SERVER.current = { enemy = "Bandit", have = 2, need = 5 }
list = { { name = "Bandit" } }
syncQuest(list)
clock += 241
running = syncQuest(list)
check("stalled count dropped after QuestStallSeconds", not running and LOG[#LOG] == "abandon")

-- 14. blind quest stays ours until our count says done
reset({ unreadable = true })
acceptFor("Bandit")
running = syncQuest({ { name = "Bandit" } })
check("blind quest is kept (no re-ask) while counting", running and SERVER.asks == 1)
questKills = 5
running = syncQuest({ { name = "Bandit" } })
check("blind quest released when the count is reached", not running)

print(all and "ALL PASS" or "SOME FAILED")
