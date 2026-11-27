# Secondary Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fruit, Factory raid and Elite run as secondaries beside the primary mode (Prehistoric + Volcano already does), each acting only when its event is up on this server, never hopping.

**Architecture:** One pure chooser `sideNext(order, on, ready, primary)` (global, LIVE CARD block, tested in `livecard_test.py`). An engine `P.side` inside the hunt block (where `fruitWanted` / `grabFruit` / `eliteUp` / `eliteFight` live) exposes `P.side.step(ids)`; the Factory block adds `P.factory.sideReady()` / `P.factory.sideStep(epoch)`. `step()` (MAIN LOOP) calls `P.side.step({"fruit","factory"})` before the volcano line and `P.side.step({"elite"})` after it. The Prehistoric + Volcano secondary is the existing `CFG.Volcano` switch.

**Tech Stack:** Luau (Roblox executor script `fast_farm.lua`), offline tests: Python runners in `tools/*_test.py` running `luau.exe` (`C:\Users\sarka\Downloads\scripts\tools\luau-0.735\luau.exe`).

**Spec:** `docs/superpowers/specs/2026-11-27-secondary-modes-design.md` — one deviation: the spec's `Side.prehistoric` is not a new key; the Prehistoric + Volcano row switches `CFG.Volcano` (already a secondary in all but name: `S.volcanoStep()` runs before the primary whenever `CFG.Volcano` is on and the island is up).

