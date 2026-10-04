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
local S = P.sea
local T = S._t
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
check("magnet on: a vent before a golem (held golems cannot reach the relic)",
    T.defendPick(true, true, true) == "vent" and T.defendPick(false, true, true) == "golem")
check("magnet off: a golem before a vent", T.defendPick(true, true, false) == "golem"
    and T.defendPick(true, false, false) == "vent")
check("nothing live: wait", T.defendPick(false, false, true) == "wait" and T.defendPick(false, false, false) == "wait")

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
    local e = { model = m, hum = { Health = hp or 50000 }, root = { Position = pos }, name = "Lava Golem" }
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
PUTBACK[g1.model], PUTBACK[g2.model] = true, true
list, centre, inPlace = T.golemBuild()
check("golems put back (no damage held): fought where they stand", #list == 1 and inPlace == true)
PUTBACK = {}
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
CF_REMOTE.InvokeServer = function(_, ...)
    table.insert(BUY_CALLS, { ... })
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
check("the island up: off the boat, over it, never the next server", ok == true and S.driving == false
    and vnear(FLIGHTS[#FLIGHTS], vec(-69800, 95, 6800)) and S.tally.found == 1, vs(FLIGHTS[#FLIGHTS]))
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
check("only the far marker: flown to, over it", S.volcanoStep() == true and vnear(FLIGHTS[1], vec(-69800, 135, 6800)),
    vs(FLIGHTS[1]))

local isle, pp, rA, rB = makeIsland(false, true)
pp.onHold = function() isle.attrs.IsMinigameActive = true end
reset()
S.driving = true
S.volcanoStep()
check("island up while sailing: the wheel stopped", S.driving == false)
check("prompt on: flown to the relic's prompt and held, the event on",
    vnear(FLIGHTS[1], vec(-69800, 23, 6890)) and pp.held == 1 and S.tally.events == 1
    and S.ev.note == "THE VOLCANO EVENT IS ON", tostring(S.ev.note))
check("the cage: 60 off the relic, away from the volcano", vnear(S.ev.cage, vec(-69800, 20, 6960)), vs(S.ev.cage))

-- On: a live vent and a golem, magnet on.
rA.kids.VFXLayer.kids.Specs.Enabled = true
local g = golem(vec(-69800, 20, 6895))
ENEMIES = { g }
TOOLS = { { Name = "Hallow Scythe", ToolTip = "Sword" }, { Name = "Dragon-Dragon", ToolTip = "Blox Fruit" } }
READY = { ["Hallow Scythe Z"] = true, ["Dragon-Dragon Z"] = true, ["Dragon-Dragon X"] = true }
BARS = { ["Dragon-Dragon Z"] = true }      -- still "ready" after the key: it did not fire
reset()
ROOT.Position = vec(-69800, 40, 6900)
S.volcanoStep()
check("event on, magnet: the golems held first (the pile is theirs, active)",
    pileCur == GOLEM_CUR and pileActive == true and REFRESHED >= 1)
check("the vent before the golem: stood 12 out, 8 up", vnear(FLIGHTS[1], vec(-69738, 208, 6800)), vs(FLIGHTS[1]))
check("fruit first: Dragon-Dragon Z, aimed AT the vent", HELD == "Dragon-Dragon" and KEYS_SENT[1] == "Z"
    and vnear(AIMED[1], vec(-69750, 200, 6800)), tostring(HELD) .. " " .. tostring(KEYS_SENT[1]) .. " " .. vs(AIMED[1]))
check("the aim point is cleared after the cast", P.aimAt == nil and aimUntil == 0)
check("lava off your client: InteriorLava and the lava pool, not the vents",
    isle.kids.Core.kids.InteriorLava.destroyed and isle.kids.LavaPool.destroyed and not rA.destroyed)
reset()
S.volcanoStep()
check("a key that did not fire is left out: X next", KEYS_SENT[1] == "X", tostring(KEYS_SENT[1]))
-- The cast closes it.
local closed0 = S.ev.vents
BARS = {}
READY = { ["Hallow Scythe Z"] = true }
rA.kids.VFXLayer.kids.Specs.Enabled = false
rA.kids.Inner.kids.At1Beam.Enabled = true
reset()
-- the next key lands: the beam goes out
ON_KEY = function() rA.kids.Inner.kids.At1Beam.Enabled = false end
S.volcanoStep()
ON_KEY = nil
check("the vent goes out after the hit: counted", S.ev.vents == closed0 + 1 and S.tally.vents >= 1,
    S.ev.vents .. " " .. closed0)
check("Hallow Scythe Z when it is the only one ready", HELD == "Hallow Scythe")
-- Nothing ready: an aimed M1.
READY = {}
rB.kids.VFXLayer.kids.Specs.Enabled = true
reset()
local m0 = M1S
S.volcanoStep()
check("every key cooling: an aimed M1 instead", M1S == m0 + 1 and S.lastVent == "M1 (every key cooling)")
-- No vent: the golem.
rB.kids.VFXLayer.kids.Specs.Enabled = false
reset()
S.volcanoStep()
check("no vent live: the golems are fought", FIGHTS[1] == "Lava Golem", tostring(FIGHTS[1]))
check("the fight breaks when a vent opens (magnet on)", GOLEM_CUR.breakIf() == false)
rB.kids.VFXLayer.kids.Specs.Enabled = true
check("...and it does", GOLEM_CUR.breakIf() == true)
CFG.Magnet = false
check("magnet off: a vent does not break the golem fight", GOLEM_CUR.breakIf() == false)
reset()
S.volcanoStep()
check("magnet off: the golem before the vent", FIGHTS[1] == "Lava Golem" and #KEYS_SENT == 0)
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

-- The win: the bones, then the egg.
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
-- touching it picks it up
ON_FLY = function(pos)
    if (pos - bone.Position).Magnitude < 1 then
        WS.kids.DinoBone = nil
        bone.Parent = nil
    end
end
S.volcanoStep()
ON_FLY = nil
check("a bone lying: flown onto it, picked, counted", vnear(FLIGHTS[1], vec(-69790, 20, 6920)) and S.ev.phase == "loot"
    and S.ev.bones == 1 and S.tally.bones == 1, vs(FLIGHTS[1]) .. " " .. S.ev.bones)
reset()
egg.onHold = function(p) p.Enabled = false end
S.volcanoStep()
check("no bones left: the egg, held", egg.held == 1 and S.ev.eggs == 1 and S.tally.eggs == 1, tostring(egg.held) .. " " .. S.ev.eggs)
-- An egg that will not come: given up after two holds.
local egg2 = prompt(true)
egg2.Name = "P2"
molten:add(egg2)
reset()
S.volcanoStep()
S.volcanoStep()
check("an egg that stays: given up after two, says why", string.find(S.ev.note, "Dragon Tether", 1, true) ~= nil, S.ev.note)
reset()
S.volcanoStep()
check("nothing left: held at the relic", S.ev.phase == "idle" and vnear(FLIGHTS[1], vec(-69800, 50, 6900)), vs(FLIGHTS[1]))

-- A new island: a new count.
MAP.kids.PrehistoricIsland = nil
local isle2 = makeIsland(false, false)
S.volcanoStep()
check("another island: its own counts", S.ev.isle == isle2 and S.ev.vents == 0 and S.ev.golems == 0)

realPrint(all and "ALL PASS" or "SOME FAILED")
