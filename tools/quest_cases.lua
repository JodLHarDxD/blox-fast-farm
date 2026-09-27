
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

-- ---------------------------------------------------------------- quest bosses
BOSS["Diamond"] = { id = "Area1Quest", tier = 3, lv = 750, names = { "Diamond" } }
BOSS["Orbitus"] = { id = "MarineQuest3", tier = 3, lv = 925, names = { "Orbitus", "Fajita" } }
BOSS["Fajita"]  = BOSS["Orbitus"]
BOSS["Stone"]   = { id = "PiratePortQuest", tier = 3, lv = 1550, names = { "Stone" } }
QUESTS["Diamond"] = { "Area1Quest", 3 }
QUESTS["Orbitus"] = { "MarineQuest3", 3 }
QUESTS["Stone"]   = { "PiratePortQuest", 3 }
QUEST_NEED["Diamond"], QUEST_NEED["Orbitus"], QUEST_NEED["Stone"] = 1, 1, 1
local BOSS_DB = {
    Area1Quest   = { { "Raider", 8 }, { "Mercenary", 8 }, { "Diamond", 1 } },
    MarineQuest3 = { { "Marine Lieutenant", 8 }, { "Marine Captain", 8 }, { "Fajita", 1 } },
}

-- B1. a Second Sea boss quest: tier 3, asked from here, one kill, never moves you
reset({ db = BOSS_DB })
PLAYER_LV = 900
local okB = acceptFor("Diamond")
check("boss quest taken from here: Area1Quest t3, 1 kill, no flight",
    okB and questSpecies == "Diamond" and questNeed == 1 and LOG[1] == "ask Area1Quest t3" and not flew(),
    P.lastQuestResult)

-- B2. below the boss's level: not asked at all, and it says why
reset({ db = BOSS_DB })
PLAYER_LV = 700
local okL = acceptFor("Diamond")
check("under level 750: the game is not asked, the panel says the level",
    not okL and SERVER.asks == 0 and string.find(P.lastQuestResult, "level 750", 1, true) ~= nil,
    P.lastQuestResult)

-- B3. renamed boss: picked as Orbitus, the game's tracker still says Fajita
reset({ db = BOSS_DB })
PLAYER_LV = 1000
local ab0 = stats.abandons
local okR = acceptFor("Orbitus")
check("renamed boss (Orbitus = Fajita): the tracker's old name is accepted, no abandon",
    okR and questSpecies == "Orbitus" and stats.abandons == ab0 and #LOG == 1,
    P.lastQuestResult)

-- B4. level unreadable: asked anyway (the game decides)
reset({ db = BOSS_DB })
PLAYER_LV = nil
check("level unreadable: still asks", acceptFor("Diamond") and SERVER.asks == 1, P.lastQuestResult)

-- B5. a Third Sea boss on the circuit while in the Second Sea: skipped, and said
reset()
PLAYER_LV = 900
local oldSea, oldSOL = mySea, seaOfLevel
mySea = function() return 2 end
seaOfLevel = function(lv) if lv < 700 then return 1 elseif lv < 1500 then return 2 end return 3 end
CFG.Targets = { "Diamond", "Stone" }
local lst = circuit()
check("circuit: Stone (Third Sea) skipped in the Second Sea, Diamond kept",
    #lst == 1 and lst[1].name == "Diamond" and P.circuitSkipped[1] == "Stone",
    #lst .. " " .. tostring(P.circuitSkipped[1]))
mySea, seaOfLevel = oldSea, oldSOL
CFG.Targets = {}

-- B6. syncQuest: a running boss quest keeps the circuit on the boss
reset({ db = BOSS_DB })
PLAYER_LV = 900
CFG.Targets = { "Bandit", "Diamond" }
acceptFor("Diamond")
circuitIdx = 1
local keep = syncQuest(circuit())
check("running boss quest: the circuit stays on the boss", keep and circuitIdx == 2, circuitIdx)
CFG.Targets = {}

print(all and "ALL PASS" or "SOME FAILED")
