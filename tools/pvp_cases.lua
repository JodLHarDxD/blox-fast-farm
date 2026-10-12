
-- ===== who can be hit =====
check("dead is not hit", L.attackable(false, false, "Pirates", "Pirates") == false)
check("his PvP off is not hit", L.attackable(true, true, "Pirates", "Pirates") == false)
check("two Marines cannot hurt each other", L.attackable(true, false, "Marines", "Marines") == false)
check("pirate vs pirate is a fight", L.attackable(true, false, "Pirates", "Pirates") == true)
check("marine vs pirate is a fight", L.attackable(true, false, "Marines", "Pirates") == true)
check("no teams known = can be hit", L.attackable(true, false, nil, nil) == true)

-- ===== who is picked (2026-10-12: one opponent, locked at your first attack) =====
local A = { id = "A", dist = 50, ok = true }
local B = { id = "B", dist = 120, ok = true }
local Cdead = { id = "C", dist = 10, ok = false }
local function pick(...) local c, l = L.pick(...) return c, l end
local c, locked = pick({ B, A, Cdead }, nil, false, 300, 300)
check("not locked: the nearest that can be hit, not locked yet", c == A and locked == false)
check("the dead one is never picked, however near", pick({ Cdead }, nil, false, 300, 300) == nil)
c, locked = pick({ A, B }, "B", true, 300, 300)
check("LOCKED: kept though another is nearer (beside / behind you)", c == B and locked == true)
check("not locked yet: the nearer one is aimed instead (no lock = no hold)", pick({ A, B }, "B", false, 300, 300) == A)
local Bfar = { id = "B", dist = 320, ok = true }
check("locked: kept a little past the keep range (no flicking)", pick({ A, Bfar }, "B", true, 100, 300) == Bfar)
local Bgone = { id = "B", dist = 340, ok = true }
c, locked = pick({ A, Bgone }, "B", true, 100, 300)
check("locked one gone well past the range -> unlocked, the nearest", c == A and locked == false)
local Bdead = { id = "B", dist = 100, ok = false }
c, locked = pick({ A, Bdead }, "B", true, 100, 300)
check("locked one dead -> unlocked, the nearest", c == A and locked == false)
local B250 = { id = "B", dist = 250, ok = true }
check("locked at 250 studs: kept (the keep range, not the pick range)", pick({ B250 }, "B", true, 100, 300) == B250)
check("not locked: nobody inside the pick range (100) -> nobody", pick({ B250 }, nil, false, 100, 300) == nil)
check("nobody in range -> nobody", pick({ { id = "X", dist = 500, ok = true } }, nil, false, 300, 300) == nil)
check("empty server -> nobody", pick({}, nil, false, 300, 300) == nil)

-- ===== the face window (2026-10-12: every attack, any weapon) =====
check("an attack key held, he in range: faced 0.4 s on", near(L.faceUntil(0, 10, true, false, 9, 50, 100, true), 10.4))
check("the move still playing (busy) right after an attack: kept facing", near(L.faceUntil(0, 10, false, true, 8, 50, 100, true), 10.4))
check("busy long after any attack (a dash, a stun): not turned", L.faceUntil(0, 10, false, true, 5, 50, 100, true) == 0)
check("nothing held, not busy: the window just runs out", L.faceUntil(10.2, 10, false, false, 9, 50, 100, true) == 10.2)
check("he is out of the face range: not turned", L.faceUntil(0, 10, true, true, 9, 120, 100, true) == 0)
check("facing switched off / nobody aimed: not turned", L.faceUntil(0, 10, true, true, 9, 50, 100, false) == 0
    and L.faceUntil(0, 10, true, true, 9, nil, 100, true) == 0)
check("a window already longer is never shortened", L.faceUntil(11, 10, true, false, 9, 50, 100, true) == 11)

-- ===== next player =====
local N1 = { id = 1, dist = 10, ok = true }
local N2 = { id = 2, dist = 20, ok = true }
local N3 = { id = 3, dist = 30, ok = true }
check("next after the nearest", L.nextOf({ N3, N1, N2 }, 1, 300) == N2)
check("next after the last wraps to the nearest", L.nextOf({ N3, N1, N2 }, 3, 300) == N1)
check("next with none picked = the nearest", L.nextOf({ N3, N2 }, nil, 300) == N2)
check("next skips the dead", L.nextOf({ N1, { id = 9, dist = 15, ok = false }, N2 }, 1, 300) == N2)
check("next with nobody = nobody", L.nextOf({}, 1, 300) == nil)
check("next alone = himself", L.nextOf({ N1 }, 1, 300) == N1)

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
