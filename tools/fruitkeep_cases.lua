
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- THE TRADING MARKET'S VALUE (a physical fruit's), by the game's own names
check("Control: 120M", P.tradeValue("Control-Control") == 120e6, P.tradeValue("Control-Control"))
check("T-Rex: its dash kept", P.tradeValue("T-Rex-T-Rex") == 20e6, P.tradeValue("T-Rex-T-Rex"))
check("Dragon: one fruit, East's (the lower)", P.tradeValue("Dragon-Dragon") == 2.97e9)
check("Dragon under any name it may carry", P.tradeValue("Dragon (West)-Dragon (West)") == 2.97e9
    and P.tradeValue("East Dragon") == 2.97e9)
check("an old name: Rumble = Lightning, Leopard = Tiger", P.tradeValue("Rumble-Rumble") == 20e6
    and P.tradeValue("Leopard-Leopard") == 100e6)
check("Bird: Falcon = Eagle", P.tradeValue("Bird-Bird: Falcon") == 800e3, P.tradeValue("Bird-Bird: Falcon"))
check("Magnet (Update 30)", P.tradeValue("Magnet-Magnet") == 540e6)
check("a fruit the list does not know: nil", P.tradeValue("Moon-Moon") == nil)
check("nothing: nil", P.tradeValue(nil) == nil)
check("Buddha 10M - the market, not its 1.2M Beli", P.tradeValue("Buddha-Buddha") == 10e6)

-- TOO GOOD TO LOSE: at or over the line
check("Dough 30M over 20M: kept", P.isKeeper("Dough-Dough", 20e6) == true)
check("Lightning exactly 20M: kept", P.isKeeper("Lightning-Lightning", 20e6) == true)
check("Buddha 10M under 20M: not", P.isKeeper("Buddha-Buddha", 20e6) == false)
check("Buddha at a 10M line: kept", P.isKeeper("Buddha-Buddha", 10e6) == true)
check("a fruit newer than the list: kept (dear till shown otherwise)", P.isKeeper("Moon-Moon", 20e6) == true)
check("line 0 = off: not even Dragon", P.isKeeper("Dragon-Dragon", 0) == false)
check("line nil = off", P.isKeeper("Dragon-Dragon", nil) == false)

check("words: 120M 2.97B 6.5M 800K 7.5K 30M ?",
    P.valueWords(120e6) == "120M" and P.valueWords(2.97e9) == "2.97B" and P.valueWords(6.5e6) == "6.5M"
    and P.valueWords(800e3) == "800K" and P.valueWords(7.5e3) == "7.5K" and P.valueWords(30e6) == "30M"
    and P.valueWords(nil) == "?",
    table.concat({ P.valueWords(120e6), P.valueWords(2.97e9), P.valueWords(6.5e6), P.valueWords(800e3),
        P.valueWords(7.5e3), P.valueWords(30e6) }, " "))

-- THE FRUIT HISTORY
check("one file per account", P.fruitLogFile == "bff_fruit_log_7.json", P.fruitLogFile)
check("nothing yet", #P.fruitLog == 0)
P.fruitLogAdd({ orig = "Buddha-Buddha", value = 10e6, server = 3, from = "spawn", state = "backpack", t = 1000 })
P.fruitLogAdd({ orig = "Dough-Dough", value = 30e6, server = 5, from = "spawn", state = "stored", t = 2000 })
P.fruitLogAdd({ orig = "Control-Control", value = 120e6, server = 9, from = "drop", state = "stored", t = 3000 })
P.fruitLogAdd({ orig = "Dough-Dough", value = 30e6, server = 12, from = "spawn", state = "held", t = 4000 })
check("each pick written to the file at once", type(FILES["bff_fruit_log_7.json"]) == "table"
    and #FILES["bff_fruit_log_7.json"].log == 4)

local e = P.fruitLogSet("Dough-Dough", "gone", { held = true })
check("set: the NEWEST Dough that was held, not the stored one", e and e.server == 12
    and P.fruitLog[2].state == "stored" and P.fruitLog[4].state == "gone")
check("set: none in that state = nil, nothing changed", P.fruitLogSet("Dough-Dough", "lost", { held = true }) == nil
    and P.fruitLog[4].state == "gone")
check("set: a fruit never picked = nil", P.fruitLogSet("Kitsune-Kitsune", "gone", nil) == nil)

local s = P.fruitLogSummary()
check("summary: dearest first, one line a fruit", #s == 3 and string.find(s[1], "^Control")
    and string.find(s[2], "^Dough") and string.find(s[3], "^Buddha"), table.concat(s, " | "))
check("summary: Dough x2 - 1 stored, 1 gone", string.find(s[2], "x2", 1, true)
    and string.find(s[2], "1 stored", 1, true) and string.find(s[2], "1 left the backpack", 1, true), s[2])
check("summary: its trade value", string.find(s[1], "120M", 1, true) ~= nil, s[1])

local lines = P.fruitLogLines(2)
check("lines: newest first, n of them", #lines == 2 and string.find(lines[1], "server #12", 1, true)
    and string.find(lines[2], "server #9", 1, true), table.concat(lines, " | "))
check("lines: a player's drop says so", string.find(lines[2], "(a drop)", 1, true) ~= nil, lines[2])
check("lines: the state in words", string.find(lines[1], "traded / stored by you", 1, true) ~= nil, lines[1])

-- reloaded (the next server, a fresh copy): the file comes back
local saved = FILES["bff_fruit_log_7.json"]
P.fruitLog = {}
local ok, t = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile(P.fruitLogFile)) end)
if ok and type(t) == "table" and type(t.log) == "table" then P.fruitLog = t.log end
check("reload: every entry back", #P.fruitLog == 4 and P.fruitLog[3].orig == "Control-Control"
    and saved ~= nil)

for i = 1, 310 do P.fruitLogAdd({ orig = "Spin-Spin", value = 7.5e3, server = i, state = "backpack" }) end
check("the last 300 kept", #P.fruitLog == 300 and P.fruitLog[300].server == 310 and P.fruitLog[1].server == 11,
    #P.fruitLog)
P.fruitLogClear()
check("clear: empty, the file too", #P.fruitLog == 0 and #FILES["bff_fruit_log_7.json"].log == 0)
check("an empty history: no lines, no summary", #P.fruitLogLines(40) == 0 and #P.fruitLogSummary() == 0)

print(all and "ALL PASS" or "SOME FAILED")
