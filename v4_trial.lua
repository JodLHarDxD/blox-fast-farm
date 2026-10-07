--[[
    DRACO V4 TRIAL MODE
    ===================
    The Trial of Flames: the Statue in the Prehistoric Island cave. Three relics
    lie at the bottom of the cave, their three extractors are ~1,300 studs up,
    and every eruption the lava climbs to just under the top. Climbing that is
    the hard part. This flies it instead.

      FLY      WASD flies flat where the camera faces, Space straight up, Ctrl
               straight down. No gravity. Let go of the keys and you hang still.
      NOCLIP   walls, doors and platforms are not in the way.
      LAVA     you are never under it: while it climbs you ride on top of it,
               with room for how fast it is coming up.
      NEXT     one button flies you to what is next: empty hands = the next
               relic's pad, a relic in your hands = its extractor, all three in
               = the way out. Up = climb first, then across; down = across
               first, then down -- you stay high as long as possible.
      AUTO     (off until you switch it on) Next over and over until all three
               are in. Hovering over a pad that does nothing for a while = its
               prompt is tried. Touch a fly key and Auto lets go.

    Turning the mode on stops fast_farm / farm_pro: their body lock writes the
    character every frame and would fight the flight.

    How the trial works was READ from the game's own client
    (EffectContainer/DracoRace/Trial, decompiled v4623), not guessed:
      - workspace.Map.DracoTrial holds Relic1-3, EndRelic1-3 (each pad is
        "Meshes/caveprops_Cube.015"), Brazier1-3, Door1-3, Center, EndPlatform,
        TeleportOut.
      - The lava is the client's own part in workspace._WorldOrigin (Neon,
        170,79,0, 2000 x 10 x 2000). It rises to EndPlatform's top - 6 and
        drains to Center - 30. Below its top with no shield = the client puts
        you back on Center's floor and holds you there 10.5 s.
      - The shield: a relic in your hands and still (< 0.3 studs) for 1 s.
        Hovering is still, so a held relic shields you while you wait.
      - A relic is IN when its Brazier gets a child named Relic<n>.
        Colors: 1 green, 2 red, 3 yellow.
    Picking up and delivering are decided by the server (not in the client).
    A public hub just hovers at each spot -- this does the same.

    USE IT ON AN ACCOUNT YOU CAN AFFORD TO LOSE: flight and noclip are what
    anti-cheat and reports look for.

    CONTROL
        _G.BFV4.on()   _G.BFV4.off()   _G.BFV4.next()   _G.BFV4.config
]]

if _G.BFV4 and _G.BFV4.off then pcall(_G.BFV4.off, "reload") end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VIM          = game:GetService("VirtualInputManager")
local player       = Players.LocalPlayer

-- =========================================================
-- CONFIG
-- =========================================================
local CFG = {
    FlySpeed    = 150,    -- studs/s while you steer
    TravelSpeed = 250,    -- studs/s when Next flies you (the hub tweens at ~300)
    FlyPitch    = false,  -- on: W flies where the camera LOOKS, up/down included
    Noclip      = true,
    LavaGuard   = true,
    LavaMargin  = 10,     -- studs kept between your root and the lava's top
    LavaLook    = 0.3,    -- seconds of the lava's climb kept as extra room
    PadHeight   = 3.5,    -- hover the root this far over a pad / extractor
    Auto        = false,  -- a new auto mode starts OFF
    PromptAfter = 3,      -- seconds over a pad with nothing happening = try its prompt
    GiveUpAfter = 12,     -- seconds over a pad with nothing happening = "do it yourself"
    StopFarm    = true,   -- turning the mode on stops fast_farm / farm_pro
    UpKey       = Enum.KeyCode.Space,
    DownKey     = Enum.KeyCode.LeftControl,
}

local V = { config = CFG, running = false, build = "2026-10-07.1" }
_G.BFV4 = V

