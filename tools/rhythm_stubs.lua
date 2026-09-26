
local clock = 0
local os = { clock = function() return clock end }
local task = { wait = function(t) clock += (t or 0.016) end }
local LOG = {}
local function ev(s) table.insert(LOG, s) end
local P = {}
local stats = { casts = 0, m1 = 0, castsTook = 0, castsMissed = 0, castsHit = 0 }
local pile, aimUntil = {}, 0
local RunService = { Heartbeat = { Wait = function() clock += 0.016 end } }
local function aimSwapIn(_, _) end
local function aimPoint() return nil end
local actions = 0
local pileCentre = Vector3 and nil or {}
local KEYS = { "Z", "X", "C", "V", "F" }
local KEYCODE = { Z = "Z", X = "X", C = "C", V = "V", F = "F" }
local CFG
local held = nil
local CD = {}          -- [w..k] = ready at
local COOL = 5         -- every skill cools 5s
local function say(_) end
local function toolType(t) return t.kind end
local function setPose(_) end
local function aimCamera(_) end
local function holdKey(code, _) ev("cast " .. held .. " " .. code) CD[held .. code] = clock + COOL end
local cdStore = {}
local function cdOf(w, k) cdStore[w .. k] = cdStore[w .. k] or {} return cdStore[w .. k] end
local function barReady(w, k) if held ~= w then return nil end return clock >= (CD[w .. k] or 0) end
local function skillReady(w, k) return clock >= (CD[w .. k] or 0) end
local function equip(name) if held ~= name then ev("swap " .. name) held = name end return true end
local TOOLS = { Kitsune = { kind = "Blox Fruit" }, ["Sanguine Art"] = { kind = "Melee" }, Sword = { kind = "Sword" } }
local function usedWeapons()
    local out = {}
    for _, n in ipairs(CFG.WeaponOrder) do
        local w = CFG.Weapons[n]
        local any = w.M1
        for _, k in ipairs(KEYS) do if w[k] then any = true end end
        if w.use and any then table.insert(out, { name = n, cfg = w, tool = TOOLS[n] }) end
    end
    return out
end
local m1Plan = {}
local function probeM1(name, _) m1Plan[name] = { path = "remote", variant = "new", pose = "safe" } return m1Plan[name] end
local function fireM1(_, _) ev("M1 " .. held) end
