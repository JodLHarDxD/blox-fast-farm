--[[
    SEA PROBE (read-only) - settles what the Mirage / Prehistoric / boat
    automation has to know before it is built. Buys nothing, moves nothing,
    clicks nothing. Two questions are asked of the server (CheckTempleDoor,
    RaceV4Progress "Check") - both only answer, they change nothing.

    Run it in the Third Sea. Sail your boat yourself (west of Tiki Outpost,
    into Sea Danger 5-6) for a few minutes while it runs: every 5 s it writes
    where you are, how far from the Tiki boat dealer in studs, and every
    number the compass shows - that gives the game's meters-to-studs ratio.
    If an island is up it describes it.

    Everything goes to the console AND to workspace/bff_sea_probe.txt.
    Stop: _G.BFF_SEA_PROBE = false
]]
_G.BFF_SEA_PROBE = true
local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local player   = Players.LocalPlayer
local TIKI     = Vector3.new(-16928.93, 7.77, 434.62)   -- Tiki Outpost boat dealer (public hubs, 2026)
local FILE     = "bff_sea_probe.txt"

local lines = {}
local function out(s)
    s = "[SEA] " .. tostring(s)
    print(s)
    table.insert(lines, s)
    if writefile then pcall(writefile, FILE, table.concat(lines, "\n")) end
end
local function attrs(inst)
    local t = {}
    local ok, a = pcall(function() return inst:GetAttributes() end)
    if ok then for k, v in pairs(a) do table.insert(t, k .. "=" .. tostring(v)) end end
    return #t > 0 and table.concat(t, ", ") or "none"
end
local function kids(inst, max)
    local t = {}
    for i, c in ipairs(inst:GetChildren()) do
        if i > (max or 40) then table.insert(t, "...") break end
        table.insert(t, c.Name .. ":" .. c.ClassName)
    end
    return table.concat(t, ", ")
end
local function root()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function commF(...)
    local r = RS:FindFirstChild("Remotes")
    local cf = r and r:FindFirstChild("CommF_")
    if not cf then return "no CommF_" end
    local args = { ... }
    local ok, a = pcall(function() return cf:InvokeServer(table.unpack(args)) end)
    return ok and tostring(a) or ("error " .. tostring(a))
end

out("probe start " .. os.date("!%Y-%m-%d %H:%M:%S") .. "Z place " .. game.PlaceId .. " MAP attr " .. tostring(workspace:GetAttribute("MAP")))

-- 1. BOATS: the names the dealer knows, your boat's insides
pcall(function()
    local c = RS:FindFirstChild("BoatDisplayCache")
    out("1 BoatDisplayCache: " .. (c and kids(c, 80) or "MISSING"))
end)
local function myBoat()
    local f = workspace:FindFirstChild("Boats")
    if not f then return nil end
    for _, b in ipairs(f:GetChildren()) do
        local o = b:FindFirstChild("Owner")
        if o and tostring(o.Value) == player.Name then return b end
    end
    return nil
end
local seenBoat
local function describeBoat()
    local b = myBoat()
    if not b or b == seenBoat then return end
    seenBoat = b
    out("1 your boat: " .. b.Name .. " (" .. b.ClassName .. ") attributes: " .. attrs(b))
    out("1   children: " .. kids(b, 60))
    local seats, vs = 0, 0
    for _, d in ipairs(b:GetDescendants()) do
        if d:IsA("VehicleSeat") then vs += 1 out("1   VehicleSeat " .. d:GetFullName() .. " MaxSpeed " .. d.MaxSpeed)
        elseif d:IsA("Seat") then seats += 1 end
    end
    out("1   seats " .. seats .. " + vehicle seats " .. vs)
    for _, n in ipairs({ "Humanoid", "Health", "HP" }) do
        local h = b:FindFirstChild(n)
        if h then out("1   " .. n .. ": " .. h.ClassName .. " = " .. tostring(h.Value ~= nil and h.Value or (h:IsA("Humanoid") and h.Health))) end
    end
end

-- 2. MOON + race steps (questions only)
out("2 MoonPhase " .. tostring(Lighting:GetAttribute("MoonPhase")) .. " IsBlueMoon " .. tostring(Lighting:GetAttribute("IsBlueMoon"))
    .. " clock " .. string.format("%.2f", Lighting.ClockTime))
