local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b, e) return math.abs(a - b) < (e or 1e-3) end

-- easing: CSS cubic-bezier curves
check("linear is the identity", near(cssEase("linear", 0.3), 0.3))
check("ease-in-out is symmetric", near(cssEase("ease-in-out", 0.5), 0.5) and near(cssEase("ease-in-out", 0.25) + cssEase("ease-in-out", 0.75), 1))
check("ease-in-out starts slow", cssEase("ease-in-out", 0.1) < 0.1)
check("ease-out starts fast", cssEase("ease-out", 0.1) > 0.1)
check("ease (CSS default) at half is ~0.80", near(cssEase("ease", 0.5), 0.8024, 0.01), cssEase("ease", 0.5))
check("ends hold", cssEase("ease", 0) == 0 and cssEase("ease", 1) == 1)

-- keyframes: per-segment easing, held stops, lists
local st = { { 0, 0 }, { 0.25, 0 }, { 0.5, 10 }, { 1, 10 } }
check("held before a ramp", kfAt(st, 0.2, "linear") == 0)
check("linear ramp mid", near(kfAt(st, 0.375, "linear"), 5))
check("held after", kfAt(st, 0.9, "linear") == 10)
local v = kfAt({ { 0, { 0, 0 } }, { 1, { 168, -18 } } }, 0.5, "linear")
check("lists mix per item", near(v[1], 84) and near(v[2], -9))

-- the boards' animations
check("ffWord: 0% = hidden, 10 px low", coverAnimAt("ffWord", 0)[1] == 1 and coverAnimAt("ffWord", 0)[2] == 10)
check("ffWord: in from 4% to 21% (0.32 - 1.68 s)", coverAnimAt("ffWord", 1)[1] == 0 and coverAnimAt("ffWord", 1)[2] == 0)
check("ffWord: out by 25%, 6 px up", coverAnimAt("ffWord", 2.5)[1] == 1 and coverAnimAt("ffWord", 2.5)[2] == -6)
check("ffWord fill both: word 4 waits at its 0% frame", coverAnimAt("ffWord", 1, 6)[2] == 10)
check("ffWord word 4 is in at 7 s", coverAnimAt("ffWord", 7, 6)[1] == 0)
check("ffWord loops every 8 s", coverAnimAt("ffWord", 9)[1] == coverAnimAt("ffWord", 1)[1])
check("ffS1 fills over the first 2 s", near(coverAnimAt("ffS1", 1), 0.5) and coverAnimAt("ffS1", 5) == 1)
check("ffS1 empties at the loop", near(coverAnimAt("ffS1", 7.9999), 0, 0.1) or coverAnimAt("ffS1", 8) == 0)
check("ffS3 waits half the loop", coverAnimAt("ffS3", 3.9) == 0 and near(coverAnimAt("ffS3", 5), 0.5))
check("ffS4 fills the last quarter", coverAnimAt("ffS4", 5.9) == 0 and near(coverAnimAt("ffS4", 7), 0.5))
check("ffSwell peaks 1.07 at 2 s", near(coverAnimAt("ffSwell", 2), 1.07) and near(coverAnimAt("ffSwell", 0), 1))
check("ffSwell delayed .6 s rests at 1", coverAnimAt("ffSwell", 0.3, 0.6) == 1)
check("ffBoat: -40 to 340 linear", coverAnimAt("ffBoat", 0) == -40 and near(coverAnimAt("ffBoat", 4), 150))
check("ffFin: down, up at 42-60%, down", coverAnimAt("ffFin", 1) == 22 and coverAnimAt("ffFin", 4) == 0
    and coverAnimAt("ffFin", 7) == 22)
local p = coverAnimAt("frPing", 0)
check("frPing starts at .3, opacity .9", near(p[1], 0.3) and near(p[2], 0.1))
p = coverAnimAt("frPing", 1.99)
check("frPing ends near 1.6, gone", near(p[1], 1.6, 0.01) and near(p[2], 1, 0.01))
p = coverAnimAt("frPing", 0.5, 1)
check("frPing 2 before its delay: the ring as drawn", p[1] == 1 and p[2] == 0)
check("frBob: -6 px at 1.5 s", near(coverAnimAt("frBob", 1.5), -6) and near(coverAnimAt("frBob", 3), 0))
local y = coverAnimAt("frYou", 4)
check("frYou: at the fruit 45-60%", near(y[1], 168) and near(y[2], -18))
check("frYou: home again from 85%", coverAnimAt("frYou", 7.5)[1] == 0)
check("frGot: STORED 50-62% only", coverAnimAt("frGot", 3) == 1 and coverAnimAt("frGot", 4.4) == 0
    and coverAnimAt("frGot", 6) == 1)
check("unknown name -> nil", coverAnimAt("nope", 1) == nil)

-- the trial recap
check("durWords", durWords(6 * 3600 + 12 * 60) == "6h 12m" and durWords(3900) == "1h 05m" and durWords(600) == "10m")
local PO = { elite = "raid", seaevents = "sea", circuit = "farm", random = "farm", pvp = "pvp" }
local PK = { raid = { price = "$0.99" }, sea = { price = "$1.49" }, farm = { price = "$0.99" }, pvp = { price = "$1.99" } }
local r = trialRecapOf({ elite = 22320, seaevents = 9600, circuit = 3900, random = 30, pvp = 120, nope = 9999 },
    { elite = "Elite pirates" }, PO, PK)
check("recap: top 3 by time, under a minute and unknown modes out", #r.rows == 3 and r.rows[1].mode == "elite"
    and r.rows[3].mode == "circuit", r.rows[3] and r.rows[3].mode)
check("recap: name, bar against the first", r.rows[1].name == "Elite pirates" and r.rows[1].frac == 1
    and near(r.rows[2].frac, 9600 / 22320))
check("recap: packs in order, $3.47, EVERYTHING $0.48 less", r.packs[1] == "raid" and r.packs[3] == "farm"
    and r.sum == 3.47 and r.save == 0.48, r.sum)
r = trialRecapOf({ circuit = 600, random = 700 }, nil, PO, PK)
check("recap: one pack counted once", #r.packs == 1 and r.sum == 0.99 and r.save == -2)
check("recap: nothing used", #trialRecapOf({}, nil, PO, PK).rows == 0 and #trialRecapOf(nil, nil, PO, PK).packs == 0)

-- executor checks
local n, miss = execChecks({ writefile = true, readfile = true, isfile = true, queue_on_teleport = true,
    hookmetamethod = true, fireproximityprompt = true, firetouchinterest = true })
check("execChecks: all 7", n == 7 and #miss == 0)
n, miss = execChecks({})
check("execChecks: none", n == 0 and #miss == 7 and miss[1] == "writefile")

print(all and "ALL PASS" or "SOME FAILED")
