-- What the Fire Flower hunt touches, faked: the FireFlowers folder and the
-- flowers in it, their prompt, the inventory, the clock, the kill counter,
-- the camps and the fight. The game's server is modelled the way it CAN
-- check a prompt:
--   HOLD_OK  a real hold (InputHoldBegin, the prompt's HoldDuration,
--            InputHoldEnd) picks the flower
--   FIRE_OK  the executor's instant fireproximityprompt picks it
-- HAVE = your Fire Flowers; READABLE = the inventory answers; LATE = the
-- count goes up this long after the flower leaves the folder.
local CLOCK = 0
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local PENDING = nil              -- { at, n }: an inventory update on its way
local task = { wait = function(s)
    CLOCK += (s or 0.03)
end }
local epoch = 0
local function stale(e) return e ~= epoch end

local V = {}
V.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, V) end
V.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }, V) end
local Vector3 = { new = function(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end }

local CFG, stats, E, P, LOG, PRINTED
local HAVE, READABLE, LATE, HOLD_OK, FIRE_OK, SEA, LOADED, FIGHTS, FOLDER, NOFIRE
local activeName
local pileCentre, pileFor = nil, nil
local function log(s) table.insert(LOG, s) end
local function say() end
local function setState() end
local function releasePile() end
local function lockAt() end
local function notify(s) log("notify " .. s) end
local realPrint = print
local print = function(s) table.insert(PRINTED, s) end
local function flyTo(_, opts) log("fly " .. tostring(opts and opts.stream or "flower")) end
local function mySea() return SEA end

local function haveNow()
    if PENDING and CLOCK >= PENDING.at then
        HAVE += PENDING.n
        PENDING = nil
    end
    return HAVE
end
local function commF()
    return { InvokeServer = function(_, what)
        if what == "getInventory" and READABLE then
            return { { Name = "Bones", Count = 9 }, { Name = "Fire Flower", Count = haveNow() } }
        end
        return nil
    end }
end

local workspace = { FindFirstChild = function(_, n) if n == "FireFlowers" then return FOLDER end end }
local function parts() return {}, { Position = Vector3.new(0, 0, 0) }, {} end
local function nearestLoaded(n) return LOADED[n] end
local ROWS = {
    ["Forest Pirate"]       = { 1825, 1849, "Forest Pirate", Vector3.new(-13225.8, 428.2, -7753.1) },
    ["Mythological Pirate"] = { 1850, 1899, "Mythological Pirate", Vector3.new(-13869.2, 565.0, -7084.4) },
}
local function rowOf(n) return ROWS[n] end
local function campOf(_, fallback) return fallback, "table" end
local function homeOf(e) return e.root.Position end
local FIGHT_HOOK
local function fight(cur, names)
    table.insert(FIGHTS, { cur = cur, names = names })
    log("fight " .. cur.name)
    if FIGHT_HOOK then FIGHT_HOOK(cur) end
    return "sweep"
end

local fireproximityprompt

-- A flower model in the folder. opts.part: "primary" | "nested" | "none";
-- opts.prompt: false = no prompt in it.
local function addFlower(pos, opts)
    opts = opts or {}
    local m = { Parent = true }
    local part = { Position = pos }
    function part:IsA(c) return c == "BasePart" or c == "MeshPart" end
    function m:IsA(c) return c == "Model" end
    if opts.part ~= "nested" and opts.part ~= "none" then m.PrimaryPart = part end
    function m:FindFirstChildWhichIsA(c, recursive)
        if opts.part == "none" then return nil end
        if c == "BasePart" and (recursive or opts.part ~= "nested") then return part end
        return nil
    end
    local function picked()
        if not m.Parent then return end
        m.Parent = nil
        for i, x in ipairs(FOLDER.kids) do
            if x == m then table.remove(FOLDER.kids, i) break end
        end
        if LATE then PENDING = { at = CLOCK + LATE, n = 1 } else HAVE += 1 end
    end
    local prompt = { HoldDuration = 1, Parent = m }
    function prompt:IsA(c) return c == "ProximityPrompt" end
    function prompt:InputHoldBegin() self.began = CLOCK end
    function prompt:InputHoldEnd()
        if HOLD_OK and self.began and CLOCK - self.began >= self.HoldDuration then picked() end
        self.began = nil
    end
    function m:GetDescendants() return (opts.prompt == false) and {} or { prompt } end
    m.pick = picked
    table.insert(FOLDER.kids, m)
    return m
end

local function reset(opts)
    opts = opts or {}
    CLOCK, epoch, PENDING = 0, 0, nil
    CFG = { HuntHop = true, FlowerGiveUp = 2, HeightSafe = 20 }
    stats = { kills = 0 }
    E = { tally = {}, flowerSkip = {}, flowerTries = {}, flowerNote = "", note = "" }
    E.flowerKills0 = 0
    LOG, PRINTED, FIGHTS = {}, {}, {}
    P = { stop = function(why) log("stop " .. tostring(why)) end }
    HAVE, READABLE, LATE = 2, opts.readable ~= false, opts.late
    HOLD_OK, FIRE_OK = opts.hold ~= false, opts.fire == true
    SEA = opts.sea or 3
    LOADED = {}
    FIGHT_HOOK = nil
    activeName = nil
    FOLDER = { kids = {} }
    function FOLDER:GetChildren() return table.clone(self.kids) end
    if opts.noFolder then FOLDER = nil end
    fireproximityprompt = (opts.noFire ~= true) and function(pr)
        if FIRE_OK then pr.Parent.pick() end
    end or nil
end
reset()
