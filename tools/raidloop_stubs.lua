-- What raid mode reads and calls, faked: vectors, the player (PlayerGui's
-- raid timer, Backpack, Character), workspace (_WorldOrigin.Locations, Map's
-- raid button), the enemies, the server (CommF_ / the Net item list), the
-- farm's own helpers (fight, flyTo, releasePile) as recorders. CLOCK is the clock.
local CLOCK = 100
local ON_WAIT = nil
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = {
    wait = function(s) CLOCK += (s or 0.03) if ON_WAIT then ON_WAIT() end end,
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
    return nil
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__mul = function(a, b)
    if type(a) == "number" then return vec(b.X * a, b.Y * a, b.Z * a) end
    return vec(a.X * b, a.Y * b, a.Z * b)
end
V.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
local Vector3 = { new = vec, zero = vec(0, 0, 0) }

-- ---------------------------------------------------------------- instances
local function inst(name, class, opts)
    opts = opts or {}
    local o = { Name = name, ClassName = class, kids = {}, attrs = opts.attrs or {}, Parent = true }
    for k, v in pairs(opts) do if k ~= "attrs" then o[k] = v end end
    function o:IsA(c)
        if c == self.ClassName then return true end
        if c == "BasePart" then return self.ClassName == "Part" end
        if c == "GuiObject" then return self.ClassName == "TextLabel" or self.ClassName == "Frame" end
        return false
    end
    function o:add(kid) self.kids[kid.Name] = kid kid.Parent = self return kid end
    function o:remove(n) local k = self.kids[n] if k then k.Parent = nil end self.kids[n] = nil end
    function o:FindFirstChild(n) return self.kids[n] end
    function o:GetChildren()
        local out = {}
        for _, k in pairs(self.kids) do table.insert(out, k) end
        table.sort(out, function(a, b) return a.Name < b.Name end)
        return out
    end
    function o:FindFirstChildWhichIsA(c)
        for _, d in ipairs(self:GetChildren()) do if d:IsA(c) then return d end end
        return nil
    end
    function o:GetAttribute(n) return self.attrs[n] end
    function o:GetPivot() return { Position = self.Position } end
    return o
end

local workspace = inst("Workspace", "Workspace")
local LOCS = workspace:add(inst("_WorldOrigin", "Folder")):add(inst("Locations", "Folder"))
local MAP = workspace:add(inst("Map", "Folder"))
local RS = inst("ReplicatedStorage", "Folder")

-- ---------------------------------------------------------------- the player
local PG = inst("PlayerGui", "PlayerGui")
local TIMER = PG:add(inst("Main", "Frame")):add(inst("TopHUDList", "Frame")):add(inst("RaidTimer", "Frame", { Visible = false }))
local BP = inst("Backpack", "Backpack")
local CHAR = inst("Character", "Model")
local player = { Name = "Me", Character = CHAR }
function player:FindFirstChild(n)
    if n == "PlayerGui" then return PG end
    if n == "Backpack" then return BP end
    return nil
end
local ROOT = { Position = vec(0, 10, 0) }
local HUM = { Health = 100 }
local function parts() return CHAR, ROOT, HUM end

-- ---------------------------------------------------------------- the farm
local CFG = {
    RaidRadius = 450, RaidReach = 2500, RaidStuckSecs = 12, RaidStuckReach = 1500,
    RaidLoop = true, RaidChip = "Flame", RaidFruitMax = 200000, RandomRadius = 750, HeightSafe = 20,
}
local P = { randomSkip = {}, randomCant = 0, pileInPlace = false }
function P.isPhysicalFruit(t) return t:IsA("Tool") and string.find(t.Name, " Fruit$") ~= nil end
local stats = { kills = 0 }
local SEA = 3
local function mySea() return SEA end
local epoch = 1
local function stale(e) return e ~= epoch end
local SAYS, STATES, FLIGHTS = {}, {}, {}
local function say(s) table.insert(SAYS, s) end
local function setState(s) table.insert(STATES, s) end
local function flyTo(pos) table.insert(FLIGHTS, pos) ROOT.Position = pos return true end
local pileCur, activeName = nil, nil
local RELEASED = 0
local function releasePile() RELEASED += 1 pileCur = nil end

-- Enemies: { model, hum, root, name }. ENEMY(name, pos, hp).
local ENEMIES = {}
local function ENEMY(name, pos, hp)
    local m = inst(name, "Model")
    local root = m:add(inst("HumanoidRootPart", "Part", { Position = pos }))
    local e = { model = m, hum = { Health = hp or 1000 }, root = root, name = name }
    table.insert(ENEMIES, e)
    return e
end
local function liveEnemies(_)
    local out = {}
    for _, e in ipairs(ENEMIES) do
        if e.hum.Health > 0 and e.model.Parent then table.insert(out, e) end
    end
    return out
end
-- Random mode's builder, raid shape: every live one within `radius` of
-- `around`, skips left out (the real one adds the magnet's rules).
local function buildRandomPile(around, radius, _)
    local out = {}
    for _, e in ipairs(liveEnemies(nil)) do
        if (e.root.Position - around).Magnitude <= radius and not P.randomSkip[e.model] then table.insert(out, e) end
    end
    return out, out[1] and out[1].root.Position or nil, false
end
-- The fight: recorded; FIGHT_HOOK(cur) plays its loop (breakIf / pose).
local FIGHTS, FIGHT_HOOK = {}, nil
local function fight(cur, _)
    table.insert(FIGHTS, cur)
    pileCur = cur
    if FIGHT_HOOK then return FIGHT_HOOK(cur) end
    return "empty"
end

-- ---------------------------------------------------------------- the server
-- CommF_ calls recorded; SERVER[what](...) answers.
local CALLS, SERVER = {}, {}
local CF = { InvokeServer = function(_, what, ...)
    table.insert(CALLS, { what, ... })
    local f = SERVER[what]
    if f then return f(...) end
    return nil
end }
local function commF() return CF end
local NET = {}
local function netRemote(kind, name) return NET[kind .. "/" .. name] end
local CLICKS, ON_CLICK = 0, nil
local fireclickdetector = function(cd)
    CLICKS += 1
    if ON_CLICK then ON_CLICK(cd) end
end
local require = function(_) error("no such module here") end
