-- A fake Third Sea for ROUTES. The body is at POS (root.CFrame = x moves it);
-- task.wait moves the clock NOW and fires what was waiting for it (the Home
-- countdown, a server pull-back). Pads: TAGGED models (Hitbox, Pivot); the
-- game's remotes: CommF_ TeleportToSpawn, Net RF BoatCastleTeleporters.
local V = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V.__index = function(t, k)
    if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z) end
    return nil
end
local Vector3 = { new = function(x, y, z) return v3(x or 0, y or 0, z or 0) end }
local CFrame = { new = function(p) return { __cf = true, Position = p } end }
local realTypeof = typeof
local function typeof(x)
    if type(x) == "table" and x.__cf then return "CFrame" end
    if type(x) == "table" and getmetatable(x) == V then return "Vector3" end
    return realTypeof(x)
end

local P = {}
local CFG = { TravelSpeed = 300, TravelHome = true }
local NOW = 1000
local os = { clock = function() return NOW end, time = function() return NOW end }
local epoch = 0
local function stale(e) return e ~= epoch end
local SEA = 3
local function mySea() return SEA end
local function say() end
local SAID = {}
local realPrint = print
local function print(s) table.insert(SAID, tostring(s)) end

-- the body
local POS = v3(0, 0, 0)
local CF_WRITES = 0
local root = setmetatable({}, {
    __index = function(_, k) if k == "Position" then return POS end return nil end,
    __newindex = function(_, k, v) if k == "CFrame" then POS = v.Position CF_WRITES += 1 end end,
})
local function parts() return {}, root, {} end
local FLIGHTS, LOCKS = {}, {}
local function flyTo(goal) table.insert(FLIGHTS, goal) POS = goal return true end
local function lockAt(p) table.insert(LOCKS, p) end

-- the clock's waiting things
local HOME_AT, HOME_LAND, PULL_TO = nil, nil, nil
local task = {
    wait = function(s)
        NOW += (s or 0.03)
        if HOME_AT and NOW >= HOME_AT then POS, HOME_AT = HOME_LAND, nil end
        if PULL_TO and NOW >= PULL_TO.at then POS, PULL_TO = PULL_TO.pos, nil end
    end,
    spawn = function(f, ...) f(...) end,
}

-- your Home Point and the world's spawns
local SPAWN_NAME, SAFE = "Castle on the Sea", false
local SPAWNS = {}               -- [name] = position of its spawn model in this sea
local player = { UserId = 9 }
player.Data = setmetatable({}, { __index = function(_, k)
    if k == "SpawnPoint" then
        if SPAWN_NAME == nil then error("no SpawnPoint") end
        return { Value = SPAWN_NAME }
    end
    return nil
end })
function player:GetAttribute(n) if n == "InSafeZone" then return SAFE end return nil end
local workspace = { _WorldOrigin = { PlayerSpawns = {
    FindFirstChild = function(_, team)
        if team ~= "Pirates" then return nil end
        return { FindFirstChild = function(_, name)
            local p = SPAWNS[name]
            return p and { GetPivot = function() return { Position = p } end } or nil
        end }
    end,
} } }

-- the pads
local TAGGED = {}
local function pad(name, x, y, z, px, py, pz)
    local hb = { Position = v3(x, y, z) }
    function hb:IsA(c) return c == "BasePart" or c == "Part" end
    local m = { Name = name, Parent = workspace, hb = hb, attrs = { Pivot = CFrame.new(v3(px, py, pz)) } }
    hb.Parent = m
    function m:IsA(c) return c == "Model" end
    function m:FindFirstChild(n) return n == "Hitbox" and self.hb or nil end
    function m:GetAttribute(n) return self.attrs[n] end
    return m
end
local CS = { GetTagged = function(_, tag) return tag == "BoatCastleTeleporter" and TAGGED or {} end }

-- the remotes
local HOME_WORKS, HOME_DELAY = true, 5
local LOCKED, TOUCH_WORKS, MIMIC_WORKS, PULL_BACK, PULL_DELAY = {}, true, true, false, 0.3
local CALLS = {}
local function partnerPivot(m)
    for _, q in ipairs(TAGGED) do
        if q ~= m and q.Name == m.Name then return q.attrs.Pivot.Position end
    end
    return nil
end
local function commF()
    return { InvokeServer = function(_, what)
        table.insert(CALLS, what)
        if what == "TeleportToSpawn" and HOME_WORKS then
            HOME_AT, HOME_LAND = NOW + HOME_DELAY, SPAWNS[SPAWN_NAME] + v3(0, 5, 0)
        end
        return nil
    end }
end
local RF = { InvokeServer = function(_, what, arg)
    table.insert(CALLS, what .. " " .. tostring(type(arg) == "table" and arg.Name or arg))
    if what == "GetInfo" then return { isUnlocked = not LOCKED[arg] } end
    if what == "InitiateTeleport" then
        if PULL_BACK then PULL_TO = { at = NOW + PULL_DELAY, pos = arg.hb.Position } end
        return MIMIC_WORKS
    end
    return nil
end }
local function netRemote(kind, name) return (kind == "RF" and name == "BoatCastleTeleporters") and RF or nil end
local TOUCHES = 0
local function firetouchinterest(_, hb, state)
    if state ~= 0 then return end
    TOUCHES += 1
    if TOUCH_WORKS then
        local p = partnerPivot(hb.Parent)
        if p then POS = p end
    end
end

-- the executor's files
local FILES = {}
local function copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copy(v) end
    return o
end
local function readfile(n) if FILES[n] == nil then error("no file") end return n end
local function writefile(n, s) FILES[n] = s end
local HttpService = { JSONEncode = function(_, t) return copy(t) end, JSONDecode = function(_, s) return copy(FILES[s]) end }
local game = { GetService = function(_, n)
    if n == "HttpService" then return HttpService end
    if n == "CollectionService" then return CS end
    return nil
end }

-- the Third Sea, roughly: the Castle on the Sea's three pads, their partners
local CASTLE_HYDRA = pad("HydraTP", -5090, 315, -3130, -5085, 316, -3125)
local CASTLE_MANSION = pad("MansionTP", -5070, 315, -3140, -5066, 316, -3136)
local CASTLE_TIKI = pad("TikiTP", -5050, 315, -3150, -5046, 316, -3146)
local HYDRA = pad("HydraTP", 5661, 1013, -335, 5655, 1014, -330)
local MANSION = pad("MansionTP", -12471, 375, -7551, -12465, 376, -7545)
local TIKI = pad("TikiTP", -16200, 20, 500, -16190, 21, 505)
SPAWNS["Castle on the Sea"] = v3(-5000, 320, -3000)
