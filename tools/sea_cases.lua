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
check("every golem held: the vent, stood 12 out, 8 up", vnear(FLIGHTS[1], vec(-69738, 208, 6800)), vs(FLIGHTS[1]))
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
ok = S.huntStep(epoch, "mirage")
local said = false
for _, l in ipairs(PRINTED) do if string.find(l, "sailing on", 1, true) then said = true end end
check("a Mirage gone before night: sailed past, still at the wheel, says why", ok == true and S.driving == true
    and not P.handsOff and said and S.mirage and S.mirage.fits == false)
LOCS.kids["Mirage Island"] = nil
S.huntStep(epoch, "mirage")
check("it went: forgotten", S.mirage == nil)
-- One that sees night: onto it, the character handed back.
P.news.sky = { night = true, edge = 600 }
local isleM, gear = mysticIsle({ t = 1 })
MAP:add(isleM)
LOCS:add(mm)
reset()
RESTORED = 0
ok = S.huntStep(epoch, "mirage")
check("a Mirage that sees night: off the boat, onto it", ok == true and S.driving == false
    and vnear(FLIGHTS[1], vec(-40000, 320, 3000)), vs(FLIGHTS[1]))
check("...and the character is yours: hands off, your collisions back", P.handsOff == true and RESTORED == 1 and flying == false)
reset()
S.huntStep(epoch, "mirage")
check("gear hidden: nothing moves, your turn", #FLIGHTS == 0 and P.handsOff and string.find(S.note, "your turn", 1, true) ~= nil, S.note)
-- The moon resonates: the gear shows.
gear.Transparency = 0
ON_FLY = function(pos) if (pos - gear.Position).Magnitude < 1 then gear.Transparency = 1 end end
reset()
STOPPED = 0
S.huntStep(epoch, "mirage")
ON_FLY = nil
check("the gear shows: run over at once, picked", vnear(FLIGHTS[1], gear.Position) and S.mirage.got
    and S.tally.gears == 1, vs(FLIGHTS[1]))
check("...then the hunt off and the farm stopped, you left on the Mirage", SET_HUNT[1] == false and STOPPED == 1)
-- A gear that will not pick up: back to you, tried again, then left to you.
S.mirage = nil
local isleN, gear2 = mysticIsle({ t = 1 })
MAP.kids.MysticIsland = nil
MAP:add(isleN)
S.huntStep(epoch, "mirage")
gear2.Transparency = 0
reset()
S.huntStep(epoch, "mirage")
check("a gear that stays: hands back to you, tried again", S.mirage.tries == 1 and P.handsOff == true and not S.mirage.got)
S.huntStep(epoch, "mirage")
S.huntStep(epoch, "mirage")
reset()
S.huntStep(epoch, "mirage")
check("three tries: left to you, no more flights", S.mirage.tries == 3 and #FLIGHTS == 0
    and string.find(S.mirage.note, "yourself", 1, true) ~= nil, S.mirage.note)
-- The fallback "Part": not trusted when first seen visible.
S.mirage = nil
local isleP, part = mysticIsle({ t = 0 }, true)
MAP.kids.MysticIsland = nil
MAP:add(isleP)
reset()
S.huntStep(epoch, "mirage")
reset()
S.huntStep(epoch, "mirage")
check("a visible \"Part\" never seen hidden: not the gear", #FLIGHTS == 0 and not S.mirage.got)
part.Transparency = 1
S.huntStep(epoch, "mirage")
part.Transparency = 0
ON_FLY = function(pos) if (pos - part.Position).Magnitude < 1 then part.Transparency = 1 end end
reset()
S.huntStep(epoch, "mirage")
ON_FLY = nil
check("...seen hidden, then shown: picked", S.mirage.got == true)
-- The Mirage goes while it is your turn: the farm drives again.
S.mirage = nil
P.handsOff = false
local isleG = mysticIsle({ t = 1 })
MAP.kids.MysticIsland = nil
MAP:add(isleG)
S.huntStep(epoch, "mirage")
check("(your turn again on a new one)", P.handsOff == true)
MAP.kids.MysticIsland = nil
LOCS.kids["Mirage Island"] = nil
reset()
S.huntStep(epoch, "mirage")
check("the Mirage went on your turn: the farm drives again, back to the boat", P.handsOff == false and S.mirage == nil)
-- A Prehistoric while hunting the Mirage: not this hunt's island.
local pre = LOCS:add(inst("Prehistoric Island", "Part", { Position = vec(-69800, 55, 6800) }))
reset()
S.huntStep(epoch, "mirage")
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

realPrint(all and "ALL PASS" or "SOME FAILED")
