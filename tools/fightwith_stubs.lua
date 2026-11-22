-- FIGHT WITH engine block: what it reads from the farm.
local CFG = { FightWith = {}, FightGoal = {}, MasteryStop = 500, Weapons = {}, WeaponOrder = {} }
local CARRIED = {}                      -- name -> { Level = n }
local STATUS = {}
local function say(s) table.insert(STATUS, s) end
local function toolNames()
    local out = {}
    for n in pairs(CARRIED) do table.insert(out, { Name = n }) end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end
local function findTool(n)
    local c = CARRIED[n]
    if not c then return nil end
    return { Name = n, FindFirstChild = function(_, k)
        if k == "Level" and c.Level then return { Value = c.Level } end
        return nil
    end }
end
local function wcfg(n)
    CFG.Weapons[n] = CFG.Weapons[n] or { use = false, M1 = false, Z = false, X = false, C = false,
        V = false, F = false, hold = {} }
    return CFG.Weapons[n]
end
local MODE = "random"
P.modeNow = function() return MODE end
