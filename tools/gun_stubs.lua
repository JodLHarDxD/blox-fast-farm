-- THE GUN, faked: a clock, a pile, tools carrying the game's own attributes
-- (LocalOverheat, IsAutoShooting, LocalTotalShots, Enabled), the mouse button
-- (VIM), the game's WeaponData and CombatController.Attack's upvalues.
local clock = 0
local os = { clock = function() return clock end }
local LOG = {}
local function ev(s) table.insert(LOG, s) end
local task = { spawn = function(f, ...) f(...) end, wait = function(t) clock += (t or 0.016) end }
local CFG = { GunFastEvery = 0.08, AutoKeys = { Z = true, X = true, C = true, V = false },
    MasteryWeapon = "", MasteryStop = 500 }
local P = { running = true }
local attacking = true
local aimUntil = 0
local pile = {}
local function say(s) ev("say " .. tostring(s)) end

local V3 = {}
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return nil
end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local ME = { Position = v3(0, 20, 0) }
local function parts() return nil, ME end

local HELD = nil
local function heldTool() return HELD end
local TOOLS = {}                       -- [name] = a tool you carry
local function findTool(n) return TOOLS[n] end
local function toolType(t) return t and t.kind or "?" end
local WCFG = {}
local function wcfg(n) WCFG[n] = WCFG[n] or { hold = { Z = 0.05 } } return WCFG[n] end

local VIM = { SendMouseButtonEvent = function(_, _, _, _, down) ev(down and "down" or "up") end }
local game = { GetService = function()
    return { SetCore = function(_, _, t) ev("notify " .. t.Text) end }
end }
local workspace = { CurrentCamera = { ViewportSize = { X = 1000, Y = 600 } } }
local Enum = { UserInputType = { MouseButton1 = "MouseButton1" } }

-- The game's own modules.
local WEAPONDATA = {
    Dragonstorm = { ShootStyle = "Gatling", OverheatLimit = 3, Range = 400, ShootType = "HitscanSingleShot" },
    ["Skull Guitar"] = { ShootType = "Custom" },
    DualFlintlock = { ShootType = "HitscanSingleShot", Range = 200 },
}
local MOUSE = { __inst = true }
function MOUSE:IsA(c) return c == "PlayerMouse" end
local SHOTS = {}
local function shootGun(tool, input)
    table.insert(SHOTS, { tool = tool.Name, input = input.UserInputType, inGame = P.inGameShot })
end
local function attackMelee() end
local function ATTACK() end
-- CombatController.Attack's upvalues, and each function's own.
local UPS = {
    [ATTACK] = { attackMelee, 5, shootGun, "x" },
    [attackMelee] = { 1, 2, 3, 4, 5, 6 },                     -- numbers, no mouse: not it
    [shootGun] = { MOUSE, 727595, 798405, 1048576, 0, 1, 0 }, -- the mouse + the validator
}
local CC = { Attack = ATTACK }
local RS = { Modules = { WeaponData = "WD" }, Controllers = { CombatController = "CC" } }
local function require(m)
    if m == "WD" then return WEAPONDATA end
    if m == "CC" then return CC end
    error("not a module")
end
local debug = { getupvalues = nil }
local getupvalues = nil
local function typeof(x)
    if type(x) == "table" and x.__inst then return "Instance" end
    return type(x)
end

local function tool(name, kind)
    local t = { Name = name, kind = kind or "Gun", Enabled = true,
        attrs = { LocalOverheat = 0, LocalTotalShots = 0 }, kids = {} }
    function t:GetAttribute(k) return self.attrs[k] end
    function t:FindFirstChild(k) return self.kids[k] end
    return t
end
local function enemy(name, hp, pos)
    local m = { Name = name, Parent = true }
    local hum = { Health = hp }
    function m:FindFirstChildOfClass() return hum end
    return { model = m, hum = hum, root = { Position = pos or v3(0, 0, 0), Parent = m } }
end