**Run all checks (used in every task's last step):**

```bash
cd /c/Users/sarka/Downloads/blox-fast-farm
pass=0; fail=""; for t in tools/*_test.py; do if python "$t" >/dev/null 2>&1; then pass=$((pass+1)); else fail="$fail $t"; fi; done; echo "suites pass: $pass  fail:$fail"
python tools/checks.py fast_farm.lua | tail -3
/c/Users/sarka/Downloads/scripts/tools/luau-0.735/luau-compile.exe fast_farm.lua >/dev/null && echo compile-ok
```
Expected: `suites pass: 49  fail:`, `checks: clean`, `compile-ok`.

---

### Task 1: The pure chooser `sideNext`

**Files:**
- Modify: `fast_farm.lua` — insert just above the line `-- PACKS END` (~line 1427)
- Test: `tools/livecard_cases.lua` (append before its final `io_print`)

- [ ] **Step 1: Write the failing test** — append to `tools/livecard_cases.lua` before the last line (`io_print(all and "ALL PASS" ...)` or the file's own final summary line):

```lua
-- secondary modes (2026-11-27): the first in the fixed order that is on, up, and not the primary
local ORDER = { "fruit", "factory", "elite" }
local function rdy(t) return function(id) return t[id] == true end end
check("side: nothing on = nil", sideNext(ORDER, {}, rdy({ fruit = true }), nil) == nil)
check("side: on but nothing up = nil", sideNext(ORDER, { fruit = true, elite = true }, rdy({}), nil) == nil)
check("side: the one on and up", sideNext(ORDER, { fruit = true, elite = true }, rdy({ elite = true }), nil) == "elite")
check("side: the fixed order decides", sideNext(ORDER, { fruit = true, factory = true },
    rdy({ fruit = true, factory = true }), nil) == "fruit")
check("side: the primary's own kind is never a secondary",
    sideNext(ORDER, { fruit = true, elite = true }, rdy({ fruit = true, elite = true }), "fruit") == "elite")
check("side: no table = nil", sideNext(ORDER, nil, rdy({ fruit = true }), nil) == nil)
```

- [ ] **Step 2: Run it to see it fail**

Run: `cd /c/Users/sarka/Downloads/blox-fast-farm && python tools/livecard_test.py | tail -4`
Expected: an error `attempt to call a nil value (global 'sideNext')`.

- [ ] **Step 3: Implement** — insert above `-- PACKS END` in `fast_farm.lua`:

```lua
-- SECONDARY MODES (user, 2026-11-27: "primary is the mode I pick; secondary
-- modes I turn on beside it - a fruit spawns, the factory raid starts: it
-- goes for it, then back"). Pure (tools/livecard_test.py): order = the
-- fixed order, on = CFG.Side, ready(id) = its event is up on this server,
-- primary = the primary's own kind (never also a secondary). -> the id to
-- run this step, or nil (the primary runs).
function sideNext(order, on, ready, primary)
    if type(on) ~= "table" then return nil end
    for _, id in ipairs(order) do
        if on[id] and id ~= primary and ready(id) then return id end
    end
    return nil
end
```

- [ ] **Step 4: Run it to see it pass**

Run: `python tools/livecard_test.py | tail -3`
Expected: the six `side:` lines PASS and `ALL PASS`.

- [ ] **Step 5: Commit**

```bash
git add fast_farm.lua tools/livecard_cases.lua
git commit -m "Secondary modes: the pure chooser sideNext

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Settings and the Fruit / Elite engine

**Files:**
- Modify: `fast_farm.lua` — CFG (after `FactoryEvery = 0.06,`), `fruitWanted` (~line 9061), and a new block right after `function huntStep()`'s closing `end` (just before `-- The hunt switches. \`kind\` = which hunt`).

- [ ] **Step 1: The settings** — after the line `    FactoryEvery       = 0.06,` add:

```lua
    -- SECONDARY MODES (user, 2026-11-27): beside the primary, each only when
    -- its event is up on this server - never a hop. The Prehistoric island +
    -- volcano is the Volcano switch (CFG.Volcano), already one.
    Side               = { fruit = false, factory = false, elite = false },
```

- [ ] **Step 2: Let the fruit finder run for a secondary** — in `fruitWanted`, replace its first two lines:

```lua
        local function fruitWanted()
            if not (CFG.Hunt and CFG.HuntKind == "fruit") then return nil end
```

with:

```lua
        -- side = asked by the Fruit secondary (SECONDARY MODES), not the hunt.
        local function fruitWanted(side)
            if not side and not (CFG.Hunt and CFG.HuntKind == "fruit") then return nil end
```

- [ ] **Step 3: The engine** — insert right after the `end` that closes `function huntStep()` and before the comment line `        -- The hunt switches. \`kind\` = which hunt ("elite" / "fruit" / "berry");`:

```lua
        -- SECONDARY MODES (user, 2026-11-27). Fruit and Elite here, where
        -- their finders live; Factory from P.factory. One step at a time, no
        -- hop ever: nothing up = the primary runs.
        local SIDE_TITLE = { fruit = "Fruit", factory = "Factory raid", elite = "Elite pirate" }
        P.SIDE_TITLE = SIDE_TITLE
        local SIDE = {
            fruit = {
                ready = function()
                    if P.fruitWait() then return false end
                    local f = fruitWanted(true)
                    E.sideFruit = f
                    return f ~= nil
                end,
                step = function(myEpoch) grabFruit(E.sideFruit, myEpoch) end,
            },
            factory = {
                ready = function() return P.factory ~= nil and P.factory.sideReady() end,
                step = function(myEpoch) P.factory.sideStep(myEpoch) end,
            },
            elite = {
                ready = function()
                    local sea = mySea()
                    if (sea and sea ~= 3) or os.clock() < E.eliteDoneUntil then return false end
                    local n, at, where = eliteUp()
                    E.sideElite = n and { n, at, where } or nil
                    return n ~= nil
                end,
                step = function(myEpoch)
                    local t = E.sideElite
                    eliteFight(t[1], t[2], t[3], myEpoch)
                end,
            },
        }
        -- the primary's own kind: a hunt picked as the primary is never also a secondary
        local function primaryKind() return CFG.Hunt and CFG.HuntKind or nil end
        P.side = {}
        -- ids = this call's part of the fixed order. -> true = a secondary ran this step.
        function P.side.step(ids)
            local id = sideNext(ids, CFG.Side, function(x)
                local ok, yes = pcall(SIDE[x].ready)
                return ok and yes == true
            end, primaryKind())
            if not id then
                if P.sideNow and table.find(ids, P.sideNow) then
                    print("[BFF] secondary: " .. SIDE_TITLE[P.sideNow] .. " done - back to your mode")
                    P.sideNow = nil
                end
                return false
            end
            if P.sideNow ~= id then
                print("[BFF] secondary: " .. SIDE_TITLE[id] .. " is up here - it goes first")
                P.sideNow = id
            end
            local ok, err = pcall(SIDE[id].step, epoch)
            if not ok then print("[BFF] secondary " .. id .. ": " .. tostring(err)) task.wait(0.5) end
            return true
        end
```

- [ ] **Step 4: Run all checks** (commands in the header). Expected: 49 pass (the factory hooks are not called yet: `P.factory.sideReady` comes in Task 3 and `P.side.step` is not wired until Task 4), checks clean, compile-ok. If `checks.py` reports `CFG.Side` unknown, the CFG key from Step 1 is missing.

- [ ] **Step 5: Commit**

```bash
git add fast_farm.lua
git commit -m "Secondary modes: the Fruit and Elite engine (P.side), no hop

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Factory as a secondary

**Files:**
- Modify: `fast_farm.lua` — inside the `FACTORY: STAY AND SWING` block, just before `    function P.factorySet(on)`.

- [ ] **Step 1: Add the two hooks**:

```lua
    -- AS A SECONDARY (SECONDARY MODES): the raid is up = the Core alive in
    -- workspace.Enemies, Second Sea. Its step: over the Core (12 up, where
    -- the reach covers it), held there by the farm's own hold, one swing a
    -- step. The first time, the Core is told in the console - the stand
    -- spot is fixed from what it says.
    function F.core()
        local folder = workspace:FindFirstChild("Enemies")
        local m = folder and folder:FindFirstChild("Core")
        local hum = m and m:FindFirstChildOfClass("Humanoid")
        local root = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart"))
        if hum and root and hum.Health > 0 then return m, root, hum end
        return nil
    end
    function F.sideReady()
        if mySea() ~= 2 then return false end
        return F.core() ~= nil
    end
    function F.sideStep(myEpoch)
        local m, root = F.core()
        if not m then return end
        if not F.told then
            F.told = true
            local ok, size = pcall(function() return m:GetExtentsSize() end)
            print(string.format("[BFF] factory core: %s at (%.1f, %.1f, %.1f), size %s, root %s",
                m:GetFullName(), root.Position.X, root.Position.Y, root.Position.Z,
                ok and tostring(size) or "?", root.Name))
        end
        local spot = root.Position + Vector3.new(0, 12, 0)
        local _, r = parts()
        if r and (r.Position - spot).Magnitude > 20 then
            say("factory raid: to the Core")
            flyTo(spot)
            if stale(myEpoch) then return end
        end
        lockAt(spot, root.Position)
        pcall(F.step)
        say("factory raid: " .. tostring(F.note))
        task.wait(math.max(tonumber(CFG.FactoryEvery) or 0.06, 0.03))
    end
```

- [ ] **Step 2: Run all checks.** Expected: 49 pass, checks clean (`hoistcheck` confirms `flyTo`, `lockAt`, `mySea`, `stale` are declared above this block), compile-ok.

- [ ] **Step 3: Commit**

```bash
git add fast_farm.lua
git commit -m "Secondary modes: the factory raid - over the Core, held, swinging

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Into the main loop, and Home's status

**Files:**
- Modify: `fast_farm.lua` — `local function step()` (MAIN LOOP); Home's live line (`detail.Text = string.format("%s · %d kills ...`); the "no mode on" branch of `step()`.

- [ ] **Step 1: Wire the step** — replace:

```lua
    -- The volcano event goes before every mode while its island is up.
    if not off and P.sea and P.sea.volcanoStep() then return end
```

with:

```lua
    -- SECONDARY MODES, in the fixed order: fruit, factory, the volcano event
    -- (its island up), elite - then the primary.
    if not off and P.side and P.side.step({ "fruit", "factory" }) then return end
    -- The volcano event goes before every mode while its island is up.
    if not off and P.sea and P.sea.volcanoStep() then return end
    if not off and P.side and P.side.step({ "elite" }) then return end
```

- [ ] **Step 2: No primary, secondaries on: wait for them** — in the same function replace:

```lua
        if CFG.Volcano then
            say("no mode on - waiting for the volcano event")
```

with:

```lua
        local sideOn = type(CFG.Side) == "table" and (CFG.Side.fruit or CFG.Side.factory or CFG.Side.elite)
        if CFG.Volcano or sideOn then
            say("no mode on - waiting for a secondary's event")
```

- [ ] **Step 3: Let Start run with only secondaries on** — in `function P.start()` replace:

```lua
    if not (CFG.Circuit or CFG.Hunt or CFG.RandomMode or CFG.RaidMode or CFG.LeviFight or CFG.Volcano) then
```

with:

```lua
    local sideOn = type(CFG.Side) == "table" and (CFG.Side.fruit or CFG.Side.factory or CFG.Side.elite)
    if not (CFG.Circuit or CFG.Hunt or CFG.RandomMode or CFG.RaidMode or CFG.LeviFight or CFG.Volcano or sideOn) then
```

- [ ] **Step 4: Home names a running secondary** — replace:

```lua
                detail.Text = string.format("%s · %d kills · %.0f/min · %s",
                    state, stats.kills, stats.kills / mins, statusLine)
```

with:

```lua
                local side = P.sideNow and P.SIDE_TITLE and P.SIDE_TITLE[P.sideNow]
                detail.Text = string.format("%s%s · %d kills · %.0f/min · %s",
                    side and (side .. " (secondary) · ") or "", state, stats.kills, stats.kills / mins, statusLine)
```

- [ ] **Step 5: Run all checks.** Expected: 49 pass, clean, compile-ok.

- [ ] **Step 6: Commit**

```bash
git add fast_farm.lua
git commit -m "Secondary modes: before the primary in the main loop; Home names it

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The Modes page — ALONGSIDE

**Files:**
- Modify: `fast_farm.lua` — the Modes page block that starts `if P.packState("volcano") == "open" then` / `heading2(v, "alongside any mode")`.
- Modify: `tools/panel_cases.lua` — `NEW_OK` gets the three new keys.

- [ ] **Step 1: Write the failing test** — in `tools/panel_cases.lua`, add to `NEW_OK` after the `Factory = true, ...` line:

```lua
    ["Side.fruit"] = true, ["Side.factory"] = true, ["Side.elite"] = true,  -- 2026-11-27: secondary modes
```

and, after the `NEW_OK` loop's checks, add:

```lua
-- 2026-11-27: the Modes page switches every secondary
for _, k in ipairs({ "Side.fruit", "Side.factory", "Side.elite" }) do
    check(have[k], "the Modes page switches CFG." .. k)
end
```

- [ ] **Step 2: Run it to see it fail**

Run: `python tools/panel_test.py 2>&1 | grep -E "FAIL|passed"`
Expected: three `FAIL the Modes page switches CFG.Side.*`.

- [ ] **Step 3: Implement** — replace the block:

```lua
        if P.packState("volcano") == "open" then
            heading2(v, "alongside any mode")
            rows({ { "Volcano event", "when Prehistoric is up", "volcano", function()
                if CFG.Volcano then return "On", true end
                return "Off"
            end } })
        end
```

with:

```lua
        -- SECONDARY MODES (user, 2026-11-27): beside your mode, each only when
        -- its event is up on this server - never a hop. Fixed order: fruit,
        -- factory, the volcano event, elite. A pack this key does not hold:
        -- no row.
        heading2(v, "alongside · when it is up here")
        local function sideRow(id, label, sub)
            if P.packState(id) ~= "open" then return end
            switchRow(v, label, sub,
                function() return CFG.Side[id] == true end,
                function(x) CFG.Side[id] = x and true or false end)
        end
        sideRow("fruit", "Fruits", "a fruit spawns here: stored, then back")
        sideRow("factory", "Factory raid", "the Core is up: hit until it breaks")
        if P.packState("volcano") == "open" then
            rows({ { "Prehistoric + Volcano", "the island is up: the event", "volcano", function()
                if CFG.Volcano then return "On", true end
                return "Off"
            end } })
        end
        sideRow("elite", "Elite pirates", "one is alive here: fought (often up)")
```

- [ ] **Step 4: Run it to see it pass**

Run: `python tools/panel_test.py 2>&1 | grep -E "FAIL|passed"`
Expected: `N passed, 0 failed`. If a rule fires on `CFG.Side.*` being written from more than one page, add the three keys to `MANY` in `tools/panel_cases.lua` beside `Factory = true`.

- [ ] **Step 5: Run all checks.** Expected: 49 pass, clean, compile-ok.

- [ ] **Step 6: Commit**

```bash
git add fast_farm.lua tools/panel_cases.lua
git commit -m "Secondary modes: the Modes page's ALONGSIDE switches

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Build, push

- [ ] **Step 1: Bump the build** — in `fast_farm.lua` the line `local P = { running = false, ... build = "2026-11-27.4" }`: change to `"2026-11-27.5"`.

```bash
sed -i 's/build = "2026-11-27.4"/build = "2026-11-27.5"/' fast_farm.lua && grep -c 'build = "2026-11-27.5"' fast_farm.lua
```
Expected: `1`.

- [ ] **Step 2: Run all checks.** Expected: 49 pass, clean, compile-ok.

- [ ] **Step 3: Commit and push** (a push is a live deploy: the running farm takes it at its next hop)

```bash
git add fast_farm.lua
git commit -m "Build 2026-11-27.5: secondary modes - fruit, factory raid, elite beside your mode

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push -q origin main && git log --oneline -3
```

- [ ] **Step 4: In game (user)** — Circuit + Fruits secondary: a spawned fruit is stored, the console shows `[BFF] secondary: Fruit is up here` then `... done - back to your mode`, the circuit's quest is kept. Factory secondary in the Second Sea during the raid: `[BFF] factory core: ...` printed once, the Core broken, back to the circuit. Send the `factory core` line: the stand spot (12 up) is fixed from it.
