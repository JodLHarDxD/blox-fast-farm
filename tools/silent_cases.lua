local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function hit() return META.__index(MOUSE, "Hit") end

check("loaded: nothing of the game's is hooked", META.__index == gameIndex and HOOKS.index == 0 and HOOKS.namecall == 0)
check("loaded: says it hooks only while casting", P.silentNote == "ready (hooks only while casting)", P.silentNote)

P.silentTick(false, 0)
check("not casting: still nothing hooked", META.__index == gameIndex)

AIM = vec(0, 50, 0)
CFG.SilentAim = false
P.silentTick(true, 1)
check("switch off: a cast does not hook", META.__index == gameIndex)
CFG.SilentAim = true

P.silentTick(true, 2)
check("casting: __index is hooked", META.__index ~= gameIndex and P.silentHooked())
check("casting: __namecall is NEVER hooked (it broke the game's scripts)", HOOKS.namecall == 0)
local h = hit()
check("casting: a game script's Mouse.Hit is the target", h.Position.X == 0 and h.Position.Y == 50, h.Position.X)
check("casting: everything else answers as the game's", META.__index(game, "Name") == "real:Name")
P.silentTick(true, 2.5)
check("casting again: hooked once, not stacked", HOOKS.index == 1, HOOKS.index)

CALLER = true
check("the script's own read: your real mouse (never fooled by its own hook)", hit() == REAL_HIT)
P.inGameShot = true
local hs = hit()
check("...except while it runs the game's own gun shot: the target (THE GUN)",
    hs ~= REAL_HIT and hs.Position.Y == 50, hs.Position and hs.Position.Y)
P.inGameShot = false
check("...and the real mouse again right after", hit() == REAL_HIT)
CALLER = false

AIM = nil
check("between casts: Mouse.Hit is your real mouse", hit() == REAL_HIT)
P.silentTick(false, 4)
check("1.5 s after the cast: still in (no churn between casts)", P.silentHooked())
P.silentTick(false, 5.6)
check("3 s after the last cast: the game's own __index is back", META.__index == gameIndex and not P.silentHooked())

AIM = vec(0, 50, 0)
P.silentTick(true, 10)
P.silentOff()
check("stop: the game's own __index is back", META.__index == gameIndex)

P.silentTick(true, 11)
P.running = false
P.silentTick(true, 11.1)
check("script not running: let go at once", META.__index == gameIndex)

-- THE GAME'S OWN SKILL AIM: ReplicatedStorage.Mouse (skills, a fruit's M1).
P.running, CFG.SilentAim = true, true
AIM = nil
P.silentOff()
check("skill aim, idle: the game's Mouse table untouched (its own Hit field)", rawget(GM, "Hit") == GAME_HIT1
    and not P.gameAimHooked())
AIM = vec(0, 50, 0)
P.aimPart = { Parent = true, name = "beastRoot" }
P.silentTick(true, 20)
check("skill aim, casting: the game's Mouse.Hit (what a skill sends) is the target", GM.Hit.Position.Y == 50
    and GM.Hit.Position.X == 0, GM.Hit.Position.X)
check("skill aim, casting: its Target is the target's part", GM.Target == P.aimPart)
gameWrites(cfr(vec(222, 0, 0), nil))
check("skill aim, casting: the game aiming it again (every frame) does not undo it", GM.Hit.Position.Y == 50
    and rawget(GM, "Hit") == nil)
check("skill aim, casting: its other fields stay the game's (X its own, Move through its own __index)",
    GM.X == 960 and GM.Move == "move-signal")
AIM = nil
check("skill aim, between casts: the game's own latest aim", GM.Hit.Position.X == 222)
P.silentTick(false, 23.5)
check("skill aim, 3 s after: let go - the game's latest aim its own field again, its metatable as it was",
    rawget(GM, "Hit") ~= nil and rawget(GM, "Hit").Position.X == 222 and getmetatable(GM).__index == GM_INDEX
    and getmetatable(GM).__newindex == nil and rawget(GM, "Target") == "gamePart" and not P.gameAimHooked())
gameWrites(cfr(vec(333, 0, 0), nil))
check("...and the game writes it straight to its table again", rawget(GM, "Hit").Position.X == 333)
check("the panel: the game's own table (seen aiming it)", string.find(P.gameAimText(), "seen", 1, true) ~= nil,
    P.gameAimText())
local savedHook = hookmetamethod
hookmetamethod = nil
AIM = vec(0, 50, 0)
P.silentTick(true, 30)
check("no hookmetamethod: the PlayerMouse hook stays out, the skill aim still goes in (a Lua table)",
    not P.silentHooked() and P.gameAimHooked() and GM.Hit.Position.Y == 50)
P.silentOff()
check("stop: the skill aim let go too", not P.gameAimHooked() and rawget(GM, "Hit") ~= nil)
hookmetamethod = savedHook
CFG.SilentAim = false
P.silentTick(true, 40)
check("silent aim switched off: the game's table never touched", not P.gameAimHooked())
CFG.SilentAim = true
AIM = nil

check("a replaced copy can be taken out by the next one", _G.BFF_SILENT_OFF == nil and _G.BFF_SILENT_V2 == true)
print(all and "ALL PASS" or "SOME FAILED")
