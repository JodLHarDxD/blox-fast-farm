
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    _G.print((cond and "PASS " or "FAIL ") .. name)
    if not cond then _G.print("  " .. tostring(detail)) all = false end
end
local function grab()
    local b = { bush = bush, names = berryNames(bush.attrs), pos = Vector3.new(0, 0, 0) }
    grabBerry(b, 0)
end

-- 1. THE BUG (2026-09-30, Velocity): the executor HAS fireproximityprompt, but
-- the game refuses its instant trigger; a real hold is taken. Picked.
reset({ hold = true, fire = false })
grab()
check("instant fire refused, real hold picks it", HAVE["Pink Pig Berry"] == 4
    and string.find(E.berryNote, "PICKED", 1, true) == 1, E.berryNote)
check("the hold went first, not the instant fire", HOLDS >= 1 and FIRES == 0, HOLDS .. " holds, " .. FIRES .. " fires")
check("the hold lasted the prompt's HoldDuration", string.find(E.berryNote, "by hold", 1, true) ~= nil, E.berryNote)
check("the console says so", PRINTED[#PRINTED] == "[BFF] berry: " .. E.berryNote, PRINTED[#PRINTED])

-- 2. a long hold (2 s) is waited out in full
reset({ hold = true, holdDuration = 2 })
grab()
check("2 s hold: picked", HAVE["Pink Pig Berry"] == 4, E.berryNote)

-- 3. the hold refused, the instant fire taken: the fallback still picks it
reset({ hold = false, fire = true })
grab()
check("hold refused, fire picks it (fallback)", HAVE["Pink Pig Berry"] == 4
    and string.find(E.berryNote, "fireproximityprompt", 1, true) ~= nil, E.berryNote)

-- 4. no executor fireproximityprompt at all: the hold alone
reset({ hold = true, noFire = true })
grab()
check("no fireproximityprompt: hold picks it", HAVE["Pink Pig Berry"] == 4, E.berryNote)

-- 5. nothing works: keeps trying well past the old 6 s, then leaves it a minute
reset({ hold = false, fire = false })
grab()
check("nothing works: not picked, skipped a minute", HAVE["Pink Pig Berry"] == 3
    and E.berrySkip[bush] ~= nil and string.find(E.berryNote, "could not pick", 1, true) ~= nil, E.berryNote)
check("tried ~15 s (not 6), not forever", CLOCK >= 14 and CLOCK <= 20, CLOCK)
check("tried both ways", HOLDS >= 3 and FIRES >= 1, HOLDS .. " holds, " .. FIRES .. " fires")

-- 6. someone else takes it first: out at once, said so
reset({ hold = false, fire = false, takenAt = 1 })
grab()
check("taken by another: gone, count not up", string.find(E.berryNote, "gone from the bush", 1, true) ~= nil
    and CLOCK < 4, tostring(E.berryNote) .. " @" .. CLOCK)

-- 7. stopped mid-hold: out quickly
reset({ hold = true, holdDuration = 5 })
local b = { bush = bush, names = berryNames(bush.attrs), pos = Vector3.new(0, 0, 0) }
local oldWait = task.wait
task.wait = function(s) oldWait(s) if CLOCK > 1 then epoch = 1 end end
grabBerry(b, 0)
task.wait = oldWait
check("stop mid-hold: out within ~1 s", CLOCK < 2.5, CLOCK)

_G.print(all and "ALL PASS" or "SOME FAILED")
