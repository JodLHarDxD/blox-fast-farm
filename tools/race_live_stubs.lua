-- race_test.py part 2: a fake game for the whole RACE section.
local REAL_PRINT = print
local clock = 0
local os = { clock = function() return clock end, date = function() return "D " end }
local PRINTS = {}
local function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
    table.insert(PRINTS, table.concat(parts, " "))
end
local DELAYS = {}
local task = {
    spawn = function(f, ...) f(...) end,
    delay = function(t, f) table.insert(DELAYS, { at = clock + t, f = f }) end,
    wait = function() end,
}
local function runDelays()
    local keep = {}
    local due = {}
    for _, d in ipairs(DELAYS) do
        if clock >= d.at then table.insert(due, d) else table.insert(keep, d) end
    end
    DELAYS = keep
    for _, d in ipairs(due) do d.f() end
end
local FILES = {}
local function writefile(n, s) FILES[n] = s end
local _G = { BFF = nil }

-- signals and instances
local function signal()
    local s = { conns = {} }
    function s:Connect(f)
        local c = { f = f, on = true }
        function c:Disconnect() c.on = false end
        table.insert(self.conns, c)
        return c
    end
    function s:Fire(...)
        for _, c in ipairs(self.conns) do if c.on then c.f(...) end end
    end
    function s:live()
        local n = 0
        for _, c in ipairs(self.conns) do if c.on then n += 1 end end
        return n
    end
    return s
end
local function inst(name, class, props)
    local o = { Name = name, ClassName = class, kids = {}, attrs = {},
        ChildAdded = signal(), AttributeChanged = signal() }
    function o:FindFirstChild(n) return self.kids[n] end
    function o:FindFirstChildOfClass(c)
        for _, k in pairs(self.kids) do if k.ClassName == c then return k end end
        return nil
    end
    function o:IsA(c) return self.ClassName == c end
    function o:GetAttribute(a) return self.attrs[a] end
    function o:SetAttribute(a, v) self.attrs[a] = v self.AttributeChanged:Fire(a) end
    function o:add(k)
        self.kids[k.Name] = k
        k.Parent = self
        self.ChildAdded:Fire(k)
        return k
    end
    function o:remove(n) self.kids[n] = nil end
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end

-- the game's remotes; SERVER decides what a V4 try does
local SERVER = { eventOk = true, callOk = true }
local CALLS = {}
local RS = inst("ReplicatedStorage", "ReplicatedStorage")
local remotes = RS:add(inst("Remotes", "Folder"))
local commE = remotes:add(inst("CommE", "RemoteEvent"))
function commE:FireServer(...) table.insert(CALLS, "CommE " .. table.concat({ ... }, " ")) end
local fx = remotes:add(inst("FX", "RemoteEvent", { OnClientEvent = signal() }))
local events = RS:add(inst("Events", "Folder"))
local v4ev = events:add(inst("ActivateRaceV4", "BindableEvent"))

-- you
local player = inst("me", "Player")
local backpack = player:add(inst("Backpack", "Backpack"))
local char, root, hum, energy, transformed
local function transform()
    if energy.Value >= 1 then transformed.Value = true energy.Value = 0.99 end
end
function v4ev:Fire()
    table.insert(CALLS, "event")
    if SERVER.eventOk then transform() end
end
local function newChar()
    char = inst("meChar", "Model")
    root = char:add(inst("HumanoidRootPart", "Part"))
    hum = char:add(inst("Humanoid", "Humanoid", { Health = 100 }))
    energy = char:add(inst("RaceEnergy", "NumberValue", { Value = 0 }))
    transformed = char:add(inst("RaceTransformed", "BoolValue", { Value = false }))
    player.Character = char
end
newChar()
local awakening = backpack:add(inst("Awakening", "Tool", { ToolTip = "" }))
local rf = awakening:add(inst("RemoteFunction", "RemoteFunction"))
function rf:InvokeServer(x)
    table.insert(CALLS, "call " .. tostring(x))
    if SERVER.callOk then transform() end
    return nil
end
local ability = backpack:add(inst("Primordial Reign", "Tool", { ToolTip = "" }))

local function toolNames()
    local out = {}
    for _, src in ipairs({ backpack, char }) do
        for _, t in pairs(src.kids) do if t.ClassName == "Tool" then table.insert(out, t) end end
    end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end
local function toolType(t) return t.ToolTip end
local KEYS = { "Z", "X", "C", "V", "F" }
local CFG = { RaceV4 = true, RaceAll = true, RaceM1Burst = 4, RaceV3 = true, RaceV3Wait = 28,
    RaceV3Every = 0.5, Weapons = {}, Pvp = false }
local P = { handsOff = false, running = false }
_G.BFF = P
