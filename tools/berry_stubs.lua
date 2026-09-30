
-- What grabBerry touches, faked. One bush, one berry, one prompt on it.
-- The game's server is modelled the way a server CAN check a prompt:
--   HOLD_OK  a real hold (InputHoldBegin, the prompt's HoldDuration,
--            InputHoldEnd) picks the berry
--   FIRE_OK  the executor's fireproximityprompt -- an INSTANT trigger by the
--            sUNC spec, no hold -- picks it
-- TAKEN_AT = someone else picks it at that clock. HAVE = your inventory.
local CLOCK = 0
local os = { clock = function() return CLOCK end, time = function() return 0 end }
local task = { wait = function(s) CLOCK += (s or 0.03) end }
local epoch = 0
local function stale(e) return e ~= epoch end
local E, HAVE, HOLD_OK, FIRE_OK, TAKEN_AT, HOLDS, FIRES, bush, prompt, PRINTED
local function say() end
local function setState() end
local function releasePile() end
local function flyTo() end
local function lockAt() end
local function notify() end
local print = function(s) table.insert(PRINTED, s) end

local V = {}
V.__index = V
V.__add = function(a, b) return setmetatable({ X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z }, V) end
local Vector3 = { new = function(x, y, z) return setmetatable({ X = x, Y = y, Z = z }, V) end }

-- Berry names from a bush's attributes: every string value.
local function berryNames(attrs)
    local out = {}
    for _, v in pairs(attrs or {}) do
        if type(v) == "string" then table.insert(out, v) end
    end
    table.sort(out)
    return out
end

local function berryCounts()
    local t = { read = true }
    for k, v in pairs(HAVE) do t[k] = v end
    return t
end

local function pick()
    if bush.attrs.Slot1 then
        HAVE[bush.attrs.Slot1] = (HAVE[bush.attrs.Slot1] or 0) + 1
        bush.attrs.Slot1 = nil
    end
end

local fireproximityprompt

local function reset(opts)
    opts = opts or {}
    CLOCK, epoch = 0, 0
    E = { berrySkip = {}, tally = {} }
    HAVE = { ["Pink Pig Berry"] = 3 }
    HOLD_OK, FIRE_OK, TAKEN_AT = opts.hold ~= false, opts.fire == true, opts.takenAt
    HOLDS, FIRES, PRINTED = 0, 0, {}
    bush = { attrs = { Slot1 = "Pink Pig Berry" } }
    function bush:GetAttributes()
        if TAKEN_AT and CLOCK >= TAKEN_AT then self.attrs.Slot1 = nil end
        return table.clone(self.attrs)
    end
    local part = { Position = Vector3.new(0, 0, 0) }
    function part:IsA(c) return c == "BasePart" end
    prompt = { HoldDuration = opts.holdDuration or 0.5, Parent = part }
    function prompt:IsA(c) return c == "ProximityPrompt" end
    function prompt:InputHoldBegin() self.began = CLOCK end
    function prompt:InputHoldEnd()
        HOLDS += 1
        if HOLD_OK and self.began and CLOCK - self.began >= self.HoldDuration then pick() end
        self.began = nil
    end
    function bush:GetDescendants() return opts.noPrompt and {} or { prompt } end
    fireproximityprompt = (opts.noFire ~= true) and function(pr)
        FIRES += 1
        if FIRE_OK then pick() end
    end or nil
end
reset()
