-- Stubs for the PvP AIM wiring (pvp_test.py part 3): just enough Roblox for
-- the REAL candidates / pingNow / floorUnder / predict / targetTick / stream /
-- gun snap / attackPressed / faceNow to run in luau.exe.
local NOW = 100
local os = { clock = function() return NOW end }

-- ---------- Vector3 / CFrame ----------
local V3 = {}
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    if k == "Unit" then
        local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
        return setmetatable({ X = v.X / m, Y = v.Y / m, Z = v.Z / m }, V3)
    end
    return nil
end
local function v3(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, n) return v3(a.X * n, a.Y * n, a.Z * n) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
local Vector3 = { new = v3 }
local CFrame = {
    new = function(p) return { Position = p, kind = "CFrame" } end,
    lookAt = function(p, q) return { Position = p, LookAt = q, kind = "CFrame" } end,
}
local Enum = {
    RaycastFilterType = { Exclude = "Exclude" },
    KeyCode = { Z = "Z", X = "X", C = "C", V = "V", F = "F" },
}
local RaycastParams = { new = function() return {} end }

-- ---------- the world ----------
local FLOOR = function(x, z) return 0 end            -- floor height under (x, z)
local RAYS = 0
local cam = {
    CFrame = { Position = v3(0, 20, -40) },
    -- a flat screen: 5 px a stud, x right, z down the screen
    WorldToViewportPoint = function(_, p) return v3(400 + p.X * 5, 300 + p.Z * 5, 1) end,
}
local folders = { Characters = {}, Enemies = {}, _WorldOrigin = {} }
local workspace = {
    Gravity = 196.2,
    CurrentCamera = cam,
    FindFirstChild = function(_, n) return folders[n] end,
    Raycast = function(_, o, d, _)
        RAYS += 1
        local y = FLOOR(o.X, o.Z)
        if y <= o.Y and y >= o.Y + d.Y then return { Position = v3(o.X, y, o.Z) } end
        return nil
    end,
}

-- ---------- instances ----------
local function inst(class, props)
    local o = props or {}
    o.ClassName = class
    o.kids = o.kids or {}
    o.attrs = o.attrs or {}
    o.IsA = function(self, c) return self.ClassName == c end
    o.FindFirstChild = function(self, n) return self.kids[n] end
    o.GetAttribute = function(self, k) return self.attrs[k] end
    return o
end
local SENT = {}
local function remote(name)
    return inst("RemoteEvent", { Name = name, FireServer = function(self, v) table.insert(SENT, { self.Name, v }) end })
end

local function makePlayer(name, pos)
    local root = inst("Part", { Position = pos, AssemblyLinearVelocity = v3(0, 0, 0), Parent = true })
    local hum = inst("Humanoid", { Health = 100 })
    local char = inst("Model", { Parent = true })
    char.kids.HumanoidRootPart = root
    char.FindFirstChildOfClass = function(_, c) return c == "Humanoid" and hum or nil end
    local plr = inst("Player", { Name = name, DisplayName = name, Character = char })
    return plr
end

local me = makePlayer("me", v3(0, 3, 0))
local player = me
local OTHERS = {}
local Players = { GetPlayers = function()
    local out = { me }
    for _, p in ipairs(OTHERS) do table.insert(out, p) end
    return out
end }
local function parts()
    local c = me.Character
    return c, c.kids.HumanoidRootPart, c:FindFirstChildOfClass("Humanoid")
end

local TOOL = nil
local function heldTool() return TOOL end
local function toolType(t) return t and t.ToolTip or "?" end

local MOUSE = { X = 400, Y = 300 }
local UIS = { GetMouseLocation = function() return MOUSE end }

local PING_MS = 120
local game = { GetService = function(_, n)
    if n == "Stats" then
        return { Network = { ServerStatsItem = { ["Data Ping"] = { GetValue = function() return PING_MS end } } } }
    end
end }

-- the game's own aim assist module (CombatController.AimAssist)
local AA = { getTargetInfo = function() return "the game's head snap" end }
local RS = { Controllers = { CombatController = { AimAssist = AA } } }
local function require(m) return m end

local CFG = {
    PvpCatchPx = 200, PvpRange = 300, PvpLead = true, PvpLeadScale = 1, PvpSkillSpeed = 300,
    PvpStream = true, PvpAim = true, PvpFace = true, PvpFaceRange = 100,
}
local P = {}
function P.gunInfo(t)
    if not t or t.ToolTip ~= "Gun" then return nil end
    return { projectile = t.projectile or false, speed = t.speed }
end

local fails, count = 0, 0
local function check(name, cond)
    count += 1
    if not cond then
        fails += 1
        print("FAIL  " .. name)
    end
end
local function near(a, b, eps) return a ~= nil and b ~= nil and math.abs(a - b) < (eps or 1e-6) end
