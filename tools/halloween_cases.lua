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
check("name: Pumpkin", t.pumpkinName("Pumpkin"))
check("name: pumpkin3", t.pumpkinName("pumpkin3"))
check("name: JackOLantern", t.pumpkinName("JackOLantern"))
check("name: Jack O' Lantern", t.pumpkinName("Jack O' Lantern"))
check("name: a plain Lantern is not one", not t.pumpkinName("Lantern") and not t.pumpkinName("ShipLantern"))
check("name: nil", not t.pumpkinName(nil))

check("gray: by name", t.isGray("Gray Pumpkin", nil) and t.isGray("GreyPumpkin", { R = 1, G = 0.5, B = 0 }))
check("gray: an orange one is not", not t.isGray("Pumpkin", { R = 1, G = 0.5, B = 0 }))
check("gray: a colourless body is", t.isGray("Pumpkin", { R = 0.5, G = 0.5, B = 0.52 }))
check("gray: near black is not called gray", not t.isGray("Pumpkin", { R = 0.05, G = 0.05, B = 0.05 }))
check("gray: no colour, no name = not gray", not t.isGray("Pumpkin", nil))
check("gray: a white (textured) mesh is not called gray", not t.isGray("Pumpkin", { R = 1, G = 1, B = 1 })
    and not t.isGray("Pumpkin", { R = 0.95, G = 0.95, B = 0.93 }))

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
check("door: nothing cooling = nil", t.soonestCool({ doorsL[5] }, 1000) == nil)

