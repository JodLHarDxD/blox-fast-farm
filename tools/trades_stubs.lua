-- What the trade counter reads, faked: the Remotes (TradeEvent, CommE) as
-- signals a case fires, the new labels in your PlayerGui, Players, the
-- executor's file calls and a JSON that round-trips a table. The wall clock
-- is NOW (P.trades.clock); os.date is the real one.
local NOW = 0
local realPrint = print
local PRINTED = {}
local print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
    table.insert(PRINTED, table.concat(t, " "))
end

local function signal()
    local s = { conns = {} }
    function s:Connect(f)
        local c = { f = f, on = true }
        function c:Disconnect() self.on = false end
        table.insert(s.conns, c)
        return c
    end
    function s:Fire(...)
        for _, c in ipairs(s.conns) do
            if c.on then c.f(...) end
        end
    end
    return s
end

-- Deferred and delayed calls run at once: a label read now and again later
-- is read twice in a row (the second must not count again).
local task = {
    wait = function() end,
    spawn = function(f, ...) f(...) end,
    defer = function(f, ...) f(...) end,
    delay = function(_, f, ...) f(...) end,
}

-- JSON that round-trips: the encoded string names a stored deep copy.
local JSON_STORE, JSON_N = {}, 0
local function deep(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deep(v) end
    return c
end
local HttpService = {}
function HttpService:JSONEncode(t)
    JSON_N += 1
    local key = "JSON#" .. JSON_N
    JSON_STORE[key] = deep(t)
    return key
end
function HttpService:JSONDecode(s)
    local t = JSON_STORE[s]
    if not t then error("Can't parse JSON") end
    return deep(t)
end
local game = { GetService = function(_, n)
    if n == "HttpService" then return HttpService end
    error("no service " .. n)
end }

local FILES = {}
local writefile = function(name, s) FILES[name] = s end
local readfile = function(name)
    local s = FILES[name]
    if not s then error("no file " .. name) end
    return s
end
local isfile = function(name) return FILES[name] ~= nil end

local TRADE_EVENT, COMM_E, ADDED = signal(), signal(), signal()
local REMOTE_KIDS = {}
local REMOTES = {}
function REMOTES:WaitForChild(n) return REMOTE_KIDS[n] end
function REMOTES:FindFirstChild(n) return REMOTE_KIDS[n] end
local RS = {}
function RS:WaitForChild(n) if n == "Remotes" then return REMOTES end return nil end

local PG = { DescendantAdded = ADDED }
local player = { UserId = 8230031723 }
function player:FindFirstChildOfClass(c) if c == "PlayerGui" then return PG end return nil end
function player:WaitForChild(n) if n == "PlayerGui" then return PG end return nil end
local OTHERS = { [222] = { Name = "exodorxz" }, [333] = { Name = "Randyorton17" } }
local Players = {}
function Players:GetPlayerByUserId(id) return OTHERS[id] end

-- A new label: its text, and the GUIs it sits in.
local function label(text, inside)
    local o = { Text = text, ClassName = "TextLabel", inside = inside or {} }
    function o:IsA(c) return c == self.ClassName end
    function o:FindFirstAncestor(n) return self.inside[n] and {} or nil end
    return o
end

local BREAKING = {}
local P = { news = { breaking = function(key, text) table.insert(BREAKING, { key = key, text = text }) end } }
local _G = { BFF = P }          -- luau's own _G is read-only; the section only compares _G.BFF

-- A fresh start: no files, no prints, both remotes there, nothing broken.
local function reset(o)
    o = o or {}
    if not o.keepFiles then FILES = {} end
    PRINTED, BREAKING = {}, {}
    TRADE_EVENT, COMM_E, ADDED = signal(), signal(), signal()
    PG.DescendantAdded = ADDED
    REMOTE_KIDS = {
        TradeEvent = (o.noTradeEvent == nil) and { OnClientEvent = TRADE_EVENT } or nil,
        CommE = { OnClientEvent = COMM_E },
    }
end
