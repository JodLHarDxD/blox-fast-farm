-- What the sea events hunt reads and calls, faked: vectors and yaw-only
-- CFrames, workspace (Map's sea plane, SeaBeasts, Enemies), the player, the
-- farm's helpers (flyTo, lockAt, fight, the weapons) as recorders, and P.sea
-- (the Prehistoric hunt's boat parts) as a fake boat. CLOCK is the clock.
local CLOCK = 100
local os = { clock = function() return CLOCK end, time = function() return 1000 end, date = function() return "now" end }
-- task.spawn is QUEUED (runSpawned() runs them): the hunt's background loops
-- never run here by themselves.
local SPAWNED = {}
local task = {
    wait = function(s) CLOCK += (s or 0.03) end,
    spawn = function(f, ...) table.insert(SPAWNED, f) end,
    defer = function(f, ...) f(...) end,
}
local function runSpawned()
    local list = SPAWNED
    SPAWNED = {}
    for _, f in ipairs(list) do f() end
end
local realPrint = print
local PRINTED = {}
local print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
    table.insert(PRINTED, table.concat(t, " "))
end
local function printed(word)
    for _, s in ipairs(PRINTED) do if string.find(s, word, 1, true) then return true end end
    return false
end

-- ---------------------------------------------------------------- vectors
local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then
        local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return vec(v.X / m, v.Y / m, v.Z / m)
    end
    if k == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__mul = function(a, b)
    if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
    return vec(a.X * b, a.Y * b, a.Z * b)
end
V.__div = function(a, b) return vec(a.X / b, a.Y / b, a.Z / b) end
V.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
local Vector3 = { new = vec, zero = vec(0, 0, 0) }

-- Yaw-only CFrames: { Position, yaw }.
local CF = {}
local function cf(pos, yaw) return setmetatable({ Position = pos, yaw = yaw or 0 }, CF) end
local function rot(v, t)
    return vec(v.X * math.cos(t) + v.Z * math.sin(t), v.Y, -v.X * math.sin(t) + v.Z * math.cos(t))
end
CF.__index = function(c, k)
    if k == "LookVector" then return vec(-math.sin(c.yaw), 0, -math.cos(c.yaw)) end
    return nil
end
CF.__mul = function(a, b) return cf(a.Position + rot(b.Position, a.yaw), a.yaw + b.yaw) end
CF.__add = function(a, v) return cf(a.Position + v, a.yaw) end
CF.__sub = function(a, v) return cf(a.Position - v, a.yaw) end
local CFrame = {
    new = function(p) return cf(p or vec(0, 0, 0), 0) end,
    Angles = function(_, y, _) return cf(vec(0, 0, 0), y) end,
}

-- ---------------------------------------------------------------- instances
local function inst(name, class, opts)
    opts = opts or {}
    local o = { Name = name, ClassName = class, kids = {}, attrs = opts.attrs or {}, Parent = true }
    for k, v in pairs(opts) do if k ~= "attrs" then o[k] = v end end
    function o:IsA(c)
        if c == self.ClassName then return true end
        if c == "BasePart" then return self.ClassName == "Part" or self.ClassName == "MeshPart" or self.ClassName == "VehicleSeat" end
        if c == "ValueBase" then return self.ClassName == "NumberValue" or self.ClassName == "IntValue" end
        return false
    end
    -- Same-named children (five "Piranha"s) each keep their own slot.
    function o:add(kid)
        local key = kid.Name
        while self.kids[key] do key = key .. "#" end
        self.kids[key], kid.key, kid.Parent = kid, key, self
        return kid
    end
    function o:FindFirstChild(n, deep)
        if self.kids[n] then return self.kids[n] end
        if deep then
            for _, k in pairs(self.kids) do
                local f = k:FindFirstChild(n, true)
                if f then return f end
            end
        end
        return nil
    end
    function o:GetChildren()
        local out = {}
        for _, k in pairs(self.kids) do table.insert(out, k) end
        table.sort(out, function(a, b) return a.Name < b.Name end)
        return out
    end
    function o:GetDescendants()
        local out = {}
        for _, k in ipairs(self:GetChildren()) do
            table.insert(out, k)
            for _, d in ipairs(k:GetDescendants()) do table.insert(out, d) end
        end
        return out
    end
    function o:FindFirstChildWhichIsA(c, deep)
        for _, d in ipairs(deep and self:GetDescendants() or self:GetChildren()) do
            if d:IsA(c) then return d end
        end
        return nil
    end
    function o:GetAttribute(n) return self.attrs[n] end
    function o:GetAttributes() return self.attrs end
    function o:GetFullName()
        local p = self.Parent
        return ((type(p) == "table" and p.GetFullName) and (p:GetFullName() .. ".") or "") .. self.Name
    end
    function o:GetPivot() return self.pivot or cf(self.Position or vec(0, 0, 0)) end
    function o:PivotTo(c) self.pivot = c self.moved = (self.moved or 0) + 1 end
    function o:Destroy() self.destroyed = true end
    return o
end

local WS = inst("Workspace", "Workspace")
local workspace = WS
local MAP = WS:add(inst("Map", "Folder"))
-- The sea plane: middle at Y -50, so the water's top (+56) is Y 6.
local PLANE = MAP:add(inst("WaterBase-Plane", "Part", { Position = vec(0, -50, 0) }))
local SEABEASTS = WS:add(inst("SeaBeasts", "Folder"))
local ENEMIES = WS:add(inst("Enemies", "Folder"))

-- ---------------------------------------------------------------- the player
local HUM = { Health = 100, SeatPart = nil, Sit = false }
local ROOT = { Position = vec(0, 10, 0) }
local player = { Name = "Me" }
local function parts() return {}, ROOT, HUM end

-- ---------------------------------------------------------------- the farm
local CFG = {
    Hunt = true, HuntKind = "seaevents", SeaSpeed = 300, InstantHop = 150,
    SeaEvDanger = 5,
    SeaEvFight = { ["Sea Beast"] = true, ["Rumbling Waters"] = true, Terrorshark = true, Piranha = true, Shark = false },
    SeaEvKeys = { Z = true, X = true, C = true, V = false, F = true },
    BeastHeight = 90, FishHeight = 30, BoatLift = 150, FleeTo = 1500,
    SeaEvGoal = 20, SeaEvStopAtGoal = false,
}
local SET_HUNT, STOPPED = {}, 0
local P = { running = true, elite = { note = "" }, randomSkip = {} }
function P.setHunt(x) table.insert(SET_HUNT, x) CFG.Hunt = x and true or false end
function P.stop() STOPPED += 1 end
-- The saved learned keys: the LEARNED KEYS block's cleaner, as it is.
function P.learnClean(t)
    local out = {}
    if type(t) ~= "table" then return out end
    for k, L in pairs(t) do
        if type(k) == "string" and type(L) == "table" then
            local c, d = tonumber(L.casts), tonumber(L.closed)
            if c and d and c >= 0 and d >= 0 and d <= c then out[k] = { casts = c, closed = d } end
        end
    end
    return out
end
local _G = { BFF = P }

local SEA = 3
local function mySea() return SEA end
local epoch = 1
local function stale(e) return e ~= epoch end
local FLIGHTS, LOCKS, SAYS, STATES = {}, {}, {}, {}
local function flyTo(pos)
    table.insert(FLIGHTS, pos)
    ROOT.Position = pos
    return true
end
local function lockAt(pos, look) table.insert(LOCKS, pos) ROOT.Position = pos end
local function say(s) table.insert(SAYS, s) end
local function setState(s) table.insert(STATES, s) end
local flying, aimUntil = false, 0
local pileCur, activeName = nil, nil
local RELEASED = 0
local function releasePile() RELEASED += 1 pileCur = nil end
local function cleanName(m) return (m.Name:gsub("%s*%b[]", ""):gsub("^%s+", ""):gsub("%s+$", "")) end
-- workspace.Enemies, read the way the farm's liveEnemies reads it.
local function liveEnemies(names)
    local out = {}
    for _, m in ipairs(ENEMIES:GetChildren()) do
        local root = m:FindFirstChild("HumanoidRootPart")
        if m.hum and root and m.hum.Health > 0 then
            local n = cleanName(m)
            if not names or names[n] then table.insert(out, { model = m, hum = m.hum, root = root, name = n }) end
        end
    end
    return out
end
-- The farm's fight: recorded; its pile builder asked once.
local FIGHTS, BUILT = {}, nil
local FIGHT_ANSWER = "empty"
local function fight(cur, names)
    table.insert(FIGHTS, cur)
    pileCur = cur
    BUILT = { cur.build() }
    return FIGHT_ANSWER
end
local TOOLS = {}
local function toolNames() return TOOLS end
local function toolType(t) return t.ToolTip end
-- CommF_: every call recorded; the Spy answers SPY_CODE.
local CALLS, SPY_CODE = {}, 1
local CF_REMOTE = { InvokeServer = function(_, ...)
    table.insert(CALLS, { ... })
    local a = { ... }
    if a[1] == "InfoLeviathan" then return SPY_CODE end
    return nil
end }
local function commF() return CF_REMOTE end
local HEARTBEAT = {}
local RunService = { Heartbeat = { Connect = function(_, f)
    table.insert(HEARTBEAT, f)
    return { Disconnect = function() end }
end } }
local function beat() for _, f in ipairs(HEARTBEAT) do f() end end
-- HttpService: a table stored under a token (no real JSON needed here).
local JSONS = {}
local function deep(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deep(v) end
    return o
end
local HS = {
    JSONEncode = function(_, t) table.insert(JSONS, deep(t)) return "json#" .. #JSONS end,
    JSONDecode = function(_, s) return deep(JSONS[tonumber(string.match(s, "%d+"))]) end,
}
local game = { GetService = function(_, n) return HS end }
-- The executor's files: readable at build (the count is loaded); written
-- only after useFiles() (the saver loop then never starts).
local FILES = {}
local readfile = function(n) local x = FILES[n] if x == nil then error("no such file") end return x end
local isfile = function(n) return FILES[n] ~= nil end
local writefile = nil
local function useFiles() writefile = function(n, s) FILES[n] = s end end
local function saved() return FILES["bff_sea_events.json"] and HS:JSONDecode(FILES["bff_sea_events.json"]) or nil end

-- ---------------------------------------------------------------- P.sea: the boat
local TIKI = vec(-16928.9, 7.8, 434.6)
local BOAT, BUYS, SITS, STOPS, NOTES = nil, 0, 0, 0, {}
local function makeBoat(pos)
    local b = inst("Beast Hunter", "Model")
    b.pivot = cf(pos, math.pi / 2)
    local seat = b:add(inst("VehicleSeat", "VehicleSeat", { Position = pos }))
    b.seat = seat
    return b
end
-- What the vent caster does to a beast (DAMAGE per action, the key it names).
local CASTS, DAMAGE, CAST_KEY = {}, 0, "Kitsune-Kitsune C"
local S = {
    driving = false, boat = nil, seat = nil, boatNote = "-", drive = { waterY = nil, boat = nil },
    TIKI = TIKI, steerFn = nil,
}
function S.myBoat() return (BOAT and BOAT.Parent) and BOAT or nil end
function S.seatOf(b) return b.seat end
function S.sit(seat) SITS += 1 HUM.SeatPart = seat return true end
function S.buyBoat() BUYS += 1 BOAT = makeBoat(vec(-16950, 4, 470)) return BOAT end
function S.boatHP() return 2500, 2500 end
local DANGER = 5
function S.dangerNow() return DANGER end
function S.notify(t) table.insert(NOTES, t) end
function S.stopDrive() STOPS += 1 S.driving = false HUM.SeatPart = nil end
-- The vent caster's ranking, as it is (SEA HUNT).
function S.keyScore(key, learn)
    local L = learn[key]
    if not L or L.casts == 0 then return 1 end
    if L.closed > 0 then return 2 + L.closed / L.casts end
    if L.casts < 4 then return 0.5 end
    return 0
end
function S.ventCast(v)
    table.insert(CASTS, v)
    if v.mark then v.mark() end
    local m = v.model
    local hv = m.kids.Health
    if hv then hv.Value = math.max(0, hv.Value - DAMAGE) end
    CLOCK += 0.5
    return CAST_KEY, v.dropped and v.dropped() or false
end
P.sea = S
