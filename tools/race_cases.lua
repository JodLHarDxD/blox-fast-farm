
-- race_test.py part 1: the pure RACE LOGIC, real code.
local fails = 0
local function check(name, ok, got)
    if ok then print("PASS " .. name)
    else
        fails += 1
        print("FAIL " .. name .. (got ~= nil and ("   got: " .. tostring(got)) or ""))
    end
end

-- ---------------------------------------------------------------- the V4 gate
check("V4: full meter, alive, the Awakening carried, not transformed = fire", v4Due(true, 1, false, true, 10, 0))
check("V4: a meter over full fires too", v4Due(true, 1.2, false, true, 10, 0))
check("V4: 99 % = not yet", not v4Due(true, 0.99, false, true, 10, 0))
check("V4: already transformed = never", not v4Due(true, 1, true, true, 10, 0))
check("V4: no Awakening tool (V4 not unlocked) = never", not v4Due(true, 1, false, false, 10, 0))
check("V4: dead = never", not v4Due(false, 1, false, true, 10, 0))
check("V4: no meter on the character = never", not v4Due(true, nil, false, true, 10, 0))
check("V4: a few seconds after a refusal = wait", not v4Due(true, 1, false, true, 10, 12))
check("...and after the wait = fire", v4Due(true, 1, false, true, 12, 12))

-- ---------------------------------------------------------------- the V3 clock (user, 2026-10-12)
local function fresh() return { anchor = nil, lastPress = nil, ever = false, burstStart = nil } end
local c = fresh()
local go, why = v3Step(c, 0, 28, 0.5, nil)
check("V3: the first T at once (it is probably ready)", go == true, why)
check("...the next not before 0.5 s", (v3Step(c, 0.3, 28, 0.5, nil)) == false)
check("...0.5 s later the next", (v3Step(c, 0.5, 28, 0.5, nil)) == true)
v3Seen(c, 0.6, "DracoRace.Roar")
check("seen going on: the clock starts there (anchor, signal known)", c.anchor == 0.6 and c.ever == true)
go, why = v3Step(c, 1, 28, 0.5, nil)
check("then nothing for 28 s - says how long", go == false and why == "next T in 28 s", why)
local pressed = 0
for t = 1, 28.5, 0.1 do if v3Step(c, t, 28, 0.5, nil) then pressed += 1 end end
check("no T at all in the 28 s", pressed == 0, pressed)
check("at 28 s from going on: a T", (v3Step(c, 28.6, 28, 0.5, nil)) == true)
local presses = {}
for t = 28.7, 30.0, 0.1 do if v3Step(c, t, 28, 0.5, nil) then table.insert(presses, string.format("%.1f", t)) end end
check("then every 0.5 s until it goes on (the signal known: no end)", table.concat(presses, ",") == "29.1,29.6", table.concat(presses, ","))
v3Seen(c, 29.7, "Primordial Reign")
check("going on again: the next 28 s from there", (v3Step(c, 57.6, 28, 0.5, nil)) == false and (v3Step(c, 57.7, 28, 0.5, nil)) == true)
-- paused (the moon, no character): never a T, and it says why
local p = fresh()
go, why = v3Step(p, 0, 28, 0.5, "your turn at the moon - your own T")
check("paused: no T, the reason shown", go == false and why == "your turn at the moon - your own T", why)
check("...and the clock untouched", p.anchor == nil and p.lastPress == nil)
-- no signal ever seen: a 3 s burst, then the next wait from its END
local n = fresh()
local times = {}
for i = 0, 61 do local t = i / 20 if v3Step(n, t, 28, 0.5, nil) then table.insert(times, string.format("%.1f", t)) end end
check("no signal: a 3 s burst of T every 0.5 s", table.concat(times, ",") == "0.0,0.5,1.0,1.5,2.0,2.5", table.concat(times, ","))
check("...then the next wait counted from the burst's end", n.anchor ~= nil and math.abs(n.anchor - 3.0) < 0.06, n.anchor)
check("...and nothing until 28 s after it", (v3Step(n, 30.9, 28, 0.5, nil)) == false and (v3Step(n, 31.05, 28, 0.5, nil)) == true)

