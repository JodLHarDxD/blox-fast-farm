-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS  " or "FAIL  ") .. name .. ((not cond and detail) and ("  (" .. tostring(detail) .. ")") or ""))
    if not cond then all = false end
end

local THIRD = PORTALS[3]
local function named(p) return p and p.name or "fly" end
local SPEED = 350

-- Floating Turtle side, you at Hydra: 19.3k studs straight = 55 s; the
-- Mansion's portal lands 800 from it = 3 + 2.3 s.
local hydra = Vector3.new(5600, 1000, -300)
local nearMansion = Vector3.new(-12000, 380, -8200)
local p, saves = P.portalPick(hydra, nearMansion, THIRD, SPEED, {}, 0)
check("far across the sea: the portal that lands nearest (the Mansion)", named(p) == "the Mansion", named(p))
check("...and what it saves, in seconds (~50 s)", saves > 47 and saves < 52, saves)

-- A fruit 600 studs away: flying is quicker than any jump.
p = P.portalPick(hydra, hydra + Vector3.new(600, 0, 0), THIRD, SPEED, {}, 0)
check("a short way: fly", p == nil, named(p))

-- A goal just past the Castle: the Castle portal, from far.
local nearCastle = Vector3.new(-5300, 320, -3000)
p = P.portalPick(hydra, nearCastle, THIRD, SPEED, {}, 0)
check("near the Castle on the Sea, from Hydra: the Castle portal", named(p) == "the Castle on the Sea", named(p))

-- Saves under 5 s: not worth the jump.
local from = Vector3.new(-5072, 314, -3151) + Vector3.new(2400, 0, 0)       -- 2400 from the Castle
p = P.portalPick(from, Vector3.new(-5072, 314, -3151) + Vector3.new(800, 0, 0), THIRD, SPEED, {}, 0)
check("saves under 5 s (1600 studs = 4.6 s, the jump 3 s): fly", p == nil, named(p))

-- A portal that did not move you is left for a while.
local bad = { ["the Mansion"] = 600 }
p = P.portalPick(hydra, nearMansion, THIRD, SPEED, bad, 100)
check("the Mansion refused earlier: not tried till its time", named(p) ~= "the Mansion", named(p))
check("...the next best still beats flying (the Castle, halfway)", named(p) == "the Castle on the Sea", named(p))
p = P.portalPick(hydra, nearMansion, THIRD, SPEED, bad, 700)
check("...after its time: the Mansion again", named(p) == "the Mansion", named(p))

-- A slower flight makes the jump worth more.
local _, s1 = P.portalPick(hydra, nearCastle, THIRD, 350, {}, 0)
local _, s2 = P.portalPick(hydra, nearCastle, THIRD, 150, {}, 0)
check("slower flying: the portal saves more", s2 > s1, s1 .. " " .. s2)

check("every sea has its portals; the Third Sea's are the Castle, the Mansion, Hydra",
    #PORTALS[1] == 4 and #PORTALS[2] == 4 and #THIRD == 3
    and THIRD[1].name == "the Castle on the Sea" and THIRD[2].name == "the Mansion" and THIRD[3].name == "Hydra Island")
check("no portals known (a sea not known): fly", P.portalPick(hydra, nearMansion, nil, SPEED, {}, 0) == nil)

print(all and "ALL PASS" or "SOME FAILED")
