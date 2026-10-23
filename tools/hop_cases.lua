
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

print(all and "ALL PASS" or "SOME FAILED")
