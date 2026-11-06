-- What P.quest touches, faked in the shape of the game (decompiled v4623):
-- RS.Quests, RS.GuideModule.Data.NPCList, Main.Quest (the tracker), CommF_.
-- REPLY = what StartQuest answers: 0 yes, 1 error, 2 done already, else a level.
local P = {}
local CFG = { Quests = true }
local CALLS, LEVEL, CLOCK, REPLY, ON_FLY, PRINTS, TRACKS
local QUESTS, NPCS, RS, ME, TITLE, QUEST_GUI
local epoch = 0
local function stale(e) return e ~= epoch end
local function say() end
local function setState() end
local function releasePile() end
local function playerLevel() return LEVEL end
local function print(s) table.insert(PRINTS, s) end
local os = { clock = function() return CLOCK end }
local task = { wait = function(s) CLOCK += (s or 0.03) end }
local function require(x) return x.module end

local V = {}
V.__index = V
local function vec(x, y, z)
    local v = setmetatable({ X = x, Y = y, Z = z }, V)
    v.Magnitude = math.sqrt(x * x + y * y + z * z)
    return v
end
V.__add = function(a, b) return vec(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V.__sub = function(a, b) return vec(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
local Vector3 = { new = vec }

local function parts() return nil, ME and { Position = ME } or nil end
local function flyTo(pos)
    table.insert(CALLS, string.format("fly %d", pos.X))
    if ON_FLY then ON_FLY() end
end
local function tracker(text)
    QUEST_GUI.Visible = text ~= nil
    TITLE.Text = text or ""
end
local cf = {}
function cf:InvokeServer(name, id, tier)
    if name == "StartQuest" then
        table.insert(CALLS, "start " .. id .. " " .. tostring(tier))
        if REPLY == 0 and TRACKS then
            local q = QUESTS[id][tier]
            local enemy, n = next(q.Task)
            tracker(string.format("Defeat %d %ss (0/%d)", n, enemy, n))
        end
        return REPLY
    end
    table.insert(CALLS, name)
    if name == "AbandonQuest" then tracker(nil) end
end
local REMOTE = true
local function commF() return REMOTE and cf or nil end
local player

local function giver(id, x, name)
    return { NPCName = name or id, InternalQuestName = id, Position = vec(x, 0, 0), Levels = {} }
end
local function reset()
    CALLS, LEVEL, CLOCK, REPLY, ON_FLY, PRINTS, TRACKS, REMOTE = {}, 1, 100, 0, nil, {}, true, true
    ME = vec(0, 0, 0)
    QUESTS = {
        BanditQuest1 = { { LevelReq = 0, Task = { Bandit = 5 } } },
        MarineQuest = { { LevelReq = 0, Task = { Trainee = 5 } } },
        JungleQuest = {
            { LevelReq = 10, Task = { Monkey = 6 } },
            { LevelReq = 15, Task = { Gorilla = 8 } },
            { LevelReq = 20, Task = { ["The Gorilla King"] = 1 } },
        },
        DesertQuest = { { LevelReq = 60, Task = { ["Desert Bandit"] = 8 } } },
        NextSeaQuest = { { LevelReq = 700, Task = { Raider = 8 } } },
    }
    -- This sea's givers. NextSeaQuest has none here.
    NPCS = {
        a = giver("BanditQuest1", 900),
        b = giver("MarineQuest", 300),
        c = giver("JungleQuest", 2000),
        d = giver("DesertQuest", 3000),
    }
    RS = {
        Quests = { module = QUESTS },
        GuideModule = { module = { Data = { NPCList = NPCS } } },
    }
    function RS:FindFirstChild(n) return self[n] end
    TITLE = { Text = "" }
    QUEST_GUI = { Visible = false, Container = { QuestTitle = { Title = TITLE } } }
    player = { PlayerGui = { Main = { Quest = QUEST_GUI } } }
    P.quest.reset()
end
P.quest = { reset = function() end }
