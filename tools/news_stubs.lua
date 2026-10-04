-- What the server news reads, faked: Lighting (ClockTime, the MoonPhase /
-- IsBlueMoon attributes, the sky's moon decal), workspace (Map,
-- _WorldOrigin.Locations, fruits lying), bossUp, the Cake Prince answer, the
-- executor's file calls and a JSON that round-trips a table. The clock is
-- CLOCK; the game's is LIGHT.ClockTime.
local CLOCK = 0
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = {
    wait = function(s) CLOCK += (s or 0.03) end,
    spawn = function(f, ...) f(...) end,
}
local realPrint = print
local PRINTED = {}
local print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
    table.insert(PRINTED, table.concat(t, " "))
end

local V = {}
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, V) end
V.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }, V) end
local Vector3 = { new = function(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end }

-- A fake instance: name, class, children by name, attributes, a position.
local function inst(name, class, opts)
    opts = opts or {}
    local o = { Name = name, ClassName = class, kids = {}, attrs = opts.attrs or {}, pos = opts.pos }
    function o:IsA(c)
        if c == self.ClassName then return true end
        if c == "BasePart" then return self.ClassName == "Part" or self.ClassName == "MeshPart" end
        return false
    end
    function o:FindFirstChild(n) return self.kids[n] end
    function o:GetChildren()
        local out = {}
        for _, k in pairs(self.kids) do table.insert(out, k) end
        table.sort(out, function(a, b) return a.Name < b.Name end)
        return out
    end
    function o:GetAttribute(n) return self.attrs[n] end
    function o:GetAttributes() return self.attrs end
    function o:GetFullName() return "Workspace." .. self.Name end
    function o:GetPivot() return { Position = self.pos or Vector3.new(0, 0, 0) } end
    if class == "Part" then o.Position = opts.pos or Vector3.new(0, 0, 0) end
    return o
end

local LIGHT, SKY, MAP, LOCS, WS_KIDS, BOSSES, CAKE_ANSWER, CAKE_CALLS, SEA, ROOT, FILES
local PLAYERS_N

local Lighting = {}
function Lighting:GetAttribute(n) return LIGHT.attrs[n] end
function Lighting:FindFirstChild(n) if SKY and SKY.Name == n then return SKY end return nil end
function Lighting:FindFirstChildOfClass(c) if SKY and c == "Sky" then return SKY end return nil end
setmetatable(Lighting, { __index = function(_, k) if k == "ClockTime" then return LIGHT.ClockTime end end })

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
    if n == "Lighting" then return Lighting end
    if n == "HttpService" then return HttpService end
    error("no service " .. n)
end }

local workspace = { DistributedGameTime = 0 }
function workspace:FindFirstChild(n)
    if n == "Map" then return MAP end
    if n == "_WorldOrigin" then
        return LOCS and { FindFirstChild = function(_, k) if k == "Locations" then return LOCS end end } or nil
    end
    return WS_KIDS[n]
end
function workspace:GetChildren()
    local out = {}
    for _, k in pairs(WS_KIDS) do table.insert(out, k) end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end

local Players = { MaxPlayers = 12 }
function Players:GetPlayers()
    local t = {}
    for i = 1, PLAYERS_N do t[i] = i end
    return t
end

local P
local function mySea() return SEA end
local function bossUp(n)
    local b = BOSSES[n]
    if b then return b.pos, b.where end
    return nil, nil
end
local function commF()
    return { InvokeServer = function(_, what, arg)
        if what == "CakePrinceSpawner" and arg == true then
            CAKE_CALLS += 1
            return CAKE_ANSWER
        end
        return nil
    end }
end
local function parts() return {}, ROOT, {} end

local writefile = function(name, s) FILES[name] = s end
local readfile = function(name)
    local s = FILES[name]
    if s == nil then error("file not found") end
    return s
end

-- A fresh world: day 10:00, no attribute, no sky, Third Sea, nothing up.
local function reset(o)
    o = o or {}
    CLOCK = o.clock or 1000
    LIGHT = { ClockTime = o.at or 10, attrs = {} }
    SKY = nil
    MAP = inst("Map", "Folder")
    LOCS = inst("Locations", "Folder")
    WS_KIDS = {}
    BOSSES = {}
    CAKE_ANSWER, CAKE_CALLS = nil, 0
    SEA = (o.sea == nil) and 3 or o.sea
    ROOT = { Position = Vector3.new(0, 0, 0) }
    if not o.keepFiles then FILES = {} end
    PLAYERS_N = 7
    workspace.DistributedGameTime = 600
    PRINTED = {}
    P = { ELITES = { "Diablo", "Deandre", "Urban", "Tyrant of the Skies" } }
end
reset()

-- The moon decal the game would show (Sea 3: Lighting.Sky).
local function decal(id, skyName)
    SKY = { Name = skyName or "Sky", MoonTextureId = "http://www.roblox.com/asset/?id=" .. id }
end
