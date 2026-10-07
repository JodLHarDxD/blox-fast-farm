
-- ---------------------------------------------------------------- cases
local all = true
local function run(name, way, tool, expect)
    table.clear(LOG)
    fireM1(way, tool)
    local got = table.concat(LOG, " | ")
    local ok = got == expect
    print((ok and "PASS " or "FAIL ") .. name)
    if not ok then print("  got:    " .. got) print("  expect: " .. expect) all = false end
end
local sword = { Name = "Yama", kind = "Sword" }
local fruit = { Name = "Kitsune-Kitsune", kind = "Blox Fruit" }
function fruit:FindFirstChild(n) return n == "LeftClickRemote" and remote("LeftClickRemote") or nil end
local DS = { Name = "Dragonstorm", kind = "Gun" }
run("remote hit (new): RegisterAttack then RegisterHit, the whole pile", { path = "remote", variant = "new" }, sword,
    "RegisterAttack | RegisterHit")
run("remote hit (old): the same two", { path = "remote", variant = "old" }, sword, "RegisterAttack | RegisterHit")
run("fruit click: its LeftClickRemote, once per enemy", { path = "click" }, fruit, "LeftClickRemote | LeftClickRemote")
run("held gun: THE GUN's hold tick", { path = "hold" }, DS, "hold Dragonstorm")
run("past the heat: THE GUN's shot tick", { path = "gunshot" }, DS, "gunshot Dragonstorm")
run("a gun's click: the aim held for its whole burst, then the click", { path = "keys" }, DS, "aim 0.5 | click")
run("a sword's key press: just the click", { path = "keys" }, sword, "click")
local counted = stats.m1 == 7 and actions == 7
print((counted and "PASS " or "FAIL ") .. "every way counts as an M1 and an action (" .. stats.m1 .. ", " .. actions .. ")")
all = counted and all
print(all and "ALL PASS" or "SOME FAILED")
