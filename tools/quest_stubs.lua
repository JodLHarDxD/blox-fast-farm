-- The game, faked, for the quest engine: a server that takes, refuses or
-- hides quests, a tracker that can be unreadable, and a log of every move.
local clock = 0
local os = { clock = function() return clock end }
local task = { wait = function(t) clock += (t or 0.016) end }
local LOG = {}
local function ev(s) table.insert(LOG, s) end

local V3 = {}
V3.__index = function(v, k)
    if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
    return rawget(V3, k)
end
V3.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, V3) end
V3.__sub = function(a, b) return setmetatable({ X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }, V3) end
local Vector3 = { new = function(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V3) end }
local Enum = { KeyCode = { E = "E" } }
local game = {}
local VIM = { SendKeyEvent = function() end }

-- THE SERVER
local SERVER = {
    db = {},            -- [questId][tier] = { enemy, need }
    current = nil,      -- { enemy, have, need }
    refuse = false,     -- StartQuest does nothing
    unreadable = false, -- the tracker cannot be read on this client
    asks = 0,
}
local cfObj = {
    InvokeServer = function(_, what, qname, tier)
        if what == "StartQuest" then
            SERVER.asks += 1
            ev("ask " .. qname .. " t" .. tier)
            if SERVER.refuse then return nil end
            local row = SERVER.db[qname] and SERVER.db[qname][tier]
            if row then SERVER.current = { enemy = row[1], have = 0, need = row[2] } end
            return true
        elseif what == "AbandonQuest" then
            ev("abandon")
            SERVER.current = nil
        end
    end,
}
local function commF() return cfObj end

local P = { learnedQuests = {}, learnedGivers = {}, giverSpots = {} }
P.readQuest = function(_)
    if SERVER.unreadable or not SERVER.current then return nil end
    local c = SERVER.current
    return { have = c.have, need = c.need, enemy = string.lower(c.enemy) .. "s" }
end
local stats = { quests = 0, abandons = 0 }
local epoch = 0
local function stale(e) return e ~= epoch end
local function say(_) end
local function setState(_) end
local ROOT = { Position = Vector3.new(0, 0, 0) }
local function parts() return {}, ROOT, {} end
local function flyTo(pos) ev(string.format("fly %.0f,%.0f", pos.X, pos.Z)) ROOT.Position = pos return true end
local function releasePile() end
local function findQuestGiver() return nil end
local function clickQuestDialog() end
local function levelRow() return nil end
local function mySea() return nil end
local function seaOfLevel() return 1 end
local function rowOf() return nil end
local activeName = nil
local circuitIdx = 1

local CFG = {
    Targets = {}, GiverMode = "never", GiverWalkRadius = 250, QuestRetrySeconds = 8,
    QuestStallSeconds = 240, QuestKillsFallback = 10, QuestName = nil, QuestTier = nil,
}
local QUESTS = {
    ["Bandit"] = { "BanditQuest1", 1 },
    ["Chief Petty Officer"] = { "MarineQuest2", 1 },
    ["Gorilla"] = { "JungleQuest", 1 },     -- deliberately the wrong tier
}
local QUEST_ALT = { ["Chief Petty Officer"] = { "MarineQuest", 2 } }
local QUEST_NEED = { ["Bandit"] = 5, ["Chief Petty Officer"] = 8 }
local GIVER_POS = { ["Bandit"] = Vector3.new(1000, 0, 0) }
local GIVER_NAMES = {}

