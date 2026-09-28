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
| How far one can be pulled | Nobody publishes how far the game lets an enemy be dragged from its spawn before it stops taking damage (hubs pull within 250-350 and put back after 3 s of no damage). "Pull at most, from their spawn" (300, Magnet page) caps it; **a camp wider than that is piled one side at a time** (the side nearest you, then the other when it is empty) - Port Town's Pistol Billionaires spawn ~550 studs across at heights 74-147 (39 public hub files). "Learn how far each kind can go": a pulled one that stops taking damage while one pulled from nearer its spawn in the same pile still takes it sets that kind's limit (no contrast = maybe not ours to move = nothing learned). The Magnet page shows what it measured. |
| Lock | your body is written every frame to a spot over the pile: **"High, over the pile" (up to 150) counted from the HIGHEST living enemy in it** (one the magnet does not own stays up on its ledge, and you still stay that far over it). **"Always stay above them" (on by default): never down to the close spot** — every attack is fired from that height, and the remote hit reaches that far (a 60 reach at 60 up used to name nobody). Off: close beside the pile for key presses and fighting-style / sword skills. A Kitsune lunge is undone the same frame. |
| Noclip | every part stops colliding before each physics step while running. The body is always held, so it never falls through anything. |
| Travel | under 150 studs: one jump. Further: a straight flight at 330 studs/s (slider). "Pulled back" on the Travel page counts server corrections. Submerged Island: the Tiki submarine. |
| M1 | tried against the pile, kept per weapon if it takes HP off: remote hit (`RE/RegisterAttack` + `RE/RegisterHit` naming the whole pile), fruit click (`tool.LeftClickRemote`), key press. |
| Combo | per-weapon switches M1 Z X C V F + hold time per key (**all skills are off until you switch them on**). Ready skills read off `PlayerGui.Main.Skills[weapon][key].Cooldown`. "M1 swings between skills" and "Start with" set the rhythm. After each cast the bar is read again: "fired" or "key sent, the skill did NOT fire" (Attack page, Stats). Skill cooldowns live on the server and cannot be removed. |
| Aim lock | Skills fire down the line from the camera through the cursor. **Camera free (default):** a frame goes input → camera update → drawn → physics → Heartbeat → next input; the camera between Heartbeat and the next camera update is never drawn, but a key sent then is read in it. So at Heartbeat the camera is solved onto the pile (yaw + pitch, exact, for your cursor's pixel) and just before the camera update your saved view goes back — your screen and the camera script only ever see your own view. Every cast reports **hit or MISSED** (pile HP before/after) per skill. **Camera free off:** the view itself turns so the pile is under your cursor. |
| Quest circuit | farm_pro's engine and farm_pro's giver switch — **Never (default): you are never moved for a quest.** The circuit flies to the camp, then asks from there (tier probed + locked, tracker read, never re-ask during a running count). Tracker unreadable = the quest is still running, its kills are counted here with the exact count from the game's quest data. Auto / Always go to the giver (First Sea giver spots included). One quest at a time; A → B → … and back. |
| Quest bosses | 24 quest bosses from the game's own quest data (ids, tiers, levels), all three seas; renamed ones (Fajita→Orbitus, Bobby→Chef, Island Empress→Hydra Leader) accept either name. **Up** = loaded near you, or parked by the game in ReplicatedStorage while far from players (how the hubs check); neither = not spawned. The quest is taken only while it is up (tier 3 mostly, one kill, from where you stand). Not up: the rest of the circuit (a held boss quest is dropped so the others can run), or — nothing else to fight — a wait over its spawn for as long as it takes. "Bosses first" (Quest page): a boss that is up goes next, between quests. Under its level: fought without the quest, and the panel says the level. Targets page lists this sea's bosses: up / up, here / not spawned. |
| Raid mode | Home page switch. Species and quests forgotten: **every living enemy, any kind**, within "Raid mode pulls within" (450, Magnet page) of the newest raid island goes in one pile, killed the usual way (magnet, aim lock, combo). The raid is read the way the public raid scripts read it (2025-07, 2026-08): timer `PlayerGui.Main.TopHUDList.RaidTimer` (older `Main.Timer`), islands `workspace._WorldOrigin.Locations["Island 1".."Island 5"]`, newest = highest number. Island empty = hover 45 over it for the wave / the next island. Outside a raid it pulls everything within the radius of you. Observation is never pressed (raids switch it off); Enhancement still is. Start the raid yourself (chip + button). |
| Random mode | Home page switch (turns raid mode off). Quests forgotten; **every living enemy of any kind within "Random mode reaches" (750) of you, and every one damaged.** At the Castle on the Sea (Third Sea) the area is the pirate raid's own: the game tags mobs `BasicMob`, and a raid pirate is one that appears within 750 of (-5556, 314, -2988) (redz module 2025-10; a 2026-09 hub goes to (-5128, 314, -2957) when farther than 1000); raid every ~1 h 15. Guarantee: (1) pulled only within each kind's pull limit (MaxPull / measured) - a far or diagonal group gets its own pile next; (2) one that took no damage when pulled is fought where it stands once the free ones are done; (3) no damage from the height in 6 s = down close for it, whatever "Always stay above" says; (4) none in 15 s even close = cannot be hurt by this setup: left a minute and counted on the panel. |
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
python tools/locate_test.py                      # where a species is + the pile, real code, 40 scenarios (Sky Bandit, new spawns, raid pile, sides, random mode)
python tools/raid_test.py                        # raid mode's view of the game: both timer paths, newest Island N
python tools/pose_test.py                        # where you hang + the remote hit's reach, real code: Port Town, ledge, 120 up, stay above
python tools/leash_test.py                       # checkPutBack: pull limit measured (contrast rule), random mode's in-place escalation
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
