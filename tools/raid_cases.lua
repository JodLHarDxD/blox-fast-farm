
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- 1. not in a raid: no timer, no island
local on, pos, n = raidState()
check("no raid: off, no island", not on and pos == nil and n == 0)

-- 2. the 2026 timer (Main.TopHUDList.RaidTimer) and islands 1-3 open: Island 3
PG.kids = { node("Main", "Frame", { node("TopHUDList", "Frame", {
    node("RaidTimer", "Frame", { node("T", "TextLabel", {}, { Text = "04:12" }) }, { Visible = true }) }) }) }
LOC.kids = {
    node("Island 1", "Part", {}, { Position = v3(1, 0, 0) }),
    node("Starter Island", "Part", {}, { Position = v3(9, 9, 9) }),
    node("Island 3", "Part", {}, { Position = v3(3, 0, 0) }),
    node("Island 2", "Part", {}, { Position = v3(2, 0, 0) }),
}
local text
on, pos, n, text = raidState()
check("2026 timer seen, newest island = Island 3, its text read",
    on and n == 3 and pos and pos.X == 3 and text == "04:12", tostring(n) .. " " .. tostring(text))

-- 3. the older timer (Main.Timer) still counts
PG.kids = { node("Main", "Frame", { node("Timer", "TextLabel", {}, { Visible = true, Text = "01:00" }) }) }
on, pos, n, text = raidState()
check("older Main.Timer seen too", on and text == "01:00" and n == 3)

-- 4. timer hidden but islands there (the moment between islands): island still followed
PG.kids = { node("Main", "Frame", { node("Timer", "TextLabel", {}, { Visible = false }) }) }
on, pos, n = raidState()
check("timer hidden, island there: the island is still followed", not on and n == 3)

-- 5. an island given as a Model: its pivot
LOC.kids = { node("Island 5", "Model", {}, { pivot = v3(5, 5, 5) }) }
on, pos, n = raidState()
check("Island 5 as a Model: its pivot", n == 5 and pos and pos.X == 5)

-- 6. ordinary map locations are never raid islands
LOC.kids = { node("Starter Island", "Part", {}, { Position = v3(9, 9, 9) }), node("Island", "Part", {}, { Position = v3(1, 1, 1) }) }
on, pos, n = raidState()
check("'Starter Island' / 'Island' are not raid islands", pos == nil and n == 0)

print(all and "ALL PASS" or "SOME FAILED")