-- Where a public hub's trial route goes (SkibidiXHub, "Auto Relic Drago
-- Trial"). Used ONLY for a spot this client has never seen (streaming can
-- keep far parts out); which hub point belongs to which relic is its order,
-- not something read.
local HUB = {
    Relic1    = Vector3.new(-40511.25, 9376.40, 23458.38),
    Relic2    = Vector3.new(-40045.83, 9376.40, 22791.29),
    Relic3    = Vector3.new(-39609.50, 9376.40, 23472.94),
    EndRelic1 = Vector3.new(-39934.98, 10685.36, 22999.34),
    EndRelic2 = Vector3.new(-39914.66, 10685.38, 23000.18),
    EndRelic3 = Vector3.new(-39908.50, 10685.41, 22990.04),
}
local COLOR_NAME = { "green", "red", "yellow" }

-- =========================================================
-- PURE: start  (tools/trial_test.py cuts this block out and runs it)
-- =========================================================
-- The metal color the trial's client paints each relic (Trial.lua's table).
local METAL = { { 132, 203, 0 }, { 232, 106, 110 }, { 191, 153, 0 } }

-- Which relic a painted metal is (r, g, b in 0-255), or nil.
local function relicByColor(r, g, b)
    for i, m in ipairs(METAL) do
        if math.abs(r - m[1]) <= 3 and math.abs(g - m[2]) <= 3 and math.abs(b - m[3]) <= 3 then
            return i
        end
    end
    return nil
end

-- What Next does: the relic in your hands goes to its extractor; empty hands
-- go for the lowest-numbered relic not in yet; all three in = the way out.
local function nextStep(delivered, carrying)
    if carrying and not delivered[carrying] then return "extractor", carrying end
    for i = 1, 3 do
        if not delivered[i] then return "relic", i end
    end
    return "out", nil
end

-- The lowest the root may be: over the lava's top by the margin, plus how far
-- the lava climbs in `look` seconds at its present rate (a Sine tween: it is
-- fastest right at the start). nil = no lava.
local function guardY(lavaTop, rise, margin, look)
    if not lavaTop then return nil end
    return lavaTop + margin + math.max(rise or 0, 0) * look
end

-- Next's path. Going up: climb straight up first, then across at the top.
-- Going down: across first at your height, then straight down. Either way you
-- stay as high as you can for as long as you can -- away from the lava.
local function route(from, goal)
    if goal.Y >= from.Y then
        return { Vector3.new(from.X, goal.Y, from.Z), goal }
    end
    return { Vector3.new(goal.X, from.Y, goal.Z), goal }
end

-- One frame of travel toward goal. Never overshoots; a long frame (a hitch)
-- moves at most 0.1 s worth.
local function stepToward(here, goal, speed, dt)
    local d = goal - here
    local m = d.Magnitude
    local step = speed * math.min(dt, 0.1)
    if m <= step then return goal, true end
    return here + d.Unit * step, false
end

-- The direction the keys ask for, or nil. look / right are the camera's.
-- Flat unless pitch: then W/S follow the look up and down too.
local function steer(look, right, keys, pitch)
    local fwd = pitch and look or Vector3.new(look.X, 0, look.Z)
    local side = Vector3.new(right.X, 0, right.Z)
    if fwd.Magnitude > 0.01 then fwd = fwd.Unit end
    if side.Magnitude > 0.01 then side = side.Unit end
    local d = Vector3.new(0, 0, 0)
    if keys.W then d = d + fwd end
    if keys.S then d = d - fwd end
    if keys.D then d = d + side end
    if keys.A then d = d - side end
    if keys.Up then d = d + Vector3.new(0, 1, 0) end
    if keys.Down then d = d - Vector3.new(0, 1, 0) end
    if d.Magnitude < 0.01 then return nil end
    return d.Unit
end

