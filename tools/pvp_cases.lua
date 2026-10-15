
-- ===== who can be hit =====
check("dead is not hit", L.attackable(false, false, "Pirates", "Pirates") == false)
check("his PvP off is not hit", L.attackable(true, true, "Pirates", "Pirates") == false)
check("two Marines cannot hurt each other", L.attackable(true, false, "Marines", "Marines") == false)
check("pirate vs pirate is a fight", L.attackable(true, false, "Pirates", "Pirates") == true)
check("marine vs pirate is a fight", L.attackable(true, false, "Marines", "Pirates") == true)
check("no teams known = can be hit", L.attackable(true, false, nil, nil) == true)

-- ===== who is picked (2026-10-12, build .8: the one nearest your MOUSE) =====
-- cands: dist = studs from you, sx / sy = his place on the screen, front = before the camera.
local function P_(id, dist, sx, sy, ok, front)
    return { id = id, dist = dist, sx = sx, sy = sy, ok = ok ~= false, front = front ~= false }
end
local near1 = P_("near-you", 10, 900, 500)          -- next to you, far from the cursor
local onMouse = P_("on-mouse", 120, 410, 300)       -- far from you, right by the cursor
check("cursor beats distance: the one by the mouse, not the one next to you",
    L.cursorPick({ near1, onMouse }, 400, 300, 200, 300) == onMouse)
check("the cursor need not be ON him: 150 px off, inside 200 = his",
    L.cursorPick({ P_("A", 50, 550, 300) }, 400, 300, 200, 300) ~= nil)
check("outside the catch area = nobody (your plain aim)",
    L.cursorPick({ P_("A", 50, 650, 300) }, 400, 300, 200, 300) == nil)
local a1, a2 = P_("A", 200, 430, 300), P_("B", 20, 470, 300)
check("two near the cursor: the one nearer the CURSOR (not the one nearer you)",
    L.cursorPick({ a2, a1 }, 400, 300, 200, 300) == a1)
check("behind the camera: never, even at the cursor's pixel",
    L.cursorPick({ P_("A", 30, 400, 300, true, false) }, 400, 300, 200, 300) == nil)
check("dead / PvP off / your side: never",
    L.cursorPick({ P_("A", 30, 400, 300, false) }, 400, 300, 200, 300) == nil)
check("past 'players count within': never",
    L.cursorPick({ P_("A", 301, 400, 300) }, 400, 300, 200, 300) == nil)
check("at the range edge: still",
    L.cursorPick({ P_("A", 300, 400, 300) }, 400, 300, 200, 300) ~= nil)
check("no screen place known: never", L.cursorPick({ { id = "A", dist = 10, ok = true, front = true } }, 400, 300, 200, 300) == nil)
check("a bigger catch area reaches him", L.cursorPick({ P_("A", 50, 650, 300) }, 400, 300, 300, 300) ~= nil)
check("empty server -> nobody", L.cursorPick({}, 400, 300, 200, 300) == nil)
check("straight above / below the cursor counts too: 250 px down = outside",
    L.cursorPick({ P_("A", 50, 400, 550) }, 400, 300, 200, 300) == nil)
local up, side = P_("A", 50, 400, 450), P_("B", 50, 480, 300)
check("screen distance both ways: 80 px across beats 150 px down",
    L.cursorPick({ up, side }, 400, 300, 200, 300) == side)

-- ===== the face window (2026-10-12: every attack, any weapon) =====
check("an attack key held, he in range: faced 0.4 s on", near(L.faceUntil(0, 10, true, false, 9, 50, 100, true), 10.4))
check("the move still playing (busy) right after an attack: kept facing", near(L.faceUntil(0, 10, false, true, 8, 50, 100, true), 10.4))
check("busy long after any attack (a dash, a stun): not turned", L.faceUntil(0, 10, false, true, 5, 50, 100, true) == 0)
check("nothing held, not busy: the window just runs out", L.faceUntil(10.2, 10, false, false, 9, 50, 100, true) == 10.2)
check("he is out of the face range: not turned", L.faceUntil(0, 10, true, true, 9, 120, 100, true) == 0)
check("facing switched off / nobody aimed: not turned", L.faceUntil(0, 10, true, true, 9, 50, 100, false) == 0
    and L.faceUntil(0, 10, true, true, 9, nil, 100, true) == 0)
