-- The panel, built for real, then pressed. RUN = "census" (only fire every
-- control and print the CFG keys written - run on the OLD panel once to
-- freeze OLD_KEYS) or "full". OLD_KEYS is put in by panel_test.py.
local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass += 1 else fail += 1 print("FAIL  " .. msg) end
end

local built = P.panel()
check(built, "the panel builds  " .. table.concat(WARNED, " | "))
local gui = PG:FindFirstChild("BFFHUD")

-- ---------- finding things ----------
local VIEWS = {}
for _, o in ipairs(ALL) do
    if o.ClassName == "ScrollingFrame" and o.Name ~= "ScrollingFrame" then VIEWS[o.Name] = o end
end
local function each(o, f)
    for _, k in ipairs(rawget(o, "_kids")) do
        f(k)
        each(k, f)
    end
end
local function labelsOf(o)
    local t = {}
    each(o, function(k) if k.ClassName == "TextLabel" then table.insert(t, tostring(k.Text)) end end)
    return t
end
local function pageOf(o)
    local p = o
    while p do
        if p.ClassName == "ScrollingFrame" and VIEWS[p.Name] == p then return p.Name end
        p = p.Parent
    end
    return nil
end
local function current()
    flush()
    local vis = {}
    for name, v in pairs(VIEWS) do if v.Visible then table.insert(vis, name) end end
    table.sort(vis)
    return #vis == 1 and vis[1] or ("?" .. table.concat(vis, ","))
end
local function listeners(o, sig)
    local s = rawget(o, "_sig")[sig]
    return s and #s.fns > 0
end
local backBtn
for _, o in ipairs(ALL) do
    if o.ClassName == "TextButton" and o.Text == "Back" then backBtn = o end
end
local function goHome()
    for _ = 1, 12 do
        if current() == "home" then return end
        backBtn.Activated:Fire()
    end
end
local function isPill(o) return o.ClassName == "TextButton" and o.Size and o.Size.X.Offset == 46 end
-- A switch's label: the row (the pill's side frame's parent), its first text.
local function switchLabel(pill) return labelsOf(pill.Parent.Parent)[1] end
local function controlLabel(o)
    if isPill(o) then return "switch " .. (switchLabel(o) or "?") end
    local t = tostring(o.Text or "")
    if o.Parent and o.Parent.Parent and #t <= 2 and t ~= "" then       -- a key chip
        return "chip " .. t .. " of " .. (labelsOf(o.Parent.Parent)[1] or "?")
    end
    if t ~= "" then return t end
    return labelsOf(o)[1] or o.ClassName
end
-- A button on a page whose own labels include text (a nav row, a mode row,
-- a link) - or whose Text is it (an action, a radio row).
local function button(page, text)
    -- First a button whose own text or label IS it; then one that contains
    -- it (a picker row with a tag keeps its name in a label: "  > name").
    for pass = 1, 2 do
        local found
        each(VIEWS[page], function(k)
            if found or k.ClassName ~= "TextButton" or k._destroyed then return end
            local t = tostring(k.Text or "")
            if t == text or (t ~= "" and string.find(t, text, 1, true)) then found = k return end
            for _, l in ipairs(labelsOf(k)) do
                if l == text or (pass == 2 and string.find(l, text, 1, true)) then found = k return end
            end
        end)
        if found then return found end
    end
    return nil
end
-- Press a button by its text; a missing one is a failure, not a crash.
local function tap(page, text)
    local b = button(page, text)
    check(b ~= nil, "a \"" .. text .. "\" button on " .. page)
    if b then b.Activated:Fire() end
end
local function modePill(page)
    local found
    each(VIEWS[page], function(k)
        if not found and isPill(k) then found = k end
    end)
    return found
