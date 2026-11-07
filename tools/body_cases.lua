-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)
    print((cond and "PASS " or "FAIL ") .. name)
    if not cond then print("  " .. tostring(detail)) all = false end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end
-- ROOT.Position mirrors writes to ROOT.CFrame (stubs); reset both.
local function at(p)
    rawset(ROOT, "CFrame", cf(p))
    rawset(ROOT, "Position", p)
end

-- THE LOCK, EVERY MODE (2026-10-11): over the sea, never under the water line
-- (the slab's top + 4); off the slab, held where asked.
lockAt(vec(10, -30, 10))
check("any mode: asked to hold under the sea - held on the water line", near(lockCF.Position.Y, 4), lockCF.Position.Y)
lockAt(vec(15000, -30, 10))
check("off the sea slab: held where asked", near(lockCF.Position.Y, -30))

-- THE WATER AS ROCK (SEA EVENTS): a sea fight's floor.
P.floorY = 9
lockAt(vec(10, -30, 10))
check("a sea fight: asked to go under the water - held ON it (its floor)", near(lockCF.Position.Y, 9) and near(lockCF.Position.X, 10))
lockAt(vec(10, 40, 10), vec(50, 0, 10))
check("...above it: held where asked, facing the target", near(lockCF.Position.Y, 40))
lockAt(vec(10, 2, 10), vec(50, 0, 10))
check("...under it while facing a target: still held on the floor", near(lockCF.Position.Y, 9))

-- Every frame: whatever the lock says, never under the floor.
lockCF, lastWritten = cf(vec(0, -20, 0)), vec(0, -20, 0)
at(vec(0, -20, 0))
bodyHeartbeat()
check("every frame: a lock under the water is lifted onto it, the body written there",
    near(lockCF.Position.Y, 9) and near(ROOT.CFrame.Position.Y, 9), lockCF.Position.Y)

-- A KNOCKBACK / PULL (a Terrorshark's): 120 studs - adopted before, now refused in a sea fight.
lockCF, lastWritten = cf(vec(0, 40, 0)), vec(0, 40, 0)
P.keepLock = true
at(vec(120, 40, 0))
bodyHeartbeat()
check("a sea fight: thrown 120 studs - NOT adopted, the body back at the lock",
    near(ROOT.CFrame.Position.X, 0) and near(lockCF.Position.X, 0), ROOT.CFrame.Position.X)
-- A respawn / teleport (thousands of studs): still followed.
at(vec(20000, 40, 0))
bodyHeartbeat()
check("...a respawn far away (20,000): followed, never dragged back across the map", near(lockCF.Position.X, 20000))
-- Outside a sea fight: a 120-stud move is adopted as before.
P.keepLock, P.floorY = nil, nil
lockCF, lastWritten = cf(vec(0, 40, 0)), vec(0, 40, 0)
at(vec(120, 40, 0))
bodyHeartbeat()
check("outside a sea fight: a 120-stud move by the game adopted, as before", near(lockCF.Position.X, 120))

-- NO CHAIRS (user, 2026-11-07): "anything that is totally automated, it should
-- not be able to sit". A body held on a chair is in two places: your screen at
-- the NPC, the server on the chair. Out of it the frame it happens; your own
-- wheel only stays yours while the sea hunt is at it.
local function chair(name)
    local seat = { Name = name, CanTouch = true }
    local weld = { Name = "SeatWeld" }
    local other = { Name = "Attachment" }
    function other:Destroy() seat.lostOther = true end
    seat.kids = { weld, other }
    function weld:Destroy()
        self.gone = true
        table.remove(seat.kids, 1)
        if HUM.SeatPart == seat then HUM.SeatPart = nil end
    end
    function seat:GetChildren() return table.clone(self.kids) end    -- a copy, as Roblox gives
    return seat, weld
end
local function sitOn(seat) HUM.SeatPart, HUM.Sit, HUM.Jump = seat, true, false end
local function reset() P.running, P.handsOff, P.sea = true, false, nil P.seatsBack() HUM.SeatPart = nil end

reset()
P.seatGuard()
check("nobody seated: nothing happens, no jump", not HUM.Jump)

reset()
local cafe, weld = chair("Seat")
sitOn(cafe)
P.seatGuard()
check("a mode runs, caught by a chair: out of it the same frame",
    HUM.SeatPart == nil and HUM.Sit == false and weld.gone == true, HUM.SeatPart)
check("...by the way a player gets up (Space)", HUM.Jump == true)
check("...the chair switched off for you, so it cannot catch you again", cafe.CanTouch == false)
check("...and only the weld goes, the chair's other children stay", #cafe.kids == 1 and not cafe.lostOther)

reset()
local idle = chair("Seat")
sitOn(idle)
P.running = false
P.seatGuard()
check("no mode running (idle, PvP): you sit as long as you like",
    HUM.SeatPart == idle and HUM.Jump == false and idle.CanTouch == true)

reset()
local hands = chair("Seat")
sitOn(hands)
P.handsOff = true
P.seatGuard()
check("your turn inside a mode (a Mirage gear): still no chair - the mode carries on after",
    HUM.SeatPart == nil)

reset()
local wheel, wheelWeld = chair("VehicleSeat")
P.sea = { seat = wheel, driving = true }
sitOn(wheel)
P.seatGuard()
check("driving: your wheel is left alone", HUM.SeatPart == wheel and not wheelWeld.gone and wheel.CanTouch == true)

reset()
local wheel2 = chair("VehicleSeat")
P.sea = { seat = wheel2, boarding = wheel2 }
sitOn(wheel2)
P.seatGuard()
check("boarding (the hunt sits you there itself): left alone", HUM.SeatPart == wheel2 and wheel2.CanTouch == true)

reset()
local wheel3, hook = chair("VehicleSeat"), chair("Seat")
P.sea = { seat = wheel3, driving = true }
sitOn(hook)
P.seatGuard()
check("driving, but caught by the harpoon's seat: out of that one", HUM.SeatPart == nil)

reset()
local wheel4 = chair("VehicleSeat")
P.sea = { seat = wheel4, driving = false }
sitOn(wheel4)
P.seatGuard()
check("your wheel with no sea hunt at it (Circuit started on a boat): out, the farm can move", HUM.SeatPart == nil)

reset()
local a, b = chair("Seat"), chair("Seat")
sitOn(a) P.seatGuard()
sitOn(b) P.seatGuard()
P.seatOn(a)
check("one seat handed back before boarding it", a.CanTouch == true and b.CanTouch == false)
P.seatsBack()
check("Stop: every chair works again, you can sit", a.CanTouch == true and b.CanTouch == true)
b.CanTouch = false
P.seatsBack()
check("...and once given back it is not touched again", b.CanTouch == false)
b.CanTouch = true

print(all and "ALL PASS" or "SOME FAILED")
