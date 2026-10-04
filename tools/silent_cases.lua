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

check("a replaced copy can be taken out by the next one", _G.BFF_SILENT_OFF == nil and _G.BFF_SILENT_V2 == true)
print(all and "ALL PASS" or "SOME FAILED")
