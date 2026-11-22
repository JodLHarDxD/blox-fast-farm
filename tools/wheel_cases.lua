local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- ---------- only real fight weapons ----------
check("Melee is a weapon", fightType("Melee") == "Melee")
check("Sword is a weapon", fightType("Sword") == "Sword")
check("Blox Fruit is a weapon", fightType("Blox Fruit") == "Blox Fruit")
check("Gun is a weapon", fightType("Gun") == "Gun")
check("no label is not a weapon", fightType("?") == nil and fightType("") == nil and fightType(nil) == nil)
check("Wear / Accessory labels are not weapons", fightType("Wear") == nil and fightType("Accessory") == nil)

-- what the owner's backpack held (2026-11-23): the game labels, as toolType reads them
local bag = {
    { name = "Dragon Talon", ty = "Melee" },
    { name = "Buddy Sword", ty = "Sword" },
    { name = "Tiger-Tiger", ty = "Blox Fruit" },
    { name = "Dragonstorm", ty = "Gun" },
    { name = "Awakening", ty = "?" },
    { name = "Dojo Belt (Black)", ty = "?" },
    { name = "Heightened Senses", ty = "?" },
    { name = "Shark Rod", ty = "?" },
    { name = "Tool", ty = "?" },
}
local function names(l)
    local t = {}
    for _, w in ipairs(l) do table.insert(t, w.name) end
    return table.concat(t, "|")
end
local only = fightWeapons(bag)
check("the wheel keeps the four weapons, in order", names(only) == "Dragon Talon|Buddy Sword|Tiger-Tiger|Dragonstorm",
    names(only))
local kept = fightWeapons(bag, { ["Shark Rod"] = true })
check("a non-weapon that is the pick stays (so it can be turned off)",
    names(kept) == "Dragon Talon|Buddy Sword|Tiger-Tiger|Dragonstorm|Shark Rod", names(kept))
