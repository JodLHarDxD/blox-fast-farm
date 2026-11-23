
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function servers()
    return {
        { id = "a", count = 5 }, { id = "b", count = 1 }, { id = "here", count = 0 },
        { id = "full", count = 12 }, { id = "d", count = 3 }, { id = "e", count = 2 },
        { id = "f", count = 4 }, { id = "g", count = 6 },
    }
end

-- 1. THE CHALICE IN THE BACKPACK: no hop, not one join
reset()
ROWS, HOLD = servers(), true
local r = hop("test")
check("chalice held: refused, no join, chalice stop", r == false and #log.joins == 0
    and log.chaliceStops == 1 and log.carries == 0, #log.joins)
check("...and nothing stored: no hop, so nothing to lose", log.stores == 0, log.stores)

-- 2. chalice already seen in this server (used since): still refused
reset()
ROWS, E.chalice = servers(), true
r = hop("test")
check("chalice seen here earlier: refused, no join", r == false and #log.joins == 0)

-- 3. no chalice: fewest players first, five a round, every one marked
reset()
ROWS = servers()
r = hop("test")
local got = table.concat(log.joins, ",")
check("joins in order b,e,d,f,a then g", got == "b,e,d,f,a,g", got)
check("this server and every tried one marked looked-at",
    E.visited.here == NOW and E.visited.b == NOW and E.visited.g == NOW)
check("all failed: false, not left hopping, fails counted", r == false and not E.hopping
    and E.tally.fails == 6, E.tally.fails)
check("the backpack stored ONCE, before the first join (a carried fruit is lost on a hop)",
    log.stores == 1 and log.storedBeforeJoin == true, log.stores)

-- 4. THE CHALICE ARRIVES MID-HOP (drop lands while the list is read): the
-- next teleport never happens
reset()
ROWS = servers()
AFTER_JOIN = function() HOLD = true end
r = hop("test")
check("chalice after the first try: no second join", #log.joins == 1 and log.chaliceStops == 1
    and r == false and not E.hopping, #log.joins)

-- 5. a hop already running: not a second one
reset()
ROWS, E.hopping = servers(), true
r = hop("test")
check("already hopping: nothing", r == false and #log.joins == 0)

-- 6. stopped mid-hop (epoch moved): gives up at once
reset()
ROWS = servers()
AFTER_JOIN = function() epoch += 1 end
r = hop("test")
check("stop mid-hop: one try, then out", #log.joins == 1 and r == false and not E.hopping)

-- 7. A FIRE FLOWER CAME HERE: this server is kept away 600 s longer (5-15 min cooldown)
reset()
ROWS = servers()
hop("flower picked", 600)
check("flower server: marked 600 s ahead, so it is skipped 10 min longer", E.visited.here == NOW + 600,
    tostring(E.visited.here))
reset()
ROWS = servers()
hop("no flower")
check("no keep-away given: marked now, as before", E.visited.here == NOW)

-- 8. PvP (2026-10-24): busiest first, then the ping order; the list read is learned from
reset()
ROWS = servers()
CFG.Pvp, CFG.PvpHopBusy = true, true
local learned, rankedIn = nil, nil
P.pingLearn = function(rows) learned = #rows end
P.pingRank = function(c)
    if rankedIn == nil and c[1] then rankedIn = c[1].id end    -- the first round's list
    local out = {}
    for i = #c, 1, -1 do table.insert(out, c[i]) end      -- a fake order: reversed
    return out
end
hop("pvp")
check("PvP: the list is learned from, every row", learned == 8, tostring(learned))
check("PvP: busiest first into the ping order (g = 6 players)", rankedIn == "g", tostring(rankedIn))
check("PvP: joins follow the ping order", log.joins[1] == "b", tostring(log.joins[1]))
reset()
ROWS = servers()
CFG.PvpHopBusy = false
rankedIn = nil
hop("pvp, busy off")
check("busy off: the hunts' order (fewest), no ping order", rankedIn == nil and log.joins[1] == "b",
    tostring(log.joins[1]))
CFG.Pvp, CFG.PvpHopBusy, P.pingLearn, P.pingRank = nil, nil, nil, nil

-- A FRUIT TOO GOOD TO LOSE, no slot (user, 2026-10-25): not one teleport -
-- by hand, PvP or hunt alike; storage tried once more first
local KEEPERS, TRIED = {}, nil
P.keepersLeft = function(tryStore) TRIED = tryStore return KEEPERS end
P.keepWords = function(list) return list[1].orig end
reset()
ROWS, KEEPERS = servers(), { { orig = "Control-Control", value = 120e6 } }
r = hop("by hand")
check("kept fruit, no slot: refused, no join, nothing carried", r == false and #log.joins == 0
    and log.carries == 0 and not E.hopping, #log.joins)
check("...storage tried once more first", TRIED == true)
check("...nothing else stored either (no hop, nothing to lose)", log.stores == 0)
check("...says which fruit and why", string.find(E.note, "Control-Control", 1, true)
    and string.find(E.note, "hop loses it", 1, true), E.note)
reset()
ROWS, KEEPERS = servers(), {}
r = hop("test")
check("traded / stored since: the hop goes on", #log.joins > 0, #log.joins)
P.keepersLeft, P.keepWords = nil, nil

-- R4 F2: STOP CANCELS EVERY PENDING HOP (owner: Stop still hopped).
-- P.hopCancel is what P.stop and Home's Stop call; a hop by hand runs with
-- the farm stopped, so the epoch alone cannot end it.
-- a. Stop while the backpack is stored before the hop: not one join
reset()
ROWS = servers()
P.storeBeforeHop = function() P.hopCancel() end
r = hop("by hand")
check("stop during the store: no join, no list, not hopping", r == false and #log.joins == 0
    and not E.hopping and E.note == "hop stopped", #log.joins)
-- b. Stop while the server list is read: not one join
reset()
ROWS = servers()
LIST_HOOK = function() P.hopCancel() end
r = hop("by hand")
check("stop during the list: no join", r == false and #log.joins == 0 and not E.hopping, #log.joins)
-- c. Stop while a join is waited on: no second join, no retry round
reset()
ROWS = servers()
AFTER_JOIN = function() P.hopCancel() end
r = hop("auto")
check("stop during a join: that one only, no retry", r == false and #log.joins == 1 and not E.hopping,
    table.concat(log.joins, ","))
check("...the join was handed the cancel test", log.goneGiven == true)
check("...the carry written again with resume off (a teleport already started lands stopped)",
    log.lastResume == false and E.carryOut == false, tostring(log.lastResume))
-- d. the farm's own Stop (epoch) while the join waits: the same
reset()
ROWS = servers()
AFTER_JOIN = function() epoch += 1 end
r = hop("auto")
check("epoch stop during a join: no retry", #log.joins == 1 and not E.hopping)
-- e. a cancel with nothing pending: says nothing, no file written
reset()
check("cancel with no hop: false, nothing written", P.hopCancel() == false and log.files == 0)
-- f. a hop after a cancel runs (the token is per hop, not a latch)
reset()
P.hopCancel()
ROWS = servers()
r = hop("by hand")
check("a new hop after the cancel joins", #log.joins == 6, #log.joins)
-- g. the cancelled hop never clears the NEXT hop's flag
reset()
ROWS = servers()
AFTER_JOIN = function()
    P.hopCancel()
    E.hopping = true          -- a new hop has begun meanwhile
end
hop("old")
check("old hop leaves the new hop's flag alone", E.hopping == true)
-- h. a new copy replacing this one (P.stop "reload"): the carry stays carried
reset()
ROWS = servers()
AFTER_JOIN = function() P.hopCancel(true) end
hop("auto")
check("reload: no carry rewrite", log.lastResume ~= false and E.carryOut == true, tostring(log.lastResume))
-- i. pending: P.hopPending is what Home's pill reads
reset()
ROWS = servers()
local seen
AFTER_JOIN = function() seen = P.hopPending() P.hopCancel() end
hop("by hand")
check("pending while it joins, not after the cancel", seen == true and P.hopPending() == false)
-- j. why no hop: the chalice dims Home's button
reset()
check("no chalice: hop allowed", P.hopBlocked() == nil)
HOLD = true
check("chalice held: blocked, says why", P.hopBlocked() == "the God's Chalice is with you")
HOLD = false
E.chalice = true
check("chalice seen here: blocked", P.hopBlocked() ~= nil)

print(all and "ALL PASS" or "SOME FAILED")
