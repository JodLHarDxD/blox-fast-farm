-- THE BOSS HUNT's world (2026-11-25): bossUp, the fight and the mode switch
-- faked, each call logged. UP[name] = { at, where } while it is up; KILL =
-- the next fight kills it.
local NOW = 100
local os = { clock = function() return NOW end }
local task = { wait = function(s) NOW += (s or 0.03) end }
local LOG, UP, KILL
local CFG, E
local P = {}
local function log(s) table.insert(LOG, s) end
local function say() end
local function setState() end
local function print(s) log("print " .. s) end
local function releasePile() end
local function bossUp(name)
    local u = UP[name]
    if u then return u[1], u[2] end
    return nil, nil
end
local function fightNamed(name)
    log("fight " .. name)
    if KILL then UP[name] = nil return true end
    return false
end
function P.setHunt(x)
    log("hunt " .. tostring(x))
    CFG.Hunt = x and true or false
end
P.setModeById = function(id, on) log("mode " .. tostring(id) .. " " .. tostring(on)) end
local function reset()
    NOW, LOG, UP, KILL = 100, {}, {}, false
    CFG = { Hunt = true, HuntKind = "boss", HuntBoss = "Cake Prince" }
    E = { lookStart = NOW, note = "" }
    P.bossBack = nil
end