-- Where the flight holds the body this frame. Far from where it was last put
-- = the game moved it (the trial's entrance, its lava catch, a respawn): stay
-- where the game put it rather than drag the body back.
local function adopt(here, held)
    if not held or (here - held).Magnitude > 50 then return here end
    return held
end
-- =========================================================
-- PURE: end
-- =========================================================

-- =========================================================
-- CHARACTER, MESSAGES
-- =========================================================
local function parts()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return char, nil, nil end
    return char, root, hum
end

local lastSaid = "off"
local function say(msg)
    lastSaid = msg
    print("[BFV4] " .. msg)
end

-- =========================================================
-- READING THE TRIAL
-- =========================================================
local function trialFolder()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("DracoTrial")
end

-- Spots, remembered once seen: they never move, and streaming can take a far
-- part away again.
local spots, spotFrom = {}, {}
local function padSpot(name)
    local t = trialFolder()
    local node = t and t:FindFirstChild(name, true)
    if node then
        local cube = node:FindFirstChild("Meshes/caveprops_Cube.015", true)
        local pos
        if cube and cube:IsA("BasePart") then
            pos = (cube.CFrame * CFrame.new(0, cube.Size.Y / 2 + CFG.PadHeight, 0)).Position
        elseif node:IsA("BasePart") then
            pos = node.Position + Vector3.new(0, node.Size.Y / 2 + CFG.PadHeight, 0)
        elseif node:IsA("Model") then
            pos = node:GetPivot().Position + Vector3.new(0, CFG.PadHeight, 0)
        end
        if pos then spots[name], spotFrom[name] = pos, "map" end
    end
    if not spots[name] and HUB[name] then spots[name], spotFrom[name] = HUB[name], "hub" end
    return spots[name], spotFrom[name]
end

local function partSpot(name)
    local t = trialFolder()
    local node = t and t:FindFirstChild(name, true)
    if node and node:IsA("BasePart") then spots[name], spotFrom[name] = node.Position, "map" end
    if node and node:IsA("Model") then spots[name], spotFrom[name] = node:GetPivot().Position, "map" end
    return spots[name], spotFrom[name]
end

local function isDelivered(i)
    local t = trialFolder()
    local b = t and t:FindFirstChild("Brazier" .. i, true)
    return b ~= nil and b:FindFirstChild("Relic" .. i) ~= nil
end

-- The relic in your hands: the client's copy of it (a model with "RelicFire"
-- in _WorldOrigin) unanchored, pulled by an AlignPosition, near you. "Near" is
-- wide: it chases you with Responsiveness 15, so at Next's 250 studs/s it
-- trails ~17 studs behind its 5-stud spot in front of you.
local function carriedRelic(delivered)
    local wo = workspace:FindFirstChild("_WorldOrigin")
    local _, r = parts()
    if not wo or not r then return nil end
    for _, m in ipairs(wo:GetChildren()) do
        local pp = m:IsA("Model") and m:FindFirstChild("RelicFire") and m.PrimaryPart
        if pp and not pp.Anchored and pp:FindFirstChildOfClass("AlignPosition")
            and (pp.Position - r.Position).Magnitude < 80 then
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("MeshPart") then
                    local c = d.Color
                    local i = relicByColor(c.R * 255, c.G * 255, c.B * 255)
                    if i and not delivered[i] then return i end
                end
            end
        end
    end
    return nil
end

-- The lava: the client's own part. Its top and how fast it is climbing.
local lavaPart, lavaLookedAt = nil, 0
local lava = { top = nil, rise = 0 }
local function findLava()
    if lavaPart and lavaPart.Parent then return lavaPart end
    lavaPart = nil
    if os.clock() - lavaLookedAt < 0.5 then return nil end
    lavaLookedAt = os.clock()
    local wo = workspace:FindFirstChild("_WorldOrigin")
    if not wo then return nil end
    for _, c in ipairs(wo:GetChildren()) do
        if c:IsA("BasePart") and c.Size.X >= 1999 and c.Size.Z >= 1999
            and c.Material == Enum.Material.Neon
            and math.abs(c.Color.R * 255 - 170) < 4 and math.abs(c.Color.G * 255 - 79) < 4 then
            lavaPart = c
            return c
        end
    end
    return nil
end

local function readLava(dt)
    local p = findLava()
    if not p then lava.top, lava.rise = nil, 0 return end
    local top = p.Position.Y + p.Size.Y / 2
    if lava.top and dt > 0 then lava.rise = (top - lava.top) / dt else lava.rise = 0 end
    lava.top = top
end

-- What the trial shows right now, read 5 times a second (not every frame).
local trial = { here = false, delivered = { false, false, false }, carrying = nil }
local function readTrial()
    trial.here = trialFolder() ~= nil
    for i = 1, 3 do trial.delivered[i] = trial.here and isDelivered(i) end
    trial.carrying = trial.here and carriedRelic(trial.delivered) or nil
end

