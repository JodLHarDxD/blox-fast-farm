
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function same(a, b)
    if (a.p - b.p).Magnitude > 1e-6 then return false end
    for i = 1, 3 do for j = 1, 3 do if math.abs(a.m[i][j] - b.m[i][j]) > 1e-9 then return false end end end
    return true
end

-- The game's camera script, worst case: it builds this frame's view FROM the
-- camera's current CFrame (turning it by your mouse drag) -- so a swap left in
-- place when it runs would turn YOUR view.
local userCF = CFrame.lookAt(v3(0, 30, 40), v3(0, 0, 0))
cam.CFrame = userCF
local DRAG = CFrame.Angles(0, math.rad(0.7), 0)        -- you turn the view a little every frame
local function cameraScript() cam.CFrame = cf(cam.CFrame.p, mmul(DRAG.m, cam.CFrame.m)) end
local function expectedUser() userCF = cf(userCF.p, mmul(DRAG.m, userCF.m)) return userCF end

local pile = v3(5, 0, -3)
hiddenAim(true)
local drawnOK, readOK, reads, worstMiss = true, true, 0, 0
local aimOn = false
for frame = 1, 120 do
    -- 1. input: a key sent last Heartbeat is read now, with whatever camera is up
    if aimOn then
        reads += 1
        local ray = cam:ViewportPointToRay(MOUSE.X, MOUSE.Y)
        local toPile = pile - ray.Origin
        local along = dot(toPile, ray.Direction)
        local miss = (toPile - ray.Direction * along).Magnitude
        worstMiss = math.max(worstMiss, miss)
        if miss > 1e-6 or along <= 0 then readOK = false end
    end
    -- 2. render steps in priority order, the camera script at 200
    local steps = { { prio = 200, fn = cameraScript } }
    for _, b in pairs(BOUND) do table.insert(steps, b) end
    table.sort(steps, function(a, b) return a.prio < b.prio end)
    for _, s in ipairs(steps) do s.fn() end
    -- 3. drawn: must be exactly your own view
    if not same(cam.CFrame, expectedUser()) then drawnOK = false end
    -- 4. Heartbeat: frames 20-80 are a cast; the cursor wanders all over
    MOUSE = v2(960 + 900 * math.sin(frame * 0.3), 540 + 500 * math.cos(frame * 0.17))
    aimOn = frame >= 20 and frame <= 80
    if aimOn then aimSwapIn(pile, pile) end
end
check(string.format("every drawn frame is exactly your own view (%d frames, the view turning, cursor moving)", 120), drawnOK)
check(string.format("every key read during the cast sees the aim: the line through your cursor hits the pile (%d reads, worst %.2g studs)", reads, worstMiss), readOK and reads == 61)

-- stop: nothing left bound, your view left in place
cam.CFrame = userCF
aimSwapIn(pile, pile)
hiddenAim(false)
check("stop: the aim is taken out and nothing stays bound", same(cam.CFrame, userCF) and next(BOUND) == nil)

print(all and "ALL PASS" or "SOME FAILED")
