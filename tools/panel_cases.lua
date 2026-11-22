-- The panel, built for real, then pressed. RUN = "census" (only fire every
-- control and print the CFG keys written - run on the OLD panel once to
-- freeze OLD_KEYS) or "full". OLD_KEYS is put in by panel_test.py.
local pass, fail = 0, 0
local function check(cond, msg)
    if cond then pass += 1 else fail += 1 print("FAIL  " .. msg) end
end

local built = P.panel()
-- The defaults, as the real file keeps them (P.cfgDefaults is set outside the panel).
if not P.cfgDefaults then
    P.cfgDefaults = {}
    for k, v in pairs(CFG_REAL) do P.cfgDefaults[k] = v end
end
check(built, "the panel builds  " .. table.concat(WARNED, " | "))
local gui = PG:FindFirstChild("BFFHUD")
local LIVE0 = SPAWNED[#SPAWNED]       -- the panel's live loop: later spawns come after it

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
    -- Task S: the board's thin "‹", found by its Name
    if o.ClassName == "TextButton" and o.Name == "Back" then backBtn = o end
end
local function goHome()
    for _ = 1, 12 do
        if current() == "home" then return end
        backBtn.Activated:Fire()
    end
end
local function isPill(o) return o.ClassName == "TextButton" and o.Size and o.Size.X.Offset == 46 end
-- R2: a page's mode strip (P.kit.modeStrip) has a button in place of the pill;
-- Task S: the board's pill ("Use this" / "In use"), named ModePill, a 44 px target.
local function isStrip(o)
    return o.ClassName == "TextButton" and o.Name == "ModePill" and o.Size and o.Size.Y.Offset == 44
end
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
        if not found and (isPill(k) or isStrip(k)) then found = k end
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
        -- the bold word: LOOK.bold (Montserrat Bold through FontFace) or, on a
        -- client without the family, GothamBold
        local bold = k.Font == Enum.Font.GothamBold
            or (k.FontFace ~= nil and tostring(k.FontFace.Weight) == "Enum.FontWeight.Bold")
        if k.ClassName == "TextLabel" and bold then return k.Text end
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
    -- ---------- 40 pages (2026-11-08: Trades; 2026-11-22: six locked covers, Key & packs) ----------
    local EXPECT = { "home", "modes", "circuit", "random", "raid", "elite", "fruit", "fruitlog", "berry",
        "recipe", "sword", "flower", "ember", "halloween", "sail", "seaevents", "prehistoric", "mirage", "levi",
        "pvp", "volcano", "seafight", "attack", "weapon", "magnet", "position", "safety", "travel",
        "servers", "stats", "news", "fruitmenu", "trades",
        "cover_farm", "cover_raid", "cover_sea", "cover_prehistoric", "cover_pvp", "cover_fruits", "key" }
    local n = 0
    for _ in pairs(VIEWS) do n += 1 end
    check(n == #EXPECT, "40 pages, got " .. n)
    for _, name in ipairs(EXPECT) do check(VIEWS[name] ~= nil, "page " .. name .. " exists") end
    check(current() == "home", "Home on screen at the start, got " .. current())

    -- ---------- Home fits without a scroll bar ----------
    local panelH, headH
    for _, o in ipairs(ALL) do
        if o.ClassName == "Frame" and o.Parent == gui then panelH = o.Size.Y.Offset end
    end
    -- the header: 48 (Task S), plus the news strip's 34 while it shows
    headH = VIEWS.home.Parent.Position.Y.Offset
    local h = 16
    for _, k in ipairs(rawget(VIEWS.home, "_kids")) do
        if k.Size and k.Size.Y then h += k.Size.Y.Offset end
    end
    check(panelH and h <= panelH - headH, string.format("Home %d px in a %d px body", h, (panelH or 0) - headH))

    -- ---------- one mode at a time; PvP / Leviathan on top ----------
    CFG_REAL.Hunt, CFG_REAL.RaidMode, CFG_REAL.RandomMode, CFG_REAL.Pvp, CFG_REAL.LeviFight =
        false, false, false, false, false
    P.running = false
    showModes()
    check(onRows() == "", "nothing on = no mode (the circuit Off by default, 2026-10-12): " .. onRows())

    modePill("raid").Activated:Fire()
    check(CFG_REAL.RaidMode == true, "raid switch -> RaidMode")
    showModes()
    check(onRows() == "Raid", "raid alone On: " .. onRows())

    goHome() button("modes", "Haki berries").Activated:Fire() livePass()
    check(string.find(labelsOf(VIEWS.berry)[1] .. table.concat(labelsOf(VIEWS.berry), "|"),
        "Raid is your mode now", 1, true) ~= nil, "berry strip says Raid is your mode now")
    modePill("berry").Activated:Fire()
    check(called("setHunt true berry") and CFG_REAL.RaidMode == false, "berry on: the hunt, raid off")
    showModes()
    check(onRows() == "Haki berries", "berry alone On: " .. onRows())

    goHome() button("modes", "PvP").Activated:Fire() livePass()
    -- R2: the page's mode strip replaced the switch and its sentence; the behaviour
    -- (Off brings the berries back) is checked below.
    check(modePill("pvp") ~= nil and isStrip(modePill("pvp")), "PvP page: a mode strip")
    modePill("pvp").Activated:Fire()
    check(CFG_REAL.Pvp == true and CFG_REAL.Hunt == true, "PvP on top: berry hunt kept underneath")
    livePass()
    do
        local words = table.concat(labelsOf(VIEWS.pvp), "|")
        check(string.find(words, "Off: Haki berries is yours again; Start runs it", 1, true) ~= nil
            and string.find(words, "brings", 1, true) == nil,
            "PvP strip, on: Off makes the mode under it yours again, Start runs it (not 'brings back')")
    end
    showModes()
    check(onRows() == "PvP", "PvP alone On: " .. onRows())
    -- Home's big button is PvP's Stop now.
    table.clear(CALLS)
    goHome() livePass()
    check(string.find(tostring(button("home", "Stop").Text), "PvP", 1, true) ~= nil, "hero: Stop · PvP")
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
    check(CFG_REAL.RaidMode == false and CFG_REAL.Circuit == true, "circuit on: raid off")
    showModes()
    check(onRows() == "Circuit farm", "circuit alone On: " .. onRows())
    modePill("raid").Activated:Fire()
    check(CFG_REAL.Circuit == false and CFG_REAL.RaidMode == true, "raid on: the circuit off (one at a time)")
    modePill("raid").Activated:Fire()
    showModes()
    check(onRows() == "", "raid off: no mode - not the circuit back: " .. onRows())
    modePill("circuit").Activated:Fire()
    modePill("circuit").Activated:Fire()
    showModes()
    check(CFG_REAL.Circuit == false and onRows() == "", "the circuit has an Off (2026-10-12): nothing On: " .. onRows())
    table.clear(CALLS)
    P.running = false
    goHome() livePass()
    check(string.find(tostring(button("home", "Start").Text), "No mode", 1, true) ~= nil,
        "hero with no mode: Start · No mode")

    -- ---------- R2 Task 3: Attack - the FIGHT WITH wheel ----------
    do
        local function openAttack()
            goHome()
            button("home", "Attack").Activated:Fire()
            livePass()
        end
        local function pillNamed(text)
            local found
            each(VIEWS.attack, function(k)
                if not found and k.ClassName == "TextButton" and k.Text == text and not k._destroyed then found = k end
            end)
            return found
        end
        local function texts()
            return table.concat(labelsOf(VIEWS.attack), "|")
        end
        check(type(P.modeNow) == "function", "P.modeNow is exposed for the farm")
        check(type(P.fightWithText) == "function", "P.fightWithText exists")
        CFG_REAL.Hunt, CFG_REAL.RaidMode, CFG_REAL.RandomMode, CFG_REAL.Pvp, CFG_REAL.LeviFight, CFG_REAL.Circuit =
            false, false, false, false, false, false
        CFG_REAL.RandomMode = true
        table.clear(CFG_REAL.FightWith)
        table.clear(CFG_REAL.FightGoal)
        check(P.modeNow() == "random", "P.modeNow names the mode running: " .. tostring(P.modeNow()))
        check(P.fightWithText("random") == "Mix", "default: Fights with = Mix: " .. P.fightWithText("random"))
        openAttack()
        check(current() == "attack", "Home > Attack opens the page")
        check(pillNamed("For Random") ~= nil, "a tab for the mode you are in (For Random)")
        check(pillNamed("For Sea events") ~= nil, "a tab for Sea events (the key owns it)")
        check(pillNamed("MIX") ~= nil and pillNamed("Godhuman") ~= nil and pillNamed("Hallow Scythe") ~= nil,
            "the wheel: MIX and the weapons you carry")
        check(string.find(texts(), "Mixing", 1, true) ~= nil, "MIX: the truth card says Mixing: " .. texts())

        -- a pick is per mode, and writes only FightWith
        pillNamed("Godhuman").Activated:Fire()
        check(CFG_REAL.FightWith.random == "Godhuman", "wheel: random fights with Godhuman")
        check(CFG_REAL.FightWith.seaevents == nil, "wheel: another mode keeps its own pick (still MIX)")
        check(P.fightWithText("random") == "Godhuman only", "Fights with: Godhuman only: " .. P.fightWithText("random"))
        check(P.fightWithText("seaevents") == "Mix", "Fights with: the other mode is Mix")
        livePass()
        check(string.find(texts(), "Everything uses Godhuman", 1, true) ~= nil, "the truth card: Everything uses Godhuman")
        goHome() livePass()
        check(string.find(table.concat(labelsOf(VIEWS.home), "|"), "Godhuman only", 1, true) ~= nil,
            "Home's Attack row says Godhuman only")
        openAttack()

        -- the sea tab keeps its own pick
        pillNamed("For Sea events").Activated:Fire()
        livePass()
        pillNamed("Hallow Scythe").Activated:Fire()
        check(CFG_REAL.FightWith.seaevents == "Hallow Scythe" and CFG_REAL.FightWith.random == "Godhuman",
            "Sea events tab: its own pick, Random's kept")
        pillNamed("For Random").Activated:Fire()
        livePass()

        -- mastery goal (visible with a single weapon)
        local goalBtn
        each(VIEWS.attack, function(k)
            if not goalBtn and k.ClassName == "TextButton" and not k._destroyed and k.Visible ~= false then
                for _, l in ipairs(labelsOf(k)) do
                    if string.find(l, "Mastery goal", 1, true) then goalBtn = k end
                end
            end
        end)
        check(goalBtn ~= nil, "the truth card has a mastery goal switch with a single weapon")
        if goalBtn then
            goalBtn.Activated:Fire()
            check(CFG_REAL.FightGoal.random == true, "goal on: FightGoal.random")
            goalBtn.Activated:Fire()
            check(CFG_REAL.FightGoal.random == nil, "goal off again")
        end

        -- the cards: Use only this, the M1 chip
        pillNamed("Using only this").Activated:Fire()
        check(CFG_REAL.FightWith.random == nil, "the chosen card's button puts the wheel back to MIX")
        livePass()
        pillNamed("Use only this").Activated:Fire()
        check(CFG_REAL.FightWith.random == "Godhuman", "a card's Use only this sets the wheel")
        local m1Chip = pillNamed("M1")
        check(m1Chip ~= nil, "a card has an M1 chip")
        CFG_REAL.M1Weapon = ""
        if m1Chip then m1Chip.Activated:Fire() end
        check(CFG_REAL.M1Weapon ~= "", "the M1 chip writes the M1 pick: " .. tostring(CFG_REAL.M1Weapon))
        CFG_REAL.M1Weapon = ""

        -- PACE: step 3 is today's, step 1 is M1 first and slower
        local pace1, pace3
        each(VIEWS.attack, function(k)
            if k.ClassName == "TextButton" and not k._destroyed then
                if k.Text == "1" and not pace1 then pace1 = k end
                if k.Text == "3" and not pace3 then pace3 = k end
            end
        end)
        check(pace1 ~= nil and pace3 ~= nil, "PACE is a 1-5 dial")
        if pace1 and pace3 then
            pace1.Activated:Fire()
            check(CFG_REAL.StartWith == "M1" and CFG_REAL.M1Between == 8 and CFG_REAL.CastWait == 0.8,
                "PACE 1 writes M1 first, 8, 0.80")
            pace3.Activated:Fire()
            check(CFG_REAL.StartWith == P.cfgDefaults.StartWith and CFG_REAL.M1Between == P.cfgDefaults.M1Between
                and CFG_REAL.CastWait == P.cfgDefaults.CastWait, "PACE 3 is today's defaults")
            CFG_REAL.CastWait = 0.51
            livePass()
            check(string.find(texts(), "your own values", 1, true) ~= nil, "an edited value lights no step: your own values")
            pace3.Activated:Fire()
        end

        -- Race: one switch for V4 and V3
        local raceOn = CFG_REAL.RaceV4 and CFG_REAL.RaceV3
        local racePill
        each(VIEWS.attack, function(k)
            if not racePill and isPill(k) and switchLabel(k) == "Race" then racePill = k end
        end)
        check(racePill ~= nil, "a Race switch")
        if racePill then
            racePill.Activated:Fire()
            check(CFG_REAL.RaceV4 == not raceOn and CFG_REAL.RaceV3 == not raceOn, "Race switches V4 and V3 together")
            racePill.Activated:Fire()
            check(CFG_REAL.RaceV4 == raceOn and CFG_REAL.RaceV3 == raceOn, "Race back")
        end
        check(string.find(texts(), "Fine-tune", 1, true) ~= nil, "a Fine-tune button")
        check(string.find(texts(), "Aim", 1, true) ~= nil, "an Aim row")
        table.clear(CFG_REAL.FightWith)
        table.clear(CFG_REAL.FightGoal)
        CFG_REAL.RandomMode = false
        goHome()
    end

    -- ---------- the fruit menu: Take, Skip, a second tap takes it off ----------
    table.clear(CFG_REAL.FruitMenu)
    tap("fruitmenu", "Take")
    check(CFG_REAL.FruitMenu.Dragon == "take", "Take marks the fruit take: " .. tostring(CFG_REAL.FruitMenu.Dragon))
    tap("fruitmenu", "Skip")
    check(CFG_REAL.FruitMenu.Dragon == "skip", "Skip over Take: one mark, the last")
    tap("fruitmenu", "Skip")
    check(CFG_REAL.FruitMenu.Dragon == nil, "a second tap takes the mark off")

    -- ---------- the Mirage: one row, its page picks the job ----------
    table.clear(CALLS)
    button("mirage", "Advanced Fruit Dealer").Activated:Fire()
    check(CFG_REAL.MirageJob == "dealer" and #CALLS == 0, "job picked with the Mirage off: kept, no hunt")
    modePill("mirage").Activated:Fire()
    check(called("setHunt true dealer"), "Mirage on runs the picked job")
    showModes()
    check(onRows() == "Mirage", "Mirage alone On: " .. onRows())
    button("mirage", "Every chest").Activated:Fire()
    check(called("setHunt true mchest") and CFG_REAL.MirageJob == "mchest", "job changed while on: that job now")
    goHome() livePass()
    check(string.find(tostring(button("home", "· Mirage").Text), "Mirage", 1, true) ~= nil,
        "hero names the mode: " .. tostring(button("home", "· Mirage") and button("home", "· Mirage").Text))
    modePill("mirage").Activated:Fire()
    check(CFG_REAL.Hunt == false, "Mirage off")

    -- ---------- Back walks where you came from ----------
    goHome()
    tap("home", "Mode")
    tap("modes", "Sea events")
    tap("seaevents", "Dodging & heights")
    check(current() == "seafight", "Sea events -> Sea fight")
    backBtn.Activated:Fire()
    check(current() == "seaevents", "Back -> Sea events, got " .. current())
    backBtn.Activated:Fire()
    check(current() == "modes", "Back -> Modes, got " .. current())
    backBtn.Activated:Fire()
    check(current() == "home", "Back -> Home, got " .. current())
    tap("levi", "Dodging & form")
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
        -- A page on the R2 kit has its mode strip first (its button, not a pill).
        local ok = p and (isStrip(p) or switchLabel(p) == title)
        check(ok, page .. ": first switch is the mode's own ("
            .. tostring(p and (isStrip(p) and "strip" or switchLabel(p))) .. ")")
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
            elseif seenFold and not isGap and ls[1] ~= "Fine-tune" and not string.find(tostring(ls[1]), "^Lab") then
                -- (R2 boards: Details, then the Lab fold, then Fine-tune, in that order)
                after = ls[1] or k.ClassName
            end
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
local NEW_OK = { MirageJob = true,
    -- 2026-10-12: dodging per attacker (a Sea Beast / a Terrorshark its own circle).
    BeastDodgeSpeed = true, BeastDodgeMin = true, BeastDodgeMax = true,
    SharkDodgeSpeed = true, SharkDodgeMin = true, SharkDodgeMax = true,
    FruitUnknownSpawn = true,   -- 2026-10-12: the game's own spawns seen
    FruitStore = true, FruitStoreOnHop = true,    -- 2026-10-12: picked fruits kept in the backpack
    -- 2026-10-12: race V4 / V3 by themselves, every weapon while V4 (Attack page).
    RaceV4 = true, RaceAll = true, RaceM1Burst = true, RaceV3 = true, RaceV3Wait = true, RaceV3Every = true,
    Circuit = true,   -- 2026-10-12: the circuit has its own Off (no mode)
    PvpCatchPx = true, PvpMark = true,    -- 2026-10-12 build .8: the player nearest your mouse, highlighted
    PvpLeadScale = true, PvpStream = true,    -- 2026-10-13: where he will be, your aim kept up during a move
    PvpNoSpread = true,                       -- 2026-10-13 build .2: Dragonstorm's shots straight
    PvpAimKeys = true,                        -- 2026-10-14: which attacks the aim takes (Z yours)
    PvpSoruCut = true, PvpCdTest = true,      -- 2026-10-15: cooldown tests (Flash Step cut, skills)
    PvpFar = true, PvpFarTo = true,           -- 2026-10-23: see far, past the Pale Scarf
    PvpDashAnim = true, PvpLegs = true,       -- 2026-10-23: the dash animation sped, legs at a normal pace
    PvpHopBusy = true,                        -- 2026-10-23: PvP hops go to the busiest servers
    PvpPingMax = true,                        -- 2026-10-24: ...in regions fast for you
    PvpLeadAuto = true,                       -- 2026-10-24: the lead learned per move
    FruitPortals = true,                      -- 2026-10-24: the fruit hunt through the game's portals
    FruitKeepValue = true,                    -- 2026-10-25: a fruit too good to lose, held safe
    TravelHome = true,                        -- 2026-10-25: the Home button on a long trip (ROUTES)
    TravelRoutes = true,                      -- 2026-10-31: every long trip routed (Travel & boat)
    TravelFar = true,                         -- 2026-11-13: a door asked from where you stand (Travel & boat)
    FruitSkipFull = true,                     -- 2026-11-13: a fruit your storage is full of is left (Fruits)
    ChaliceGuard = true,                      -- 2026-11-13: the God's Chalice stops every hop (Servers & team)
    HalloweenRareOnly = true,                 -- 2026-11-13: only the rare (seed) pumpkin (Halloween)
    HalloweenTalk = true,                     -- 2026-11-13: a door's conversation finished (Halloween)
    HalloweenChase = true,                    -- 2026-11-14: the ghost chased (Halloween)
    HalloweenCandy = true,                    -- 2026-11-14: candy on the floor walked through (Halloween)
    HalloweenPumpkins = true, HalloweenRareFirst = true,  -- 2026-10-31: the Halloween hunt's page
    HalloweenDoors = true, HalloweenBoss = true,
    HalloweenReturn = true, HalloweenTour = true,
    HalloweenWatch = true,                    -- 2026-10-31: record what you smash by hand
    LightMode = true,                         -- 2026-11-07: Fast Mode on, shake and music off, every server
    Quests = true,                            -- 2026-11-07: quests by your level, on the Circuit page
    -- 2026-11-07: which news the strip shows, one tick each.
    ["NewsShow.fruit"] = true, ["NewsShow.moon"] = true, ["NewsShow.mirage"] = true,
    ["NewsShow.prehistoric"] = true, ["NewsShow.kitsune"] = true, ["NewsShow.frozen"] = true,
    ["NewsShow.elite"] = true, ["NewsShow.raid"] = true, ["NewsShow.server"] = true,
    ["NewsShow.trades"] = true }                -- 2026-11-08: your trades, left and back at
for _, k in ipairs(keys) do
    -- 2026-11-07: the fruit menu, a mark per fruit.
    -- 2026-11-22: FIGHT WITH, one wheel per mode, and its mastery goal (Attack).
    check(old[k] or NEW_OK[k] or string.match(k, "^FruitMenu%.") or string.match(k, "^FightWith%.")
        or string.match(k, "^FightGoal%."), "a key the old panel never changed: CFG." .. k)
end

-- The fruit menu: every fruit on it can be marked.
for n in pairs(P.TRADE_VALUES) do
    check(have["FruitMenu." .. n], "the fruit menu has a row for " .. n)
end

-- Every news topic has its tick.
for k in pairs(CFG_REAL.NewsShow) do
    check(have["NewsShow." .. k], "the news topic " .. k .. " has a tick")
end

-- ... and from ONE page. The modes are the exception: each mode page's switch
-- turns the others off (that is the one-at-a-time rule), the bone pair keeps
-- min <= max.
local MANY = { Hunt = true, HuntKind = true, RaidMode = true, RandomMode = true, Pvp = true,
    LeviFight = true, MirageJob = true, BoneMin = true, BoneMax = true, Circuit = true,
    -- 2026-11-22: a weapon's moves are lit on its Attack card AND on its own page.
    ["Weapons.*.M1"] = true, ["Weapons.*.Z"] = true, ["Weapons.*.X"] = true, ["Weapons.*.C"] = true,
    ["Weapons.*.V"] = true, ["Weapons.*.F"] = true, ["Weapons.*.use"] = true }
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
-- R2: every mode this key holds is a row of the Library's MAIN JOB (or its
-- owner tools): Home > Mode > the mode = 2 taps. A cover is 2 as well (Home >
-- Mode > the cover is 2 taps from the Library), Key & packs is 1.
for _, id in ipairs({ "circuit", "random", "raid", "elite", "sword", "sail", "seaevents", "prehistoric",
    "mirage", "levi", "pvp", "fruit", "volcano", "berry", "recipe", "flower", "ember", "halloween" }) do
    check(depth[id] ~= nil and depth[id] <= 2, id .. " within 2 taps of Home (" .. tostring(depth[id]) .. ")")
end
check(depth.key == 1, "Key & packs is one tap from Home")
for _, f in ipairs({ "farm", "raid", "sea", "prehistoric", "pvp", "fruits" }) do
    check(depth["cover_" .. f] == 2, "cover_" .. f .. " is Home > Mode > the cover (" .. tostring(depth["cover_" .. f]) .. ")")
end

-- ---------- R2 kit: every component builds on a scratch view; every dial's today step is today's CFG ----------
do
    local K = P.kit
    check(K ~= nil, "P.kit exists")
    for _, n in ipairs({ "packChip", "modeStrip", "fightsWith", "dial", "segmented", "truthCard", "fineTune", "wheel" }) do
        check(K and type(K[n]) == "function", "P.kit." .. n .. " is a function")
    end
    if K then
        local scratch = Instance.new("Frame")
        scratch.Name = "scratch"
        scratch.Parent = gui
        local nDials = #P.dials
        local keyName = "RandomRadius"
        local today = P.cfgDefaults[keyName]
        local mine = {
            { name = "1  CLOSE", set = { [keyName] = 300 }, line = "Reaches 300 studs" },
            { name = "3  BALANCED", set = { [keyName] = today }, line = "today", today = true },
        }
        local ok, err = pcall(function()
            K.packChip(scratch, "farm")
            K.modeStrip(scratch, "random")
            K.modeStrip(scratch, "volcano")
            K.fightsWith(scratch, "random")
            K.dial(scratch, "Pace", mine, "farm")
            K.segmented(scratch, "By", { { true, "My level" }, { false, "My list" } },
                function() return true end, function() end)
            K.truthCard(scratch, function() return "Title" end, function() return "Reason" end, "sea")
            K.fineTune(scratch, function(box) K.packChip(box, "pvp") end, 3)
            local picked = "MIX"
            K.wheel(scratch, { { id = "MIX", label = "MIX" }, { id = "Tiger", label = "Tiger" },
                { id = "CDK", label = "CDK" } }, function() return picked end, function(v) picked = v end)
            flush()
        end)
        check(ok, "every kit component builds on a scratch view  " .. tostring(err))
        -- Pressing the scratch dial's step 1 writes its values, and Fine-tune opens.
        local before = CFG[keyName]
        local b1
        each(scratch, function(k) if not b1 and k.ClassName == "TextButton" and k.Text == "1" then b1 = k end end)
        check(b1 ~= nil, "the scratch dial has a button 1")
        if b1 then
            b1.Activated:Fire()
            check(CFG[keyName] == 300, "a dial tap writes its step's values")
            CFG[keyName] = before
        end
        -- The automatic check: every registered dial's today step equals today's defaults.
        check(#P.dials == nDials + 1, "a dial registers its steps in P.dials")
        for i, steps in ipairs(P.dials) do
            local t = dialToday(steps)
            check(t ~= nil, "dial " .. i .. " has a today step")
            if t then
                for k, v in pairs(steps[t].set) do
                    check(P.cfgDefaults[k] == v, "dial " .. i .. " today step sets CFG." .. k .. " to its default")
                end
            end
        end
        table.remove(P.dials, nDials + 1)   -- the scratch dial leaves with the scratch view
        scratch:Destroy()
    end
end

-- ---------- R2: Home, the Library, the covers, Key & packs - by key kind ----------
-- The panel is built again under each key; a page's rows are read from the
-- fresh gui (views are built once per build, from what the key holds).
do
    local CLIP = nil
    setclipboard = function(s) CLIP = s end
    local function walk(o, f)
        for _, k in ipairs(rawget(o, "_kids")) do f(k) walk(k, f) end
    end
    local function labelsIn(o)
        local t = {}
        walk(o, function(c) if c.ClassName == "TextLabel" then table.insert(t, tostring(c.Text)) end end)
        return t
    end
    local function build(ent, kind, store)
        _G.BFF_ENT, _G.BFF_KIND, _G.BFF_STORE, _G.BFF_KEY = ent, kind, store, "BFF-CC4V-AAAA-BBBB-CCCC-NQ0H"
        P.hudExtra = 0
        check(P.panel(), "the panel builds again (" .. tostring(kind) .. ")")
        local g = PG:FindFirstChild("BFFHUD")
        local V = {}
        walk(g, function(o)
            if o.ClassName == "ScrollingFrame" and o.Name ~= "ScrollingFrame" then V[o.Name] = o end
        end)
        local back
        walk(g, function(o) if o.ClassName == "TextButton" and o.Name == "Back" then back = o end end)
        local I = { V = V, g = g }
        function I.has(page, needle)
            for _, l in ipairs(labelsIn(V[page])) do if string.find(l, needle, 1, true) then return true end end
            return false
        end
        function I.cur()
            flush()
            local vis = {}
            for n, v in pairs(V) do if v.Visible then table.insert(vis, n) end end
            return #vis == 1 and vis[1] or ("?" .. table.concat(vis, ","))
        end
        function I.btn(page, text)
            local found
            walk(V[page], function(k)
                if found or k.ClassName ~= "TextButton" then return end
                if tostring(k.Text) == text then found = k return end
                for _, l in ipairs(labelsIn(k)) do if l == text then found = k return end end
            end)
            return found
        end
        function I.find(page, pred)
            local out
            walk(V[page], function(k) if not out and pred(k) then out = k end end)
            return out
        end
        function I.tap(page, text)
            local b = I.btn(page, text)
            check(b ~= nil, "[" .. tostring(kind) .. "] a \"" .. text .. "\" button on " .. page)
            if b then b.Activated:Fire() end
            flush()
        end
        function I.home() for _ = 1, 8 do if I.cur() == "home" then return end back.Activated:Fire() end end
        function I.live() flush() pcall(SPAWNED[#SPAWNED]) end
        return I
    end
    local NOW = os.time()

    -- A buyer with GRIND only.
    local B = build({ farm = NOW + 5 * 86400 + 60 }, "buyer", "https://store.example/x")
    B.tap("home", "Mode")
    B.live()
    check(B.has("modes", "5 days left on your key") and B.has("modes", "GRIND"), "buyer: the Library's key strip says GRIND, 5 days left")
    check(B.btn("modes", "Circuit farm") and B.btn("modes", "Random"), "buyer: GRIND's modes are rows of MAIN JOB")
    check(not B.btn("modes", "Raid") and not B.btn("modes", "Mirage") and not B.btn("modes", "PvP"),
        "buyer: a locked pack's modes are not rows")
    check(not B.btn("modes", "Haki berries") and not B.btn("modes", "Halloween"), "buyer: no owner tools")
    check(B.has("modes", "LIBRARY · 5 MORE PACKS") and B.has("modes", "tap a cover"), "buyer: LIBRARY · 5 MORE PACKS (4 covers and Fruits)")
    check(B.has("modes", "EVERYTHING") and B.has("modes", "BEST VALUE"), "buyer: the EVERYTHING card shows")
    check(B.has("modes", "Diablo, Deandre, Urban, the sword dealer, raids"), "buyer: a cover carries its line")
    local function coverText(line)
        local b = B.btn("modes", line)
        return b and table.concat(labelsIn(b), "|")
    end
    local rc, gc = coverText("Diablo, Deandre, Urban, the sword dealer, raids"),
        coverText("Circuit farm and Random: your level or your list")
    check(rc and string.find(rc, "$0.99", 1, true), "buyer: BOSSES + RAIDS cover shows its price: " .. tostring(rc))
    check(gc and string.find(gc, ">on<", 1, true) and not string.find(gc, "$0.99", 1, true), "buyer: the GRIND cover says on, no price: " .. tostring(gc))
    -- a locked cover's tap opens cover_<pack>; the plate has the price, copy and a code
    B.tap("modes", "BOSSES + RAIDS")
    check(B.cur() == "cover_raid", "buyer: the locked cover opens cover_raid, got " .. B.cur())
    check(B.has("cover_raid", "Not on your key yet") and B.has("cover_raid", "$0.99") and B.has("cover_raid", "INSIDE"),
        "buyer: cover page has the plate and INSIDE")
    check(B.has("cover_raid", "Elite pirates") and B.has("cover_raid", "Legendary swords") and not B.btn("cover_raid", "Raid"),
        "buyer: INSIDE lists the modes, not tappable")
    B.tap("cover_raid", "Get Bosses + Raids · copy store link")
    check(CLIP == "https://store.example/x", "buyer: Get ... copies the store link")
    check(B.btn("cover_raid", "Link copied: paste it in your browser") ~= nil, "buyer: the button says the link is copied")
    B.tap("cover_raid", "I have a code")
    check(B.cur() == "key", "buyer: I have a code opens Key & packs")
    -- the motion: one live step puts word 1 in; it ticks only while the page is visible
    B.home() B.tap("home", "Mode") B.tap("modes", "SEA")
    check(B.cur() == "cover_sea", "buyer: SEA cover opens, got " .. B.cur())
    B.live()
    local w1 = B.find("cover_sea", function(k) return k.ClassName == "TextLabel" and k.Text == "SEA BEASTS." end)
    check(w1 and w1.TextTransparency == 0, "SEA cover: the first word is in after a live step")
    local w4 = B.find("cover_sea", function(k) return k.ClassName == "TextLabel" and k.Text == "FROM YOUR BOAT." end)
    check(w4 and w4.TextTransparency == 1, "SEA cover: the fourth word waits")
    w1.TextTransparency = 0.5
    B.home()
    flush()
    B.live()
    check(w1.TextTransparency == 0.5, "SEA cover: nothing ticks while the page is not on screen")
    -- FRUITS: coming soon
    B.tap("home", "Mode") B.tap("modes", "FRUITS")
    check(B.cur() == "cover_fruits" and B.btn("cover_fruits", "Coming soon") and B.has("cover_fruits", "$14.99")
        and B.has("cover_fruits", "Fruit notifier"), "FRUITS cover: coming soon, $14.99, what it does")
    B.tap("cover_fruits", "Coming soon")
    check(string.find(SAID[#SAID] or "", "not for sale yet", 1, true) ~= nil, "FRUITS: the plate says it is not for sale yet")
    B.tap("cover_fruits", "Back to the Library")
    check(B.cur() == "modes", "FRUITS: Back to the Library, got " .. B.cur())
    -- Key & packs
    B.home() B.tap("home", "Key & packs")
    check(B.cur() == "key", "Key & packs opens from Home")
    check(B.has("key", "BFF-CC4V-····-····-····-NQ0H"), "Key: the key with its middle hidden")
    check(not B.has("key", "AAAA") and not B.has("key", "BBBB"), "Key: the middle groups are not shown")
    B.live()
    check(B.has("key", "Grind") and B.has("key", "Sea") and B.has("key", "$1.49 / wk") and B.has("key", "Everything"),
        "Key: every pack and the price of the locked ones")
    check(B.has("key", "5 days left"), "Key: GRIND says 5 days left")
    B.home() B.live()
    local keyRow = B.btn("home", "Key & packs")
    local kv
    for _, k in ipairs(rawget(keyRow, "_kids")) do
        if k.ClassName == "TextLabel" and k.Text ~= "›" and k.Text ~= "Key & packs" then kv = k.Text end
    end
    check(kv == "Grind · 5d left", "Home Key row: Grind · 5d left (" .. tostring(kv) .. ")")
    B.tap("home", "Key & packs")
    -- Redeem: a tap with a code runs P.redeem; the answer shows
    local nCalls = 0
    local realRedeem = P.redeem
    P.redeem = function(c) nCalls += 1 P.redeemNote = "that code is used" end
    local tb = B.find("key", function(k) return k.ClassName == "TextBox" end)
    tb.Text = "BFV-AAAA"
    B.tap("key", "Redeem")
    check(nCalls == 1, "Key: Redeem runs P.redeem with the code")
    tb.Text = ""
    B.tap("key", "Redeem")
    check(nCalls == 1, "Key: Redeem with nothing typed does nothing")
    B.live()
    check(B.has("key", "that code is used"), "Key: the answer shows")
    P.redeem = realRedeem
    P.redeemNote = nil
    -- the Home moment: the news says Mirage is up, SEA is locked
    P.news = { headlines = function() return { { key = "mirage", tone = "up", title = "MIRAGE ISLAND UP", body = "" } } end }
    B = build({ farm = NOW + 5 * 86400 + 60 }, "buyer", nil)
    B.live()
    -- Task S: the BREAKING strip (Home.dc.html) - Home only, only while something is up
    do
        local panel = rawget(B.g, "_kids")[1]
        local strip = panel:FindFirstChild("NewsStrip")
        check(strip ~= nil, "strip: built when there is news")
        P.newsStripNow()
        local words = {}
        walk(strip, function(o) if o.ClassName == "TextLabel" then table.insert(words, tostring(o.Text)) end end)
        local w = table.concat(words, "|")
        check(strip.Visible and string.find(w, "BREAKING", 1, true) and string.find(w, "MIRAGE ISLAND IS UP", 1, true)
            and string.find(w, "SEA", 1, true), "strip: Home says BREAKING, MIRAGE ISLAND IS UP and the locked SEA chip: " .. w)
        local body
        for _, k in ipairs(rawget(panel, "_kids")) do
            if k.ClassName == "Frame" and k.ClipsDescendants and k.Name ~= "NewsStrip" then body = k end
        end
        check(body.Position.Y.Offset == 82 and P.hudHead == 34, "strip: the body moves under it (" .. body.Position.Y.Offset .. ")")
        B.tap("home", "Key & packs")
        check(not strip.Visible and body.Position.Y.Offset == 48 and P.hudHead == 0,
            "strip: another page has no strip, the body is right under the header")
        B.home()
        check(strip.Visible and body.Position.Y.Offset == 82, "strip: back on Home it is back")
        P.news = { headlines = function() return { { key = "mirage", tone = "dim", title = "NO MIRAGE ISLAND", body = "" } } end }
        P.newsStripNow()
        check(not strip.Visible and body.Position.Y.Offset == 48, "strip: nothing up = no strip, no NEWS block")
        P.news = { headlines = function() return { { key = "mirage", tone = "up", title = "MIRAGE ISLAND UP", body = "" } } end }
        P.newsStripNow()
    end
    check(B.has("home", "Mirage is up in this server") and B.has("home", "SEA runs it for you · look inside"),
        "Home: the live moment card shows for a locked pack")
    check(P.hudExtra == 76, "Home: the panel grows by the card (" .. tostring(P.hudExtra) .. ")")
    B.tap("home", "Mirage is up in this server")
    check(B.cur() == "cover_sea", "Home: the moment card opens the SEA cover, got " .. B.cur())
    check(P.hudExtra == 0, "Home: the panel is its own size again off Home")
    B.home()
    check(P.hudExtra == 76, "Home: the card is back when Home is")
    B.tap("home", "×")
    check(P.hudExtra == 0, "Home: x puts the card away")
    -- a pack this key holds (R3 1c): the card shows too, and a tap hunts it
    B = build({ farm = NOW + 86400, sea = 0 }, "buyer", nil)
    P.running = false
    B.live()
    check(B.has("home", "Mirage is up in this server") and B.has("home", "Tap to hunt it · SEA"),
        "Home: a held pack shows the card, Tap to hunt it")
    check(P.hudExtra == 76, "Home: the panel grows by the card for a held pack too")
    table.clear(CALLS)
    B.tap("home", "Mirage is up in this server")
    check(B.cur() == "home" and called("setHunt true mirage") and called("start") and P.running,
        "Home: a tap on a held pack sets the Mirage hunt and starts the farm")
    B.live()
    check(B.has("home", "Hunting it now · SEA"), "Home: the card says Hunting it now")
    P.running = false
    -- the event ends: the card clears itself
    P.news = { headlines = function() return { { key = "mirage", tone = "dim", title = "NO MIRAGE ISLAND", body = "" } } end }
    P.momentLook()    -- the card looks every 2 s: look now
    B.live()
    check(P.hudExtra == 0,
        "Home: the card clears when the event ends")
    -- the owner: a fruit on the map beats the island, named, and a tap hunts it
    P.fruitSpot = function() return "spot" end
    P.fruitBase = P.fruitBase or function(o) return tostring(o) end
    P.news = { fruits = { { orig = "Ice-Ice" } }, headlines = function()
        return { { key = "mirage", tone = "up", title = "MIRAGE ISLAND UP", body = "" },
            { key = "fruit", tone = "up", title = "FRUIT ON THE MAP", body = "" } } end }
    local OW = build({ fruits = 0 }, "owner", nil)
    P.running = false
    P.momentLook()
    OW.live()
    check(OW.has("home", "Ice fruit is up in this server") and OW.has("home", "Tap to hunt it · FRUITS"),
        "Home (owner): a fruit on the map leads, named")
    table.clear(CALLS)
    OW.tap("home", "Ice fruit is up in this server")
    check(called("setHunt true fruit") and called("start"), "Home (owner): a tap hunts the fruit")
    P.running = false
    P.fruitSpot = nil
    P.news = nil

    -- ---------- Task S: the shell and kit match the boards ----------
    do
        local S = build({ fruits = 0 }, "owner", nil)
        local panel = rawget(S.g, "_kids")[1]
        check(panel:FindFirstChild("NewsStrip") == nil, "shell: no news = no strip at all")
        local back, row
        walk(S.g, function(o)
            if o.Name == "Back" then back = o end
            if o.Name == "TitleRow" then row = o end
        end)
        check(back and back.Text == "‹" and back.Size.X.Offset == 44 and back.Size.Y.Offset == 44,
            "header: the board's thin chevron, a 44 px target (not the word Back)")
        S.tap("home", "Mode")
        S.tap("modes", "Legendary swords")
        check(S.cur() == "sword", "header: on Swords, got " .. S.cur())
        local chip = row and row:FindFirstChild("PackChip")
        check(chip and chip.Text == "BOSSES + RAIDS" and row.Position.X.Offset == 54,
            "header: the pack chip sits inline after the title, the title at 54")
        check(not S.has("sword", "BOSSES + RAIDS"), "header: the chip is no longer a line of the page")
        -- the raw here / last / bought lines are in Details, not on the page
        -- (the stub's Enum is a table, so setFont takes Code through FontFace here)
        local function mono(k)
            return k.ClassName == "TextLabel" and (k.Font == Enum.Font.Code
                or string.find(tostring(k.FontFace), "Enum.Font.Code", 1, true) ~= nil)
        end
        local raw = S.find("sword", mono)
        local inFold = false
        local p = raw and raw.Parent
        while p do
            for _, k in ipairs(rawget(p, "_kids")) do
                if k.ClassName == "Frame" then
                    walk(k, function(o) if o.ClassName == "TextLabel" and o.Text == "Details" then inFold = true end end)
                end
            end
            if inFold or p == S.V.sword then break end
            p = p.Parent
        end
        check(raw ~= nil and raw.Parent ~= S.V.sword and inFold, "raw readouts: Swords' monospace lines sit in Details")
        -- the mode strip: the board's pill
        local pill = S.find("sword", function(k) return k.Name == "ModePill" end)
        local word = pill and pill:FindFirstChild("Word")
        CFG_REAL.Pvp, CFG_REAL.LeviFight, CFG_REAL.Hunt = false, false, false
        S.live()
        check(word and word.Text == "Use this" and pill:FindFirstChild("Face").BackgroundColor3.R == 232,
            "pill: Not your mode = an ivory Use this (" .. tostring(word and word.Text) .. ")")
        pill.Activated:Fire()
        S.live()
        check(word.Text == "In use" and pill:FindFirstChild("Face").BackgroundTransparency == 1,
            "pill: your mode = a ghost In use")
        check(S.has("sword", "Not your mode") == false and S.has("sword", "Your mode"), "pill: the bold line says Your mode")
        P.setHunt(false)
        -- type scale: board px through lookPx (Montserrat in Roblox is 1.21x smaller)
        local navLabel = S.find("sword", function(k) return k.ClassName == "TextLabel" and k.Text == "Fights with" end)
        check(navLabel and navLabel.TextSize == 18, "type: a row label is the board's 15 px = TextSize 18")
        local help = S.find("sword", function(k)
            return k.ClassName == "TextLabel" and string.find(tostring(k.Text), "^For True Triple Katana") ~= nil end)
        check(help and help.TextSize == 13 and help.LineHeight and help.LineHeight > 1.15,
            "type: help text is the board's 11 px, line-height 1.45")
    end

    -- The owner: nothing locked, every pack a cover that opens its modes, owner tools in their own section.
    local O = build({ fruits = 0 }, "owner", nil)
    O.tap("home", "Mode")
    O.live()
    check(O.has("modes", "OWNER") and O.has("modes", "everything is open on your key"), "owner: the key strip says OWNER")
    for _, row in ipairs({ "Circuit farm", "Random", "Raid", "Elite pirates", "Legendary swords", "Sea travel", "Sea events",
        "Prehistoric", "Mirage", "Leviathan", "PvP", "Fruits", "Haki berries", "Aura recipe", "Fire Flower", "Blaze Ember", "Halloween" }) do
        check(O.btn("modes", row) ~= nil, "owner: a row for " .. row)
    end
    check(O.has("modes", "OWNER TOOLS · HUNT, NEXT SERVER WHEN NOT HERE"), "owner: the owner tools have their own section")
    check(O.has("modes", "LIBRARY · EVERY PACK IS YOURS") and not O.has("modes", "BEST VALUE"), "owner: no shop, no EVERYTHING card")
    O.tap("modes", "SEA")
    check(O.cur() == "cover_sea", "owner: a pack's cover opens, got " .. O.cur())
    check(O.has("cover_sea", "On your key") and not O.has("cover_sea", "Not on your key yet"), "owner: the plate says On your key, no price")
    check(O.btn("cover_sea", "Mirage") ~= nil and O.btn("cover_sea", "Leviathan") ~= nil, "owner: INSIDE rows open the modes")
    O.tap("cover_sea", "Mirage")
    check(O.cur() == "mirage", "owner: a cover's row opens the mode, got " .. O.cur())
    local anyLock = false
    for _, name in ipairs({ "modes", "cover_sea", "cover_raid", "key" }) do
        if O.has(name, "Not on your key yet") then anyLock = true end
    end
    check(not anyLock, "owner: no lock text anywhere")
    O.home() O.tap("home", "Key & packs")
    O.live()
    check(O.has("key", "for ever") and O.has("key", "OWNER"), "owner: Key says OWNER, packs for ever")

    -- No key at all: as before the gate - every mode open.
    local N = build(nil, nil, nil)
    N.tap("home", "Mode")
    check(N.has("modes", "NO KEY") and N.btn("modes", "Raid") ~= nil and N.btn("modes", "Mirage") ~= nil, "no key: every mode is a row")
    _G.BFF_ENT, _G.BFF_KIND, _G.BFF_STORE, _G.BFF_KEY = nil, nil, nil, nil
    setclipboard = nil
end

-- ---------- R2 Task 4: GRIND pages, Circuit and Random ----------
do
    local was = { q = CFG_REAL.Quests, r = CFG_REAL.RandomRadius }
    for _, page in ipairs({ "circuit", "random" }) do
        check(modePill(page) ~= nil and isStrip(modePill(page)), page .. ": a mode strip")
        check(button(page, "Fights with") ~= nil, page .. ": a Fights with row")
        check(button(page, "Fine-tune") ~= nil, page .. ": a Fine-tune button")
    end
    -- Circuit: BY MY LEVEL | MY LIST is one explicit choice over CFG.Quests
    tap("circuit", "BY MY LEVEL")
    check(CFG_REAL.Quests == true, "circuit: BY MY LEVEL -> Quests true")
    tap("circuit", "MY LIST")
    check(CFG_REAL.Quests == false, "circuit: MY LIST -> Quests false (the list never silently waits)")
    check(button("circuit", "Clear the circuit") ~= nil, "circuit: Clear the circuit reachable")
    local typed
    each(VIEWS.circuit, function(k) if not typed and k.ClassName == "TextBox" then typed = k end end)
    check(typed ~= nil, "circuit: the type-a-name row is there")
    if typed then
        typed.Text = "Reborn Skeleton"
        typed.FocusLost:Fire(true)
        check(called("toggleTarget Reborn Skeleton"), "circuit: a typed name goes to P.toggleTarget")
    end
    -- Random: the area dial writes RandomRadius; today (750) is step 3
    tap("random", "4")
    check(CFG_REAL.RandomRadius == 1200, "random: step 4 -> 1200 studs")
    tap("random", "1")
    check(CFG_REAL.RandomRadius == 300, "random: step 1 -> 300 studs")
    tap("random", "3")
    check(CFG_REAL.RandomRadius == 750, "random: step 3 is today's 750")
    CFG_REAL.Quests, CFG_REAL.RandomRadius = was.q, was.r
end

-- ---------- R2 Task 5: BOSSES + RAIDS pages, Raid, Elite, Legendary swords ----------
do
    local was = { loop = CFG_REAL.RaidLoop, chip = CFG_REAL.RaidChip, fruit = CFG_REAL.RaidFruitMax,
        look = CFG_REAL.EliteLook, want = CFG_REAL.SwordWant.Shizu }
    for _, page in ipairs({ "raid", "elite", "sword" }) do
        check(modePill(page) ~= nil and isStrip(modePill(page)), page .. ": a mode strip")
        check(button(page, "Fights with") ~= nil, page .. ": a Fights with row")
    end
    check(button("raid", "Fine-tune") ~= nil and button("elite", "Fine-tune") ~= nil, "raid and elite: Fine-tune")
    -- Raid: a chip is the next raid (loop on); "I start each raid myself" = no loop
    tap("raid", "Quake")
    check(CFG_REAL.RaidChip == "Quake" and CFG_REAL.RaidLoop == true, "raid: a chip sets RaidChip and turns the loop on")
    tap("raid", "I start each raid myself")
    check(CFG_REAL.RaidLoop == false, "raid: I start each raid myself -> RaidLoop off")
    tap("raid", "Flame")
    check(CFG_REAL.RaidChip == "Flame" and CFG_REAL.RaidLoop == true, "raid: Flame puts the loop back")
    tap("raid", "1")
    check(CFG_REAL.RaidFruitMax == 0, "raid: money guard step 1 = no fruit")
    tap("raid", "5")
    check(CFG_REAL.RaidFruitMax == 500000, "raid: money guard step 5 = 500,000")
    tap("raid", "3")
    check(CFG_REAL.RaidFruitMax == 200000, "raid: money guard step 3 is today's 200,000")
    -- Elite: patience dial over EliteLook, today = step 3 (8 s)
    tap("elite", "5")
    check(CFG_REAL.EliteLook == 30, "elite: patience 5 = 30 s")
    tap("elite", "1")
    check(CFG_REAL.EliteLook == 3, "elite: patience 1 = 3 s")
    tap("elite", "3")
    check(CFG_REAL.EliteLook == 8, "elite: patience 3 is today's 8 s")
    check(button("elite", "Servers & team") ~= nil, "elite: Servers & team link")
    -- Swords: a card buys or skips
    tap("sword", "Shizu")
    check(CFG_REAL.SwordWant.Shizu == (not was.want), "sword: a card toggles SwordWant")
    tap("sword", "Shizu")
    check(CFG_REAL.SwordWant.Shizu == was.want, "sword: and back")
    CFG_REAL.RaidLoop, CFG_REAL.RaidChip, CFG_REAL.RaidFruitMax = was.loop, was.chip, was.fruit
    CFG_REAL.EliteLook, CFG_REAL.SwordWant.Shizu = was.look, was.want
end

-- ---------- R2 Task 6: SEA pages, Sea travel, Sea events, Sea fight, Leviathan, Mirage ----------
do
    local was = { fight = CFG_REAL.SeaEvFight["Shark"], goal = CFG_REAL.SeaEvGoal, form = CFG_REAL.SeaEvForm,
        lh = CFG_REAL.LeviHeight, ls = CFG_REAL.LeviShare, job = CFG_REAL.MirageJob, need = CFG_REAL.MirageNeed }
    local DODGE = { "SeaDodge", "BeastDodgeMin", "BeastDodgeMax", "BeastDodgeSpeed", "BeastHeight",
        "SharkDodgeMin", "SharkDodgeMax", "SharkDodgeSpeed", "DodgeRadius", "DodgeSpeed", "FishHeight",
        "DodgeUp", "DodgeTime" }
    local function snap() local t = {} for _, k in ipairs(DODGE) do t[k] = CFG_REAL[k] end return t end
    local before = snap()
    for _, page in ipairs({ "sail", "seaevents", "levi", "mirage" }) do
        check(modePill(page) ~= nil and isStrip(modePill(page)), page .. ": a mode strip")
    end
    check(not (modePill("seafight") and isStrip(modePill("seafight"))), "seafight: a settings page, no mode strip")
    for _, page in ipairs({ "seaevents", "levi", "mirage", "seafight" }) do
        check(button(page, "Fights with") ~= nil, page .. ": a Fights with row")
    end
    check(button("sail", "Fights with") == nil, "sail: only sails, no Fights with row")
    for _, page in ipairs({ "seaevents", "levi", "seafight" }) do
        check(button(page, "Fine-tune") ~= nil, page .. ": Fine-tune")
    end
    -- Sea travel: the two boat numbers open Travel
    tap("sail", "Boat speed")
    check(current() == "travel", "sail: Boat speed opens Travel")
    goHome()
    tap("sail", "Turn speed")
    check(current() == "travel", "sail: Turn speed opens Travel")
    goHome()
    -- Sea events: a chip moves between FIGHT and SAIL AWAY
    CFG_REAL.SeaEvFight["Shark"] = false
    tap("seaevents", "Shark")
    check(CFG_REAL.SeaEvFight["Shark"] == true, "seaevents: tapping Shark moves it to FIGHT")
    tap("seaevents", "Shark")
    check(CFG_REAL.SeaEvFight["Shark"] == false, "seaevents: and back to SAIL AWAY")
    CFG_REAL.SeaEvGoal = 20
    tap("seaevents", "+")
    check(CFG_REAL.SeaEvGoal == 21, "seaevents: + raises the goal")
    tap("seaevents", "-")
    tap("seaevents", "-")
    check(CFG_REAL.SeaEvGoal == 19, "seaevents: - lowers it")
    check(button("seaevents", "Ask the Spy now") ~= nil and button("seaevents", "Reset to 0") ~= nil,
        "seaevents: Ask the Spy now, Reset to 0")
    check(string.find(table.concat(labelsOf(VIEWS.seaevents), "|"), "Stop at the goal", 1, true) ~= nil,
        "seaevents: Stop at the goal")
    goHome() tap("home", "Mode") tap("modes", "Sea events")
    tap("seaevents", "Dodging & heights")
    check(current() == "seafight", "seaevents: Dodging & heights opens Sea fight")
    backBtn.Activated:Fire()
    check(current() == "seaevents", "seafight: Back goes to Sea events")
    goHome()
    -- Sea fight: DODGE OFF + 1-5; step 3 = today's CFG; the form choice
    tap("seafight", "5")
    check(CFG_REAL.BeastHeight == 150 and CFG_REAL.DodgeUp == 80 and CFG_REAL.SharkDodgeSpeed == 500
        and CFG_REAL.DodgeRadius == 50 and CFG_REAL.DodgeTime == 1.8, "seafight: dodge 5 = safest")
    tap("seafight", "1")
    check(CFG_REAL.BeastDodgeMin == 25 and CFG_REAL.FishHeight == 15 and CFG_REAL.DodgeTime == 0.6,
        "seafight: dodge 1 = close")
    tap("seafight", "OFF")
    check(CFG_REAL.SeaDodge == false and CFG_REAL.BeastHeight == 90 and CFG_REAL.FishHeight == 30,
        "seafight: OFF = no dodge, today's heights")
    tap("seafight", "5")
    check(CFG_REAL.SeaDodge == true, "seafight: a step turns dodging back on")
    tap("seafight", "3")
    for _, k in ipairs(DODGE) do
        check(CFG_REAL[k] == P.cfgDefaults[k], "seafight: step 3 " .. k .. " is today's " .. tostring(P.cfgDefaults[k]))
    end
    tap("seafight", "ALWAYS")
    check(CFG_REAL.SeaEvForm == "form", "seafight: Always -> SeaEvForm form")
    tap("seafight", "NEVER")
    check(CFG_REAL.SeaEvForm == "base", "seafight: Never -> SeaEvForm base")
    tap("seafight", "WHEN IT HURTS")
    check(CFG_REAL.SeaEvForm == "auto", "seafight: When it hurts -> SeaEvForm auto")
    tap("seafight", "Fights with")
    check(current() == "attack", "seafight: Fights with opens Attack")
    goHome()
    -- Leviathan: one dial over its two numbers, today = step 3
    tap("levi", "1")
    check(CFG_REAL.LeviHeight == 120 and CFG_REAL.LeviShare == 10, "levi: step 1 = spread (120, 10%)")
    tap("levi", "5")
    check(CFG_REAL.LeviHeight == 45 and CFG_REAL.LeviShare == 40, "levi: step 5 = carry (45, 40%)")
    tap("levi", "3")
    check(CFG_REAL.LeviHeight == P.cfgDefaults.LeviHeight and CFG_REAL.LeviShare == P.cfgDefaults.LeviShare,
        "levi: step 3 is today's values")
    tap("levi", "The Spy's count")
    check(current() == "seaevents", "levi: the Spy's count opens Sea events")
    goHome()
    -- Mirage: the job is the main control; which Mirage only for Blue Gear
    local function whichShown()
        local shown
        each(VIEWS.mirage, function(k)
            if k.ClassName == "TextLabel" and tostring(k.Text) == "BLUE GEAR: WHICH MIRAGE" then shown = k.Parent.Visible end
        end)
        return shown
    end
    goHome() tap("home", "Mode") tap("modes", "Mirage") pcall(LIVE0)
    tap("mirage", "Onto it")
    pcall(LIVE0)
    check(CFG_REAL.MirageJob == "mirage" and whichShown() == false, "mirage: which Mirage hidden for Onto it")
    tap("mirage", "Blue Gear")
    pcall(LIVE0)
    check(CFG_REAL.MirageJob == "gear" and whichShown() == true, "mirage: which Mirage shown for Blue Gear ")
    tap("mirage", "FULL MOON")
    check(CFG_REAL.MirageNeed == "full", "mirage: Full moon -> MirageNeed full")
    tap("mirage", "EVERY ONE")
    check(CFG_REAL.MirageNeed == "any", "mirage: Every one -> MirageNeed any")
    tap("mirage", "SEES NIGHT")
    check(CFG_REAL.MirageNeed == "night", "mirage: Sees night -> MirageNeed night")
    tap("mirage", "Advanced Fruit Dealer")
    pcall(LIVE0)
    check(CFG_REAL.MirageJob == "dealer" and whichShown() == false, "mirage: hidden again for the dealer")
    check(button("mirage", "Sea fight") ~= nil and button("mirage", "Searching the sea") ~= nil, "mirage: the two links")
    -- put it all back
    for k, v in pairs(before) do CFG_REAL[k] = v end
    CFG_REAL.SeaEvFight["Shark"], CFG_REAL.SeaEvGoal, CFG_REAL.SeaEvForm = was.fight, was.goal, was.form
    CFG_REAL.LeviHeight, CFG_REAL.LeviShare = was.lh, was.ls
    CFG_REAL.MirageJob, CFG_REAL.MirageNeed = was.job, was.need
    goHome()
end

-- ---------- R2 Task 7: PREHISTORIC pages, Prehistoric and Volcano ----------
do
    local was = { cap = CFG_REAL.SeaSearchMinutes, mag = CFG_REAL.SeaMagnet, loot = CFG_REAL.VolcanoLoot,
        after = CFG_REAL.VolcanoAfter, guitar = CFG_REAL.VentGuitar, home = CFG_REAL.RespawnHome,
        volcano = CFG_REAL.Volcano, hunt = CFG_REAL.Hunt, kind = CFG_REAL.HuntKind }
    for _, page in ipairs({ "prehistoric", "volcano" }) do
        check(modePill(page) ~= nil and isStrip(modePill(page)), page .. ": a mode strip")
        check(button(page, "Fights with") ~= nil, page .. ": a Fights with row")
        check(button(page, "Fine-tune") ~= nil, page .. ": Fine-tune")
    end
    check(button("prehistoric", "Volcano event") ~= nil and button("prehistoric", "Searching the sea") ~= nil,
        "prehistoric: nav rows to Volcano and Travel")
    -- the 4-step loop track lights the step the hunt is in
    local function lit()
        local out
        each(VIEWS.prehistoric, function(k)
            if k.ClassName == "TextLabel" and k.Size and k.Size.X.Offset == 28 and k.BackgroundColor3
                and k.BackgroundColor3.R == 240 and k.BackgroundColor3.G == 166 then out = tostring(k.Text) end
        end)
        return out
    end
    goHome() tap("home", "Mode") tap("modes", "Prehistoric")
    CFG_REAL.Hunt, CFG_REAL.HuntKind = false, "prehistoric"
    pcall(LIVE0)
    check(lit() == nil, "prehistoric: hunt off, no loop step lit")
    CFG_REAL.Hunt = true
    local ev0 = P.sea.ev
    P.sea.ev = nil
    pcall(LIVE0)
    check(lit() == "1", "prehistoric: hunt sailing, step 1 lit: " .. tostring(lit()))
    P.sea.ev = { vents = 0, golems = 0, bones = 0, eggs = 0 }
    pcall(LIVE0)
    check(lit() == "2", "prehistoric: event running, step 2 lit: " .. tostring(lit()))
    P.sea.ev.overAt = 1
    pcall(LIVE0)
    check(lit() == "3", "prehistoric: event over, loot, step 3 lit: " .. tostring(lit()))
    P.sea.ev.complete = true
    pcall(LIVE0)
    check(lit() == "4", "prehistoric: complete, step 4 lit: " .. tostring(lit()))
    P.sea.ev = ev0
    CFG_REAL.Hunt, CFG_REAL.HuntKind = was.hunt, was.kind
    -- the give-up dial over SeaSearchMinutes
    tap("prehistoric", "OFF")
    check(CFG_REAL.SeaSearchMinutes == 0, "prehistoric: OFF = no cap")
    tap("prehistoric", "10")
    check(CFG_REAL.SeaSearchMinutes == 10, "prehistoric: 10 min")
    tap("prehistoric", "60")
    check(CFG_REAL.SeaSearchMinutes == 60, "prehistoric: 60 min")
    tap("prehistoric", "40")
    check(CFG_REAL.SeaSearchMinutes == 40, "prehistoric: 40 min")
    tap("prehistoric", "15")
    check(CFG_REAL.SeaSearchMinutes == 15, "prehistoric: 15 min")
    tap("prehistoric", "21")
    check(CFG_REAL.SeaSearchMinutes == P.cfgDefaults.SeaSearchMinutes and P.cfgDefaults.SeaSearchMinutes == 21,
        "prehistoric: 21 min is today's")
    -- Volcanic Magnet first
    local function pillOf(page, label)
        local found
        each(VIEWS[page], function(k) if not found and isPill(k) and switchLabel(k) == label then found = k end end)
        check(found ~= nil, "a \"" .. label .. "\" switch on " .. page)
        return found or { Activated = { Fire = function() end } }
    end
    CFG_REAL.SeaMagnet = true
    pillOf("prehistoric", "Volcanic Magnet first").Activated:Fire()
    check(CFG_REAL.SeaMagnet == false, "prehistoric: the magnet switch writes SeaMagnet")
    pillOf("prehistoric", "Volcanic Magnet first").Activated:Fire()
    check(CFG_REAL.SeaMagnet == true, "prehistoric: and back")
    tap("prehistoric", "Volcano event")
    check(current() == "volcano", "prehistoric: Volcano event opens Volcano")
    goHome()
    tap("prehistoric", "Searching the sea")
    check(current() == "travel", "prehistoric: Searching the sea opens Travel")
    goHome()
    -- Volcano: the strip is the alongside one (it turns CFG.Volcano)
    CFG_REAL.Volcano = false
    modePill("volcano").Activated:Fire()
    check(CFG_REAL.Volcano == true, "volcano: the strip turns the event on, alongside")
    modePill("volcano").Activated:Fire()
    check(CFG_REAL.Volcano == false, "volcano: and off")
    -- AFTER THE WIN: VolcanoLoot + VolcanoAfter
    tap("volcano", "LOOT + AGAIN")
    check(CFG_REAL.VolcanoLoot == true and CFG_REAL.VolcanoAfter == "again", "volcano: loot + again")
    tap("volcano", "NO LOOT")
    check(CFG_REAL.VolcanoLoot == false and CFG_REAL.VolcanoAfter == "hop", "volcano: no loot, next server")
    tap("volcano", "LOOT + HOP")
    check(CFG_REAL.VolcanoLoot == P.cfgDefaults.VolcanoLoot and CFG_REAL.VolcanoAfter == P.cfgDefaults.VolcanoAfter,
        "volcano: loot + hop is today's")
    -- the two switches
    CFG_REAL.VentGuitar, CFG_REAL.RespawnHome = true, true
    pillOf("volcano", "Skull Guitar M1 on the vents").Activated:Fire()
    check(CFG_REAL.VentGuitar == false, "volcano: Skull Guitar switch")
    pillOf("volcano", "Home by respawn after the loot").Activated:Fire()
    check(CFG_REAL.RespawnHome == false, "volcano: Home by respawn switch")
    -- every raw value is still in Fine-tune
    local lab = table.concat(labelsOf(VIEWS.volcano), "|")
    for _, l in ipairs({ "Stay after the loot, then the next server", "Egg: stand still after E", "Each bone, at least",
        "Each bone, at most", "Seconds between shots", "Vent keys", "Stand off a vent", "Held off the relic",
        "Held up in the air", "Keep the relic over", "Pressure that comes first" }) do
        check(string.find(lab, l, 1, true) ~= nil, "volcano: Fine-tune keeps \"" .. l .. "\"")
    end
    CFG_REAL.SeaSearchMinutes, CFG_REAL.SeaMagnet = was.cap, was.mag
    CFG_REAL.VolcanoLoot, CFG_REAL.VolcanoAfter, CFG_REAL.VentGuitar = was.loot, was.after, was.guitar
    CFG_REAL.RespawnHome, CFG_REAL.Volcano = was.home, was.volcano
    goHome()
end

-- ---------- R2 Task 8: PvP, one aim dial ----------
do
    local KEYS = { "PvpAim", "PvpFace", "PvpCatchPx", "PvpRange", "PvpStream", "PvpFaceRange", "PvpVision", "PvpFar",
        "PvpClean", "PvpNoShake", "PvpKenBack", "PvpSpeed", "PvpDash", "PvpLeadAuto", "PvpLead", "PvpLeadScale",
        "PvpHopBusy", "PvpSoruCut", "PvpCdTest" }
    local was = {}
    for _, k in ipairs(KEYS) do was[k] = CFG_REAL[k] end
    local wasKeys = {}
    for kind, t in pairs(CFG_REAL.PvpAimKeys) do wasKeys[kind] = {} for k2, x in pairs(t) do wasKeys[kind][k2] = x end end
    local function buttonsOf(page, text)
        local out = {}
        each(VIEWS[page], function(k)
            if k.ClassName == "TextButton" and tostring(k.Text) == text then table.insert(out, k) end
        end)
        return out
    end
    local function nth(page, text, n)
        local b = buttonsOf(page, text)[n]
        check(b ~= nil, "button #" .. n .. " \"" .. text .. "\" on " .. page)
        return b or { Activated = { Fire = function() end } }
    end
    local function pillOf(page, label)
        local found
        each(VIEWS[page], function(k) if not found and isPill(k) and switchLabel(k) == label then found = k end end)
        check(found ~= nil, "a \"" .. label .. "\" switch on " .. page)
        return found or { Activated = { Fire = function() end } }
    end
    check(modePill("pvp") ~= nil and isStrip(modePill("pvp")), "pvp: a mode strip")
    check(button("pvp", "Fights with") == nil, "pvp: no Fights with row (you fight by hand)")
    check(button("pvp", "Fine-tune") ~= nil and button("pvp", "Details") ~= nil, "pvp: Details and Fine-tune")
    -- AIM dial: OFF also turns Face off; step 3 = today's CFG
    CFG_REAL.PvpAim, CFG_REAL.PvpFace = true, true
    tap("pvp", "OFF")
    check(CFG_REAL.PvpAim == false and CFG_REAL.PvpFace == false, "pvp: dial OFF turns the aim and Face off")
    tap("pvp", "1")
    check(CFG_REAL.PvpAim == true and CFG_REAL.PvpCatchPx == 60 and CFG_REAL.PvpRange == 150
        and CFG_REAL.PvpStream == false and CFG_REAL.PvpFace == false, "pvp: dial 1 = touch")
    tap("pvp", "2")
    check(CFG_REAL.PvpCatchPx == 120 and CFG_REAL.PvpRange == 200 and CFG_REAL.PvpFace == true
        and CFG_REAL.PvpFaceRange == 50, "pvp: dial 2 = light")
    tap("pvp", "4")
    check(CFG_REAL.PvpCatchPx == 320 and CFG_REAL.PvpRange == 500 and CFG_REAL.PvpFaceRange == 125, "pvp: dial 4 = strong")
    tap("pvp", "5")
    check(CFG_REAL.PvpCatchPx == 500 and CFG_REAL.PvpRange == 1000 and CFG_REAL.PvpFaceRange == 150, "pvp: dial 5 = sticky")
    tap("pvp", "3")
    for _, k in ipairs({ "PvpAim", "PvpFace", "PvpCatchPx", "PvpRange", "PvpStream", "PvpFaceRange" }) do
        check(CFG_REAL[k] == P.cfgDefaults[k], "pvp: dial 3 " .. k .. " is today's " .. tostring(P.cfgDefaults[k]))
    end
    -- tiles: Vision sets its 5 keys at once; Run, Dash one each
    local VIS = { "PvpVision", "PvpFar", "PvpClean", "PvpNoShake", "PvpKenBack" }
    for _, k in ipairs(VIS) do CFG_REAL[k] = true end
    tap("pvp", "Vision")
    for _, k in ipairs(VIS) do check(CFG_REAL[k] == false, "pvp: Vision tile off sets " .. k) end
    tap("pvp", "Vision")
    for _, k in ipairs(VIS) do check(CFG_REAL[k] == true, "pvp: Vision tile on sets " .. k) end
    CFG_REAL.PvpSpeed, CFG_REAL.PvpDash = true, true
    tap("pvp", "Run")
    check(CFG_REAL.PvpSpeed == false, "pvp: Run tile writes PvpSpeed")
    tap("pvp", "Dash")
    check(CFG_REAL.PvpDash == false, "pvp: Dash tile writes PvpDash")
    -- aimed moves: Fruit, Fighting, Sword, Gun cards, Z is the third
    check(#buttonsOf("pvp", "Z") == 4, "pvp: four weapon cards each with a Z chip")
    local zWas, m1Was = CFG_REAL.PvpAimKeys.Sword.Z ~= false, CFG_REAL.PvpAimKeys.Gun.M1 ~= false
    nth("pvp", "Z", 3).Activated:Fire()
    check((CFG_REAL.PvpAimKeys.Sword.Z ~= false) == (not zWas), "pvp: the Sword's Z chip flips")
    nth("pvp", "M1", 4).Activated:Fire()
    check((CFG_REAL.PvpAimKeys.Gun.M1 ~= false) == (not m1Was), "pvp: the Gun's M1 chip flips")
    -- LEAD: Learns | Off | Fixed over three old controls
    nth("pvp", "OFF", 2).Activated:Fire()
    check(CFG_REAL.PvpLeadAuto == false and CFG_REAL.PvpLead == false, "pvp: lead Off")
    tap("pvp", "FIXED")
    check(CFG_REAL.PvpLeadAuto == false and CFG_REAL.PvpLead == true, "pvp: lead Fixed")
    CFG_REAL.PvpLeadScale = 1.0
    nth("pvp", "+", 1).Activated:Fire()
    check(CFG_REAL.PvpLeadScale == 1.1, "pvp: the Fixed stepper + raises the lead strength: " .. tostring(CFG_REAL.PvpLeadScale))
    nth("pvp", "-", 1).Activated:Fire()
    nth("pvp", "-", 1).Activated:Fire()
    check(CFG_REAL.PvpLeadScale == 0.9, "pvp: and - lowers it: " .. tostring(CFG_REAL.PvpLeadScale))
    tap("pvp", "LEARNS")
    check(CFG_REAL.PvpLeadAuto == true, "pvp: lead Learns")
    -- busy servers
    CFG_REAL.PvpHopBusy = true
    pillOf("pvp", "Busy servers").Activated:Fire()
    check(CFG_REAL.PvpHopBusy == false, "pvp: Busy servers switch")
    table.clear(CALLS)
    tap("pvp", "Hop")
    livePass()
    check(called("hopNow"), "pvp: the hop row hops")
    -- Lab: a test on turns the header amber
    local function labHint()
        local b = button("pvp", "Lab · TEST")
        local kids = b and rawget(b, "_kids") or {}
        return kids[2]
    end
    goHome() tap("home", "Mode") tap("modes", "PvP")
    CFG_REAL.PvpSoruCut, CFG_REAL.PvpCdTest = 0, false
    pcall(LIVE0)
    if labHint() and tostring(labHint().Text) == "hide" then tap("pvp", "Lab · TEST") end   -- folds start shut
    check(labHint() ~= nil and tostring(labHint().Text) == "2 tests, both off" and labHint().TextColor3.R ~= 240,
        "pvp: Lab header, both off, is not amber")
    nth("pvp", "+", 2).Activated:Fire()
    check(CFG_REAL.PvpSoruCut == 5, "pvp: Lab Flash Step cut + steps 5")
    pcall(LIVE0)
    check(labHint() ~= nil and tostring(labHint().Text) == "1 test on" and labHint().TextColor3.R == 240,
        "pvp: Lab header turns amber when a test is on")
    pillOf("pvp", "Skills off cooldown (test)").Activated:Fire()
    check(CFG_REAL.PvpCdTest == true, "pvp: Lab skills-off-cooldown switch")
    pcall(LIVE0)
    check(labHint() ~= nil and tostring(labHint().Text) == "2 tests on", "pvp: both tests on")
    -- Fine-tune keeps every exact value
    local lab = table.concat(labelsOf(VIEWS.pvp), "|")
    for _, l in ipairs({ "Aim at the player", "Mouse catch area", "Players count within", "Face him on every attack",
        "Face him within", "Keep aiming while the move plays", "Highlight him", "Ray guns shoot straight", "Lead strength",
        "Observation view always on", "See far", "Vision range", "Clean screen", "No camera shake", "Ken back by itself",
        "Legs at a normal pace", "Run speed", "Dash", "Dash animation", "Ping at most, any most-players hop" }) do
        check(string.find(lab, l, 1, true) ~= nil, "pvp: keeps \"" .. l .. "\"")
    end
    check(button("pvp", "Forget what the moves learned") ~= nil, "pvp: Details keeps Forget what the moves learned")
    for _, k in ipairs(KEYS) do CFG_REAL[k] = was[k] end
    for kind, t in pairs(wasKeys) do for k2, x in pairs(t) do CFG_REAL.PvpAimKeys[kind][k2] = x end end
    goHome()
end

-- ---------- R2 Task 9: Travel, Position, Magnet, Safety, Servers ----------
do
    local KEYS = { "Magnet", "PullAll", "MaxPull", "GrabMax", "PileSpread", "PullOthers", "LearnLeash",
        "HeightMode", "StayHigh", "EscapeBelow", "ReturnAt", "AutoBuso", "AutoKen", "TravelSpeed", "InstantHop",
        "SeaSpeed", "SeaSteer", "SeaSearchTo", "SeaTurnBack", "SeaLeg2", "HuntHop", "HopOrder", "AutoTeam", "Team",
        "ChaliceGuard", "LightMode" }
    local was = {}
    for _, k in ipairs(KEYS) do was[k] = CFG_REAL[k] end
    local function pillOf(page, label)
        local found
        each(VIEWS[page], function(k) if not found and isPill(k) and switchLabel(k) == label then found = k end end)
        check(found ~= nil, "a \"" .. label .. "\" switch on " .. page)
        return found or { Activated = { Fire = function() end } }
    end
    local function nth(page, text, n)
        local list = {}
        each(VIEWS[page], function(k)
            if k.ClassName == "TextButton" and tostring(k.Text) == text then table.insert(list, k) end
        end)
        check(list[n] ~= nil, "button #" .. n .. " \"" .. text .. "\" on " .. page)
        return list[n] or { Activated = { Fire = function() end } }
    end
    local function labelsHave(page, list, tag)
        local lab = table.concat(labelsOf(VIEWS[page]), "|")
        for _, l in ipairs(list) do check(string.find(lab, l, 1, true) ~= nil, tag .. ": keeps \"" .. l .. "\"") end
    end
    -- MAGNET: OFF + 1-5, step 3 = today
    tap("magnet", "OFF")
    check(CFG_REAL.Magnet == false, "magnet: dial OFF turns the magnet off")
    tap("magnet", "1")
    check(CFG_REAL.Magnet == true and CFG_REAL.PullAll == false and CFG_REAL.MaxPull == 150 and CFG_REAL.GrabMax == 8
        and CFG_REAL.PileSpread == 1, "magnet: dial 1 = gentle")
    tap("magnet", "5")
    check(CFG_REAL.PullAll == true and CFG_REAL.MaxPull == 1000 and CFG_REAL.PileSpread == 4, "magnet: dial 5 = all")
    tap("magnet", "3")
    check(CFG_REAL.MaxPull == 300 and CFG_REAL.GrabMax == 30 and CFG_REAL.PileSpread == 3 and CFG_REAL.PullAll == true,
        "magnet: dial 3 = today")
    pillOf("magnet", "Pull other picked species too").Activated:Fire()
    check(CFG_REAL.PullOthers == (not was.PullOthers), "magnet: species switch")
    pillOf("magnet", "Learn how far each kind can go").Activated:Fire()
    check(CFG_REAL.LearnLeash == (not was.LearnLeash), "magnet: learn switch")
    labelsHave("magnet", { "Pull every one loaded", "Pull at most, from their spawn", "When that is off: within",
        "Most in one pile", "Pile width", "This camp means within", "Put back after no damage for" }, "magnet")
    check(button("magnet", "Clear the list") ~= nil and button("magnet", "Forget what it measured") ~= nil,
        "magnet: Details keeps its two clears")
    -- POSITION
    tap("position", "ONE FIXED SPOT")
    check(CFG_REAL.HeightMode == "fixed", "position: FIXED")
    tap("position", "AUTO: HIGH OR CLOSE")
    check(CFG_REAL.HeightMode == "auto", "position: AUTO")
    pillOf("position", "Always stay above them").Activated:Fire()
    check(CFG_REAL.StayHigh == (not was.StayHigh), "position: Always stay above them")
    labelsHave("position", { "Auto: high, over the pile", "Auto: close, height", "Auto: close, out to the side",
        "Fixed: height", "Fixed: out to the side" }, "position")
    -- SAFETY: the two marks never cross
    CFG_REAL.EscapeBelow, CFG_REAL.ReturnAt = 0.35, 0.40
    nth("safety", "+", 1).Activated:Fire()
    check(CFG_REAL.EscapeBelow == 0.4 and CFG_REAL.ReturnAt == 0.45, "safety: escape up pushes come-back up")
    nth("safety", "-", 2).Activated:Fire()
    check(CFG_REAL.ReturnAt == 0.4 and CFG_REAL.EscapeBelow == 0.35, "safety: come-back down pulls escape down")
    CFG_REAL.AutoBuso, CFG_REAL.AutoKen = true, true
    tap("safety", "Enhancement")
    check(CFG_REAL.AutoBuso == false and CFG_REAL.AutoKen == true, "safety: J tile")
    tap("safety", "Observation")
    check(CFG_REAL.AutoKen == false, "safety: E tile")
    labelsHave("safety", { "Check Observation every" }, "safety")
    -- TRAVEL
    nth("travel", "1", 1).Activated:Fire()
    check(CFG_REAL.TravelSpeed == 250 and CFG_REAL.InstantHop == 100 and CFG_REAL.SeaSpeed == 250, "travel: speed 1")
    nth("travel", "3", 1).Activated:Fire()
    check(CFG_REAL.TravelSpeed == 330 and CFG_REAL.InstantHop == 150 and CFG_REAL.SeaSpeed == 300, "travel: speed 3 = today")
    tap("travel", "I STEER: A D W S")
    check(CFG_REAL.SeaSteer == "manual", "travel: I steer")
    tap("travel", "AUTO: WEST, THEN NEW SERVER")
    check(CFG_REAL.SeaSteer == "auto", "travel: Auto")
    nth("travel", "1", 2).Activated:Fire()
    check(CFG_REAL.SeaSearchTo == 6000 and CFG_REAL.SeaTurnBack == 60 and CFG_REAL.SeaLeg2 == 2000, "travel: look dial 1")
    nth("travel", "5", 2).Activated:Fire()
    check(CFG_REAL.SeaSearchTo == 17000 and CFG_REAL.SeaTurnBack == 120 and CFG_REAL.SeaLeg2 == 7000, "travel: look dial 5 = today")
    labelsHave("travel", { "Fly speed", "One jump, no flight, under", "Boat speed", "Ask a far door from where I stand",
        "Auto: out to", "Auto: then turn left", "Auto: and sail on", "Auto: a turn every", "Auto: a turn up to",
        "I steer: turn speed (A / D)", "One compass meter", "Shortest way" }, "travel")
    -- SERVERS
    tap("servers", "MOST")
    check(CFG_REAL.HuntHop == true and CFG_REAL.HopOrder == "most", "servers: most")
    tap("servers", "ANY")
    check(CFG_REAL.HopOrder == "random", "servers: any")
    tap("servers", "STAY")
    check(CFG_REAL.HuntHop == false, "servers: stay")
    tap("servers", "FEWEST")
    check(CFG_REAL.HuntHop == true and CFG_REAL.HopOrder == "fewest", "servers: fewest")
    tap("servers", "MARINES")
    check(CFG_REAL.AutoTeam == true and CFG_REAL.Team == "Marines", "servers: Marines")
    tap("servers", "DON'T PICK")
    check(CFG_REAL.AutoTeam == false, "servers: don't pick")
    pillOf("servers", "Light mode").Activated:Fire()
    check(CFG_REAL.LightMode == (not was.LightMode), "servers: Light mode")
    pillOf("servers", "The God's Chalice stops every hop").Activated:Fire()
    check((CFG_REAL.ChaliceGuard ~= false) == (was.ChaliceGuard == false), "servers: Chalice switch")
    check(button("servers", "Breaking news") ~= nil, "servers: the news row")
    labelsHave("servers", { "Try a server again after" }, "servers")
    table.clear(CALLS)
    tap("servers", "Hop now")
    livePass()
    check(not called("hopNow"), "servers: Hop now wants a second tap")
    tap("servers", "Tap again: Hop now")
    livePass()
    check(called("hopNow"), "servers: the second tap hops")
    for _, k in ipairs(KEYS) do CFG_REAL[k] = was[k] end
    goHome()
end

-- ---------- R3: the look ----------
do
    local function loops()
        local out = {}
        for _, t in ipairs(TWEENS) do
            -- (the cases rebuild the panel; only the live one's tween counts)
            local g = t.target.Parent and t.target.Parent.Parent and t.target.Parent.Parent.Parent
            if t.info and t.info.args and t.info.args[4] == -1 and g == gui then table.insert(out, t) end
        end
        return out
    end
    local function foldBtn()
        for _, o in ipairs(ALL) do
            if o.ClassName == "TextButton" and (o.Text == "Hide" or o.Text == "Show") then return o end
        end
    end
    local L = loops()
    check(#L == 1 and L[1].playing and L[1].target.ClassName == "UIGradient",
        "outline sweep: one looping gradient tween, playing while the panel is up")
    local stroke = L[1] and L[1].target.Parent
    check(stroke and stroke.ClassName == "UIStroke" and stroke.Parent and stroke.Parent.Parent == gui,
        "outline sweep: the gradient is on the panel's own stroke (never on the panel)")
    check(stroke and tostring(stroke.ApplyStrokeMode) == "Enum.ApplyStrokeMode.Border" and stroke.Thickness == 1,
        "outline: a 1 px stroke in Border mode, outside the content")
    foldBtn().Activated:Fire()
    check(not L[1].playing, "outline sweep stops when the panel is folded")
    foldBtn().Activated:Fire()
    local playing = 0
    for _, t in ipairs(loops()) do if t.playing then playing += 1 end end
    check(playing == 1, "outline sweep runs again when the panel is shown (and only one runs)")

    -- Montserrat, through FontFace, on the labels of Home
    local mont, gotham = 0, 0
    for _, k in ipairs(rawget(VIEWS.home, "_kids")) do
        for _, o in ipairs(rawget(k, "_kids") or {}) do
            if o.FontFace and string.find(o.FontFace.Path, "Montserrat", 1, true) then mont += 1 end
            if o.Font and tostring(o.Font):find("Gotham", 1, true) then gotham += 1 end
        end
    end
    check(mont > 0 and gotham == 0, "Home rows: Montserrat, no Gotham (" .. mont .. "/" .. gotham .. ")")

    -- "Idle" and its line start where the rows do: full width, 20 px padding
    local function labelWith(txt)
        for _, k in ipairs(rawget(VIEWS.home, "_kids")) do
            if k.ClassName == "TextLabel" and k.Text == txt then return k end
        end
    end
    local idle = labelWith("Idle")
    local pad = idle and idle:FindFirstChild("UIPadding")
    check(idle and idle.Size.X.Scale == 1 and idle.Size.X.Offset == 0 and pad and pad.PaddingLeft.Offset == 20,
        "Idle: full width + 20 px padding, in line with the rows")
    -- thin chevrons
    local chev = 0
    for _, o in ipairs(ALL) do
        if o.ClassName == "TextLabel" and o.Text == ">" then chev += 1 end
    end
    check(chev == 0, "no text '>' chevrons left (" .. chev .. ")")
end

-- ---------- R3 Task 1b: resize (scale + crop) ----------
do
    local panel
    local liveGui = PG:FindFirstChild("BFFHUD")      -- (the cases above rebuilt the panel)
    for _, k in ipairs(rawget(liveGui, "_kids")) do
        if k.ClassName == "Frame" then panel = k break end
    end
    local sg, cg = panel:FindFirstChild("ScaleGrip"), panel:FindFirstChild("CropGrip")
    local us = panel:FindFirstChild("UIScale")
    check(sg and cg and us, "resize: a corner grip, an edge grip and a UIScale on the panel")
    check(panel.AnchorPoint.X == 1 and panel.AnchorPoint.Y == 0, "resize: the panel is anchored top-right")
    check(sg.Size.X.Offset == 44 and sg.Size.Y.Offset == 44 and cg.Size.Y.Offset == 44,
        "resize: 44 px hit areas")
    -- the hit areas lie over the page by 16 px at most (its bottom padding)
    check(sg.Position.Y.Offset == -16 and cg.Position.Y.Offset == -16,
        "resize: only the inner 16 px of a grip is over the page")
    local function bg(o)
        for _, k in ipairs(rawget(o, "_kids")) do
            if k.ClassName == "Frame" and k.BackgroundTransparency == 0 then return true end
        end
        return false
    end
    check(not bg(sg), "resize: the corner marks stay hidden until hover / touch / drag")
    sg.MouseEnter:Fire()
    check(bg(sg), "resize: the corner marks show on hover")
    sg.MouseLeave:Fire()
    check(CFG_REAL.PanelScale == 1.0 and CFG_REAL.PanelHeight == 0, "resize: starts at 1.0 / full")
    local fullH = panel.Size.Y.Offset
    local M1 = Enum.UserInputType.MouseButton1
    local function press(g, y, id)
        local inp = { UserInputType = M1, Position = { X = 0, Y = y } }
        g.InputBegan:Fire(inp)
        return inp
    end
    -- touch + mouse both start a drag; the move comes through UIS.InputChanged
    local inp = press(cg, 500)
    UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = { X = 0, Y = 300 } })
    check(panel.Size.Y.Offset == fullH - 200, "resize: edge drag crops the height (" .. panel.Size.Y.Offset .. ")")
    check(CFG_REAL.PanelHeight == fullH - 200, "resize: the crop is in CFG.PanelHeight")
    UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = { X = 0, Y = -4000 } })
    check(panel.Size.Y.Offset == 250, "resize: the crop stops at the header plus 3 rows")
    UIS.InputEnded:Fire(inp)
    UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = { X = 0, Y = 0 } })
    check(panel.Size.Y.Offset == 250, "resize: after release a move does nothing")
    -- scale: a touch drag
    local T = Enum.UserInputType.Touch
    local tin = { UserInputType = T, Position = { X = 0, Y = 100 } }
    sg.InputBegan:Fire(tin)
    UIS.InputChanged:Fire({ UserInputType = T, Position = { X = 0, Y = -60 } })
    check(us.Scale < 1 and us.Scale >= 0.6 and CFG_REAL.PanelScale == us.Scale,
        "resize: corner drag (touch) scales the panel, kept in CFG.PanelScale")
    UIS.InputChanged:Fire({ UserInputType = T, Position = { X = 0, Y = -9000 } })
    check(us.Scale == 0.6, "resize: scale stops at 0.6")
    UIS.InputEnded:Fire(tin)
    -- double tap resets
    sg.InputBegan:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    UIS.InputEnded:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    sg.InputBegan:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    check(CFG_REAL.PanelScale == 1.0 and us.Scale == 1.0, "resize: double tap on the corner resets the scale")
    UIS.InputEnded:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    cg.InputBegan:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    UIS.InputEnded:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    cg.InputBegan:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    check(CFG_REAL.PanelHeight == 0 and panel.Size.Y.Offset == fullH, "resize: double tap on the edge resets the height")
    UIS.InputEnded:Fire({ UserInputType = M1, Position = { X = 0, Y = 0 } })
    -- the header is not inside the scrolling body
    local body
    for _, k in ipairs(rawget(panel, "_kids")) do
        if k.ClassName == "Frame" and k.ClipsDescendants and k.Position.Y.Offset == 48 then body = k end
    end
    check(body and body.Size.Y.Scale == 1 and body.Size.Y.Offset == -48,
        "resize: the body follows the panel height; the header (48 px, no strip up) is outside it")
    local scrolls = 0
    for _, k in ipairs(rawget(body, "_kids")) do
        if k.ClassName == "ScrollingFrame" then scrolls += 1 end
    end
    check(scrolls >= 25, "resize: every page is a scrolling frame (" .. scrolls .. ")")
    -- the settings file keeps both
    check(P.cfgDefaults.PanelScale == 1.0 and P.cfgDefaults.PanelHeight == 0, "resize: defaults are in P.cfgDefaults")
end

print(string.format("%d passed, %d failed", pass, fail))
if fail == 0 then print("ALL PASS") end