-- =========================================================
-- THE BODY: FLIGHT, NOCLIP, THE LAVA GUARD
-- =========================================================
local conns = {}
local held = nil              -- where the flight holds the root
local path = nil              -- Next's waypoints still ahead; nil = arrived / none
local liftedAt = 0            -- the guard last held you up
local savedCollide = {}
local bodyChar, bodyList, bodyListAt = nil, {}, 0
local epoch = 0

local function keysDown()
    if UIS:GetFocusedTextBox() then return {} end
    return {
        W = UIS:IsKeyDown(Enum.KeyCode.W), S = UIS:IsKeyDown(Enum.KeyCode.S),
        A = UIS:IsKeyDown(Enum.KeyCode.A), D = UIS:IsKeyDown(Enum.KeyCode.D),
        Up = UIS:IsKeyDown(CFG.UpKey), Down = UIS:IsKeyDown(CFG.DownKey),
    }
end

local function stepped()
    if not V.running or not CFG.Noclip then return end
    local char = player.Character
    if not char then return end
    if char ~= bodyChar or os.clock() - bodyListAt > 0.5 then
        bodyList = {}
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") then table.insert(bodyList, d) end
        end
        bodyChar, bodyListAt = char, os.clock()
    end
    for _, p in ipairs(bodyList) do
        if p.Parent then
            if savedCollide[p] == nil then savedCollide[p] = p.CanCollide end
            p.CanCollide = false
        end
    end
end

local function restoreCollide()
    for p, was in pairs(savedCollide) do
        if p.Parent then pcall(function() p.CanCollide = was end) end
    end
    table.clear(savedCollide)
end

local function heartbeat(dt)
    if not V.running then return end
    readLava(dt)
    local _, r, h = parts()
    if not r then held = nil return end
    h.AutoRotate = false
    local pos = adopt(r.Position, held)

    local cam = workspace.CurrentCamera
    local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
    local right = cam and cam.CFrame.RightVector or Vector3.new(1, 0, 0)
    local dir = steer(look, right, keysDown(), CFG.FlyPitch)
    if dir then
        if path or CFG.Auto then
            path = nil
            if CFG.Auto then CFG.Auto = false say("you took over - Auto off") else say("you took over") end
        end
        pos = pos + dir * CFG.FlySpeed * math.min(dt, 0.1)
    elseif path then
        local arrived
        pos, arrived = stepToward(pos, path[1], CFG.TravelSpeed, dt)
        if arrived then
            table.remove(path, 1)
            if #path == 0 then path = nil end
        end
    end

    local g = CFG.LavaGuard and guardY(lava.top, lava.rise, CFG.LavaMargin, CFG.LavaLook)
    if g and pos.Y < g then
        pos = Vector3.new(pos.X, g, pos.Z)
        liftedAt = os.clock()
    end

    held = pos
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude > 0.1 then
        r.CFrame = CFrame.lookAt(pos, pos + flat)
    else
        r.CFrame = CFrame.new(pos) * (r.CFrame - r.CFrame.Position)
    end
    r.AssemblyLinearVelocity = Vector3.zero
    r.AssemblyAngularVelocity = Vector3.zero
end

-- =========================================================
-- NEXT AND AUTO
-- =========================================================
local function describe(kind, i)
    if kind == "relic" then return string.format("relic %d (%s)", i, COLOR_NAME[i]) end
    if kind == "extractor" then return string.format("extractor %d (%s)", i, COLOR_NAME[i]) end
    return "the way out"
end

local function goalOf(kind, i)
    if kind == "relic" then return padSpot("Relic" .. i) end
    if kind == "extractor" then return padSpot("EndRelic" .. i) end
    local p, from = partSpot("TeleportOut")
    if not p then p, from = partSpot("EndPlatform") end
    return p, from
end

-- Fly to what is next. Returns the step, or nil when there is nowhere to go.
local function goNext()
    local _, r = parts()
    if not r then say("no character") return nil end
    if not trial.here then say("not in the trial (no Map.DracoTrial here)") return nil end
    local kind, i = nextStep(trial.delivered, trial.carrying)
    local goal, from = goalOf(kind, i)
    if not goal then say("cannot find " .. describe(kind, i) .. " yet") return nil end
    path = route(held or r.Position, goal)
    say("flying to " .. describe(kind, i) .. (from == "hub" and "  (a hub's point - not seen here yet)" or ""))
    return kind, i