check("a window already longer is never shortened", L.faceUntil(11, 10, true, false, 9, 50, 100, true) == 11)

-- ===== per attack (2026-10-14: "I don't want aim assist on the Z move") =====
do
    local on = { M1 = true, Z = false, X = true }
    check("Z held (the press frame, heard or not): your own mouse", L.aimFor(on, { Z = true }, nil, false) == false)
    check("X held: aimed", L.aimFor(on, { X = true }, "Z", false) == true)
    check("Z let go, its move still playing (the release read): still yours", L.aimFor(on, {}, "Z", true) == false)
    check("Z's move over: aimed again", L.aimFor(on, {}, "Z", false) == true)
    check("a key not listed = on", L.aimFor(on, { C = true }, "C", true) == true)
    check("nothing pressed yet: aimed", L.aimFor(on, {}, nil, false) == true)
    check("M1 switched off and held: yours", L.aimFor({ M1 = false }, { M1 = true }, nil, false) == false)
    -- per weapon: the last attack's own weapon decides its release read
    check("a sword Z (off) still playing after a swap to the fruit (on): yours",
        L.aimFor({ Z = true }, {}, "Z", true, { Z = false }) == false)
    check("the fruit's Z pressed (on) while nothing plays: aimed", L.aimFor({ Z = true }, { Z = true }, "Z", false, { Z = false }) == true)
    local keys = { Sword = { Z = false }, ["Blox Fruit"] = { Z = true } }
    check("each weapon its own switches", L.aimOn(keys, "Sword").Z == false and L.aimOn(keys, "Blox Fruit").Z == true)
    check("a weapon not listed: every attack aimed", next(L.aimOn(keys, "Gun")) == nil)
    check("no weapon / no lists: every attack aimed", next(L.aimOn(keys, "?")) == nil and next(L.aimOn(nil, "Sword")) == nil)
end

-- ===== the pick holds on (2026-10-13: a fast player no longer drops out for a frame) =====
do
    local A = P_("A", 50, 400 + 260, 300)                    -- 260 px off: outside 200, inside 300
    check("the one picked last frame keeps a 1.5x catch area",
        L.cursorPick({ A }, 400, 300, 200, 300, "A") == A)
    check("...a new one does not get it", L.cursorPick({ A }, 400, 300, 200, 300, nil) == nil)
    check("...nor past 1.5x", L.cursorPick({ P_("A", 50, 400 + 310, 300) }, 400, 300, 200, 300, "A") == nil)
    local cur, other = P_("A", 50, 500, 300), P_("B", 50, 315, 300)   -- 100 px vs 85 px
    check("another a little nearer the cursor does not steal him (85 vs 100 px)",
        L.cursorPick({ cur, other }, 400, 300, 200, 300, "A") == cur)
    local close = P_("B", 50, 350, 300)                                -- 50 px: clearly nearer
    check("another clearly nearer (0.8x) takes over", L.cursorPick({ cur, close }, 400, 300, 200, 300, "A") == close)
    check("held-on one dead: the other", L.cursorPick({ P_("A", 50, 500, 300, false), other }, 400, 300, 200, 300, "A") == other)
end

-- ===== where he will be (2026-10-13: "predict the movement of the player") =====
-- his path: 60 looks a second
local function path(fn, t0, t1)
    local h = {}
    local t = t0
    while t <= t1 + 1e-9 do
        local x, y, z = fn(t)
        L.track(h, t, x, y, z)
        t += 1 / 60
    end
    return h
