-- The farm's weapon helpers, a fake backpack and inventory, a clock.
local T = 100
local os = { clock = function() return T end }
local task = { wait = function(s) T += (s or 0.03) end, spawn = function(f, ...) f(...) end }
local CFG = { AutoAttack = true, AutoKeys = { Z = true, X = true, C = true, V = false },
    InvSwap = true, InvSwapGap = 1.5, InvSkip = {}, Weapons = {}, WeaponOrder = {}, M1Weapon = "" }
local P = {}
local stats = { swaps = 0 }
local KEYS = { "Z", "X", "C", "V", "F" }
local cd = {}
local pileCur = nil         -- the fight the M1 is for (the golems name their own weapon)

-- What you carry: name -> type. The inventory: what getInventory answers.
local CARRY = {}
local INV = {}
local LOADS = {}
local LOAD_WORKS = true
local function tool(name, ty) return { Name = name, ToolTip = ty } end
local function toolNames()
    local out = {}
    for name, ty in pairs(CARRY) do table.insert(out, tool(name, ty)) end
    table.sort(out, function(a, b) return a.Name < b.Name end)
    return out
end
local function toolType(t) return t.ToolTip end
local function findTool(name) return CARRY[name] and tool(name, CARRY[name]) or nil end
local function wcfg(name)
    local w = CFG.Weapons[name]
    if not w then
        w = { hold = { Z = 0.05 } }
        CFG.Weapons[name] = w
    end
    return w
end
local CF = {}
function CF:InvokeServer(what, name)
    if what == "getInventory" then return INV end
    if what == "LoadItem" then
        table.insert(LOADS, name)
        if not LOAD_WORKS then return nil end
        -- One sword slot, one gun slot: the new one replaces its kind.
        local ty = nil
        for _, it in ipairs(INV) do if it.Name == name then ty = it.Type end end
        for n, t in pairs(CARRY) do if t == ty then CARRY[n] = nil end end
        CARRY[name] = ty
    end
    return nil
end
local function commF() return CF end
