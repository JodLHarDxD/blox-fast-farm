
-- ===== cooldown tests (2026-10-15): Flash Step's cut, skills pressed early =====
local char = me.Character
char.kids.Busy = inst("BoolValue", { Value = false })
CFG.PvpSoruCut, CFG.PvpCdTest = 0, false

-- Flash Step: nothing set = the game's own
soruTick()
check("no cut: the attribute left alone", char.attrs.FlashstepCooldown == nil)
check("the line: the game's 15 s", string.find(S.soruNote(), "15.0 s cooldown", 1, true) ~= nil)
CFG.PvpSoruCut = 50
soruTick()
check("50 % cut: the game's own attribute at 0.5", near(char.attrs.FlashstepCooldown, 0.5))
check("the line: 7.5 s", string.find(S.soruNote(), "7.5 s cooldown", 1, true) ~= nil)
soruTick()
check("held, not rewritten", near(char.attrs.FlashstepCooldown, 0.5) and near(S.soru.mine, 0.5))
-- an accessory's own cut arrives from the server: kept, ours on top
char.attrs.FlashstepCooldown = 0.2
soruTick()
check("the server's 0.2 (gear) kept, then half of the rest", near(S.soru.base, 0.2) and near(char.attrs.FlashstepCooldown, 0.6))
CFG.PvpSoruCut = 0
soruTick()
check("cut back to 0: the server's own value back", near(char.attrs.FlashstepCooldown, 0.2))
CFG.PvpSoruCut = 95
soruTick()
soruRestore()
check("PvP off: the server's own value back", near(char.attrs.FlashstepCooldown, 0.2) and S.soru.mine == nil)

-- skills: the tool's IgnoreCooldowns only while the test is on, only on a skill tool
local tool = inst("Tool", { Name = "Buddy Sword", ToolTip = "Sword" })
tool.kids.Holding = inst("BoolValue", { Value = false })
TOOL = tool
cdTick()
check("test off: the tool untouched", tool.attrs.IgnoreCooldowns == nil)
CFG.PvpCdTest = true
cdTick()
check("test on: the game's own IgnoreCooldowns on the tool in hand", tool.attrs.IgnoreCooldowns == true)
TOOL = inst("Tool", { Name = "Dragonstorm", ToolTip = "Gun" })      -- no Holding: not a skill tool
cdTick()
check("a tool with no skills: untouched", TOOL.attrs.IgnoreCooldowns == nil)
TOOL = tool
-- presses against moves started
S.cd.presses, S.cd.moves, S.cd.busy = 0, 0, false
attackPressed("Z")
attackPressed("Z")
attackPressed("M1")
char.kids.Busy.Value = true
cdTick()
cdTick()
char.kids.Busy.Value = false
cdTick()
check("two Z presses counted, M1 not", S.cd.presses == 2)
check("one move started (Busy turned on once)", S.cd.moves == 1)
check("the line says both", string.find(S.cdNote(), "2 presses", 1, true) ~= nil and string.find(S.cdNote(), "1 moves", 1, true) ~= nil)
CFG.PvpCdTest = false
cdTick()
check("test off: the switch taken off the tool", tool.attrs.IgnoreCooldowns == nil)
tool.attrs.IgnoreCooldowns = true                                   -- set by the server (an admin): not ours
CFG.PvpCdTest = true
cdTick()
CFG.PvpCdTest = false
cdTick()
check("a switch this script did not set is never taken off", tool.attrs.IgnoreCooldowns == true)
check("off: the line says the game's own", S.cdNote() == "skills: the game's own cooldowns")
TOOL = nil

print(string.format("%d checks, %d failed", count, fails))
if fails == 0 then print("ALL PASS (cooldowns)") end
