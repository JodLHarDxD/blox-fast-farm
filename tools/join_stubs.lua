
-- What browserList() and joinServer() touch, faked. SB = the game's
-- __ServerBrowser (nil = missing): PAGES[n] is what page n gives,
-- GAME_JOIN(id) what its "teleport" does. HERE_JOIN(id) is what
-- TeleportToPlaceInstance does. CALLS records every join in order.
local CLOCK = 0
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = { wait = function(s) CLOCK += (s or 0.03) end, spawn = function(f, ...) f(...) end }
local epoch = 0
local function stale(e) return e ~= epoch end
local game = { PlaceId = 7, JobId = "here" }
local Enum = { TeleportState = { Failed = "Failed" } }
local function say() end

local function signal()
    local s = { cbs = {} }
    function s:Connect(f)
        table.insert(self.cbs, f)
        local c = {}
        function c:Disconnect()
            for i, g in ipairs(s.cbs) do
                if g == f then table.remove(s.cbs, i) break end
            end
        end
        return c
    end
    function s:Fire(...)
        for _, f in ipairs(table.clone(self.cbs)) do f(...) end
    end
    return s
end

local TOKEN = "Teleport failed because Cannot teleport without a valid teleport token (Unauthorized)"
local E, SB, PAGES, GAME_JOIN, HERE_JOIN, CALLS
local TeleportService = { TeleportInitFailed = signal() }
player.OnTeleport = signal()
local function refuse(msg) TeleportService.TeleportInitFailed:Fire(player, "Unauthorized", msg) end

function TeleportService:TeleportToPlaceInstance(place, id, plr)
    table.insert(CALLS, "here:" .. id)
    if HERE_JOIN then HERE_JOIN(id) end
end

local RS = {}
function RS:FindFirstChild(n)
    if n == "__ServerBrowser" then return SB end
    return nil
end

local function newSB()
    local sb = {}
    function sb:InvokeServer(a, b)
        if a == "teleport" then
            table.insert(CALLS, "game:" .. b)
            if GAME_JOIN then return GAME_JOIN(b) end
            return nil
        end
        local p = PAGES[a]
        if type(p) == "function" then return p() end
        return p
    end
    return sb
end

local function reset()
    E = { clientRefused = false }
    SB, PAGES, GAME_JOIN, HERE_JOIN, CALLS = newSB(), {}, nil, nil, {}
    CLOCK, epoch = 0, 0
    TeleportService.TeleportInitFailed.cbs = {}
    player.OnTeleport.cbs = {}
end
reset()
