-- A fake world for the HALLOWEEN HUNT section: a clock with a queue, Roblox-ish
-- instances, pumpkins a server breaks after N hits, doors a server answers,
-- enemies, the item list.
local T = 1000
local SCHED = {}
local ERRORS = {}
local function runDue()
    local again = true
    while again do
        again = false
        for i, ev in ipairs(SCHED) do
            if ev.at <= T then
                table.remove(SCHED, i)
                local ok, err = pcall(ev.fn)
                if not ok then table.insert(ERRORS, tostring(err)) end
                again = true
                break
            end
        end
    end
end
local MIN, HOUR = 30, 15
local os = {
    clock = function() return T end,
    time = function() return math.floor(T) end,
    date = function(fmt)
        if fmt == "!*t" then return { min = MIN, hour = HOUR } end
        if fmt == "!%Y%m%d%H" then return "20261031" .. tostring(HOUR) end
        return "2026-10-31 " .. HOUR .. ":" .. MIN .. "Z"
    end,
}
local task = {}
function task.wait(s) T += (s or 0.03) runDue() return s end
function task.delay(s, fn, ...)
    local args = { ... }
    table.insert(SCHED, { at = T + (s or 0), fn = function() fn(table.unpack(args)) end })
end
function task.spawn(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then table.insert(ERRORS, tostring(err)) end
end

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

-- ---------- instances ----------
local ADDED = {}            -- workspace.DescendantAdded handlers
local function conn(list, h)
    table.insert(list, h)
    return { Disconnect = function()
        for i, x in ipairs(list) do if x == h then table.remove(list, i) break end end
    end }
end
local Inst = {}
Inst.__index = Inst
local BASEPART = { Part = true, MeshPart = true, UnionOperation = true }
local function new(class, name, props)
    local o = setmetatable({ ClassName = class, Name = name or class, kids = {}, attrs = {}, tags = {},
        Parent = nil }, Inst)
    if BASEPART[class] then
        o.Position, o.Size, o.Color, o.Transparency, o.Anchored = vec(0, 0, 0), vec(4, 4, 4), { R = 1, G = 0.5, B = 0 }, 0, true
    end
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end
function Inst:IsA(c)
    if c == self.ClassName then return true end
    if c == "BasePart" then return BASEPART[self.ClassName] == true end
    if c == "Instance" then return true end
    return false
end
function Inst:GetChildren() return table.clone(self.kids) end
function Inst:GetDescendants()
    local out = {}
    local function walk(x)
        for _, c in ipairs(x.kids) do table.insert(out, c) walk(c) end
    end
    walk(self)
    return out
end
function Inst:FindFirstChild(n)
    for _, c in ipairs(self.kids) do if c.Name == n then return c end end
    return nil
end
function Inst:FindFirstChildOfClass(cl)
    for _, c in ipairs(self.kids) do if c.ClassName == cl then return c end end
    return nil
end
function Inst:FindFirstChildWhichIsA(cl, deep)
    local list = deep and self:GetDescendants() or self.kids
    for _, c in ipairs(list) do if c:IsA(cl) then return c end end
    return nil
end
function Inst:IsDescendantOf(x)
    local p = self.Parent
    while p do
        if p == x then return true end
        p = p.Parent
    end
    return false
end
function Inst:GetAttribute(k) return self.attrs[k] end
function Inst:SetAttribute(k, v) self.attrs[k] = v end
function Inst:GetAttributes() return table.clone(self.attrs) end
function Inst:HasTag(t) return self.tags[t] == true end
function Inst:GetTags()
    local out = {}
    for t in pairs(self.tags) do table.insert(out, t) end
    return out
end
function Inst:GetFullName()
    local names, p = { self.Name }, self.Parent
    while p do table.insert(names, 1, p.Name) p = p.Parent end
    return table.concat(names, ".")
end
function Inst:GetPivot() return { Position = self.Position or vec(0, 0, 0) } end
local workspace
local function inWorkspace(o)
    local p = o
    while p do
        if p == workspace then return true end
        p = p.Parent
    end
    return false
end
function Inst:Add(child)
    child.Parent = self
    table.insert(self.kids, child)
    if inWorkspace(child) then
        local all = { child }
        for _, d in ipairs(child:GetDescendants()) do table.insert(all, d) end
        for _, d in ipairs(all) do
            for _, h in ipairs(table.clone(ADDED)) do h(d) end
        end
    end
    return child
end
function Inst:Destroy()
    local p = self.Parent
    if p then
        for i, c in ipairs(p.kids) do if c == self then table.remove(p.kids, i) break end end
    end
    self.Parent = nil
end

workspace = new("Workspace", "Workspace")
workspace.DescendantAdded = { Connect = function(_, h) return conn(ADDED, h) end }
workspace.CurrentCamera = nil
local MOON = false
workspace.attrs.HalloweenEventActive = false
function workspace:GetServerTimeNow() return T end
local MAP = workspace:Add(new("Folder", "Map"))
local CHARS = workspace:Add(new("Folder", "Characters"))
local ENEMIES = workspace:Add(new("Folder", "Enemies"))

-- ---------- CollectionService ----------
local CS = {}
function CS:GetTagged(tag)
    local out = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.tags[tag] then table.insert(out, d) end
    end
    return out
end
function CS:GetAllTags() return { "M1HitRegistry", "BasicMob" } end

-- ---------- the player ----------
local ROOT = { Position = vec(0, 50, 0) }
local player = { Name = "Me", Character = nil, UserId = 1 }
function player:FindFirstChild(_) return nil end
local Players = { LocalPlayer = player }
function Players:GetPlayers() return { player } end
local function parts() return {}, ROOT, {} end
local function healthPct() return 1 end
local epoch = 1
local function stale(e) return e ~= epoch end
local STATUS = { line = "", state = "IDLE" }
local function say(s) STATUS.line = s end
local function setState(s) STATUS.state = s end
local function releasePile() end
local LOG = { flights = {}, equips = {}, clicks = 0, ra = 0, rh = 0, fights = 0, fires = {}, invokes = 0,
    holds = 0, addIds = {} }
local function flyTo(goal, _) table.insert(LOG.flights, goal) ROOT.Position = goal end
local function lockAt(pos, _) ROOT.Position = pos end
local HELD = nil
local function heldTool() return HELD and { Name = HELD } or nil end
local function equip(name) table.insert(LOG.equips, name) HELD = name return true end
local TOOLS = { { Name = "Hallow Scythe", tip = "Sword" }, { Name = "Dragon Talon", tip = "Melee" } }
local function toolNames() return TOOLS end
local function toolType(t) return t.tip end
local CLICK_BREAKS = false
local PUMPKINS = {}         -- part -> { hp, way }
local function hitPumpkin(part, way)
    local pk = PUMPKINS[part]
    if not pk or pk.way ~= way or pk.hp <= 0 then return end
    pk.hp -= 1
    if pk.hp <= 0 then
        part.tags.M1HitRegistry = nil
        if pk.vanish then part.Parent.Transparency = 1 end
    end
end
local function pressM1()
    LOG.clicks += 1
    -- A real click: the game's own box hits a tagged part right in front of you.
    for part, pk in pairs(PUMPKINS) do
        if pk.way == "click" and (part.Position - ROOT.Position).Magnitude < 8 then hitPumpkin(part, "click") end
    end
end
local RA = { FireServer = function() LOG.ra += 1 end }
local RH = { FireServer = function(_, part)
    LOG.rh += 1
    if (part.Position - ROOT.Position).Magnitude < 10 then hitPumpkin(part, "remote") end
end }
local function netRemote(kind, name)
    if kind == "RE" and name == "RegisterAttack" then return RA end
    if kind == "RE" and name == "RegisterHit" then return RH end
    return nil
end

-- ---------- the enemies ----------
local stats = { kills = 0, m1 = 0 }
local activeName = nil
local function enemy(name, at, localEnemy)
    local m = ENEMIES:Add(new("Model", name))
    if localEnemy then m.attrs.LocalEnemy = localEnemy end
    m.hum = { Health = 100 }
    m.root = { Position = at }
    return m
end
local function liveEnemies(_)
    local out = {}
    for _, m in ipairs(ENEMIES.kids) do
        if m.hum.Health > 0 then table.insert(out, { model = m, hum = m.hum, root = m.root, name = m.Name }) end
    end
    return out
end
local function fight(cur, _)
    LOG.fights += 1
    LOG.lastFight = cur.name
    for _ = 1, 20 do
        local list = cur.build()
        if #list == 0 then return "empty" end
        list[1].hum.Health = 0
        stats.kills += 1
        T += 0.5
    end
    return "sweep"
end

-- ---------- the remotes ----------
local CLIENT = {}            -- HalloweenEvent.OnClientEvent handlers
local function fireClient(...)
    for _, h in ipairs(table.clone(CLIENT)) do h(...) end
end
local SERVER = { treat = "rip_indra" }
local HEV = new("RemoteEvent", "HalloweenEvent")
HEV.OnClientEvent = { Connect = function(_, h) return conn(CLIENT, h) end }
function HEV:FireServer(what)
    table.insert(LOG.fires, what)
    if what == "AcceptReward" and SERVER.open then
        local d = SERVER.open
        SERVER.open = nil
        task.delay(3, function()
            d.attrs.DoorOpen = false
            d.attrs.CooldownUntil = T + 300
            fireClient("EventFinished", d)
        end)
    end
end
local HFN = new("RemoteFunction", "HalloweenFunction")
local function serverKnock(d)
    if d.attrs.DoorOpen or (d.attrs.CooldownUntil or 0) > T then return false end
    d.attrs.DoorOpen = true
    SERVER.open = d
    fireClient("DoorOpened", d, player, { Event = SERVER.treat, Scene = "Mansion" })
    return true
end
function HFN:InvokeServer(d)
    LOG.invokes += 1
    return serverKnock(d)
end
local REMOTES = new("Folder", "Remotes")
REMOTES:Add(HEV)
REMOTES:Add(HFN)
local RAW = {
    { Id = { Type = "Material", StorageKey = "Candy Corn", ItemId = 832 } },
    { Id = { Type = "Material", StorageKey = "Spooky Token", ItemId = 1599 } },
    { Id = { Type = "Potion", StorageKey = "Spooky Potion", ItemId = 1607 } },
    { Id = { Type = "Fruit", StorageKey = "Quake-Quake", ItemId = 3 } },
}
local RAWSOURCE = { tag = "RawSource" }
local function require(m)
    if m == RAWSOURCE then return RAW end
    error("require of an unknown module")
end
local RS = { Economy = { ItemId = { RawSource = RAWSOURCE } } }
function RS:FindFirstChild(n)
    if n == "Remotes" then return REMOTES end
    return nil
end
local game = { PlaceId = 7449423635 }
local REPFIRST = new("Folder", "ReplicatedFirst")
function game:GetService(n)
    if n == "CollectionService" then return CS end
    if n == "ReplicatedFirst" then return REPFIRST end
    return { JSONEncode = function() return "{}" end, JSONDecode = function() return {} end }
end
local _G = { BFF = nil }
local writefile, readfile, isfile, makefolder, isfolder = nil, nil, nil, nil, nil
local getscriptbytecode, decompile, fireproximityprompt, fireclickdetector = nil, nil, nil, nil

-- ---------- the farm ----------
local CFG = { Hunt = true, HuntKind = "halloween", M1Weapon = "", EscapeBelow = 0.35,
    HalloweenPumpkins = true, HalloweenSkipGray = true, HalloweenDoors = true, HalloweenBoss = true,
    HalloweenReturn = true, HalloweenTour = true }
local HAVE = { ["Spooky Token"] = 40 }
local P = { running = true, build = "test" }
P.sea = {
    addIds = function(name, ids) LOG.addIds[name] = ids end,
    have = function(names, _)
        local out = {}
        for _, n in ipairs(names) do out[n] = HAVE[n] or 0 end
        return out
    end,
}
local function mySea() return 3 end
local LEVELS = {
    { 1500, 1524, "Pirate Millionaire", vec(-290, 43, 5580) },
    { 1525, 1574, "Pistol Billionaire", vec(-190, 86, 6018) },       -- same island
    { 1575, 1599, "Dragon Crew Warrior", vec(6241, 51, -1243) },
    { 1600, 1624, "Fishman Raider", vec(-10407, 331, -8368) },
    { 1625, 1649, "Sunken Vessel", vec(9000, -500, 9000) },           -- the sea floor
    { 700, 724, "Raider", vec(-728, 52, 2345) },                      -- Second Sea
}
local function seaOfLevel(lv) return lv >= 1500 and 3 or 2 end

-- Builders for the cases.
local function pumpkin(name, at, opts)
    opts = opts or {}
    local m = new("Model", name)
    local body = new("Part", opts.partName or "Body", { Position = at, Color = opts.color or { R = 1, G = 0.5, B = 0 } })
    m:Add(body)
    if opts.tagged ~= false then body.tags.M1HitRegistry = true end
    PUMPKINS[body] = { hp = opts.hp or 3, way = opts.way or "remote", vanish = opts.vanish }
    MAP:Add(m)
    return m, body
end
local function door(at)
    local d = new("Model", "HalloweenDoor")
    local prox = new("Part", "Proximity", { Position = at })
    local pr = new("ProximityPrompt", "ProximityPrompt", { Enabled = true, HoldDuration = 0 })
    function pr:InputHoldBegin() LOG.holds += 1 end
    function pr:InputHoldEnd()
        -- The game's own Triggered handler: 1.2 s, then the server.
        task.delay(1.2, function() serverKnock(d) end)
    end
    prox:Add(pr)
    d:Add(prox)
    d:Add(new("Part", "Part", { Position = at }))
    MAP:Add(d)
    return d
end