end
V.next = goNext

-- A pad that does nothing while you hover over it: its prompt, if it has one.
local function tryPrompt(kind, i)
    local t = trialFolder()
    local node = t and t:FindFirstChild((kind == "relic" and "Relic" or "EndRelic") .. tostring(i), true)
    local prompt = node and node:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end
    say(string.format("%s: trying its prompt (%s)", describe(kind, i), prompt.ActionText))
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    else
        pcall(function()
            VIM:SendKeyEvent(true, prompt.KeyboardKeyCode, false, game)
            task.wait(prompt.HoldDuration + 0.2)
            VIM:SendKeyEvent(false, prompt.KeyboardKeyCode, false, game)
        end)
    end
    return true
end

local function sameStep(kind, i)
    local k2, i2 = nextStep(trial.delivered, trial.carrying)
    return k2 == kind and i2 == i
end

-- One Auto at a time: every switch flip (and on / off) takes a new number, and
-- a loop whose number is not the current one ends.
local autoRun = 0
local function autoLoop(myRun)
    while V.running and CFG.Auto and autoRun == myRun do
        readTrial()
        local kind, i = nextStep(trial.delivered, trial.carrying)
        if kind == "out" then
            CFG.Auto = false
            say("all three are in - the final door is open. Next flies you out.")
            break
        end
        if not goNext() then task.wait(1) continue end
        while path and CFG.Auto and autoRun == myRun do task.wait(0.1) end
        if not CFG.Auto or autoRun ~= myRun then break end
        -- Over the pad. Wait for the trial to move on (picked up / delivered).
        local t0, prompted, toldYou = os.clock(), false, false
        while CFG.Auto and autoRun == myRun and sameStep(kind, i) do
            local waited = os.clock() - t0
            if not prompted and waited > CFG.PromptAfter then prompted = true tryPrompt(kind, i) end
            if not toldYou and waited > CFG.GiveUpAfter then
                toldYou = true
                say(string.format("%s: nothing for %ds - do it yourself (E / touch it); Auto waits",
                    describe(kind, i), CFG.GiveUpAfter))
            end
            task.wait(0.2)
            readTrial()
        end
    end
end

local function setAuto(on)
    CFG.Auto = on
    autoRun += 1
    if on and V.running then task.spawn(autoLoop, autoRun) end
end
V.setAuto = setAuto

-- =========================================================
-- ON / OFF
-- =========================================================
local function track(c) table.insert(conns, c) return c end

function V.on()
    if V.running then return end
    if CFG.StopFarm then
        if _G.BFF and _G.BFF.running and _G.BFF.stop then pcall(_G.BFF.stop) say("fast_farm stopped") end
        if _G.BFP and _G.BFP.stop then pcall(_G.BFP.stop) end
    end
    epoch += 1
    V.running, held, path = true, nil, nil
    track(RunService.Stepped:Connect(function() pcall(stepped) end))
    track(RunService.Heartbeat:Connect(function(dt) pcall(heartbeat, dt) end))
    track(player.CharacterAdded:Connect(function()
        held, path = nil, nil
        table.clear(savedCollide)
    end))
    task.spawn(function()
        local mine = epoch
        while V.running and epoch == mine do
            pcall(readTrial)
            task.wait(0.2)
        end
    end)
    if CFG.Auto then setAuto(true) end
    say(trialFolder() and "on - fly with WASD, Space up, Ctrl down" or "on - not in the trial yet; flight works anywhere")
end

function V.off(why)
    if not V.running and why ~= "reload" then return end
    V.running = false
    epoch += 1
    path, held = nil, nil
    lava.top, lava.rise = nil, 0     -- read only while on; a stale one would show
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    restoreCollide()
    local _, _, h = parts()
    if h then pcall(function() h.AutoRotate = true end) end
    if why == "reload" then
        pcall(function()
            local g = player.PlayerGui:FindFirstChild("BFV4HUD")
            if g then g:Destroy() end
        end)
    end
    say("off")
end

