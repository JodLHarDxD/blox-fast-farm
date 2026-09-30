-- Blox Fruits: your team picked at EVERY join, the farm script loaded or not
-- (a hop through the game's own server menu, a fresh join). The executor runs
-- it from its autoexec folder (Velocity: D:\Velocity\AutoExec). Any other
-- game: it does nothing. Only while you have no team: the one you are on is
-- never switched. fast_farm.lua's own team pick (CFG.AutoTeam) does the same
-- when it is loaded; both at once is harmless.
local TEAM = "Pirates"   -- or "Marines"

-- PlaceId is only certain once the game has loaded.
if not game:IsLoaded() then game.Loaded:Wait() end
local BLOX_FRUITS = {
    [2753915549] = true, [85211729168715] = true,    -- First Sea
    [4442272183] = true, [79091703265657] = true,    -- Second Sea
    [7449423635] = true, [100117331123089] = true,   -- Third Sea
}
if not BLOX_FRUITS[game.PlaceId] then return end

local Players = game:GetService("Players")
local player = Players.LocalPlayer
while not player do
    task.wait(0.1)
    player = Players.LocalPlayer
end
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 30)
local cf = remotes and remotes:WaitForChild("CommF_", 30)
if not cf then return end

-- Every 2 s, a minute at most.
for _ = 1, 30 do
    if player.Team ~= nil then break end
    pcall(function() cf:InvokeServer("SetTeam", TEAM) end)
    task.wait(2)
end
if player.Team then
    print("[BFF] autoexec team: on " .. player.Team.Name)
    -- The team is set; its screen is not needed (the remote does not always close it).
    pcall(function()
        local ct = player.PlayerGui.Main.ChooseTeam
        if ct.Visible then ct.Visible = false end
    end)
end
