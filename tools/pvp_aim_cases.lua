S.on = true

-- ===== the wiring: pick -> his path -> this frame's aim points =====
-- him: 60 studs east of you, running north-east... on the screen, near the cursor
local him = makePlayer("him", v3(60, 3, 0))
OTHERS = { him }
local hroot = him.Character.kids.HumanoidRootPart
local function runFor(secs, vx, vz)
    -- 60 frames a second: he moves, the frame's tick runs
    local frames = math.floor(secs * 60 + 0.5)
    for _ = 1, frames do
        NOW += 1 / 60
        hroot.Position = hroot.Position + v3(vx / 60, 0, vz / 60)
        targetTick(NOW)
    end
end
MOUSE = { X = 400 + 60 * 5, Y = 300 }            -- the cursor on him
targetTick(NOW)
check("the cursor on him: he is picked", S.target ~= nil and S.target.id == him)
check("one look: no path yet -> aimed where he is", S.aimSkill == hroot.Position)

-- he runs 90 studs/s east; the cursor follows him
local function follow() MOUSE = { X = 400 + hroot.Position.X * 5, Y = 300 + hroot.Position.Z * 5 } end
for _ = 1, 30 do runFor(1 / 60, 90, 0) follow() end
local pos = hroot.Position
local dist = S.target.dist
local t = 0.12 + 0.05 + dist / 300                 -- ping 120 ms + buffer + travel
check("a running player: the skill point is ahead by his speed x (ping + buffer + travel)",
    near(S.aimSkill.X, pos.X + 90 * t, 0.05) and near(S.aimSkill.Z, pos.Z, 1e-6))
check("...his height kept over the floor (flat ground)", near(S.aimSkill.Y, 3, 1e-6))
check("the panel's numbers follow", near(S.lead.t, t, 1e-6) and near(S.lead.speed, 90, 1e-6) and near(S.lead.ahead, 90 * t, 0.05))
check("no gun in hand: the gun's point = where he is", S.aimShot == pos)
check("what the skill table answers is the skill point", S.aimPoint("skill") == S.aimSkill)
check("what your mouse answers (a gun) is the shot point", S.aimPoint("gun") == S.aimShot)

-- a ray gun: never ahead; a slow gun: ahead at its own speed
TOOL = inst("Tool", { Name = "Musket", ToolTip = "Gun" })
targetTick(NOW)
check("a ray gun: the shot point is him as you see him", S.aimShot == hroot.Position and S.lead.gun == "hitscan")
TOOL = inst("Tool", { Name = "Cannon", ToolTip = "Gun", projectile = true, speed = 170 })
targetTick(NOW)
local tg = 0.12 + 0.05 + S.target.dist / 170
check("a slow gun (Cannon): its shot ahead by its own travel", near(S.aimShot.X, hroot.Position.X + 90 * tg, 0.05)
    and S.lead.gun == "gun")
check("...and the skill point still by the skill travel", S.aimSkill.X < S.aimShot.X)
TOOL = nil

-- lead off: where he is
CFG.PvpLead = false
targetTick(NOW)
check("lead off: aimed where he is", S.aimSkill == hroot.Position)
CFG.PvpLead = true

-- lead strength
CFG.PvpLeadScale = 0.5
targetTick(NOW)
local th = (0.12 + 0.05 + S.target.dist / 300) * 0.5
check("lead strength 0.5: half as far ahead", near(S.aimSkill.X, hroot.Position.X + 90 * th, 0.05))
CFG.PvpLeadScale = 1

-- the floor: a slope up ahead of him (1 stud up every 5 east)
FLOOR = function(x) return x / 5 end
local sx0 = hroot.Position.X - 40                      -- onto the slope, 40 back: a teleport, his path anew
hroot.Position = v3(sx0, sx0 / 5 + 3, 0)
follow()
for _ = 1, 12 do
    NOW += 1 / 60
    hroot.Position = hroot.Position + v3(90 / 60, 90 / 60 / 5, 0)
    targetTick(NOW)
    follow()
