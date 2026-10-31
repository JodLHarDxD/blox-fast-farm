-- What the panel needs from Roblox and from the rest of fast_farm, faked.
-- Instances keep their properties, children and signals; a tween sets its
-- end values at once; task.delay runs at once; task.spawn is kept (the live
-- loop) and run by the cases one pass at a time. CFG is the REAL config table
-- (cut out of fast_farm.lua by panel_test.py) behind a proxy that logs every
-- write with the control that made it.

-- ---------- signals and instances ----------
local function signal()
    local s = { fns = {} }
    function s:Connect(f)
        table.insert(self.fns, f)
        return { Disconnect = function() end }
    end
    function s:Fire(...)
        for _, f in ipairs(self.fns) do f(...) end
    end
    return s
end

local SIGNALS = {
    Activated = true, MouseButton1Down = true, MouseButton1Up = true, MouseLeave = true,
    InputBegan = true, InputEnded = true, FocusLost = true, InputChanged = true,
    RenderStepped = true, Heartbeat = true, Stepped = true,
}
local GUI = { Frame = true, TextLabel = true, TextButton = true, TextBox = true,
    ScrollingFrame = true, ImageLabel = true }
local ALL = {}

local function newInst(class)
    local o = { _props = { ClassName = class, Name = class, Visible = true }, _kids = {}, _sig = {} }
    local api = {}
    function api:IsA(c)
        return class == c or (c == "GuiObject" and GUI[class] == true)
    end
    function api:Destroy()
        local p = o._props.Parent
        if p then
            local kids = rawget(p, "_kids")
            for i, k in ipairs(kids) do
                if k == o then table.remove(kids, i) break end
            end
        end
        o._props.Parent = nil
        o._destroyed = true
    end
    function api:GetChildren()
        local out = {}
        for _, k in ipairs(o._kids) do table.insert(out, k) end
        return out
    end
    function api:FindFirstChild(n)
        for _, k in ipairs(o._kids) do
            if k.Name == n then return k end
        end
        return nil
    end
    function api:WaitForChild(n) return api.FindFirstChild(o, n) end
    setmetatable(o, {
        __index = function(_, k)
            if api[k] then return api[k] end
            if SIGNALS[k] then
                o._sig[k] = o._sig[k] or signal()
                return o._sig[k]
            end
            if k == "TextBounds" then return { X = 100, Y = 14 } end
            if k == "AbsolutePosition" then return { X = 0, Y = 0 } end
            if k == "AbsoluteSize" then return { X = 300, Y = 20 } end
            return o._props[k]
        end,
        __newindex = function(t, k, v)
            if k == "Parent" then
                local old = o._props.Parent
                if old then
                    local kids = rawget(old, "_kids")
                    for i, c in ipairs(kids) do
                        if c == t then table.remove(kids, i) break end
                    end
                end
                if v then table.insert(rawget(v, "_kids"), t) end
            end
            o._props[k] = v
        end,
    })
    table.insert(ALL, o)
    return o
end

local Instance = { new = newInst }

local function enumNode(path)
    return setmetatable({ _path = path }, {
        __index = function(t, k)
            local c = enumNode(path .. "." .. k)
            rawset(t, k, c)
            return c
        end,
        __tostring = function() return path end,
    })
end
local Enum = enumNode("Enum")

local UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
    return { X = { Scale = xs or 0, Offset = xo or 0 }, Y = { Scale = ys or 0, Offset = yo or 0 } }
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end }
local TweenInfo = { new = function() return {} end }
local TweenService = {}
function TweenService:Create(o, _, props)
    return { Play = function() for k, v in pairs(props) do o[k] = v end end }
end
local RunService = newInst("RunService")
function RunService:BindToRenderStep() end
function RunService:UnbindFromRenderStep() end
local UIS = newInst("UserInputService")
local game = {}
function game:GetService(n)
    if n == "UserInputService" then return UIS end
    if n == "TweenService" then return TweenService end
    if n == "RunService" then return RunService end
    return newInst(n)
end