check("nothing carried: nothing", #fightWeapons({}) == 0 and #fightWeapons(nil) == 0)

-- ---------- 5 most used + "+N" past 6 ----------
local six = {}
for i = 1, 6 do table.insert(six, { name = "W" .. i, used = 0 }) end
local s, h = wheelShown(six, nil)
check("6 weapons: all on the wheel", #s == 6 and #h == 0)
local nine = {}
for i = 1, 9 do table.insert(nine, { name = "W" .. i, used = (i % 3 == 0) and 5 or i % 2 }) end
-- used: W1 1, W2 0, W3 5, W4 0, W5 1, W6 5, W7 1, W8 0, W9 5
s, h = wheelShown(nine, nil)
check("9 weapons: 5 shown", #s == 5, #s)
check("9 weapons: +4 hidden", #h == 4, #h)
check("the most used win, in turning order", names(s) == "W1|W3|W5|W6|W9", names(s))
check("the rest are the +N list", names(h) == "W2|W4|W7|W8", names(h))
s, h = wheelShown(nine, "W8")
check("the pick is always shown", string.find(names(s), "W8", 1, true) ~= nil and #s == 5, names(s))
check("the pick pushes out the least used (ties: turning order)", names(s) == "W1|W3|W6|W8|W9", names(s))
check("the pick is never in +N", string.find(names(h), "W8", 1, true) == nil, names(h))
s, h = wheelShown(nine, "MIX")
check("MIX picks no weapon", names(s) == "W1|W3|W5|W6|W9")

-- ---------- labels never overlap ----------
local function overlap(a, b, gap)
    return a.left < b.left + b.w + gap and b.left < a.left + a.w + gap
        and a.top < b.top + WHEEL_PILL + gap and b.top < a.top + WHEEL_PILL + gap
end
local function dialDist(o)
    local nx = math.max(o.left, math.min(WHEEL_CX, o.left + o.w))
    local ny = math.max(o.top, math.min(WHEEL_CY, o.top + WHEEL_PILL))
    return math.sqrt((nx - WHEEL_CX) ^ 2 + (ny - WHEEL_CY) ^ 2)
end
local function verify(widths, tag)
    local L = wheelLayout(widths)
    local ok, why = #L == #widths, "count"
    for i, o in ipairs(L) do
        if o.left < 0 or o.top < 0 or o.left + o.w > WHEEL_W or o.top + WHEEL_PILL > WHEEL_H then
            ok, why = false, "label " .. i .. " leaves the box"
        end
        if o.w < 40 then ok, why = false, "label " .. i .. " too narrow: " .. o.w end
        if dialDist(o) < 55 then ok, why = false, "label " .. i .. " on the dial: " .. dialDist(o) end
        for j = i + 1, #L do
            if overlap(o, L[j], WHEEL_GAP - 1) then ok, why = false, "labels " .. i .. " and " .. j .. " overlap" end
        end
    end
    check("layout " .. tag, ok, why)
    return L
end
-- every count the wheel can show (MIX + up to 5 weapons + the +N chip), short and long names
for n = 1, 7 do
    local short, long, mixed = { 64 }, { 64 }, { 64 }
    for i = 2, n do
        table.insert(short, 60)
        table.insert(long, 104)
        table.insert(mixed, (i % 2 == 0) and 104 or 48)
    end
    verify(short, n .. " short")
    verify(long, n .. " long")
    verify(mixed, n .. " mixed")
end
-- a seeded sweep of random widths
local seed = 7
local function rnd(lo, hi)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return lo + seed % (hi - lo + 1)
end
local sweepOk = true
for t = 1, 300 do
    local n = rnd(1, 7)
    local w = { 64 }
    for _ = 2, n do table.insert(w, rnd(44, 104)) end
    local L = wheelLayout(w)
    for i, o in ipairs(L) do
        if o.left < 0 or o.top < 0 or o.left + o.w > WHEEL_W or o.top + WHEEL_PILL > WHEEL_H
            or dialDist(o) < 55 or o.w < 40 then sweepOk = false end
        for j = i + 1, #L do if overlap(o, L[j], WHEEL_GAP - 1) then sweepOk = false end end
    end
end
check("300 random label sets: none overlap, none on the dial", sweepOk)

-- the board's five (MIX, Dragon Talon, CDK, Tiger, Dragonstorm): its places, near enough
local B = wheelLayout({ 64, 100, 60, 64, 100 })
check("board: MIX at the top", B[1].left == 119 and B[1].top == 2 and B[1].deg == 0, B[1].left .. "," .. B[1].top)
check("board: Dragon Talon upper left", B[2].left <= 14 and math.abs(B[2].top - 50) <= 3 and B[2].deg < -50
    and B[2].deg > -70, B[2].left .. "," .. B[2].top .. " " .. B[2].deg)
check("board: CDK lower left", math.abs(B[3].left - 34) <= 4 and math.abs(B[3].top - 153) <= 4
    and B[3].deg < -110, B[3].left .. "," .. B[3].top .. " " .. B[3].deg)
check("board: Tiger upper right", math.abs(B[4].left - 206) <= 4 and math.abs(B[4].top - 53) <= 4
    and B[4].deg > 50 and B[4].deg < 70, B[4].left .. "," .. B[4].top .. " " .. B[4].deg)
check("board: Dragonstorm lower right", B[5].left >= 190 and math.abs(B[5].top - 153) <= 4
    and B[5].deg > 110, B[5].left .. "," .. B[5].top .. " " .. B[5].deg)
-- the needle points at each label's own side
local L7 = wheelLayout({ 64, 104, 104, 104, 104, 104, 48 })
check("7 stops: left column points left, right column right",
    L7[2].deg < 0 and L7[3].deg < 0 and L7[4].deg < 0 and L7[5].deg > 0 and L7[6].deg > 0 and L7[7].deg > 0)
check("7 stops: each column turns top to bottom",
    L7[2].deg > L7[3].deg and L7[3].deg > L7[4].deg and L7[5].deg < L7[6].deg and L7[6].deg < L7[7].deg)

print(all and "ALL PASS" or "SOME FAILED")
