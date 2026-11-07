
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function printed(s)
    for _, l in ipairs(PRINTED) do if string.find(l, s, 1, true) then return true end end
    return false
end
local function times(s)
    local n = 0
    for _, l in ipairs(PRINTED) do if string.find(l, s, 1, true) then n += 1 end end
    return n
end
local function has(str, s) return type(str) == "string" and string.find(str, s, 1, true) ~= nil end

-- Unix time of a UTC date (days from civil), then IST = UTC + 5:30.
local function utc(y, m, d, hh, mm)
    y = (m <= 2) and (y - 1) or y
    local era = y // 400
    local yoe = y - era * 400
    local mp = (m + 9) % 12
    local doy = (153 * mp + 2) // 5 + d - 1
    local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
    return (era * 146097 + doe - 719468) * 86400 + hh * 3600 + mm * 60
end
local function IST(s)
    local mo, d, h, mi = string.match(s, "(%d+)-(%d+) (%d+):(%d+)")
    return utc(2026, tonumber(mo), tonumber(d), tonumber(h), tonumber(mi)) - 19800
end
local function hhmm(t) return os.date("%H:%M", t) end

-- jodl_37's 29 trades, 30 Oct - 7 Nov (IST, his trade-window screenshots),
-- and the three counts the game showed him: (2/5) after the 2nd, (1/5)
-- after the 3rd, 5 of 5 after the 7th.
local REAL = { "10-30 23:38", "10-30 23:54", "10-31 16:24", "10-31 16:36", "10-31 23:41", "10-31 23:57",
    "11-01 00:11", "11-01 15:24", "11-01 20:01", "11-01 21:55", "11-01 23:02", "11-02 01:12", "11-02 23:54",
    "11-03 01:21", "11-04 01:21", "11-04 01:53", "11-04 02:09", "11-04 19:26", "11-05 01:11", "11-05 02:25",
    "11-06 00:18", "11-06 00:24", "11-06 23:15", "11-07 00:11", "11-07 18:08", "11-07 19:12", "11-07 22:16",
    "11-07 22:58", "11-07 23:01" }
local SAID = { [2] = 2, [3] = 1, [7] = 5 }
local function ledger(list, said)
    local out = {}
    for i, s in ipairs(list) do out[i] = { t = IST(s), n = said and said[i], src = "seed" } end
    return out
end

local FILE = "bff_trades_8230031723.json"
local T
-- The section built with this file on disk, listening, its clock NOW.
local function withLedger(list, o)
    reset(o)
    if list then FILES[FILE] = HttpService:JSONEncode({ v = 1, cap = 5, list = list }) end
    SECTION()
    T = P.trades
    T.clock = function() return NOW end
    T.listen()
end
local function msg(text) COMM_E:Fire("Notify", text) end
local function done(other, gave, got, state)
    local st = { Trader = { 8230031723, other }, State = { Type = state or "Processing" },
        Offer = { { Items = gave }, { Items = got } } }
    TRADE_EVENT:Fire("start", { Trader = st.Trader, State = { Type = "NotReady" }, Offer = st.Offer })
    TRADE_EVENT:Fire("leave", st)
end