end
local function livePass()
    pcall(SPAWNED[#SPAWNED])
end
local function modeRowValue(label)
    local b = button("modes", label)
    if not b then return "<no row " .. label .. ">" end
    for _, k in ipairs(rawget(b, "_kids")) do
        if k.ClassName == "TextLabel" and k.Font == Enum.Font.GothamBold then return k.Text end
    end
    return "<no value>"
end
local function onRows()
    local on = {}
    for _, l in ipairs({ "Circuit farm", "Random", "Raid", "Elite pirates", "Fruits", "Haki berries",
        "Aura recipe", "Legendary swords", "Fire Flower", "Blaze Ember", "Sea travel", "Sea events",
        "Prehistoric", "Mirage", "Leviathan", "PvP" }) do
        if modeRowValue(l) == "On" then table.insert(on, l) end
    end
    return table.concat(on, ",")
end
local function showModes()
    goHome()
    button("home", "Mode").Activated:Fire()
    livePass()
end
local function called(s)
    for _, c in ipairs(CALLS) do if c == s then return true end end
    return false
end

if RUN == "full" then
    -- ---------- 28 pages ----------
    local EXPECT = { "home", "modes", "circuit", "random", "raid", "elite", "fruit", "berry",
        "recipe", "sword", "flower", "ember", "sail", "seaevents", "prehistoric", "mirage", "levi",
        "pvp", "volcano", "seafight", "attack", "weapon", "magnet", "position", "safety", "travel",
        "servers", "stats" }
    local n = 0
    for _ in pairs(VIEWS) do n += 1 end
    check(n == #EXPECT, "28 pages, got " .. n)
    for _, name in ipairs(EXPECT) do check(VIEWS[name] ~= nil, "page " .. name .. " exists") end
    check(current() == "home", "Home on screen at the start, got " .. current())

    -- ---------- Home fits without a scroll bar ----------
    local panelH
    for _, o in ipairs(ALL) do
        if o.ClassName == "Frame" and o.Parent == gui then panelH = o.Size.Y.Offset end
    end
    local h = 16
    for _, k in ipairs(rawget(VIEWS.home, "_kids")) do
        if k.Size and k.Size.Y then h += k.Size.Y.Offset end
    end
    check(panelH and h <= panelH - 82, string.format("Home %d px in a %d px body", h, (panelH or 0) - 82))

    -- ---------- one mode at a time; PvP / Leviathan on top ----------
    CFG_REAL.Hunt, CFG_REAL.RaidMode, CFG_REAL.RandomMode, CFG_REAL.Pvp, CFG_REAL.LeviFight =
        false, false, false, false, false
    P.running = false
    showModes()
    check(onRows() == "Circuit farm", "nothing on = the circuit is On: " .. onRows())

    modePill("raid").Activated:Fire()
    check(CFG_REAL.RaidMode == true, "raid switch -> RaidMode")
    showModes()
    check(onRows() == "Raid", "raid alone On: " .. onRows())

    goHome() button("modes", "Haki berries").Activated:Fire() livePass()
    check(string.find(labelsOf(VIEWS.berry)[1] .. table.concat(labelsOf(VIEWS.berry), "|"),
        "On turns Raid off", 1, true) ~= nil, "berry switch says it turns Raid off")
    modePill("berry").Activated:Fire()
    check(called("setHunt true berry") and CFG_REAL.RaidMode == false, "berry on: the hunt, raid off")
    showModes()
    check(onRows() == "Haki berries", "berry alone On: " .. onRows())

    goHome() button("modes", "PvP").Activated:Fire() livePass()
    check(string.find(table.concat(labelsOf(VIEWS.pvp), "|"), "Off brings Haki berries back", 1, true) ~= nil,
        "PvP switch says Off brings the berries back")
    modePill("pvp").Activated:Fire()
    check(CFG_REAL.Pvp == true and CFG_REAL.Hunt == true, "PvP on top: berry hunt kept underneath")
    showModes()
    check(onRows() == "PvP", "PvP alone On: " .. onRows())
    -- Home's big button is PvP's Stop now.
    table.clear(CALLS)
    goHome() livePass()
    check(string.find(tostring(button("home", "Stop").Text), "PvP", 1, true) ~= nil, "hero: Stop  ·  PvP")
    button("home", "Stop").Activated:Fire()
    check(called("pvpSet false") and not called("start"), "hero with PvP on = PvP off, no farm start")
    showModes()
    check(onRows() == "Haki berries", "PvP off: the berries again: " .. onRows())

    P.running = false
    table.clear(CALLS)
    modePill("levi").Activated:Fire()
    check(CFG_REAL.LeviFight == true and called("start") and P.running, "Leviathan on starts the run")
    showModes()
    check(onRows() == "Leviathan", "Leviathan alone On: " .. onRows())
    modePill("raid").Activated:Fire()
    check(CFG_REAL.LeviFight == false and CFG_REAL.Hunt == false and CFG_REAL.RaidMode == true,
        "raid on over the Leviathan: Leviathan off, berries off, raid on")
    showModes()
    check(onRows() == "Raid", "raid alone On: " .. onRows())

    modePill("circuit").Activated:Fire()
    check(CFG_REAL.RaidMode == false, "circuit on: raid off")
    modePill("circuit").Activated:Fire()
    showModes()
    check(onRows() == "Circuit farm", "the circuit has no off: still On: " .. onRows())

    -- ---------- the Mirage: one row, its page picks the job ----------
    table.clear(CALLS)
    button("mirage", "Advanced Fruit Dealer").Activated:Fire()
    check(CFG_REAL.MirageJob == "dealer" and #CALLS == 0, "job picked with the Mirage off: kept, no hunt")
    modePill("mirage").Activated:Fire()
    check(called("setHunt true dealer"), "Mirage on runs the picked job")
    showModes()
    check(onRows() == "Mirage", "Mirage alone On: " .. onRows())
    button("mirage", "Every chest on it").Activated:Fire()
    check(called("setHunt true mchest") and CFG_REAL.MirageJob == "mchest", "job changed while on: that job now")
    goHome() livePass()
    check(string.find(tostring(button("home", "·  Mirage").Text), "Mirage", 1, true) ~= nil,
        "hero names the mode: " .. tostring(button("home", "·  Mirage") and button("home", "·  Mirage").Text))
    modePill("mirage").Activated:Fire()
    check(CFG_REAL.Hunt == false, "Mirage off")

    -- ---------- Back walks where you came from ----------
    goHome()
    tap("home", "Mode")
    tap("modes", "Sea events")
    tap("seaevents", "Fighting at sea")
    check(current() == "seafight", "Sea events -> Fighting at sea")
    backBtn.Activated:Fire()
    check(current() == "seaevents", "Back -> Sea events, got " .. current())
    backBtn.Activated:Fire()
    check(current() == "modes", "Back -> Modes, got " .. current())
    backBtn.Activated:Fire()
    check(current() == "home", "Back -> Home, got " .. current())
    tap("levi", "Fighting at sea")
    backBtn.Activated:Fire()
    check(current() == "home", "a link from elsewhere, Back = where you were")

    -- Both on at once (a carried state, a console): PvP is what is happening
    -- - the farm, and so the Leviathan, is stopped while you fight.
    CFG_REAL.Pvp, CFG_REAL.LeviFight = true, true
    showModes()
    check(onRows() == "PvP", "PvP + Leviathan both set: PvP is the one On: " .. onRows())
    CFG_REAL.Pvp, CFG_REAL.LeviFight = false, false

    -- ---------- every mode page: its own switch first, folds last ----------
    local MODES = { circuit = "Circuit farm", random = "Random", raid = "Raid", elite = "Elite pirates",
        fruit = "Fruits", berry = "Haki berries", recipe = "Aura recipe", sword = "Legendary swords",
        flower = "Fire Flower", ember = "Blaze Ember", sail = "Sea travel", seaevents = "Sea events",
        prehistoric = "Prehistoric", mirage = "Mirage", levi = "Leviathan", pvp = "PvP",
        volcano = "Volcano event" }
    for page, title in pairs(MODES) do
        local p = modePill(page)
        check(p and switchLabel(p) == title, page .. ": first switch is the mode's own ("
            .. tostring(p and switchLabel(p)) .. ")")
    end
    for name, v in pairs(VIEWS) do
        local kids = {}
        for _, k in ipairs(rawget(v, "_kids")) do
            if k.LayoutOrder then table.insert(kids, k) end
        end
        table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        local seenFold, after = false, nil
        for _, k in ipairs(kids) do
            local ls = labelsOf(k)
            local isFold = (ls[1] == "How it works" or ls[1] == "Details") and (ls[2] == "Show" or ls[2] == "Hide")
            local isGap = k.ClassName == "Frame" and #rawget(k, "_kids") == 0
            if isFold then seenFold = true
            elseif seenFold and not isGap then after = ls[1] or k.ClassName end
        end
        check(after == nil, name .. ": nothing after How it works / Details (" .. tostring(after) .. ")")
    end
end

-- ---------- fire every control: which CFG keys, and from where ----------
goHome()
local EDGES = {}
local snapshot = {}
for _, o in ipairs(ALL) do table.insert(snapshot, o) end
table.clear(WRITES)
for _, o in ipairs(snapshot) do
    local page = pageOf(o)
    if page and not o._destroyed then
        local label = controlLabel(o)
        if label ~= "Stop and close the panel" then
            if listeners(o, "Activated") then
                goHome()
                CTRL = page .. ": " .. label
                o.Activated:Fire()
                local now = current()
                if now ~= "home" then
                    EDGES[page] = EDGES[page] or {}
                    EDGES[page][now] = true
                end
            end
            if listeners(o, "InputBegan") then
                CTRL = page .. ": " .. label
                o.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, Position = { X = 150 } })
            end
            if listeners(o, "FocusLost") then
                CTRL = page .. ": " .. label
                o.Text = "Reborn Skeleton"
                o.FocusLost:Fire(true)
            end
        end
    end
end

local keys = {}
for k in pairs(WRITES) do table.insert(keys, k) end
table.sort(keys)

if RUN == "census" then
    print("KEYS " .. table.concat(keys, "\n"))
    return
end

-- Every key the old panel could change, still changed by one.
local have = {}
for _, k in ipairs(keys) do have[k] = true end
for _, k in ipairs(OLD_KEYS) do
    check(have[k], "the new panel still changes CFG." .. k)
end
local old = {}
for _, k in ipairs(OLD_KEYS) do old[k] = true end
local NEW_OK = { MirageJob = true }
for _, k in ipairs(keys) do
    check(old[k] or NEW_OK[k], "a key the old panel never changed: CFG." .. k)
end

-- ... and from ONE page. The modes are the exception: each mode page's switch
-- turns the others off (that is the one-at-a-time rule), the bone pair keeps
-- min <= max.
local MANY = { Hunt = true, HuntKind = true, RaidMode = true, RandomMode = true, Pvp = true,
    LeviFight = true, MirageJob = true, BoneMin = true, BoneMax = true }
for _, k in ipairs(keys) do
    local pages = {}
    for ctrl in pairs(WRITES[k]) do pages[string.match(ctrl, "^(%w+):") or ctrl] = true end
    local list = {}
    for p in pairs(pages) do table.insert(list, p) end
    table.sort(list)
    check(MANY[k] or #list == 1, "CFG." .. k .. " is changed on one page, not " .. table.concat(list, ", "))
end

-- Every page reached from Home in 3 taps at most.
local depth = { home = 0 }
local queue = { "home" }
while #queue > 0 do
    local p = table.remove(queue, 1)
    for to in pairs(EDGES[p] or {}) do
        if depth[to] == nil then
            depth[to] = depth[p] + 1
            table.insert(queue, to)
        end
    end
end
for name in pairs(VIEWS) do
    check(depth[name] ~= nil and depth[name] <= 3,
        name .. " within 3 taps of Home (" .. tostring(depth[name]) .. ")")
end

print(string.format("%d passed, %d failed", pass, fail))
if fail == 0 then print("ALL PASS") end
