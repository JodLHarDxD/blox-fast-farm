
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

-- ---------------------------------------------------------------- 2026-11-25
-- The log: a quest taken every ~185 s whatever the kills - the tracker was
-- never read, every quest ran blind for the full hold and was asked again.

reset()
LEVEL = 25
ME = vec(1000, 0, 0)
w = Q.want()
check("near its giver: asked from where you stand, no flight",
    Q.take(w) == true and calls() == "start JungleQuest 2", calls())

reset()
LEVEL = 25
CAMPS.Gorilla = vec(1800, 0, 0)
w = Q.want()
Q.take(w)
check("far: flown to the species' camp (the fight is there), asked from there",
    calls() == "fly 1800,start JungleQuest 2", calls())

reset()
LEVEL = 25
CAMPS.Gorilla = vec(9000, 0, 0)
w = Q.want()
Q.take(w)
check("far, and the camp is not near the giver: to the giver", calls() == "fly 2000,start JungleQuest 2", calls())

reset()
LEVEL = 25
ME = vec(1000, 0, 0)
REPLY = function() return (ME - vec(2000, 0, 0)).Magnitude < 100 and 0 or 1 end
w = Q.want()
check("refused from afar: to the giver, asked again - a success",
    Q.take(w) == true and calls() == "start JungleQuest 2,fly 2000,start JungleQuest 2", calls())
tracker(nil)
CLOCK += 1
Q.finished()
CLOCK += 1
Q.finished()
ME = vec(1000, 0, 0)
CALLS = {}
w = Q.want()
Q.take(w)
check("...and the next ask for that giver comes from closer (flown first)",
    CALLS[1] ~= "start JungleQuest 2" and string.find(CALLS[1] or "", "fly", 1, true) ~= nil, calls())

reset()
LEVEL = 25
REPLY = 1
ME = vec(2000, 0, 0)
w = Q.want()
check("refused at the giver: no flight, a refusal", Q.take(w) == false and calls() == "start JungleQuest 2", calls())

-- THE TRACKER MOVED off Main.Quest: found on screen, not the panel, not a tag.
reset()
MOVED = true
PG.Main = nil
LEVEL = 25
w = Q.want()
check("tracker moved: taken, and read where it is now", Q.take(w) == true and not string.find(Q.note, "counted here", 1, true), Q.note)
local held2 = Q.want()
check("...held as running (no second ask)", held2 and held2.running and held2.enemy == "Gorilla", held2 and held2.enemy)
tracker("Defeat 8 Gorillas (5/8)")
CLOCK += 5
Q.want()
check("...its count shown", string.find(Q.note, "5/8", 1, true) ~= nil, Q.note)
tracker(nil)
CLOCK += 1
Q.finished()
CLOCK += 1
check("...gone twice: finished", Q.finished() == true)

reset()
MOVED = true
PG.Main = nil
LEVEL = 25
check("the panel's own words and a name tag are no quest", Q.want() and not Q.want().running)

-- BLIND: no tracker anywhere - its own count, Beli, or no kill for long.
reset()
LEVEL = 25
TRACKS = false
w = Q.want()
Q.take(w)
for _ = 1, 7 do Q.onKill("Gorilla") end
Q.onKill("Monkey")
CLOCK += 10
check("blind: 7 of 8 is not done", Q.finished() == false)
check("...the count is shown", string.find(Q.note, "7/8", 1, true) ~= nil, Q.note)
Q.onKill("Gorilla")
CLOCK += 1
check("...8 of 8: not yet (the game's word may still come)", Q.finished() == false)
CLOCK += 5
check("...8 of 8 and a moment: done", Q.finished() == true)
check("...a new quest picked at once", Q.want() and not Q.want().running)

reset()
LEVEL = 25
TRACKS = false
Q.take(Q.want())
Q.onKill("Gorilla")
BELI.Value += 2500
CLOCK += 1
check("blind: Beli paid (only a quest pays) = done, whatever the count", Q.finished() == true)

