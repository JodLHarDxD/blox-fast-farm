
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b, tol) return a and b and (a - b).Magnitude <= (tol or 1) end
local function reset()
    WORLD.spawns, WORLD.parked, WORLD.loaded = {}, {}, {}
    table.clear(campCache)
    for k in pairs(homePos) do homePos[k] = nil end
    ME.Position = v3(0, 0, 0)
    CFG.Magnet, CFG.PullOthers, CFG.PullAll = true, true, false
end

-- The Sky Bandit case: table point = the quest giver's island, 490 studs off.
local TABLE_SKY = v3(-4841.7, 717.8, -2666.9)
local CAMP_SKY  = v3(-4953, 296, -2899)

-- 1. no enemies loaded: the game's spawn points win over the table
reset()
for i = 0, 5 do table.insert(WORLD.spawns, part("Sky Bandit", CAMP_SKY + v3(i * 10, 0, 0))) end
table.insert(WORLD.spawns, part("Dark Master", v3(-5259, 391, -2229)))
local pos, src = campOf("Sky Bandit", TABLE_SKY)
check("spawn points beat the table", near(pos, CAMP_SKY + v3(25, 0, 0)) and src == "spawn points",
    tostring(src))

-- 2. old "[Lv. 150]" names still match
reset()
table.insert(WORLD.spawns, part("Sky Bandit [Lv. 150]", CAMP_SKY))
pos, src = campOf("Sky Bandit", TABLE_SKY)
check("'Sky Bandit [Lv. 150]' spawn part matches", near(pos, CAMP_SKY), tostring(src))

-- 3. two camps: the bigger one
reset()
for i = 0, 1 do table.insert(WORLD.spawns, part("Bandit", v3(i * 5, 0, 0))) end
for i = 0, 4 do table.insert(WORLD.spawns, part("Bandit", v3(2000 + i * 5, 0, 0))) end
pos = campOf("Bandit", nil)
check("two camps: the biggest group", near(pos, v3(2010, 0, 0)), pos and pos.X)

-- 4. no spawn points: parked enemies in ReplicatedStorage
reset()
table.insert(WORLD.parked, model("Sky Bandit", CAMP_SKY))
pos, src = campOf("Sky Bandit", TABLE_SKY)
check("parked enemies when there are no spawn points", near(pos, CAMP_SKY) and src == "parked enemies",
    tostring(src))

-- 5. the game knows nothing: the table, and it says so
reset()
pos, src = campOf("Sky Bandit", TABLE_SKY)
check("table only as the last resort", near(pos, TABLE_SKY) and src == "table", tostring(src))

