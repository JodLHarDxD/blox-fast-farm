local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local steps = {
    { name = "1  CLOSE", set = { RandomRadius = 300 }, line = "Reaches 300 studs" },
    { name = "3  BALANCED", set = { RandomRadius = 750 }, line = "Reaches 750 studs", today = true },
}
local cfg = { RandomRadius = 750 }
check("step of today's cfg is 2", dialStepOf(steps, cfg) == 2)
dialApply(steps, 1, cfg)
check("apply step 1 writes its values", cfg.RandomRadius == 300 and dialStepOf(steps, cfg) == 1)
cfg.RandomRadius = 444
check("own values: no step", dialStepOf(steps, cfg) == nil)
check("today step index", dialToday(steps) == 2)
check("every pack has an accent", ACCENT.farm and ACCENT.raid and ACCENT.sea and ACCENT.prehistoric
    and ACCENT.pvp and ACCENT.fruits and ACCENT.none)
print(all and "ALL PASS" or "SOME FAILED")
