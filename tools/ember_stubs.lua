-- A fake Dragon Hunter server, island and clock for the EMBER HUNT section.
local T = 1000
local os = { clock = function() return T end }
local task = { wait = function(s) T += (s or 0.03) end }
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
V.__mul = function(a, b) return vec(a.X * b, a.Y * b, a.Z * b) end
local Vector3 = { new = vec }

-- The server: what Check says, whether RequestQuest works from afar.
local SERVER = { text = nil, remoteOk = true, eligible = true, next = "Defeat 3 Hydra Enforcers",
    requests = 0, nearHunter = false, fakeRemote = false }
local ROOT = { Position = vec(0, 0, 0) }
local HUNTER = vec(5864, 1209, 810)
local function nearHunter() return (ROOT.Position - HUNTER).Magnitude < 20 end
local RF = {}
function RF:InvokeServer(arg)
    if arg.Context == "Check" then
        if SERVER.text then return { Text = SERVER.text } end
        return {}
    end
    SERVER.requests += 1
    if not SERVER.eligible then return nil end
    if SERVER.fakeRemote and not nearHunter() then return nil end     -- says nothing, changes nothing
    if SERVER.remoteOk or nearHunter() then SERVER.text = SERVER.next end
    return nil
end
local function netRemote(kind, name) return (kind == "RF" and name == "DragonHunter") and RF or nil end
local function commF() return nil end

-- The notification on screen.
local NOTE = { list = {} }
local function label(text)
    return { Text = text, IsA = function(_, c) return c == "TextLabel" end }
end
local player = { PlayerGui = { FindFirstChild = function(_, n)
    if n == "Notifications" then return { GetDescendants = function() return NOTE.list end } end
    return nil
end } }

-- Embers lying in the world.
local EMBERS = {}
-- Hydra Island: a Map.Waterfall with tree models (made by the cases).
local function inst(name, class, kids)
    local o = { Name = name, ClassName = class, kids = kids or {}, Parent = true }
    function o:IsA(c) return c == class or (c == "BasePart" and class == "Part") end
    function o:GetChildren() return self.kids end
    function o:GetDescendants()
        local out = {}
        local function walk(x)
            for _, k in ipairs(x.kids) do
                table.insert(out, k)
                walk(k)
            end
        end
        walk(self)
        return out
    end
    function o:FindFirstChild(n)
        for _, k in ipairs(self.kids) do if k.Name == n then return k end end
        return nil
    end
    for _, k in ipairs(o.kids) do k.Parent = o end
    return o
end
local function treePart(name, pos, h)
    local part = inst(name, "Part")
    part.Position, part.Size, part.Anchored, part.Transparency = pos, vec(4, h, 4), true, 0
    return part
end
local function treeModel(name, part, h)
    local m = inst(name, "Model", { part })
    function m:GetExtentsSize() return vec(10, h, 10) end
    return m
end
local ISLE = inst("Waterfall", "Model", {})
local MAP = inst("Map", "Model", { ISLE })
local workspace = {
    GetChildren = function() return EMBERS end,
    FindFirstChild = function(_, n) return n == "Map" and MAP or nil end,
}
local RS = { FindFirstChild = function() return nil end }
local function ember(pos)
    local part = { Position = pos, Parent = true, IsA = function(_, c) return c == "BasePart" end }
    local m = { Name = "EmberTemplate", Parent = true, part = part }
    m.FindFirstChild = function(_, n) return n == "Part" and part or nil end
    return m
end

local CFG = { Hunt = true, HuntKind = "ember", HeightSafe = 20, EmberStopAt = 99 }
local stats = { kills = 0 }
local activeName = nil
local FLIGHTS, FIGHTS, LOCKS = {}, {}, 0
local STOPPED = nil
local P = {}
function P.stop(why) STOPPED = why end
local function mySea() return 3 end
local function parts() return nil, ROOT end
local function flyTo(pos) table.insert(FLIGHTS, pos) ROOT.Position = pos end
local function lockAt(pos)
    LOCKS += 1
    -- Standing on an ember takes it.
    for i = #EMBERS, 1, -1 do
        local e = EMBERS[i]
        if (e.part.Position - pos).Magnitude < 1 then
            e.Parent, e.part.Parent = nil, nil
            table.remove(EMBERS, i)
        end
    end
end
local function stale() return false end
local function releasePile() end
local function setState() end
local function say() end
local function nearestLoaded() return { root = { Position = vec(4620, 1002, 399) } } end
local function campOf(_, fallback) return fallback end
local function fight(cur, names)
    table.insert(FIGHTS, cur.name)
    stats.kills += 1
    return "empty"
end
local writefile = nil
-- The cast: breaks (unanchors) what BREAKS lists; counts every cast.
local BREAKS, CASTS = {}, {}
P.sea = { castAt = function(v)
    table.insert(CASTS, v.part.Name)
    if BREAKS[v.part.Name] then v.part.Anchored = false end
    return "Fruit Z", not v.alive()
end }
