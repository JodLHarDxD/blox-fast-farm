-- A fake world for the HALLOWEEN HUNT section: a clock with a queue, Roblox-ish
-- instances with signals, the game's PumpkinHunt (a pumpkin's state flipped by
-- a server after N hits), the Map's big decorations, doors a server answers,
-- enemies, the item list and its pushes.
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

-- ---------- signals + instances ----------
local function conn(list, h)
    table.insert(list, h)
    return { Disconnect = function()
        for i, x in ipairs(list) do if x == h then table.remove(list, i) break end end
    end }
end
local function signal()
    local sg = { list = {} }
    function sg:Connect(h) return conn(self.list, h) end
    function sg:Fire(...) for _, h in ipairs(table.clone(self.list)) do h(...) end end
    return sg
end
local SIGNALS = { AttributeChanged = true, ChildAdded = true, ChildRemoved = true, DescendantAdded = true,
    DescendantRemoving = true }
local Inst = {}
Inst.__index = function(o, k)
    local m = Inst[k]
    if m ~= nil then return m end
    if SIGNALS[k] then
        local sg = signal()
        rawset(o, k, sg)
        return sg
    end
    return nil
end
local BASEPART = { Part = true, MeshPart = true, UnionOperation = true }
local function new(class, name, props)
    local o = setmetatable({ ClassName = class, Name = name or class, kids = {}, attrs = {}, tags = {} }, Inst)
    if BASEPART[class] then
        o.Position, o.Size, o.Color, o.Transparency, o.Anchored = vec(0, 0, 0), vec(2, 2, 2), { R = 1, G = 0.5, B = 0 }, 0, false
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
function Inst:FindFirstAncestorOfClass(cl)
    local p = rawget(self, "Parent")
    while p do
        if p.ClassName == cl then return p end
        p = rawget(p, "Parent")
    end
    return nil
end
function Inst:IsDescendantOf(x)
    local p = rawget(self, "Parent")
    while p do
        if p == x then return true end
        p = rawget(p, "Parent")
    end
    return false
end
function Inst:GetAttribute(k) return self.attrs[k] end
function Inst:SetAttribute(k, v)
    self.attrs[k] = v
    local sg = rawget(self, "AttributeChanged")
    if sg then sg:Fire(k) end
end
function Inst:GetAttributes() return table.clone(self.attrs) end
function Inst:HasTag(t) return self.tags[t] == true end
function Inst:GetTags()
    local out = {}
    for t in pairs(self.tags) do table.insert(out, t) end
    return out
end
function Inst:GetFullName()
    local names, p = { self.Name }, rawget(self, "Parent")
    while p do table.insert(names, 1, p.Name) p = rawget(p, "Parent") end
    return table.concat(names, ".")
end
function Inst:GetPivot() return { Position = rawget(self, "Position") or vec(0, 0, 0) } end
local workspace
local ADDED = {}            -- workspace.DescendantAdded handlers (the door index)
local function inWorkspace(o)
    local p = o
    while p do
        if p == workspace then return true end
        p = rawget(p, "Parent")
    end
    return false
end
function Inst:Add(child)
    child.Parent = self
    table.insert(self.kids, child)
    local sg = rawget(self, "ChildAdded")
    if sg then sg:Fire(child) end
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
    local p = rawget(self, "Parent")
    if p then
        local a = p
        while a do
            local sg = rawget(a, "DescendantRemoving")
            if sg then sg:Fire(self) end
            a = rawget(a, "Parent")
        end
        for i, c in ipairs(p.kids) do if c == self then table.remove(p.kids, i) break end end
        local sg = rawget(p, "ChildRemoved")
        if sg then sg:Fire(self) end
    end
    self.Parent = nil
end

workspace = new("Workspace", "Workspace")
workspace.DescendantAdded = { Connect = function(_, h) return conn(ADDED, h) end }
workspace.CurrentCamera = nil
workspace.attrs.HalloweenEventActive = false
function workspace:GetServerTimeNow() return T end
local MAP = workspace:Add(new("Folder", "Map"))
local CHARS = workspace:Add(new("Folder", "Characters"))
local ENEMIES = workspace:Add(new("Folder", "Enemies"))
local HUNT = workspace:Add(new("Folder", "PumpkinHunt"))

-- ---------- CollectionService ----------
local TAG_OFF = signal()
local CS = {}
function CS:GetTagged(tag)
    local out = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.tags[tag] then table.insert(out, d) end
    end
    return out
end
function CS:GetAllTags() return { "M1HitRegistry", "BasicMob" } end
function CS:GetInstanceRemovedSignal(_) return TAG_OFF end

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
    holds = 0, addIds = {}, files = {} }
local function flyTo(goal, _) table.insert(LOG.flights, goal) ROOT.Position = goal end
local function lockAt(pos, _) ROOT.Position = pos end
local HELD = nil
local function heldTool() return HELD and { Name = HELD } or nil end
local function equip(name) table.insert(LOG.equips, name) HELD = name return true end
local TOOLS = { { Name = "Hallow Scythe", tip = "Sword" }, { Name = "Dragon Talon", tip = "Melee" } }
local function toolNames() return TOOLS end
local function toolType(t) return t.tip end

