-- The game's inventory and craft, the farm's movers and fight, for the
-- VOLCANIC MAGNET section.
local T = 100
local os = { clock = function() return T end }
local task = { wait = function(s) T += (s or 0.03) end }
local V = {}
local function vec(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = vec }
local CFG = { SeaMagnet = true, Hunt = true, HuntKind = "prehistoric", HeightSafe = 20 }
local P = {}
local activeName = nil

-- The inventory (counts) and what a craft does (where it works).
local INV = { magnet = 0, ember = 0, scrap = 0 }
local READABLE = true
local CRAFT_WORKS = "anywhere"         -- "anywhere" | "npc" | "never"
local AT_NPC = false
local CRAFTS = 0
local LEGACY_CALLS, LEGACY_WORKS = 0, false
local CF = {}
function CF:InvokeServer(what, a, b)
    if what == "getInventory" then
        if not READABLE then return nil end
        return {
            { Name = "Volcanic Magnet", Count = INV.magnet }, { Name = "Blaze Ember", Count = INV.ember },
            { Name = "Scrap Metal", Count = INV.scrap }, { Name = "Leather", Count = 50 },
        }
    end
    -- The hubs' CommF_ craft: refused on the user's client (2026-10-31 log),
    -- unless LEGACY_WORKS (a client without the Net Craft remote).
    if what == "CraftItem" and a == "Craft" and b == "Volcanic Magnet" then
        LEGACY_CALLS += 1
        if LEGACY_WORKS and INV.ember >= 15 and INV.scrap >= 10 and INV.magnet == 0 then
            INV.magnet, INV.ember, INV.scrap = 1, INV.ember - 15, INV.scrap - 10
        end
    end
    return nil
end
local function commF() return CF end

-- The game's Net RF "Craft" (decompiled v4623, the Dragon Hunter's dialogue
-- and CraftWindow): PossibleHardcode -> Check -> Craft(Recipe, 1, {}).
local RFC, CRAFT_CALLS, NET = {}, {}, true
function RFC:InvokeServer(what, name, qty, picks)
    table.insert(CRAFT_CALLS, what)
    if what == "PossibleHardcode" then return name == "Volcanic Magnet" end
    if what == "Check" then
        local could = INV.ember >= 15 and INV.scrap >= 10
        return { Required = {}, Result = { Recipe = name, Name = name, Count = 1, Could = could,
            ErrorMessage = (not could) and "Not enough materials" or nil } }
    end
    if what == "Craft" and name == "Volcanic Magnet" and qty == 1 and type(picks) == "table" then
        CRAFTS += 1
        if CRAFT_WORKS == "anywhere" or (CRAFT_WORKS == "npc" and AT_NPC) then
            if INV.ember >= 15 and INV.scrap >= 10 and INV.magnet == 0 then
                INV.magnet, INV.ember, INV.scrap = 1, INV.ember - 15, INV.scrap - 10
                return { Required = {}, Result = {} }
            end
        end
    end
    return nil
end
local function netRemote(kind, name)
    if NET and kind == "RF" and name == "Craft" then return RFC end
    return nil
end

local FLIGHTS, FIGHTS = {}, {}
local HUNTER = vec(5864, 1209, 810)
local function flyTo(pos)
    table.insert(FLIGHTS, pos)
    AT_NPC = math.abs(pos.X - HUNTER.X) < 5 and math.abs(pos.Z - HUNTER.Z) < 5
end
local function lockAt() end
local function releasePile() end
local function setState() end
local function say() end
local function stale() return false end
local LOADED = {}
local function nearestLoaded(n) return LOADED[n] end
local function campOf(_, fallback) return fallback end
local function fight(cur, names)
    table.insert(FIGHTS, cur.name)
    INV.scrap += 1                          -- a kill drops one
    return "empty"
end
local print = function() end

-- The Ember hunt, borrowed.
local EMBER_CALLS = {}
P.ember = { note = "on a quest", hunterAt = function() return HUNTER end }
function P.ember.step(myEpoch, borrowed)
    table.insert(EMBER_CALLS, borrowed)
    P.ember.blocked = P.ember.blockNext
    if not P.ember.blocked then INV.ember += 3 end
    return not P.ember.blocked
end
