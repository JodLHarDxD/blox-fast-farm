
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

local kitsuneFruit = tool("Kitsune Fruit")            -- the physical one, to eat or store
local rocket       = tool("Rocket Fruit", true)       -- with its EatRemote
local oddName      = tool("Mystery Thing", true)      -- EatRemote deep inside, odd name
local power        = tool("Kitsune-Kitsune")          -- your EATEN fruit's power
local melee        = tool("Godhuman")
local chalice      = tool("God's Chalice")

check("'X Fruit' is a physical fruit", P.isPhysicalFruit(kitsuneFruit))
check("an EatRemote anywhere inside = physical fruit", P.isPhysicalFruit(rocket) and P.isPhysicalFruit(oddName))
check("your eaten fruit's power is NOT (Kitsune-Kitsune stays a weapon)", not P.isPhysicalFruit(power))
check("melee and the God's Chalice are not fruits", not P.isPhysicalFruit(melee) and not P.isPhysicalFruit(chalice))

BACKPACK.list = { kitsuneFruit, power, melee, rocket, chalice }
local names = {}
for _, t in ipairs(toolNames()) do names[t.Name] = true end
check("never listed as a weapon", not names["Kitsune Fruit"] and not names["Rocket Fruit"]
    and names["Kitsune-Kitsune"] and names["Godhuman"])
check("never found to equip", findTool("Kitsune Fruit") == nil and findTool("Kitsune-Kitsune") == power)
check("the chalice is still found (the hunt's stop check)", findTool("God's Chalice") == chalice)

-- A fruit in hand (Roblox equips a touched tool): the click would EAT it
HELD = kitsuneFruit
pressM1()
check("fruit in hand: no click, it is put away", LOG.clicks == 0 and LOG.unequips == 1 and HELD == nil,
    LOG.clicks .. " clicks")
HELD = melee
pressM1()
check("a weapon in hand: the click goes through", LOG.clicks > 0)

print(all and "ALL PASS" or "SOME FAILED")
