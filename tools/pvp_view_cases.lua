
local V = S.view

-- PvP on, the view on, then a hit ends Ken: the game asks for OFF.
local om = OMClass.new()
check("wrap takes", wrap(om) == true)
om:setActive(true)
check("the game's own ON goes through", om.active == true and om.ons == 1)
om:setActive(false)                                     -- DisableKen
check("the game's OFF is dropped: view stays on", om.active == true and om.offs == 0)
check("the dropped OFF is counted", V.blocked == 1)
om:setActive(not om.active)                             -- your E press (toggle)
check("E cannot turn the view off in PvP", om.active == true)
check("wrap twice on the same object = no change", wrap(om) == true and V.om == om)

-- A life that is over: its OFF must reach the object (it is being taken down).
world.alive = false
om:setActive(false)
check("dead: the OFF goes through", om.active == false and om.offs == 1)
world.alive = true
om.active = true
om._destroyed = true
om:setActive(false)
check("an object marked destroyed: the OFF goes through", om.active == false)
om._destroyed = nil

-- PvP switched off while wrapped (before the unwrap): OFF goes through.
om.active = true
S.on = false
om:setActive(false)
check("PvP off: the OFF goes through", om.active == false)
S.on = true

-- The vision switch off: OFF goes through.
om.active = true
CFG.PvpVision = false
om:setActive(false)
check("view switch off: the OFF goes through", om.active == false)
CFG.PvpVision = true

-- Unwrap with sync while the server's Ken is OFF: the view off, class method back.
om.active = true
world.kenActive = false
local offsBefore = om.offs
unwrap(true)
check("unwrap: the instance field is gone", rawget(om, "setActive") == nil)
check("unwrap: the class method is back", om.setActive == OMClass.setActive)
check("unwrap with Ken off: view put in step (off)", om.active == false and om.offs == offsBefore + 1)
check("unwrap clears the record", V.om == nil and V.orig == nil)

-- Unwrap with sync while Ken is ON: the view stays.
wrap(om)
om:setActive(true)
world.kenActive = true
unwrap(true)
check("unwrap with Ken on: the view stays", om.active == true)

-- A new life: wrap the new object; the old one gets no OFF (its OFF could
-- reach the screen look the new life shares).
local old = OMClass.new()
wrap(old)
old:setActive(true)
local oldOffs = old.offs
local new = OMClass.new()
world.kenActive = false
check("new life: the new object wrapped", wrap(new) == true and V.om == new)
check("new life: the old object got no OFF", old.offs == oldOffs)
check("new life: the old object's field given back", rawget(old, "setActive") == nil)

-- A frozen object cannot take the field: wrap says so.
unwrap(false)
local frozen = table.freeze(setmetatable({ active = true }, OMClass))
check("frozen object: wrap refuses", wrap(frozen) == false and V.om == nil)

-- An object with its own instance setActive: it is what comes back.
local own = OMClass.new()
local mine = function(self, on) self.active = on end
own.setActive = mine
wrap(own)
unwrap(false)
check("its own instance method is put back", rawget(own, "setActive") == mine)

print(string.format("%d checks, %d failed", count, fails))
if fails == 0 then print("ALL PASS (view)") end