end
do
    local h = path(function(t) return 100 * t, 5, -40 * t end, 0, 1)
    check("only the last 0.5 s kept", h[1][1] >= 1 - 0.5 - 1e-6 and #h <= 32)
    local vx, vy, vz, ay = L.motion(h, 1)
    check("a steady run: his velocity exactly", near(vx, 100, 1e-6) and near(vy, 0, 1e-6) and near(vz, -40, 1e-6))
    check("a steady run: no pull up or down", near(ay, 0, 1e-6))
    check("not a dash past 140 for long: 108 studs/s", L.fastFor(h, 1, 140) == 0)
    check("past 100 for 0.4 s and more = kept up (a flight)", near(L.fastFor(h, 1, 100), 0.4))
end
do
    -- a jump: up at 50, the game's gravity
    local g = 196.2
    local h = path(function(t) return 0, 3 + 50 * t - 0.5 * g * t * t, 0 end, 0, 0.2)
    local _, vy, _, ay = L.motion(h, 0.2)
    check("in a jump the pull is gravity", ay < -0.8 * g and ay > -1.2 * g)
    check("in a jump his speed up is read", vy < 50 and vy > 0)
end
do
    local h = {}
    L.track(h, 0, 0, 0, 0)
    L.track(h, 1 / 60, 1, 0, 0)
    L.track(h, 2 / 60, 80, 0, 0)                               -- 79 studs in a frame: Soru
    check("a teleport forgets his old path", #h == 1 and h[1][2] == 80)
    L.track(h, 2 / 60, 81, 0, 0)
    check("the same frame twice is one look", #h == 1)
    check("one look = no velocity yet", L.motion(h, 2 / 60) == nil)
    -- Flash Step smoothed by your screen: 45 studs over 3 frames (15 a frame)
    local f = path(function(t) return 90 * t, 3, 0 end, 0, 1)
    local t0 = f[#f][1]
    local x0 = f[#f][2]
    for k = 1, 3 do L.track(f, t0 + k / 60, x0 + 15 * k, 3, 0) end
    local vx = L.motion(f, t0 + 3 / 60)
    check("a blink smoothed over 3 frames: his path forgotten, no 900 studs/s read", vx == nil)
    -- a real 300 studs/s dash (5 studs a frame) is not a blink
    local g = path(function(t) return 300 * t, 3, 0 end, 0, 0.3)
    local gx = L.motion(g, g[#g][1])
    check("a 300 studs/s dash is kept as motion", gx ~= nil and near(gx, 300, 1e-6))
end

-- lead time
check("a ray gun: no lead at all", L.leadTime("hitscan", 0.2, 100, 300, 1) == 0)
check("a skill: ping + buffer + travel", near(L.leadTime("skill", 0.1, 60, 300, 1), 0.1 + 0.05 + 0.2))
check("a slow gun (Cannon 170): its own travel", near(L.leadTime("gun", 0.1, 85, 170, 1), 0.65))
check("lead strength scales it", near(L.leadTime("skill", 0.1, 60, 300, 0.5), 0.175))
check("never past 1 s", L.leadTime("gun", 0.2, 400, 170, 2) == 1)
check("ping unknown: 150 ms", near(L.leadTime("skill", nil, 0, 300, 1), 0.2))

-- flat: run kept, dash dies out, flight kept
do
    local dx, dz = L.aheadXZ(100, 0, 0.3, 140, false, 0.15)
    check("a run is kept up: 100 x 0.3 = 30", near(dx, 30) and near(dz, 0))
    local dx2 = L.aheadXZ(300, 0, 0.3, 140, false, 0.15)
    check("a dash dies out: less than a straight 90", dx2 < 90 and dx2 > 42)
    check("...but more than the run alone", dx2 > 140 * 0.3)
    local dx3 = L.aheadXZ(300, 0, 0.3, 140, true, 0.15)
    check("a fast flight that has lasted: straight", near(dx3, 90))
    local ax, az = L.aheadXZ(1, 1, 0.3, 140, false, 0.15)
    check("standing (under 2 studs/s): no lead", ax == 0 and az == 0)
    local fx = L.aheadXZ(2000, 0, 1, 140, true, 0.15)
    check("never more than 150 studs", near(fx, 150))
    local bx = L.aheadXZ(1200, 0, 0.35, 140, false, 0.15)
    check("a blink in progress (1200 studs/s, not lasted): at most 15 studs on", near(bx, 15))
    local by = L.aheadXZ(390, 0, 0.35, 140, false, 0.15)
    check("a hard dash under 400: the dash rule, not the blink cap", by > 15 and by < 390 * 0.35)
    local gx, gz = L.aheadXZ(60, 80, 0.5, 140, false, 0.15)
    check("the lead keeps his direction", near(gx, 30) and near(gz, 40))
end

-- height: floor kept, a jump falls, a flight stays
do
    local g = 196.2
    check("on the ground: his height over the floor where he will be (a slope up)",
        near(L.aheadY(13, 0, 0, 0.3, g, 3, 20), 23))
    check("on the ground, no floor seen there: his height now", near(L.aheadY(13, 0, 0, 0.3, g, 3, nil), 13))
    local yJ = L.aheadY(20, 50, 300, 0.3, g, 8, 10)            -- just jumped (pull measured up)
    check("just jumped: gravity takes him (not 50 x 0.3 up)", near(yJ, 20 + 15 - 0.5 * g * 0.09))
    local yF = L.aheadY(50, -10, 0, 0.3, g, 40, 10)
    check("flying (no pull): straight on", near(yF, 47))
    local yD = L.aheadY(12, -60, -g, 0.5, g, 9, 0)
    check("falling: never under the floor (+3)", near(yD, 3))
    check("no time ahead: where he is", L.aheadY(12, -60, -g, 0, g, 9, 0) == 12)
end

-- THE WHOLE CHAIN against a network: he runs, his place reaches your screen
-- late (his upload + the server + your download + the buffer), your aim
-- reaches the server after your upload, the move flies dist / speed. The
-- point aimed at must be where the SERVER has him when the hit lands.
do
    local up, down, buf = 0.06, 0.06, 0.05                    -- ping 120 ms there and back
    local speed = 300
    -- the server's own place for him at server time s: a run, then a turn
    local function server(s) return 40 + 90 * s, 3, 10 + 30 * s end
    -- what you see at your time t: the server's, (down + buf) late
    local function seen(t) return server(t - down - buf) end
    local h = path(seen, 0, 2)
    local now = 2
    local sx, sy, sz = seen(now)
    local vx, vy, vz, ay = L.motion(h, now)
    local dist = 60
    local t = L.leadTime("skill", up + down, dist, speed, 1)
    local dx, dz = L.aheadXZ(vx, vz, t, 140, false, 0.15)
    local ax, az = sx + dx, sz + dz
    -- the hit lands at server time now + up + dist / speed
    local hx, _, hz = server(now + up + dist / speed)
    check("steady run, ping 120: aimed within 0.5 stud of where the server has him",
        math.sqrt((ax - hx) ^ 2 + (az - hz) ^ 2) < 0.5)
    -- without the lead the old aim misses by his whole travel
    check("the old aim (where you see him) misses by ~33 studs here",
        math.sqrt((sx - hx) ^ 2 + (sz - hz) ^ 2) > 30)
end
do
    -- a strafe: he turns round 0.15 s before the hit lands; the miss stays
    -- under the turn's own doubling, never the whole lead past him
    local up, down, buf = 0.08, 0.08, 0.05
    local turnAt = 2 + 0.08 + 0.2 - 0.15
    local function server(s)
        if s <= turnAt then return 100 * s, 3, 0 end
        return 100 * turnAt - 100 * (s - turnAt), 3, 0
    end
    local function seen(t) return server(t - down - buf) end
    local h = path(seen, 0, 2)
    local sx = seen(2)
    local vx, _, vz = L.motion(h, 2)
    local t = L.leadTime("skill", up + down, 60, 300, 1)
    local dx = L.aheadXZ(vx, vz, t, 140, false, 0.15)
    local hx = server(2 + up + 60 / 300)
    check("a turn he makes after you fire: a miss of 2 x 100 x 0.15 at most",
        math.abs((sx + dx) - hx) <= 30.5)
end

-- ===== speed =====
-- The game's own number outside a transformation: 36 x (race + bonuses + attr - 1).
local function game(race, bonus, attr) return 36 * (race + bonus + (attr or 1) - 1) end
local DRACO = 1.325
do
    local s = {}
    local ws = game(DRACO, 0, nil)                         -- 47.7, no speed gear
    local w = L.speed(s, nil, ws, 112.5, true, false)
    check("no gear: attribute set so the game says 112.5", near(game(DRACO, 0, w), 112.5))
    check("no gear: written value remembered", s.mine == w)
    -- next tick: the game has used it
    local w2 = L.speed(s, w, game(DRACO, 0, w), 112.5, true, false)
    check("stable once there (nothing written)", w2 == nil)
    -- the game busy / swimming: no reading, no write, nothing forgotten
    check("not a clean reading -> nothing", L.speed(s, w, 20, 112.5, false, false) == nil and s.mine == w)
    -- Agility comes on (+2): the game alone is past the goal -> back to the base
    local w3 = L.speed(s, w, game(DRACO, 2, w), 112.5, true, false)
    check("already faster on its own -> the base back", near(w3, 1))
    check("game alone after that", near(game(DRACO, 2, w3), 36 * 3.325))
    -- Agility ends
    local w4 = L.speed(s, w3, game(DRACO, 0, w3), 112.5, true, false)
    check("Agility over -> boosted again", near(game(DRACO, 0, w4), 112.5))
end
do
    local s = {}
    -- Pilot Helmet (1.3) from the server
    local w = L.speed(s, 1.3, game(DRACO, 0, 1.3), 112.5, true, false)
    check("helmet: the server's 1.3 is the base", s.base == 1.3)
    check("helmet: the goal reached", near(game(DRACO, 0, w), 112.5))
    -- a transformation: the base back, whatever it is
    local w2 = L.speed(s, w, 999, 112.5, true, true)
    check("transformed -> the server's own value back", w2 == 1.3)
    check("transformed, already base -> nothing", L.speed(s, 1.3, 999, 112.5, true, true) == nil)
    -- new gear while boosted: the server writes 1.5 over ours
    L.speed(s, 1.5, game(DRACO, 0, 1.5), 112.5, true, false)
    check("new gear seen as the new base", s.base == 1.5)
end
do
    local s = {}
    check("already at the goal -> nothing", L.speed(s, nil, 120, 112.5, true, false) == nil)
    local w = L.speed({}, nil, 36, 9999, true, false)
    check("capped at base + 8", near(w, 9))
end
do
    -- Mink V3 + 3 tails + Pilot Helmet, the user's own goal number
    check("goal number = Mink evolved + tail3 + helmet", near(36 * (1.95 + 0.875 + 0.3), 112.5))
    -- convergence: ten ticks of the game and this, never oscillating
    local s, attr = {}, nil
    local writes = 0
    for _ = 1, 10 do
        local w = L.speed(s, attr, game(1, 0, attr), 112.5, true, false)
        if w then attr, writes = w, writes + 1 end
    end
    check("human: one write, then steady", writes == 1 and near(game(1, 0, attr), 112.5))
end

-- ===== dash =====
do
    local d = {}
    L.dashSeen(d, nil)
    check("nothing measured -> your own dash untouched", L.dashWant(d, 1.5) == nil)
    L.dashLearn(d, nil, 40)
    check("first ground dash = your base", d.d0 == 40)
    local w = L.dashWant(d, 1.5)
    check("x1.5 with no slope yet = +20 (1 stud a unit)", near(w, 20))
    d.mine = w
    L.dashSeen(d, w)
    check("our own value is not taken for the server's", d.base == nil and d.d0 == 40)
    L.dashLearn(d, w, 80)                                    -- it went 80, not 60
    check("slope measured: 2 studs a unit", near(d.k, 2))
    check("x1.5 corrected to +10", near(L.dashWant(d, 1.5), 10))
    check("x2 = +20 at 2 studs a unit", near(L.dashWant(d, 2), 20))
    check("x1 = your own", L.dashWant(d, 1) == nil)
    -- a new life, the server's value the same (none): what was measured stays
    d.mine = 10
    L.dashSeen(d, nil)
    check("new life, same gear: measurement kept", d.d0 == 40 and near(d.k, 2))
    -- other gear: DashLength 10 from the server
    d.mine = 10
    L.dashSeen(d, 7)
    check("other gear: measured again", d.d0 == nil and d.k == nil and d.base == 7)
    check("other gear, unmeasured: the server's value", L.dashWant(d, 1.5) == 7)
    L.dashLearn(d, 7, 50)
    check("measured on top of the gear", d.d0 == 50)
    check("x1.5 on top of the gear: 7 + 25", near(L.dashWant(d, 1.5), 32))
    L.dashLearn(d, 7, 2)
    check("a twitch is not a dash", d.d0 == 50)
    L.dashLearn(d, 7, 900)
    check("a teleport is not a dash", d.d0 == 50)
end

-- ===== Flash Step's cut (2026-10-15) =====
check("no cut: the server's own value", L.soruAttr(0.2, 0) == 0.2 and L.soruAttr(nil, 0) == 0)
check("50 % with no gear: 0.5", near(L.soruAttr(nil, 50), 0.5))
check("50 % over gear's 0.2: half of what is left", near(L.soruAttr(0.2, 50), 0.6))
check("never past 95 %", near(L.soruAttr(0, 100), 0.95))

-- ===== Ken back =====
do
    local k = {}
    check("Ken on -> nothing", L.kenStep(k, 0, true, false, true) == false and k.offAt == nil)
    check("goes off -> waits", L.kenStep(k, 10, false, false, true) == false and k.offAt == 10)
    check("1 s later -> still waiting", L.kenStep(k, 11, false, false, true) == false)
    check("2 s later -> asks", L.kenStep(k, 12, false, false, true) == true)
    check("0.2 s after asking -> no", L.kenStep(k, 12.2, false, false, true) == false)
    check("0.5 s after asking -> asks again", L.kenStep(k, 12.5, false, false, true) == true)
    check("cooldown on you -> does not ask", L.kenStep(k, 13.0, false, true, true) == false)
    check("cooldown -> looks again 0.5 s later", L.kenStep(k, 13.2, false, true, true) == false)
    check("cooldown over -> asks at once", L.kenStep(k, 13.5, false, false, true) == true)
    check("Ken back -> counter reset", L.kenStep(k, 14, true, false, true) == false and k.tries == 0)
    local k2 = {}
    L.kenStep(k2, 0, false, false, false)
    check("no Observation on this character -> never asks", L.kenStep(k2, 5, false, false, false) == false)
    local k3 = {}
    L.kenStep(k3, 0, false, false, true)
    local t, asked = 2, 0
    for _ = 1, 21 do
        if L.kenStep(k3, t, false, false, true) then asked += 1 end
        t += 0.5
    end
    check("21 asks in a row", asked == 21)
    check("after 20 refusals: every 3 s, not 0.5", near(k3.nextAt - (t - 0.5), 3))
end

-- ===== blinding =====
check("Ghoul V4 red/grey -> blinding",
    L.blinding("ColorCorrectionEffect", "ColorCorrection", -1, -0.125, 1, nil) == true)
check("Angel V4 grey -> blinding", L.blinding("ColorCorrectionEffect", "ColorCorrection", -2, 0, 0, nil) == true)
check("Ken's cyan tint alone -> clean", L.blinding("ColorCorrectionEffect", "ColorCorrection", 0, 0, 0, nil) == false)
check("the game's own Blur -> left", L.blinding("BlurEffect", "Blur", nil, nil, nil, 7.5) == false)
check("someone else's heavy blur -> blinding", L.blinding("BlurEffect", "BlurEffect", nil, nil, nil, 12) == true)
check("a light blur -> left", L.blinding("BlurEffect", "X", nil, nil, nil, 2) == false)
check("bloom -> left", L.blinding("BloomEffect", "Bloom", nil, nil, nil, nil) == false)

print(string.format("%d checks, %d failed", count, fails))
if fails == 0 then print("ALL PASS (logic)") end