-- The clock against a fake server: V3 cools CD s from the press that took it.
-- seen = the script sees it going on (a signal). Lateness = how long V3 sat
-- ready before a T took it. 10 minutes, a tick every 0.1 s.
local function sim(cd, seen)
    local cl = fresh()
    local readyAt, worst, ons, misses = 0, 0, 0, 0
    for i = 0, 6000 do
        local t = i * 0.1
        if v3Step(cl, t, 28, 0.5, nil) and t >= readyAt - 1e-6 then
            worst = math.max(worst, t - readyAt)
            ons += 1
            readyAt = t + cd
            if seen then v3Seen(cl, t, "roar") end
        end
        if t - readyAt > 10 then misses += 1 end
    end
    return worst, ons, misses
end
for _, cd in ipairs({ 29, 29.5, 30 }) do
    local w, ons, miss = sim(cd, true)
    check(string.format("signal seen, cooldown %.1f s: never more than 0.5 s late (%.2f), %d times in 10 min", cd, w, ons),
        w <= 0.5 + 1e-6 and miss == 0 and ons >= 19)
    w, ons, miss = sim(cd, false)
    check(string.format("no signal, cooldown %.1f s: never missed, at most %.1f s late (%.2f), %d times in 10 min", cd, 31 - cd, w, ons),
        w <= (31 - cd) + 0.11 and miss == 0 and ons >= 18)
end
-- a T sent while V3 is not ready changes nothing on the clock's side
local busy = 0
local cb = fresh()
for i = 0, 300 do if v3Step(cb, i * 0.1, 28, 0.5, nil) then busy += 1 end end
check("no signal, 30 s: 6 T's in the first burst, none in the wait (not 60)", busy == 6, busy)

-- ---------------------------------------------------------------- whose effect
local me, myChar, other, otherChar = { Name = "me" }, { Name = "meChar" }, { Name = "other" }, { Name = "otherChar" }
local ROAR = { Name = "DracoRace.Roar" }
check("your roar (the Player in its player field) = V3 on", fxV3(ROAR, { player = me }, me, myChar, "me"))
check("your roar, the Player streamed ({guid, 1, '__StreamedObject', false, you})",
    fxV3(ROAR, { player = { "g", 1, "__StreamedObject", false, me } }, me, myChar, "me"))
check("your roar, a stand-in effect player { Name, Character }",
    fxV3(ROAR, { player = { __EffectFakePlayer = true, Name = "me", Character = myChar } }, me, myChar, "me"))
check("your roar, your character as its Character", fxV3(ROAR, { Character = myChar }, me, myChar, "me"))
check("the sender in the metadata", fxV3({ Name = "DracoRace.Roar", Sender = me }, {}, me, myChar, "me"))
check("an ALLY's roar that buffed you (you in its Characters) = not yours",
    not fxV3(ROAR, { player = other, Characters = { myChar, otherChar }, BuffType = 1 }, me, myChar, "me"))
check("someone else's streamed Player = not yours",
    not fxV3(ROAR, { player = { "g", 1, "__StreamedObject", false, other } }, me, myChar, "me"))
check("another effect of yours (not a V3) = nothing", not fxV3({ Name = "DracoRace.Orbs" }, { player = me }, me, myChar, "me"))
check("no metadata table = nothing", not fxV3("DracoRace.Roar", { player = me }, me, myChar, "me"))
check("no payload = only the metadata's sender counts", not fxV3(ROAR, nil, me, myChar, "me"))
check("the name alone never matches another player's name", not isYou({ Name = "other" }, me, myChar, "me"))