end
local ax = S.aimSkill.X
check("up a slope: his point stays 3 over the floor where he will be", near(S.aimSkill.Y, ax / 5 + 3, 0.05))
-- he jumps (up 10, gravity) toward a ledge 12 high: the floor ahead is looked
-- for from over where he will be - a ray from his own height starts inside
-- the ledge and sees no floor, and the aim went into the rock
FLOOR = function(x) return (x > 10) and 12 or 0 end
do
    local mo = { pos = v3(0, 3, 0), vx = 60, vy = 10, vz = 0, ay = -196.2, sustained = false, floor = 0 }
    local pt = predict(mo, "skill", 60, 300, NOW)
    check("jumping at a ledge: aimed on its top (12 + 3), not inside it", near(pt.Y, 15, 1e-6))
end
FLOOR = function() return 0 end
hroot.Position = v3(hroot.Position.X, 3, 0)
targetTick(NOW)

-- ===== the pick holds on, and a move keeps the one it was cast at =====
local other = makePlayer("other", v3(hroot.Position.X + 40, 3, 0))
OTHERS = { him, other }
follow()
for _ = 1, 3 do runFor(1 / 60, 0, 0) end
check("before: him", S.target.id == him)
MOUSE = { X = MOUSE.X - 230, Y = 300 }               -- slipped 230 px off him, away from the other (the 1.5x area)
targetTick(NOW)
check("slipped past the catch area, inside 1.5x: still him", S.target.id == him)
-- you press Z on him; the move plays (Busy); your mouse lands on the other
attackPressed("Z")
check("Z is a skill press", S.lastKind == "skill" and S.castTarget == him)
me.Character.kids.Busy = inst("BoolValue", { Value = true })
MOUSE = { X = 400 + other.Character.kids.HumanoidRootPart.Position.X * 5, Y = 300 }
NOW += 0.1
targetTick(NOW)
check("the move playing keeps the one it was cast at", S.target.id == him)
me.Character.kids.Busy.Value = false
NOW += 0.1
targetTick(NOW)
check("the move over: the one under your mouse", S.target.id == other)
OTHERS = { him }
follow()
targetTick(NOW)

-- ===== facing: a swing at him as he is, a skill at where he will be =====
hroot.Position = v3(40, 3, 0)                          -- back within the face range (a teleport: path anew)
follow()
for _ = 1, 20 do runFor(1 / 60, 90, 0) follow() end
check("he is within the face range", S.target.dist <= 100)
TOOL = inst("Tool", { Name = "Katana", ToolTip = "Sword" })
attackPressed("M1")
check("a sword M1 is a swing", S.lastKind == "melee")
faceNow()
local myRoot = me.Character.kids.HumanoidRootPart
check("a swing faces him as he is", myRoot.CFrame and myRoot.CFrame.LookAt.X == hroot.Position.X)
TOOL = inst("Tool", { Name = "Kitsune-Kitsune", ToolTip = "Blox Fruit" })
attackPressed("M1")
check("a fruit's M1 (the fox's too) is a skill", S.lastKind == "skill")
faceNow()
check("a skill faces where he will be", near(myRoot.CFrame.LookAt.X, S.aimSkill.X, 1e-6))
TOOL = inst("Tool", { Name = "Musket", ToolTip = "Gun" })
attackPressed("M1")
check("a ray gun's M1: aimed at him as he is", S.lastKind == "hitscan")
TOOL = nil

-- ===== your aim sent again while the move plays =====
local function fruit(name, mpClass)
    local t = inst("Tool", { Name = name, ToolTip = "Blox Fruit" })
    t.kids[mpClass == "CFrameValue" and "Mouse" or "MousePos"] = inst(mpClass or "Vector3Value", {})
    t.kids.Holding = inst("BoolValue", { Value = true })
    t.kids.RemoteEvent = remote("RemoteEvent")
    return t
