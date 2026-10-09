
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- The cursor's direction in the camera's own frame, for a pixel on a
-- 1920x1080 screen at a 70 degree field of view (what ViewportPointToRay +
-- VectorToObjectSpace give in the game).
local function pixelDir(px, py)
    local h = math.tan(math.rad(70) / 2)
    local x = (px / 1920 * 2 - 1) * h * (1920 / 1080)
    local y = (1 - py / 1080 * 2) * h
    return v3(x, y, -1).Unit
end

-- The whole solve as the game runs it: aimFrame picks where the camera
-- stands, rayAim turns it. Every pixel of the screen, from several sides.
local pile = v3(100, 50, -30)
local worst, rollWorst, tried, lowest = 0, 0, 0, 90
for _, away in ipairs({ v3(0, 0, 1), v3(1, 0, 0), v3(-0.6, 0, -0.8) }) do
    for gx = 0, 1920, 120 do
        for gy = 0, 1080, 90 do
            local d = pixelDir(gx, gy)
            local c = aimFrame(pile, away, d)
            local got = rot(c, d)
            local want = (pile - c.p).Unit
            local err = math.deg(math.acos(math.clamp(dot(got, want), -1, 1)))
            worst = math.max(worst, err)
            rollWorst = math.max(rollWorst, math.abs(rot(c, v3(1, 0, 0)).Y))
            local dist = (pile - c.p).Magnitude
            lowest = math.min(lowest, math.deg(math.asin((c.p.Y - pile.Y) / dist)))
            if math.abs(dist - 30) > 1e-6 then worst = 999 end
            tried += 1
        end
    end
end
check(string.format("every cursor pixel (%d tried, 3 sides): the line through it hits the pile (worst %.5f deg)",
    tried, worst), worst < 0.01, worst)
check("never any roll: the camera's right stays level", rollWorst < 1e-9, rollWorst)
check(string.format("camera stays above the pile (lowest %.0f deg, highest 55)", lowest), lowest > 20, lowest)

-- The camera must not sit so that you (20 over the pile) block the line.
local you = pile + v3(0, 22, 0)
local c2 = aimFrame(pile, v3(0, 0, 1), pixelDir(960, 540))
local seg = pile - c2.p
local s = math.clamp(dot(you - c2.p, seg) / dot(seg, seg), 0, 1)
local miss = ((c2.p + seg * s) - you).Magnitude
check(string.format("you are not in the way of the line (%.1f studs clear)", miss), miss > 5, miss)

local at = pile + v3(0, 22, 0) + v3(0, 6, 14)
-- The middle of the screen = plain look-at.
local c0 = rayAim(at, pile, v3(0, 0, -1))
check("cursor in the middle: camera looks straight at the pile",
    dot(rot(c0, v3(0, 0, -1)), (pile - at).Unit) > 0.999999)

-- Cursor far in a corner and the pile almost straight below: no exact
-- answer without roll, but it never breaks and stays close.
local steep = v3(0, -1, -0.05).Unit
local c1 = rayAim(v3(0, 100, 0), v3(0, 100, 0) + steep * 50, pixelDir(1900, 20))
local got = rot(c1, pixelDir(1900, 20))
local e1 = math.deg(math.acos(math.clamp(dot(got, steep), -1, 1)))
check(string.format("pile straight below, cursor in the corner: no error thrown, off by %.1f deg", e1),
    e1 == e1 and e1 < 60, e1)

-- A fight's own camera distance (SEA EVENTS: a beast is bigger than 30 studs).
P.camDistance = 90
local c3 = aimFrame(pile, v3(0, 0, 1), pixelDir(960, 540))
local far = (c3.p - pile).Magnitude
local g3 = rot(c3, pixelDir(960, 540))
check(string.format("a sea fight: the camera 90 from the target (%.1f), still aimed through it", far),
    math.abs(far - 90) < 0.01 and dot(g3, (pile - c3.p).Unit) > 0.9999, far)
P.camDistance = nil
check("...the fight over: 30 again", math.abs((aimFrame(pile, v3(0, 0, 1), pixelDir(960, 540)).p - pile).Magnitude - 30) < 0.01)

print(all and "ALL PASS" or "SOME FAILED")
