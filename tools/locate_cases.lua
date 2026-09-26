
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
    CFG.Magnet, CFG.PullOthers = true, true
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

print(all and "ALL PASS" or "SOME FAILED")
