-- The backpack before a hop (P.storeBeforeHop) and the one store (storeTool),
-- cut from fast_farm.lua: the game's StoreFruit answers from STORE_OK.
local task = { wait = function() end }
local CFG = { FruitStoreOnHop = true, FruitKeepValue = 20000000 }
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
local CHAR = { kids = {} }
function CHAR:GetChildren() return self.kids end
local player = { Character = CHAR }
function player:FindFirstChild(n) return (n == "Backpack") and BACKPACK or nil end
local UNEQUIPS = 0
-- Put away: the tool in your hand goes to the backpack.
local HUM = { UnequipTools = function()
    UNEQUIPS += 1
    for _, t in ipairs(CHAR.kids) do t.Parent = BACKPACK table.insert(BACKPACK.kids, t) end
    CHAR.kids = {}
end }
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
-- The market's values (P.tradeValue) for the fruits used here; the history
-- logged (P.fruitLogSet).
local VALUES = { ["Dough-Dough"] = 30e6, ["Control-Control"] = 120e6, ["Buddha-Buddha"] = 10e6,
    ["Rocket-Rocket"] = 5e3, ["Spin-Spin"] = 7.5e3, ["Ice-Ice"] = 550e3 }
function P.tradeValue(o) return VALUES[o] end
function P.isKeeper(o, min)
    min = tonumber(min) or 0
    if min <= 0 then return false end
    local v = VALUES[o]
    return v == nil or v >= min
end
function P.fruitBase(o) return string.match(tostring(o), "^(.+)%-%1$") or o end
function P.valueWords(v) return v and (tostring(v / 1e6) .. "M") or "?" end
local LOGSET = {}
function P.fruitLogSet(orig, state, from) table.insert(LOGSET, tostring(orig) .. " " .. state) return nil end
function P.isPhysicalFruit(t) return t.physical == true end
function P.fruitOrig(name)
    local base = string.match(tostring(name), "^%s*(.-)%s+Fruit%s*$")
    return base and (base .. "-" .. base) or nil
end
