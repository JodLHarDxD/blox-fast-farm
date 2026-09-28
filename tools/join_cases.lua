
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- JOIN 1. THE BUG (2026-09-28): the servers came from the Roblox list, the
-- join went out from here and the Third Sea refused it (no teleport token).
-- With the game's server browser present the join is ALWAYS the game's.
reset()
GAME_JOIN = function() refuse("Server is full") end
HERE_JOIN = function() refuse(TOKEN) end
joinServer("job-1", 0)
check("remote there: the game's join, never one from here",
    table.concat(CALLS, ",") == "game:job-1", table.concat(CALLS, ","))
check("the refusal's words are kept", E.lastJoin == "game's join: Server is full", E.lastJoin)

-- JOIN 2. no game remote: from here; a token refusal = never again here
reset()
SB = nil
HERE_JOIN = function() refuse(TOKEN) end
joinServer("job-1", 0)
check("remote missing: joined from here", table.concat(CALLS, ",") == "here:job-1", table.concat(CALLS, ","))
check("token refusal marks this place", E.clientRefused == true
    and string.find(E.lastJoin, "join from here: ", 1, true) == 1, E.lastJoin)
joinServer("job-2", 0)
check("after it: not tried again", #CALLS == 1 and string.find(E.lastJoin, "no way to join", 1, true) == 1,
    E.lastJoin)

-- JOIN 3. another refusal from here (full server) does not mark the place
reset()
SB = nil
HERE_JOIN = function() refuse("Requested server is full") end
joinServer("job-1", 0)
check("a full server is not a token refusal", E.clientRefused == false)

-- JOIN 4. the game's join answers but no teleport comes: the wait still ends
reset()
GAME_JOIN = function() return false end
joinServer("job-1", 0)
check("no teleport: gives up after 15 s", CLOCK >= 15 and CLOCK < 16, CLOCK)
check("what the game answered is shown", E.lastJoin == "game's join: no teleport within 15 s  (the game said false)",
    E.lastJoin)

-- JOIN 5. the call itself errors: no 15 s wait
reset()
GAME_JOIN = function() error("InvokeServer throttled") end
joinServer("job-1", 0)
check("call error: out at once, said why", CLOCK < 1 and string.find(E.lastJoin, "the call failed", 1, true) ~= nil,
    tostring(CLOCK) .. " " .. tostring(E.lastJoin))

-- JOIN 6. somebody else's failed teleport is not ours
reset()
GAME_JOIN = function() TeleportService.TeleportInitFailed:Fire({ UserId = 2 }, "Failure", "theirs") end
joinServer("job-1", 0)
check("another player's failure ignored", CLOCK >= 15 and not string.find(E.lastJoin, "theirs", 1, true),
    E.lastJoin)

-- JOIN 7. stopped mid-wait: out at once; listeners gone
reset()
GAME_JOIN = function() epoch += 1 end
joinServer("job-1", 0)
check("stop mid-join: out, said so", CLOCK < 1 and E.lastJoin == "game's join: stopped", E.lastJoin)
check("listeners disconnected", #TeleportService.TeleportInitFailed.cbs == 0 and #player.OnTeleport.cbs == 0)

-- LIST 1. no remote: nil, and why
reset()
SB = nil
check("list: no remote = nil + why", browserList(0) == nil
    and string.find(E.listWhy, "is missing", 1, true) ~= nil, E.listWhy)

-- LIST 2. page 1 errors
reset()
PAGES[1] = function() error("not allowed") end
local out = browserList(0)
check("list: page 1 error = empty + why", #out == 0 and string.find(E.listWhy, "its page 1 failed", 1, true) == 1,
    E.listWhy)

-- LIST 3. a moved format (an array) is described, not silently empty
reset()
PAGES[1] = { { JobId = "x", Count = 3 } }
out = browserList(0)
check("list: array page described", #out == 0
    and E.listWhy == "its page 1 gave a table of 1, first number 1 -> table", E.listWhy)
reset()
PAGES[1] = nil
browserList(0)
check("list: nil page described", E.listWhy == "its page 1 gave nil nil", E.listWhy)

-- LIST 4. the known format: read, no why left over
reset()
E.listWhy = "old"
PAGES[1] = { ["job-a"] = { Count = 2 }, ["job-b"] = { Count = 5 } }
PAGES[2] = { ["job-a"] = { Count = 2 } }
out = browserList(0)
check("list: two servers, stops on a page with nothing new", #out == 2 and E.listWhy == nil, #out)

print(all and "ALL PASS" or "SOME FAILED")
