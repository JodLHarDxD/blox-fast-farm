--[[
    ANDROID PROBE - settles, on the phone itself, whether fast_farm.lua can
    run there. Moves nothing, buys nothing. It presses ONE skill key (Z) once,
    with whatever weapon you hold, to see whether the game takes a key the
    script sends: that is the one thing the code cannot tell from a PC.

    Run it in Blox Fruits with a weapon IN HAND whose Z skill is ready
    (any fruit, sword or fighting style that has a Z). Takes ~5 s.

    Everything goes to the console AND to workspace/bff_android_probe.txt.
]]
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local player    = Players.LocalPlayer
local FILE      = "bff_android_probe.txt"

local lines = {}
local function out(s)
    s = "[ANDROID] " .. tostring(s)
    print(s)
    table.insert(lines, s)
end
local function yn(b) return b and "yes" or "NO" end

-- 1. The executor: what fast_farm.lua reaches for. Every one is optional in
-- the farm (it says what it lost), but these are the ones that matter.
local name = "?"
pcall(function()
    if identifyexecutor then name = table.concat({ identifyexecutor() }, " ")
    elseif getexecutorname then name = tostring(getexecutorname()) end
end)
out("executor: " .. name)
local id = "?"
pcall(function() id = tostring((getthreadidentity or getidentity or function() return "?" end)()) end)
out("identity: " .. id)
local q = (syn and syn.queue_on_teleport) or queue_on_teleport or queueonteleport
    or (fluxus and fluxus.queue_on_teleport)
local fns = {
    { "queue_on_teleport (comes back after a hop)", q },
    { "getrenv (the game's own hit sender)", getrenv },
    { "getsenv (hit sender, second way)", getsenv },
    { "hookmetamethod (silent aim)", hookmetamethod },
    { "fireproximityprompt (berries, flowers)", fireproximityprompt },
    { "firetouchinterest (fruits)", firetouchinterest },
    { "sethiddenproperty (magnet radius)", sethiddenproperty },
    { "isnetworkowner (magnet ownership)", isnetworkowner },
    { "writefile / readfile (hop + learned files)", writefile and readfile },
}
for _, f in ipairs(fns) do out(("  %-46s %s"):format(f[1], yn(type(f[2]) == "function"))) end

-- 2. The device.
local cam = workspace.CurrentCamera
local vs = cam and cam.ViewportSize or Vector2.new()
out(("screen: %d x %d  touch=%s keyboard=%s mouse=%s"):format(
    vs.X, vs.Y, tostring(UIS.TouchEnabled), tostring(UIS.KeyboardEnabled), tostring(UIS.MouseEnabled)))
out(("fast_farm panel 342 x 570 at y=18: %s"):format(
    (vs.Y >= 588) and "fits" or ("bottom " .. math.floor(588 - vs.Y) .. " px off screen (use Hide / drag)")))

-- 3. The game's UI the farm reads.
local pg = player:FindFirstChildOfClass("PlayerGui")
local main = pg and pg:FindFirstChild("Main")
out("PlayerGui.Main (quests, raid timer): " .. yn(main))
out("PlayerGui.Main.Skills (cooldown bars): " .. yn(main and main:FindFirstChild("Skills")))
out("PlayerGui.ScreenGui (Ken check): " .. yn(pg and pg:FindFirstChild("ScreenGui")))

-- 4. The VirtualInputManager service itself.
local okVim, VIM = pcall(function() return game:GetService("VirtualInputManager") end)
out("VirtualInputManager reachable: " .. yn(okVim and VIM))

-- 5. The deciding test: does the game take a Z the script sends?
-- Watched three ways: the game's InputBegan sees it, the skill's cooldown
-- bar fills, or the tool in hand fires (Activated is not enough - skills
-- are not Activated - so the bar is the real answer).
local char = player.Character
local tool = char and char:FindFirstChildOfClass("Tool")
if not tool then
    out("KEY TEST SKIPPED: hold a weapon first (fruit / sword / style with a Z skill)")
elseif not (okVim and VIM) then
    out("KEY TEST SKIPPED: no VirtualInputManager")
else
    local sawInput = false
    local conn = UIS.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.Z then sawInput = true end
    end)
    local function bar()
        local sk = main and main:FindFirstChild("Skills")
        local wf = sk and sk:FindFirstChild(tool.Name)
        local kf = wf and wf:FindFirstChild("Z")
        local b = kf and kf:FindFirstChild("Cooldown")
        return (b and b:IsA("GuiObject")) and b or nil
    end
    local b = bar()
    local before = b and b.AbsoluteSize.X
    out(("weapon: %s  Z bar before: %s"):format(tool.Name, b and tostring(before) or "no bar"))
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
    end)
    local fired = false
    for _ = 1, 30 do
        task.wait(0.1)
        b = bar()
        if b and b.AbsoluteSize.X > 0 and (before or 0) <= 0 then fired = true break end
    end
    conn:Disconnect()
    out("engine saw the sent Z (UIS.InputBegan): " .. yn(sawInput))
    if fired then
        out("RESULT: the game FIRED the skill from a sent key -> skills work on this phone")
    elseif not b then
        out("RESULT: no cooldown bar for this weapon's Z - did the skill go off on screen? (yes = works)")
    elseif (before or 0) > 0 then
        out("RESULT: Z was already cooling - wait for it and run again")
    else
        out("RESULT: sent Z did NOT fire the skill -> skills need the mobile buttons, not keys")
    end
end

if writefile then pcall(writefile, FILE, table.concat(lines, "\n")) end
out("written to workspace/" .. FILE)
