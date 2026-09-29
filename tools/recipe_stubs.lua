
-- What recipeStep touches, faked. OFFER = what ("ColorsDealer", "1") gives
-- (name, rarity) or nil; BUY = a list of answers to ("ColorsDealer", "2"),
-- one per call; AT = where the Barista Cousin stands (nil = not loaded).
local VM = {}
VM.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, VM) end
local function V(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, VM) end
Vector3 = { new = V }
local SEA, OFFER, RARITY, BUY, AT, CALLS, FLIGHTS, STOPPED
local CFG, E
local epoch = 0
local function stale(e) return e ~= epoch end
local function reset()
    SEA, OFFER, RARITY, BUY, AT, CALLS, FLIGHTS, STOPPED = 3, nil, nil, {}, nil, {}, 0, nil
    CFG = { RecipeWant = { ["Winter Sky"] = true, ["Snow White"] = false } }
    E = { tally = {}, recipeNote = "", note = "" }
    epoch = 0
end
reset()
local function mySea() return SEA end
local cf = {}
function cf:InvokeServer(a, b)
    table.insert(CALLS, a .. " " .. b)
    if b == "1" then return OFFER, RARITY end
    return table.remove(BUY, 1)
end
local function commF() return cf end
local function say() end
local function setState() end
local function releasePile() end
local function notify() end
local function flyTo() FLIGHTS += 1 end
function P.stop(why) STOPPED = why end
local cousin = { GetPivot = function() return { Position = AT } end }
local npcs = { FindFirstChild = function(_, n) return (n == "Barista Cousin" and AT) and cousin or nil end }
local workspace = { FindFirstChild = function(_, n) return n == "NPCs" and npcs or nil end }
local RS = { FindFirstChild = function() return nil end }
