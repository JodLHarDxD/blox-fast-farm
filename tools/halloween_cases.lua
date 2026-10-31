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

check("gray: by name", t.isGray("Gray Pumpkin", nil) and t.isGray("GreyPumpkin", { R = 1, G = 0.5, B = 0 }))
check("gray: an orange one is not", not t.isGray("Pumpkin", { R = 0.91, G = 0.45, B = 0.14 }))
check("gray: a colourless body is", t.isGray("Pumpkin", { R = 0.5, G = 0.5, B = 0.52 }))
check("gray: near black / white / no colour = not gray", not t.isGray("Pumpkin", { R = 0.05, G = 0.05, B = 0.05 })
    and not t.isGray("Pumpkin", { R = 1, G = 1, B = 1 }) and not t.isGray("Pumpkin", nil))

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
check("REGRESSION build .3: the invisible grey RootPart does not make it gray", list[1] and not list[1].gray)
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

-- ---------------------------------------------------------------- 6. GRAY, SEA FLOOR, ALREADY SMASHED
local gray = pumpkin(Vector3.new(ROOT.Position.X + 30, 10, 0), { color = { R = 0.5, G = 0.5, B = 0.5 } })
local deep = pumpkin(Vector3.new(11408, -2158, 9800))
local done = pumpkin(Vector3.new(ROOT.Position.X + 20, 10, 0), { state = "Smashed" })
local rh0 = LOG.rh
local r = M.step(1)
check("gray / sea floor / smashed: none of them touched", LOG.rh == rh0 and gray:GetAttribute("PumpkinState") == "Idle", LOG.rh - rh0)
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

check("no error in any spawned task", #ERRORS == 0, ERRORS[1])
if all then print("ALL PASS") end
