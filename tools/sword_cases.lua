
-- he is not here, not loaded: nothing here, said why, nothing bought
reset()
local r = swordStep(0)
check("not here: false, why, no buy", r == false and E.why == "the Legendary Sword Dealer is not here now"
    and count("LegendarySwordDealer 1") == 1 and count("LegendarySwordDealer 2") == 0
    and E.swordOffer == "he is not here now", E.why)
check("your swords read once (the item list)", count("GetAllItemValues") == 1)
swordStep(0)
check("...and not again in the same hunt", count("GetAllItemValues") == 1)

-- not answered, but his model is loaded: flown to him once, asked again
reset() AT = V(1, 2, 3)
r = swordStep(0)
check("loaded but silent: one flight, asked twice, then next server", r == false and FLIGHTS == 1
    and count("LegendarySwordDealer 1") == 2, FLIGHTS)
swordStep(0)
check("no second flight in the same server", FLIGHTS == 1)

-- not answered, his model only PARKED in ReplicatedStorage (not in the
-- world): never flown to (user, 2026-10-11: every server it flew them under
-- Kingdom of Rose, into the sea) - next server
reset() AT = V(1, -60, 3) PARKED = true
r = swordStep(0)
check("silent + only a parked copy (ReplicatedStorage): no flight, next server", r == false and FLIGHTS == 0
    and count("LegendarySwordDealer 1") == 1 and E.why == "the Legendary Sword Dealer is not here now", FLIGHTS)

-- he sells one but refuses from afar, his model parked: flown to (he IS here)
reset() AT = V(1, 2, 3) PARKED = true OFFER = "Saishi" BUY = { nil, 1 }
r = swordStep(0)
check("he sells one, refuses from afar, model parked: one flight, bought there", r == true and FLIGHTS == 1
    and CFG.SwordWant.Saishi == false, E.swordNote)

-- in front of him he answers: bought there
reset() AT = V(1, 2, 3) OFFER = { nil, "Saishi" } BUY = { 1 }
r = swordStep(0)
check("answered near him: bought", r == true and FLIGHTS == 1 and CFG.SwordWant.Saishi == false
    and E.tally.swords == 1, E.swordNote)

-- THE ONE YOU NEED, bought from where you stand (old name answered)
reset() OFFER = "Shisui" BUY = { 1 }
r = swordStep(0)
check("old name Shisui = Shizu: bought from here, no flight", r == true and FLIGHTS == 0
    and CFG.SwordWant.Shizu == false and E.tally.swords == 1 and E.swordNote == "Shizu: bought", E.swordNote)
check("bought = a notice", NOTES[1] == "Legendary sword: Shizu")
check("the others stay on", CFG.SwordWant.Saishi == true and CFG.SwordWant.Oroshi == true)
-- next step in the same server: he still sells it, you have it -> next server
r = swordStep(0)
check("after the buy: next server", r == false and E.why:find("Shizu", 1, true) ~= nil
    and count("LegendarySwordDealer 2") == 1, E.why)

-- one you switched off
reset() CFG.SwordWant.Oroshi = false OFFER = "Oroshi"
r = swordStep(0)
check("not wanted: false, names it, no buy", r == false and E.why:find("Oroshi", 1, true) ~= nil
    and count("LegendarySwordDealer 2") == 0, E.why)

-- something that is not one of the three
reset() OFFER = "Yama"
r = swordStep(0)
check("not one of the three: false", r == false and E.why:find("not one of the three", 1, true) ~= nil, E.why)

-- YOURS ALREADY, from the game's item list
reset() ITEMS = { { Key = "Mastery", ItemId = 69, Value = 120 } } OFFER = "Saishi"
r = swordStep(0)
check("owned (item list): switched off at the start, not bought", r == false and CFG.SwordWant.Saishi == false
    and count("LegendarySwordDealer 2") == 0, E.why)
reset() ITEMS = { { Key = "Quantity", ItemId = 70, Value = 0 } }
swordStep(0)
check("a count of 0 is not owning it", CFG.SwordWant.Oroshi == true)
reset() ITEMS = { { Key = "Whatever", ItemId = 1142, Value = 1 } }
swordStep(0)
check("its moves' id counts too", CFG.SwordWant.Shizu == false)
-- no item list: the legacy list, old names too
reset() ITEMS = nil INV = { { Name = "Wando", Type = "Sword" } }
swordStep(0)
check("legacy list, old name Wando = Oroshi owned", CFG.SwordWant.Oroshi == false and CFG.SwordWant.Shizu == true)
-- carried
reset() CARRY = { "Shizu", "Combat" }
swordStep(0)
check("carried in the backpack = owned", CFG.SwordWant.Shizu == false and CFG.SwordWant.Saishi == true)

-- all three yours: the hunt stops and says what is next
reset() ITEMS = { { Key = "M", ItemId = 66 }, { Key = "M", ItemId = 69 }, { Key = "M", ItemId = 70 } }
r = swordStep(0)
check("all three yours: stopped, the next step named, nothing asked", r == true and STOPPED == "swords done"
    and E.swordNote:find("Mysterious Man", 1, true) ~= nil and count("LegendarySwordDealer 1") == 0, E.swordNote)

-- money first
reset() BELI = 1500000
r = swordStep(0)
check("under $2,000,000: stopped before asking", r == true and STOPPED == "not enough money"
    and count("LegendarySwordDealer 1") == 0, E.swordNote)
reset() BELI = nil OFFER = "Saishi" BUY = { 1 }
r = swordStep(0)
check("money unreadable: goes on", r == true and CFG.SwordWant.Saishi == false)

-- refused from afar: flown to him, bought there
reset() OFFER = "Oroshi" BUY = { "nope", 1 } AT = V(10, 20, 30)
r = swordStep(0)
check("refused from afar: one flight, bought in front of him", r == true and FLIGHTS == 1
    and CFG.SwordWant.Oroshi == false and E.tally.swords == 1, E.swordNote)
-- refused, and not loaded: next server, switch left on
reset() OFFER = "Oroshi" BUY = { "nope" }
r = swordStep(0)
check("refused, no model: next server, switch on", r == false and CFG.SwordWant.Oroshi == true
    and E.why:find("not bought", 1, true) ~= nil, E.why)
-- "already yours" from the dealer
reset() OFFER = "Saishi" BUY = { 2 }
r = swordStep(0)
check("dealer says already yours: switch off, not counted, no notice", r == true and CFG.SwordWant.Saishi == false
    and (E.tally.swords or 0) == 0 and #NOTES == 0, E.swordNote)
-- the dealer says not enough money
reset() OFFER = "Saishi" BUY = { 0 }
r = swordStep(0)
check("not enough money at the till: stopped, switch on", r == true and STOPPED == "not enough money"
    and CFG.SwordWant.Saishi == true, E.swordNote)

-- another sea: stops, asks nothing (no hopping round the wrong sea)
reset() SEA = 3
r = swordStep(0)
check("Third Sea: stopped, nothing asked", r == true and STOPPED == "not the Second Sea" and #CALLS == 0, STOPPED)
-- no character yet: waits, asks nothing (a "not here" now could be wrong)
reset() ALIVE = false
r = swordStep(0)
check("no character yet: waits, nothing asked", r == true and #CALLS == 0)

if all then print("ALL PASS") end