out("2 CheckTempleDoor -> " .. commF("CheckTempleDoor"))
out("2 RaceV4Progress Check -> " .. commF("RaceV4Progress", "Check"))
out("2 player attributes: " .. attrs(player))

-- 3. ISLANDS: marker types, MeshIds hubs look for, Prehistoric Core
local MESH = { ["6745037796"] = "high point (2024)", ["6105779869"] = "high point (2026)", ["10153114969"] = "BLUE GEAR" }
local described = {}
local function describeIslands()
    local map = workspace:FindFirstChild("Map")
    local locs = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    for _, n in ipairs({ "Mirage Island", "Prehistoric Island", "Kitsune Island", "Frozen Dimension" }) do
        local m = locs and locs:FindFirstChild(n)
        if m and not described["loc" .. n] then
            described["loc" .. n] = true
            out("3 marker Locations['" .. n .. "'] class " .. m.ClassName .. " attributes: " .. attrs(m))
        end
    end
    for _, n in ipairs({ "MysticIsland", "PrehistoricIsland", "KitsuneIsland", "FrozenDimension" }) do
        local m = (map and map:FindFirstChild(n)) or workspace:FindFirstChild(n)
        if m and not described[n] then
            described[n] = true
            out("3 " .. m:GetFullName() .. " attributes: " .. attrs(m))
            out("3   children: " .. kids(m, 60))
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("MeshPart") then
                    local id = string.match(d.MeshId, "%d+")
                    if id and MESH[id] then
                        out(string.format("3   %s %s at (%.0f, %.0f, %.0f) Transparency %.2f parent %s", MESH[id], id,
                            d.Position.X, d.Position.Y, d.Position.Z, d.Transparency, d.Parent.Name))
                    end
                end
            end
            local core = m:FindFirstChild("Core")
            if core then
                out("3   Core: " .. kids(core, 60))
                local vr = core:FindFirstChild("VolcanoRocks")
                if vr then out("3   VolcanoRocks: " .. #vr:GetChildren() .. " rocks; first: " .. kids(vr:GetChildren()[1] or vr, 20)) end
                local ap = core:FindFirstChild("ActivationPrompt")
                local pp = ap and ap:FindFirstChildWhichIsA("ProximityPrompt", true)
                if pp then out("3   ActivationPrompt: HoldDuration " .. pp.HoldDuration .. " MaxDistance " .. pp.MaxActivationDistance .. " Enabled " .. tostring(pp.Enabled)) end
            end
        end
    end
end

-- 4. THE COMPASS: every number it shows, next to where you really are
local function compassTexts()
    local t = {}
    local main = player.PlayerGui:FindFirstChild("Main")
    local comp = main and main:FindFirstChild("Compass")
    if not comp then return "no PlayerGui.Main.Compass" end
    for _, d in ipairs(comp:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.Visible then
            table.insert(t, d:GetFullName():gsub("^.-Compass%.", "") .. "='" .. d.Text .. "'")
        end
    end
    return #t > 0 and table.concat(t, " | ") or "compass empty"
end

local lastC, lastT = Lighting.ClockTime, os.clock()
task.spawn(function()
    local n = 0
    while _G.BFF_SEA_PROBE and n < 240 do      -- 20 min at most
        n += 1
        pcall(describeBoat)
        pcall(describeIslands)
        local r = root()
        if r then
            local p = r.Position
            local studs = (Vector3.new(p.X, 0, p.Z) - Vector3.new(TIKI.X, 0, TIKI.Z)).Magnitude
            out(string.format("4 pos (%.0f, %.0f, %.0f) studs from Tiki %.0f  /5 = %.0f m  DangerLevel attr %s  sitting %s  compass: %s",
                p.X, p.Y, p.Z, studs, studs / 5, tostring(player:GetAttribute("DangerLevel")),
                tostring(player.Character.Humanoid.SeatPart and player.Character.Humanoid.SeatPart:GetFullName()), compassTexts()))
        end
        if n % 12 == 0 then
            local c, t = Lighting.ClockTime, os.clock()
            local dc = c - lastC
            if dc < 0 then dc += 24 end
            out(string.format("5 clock %.2f; %.1f real s per game hour", c, (t - lastT) / math.max(dc, 1e-6)))
            lastC, lastT = c, t
        end
        task.wait(5)
    end
    out("probe end")
end)
