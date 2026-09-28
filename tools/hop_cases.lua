
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

print(all and "ALL PASS" or "SOME FAILED")
