local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local M = P.ember
local t = M._t

-- ---------------------------------------------------------------- PURE
local k, mob, n = t.parseQuest("Defeat 3 Hydra Enforcers")
check("quest: Hydra Enforcers", k == "defeat" and mob == "Hydra Enforcer" and n == 3, tostring(k) .. tostring(mob))
k, mob, n = t.parseQuest("Defeat 3 Venomous Assailants on Hydra Island")
check("quest: Venomous Assailants (not Hydra Enforcer for 'Hydra Island')", k == "defeat" and mob == "Venomous Assailant", mob)
k, mob, n = t.parseQuest("Destroy 10 trees on Hydra Island")
check("quest: trees, 10 (not Hydra Enforcer for 'Hydra Island')", k == "trees" and n == 10, tostring(k) .. tostring(n))
check("no text: no quest", t.parseQuest(nil) == nil and t.parseQuest("") == nil)
check("a quest it does not know", (t.parseQuest("Find the lost cat")) == "unknown")

check("from afar: not failed at the count", not t.remoteFailed(5, 3))
check("from afar: failed past the count + 3", t.remoteFailed(6, 3))
check("no count known: never called failed", not t.remoteFailed(50, nil))

local trees = {
    { kind = "Tree/Trunk", height = 40, bamboo = false, dist = 300 },
    { kind = "Tree/bambootree", height = 30, bamboo = true, dist = 10 },
    { kind = "BigTree/Trunk", height = 400, bamboo = false, dist = 5 },
    { kind = "Palm/Trunk", height = 35, bamboo = false, dist = 100 },
}
local o = t.treeOrder(trees, 120, {})
check("trees: the giants never tried", #o == 3 and o[1].kind ~= "BigTree/Trunk" and o[2].kind ~= "BigTree/Trunk" and o[3].kind ~= "BigTree/Trunk")
check("trees: medium ones before bamboo, nearest first", o[1].kind == "Palm/Trunk" and o[2].kind == "Tree/Trunk" and o[3].bamboo,
    o[1].kind .. " " .. o[2].kind .. " " .. o[3].kind)
o = t.treeOrder(trees, 120, { ["Tree/Trunk"] = { tries = 1, broke = 2 } })
check("trees: a kind that broke goes first", o[1].kind == "Tree/Trunk", o[1].kind)
o = t.treeOrder(trees, 120, { ["Palm/Trunk"] = { tries = 3, broke = 0 } })
check("trees: a kind 3 trees never broke is dropped", #o == 2 and o[1].kind == "Tree/Trunk", #o)

-- ---------------------------------------------------------------- THE FLOW
-- 1. No quest; asking from afar works: taken here, no flight.
M.step(1)
check("asked from afar: quest taken without flying", M.quest == "Defeat 3 Hydra Enforcers" and M.how == "asked from here"
    and #FLIGHTS == 0, tostring(M.how) .. " flights " .. #FLIGHTS)
check("defeat: the fight is on Hydra Enforcers", FIGHTS[#FIGHTS] == "Hydra Enforcer" and M.progress == 1, M.progress)
M.step(1) M.step(1)
check("3 kills counted", M.progress == 3, M.progress)

-- 2. "Head back to the Dojo": stale (just taken) is ignored; later it ends the quest.
NOTE.list = { label("Head back to the Dojo to complete more tasks.") }
SERVER.next = "Destroy 10 trees on Hydra Island"
local before = M.tally.quests
M.takenAt = T                      -- as if this quest was taken just now
M.step(1)
check("the notification in the first 12 s of a quest: not believed", M.quest == "Defeat 3 Hydra Enforcers" and M.tally.quests == before)
T += 13
M.step(1)
check("then: quest done, the next one asked for", M.quest == "Destroy 10 trees on Hydra Island" and M.tally.quests == before + 1
    and M.remoteOk == true, M.quest)
NOTE.list = {}

-- 3. Embers lying: taken first, before anything else.
SERVER.text = "Defeat 3 Hydra Enforcers"
EMBERS[1] = ember(vec(4700, 1010, 400))
EMBERS[2] = ember(vec(4705, 1010, 405))
local f0 = #FIGHTS
M.step(1)
M.step(1)
check("embers: both taken, no fighting meanwhile", #EMBERS == 0 and M.tally.embers == 2 and #FIGHTS == f0, #EMBERS)

-- 4. A server that only gives quests AT the Dragon Hunter.
local M2 = M
SERVER.text, SERVER.remoteOk = nil, false
SERVER.next = "Defeat 3 Venomous Assailants"
M.quest, M.back = nil, false
ROOT.Position = vec(0, 0, 0)
M.step(1)
check("refused from afar: flown to the Dragon Hunter, quest taken there",
    M.how == "at the Dragon Hunter" and M.quest == "Defeat 3 Venomous Assailants"
    and (FLIGHTS[#FLIGHTS] - vec(5864, 1212, 810)).Magnitude < 1, tostring(M.how))

-- 5. Asked from afar, the server said nothing and changed nothing: the old
--    quest's text keeps coming back, it never finishes -> to the Dragon Hunter.
M.remoteOk, M.mustVisit = false, false
SERVER.remoteOk, SERVER.fakeRemote = true, true
SERVER.text = "Defeat 3 Hydra Enforcers"
M.quest, M.back = "Defeat 3 Hydra Enforcers", true          -- the last one done
ROOT.Position = vec(4620, 1002, 399)
M.step(1)
check("a quest 'taken' from afar", M.how == "asked from here", M.how)
for _ = 1, 6 do T += 16 M.step(1) end
check("never finishes past the count: from now on at the Dragon Hunter", M.mustVisit == true
    and (ROOT.Position - vec(5864, 1212, 810)).Magnitude < 1, tostring(M.mustVisit))

-- 6. Trees: the medium ones break, the bamboo is last, the giant never tried,
--    one that never breaks is left after 8 casts.
local medium = treePart("Trunk", vec(4600, 1000, 300), 40)
local bamboo = treePart("Meshes/bambootree", vec(4610, 1000, 310), 30)
local giant = treePart("BigTrunk", vec(4605, 1000, 305), 400)
local stubborn = treePart("Stone", vec(4500, 1000, 300), 40)
ISLE.kids = { treeModel("Tree", medium, 40), inst("Group", "Model", { treeModel("Tree", bamboo, 30) }),
    treeModel("GiantTree", giant, 400), treeModel("Rock Tree", stubborn, 40) }
for _, k in ipairs(ISLE.kids) do k.Parent = ISLE end
BREAKS = { Trunk = true }
SERVER.fakeRemote, SERVER.remoteOk, M.mustVisit = false, true, false
SERVER.text = "Destroy 10 trees on Hydra Island"
M.quest, M.back, M.checkAt = "Destroy 10 trees on Hydra Island", false, T
M.kind, M.need, M.progress = "trees", 10, 0
ROOT.Position = vec(4550, 1000, 300)
CASTS = {}
M.step(1)
check("trees: the nearest MEDIUM tree is broken first", CASTS[1] == "Stone" or CASTS[1] == "Trunk", CASTS[1])
for _ = 1, 12 do M.step(1) end
local seen = {}
for _, c in ipairs(CASTS) do seen[c] = (seen[c] or 0) + 1 end
check("trees: the giant is never tried", seen.BigTrunk == nil)
check("trees: the medium one broke and counted", medium.Anchored == false and M.progress >= 1 and M.tally.trees >= 1, M.progress)
check("trees: one that never breaks gets 8 casts, then left", seen.Stone == 8, seen.Stone)
check("trees: bamboo only after the medium ones", seen["Meshes/bambootree"] ~= nil and CASTS[1] ~= "Meshes/bambootree", CASTS[1])
check("trees: aimed with their OWN learned keys, not the vents'", M.learn ~= nil)

-- 6b. Every key cooling: nothing fired - waiting is not a try on the tree.
local realCast = P.sea.castAt
P.sea.castAt = function() return nil, false end
local function triesNow() local c = 0 for _, n in pairs(M.treeTries) do c += n end return c end
local tries0 = triesNow()
SERVER.text = "Destroy 10 trees on Hydra Island"
M.quest, M.back, M.checkAt, M.kind, M.need = "Destroy 10 trees on Hydra Island", false, T, "trees", 10
medium.Anchored = true
for _ = 1, 3 do M.step(1) end
check("trees: every key cooling - waits, no try counted", triesNow() == tries0
    and string.find(M.note, "cooling", 1, true) ~= nil, triesNow() .. " vs " .. tries0 .. " " .. M.note)
P.sea.castAt = realCast

-- 7. He gives nothing at all (no Dragon Talon 500 / Yellow Belt): stopped, says why.
SERVER.text, SERVER.eligible = nil, false
M.quest, M.back, M.visits = nil, false, 0
for _ = 1, 4 do M.step(1) end
check("no quest 3 visits running: hunt stopped, says why", STOPPED == "Blaze Embers: no quest"
    and string.find(M.note, "Dragon Talon", 1, true) ~= nil, tostring(STOPPED) .. " / " .. tostring(M.note))

-- 8. Enough embers.
STOPPED = nil
M.have, M.haveAt, CFG.EmberStopAt = 99, T, 99
M.step(1)
check("99 held: hunt done", STOPPED == "Blaze Embers: enough", STOPPED)

print(all and "ALL PASS" or "SOME FAILED")
