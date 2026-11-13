-- The fruit hunt's choice (fruitWanted), for tools/elite_test.py "fruitwant".
-- After elite_stubs.lua + the pure block (pickFruit). LIST = what lies here;
-- STOCK = your storage ({ [name] = count }, nil = not readable); CAP = the
-- game's player.Data.FruitCap (nil = not there).
local CFG = {}
local E = { fruitSkip = {} }
local LIST, STOCK, STOCK_READS, NOW, SAID, CAP = {}, {}, 0, 100, {}, 3
local os = { clock = function() return NOW end, time = function() return NOW end }
local realPrint = print
local function print(s)
    s = tostring(s)
    if string.sub(s, 1, 5) == "[BFF]" then table.insert(SAID, s) else realPrint(s) end
end
player.Data = setmetatable({}, { __index = function(_, k)
    if k == "FruitCap" then
        if CAP == nil then error("no FruitCap") end
        return { Value = CAP }
    end
    return nil
end })
local function fruitsLying() return LIST end
local function fruitWords(f) return tostring(f.orig or "a spawn") end
function P.fruitBase(orig) return (string.match(tostring(orig), "^(.+)%-%1$")) or tostring(orig) end
local VALUES = { Kitsune = 570e6, Shadow = 6.5e6, Dough = 30e6, Spin = 7.5e3 }
function P.isKeeper(orig, min)
    min = tonumber(min) or 0
    if min <= 0 then return false end
    local v = VALUES[P.fruitBase(orig)]
    return v == nil or v >= min
end
function P.storedCount(list, orig)
    if type(list) ~= "table" then return nil end
    return tonumber(list[orig]) or 0
end
function P.storedFruits()
    STOCK_READS += 1
    if STOCK then return STOCK, "test" end
    return nil, "not readable"
end
function P.fruitChoice() return nil end
