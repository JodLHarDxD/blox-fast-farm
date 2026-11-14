local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local M = P.halloween
local t = M._t
_G.BFF = P
M.probed = true            -- the first-run probe is tested on its own, below

-- ---------------------------------------------------------------- PURE
check("enemy name: Pumpkin / JackOLantern", t.pumpkinName("Pumpkin") and t.pumpkinName("JackOLantern")
    and t.pumpkinName("Jack O' Lantern"))
check("enemy name: a plain Lantern is not one", not t.pumpkinName("Lantern") and not t.pumpkinName(nil))

check("idle: Idle / no state", t.idle("Idle") and t.idle(nil))
check("idle: any other state is not", not t.idle("Smashed") and not t.idle("Hit"))
check("look: pumpkinv1.007 -> pumpkinv1", t.variant("pumpkinv1.007") == "pumpkinv1" and t.variant("PumpkinV4") == "PumpkinV4",
    t.variant("pumpkinv1.007"))

local near = { id = "near", pos = Vector3.new(10, 0, 0) }
local farRare = { id = "rare", pos = Vector3.new(9000, 0, 0), rare = true }
local mid = { id = "mid", pos = Vector3.new(500, 0, 0) }
local pick = t.pickPumpkin({ near, farRare, mid }, Vector3.new(0, 0, 0), nil, true)
check("pick: a rare one (the seed) before a near one, from any distance", pick and pick.id == "rare", pick and pick.id)
pick = t.pickPumpkin({ near, farRare, mid }, Vector3.new(0, 0, 0), nil, false)
check("pick: rare-first off = the nearest", pick and pick.id == "near", pick and pick.id)
pick = t.pickPumpkin({ mid, farRare }, Vector3.new(0, 0, 0), 100, true)
check("pick: a limit holds the ordinary ones, not the rare one", pick and pick.id == "rare", pick and pick.id)
check("pick: nothing within the limit = nil", t.pickPumpkin({ mid }, Vector3.new(0, 0, 0), 100, true) == nil)
-- A DOOR'S CONVERSATION: the safe option (the labels are the game's own, from the dump)
local function picked(labels) return labels[t.talkPick(labels)] end
check("talk: the Fruit Dealer - beg, never rob", picked({ "Give me those fruits!", "Wow, you're rich. Can you spare any?" })
    == "Wow, you're rich. Can you spare any?")
