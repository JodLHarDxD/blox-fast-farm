# blox-fast-farm

`fast_farm.lua` — the loud, fast Blox Fruits farm. Magnet pile, noclip, fast
travel, multi-target remote hits, a per-weapon combo, a species circuit
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

## Executor: Velocity (since 2026-09-30)

Solara was removed: since 2026-09-29 the client freezes and closes on every
join with it attached (the game's own teleports too, no script needed). Wave
was tried next and removed: it has no free tier (every plan is a paid
license). Velocity (getvelocity.llc, the product "Roblox", NOT "Roblox
(External)", which is an aimbot/ESP tool) is free with a 48-hour key from
getvelocity.llc/keysystem and needs the .NET 10 Desktop Runtime. Its docs list
every function this script can use: `queue_on_teleport` (the hop carry-over),
`getrenv` / `getsenv` (the game's own hit sender), `fireproximityprompt`
(berries), `firetouchinterest` (fruits), `sethiddenproperty`,
`readfile` / `writefile`.

| What | Where |
|---|---|
| Velocity | `D:\Velocity` (`VelocityLite.exe`; excluded from Windows Defender) |
| The loader above, saved | `D:\Velocity\Scripts\fast_farm.lua` |
| Hop files, `fruit_probe.txt` | `D:\Velocity\Workspace` |
| `autoexec_team.lua` (team at every join) | `D:\Velocity\AutoExec\bff_team.lua` |
| Installers | `D:\scripting` (.NET 9 Desktop, Bloxstrap); Velocity's archive is `D:\Velocity.7z` |

No autoexec loader is needed: Velocity has `queue_on_teleport`. The Hunt page's
"after a hop" line confirms it; the M1 page's "hits sent by" line says whether
the game's hit sender was reached.

The script comes back by itself only after a hop IT made (a hunt's hop, the
panel's "Hop now"). A hop through the game's own server menu, or a fresh join,
arrives without it -- so `autoexec_team.lua` sits in the executor's autoexec
folder: at every Blox Fruits join it asks for Pirates (`TEAM` at its top) until
you are on a team, then hides the team screen; the console says
`[BFF] autoexec team: on Pirates`. It never loads the farm, does nothing in
other games, and never switches a team you are on.

## What each part does

| part | how |
|---|---|
| Finding the camp | farm_pro's rule: every LOADED enemy of the species counts, wherever it stands; the one nearest you picks the camp. Travel goes to a loaded one, else the game's own spawn points (`_WorldOrigin.EnemySpawns`), else enemies the game parked in ReplicatedStorage, and only then the level table (12 of its points were corrected against three hubs). The Targets page says which source each camp came from. |
| Magnet | **Every loaded enemy of the species, any distance** ("Pull every one loaded", on by default). Looked for again 10×/s from the frame loop, so one that spawns mid-fight joins the pile at once, even during a cast. The pile sits at the camp's middle: the centre of the smallest circle round its spawn points (game's `EnemySpawns`, else spots seen) — the spot where the farthest pull is shortest, so every one stays inside its own area. SimulationRadius raised; every frame each is written to a ring there, velocity zeroed, knockback removed. Held + hit with no HP change for 3 s = put back, left alone 30 s. |
| How far one can be pulled | Nobody publishes how far the game lets an enemy be dragged from its spawn before it stops taking damage (hubs pull within 250-350 and put back after 3 s of no damage). "Pull at most, from their spawn" (300, Magnet page) caps it; **a camp wider than that is piled one side at a time** (the side nearest you, then the other when it is empty) - Port Town's Pistol Billionaires spawn ~550 studs across at heights 74-147 (39 public hub files). "Learn how far each kind can go": a pulled one that stops taking damage while one pulled from nearer its spawn in the same pile still takes it sets that kind's limit (no contrast = maybe not ours to move = nothing learned). The Magnet page shows what it measured. |
| Lock | your body is written every frame to a spot over the pile: **"High, over the pile" (up to 150) counted from the HIGHEST living enemy in it** (one the magnet does not own stays up on its ledge, and you still stay that far over it). **"Always stay above them" (on by default): never down to the close spot** — every attack is fired from that height, and the remote hit reaches that far (a 60 reach at 60 up used to name nobody). Off: close beside the pile for key presses and fighting-style / sword skills. A Kitsune lunge is undone the same frame. |
| Noclip | every part stops colliding before each physics step while running. The body is always held, so it never falls through anything. |
| Travel | under 150 studs: one jump. Further: a straight flight at 330 studs/s (slider). "Pulled back" on the Travel page counts server corrections. Submerged Island: the Tiki submarine. |
| M1 | tried against the pile, kept per weapon if it takes HP off: remote hit (`RE/RegisterAttack` + `RE/RegisterHit` naming the whole pile), fruit click (`tool.LeftClickRemote`), key press. |
| Combo | per-weapon switches M1 Z X C V F + hold time per key (**all skills are off until you switch them on**). Ready skills read off `PlayerGui.Main.Skills[weapon][key].Cooldown`. "M1 swings between skills" and "Start with" set the rhythm. After each cast the bar is read again: "fired" or "key sent, the skill did NOT fire" (Attack page, Stats). Skill cooldowns live on the server and cannot be removed. |
| Aim lock | Skills fire down the line from the camera through the cursor. **Camera free (default):** a frame goes input → camera update → drawn → physics → Heartbeat → next input; the camera between Heartbeat and the next camera update is never drawn, but a key sent then is read in it. So at Heartbeat the camera is solved onto the pile (yaw + pitch, exact, for your cursor's pixel) and just before the camera update your saved view goes back — your screen and the camera script only ever see your own view. Every cast reports **hit or MISSED** (pile HP before/after) per skill. **Camera free off:** the view itself turns so the pile is under your cursor. |
| Circuit (Targets page) | The species you pick, in your order: pile, kill, next species; alone, it waits for the respawn ("One species alone: wait for it", 45 s). Nothing picked = the species for your level. Another sea's species is skipped and named. **No quests** - the level-quest engine was removed 2026-09-28 (max level; git tag `quest-engine-2026-09-28` has it). **Bosses:** 24 from the game's data, all seas, renamed ones accept either name; **up** = loaded near you or parked by the game in ReplicatedStorage; not up = the rest of the circuit, or a wait over its spawn when it is alone. "Bosses first" (Targets page): one that is up goes next. Use it for the Dough King road: Cake Island species for the 500 kills, Cocoa Warrior / Chocolate Bar Battler for Conjured Cocoa. |
| Raid mode | Home page switch. Species and quests forgotten: **every living enemy, any kind**, within "Raid mode pulls within" (450, Magnet page) of the newest raid island, killed the usual way (magnet, aim lock, combo). **Stuck wave fixed (2026-09-28):** every one within the radius is pulled (raid enemies have no leash - they roam the island to reach you). One that takes no damage is no longer put back and LEFT OUT (that left the wave stuck with it alive while the farm hovered - "2 of 5 never hurt"): once the free ones are dead it is fought where it stands, from close if high does not hurt it. **Why it took no damage is written down** the moment it happens (Magnet page, "why no damage"): NOT OURS (the magnet moves it only on your screen) / OUT OF REACH / SHIELDED / its place in the pile. The readout says "one fought where it stands" / "could not hurt N". The raid is read the way the public raid scripts read it (2025-07, 2026-08): timer `PlayerGui.Main.TopHUDList.RaidTimer` (older `Main.Timer`), islands `workspace._WorldOrigin.Locations["Island 1".."Island 5"]`, newest = highest number. Island empty = hover 45 over it for the wave / the next island. Outside a raid it pulls everything within the radius of you. Observation is never pressed (raids switch it off); Enhancement still is. Start the raid yourself (chip + button). |
| Random mode | Home page switch (turns raid mode off). Quests forgotten; **every living enemy of any kind within "Random mode reaches" (750) of you, and every one damaged.** At the Castle on the Sea (Third Sea) the area is the pirate raid's own: the game tags mobs `BasicMob`, and a raid pirate is one that appears within 750 of (-5556, 314, -2988) (redz module 2025-10; a 2026-09 hub goes to (-5128, 314, -2957) when farther than 1000); raid every ~1 h 15. Guarantee: (1) pulled only within each kind's pull limit (MaxPull / measured) - a far or diagonal group gets its own pile next; (2) one that took no damage when pulled is fought where it stands once the free ones are done; (3) no damage from the height in 6 s = down close for it, whatever "Always stay above" says; (4) none in 15 s even close = cannot be hurt by this setup: left a minute and counted on the panel. |
| Hunt | **Four switches, one hunt at a time** (Home and Hunt page; one on turns the others off, and raid / random off): **Elite pirate hunt**, **Fruit hunt**, **Berry hunt**, **Aura recipe hunt**. The hunt you switch on does only that, then the next server - nothing is ranked or picked for you, and nothing breaks off an elite fight. **Fruit hunt** (any sea): the whole server's fruits are seen from anywhere (a Tool in workspace, `OriginalName` = "Kitsune-Kitsune"); worth it = the game's own price (GetFruits) at least your minimum (0 = any), dearest first; player drops (the game tags them `DroppedBy`) only with "Include fruits players dropped" on - off by default, drops are mostly trades - and never while the dropper stands by it. Flown onto, touched, put away at once (never in your hand) and **stored** with StoreFruit; not stored = said so. **Berry hunt** (any sea; the Haki colors): every bush the game tags `BerryBush`, a bush's attribute values = the berries on it; a switch per berry (the Legendary Aura colors: **Winter Sky 15 Pink Pig, Snow White 10 White Cloud, Pure Red 15 Red Cherry**, + 7,500 fragments at the Barista). Nearest wanted bush, flown to, each berry's ProximityPrompt **held like a player holds E** (InputHoldBegin, the prompt's own HoldDuration, InputHoldEnd) - the executor's `fireproximityprompt` only every third try: it triggers instantly, skipping the hold, and the game can refuse that (on Velocity about half the berries were never picked until 2026-09-30). ~15 s while the berry is still there; **PICKED** = your inventory count (`getInventory`) went up, and the console says `[BFF] berry: PICKED ... (by hold, try 1)`. A kind you hold 99 of is not wanted; a bush it could not pick is left a minute. At most 4 berries in a server, a new one every 15 min. **Aura recipe hunt** (Second and Third Sea): the **Barista Cousin** teaches ONE recipe per server (he comes 20 min after a server starts, stays 20, is gone 2). `CommF_:InvokeServer("ColorsDealer", "1")` names it (and a rarity, 3+ = Legendary) from anywhere - no flight to find out; not him or not a recipe you switched on = the next server. One you picked: `("ColorsDealer", "2")` learns it from where you stand, else from in front of him (`workspace.NPCs["Barista Cousin"]`); learned = its switch goes off and the hunt goes on for the others; all learned = stops. Not learned (fragments, **Aura stage 5** = the "Iron Man" title) = the hunt stops and says why. A switch per recipe, the three Legendary first (Winter Sky, Snow White, Pure Red - rip_indra's buttons need all three; switch off the ones you have). **Elite pirate hunt** (Third Sea): **Diablo, Deandre, Urban** (and Tyrant of the Skies while he is up) - one per server, back 8 min 45 s after the last one died; only the **last hit** gets the drops, God's Chalice among them. **Up** = loaded near a player or parked by the game in ReplicatedStorage, or the Elite Hunter (the cat at the Castle on the Sea, `CommF_:InvokeServer("EliteHunter")`) answers with a name. Up: its quest (a different running quest is dropped; if asking from where you stand gets no answer, once per server from in front of the Elite Hunter), flight, the fight where it stands - never pulled. Down: 4 s look for the chalice, progress read, then it is not looked for in this server for 8 min. **Nothing for the hunt here** (3 s after a join at least; elites: 3 s when the Elite Hunter says none, else "Look for" 8 s): the next server, or with hop off, wait. |
| Team | Every new server asks **Pirates or Marines** before your character spawns - so every hop. "Pick my team on join" (Hunt page, after a hop; on, **Pirates** by default) answers it: `CommF_:InvokeServer("SetTeam", team)` (the public hubs, 2026-04 .. 2026-09-29), every 2 s until you are on one. Not the screen's button through `getconnections` - removed 2026-09-30: firing a game's connections natively is a call an executor can crash on. Only while you have no team - the team you are on is never switched. Runs after the carried settings, so the next server gets the team you picked, not the default. |
| Server hop | The game's own server browser, `ReplicatedStorage.__ServerBrowser` (what its Servers menu calls): `InvokeServer(page)` → `{ [JobId] = { Count, Region } }`, `InvokeServer("teleport", JobId)`. List empty → the Roblox list (`games.roblox.com/v1/games/<place>/servers/Public`). **The join is always the game's** (`"teleport"`: its server starts the teleport), whichever list the server came from: the Third Sea takes only server-started teleports (Roblox "Secure within universe"), and a join started on your client (`TeleportToPlaceInstance`) is refused - "Cannot teleport without a valid teleport token (Unauthorized)" (seen in game 2026-09-28). That one is tried only with no `__ServerBrowser`, and not again in that server once refused. Why a list or a join failed: the Hunt page ("servers", "last join") and the console (`[BFF] hop: ...`). Not this server, not full, not looked at in "Try a server again after" (10 min); **fewest players first** (or any order). Five tries a round, three rounds. Your settings, the servers looked at and the counts go to the next server in the reload queued with `queue_on_teleport` **and** in `workspace/bff_elite_hop_<your UserId>.json` (one file per account - two accounts never share settings); the next copy starts the hunt by itself (only within 5 min of the hop, only if it was running). |
| **The chalice** | **God's Chalice in your backpack or hand = the hunt is over in that server, for good.** Leaving the server or dying with it loses it, so every hop refuses - checked on every step, and again right before each teleport call (a drop that lands while the server list is being read still stops it). You are flown 300 up and held there; the next server's copy is told not to start. Turning the hunt off and on does not re-arm hopping in that server. Stop gives you the character back. |
| **Fruit guard** | A physical fruit ("Kitsune Fruit", or anything with an `EatRemote`) is **never a weapon**: never listed on the Attack page, never equipped, and **nothing is clicked while one is in your hand** (it is put away) - a click with a fruit held EATS it and replaces yours. Your eaten fruit's power ("Kitsune-Kitsune") is a weapon as always. |
| Safety | under 35 % HP: fly 250 up, wait for 80 %. Enhancement (J) + Observation (E) kept on. No real god mode exists — health is server-side. |
| Stats | kills per minute of FIGHTING and average pile time for the current attack setup; changing any attack switch files it under "tried" so setups can be compared. |

## Elite hunt without queue_on_teleport

The **Elite hunt** page says whether your executor has `queue_on_teleport`.
If it does not, save this in the executor's `autoexec` folder. It loads the
farm only when a hunt hopped you here (the file says so), so it stays out of
the way the rest of the time:

```lua
repeat task.wait() until game:IsLoaded()
local ok, s = pcall(readfile, "bff_elite_hop_" .. game.Players.LocalPlayer.UserId .. ".json")
if ok and type(s) == "string" and s:find('"resume":true', 1, true) then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/fast_farm.lua?cb=" .. tick()))()
end
```

Having both is harmless: a second copy replaces the first and the join is
counted once.

## First hunt test

1. **Elite hunt** page, "Elite Hunter" line after the first look: the words it
   got back from `CommF_:InvokeServer("EliteHunter")` far from the NPC. Words =
   it answers from anywhere. "unknown" + a flight to the Elite Hunter = it
   only answers up close.
2. "servers" line after the first hop: "N listed … the game's server browser"?
   ("the Roblox server list - <why>" = `__ServerBrowser` gave no list; the
   why says missing / its page 1 failed / what page 1 came back as.) "last
   join": the game's words for a refused join. Both also print in the console
   as `[BFF] hop: ...`.
3. "after a hop" line: queue_on_teleport yes / no. After the first hop, does
   the panel come back by itself and say "elite hunt carried over"?
4. After ~20 joins: "had one N (x%)" and "join Ns" - the real numbers the
   speed estimate (~2 min per elite) was guessed from.
5. When one is up far away: does it fly straight to it ("parked by the game")?
6. **Fruits:** Hunt page, "fruits on the ground" - the list of what is lying in the server (name, price, server spawn / dropped by). When it goes for one: does "last" end in STORED? If it says "NOT stored", send the words in brackets (inventory full? already stored?).
7. **Berries:** switch on **Berry hunt**. Hunt page, "berry hunt" - does it list what is on the bushes here (e.g. "Pink Pig Berry   820 studs")? "on the bushes here: none" in every server = the `BerryBush` tag or its attributes changed. When it goes for one: "PICKED ..." = done. "gone from the bush, your count did not go up" = picked but `getInventory` did not show it (send the words); "could not pick in N tries" = neither the hold nor the instant fire was taken (send the console's `[BFF] berry:` lines); "(no prompt on the bush)" = the berry's prompt moved.
8. Switch between the three hunts mid-fight: the elite fight should stop at once when Elite pirate hunt goes off.
11. **Team:** after a hop, does the Pirates / Marines screen go away by itself? Hunt page "team" line: "on Pirates" = done. "asking for Pirates ..." that never ends = send a screenshot of the screen (its buttons moved).
10. **Aura recipe hunt:** switch off the recipes you already have (Snow White, Pure Red), leave Winter Sky on, switch on **Aura recipe hunt**. The Hunt page "here" line says what the Barista Cousin teaches in each server ("he is not here now" in young servers - under 20 min old). When it is Winter Sky: "Winter Sky: learned" = done. "NOT learned - <words>" = send the words (the game's own answer code is in them).
9. **Elite not taking damage** (it was all-or-nothing per server): the console prints `[BFF] hits: <sender>  ·  COMBAT_REMOTE_THREAD = <true/false/nil>` once per server, and `[BFF] M1 <weapon>: <way>` after each probe. Send those lines from a server where it hit and one where it did not. The M1 page shows the same ("hits sent by", "this server's COMBAT_REMOTE_THREAD").

## First in-game test (each answer decides the next fix)

1. **Attack** page, "how M1 lands": which way does each weapon say — remote hit / fruit click / key press / nothing landed?
2. **Magnet** page: "held N · staying put N" and "farthest pull N studs". When new ones spawn mid-fight, do they fly into the pile at once? Does "put back" climb (= some were dragged out of their area)?
2b. **Attack** page: switch on Z/X/C for a weapon. Under "last skill" each skill shows "hit N of M". Look around and move your cursor freely while it casts — do the counts say hit? A skill that keeps saying MISSED reads the aim at a moment the hidden swap does not cover: switch "Keep my camera free" off and compare.
3. **Travel** page: does a long flight arrive? Any "pulled back"? (lower the speed if so)
4. **Targets**: two species on the circuit - does it go A → B → A without stopping? (No quests any more.)
5. **Attack** → a weapon: do the skill states (ready / 3.1s) match your hotbar?
6. **Stats**: three setups a few minutes each on one camp — do the kills/min differ?

## Checks (run after every edit)

```
luau-compile.exe --binary fast_farm.lua          # parses
luau-analyze.exe fast_farm.lua                   # filter "Unknown global", "SameLineStatement", "Unknown type 'Instance'"; the new solver now hits its budget ("inference failed to complete") - lints still run
luau-analyze.exe --solver=old fast_farm.lua      # the full type check; only "Key 'start' / 'fruitWanted' not found in table 'P'" (both set later in the file, nil-checked where used)
python tools/checks.py fast_farm.lua             # every CFG/stats/P field defined; no local used above its declaration
python tools/rhythm_test.py                      # the combo rhythm, real code, 9 scenarios
python tools/circuit_test.py                     # the circuit, real code: your level's species, another sea skipped + named, your order kept
python tools/locate_test.py                      # where a species is + the pile, real code, 40 scenarios (Sky Bandit, new spawns, raid pile, sides, random mode)
python tools/raid_test.py                        # raid mode's view of the game: both timer paths, newest Island N
python tools/pose_test.py                        # where you hang + the remote hit's reach, real code: Port Town, ledge, 120 up, stay above
python tools/probe_test.py                       # the M1 probe, real code: the game's own hit sender tried first; "nothing landed" tried again after 12 s, not final for the server
python tools/team_test.py                        # the team pick, real code: SetTeam until on a team, the screen's button never fired, Marines when picked, never a switch, off = nothing
python tools/berry_test.py                       # the berry pick, real code: a real hold first (a game refusing the instant fire still gets picked), fireproximityprompt as the fallback, ~15 s then left a minute, taken by another = out at once, a stop = out at once
python tools/autoexec_test.py                    # autoexec_team.lua, real file: Pirates at every join, other games untouched, never a switch, a minute at most, place read after load, call errors survived
python tools/leash_test.py                       # checkPutBack: pull limit measured (contrast rule), random mode's in-place escalation
python tools/aim_test.py                         # the aim lock's camera solve, real code, every cursor pixel lands on the pile
python tools/hidden_test.py                      # camera-free aim, real camera block in a simulated frame loop: drawn = your view, keys see the aim
python tools/fruitguard_test.py                  # the fruit guard, real code: never a weapon, never equipped, no click with one in hand
python tools/elite_test.py                       # the hunt, real code, 95 checks: Elite Hunter words, server pick, pickFruit (price, drops, traders), berries (names, nearest wanted), the Barista Cousin's recipe (not here / not picked / learned / cannot pay), hop() refusing on the chalice, the join (always the game's; a token refusal remembered; why in words), carry-over, the director (the chalice in every hunt; ONLY the hunt switched on)
```

The main chunk is at Luau's 200-local register limit: a new section goes in
a function of its own (see ELITE HUNT) with only what the rest needs exported.

The Luau tools live in `blox-scripts/tools/luau-0.735/`.

## Provenance

Built 2026-09-26. Lifted verbatim from farm_pro.lua (blox-scripts commit
0be796b): the level table, Enhancement + Observation keeper, walk on water + deep
sea, and the panel kit (made opaque: farm_pro's UIGradient made its background
94–100 % see-through). Everything else is new. `fast_farm.lua` is the source
from here on — edit it directly.