-- =========================================================
-- PANEL
-- =========================================================
local C = {
    base   = Color3.fromRGB(18, 17, 16),
    raised = Color3.fromRGB(30, 29, 27),
    line   = Color3.fromRGB(48, 46, 43),
    ivory  = Color3.fromRGB(232, 224, 212),
    muted  = Color3.fromRGB(150, 143, 134),
    lava   = Color3.fromRGB(255, 120, 40),
}
local quick = TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function new(class, props, kids)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    for _, k in ipairs(kids or {}) do k.Parent = o end
    return o
end

-- Grows downward when the text wraps; h is the least it is.
local function label(text, font, size, color, h)
    return new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h or 18),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = font, TextSize = size, TextColor3 = color, Text = text,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    })
end

local function buildUI()
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("BFV4HUD")
    if old then old:Destroy() end
    local gui = new("ScreenGui", { Name = "BFV4HUD", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 46, Parent = pg })

    local panel = new("Frame", {
        Size = UDim2.new(0, 290, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, -310, 0, 120), BackgroundColor3 = C.base, BorderSizePixel = 0,
        Parent = gui,
    }, {
        new("UICorner", { CornerRadius = UDim.new(0, 12) }),
        new("UIStroke", { Color = C.line, Thickness = 1 }),
        new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14) }),
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    -- Header: the title drags the panel; Hide folds it to the header.
    local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 1, Parent = panel })
    local title = label("V4 TRIAL", Enum.Font.GothamBold, 14, C.ivory, 22)
    title.Parent = header
    local hide = new("TextButton", { Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(1, -44, 0, 0),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.muted,
        Text = "Hide", TextXAlignment = Enum.TextXAlignment.Right, Parent = header })

    local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = panel }, {
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    local order = 0
    local function add(o) order += 1 o.LayoutOrder = order o.Parent = body return o end
    local function gap(h) add(new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h) })) end

    -- The one control that matters without looking.
    gap(4)
    local hero = add(new("TextButton", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.raised,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 15,
        TextColor3 = C.ivory, Text = "" }, { new("UICorner", { CornerRadius = UDim.new(0, 10) }) }))

    gap(6)
    local relicsL = add(label("", Enum.Font.Code, 13, C.ivory))
    local handsL  = add(label("", Enum.Font.Code, 13, C.ivory))
    local lavaL   = add(label("", Enum.Font.Code, 13, C.muted))
    local sayL    = add(label("", Enum.Font.Gotham, 12, C.muted, 30))

    gap(4)
    local nextB = add(new("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.raised,
        BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextColor3 = C.ivory, Text = "Next" }, { new("UICorner", { CornerRadius = UDim.new(0, 8) }) }))

    gap(8)
    local switches = {}
    local function switch(text, key, onSet)
        local row = add(new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false }))
        local l = label(text, Enum.Font.Gotham, 13, C.ivory, 30)
        l.Size = UDim2.new(1, -50, 1, 0)
        l.Parent = row
        local v = new("TextLabel", { Size = UDim2.new(0, 46, 1, 0), Position = UDim2.new(1, -46, 0, 0),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
        local function show()
            v.Text = CFG[key] and "ON" or "OFF"
            v.TextColor3 = CFG[key] and C.ivory or C.muted
        end
        row.MouseButton1Click:Connect(function()
            if onSet then onSet(not CFG[key]) else CFG[key] = not CFG[key] end
            show()
        end)
        show()
        table.insert(switches, show)
    end
    switch("Auto - Next until all three are in", "Auto", setAuto)
    switch("Noclip", "Noclip", function(on) CFG.Noclip = on if not on then restoreCollide() end end)
    switch("Lava guard - ride on top of it", "LavaGuard")
    switch("W flies where you look (up/down too)", "FlyPitch")

    local function stepper(text, key, step, lo, hi)
        local row = add(new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }))
        local l = label("", Enum.Font.Gotham, 13, C.ivory, 30)
        l.Size = UDim2.new(1, -70, 1, 0)
        l.Parent = row
        local function show() l.Text = string.format("%s  %d", text, CFG[key]) end
        local function btn(t, x, d)
            local b = new("TextButton", { Size = UDim2.new(0, 30, 0, 26), Position = UDim2.new(1, x, 0, 2),
                BackgroundColor3 = C.raised, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 14,
                TextColor3 = C.ivory, Text = t, AutoButtonColor = false, Parent = row },
                { new("UICorner", { CornerRadius = UDim.new(0, 6) }) })
            b.MouseButton1Click:Connect(function()
                CFG[key] = math.clamp(CFG[key] + d, lo, hi)
                show()
            end)
        end
        btn("-", -64, -step)
        btn("+", -30, step)
        show()
    end
    stepper("Fly speed", "FlySpeed", 25, 25, 400)
    stepper("Next speed", "TravelSpeed", 25, 50, 400)

    gap(4)
    add(label("WASD fly - Space up - Ctrl down. A fly key takes over from Next and Auto.",
        Enum.Font.Gotham, 11, C.muted, 28))

    -- Behaviour.
    local painted = nil
    local function paintHero()
        if painted == V.running then return end
        painted = V.running
        hero.Text = V.running and "TRIAL MODE  ON" or "TRIAL MODE  OFF"
        TweenService:Create(hero, quick, {
            BackgroundColor3 = V.running and C.ivory or C.raised,
            TextColor3 = V.running and C.base or C.ivory,
        }):Play()
    end
    hero.MouseButton1Click:Connect(function()
        if V.running then V.off() else V.on() end
        paintHero()
        for _, s in ipairs(switches) do s() end
    end)
    nextB.MouseButton1Click:Connect(function()
        if not V.running then V.on() paintHero() end
        readTrial()
        goNext()
    end)
    hide.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        hide.Text = body.Visible and "Hide" or "Show"
    end)

    -- Drag by the header (the frame or the title on top of it). The two
    -- UserInputService connections go with the panel.
    local dragging, dragFrom, panelFrom = false, nil, nil
    local function grab(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragFrom, panelFrom = true, input.Position, panel.Position
        end
    end
    header.InputBegan:Connect(grab)
    title.InputBegan:Connect(grab)
    local uiConns = {
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragFrom
                panel.Position = UDim2.new(panelFrom.X.Scale, panelFrom.X.Offset + d.X, panelFrom.Y.Scale, panelFrom.Y.Offset + d.Y)
            end
        end),
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end),
    }
    gui.Destroying:Connect(function()
        for _, c in ipairs(uiConns) do c:Disconnect() end
    end)

    -- Live lines, 5 times a second while the panel is open.
    task.spawn(function()
        while gui.Parent do
            if body.Visible then
                if not V.running then readTrial() end
                if trial.here then
                    local parts_ = {}
                    for i = 1, 3 do
                        table.insert(parts_, COLOR_NAME[i] .. (trial.delivered[i] and " IN" or " --"))
                    end
                    local n = 0
                    for i = 1, 3 do if trial.delivered[i] then n += 1 end end
                    relicsL.Text = string.format("Relics %d/3   %s", n, table.concat(parts_, "  "))
                    handsL.Text = trial.carrying
                        and string.format("Hands  %s (%d) - hover still = shield", COLOR_NAME[trial.carrying], trial.carrying)
                        or "Hands  empty"
                    local kind, i = nextStep(trial.delivered, trial.carrying)
                    nextB.Text = (path and "Flying to " or "Next: ") .. describe(kind, i)
                else
                    relicsL.Text = "Relics  - (not in the trial)"
                    handsL.Text = "Hands  -"
                    nextB.Text = "Next (in the trial)"
                end
                local _, r = parts()
                if lava.top and r then
                    local gapY = r.Position.Y - lava.top
                    local trend = lava.rise > 1 and "rising" or (lava.rise < -1 and "draining" or "still")
                    local holding = os.clock() - liftedAt < 0.3
                    lavaL.Text = holding and string.format("Lava  HOLDING YOU UP - %s", trend)
                        or string.format("Lava  %.0f under you - %s", gapY, trend)
                    lavaL.TextColor3 = (holding or gapY < 60) and C.lava or C.muted
                else
                    lavaL.Text = "Lava  none yet"
                    lavaL.TextColor3 = C.muted
                end
                sayL.Text = lastSaid
                paintHero()
                for _, s in ipairs(switches) do s() end   -- a fly key turns Auto off
            end
            task.wait(0.2)
        end
    end)
    paintHero()
end

pcall(buildUI)
print("[BFV4] loaded - build " .. V.build .. ". The panel's big button (or _G.BFV4.on()) turns trial mode on.")
