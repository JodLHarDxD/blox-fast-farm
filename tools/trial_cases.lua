
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, ok, got)
    if not ok then all = false end
    realPrint((ok and "ok    " or "FAIL  ") .. name .. ((not ok and got) and ("   got: " .. tostring(got)) or ""))
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
local function at(v, x, y, z) return near(v.X, x, 1e-4) and near(v.Y, y, 1e-4) and near(v.Z, z, 1e-4) end
local function show(v) return v and string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z) or "nil" end

-- Which relic: the colors the trial's client paints (Trial.lua), read back as
-- Color3 * 255 floats.
check("green metal = relic 1", relicByColor(132, 203, 0) == 1)
check("red metal = relic 2", relicByColor(232, 106, 110) == 2)
check("yellow metal = relic 3", relicByColor(191, 153, 0) == 3)
check("float read-back (x/255*255 drift) still matches", relicByColor(132.0000001, 202.9999, 0.0001) == 1)
check("the relic's GEM color is not its metal", relicByColor(108, 119, 41) == nil)
check("the yellow particles are not the metal", relicByColor(255, 255, 0) == nil)
check("plain grey = no relic", relicByColor(163, 162, 165) == nil)

-- Next: what it flies to.
local function step(d, c) local k, i = nextStep(d, c) return tostring(k) .. ":" .. tostring(i) end
check("nothing in, hands empty: relic 1", step({ false, false, false }, nil) == "relic:1", step({ false, false, false }, nil))
check("carrying 2: extractor 2 (whatever is in)", step({ false, false, false }, 2) == "extractor:2")
check("1 in, hands empty: relic 2", step({ true, false, false }, nil) == "relic:2")
check("2 in first (out of order), hands empty: relic 1", step({ false, true, false }, nil) == "relic:1")
check("carrying one already in (the delivery's own frame): the next relic",
    step({ true, false, false }, 1) == "relic:2", step({ true, false, false }, 1))
check("all three in: the way out", step({ true, true, true }, nil) == "out:nil", step({ true, true, true }, nil))

-- The lava guard.
check("no lava: no floor", guardY(nil, 0, 10, 0.3) == nil)
check("still lava: its top + the margin", near(guardY(9400, 0, 10, 0.3), 9410))
check("rising 200/s: 0.3 s of it more room", near(guardY(9400, 200, 10, 0.3), 9470), guardY(9400, 200, 10, 0.3))
check("draining: no extra room, no less either", near(guardY(9400, -150, 10, 0.3), 9410))
check("rise nil (first frame): just the margin", near(guardY(9400, nil, 10, 0.3), 9410))

-- Next's route.
local bottom = Vector3.new(-40511, 9376, 23458)
local top = Vector3.new(-39935, 10685, 22999)
local up = route(bottom, top)
check("going up: two legs", #up == 2)
check("going up: straight up first (same X/Z, the goal's height)", at(up[1], -40511, 10685, 23458), show(up[1]))
check("going up: then across to the goal", at(up[2], -39935, 10685, 22999), show(up[2]))
local down = route(top, bottom)
check("going down: across first, at your height", at(down[1], -40511, 10685, 23458), show(down[1]))
check("going down: then straight down", at(down[2], -40511, 9376, 23458), show(down[2]))
local level = route(Vector3.new(0, 50, 0), Vector3.new(100, 50, 0))
check("level: the first leg is where you are, then the goal", at(level[1], 0, 50, 0) and at(level[2], 100, 50, 0))

-- One frame of travel.
local p, arrived = stepToward(Vector3.new(0, 0, 0), Vector3.new(0, 1000, 0), 250, 1 / 60)
check("250/s at 60 fps: 4.17 studs up", at(p, 0, 250 / 60, 0) and not arrived, show(p))
p, arrived = stepToward(Vector3.new(0, 0, 0), Vector3.new(0, 1000, 0), 250, 2)
check("a 2 s hitch moves only 0.1 s worth", at(p, 0, 25, 0) and not arrived, show(p))
p, arrived = stepToward(Vector3.new(0, 998, 0), Vector3.new(0, 1000, 0), 250, 1 / 60)
check("closer than one step: lands ON the goal, never past it", at(p, 0, 1000, 0) and arrived, show(p))
p, arrived = stepToward(Vector3.new(5, 5, 5), Vector3.new(5, 5, 5), 250, 1 / 60)
check("already there: arrived, no NaN", at(p, 5, 5, 5) and arrived, show(p))

-- The keys.
local look = Vector3.new(0, -0.5, -0.866)      -- the usual camera: behind, looking a bit down
local right = Vector3.new(1, 0, 0)
check("no keys: no direction (hang still)", steer(look, right, {}, false) == nil)
check("W and S together cancel", steer(look, right, { W = true, S = true }, false) == nil)
local d = steer(look, right, { W = true }, false)
check("W, flat: straight ahead, no sinking", d and at(d, 0, 0, -1), show(d))
d = steer(look, right, { W = true }, true)
check("W, pitch on: follows the look down", d and d.Y < -0.4, show(d))
d = steer(look, right, { Up = true }, false)
check("Space: straight up", d and at(d, 0, 1, 0), show(d))
d = steer(look, right, { Down = true }, false)
check("Ctrl: straight down", d and at(d, 0, -1, 0), show(d))
d = steer(look, right, { W = true, Up = true }, false)
check("W + Space: diagonal, unit length (not faster)", d and near(d.Magnitude, 1, 1e-6) and near(d.Y, 0.7071, 1e-3), show(d))
d = steer(look, right, { D = true }, false)
check("D: camera's right", d and at(d, 1, 0, 0), show(d))
d = steer(Vector3.new(0, -1, 0), right, { W = true }, false)
check("camera straight down, W flat: nothing (no NaN)", d == nil, show(d))

-- Adopting the game's own moves.
local held = Vector3.new(0, 100, 0)
check("first frame: take the body's position", at(adopt(Vector3.new(1, 2, 3), nil), 1, 2, 3))
check("physics drift (gravity between frames): keep holding", at(adopt(Vector3.new(0, 99.7, 0), held), 0, 100, 0))
check("the lava catch puts you on Center's floor (1,300 down): stay there",
    at(adopt(Vector3.new(0, -1200, 0), held), 0, -1200, 0))
check("the trial's entrance teleport: stay there", at(adopt(Vector3.new(40000, 100, 0), held), 40000, 100, 0))

realPrint(all and "ALL PASS" or "SOME FAILED")
