-- What swordStep touches, faked. OFFER = what ("LegendarySwordDealer", "1")
-- gives (a name or nil), one per call when a list; BUY = answers to "2", one
-- per call; AT = where he stands (nil = not loaded); ITEMS = what
-- GetAllItemValues answers (nil = no such remote); INV = getInventory's list;
-- BELI = your money (nil = no Data); CARRY = tool names in your Backpack;
-- PARKED = his model only in ReplicatedStorage.NPCs (not in the world).
local VM = {}
VM.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, VM) end
local function V(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, VM) end
Vector3 = { new = V }
local SEA, OFFER, BUY, AT, ITEMS, INV, BELI, CARRY, ALIVE, PARKED
local CALLS, FLIGHTS, STOPPED, NOTES
local CFG, E
local epoch = 0
local function stale(e) return e ~= epoch end
local function reset()
    SEA, OFFER, BUY, AT, ITEMS, INV, BELI, CARRY, ALIVE, PARKED = 2, nil, {}, nil, {}, nil, 5000000, {}, true, false
    CALLS, FLIGHTS, STOPPED, NOTES = {}, 0, nil, {}
    CFG = { SwordWant = { Shizu = true, Saishi = true, Oroshi = true } }
    E = { tally = {}, note = "" }
    epoch = 0
end
reset()
local function mySea() return SEA end
local cf = {}
function cf:InvokeServer(a, b)
    table.insert(CALLS, a .. " " .. tostring(b))
    if a == "getInventory" then return INV end
    if b == "1" then
        if type(OFFER) == "table" then return table.remove(OFFER, 1) end
        return OFFER
    end
    return table.remove(BUY, 1)
end
local function commF() return cf end
local rf = {}
function rf:InvokeServer() table.insert(CALLS, "GetAllItemValues") return ITEMS end
local function netRemote(kind, name)
    if kind == "RF" and name == "GetAllItemValues" and ITEMS ~= nil then return rf end
    return nil
end
local function say() end
local function setState() end
local function releasePile() end
local function notify(t) table.insert(NOTES, t) end
local function flyTo() FLIGHTS += 1 end
local task = { wait = function() end }
local function parts() if ALIVE then return {}, {}, {} end return {}, nil, nil end
function P.stop(why) STOPPED = why end
local dealer = { GetPivot = function() return { Position = AT } end }
local npcs = { FindFirstChild = function(_, n) return (n == "Legendary Sword Dealer" and AT and not PARKED) and dealer or nil end }
local parked = { FindFirstChild = function(_, n) return (n == "Legendary Sword Dealer" and AT and PARKED) and dealer or nil end }
local workspace = { FindFirstChild = function(_, n) return n == "NPCs" and npcs or nil end }
local RS = { FindFirstChild = function(_, n) return n == "NPCs" and parked or nil end }
local function kids(names)
    local out = {}
    for _, n in ipairs(names) do table.insert(out, { Name = n }) end
    return out
end
player.FindFirstChild = function(_, n)
    if n == "Data" and BELI ~= nil then
        return { FindFirstChild = function(_, k) return k == "Beli" and { Value = BELI } or nil end }
    end
    if n == "Backpack" then return { GetChildren = function() return kids(CARRY) end } end
    return nil
end
player.Character = nil

-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function count(word)
    local n = 0
    for _, c in ipairs(CALLS) do if c == word then n += 1 end end
    return n
end