-- ---------------------------------------------------------------- V4's weapons
local function tool(name, tip) return { Name = name, ToolTip = tip } end
local TOOLS = { tool("Dragonstorm", "Gun"), tool("Kitsune-Kitsune", "Blox Fruit"), tool("Awakening", ""),
    tool("Primordial Reign", ""), tool("Cursed Dual Katana", "Sword"), tool("Dragon Talon", "Melee") }
local function typeOf(t) return t.ToolTip end
local function allKeys(_, _) return true end
local holds = { ["Dragon Talon"] = { Z = 1.2 } }
local list = pickWeapons(TOOLS, typeOf, nil, allKeys, function(n) return holds[n] end)
local names = {}
for _, u in ipairs(list) do table.insert(names, u.name) end
check("V4: the real weapons only (no Awakening, no ability tool), sword -> fighting style -> fruit -> gun",
    table.concat(names, ",") == "Cursed Dual Katana,Dragon Talon,Kitsune-Kitsune,Dragonstorm", table.concat(names, ","))
local allOn = true
for _, u in ipairs(list) do
    if not (u.cfg.M1 and u.cfg.use) then allOn = false end
    for _, k in ipairs(KEYS) do if not u.cfg[k] then allOn = false end end
end
check("...M1 and every key on all of them", allOn)
check("...the list is marked as V4's (attackTick turns the M1s)", list.race == true)
check("...your hold times kept", list[2].cfg.hold and list[2].cfg.hold.Z == 1.2)
local function noFoxV(name, k) return not (k == "V" and name == "Kitsune-Kitsune") end
local l2 = pickWeapons(TOOLS, typeOf, nil, noFoxV, nil)
check("a transformation fruit's V never (its form would lock every other weapon out)",
    l2[3].name == "Kitsune-Kitsune" and l2[3].cfg.V == false and l2[3].cfg.Z == true and l2[2].cfg.V == true)
local l3 = pickWeapons(TOOLS, typeOf, "Kitsune", allKeys, nil)
check("in a fruit's form: only that fruit (the game refuses the rest)", #l3 == 1 and l3[1].name == "Kitsune-Kitsune")
check("nothing carried = an empty V4 list", #pickWeapons({}, typeOf, nil, allKeys, nil) == 0)

-- ---------------------------------------------------------------- M1s in turn
local used = {
    { name = "A", cfg = { M1 = true } }, { name = "B", cfg = { M1 = true } },
    { name = "X", cfg = { M1 = false } }, { name = "C", cfg = { M1 = true } },
}
local T = { name = nil, count = 0 }
local seq = {}
for _ = 1, 8 do
    local u = m1Turn(T, used, 2, nil)
    table.insert(seq, u.name)
    T.count += 1
end
check("M1 in turn: 2 swings each, one with M1 off left out, round again",
    table.concat(seq, "") == "AABBCCAA", table.concat(seq, ""))
T = { name = nil, count = 0 }
seq = {}
for _ = 1, 6 do
    local u = m1Turn(T, used, 2, function(x) return x.name == "B" end)
    table.insert(seq, u.name)
    T.count += 1
end
check("one whose M1 lands nowhere just now is passed over", table.concat(seq, "") == "AACCAA", table.concat(seq, ""))
T = { name = "Gone", count = 1 }
check("the weapon in turn not carried any more: from the first", m1Turn(T, used, 2, nil).name == "A" and T.count == 0)
T = { name = nil, count = 0 }
seq = {}
for _ = 1, 3 do
    local u = m1Turn(T, used, 0, nil)
    table.insert(seq, u.name)
    T.count += 1
end
check("a burst under 1 counts as 1", table.concat(seq, "") == "ABC", table.concat(seq, ""))
check("no M1 anywhere = none", m1Turn({ count = 0 }, { { name = "X", cfg = { M1 = false } } }, 2, nil) == nil)

print(fails == 0 and "ALL PASS (logic)" or (fails .. " FAILED (logic)"))
