-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
local function vnear(a, b, eps)
    return a and b and near(a.X, b.X, eps or 0.01) and near(a.Y, b.Y, eps or 0.01) and near(a.Z, b.Z, eps or 0.01)
end
local function vs(v) return v and string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) or "nil" end

SECTION()
useFiles()
local S = P.sea
local T = S._t
-- Flights: was one to `p`; every corner of the way (all but the last) clear
-- of the crater's disc.
function T.hasFlight(p) for _, f in ipairs(FLIGHTS) do if vnear(f, p) then return true end end return false end
function T.cornersClear(centre, r)
    for i = 1, #FLIGHTS - 1 do
        if vec(FLIGHTS[i].X - centre.X, 0, FLIGHTS[i].Z - centre.Z).Magnitude < r - 1e-6 then return false end
    end
    return true
end
function T.horiz(a, b) return vec(a.X - b.X, 0, a.Z - b.Z).Magnitude end
local TIKI = vec(-16928.9, 7.8, 434.6)

-- ---------------------------------------------------------------- ARITHMETIC
check("meters: Danger 6 at 26,300 studs west of the dealer = 2,630 m",
    near(T.metersFrom(TIKI + vec(-26300, 50, 0), 10), 2630, 0.01), T.metersFrom(TIKI + vec(-26300, 0, 0), 10))
check("meters: height does not count, the unit is the slider",
    near(T.metersFrom(TIKI + vec(0, 900, -5000), 5), 1000, 0.01), T.metersFrom(TIKI + vec(0, 900, -5000), 5))
check("heading 0 = due west", vnear(T.headingFor(0), vec(-1, 0, 0)), vs(T.headingFor(0)))
check("heading 90 = toward +Z", vnear(T.headingFor(90), vec(0, 0, 1)), vs(T.headingFor(90)))
check("yawOf inverts CFrame.Angles", near(T.yawOf(CFrame.Angles(0, 0.5, 0).LookVector), 0.5),
    T.yawOf(CFrame.Angles(0, 0.5, 0).LookVector))
check("yawOf west = pi/2", near(T.yawOf(vec(-1, 0, 0)), math.pi / 2), T.yawOf(vec(-1, 0, 0)))
check("turn is capped", near(T.turnStep(0, 3, 0.1), 0.1), T.turnStep(0, 3, 0.1))
check("turn goes the short way round (3 -> -3 is +0.28, not -6)",
    near(T.turnStep(3, -3, 1), 2 * math.pi - 6, 1e-6), T.turnStep(3, -3, 1))
check("cage: 60 off the relic, away from the volcano",
    vnear(T.cageSpot(vec(0, 5, 0), vec(0, 200, -100), 60), vec(0, 5, 60)), vs(T.cageSpot(vec(0, 5, 0), vec(0, 200, -100), 60)))
check("cage: relic straight under the volcano's middle still gets a side",
    vnear(T.cageSpot(vec(0, 5, 0), vec(0, 200, 0), 60), vec(0, 5, 60)), vs(T.cageSpot(vec(0, 5, 0), vec(0, 200, 0), 60)))
check("stand: 12 out from the volcano, 8 up",
    vnear(T.standFor(vec(10, 50, 0), vec(0, 0, 0), 12), vec(22, 58, 0)), vs(T.standFor(vec(10, 50, 0), vec(0, 0, 0), 12)))
check("phase: on = defend", T.phase(true, true, true) == "defend")
check("phase: loot before a new start", T.phase(false, true, true) == "loot")
check("phase: prompt on = start", T.phase(false, true, false) == "start")
check("phase: nothing = idle", T.phase(false, false, false) == "idle")
local function pick(o) o.relicMin, o.pressureMax = 90, 70 return T.defendPick(o) end
check("a golem NOT held goes before a vent (it is on the relic)", pick({ vent = true, free = true }) == "golem")
check("every golem held: the vent first", pick({ vent = true, held = true }) == "vent")
check("held golems are killed when no vent is open", pick({ held = true }) == "golem")
check("nothing live: wait", pick({}) == "wait")
check("pressure over its limit, relic healthy: the vent before even a free golem",
    pick({ vent = true, free = true, pressure = 80, relic = 97 }) == "vent")
check("pressure over its limit but the relic under 90%: the golem", pick({ vent = true, free = true, pressure = 80, relic = 85 }) == "golem")
check("pressure over its limit, relic unread: the vent", pick({ vent = true, free = true, pressure = 80 }) == "vent")
check("pressure under its limit: the free golem", pick({ vent = true, free = true, pressure = 50, relic = 99 }) == "golem")
check("a free golem and no vent: the golem", pick({ free = true, pressure = 95, relic = 100 }) == "golem")

-- ---------------------------------------------------------------- METERS
check("pct: a fraction", near(T.pctFrom(0.5), 50))
check("pct: a percent", near(T.pctFrom(73), 73))
check("pct: out of a max", near(T.pctFrom(1460, 2000), 73))
check("pct: a raw number with no max is not a percent", T.pctFrom(5000) == nil)
check("pct text: 73%", near(T.pctText("Relic 73%") or -1, 73))
check("pct text: 1460/2000", near(T.pctText("1460 / 2000") or -1, 73))
check("pct text: no number", T.pctText("Relic") == nil)

-- ---------------------------------------------------------------- VENTS
local function rock(name, pos)
    local m = inst(name, "Model", { Position = pos })
    local vfx = m:add(inst("VFXLayer", "Part", { Position = pos }))
    vfx:add(inst("Specs", "ParticleEmitter", { Enabled = false }))
    local at0 = vfx:add(inst("At0", "Attachment"))
    at0:add(inst("Glow", "ParticleEmitter", { Enabled = false }))
    local deep = m:add(inst("Inner", "Model"))
    deep:add(inst("At1Beam", "Beam", { Enabled = false }))
    m:add(inst("volcanorock", "MeshPart", { Position = pos, Color = { R = 0.3, G = 0.3, B = 0.3 } }))
    return m
end
local r1 = rock("Rock1", vec(0, 0, 0))
check("vent: nothing on = not live", not T.ventLive(r1))
r1.kids.VFXLayer.kids.Specs.Enabled = true
check("vent: VFXLayer.Specs on = live", T.ventLive(r1))
r1.kids.VFXLayer.kids.Specs.Enabled = false
r1.kids.VFXLayer.kids.At0.kids.Glow.Enabled = true
check("vent: VFXLayer.At0.Glow on = live", T.ventLive(r1))
r1.kids.VFXLayer.kids.At0.kids.Glow.Enabled = false
r1.kids.Inner.kids.At1Beam.Enabled = true
check("vent: an At1Beam anywhere inside on = live", T.ventLive(r1))
r1.kids.Inner.kids.At1Beam.Enabled = false
r1.kids.volcanorock.Color = { R = 185 / 255, G = 53 / 255, B = 57 / 255 }
check("vent: the red volcanorock (185,53,57) = live", T.ventLive(r1))
r1.kids.volcanorock.Color = { R = 120 / 255, G = 53 / 255, B = 56 / 255 }
check("vent: another colour = not live", not T.ventLive(r1))

-- ---------------------------------------------------------------- GOLEMS
local function golem(pos, hp)
    local m = inst("Lava Golem", "Model")
    -- A root that moves when its CFrame is written (as a part we own does).
    local root = setmetatable({ Position = pos }, { __newindex = function(t, k, v)
        if k == "CFrame" then rawset(t, "Position", v.Position) else rawset(t, k, v) end
    end })
    local e = { model = m, hum = { Health = hp or 50000, WalkSpeed = 16 }, root = root, name = "Lava Golem" }
    m.Parent = WS
    return e
