
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    io_print((cond and "PASS " or "FAIL ") .. name)
    if not cond then io_print("  " .. tostring(detail)) all = false end
end
local function calls() return table.concat(CALLS, ",") end
local Q = P.quest

reset()
LEVEL = 1
local w = Q.want()
check("level 1: the nearest of the two starter quests", w and w.id == "MarineQuest" and w.tier == 1
    and w.enemy == "Trainee" and not w.running, w and w.id)

reset()
ME = vec(1000, 0, 0)
w = Q.want()
check("the other starter when you stand by it", w and w.id == "BanditQuest1", w and w.id)

reset()
LEVEL = 12
w = Q.want()
check("level 12: tier 1 of the Jungle", w and w.enemy == "Monkey" and w.tier == 1, w and w.enemy)

reset()
LEVEL = 15
w = Q.want()
check("level 15: tier 2, exactly at its LevelReq", w and w.enemy == "Gorilla" and w.tier == 2, w and w.enemy)

reset()
LEVEL = 25
w = Q.want()
check("level 25: never the boss tier (one kill, long respawn)", w and w.enemy == "Gorilla", w and w.enemy)

reset()
LEVEL = 2000
w = Q.want()
check("past this sea's top: this sea's best, nothing from a sea with no giver here",
    w and w.enemy == "Desert Bandit", w and w.enemy)

reset()
LEVEL = 25
w = Q.want()
check(Q.take(w) == true and "taking: true" or "taking: false", calls() == "fly 2000,start JungleQuest 2", calls())
check("flown to the giver BEFORE asking (the server refuses from afar)", CALLS[1] == "fly 2000", calls())

reset()
tracker("Defeat 8 Gorillas (3/8)")
LEVEL = 60
w = Q.want()
check("a running quest holds, whatever your level says now", w and w.running and w.enemy == "Gorilla",
    w and w.enemy)

reset()
tracker("Defeat 8 Desert Bandits (3/8)")
LEVEL = 60
w = Q.want()
check("the longest name in the tracker: Desert Bandit, not Bandit", w and w.enemy == "Desert Bandit",
    w and w.enemy)

reset()
tracker("Defeat Diablo (0/1)")
LEVEL = 25
w = Q.want()
check("a tracker that is no quest here does not hold the farm", w and not w.running and w.enemy == "Gorilla",
    w and w.enemy)
Q.take(w)
check("...it is dropped before asking", calls() == "AbandonQuest,fly 2000,start JungleQuest 2", calls())

reset()
LEVEL = 25
REPLY = 1
w = Q.want()
check("refused: not a success", Q.take(w) == false)
local again = Q.want()
check("refused: the next look picks another", again and again.enemy == "Monkey", again and again.enemy)
CLOCK += 120
again = Q.want()
check("...and the refused one is tried again later", again and again.enemy == "Gorilla", again and again.enemy)

reset()
LEVEL = 25
REPLY = 30
w = Q.want()
Q.take(w)
check("a level answer is said", string.find(Q.note, "level 30", 1, true) ~= nil, Q.note)

reset()
LEVEL = 25
REPLY = 2
w = Q.want()
Q.take(w)
local said = string.find(Q.note, "already", 1, true) ~= nil
CLOCK += 100000
check("done already: said, and never asked again in this run", said and Q.want().enemy == "Monkey", Q.note)

reset()
LEVEL = 25
w = Q.want()
ON_FLY = function() epoch += 1 end
check("stopped on the way: nothing asked", Q.take(w) == false and calls() == "fly 2000", calls())

reset()
REMOTE = false
w = Q.want()
check("no remote: false, said", Q.take(w) == false and Q.note ~= "", Q.note)

reset()
tracker("Defeat 8 Gorillas (7/8)")
check("tracker up: not finished", Q.finished() == false)
tracker(nil)
CLOCK += 1
check("gone for one look: a blink, not finished", Q.finished() == false)
tracker("Defeat 8 Gorillas (7/8)")
CLOCK += 1
check("back: still not finished", Q.finished() == false)
tracker(nil)
CLOCK += 1
Q.finished()
CLOCK += 1
check("gone twice in a row: finished", Q.finished() == true)
check("finished is counted once", Q.done == 1, Q.done)
CLOCK += 0.1
check("looks are spaced: no second look at once", Q.finished() == false)

reset()
LEVEL = 25
TRACKS = false
w = Q.want()
check("tracker unreadable after a yes: still a success", Q.take(w) == true)
local held = Q.want()
check("...its enemy held, no second ask (it would reset the count)", held and held.running
    and held.enemy == "Gorilla", held and held.enemy)
check("...not finished while held", Q.finished() == false)
CLOCK += 200
check("...finished when the hold ends", Q.finished() == true)
check("...and a new pick after", Q.want() and not Q.want().running)

reset()
RS.GuideModule = nil
check("no guide module: nil, said", Q.want() == nil and Q.note ~= "", Q.note)

reset()
RS.Quests = nil
check("no quest data: nil, no error", Q.want() == nil)

reset()
RS.GuideModule.module.Data.NPCList = {}
check("no givers known: nil, said so", Q.want() == nil and string.find(Q.note, "giver", 1, true) ~= nil, Q.note)

reset()
NPCS.e = { InternalQuestName = "NoSuchQuest", Position = vec(1, 0, 0) }
NPCS.f = { InternalQuestName = "BanditQuest1" }   -- no position
LEVEL = 25
check("a broken giver row is skipped", Q.want() and Q.want().enemy == "Gorilla")

reset()
LEVEL = nil
check("level unknown: nil, no error", Q.want() == nil)

reset()
ME = nil
check("no character yet: still a pick, no error", Q.want() ~= nil)

io_print(all and "ALL PASS" or "SOME FAILED")