do
    -- ======================================== the rules against his real trades
    withLedger(ledger(REAL, SAID))
    check("every rule fits jodl_37's 29 trades and the 3 counts the game showed", next(T.out) == nil,
        tostring(next(T.out)))
    check("...none needs a trade the script never saw", next(T.miss) == nil or (T.miss.cycle8 or 0) == 0, T.miss.cycle8)
    -- The wiki's day (a new day at 11:59 PM UTC+8 = 15:59 UTC) counts 3 where the game said 1.
    local wiki = { kind = "day", at = 15 * 3600 + 59 * 60 }
    check("the wiki's 11:59 PM UTC+8 day counts 3 at the trade the game called (1/5)",
        T.count(wiki, T.list, T.list[3].t, 3) == 3, T.count(wiki, T.list, T.list[3].t, 3))
    check("...and a rolling 24 h counts more than 5 on 1 Nov", T.count({ kind = "roll", span = 86400 },
        T.list, IST("11-01 23:02"), 11) > 5, T.count({ kind = "roll", span = 86400 }, T.list, IST("11-01 23:02"), 11))

    NOW = IST("11-07 23:30")
    local h = T.headline()
    check("7 Nov 23:30, after his 5th since 18:08: 0 left", h.title == "TRADES 0/5 LEFT", h.title)
    check("...back at 02:08 (8 h after 18:08)", has(h.body, "back " .. hhmm(IST("11-08 02:08"))), h.body)
    local w, c, tone = T.chip()
    check("...the chip: NO TRADE and the time to it", w == "NO TRADE" and c == "2:38:00" and tone == "full",
        tostring(w) .. " " .. tostring(c) .. " " .. tostring(tone))
    check("...the Fruits row says when", T.short() == "back " .. hhmm(IST("11-08 02:08")), T.short())

    NOW = IST("11-08 02:24")
    h = T.headline()
    check("8 Nov 02:24: the 8 h cycle ended at 02:08 - 5/5 left", h.title == "TRADES 5/5 LEFT", h.title)
    check("...none used", has(h.body, "none used"), h.body)
    check("...and it says it is not sure: rolling 8 h would leave 1", has(h.body, "not sure yet")
        and has(h.body, "each trade back 8 h after it, 1 left"), h.body)
    check("...the chip: TRADES 5/5", select(2, T.chip()) == "5/5", select(2, T.chip()))
    check("...the page lists the other answers", has(T.report(), "if        each trade back 8 h after it: 1 left"),
        T.report())

    -- ======================================== the game's next count decides
    NOW = IST("11-08 02:30")
    msg("Trade completed (1/5).\nCheck your Inventory.")
    check("(1/5) at 02:30: rolling 8 h is out (it counted 5)", T.out.roll8 and T.out.roll8.counted == 5,
        T.out.roll8 and T.out.roll8.counted)
    check("...the 00:00 UTC day is out", T.out.day ~= nil, T.out.day)
    check("...the 12 h cycle is out", T.out.cycle12 ~= nil, T.out.cycle12)
    check("...the 8 h cycle stands", T.out.cycle8 == nil, T.out.cycle8)
    check("...said in the log", printed("ruled out \"each trade back 8 h after it\""), table.concat(PRINTED, " | "))
    check("...one trade added, the game's count on it", #T.list == 30 and T.list[30].n == 1, #T.list)
    check("...4/5 left now", T.headline().title == "TRADES 4/5 LEFT", T.headline().title)
    check("...the page: what was ruled out and why", has(T.rules(), "out     each trade back 8 h after it"), T.rules())

    -- kept: a new load reads the file and judges again
    reset({ keepFiles = true })
    SECTION()
    T = P.trades
    T.clock = function() return NOW end
    check("kept: the next load has the 30 trades", #T.list == 30, #T.list)
    check("...and the rules ruled out stay out", T.out.roll8 ~= nil and T.out.cycle8 == nil, T.out.roll8)
    check("...said at load", printed("[BFF] trades: "), table.concat(PRINTED, " | "))

    -- (5/5) instead: rolling fits with nothing unseen, the cycle needs 4
    withLedger(ledger(REAL, SAID))
    NOW = IST("11-08 02:30")
    msg("Trade completed (5/5).\nCheck your Inventory.")
    check("(5/5) at 02:30 instead: the day and the 12 h cycle are out", T.out.day and T.out.cycle12, T.out.day)
    check("...rolling 8 h is shown: it needs no unseen trade", T.status()[1].rule.key == "roll8",
        T.status()[1].rule.key)
    check("...the 8 h cycle fits only with 4 the script never saw", T.miss.cycle8 == 4, T.miss.cycle8)
    check("...0 left, the next back at 03:12", T.headline().title == "TRADES 0/5 LEFT"
        and has(T.headline().body, hhmm(IST("11-08 03:12"))), T.headline().body)

    -- ======================================== a trade, as the game sends it
    withLedger(nil)
    NOW = 1000
    check("nothing seen yet: said so", has(T.headline().body, "none seen on this account yet"), T.headline().body)
    check("...no chip of its own", T.chip() == nil, T.chip())
    done(222, { { Name = "Portal", Amount = 1 } }, { { Name = "Phoenix" } })
    check("a trade that went through is one", #T.list == 1, #T.list)
    check("...with whom, what you gave, what you got", T.list[1].with == "exodorxz" and T.list[1].gave == "Portal"
        and T.list[1].got == "Phoenix", tostring(T.list[1].with) .. " " .. tostring(T.list[1].gave))
    check("...BREAKING in the strip", BREAKING[1] and BREAKING[1].key == "trades"
        and has(BREAKING[1].text, "TRADE DONE with exodorxz"), BREAKING[1] and BREAKING[1].text)
    check("...written to the file at once", FILES[FILE] ~= nil and #HttpService:JSONDecode(FILES[FILE]).list == 1, FILES[FILE])
    done(222, { { Name = "Gas" } }, {}, "NotReady")
    check("a trade left before it went through is not one", #T.list == 1, #T.list)
    NOW += 3
    msg("Trade completed (1/5).\nCheck your Inventory.")
    check("the count right after: the same trade", #T.list == 1 and T.list[1].n == 1 and T.list[1].src == "both",
        #T.list .. " " .. tostring(T.list[1].n))

    withLedger(nil)
    NOW = 5000
    ADDED:Fire(label("Trade completed (2/5).\nCheck your Inventory."))
    check("the count off a new label: a trade", #T.list == 1 and T.list[1].n == 2, #T.list)
    check("...a label read twice is one count", times("the game says: Trade completed (2/5)") == 1,
        times("the game says: Trade completed (2/5)"))
    NOW += 2
    done(333, { { Name = "Yellow Lightning" } }, {})
    check("the count first, the trade after: one trade", #T.list == 1 and T.list[1].with == "Randyorton17"
        and T.list[1].src == "both", #T.list .. " " .. tostring(T.list[1].src))

    withLedger(nil)
    NOW = 9000
    msg("Trade completed (3/5). Check your Inventory.")
    ADDED:Fire(label("<font color=\"#00ff00\">Trade completed (3/5).</font>\nCheck your Inventory."))
    check("the same count by both ways, written a little differently: one trade", #T.list == 1, #T.list)
    ADDED:Fire(label("Trade completed (4/5).", { BFFHUD = true }))
    ADDED:Fire(label("Trade completed (4/5).", { Chat = true }))
    check("this panel's own words and the chat are not the game's", #T.list == 1, #T.list)
    local notes = #T.notes
    ADDED:Fire(label("TREASURE TRADE"))
    check("a title is not a message", #T.notes == notes and not printed("TREASURE"), #T.notes)
    msg("You have reached the trade limit")
    check("a limit message is written down", printed("the game says: You have reached the trade limit")
        and has(T.notes[#T.notes].text, "trade limit"), T.notes[#T.notes] and T.notes[#T.notes].text)
    check("...and is not a trade", #T.list == 1, #T.list)

    -- ======================================== trades it never saw
    withLedger(nil)
    NOW = IST("11-08 10:00")
    msg("Trade completed (3/5).\nCheck your Inventory.")
    h = T.headline()
    check("the game says (3/5), the script saw 1: 2/5 left (the game's count)", h.title == "TRADES 2/5 LEFT", h.title)
    check("...the time is the latest it can be: \"by\"", has(h.body, "back by " .. hhmm(IST("11-08 18:00"))), h.body)

    -- ======================================== the moment they come back
    withLedger(ledger(REAL, SAID))
    NOW = IST("11-08 02:00")
    T.tick()
    NOW = IST("11-08 02:09")
    T.tick()
    T.tick()
    check("02:09: back, said once", times("[BFF] trades: back - 5 of 5 left") == 1,
        times("[BFF] trades: back - 5 of 5 left"))
    check("...and BREAKING", BREAKING[#BREAKING] and has(BREAKING[#BREAKING].text, "TRADES BACK"),
        BREAKING[#BREAKING] and BREAKING[#BREAKING].text)

    -- 02:24 on 8 Nov the rules disagree: the 00:00 UTC day says 0 left, the 8 h cycle 5.
    withLedger(ledger(REAL, SAID))
    NOW = IST("11-08 02:24")
    local gone = { at = 0, said = 0, counted = 0 }
    T.out.cycle8, T.out.roll8 = gone, gone                  -- the day shown: 0 left
    T.tick()
    local dayLeft = T.status()[1].s.left
    T.out.cycle8 = nil                                      -- the cycle shown again: 5 left, same minute
    T.tick()
    check("a rule ruled out changes the count: not trades coming back", dayLeft == 0 and not printed("back - "),
        dayLeft .. " | " .. table.concat(PRINTED, " | "))

    -- ======================================== the three kinds of rule
    local H = 3600
    local cyc = { kind = "cycle", span = 8 * H }
    local list = { { t = 0 }, { t = 100 }, { t = 8 * H + 50 } }
    local n, back = T.count(cyc, list, 8 * H + 60)
    check("cycle: a trade after 8 h starts a new cycle", n == 1 and back == 16 * H + 50, n .. " " .. tostring(back))
    n, back = T.count({ kind = "roll", span = 8 * H }, { { t = 0 }, { t = 100 }, { t = 200 } }, 8 * H + 150)
    check("roll: only the trades of the last 8 h, the oldest back first", n == 1 and back == 8 * H + 200,
        n .. " " .. tostring(back))
    n, back = T.count({ kind = "day", at = 0 }, { { t = 86400 - 3600 }, { t = 86400 + 3600 } }, 86400 + 5400)
    check("day: only today's, back at midnight UTC", n == 1 and back == 2 * 86400, n .. " " .. tostring(back))
    check("items: the game's names, x2, else its id", T.items({ Items = { { Name = "Venom", Amount = 2 } } }) == "Venom x2"
        and T.items({ Items = { { ItemId = 55 } } }) == "#55", T.items({ Items = { { ItemId = 55 } } }))

    -- ======================================== clear, and a missing remote
    withLedger(ledger(REAL, SAID))
    T.clear()
    check("clear: forgotten", #T.list == 0 and next(T.out) == nil, #T.list)
    check("...the file too", #HttpService:JSONDecode(FILES[FILE]).list == 0, FILES[FILE])
    withLedger(nil, { noTradeEvent = true })
    check("no TradeEvent remote: still listening for the count", has(T.note, "TradeEvent no")
        and has(T.note, "CommE yes"), T.note)
    msg("Trade completed (1/5).")
    check("...and the count still makes a trade", #T.list == 1, #T.list)
    _G.BFF = {}
    msg("Trade completed (2/5).")
    check("a reloaded script's old listeners do nothing", #T.list == 1, #T.list)
    _G.BFF = P
end

realPrint(all and "ALL PASS" or "SOME FAILED")