check("talk: Free Roll - the candy, not the roll", picked({ "One free roll!", "Just the candy, please" }) == "Just the candy, please")
check("talk: Tarot - Nevermind, not the game", picked({ "Play matching!", "Nevermind" }) == "Nevermind")
check("talk: never pays Candy Corn", picked({ "Offer some Candy Corn", "T-T-Trick or Treat..!" }) == "T-T-Trick or Treat..!")
check("talk: never the teleport", picked({ "Teleport", "Trick or Treat!" }) == "Trick or Treat!")
check("talk: the Gravedigger - not more power", picked({ "Focus more power!", "Uh... sure, I'll take one?" }) == "Uh... sure, I'll take one?")
check("talk: nothing safe or risky to tell apart: the first", picked({ "Oni (Left)", "Celestial (Right)" }) == "Oni (Left)")
check("talk: one option: it", picked({ "TRICK OR TREAT!" }) == "TRICK OR TREAT!")
check("talk: no option: nothing", t.talkPick({}) == nil)
-- the window driven: a line tapped, a choice picked, at a tapping pace
do
    local log = {}
    local page = { _options = {} }
    local DC = { Active = true, advance = function() table.insert(log, "advance") end,
        select = function(o) table.insert(log, "select " .. (type(o._text) == "table" and o._text[1] or o._text)) end,
        getActiveDialogue = function() return { getCurrent = function() return page end } end }
    M.dc, M.talkPage, M.talkAt = DC, nil, nil
    check("talk: a new line is shown a moment first", t.talk() == false and #log == 0)
    T += 1
    check("talk: then tapped", t.talk() == true and log[1] == "advance")
    check("talk: not twice in the same instant", t.talk() == false and #log == 1)
    -- as the game keeps it: _text = { text } (in game 2026-11-13 the labels read "table: 0x...")
    page = { _options = { { _text = { "Give me those fruits!" } }, { _text = { "Can you spare any?" } } } }
    T += 1
    t.talk()
    T += 1
    check("talk: a choice - the safe one selected", t.talk() == true and log[2] == "select Can you spare any?", log[2])
    page = { _options = { { _text = "Just the candy, please", _locked = true }, { _text = "One free roll!" } } }
    T += 1
    t.talk()
    T += 1
    t.talk()
    check("talk: a locked option is never picked", log[3] == "select One free roll!", log[3])
    DC.Active = false
    T += 2
    check("talk: no window open: nothing", t.talk() == false and #log == 3)
    DC.Active = true
    CFG.HalloweenTalk = false
    T += 2
    check("talk: the switch off: the window is left alone", t.talk() == false and #log == 3)
    CFG.HalloweenTalk = true
    M.dc = nil
end
-- ONLY THE RARE ONE (user, 2026-11-13: "I want the seeds - only that pumpkin")
pick = t.pickPumpkin({ near, farRare, mid }, Vector3.new(0, 0, 0), nil, true, true)
check("rare only: the rare one, from any distance", pick and pick.id == "rare", pick and pick.id)
check("rare only: no rare one here = nil, however near an ordinary one is",
    t.pickPumpkin({ near, mid }, Vector3.new(0, 0, 0), nil, true, true) == nil)
check("rare only holds with rare-first off too", t.pickPumpkin({ near }, Vector3.new(0, 0, 0), nil, false, true) == nil
    and (t.pickPumpkin({ near, farRare }, Vector3.new(0, 0, 0), nil, false, true) or {}).id == "rare")

local from = Vector3.new(0, 0, 0)
local doorsL = {
    { id = "open", pos = Vector3.new(5, 0, 0), open = true, cool = 0 },
    { id = "cool", pos = Vector3.new(6, 0, 0), cool = 2000 },
    { id = "off", pos = Vector3.new(7, 0, 0), cool = 0, enabled = false },
    { id = "skip", pos = Vector3.new(8, 0, 0), cool = 0, skipUntil = 1500 },
    { id = "far", pos = Vector3.new(300, 0, 0), cool = 0, enabled = true },
    { id = "near", pos = Vector3.new(50, 0, 0), cool = 900, enabled = true },
}
local d = t.pickDoor(doorsL, from, 1000, 1000)
check("door: the nearest open to a knock (not open / cooling / prompt off / skipped)", d and d.id == "near", d and d.id)
check("door: none = nil", t.pickDoor({ doorsL[1], doorsL[2] }, from, 1000, 1000) == nil)
check("door: the soonest cooldown", t.soonestCool(doorsL, 1000) == 1000, t.soonestCool(doorsL, 1000))

local ids = t.tokenIds(RAW)
check("ids: the seeds (the user's reward)", ids.byName["Cursed Pumpkin Seed"][1] == 1608)
check("ids: Candy Corn", ids.byName["Candy Corn"][1] == 832)
check("ids: Pumpkin Bits", ids.byName["Pumpkin Bits"][1] == 1607)
check("ids: no Spooky Token in this game = none counted", #ids.byName["Spooky Token"] == 0)
check("ids: every id named (the recorder)", ids.names[1608] == "Cursed Pumpkin Seed" and ids.names[3] == "Quake-Quake")

check("door event: Boss Fight = boss", t.eventKind("Boss Fight") == "boss")
check("door event: rip_indra = treat", t.eventKind("rip_indra") == "treat")
check("door event: Skeleton Attack = fight", t.eventKind("Skeleton Attack") == "fight")
check("door event: a minigame / nothing = game", t.eventKind("Witch Brew Minigame") == "game" and t.eventKind(nil) == "game")

local o = t.wayOrder({ prompt = true, hits = { 1 } }, nil)
check("ways: its prompt first", o[1] == "prompt" and o[2] == "remote" and o[3] == "click", table.concat(o, ","))
o = t.wayOrder({ hits = { 1 } }, "click")
check("ways: the learned way first", o[1] == "click" and o[2] == "remote", table.concat(o, ","))
check("kind: dropped after 2 tries, none broke", t.kindDropped({ tries = 2, broke = 0 }) and not t.kindDropped({ tries = 2, broke = 1 })
    and not t.kindDropped(nil))

-- ---------------------------------------------------------------- THE REWARDS
local c = M.readTokens()
check("rewards: seeds + candy corn + bits read", c and c["Cursed Pumpkin Seed"] == 12 and c["Candy Corn"] == 81
    and c["Pumpkin Bits"] == 3)
check("rewards: the seeds on the Home line", M.have == 12, M.have)
check("rewards: the ids given to the inventory reader", LOG.addIds["Cursed Pumpkin Seed"][1] == 1608
    and LOG.addIds["Candy Corn"][1] == 832)

-- ---------------------------------------------------------------- THE REAL ONES, NOT THE DECORATIONS
-- (user, 2026-10-31: "big pumpkins are decoration, it attacks the wrong ones")
local deco = decoration(Vector3.new(15, 10, 0))
local pk1, body1 = pumpkin(Vector3.new(400, 10, 0))
local list = P.halloweenPumpkins()
check("decoration: the Map's big pumpkin is never a target", #list == 1 and list[1].root == pk1, #list)
check("REGRESSION build .3: a real one is listed (its invisible grey RootPart skipped nothing)", list[1] ~= nil
    and list[1].pos.X == 400, list[1] and list[1].pos.X)
check("the body is the visible one, its parts tagged", list[1] and list[1].tagged and #list[1].hits == 2
    and list[1].kind == "pumpkinv1", list[1] and (#list[1].hits .. " " .. list[1].kind))

-- ---------------------------------------------------------------- 1. WHAT CAME AT ME FIRST
local mine = enemy("Jack O Lantern", Vector3.new(30, 50, 0), "Me")
local other = enemy("Skeleton", Vector3.new(40, 50, 0), "SomeoneElse")
check("step: busy", M.step(1) == true)
check("mine first: fought (before the pumpkin)", LOG.fights == 1 and mine.hum.Health == 0 and M.tally.kills == 1, LOG.fights)
check("mine first: someone else's enemy left alone", other.hum.Health == 100)

-- ---------------------------------------------------------------- 2. THE REMOTE HIT
local ra0 = LOG.ra
check("step: busy", M.step(1) == true)
check("pumpkin: flew to the real one (past the decoration)", (ROOT.Position - body1.Position).Magnitude < 8,
    (ROOT.Position - body1.Position).Magnitude)
check("pumpkin: a melee taken (Dragon Talon, not the sword)", LOG.equips[#LOG.equips] == "Dragon Talon", LOG.equips[#LOG.equips])
check("pumpkin: smashed by the remote hit", M.tally.pumpkins == 1 and pk1:GetAttribute("PumpkinState") == "Smashed"
    and LOG.ra - ra0 >= 1 and LOG.rh > LOG.ra, M.tally.pumpkins .. " ra " .. (LOG.ra - ra0))
check("pumpkin: the way kept, the state it went to said", M.way == "remote" and string.find(M.note, "Smashed", 1, true) ~= nil, M.note)
check("pumpkin: the probe after the first smash ran clean", #ERRORS == 0, ERRORS[1])
check("pumpkin: a smashed one is not a target any more", #P.halloweenPumpkins() == 0, #P.halloweenPumpkins())

-- ---------------------------------------------------------------- 3. A HIT FLIPS IT AND BACK: KEPT ON IT
local pk2 = pumpkin(Vector3.new(ROOT.Position.X + 40, 10, 0), { hp = 4, blink = true })
M.step(1)
check("blink: Hit -> Idle is a hit, not the end; smashed on the 4th", pk2:GetAttribute("PumpkinState") == "Smashed"
    and M.tally.pumpkins == 2, tostring(pk2:GetAttribute("PumpkinState")) .. " " .. M.tally.pumpkins)

-- ---------------------------------------------------------------- 4. A CLICK-ONLY PUMPKIN: THE WAY LEARNED
local ck = pumpkin(Vector3.new(ROOT.Position.X + 50, 10, 0), { way = "click" })
local clicks0 = LOG.clicks
M.step(1)
check("click: the remote did nothing, the click broke it", ck:GetAttribute("PumpkinState") == "Smashed"
    and LOG.clicks - clicks0 >= 3, LOG.clicks - clicks0)
check("click: now the way first", M.way == "click", M.way)

-- ---------------------------------------------------------------- 5. ONE THAT NEVER BREAKS: LEFT A WHILE
local stub = pumpkin(Vector3.new(ROOT.Position.X + 30, 10, 0), { way = "none", look = "PumpkinV4" })
M.step(1)
check("stands through every way: tried once, left 3 min", (M.kinds["PumpkinV4"] or {}).tries == 1 and (M.skip[stub] or 0) > T)
stub:Destroy()

-- ---------------------------------------------------------------- 5b. THE RARE ONE (the seed) FIRST
local near5 = pumpkin(Vector3.new(ROOT.Position.X + 20, 10, 0))
local rare5, rareBody = pumpkin(Vector3.new(ROOT.Position.X + 3000, 10, 0), { rare = true })
M.step(1)
check("rare: flew past the near one to the rare one", (ROOT.Position - rareBody.Position).Magnitude < 8
    and near5:GetAttribute("PumpkinState") == "Idle", (ROOT.Position - rareBody.Position).Magnitude)
check("rare: kept hitting through Summoning until its tags went", rare5:GetAttribute("PumpkinState") == "Burst"
    and M.tally.rare == 1, tostring(rare5:GetAttribute("PumpkinState")))
rare5:Destroy()
M.step(1)
check("rare: then the ordinary one", near5:GetAttribute("PumpkinState") == "Smashed")
near5:Destroy()

-- ---------------------------------------------------------------- 5c. ONLY THE RARE ONE
CFG.HalloweenRareOnly = true
local near6 = pumpkin(Vector3.new(ROOT.Position.X + 20, 10, 0))
local rare6, rareBody6 = pumpkin(Vector3.new(ROOT.Position.X + 2500, 10, 0), { rare = true })
local rareTally = M.tally.rare
check("rare only: busy on the rare one", M.step(1) == true and M.tally.rare == rareTally + 1
    and (ROOT.Position - rareBody6.Position).Magnitude < 8, M.tally.rare)
rare6:Destroy()
local rh6 = LOG.rh
local r6 = M.step(1)
check("rare only: the ordinary one next to you is left alone", near6:GetAttribute("PumpkinState") == "Idle" and LOG.rh == rh6,
    tostring(near6:GetAttribute("PumpkinState")))
check("rare only: no rare one left = false (the director takes the next server)", r6 == false, tostring(r6))
check("rare only: why says so, and how many ordinary ones it left", type(M.why) == "string"
    and string.find(M.why, "no rare pumpkin here (1 ordinary left alone)", 1, true) ~= nil, M.why)
CFG.HalloweenTour = false
check("rare only, 'next server' off: waits here for one", M.step(1) == true
    and string.find(STATUS.line, "waiting", 1, true) ~= nil and near6:GetAttribute("PumpkinState") == "Idle", STATUS.line)
CFG.HalloweenTour = true
CFG.HalloweenRareOnly = false
near6:Destroy()

-- ---------------------------------------------------------------- 6. SEA FLOOR, ALREADY SMASHED
local gray = pumpkin(Vector3.new(ROOT.Position.X + 30, 10, 0), { color = { R = 0.5, G = 0.5, B = 0.5 } })
gray:SetAttribute("PumpkinState", "Smashed")
local deep = pumpkin(Vector3.new(11408, -2158, 9800))
local done = pumpkin(Vector3.new(ROOT.Position.X + 20, 10, 0), { state = "Smashed" })
local rh0 = LOG.rh
local r = M.step(1)
check("sea floor / smashed: none of them touched", LOG.rh == rh0, LOG.rh - rh0)
check("none to smash: false (the director takes the next server)", r == false, tostring(r))
check("none to smash: why says it", type(M.why) == "string" and string.find(M.why, "smashed", 1, true) ~= nil, M.why)
CFG.HalloweenTour = false
check("'next server' off: waits here instead", M.step(1) == true and string.find(STATUS.line, "waiting", 1, true) ~= nil, STATUS.line)
CFG.HalloweenTour = true
gray:Destroy() deep:Destroy() done:Destroy()

-- ---------------------------------------------------------------- 7. THE HARVEST MOON, NO DOOR HERE
workspace.attrs.HalloweenEventActive = true
local function count(what)
    local n = 0
    for _, f in ipairs(LOG.fires) do if f == what then n += 1 end end
    return n
end
M.step(1)
check("moon, no door: the game's teleport asked for", count("AcceptEventTeleport") == 1)
M.step(1)
check("moon, no door: asked once a moon only", count("AcceptEventTeleport") == 1)
check("moon, nothing near: waits (no hop)", M.step(1) == true)
HOUR = 16
fireClient("PromptEventTeleport")
task.wait(1.5)
check("moon: the game's offer accepted", count("AcceptEventTeleport") == 2, count("AcceptEventTeleport"))

-- ---------------------------------------------------------------- 8. A DOOR: KNOCK, THE TREAT, ITS END
local dr = door(Vector3.new(ROOT.Position.X + 80, 5, 0))
M.step(1)
check("door: knocked (its prompt held)", LOG.holds >= 1 and M.tally.doors == 1, M.tally.doors)
check("door: the treat seen", M.door ~= nil and M.door.kind == "treat" and M.tally.treats == 1, M.door and M.door.kind)
for _ = 1, 30 do
    M.step(1)
    if not M.door then break end
end
check("door: the treat accepted", count("AcceptReward") >= 1)
check("door: its end seen, the door done", M.door == nil and dr.attrs.CooldownUntil ~= nil)
local h0 = LOG.holds
M.step(1)
check("door: a cooling door is not knocked again", LOG.holds == h0 and string.find(STATUS.line, "cooling", 1, true) ~= nil, STATUS.line)
local dr2 = door(Vector3.new(ROOT.Position.X + 40, 5, 0))
dr2:FindFirstChild("Proximity"):FindFirstChild("ProximityPrompt").InputHoldEnd = function() end
SERVER.treat = "Skeleton Attack"
local inv0 = LOG.invokes
M.step(1)
check("door: no answer to the prompt -> HalloweenFunction:InvokeServer(door)", LOG.invokes == inv0 + 1 and M.tally.doors == 2,
    LOG.invokes - inv0)
check("door: a trick counted", M.tally.tricks == 1)
workspace.attrs.HalloweenEventActive = false

-- ---------------------------------------------------------------- 9. THE RECORDER (watch only)
CFG.Hunt = false                                   -- the farm off: it still records
local W = M.watch
local hits0, fires0 = LOG.rh + LOG.ra + LOG.clicks, #LOG.fires
local pk9, body9 = pumpkin(Vector3.new(ROOT.Position.X + 5, 10, 0))
W.start()
check("recorder: on", W.on == true)
pk9:SetAttribute("PumpkinState", "Smashed")
enemy("Jack O Lantern", ROOT.Position + Vector3.new(10, 0, 0), "Me")
task.wait(0.2)
ITEMPUSH.OnClientEvent:Fire({ { Key = "Quantity", ItemId = 1608, Value = 13 }, { Key = "IsNew", ItemId = 1608, Value = true } })
body9:Destroy()
local text = table.concat(W.lines, "\n")
check("recorder: the state change, old -> new", string.find(text, "PumpkinState Idle -> Smashed", 1, true) ~= nil)
check("recorder: the enemy that came, with LocalEnemy", string.find(text, "enemy appeared: Jack O Lantern", 1, true) ~= nil
    and string.find(text, "LocalEnemy Me", 1, true) ~= nil)
check("recorder: the item, named", string.find(text, "item: Cursed Pumpkin Seed (1608) = 13", 1, true) ~= nil)
check("recorder: a part gone", string.find(text, "part gone pumpkinv1.006", 1, true) ~= nil)
check("recorder: touched nothing in the game", LOG.rh + LOG.ra + LOG.clicks == hits0 and #LOG.fires == fires0)
W.stop()
check("recorder: off, written to bff_halloween_watch.txt", not W.on and type(LOG.files["bff_halloween_watch.txt"]) == "string"
    and string.find(LOG.files["bff_halloween_watch.txt"], "Idle -> Smashed", 1, true) ~= nil)
local n0 = W.n
pk1:SetAttribute("PumpkinState", "Idle")
check("recorder: off = nothing more written", W.n == n0)
CFG.Hunt = true

-- ---------------------------------------------------------------- 10. THE PROBE
local okP, errP = pcall(M.probe, "test")
check("probe: runs without an error", okP, errP)
check("probe: PumpkinHunt counted by state", type(LOG.files["bff_halloween_probe.txt"]) == "string"
    and string.find(LOG.files["bff_halloween_probe.txt"], "PUMPKINHUNT: found", 1, true) ~= nil)

-- ---------------------------------------------------------------- WHOSE ENEMIES (2026-11-14)
-- "the Snow Yeti door: the snow bandits at the end are not killed" and "it
-- attacks the jungle pirates at Floating Turtle": no mark on what a door
-- sends, so it is known by its birth.
check("born: right at the door, whatever its species", t.bornRule(30, 30, true, false) == true)
check("born: near you, not one of the island's own", t.bornRule(300, 300, false, false) == true)
check("born: near you but the island's own species (a respawn): not yours", t.bornRule(300, 300, true, false) == false)
check("born: far from you and the door: not yours", t.bornRule(600, 600, false, false) == false)
check("born: just moved by the event (what stands there is that place's): not yours", t.bornRule(10, 10, false, true) == false)
do
    for _, m in ipairs(table.clone(ENEMIES.kids)) do m.hum.Health = 0 end
    M.door, M.ev, M.domain, M.bossSound = nil, nil, nil, nil
    CFG.HalloweenPumpkins, CFG.HalloweenDoors = false, false
    local here = ROOT.Position
    local pirate = enemy("Jungle Pirate", here + Vector3.new(60, 0, 0))
    T += 2
    M.step(1)
    check("no door open: the island's own NPC is left alone", pirate.hum.Health == 100)
    -- the Yeti door opens for me
    local door = workspace:Add(new("Model", "HalloweenDoor"))
    fireClient("DoorOpened", door, player, { Event = "Attack_YetiRoom" })
    M.step(1)
    check("the door open, nothing sent yet: still left alone", pirate.hum.Health == 100)
    local bandit1 = enemy("Snow Bandit", here + Vector3.new(120, 0, 0))
    local bandit2 = enemy("Snow Bandit", here + Vector3.new(140, 0, 40))
    local respawn = enemy("Jungle Pirate", here + Vector3.new(200, 0, 0))
    T += 0.5
    M.step(1)
    check("what the door sent (Snow Bandits, no mark on them): killed, all of them", bandit1.hum.Health == 0 and bandit2.hum.Health == 0,
        bandit1.hum.Health .. " " .. bandit2.hum.Health)
    check("...the island's own, and one of them respawned meanwhile: untouched", pirate.hum.Health == 100 and respawn.hum.Health == 100)
    check("...said once, with its marks, for the log", string.find(table.concat(PRINTS, "|"), "your door sent Snow Bandit", 1, true) ~= nil)
    -- the event over, the door closed: a late stranger 25 s after is nobody's
    M.door = nil
    T += 40
    M.step(1)
    local late = enemy("Sea Soldier", here + Vector3.new(100, 0, 0))
    T += 1
    M.step(1)
    check("long after the door's event: a newcomer is not fought", late.hum.Health == 100)
    late.hum.Health = 0

    -- THE BOSS'S DOMAIN: someone else's portal sounds - nothing changes for you
    fireClient("BossTeleportSound")
    T += 1
    M.step(1)
    check("a boss portal sounded, you were not moved: NOT 'in the domain' (the island's NPCs were fought for this)",
        M.domain == nil and pirate.hum.Health == 100)
    T += 9
    M.step(1)
    check("...and it is forgotten", M.bossSound == nil and pirate.hum.Health == 100)
    -- your own jump: in the domain, everyone there is yours
    fireClient("BossTeleportSound")
    ROOT.Position = here + Vector3.new(0, 0, 9000)
    local minion = enemy("Hell Minion", ROOT.Position + Vector3.new(50, 0, 0))
    T += 0.5
    M.step(1)
    check("moved 9000 studs with the sound: in the domain, what is there is fought", minion.hum.Health == 0)
    -- back on the island: the domain is over at once
    ROOT.Position = here
    T += 0.5
    M.step(1)
    check("back on the island: the domain is over - the island's NPCs untouched", M.domain == nil and pirate.hum.Health == 100
        and respawn.hum.Health == 100)
    pirate.hum.Health, respawn.hum.Health = 0, 0
    CFG.HalloweenPumpkins, CFG.HalloweenDoors = true, true
    M.ev = nil
end
-- THE CANDY ON THE FLOOR: where the pieces lie, read from the game's own attributes
do
    local realTypeof = typeof
    typeof = function(x)
        if type(x) == "table" and x.X ~= nil and x.Z ~= nil then return "Vector3" end
        return realTypeof(x)
    end
    local spill = { Name = "Spill7", GetAttributes = function()
        return { Candy_1 = Vector3.new(10, 5, 0), Candy_2 = Vector3.new(30, 5, 0), Chest_Gold_1 = Vector3.new(50, 5, 0),
            GhostCandy_a = Vector3.new(70, 5, 0), SpillOrigin = Vector3.new(0, 5, 0), SpillStarted = 12, Other = "x" }
    end }
    local out = t.candyOf(spill, {})
    table.sort(out, function(a, b) return a.pos.X < b.pos.X end)
    check("candy: every piece of a spill (candy, chest, the ghost's) - not its origin", #out == 4 and out[1].pos.X == 10
        and out[4].pos.X == 70, #out)
    check("candy: each piece has its own key", out[1].key == "Spill7/Candy_1", out[1] and out[1].key)
    local odd = { Name = "Odd", GetAttributes = function() return { Candy_1 = "3,4,5" } end }
    check("candy: a piece that is not a place is said, not walked to", #t.candyOf(odd, {}) == 0
        and string.find(table.concat(PRINTS, "|"), "not a place", 1, true) ~= nil)
    typeof = realTypeof
end

check("no error in any spawned task", #ERRORS == 0, ERRORS[1])
if all then print("ALL PASS") end
