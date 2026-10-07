-- What the M1 probe touches, faked. LANDS[key] = that way takes HP off
-- ("game", "new", "old", "keys"); GAME = the game's hit sender is reachable.
local CLOCK = 0
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = { wait = function(s) CLOCK += (s or 0.03) end }
local CFG = { StayHigh = false, M1Method = "auto", M1Every = 0.12 }
local P = { running = true }
local stats = { probes = 0 }
local probing = false
local LANDS, GAME, TRIED, TYPE = {}, false, {}, "Sword"
local enemy = { model = { Parent = true }, hum = { Parent = true, Health = 1000 } }
local pile = { enemy }
local function say() end
local function setPose() end
local function toolType() return TYPE end
local function keyOf(way) return way.variant or way.path end
local function describeWay(way) return keyOf(way) .. "/" .. tostring(way.pose) end
local function fireM1(way)
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
local function reset()
    CLOCK, LANDS, GAME, TRIED, TYPE = 0, {}, false, {}, "Sword"
    GUN, SHOTFN, RELEASED = nil, false, 0
    CFG.GunHold, CFG.GunFast = true, false
    enemy.hum.Health = 1000
end