end
ROOT.Position = vec(0, 10, 0)
local g1, g2 = golem(vec(100, 0, 0)), golem(vec(20, 0, 0))
ENEMIES = { g1, g2, { model = inst("Pirate", "Model"), hum = { Health = 100 }, root = { Position = vec(1, 0, 0) }, name = "Pirate" } }
S.ev = nil
local list, centre, inPlace = T.golemBuild()
check("golems, no cage yet: the nearest, where it stands", #list == 1 and list[1] == g2 and inPlace == true,
    #list .. " " .. tostring(inPlace))
S.ev = { cage = vec(0, 0, 60) }
list, centre, inPlace = T.golemBuild()
check("golems, caged: every Lava Golem (and no other kind) to the cage", #list == 2 and vnear(centre, vec(0, 0, 60))
    and inPlace == false, #list .. " " .. vs(centre))
CFG.Magnet = false
list, centre, inPlace = T.golemBuild()
check("golems, magnet off: the nearest, where it stands", #list == 1 and list[1] == g2 and inPlace)
CFG.Magnet = true
S.tried[g1.model] = CLOCK - 2                 -- tried 2 s ago, never stuck: not ours
list, centre, inPlace = T.golemBuild()
check("a golem that cannot be held: fought first, where it stands", #list == 1 and list[1] == g1 and inPlace == true)
P.heldAt[g1.model] = CLOCK
list, centre, inPlace = T.golemBuild()
check("...held after all: back in the pile at the cage", #list == 2 and inPlace == false)
P.heldAt[g1.model] = nil
S.tried[g1.model] = nil
ENEMIES = {}
list = T.golemBuild()
check("no golems: an empty pile", #list == 0)

-- ---------------------------------------------------------------- THE WHEEL
local function makeBoat(pos, yaw)
    local b = inst("Beast Hunter", "Model")
    b.pivot = cf(pos, yaw)
    b:add(inst("Owner", "ObjectValue", { Value = player }))
    b:add(inst("Humanoid", "IntValue", { Value = 2500 }))
    b.attrs.MaxHealth = 2500
    -- The harpoon's own VehicleSeat, found FIRST by name order (the bug).
    local hp = b:add(inst("Harpoon", "Model"))
    local hook = hp:add(inst("Seat", "VehicleSeat"))
    hook.CFrame, hook.Position = cf(pos + vec(0, 0, -40), 1.2), pos + vec(0, 0, -40)
    function hook:Sit(h) h.SeatPart = self end
    b.hook = hook
    local seat = b:add(inst("VehicleSeat", "VehicleSeat"))
    seat.CFrame = cf(pos, yaw)
    seat.Position = pos
    function seat:Sit(h) h.SeatPart = self self.sat = (self.sat or 0) + 1 end
    return b, seat
end
local boat, seat = makeBoat(vec(-30000, 5, 400), math.pi / 2)    -- facing west
S.boat, S.seat, S.driving = boat, seat, true
HUM.SeatPart = seat
T.drive.waterY, T.drive.wobbleAt, T.drive.want = 5, 1e9, 0
T.driveTick(0.1)
check("at the wheel, facing west: 30 studs west in 0.1 s at 300", vnear(boat.pivot.Position, vec(-30030, 5, 400))
    and near(boat.pivot.yaw, math.pi / 2), vs(boat.pivot.Position) .. " yaw " .. boat.pivot.yaw)
CFG.SeaSpeed = 500
T.driveTick(0.1)
check("speed capped at 350", vnear(boat.pivot.Position, vec(-30065, 5, 400)), vs(boat.pivot.Position))
CFG.SeaSpeed = 300
T.driveTick(1)
check("a long frame counts as 0.1 s (no jump)", vnear(boat.pivot.Position, vec(-30095, 5, 400)), vs(boat.pivot.Position))
boat.pivot = cf(vec(-30000, 9, 400), 0)
seat.CFrame = cf(vec(-30000, 9, 400), 0)                             -- facing -Z
T.driveTick(0.1)
check("facing away: turns toward west at 45 deg/s, held on the water line",
    near(boat.pivot.yaw, math.rad(4.5), 1e-6) and near(boat.pivot.Position.Y, 5), boat.pivot.yaw .. " y " .. boat.pivot.Position.Y)
HUM.SeatPart = nil
local before = boat.moved
CLOCK += 1
T.driveTick(0.1)
check("knocked off the seat: back in it, the boat waits", boat.moved == before and seat.sat == 1 and HUM.SeatPart == seat,
    tostring(boat.moved) .. " " .. tostring(seat.sat))
P.running = false
before = boat.moved
T.driveTick(0.1)
check("stopped: the boat does not move", boat.moved == before)
P.running = true
boat.Parent = nil
T.driveTick(0.1)
check("the boat gone: the wheel lets go", S.driving == false)
boat.Parent = true

-- ---------------------------------------------------------------- THE SEAT
local b1 = inst("Boat", "Model")
local hpn = b1:add(inst("Harpoon", "Model"))
hpn:add(inst("Seat", "VehicleSeat"))
local deck = b1:add(inst("Deck", "Model"))
local wheel1 = deck:add(inst("VehicleSeat", "VehicleSeat"))
check("seat: no direct wheel seat - the one that is not the harpoon's", T.seatOf(b1) == wheel1)
local b2 = inst("Boat", "Model")
local aft = b2:add(inst("Aft", "Model"))
aft:add(inst("Seat", "VehicleSeat"))
local own2 = b2:add(inst("VehicleSeat", "VehicleSeat"))
check("seat: the boat's own VehicleSeat before any other", T.seatOf(b2) == own2)
local b3 = inst("Boat", "Model")
local cn = b3:add(inst("Cannon", "Model"))
cn:add(inst("Seat", "VehicleSeat"))
check("seat: only a cannon's seat = no wheel", T.seatOf(b3) == nil)

-- ---------------------------------------------------------------- THE HUNT
local BOATS = WS:add(inst("Boats", "Folder"))
local MAP = WS:add(inst("Map", "Folder"))
local WO = WS:add(inst("_WorldOrigin", "Folder"))
local LOCS = WO:add(inst("Locations", "Folder"))
local function reset()
    FLIGHTS, LOCKS, SAYS, STATES, BUY_CALLS, FIGHTS, KEYS_SENT, AIMED, SET_HUNT = {}, {}, {}, {}, {}, {}, {}, {}, {}
    P.elite.why, P.elite.note = nil, ""
end

-- Buying: the game puts the boat in workspace.Boats when BuyBoat answers.
local NEW_BOAT, NEW_SEAT
CF_REMOTE.InvokeServer = function(_, what, ...)
    if what ~= "BuyBoat" then return true end
    table.insert(BUY_CALLS, { what, ... })
    NEW_BOAT, NEW_SEAT = makeBoat(vec(-16950, 4, 470), 0)
    BOATS:add(NEW_BOAT)
    return 1
end
reset()
S.driving, S.everDriven, S.boat, S.seat = false, false, nil, nil
HUM.SeatPart = nil
flying = false
SEA = 2
check("hunt in the Second Sea: stopped, says why", S.huntStep(epoch) == true and SET_HUNT[1] == false
    and string.find(S.note, "Third Sea", 1, true) ~= nil, S.note)
SEA = 3
reset()
local ok = S.huntStep(epoch)
check("no boat: to the back dealer, BuyBoat \"Beast Hunter\"", ok == true and BUY_CALLS[1] and BUY_CALLS[1][1] == "BuyBoat"
    and BUY_CALLS[1][2] == "Beast Hunter" and vnear(FLIGHTS[1], TIKI + vec(0, 4, 0)), BUY_CALLS[1] and BUY_CALLS[1][2])
check("bought: at the WHEEL, not on the harpoon's seat", HUM.SeatPart == NEW_SEAT and HUM.SeatPart ~= NEW_BOAT.hook)
check("bought: in the seat, the wheel on, the body lock let go", HUM.SeatPart == NEW_SEAT and S.driving and flying == true
    and S.everDriven, tostring(S.driving) .. " " .. tostring(flying))
check("sailing: the note says meters and danger", string.find(S.note, "m from Tiki", 1, true) ~= nil, S.note)
check("the boat's collisions are off", NEW_SEAT.CanCollide == false)
DANGER_TEXT = "6"
NEW_BOAT.pivot = cf(TIKI + vec(-30000, 0, 0), 0)
S.huntStep(epoch)
check("danger read off the compass, meters off the dealer", S.danger == 6 and near(S.meters, 3000, 0.5),
    tostring(S.danger) .. " " .. tostring(S.meters))
DANGER_TEXT = nil
player.attrs.DangerLevel = 512
S.huntStep(epoch)
check("no compass label: the DangerLevel attribute / 100", S.danger == 5, S.danger)
NEW_BOAT.pivot = cf(TIKI + vec(-80001, 0, 0), 0)
reset()
ok = S.huntStep(epoch)
check("nothing by the far edge: the next server, and why", ok == false and P.elite.why == "no Prehistoric Island by 8000 m"
    and S.driving == false and flying == false, tostring(ok) .. " " .. tostring(P.elite.why))
-- Back from a failed hop: already at the boat, the edge again.
reset()
HUM.SeatPart = nil
local sat0 = NEW_SEAT.sat
ok = S.huntStep(epoch)
check("a failed hop: back in the seat, the edge seen again, the next server again",
    ok == false and NEW_SEAT.sat == sat0 + 1 and P.elite.why == "no Prehistoric Island by 8000 m")
-- THE TWO LEGS (user, 2026-10-06): out to the edge, 120 left, 10k m more, then the next server.
CFG.SeaLeg2 = 10000
reset()
HUM.SeatPart = nil
ok = S.huntStep(epoch)
local turnedSaid = false
for _, l in ipairs(PRINTED) do if string.find(l, "120 deg left, 10000 m more", 1, true) then turnedSaid = true end end
check("two legs: at the edge NOT the next server - turned 120 left, said", ok == true and T.drive.leg == 2
    and T.drive.base == 120 and turnedSaid and P.elite.why == nil, tostring(ok) .. " leg " .. tostring(T.drive.leg))
T.drive.odo = (T.drive.odo or 0) + 5000 * 10
ok = S.huntStep(epoch)
check("two legs: 5,000 m after the turn - still sailing, the note says how far", ok == true
    and string.find(S.note, "turned back: 5000 of 10000 m", 1, true) ~= nil, S.note)
T.drive.odo = T.drive.odo + 5000 * 10
reset()
ok = S.huntStep(epoch)
check("two legs: 10,000 m after the turn - the next server, and why", ok == false
    and P.elite.why == "no Prehistoric Island by 8000 m, nor 10000 m after the turn" and T.drive.leg == 1,
    tostring(P.elite.why))
CFG.SeaLeg2 = 0
-- THE CLOCK (user, 2026-10-06): 21 min at sea, no island = the next server.
CFG.SeaSearchMinutes = 21
NEW_BOAT.pivot = cf(TIKI + vec(-50000, 0, 0), 0)        -- 5,000 m out: no leg ends here
T.drive.leg, T.drive.base, T.drive.odo0 = 1, 0, nil
reset()
HUM.SeatPart = nil
S.huntStep(epoch)
S.sailStart = CLOCK
CLOCK += 20 * 60
reset()
ok = S.huntStep(epoch)
check("clock: 20 min at sea - still sailing, the note shows the clock", ok == true
    and string.find(S.note, "20:00 of 21:00 in this server", 1, true) ~= nil, S.note)
CLOCK += 61
reset()
ok = S.huntStep(epoch)
check("clock: 21 min at sea, no island - the next server, and why", ok == false
    and P.elite.why == "no Prehistoric Island in 21 min in this server" and S.driving == false, tostring(P.elite.why))
-- Manual steering too.
CFG.SeaSteer = "manual"
reset()
HUM.SeatPart = nil
ok = S.huntStep(epoch)
check("clock: you steering - 21 min still means the next server", ok == false
    and P.elite.why == "no Prehistoric Island in 21 min in this server")
CFG.SeaSteer = "auto"
-- The Mirage hunt: no clock (the Prehistoric hunt's only).
reset()
HUM.SeatPart = nil
ok = S.huntStep(epoch, "mirage")
check("clock: the Mirage hunt has none - sailing on past 21 min, no clock shown", ok == true and P.elite.why == nil
    and string.find(S.note, "in this server", 1, true) == nil, tostring(P.elite.why) .. " / " .. S.note)
-- 0 = off.
CFG.SeaSearchMinutes = 0
reset()
HUM.SeatPart = nil
ok = S.huntStep(epoch)
check("clock off (0): sailing on past 21 min", ok == true and string.find(S.note, "at sea", 1, true) == nil, S.note)
-- The island up after the clock ran out: it stays (the event, the loot).
CFG.SeaSearchMinutes = 21
local found0 = S.tally.found
local mkLate = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
reset()
ok = S.huntStep(epoch)
check("clock: the island came - it stays, the clock no longer counts", ok == true and P.elite.why == nil
    and string.find(S.note, "PREHISTORIC ISLAND UP", 1, true) ~= nil, tostring(P.elite.why) .. " / " .. S.note)
LOCS.kids["Prehistoric Island"] = nil
-- Stuck before sailing (no boat, the buy never comes): the server's clock still ends it.
BOATS.kids[NEW_BOAT.Name] = nil
S.foundAt, S.driving = nil, false
S.sailStart = CLOCK - 22 * 60
reset()
ok = S.huntStep(epoch)
check("clock: stuck before sailing (no boat) - 21 min in the server still = the next server, no buy tried",
    ok == false and P.elite.why == "no Prehistoric Island in 21 min in this server" and #BUY_CALLS == 0,
    tostring(P.elite.why) .. " buys " .. #BUY_CALLS)
BOATS:add(NEW_BOAT)
CFG.SeaSearchMinutes = 0
S.sailStart, S.foundAt, S.tally.found = nil, nil, found0
-- Sunk far out: the next server.
BOATS.kids[NEW_BOAT.Name] = nil
NEW_BOAT.Parent = nil
S.everDriven = true
ROOT.Position = TIKI + vec(-40000, 10, 0)
reset()
ok = S.huntStep(epoch)
check("the boat lost far out: the next server", ok == false and P.elite.why == "the boat was lost at sea"
    and #BUY_CALLS == 0, P.elite.why)
-- Sunk near Tiki: another one.
local lost = NEW_BOAT
S.everDriven = true
ROOT.Position = TIKI + vec(-3000, 10, 0)
reset()
ok = S.huntStep(epoch)
check("the boat lost near Tiki: bought again", ok == true and #BUY_CALLS == 1 and NEW_BOAT ~= lost and S.driving)
S.driving = false
-- The island comes.
local mk = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
S.driving = true
reset()
ok = S.huntStep(epoch)
check("the island up (marker only): off the boat, to its EDGE - never the middle (the volcano), never the next server",
    ok == true and S.driving == false and #FLIGHTS >= 1
    and near(T.horiz(FLIGHTS[#FLIGHTS], vec(-69800, 55, 6800)), 352, 1) and near(FLIGHTS[#FLIGHTS].Y, 85, 1e-6)
    and T.cornersClear(vec(-69800, 55, 6800), 220) and S.tally.found == 1, vs(FLIGHTS[#FLIGHTS]))
S.huntStep(epoch)
check("found counted once", S.tally.found == 1)
LOCS.kids["Prehistoric Island"] = nil

-- ---------------------------------------------------------------- THE EVENT
local function prompt(on)
    local p = inst("ProximityPrompt", "ProximityPrompt", { Enabled = on, HoldDuration = 0 })
    function p:InputHoldBegin() self.held = (self.held or 0) + 1 end
    function p:InputHoldEnd() if self.onHold then self.onHold(self) end end
    return p
end
local function makeIsland(active, promptOn)
    local isle = inst("PrehistoricIsland", "Model", { attrs = { IsMinigameActive = active }, Position = vec(-69800, 55, 6800) })
    local core = isle:add(inst("Core", "Model", { Position = vec(-69800, 55, 6800) }))
    local rel = core:add(inst("PrehistoricRelic", "Model"))
    rel:add(inst("Skull", "Part", { Position = vec(-69800, 20, 6900) }))
    local ap = core:add(inst("ActivationPrompt", "Part", { Position = vec(-69800, 20, 6890) }))
    local pp = ap:add(prompt(promptOn))
    local vr = core:add(inst("VolcanoRocks", "Folder"))
    local a = vr:add(rock("RockA", vec(-69750, 200, 6800)))
    local b = vr:add(rock("RockB", vec(-69850, 200, 6800)))
    core:add(inst("InteriorLava", "Model"))
    isle:add(inst("LavaPool", "Part", { Position = vec(-69800, 150, 6800) }))
    MAP:add(isle)
    return isle, pp, a, b
end
local GOLEM_CUR = S.GOLEM_CUR

reset()
CFG.Volcano = false
pileCur, pileActive = GOLEM_CUR, true
check("switch off: not the event's step, the golems let go", S.volcanoStep() == false and pileCur == nil)
CFG.Volcano = true
check("switch on, no island: not the event's step", S.volcanoStep() == false and S.ev == nil)
mk = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
ROOT.Position = vec(0, 10, 0)
reset()
check("only the far marker: flown to the island's EDGE on your side, never over the volcano", S.volcanoStep() == true
    and near(T.horiz(FLIGHTS[#FLIGHTS], vec(-69800, 55, 6800)), 352, 1) and FLIGHTS[#FLIGHTS].X > -69800
    and T.cornersClear(vec(-69800, 55, 6800), 220), vs(FLIGHTS[#FLIGHTS]))

local isle, pp, rA, rB = makeIsland(false, true)
pp.onHold = function() isle.attrs.IsMinigameActive = true end
reset()
S.driving = true
S.volcanoStep()
check("island up while sailing: the wheel stopped", S.driving == false)
check("prompt on: flown to the relic's prompt ROUND the crater, held, the event on",
    T.hasFlight(vec(-69800, 23, 6890)) and pp.held == 1 and S.tally.events == 1
    and S.ev.note == "THE VOLCANO EVENT IS ON", tostring(S.ev.note))
check("the cage: 60 off the relic, away from the volcano, 60 up in the air", vnear(S.ev.cage, vec(-69800, 80, 6960)), vs(S.ev.cage))

-- On: a live vent and a golem that just landed on the relic, magnet on.
rA.kids.VFXLayer.kids.Specs.Enabled = true
local g = golem(vec(-69800, 20, 6895))
ENEMIES = { g }
TOOLS = { { Name = "Hallow Scythe", ToolTip = "Sword" }, { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" } }
READY = { ["Hallow Scythe Z"] = true, ["Dragon-Dragon Z"] = true, ["Dragon-Dragon X"] = true }
BARS = { ["Dragon-Dragon Z"] = true }      -- still "ready" after the key: it did not fire
reset()
ROOT.Position = vec(-69800, 40, 6900)
S.volcanoStep()
check("a golem not held yet: it goes first, before the vent (relic first)", FIGHTS[1] == "Lava Golem" and #KEYS_SENT == 0,
    tostring(FIGHTS[1]) .. " " .. tostring(S.ev.note))
check("lava off your client: InteriorLava and the lava pool, not the vents",
    isle.kids.Core.kids.InteriorLava.destroyed and isle.kids.LavaPool.destroyed and not rA.destroyed)
check("the fight on a free golem does not break for a vent", GOLEM_CUR.breakIf() == false)
-- The holder lifts it.
pileCur, pileActive = nil, false
T.cageTick()
local cage = S.ev.cage
check("the holder: the golem lifted to its spot in the air over the cage, frozen",
    near(g.root.Position.Y, cage.Y) and (g.root.Position - cage).Magnitude < 9 and g.hum.PlatformStand == true
    and g.hum.WalkSpeed == 0, vs(g.root.Position))
check("...not held until a write is seen to stick", not T.golemHeld(g))
T.cageTick()
check("the write stuck: held", T.golemHeld(g))
check("...and the fight breaks: every golem held, a vent open", GOLEM_CUR.breakIf() == true)
reset()
T.cageTick()
S.volcanoStep()
check("every golem held: the vent, stood 12 out, 8 up", T.hasFlight(vec(-69738, 208, 6800)), vs(FLIGHTS[#FLIGHTS]))
check("fruit first: Dragon-Dragon Z, aimed AT the vent", HELD == "Dragon-Dragon" and KEYS_SENT[1] == "Z"
    and vnear(AIMED[1], vec(-69750, 200, 6800)), tostring(HELD) .. " " .. tostring(KEYS_SENT[1]) .. " " .. vs(AIMED[1]))
check("the aim point and part are cleared after the cast", P.aimAt == nil and P.aimPart == nil and aimUntil == 0)
check("it did not fire: learned as tried, not closed", S.learn["Dragon-Dragon Z"].casts == 1 and S.learn["Dragon-Dragon Z"].closed == 0)
reset()
T.cageTick()
S.volcanoStep()
check("a key that did not fire is left out: X next", KEYS_SENT[1] == "X", tostring(KEYS_SENT[1]))
-- The cast closes it.
local closed0 = S.ev.vents
BARS = {}
READY = { ["Hallow Scythe Z"] = true }
rA.kids.VFXLayer.kids.Specs.Enabled = false
rA.kids.Inner.kids.At1Beam.Enabled = true
reset()
ON_KEY = function() rA.kids.Inner.kids.At1Beam.Enabled = false end
T.cageTick()
S.volcanoStep()
ON_KEY = nil
check("the vent goes out after the hit: counted, the key credited", S.ev.vents == closed0 + 1
    and S.learn["Hallow Scythe Z"].closed == 1, S.ev.vents .. " " .. closed0)
-- Learned: the key that closed one goes first, even before the fruit.
rB.kids.VFXLayer.kids.Specs.Enabled = true
READY = { ["Hallow Scythe Z"] = true, ["Dragon-Dragon C"] = true }
reset()
T.cageTick()
S.volcanoStep()
check("learned: the key that closed a vent is fired first", HELD == "Hallow Scythe" and KEYS_SENT[1] == "Z", tostring(HELD))
-- A key that never closes one goes last.
S.learn["Dragon-Dragon C"] = { casts = 4, closed = 0 }
S.learn["Hallow Scythe Z"] = nil
READY = { ["Hallow Scythe X"] = true, ["Dragon-Dragon C"] = true }
reset()
T.cageTick()
S.volcanoStep()
check("a key that never closed one in 4 goes after an untried one", HELD == "Hallow Scythe" and KEYS_SENT[1] == "X", tostring(HELD))
-- Nothing ready: an aimed M1, at the vent.
READY = {}
reset()
local m0 = M1S
M1_AIM = nil
T.cageTick()
S.volcanoStep()
check("every key cooling: an aimed M1, the silent aim on the vent", M1S == m0 + 1 and vnear(M1_AIM, vec(-69850, 200, 6800))
    and string.find(S.lastVent, "every key cooling", 1, true) ~= nil, vs(M1_AIM))
-- Meters drive the order.
local relHum = inst("Humanoid", "Humanoid", { Health = 950, MaxHealth = 1000 })
isle.kids.Core.kids.PrehistoricRelic:add(relHum)
isle.attrs.Pressure = 0.8
P.heldAt[g.model] = nil
S.ev.metersAt = nil
local s1 = T.situation(isle, S.ev)
check("meters: the relic's Humanoid 95%, the island's Pressure 80%", near(S.ev.relicPct, 95) and near(S.ev.pressurePct, 80),
    tostring(S.ev.relicPct) .. " " .. tostring(S.ev.pressurePct))
check("pressure over 70 with the relic over 90: the vent before a free golem", s1 == "vent", s1)
relHum.Health = 800
S.ev.metersAt = nil
check("the relic at 80%: the free golem first again", (T.situation(isle, S.ev)) == "golem")
check("the relic's lowest is kept", near(S.ev.relicLow, 80), S.ev.relicLow)
isle.kids.Core.kids.PrehistoricRelic.kids.Humanoid = nil
isle.attrs.Pressure = nil
-- On screen only: read off the text, never off this panel.
local hud = PG:add(inst("BFFHUD", "ScreenGui"))
hud:add(inst("Mine", "TextLabel", { Text = "relic 12%" }))
local eg = PG:add(inst("EventGui", "ScreenGui"))
local bar = eg:add(inst("RelicBar", "Frame"))
bar:add(inst("Label", "TextLabel", { Text = "1840/2000" }))
eg:add(inst("PressureText", "TextLabel", { Text = "Pressure: 35%" }))
S.ev.metersAt = nil
T.readMeters(isle, S.ev)
check("meters on screen: 92% relic, 35% pressure (the panel's own text ignored)",
    near(S.ev.relicPct or -1, 92) and near(S.ev.pressurePct or -1, 35), tostring(S.ev.relicPct) .. " " .. tostring(S.ev.pressurePct))
PG.kids.EventGui, PG.kids.BFFHUD = nil, nil
-- Magnet off: golems first, always.
rB.kids.VFXLayer.kids.Specs.Enabled = true
CFG.Magnet = false
reset()
S.volcanoStep()
check("magnet off: the golem before the vent", FIGHTS[1] == "Lava Golem" and #KEYS_SENT == 0)
local before = g.root.Position
T.cageTick()
check("magnet off: the holder leaves them alone", g.root.Position == before)
CFG.Magnet = true
CFG.Volcano = false
check("switch off: breaks the golem fight", GOLEM_CUR.breakIf() == true)
CFG.Volcano = true
-- A golem dies: counted once.
g.hum.Health = 0
S.volcanoStep()
S.volcanoStep()
check("a dead golem counted once", S.ev.golems == 1, S.ev.golems)
ENEMIES = {}
rB.kids.VFXLayer.kids.Specs.Enabled = false

-- The win: the bones, then the egg - each counted ONLY when the game's own
-- count goes up (user, 2026-10-07: "picked" loot never reached the inventory).
local ITEMS = { [585] = 14, [565] = 1 }          -- what the server says you have (585 bones, 565 egg)
NET["RF/GetAllItemValues"] = { InvokeServer = function()
    local out = { { Key = "Mastery", ItemId = 585, Value = 99 } }      -- not a count: ignored
    for id, v in pairs(ITEMS) do table.insert(out, { Key = "Quantity", ItemId = id, Value = v }) end
    return out
end }
-- The server gives it: its count, and its push.
local function grant(id, n)
    ITEMS[id] = (ITEMS[id] or 0) + n
    if PUSH then PUSH({ { Key = "Quantity", ItemId = id, Value = ITEMS[id] } }) end
end
local function saidP(text)
    for _, l in ipairs(PRINTED) do if string.find(l, text, 1, true) then return true end end
    return false
end
check("the game's item list: Quantity rows only, by ItemId", (function()
    local q = T.qtyOf({ { Key = "Quantity", ItemId = 585, Value = 3 }, { Key = "Mastery", ItemId = 585, Value = 50 },
        { Key = "Quantity", ItemId = "565", Value = 2 } })
    return q[585] == 3 and q[565] == 2
end)())
isle.attrs.IsMinigameActive = false
pp.Enabled = false
check("the event over: the golem pile let go", (function() S.volcanoStep() return pileCur == nil end)())
local bone = WS:add(inst("DinoBone", "Part", { Position = vec(-69790, 20, 6920) }))
local egg = prompt(true)
local se = isle.kids.Core:add(inst("SpawnedDragonEggs", "Folder"))
local de = se:add(inst("DragonEgg", "Model"))
local molten = de:add(inst("Molten", "Part", { Position = vec(-69800, 22, 6910) }))
molten:add(egg)
reset()
PRINTED = {}
-- touching it: the game takes the bone and gives it to you
ON_FLY = function(pos)
    if (pos - bone.Position).Magnitude < 1 and bone.Parent then
        WS.kids.DinoBone = nil
        bone.Parent = nil
        grant(585, 1)
    end
end
do
    local boneT0 = CLOCK
    S.volcanoStep()
    local boneTook = CLOCK - boneT0
    ON_FLY = nil
    check("a bone: flown onto it, counted as the game's count went up (14 -> 15)", vnear(FLIGHTS[1], vec(-69790, 20, 6920))
        and S.ev.phase == "loot" and S.ev.bones == 1 and S.tally.bones == 1 and saidP("Dinosaur Bones 14 -> 15"),
        vs(FLIGHTS[1]) .. " " .. S.ev.bones)
    -- Slowly (user, 2026-10-10: "light speed"): 0.5-1 s on each bone, given at once or not.
    check("a bone takes 0.5-1 s on it (the count up at once)", boneTook >= 0.5 - 1e-6 and boneTook <= 1.0 + 0.06,
        string.format("%.2f s", boneTook))
end
-- A bone that goes WITHOUT reaching your inventory: never counted as picked.
local bone2 = WS:add(inst("DinoBone", "Part", { Position = vec(-69780, 20, 6925) }))
ON_FLY = function(pos)
    if (pos - bone2.Position).Magnitude < 1 and bone2.Parent then
        WS.kids.DinoBone = nil
        bone2.Parent = nil
    end
end
reset()
S.volcanoStep()
ON_FLY = nil
check("a bone gone with the count unchanged: NOT picked, said so", S.ev.bones == 1 and S.ev.bonesGone == 1
    and saidP("Dinosaur Bones stayed 15"), tostring(S.ev.bonesGone))
-- The egg: held, then stayed by until the game's count goes up.
reset()
do
    local eggAt, eggFlights = nil, nil
    egg.onHold = function(p) p.Enabled = false grant(565, 1) eggAt, eggFlights = CLOCK, #FLIGHTS end
    S.volcanoStep()
    check("the egg: held, counted as the count went up (1 -> 2)", egg.held == 1 and S.ev.eggs == 1 and S.tally.eggs == 1
        and saidP("Dragon Egg 1 -> 2"), tostring(egg.held) .. " " .. S.ev.eggs)
    -- Its ~3 s animation (user, 2026-10-10: moved before it ends = not yours):
    -- stood still 4 s after E even with the count up at once, locked on the spot.
    check("the egg: stood still 4 s after E (the count up at once), no move meanwhile",
        eggAt and CLOCK - eggAt >= 4 and #FLIGHTS == eggFlights and vnear(LOCKS[#LOCKS], vec(-69800, 25, 6910)),
        string.format("%.2f s, flights %s -> %d, lock %s", eggAt and CLOCK - eggAt or -1, tostring(eggFlights), #FLIGHTS,
            vs(LOCKS[#LOCKS])))
end
-- An egg whose prompt goes with no egg for you.
local egg3 = prompt(true)
egg3.Name = "P3"
molten:add(egg3)
egg3.onHold = function(p) p.Enabled = false end
reset()
S.volcanoStep()
check("an egg prompt gone, your Dragon Egg unchanged: NOT counted, said so", S.ev.eggs == 1 and S.ev.eggGone == true
    and saidP("Dragon Egg stayed 2"), tostring(S.ev.eggGone))
-- An egg that will not come: given up after two holds.
local egg2 = prompt(true)
egg2.Name = "P2"
molten:add(egg2)
reset()
S.volcanoStep()
S.volcanoStep()
check("an egg that stays: given up after two, says why", string.find(S.ev.note, "Dragon Tether", 1, true) ~= nil, S.ev.note)
reset()
S.ev.overAt = CLOCK                    -- the loot just over: the 8 s not run out yet
S.volcanoStep()
check("nothing left: held in front of the skull (away from the volcano), not on it", S.ev.phase == "idle"
    and vnear(FLIGHTS[#FLIGHTS], vec(-69800, 35, 6940)), vs(FLIGHTS[#FLIGHTS]))

-- A new island: a new count.
MAP.kids.PrehistoricIsland = nil
local isle2 = makeIsland(false, false)
S.volcanoStep()
check("another island: its own counts", S.ev.isle == isle2 and S.ev.vents == 0 and S.ev.golems == 0)


-- ---------------------------------------------------------------- THE MIRAGE
local fits, why = T.mirageFits("any", nil, 900, 120)
check("mirage: \"every\" takes it, sky or not", fits)
fits = T.mirageFits("night", nil, 900, 120)
check("mirage: sky not read yet = taken", fits)
fits, why = T.mirageFits("night", { night = true, edge = 600 }, 900, 120)
check("mirage at night, 10 min of it left: taken", fits, why)
fits, why = T.mirageFits("night", { night = true, edge = 60 }, 900, 120)
check("mirage at night, dawn in 1 min: sailed past", not fits and string.find(why, "too soon", 1, true) ~= nil, why)
fits, why = T.mirageFits("night", { night = false, edge = 600 }, 900, 120)
check("mirage by day, night in 10 min: it lasts 5 min into it - taken", fits and string.find(why, "5:00", 1, true) ~= nil, why)
fits, why = T.mirageFits("night", { night = false, edge = 800 }, 900, 120)
check("mirage by day, night in 13:20: only 1:40 of night - sailed past", not fits, why)
fits = T.mirageFits("full", { night = true, edge = 600, full = false }, 900, 120)
check("full moon only: a plain night is sailed past", not fits)
fits = T.mirageFits("full", { night = true, edge = 600, full = true }, 900, 120)
check("full moon only: the full moon up - taken", fits)
fits = T.mirageFits("full", { night = false, edge = 300, nights = 1 }, 900, 120)
check("full moon only: by day, tonight not full - sailed past", not fits)
fits = T.mirageFits("full", { night = false, edge = 300, nights = 0 }, 900, 120)
check("full moon only: by day, the full moon rises tonight in time - taken", fits)

local function mysticIsle(gearOpts, named)
    local isle = inst("MysticIsland", "Model", { Position = vec(-40000, 300, 3000) })
    isle:add(inst("Rock", "MeshPart", { MeshId = "rbxassetid://123", Transparency = 0, Position = vec(-40000, 300, 3000) }))
    if gearOpts then
        local g = inst(named and "Part" or "Gear", "MeshPart", {
            MeshId = named and "rbxassetid://999" or "rbxassetid://10153114969",
            Transparency = gearOpts.t, Position = gearOpts.pos or vec(-40010, 320, 3005) })
        isle:add(g)
        return isle, g
    end
    return isle, nil
end
local gi, gg = mysticIsle({ t = 1 })
local gp, by = T.blueGear(gi)
check("blue gear: found by its mesh", gp == gg and by == true)
gi, gg = mysticIsle({ t = 1 }, true)
gp, by = T.blueGear(gi)
check("blue gear: a MeshPart named Part as the fallback, flagged as such", gp == gg and by == false)
gi = mysticIsle(nil)
check("blue gear: none on the island", T.blueGear(gi) == nil)

-- The hunt: a boat at the wheel, far from Tiki.
local mboat, mseat = makeBoat(TIKI + vec(-20000, 0, 0), math.pi / 2)
BOATS:add(mboat)
HUM.SeatPart = mseat
S.driving, S.everDriven, S.mirage = false, true, nil
P.handsOff = false
ROOT.Position = TIKI + vec(-20000, 5, 0)
reset()
check("mirage hunt, nothing up: sailing", S.huntStep(epoch, "mirage") == true and S.driving == true, S.note)
-- One that will not see night: sailed past.
P.news.sky = { night = false, edge = 1200 }
local mm = LOCS:add(inst("Mirage Island", "Part", { Position = vec(-40000, 300, 3000) }))
reset()
ok = S.huntStep(epoch, "gear")
local said = false
for _, l in ipairs(PRINTED) do if string.find(l, "sailing on", 1, true) then said = true end end
check("a Mirage gone before night: sailed past, still at the wheel, says why", ok == true and S.driving == true
    and not P.handsOff and said and S.mirage and S.mirage.fits == false)
LOCS.kids["Mirage Island"] = nil
S.huntStep(epoch, "gear")
check("it went: forgotten", S.mirage == nil)
-- One that sees night: onto it, the character handed back.
P.news.sky = { night = true, edge = 600 }
local isleM, gear = mysticIsle({ t = 1 })
MAP:add(isleM)
LOCS:add(mm)
reset()
RESTORED = 0
ok = S.huntStep(epoch, "gear")
check("a Mirage that sees night: off the boat, onto it", ok == true and S.driving == false
    and vnear(FLIGHTS[1], vec(-40000, 320, 3000)), vs(FLIGHTS[1]))
check("...and the character is yours: hands off, your collisions back", P.handsOff == true and RESTORED == 1 and flying == false)
reset()
S.huntStep(epoch, "gear")
check("gear hidden: nothing moves, your turn", #FLIGHTS == 0 and P.handsOff and string.find(S.note, "your turn", 1, true) ~= nil, S.note)
-- The moon resonates: the gear shows.
gear.Transparency = 0
ON_FLY = function(pos) if (pos - gear.Position).Magnitude < 1 then gear.Transparency = 1 end end
reset()
STOPPED = 0
S.huntStep(epoch, "gear")
ON_FLY = nil
check("the gear shows: run over at once, picked", vnear(FLIGHTS[1], gear.Position) and S.mirage.got
    and S.tally.gears == 1, vs(FLIGHTS[1]))
check("...then the hunt off and the farm stopped, you left on the Mirage", SET_HUNT[1] == false and STOPPED == 1)
-- A gear that will not pick up: back to you, tried again, then left to you.
S.mirage = nil
local isleN, gear2 = mysticIsle({ t = 1 })
MAP.kids.MysticIsland = nil
MAP:add(isleN)
S.huntStep(epoch, "gear")
gear2.Transparency = 0
reset()
S.huntStep(epoch, "gear")
check("a gear that stays: hands back to you, tried again", S.mirage.tries == 1 and P.handsOff == true and not S.mirage.got)
S.huntStep(epoch, "gear")
S.huntStep(epoch, "gear")
reset()
S.huntStep(epoch, "gear")
check("three tries: left to you, no more flights", S.mirage.tries == 3 and #FLIGHTS == 0
    and string.find(S.mirage.note, "yourself", 1, true) ~= nil, S.mirage.note)
-- The fallback "Part": not trusted when first seen visible.
S.mirage = nil
local isleP, part = mysticIsle({ t = 0 }, true)
MAP.kids.MysticIsland = nil
MAP:add(isleP)
reset()
S.huntStep(epoch, "gear")
reset()
S.huntStep(epoch, "gear")
check("a visible \"Part\" never seen hidden: not the gear", #FLIGHTS == 0 and not S.mirage.got)
part.Transparency = 1
S.huntStep(epoch, "gear")
part.Transparency = 0
ON_FLY = function(pos) if (pos - part.Position).Magnitude < 1 then part.Transparency = 1 end end
reset()
S.huntStep(epoch, "gear")
ON_FLY = nil
check("...seen hidden, then shown: picked", S.mirage.got == true)
-- The Mirage goes while it is your turn: the farm drives again.
S.mirage = nil
P.handsOff = false
local isleG = mysticIsle({ t = 1 })
MAP.kids.MysticIsland = nil
MAP:add(isleG)
S.huntStep(epoch, "gear")
check("(your turn again on a new one)", P.handsOff == true)
MAP.kids.MysticIsland = nil
LOCS.kids["Mirage Island"] = nil
reset()
S.huntStep(epoch, "gear")
check("the Mirage went on your turn: the farm drives again, back to the boat", P.handsOff == false and S.mirage == nil)
-- A Prehistoric while hunting the Mirage: not this hunt's island.
local pre = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
reset()
S.huntStep(epoch, "gear")
check("a Prehistoric on the Mirage hunt: not stopped for, still at the wheel", S.driving == true and #FLIGHTS == 0)
LOCS.kids["Prehistoric Island"] = nil


-- ---------------------------------------------------------------- YOU STEER
MAP.kids.PrehistoricIsland = nil         -- the event's last island: not on this sea
CFG.SeaSteer = "manual"
local sb, ss = makeBoat(vec(-40000, 5, 0), 0)          -- facing -Z
S.boat, S.seat, S.driving = sb, ss, true
HUM.SeatPart = ss
T.drive.waterY, T.drive.cruise = 5, true
P.running = true
KEYS_DOWN = {}
T.driveTick(0.1)
check("you steer, no key: straight on the way it faces, 30 studs", vnear(sb.pivot.Position, vec(-40000, 5, -30))
    and near(sb.pivot.yaw, 0), vs(sb.pivot.Position))
ss.CFrame = sb.pivot
KEYS_DOWN = { A = true }
T.driveTick(0.1)
check("A held: turns left (6 deg in 0.1 s at 60/s)", near(sb.pivot.yaw, math.rad(6), 1e-6), sb.pivot.yaw)
ss.CFrame = sb.pivot
KEYS_DOWN = { Right = true }
T.driveTick(0.1)
check("the right arrow: back right", near(sb.pivot.yaw, 0, 1e-6), sb.pivot.yaw)
ss.CFrame = sb.pivot
KEYS_DOWN = { S = true }
local at = sb.pivot.Position
T.driveTick(0.1)
KEYS_DOWN = {}
T.driveTick(0.1)
check("S: stops, and stays stopped with no key", vnear(sb.pivot.Position, at), vs(sb.pivot.Position))
KEYS_DOWN = { W = true }
T.driveTick(0.1)
KEYS_DOWN = {}
T.driveTick(0.1)
check("W: goes, and keeps going", vnear(sb.pivot.Position, at + vec(0, 0, -60)), vs(sb.pivot.Position))
TYPING = true
KEYS_DOWN = { S = true, A = true }
at = sb.pivot.Position
T.driveTick(0.1)
TYPING = false
KEYS_DOWN = {}
check("typing in chat: your keys do not steer", vnear(sb.pivot.Position, at + vec(0, 0, -30)) and near(sb.pivot.yaw, 0, 1e-6))
-- Never the next server by distance while you steer.
BOATS:add(sb)
sb.pivot = cf(TIKI + vec(-120000, 0, 0), 0)
S.driving, S.mirage = false, nil
reset()
ok = S.huntStep(epoch, "prehistoric")
check("you steer past the far edge: no hop, the note says the keys", ok == true and P.elite.why == nil
    and string.find(S.note, "A/D turn", 1, true) ~= nil, S.note)
CFG.SeaSteer = "auto"

-- ---------------------------------------------------------------- SEA TRAVEL (user, 2026-10-10)
-- The hunts' fast boat with no target: your keys even with "auto" picked, no
-- island, no clock, never the next server.
;(function()
    CFG.Hunt, CFG.HuntKind, CFG.SeaSearchMinutes = true, "sail", 21
    S.driving, S.mirage, S.sailStart = false, nil, nil
    HUM.SeatPart = nil
    reset()
    local okS = S.huntStep(epoch, "sail")
    check("sea travel past the far edge, steering on auto: no hop - your keys at the wheel", okS == true
        and P.elite.why == nil and S.driving and string.find(S.note, "A/D turn", 1, true) ~= nil, S.note)
    check("...no clock (the Prehistoric hunt's only)", string.find(S.note, "in this server", 1, true) == nil, S.note)
    sb.pivot = cf(vec(-40000, 5, 0), 0)
    ss.CFrame = sb.pivot
    T.drive.cruise, T.drive.waterY = true, 5
    KEYS_DOWN = { A = true }
    T.driveTick(0.1)
    KEYS_DOWN = {}
    check("sea travel, steering on auto: A turns the boat (your keys, not the auto heading)",
        near(sb.pivot.yaw, math.rad(6), 1e-6), sb.pivot.yaw)
    -- A Prehistoric and a Mirage up: sailed past, never flown to.
    sb.pivot = cf(TIKI + vec(-120000, 0, 0), 0)
    local mkP = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
    local mkM = LOCS:add(inst("Mirage Island", "Part", { Position = vec(-60000, 55, 6800) }))
    reset()
    okS = S.huntStep(epoch, "sail")
    check("sea travel: a Prehistoric and a Mirage up - sailed past, never flown to", okS == true and #FLIGHTS == 0
        and S.driving and P.elite.why == nil and S.foundAt == nil, tostring(#FLIGHTS) .. " " .. S.note)
    LOCS.kids["Prehistoric Island"], LOCS.kids["Mirage Island"] = nil, nil
    -- 22 min at sea: still sailing.
    S.sailStart = CLOCK - 22 * 60
    reset()
    okS = S.huntStep(epoch, "sail")
    check("sea travel: 22 min at sea - still sailing", okS == true and P.elite.why == nil and S.driving)
    -- The boat lost far out: the switch goes off - never the next server.
    BOATS.kids[sb.Name] = nil
    S.everDriven = true
    ROOT.Position = TIKI + vec(-40000, 10, 0)
    reset()
    okS = S.huntStep(epoch, "sail")
    check("sea travel: the boat lost far out - Sea travel off, never the next server", okS == true
        and SET_HUNT[1] == false and P.elite.why == nil and #BUY_CALLS == 0
        and string.find(S.note, "Sea travel off", 1, true) ~= nil, S.note)
    BOATS:add(sb)
    -- Second Sea: off, said.
    SEA = 2
    reset()
    okS = S.huntStep(epoch, "sail")
    check("sea travel in the Second Sea: stopped, says why", okS == true and SET_HUNT[1] == false
        and string.find(S.note, "Sea travel is Third Sea only", 1, true) ~= nil, S.note)
    SEA = 3
    S.driving, S.everDriven, S.sailStart = false, false, nil
    CFG.Hunt, CFG.HuntKind, CFG.SeaSearchMinutes = false, nil, 0
end)()


-- ---------------------------------------------------------------- THE MIRAGE HUNTS: EACH ITS OWN JOB
;(function()
-- A fresh Mirage with 3 chests (2 in its Chests folder, 1 only tagged), one
-- already taken, the gear hidden.
local function freshMirage()
    S.mirage = nil
    MAP.kids.MysticIsland = nil
    local isle, g = mysticIsle({ t = 1 })
    local chests = isle:add(inst("Chests", "Folder"))
    local c1 = chests:add(inst("DiamondChest", "Model", { Position = vec(-40050, 305, 3000) }))
    local c2 = chests:add(inst("FragChest", "Model", { Position = vec(-40100, 305, 3000) }))
    local taken = chests:add(inst("OldChest", "Model", { Position = vec(-40010, 305, 3000), attrs = { IsDisabled = true } }))
    local deep = isle:add(inst("Ruins", "Folder"))
    local c3 = deep:add(inst("Chest3", "Model", { Position = vec(-40200, 305, 3000) }))
    local elsewhere = inst("FarChest", "Model", { Position = vec(0, 5, 0) })
    TAGGED["_ChestTagged"] = { c1, c3, elsewhere }
    MAP:add(isle)
    return isle, g, { c1, c2, c3 }, taken, elsewhere
end
-- Touching a chest takes it (the game sets IsDisabled).
local CHESTS_NOW = {}
local function touchTakes(pos)
    for _, c in ipairs(CHESTS_NOW) do
        if (pos - c.Position).Magnitude < 3 then c.attrs.IsDisabled = true end
    end
end
-- The dealer: a Model with his root, facing `yaw` (yaw -pi/2 = he looks +X).
local function makeDealer(pos, yaw)
    local d = inst("Advanced Fruit Dealer", "Model", { Position = pos })
    d:add(inst("HumanoidRootPart", "Part", { Position = pos, CFrame = cf(pos, yaw or 0) }))
    return d
end
local function fresh()
    reset()
    STOPPED, P.handsOff = 0, false
end
local function said(text)
    for _, l in ipairs(PRINTED) do if string.find(l, text, 1, true) then return true end end
    return false
end
LOCS.kids["Mirage Island"] = nil
P.news.sky = { night = false, edge = 1200 }       -- day, night far off: only the gear hunt minds

-- 1. THE MIRAGE HUNT: onto it, nothing else.
local _, _, csM = freshMirage()
local npcs = RS:add(inst("NPCs", "Folder"))
local dealerM = npcs:add(makeDealer(vec(-40030, 310, 3020), -math.pi / 2))
fresh()
S.huntStep(epoch, "mirage")
check("mirage hunt: onto the Mirage, then the character is yours, the farm stopped", #FLIGHTS == 1
    and vnear(FLIGHTS[1], vec(-40000, 320, 3000)) and S.mirage.done
    and STOPPED == 1 and SET_HUNT[#SET_HUNT] == false, #FLIGHTS .. " " .. tostring(S.mirage.note))
check("mirage hunt: taken by day (only the gear hunt needs night)", S.mirage.fits == true, S.mirage.why)
check("mirage hunt: no chest, no dealer", not csM[1].attrs.IsDisabled and S.tally.dealers == 0)

-- 2. THE DEALER HUNT, next on the SAME Mirage: its own job, the Mirage not counted twice.
local mirages0 = S.tally.mirages
fresh()
S.huntStep(epoch, "dealer")
local front = vec(-40030, 310, 3020) + vec(5, 0, 0)      -- 5 along his look (+X): his face
check("dealer hunt after the Mirage hunt: a new job on the same Mirage, not a new Mirage",
    S.mirage.kind == "dealer" and S.tally.mirages == mirages0, S.tally.mirages)
check("dealer hunt: read in ReplicatedStorage.NPCs, flown straight to his FRONT (no stop in the middle)",
    #FLIGHTS == 1 and vnear(FLIGHTS[1], front), vs(FLIGHTS[1]))
local heldThere = false
for _, l in ipairs(LOCKS) do if vnear(l, front) then heldThere = true end end
check("dealer hunt: held there, his shop asked for, then done - the character yours, the farm stopped",
    heldThere and S.mirage.dealerSeen and S.mirage.done
    and STOPPED == 1 and string.find(S.mirage.note, "in front of the Advanced Fruit Dealer", 1, true) ~= nil, S.mirage.note)
check("dealer hunt: where he was read is said", S.mirage.dealerFrom == "ReplicatedStorage.NPCs"
    and said("the Advanced Fruit Dealer is in ReplicatedStorage.NPCs"))
check("dealer hunt: no chest taken", not csM[1].attrs.IsDisabled)

-- 3. Switched on again on the same Mirage: done before is not "done" now.
S.mirage.kind = nil                       -- what P.setHunt does on a switch
fresh()
S.huntStep(epoch, "dealer")
check("the dealer hunt again on the same Mirage: flown to him again", #FLIGHTS == 1 and vnear(FLIGHTS[1], front))

-- 4. Parked copy out of date: the live one (workspace.NPCs, met on arrival) is where he is.
freshMirage()
local live = vec(-40300, 302, 2900)
ON_FLY = function(pos)
    if vnear(pos, front) and not WS.kids.NPCs then
        local w = WS:add(inst("NPCs", "Folder"))
        w:add(makeDealer(live, 0))                 -- yaw 0: he looks -Z
    end
end
fresh()
for _ = 1, 3 do S.huntStep(epoch, "dealer") end
ON_FLY = nil
check("parked spot out of date: flown on to the live one's front", vnear(FLIGHTS[#FLIGHTS], live + vec(0, 0, -5))
    and S.mirage.done, vs(FLIGHTS[#FLIGHTS]))
WS.kids.NPCs = nil

-- 5. A copy far off this Mirage is not him; not read anywhere = the island
--    searched, ring after ring, until he streams in - never one look and "not found".
freshMirage()
RS.kids.NPCs = nil
npcs = RS:add(inst("NPCs", "Folder"))
npcs:add(makeDealer(vec(0, 5, 0), 0))             -- 40,000 studs off: somebody's stale copy
local sweeps = 0
ON_FLY = function(pos)
    if (vec(pos.X, 0, pos.Z) - vec(-40000, 0, 3000)).Magnitude < 250 and pos.Y == 330 then
        sweeps += 1
        if sweeps == 5 then
            local w = WS:add(inst("NPCs", "Folder"))
            w:add(makeDealer(vec(-40150, 305, 3080), math.pi))     -- he looks +Z
        end
    end
end
fresh()
for _ = 1, 4 do S.huntStep(epoch, "dealer") end
check("not read: not given up - still at it, searching the island",
    not S.mirage.done and P.handsOff == false and sweeps == 4
    and string.find(S.mirage.note, "looking for the Advanced Fruit Dealer", 1, true) ~= nil, S.mirage.note)
check("the far copy: said, never flown to", said("studs off this Mirage - not him")
    and not T.hasFlight(vec(0, 5, 0) + vec(0, 0, -5)))
for _ = 1, 3 do S.huntStep(epoch, "dealer") end
ON_FLY = nil
check("...he streams in on the search: flown to his front, done", S.mirage.done
    and vnear(FLIGHTS[#FLIGHTS], vec(-40150, 305, 3085)) and S.mirage.dealerFrom == "workspace.NPCs", vs(FLIGHTS[#FLIGHTS]))
WS.kids.NPCs = nil
RS.kids.NPCs = nil

-- 6. Only among the nil instances (some clients hold him there).
freshMirage()
local nilDealer = makeDealer(vec(-39900, 305, 2950), -math.pi / 2)
nilDealer.Parent = nil
getnilinstances = function() return { inst("Junk", "Part"), nilDealer } end
fresh()
S.huntStep(epoch, "dealer")
S.huntStep(epoch, "dealer")
getnilinstances = nil
check("held among the nil instances: found, flown to his front",
    S.mirage.done and S.mirage.dealerFrom == "the nil instances"
    and vnear(FLIGHTS[#FLIGHTS], vec(-39895, 305, 2950)), vs(FLIGHTS[#FLIGHTS]))

-- 7. THE CHEST HUNT: every chest, nothing else.
local _, gearC, cs, takenC, farC = freshMirage()
npcs = RS:add(inst("NPCs", "Folder"))
npcs:add(makeDealer(vec(-40030, 310, 3020), -math.pi / 2))
CHESTS_NOW = cs
ON_FLY = function(pos) touchTakes(pos) end
fresh()
for _ = 1, 6 do S.huntStep(epoch, "mchest") end
ON_FLY = nil
check("chest hunt: taken without night (only the gear hunt needs it)", S.mirage.fits == true, S.mirage.why)
check("chests: all three taken (folder + tagged), the taken one and the far one never flown to",
    cs[1].attrs.IsDisabled and cs[2].attrs.IsDisabled and cs[3].attrs.IsDisabled and S.mirage.chests == 3, S.mirage.chests)
local toTaken, toFar, toDealer = false, false, false
for _, f in ipairs(FLIGHTS) do
    if (f - takenC.Position).Magnitude < 4 then toTaken = true end
    if (f - farC.Position).Magnitude < 4 then toFar = true end
    if (f - front).Magnitude < 4 then toDealer = true end
end
check("chests: never to one already taken or off the Mirage", not toTaken and not toFar)
check("chests: nearest first", vnear(FLIGHTS[2], cs[1].Position + vec(0, 2, 0)), vs(FLIGHTS[2]))
check("chest hunt: never to the dealer", not toDealer)
check("chests done: hunt off, farm stopped, the character yours",
    S.mirage.done and SET_HUNT[#SET_HUNT] == false and STOPPED == 1
    and string.find(S.mirage.note, "3 chests taken", 1, true) ~= nil, S.mirage.note)
RS.kids.NPCs = nil

-- 8. A chest that will not go: 3 tries, then left.
S.chestSkip, S.chestTries = {}, {}
local _, _, cs2 = freshMirage()
CHESTS_NOW = { cs2[1], cs2[3] }                   -- cs2[2] never takes
ON_FLY = function(pos) touchTakes(pos) end
fresh()
for _ = 1, 10 do S.huntStep(epoch, "mchest") end
ON_FLY = nil
local stuckFlights = 0
for _, f in ipairs(FLIGHTS) do if (f - (cs2[2].Position + vec(0, 2, 0))).Magnitude < 1 then stuckFlights += 1 end end
check("a chest that will not open: 3 tries, then left, the hunt still ends", stuckFlights == 3 and S.mirage.done, stuckFlights)

-- 9. Only the marker so far: the chest hunt waits for the island, not "0 chests, done".
S.chestSkip, S.chestTries = {}, {}
S.mirage = nil
MAP.kids.MysticIsland = nil
LOCS:add(inst("Mirage Island", "Part", { Position = vec(-40000, 300, 3000) }))
fresh()
S.huntStep(epoch, "mchest")
S.huntStep(epoch, "mchest")
check("chest hunt, island not loaded yet: waits, not done", not S.mirage.done and S.mirage.chests == 0)
LOCS.kids["Mirage Island"] = nil

-- 10. THE BLUE GEAR HUNT on a Mirage with chests and the dealer: only the gear.
P.news.sky = { night = true, edge = 600 }
local _, gear4, cs4 = freshMirage()
npcs = RS:add(inst("NPCs", "Folder"))
npcs:add(makeDealer(vec(-40030, 310, 3020), -math.pi / 2))
CHESTS_NOW = cs4
ON_FLY = function(pos) touchTakes(pos) end
fresh()
for _ = 1, 3 do S.huntStep(epoch, "gear") end
check("gear hunt: no chest, no dealer - straight to your turn (hands off)",
    S.mirage.chests == 0 and not cs4[1].attrs.IsDisabled and not S.mirage.dealerSeen
    and P.handsOff == true and STOPPED == 0 and string.find(S.note, "your turn", 1, true) ~= nil, S.note)
gear4.Transparency = 0
ON_FLY = function(pos) if (pos - gear4.Position).Magnitude < 1 then gear4.Transparency = 1 end end
S.huntStep(epoch, "gear")
ON_FLY = nil
check("gear hunt: the gear shows - picked, done, the farm stopped",
    S.mirage.got and S.mirage.done and STOPPED == 1
    and string.find(S.mirage.note, "Blue Gear collected", 1, true) ~= nil, S.mirage.note)
RS.kids.NPCs = nil

-- 11. The gear already showing on arrival: taken at once (it does not wait).
local _, gear5 = freshMirage()
gear5.Transparency = 1
S.huntStep(epoch, "gear")              -- land; seen hidden
S.mirage = nil
gear5.Transparency = 0
local gotAt = nil
ON_FLY = function(pos)
    if (pos - gear5.Position).Magnitude < 1 then gear5.Transparency = 1 gotAt = gotAt or #FLIGHTS end
end
fresh()
S.huntStep(epoch, "gear")
ON_FLY = nil
check("the gear showing on arrival: taken right after landing", gotAt == 2 and S.mirage.got, gotAt)

-- 12. No Mirage up: the dealer hunt sails for one like the Mirage hunt.
MAP.kids.MysticIsland = nil
S.mirage = nil
local boatBefore = BOATS.kids["Beast Hunter"]
BOATS:add(mboat)
mboat.pivot = cf(TIKI + vec(-15000, 0, 0), math.pi / 2)     -- 1,500 m out, at the wheel
ROOT.Position = TIKI + vec(-15000, 5, 0)
HUM.SeatPart = mseat
S.driving = false
fresh()
check("dealer hunt, no Mirage up: sailing for one", S.huntStep(epoch, "dealer") == true and S.driving == true, S.note)
S.driving = false
if boatBefore then BOATS:add(boatBefore) end

MAP.kids.MysticIsland = nil
RS.kids.NPCs = nil
S.mirage = nil
end)()

-- ---------------------------------------------------------------- VENTS: GUNS FIRST, THE INVENTORY
;(function()
    local part = inst("Rock", "Part", { Position = vec(10, 10, 10) })
    local function target() return { pos = part.Position, part = part, model = part, learn = {}, alive = function() return true end } end
    TOOLS = { { Name = "Hallow Scythe", ToolTip = "Sword" }, { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" },
        { Name = "Kabucha", ToolTip = "Gun" }, { Name = "Dragon Talon", ToolTip = "Melee" } }
    READY = { ["Hallow Scythe Z"] = true, ["Dragon-Dragon Z"] = true, ["Kabucha Z"] = true, ["Dragon Talon Z"] = true }
    BARS = {}
    reset()
    T.ventCast(target())
    check("vents: a shooting move first - the gun, before fruit / sword / melee", HELD == "Kabucha" and KEYS_SENT[1] == "Z",
        tostring(HELD))
    -- Every key cooling: a sword / gun from your inventory, then fired.
    READY = {}
    local asked = 0
    P.rotate = function(vents)
        asked += 1
        if not vents then return false end
        table.insert(TOOLS, { Name = "Bazooka", ToolTip = "Gun" })
        READY["Bazooka Z"] = true
        return true
    end
    reset()
    T.ventCast(target())
    check("vents: every key cooling - the inventory asked once, its gun fired", asked == 1 and HELD == "Bazooka"
        and KEYS_SENT[1] == "Z", asked .. " " .. tostring(HELD))
    READY = {}
    P.rotate = function() asked += 1 return false end
    asked = 0
    reset()
    T.ventCast(target())
    check("vents: nothing rested in the inventory either - the aimed M1, asked only once", asked == 1)
    P.rotate = nil
end)()

-- ---------------------------------------------------------------- VENTS: THE SKULL GUITAR M1
;(function()
    local ENERGY = { Value = 100 }
    local energyOn = true
    player.Character = { FindFirstChild = function(_, n) return (n == "Energy" and energyOn) and ENERGY or nil end }
    local TAPS = {}
    local spends = true
    local RE = { FireServer = function(_, what, pos)
        table.insert(TAPS, { what, pos })
        if spends then ENERGY.Value -= 20 end
    end }
    local guitar = { Name = "Skull Guitar", ToolTip = "Gun",
        FindFirstChild = function(_, n) return n == "RemoteEvent" and RE or nil end }
    local part = inst("Rock", "Part", { Position = vec(20, 20, 20) })
    local hitsToClose = 2
    local function target()
        local t = { pos = part.Position, part = part, model = part }
        t.alive = function() return #TAPS + M1S < hitsToClose end
        return t
    end
    CFG.VentGuitar, CFG.VentM1Every, CFG.VentM1Time = true, 0.3, 3
    TOOLS = { { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" }, guitar }
    READY = { ["Dragon-Dragon Z"] = true }
    S.learn, S.gunWay, S.gunProbe, S.lowEnergyAt = {}, {}, {}, nil

    -- 1. Its remote spends energy: fired by the remote at the vent, no clicks.
    reset()
    M1S = 0
    check("vents: the Skull Guitar is the vent gun", T.gunForVents() == "Skull Guitar")
    local key, closed = T.gunM1(target(), "Skull Guitar")
    check("guitar: in hand, TAP at the vent itself, closed it", HELD == "Skull Guitar" and closed == true
        and TAPS[1][1] == "TAP" and vnear(TAPS[1][2], part.Position), key)
    check("guitar: the remote proven by its energy - no clicks", S.gunWay["Skull Guitar"] == "remote" and M1S == 0)
    check("guitar: credited as \"Skull Guitar M1\"", S.learn["Skull Guitar M1"] and S.learn["Skull Guitar M1"].closed == 1)
    check("guitar: aimed at the vent while it shoots, the aim cleared after", P.aimAt == nil and aimUntil == 0)

    -- 2. A remote that spends nothing: 3 shots, then the aimed click.
    S.gunWay, S.gunProbe = {}, {}
    TAPS, spends, ENERGY.Value, hitsToClose = {}, false, 100, 99
    M1S = 0
    T.gunM1(target(), "Skull Guitar")
    check("guitar: remote spent no energy in 3 shots - the aimed click from then on",
        S.gunWay["Skull Guitar"] == "click" and #TAPS == 3 and M1S > 0, #TAPS .. " taps, " .. M1S .. " clicks")
    check("guitar: the click is aimed at the vent (silent aim)", vnear(M1_AIM, part.Position), vs(M1_AIM))

    -- 3. Energy not readable: both, every shot.
    S.gunWay, S.gunProbe = {}, {}
    energyOn, TAPS, M1S = false, {}, 0
    T.gunM1(target(), "Skull Guitar")
    check("guitar: energy not readable - remote AND click", S.gunWay["Skull Guitar"] == "both" and #TAPS > 1 and M1S >= #TAPS - 1,
        #TAPS .. " / " .. M1S)
    energyOn = true

    -- 4. Energy under 20: stops at once, the skills for 5 s.
    S.gunWay = { ["Skull Guitar"] = "remote" }
    ENERGY.Value, TAPS = 10, {}
    T.gunM1(target(), "Skull Guitar")
    check("guitar: energy under 20 - no shot, the skills next", #TAPS == 0 and T.gunForVents() == nil)
    CLOCK += 6
    check("...5 s later the guitar again", T.gunForVents() == "Skull Guitar")

    -- 5. Learned useless: 6 tries, nothing closed - the skills.
    S.learn["Skull Guitar M1"] = { casts = 6, closed = 0 }
    check("guitar: 6 tries closed nothing - the skills instead", T.gunForVents() == nil)
    S.learn["Skull Guitar M1"] = { casts = 6, closed = 1 }
    check("...one closed = still the guitar", T.gunForVents() == "Skull Guitar")

    -- 6. Not carried / switch off.
    TOOLS = { { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" } }
    check("no vent gun carried: the skills", T.gunForVents() == nil)
    TOOLS = { { Name = "Bazooka", ToolTip = "Gun" } }
    check("Bazooka carried: it is the vent gun (its M1 breaks things too)", T.gunForVents() == "Bazooka")
    TOOLS = { { Name = "Bazooka", ToolTip = "Gun" }, guitar }
    check("both carried: the Skull Guitar first", T.gunForVents() == "Skull Guitar")
    CFG.VentGuitar = false
    check("switch off: the skills", T.gunForVents() == nil)
    -- 7. The whole event: the guitar in your inventory is loaded, kept, and
    --    its TAPs close the vent - no skill key at all.
    CFG.VentGuitar = true
    S.learn, S.gunWay, S.gunProbe, S.lowEnergyAt = {}, {}, {}, nil
    ENERGY.Value, spends, TAPS, M1S = 100, true, {}, 0
    MAP.kids.PrehistoricIsland = nil
    local isleG, _, ventA = makeIsland(true, false)
    ventA.kids.VFXLayer.kids.Specs.Enabled = true
    RE.FireServer = function(_, what, pos)
        table.insert(TAPS, { what, pos })
        ENERGY.Value -= 20
        ventA.kids.VFXLayer.kids.Specs.Enabled = false
    end
    ENEMIES = {}
    TOOLS = { { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" } }
    READY = { ["Dragon-Dragon Z"] = true }
    local loaded = {}
    P.invHas = function(n) return n == "Skull Guitar" end
    P.loadItem = function(n) table.insert(loaded, n) table.insert(TOOLS, guitar) return true end
    S.ev = nil
    reset()
    S.volcanoStep()
    check("event: the Skull Guitar loaded from your inventory", loaded[1] == "Skull Guitar" and #loaded == 1)
    check("event: kept - no gun swapped in over it", P.keepGun == "Skull Guitar")
    check("event: the vent closed by the guitar's TAPs, no skill key", #TAPS >= 1 and #KEYS_SENT == 0
        and S.ev.vents == 1, #TAPS .. " taps, " .. #KEYS_SENT .. " keys, vents " .. tostring(S.ev.vents))
    P.invHas, P.loadItem = nil, nil
    MAP.kids.PrehistoricIsland = nil
    S.ev = nil
    CFG.VentGuitar = nil
    S.learn = {}
    player.Character = nil
end)()

-- ---------------------------------------------------------------- THE LOOP: HUNT -> EVENT -> LOOT -> NEXT SERVER
;(function()
    local function fresh(active, promptOn)
        MAP.kids.PrehistoricIsland = nil
        S.ev = nil
        return makeIsland(active, promptOn)
    end
    ENEMIES, TOOLS, READY, BARS = {}, {}, {}, {}
    CFG.Volcano = false
    CFG.Hunt, CFG.HuntKind, CFG.VolcanoAfter = true, "prehistoric", "hop"
    -- 1. The hunt alone runs the event; the prompt does nothing -> E held.
    local isleL, ppL = fresh(false, true)
    ppL.onHold = nil
    ON_KEY = function(code) if code == "E" then isleL.attrs.IsMinigameActive = true end end
    reset()
    check("loop: the Prehistoric hunt runs the event - no Volcano switch needed", S.volcanoStep() == true)
    ON_KEY = nil
    check("loop: the prompt did not start it - E held, the event on", KEYS_SENT[#KEYS_SENT] == "E"
        and ppL.held == 1 and S.ev.note == "THE VOLCANO EVENT IS ON", tostring(S.ev.note))
    -- 2. It runs, then ends; no loot: 8 s later DONE -> the hunt hops.
    S.volcanoStep()
    check("loop: event on - not done", not S.ev.complete)
    isleL.attrs.IsMinigameActive = false
    ppL.Enabled = false
    S.volcanoStep()
    check("loop: over, waiting for the loot to come", S.ev.overAt ~= nil and not S.ev.complete)
    CLOCK += 9
    check("loop: 8 s, nothing to pick - DONE, the event step lets go", S.volcanoStep() == false and S.ev.complete == true)
    reset()
    check("loop: the hunt says the next server", S.huntStep(epoch, "prehistoric") == false
        and string.find(tostring(P.elite.why), "next server", 1, true) ~= nil, tostring(P.elite.why))
    -- 3. "again": the same island, a fresh event.
    CFG.VolcanoAfter = "again"
    ppL.Enabled = true
    ppL.onHold = function() isleL.attrs.IsMinigameActive = true end
    reset()
    S.volcanoStep()
    check("again: the relic pressed once more, a second event", ppL.held == 2 and S.ev.ran == false
        and isleL.attrs.IsMinigameActive == true, tostring(ppL.held))
    CFG.VolcanoAfter = "hop"
    -- 4. The game's start bug: 4 presses, nothing -> this island given up, the hunt hops.
    local isleB, ppB = fresh(false, true)
    ppB.onHold = nil
    for _ = 1, 4 do reset() S.volcanoStep() end
    check("start bug: 4 tries - given up", S.ev.stuck == true and S.ev.complete == true, S.ev.starts)
    reset()
    check("start bug: the hunt goes to the next server, says why", S.huntStep(epoch, "prehistoric") == false
        and string.find(tostring(P.elite.why), "would not start", 1, true) ~= nil, tostring(P.elite.why))
    -- 5. The Volcano switch alone (no hunt): done = held there, no hop.
    CFG.Hunt, CFG.Volcano = false, true
    local isleV, ppV = fresh(true, false)
    S.volcanoStep()
    isleV.attrs.IsMinigameActive = false
    S.volcanoStep()
    CLOCK += 9
    check("switch alone: done - held on the island (no hunt, no hop)", S.volcanoStep() == true and S.ev.complete)
    -- 6. Loot picked: the hunt STAYS LootStay seconds after the last pick
    --    before the next server (the game saves it), then the game's count is
    --    written for the next server to check. Diagnostics on the way.
    CFG.Hunt, CFG.HuntKind, CFG.Volcano, CFG.VolcanoAfter, CFG.LootStay = true, "prehistoric", false, "hop", 60
    local isleS = fresh(true, false)
    player.attrs.PrehistoricIslandParticipant = true
    player.Character = { name = "life 1" }
    PRINTED = {}
    S.volcanoStep()
    check("event on: whether the game counts you is said", saidP("you ARE counted"))
    player.Character = { name = "life 2" }
    S.volcanoStep()
    check("a death during the event: said (the game gives no loot after one)", saidP("you died during the event"))
    ITEMS[585], ITEMS[565] = 20, 3
    isleS.attrs.IsMinigameActive = false
    S.volcanoStep()
    S.ev.bones, S.ev.lastPickAt = 5, CLOCK
    CLOCK += 9
    reset()
    check("loot in: not done yet - staying so the game saves it", S.volcanoStep() == true and not S.ev.complete
        and string.find(tostring(S.ev.note), "staying", 1, true) ~= nil, tostring(S.ev.note))
    reset()
    check("...the hunt does not go to the next server meanwhile", S.huntStep(epoch, "prehistoric") == true)
    CLOCK += 61
    FILES["bff_loot.json"] = nil
    check("60 s after the last pick: DONE, the event step lets go", S.volcanoStep() == false and S.ev.complete == true)
    check("...the game's count written for the next server", string.find(tostring(FILES["bff_loot.json"]),
        "bones=20;eggs=3", 1, true) ~= nil, tostring(FILES["bff_loot.json"]))
    check("...DONE says the count before -> after", saidP("Dinosaur Bones"))
    -- 6b. HOME BY RESPAWN (user, 2026-10-10): the stay over, the character
    --     reset - the game's new one at your spawn (Tiki) - then the next server.
    CFG.RespawnHome, CFG.RespawnWait = true, 20
    local oldLife, newLife = player.Character, { name = "life 3" }
    local healthWrites = 0
    -- The game: Health 0 = dead, the new character at the spawn.
    local function gameRespawns(onRung)
        HUM.Health = nil
        setmetatable(HUM, {
            __index = function(_, k) if k == "Health" then return 100 end return nil end,
            __newindex = function(t, k, v)
                if k ~= "Health" then rawset(t, k, v) return end
                healthWrites += 1
                if onRung == "Health 0" and v == 0 then
                    player.Character = newLife
                    ROOT.Position = TIKI + vec(0, 5, 0)
                end
            end,
        })
    end
    local function gameDone() setmetatable(HUM, nil) HUM.Health = 100 end
    local islandAt = ROOT.Position
    gameRespawns("Health 0")
    reset()
    PRINTED = {}
    local okH = S.huntStep(epoch, "prehistoric")
    check("home by respawn: Health 0, the new character at your spawn (Tiki), then the next server", okH == false
        and player.Character == newLife and S.ev.home == "done"
        and string.find(tostring(P.elite.why), "next server", 1, true) ~= nil and saidP("home by respawn (Health 0) - 0 m from Tiki"),
        tostring(P.elite.why) .. " / " .. tostring(S.ev.home))
    check("...never a flight (home is not travel)", #FLIGHTS == 0, #FLIGHTS)
    check("...the inventory read again at home", saidP("you have 20 Dinosaur Bones, 3 Dragon Egg"))
    -- At Tiki the island streams out: only its far marker is left.
    local keepIsle = MAP.kids.PrehistoricIsland
    MAP.kids.PrehistoricIsland = nil
    LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
    reset()
    check("...at Tiki (the island streamed out, its marker up): the event step never flies back",
        S.volcanoStep() == false and #FLIGHTS == 0, #FLIGHTS)
    reset()
    okH = S.huntStep(epoch, "prehistoric")
    check("...a failed hop: the next server again, no second respawn, no flight", okH == false and healthWrites == 1
        and #FLIGHTS == 0)
    MAP.kids.PrehistoricIsland = keepIsle
    LOCS.kids["Prehistoric Island"] = nil
    -- 6c. Health 0 refused: BreakJoints, then the Head; nothing = the next server after 20 s.
    player.Character = oldLife
    local joints, heads = 0, 0
    function oldLife:BreakJoints() joints += 1 end
    function oldLife:FindFirstChild(n)
        if n == "Head" then return { Destroy = function() heads += 1 end } end
        return nil
    end
    gameRespawns("none")
    S.ev.home = nil
    reset()
    PRINTED = {}
    local t0 = CLOCK
    okH = S.huntStep(epoch, "prehistoric")
    check("respawn refused: Health 0, then BreakJoints, then the Head; 20 s, then the next server anyway",
        okH == false and joints == 1 and heads == 1 and CLOCK - t0 >= 20 and S.ev.home == "failed"
        and saidP("no respawn in 20 s (tried: Health 0, BreakJoints, the Head off)"),
        string.format("joints %d heads %d %.1f s %s", joints, heads, CLOCK - t0, tostring(S.ev.home)))
    -- 6c2. Health 0 kills, the game's respawn takes 4 s: nothing more done to the dead body.
    gameDone()
    player.Character = nil
    local dueAt = nil
    setmetatable(player, { __index = function(_, k)
        if k == "Character" then return (dueAt and CLOCK >= dueAt) and newLife or oldLife end
        return nil
    end })
    HUM.Health = nil
    setmetatable(HUM, {
        __index = function(_, k) if k == "Health" then return dueAt and 0 or 100 end return nil end,
        __newindex = function(t, k, v)
            if k ~= "Health" then rawset(t, k, v) return end
            if v == 0 and not dueAt then dueAt = CLOCK + 4 end
        end,
    })
    joints, heads = 0, 0
    S.ev.home = nil
    reset()
    PRINTED = {}
    okH = S.huntStep(epoch, "prehistoric")
    check("dead by Health 0, the respawn 4 s later: BreakJoints / the Head never tried on the dead body",
        okH == false and joints == 0 and heads == 0 and S.ev.home == "done" and saidP("home by respawn (Health 0)"),
        string.format("joints %d heads %d %s", joints, heads, tostring(S.ev.home)))
    setmetatable(player, nil)
    player.Character = oldLife
    gameRespawns("none")
    -- 6d. The God's Chalice on you: no respawn (a death loses it).
    P.holdingChalice = function() return true end
    S.ev.home, healthWrites = nil, 0
    reset()
    PRINTED = {}
    okH = S.huntStep(epoch, "prehistoric")
    check("the God's Chalice on you: NOT home by respawn, said", healthWrites == 0 and joints == 0 and heads == 0
        and saidP("God's Chalice is on you"), healthWrites)
    P.holdingChalice = nil
    -- 6e. The switch off: no respawn.
    CFG.RespawnHome = false
    S.ev.home = nil
    reset()
    okH = S.huntStep(epoch, "prehistoric")
    check("home by respawn off: no reset, the next server", okH == false and healthWrites == 0 and S.ev.home == "skipped")
    CFG.RespawnHome = true
    gameDone()
    ROOT.Position = islandAt
    player.Character = nil
    player.attrs.PrehistoricIslandParticipant = nil
    -- Nothing picked: no stay.
    local isleN = fresh(true, false)
    S.volcanoStep()
    isleN.attrs.IsMinigameActive = false
    S.volcanoStep()
    CLOCK += 9
    check("nothing picked: no stay - DONE at once", S.volcanoStep() == false and S.ev.complete == true)
    -- 7. The next server: the last one's count against this one's.
    FILES["bff_loot.json"] = "bones=20;eggs=3;at=0;job=job-other"
    ITEMS[585], ITEMS[565] = 20, 3
    reset()
    STOPPED = 0
    S.lootCheck = nil
    S.checkLastLoot()
    check("next server, the loot is here: said, the hunt goes on", SET_HUNT[1] == nil and STOPPED == 0
        and string.find(tostring(S.lootCheck), "saved", 1, true) ~= nil, tostring(S.lootCheck))
    FILES["bff_loot.json"] = "bones=20;eggs=3;at=0;job=job-other"
    ITEMS[585], ITEMS[565] = 14, 1
    reset()
    S.checkLastLoot()
    check("next server, LESS here: LOST ON THE HOP said, the hunt stopped", string.find(tostring(S.lootCheck),
        "LOST ON THE HOP", 1, true) ~= nil and SET_HUNT[1] == false and STOPPED == 1, tostring(S.lootCheck))
    check("...checked once (the file emptied)", FILES["bff_loot.json"] == "")
    FILES["bff_loot.json"] = "bones=99;eggs=9;at=0;job=job-this"
    S.lootCheck = nil
    S.checkLastLoot()
    check("a reload in the same server: not checked", S.lootCheck == nil)
    -- 8. Neither list readable: the server is asked at most every 2 s, never a frame.
    local keepRF, keepInvoke = NET["RF/GetAllItemValues"], CF_REMOTE.InvokeServer
    NET["RF/GetAllItemValues"] = nil
    S.qtyRead, S.qtyTry, S.legacyTry = nil, nil, nil
    local asks = 0
    CF_REMOTE.InvokeServer = function(_, what) if what == "getInventory" then asks += 1 end return nil end
    local got = "x"
    for _ = 1, 20 do
        got = S.have({ "Dinosaur Bones" }, false)
        task.wait(0.15)
    end
    check("unreadable: nil, and getInventory asked at most every 2 s (2 in 3 s)", got == nil and asks <= 2, asks)
    NET["RF/GetAllItemValues"], CF_REMOTE.InvokeServer = keepRF, keepInvoke
    FILES["bff_loot.json"] = nil
    CFG.LootStay = nil
    MAP.kids.PrehistoricIsland = nil
    S.ev = nil
    CFG.Hunt, CFG.HuntKind, CFG.Volcano, CFG.VolcanoAfter = false, nil, false, nil
end)()

-- ---------------------------------------------------------------- TREES (S.castAt): BLASTS ONLY
;(function()
    local TAPS = {}
    local RE = { FireServer = function(_, what, pos) table.insert(TAPS, { what, pos }) end }
    local guitar = { Name = "Skull Guitar", ToolTip = "Gun",
        FindFirstChild = function(_, n) return n == "RemoteEvent" and RE or nil end }
    local trunk = inst("Trunk", "Part", { Position = vec(30, 5, 30) })
    local standing = true
    local learn = {}
    local function tree() return { pos = trunk.Position, part = trunk, model = trunk, learn = learn,
        alive = function() return standing end } end
    CFG.VentGuitar, CFG.VentM1Every, CFG.VentM1Time = true, 0.3, 1
    S.learn, S.gunWay, S.lowEnergyAt = {}, { ["Skull Guitar"] = "remote" }, nil
    player.Character = nil
    -- 1. The guitar carried: its M1 first, credited to the TREES' table.
    TOOLS = { { Name = "Dragon Talon", ToolTip = "Melee" }, guitar }
    READY = { ["Dragon Talon Z"] = true }
    reset()
    M1S = 0
    local key = S.castAt(tree())
    check("trees: the Skull Guitar M1 first (the wiki: its M1 breaks trees)", key == "Skull Guitar M1" and #TAPS > 0
        and #KEYS_SENT == 0, tostring(key))
    check("trees: learned in the trees' own table, not the vents'", learn["Skull Guitar M1"] ~= nil and S.learn["Skull Guitar M1"] == nil)
    -- 2. No gun: the skills of every weapon - never a plain M1.
    TOOLS = { { Name = "Dragon Talon", ToolTip = "Melee" }, { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" } }
    READY = { ["Dragon-Dragon Z"] = true }
    reset()
    M1S = 0
    key = S.castAt(tree())
    check("trees, no gun: a skill fired at the tree", key == "Dragon-Dragon Z" and KEYS_SENT[1] == "Z", tostring(key))
    -- 3. Every key cooling: no M1 at all, nothing fired.
    READY = {}
    reset()
    M1S = 0
    key = S.castAt(tree())
    check("trees, every key cooling: NO plain M1 (a fighting style's does nothing), nothing fired", key == nil and M1S == 0,
        tostring(key) .. " " .. M1S)
    -- 4. The guitar useless on trees (6 tries, none broke): the skills.
    TOOLS = { { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" }, guitar }
    READY = { ["Dragon-Dragon Z"] = true }
    learn["Skull Guitar M1"] = { casts = 6, closed = 0 }
    reset()
    key = S.castAt(tree())
    check("trees: the guitar learned useless on trees - the skills", key == "Dragon-Dragon Z", tostring(key))
    CFG.VentGuitar = nil
    S.learn, S.gunWay = {}, {}
end)()

-- ---------------------------------------------------------------- THE GOLEM WEAPON
;(function()
    check("golems: the fight names CFG.GolemWeapon", (function()
        CFG.GolemWeapon = "Cursed Dual Katana"
        return S.GOLEM_CUR.m1Weapon() == "Cursed Dual Katana"
    end)())
    local function event()
        MAP.kids.PrehistoricIsland = nil
        S.ev = nil
        makeIsland(true, false)
        ENEMIES, READY = {}, {}
        CFG.Volcano = true
        reset()
        S.volcanoStep()
    end
    -- In the inventory: loaded at the event.
    local loaded = {}
    TOOLS = { { Name = "Hallow Scythe", ToolTip = "Sword" } }
    P.invHas = function(n) return n == "Cursed Dual Katana" end
    P.loadItem = function(n) table.insert(loaded, n) table.insert(TOOLS, { Name = n, ToolTip = "Sword" }) return true end
    event()
    check("golem weapon: loaded from your inventory at the event", loaded[1] == "Cursed Dual Katana"
        and string.find(tostring(S.golemNote), "loaded", 1, true) ~= nil, tostring(S.golemNote))
    -- Carried: nothing loaded.
    loaded = {}
    event()
    check("golem weapon: carried - nothing loaded", #loaded == 0 and string.find(tostring(S.golemNote), "carried", 1, true) ~= nil)
    -- Nowhere: says so, the Attack page pick.
    TOOLS = { { Name = "Hallow Scythe", ToolTip = "Sword" } }
    P.invHas = function() return false end
    event()
    check("golem weapon: not found - said, the Attack page pick", #loaded == 0
        and string.find(tostring(S.golemNote), "not found", 1, true) ~= nil, tostring(S.golemNote))
    -- "" = no golem weapon: nothing tried.
    CFG.GolemWeapon = ""
    S.golemNote = nil
    event()
    check("golem weapon off: nothing loaded, nothing said", S.golemNote == nil and #loaded == 0)
    P.invHas, P.loadItem = nil, nil
    MAP.kids.PrehistoricIsland = nil
    S.ev, CFG.Volcano, CFG.GolemWeapon = nil, false, nil
end)()

-- ---------------------------------------------------------------- AUTO STEERING: LEFT, RIGHT, STRAIGHT
;(function()
    local function seq(list)
        local i = 0
        return function() i += 1 return list[(i - 1) % #list + 1] end
    end
    local h, wait = T.nextHeading(0, seq({ 0.1, 0.0, 0.5 }), 60, 20, 45)
    check("steer: a third of the time LEFT (+), 10 deg at the least", near(h, 10) and near(wait, 90), h .. " " .. wait)
    h = T.nextHeading(10, seq({ 0.5, 1 - 1e-9, 0 }), 60, 20, 45)
    check("steer: a third RIGHT (-), from where it heads now, up to 20", near(h, -10, 1e-6), h)
    h = T.nextHeading(-10, seq({ 0.9, 0.5, 0 }), 60, 20, 45)
    check("steer: a third STRAIGHT ON", near(h, -10))
    h = T.nextHeading(40, seq({ 0.1, 1 - 1e-9, 0 }), 60, 20, 45)
    check("steer: never past 45 off west - a turn past it goes the other way", near(h, 20, 1e-6), h)
    -- 300 turns at random: all three kinds, sizes 10..20, waits 60..120, inside +-45.
    math.randomseed(7)
    local cur, l, r, st, okSize, okWait, okLim = 0, 0, 0, 0, true, true, true
    for _ = 1, 300 do
        local nh, w = T.nextHeading(cur, math.random, 60, 20, 45)
        local d = nh - cur
        if d > 0 then l += 1 elseif d < 0 then r += 1 else st += 1 end
        if d ~= 0 and (math.abs(d) < 10 - 1e-9 or math.abs(d) > 20 + 1e-9) then okSize = false end
        if w < 60 or w > 120 then okWait = false end
        if math.abs(nh) > 45 then okLim = false end
        cur = nh
    end
    check("steer: left, right and straight all happen", l > 50 and r > 50 and st > 50, l .. "/" .. r .. "/" .. st)
    check("steer: every turn 10..20 deg, every 1..2 min, always within 45 of west", okSize and okWait and okLim)
    -- The drive itself turns: a turn due, auto steering, at the wheel.
    local bt, st2 = makeBoat(vec(-30000, 5, 400), math.pi / 2)
    S.boat, S.seat, S.driving, P.running = bt, st2, true, true
    HUM.SeatPart = st2
    CFG.SeaSteer, CFG.SeaTurnEvery, CFG.SeaTurnMax = "auto", 60, 20
    local turned = false
    for i = 1, 40 do
        T.drive.waterY, T.drive.wobbleAt, T.drive.want = 5, 0, 0
        T.driveTick(0.1)
        local wnt, at = T.drive.want, T.drive.wobbleAt
        if wnt ~= 0 then
            turned = math.abs(wnt) >= 10 - 1e-9 and math.abs(wnt) <= 20 + 1e-9
                and at - CLOCK >= 60 - 1e-6 and at - CLOCK <= 120 + 1e-6
            break
        end
    end
    check("the drive: a turn due - a new heading 10..20 off, the next turn 1..2 min on", turned)
    S.driving = false
    CFG.SeaSteer = "auto"
end)()

-- ---------------------------------------------------------------- THE SEARCH'S LEGS (pure) + THE TURNED HEADING
;(function()
    local st = { leg = 1 }
    check("legs: short of 23k - out", T.searchLeg(st, 10000, 10000, 23000, 120, 10000) == "out" and st.leg == 1)
    check("legs: at 23k - turn, once: 120 left", T.searchLeg(st, 23000, 23500, 23000, 120, 10000) == "turn"
        and st.leg == 2 and st.base == 120 and st.odo0 == 23500)
    check("legs: after the turn, closer to Tiki - still sailing back (by the odometer, not the distance)",
        T.searchLeg(st, 20000, 30000, 23000, 120, 10000) == "back")
    check("legs: 10k sailed after the turn - the next server", T.searchLeg(st, 19000, 33500, 23000, 120, 10000) == "hop")
    check("legs: 0 m after the turn = the next server at the edge", T.searchLeg({ leg = 1 }, 23000, 0, 23000, 120, 0) == "hop")
    -- The drive follows the turned heading: 120 left of west = east-north-east-ish, +Z.
    local bt, st2 = makeBoat(vec(-30000, 5, 400), math.pi / 2)
    S.boat, S.seat, S.driving, P.running = bt, st2, true, true
    HUM.SeatPart = st2
    CFG.SeaSteer = "auto"
    T.drive.waterY, T.drive.wobbleAt, T.drive.want, T.drive.base, T.drive.odo = 5, 1e9, 0, 120, 0
    T.driveTick(0.1)
    local p = bt.pivot.Position
    check("the drive: sails the turned heading (120 left of west: +X and +Z)", p.X > -30000 and p.Z > 400
        and near(T.drive.odo, 30, 1e-6), vs(p) .. " odo " .. T.drive.odo)
    T.drive.base, T.drive.leg = 0, 1
    S.driving = false
end)()

-- ---------------------------------------------------------------- THE VOLCANIC MAGNET BEFORE THE SAIL
;(function()
    MAP.kids.PrehistoricIsland = nil
    LOCS.kids["Prehistoric Island"] = nil
    S.ev, S.foundAt, S.sailStart, S.driving = nil, nil, nil, false
    CFG.SeaSearchMinutes = 21
    local busy = true
    P.magnet = { note = "Scrap Metal for the magnet: 2 / 10", step = function() return busy end }
    reset()
    local ok = S.huntStep(epoch, "prehistoric")
    check("magnet: getting it - busy, no sail, the 21 min NOT started", ok == true and S.sailStart == nil
        and string.find(S.note, "before the sail", 1, true) ~= nil and #BUY_CALLS == 0, S.note)
    busy = false
    reset()
    S.huntStep(epoch, "prehistoric")
    check("magnet held: the 21 min start now, at the sail", S.sailStart == CLOCK)
    -- The Mirage hunt: no magnet step.
    busy = true
    S.sailStart = nil
    reset()
    S.huntStep(epoch, "mirage")
    check("the Mirage hunt: no magnet step", string.find(tostring(S.note), "before the sail", 1, true) == nil)
    P.magnet = nil
    CFG.SeaSearchMinutes = 0
    S.sailStart, S.driving = nil, false
end)()

-- ---------------------------------------------------------------- THE CRATER: NEVER ACROSS IT
;(function()
    local c = vec(0, 200, 0)
    local function minDist(path, from)
        -- closest any straight leg of the path comes to the middle
        local best, prev = math.huge, from
        for _, p in ipairs(path) do
            local a, b = vec(prev.X, 0, prev.Z), vec(p.X, 0, p.Z)
            local seg = b - a
            local t = 0
            if seg.Magnitude > 0.01 then t = math.clamp(-(a.X * seg.X + a.Z * seg.Z) / (seg.X ^ 2 + seg.Z ^ 2), 0, 1) end
            local q = a + seg * t
            best = math.min(best, vec(q.X, 0, q.Z).Magnitude)
            prev = p
        end
        return best
    end
    -- The skull's prompt on the far side (90 from the middle), you on this side.
    local from, to = vec(-800, 5, 0), vec(90, 23, 0)
    local path = T.arcPath(from, to, c, 220)
    check("crater: the prompt behind the volcano - the way goes ROUND (corners on the 275 circle)", #path >= 3
        and near(T.horiz(path[1], c), 275, 1e-6) and vnear(path[#path], to), #path)
    -- Every leg but the last stays out of the disc; the last comes in on the prompt's own bearing.
    local outside = minDist({ table.unpack(path, 1, #path - 1) }, from)
    check("crater: no leg before the last crosses the disc", outside >= 220 - 1e-6, outside)
    local last0 = path[#path - 1]
    check("crater: the last leg comes in from the prompt's side (same bearing, from outside)",
        near(math.atan2(last0.Z - c.Z, last0.X - c.X), math.atan2(to.Z - c.Z, to.X - c.X), 1e-6))
    -- The straight line keeps out: straight.
    path = T.arcPath(vec(-800, 5, 400), vec(800, 5, 400), c, 220)
    check("crater: a line that keeps out of it - straight, one leg", #path == 1)
    -- A short hop: straight.
    check("crater: a short hop - straight", #T.arcPath(vec(90, 23, 0), vec(100, 23, 10), c, 220) == 1)
    -- The edge (only the marker): toward you, 1.6x out, 30 up.
    local e = T.edgeOf(vec(0, 55, 0), vec(5000, 5, 0), 220)
    check("crater: the island's edge toward you", vnear(e, vec(352, 85, 0)), vs(e))
    -- The lava goes the moment the island streams in (before any event).
    MAP.kids.PrehistoricIsland = nil
    S.ev, S.lavaAt = nil, nil
    local isleL = makeIsland(false, false)
    CFG.Volcano = true
    reset()
    S.volcanoStep()
    check("crater: the island streamed in, no event yet - its lava already off", isleL.kids.Core.kids.InteriorLava.destroyed == true
        and isleL.kids.LavaPool.destroyed == true)
    -- Starting the event from BEHIND the volcano: round it to the skull's prompt.
    MAP.kids.PrehistoricIsland = nil
    S.ev = nil
    local isleS, ppS = makeIsland(false, true)
    ppS.onHold = function() isleS.attrs.IsMinigameActive = true end
    ROOT.Position = vec(-69800, 40, 6500)          -- 300 behind the middle; the prompt is in front (z 6890)
    reset()
    S.volcanoStep()
    check("crater: the event started from behind the volcano - flown ROUND it to the prompt",
        T.hasFlight(vec(-69800, 23, 6890)) and T.cornersClear(vec(-69800, 200, 6800), 220) and #FLIGHTS >= 3, #FLIGHTS)
    MAP.kids.PrehistoricIsland = nil
    S.ev, CFG.Volcano = nil, false
end)()

-- ---------------------------------------------------------------- SEA EVENTS' HOOKS (2026-10-09)
;(function()
    -- The wheel steered by the sea events hunt: { dir, speed } every frame.
    local b2, s2 = makeBoat(vec(-38000, 5, 4000), math.pi / 2)      -- facing west
    S.boat, S.seat, S.driving = b2, s2, true
    HUM.SeatPart = s2
    T.drive.waterY = 5
    S.steerFn = function() return { dir = vec(0, 0, 1), speed = 60 } end
    T.driveTick(0.1)
    check("steered by another hunt: along its direction at its speed (6 studs +Z), on the water line",
        vnear(b2.pivot.Position, vec(-38000, 5, 4006)), vs(b2.pivot.Position))
    check("steered by another hunt: the bow turns toward it, 90 deg/s at most",
        near(math.abs(b2.pivot.yaw - math.pi / 2), math.rad(9), 1e-6), b2.pivot.yaw)
    S.steerFn = function() return nil end
    CFG.SeaSteer = "auto"
    T.drive.wobbleAt, T.drive.want, T.drive.base = 1e9, 0, 0
    b2.pivot, s2.CFrame = cf(vec(-38000, 5, 4000), math.pi / 2), cf(vec(-38000, 5, 4000), math.pi / 2)
    T.driveTick(0.1)
    check("the hook answering nil: the hunt's own steering (west at SeaSpeed)",
        vnear(b2.pivot.Position, vec(-38030, 5, 4000)), vs(b2.pivot.Position))
    S.steerFn, S.driving, HUM.SeatPart = nil, false, nil

    -- The vent caster on a sea beast: its own keys (F too), credited by its HP.
    local part = inst("Beast", "Part", { Position = vec(0, 60, 0) })
    local HP = 1000
    TOOLS = { { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" }, { Name = "Skull Guitar", ToolTip = "Gun" } }
    READY = { ["Kitsune-Kitsune F"] = true }
    BARS = {}
    P.rotate = nil
    local learn = {}
    local v = { pos = part.Position, part = part, model = part, learn = learn,
        keys = { "Z", "X", "C", "V", "F" }, keyOn = { Z = true, F = true }, m1Watch = 0.5,
        alive = function() return HP > 0 end }
    v.mark = function() v.hp0 = HP end
    v.dropped = function() return HP < v.hp0 end
    ON_KEY = function(code) if code == "F" then HP -= 50 end end
    reset()
    local key, landed = T.ventCast(v)
    check("sea beast: F (a sea event key, never a vent key) fired and credited by the HP drop",
        KEYS_SENT[1] == "F" and landed == true and learn["Kitsune-Kitsune F"] and learn["Kitsune-Kitsune F"].closed == 1,
        tostring(key) .. " " .. tostring(KEYS_SENT[1]))
    -- A key that did not lower the HP: fired, NOT credited.
    ON_KEY = nil
    CLOCK += 100
    reset()
    key, landed = T.ventCast(v)
    check("sea beast: a key that took no HP is a miss (cast counted, not credited)",
        landed == false and learn["Kitsune-Kitsune F"].casts == 2 and learn["Kitsune-Kitsune F"].closed == 1, tostring(landed))
    -- Every key cooling: the M1 of the weapon v.m1Tool names, in hand first.
    READY, HELD = {}, "Skull Guitar"
    v.m1Tool = function() return "Kitsune-Kitsune" end
    local m1s0 = M1S
    v.dropped = function() return M1S > m1s0 end
    reset()
    key, landed = T.ventCast(v)
    check("sea beast: every key cooling - the M1 of the weapon that hurts it, in hand first, credited",
        HELD == "Kitsune-Kitsune" and M1S == m1s0 + 1 and key == "M1 Kitsune-Kitsune" and landed == true
        and learn["M1 Kitsune-Kitsune"].closed == 1, tostring(key) .. " " .. tostring(HELD))
    -- A transformed fruit (v.toolOk): only its moves are fired.
    READY = { ["Kitsune-Kitsune Z"] = true, ["Skull Guitar Z"] = true }
    HELD = nil
    reset()
    T.ventCast({ pos = part.Position, part = part, model = part, learn = {}, alive = function() return true end,
        keys = { "Z" }, keyOn = { Z = true }, toolOk = function(n) return n == "Kitsune-Kitsune" end })
    check("sea beast, Kitsune form: the gun's Z (refused by the game) is never fired - Kitsune's is",
        HELD == "Kitsune-Kitsune" and KEYS_SENT[1] == "Z", tostring(HELD))
    -- v.suffix: a transformed fruit's moves learned apart ("(form)").
    READY = { ["Kitsune-Kitsune Z"] = true }
    HELD = nil
    local lf = {}
    reset()
    local fk = T.ventCast({ pos = part.Position, part = part, model = part, learn = lf, alive = function() return true end,
        keys = { "Z" }, keyOn = { Z = true }, suffix = " (form)" })
    check("sea beast in form: its key learned apart - \"Kitsune-Kitsune Z (form)\"", fk == "Kitsune-Kitsune Z (form)"
        and lf["Kitsune-Kitsune Z (form)"] and lf["Kitsune-Kitsune Z"] == nil, tostring(fk))
    READY = {}
    local mk = T.ventCast({ pos = part.Position, part = part, model = part, learn = lf, alive = function() return true end,
        keys = { "Z" }, keyOn = { Z = true }, suffix = " (form)", m1Tool = function() return "Kitsune-Kitsune" end })
    check("...its M1 too - \"M1 Kitsune-Kitsune (form)\"", mk == "M1 Kitsune-Kitsune (form)", tostring(mk))
    -- v.noRotate: every key cooling, no sword / gun loaded (a fruit + melee fight).
    local loads = 0
    P.rotate = function() loads += 1 return false end
    T.ventCast({ pos = part.Position, part = part, model = part, learn = {}, alive = function() return true end,
        keys = { "Z" }, keyOn = { Z = true }, noRotate = function() return true end })
    check("sea beast, fruit + melee only: every key cooling - nothing loaded from the inventory", loads == 0, loads)
    T.ventCast({ pos = part.Position, part = part, model = part, learn = {}, alive = function() return true end,
        keys = { "Z" }, keyOn = { Z = true } })
    check("...a vent (no such rule): the inventory asked as before", loads == 1, loads)
    P.rotate = nil
    -- A vent never fires F (no keys of its own): unchanged.
    READY = { ["Kitsune-Kitsune F"] = true }
    HELD = nil
    reset()
    T.ventCast({ pos = part.Position, part = part, model = part, learn = {}, alive = function() return true end })
    check("a vent: F is not one of its keys - nothing fired but the aimed M1", #KEYS_SENT == 0, #KEYS_SENT)
end)()

realPrint(all and "ALL PASS" or "SOME FAILED")
