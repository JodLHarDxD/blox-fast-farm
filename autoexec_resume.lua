-- Blox Fruits: after a CRASH, the farm comes back by itself. Roblox-Velocity.ps1's
-- Live Guard sees Roblox crash (a new crash dump, no game left), opens Blox
-- Fruits again and leaves bff_crash_resume.json in the executor's workspace:
--   { "at": <unix time>, "start": <the farm was running when it crashed> }
-- This file, in the executor's autoexec folder (Velocity: D:\Velocity\AutoExec),
-- loads fast_farm in the server you stay in and presses Start if the farm was
-- running. Once per crash: the file is used up before the load. Older than 5
-- minutes, or any other game: nothing. fast_farm's settings lock brings your
-- modes back, so Start runs what you had on.
-- Why (2026-11-10): Velocity 1.6.0 crashes Roblox every few joins; the user
-- keeps the script on it until Velocity ships a fix.

-- PlaceId is only certain once the game has loaded.
if not game:IsLoaded() then game.Loaded:Wait() end
local START_PLACE = 2753915549
local BLOX_FRUITS = {
    [2753915549] = true, [85211729168715] = true,    -- First Sea
    [4442272183] = true, [79091703265657] = true,    -- Second Sea
    [7449423635] = true, [100117331123089] = true,   -- Third Sea
}
if not BLOX_FRUITS[game.PlaceId] then return end

local FLAG = "bff_crash_resume.json"
local SOURCE = "https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/fast_farm.lua"
if not (isfile and readfile) then return end
local HttpService = game:GetService("HttpService")

-- The Guard's note, if there is one and it is fresh.
local function note()
    local ok, t = pcall(function()
        if not isfile(FLAG) then return nil end
        return HttpService:JSONDecode(readfile(FLAG))
    end)
    if ok and type(t) == "table" and tonumber(t.at) and os.time() - t.at <= 300 then return t end
    return nil
end
if not note() then return end

-- The start place sends a Second or Third Sea account on to its sea within
-- seconds, and that teleport ends this copy: wait here, so the farm loads in
-- the server you stay in. The note is still there for that server's copy.
if game.PlaceId == START_PLACE then task.wait(25) end
local t = note()
if not t then return end              -- another copy took it meanwhile
if _G.BFF then return end             -- loaded already (by hand, or a hop's queued reload)

-- Used up BEFORE the load: a crash during the load must not come back to it.
if delfile then pcall(delfile, FLAG) else pcall(writefile, FLAG, "{}") end

local url = _G.BFF_SOURCE or SOURCE
local got, src = pcall(function() return game:HttpGet(url .. "?cb=" .. tostring(tick())) end)
-- A scheduler pass between HttpGet and the first print (Roblox 0.746 + Velocity:
-- a print straight after HttpGet killed the client, 2026-11-06).
task.wait()
if not got or type(src) ~= "string" then
    print("[BFF] crash resume: fast_farm could not be downloaded - load it by hand")
    return
end
local fn = loadstring(src)
if not fn then
    print("[BFF] crash resume: fast_farm did not compile - load it by hand")
    return
end
_G.BFF_SOURCE = url
-- Returns when fast_farm's load is done (its own yields run inside).
local loaded = pcall(fn)
if not (loaded and _G.BFF) then return end
local how
if not t.start then
    how = " - it was not running, press Start when you want it"
else
    -- A hunt carried over by the hop file starts by itself (deferred): give it a moment.
    task.wait(2)
    if _G.BFF.running then
        how = ", the farm was already running"
    else
        how = pcall(_G.BFF.start) and ", farm started again" or ", Start failed - press it by hand"
    end
end
print("[BFF] crash resume: fast_farm reloaded" .. how)
