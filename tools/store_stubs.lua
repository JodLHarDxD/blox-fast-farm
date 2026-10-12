-- The backpack before a hop (P.storeBeforeHop) and the one store (storeTool),
-- cut from fast_farm.lua: the game's StoreFruit answers from STORE_OK.
local task = { wait = function() end }
local CFG = { FruitStoreOnHop = true }
local PRINTED = {}
local realPrint = print
local function print(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end table.insert(PRINTED, table.concat(t, " ")) end
local function tool(name, attrs, physical)
    local t = { Name = name, attrs = attrs or {}, physical = physical }
    function t:GetAttribute(n) return self.attrs[n] end
    return t
end
local BACKPACK = { kids = {} }
function BACKPACK:GetChildren() return self.kids end
local CHAR = {}
local player = { Character = CHAR }
function player:FindFirstChild(n) return (n == "Backpack") and BACKPACK or nil end
local UNEQUIPS = 0
local HUM = { UnequipTools = function() UNEQUIPS += 1 end }
local function parts() return {}, {}, HUM end
local STORED, STORE_OK = {}, {}
local function commF()
    return { InvokeServer = function(_, what, orig, t)
        if what ~= "StoreFruit" then return nil end
        table.insert(STORED, orig)
        if STORE_OK[orig] ~= false then t.Parent = "storage" return true end
        return "you already have one"
    end }
end
local P = {}
function P.isPhysicalFruit(t) return t.physical == true end
function P.fruitOrig(name)
    local base = string.match(tostring(name), "^%s*(.-)%s+Fruit%s*$")
    return base and (base .. "-" .. base) or nil
end
