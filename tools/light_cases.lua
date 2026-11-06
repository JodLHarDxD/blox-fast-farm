
-- ---------------------------------------------------------------- cases
local all = true
local function check(name, cond, detail)

    io_print((cond and "PASS " or "FAIL ") .. name)
    if not cond then io_print("  " .. tostring(detail)) all = false end
end
local function has(what)
    local n = 0
    for _, c in ipairs(CALLS) do if c == what then n += 1 end end
    return n
end

reset()
P.lightRun()
check("music off through the game's own event", G.muted == true and has("music true") == 1,
    table.concat(CALLS, ","))
check("both shakers off, both times round (the Settings script sets them on at join)",
    has("CameraShake false") == 2 and has("CameraShaker false") == 2, table.concat(CALLS, ","))
check("fast mode on, as the game marks it", G.FastMode == true and G.reducing == true)
check("the game's Optimize message sent", ACTOR.sent[1] == "Optimize true", ACTOR.sent[1])
check("note and log line say what happened",
    P.light.note == "music off  ·  shake off  ·  fast mode on"
    and PRINTS[1] == "[BFF] light mode: " .. P.light.note, tostring(PRINTS[1]))

reset()
local grass, water, plain, offset = MAP[1], MAP[2], MAP[3], MAP[4]
P.lightRun()
check("map parts plastic, the old material kept for the game's Off button",
    grass.Material == Enum.Material.SmoothPlastic and G.FastModeCache[grass] == Enum.Material.Grass)
check("a water part stays water (partWater reads it)", water.Material == Enum.Material.Water)
check("textures go, one the game animates (Offset) stays",
    plain.destroyed == true and offset.destroyed == false)
check("the Unloaded folder too", UNLOADED[1].Material == Enum.Material.SmoothPlastic)

reset()
player.Team = nil
local before = nil
ON_WAIT = function(n)
    if n == 3 then before = #CALLS player.Team = { Name = "Marines" } end
end
P.lightRun()
check("nothing until you have a team, then all of it", before == 0 and G.FastMode == true,
    "calls before team: " .. tostring(before))

reset()
ON_WAIT = function() G.muted = false end   -- the Settings script ran late and reset it
P.lightRun()
check("music reset during the settle is turned off again", has("music true") == 2,
    table.concat(CALLS, ","))

reset()
G.muted = true
P.lightRun()
check("music already off: the event is not fired", has("music true") == 0)

reset()
G.FastMode, G.reducing = true, true
local g2 = MAP[1]
P.lightRun()
check("fast mode already on (your button): the map is not walked again",
    g2.Material == Enum.Material.Grass and #ACTOR.sent == 0)

reset()
CFG.LightMode = false
P.lightRun()
check("switched off: nothing touched, note says so",
    #CALLS == 0 and G.FastMode == nil and P.light.note == "off", P.light.note)

reset()
player.Team = nil
_G.BFF = nil
P.lightRun()
check("a replaced copy waiting for a team just ends", #CALLS == 0 and WAITS == 0, WAITS)

reset()
EVENTS.ToggleMusic = nil
UTIL.CameraShaker = nil
RS.Unloaded = nil
P.lightRun()
check("a piece the game no longer has is said, the rest still done",
    P.light.note == "music not found  ·  shake off  ·  fast mode on" and G.FastMode == true,
    P.light.note)

reset()
function EVENTS.ToggleMusic:Fire() table.insert(CALLS, "music true") end   -- nobody listens
P.lightRun()
check("the event did nothing: the note does not claim music is off",
    P.light.note == "music not confirmed  ·  shake off  ·  fast mode on", P.light.note)

reset()
RS.Util, RS.Events, RS.Global = nil, nil, nil
MAP = nil
local ok, e = pcall(P.lightRun)
check("nothing of the game there: no error, all said",
    ok and P.light.note == "music not found  ·  shake not found  ·  fast mode not found",
    tostring(e) .. " / " .. P.light.note)

reset()
for _ = 1, 40 do table.insert(MAP, part(Enum.Material.Grass)) end

P.lightRun()
check("a big map is walked in slices, not in one frame", WAITS > 2, WAITS)

-- The fruit's look keys under Fast Mode: the game's thumbnail form of a texture
-- ends in the size, and every fruit would then share one key.
local function mesh(tex)
    local m = { MeshId = "rbxassetid://15116730102", TextureID = tex, Name = "x" }
    function m:IsA(c) return c == "MeshPart" end
    return m
end
local function fruitWith(tex)
    local f = {}
    function f:FindFirstChild() return nil end
    function f:GetDescendants() return { mesh(tex) } end
    return f
end
local a = P.fruitLooks(fruitWith("rbxthumb://type=Asset&id=10395894563&w=150&h=150"))
local b = P.fruitLooks(fruitWith("rbxassetid://10395894563"))
check("a thumbnail texture gives the same key as the real one",
    table.concat(a, ",") == table.concat(b, ","), table.concat(a, ",") .. " / " .. table.concat(b, ","))

io_print(all and "ALL PASS" or "SOME FAILED")
