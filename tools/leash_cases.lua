
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function run(secs, hurt)
    for _ = 1, secs * 10 do
        clock += 0.1
        actions += 1
        for _, e in ipairs(hurt or {}) do e.hum.Health -= 1 end
        checkPutBack()
    end
end
local function reset()
    clock, actions = 0, 0
    table.clear(pileJoin) table.clear(putBack) table.clear(P.leash)
    CFG.LearnLeash = true
end

-- 1. PORT TOWN: one pulled from 30 takes damage, one pulled from 250 does not
reset()
local near = enemy("Pistol Billionaire", v3(30, 0, 0))
local far  = enemy("Pistol Billionaire", v3(250, 0, 0))
pile = { near, far }
run(4, { near })
check("the far one is put back after 3 s of no damage", putBack[far.model] ~= nil and putBack[near.model] == nil)
local l = P.leash["Pistol Billionaire"]
check("measured: hit up to 30, no damage at 250", l and math.floor(l.ok) == 30 and math.floor(l.bad) == 250,
    l and (tostring(l.ok) .. " / " .. tostring(l.bad)))

-- 2. nobody takes damage (not ours to move, or no hit landing): nothing learned
reset()
local a = enemy("Sky Bandit", v3(20, 0, 0))
local b = enemy("Sky Bandit", v3(200, 0, 0))
pile = { a, b }
run(4, {})
check("no one hit at all: put back, but no distance learned", putBack[b.model] ~= nil and P.leash["Sky Bandit"] == nil,
    P.leash["Sky Bandit"] and tostring(P.leash["Sky Bandit"].bad))

-- 3. the nearer one is the one not taking damage: not a distance problem
reset()
local c = enemy("Brute", v3(20, 0, 0))
local d = enemy("Brute", v3(200, 0, 0))
pile = { c, d }
run(4, { d })
check("the NEAR one takes no damage: no limit learned from it", (P.leash["Brute"] or {}).bad == nil,
    tostring((P.leash["Brute"] or {}).bad))

-- 4. learning off: put back as always, nothing recorded as a limit
reset()
CFG.LearnLeash = false
local e1 = enemy("Pirate", v3(30, 0, 0))
local e2 = enemy("Pirate", v3(250, 0, 0))
pile = { e1, e2 }
run(4, { e1 })
check("learning off: put back, no limit recorded", putBack[e2.model] ~= nil and (P.leash["Pirate"] or {}).bad == nil)

-- ---------------------------------------------------------------- FOUGHT IN PLACE (random mode)
-- 5. no damage from high for 6 s: come close; never teleported home
reset()
P.pileInPlace, P.forceClose, P.randomCant = true, false, 0
local st = enemy("Pirate", v3(200, 0, 0))
pile = { st }
run(7, {})
check("in place, no damage 6 s from high: comes close", P.forceClose == true and putBack[st.model] == nil)
-- 6. damage once close: stays, the clock resets, not skipped
run(3, { st })
check("close now and it takes damage: kept, not skipped", P.randomSkip[st.model] == nil)
-- 7. none for 15 s even close: skipped a minute, counted
local st2 = enemy("Brute", v3(0, 0, 0))
pile = { st2 }
P.forceClose = true
run(16, {})
check("in place, no damage 15 s even close: skipped for a minute and counted",
    P.randomSkip[st2.model] ~= nil and P.randomCant == 1 and putBack[st2.model] == nil)
P.pileInPlace, P.forceClose = false, false

-- ---------------------------------------------------------------- WHY NO DAMAGE (the note)
-- 8. pulled, but the server has it elsewhere: NOT OURS, with the gap
reset()
table.clear(P.noDamage)
local ghostly = enemy("Raid Brute", v3(10, 0, 0))
local fine    = enemy("Raid Brute", v3(20, 0, 0))
lastDest[ghostly.model] = v3(0, 0, 0)
ghostly.root.Position = v3(80, 0, 0)          -- replication put it back where it really is
lastDest[fine.model] = v3(0, 0, 0)
pile = { fine, ghostly }
run(4, { fine })
check("not ours: the note says NOT OURS with the gap, and pulled",
    P.noDamage[1] and P.noDamage[1]:find("NOT OURS (really 80", 1, true) and P.noDamage[1]:find("pulled:", 1, true),
    P.noDamage[1])

-- 9. held where it was put, in reach, no shield, still no damage: the server refused it
reset()
table.clear(P.noDamage)
local a9 = enemy("Raid Archer", v3(5, 0, 0))
local b9 = enemy("Raid Archer", v3(6, 0, 0))
lastDest[a9.model], lastDest[b9.model] = v3(0, 0, 0), v3(0, 0, 0)
pile = { a9, b9 }
run(4, { a9 })
check("ours + in reach + no damage: 'held, ours', 'in reach', its place in the pile",
    P.noDamage[1] and P.noDamage[1]:find("held, ours", 1, true) and P.noDamage[1]:find("in reach (20 of 60)", 1, true)
        and P.noDamage[1]:find("pile 2 of 2", 1, true), P.noDamage[1])

-- 10. fought in place: no ownership claim (lastDest is an old pull's), the stage named
reset()
table.clear(P.noDamage)
P.pileInPlace, P.forceClose = true, false
local c10 = enemy("Raid Brute", v3(0, 0, 0))
lastDest[c10.model] = v3(500, 0, 0)
pile = { c10 }
run(7, {})
check("in place: 'in place, from high', no NOT OURS from an old pull",
    P.noDamage[1] and P.noDamage[1]:find("in place, from high", 1, true) and not P.noDamage[1]:find("OURS", 1, true),
    P.noDamage[1])
P.pileInPlace, P.forceClose = false, false

print(all and "ALL PASS" or "SOME FAILED")
