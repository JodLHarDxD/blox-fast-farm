
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b, tol) return a and b and (a - b).Magnitude <= (tol or 0.01) end

-- 1. FROZEN: a pulled enemy cannot walk out of the pile. Held only by a write
--    every frame, it walked off the moment it was let go for one frame (an
--    ownership blip, a pile rebuilt without it) -- the public hubs all set
--    WalkSpeed 0, JumpPower 0 and PlatformStand on the ones they bring.
local a, b, c = enemy(v3(100, 0, 0)), enemy(v3(-100, 0, 0)), enemy(v3(0, 0, 100))
pile = { a, b, c }
clock = 1
magnetTick()
check("pulled: frozen (WalkSpeed 0, JumpPower 0, PlatformStand)",
    a.hum.WalkSpeed == 0 and a.hum.JumpPower == 0 and a.hum.PlatformStand == true
        and c.hum.WalkSpeed == 0, a.hum.WalkSpeed .. " " .. a.hum.JumpPower .. " " .. tostring(a.hum.PlatformStand))
check("pulled: on the ring round the centre", (a.root.Position - pileCentre).Magnitude < 3.01
    and (a.root.Position - pileCentre).Magnitude > 2.99, (a.root.Position - pileCentre).Magnitude)

-- 2. ITS OWN PLACE. The ring slot was the enemy's index in the pile list, so
--    a death or a reorder moved every other one across the ring each time.
local atB, atC = b.root.Position, c.root.Position
pile = { c, b }                          -- a died; the list is rebuilt in another order
clock = 2
magnetTick()
check("a death / a reorder: the others keep their places on the ring",
    near(b.root.Position, atB) and near(c.root.Position, atC),
    string.format("b moved %.2f, c moved %.2f", (b.root.Position - atB).Magnitude, (c.root.Position - atC).Magnitude))

-- 3. two in the pile never share a spot
local d = enemy(v3(5, 0, 5))
pile = { c, b, d }
clock = 3
magnetTick()
check("a newcomer gets a spot of its own", (d.root.Position - b.root.Position).Magnitude > 1
    and (d.root.Position - c.root.Position).Magnitude > 1)

-- 3b. the game sets its speed back: frozen again the next frame
b.hum.WalkSpeed, b.hum.PlatformStand = 16, false
clock = 3.5
magnetTick()
check("speed set back by the game: frozen again", b.hum.WalkSpeed == 0 and b.hum.PlatformStand == true)

-- 4. one alone sits at the centre
pile = { d }
clock = 4
magnetTick()
check("one alone: at the centre", near(d.root.Position, pileCentre), (d.root.Position - pileCentre).Magnitude)

print(all and "ALL PASS" or "SOME FAILED")
