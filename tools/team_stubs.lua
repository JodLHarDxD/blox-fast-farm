-- What P.pickTeam touches, faked. REMOTE_WORKS = SetTeam puts you on the
-- team; BUTTON_WORKS = the ChooseTeam screen's button does. WAITS caps the
-- loop (a test must end even when no team ever comes).
local P = {}
local _G = { BFF = P }     -- luau.exe's own _G is read-only
local CFG, player, CALLS, WAITS, REMOTE_WORKS, BUTTON_WORKS, screen
local task = { wait = function()
    WAITS += 1
    if WAITS > 20 then _G.BFF = nil end
end }
local function newButton(team)
    local b = { Activated = {} }
    function b:IsA(c) return c == "GuiButton" end
    b.conn = { Fire = function() table.insert(CALLS, "button " .. team)
        if BUTTON_WORKS then player.Team = { Name = team } end end }
    return b
end
local getconnections = function(sig) return { sig.owner.conn } end
local firesignal = nil
local function reset()
    _G.BFF = P
    CFG = { AutoTeam = true, Team = "Pirates" }
    CALLS, WAITS, REMOTE_WORKS, BUTTON_WORKS = {}, 0, true, false
    screen = { Visible = true }
    local boxes = {}
    for _, t in ipairs({ "Pirates", "Marines" }) do
        local b = newButton(t)
        b.Activated.owner = b
        boxes[t] = { GetDescendants = function() return { b } end }
    end
    screen.Container = { FindFirstChild = function(_, n) return boxes[n] end }
    player = { Team = nil, PlayerGui = { Main = { ChooseTeam = screen } } }
end
reset()
local cf = {}
function cf:InvokeServer(a, team)
    table.insert(CALLS, a .. " " .. team)
    if REMOTE_WORKS then player.Team = { Name = team } end
end
local function commF() return cf end
