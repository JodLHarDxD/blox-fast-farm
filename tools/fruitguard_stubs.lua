-- Tools, a backpack, a hand, and the mouse - faked, for the fruit guard.
local function tool(name, eatDeep)
    local t = { Name = name, ClassName = "Tool", kids = {} }
    function t:IsA(c) return c == "Tool" end
    function t:FindFirstChild(n, recursive)
        if n == "EatRemote" and eatDeep then return { Name = "EatRemote" } end
        return nil
    end
    return t
end
local function holder(list)
    local h = { list = list }
    function h:GetChildren() return self.list end
    function h:FindFirstChild(n) for _, t in ipairs(self.list) do if t.Name == n then return t end end end
    function h:FindFirstChildOfClass() return self.list[1] end
    return h
end
local BACKPACK, CHAR = holder({}), holder({})
local player = { Character = CHAR }
function player:FindFirstChild(n) if n == "Backpack" then return BACKPACK end end
local P = {}
local HELD = nil
local function heldTool() return HELD end
local LOG = { clicks = 0, unequips = 0 }
local HUM = { UnequipTools = function() LOG.unequips += 1 HELD = nil end }
local function parts() return CHAR, {}, HUM end
local VIM = { SendMouseButtonEvent = function() LOG.clicks += 1 end }
local VirtualUser = { CaptureController = function() end, Button1Down = function() LOG.clicks += 1 end,
    Button1Up = function() end }
local workspace = { CurrentCamera = { ViewportSize = { X = 800, Y = 600 }, CFrame = {} } }
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local task = { wait = function() end }
local game = {}