-- 6. THE BUG: loaded Sky Bandits 490 studs from the table point are pulled
reset()
ME.Position = CAMP_SKY + v3(0, 20, 0)
for i = 1, 7 do table.insert(WORLD.loaded, enemy("Sky Bandit", CAMP_SKY + v3(i * 8, 0, 0))) end
local cur = { name = "Sky Bandit", spot = TABLE_SKY }
local pl, centre = buildPile(cur, { ["Sky Bandit"] = true })
check("loaded enemies far from the table point ARE pulled (was 0 held)", #pl == 7 and near(centre, CAMP_SKY + v3(32, 0, 0)),
    "held " .. #pl)

-- 7. the camp is the one nearest you; the same species across the map is left alone
reset()
ME.Position = v3(0, 0, 0)
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Bandit", v3(i * 10, 0, 0))) end
for i = 1, 4 do table.insert(WORLD.loaded, enemy("Bandit", v3(3000 + i * 10, 0, 0))) end
pl = buildPile({ name = "Bandit" }, { Bandit = true })
check("pile = the camp nearest you only", #pl == 3, "held " .. #pl)

-- 8. other picked species only if they spawned in this camp
reset()
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Bandit", v3(i * 10, 0, 0))) end
table.insert(WORLD.loaded, enemy("Monkey", v3(30, 0, 10)))     -- same camp
table.insert(WORLD.loaded, enemy("Monkey", v3(900, 0, 0)))     -- another camp
pl = buildPile({ name = "Bandit" }, { Bandit = true, Monkey = true })
check("other species: same camp yes, other camp no", #pl == 4, "held " .. #pl)

-- 9. nothing of the species loaded = empty (the step then flies to campOf)
reset()
table.insert(WORLD.loaded, enemy("Monkey", v3(10, 0, 0)))
pl = buildPile({ name = "Bandit" }, { Bandit = true, Monkey = true })
check("none of the quest species loaded: empty", #pl == 0, "held " .. #pl)

-- 10. magnet off: the nearest one, where it stands
reset()
CFG.Magnet = false
table.insert(WORLD.loaded, enemy("Bandit", v3(50, 0, 0)))
table.insert(WORLD.loaded, enemy("Bandit", v3(10, 0, 0)))
pl, centre = buildPile({ name = "Bandit" }, { Bandit = true })
check("magnet off: nearest only", #pl == 1 and near(centre, v3(10, 0, 0)), "held " .. #pl)

-- 11. nearestLoaded finds it at any distance
reset()
table.insert(WORLD.loaded, enemy("Sky Bandit", CAMP_SKY))
local e = nearestLoaded("Sky Bandit")
check("nearestLoaded at any distance", e ~= nil and near(e.root.Position, CAMP_SKY))

-- ---------------------------------------------------------------- PullAll
-- (each case its own species: the spots seen per species are remembered)

-- 12. THE USER'S CASE: 3 in the pile, 3 more spawn 450 studs off in the same
--     camp -> all 6 pulled, the pile at the camp's middle
reset()
CFG.PullAll = true
for _, x in ipairs({ 0, 150, 300, 450 }) do table.insert(WORLD.spawns, part("Pirate", v3(x, 0, 0))) end
ME.Position = v3(0, 20, 0)
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Pirate", v3(i * 4, 0, 0))) end
pl, centre = buildPile({ name = "Pirate" }, { Pirate = true })
check("PullAll: first three pulled", #pl == 3, "held " .. #pl)
local first = centre
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Pirate", v3(450 - i * 4, 0, 0))) end
pl, centre = buildPile({ name = "Pirate" }, { Pirate = true })
check("PullAll: 3 new spawns 450 away join at once (was: after the first 3 died)", #pl == 6, "held " .. #pl)
check("PullAll: pile centre does not move when they join", near(first, centre) and near(centre, v3(225, 0, 0)),
    centre and centre.X)
check("PullAll: farthest pull reported", P.pileReach and math.abs(P.pileReach - 225) < 1, P.pileReach)

-- 13. the middle is the one where the FARTHEST pull is shortest, not the mean
reset()
CFG.PullAll = true
for i = 0, 4 do table.insert(WORLD.spawns, part("Brute", v3(i * 5, 0, 0))) end
table.insert(WORLD.spawns, part("Brute", v3(380, 0, 0)))
table.insert(WORLD.loaded, enemy("Brute", v3(2, 0, 0)))
pl, centre = buildPile({ name = "Brute" }, { Brute = true })
check("camp middle = smallest circle (190), not the mean (70)", near(centre, v3(190, 0, 0)), centre and centre.X)

-- 14. three corners: the circle through them
reset()
CFG.PullAll = true
for _, p in ipairs({ v3(0, 0, 0), v3(100, 0, 0), v3(50, 0, 80) }) do
    table.insert(WORLD.spawns, part("Chief", p))
end
table.insert(WORLD.loaded, enemy("Chief", v3(1, 0, 1)))
pl, centre = buildPile({ name = "Chief" }, { Chief = true })
check("acute triangle: circumcentre (50, 24.4)", near(centre, v3(50, 0, 24.375), 0.1),
    centre and (centre.X .. "," .. centre.Z))

-- 15. no spawn points from the game: the spots seen are the camp
reset()
CFG.PullAll = true
for _, x in ipairs({ 0, 100, 300 }) do table.insert(WORLD.loaded, enemy("Toga", v3(x, 0, 0))) end
pl, centre = buildPile({ name = "Toga" }, { Toga = true })
check("no game spawn points: middle of the spots seen", #pl == 3 and near(centre, v3(150, 0, 0)),
    centre and centre.X)

-- 16. two camps loaded: every one pulled, to the middle of the camp you are at
reset()
CFG.PullAll = true
for i = 0, 2 do table.insert(WORLD.spawns, part("Sniper", v3(i * 10, 0, 0))) end
for i = 0, 2 do table.insert(WORLD.spawns, part("Sniper", v3(3000 + i * 10, 0, 0))) end
ME.Position = v3(0, 20, 0)
for i = 0, 1 do table.insert(WORLD.loaded, enemy("Sniper", v3(i * 10, 0, 0))) end
for i = 0, 1 do table.insert(WORLD.loaded, enemy("Sniper", v3(3000 + i * 10, 0, 0))) end
pl, centre = buildPile({ name = "Sniper" }, { Sniper = true })
check("two camps: only yours (the other is 3000 away, past the pull limit), centre at YOUR camp",
    #pl == 2 and near(centre, v3(10, 0, 0)), "held " .. #pl .. " at " .. tostring(centre and centre.X))

-- 17. heights: the middle height of the camp
reset()
CFG.PullAll = true
table.insert(WORLD.spawns, part("Sky", v3(0, 280, 0)))
table.insert(WORLD.spawns, part("Sky", v3(40, 300, 0)))
table.insert(WORLD.loaded, enemy("Sky", v3(0, 280, 0)))
pl, centre = buildPile({ name = "Sky" }, { Sky = true })
check("middle height of the camp", near(centre, v3(20, 290, 0)), centre and centre.Y)

-- ---------------------------------------------------------------- RAID MODE
-- 18. every kind of enemy near the raid island goes in; one far off does not
reset()
CFG.RaidRadius = 450
P.raidAt = v3(1000, 0, 1000)
ME.Position = v3(1000, 45, 1000)
table.insert(WORLD.loaded, enemy("Raid Brute", v3(1010, 0, 1000)))
table.insert(WORLD.loaded, enemy("Raid Archer", v3(990, 0, 1020)))
table.insert(WORLD.loaded, enemy("Order", v3(1100, 0, 900)))
table.insert(WORLD.loaded, enemy("Bandit", v3(3000, 0, 3000)))     -- another island
pl, centre = buildRaidPile()
local kinds = {}
for _, e in ipairs(pl) do kinds[e.name] = true end
check("raid: every kind on the island pulled (3 kinds), the far one not",
    #pl == 3 and kinds["Raid Brute"] and kinds["Raid Archer"] and kinds["Order"] and not kinds["Bandit"],
    "held " .. #pl)
check("raid: piled at the middle of where they spawned",
    near(centre, v3(1045, 0, 960), 1), centre and (centre.X .. "," .. centre.Z))

-- 19. outside a raid: everything within the radius of YOU
reset()
CFG.RaidRadius = 450
P.raidAt = nil
ME.Position = v3(0, 20, 0)
local pirate19 = enemy("Pirate", v3(100, 0, 0))
table.insert(WORLD.loaded, pirate19)
table.insert(WORLD.loaded, enemy("Brute", v3(-200, 0, 50)))
table.insert(WORLD.loaded, enemy("Sea Beast", v3(900, 0, 0)))
pl = buildRaidPile()
-- Raid enemies have no leash (user, 2026-09-28): the Brute 304 away goes in
-- the same pile - no pull limit in raid mode.
check("outside a raid: everything near you, any kind (2), not the far one", #pl == 2, "held " .. #pl)

-- 20. nobody near: empty
reset()
P.raidAt = v3(5000, 0, 5000)
table.insert(WORLD.loaded, enemy("Pirate", v3(0, 0, 0)))
pl = buildRaidPile()
check("raid: no enemy near the island = empty (the step waits over it)", #pl == 0, "held " .. #pl)

-- 21. more than GrabMax: the nearest ones
reset()
CFG.RaidRadius, CFG.GrabMax = 450, 5
P.raidAt = v3(0, 0, 0)
for i = 1, 9 do table.insert(WORLD.loaded, enemy("Raider " .. i, v3(i * 20, 0, 0))) end
pl, centre = buildRaidPile()
-- Capped, and the ones kept are those nearest the pile's middle (the
-- shortest pulls), not the ones nearest the island's point.
local worst = 0
for _, e in ipairs(pl) do worst = math.max(worst, (e.root.Position - centre).Magnitude) end
check("raid: capped at Most in one pile, the shortest pulls kept", #pl == 5 and worst <= 41, "held " .. #pl .. " worst " .. worst)
CFG.GrabMax = 12
P.raidAt = nil

-- ---------------------------------------------------------------- HOW FAR ONE CAN BE PULLED
-- A Port Town-like camp: side A (x 0-40) and side B (x 380-420), one camp
-- (340 apart, linked), 210 from its middle to either side.
local function portTown(name)
    for _, x in ipairs({ 0, 20, 40, 380, 400, 420 }) do table.insert(WORLD.spawns, part(name, v3(x, 0, 0))) end
end

-- 22. limit 300: the whole camp fits -> one pile at the middle, all 6
reset()
CFG.PullAll, CFG.MaxPull = true, 300
portTown("Billionaire A")
ME.Position = v3(10, 60, 0)
for _, x in ipairs({ 5, 25, 35, 385, 405, 415 }) do table.insert(WORLD.loaded, enemy("Billionaire A", v3(x, 0, 0))) end
pl, centre = buildPile({ name = "Billionaire A" }, { ["Billionaire A"] = true })
check("limit 300, camp 210 from its middle: one pile of 6 at the middle", #pl == 6 and near(centre, v3(210, 0, 0)),
    "held " .. #pl .. " at " .. tostring(centre and centre.X))

-- 23. limit 150: side A only (you are there), B left alone for now
reset()
CFG.PullAll, CFG.MaxPull = true, 150
portTown("Billionaire B")
ME.Position = v3(10, 60, 0)
for _, x in ipairs({ 5, 25, 35, 385, 405, 415 }) do table.insert(WORLD.loaded, enemy("Billionaire B", v3(x, 0, 0))) end
pl, centre = buildPile({ name = "Billionaire B" }, { ["Billionaire B"] = true })
local allA = true
for _, e in ipairs(pl) do if e.root.Position.X > 100 then allA = false end end
check("limit 150: side A only, piled at A's middle (x 20)", #pl == 3 and allA and near(centre, v3(20, 0, 0)),
    "held " .. #pl .. " at " .. tostring(centre and centre.X))
check("limit 150: the panel says it is one side at a time", P.pileSplit ~= nil, P.pileSplit)

-- 24. side A cleared: the pile moves to side B
WORLD.loaded = {}
for _, x in ipairs({ 385, 405, 415 }) do table.insert(WORLD.loaded, enemy("Billionaire B", v3(x, 0, 0))) end
pl, centre = buildPile({ name = "Billionaire B" }, { ["Billionaire B"] = true })
check("side A empty: side B's 3, at B's middle (x 400)", #pl == 3 and near(centre, v3(400, 0, 0)),
    "held " .. #pl .. " at " .. tostring(centre and centre.X))

-- 25. measured: one stopped taking damage 150 from its spawn -> limit 135
reset()
CFG.PullAll, CFG.MaxPull, CFG.LearnLeash = true, 300, true
portTown("Billionaire C")
P.leash["Billionaire C"] = { ok = 90, bad = 150 }
check("measured 'no damage at 150' -> pulls at most 135", pullLimit("Billionaire C") == 135, pullLimit("Billionaire C"))
ME.Position = v3(10, 60, 0)
for _, x in ipairs({ 5, 25, 35, 385, 405, 415 }) do table.insert(WORLD.loaded, enemy("Billionaire C", v3(x, 0, 0))) end
pl = buildPile({ name = "Billionaire C" }, { ["Billionaire C"] = true })
check("so the camp is done one side at a time (3)", #pl == 3, "held " .. #pl)
CFG.LearnLeash = false
check("learning off: back to your 300", pullLimit("Billionaire C") == 300, pullLimit("Billionaire C"))
CFG.MaxPull, CFG.LearnLeash = 300, true

-- ---------------------------------------------------------------- RANDOM MODE
local function rreset()
    reset()
    table.clear(putBack)
    P.randomSkip, P.randomAt = {}, nil
    CFG.RandomRadius, CFG.MaxPull, CFG.LearnLeash, CFG.GrabMax = 750, 300, true, 12
    table.clear(P.leash)
    pileCentre = nil
end

-- 26. mixed kinds close together: one pile, all of them
rreset()
ME.Position = v3(0, 40, 0)
for i, n in ipairs({ "Pirate", "Brute", "Gunner", "Captain" }) do
    table.insert(WORLD.loaded, enemy(n, v3(i * 30, 0, 0)))
end
local pl2, c2, inPlace = buildRandomPile()
check("random: 4 kinds within the limit = one pile of 4", #pl2 == 4 and not inPlace, "held " .. #pl2)

-- 27. two groups on opposite corners of the yard (~560 apart): the near group
--     only - the far one is NOT dragged past its limit
rreset()
ME.Position = v3(0, 40, 0)
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Raider", v3(i * 20, 0, 0))) end
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Raider", v3(400 + i * 20, 0, 400))) end
pl2, c2 = buildRandomPile()
local farIn = false
for _, e in ipairs(pl2) do if e.root.Position.X > 300 then farIn = true end end
check("random: diagonal groups - near group piled, far one not dragged", #pl2 == 3 and not farIn, "held " .. #pl2)

-- 28. near group dead: the far corner is the next pile (nobody left out)
WORLD.loaded = {}
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Raider", v3(400 + i * 20, 0, 400))) end
pl2, c2 = buildRandomPile()
check("random: then the far corner gets its own pile", #pl2 == 3 and near(c2, v3(440, 0, 400), 1),
    "held " .. #pl2 .. " at " .. tostring(c2 and c2.X))

-- 29. one that took no damage when pulled is fought WHERE IT STANDS, after the free ones
rreset()
ME.Position = v3(0, 40, 0)
local stubborn = enemy("Pirate", v3(200, 5, 0))
local other = enemy("Pirate", v3(20, 0, 0))
WORLD.loaded = { stubborn, other }
putBack[stubborn.model] = 1e9
pl2, c2, inPlace = buildRandomPile()
check("random: free ones first (the put-back one is not in the pile)", #pl2 == 1 and pl2[1] == other and not inPlace)
WORLD.loaded = { stubborn }
pl2, c2, inPlace = buildRandomPile()
check("random: then the put-back one, fought in place at its own position",
    #pl2 == 1 and pl2[1] == stubborn and inPlace and near(c2, v3(200, 5, 0), 0.1), tostring(inPlace))

-- 30. the area: round you, or round the castle raid area when there
rreset()
ME.Position = v3(0, 40, 0)
WORLD.loaded = { enemy("Pirate", v3(700, 0, 0)), enemy("Pirate", v3(900, 0, 0)) }
check("random: 750 round you - the one at 900 is out", #buildRandomPile() == 1)
P.randomAt = v3(900, 0, 0)
check("random at the castle: round the raid area (at least 800) - both in", #buildRandomPile() == 2)

-- 31. one that cannot be hurt at all is skipped for a minute, not fought for ever
rreset()
local ghost = enemy("Pirate", v3(10, 0, 0))
WORLD.loaded = { ghost }
P.randomSkip[ghost.model] = 1e9
check("random: an unhurtable one (skipped) is left out", #buildRandomPile() == 0)
P.randomSkip = {}

-- ---------------------------------------------------------------- RAID: THE STUCK WAVE (user, 2026-09-28)
-- "5 in the raid, 2 never take damage; sometimes it stops and I finish them
-- by hand, then the next wave works." Raid pulled everyone to one middle with
-- no limit; one dragged out of its area took no damage, was put back, and
-- was IGNORED - so the pile went empty while it lived and the farm waited.

-- 32. two groups on the raid island ~560 apart: ONE pile of all six - raid
--     enemies roam the island to reach you, there is no leash to respect
rreset()
CFG.RaidRadius = 450
P.raidAt = v3(0, 0, 0)
ME.Position = v3(-200, 40, -200)
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Raid Brute", v3(-200 + i * 10, 0, -200))) end
for i = 1, 3 do table.insert(WORLD.loaded, enemy("Raid Brute", v3(200 + i * 10, 0, 200))) end
pl2 = buildRaidPile()
local dragged = false
for _, e in ipairs(pl2) do if e.root.Position.X > 0 then dragged = true end end
check("raid: no pull limit - both groups in one pile", #pl2 == 6 and dragged, "held " .. #pl2)

-- 33. the one put back (no damage when pulled) is fought IN PLACE once the
--     free ones are dead - never left alive while the farm waits
rreset()
CFG.RaidRadius = 450
P.raidAt = v3(0, 0, 0)
ME.Position = v3(0, 40, 0)
local stuck = enemy("Raid Archer", v3(150, 5, 0))
local free1 = enemy("Raid Archer", v3(10, 0, 0))
WORLD.loaded = { stuck, free1 }
putBack[stuck.model] = 1e9
pl2, c2, inPlace = buildRaidPile()
check("raid: free ones first", #pl2 == 1 and pl2[1] == free1 and not inPlace)
WORLD.loaded = { stuck }
pl2, c2, inPlace = buildRaidPile()
check("raid: then the put-back one, in place at its own spot (the wave is not left stuck)",
    #pl2 == 1 and pl2[1] == stuck and inPlace and near(c2, v3(150, 5, 0), 0.1), "held " .. #pl2 .. " " .. tostring(inPlace))
P.raidAt = nil

print(all and "ALL PASS" or "SOME FAILED")
