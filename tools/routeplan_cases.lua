
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    realPrint((cond and "PASS " or "FAIL ") .. name)
    if not cond then realPrint("  " .. tostring(detail)) all = false end
end
local function kinds(steps)
    local w = {}
    for _, s in ipairs(steps) do table.insert(w, s.kind == "home" and "home" or s.pad.name) end
    return table.concat(w, ",")
end
-- The Third Sea's graph, as ROUTES builds it: each pad, where its ride puts you.
local function pads()
    return {
        { id = "c-h", name = "HydraTP", hit = CASTLE_HYDRA.hb.Position, out = HYDRA.attrs.Pivot.Position, secs = 2.5 },
        { id = "c-m", name = "MansionTP", hit = CASTLE_MANSION.hb.Position, out = MANSION.attrs.Pivot.Position, secs = 2.5 },
        { id = "c-t", name = "TikiTP", hit = CASTLE_TIKI.hb.Position, out = TIKI.attrs.Pivot.Position, secs = 2.5 },
        { id = "h", name = "HydraTP", hit = HYDRA.hb.Position, out = CASTLE_HYDRA.attrs.Pivot.Position, secs = 2.5 },
        { id = "m", name = "MansionTP", hit = MANSION.hb.Position, out = CASTLE_MANSION.attrs.Pivot.Position, secs = 2.5 },
        { id = "t", name = "TikiTP", hit = TIKI.hb.Position, out = CASTLE_TIKI.attrs.Pivot.Position, secs = 2.5 },
    }
end
local HOME = { pos = SPAWNS["Castle on the Sea"], secs = 6 }
local SEA_OF_TEARS = v3(-9500, 20, 6000)
local HYDRA_TOWN = v3(5300, 1000, 100)
local TURTLE = v3(-12000, 330, -8800)
local PORT_TOWN = v3(81, 44, 5724)          -- Pirate Millionaire camp (fast_farm's LEVELS)

-- a short trip: straight
local steps, secs, direct = P.routePlan(v3(0, 0, 0), v3(500, 0, 0), { home = HOME, pads = pads() }, 300)
check("short trip: no teleport, straight", #steps == 0 and math.abs(secs - direct) < 1e-6, kinds(steps))

-- the user's example: Sea of Tears -> Hydra Island = Home (the Castle), the Hydra pad
steps, secs, direct = P.routePlan(SEA_OF_TEARS, HYDRA_TOWN, { home = HOME, pads = pads() }, 300)
check("Sea of Tears -> Hydra: Home, then the Castle's Hydra pad", kinds(steps) == "home,HydraTP", kinds(steps))
check("...far shorter than flying", secs < direct / 3, string.format("%.0f vs %.0f", secs, direct))

-- the user's example: Floating Turtle -> Port Town. Hydra's pad comes out ~2,000
-- studs nearer Port Town than the Castle: Home, the Hydra pad, then fly
steps = P.routePlan(TURTLE, PORT_TOWN, { home = HOME, pads = pads() }, 300)
check("Floating Turtle -> Port Town: Home, the Castle's Hydra pad, then fly", kinds(steps) == "home,HydraTP", kinds(steps))
steps = P.routePlan(TURTLE, PORT_TOWN, { pads = pads() }, 300)
check("...Home off: the Mansion's pad to the Castle, its Hydra pad (two rides)", kinds(steps) == "MansionTP,HydraTP", kinds(steps))
steps = P.routePlan(TURTLE, v3(-5400, 60, -2400), { home = HOME, pads = pads() }, 300)
check("Floating Turtle -> by the Castle: Home, then fly", kinds(steps) == "home", kinds(steps))

-- the Castle -> Floating Turtle: the Castle's Mansion pad (Home is where you are)
steps = P.routePlan(v3(-5060, 316, -3140), v3(-12300, 330, -7900), { home = HOME, pads = pads() }, 300)
check("at the Castle -> Floating Turtle: the Mansion pad", kinds(steps) == "MansionTP", kinds(steps))

-- Hydra -> Tiki: two rides through the Castle
steps = P.routePlan(v3(5600, 1010, -300), v3(-16150, 20, 600), { pads = pads() }, 300)
check("Hydra -> Tiki, no Home: Hydra pad, then the Castle's Tiki pad", kinds(steps) == "HydraTP,TikiTP", kinds(steps))

-- a pad whose ride's end is not known: never planned
local p2 = pads()
for _, p in ipairs(p2) do if p.name == "HydraTP" then p.out = nil end end
steps = P.routePlan(SEA_OF_TEARS, HYDRA_TOWN, { home = HOME, pads = p2 }, 300)
check("Hydra pad's end not known: not planned (Home, then fly)", kinds(steps) == "home", kinds(steps))

-- standing by a pad: its ride beats the Home countdown
steps = P.routePlan(v3(5600, 1010, -300), v3(-4900, 320, -2900), { home = HOME, pads = pads() }, 300)
check("at Hydra's pad -> the Castle: the pad (2.5 s), not Home (6 s)", kinds(steps) == "HydraTP", kinds(steps))
-- Home only from where you start: never after a ride
local homeAfter = false
steps = P.routePlan(v3(-16150, 20, 600), HYDRA_TOWN, { home = HOME, pads = pads() }, 300)
local seenPad = false
for _, s in ipairs(steps) do
    if s.kind ~= "home" then seenPad = true elseif seenPad then homeAfter = true end
end
check("...never Home after a pad", not homeAfter, kinds(steps))

-- a dear Home (a slow countdown) loses to the pads
steps = P.routePlan(TURTLE, PORT_TOWN, { home = { pos = HOME.pos, secs = 60 }, pads = pads() }, 300)
check("Home at 60 s: the pads instead", kinds(steps) == "MansionTP,HydraTP", kinds(steps))

-- nothing to plan with: straight
steps, secs, direct = P.routePlan(TURTLE, PORT_TOWN, { pads = {} }, 300)
check("no Home, no pads: straight", #steps == 0 and secs == direct)

realPrint(all and "ALL PASS" or "SOME FAILED")
