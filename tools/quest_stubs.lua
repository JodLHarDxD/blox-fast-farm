-- What P.quest touches, faked in the shape of the game (decompiled v4623):
-- RS.Quests, RS.GuideModule.Data.NPCList, Main.Quest (the tracker), CommF_.
-- REPLY = what StartQuest answers: 0 yes, 1 error, 2 done already, else a level
-- (or a function of where you stand). MOVED = the tracker is not at Main.Quest
-- but a label elsewhere on screen. BELI = player.Data.Beli. CAMPS = campOf.
local P = {}
local CFG = { Quests = true, QuestAskFrom = 1500 }
local CALLS, LEVEL, CLOCK, REPLY, ON_FLY, PRINTS, TRACKS, MOVED, BELI, CAMPS
local QUESTS, NPCS, RS, ME, TITLE, QUEST_GUI, PG, HUD_FRAME, HUD_LABEL
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
    ME = vec(pos.X, pos.Y, pos.Z)
    if ON_FLY then ON_FLY() end
end
local function rowOf() return nil end
local function campOf(name) return CAMPS[name], "game" end
local function tracker(text)
    if MOVED then
        HUD_FRAME.Visible = text ~= nil
        HUD_LABEL.Text = text and ("<b>" .. text .. "</b>") or ""
        return
    end
    QUEST_GUI.Visible = text ~= nil
    TITLE.Text = text or ""
end

-- A small instance tree: IsA, GetDescendants, IsDescendantOf, GetFullName.
local KINDS = { TextLabel = { "GuiObject" }, Frame = { "GuiObject" }, ScreenGui = { "LayerCollector" },
    BillboardGui = { "LayerCollector" }, PlayerGui = {} }
local function inst(class, name, props, kids)
    local o = props or {}
    o.ClassName, o.Name, o.kids = class, name, {}
    function o:IsA(c)
        if c == class then return true end
        for _, k in ipairs(KINDS[class]) do if k == c then return true end end
        return false
    end
    function o:GetDescendants()
        local out = {}
        local function walk(x) for _, k in ipairs(x.kids) do table.insert(out, k) walk(k) end end
        walk(self)
        return out
    end
    function o:IsDescendantOf(a)
        local x = self.Parent
        while x do if x == a then return true end x = x.Parent end
        return false
    end
    function o:GetFullName() return (self.Parent and self.Parent.Parent and (self.Parent:GetFullName() .. ".") or "") .. self.Name end
    for _, k in ipairs(kids or {}) do k.Parent = o table.insert(o.kids, k) end
    return o
end
local cf = {}
function cf:InvokeServer(name, id, tier)
    if name == "StartQuest" then
        table.insert(CALLS, "start " .. id .. " " .. tostring(tier))
        local r = REPLY
        if type(r) == "function" then r = r() end
        if r == 0 and TRACKS then
            local q = QUESTS[id][tier]
            local enemy, n = next(q.Task)
            tracker(string.format("Defeat %d %ss (0/%d)", n, enemy, n))
        end
        return r
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
    MOVED, BELI, CAMPS = false, { Value = 1000 }, {}
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
    TITLE = inst("TextLabel", "Title", { Text = "", Visible = true })
    QUEST_GUI = inst("Frame", "Quest", { Visible = false }, {
        inst("Frame", "Container", { Visible = true }, {
            inst("Frame", "QuestTitle", { Visible = true }, { TITLE }) }) })
    -- The screen: the game's HUD (the moved tracker in it), this panel and a
    -- name tag - both of which carry quest-like words and must be passed over.
    HUD_LABEL = inst("TextLabel", "Title", { Text = "", Visible = true })
    HUD_FRAME = inst("Frame", "QuestFrame", { Visible = false }, { HUD_LABEL })
    PG = inst("PlayerGui", "PlayerGui", {}, {
        inst("ScreenGui", "BFFHUD", { Enabled = true }, {
            inst("TextLabel", "Card", { Text = "Gorilla 3/8  ·  0 done", Visible = true }) }),
        inst("ScreenGui", "Tags", { Enabled = true }, {
            inst("BillboardGui", "Tag", { Enabled = true }, {
                inst("TextLabel", "Name", { Text = "Gorilla 1/1", Visible = true }) }) }),
        inst("ScreenGui", "HUD", { Enabled = true }, { HUD_FRAME }),
        inst("ScreenGui", "Main", { Enabled = true }, { QUEST_GUI }),
    })
    PG.Main = { Quest = QUEST_GUI }
    player = { PlayerGui = PG, Data = { Beli = BELI } }
    function player:FindFirstChildOfClass(c) return c == "PlayerGui" and PG or nil end
    P.quest.reset()
end
P.quest = { reset = function() end }
