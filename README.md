# blox-fast-farm

`fast_farm.lua` — the loud, fast Blox Fruits farm. Magnet pile, noclip, fast
travel, multi-target remote hits, a per-weapon combo, and a quest circuit
across several species.

**`farm_pro.lua` (in blox-scripts) is the human-like one for your main
account. This one is built to be fast, not to look human: flight, noclip,
hovering and enemies moved by your client are exactly what anti-cheat and
player reports look for. Use it on an account you can afford to lose.**

Loading it stops farm_pro and removes its panel (both drive the character).

## Run

Paste `fast_farm.lua` into the executor, or once this repo is on GitHub:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/fast_farm.lua?cb=" .. tick()))()
```

Then: **Targets** → tap the species for the circuit → **Attack** → tap each
weapon and switch on what it fires → **Start**.

```lua
_G.BFF.start()   _G.BFF.stop()   _G.BFF.config
```

## What each part does

| part | how |
|---|---|
| Finding the camp | farm_pro's rule: every LOADED enemy of the species counts, wherever it stands; the one nearest you picks the camp. Travel goes to a loaded one, else the game's own spawn points (`_WorldOrigin.EnemySpawns`), else enemies the game parked in ReplicatedStorage, and only then the level table (12 of its points were corrected against three hubs). The Targets page says which source each camp came from. |
| Magnet | **Every loaded enemy of the quest species, any distance** ("Pull every one loaded", on by default). Looked for again 10×/s from the frame loop, so one that spawns mid-fight joins the pile at once, even during a cast. The pile sits at the camp's middle: the centre of the smallest circle round its spawn points (game's `EnemySpawns`, else spots seen) — the spot where the farthest pull is shortest, so every one stays inside its own area. SimulationRadius raised; every frame each is written to a ring there, velocity zeroed, knockback removed. Held + hit with no HP change for 3 s = put back, left alone 30 s. |
| Lock | your body is written to a spot over the pile every frame: high (default 20 up) when the hit reaches from there, close beside it when it does not. A Kitsune lunge is undone the same frame. |
| Noclip | every part stops colliding before each physics step while running. The body is always held, so it never falls through anything. |
| Travel | under 150 studs: one jump. Further: a straight flight at 330 studs/s (slider). "Pulled back" on the Travel page counts server corrections. Submerged Island: the Tiki submarine. |
| M1 | tried against the pile, kept per weapon if it takes HP off: remote hit (`RE/RegisterAttack` + `RE/RegisterHit` naming the whole pile), fruit click (`tool.LeftClickRemote`), key press. |
| Combo | per-weapon switches M1 Z X C V F + hold time per key (**all skills are off until you switch them on**). Ready skills read off `PlayerGui.Main.Skills[weapon][key].Cooldown`. "M1 swings between skills" and "Start with" set the rhythm. After each cast the bar is read again: "fired" or "key sent, the skill did NOT fire" (Attack page, Stats). Skill cooldowns live on the server and cannot be removed. |
| Aim lock | Skills fire down the line from the camera through the cursor. **Camera free (default):** a frame goes input → camera update → drawn → physics → Heartbeat → next input; the camera between Heartbeat and the next camera update is never drawn, but a key sent then is read in it. So at Heartbeat the camera is solved onto the pile (yaw + pitch, exact, for your cursor's pixel) and just before the camera update your saved view goes back — your screen and the camera script only ever see your own view. Every cast reports **hit or MISSED** (pile HP before/after) per skill. **Camera free off:** the view itself turns so the pile is under your cursor. |
| Quest circuit | farm_pro's engine and farm_pro's giver switch — **Never (default): you are never moved for a quest.** The circuit flies to the camp, then asks from there (tier probed + locked, tracker read, never re-ask during a running count). Tracker unreadable = the quest is still running, its kills are counted here with the exact count from the game's quest data. Auto / Always go to the giver (First Sea giver spots included). One quest at a time; A → B → … and back. |
| Quest bosses | 24 quest bosses from the game's own quest data (ids, tiers, levels), all three seas; renamed ones (Fajita→Orbitus, Bobby→Chef, Island Empress→Hydra Leader) accept either name. **Up** = loaded near you, or parked by the game in ReplicatedStorage while far from players (how the hubs check); neither = not spawned. The quest is taken only while it is up (tier 3 mostly, one kill, from where you stand). Not up: the rest of the circuit (a held boss quest is dropped so the others can run), or — nothing else to fight — a wait over its spawn for as long as it takes. "Bosses first" (Quest page): a boss that is up goes next, between quests. Under its level: fought without the quest, and the panel says the level. Targets page lists this sea's bosses: up / up, here / not spawned. |
| Safety | under 35 % HP: fly 250 up, wait for 80 %. Enhancement (J) + Observation (E) kept on. No real god mode exists — health is server-side. |
| Stats | kills per minute of FIGHTING and average pile time for the current attack setup; changing any attack switch files it under "tried" so setups can be compared. |

## First in-game test (each answer decides the next fix)

1. **Attack** page, "how M1 lands": which way does each weapon say — remote hit / fruit click / key press / nothing landed?
2. **Magnet** page: "held N · staying put N" and "farthest pull N studs". When new ones spawn mid-fight, do they fly into the pile at once? Does "put back" climb (= some were dragged out of their area)?
2b. **Attack** page: switch on Z/X/C for a weapon. Under "last skill" each skill shows "hit N of M". Look around and move your cursor freely while it casts — do the counts say hit? A skill that keeps saying MISSED reads the aim at a moment the hidden swap does not cover: switch "Keep my camera free" off and compare.
3. **Travel** page: does a long flight arrive? Any "pulled back"? (lower the speed if so)
4. **Quest** page: what does the "last" line say after the first ask (ACTIVE / sent, tracker unreadable / refused)? Does the circuit go A → B → A without stopping?
5. **Attack** → a weapon: do the skill states (ready / 3.1s) match your hotbar?
6. **Stats**: three setups a few minutes each on one camp — do the kills/min differ?

## Checks (run after every edit)

```
luau-compile.exe --binary fast_farm.lua          # parses
luau-analyze.exe fast_farm.lua                   # filter "Unknown global", "SameLineStatement", "Unknown type 'Instance'"; the new solver now hits its budget ("inference failed to complete") - lints still run
luau-analyze.exe --solver=old fast_farm.lua      # the full type check; only "Key 'start' not found in table 'P'" (P.start is set before the panel is built)
python tools/checks.py fast_farm.lua             # every CFG/stats/P field defined; no local used above its declaration
python tools/rhythm_test.py                      # the combo rhythm, real code, 9 scenarios
python tools/quest_test.py                       # the quest engine, real code, 22 scenarios (never mode never moves you; boss quests, level gate, renamed boss, sea skip)
python tools/locate_test.py                      # where a species is + the pile, real code, 20 scenarios (Sky Bandit case, new spawns joining)
python tools/aim_test.py                         # the aim lock's camera solve, real code, every cursor pixel lands on the pile
python tools/hidden_test.py                      # camera-free aim, real camera block in a simulated frame loop: drawn = your view, keys see the aim
```

The Luau tools live in `blox-scripts/tools/luau-0.735/`.

## Provenance

Built 2026-09-26. Lifted verbatim from farm_pro.lua (blox-scripts commit
0be796b): the level / quest / giver tables, quest-giver scan, tracker reader,
quest dialog clicker, Enhancement + Observation keeper, walk on water + deep
sea, and the panel kit (made opaque: farm_pro's UIGradient made its background
94–100 % see-through). Everything else is new. `fast_farm.lua` is the source
from here on — edit it directly.