local PG = newInst("PlayerGui")
local player = { Name = "Tester", DisplayName = "Tester", UserId = 1 }
function player:WaitForChild(n) if n == "PlayerGui" then return PG end return nil end
function player:FindFirstChild(n) if n == "PlayerGui" then return PG end return nil end

-- task.delay runs later, as in the game (show() hides the old page in a
-- delay that reads the NEW current page): queued, run by flush().
local SPAWNED, DELAYED = {}, {}
local function flush()
    while #DELAYED > 0 do table.remove(DELAYED, 1)() end
end
local task = {
    spawn = function(f, ...) table.insert(SPAWNED, f) end,
    delay = function(_, f, ...)
        local a = { ... }
        table.insert(DELAYED, function() f(table.unpack(a)) end)
    end,
    defer = function(f, ...) f(...) end,
    wait = function() error("__ONE_PASS__") end,
}
local WARNED = {}
local warn = function(...) table.insert(WARNED, table.concat({ ... }, " ")) end

-- ---------- the config, behind a proxy that logs writes ----------
local CTRL = "-"                -- the control being fired (set by the cases)
local WRITES = {}               -- "Key" or "Table.key" -> { [ctrl] = true }
local function logWrite(path)
    WRITES[path] = WRITES[path] or {}
    WRITES[path][CTRL] = true
end
local NESTED = { AutoKeys = true, SeaEvFight = true, SeaEvKeys = true, SeaEvWeapons = true,
    VentKeys = true, BerryWant = true, RecipeWant = true, SwordWant = true }
local function proxy(real, prefix)
    return setmetatable({}, {
        __index = function(_, k)
            local v = real[k]
            if prefix == "" and NESTED[k] and type(v) == "table" then
                return proxy(v, k .. ".")
            end
            return v
        end,
        __newindex = function(_, k, v)
            if prefix == "" and NESTED[k] and type(v) == "table" and getmetatable(v) then
                return          -- `CFG.X = CFG.X or {}` hands the proxy back: not a change
            end
            logWrite(prefix .. tostring(k))
            real[k] = v
        end,
    })
end

-- @@CFG@@  (panel_test.py puts the real `local CFG = {...}` here, then the proxy)

-- ---------- the rest of fast_farm the panel reads ----------
CFG_REAL.WeaponOrder = { "Godhuman", "Hallow Scythe" }
CFG_REAL.Weapons = {
    Godhuman = { use = true, M1 = true, Z = true, X = false, C = false, V = false, F = false },
    ["Hallow Scythe"] = { use = true, M1 = false, Z = true, X = true, C = false, V = false, F = false },
}
local KEYS = { "Z", "X", "C", "V", "F" }
local LEVELS = {}
local stats = { kills = 0, piles = 0, startedAt = 0, putBack = 0, flights = 0, hops = 0,
    pulledBack = 0, escapes = 0, m1 = 0, casts = 0, castsTook = 0, castsHit = 0,
    castsMissed = 0, swaps = 0, probes = 0, hakiPresses = 0 }
local state, statusLine, activeName, meas, stateEnteredAt = "IDLE", "", nil, nil, 0
local tried, wantPose, kenNextAt = {}, "safe", 0
local SAID = {}
local function say(s) table.insert(SAID, tostring(s)) end
local function circuit() return {} end
local function setupKey() return "a setup" end
local function toolNames() return { { Name = "Godhuman" }, { Name = "Hallow Scythe" } } end
local function toolType(t) return (t and t.Name == "Hallow Scythe") and "Sword" or "Melee" end
local function findTool(n) if n == "Godhuman" or n == "Hallow Scythe" then return { Name = n } end return nil end
local function heldTool() return nil end
local function wSummary() return "M1 Z" end
local function syncWeapons() end
local function wcfg(n)
    CFG_REAL.Weapons[n] = CFG_REAL.Weapons[n] or {}
    return proxy(CFG_REAL.Weapons[n], "Weapons.*.")
