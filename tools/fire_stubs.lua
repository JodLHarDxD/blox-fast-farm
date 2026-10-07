-- What fireM1 reaches, faked: every path logs what it would send.
local LOG = {}
local function ev(s) table.insert(LOG, s) end
local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then
        local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return v3(v.X / m, v.Y / m, v.Z / m)
    end
    return nil
end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local ME = { Position = v3(0, 20, 0) }
local function parts() return nil, ME end
local CFG = { HitRange = 60, PileSpread = 3, AimSkills = false, AimHidden = true }
local P = {}
local stats = { m1 = 0 }
local actions = 0
local pileCentre = v3(0, 0, 0)
local function enemy(name, x)
    local m = { Name = name, Parent = true }
    function m:FindFirstChild() return nil end
    return { model = m, hum = { Health = 100 }, root = { Position = v3(x, 0, 0) } }
end
local pile = { enemy("A", 1), enemy("B", -1) }
local RS = {}
local player = {}
local function remote(name)
    return { FireServer = function(_, ...) ev(name) end }
end
local function netRemote(_, name) return remote(name) end
local workspace = { CurrentCamera = { ViewportSize = 1 } }
local aimPixel = nil
local function aimSwapIn() end
local function aimCamera() end
local function aimPoint() return pileCentre end
local RunService = { Heartbeat = { Wait = function() end } }
local function pressM1() ev("click") end
local function toolType(t) return t.kind end
function P.gunHoldTick(t) ev("hold " .. t.Name) end
function P.gunShotTick(t) ev("gunshot " .. t.Name) end
function P.gunAimFor(secs) ev("aim " .. secs) end
