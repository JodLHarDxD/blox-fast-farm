
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

-- ===== lead =====
local p0 = Vector3.new(0, 0, 0)
local vel = Vector3.new(100, 0, 0)
check("lead off = where he is", L.lead(p0, vel, 125, false) == p0)
check("lead on = ahead by dist/250 s", near(L.lead(p0, vel, 125, true).X, 50))
check("lead capped at 0.6 s", near(L.lead(p0, vel, 1000, true).X, 60))
check("lead with no velocity = where he is", L.lead(p0, nil, 125, true) == p0)

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
