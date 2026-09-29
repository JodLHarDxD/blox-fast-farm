
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end

-- eliteReply: what the Elite Hunter said
check("no answer = unknown", eliteReply(nil) == "unknown" and eliteReply("") == "unknown"
    and eliteReply(5) == "unknown")
check("hub string = none",
    eliteReply("I don't have anything for you right now. Come back later.") == "none")
check("wiki string = none", eliteReply("I don't have anything for you right now.") == "none")
check("quest given = up", eliteReply("We heard some news about Diablo roaming around. Find and "
    .. "capture him, he was last seen near Floating Turtle.") == "up")
check("a bare elite name = up", eliteReply("Deandre") == "up" and eliteReply("URBAN!") == "up")
check("Tyrant = up", eliteReply("Tyrant of the Skies appeared") == "up")
check("greeting = unknown", eliteReply("Aye aye aye, looking for any difficult tasks?") == "unknown")

-- eliteIsle: where the words send you
local isle, pos = eliteIsle("he was last seen near Floating Turtle.")
check("Floating Turtle named", isle == "floating turtle" and pos and pos.X == -12000, tostring(isle))
check("Hydra Island named", (eliteIsle("last seen near Hydra Island")) == "hydra")
check("Port Town named", (eliteIsle("near Port Town")) == "port town")
check("Liberation of Tiki Outpost named", (eliteIsle("Liberation of Tiki Outpost")) == "tiki")
check("no island / no text", eliteIsle("somewhere") == nil and eliteIsle(nil) == nil)

-- browserRows: one page of the game's server browser
local rows = {}
check("not a table = 0 rows", browserRows(nil, rows) == 0 and browserRows("x", rows) == 0 and #rows == 0)
local n = browserRows({
    ["job-a"] = { Count = 3, Region = "Singapore" },
    ["job-b"] = { Count = 12 },
    [7] = { Count = 1 },
    ["job-c"] = 5,
}, rows)
local byId = {}
for _, r in ipairs(rows) do byId[r.id] = r end
check("string JobId + table entry only", n == 2 and byId["job-a"] and byId["job-b"] and not byId["job-c"], n)
check("count and region read", byId["job-a"].count == 3 and byId["job-a"].region == "Singapore")

-- pickServers: which servers, in what order
local seq = 0
local function rnd() seq += 1 return seq / 1000 end
local list = {
    { id = "a", count = 5 }, { id = "b", count = 1 }, { id = "here", count = 0 },
    { id = "full", count = 12 }, { id = "small", count = 8, max = 8 },
    { id = "seen", count = 0 }, { id = "old", count = 2 }, { id = "b", count = 1 },
    { id = 9, count = 0 }, { id = "nocount" },
}
local visited = { seen = 1000 - 60, old = 1000 - 700 }
local out = pickServers(list, "here", visited, 1000, 600, "fewest", rnd)
local ids = {}
for _, s in ipairs(out) do table.insert(ids, s.id) end
local got = table.concat(ids, ",")
check("fewest first; not here, not full, not seen in 10 min, no duplicates",
    got == "nocount,b,old,a", got)
seq = 0
out = pickServers({ { id = "x", count = 4 }, { id = "y", count = 4 } }, "h", {}, 0, 600, "fewest", function()
    seq += 1 return 10 - seq end)
check("equal counts: the random key decides", out[1].id == "y", out[1].id)
seq = 0
out = pickServers({ { id = "p", count = 1 }, { id = "q", count = 9 } }, "h", {}, 0, 600, "random", function()
    seq += 1 return 10 - seq end)
check("random order ignores the count", out[1].id == "q", out[1].id)

-- pruneVisited
local v = { a = 100, b = 5000, c = "x" }
pruneVisited(v, 5000, 3600)
check("older than an hour and junk forgotten", v.a == nil and v.b == 5000 and v.c == nil)

-- pickFruit: which fruit lying here is worth going for
local spawnCheap = { orig = "Rocket-Rocket", price = 5000 }
local spawnDear  = { orig = "Kitsune-Kitsune", price = 8000000 }
local dropFar    = { orig = "Yeti-Yeti", price = 5000000, dropper = "someone", dropperNear = false }
local dropNear   = { orig = "Tiger-Tiger", price = 5000000, dropper = "trader", dropperNear = true }
local unknown    = { orig = "New-New" }
check("server spawns: the dearest first", pickFruit({ spawnCheap, spawnDear }, 0, false) == spawnDear)
check("player drops off: a dear drop is ignored", pickFruit({ dropFar, spawnCheap }, 0, false) == spawnCheap)
check("player drops on: a drop whose dropper walked off counts", pickFruit({ dropFar, spawnCheap }, 0, true) == dropFar)
check("a dropper still by it = a trade: never taken, even with drops on",
    pickFruit({ dropNear }, 0, true) == nil)
check("minimum price: a cheap spawn is left", pickFruit({ spawnCheap }, 1000000, false) == nil
    and pickFruit({ spawnCheap, spawnDear }, 1000000, false) == spawnDear)
check("price unknown: taken only when the minimum is 0", pickFruit({ unknown }, 0, false) == unknown
    and pickFruit({ unknown }, 1, false) == nil)
check("nothing lying: nil", pickFruit({}, 0, true) == nil)

-- berryNames: what a bush's attributes say is on it
check("berry names read from attribute values, sorted, junk ignored",
    table.concat(berryNames({ a = "Red Cherry Berry", b = "Pink Pig Berry", c = 5, d = "Rock" }), ",")
        == "Pink Pig Berry,Red Cherry Berry")
check("no attributes / not a table: none", #berryNames({}) == 0 and #berryNames(nil) == 0)

-- pickBerry: the nearest bush holding one you want
local VM = {}
VM.__sub = function(a, b)
    local x, y, z = a.X - b.X, a.Y - b.Y, a.Z - b.Z
    return { Magnitude = math.sqrt(x * x + y * y + z * z) }
end
local function V(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, VM) end
local here = V(0, 0, 0)
local nearPig   = { names = { "Pink Pig Berry" }, pos = V(10, 0, 0) }
local farPig    = { names = { "Pink Pig Berry" }, pos = V(500, 0, 0) }
local nearBlue  = { names = { "Blue Icicle Berry" }, pos = V(5, 0, 0) }
local mixed     = { names = { "Blue Icicle Berry", "Red Cherry Berry" }, pos = V(300, 0, 0) }
check("nearest wanted bush", pickBerry({ farPig, nearPig }, { ["Pink Pig Berry"] = true }, here) == nearPig)
check("an unwanted berry is passed, however near",
    pickBerry({ nearBlue, farPig }, { ["Pink Pig Berry"] = true }, here) == farPig)
check("a bush with one wanted among others counts",
    pickBerry({ nearBlue, mixed }, { ["Red Cherry Berry"] = true }, here) == mixed)
check("none wanted / none on: nil", pickBerry({ nearBlue }, { ["Pink Pig Berry"] = true }, here) == nil
    and pickBerry({}, { ["Pink Pig Berry"] = true }, here) == nil
    and pickBerry({ nearPig }, {}, here) == nil)

print(all and "ALL PASS" or "SOME FAILED")