end
local function parts() return nil, nil end
local function mySea() return 3 end
local function rowOf() return nil end
local function seaOfLevel() return 3 end
local function levelRow() return nil end
local function playerLevel() return 2650 end
local function bossWhere() return nil end
local function gamePoints() return {} end
local function bossUp() return nil end
local function pullLimit() return 300 end
local function setPose() end
local function releaseCamera() end
local function releasePile() end
local function hasBuso() return true end
local function kenOn() return true end

local CALLS = {}
local function call(s) table.insert(CALLS, s) end
local P = { build = "TEST", running = false, handsOff = false }
P.BERRIES = { "Pink Pig Berry", "White Cloud Berry", "Red Cherry Berry", "Blue Icicle Berry",
    "Green Toad Berry", "Orange Berry", "Purple Jelly Berry", "Yellow Star Berry" }
P.RECIPES = { "Winter Sky", "Snow White", "Pure Red", "Bright Yellow" }
P.SWORDS = { "Shizu", "Saishi", "Oroshi" }
P.bosses = {}
P.skillTally, P.noDamage, P.leash, P.m1Notes, P.campNotes = {}, {}, {}, {}, {}
P.elite = { tally = { joins = 0, kills = 0, chalices = 0, found = 0, fails = 0, joinSecs = 0 },
    visited = {}, have = {}, note = "-" }
P.sea = { tally = { mirages = 0, dealers = 0, chests = 0, gears = 0, found = 0, buys = 0 },
    learn = {}, MIRAGE_HUNT = { mirage = true, dealer = true, mchest = true, gear = true } }
P.seaev = { count = { total = 0, kinds = {}, since = 0 }, levi = { note = "-", kills = 0, now = {}, share = {} },
    form = {}, learn = {} }
P.ember = { tally = { embers = 0, quests = 0, trees = 0 }, learn = {} }
P.halloween = { tally = { pumpkins = 0, kills = 0, doors = 0, treats = 0, tricks = 0, bosses = 0 }, note = "off",
    moonUp = function() return false end, census = function() return {}, 0, false end,
    watch = { on = false, n = 0, start = function() P.halloween.watch.on = true end,
        stop = function() P.halloween.watch.on = false end } }
P.pvp = { targetText = function() return "-" end, dashNote = function() return "-" end,
    next = function() call("pvp next") end, view = { note = "-" }, ken = { note = "-" },
    clean = { count = 0 }, shake = { note = "-" }, speed = { note = "-" }, faced = 0 }
P.seaev.spyAsk = function() call("spyAsk") end
P.seaev.reset = function() call("seaev reset") end
function P.nearbyNames() return {} end
function P.toggleTarget(n) call("toggleTarget " .. tostring(n)) end
function P.clearTargets() call("clearTargets") end
function P.reprobe() call("reprobe") end
function P.moveWeaponUp(n) call("moveWeaponUp " .. tostring(n)) return true end
function P.hopNow() call("hopNow") end
function P.kenNextIn() return 0 end
function P.reloadWay() return "-" end
function P.teamSave() end
-- The fruit history and the market's values (fast_farm's main chunk).
P.fruitLog = {}
function P.fruitLogSummary() return {} end
function P.fruitLogLines() return {} end
function P.fruitLogClear() end
function P.valueWords(v) return tostring(v) end
function P.skillState() return "-" end
function P.heldTool() return nil end
-- The mode setters as the real ones change CFG (P.setHunt: ELITE HUNT;
-- P.pvpSet: PVP; P.start / P.stop: API).
function P.setHunt(x, kind)
    call("setHunt " .. tostring(x) .. " " .. tostring(kind))
    if kind then CFG.HuntKind = kind end
    CFG.Hunt = x and true or false
    if x then CFG.RaidMode, CFG.RandomMode = false, false end
end
function P.stop() call("stop") P.running = false end
function P.start()
    call("start")
    if CFG.Pvp then P.pvpSet(false) end
    P.running = true
end
function P.pvpSet(on)
    call("pvpSet " .. tostring(on))
    CFG.Pvp = on and true or false
    if on and P.running then P.stop() end
end