-- ---------- the pumpkin server ----------
-- model -> { hp, way, blink, rare }: each hit takes 1; at 0 PumpkinState goes "Smashed".
-- blink = every hit flips it "Hit" and back to "Idle" 0.5 s later.
-- rare = at 0 it goes "Summoning" with 3 more hits in it (still tagged), then
-- its tags come off and it is "Burst".
local PUMPKINS = {}
local function hitPumpkin(part, way)
    local m = rawget(part, "Parent")
    local pk = m and PUMPKINS[m]
    local st = m and m:GetAttribute("PumpkinState")
    if not pk or pk.way ~= way or pk.hp <= 0 or (st ~= "Idle" and not (pk.rare and st == "Summoning")) then return end
    pk.hp -= 1
    if pk.hp <= 0 and pk.rare and st == "Idle" then
        pk.hp = 3
        m:SetAttribute("PumpkinState", "Summoning")
    elseif pk.hp <= 0 and pk.rare then
        for _, d in ipairs(m:GetDescendants()) do d.tags.M1HitRegistry = nil end
        m:SetAttribute("PumpkinState", "Burst")
    elseif pk.hp <= 0 then
        m:SetAttribute("PumpkinState", "Smashed")
    elseif pk.blink then
        m:SetAttribute("PumpkinState", "Hit")
        task.delay(0.5, function() m:SetAttribute("PumpkinState", "Idle") end)
    end
end
local function pressM1()
    LOG.clicks += 1
    -- A real click: the game's own box hits the tagged parts right in front of you.
    for m, pk in pairs(PUMPKINS) do
        if pk.way == "click" then
            for _, p in ipairs(m:GetDescendants()) do
                if p.tags.M1HitRegistry and (p.Position - ROOT.Position).Magnitude < 8 then hitPumpkin(p, "click") break end
            end
        end
    end
end
local RA = { FireServer = function() LOG.ra += 1 end }
local RH = { FireServer = function(_, part)
    LOG.rh += 1
    if (part.Position - ROOT.Position).Magnitude < 10 then hitPumpkin(part, "remote") end
end }
local ITEMPUSH = new("RemoteEvent", "RE/OnItemValueChanged")
ITEMPUSH.OnClientEvent = signal()
local function netRemote(kind, name)
    if kind == "RE" and name == "RegisterAttack" then return RA end
    if kind == "RE" and name == "RegisterHit" then return RH end
    if kind == "RE" and name == "OnItemValueChanged" then return ITEMPUSH end
    return nil
end

-- ---------- the enemies ----------
local stats = { kills = 0, m1 = 0 }
local activeName = nil
local function enemy(name, at, localEnemy)
    local m = new("Model", name)
    if localEnemy then m.attrs.LocalEnemy = localEnemy end
    m.hum = { Health = 100 }
    m.root = { Position = at }
    m:Add(new("Part", "HumanoidRootPart", { Position = at }))
    ENEMIES:Add(m)
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
    { Id = { Type = "Material", StorageKey = "Pumpkin Bits", ItemId = 1607 } },
    { Id = { Type = "Material", StorageKey = "Cursed Pumpkin Seed", ItemId = 1608 } },
    { Id = { Type = "Potion", StorageKey = "Poltergeist Potion", ItemId = 1599 } },
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
local function typeof(x)
    if type(x) == "table" and getmetatable(x) == Inst then return "Instance" end
    return type(x)
end
local function writefile(name, text) LOG.files[name] = text end
local readfile, isfile, makefolder, isfolder = nil, nil, nil, nil
local getscriptbytecode, decompile, fireproximityprompt, fireclickdetector = nil, nil, nil, nil

-- ---------- the farm ----------
local CFG = { Hunt = true, HuntKind = "halloween", M1Weapon = "", EscapeBelow = 0.35,
    HalloweenPumpkins = true, HalloweenRareFirst = true, HalloweenDoors = true, HalloweenBoss = true,
    HalloweenReturn = true, HalloweenTour = true, HalloweenWatch = false }
local HAVE = { ["Cursed Pumpkin Seed"] = 12, ["Candy Corn"] = 81, ["Pumpkin Bits"] = 3 }
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

-- Builders for the cases.
-- The game's pumpkin: Model "Pumpkin" in PumpkinHunt, PumpkinState Idle, an
-- invisible grey 0.1-stud RootPart (tagged) + visible orange MeshParts (tagged).
local function pumpkin(at, opts)
    opts = opts or {}
    local look = opts.look or "pumpkinv1"
    local m = new("Model", "Pumpkin")
    m.attrs.PumpkinState = opts.state or "Idle"
    if opts.rare then m.attrs.PumpkinRare = true end
    local root = new("Part", "RootPart", { Position = at, Size = vec(0.1, 0.1, 0.1), Transparency = 1,
        Color = { R = 0.64, G = 0.64, B = 0.65 }, Anchored = true })
    root.tags.M1HitRegistry = true
    m:Add(root)
    m.PrimaryPart = root
    local body = new("MeshPart", look .. ".006", { Position = at, Size = vec(1.8, 2.6, 1.8),
        Color = opts.color or { R = 0.91, G = 0.45, B = 0.14 } })
    body.tags.M1HitRegistry = true
    m:Add(body)
    local stem = new("MeshPart", look .. ".007", { Position = at + vec(0, 1.3, 0), Size = vec(0.3, 0.3, 0.4),
        Color = { R = 0.27, G = 0.19, B = 0.12 } })
    stem.tags.M1HitRegistry = true
    m:Add(stem)
    PUMPKINS[m] = { hp = opts.hp or 3, way = opts.way or "remote", blink = opts.blink, rare = opts.rare }
    HUNT:Add(m)
    return m, body
end
-- The Map's own big untagged pumpkin (the Turtle's HalloweenHotel).
local function decoration(at)
    local d = new("Model", "pumpkin2")
    d:Add(new("MeshPart", "pumpkinprop.003", { Position = at, Size = vec(7.8, 4.2, 7.8), Anchored = true }))
    MAP:Add(d)
    return d
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