local pts = t.tourPoints(LEVELS, 3, seaOfLevel, 1500, Vector3.new(6000, 0, -1000))
check("tour: one stop per island, this sea only, no sea floor", #pts == 3, #pts)
check("tour: nearest first", pts[1].X == 6241 and pts[2].X == -290 and pts[3].X == -10407,
    pts[1] and (pts[1].X .. " " .. pts[2].X .. " " .. pts[3].X))

local ids = t.tokenIds(RAW)
check("ids: the Spooky Token", #ids.token == 1 and ids.token[1] == 1599, #ids.token)
check("ids: Candy Corn", #ids.candy == 1 and ids.candy[1] == 832)
check("ids: the Spooky Potion is listed, not counted as tokens", #ids.all == 3, #ids.all)

check("door event: Boss Fight = boss", t.eventKind("Boss Fight") == "boss")
check("door event: a Hell Rider name = boss", t.eventKind("Hell Rider Domain") == "boss")
check("door event: rip_indra = treat", t.eventKind("rip_indra") == "treat")
check("door event: Skeleton Attack = fight", t.eventKind("Skeleton Attack") == "fight")
check("door event: a minigame / nothing = game", t.eventKind("Witch Brew Minigame") == "game" and t.eventKind(nil) == "game")

local o = t.wayOrder({ prompt = true, hits = { 1 } }, nil)
check("ways: its prompt first", o[1] == "prompt" and o[2] == "remote" and o[3] == "click", table.concat(o, ","))
o = t.wayOrder({ hits = {} }, "click")
check("ways: the learned way first; untagged = click before remote", o[1] == "click" and o[2] == "remote" and #o == 2, table.concat(o, ","))
o = t.wayOrder({ hits = { 1 } }, nil)
check("ways: tagged = the remote hit first", o[1] == "remote" and o[2] == "click", table.concat(o, ","))
check("kind: dropped after 2 tries, none broke", t.kindDropped({ tries = 2, broke = 0 }) and not t.kindDropped({ tries = 2, broke = 1 })
    and not t.kindDropped({ tries = 1, broke = 0 }) and not t.kindDropped(nil))

-- ---------------------------------------------------------------- THE TOKENS
check("tokens: read through the resolved id", M.readTokens() == 40, M.readTokens())
check("tokens: the ids given to the inventory reader", LOG.addIds["Spooky Token"] and LOG.addIds["Spooky Token"][1] == 1599
    and LOG.addIds["Candy Corn"][1] == 832)

-- ---------------------------------------------------------------- 1. WHAT CAME AT ME FIRST
local mine = enemy("Skeleton", Vector3.new(30, 50, 0), "Me")
local other = enemy("Skeleton", Vector3.new(40, 50, 0), "SomeoneElse")
local pk1, body1 = pumpkin("Pumpkin", Vector3.new(60, 10, 0))
check("step: busy", M.step(1) == true)
check("mine first: fought (before the pumpkin)", LOG.fights == 1 and mine.hum.Health == 0 and M.tally.kills == 1, LOG.fights)
check("mine first: someone else's enemy left alone", other.hum.Health == 100)

-- ---------------------------------------------------------------- 2. A TAGGED PUMPKIN, THE REMOTE HIT
local ra0 = LOG.ra
check("step: busy", M.step(1) == true)
check("pumpkin: a melee taken (Dragon Talon, not the sword)", LOG.equips[#LOG.equips] == "Dragon Talon", LOG.equips[#LOG.equips])
check("pumpkin: smashed by the remote hit", M.tally.pumpkins == 1 and not body1.tags.M1HitRegistry and LOG.ra - ra0 >= 3,
    M.tally.pumpkins .. " ra " .. (LOG.ra - ra0))
check("pumpkin: the way kept", M.way == "remote", M.way)
check("pumpkin: the probe after the first smash ran clean", #ERRORS == 0, ERRORS[1])
check("pumpkin: a smashed one (still there, untagged) is not a pumpkin any more", #P.halloweenPumpkins() == 0, #P.halloweenPumpkins())

-- ---------------------------------------------------------------- 3. TAGGED BEFORE A NEAR DECORATION
local decor = MAP:Add(new("Model", "Pumpkin Patch"))
decor:Add(new("Part", "Body", { Position = Vector3.new(ROOT.Position.X + 20, 10, 0) }))
local far, farBody = pumpkin("Pumpkin", Vector3.new(ROOT.Position.X + 600, 10, 0))
M.step(1)
check("tagged first: the far tagged one, not the near decoration", not farBody.tags.M1HitRegistry and M.tally.pumpkins == 2,
    M.tally.pumpkins)

-- ---------------------------------------------------------------- 4. THE DECORATION: TRIED, THEN DROPPED
M.step(1)
check("decoration: stood through every way, left a while", (M.kinds["Pumpkin Patch"] or {}).tries == 1,
    M.kinds["Pumpkin Patch"] and M.kinds["Pumpkin Patch"].tries)
local decor2 = MAP:Add(new("Model", "Pumpkin Patch"))
decor2:Add(new("Part", "Body", { Position = Vector3.new(ROOT.Position.X + 30, 10, 0) }))
M.step(1)
check("decoration: a second of its kind stood too", (M.kinds["Pumpkin Patch"] or {}).tries == 2)
local decor3 = MAP:Add(new("Model", "Pumpkin Patch"))
decor3:Add(new("Part", "Body", { Position = Vector3.new(ROOT.Position.X + 30, 10, 0) }))
local listed = false
for _, c in ipairs(P.halloweenPumpkins()) do if c.root == decor3 then listed = true end end
check("decoration: that kind is dropped", not listed)

-- ---------------------------------------------------------------- 5. A CLICK-ONLY PUMPKIN: THE WAY LEARNED
local ck, ckBody = pumpkin("Pumpkin", Vector3.new(ROOT.Position.X + 50, 10, 0), { way = "click" })
local clicks0 = LOG.clicks
M.step(1)
check("click: the remote did nothing, the click broke it", not ckBody.tags.M1HitRegistry and LOG.clicks - clicks0 >= 3,
    LOG.clicks - clicks0)
check("click: now the way first", M.way == "click", M.way)

-- ---------------------------------------------------------------- 6. MANY HITS: KEPT ON WHAT IT REACTS TO
local big, bigBody = pumpkin("Pumpkin", Vector3.new(ROOT.Position.X + 40, 10, 0), { hp = 40 })
big.attrs.Health = 40
local oldHit = hitPumpkin
PUMPKINS[bigBody].onHit = true
RH.FireServer = function(_, part)
    LOG.rh += 1
    if (part.Position - ROOT.Position).Magnitude < 10 then
        hitPumpkin(part, "remote")
        local pk = PUMPKINS[part]
        if pk and pk.onHit then part.Parent.attrs.Health = pk.hp end
    end
end
M.step(1)
check("many hits: an attribute moved, so 40 hits were given", not bigBody.tags.M1HitRegistry, PUMPKINS[bigBody].hp)

-- ---------------------------------------------------------------- 7. THE GRAY PUMPKIN
local gray, grayBody = pumpkin("Pumpkin", Vector3.new(ROOT.Position.X + 30, 10, 0), { color = { R = 0.5, G = 0.5, B = 0.5 } })
local rh0 = LOG.rh
-- Nothing else is here: the tour starts instead.
local fl0 = #LOG.flights
M.step(1)
check("gray: left alone", grayBody.tags.M1HitRegistry == true and LOG.rh == rh0)
check("gray: the islands looked at instead", M.tour ~= nil and M.tour.i == 1 and #LOG.flights > fl0, M.tour and M.tour.i)
gray:Destroy()

-- ---------------------------------------------------------------- 8. THE TOUR, THEN THE NEXT SERVER
M.step(1)
M.step(1)
local r = M.step(1)
check("tour: all 3 islands, then false (the director hops)", r == false and M.tour == nil, tostring(r))
check("tour: why says it", type(M.why) == "string" and string.find(M.why, "3 islands", 1, true) ~= nil, M.why)

-- ---------------------------------------------------------------- 9. THE HARVEST MOON, NO DOOR HERE
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
check("moon, nothing near: waits (no tour, no hop)", M.step(1) == true and M.tour == nil)

-- The game's own offer at the next moon: accepted.
HOUR = 16
fireClient("PromptEventTeleport")
task.wait(1.5)
check("moon: the game's offer accepted", count("AcceptEventTeleport") == 2, count("AcceptEventTeleport"))

-- ---------------------------------------------------------------- 10. A DOOR: KNOCK, THE TREAT, ITS END
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

-- A door the prompt does not take: asked of the server as the game does.
local dr2 = door(Vector3.new(ROOT.Position.X + 40, 5, 0))
local prox2 = dr2:FindFirstChild("Proximity")
prox2:FindFirstChild("ProximityPrompt").InputHoldEnd = function() end
SERVER.treat = "Skeleton Attack"
local inv0 = LOG.invokes
M.step(1)
check("door: no answer to the prompt -> HalloweenFunction:InvokeServer(door)", LOG.invokes == inv0 + 1 and M.tally.doors == 2,
    LOG.invokes - inv0)
check("door: a trick counted", M.tally.tricks == 1)

-- ---------------------------------------------------------------- 11. THE PROBE
local okP, errP = pcall(M.probe, "test")
check("probe: runs without an error", okP, errP)

check("no error in any spawned task", #ERRORS == 0, ERRORS[1])
if all then print("ALL PASS") end
