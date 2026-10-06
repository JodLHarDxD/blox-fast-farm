local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local G = P.magnet
local plan = G._t.plan

check("plan: a magnet held - sail", plan({ magnet = 1, ember = 0, scrap = 0 }) == "sail")
check("plan: 15 embers + 10 scrap - craft", plan({ magnet = 0, ember = 15, scrap = 10 }) == "craft")
check("plan: scrap short - scrap first", plan({ magnet = 0, ember = 30, scrap = 4 }) == "scrap")
check("plan: scrap enough, embers short - embers", plan({ magnet = 0, ember = 3, scrap = 10 }) == "embers")

-- Have one: sail at once.
INV = { magnet = 1, ember = 0, scrap = 0 }
check("step: magnet in your inventory - sail", G.step(1) == false and string.find(G.note, "in your inventory", 1, true) ~= nil)

-- Enough materials: crafted from where you are, no flight.
INV = { magnet = 0, ember = 15, scrap = 10 }
G.inv = nil
FLIGHTS = {}
check("step: enough - crafting (busy)", G.step(1) == true)
check("craft from here: the magnet made, no flight", INV.magnet == 1 and #FLIGHTS == 0 and G.crafts == 1)
G.inv = nil
check("then: sail", G.step(1) == false)

-- The craft only at the Dragon Hunter: flown there.
CRAFT_WORKS = "npc"
INV = { magnet = 0, ember = 20, scrap = 12 }
G.inv, FLIGHTS = nil, {}
G.step(1)
check("craft refused from afar: flown to the Dragon Hunter, crafted there", INV.magnet == 1 and #FLIGHTS == 1
    and math.abs(FLIGHTS[1].X - 5864) < 1, #FLIGHTS)

-- Never crafts: 3 refusals, then sail without it.
CRAFT_WORKS = "never"
INV = { magnet = 0, ember = 15, scrap = 10 }
G.inv, G.tries = nil, 0
for _ = 1, 3 do G.inv = nil G.step(1) end
check("craft refused 3 times: given up, sailing without it", G.gaveUp ~= nil and G.step(1) == false
    and string.find(G.note, "without", 1, true) ~= nil, tostring(G.gaveUp))
G.gaveUp, G.tries = nil, 0
CRAFT_WORKS = "anywhere"

-- Scrap short: Forest Pirates fought (loaded), else flown to their camp.
INV = { magnet = 0, ember = 20, scrap = 2 }
G.inv, FIGHTS, FLIGHTS = nil, {}, {}
LOADED = {}
G.step(1)
check("scrap short, none loaded: flown to the Forest Pirates", #FLIGHTS == 1 and math.abs(FLIGHTS[1].X + 13206) < 1
    and #FIGHTS == 0, #FLIGHTS)
LOADED = { ["Forest Pirate"] = true }
G.inv = nil
G.step(1)
check("scrap short, Forest Pirates here: fought", FIGHTS[1] == "Forest Pirate", tostring(FIGHTS[1]))
LOADED = { ["Pirate Millionaire"] = true }
G.inv = nil
G.step(1)
check("...or Pirate Millionaires when they are the ones here", FIGHTS[2] == "Pirate Millionaire", tostring(FIGHTS[2]))

-- Embers short: the Ember hunt's quests, borrowed.
INV = { magnet = 0, ember = 3, scrap = 10 }
G.inv, EMBER_CALLS = nil, {}
check("embers short: busy", G.step(1) == true)
check("...the Ember hunt run BORROWED (it does not stop the farm)", EMBER_CALLS[1] == true)
-- Its quests blocked (no Dragon Talon 500 / Yellow Belt): sail without it.
P.ember.blockNext = "the Dragon Hunter gives no quest"
G.inv = nil
check("ember quests blocked: sailing without the magnet, says why", G.step(1) == false
    and string.find(tostring(G.gaveUp), "no quest", 1, true) ~= nil, tostring(G.gaveUp))
P.ember.blockNext, G.gaveUp = nil, nil

-- Off / unreadable.
CFG.SeaMagnet = false
check("switch off: sail", G.step(1) == false)
CFG.SeaMagnet = true
READABLE = false
G.inv = nil
check("inventory unreadable: sail without it, said", G.step(1) == false and string.find(G.note, "not readable", 1, true) ~= nil)
READABLE = true

realPrint(all and "ALL PASS" or "SOME FAILED")
