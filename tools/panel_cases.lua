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
    check(onRows() == "", "nothing on = no mode (the circuit Off by default, 2026-10-12): " .. onRows())

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
        "hero with no mode: Start  ·  No mode")

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
        walk(g, function(o) if o.ClassName == "TextButton" and o.Text == "Back" then back = o end end)
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
    check(B.has("modes", "LIBRARY  ·  5 MORE PACKS") and B.has("modes", "tap a cover"), "buyer: LIBRARY  ·  5 MORE PACKS (4 covers and Fruits)")
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
    B.tap("cover_raid", "Get Bosses + Raids  ·  copy store link")
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
        if k.ClassName == "TextLabel" and k.Text ~= ">" and k.Text ~= "Key & packs" then kv = k.Text end
    end
    check(kv == "Grind  ·  5d left", "Home Key row: Grind  ·  5d left (" .. tostring(kv) .. ")")
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
    check(B.has("home", "Mirage is up in this server") and B.has("home", "SEA runs it for you  ·  look inside"),
        "Home: the live moment card shows for a locked pack")
    check(P.hudExtra == 76, "Home: the panel grows by the card (" .. tostring(P.hudExtra) .. ")")
    B.tap("home", "Mirage is up in this server")
    check(B.cur() == "cover_sea", "Home: the moment card opens the SEA cover, got " .. B.cur())
    check(P.hudExtra == 0, "Home: the panel is its own size again off Home")
    B.home()
    check(P.hudExtra == 76, "Home: the card is back when Home is")
    B.tap("home", "x")
    check(P.hudExtra == 0, "Home: x puts the card away")
    -- a pack this key holds: no card at all
    B = build({ farm = NOW + 86400, sea = 0 }, "buyer", nil)
    B.live()
    check(P.hudExtra == 0, "Home: no card when the pack is yours")
    P.news = nil

    -- The owner: nothing locked, every pack a cover that opens its modes, owner tools in their own section.
    local O = build({ fruits = 0 }, "owner", nil)
    O.tap("home", "Mode")
    O.live()
    check(O.has("modes", "OWNER") and O.has("modes", "everything is open on your key"), "owner: the key strip says OWNER")
    for _, row in ipairs({ "Circuit farm", "Random", "Raid", "Elite pirates", "Legendary swords", "Sea travel", "Sea events",
        "Prehistoric", "Mirage", "Leviathan", "PvP", "Fruits", "Haki berries", "Aura recipe", "Fire Flower", "Blaze Ember", "Halloween" }) do
        check(O.btn("modes", row) ~= nil, "owner: a row for " .. row)
    end
    check(O.has("modes", "OWNER TOOLS  ·  HUNT, NEXT SERVER WHEN NOT HERE"), "owner: the owner tools have their own section")
    check(O.has("modes", "LIBRARY  ·  EVERY PACK IS YOURS") and not O.has("modes", "BEST VALUE"), "owner: no shop, no EVERYTHING card")
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

print(string.format("%d passed, %d failed", pass, fail))
if fail == 0 then print("ALL PASS") end