reset()
LEVEL = 25
TRACKS = false
Q.take(Q.want())
for _ = 1, 3 do
    CLOCK += 150
    Q.onKill("Gorilla")
end
CLOCK += 1
check("blind: kills keep coming - no hold ends it", Q.finished() == false)
CLOCK += 181
check("...no kill for 180 s: ended", Q.finished() == true)

-- MY LIST: the species fought takes its quest; a list quest running is kept.
reset()
CFG.Quests = false
LEVEL = 25
local lw, lrun = Q.forList({ Monkey = true, Gorilla = true }, "Monkey")
check("my list: Monkey's own quest", lw and lw.enemy == "Monkey" and lw.tier == 1 and lrun == nil, lw and lw.enemy)
tracker("Defeat 8 Gorillas (2/8)")
CLOCK += 5
lw, lrun = Q.forList({ Monkey = true, Gorilla = true }, "Monkey")
check("...a running Gorilla quest (on the list) is kept", lw == nil and lrun == "Gorilla", tostring(lrun))
lw, lrun = Q.forList({ Monkey = true }, "Monkey")
check("...one of a species not on the list is replaced", lw and lw.enemy == "Monkey", lw and lw.enemy)
tracker(nil)
lw = Q.forList({ ["The Gorilla King"] = true }, "The Gorilla King")
check("...a boss on the list takes its boss quest", lw and lw.tier == 3, lw and lw.tier)
LEVEL = 5
lw = Q.forList({ Gorilla = true }, "Gorilla")
check("...not until your level allows it", lw == nil)
CFG.Quests = true

-- THE OLD ENGINE'S READING (2026-09-28): counter + Defeat in one block.
reset()
MOVED = true
PG.Main = nil
LEVEL = 25
local split = inst("Frame", "Split", { Visible = true }, {
    inst("TextLabel", "Head", { Text = "Defeat 8 Gorillas", Visible = true }),
    inst("TextLabel", "Count", { Text = "(2/8)", Visible = true }) })
HUD_FRAME.Visible = true
split.Parent = HUD_FRAME
table.insert(HUD_FRAME.kids, split)
local sw = Q.want()
check("title and counter in two labels of one block: running",
    sw and sw.running and sw.enemy == "Gorilla", sw and sw.enemy)
check("...its count read from the counter", string.find(Q.note, "2/8", 1, true) ~= nil, Q.note)

reset()
MOVED = true
PG.Main = nil
LEVEL = 25
HUD_FRAME.Visible = true
HUD_LABEL.Text = "Gorillas 3/8 left on the board"
check("a counter with no Defeat in its block (a board) is no quest", not Q.want().running)

reset()
LEVEL = 25
TITLE.Text = "Defeat 8 Gorillas (8/8)"
QUEST_GUI.Visible = false
check("old words left in a hidden tracker are no quest", not Q.want().running)

reset()
LEVEL = 25
ME = vec(1000, 0, 0)
w = Q.want()
tracker("Defeat 8 Gorillas (3/8)")
check("taking a quest already running (a look missed it): kept, never asked again",
    Q.take(w) == true and calls() == "", calls())
check("...its count kept", string.find(Q.note, "3/8", 1, true) ~= nil, Q.note)

reset()
LEVEL = 25
ME = vec(1000, 0, 0)
REPLY = 1
w = Q.want()
local plain = cf.InvokeServer
cf.InvokeServer = function(self, name, id, tier)
    local r = plain(self, name, id, tier)
    if name == "StartQuest" then tracker("Defeat 8 Gorillas (0/8)") end
    return r
end
check("the server's word odd but its tracker up: taken, no flight, no second ask",
    Q.take(w) == true and calls() == "start JungleQuest 2", calls())
cf.InvokeServer = plain

io_print(all and "ALL PASS" or "SOME FAILED")
