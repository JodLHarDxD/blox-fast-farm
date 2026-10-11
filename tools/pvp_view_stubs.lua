-- The world THE KEN VIEW block expects: S, CFG, player, parts().
local fails, count = 0, 0
local function check(name, cond)
    count += 1
    if not cond then
        fails += 1
        print("FAIL  " .. name)
    end
end

local S = { on = true, view = { note = "-", blocked = 0, ons = 0 } }
local CFG = { PvpVision = true }
local world = { kenActive = false, alive = true }
local player = {}
function player:GetAttribute(k)
    if k == "KenActive" then return world.kenActive end
    return nil
end
local function parts()
    if world.alive then return {}, {}, {} end
    return {}, nil, nil
end

-- The game's ObservationManager class, as far as the switch can tell: an
-- object whose methods live on the class (setmetatable, __index).
local OMClass = {}
OMClass.__index = OMClass
function OMClass.new()
    return setmetatable({ active = false, radius = 0, offs = 0, ons = 0 }, OMClass)
end
function OMClass:setActive(on)
    self.active = on and true or false
    if on then self.ons += 1 else self.offs += 1 end
end
