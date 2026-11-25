-- THE BOSS HUNT's world (2026-11-25): bossUp, the fight and the mode switch
-- faked, each call logged. UP[name] = { at, where } while it is up; KILL =
-- the next fight kills it. 2026-11-26: the Cake Loaf mirror - MIRROR = the
-- part (nil = not streamed in yet), OPEN = touching it moves you to INSIDE,
-- STREAMS = it streams in once you are near the Cake Loaf.
local NOW = 100
local os = { clock = function() return NOW end }
local task = { wait = function(s) NOW += (s or 0.03) end }
local LOG, UP, KILL, ME, MIRROR, OPEN, STREAMS, INSIDE
local CFG, E
local P = {}
local epoch = 0
local function stale(e) return e ~= epoch end
local function log(s) table.insert(LOG, s) end
local function say() end
local function setState() end
local function print(s) log("print " .. s) end
local function releasePile() end

local V = {}
V.__index = V
local function vec(x, y, z)
    local v = setmetatable({ X = x, Y = y, Z = z }, V)
    v.Magnitude = math.sqrt(x * x + y * y + z * z)
    return v
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = vec }

local CAKE = vec(-2124, 69, -12401)
local MIRROR_AT = vec(-2100, 150, -12420)
local SKY = vec(-2000, 4533, -14970)        -- the dimension (far, high)

local function parts() return nil, ME and { Position = ME } or nil end
local function flyTo(pos, opts)
    log(string.format("fly %d,%d,%d%s", pos.X, pos.Y, pos.Z, (opts and opts.portal == false) and " noroute" or ""))
    ME = vec(pos.X, pos.Y, pos.Z)
    if STREAMS and not MIRROR and (ME - CAKE).Magnitude < 300 then
        MIRROR = { Position = MIRROR_AT, IsA = function(_, c) return c == "BasePart" end }
    end
end
local function firetouchinterest(r, part, n)
    log("touch " .. n)
    if n == 1 and OPEN and part == MIRROR then ME = INSIDE end
end
local workspace = setmetatable({}, { __index = function(_, k)
    if k == "Map" then
        if not MIRROR then return {} end
        return { CakeLoaf = { BigMirror = { Main = MIRROR } } }
    end
end })
local player = { RequestStreamAroundAsync = function() end }

local function bossUp(name)
    local u = UP[name]
    if u then return u[1], u[2] end
    return nil, nil
end
local function fightNamed(name)
    log("fight " .. name)
    if KILL then UP[name] = nil return true end
    return false
end
function P.setHunt(x)
    log("hunt " .. tostring(x))
    CFG.Hunt = x and true or false
end
P.setModeById = function(id, on) log("mode " .. tostring(id) .. " " .. tostring(on)) end
local function reset()
    NOW, LOG, UP, KILL = 100, {}, {}, false
    ME, MIRROR, OPEN, STREAMS, INSIDE = vec(0, 0, 0), nil, true, true, vec(-2010, 4540, -14960)
    CFG = { Hunt = true, HuntKind = "boss", HuntBoss = "Cake Prince" }
    E = { lookStart = NOW, note = "" }
    P.bossBack = nil
end
