-- What the M1 probe touches, faked. LANDS[key] = that way takes HP off
-- ("game", "new", "old", "keys", "tap"); GAME = the game's hit sender is reachable.
-- DOT = HP a second the pile loses whatever is fired (a skill's storm, a burn,
-- another player); FIRST_AT = the clock at the first M1 fired.
local CLOCK, DOT, ON_WAIT = 0, 0, nil
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = { wait = function(s) s = s or 0.03 CLOCK += s if ON_WAIT then ON_WAIT(s) end end }
local CFG = { StayHigh = false, M1Method = "auto", M1Every = 0.12 }
local P = { running = true }
local stats = { probes = 0 }
local probing = false
local LANDS, GAME, TRIED, TYPE, FIRST_AT = {}, false, {}, "Sword", nil
local enemy = { model = { Parent = true }, hum = { Parent = true, Health = 1000 } }
local pile = { enemy }
ON_WAIT = function(s) enemy.hum.Health -= DOT * s end
local function say() end
local function setPose() end
local function toolType() return TYPE end
local function keyOf(way) return way.variant or way.path end
local function describeWay(way) return keyOf(way) .. "/" .. tostring(way.pose) end
local function fireM1(way)
    FIRST_AT = FIRST_AT or CLOCK
    local k = keyOf(way)
    if TRIED[#TRIED] ~= k then table.insert(TRIED, k) end
    if LANDS[k] then enemy.hum.Health -= 5 end
end
function P.findGameHit() return GAME and function() end or nil end
-- A gun (THE GUN): GUN = P.gunInfo's answer, SHOTFN = the game's shot found.
local GUN, SHOTFN, RELEASED = nil, false, 0
function P.gunInfo() return GUN end
function P.gunShotFn() return SHOTFN and function() end or nil end
function P.gunRelease() RELEASED += 1 end
-- A fruit's tool: the children it has (Holding = run by the game's moveset).
local function fruitTool(kids)
    local t = { kids = kids }
    function t:FindFirstChild(n) return self.kids[n] end
    return t
end
local function reset()
    CLOCK, LANDS, GAME, TRIED, TYPE, FIRST_AT, DOT = 0, {}, false, {}, "Sword", nil, 0
    GUN, SHOTFN, RELEASED = nil, false, 0
    CFG.GunHold, CFG.GunFast = true, false
    P.canCast, P.lastCastAt = nil, nil
    enemy.hum.Health = 1000
end