end
TOOL = fruit("Flame-Flame")
TOOL.kids.LegacyRemoteEvent = remote("LegacyRemoteEvent")
attackPressed("X")
table.clear(SENT)
NOW += 0.06
streamTick(NOW)
check("a Vector3 aim goes to the legacy remote, as the game's own sendMouse",
    #SENT == 1 and SENT[1][1] == "LegacyRemoteEvent" and SENT[1][2] == S.aimSkill)
streamTick(NOW + 0.01)
check("not more than 20 a second", #SENT == 1)
TOOL.kids.LegacyRemoteEvent = nil
NOW += 0.06
streamTick(NOW)
check("no legacy remote: the tool's RemoteEvent", #SENT == 2 and SENT[2][1] == "RemoteEvent")
TOOL = fruit("Dough-Dough", "CFrameValue")
attackPressed("C")
NOW += 0.06
streamTick(NOW)
check("a CFrame aim: a CFrame at the point, to RemoteEvent",
    #SENT == 3 and SENT[3][1] == "RemoteEvent" and SENT[3][2].kind == "CFrame" and SENT[3][2].Position == S.aimSkill)
TOOL.kids.Holding.Value = false
me.Character.kids.Busy.Value = false
NOW += 0.06
streamTick(NOW)
check("the move over (not holding, not busy): nothing sent", #SENT == 3)
TOOL = fruit("Love-Love")
attackPressed("Z")
NOW += 0.06
streamTick(NOW)
check("Love: never (the game never sends its aim)", #SENT == 3)
TOOL = fruit("Flame-Flame")
attackPressed("Z")
NOW += 3.5
streamTick(NOW)
check("3 s after the press: no more", #SENT == 3)
TOOL = fruit("Flame-Flame")
TOOL.ToolTip = "Sword"
attackPressed("M1")
NOW += 0.06
streamTick(NOW)
check("a swing is never streamed", #SENT == 3)
attackPressed("Z")
CFG.PvpStream = false
NOW += 0.06
streamTick(NOW)
check("Keep aiming off: nothing", #SENT == 3)
CFG.PvpStream = true
TOOL = nil

-- ===== the game's own gun snap =====
snapOff()
check("snap off: the game's head snap answers nobody while you aim at him", AA.getTargetInfo() == nil)
S.target = nil
check("...nobody picked: the game's own answer", AA.getTargetInfo() == "the game's head snap")
snapOn()
check("snap back: the game's own function itself", AA.getTargetInfo() == "the game's head snap"
    and S.snap.orig == nil)

-- ===== a ray gun's spread (2026-10-13: Dragonstorm's M1 should land) =====
do
    local DS = { ShootType = "HitscanSingleShot", BulletSpreadDegree = 3, SkipSpreadInterval = 4 }
    local storm = inst("Tool", { Name = "Dragonstorm", ToolTip = "Gun", data = DS })
    spreadOff(storm, NOW)
    check("Dragonstorm aimed at him: its spread off in the game's own table", DS.BulletSpreadDegree == nil and S.spread.d == DS)
    spreadOff(storm, NOW + 1)
    check("again: kept off, its clock moved on", DS.BulletSpreadDegree == nil and S.spread.at == NOW + 1)
    local MUSKET = { ShootType = "HitscanSingleShot", BulletSpreadDegree = 2 }
    spreadOff(inst("Tool", { Name = "Musket", ToolTip = "Gun", data = MUSKET }), NOW + 2)
    check("another ray gun: the first one's spread back, the new one's off",
        DS.BulletSpreadDegree == 3 and MUSKET.BulletSpreadDegree == nil)
    spreadOn()
    check("put back: its own number", MUSKET.BulletSpreadDegree == 2 and S.spread.d == nil)
    local SHOT = { ShootType = "HitscanShotgun", BulletSpreadDegree = 12, BulletSpreadCount = 7 }
    spreadOff(inst("Tool", { Name = "Magma Blaster", ToolTip = "Gun", data = SHOT }), NOW)
    check("a shotgun's pellets: never touched", SHOT.BulletSpreadDegree == 12 and S.spread.d == nil)
    spreadOff(inst("Tool", { Name = "Flintlock", ToolTip = "Gun", data = { ShootType = "HitscanSingleShot" } }), NOW)
    check("a gun with no spread: nothing to do", S.spread.d == nil)
    spreadOff(inst("Tool", { Name = "Katana", ToolTip = "Sword" }), NOW)
    check("not a gun: nothing", S.spread.d == nil)
end

-- ===== your shots at him against his HP =====
do
    follow()
    targetTick(NOW)
    local gunT = inst("Tool", { Name = "Dragonstorm", ToolTip = "Gun" })
    gunT.attrs.LocalTotalShots = 10
    local hhum = him.Character:FindFirstChildOfClass("Humanoid")
    hhum.Health = 100
    S.shots.n, S.shots.drops, S.shots.last, S.shots.tool = 0, 0, nil, nil
    shotsTick(gunT, NOW)
    gunT.attrs.LocalTotalShots = 13
    NOW += 0.05
    hhum.Health = 95
    shotsTick(gunT, NOW)
    check("3 shots at him counted", S.shots.n == 3)
    check("his HP down right after a shot: counted", S.shots.drops == 1)
    NOW += 1
    hhum.Health = 90
    shotsTick(gunT, NOW)
    check("his HP down a second after your last shot: not yours", S.shots.drops == 1)
    local musket = inst("Tool", { Name = "Musket", ToolTip = "Gun" })
    musket.attrs.LocalTotalShots = 500
    shotsTick(musket, NOW)
    check("another gun's own count is not shots at him", S.shots.n == 3)
    check("the lead line says it", string.find(S.leadText(), "3 shots at him", 1, true) ~= nil)
end

-- ===== his Ken said =====
follow()
targetTick(NOW)
him.attrs.KenActive, him.attrs.KenDodgesLeft = true, 3
check("his Ken on: said on the PLAYER line", string.find(S.targetText(), "HIS KEN ON (3 dodges left)", 1, true) ~= nil)
him.attrs.KenActive = false
check("his Ken off: not said", string.find(S.targetText(), "KEN", 1, true) == nil)
check("the lead line has your ping", string.find(S.leadText(), "ping 120 ms", 1, true) ~= nil)

-- ===== per attack: Z yours, the rest aimed (2026-10-14) =====
do
    follow()
    targetTick(NOW)
    CFG.PvpAimKeys = { M1 = true, Z = false, X = true, C = true, V = true, F = true }
    me.Character.kids.Busy.Value = false
    S.lastKey = nil
    check("nothing pressed: the skill table answers him", S.aimPoint("skill") ~= nil)
    DOWN[Enum.KeyCode.Z] = true
    check("Z down (the press frame, before this script hears it): your own mouse", S.aimPoint("skill") == nil)
    S.faceUntil = 0
    attackPressed("Z")
    check("a Z press is not turned to him", S.faceUntil == 0)
    DOWN[Enum.KeyCode.Z] = nil
    me.Character.kids.Busy.Value = true
    check("Z let go while its move plays (the release read): still yours", S.aimPoint("skill") == nil)
    TOOL = fruit("Flame-Flame")
    table.clear(SENT)
    NOW += 0.06
    streamTick(NOW)
    check("Z's move: its aim never re-sent", #SENT == 0)
    faceNow()
    me.Character.kids.Busy.Value = false
    check("Busy off but the key's Holding still on: still Z's move, still yours", S.aimPoint("skill") == nil)
    TOOL.kids.Holding.Value = false
    check("Z's move over: aimed again", S.aimPoint("skill") ~= nil)
    DOWN[Enum.KeyCode.X] = true
    attackPressed("X")
    check("X: aimed and turned to him", S.aimPoint("skill") ~= nil and S.faceUntil > NOW)
    DOWN[Enum.KeyCode.X] = nil
    CFG.PvpAimKeys.M1 = false
    DOWN.M1 = true
    check("M1 switched off and held: the gun shot is yours too", S.aimPoint("gun") == nil)
    DOWN.M1 = nil
    CFG.PvpAimKeys = nil
    check("no list at all: everything aimed", S.aimPoint("skill") ~= nil)
    check("the line says which are yours", string.find(S.keysText(), "aimed M1 Z X C V F", 1, true) ~= nil)
    CFG.PvpAimKeys = { Z = false }
    check("...and Z yours", string.find(S.keysText(), "yours Z", 1, true) ~= nil)
    CFG.PvpAimKeys = nil
    TOOL = nil
end

-- ===== a teleport (Soru): his old path forgotten, no wild lead =====
for _ = 1, 20 do runFor(1 / 60, 90, 0) follow() end
NOW += 1 / 60
hroot.Position = hroot.Position + v3(-120, 0, 0)       -- Soru back 120 studs
follow()
targetTick(NOW)
check("right after a teleport: aimed where he is now, not at a wild lead",
    (S.aimSkill - hroot.Position).Magnitude < 1e-6)

print(string.format("%d checks, %d failed", count, fails))
if fails == 0 then print("ALL PASS (aim)") end
