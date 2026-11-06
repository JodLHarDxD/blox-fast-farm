-- What P.lightRun touches, faked: the game's Settings script as decompiled
-- (v4623). WAITS caps every loop, a test must end when no team ever comes.
-- ON_WAIT runs at each task.wait: the world changing while the script waits.
local P = {}
local _G = { BFF = P }     -- luau.exe's own _G is read-only
local CFG, player, CALLS, WAITS, ON_WAIT, CLOCK, PRINTS
local G, RS, MAP, UNLOADED, EVENTS, UTIL, ACTOR, SHAKE, SHAKER
local task = { wait = function(s)
    WAITS += 1
    if ON_WAIT then ON_WAIT(WAITS, s) end
    if WAITS > 400 then _G.BFF = nil end
end }
local os = { clock = function() CLOCK += 0.003 return CLOCK end }
local Enum = { Material = { SmoothPlastic = "SmoothPlastic", Water = "Water", Grass = "Grass" } }
local function print(s) table.insert(PRINTS, s) end
local function require(x) return x.module end
local function prop(o, k) return o[k] end
function P.meshToken() return nil end

local function kids(t)
    return function(self, n) return t[n] end
end
local function part(mat)
    local p = { Material = mat }
    function p:IsA(c) return c == "BasePart" end
    return p
end
local function texture(offset)
    local t = { destroyed = false }
    function t:IsA(c) return c == "Texture" end
    function t:GetAttribute(n) return n == "Offset" and offset or nil end
    function t:Destroy() self.destroyed = true end
    return t
end
local function folder(list)
    return { GetDescendants = function() return list end }
end

-- The real music button's handler: ToggleMusic is a bindable the game listens to.
local function newMusicEvent()
    local ev = {}
    function ev:Fire(v)
        table.insert(CALLS, "music " .. tostring(v))
        G.muted = v
    end
    return ev
end
local function newShaker(name)
    local s = { module = nil }
    s.module = { SetEnabled = function(_, flag)
        table.insert(CALLS, name .. " " .. tostring(flag))
    end }
    return s
end

local function reset()
    _G.BFF = P
    CFG = { LightMode = true }
    CALLS, WAITS, CLOCK, PRINTS, ON_WAIT = {}, 0, 0, {}, nil
    P.light.note = "waiting for your team"
    G = { muted = false }
    function G.isMusicMuted() return G.muted end
    MAP = { part(Enum.Material.Grass), part(Enum.Material.Water), texture(nil), texture(1) }
    UNLOADED = { part(Enum.Material.Grass) }
    EVENTS = { ToggleMusic = newMusicEvent() }
    SHAKE, SHAKER = newShaker("CameraShake"), newShaker("CameraShaker")
    UTIL = { CameraShake = SHAKE, CameraShaker = SHAKER }
    UTIL.FindFirstChild = kids(UTIL)
    EVENTS.FindFirstChild = kids(EVENTS)
    RS = { Events = EVENTS, Util = UTIL, Global = { module = G }, Unloaded = folder(UNLOADED) }
    RS.FindFirstChild = kids(RS)
    ACTOR = { sent = {} }
    function ACTOR:SendMessage(a, b) table.insert(self.sent, a .. " " .. tostring(b)) end
    local scripts = { OptimizerClientActor = ACTOR }
    scripts.FindFirstChild = kids(scripts)
    player = { Team = { Name = "Marines" }, PlayerScripts = scripts }
    player.FindFirstChild = kids(player)
end
local workspace = { FindFirstChild = function(_, n)
    if n == "Map" then return MAP and folder(MAP) end
end }
P.light = {}
