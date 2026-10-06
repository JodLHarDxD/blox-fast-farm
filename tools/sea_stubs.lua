-- What the sea hunt and the volcano event read and call, faked: vectors and
-- yaw-only CFrames, workspace (Map, _WorldOrigin.Locations, Boats, Enemies,
-- DinoBone), the player and the compass, the farm's own helpers (flyTo,
-- fight, the pile, the weapons) as recorders. CLOCK is the clock.
local CLOCK = 100
local os = { clock = function() return CLOCK end, time = function() return 0 end, date = function() return "now" end }
local task = {
    wait = function(s) CLOCK += (s or 0.03) end,
    spawn = function(f, ...) f(...) end,
    defer = function(f, ...) f(...) end,
}
local realPrint = print
local PRINTED = {}
local print = function(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end
    table.insert(PRINTED, table.concat(t, " "))
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

-- Yaw-only CFrames: { Position, yaw }. Ry(t) turns (x, z) to
-- (x cos t + z sin t, -x sin t + z cos t); LookVector = (-sin t, 0, -cos t).
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
        if c == "GuiObject" then return self.ClassName == "TextLabel" or self.ClassName == "Frame" or self.ClassName == "TextButton" end
        if c == "ValueBase" then return self.ClassName == "NumberValue" or self.ClassName == "IntValue" end
        return false
    end
    function o:add(kid) self.kids[kid.Name] = kid kid.Parent = self return kid end
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
    function o:IsDescendantOf(a)
        local p = self.Parent
        while type(p) == "table" do
            if p == a then return true end
            p = p.Parent
        end
        return false
    end
    function o:Destroy() self.destroyed = true end
    return o
end

local WS = inst("Workspace", "Workspace")
local workspace = WS
WS.CurrentCamera = { ViewportSize = vec(1920, 1080, 0) }

-- ---------------------------------------------------------------- the player
local HUM = { Health = 100, SeatPart = nil, Sit = false }
local ROOT = { Position = vec(0, 10, 0) }
ROOT.CFrame = cf(ROOT.Position)
local DANGER_TEXT = nil
local PG = inst("PlayerGui", "PlayerGui")
setmetatable(PG, { __index = function(_, k)
    if k == "Main" then
        if DANGER_TEXT == nil then error("no compass") end
        return { Compass = { Frame = { DangerLevel = { TextLabel = { Text = DANGER_TEXT } } } } }
    end
    return nil
end })
local player = { Name = "Me", attrs = {}, PlayerGui = PG }
function player:GetAttribute(n) return self.attrs[n] end
local function parts() return {}, ROOT, HUM end

-- ---------------------------------------------------------------- the farm
local CFG = {
    Magnet = true, GrabMax = 30, CastWait = 0.45, Weapons = {},
    SeaBoat = "Beast Hunter", SeaSpeed = 300, SeaSearchTo = 8000, SeaStudsPerM = 10, SeaLeg2 = 0, SeaTurnBack = 120, SeaSearchMinutes = 0,
    SeaSteer = "auto", SeaTurnRate = 60, MirageGear = true, MirageNeed = "night",
    Volcano = false, VentKeys = { Z = true, X = true, C = true, V = false },
    VentDistance = 12, GolemCage = 60, VolcanoLoot = true,
}
local SET_HUNT = {}
local P = { running = true, elite = { note = "", why = nil }, heldAt = {} }
function P.setHunt(x) table.insert(SET_HUNT, x) P.handsOff = false end
local STOPPED = 0
function P.stop() STOPPED += 1 end
P.news = { sky = nil }
local _G = { BFF = P }

local SEA = 3
local function mySea() return SEA end
local epoch = 1
local function stale(e) return e ~= epoch end
local FLIGHTS, LOCKS, SAYS, STATES = {}, {}, {}, {}
local ON_FLY, ON_KEY = nil, nil
local function flyTo(pos)
    table.insert(FLIGHTS, pos)
    ROOT.Position = pos
    if ON_FLY then ON_FLY(pos) end
    return true
end
local function lockAt(pos) table.insert(LOCKS, pos) end
local function say(s) table.insert(SAYS, s) end
local function setState(s) table.insert(STATES, s) end
local flying, lastWritten, aimUntil, aimPixel = false, nil, 0, nil
local pileCur, pileNames, pileActive, activeName = nil, nil, false, nil
local RELEASED, REFRESHED, FIGHTS = 0, 0, {}
local function releasePile() RELEASED += 1 pileCur, pileNames, pileActive = nil, nil, false end
local RESTORED, CAM_RELEASED = 0, 0
local function restoreBody() RESTORED += 1 end
local function releaseCamera() CAM_RELEASED += 1 end
local function refreshPile()
    REFRESHED += 1
    if pileCur and pileCur.build then pileCur.build() end
end
local ENEMIES = {}
local function liveEnemies(names)
    local out = {}
    for _, e in ipairs(ENEMIES) do
        if e.hum.Health > 0 and (not names or names[e.name]) then table.insert(out, e) end
    end
    return out
end
local PUTBACK = {}
local function isPutBack(m) return PUTBACK[m] == true end
local pile = {}
local function fight(cur, names)
    table.insert(FIGHTS, cur.name)
    pileCur, pileNames, pileActive = cur, names, true
    return "break"
end
local stats = { casts = 0 }
local TOOLS = {}
local function toolNames() return TOOLS end
local function toolType(t) return t.ToolTip end
local READY = {}
local function skillReady(w, k) return READY[w .. " " .. k] == true end
local HELD = nil
local function heldTool() return HELD and { Name = HELD } or nil end
local function equip(n) HELD = n return true end
local BARS = {}
local function barReady(w, k) return BARS[w .. " " .. k] end
local CDS = {}
local function cdOf(w, k) CDS[w .. k] = CDS[w .. k] or {} return CDS[w .. k] end
local KEYS_SENT = {}
local function holdKey(code, secs, before)
    if before then before() end
    table.insert(KEYS_SENT, code)
    if ON_KEY then ON_KEY(code) end
end
local KEYCODE = { Z = "Z", X = "X", C = "C", V = "V", F = "F" }
local AIMED = {}
local function aimSwapIn(at) table.insert(AIMED, at) end
local M1S = 0
local M1_AIM = nil
local function pressM1() M1S += 1 M1_AIM = P.aimAt end
local BUY_CALLS = {}
local CF_REMOTE = { InvokeServer = function(_, ...) table.insert(BUY_CALLS, { ... }) return 1 end }
local function commF() return CF_REMOTE end
local RunService = {
    Heartbeat = {
        Connect = function(_, f) return { Disconnect = function() end } end,
        Wait = function() CLOCK += 1 / 60 return 1 / 60 end,
    },
}
local KEYS_DOWN, TYPING = {}, false
local Enum = { KeyCode = { W = "W", A = "A", S = "S", D = "D", Up = "Up", Down = "Down", Left = "Left", Right = "Right", E = "E" } }
local INPUT = {
    SetCore = function() end,
    IsKeyDown = function(_, k) return KEYS_DOWN[k] == true end,
    GetFocusedTextBox = function() return TYPING and {} or nil end,
}
local TAGGED = {}
INPUT.GetTagged = function(_, tag) return TAGGED[tag] or {} end
local game = { GetService = function() return INPUT end }
local RS = inst("ReplicatedStorage", "Folder")
local fireproximityprompt = function(p) p.fired = (p.fired or 0) + 1 end
