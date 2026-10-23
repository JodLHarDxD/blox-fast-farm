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

**Which build is running:** the panel's title and the console's `[BFF] running - build ...` line (e.g. `2026-10-07.1`). A hop carries your settings only between copies of the **same** build - an older copy's would bring its old defaults with it.

Then: **Mode** → open what it should do (everything for it is on its page) →
**Attack** → your weapons → **Start** (it names the mode it starts).

```lua
_G.BFF.start()   _G.BFF.stop()   _G.BFF.config
```

**Clear it from the server and load it fresh** (same server, no rejoin):

```lua
if _G.BFF and _G.BFF.stop then pcall(_G.BFF.stop) end
_G.BFF = nil                      -- every loop / hook of the old copy lets go by itself
local hud = game.Players.LocalPlayer.PlayerGui:FindFirstChild("BFFHUD")
if hud then hud:Destroy() end
```

Then the loader above. **No panel?** The console says why (`[BFF] the panel failed to build: ...`, since build 2026-10-09.10); `_G.BFF.panel()` builds it again. Saved between loads: the sea event count (`bff_sea_events.json`) and learned keys (`bff_learn.json`); switches start at their defaults.

## The panel: where everything is (build 2026-10-11.3)

Three questions, one place each - nothing exists twice:

```
What is it doing?    the top of Home (and the top of every page) + Start / Stop
What should it do?   Mode -> the Modes list; each mode's page holds ALL its settings
                     FARM  Circuit farm · Random · Raid
                     HUNT  Elite pirates · Fruits · Haki berries · Aura recipe ·
                           Legendary swords · Fire Flower · Blaze Ember
                     SEA   Sea travel · Sea events · Prehistoric · Mirage · Leviathan
                     YOU FIGHT  PvP        ALONGSIDE ANY MODE  Volcano event
How does it fight?   FIGHT (every mode): Attack · Magnet · Position · Safety & haki
The rest             MORE: Travel & boat · Servers & team · Stats & debug
```

Every page has the same shape: what it is doing now, the mode's own switch,
sections, links to shared pages, then **How it works** (the long text) and
**Details** (learned tables, lists) - both closed, tap Show. **One mode at a
time**, and the line under a mode's switch says what On will turn off before
you tap. **PvP and the Leviathan sit on top** of your mode: off brings it back.
The Mirage is one mode; its page picks the job (onto it, Advanced Fruit Dealer,
chests, Blue Gear). A setting shared by several modes lives on the page named
after it: boat speed, steering and the sea search on **Travel & boat** (Sea
travel, Prehistoric and Mirage link there); the sea loadout, keys, dodging and
heights on **Fighting at sea** (Sea events and Leviathan link there); hop and
team on **Servers & team** (every hunt links there). Back goes to the page you
came from.

The notes below written before 2026-10-11.3 name the old pages:

| old | now |
|---|---|
| Home switches (raid, random, the hunts, volcano, Leviathan, PvP) | each one's own page, from **Modes** |
| Targets page | Circuit farm |
| Hunt page: a hunt's own settings / readout | that hunt's page |
| Hunt page: hop, order, team, "servers", "last join", Hop now | Servers & team |
| Sea page: sea events | Sea events; the loadout, keys, dodging, heights, "what hurts": Fighting at sea |
| Sea page: Prehistoric | Prehistoric; boat speed, "I steer", the search: Travel & boat |
| Sea page: Mirage | Mirage (one mode, the job picked on its page) |
| Sea page: the Leviathan | Leviathan |
| Sea page: volcano, vents, golems, golem weapon, loot | Volcano event |
| Sea page: Silent aim, "skill aim" | Attack, "aim" |
| Magnet page: raid mode, raid loop chip, random mode reach | Raid / Random |
| Travel, Safety, Stats | Travel & boat, Safety & haki, Stats & debug |
| Attack page readouts (hit counts, "hits sent by", inventory) | Attack, Details |

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

No autoexec loader is needed: Velocity has `queue_on_teleport`. Servers &
team's reload line confirms it; Attack > Details "hits sent by" says whether
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
| Finding the camp | farm_pro's rule: every LOADED enemy of the species counts, wherever it stands; the one nearest you picks the camp. Travel goes to a loaded one, else the game's own spawn points (`_WorldOrigin.EnemySpawns`), else enemies the game parked in ReplicatedStorage, and only then the level table (12 of its points were corrected against three hubs). The Circuit farm page says which source each camp came from. |
| Magnet | **Every loaded enemy of the species, any distance** ("Pull every one loaded", on by default). Looked for again 10×/s from the frame loop, so one that spawns mid-fight joins the pile at once, even during a cast. The pile sits at the camp's middle: the centre of the smallest circle round its spawn points (game's `EnemySpawns`, else spots seen) — the spot where the farthest pull is shortest, so every one stays inside its own area. SimulationRadius raised; every frame each is written to its OWN spot on a ring there (kept for as long as it is in the pile - a death no longer moves the rest), velocity zeroed, knockback removed, and **frozen** the way the public hubs freeze theirs (WalkSpeed 0, JumpPower 0, PlatformStand, re-applied whenever the game undoes it) so a frame without the write cannot let it walk off. **The pile holds (2026-09-30):** while one pulled into it is alive it does not move and lets no living member go; new ones join within the limit of it; a new centre only when it is empty. It used to be worked out again 10×/s from whichever member stood nearest the middle, so a camp done one side at a time flipped sides mid-fight and dropped living members - the scatter. The remote hit / fruit click names the whole pile with the FIRST name turning each swing (a way that lands on the first names only no longer starves the back of the pile). Held + hit with no HP change for 3 s = put back, left alone 30 s. |
| How far one can be pulled | Nobody publishes how far the game lets an enemy be dragged from its spawn before it stops taking damage (hubs pull within 250-350 and put back after 3 s of no damage). "Pull at most, from their spawn" (300, Magnet page) caps it; **a camp wider than that is piled one side at a time** (the side nearest you, then the other when it is empty) - Port Town's Pistol Billionaires spawn ~550 studs across at heights 74-147 (39 public hub files). "Learn how far each kind can go" (**off by default since 2026-09-30** - user: the pile holds with it off; it only ever lowered the limit, and the back of the pile going unhit looked exactly like a limit, so camps got split and scattered): a pulled one that stops taking damage while one pulled from nearer its spawn in the same pile still takes it sets that kind's limit (no contrast, or NOT OURS = nothing learned). The Magnet page shows what it measured. |
| Lock | your body is written every frame to a spot over the pile: **"High, over the pile" (up to 150) counted from the HIGHEST living enemy in it** (one the magnet does not own stays up on its ledge, and you still stay that far over it). **"Always stay above them" (on by default): never down to the close spot** — every attack is fired from that height, and the remote hit reaches that far (a 60 reach at 60 up used to name nobody). Off: close beside the pile for key presses and fighting-style / sword skills. A Kitsune lunge is undone the same frame. |
| Noclip | every part stops colliding before each physics step while running. The body is always held, so it never falls through anything. |
| **Water is rock, every mode** | (user, 2026-10-11, after the Legendary Sword hunt flew them under Kingdom of Rose into the sea: water damage, death.) Noclip means the raised sea slab cannot hold your body, so the line is in every write: **the body is never put lower than the sea's top + 4** - the hover lock (asked and every frame), every frame of a flight, an instant hop. A goal under the water is reached ON it; a body the game throws under the water is lifted onto it. Only over the sea slab (`WaterBase-Plane`'s footprint) and not in the deep sea - Submerged Island keeps its own floor. A flight still goes straight through an island's ground (noclip) - but never under the sea. |
| Travel | under 150 studs: one jump. Further: a straight flight at 330 studs/s (slider). "Pulled back" on Travel & boat counts server corrections. Submerged Island: the Tiki submarine. |
| M1 with | Attack page, top: **which weapon swings M1 in every fight** (farm, golems, Blaze Ember quests). Auto (default): **your sword first**, then a fighting style, fruit, gun; or tap one - **your pick always swings**, even with its own M1 switch off. (The bug it fixes, 2026-10-05: the M1 weapon was the FIRST in the weapon list with M1 on - fighting styles are listed before swords and the first run switches M1 on for what you hold - so a picked Hallow Scythe lost to the fighting style.) The sword that swings is never swapped out by the rotation. |
| Every weapon you carry | Attack page switch, **off by default** (it was for the volcano; two M1s do that now - Hallow Scythe on the golems, Skull Guitar on the vents). On: no setup - M1 as picked above, Z / X / C of every weapon you carry. Off: the per-weapon choices below it. |
| Swords and guns from your inventory | Attack page, on by default: **every carried skill cooling = the next sword or gun from your inventory is put in your hands** - `CommF_("LoadItem", name)`, the game's own call, no menu - and its skills fired. Never-loaded first, then the one loaded longest ago; only rested ones (none of its keys cast within their cooldown); one that does not come is left 2 min; 1.5 s between loads. **What you carried goes back when the farm stops.** The volcano uses it too, in any attack mode, before its aimed M1. |
| **Race V4 / V3 by themselves** | (user, 2026-10-12) Attack page, top - **all ON by default, while the script works**: a mode running (any mode), or PvP mode on. **Loaded and idle = nothing fires** (user, 2026-10-12, build .6). **V4** the moment its meter (`Character.RaceEnergy`) is full: the game's own Y (`Events.ActivateRaceV4`), and if that does not transform you in 1.5 s the Awakening tool's own call (`Awakening.RemoteFunction:InvokeServer(true)`, the public hubs'); the way that worked goes first after that; both refused = again in 3 s. **V3 by your clock** (it cools ~29-30 s): from the moment it is SEEN going on - your Draco roar (`DracoRace.Roar` on `Remotes.FX`, cast by you, not an ally's), or a child named after the ability on your character (Mink's Agility) - nothing for 28 s, then `CommE "ActivateAbility"` (the game's T) every 0.5 s until it goes on again. Your own T counts the same. Never seen: a 3 s burst, the next 28 s from its end. No T while the Mirage gives you the moon. **While V4 is on** (the V4 gear: "receive MAX STATS") the farm fights with **every weapon you carry**: every key the moment it is ready (never a transformation fruit's V, never a key not unlocked), every M1 in turn (4 each, sword -> fighting style -> fruit -> gun), nothing loaded from the inventory; the Attack page's setup is for when you are not transformed. Sea fights keep their no-M1 rule (the sword and gun skills join in); a fruit's form = only its moves; the mastery farm and the golems' M1 weapon are kept. `workspace/bff_race_probe.txt`: what the game put on you after T and when V4 went on. |
| Learned keys, kept | Which key closes vents and which breaks trees are written to `workspace/bff_learn.json` and read back at load: learned once, not every event. Vents try **guns first** (shooting moves), then fruit, sword, fighting style - the learned ranking on top. |
| M1 | tried against the pile, kept per weapon if it takes HP off: remote hit (`RE/RegisterAttack` + `RE/RegisterHit` naming the whole pile), fruit click (`tool.LeftClickRemote`), key press. |
| A gun's M1 | (user, 2026-10-07: Dragonstorm "should hold down", the aim missed.) Read in the game's own client (decompiled v4623): Dragonstorm is `HitscanSingleShot` + `ShootStyle "Gatling"` - a shot every 0.08 s for as long as the MouseButton1 input is held, heat +1/s firing and -1/s idle, 3 = locked 1 s; **every shot reads `Mouse.Hit` and hits ONE enemy**. The old tap aimed only the first shot of each 3-shot burst. Now (Attack page, "a gun's M1"): **Hold the button** (on) - the button held like a player while the gun can fire, let go when its loop ends (heat, a skill, a stun), pressed again after the lockout; the silent aim on **one enemy for every shot** (the one being shot while it lives, then the weakest). Skills go **whenever ready** for a held gun: its heat drains while a skill plays, so a cast costs it no shots. The rest of the pile waits its turn and is **never put back for it** (the put-back clock judged every member while the gun shot one - the pile went back to its spawns). **Past the heat** (off): the game's own shot function (found among `CombatController.Attack`'s upvalues, the one holding the mouse + the validator's numbers) called every *a shot every* seconds - no lockout, the validator kept in step; the wiki says long gun M1 streams get kills marked suspicious. Readout: shots/s off `LocalTotalShots`, heat, LOCKED, the enemy and its HP, presses, overheats. Other guns' click keeps the aim for its whole burst. |
| Mastery farm | Attack page, "mastery farm": a weapon picked there is **the only one that hurts anything**, in every fight - its M1 and the keys under "Every weapon you carry" (a key not unlocked yet never fires and is left alone); nothing else swings, nothing is loaded from the inventory (another weapon's damage shares the kill). Not carried = loaded from your inventory. Mastery read off the tool's `Level` (your inventory's number if it has none); **the farm stops at "Stop the farm at"** (500 by default: Draco v4 needs Dragonstorm + Dragonheart at 500; 0 = never) with a notification. Stats & debug: "mastery: <weapon>, gun held / past the heat" is its own setup, kills per minute side by side. |
| Combo | per-weapon switches M1 Z X C V F + hold time per key (**all skills are off until you switch them on**). Ready skills read off `PlayerGui.Main.Skills[weapon][key].Cooldown`. "M1 swings between skills" and "Start with" set the rhythm. After each cast the bar is read again: "fired" or "key sent, the skill did NOT fire" (Attack page, Stats). Skill cooldowns live on the server and cannot be removed. |
| Aim lock | Skills fire down the line from the camera through the cursor. **Camera free (default):** a frame goes input → camera update → drawn → physics → Heartbeat → next input; the camera between Heartbeat and the next camera update is never drawn, but a key sent then is read in it. So at Heartbeat the camera is solved onto the pile (yaw + pitch, exact, for your cursor's pixel) and just before the camera update your saved view goes back — your screen and the camera script only ever see your own view. Every cast reports **hit or MISSED** (pile HP before/after) per skill. **Camera free off:** the view itself turns so the pile is under your cursor. |
| Circuit (Circuit farm page) | The species you pick, in your order: pile, kill, next species; alone, it waits for the respawn ("One species alone: wait for it", 45 s). Nothing picked = the species for your level. Another sea's species is skipped and named. **No quests** - the level-quest engine was removed 2026-09-28 (max level; git tag `quest-engine-2026-09-28` has it). **Bosses:** 24 from the game's data, all seas, renamed ones accept either name; **up** = loaded near you or parked by the game in ReplicatedStorage; not up = the rest of the circuit, or a wait over its spawn when it is alone. "Bosses first" (Circuit farm page): one that is up goes next. Use it for the Dough King road: Cake Island species for the 500 kills, Cocoa Warrior / Chocolate Bar Battler for Conjured Cocoa. |
| Raid mode | Raid page (Modes), its own switch. Species and quests forgotten: **every living enemy, any kind**, within "Pulls within" (450, Raid page) of the newest raid island, killed the usual way (magnet, aim lock, combo). **Stuck wave fixed (2026-09-28):** every one within the radius is pulled (raid enemies have no leash - they roam the island to reach you). One that takes no damage is no longer put back and LEFT OUT (that left the wave stuck with it alive while the farm hovered - "2 of 5 never hurt"): once the free ones are dead it is fought where it stands, from close if high does not hurt it. **Why it took no damage is written down** the moment it happens (Magnet page, "why no damage"): NOT OURS (the magnet moves it only on your screen) / OUT OF REACH / SHIELDED / its place in the pile. The readout says "one fought where it stands" / "could not hurt N". The raid is read the way the public raid scripts read it (2025-07, 2026-08): timer `PlayerGui.Main.TopHUDList.RaidTimer` (older `Main.Timer`), islands `workspace._WorldOrigin.Locations["Island 1".."Island 5"]`, newest = highest number. Island empty = hover 45 over it for the wave / the next island. Outside a raid it pulls everything within the radius of you. Observation is never pressed (raids switch it off); Enhancement still is. **The raid over (2026-10-10):** the game puts you back at the Castle on the Sea and the old code flew off to the raid's island markers (they stay). Now an island counts only **within 2,500 studs of you** ("A raid island counts within", Raid page; the public hubs' number), a farther one only while the raid timer is up - and **outside a raid nothing is fought and you stay where you are**. **The stuck fight:** no kill and no HP off any enemy within 1,500 of the island for **12 s** ("Stuck: relocate after") = the pile let go, every skip forgotten, the nearest one becomes THE target - fought where it stands even outside the pull radius, from a new spot (straight over it close, then beside it, 120 deg round) - again each 12 s while it lasts; a kill ends it (`[BFF] raid: stuck Ns on Island N ... relocating (k): <name>`). The watch also runs inside a fight. **Raid loop** (Raid page switch, on): raid over -> 5 s -> a chip from the Mysterious Scientist (`RaidsNpc "Select" <chip>`, Raid page "the chip", Flame by default) paid with your **cheapest stored fruit worth at most 200,000** (slider): read from `getInventoryFruits`, else the game's item list (PhysicalFruit ids), else `getInventory`; loaded with `LoadFruit` into the **backpack, never your hand**; none that cheap = asked anyway (his $100,000-every-2-h way). A dearer physical fruit already in your backpack = **nothing traded** (he could take it). Then the raid button (`Map["Boat Castle"].RaidSummon2.Button.Main`, flown to, `fireclickdetector`), the raid awaited 20 s. Anything fails = **you stay**, said why, tried again (60 s; a press 10 s, the third 2 min). Level under 1100 = the loop goes off. |
| Random mode | Random page (Modes), its own switch (one mode at a time). Quests forgotten; **every living enemy of any kind within "Random mode reaches" (750) of you, and every one damaged.** At the Castle on the Sea (Third Sea) the area is the pirate raid's own: the game tags mobs `BasicMob`, and a raid pirate is one that appears within 750 of (-5556, 314, -2988) (redz module 2025-10; a 2026-09 hub goes to (-5128, 314, -2957) when farther than 1000); raid every ~1 h 15. Guarantee: (1) pulled only within each kind's pull limit (MaxPull / measured) - a far or diagonal group gets its own pile next; (2) one that took no damage when pulled is fought where it stands once the free ones are done; (3) no damage from the height in 6 s = down close for it, whatever "Always stay above" says; (4) none in 15 s even close = cannot be hurt by this setup: left a minute and counted on the panel. |
| Hunt | **Five switches, one hunt at a time** (each its own page in Modes, its switch at the top; one on turns the others off, and raid / random off): **Elite pirate hunt**, **Fruit hunt**, **Berry hunt**, **Aura recipe hunt**, **Fire Flower hunt**. The hunt you switch on does only that, then the next server - nothing is ranked or picked for you, and nothing breaks off an elite fight. **Fruit hunt** (any sea): the whole server's fruits are seen from anywhere - **the game's own spawns too** (2026-10-12: the finder used to ask for a Tool with `OriginalName`, which only players' drops were ever seen to carry - the probe of 2026-09-28 logged seven fruits, all drops): any child of workspace, a **Tool or a Model**, named a fruit (or carrying `OriginalName`), with a Handle (its own, or its Tool's), not a player's character; which fruit = `OriginalName`, else its name ("Kitsune Fruit" -> Kitsune-Kitsune, "Bird: Falcon Fruit" -> Bird-Bird: Falcon); a spawn whose fruit cannot be named on the ground is taken whatever the minimum (switch, on) and named once it is in your hands; every new shape is written once to the console and `workspace/bff_fruit_seen.txt`; worth it = the game's own price (GetFruits) at least your minimum (0 = any), dearest first; player drops (the game tags them `DroppedBy`) only with "Include fruits players dropped" on - off by default, drops are mostly trades - and never while the dropper stands by it. Flown onto, touched, put away at once (never in your hand) and **kept in your backpack** (user, 2026-10-12: the fruit hunt collects fruits for raid chips - the raid loop trades a carried fruit before it loads a stored one); "Store it at once" on = StoreFruit instead. **Before every hop the backpack's fruits are stored** ("Store the backpack before a hop", on) - a fruit carried, not stored, is lost when you leave the server; stored, the raid loop still loads it back for a chip. A carried fruit worth more than the raid page's cap blocks the chip (the scientist picks which carried fruit he takes). **Berry hunt** (any sea; the Haki colors): every bush the game tags `BerryBush`, a bush's attribute values = the berries on it; a switch per berry (the Legendary Aura colors: **Winter Sky 15 Pink Pig, Snow White 10 White Cloud, Pure Red 15 Red Cherry**, + 7,500 fragments at the Barista). Nearest wanted bush, flown to, each berry's ProximityPrompt **held like a player holds E** (InputHoldBegin, the prompt's own HoldDuration, InputHoldEnd) - the executor's `fireproximityprompt` only every third try: it triggers instantly, skipping the hold, and the game can refuse that (on Velocity about half the berries were never picked until 2026-09-30). ~15 s while the berry is still there; **PICKED** = your inventory count (`getInventory`) went up, and the console says `[BFF] berry: PICKED ... (by hold, try 1)`. A kind you hold 99 of is not wanted; a bush it could not pick is left a minute. At most 4 berries in a server, a new one every 15 min. **Aura recipe hunt** (Second and Third Sea): the **Barista Cousin** teaches ONE recipe per server (he comes 20 min after a server starts, stays 20, is gone 2). `CommF_:InvokeServer("ColorsDealer", "1")` names it (and a rarity, 3+ = Legendary) from anywhere - no flight to find out; not him or not a recipe you switched on = the next server. One you picked: `("ColorsDealer", "2")` learns it from where you stand, else from in front of him (`workspace.NPCs["Barista Cousin"]`); learned = its switch goes off and the hunt goes on for the others; all learned = stops. Not learned (fragments, **Aura stage 5** = the "Iron Man" title) = the hunt stops and says why. A switch per recipe, the three Legendary first (Winter Sky, Snow White, Pure Red - rip_indra's buttons need all three; switch off the ones you have). **Elite pirate hunt** (Third Sea): **Diablo, Deandre, Urban** (and Tyrant of the Skies while he is up) - one per server, back 8 min 45 s after the last one died; only the **last hit** gets the drops, God's Chalice among them. **Up** = loaded near a player or parked by the game in ReplicatedStorage, or the Elite Hunter (the cat at the Castle on the Sea, `CommF_:InvokeServer("EliteHunter")`) answers with a name. Up: its quest (a different running quest is dropped; if asking from where you stand gets no answer, once per server from in front of the Elite Hunter), flight, the fight where it stands - never pulled. Down: 4 s look for the chalice, progress read, then it is not looked for in this server for 8 min. **Fire Flower hunt** (Third Sea; Draco V2 = 5 Fire Flowers + $1,000,000 at the Dragon Wizard - his V2 quest must be taken, flowers spawn only then): any kill can drop one; it comes up from the ground a while after the kill, for you only, as a Model in `workspace.FireFlowers` (three public hubs, 2026). **Forest + Mythological Pirates** (Floating Turtle), **no magnet**: the nearest one is fought where it stands, on the ground, kept until it dies, then the next (no damage: close after 6 s, skipped a minute after 15 s). The fight breaks off the moment a flower lies there; it is flown onto and its prompt **held like a player** (the berries' way, `fireproximityprompt` every third try); **PICKED** = the inventory's "Fire Flower" count went up, console `[BFF] flower: PICKED ...`. A flower came = the next server (that one gives none for 5-15 min, so it is not rejoined for 10 min longer than usual). **No flower 2.5 min after the FIRST KILL in a server** (from the first kill straight through, respawn waits included - not from the join; slider 1-5 min) = the next server; nothing dies for 3 min = the next server too. No count: it runs until you switch it off. Hop off = stays and keeps killing. **Nothing for the hunt here** (3 s after a join at least; elites: 3 s when the Elite Hunter says none, else "Look for" 8 s): the next server, or with hop off, wait. |
| Team | Every new server asks **Pirates or Marines** before your character spawns - so every hop. "Pick my team on join" (Servers & team; on, **Pirates** by default) answers it: `CommF_:InvokeServer("SetTeam", team)` (the public hubs, 2026-04 .. 2026-09-29), every 2 s until you are on one. Not the screen's button through `getconnections` - removed 2026-09-30: firing a game's connections natively is a call an executor can crash on. Only while you have no team - the team you are on is never switched. Runs after the carried settings, so the next server gets the team you picked, not the default. |
| Server hop | The game's own server browser, `ReplicatedStorage.__ServerBrowser` (what its Servers menu calls): `InvokeServer(page)` → `{ [JobId] = { Count, Region } }`, `InvokeServer("teleport", JobId)`. List empty → the Roblox list (`games.roblox.com/v1/games/<place>/servers/Public`). **The join is always the game's** (`"teleport"`: its server starts the teleport), whichever list the server came from: the Third Sea takes only server-started teleports (Roblox "Secure within universe"), and a join started on your client (`TeleportToPlaceInstance`) is refused - "Cannot teleport without a valid teleport token (Unauthorized)" (seen in game 2026-09-28). That one is tried only with no `__ServerBrowser`, and not again in that server once refused. Why a list or a join failed: Servers & team ("servers", "last join") and the console (`[BFF] hop: ...`). Not this server, not full, not looked at in "Try a server again after" (10 min); **fewest players first** (or any order). Five tries a round, three rounds. Your settings, the servers looked at and the counts go to the next server in the reload queued with `queue_on_teleport` **and** in `workspace/bff_elite_hop_<your UserId>.json` (one file per account - two accounts never share settings); the next copy starts the hunt by itself (only within 5 min of the hop, only if it was running). |
| **The chalice** | **God's Chalice in your backpack or hand = the hunt is over in that server, for good.** Leaving the server or dying with it loses it, so every hop refuses - checked on every step, and again right before each teleport call (a drop that lands while the server list is being read still stops it). You are flown 300 up and held there; the next server's copy is told not to start. Turning the hunt off and on does not re-arm hopping in that server. Stop gives you the character back. |
| **Fruit guard** | A physical fruit ("Kitsune Fruit", or anything with an `EatRemote`) is **never a weapon**: never listed on the Attack page, never equipped, and **nothing is clicked while one is in your hand** (it is put away) - a click with a fruit held EATS it and replaces yours. Your eaten fruit's power ("Kitsune-Kitsune") is a weapon as always. |
| Safety | under 35 % HP: fly 250 up, wait for 80 %. Enhancement (J) + Observation (E) kept on. No real god mode exists — health is server-side. |
| Stats | kills per minute of FIGHTING and average pile time for the current attack setup; changing any attack switch files it under "tried" so setups can be compared. |
| **Server news** | The strip under the panel's title - **Hide keeps it** (the panel folds to the title + the strip). Read once a second from load, from what the game sends every client, at whatever moment you join (nothing counted from the server's start): **the moon** = `Lighting:GetAttribute("MoonPhase")`, 1-8, **5 = the full moon** (public hubs 2024-26), else the moon decal (the game's eight are named moon1..moon8 on Roblox); `IsBlueMoon`. **Night** = `Lighting.ClockTime` 18:00-05:00. The phase turns at noon, so a day carries the number of the night it leads into (night 4, day 5, night 5 = full). The chip: `DAY 5` / `NIGHT 4` / `FULL MOON` / `BLUE MOON` / `FULL IN` + m:ss to the next dusk or dawn; `BREAKING` 8 s after news. The crawl: the moon (night N/8, the full moon tonight / next night / in N nights, in real minutes), **Mirage** and **Prehistoric** (up or not, every lap; age since this client saw it come - already up at the join = age unknown; Mirage/Kitsune live 15 min at most; its middle's distance, and the Advanced Fruit Dealer's own when the client holds him), Kitsune (when up, or on a full-moon night), the Frozen Dimension, the elite, Dough King / Cake Prince / rip_indra / Soul Reaper, Cake Prince's kills to go (`CommF_("CakePrinceSpawner", true)` - a question, never the summon - once a minute, only while the strip is on screen), a fruit lying on the map, players. News (an island, the full moon rising, an elite or raid boss, a fruit) starts the crawl over with it in front, marked BREAKING for a minute. **Real minutes are measured:** the clock's speed day and night apart (20 s samples), the hour the phase turns and the order it turns in - kept in `workspace/bff_sky.json` so the next server starts knowing them (until measured: a game hour a minute, which is what makes the wiki's "first full moon 54 min after a server starts" come out). |
| **Prehistoric hunt** | Prehistoric page (Modes), one of the hunts (Third Sea). Buys a **Beast Hunter** at Tiki Outpost's **back** boat dealer (`CommF_("BuyBoat", "Beast Hunter")` - 1 = bought, the user's probe), puts you **at the wheel** (the boat's own `VehicleSeat` - never the harpoon's seat at the bow, which is one too) and drives it. **You steer by default** (Travel & boat "I steer"): **A / D** (or the arrows) turn, **W** goes and keeps going, **S** stops, at your speed - no hop by distance, stay in Danger 6 as long as you like. "Auto" instead **drives it west** at Travel & boat's boat speed (250-350 studs/s; the boat alone sails ~140): its pivot written every frame, its collisions off, so Rumbling Waters and the Terrorshark are driven through. **It steers like a person** (user, 2026-10-06): every 1-2 min, at random, **left, right or straight on**, each turn 10-20 deg from where it heads now, never more than 45 deg off west (Travel & boat sliders). Distance is shown in the compass's meters, counted from that dealer (1 m = 10 studs, from your compass: Danger 6 ~2,600 m, the Prehistoric came ~5,000 m) next to the danger level read off the compass. **The island up** (its `_WorldOrigin.Locations` marker or `Map.PrehistoricIsland`): off the boat, onto the island, and it **never leaves** (the island despawns with nobody on it). **The search** (auto, user 2026-10-06; 2026-10-10: 17,000 / 7,000): out to **17,000 m** from Tiki; no island = a **120 deg turn to the left** and **7,000 m more** (by the boat's own odometer - the turn heads back toward Tiki, so distance from it would lie); still none = the next server. Travel & boat: "out to", "then turn left", "and sail on" (0 = the next server at the edge). **And the server's safety cap:** the legs are the plan; whatever goes wrong (back at Tiki, a boat that will not come, a loop), no island **21 minutes** after the **Prehistoric hunt** started in this server (switching it on restarts the clock) = the next server, auto or manual - checked before any boat step. Only the Prehistoric hunt: not the Mirage hunt, not the farm. Once the island is up the cap no longer counts (event, loot, then the hop). Slider, 0 = off. Boat sunk far out = the next server; near Tiki = another one bought. |
| **Sea travel** | Sea travel page (Modes) switch (Third Sea; user, 2026-10-10: "just the boat fast" - for the Leviathan, when no island is wanted). The same boat and wheel as the Prehistoric / Mirage hunts - your boat, or a Beast Hunter bought at Tiki's back dealer - at Travel & boat's boat speed, **always your keys** (A / D turn, W go, S stop) even with "Auto" picked on Travel & boat. **No target**: a Mirage or a Prehistoric Island up is sailed past (the Mirage hunt would fly you onto it; the Prehistoric hunt would fly you to Hydra for the magnet). No clock, **never the next server**; the boat lost far out = the switch goes off. Switching any hunt off stops the boat (you stay in your seat). |
| **Sea events hunt** | Sea events page (Modes) switch, one of the hunts (Third Sea; user, 2026-10-09). The Prehistoric hunt's boat **always travels** (user, 2026-10-12: no staying in one place) - **the Prehistoric / Mirage hunts' own wheel and steering** (Travel & boat: *I steer* = your A / D / W / S; *Auto* = west, the heading wandering, out to 17,000 m, 120 deg left, 7,000 m more), only where the Prehistoric hunt would hop it **turns left again and sails on**, round a triangle far out (10,000 m from Tiki at its nearest - all Danger 6). The old patrol circle and its Sea Danger slider are gone. **Fought** (each its own switch): **Sea Beast**, **Rumbling Waters** (three beasts, one at a time), **Terrorshark**, **Piranha**; Shark off. **Fled, always:** ship raids (pirate brigades, the Fish Boat and its crew, haunted ships) - sailed away until 1,500 off, then, until twice that or gone, the boat goes on but **never toward it** (the part of its heading closing on the ship is taken out - along its side). **The Leviathan: its own switch** (below). A fight: off the seat, the boat held 150 up (out of the waves), the nearest target kept until it dies. A **Sea Beast** (`workspace.SeaBeasts`, no Humanoid - HP from its `Health` value / `HealthBBG` text / attribute): hovered 90 over the water, every key Z X C F of every carried weapon + the M1 between, **aimed at its body every frame**; which key and whose M1 hurt it is **learned from its HP** (the vent caster, credited by HP); nothing for 6 s = in close (25 up); dived = wait 200 over it, nothing fired. **Terrorshark / Piranha / Shark**: the farm's own fight in place, 30 over, M1 + every skill whatever the Attack page says. **How a move lands** (read in the decompiled client v4623, 2026-10-09): skills and a fruit's M1 send `ReplicatedStorage.Mouse`'s `Hit` - the game's own table, re-aimed every frame by a camera ray - NOT the PlayerMouse; while the script casts, that table's `Hit` / `Target` answer the target (its own writes kept aside, put back 3 s after; a Lua table's metatable - no `__namecall`). Guns read the PlayerMouse (the old hook). The target's `HumanoidRootPart` is made 60 a side on your client (every public sea-event script) and the camera stands 90 off, so a move casting its own camera ray finds it. Transformed (a fruit's rig on you - Kitsune, Dragon, ...) the game refuses every other weapon's key, so only that fruit's moves are fired and learned. **The loadout** (user, 2026-10-09: points in fruit + melee): Fighting at sea radio, default **Kitsune form first** - V pressed for you (off the seat: seated, the game refuses skills), its M1 tested on each class (Sea Beasts / Terrorshark-Piranha-Shark), credited by the target's HP; 2 hits = stay in form for that class; 20 s with 6+ M1s and fewer = out of form, **untransformed Kitsune + your fighting style** (Dragon Talon) - only the weapon types switched on (fruit + melee by default; no sword / gun, none loaded from your inventory). Out of form a Terrorshark is the farm's own fight (fighting-style remote-hit M1); in form the HP-credited caster. Re-tested every 5th target; form keys learned apart (" (form)"), fish have their own table. **NO M1 at a sea event** (user, 2026-10-09: an untransformed M1 does nothing to one): never out of Kitsune form - not even to test - whatever the Attack page, your M1 pick or the mastery say; in Kitsune form, Kitsune's M1 only. **Every ready key, at once** (user, 2026-10-09): a key goes the moment the game takes it (the decompiled client's own gates: not `Busy`, not stunned, no move `Holding`), the next one the frame its bar starts cooling OR the game goes busy with it (a long move - Kitsune Z / X - starts its bar only at its END; it used to be read as refused and put aside, so only C and F fired), the next key waiting for the move to end, never pressed into it; no fixed 0.45 s wait; a press the game refused (too early) is retried in 3 s, never left a minute; V never on a transformation fruit (Kitsune's V transforms), on for everything else (Dragon Talon's V); keys the weapon's mastery has not unlocked are skipped. **The water as rock**: every sea fight sets a floor at the sea's top + 4 - the lock never goes under it (noclip let you through the slab; a dived Terrorshark took the fight's height under with it), swimming is switched off, a knockback / pull under 500 studs is not adopted (the body goes back; a respawn is still followed). **Dodging, per attacker** (Fighting at sea, on; user, 2026-10-12): a **Sea Beast** (each of Rumbling Waters' three) is circled too now - it used to be hovered over, still, and took its hits - at **350 studs/s, 40-60 studs off** (flat), BeastHeight over the water (25 in close, 200 while it is dived); a **Terrorshark** the same 350 / 40-60 at FishHeight; a new distance in the band at random at each direction flip, gone to at half the speed; **Rumbling Waters**: the circle round one beast is pushed out of the other two's reach (40 + 15), never nearer the one fought than its 40; a Piranha / Shark at 30 studs, 50 studs/s and the Leviathan keep their old circle; every one: the direction flipping every 1.2-3 s, the aim held on it; up 40 for 1 s the moment it starts an attack (a new animation that does not loop - its id is printed once), charges at you or leaps. **The count** (for the Spy's cooldown - 20+ KILLED sea events after a Frozen Dimension, the wiki): one group of a kind = one event (five piranhas once; three beasts = Rumbling Waters once), counted when all of it is gone and one was killed (HP 0, or gone at 10% or less) - under-counted rather than over; kept in `workspace/bff_sea_events.json`; goal slider + optional stop at it; reset button. **The Spy** is asked, read only (`CommF_("InfoLeviathan", "1")`: 1 = cooldown, 2-4 = takes fragments, 5 = out there), at the start, after each count, every 5 min - never bribed. Never the next server. |
| **Leviathan fight** | Leviathan page (Modes) switch, OFF by default (user, 2026-10-09). **On = only the Leviathan** - switch it on inside the Frozen Dimension (it starts the run if stopped); nothing else runs while it is on: until it shows the character is yours (hands off), and if it vanishes mid-fight you are held over the water 20 s first. Its parts (`workspace.SeaBeasts`: `Leviathan` the head, `Leviathan Segment`s, `Leviathan Tail` - the hubs; each with a Humanoid + Animator - the game's `SyncLeviathan`) are fought like a Sea Beast - every ready key aimed at the part, no M1 out of Kitsune form, round it at 75 over it (slider; nothing landed for 6 s = 25), the water a floor, dives waited out. **Segments first, the head LAST**: only parts whose `HealthEnabled` is on, and never the head while a segment / the tail is alive (they respawn - back to them). **Its attacks dodged off the game's own effects** (decompiled client v4623, `EffectContainer/Leviathan`): the tail's red area (`Bubble` in `workspace._WorldOrigin`, ~5 s before the swipe) - out of it sideways, kept 7 s (up does not save you - the wiki); the beam's charge on its mouth (`MouthCharge`) and the beam (`BeamModel`) - off its line; its tornadoes (`IcyTornado`) - away; the roar's ice spears (`IceSpear`) - up the moment one flies within 400; any attack animation on ANY of its parts (the head roars while you hit a segment) - up. **The reward needs 8% of the damage on EACH segment** (the wiki): your share is read off its HP while your keys land (others' hits in that moment count too), so it moves on at 15% (slider). **Its heart** (`Map.FrozenHeart`): the character is yours - the Beast Hunter's harpoon, tow it to Tiki. **Killed**: the sea event count back to 0 (the Spy's cooldown starts), the kill kept. No boat is ever touched (it only gets you off a seat: seated, the game refuses skills); the hitbox is grown to 60 but never shrunk. The first one writes its parts, and each attack's real size, to `workspace/bff_beast_probe.txt`. |
| **Mirage hunts** | **Four hunts, one Mirage mode** (user, 2026-10-07: "separated"; since 2026-10-11.3 one row, the Mirage page picks the job), one at a time like every hunt. A Mirage already up in the server = straight to the job; none = **the same boat and search** as the Prehistoric hunt first. Each one does ONLY its job, then the character is yours and the farm stops, on the Mirage. **Mirage hunt** - onto it, nothing else. **Advanced Fruit Dealer hunt** - he stands at a **random spot** on the Mirage (wiki), so never a fixed point: his own root, read wherever the client holds him - `workspace.NPCs` (near you), `ReplicatedStorage.NPCs` (parked; still his real spot), the executor's `getnilinstances()`, the island's own model. A copy more than 2,500 studs off this Mirage is a stale one, skipped (said in the console). Not read anywhere = **the island searched**, two rings round its middle, until he is - never a single look and "not found" (the 2026-10-07 bug). Flown to **in front of his face** (5 studs along his own look), turned to him, the camera on his head, his shop opened through the game's `FruitShop` controller - you buy. A parked spot is re-read from beside him and corrected (up to 3 times). **Mirage chest hunt** - every chest (`Map.MysticIsland.Chests` + the game's `_ChestTagged` tag, `IsDisabled` = taken), nearest first, one that will not open in 3 tries left; waits up to 15 s for the island's model when only its marker is there. **Blue Gear hunt** - taken at once if it already shows, else the character is **yours for the moon** (a high point, face it, T) and the gear (MeshPart 10153114969) is run over the moment it shows. Only this hunt asks the sky (Mirage page: night / full moon / any); the other three take every Mirage. Switching a hunt on again on the same Mirage starts its job again. The server-news strip says the Mirage's distance is **its middle**, and when the client holds the dealer, **his own distance** too. |
| **Volcanic Magnet first** | Prehistoric page switch, on. Before the Prehistoric hunt sails (the wiki: the magnet "drastically increases" the island's spawn chance, and is **consumed** when it spawns - every trip wants one; you hold at most 1): **in your inventory = sail**; not = **crafted** - 15 Blaze Ember + 10 Scrap Metal, `CommF_("CraftItem", "Craft", "Volcanic Magnet")` from where you are, else at the Dragon Hunter. Short: **Scrap Metal** from Forest Pirates (or Pirate Millionaires - the wiki's Third Sea droppers), then **Blaze Embers** by the Ember hunt's own quests (run borrowed: nothing it hits stops the farm). Cannot (no Ember quests, the craft refused 3 times, the inventory unreadable) = sail without it, said. **The 21-minute cap starts at the sail**, not during this. |
| **The Prehistoric loop** | The Prehistoric hunt runs the whole loop itself (no Volcano switch needed): sail till the island comes -> **the event started** (stood at the fossil's prompt in front of the T-Rex skull - `Core.ActivationPrompt` - the prompt held, then the real **E held 1.5 s** as a fallback, as the hubs do) -> defend -> **over + bones and egg picked** (8 s for them to come) -> **the next server**, and the hunt goes on there. Volcano event page: "The next server / Again, on this island" (the wiki: no cooldown). The game's known start bug (the wiki: "does not start, even after interacting") = 4 presses, then this island is given up and the hunt hops. |
| Never into the crater | (user, 2026-10-06: arriving, the character went to the island's middle - the volcano - touched the lava and died.) The island's map marker IS its middle. Now: **only the marker known = the island's edge on your side** (1.6x the keep-out from the middle); streamed in = **in front of the T-Rex skull, on the side away from the volcano**. **Every flight on / to the island goes ROUND a 220-stud disc** round the volcano's middle (`VolcanoKeepOut`): the short way on a circle at 1.25x, then in to the target along its own bearing - to the skull's prompt, a vent, back to the relic. **The island's lava is taken off your client the moment it streams in** (the hubs do), not only once the event runs. |
| **Volcano event** | Its own page and switch (Modes, alongside any mode): whenever a Prehistoric Island is up in this server, nothing else runs. Flown to it, the relic's prompt held (`IsMinigameActive`). Then, **the relic first** (first run, 2026-10-04: lost on the relic's health): **golems** (`"Lava Golem"` by name) are **lifted into the air and held there the whole event** (60 off the relic away from the volcano, 60 up - its own frame holder, never put back); a golem that is **not held** (just landed, or not ours to move) is **fought first, where it stands**; held ones die when no vent is open (your Attack page weapons). **Vents** are closed with ready Z/X/C of every weapon you carry, **through the silent aim** (the game is told your mouse points at the vent - your real cursor is never read while it fires; hooked **only while the script casts**, the game's own back 3 s after); **which keys close vents is learned** (Volcano event, Details) and those go first, keys that never close one go last; nothing ready = an aimed M1. **The meters:** relic health and pressure read off the game where found (relic Humanoid / attributes / values / billboard / screen text); pressure over 70% while the relic is over 90% = vents before even a free golem. Everything that could be a meter is written to `workspace/bff_volcano_probe.txt` in each event's first seconds. Lava taken off your client. After a win: the bones, then the Dragon Egg - **each counted only when the game's own count goes up** (user, 2026-10-07: 5 bones + an egg "picked", inventory unchanged - the old check was the bone *vanishing* / the egg's prompt going, and the loop left the server 3 s after the last bone). **The game's count:** its item list (`ReplicatedStorage.Modules.Net` `RF/GetAllItemValues` -> `{Key="Quantity", ItemId, Value}`, kept current by `RE/OnItemValueChanged`; ids from the game's `Economy.ItemId.RawSource`: Dinosaur Bones 585, Dragon Egg 565 - both stored materials, straight into the inventory, never held), legacy `CommF_("getInventory")` as the fallback (it answers nothing on your client), never asked more than every 2 s. **Before:** your counts at the hunt's start and when the event comes on, plus whether the game counts you (`PrehistoricIslandParticipant` - only those on the island when the relic is touched get loot) and a death during the event (no loot after one). **Each pick:** it stays by the bone / the egg until the count goes up (egg: 6 s - its pickup plays); gone without the count going up = said, NOT counted. **Slowly** (user, 2026-10-10: bones went "at light speed"; the egg's ~3 s animation must finish or it is not yours): **0.5-1 s on each bone** (random; Volcano event "Each bone, at least / at most"), and after E on the egg it **stands still 4 s** ("The egg: stand still after E") even when the count is already up. **Before the next server:** stays **20 s after the last pick** (Volcano event "Stay after the loot", 0-300 s) so the game saves it, then `[BFF] volcano: DONE ... Dinosaur Bones 14 -> 19 (+5) · Dragon Egg 1 -> 2 (+1)` and the count is written to `workspace/bff_loot.json`. **Then home by respawn** (user, 2026-10-10; Volcano event switch "Home by respawn after the loot", on): the character is reset - Health 0, then BreakJoints, then the Head, each only if the last left you alive - and the game puts the new one at your spawn (Tiki Outpost, where the sail began), **never a flight back**; the inventory is read again there, then the next server. No new character in 20 s = the next server from where you stand. Never with the God's Chalice on you (a death loses it); only when something was picked. **The next server** reads its own count against that: less = `LOST ON THE HOP`, notification, the Prehistoric hunt stops. Volcano event: "you have", this event's confirmed picks, the last hop's check. The Volcanic Magnet step reads the same item list. |
| Golem weapon | Volcano event, "lava golems": **its M1 swings on the Lava Golems** - default **Cursed Dual Katana** (user: 4100+ a swing; Hallow Scythe 3755). Not carried = **loaded from your inventory when the event starts** (`LoadItem`) and kept; not found = the Attack page's "M1 with" pick (the readout says which). Tap any carried sword / fighting style, or "The Attack page's M1 pick". Other fights keep the Attack page pick. |
| Skull Guitar M1 on the vents | Volcano event switch, on. The wiki: Skull Guitar's M1 has Destructible Physics and a short cooldown, "can be used on the pressure points" (Bazooka, Cannon too). **Carried or in your inventory = loaded at the event** (`LoadItem`) **and kept** (the rotation swaps swords only while it is in hand), then fired at each vent **stood still** for up to 3 s before any skill - by its own remote, `tool.RemoteEvent:FireServer("TAP", vent)` (the hubs' gun fast attack, no mouse). The first shots are checked against its **energy** (20 a shot): spent = the remote works; not = the aimed click (silent aim) from then on; unreadable = both. Energy under 20 = the skills for 5 s; six turns closing nothing = the skills instead. |
| **Blaze Ember hunt** | Blaze Ember page (Modes), one of the hunts (Third Sea). The **Dragon Hunter**'s quests (Dragon Dojo, Hydra Island), over and over: `Modules.Net["RF/DragonHunter"]` `{Context="RequestQuest"}` / `{Context="Check"}` -> the quest's text. **Asked from where you are**; if that gives none, or one taken that way never finishes (more done than it asks, no "Head back to the Dojo"), **at the Dragon Hunter** from then on. *Defeat 3 Hydra Enforcers / Venomous Assailants*: pulled and killed (your Attack page). *Destroy 10 trees*: the **medium ground trees first, bamboo last, the giants never** (taller than 120 studs, slider) - **blasts only**: the Skull Guitar / Bazooka / Cannon M1 first (the wiki: their M1 breaks trees), else Z/X/C of every weapon you carry **aimed at the tree** (silent aim), **never a plain M1** (every key cooling = wait, not a try), the key that breaks trees **learned**, a tree that stands through 8 casts left 5 min; every tree-like model is written to `workspace/bff_ember_trees.txt`. **Embers** (`workspace.EmberTemplate`) are run through before anything else. Stops at 99 (slider), or when he gives no quest 3 visits running (needs **Dragon Talon 500 mastery + the Dojo's Yellow Belt**). |

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
11. **Fire Flower hunt:** be in the Third Sea with the Dragon Wizard's V2 quest taken, switch on **Fire Flower hunt**. It flies to Floating Turtle and kills the pirates one at a time. When a flower comes: "PICKED a Fire Flower - you have N" = done, then the next server. "could not pick it" / "(no prompt in it)" / "the flower went, your count did not go up" = send the console's `[BFF] flower:` lines. "lying now none" for ages while kills climb = the quest is not running, or the flowers moved out of `workspace.FireFlowers`.
9. **Elite not taking damage** (it was all-or-nothing per server): the console prints `[BFF] hits: <sender>  ·  COMBAT_REMOTE_THREAD = <true/false/nil>` once per server, and `[BFF] M1 <weapon>: <way>` after each probe. Send those lines from a server where it hit and one where it did not. The M1 page shows the same ("hits sent by", "this server's COMBAT_REMOTE_THREAD").

## Server news: first test

Load the script anywhere in the Third Sea and leave it a few minutes (Stop is fine - the news runs with the farm off).

1. The chip: `DAY n` / `NIGHT n` - does n match the moon you see (5 = full; 1 = no moon, 3 = half, 4 = almost full)? `SKY` that never changes, or a crawl saying "moon phase not readable here" = the attribute and the decal both moved: send the words in brackets.
2. Console `[BFF] sky: the clock runs X game hours a minute by day, Y by night` (after ~1 min). X and Y are the real speed - send them.
3. Console `[BFF] sky: the moon turned a -> b at HH:MM` (once per in-game day). Expected: b = a + 1, at 12:00. Anything else is learned automatically, but send it.
4. A Mirage / Prehistoric / Kitsune island or the Frozen Dimension: `[BFF] news: ... SPAWNED` / `IS UP` and `[BFF] sky: Workspace.Map.<island> attributes: ...` - send that line (a spawn time there would give the age of one already up when you join).
5. Elite or raid boss up: the crawl's `ELITE UP` should match the Elite Hunter's answer. Cake Prince: "N kills to go" should match the game's own message at the Cake Island.

## Prehistoric + volcano + Mirage: first test

Third Sea, with money for a boat, your Hallow Scythe M1 on the Attack page (and Z/X/C of a fruit or melee if you have them - vents close only with moves that break things).

1. **Sea page:** switch on **Prehistoric hunt** (Home). It flies to the back dealer: console `[BFF] sea: BuyBoat "Beast Hunter" -> 1`. Anything other than 1 = send the line.
2. **At the wheel** (by the steering wheel, NOT on the harpoon at the bow)? Steer with A / D, W go, S stop. In the seat and moving? The "where" line counts meters from Tiki. **Check it against your compass once** at Danger 6: if the compass says much more or less, move "One compass meter" (studs per meter) until they agree. Knocked off by a sea event: it sits you back down by itself.
3. Does the boat **keep its speed** (no rubber-banding back)? If it jumps back, lower "Boat speed".
4. The island comes: console `[BFF] sea: PREHISTORIC ISLAND at N m from Tiki`, you leave the boat and fly onto it. Send N.
5. **Volcano event** on: "starting the event at the relic" then `[BFF] volcano: event started`. Console `[BFF] volcano: meters event start - relic <where> · pressure <where>`: **NOT FOUND = send `workspace/bff_volcano_probe.txt`** (it lists every candidate) so the meters can be pinned.
6. **Golems:** Sea page "golems  N held up in the air · N NOT held". They should float in a ring over the sea side of the relic the moment they land. "NOT held" staying above 0 = they are not ours to move - send the Magnet page "why no damage" lines.
7. **Vents:** your mouse can be anywhere - skills should land ON the vent (Sea page "silent aim  in (casting)" during a cast, "ready" between). **If NPCs are invisible or the sea has no darkness, rejoin once:** the first silent aim (ddfd130) hooked every game call for the whole session and broke the game's own scripts; it stays in that game until you leave (the Sea page says "REJOIN"). `[BFF] volcano: vent closed by <weapon> <key>`. The Sea page table "which keys close vents" fills in: send it after a run - that answers which sword / fruit to bring.
8. Relic: "relic lowest" on the Sea page - the target is staying over 90%.
9. After a win: console `[BFF] loot: Dinosaur Bones 14 -> 15 - in your inventory` per bone, `[BFF] loot: Dragon Egg 1 -> 2 - in your inventory`, each bone 0.5-1 s, the egg 4 s stood still after E, then 20 s `loot in - staying` and `[BFF] volcano: DONE ... before -> after`, then `[BFF] loot: home by respawn (Health 0) - N m from Tiki · you have ...` (send the line: the rung that worked, and N should be near 0) or `no respawn in 20 s (tried: ...)` (send it - the game refused every reset) - then the next server. `went but your ... stayed N - NOT given to you` = the game did not give it (send the line with `counted by the game: true/false`). `not readable` = neither inventory list answered (send the line - it says what each gave). Next server: `[BFF] loot: the last server's loot is here ... saved`, or `LOST ON THE HOP` (the hunt stops - raise "Stay after the loot"). "the egg will not come" = no Dragon Tether (or no hit on a golem/vent).
10. **Sea travel** (Hunt page): the boat at speed, you steer - a Mirage / Prehistoric up is sailed past, never the next server. The boat should not stop or turn by itself; switching it off stops the boat.
11. **Mirage hunts** (Hunt page, one at a time): console `[BFF] mirage: MIRAGE ISLAND (<hunt> hunt) at N m from Tiki - <why>`.
    **Advanced Fruit Dealer hunt:** `[BFF] mirage: the Advanced Fruit Dealer is in <where> - N studs from you, M from the Mirage's middle`, then `in front of the Advanced Fruit Dealer - his shop is open`. Not found at once: `no Advanced Fruit Dealer in workspace.NPCs, ReplicatedStorage.NPCs, the nil instances or the island - searching the island` and the Sea page says `looking for ... (n/16)` - send the `<where>` line either way. **Chest hunt:** `chests done - N taken`. **Blue Gear hunt:** YOUR TURN on Home; climb, face the moon, T; the gear is grabbed within a second of showing.

12. **Blaze Ember hunt:** console `[BFF] ember: quest (asked from here|at the Dragon Hunter): <text>`. Hunt page "blaze ember hunt": quest, embers taken / you have, trees broken, the tree key that works. A trees quest: send `workspace/bff_ember_trees.txt` if it breaks nothing (that pins the real tree kind).

## Sea events hunt: first test

Third Sea, money for a boat, the weapons you fight sea events with carried (Kitsune / Sanguine Art / Skull Guitar...).

1. **Hunt page:** switch on **Sea events hunt**. It buys a boat if you have none (`[BFF] sea: BuyBoat "Beast Hunter" -> 1`), sits you at the wheel and the boat goes - **it never stops in one place** (build 2026-10-12.1). Sea page "now": with *I steer* `YOU STEER: A/D turn, W go, S stop · N m from Tiki · danger D`; with *Auto* `travelling · N m from Tiki (of 17000) · danger D`, then after the first turn `turn 1: x of 7000 m` (console `[BFF] seaev: 17000 m from Tiki - 120 deg left, 7000 m more (turn 1)`), turn 2, 3 ... for as long as the hunt is on.
2. **First Sea Beast:** console `[BFF] seaev: a Sea Beast up (Sea Beast, 1 in it)` and `first Sea Beast - HP from <where>`. **"not found" = send `workspace/bff_beast_probe.txt`** (it lists the beast's insides). You leave the seat, the boat should float 150 up, you hover over the beast.
3. **Sea page "skill aim":** `in (casting) · the game's own table (it aims it, seen)` during a fight. `not found` or `the game never wrote it while hooked` = send the line (skills then fall back to the camera turn only).
4. **Kitsune form:** console `[BFF] seaev: into Kitsune form` at the first fight. `V did not transform` = send it (V cooling is fine - it says so and fights out of form meanwhile). Then `Kitsune form's M1 HURTS Sea Beasts (n of m M1s ...)` or `does NOT hurt ... - untransformed Kitsune + your fighting style`. Send both verdict lines (beasts and Terrorshark). `out of Kitsune form` after a fight = V undoes it; `V did not untransform` = it does not (tell me - the form then ends by itself).
5. **Terrorshark dodging:** console `[BFF] seaev: Terrorshark attack animation rbxassetid://... - dodged up` for each attack kind (send them - they make the dodge exact). Sea page "dodged N times · last: ...". You should NEVER swim: Sea page "water  a floor at Y ..." during the fight. Hit anyway = say by which attack (the splash, the tail swipe, the charge).
6. **Every key at once, no M1:** Attack page "last skill" should change every fraction of a second while keys are ready; a key that sits ready and never fires = send its name. Out of Kitsune form you should see NO M1 swing at all at a sea event.
7. **Does anything hurt it?** Sea page "what hurts a sea beast (learned)": `Kitsune-Kitsune C  hurt it 3 of 4` etc. `[BFF] seaev: nothing hurt Sea Beast for 6 s from 90 up - in close` = nothing landed from up there; say whether it lands from close. Send that table after the fight - it answers which weapon to bring.
8. **Dives:** "under the water - waiting over it", nothing fired, then back on it when it comes up.
9. **The kill:** `[BFF] seaev: Sea Beast done - counted (n of 20)`. A beast that left / despawned says `gone without a kill - not counted`. Back to the wheel: the boat drops back onto the water and travels on.
10. **Terrorshark / Piranha:** the normal fight, 30 over it; the Attack page's "last skill" line shows every key firing. `Piranha done - counted` once for the whole school.
11. **Ship raid:** `[BFF] seaev: PirateBrigade N studs off - sailing away`, Sea page `AWAY from ...`, then `clear of ... · N studs · never toward it` - the boat still moving. A ship that is NOT fled = send the console's `near the boat, unknown here: <name>` lines (haunted ship names are not known yet).
12. **The Spy:** Sea page `spy  on cooldown - "I don't know anything yet"` (or "takes fragments"). When it flips: `[BFF] seaev: the Spy is past his cooldown - at N counted sea events` - send N; it tells whether the count matches the game's.

## Raid mode: first test (2026-10-10)

1. Raid mode + Raid loop on, at the Castle on the Sea, no chip: console `[BFF] raid loop: a Flame chip - paid with <fruit> ($N, from <source>)` - send the line (`<source>` says which inventory read works on your client). `no Flame chip - the scientist said ...` = send it.
2. `[BFF] raid loop: the raid started`, then `[BFF] raid: in a raid`, `Island 1`... `no fireclickdetector` = press the button yourself (the rest still runs).
3. The last island: `[BFF] raid: stuck Ns on Island N (k left, no HP off) - relocating (k): <name>` when it hangs - does the fight carry on after it? Send the lines if it still hangs.
4. `[BFF] raid: over (Island 5)`: you should stay at the castle - no flight anywhere - then the next chip after 5 s.

## Leviathan fight: first test

With your group in the Frozen Dimension, BEFORE the cutscene (join after it and the game gives you no damage - the wiki). Home: **Leviathan fight** on (it starts the run). Until it shows: `waiting for it: the character is yours` - move as you like.

1. Console `[BFF] levi: THE LEVIATHAN - N parts up` and `its parts written to workspace/bff_beast_probe.txt` - **send that file** (part names, HP source, HealthEnabled, and the `[leviathan attack]` lines below).
2. `[BFF] levi: on the Leviathan segment (HP ...)`: you leave the seat (the boat stays where it is), circle the segment 75 over it, keys fire. Sea page "the leviathan": every part's HP, "takes damage / not now", your share, `dodged N` and what you are being kept out of now.
3. The head is never hit while a segment / the tail is alive - say if you see it hit early.
4. Its attacks: each kind prints once - `the tail's red area (Bubble)`, `its beam charging (MouthCharge)`, `its beam (BeamModel)`, `a tornado (IcyTornado)` - and you should slide out of the red area / off the beam's line. Say which hit you anyway, and send the `[leviathan attack]` lines (their real size: the reach is a guess from the game's code until then) and any `attack animation` lines.
5. At your share (15%) `on the Leviathan ...` the next segment. Damage numbers you see in game vs the share line - say if they differ a lot.
6. Its heart: `THE LEVIATHAN'S HEART - the character is YOURS` - harpoon it yourself. Then `[BFF] levi: THE LEVIATHAN IS DOWN - ... count is back to 0`. Switch it off for the farm.

## Dragonstorm mastery: first test

Third Sea, Dragonstorm carried (or in your inventory), your usual Random mode spot.

1. **Attack page -> mastery farm:** tap **Dragonstorm**, "Stop the farm at" 500. The readout under it: `Dragonstorm  mastery N  ·  stops at 500`. "not readable" = send it (the tool has no Level here).
2. Start. Console `[BFF] M1 Dragonstorm: held like a player (the game's own fire), from above` = the hold lands. `nothing landed (...)` = send the whole line.
3. **Attack page -> "a gun's M1" readout** while it fights: `Dragonstorm held · keep · ~12 shots/s · heat 1.4 of 3` then `LOCKED` for about a second every ~2 s, `at <enemy> <HP>` counting down. **0 shots/s while "keep"** = the held button is not reaching the gun - send the readout (the click goes to the middle of the screen; nothing of a panel may sit there).
4. **Aim:** your mouse anywhere - every shot should land on the one named enemy (the same readout's `silent aim  in (casting)` while it fires). Misses = send the readout + whether your Velocity console printed any hook error.
5. **The pile stays:** the ones not being shot should stay in the pile; Magnet page "put back" should not climb while the gun works on one.
6. **Skills:** Z unlocks at 125, X at 250. "last skill  Dragonstorm Z: fired, hit the pile" every ~9 s, X every ~15 s; a locked one says "did NOT fire - left 1 min" (expected below its mastery).
7. **Past the heat** (off by default): switch on for a few minutes, then Stats page "which setup is better": `mastery: Dragonstorm, gun held` vs `gun past the heat 0.08 s` kills/min. The readout's `the game's shot` line says whether the game's shot function was found (`this executor has no getupvalues` = Velocity lacks it; held is all there is). Watch the mastery bar too - if kills "past the heat" give no mastery (the wiki's "suspicious kills"), switch it back off.

## Cooldown tests - first test (2026-10-15, build 2026-10-15.1)

Read in the game's client: **Flash Step (R)** - your own client checks its cooldown (15 s;
10 for an evolved Human) and moves you itself (200 studs; 350 evolved Human). That is
almost surely how you were run down over 300-400 m: Flash Step every second or two
instead of every 15. **Skills (Z X C V F)** - the server sends the cooldown and runs the
move; an early cast is most likely refused. Both on the PvP page, `cooldowns · tests`,
both OFF by default:

1. **Flash Step cooldown cut** (0-95 %). Set 50: the line says `Flash Step: 7.5 s
   cooldown (the game's 15 s)`. Press R twice 8 s apart: the second should go. Then 90 %
   (1.5 s). Watch for being pulled back to where you stepped from (= the server refuses).
   Each step still costs 10 energy.
2. **Skills off cooldown (test)**. On, then spam ONE skill key 10 times. The line:
   `N presses · N moves the game started`. Moves near presses = it works; far fewer (or
   an animation with no damage) = the server refuses - turn it off.

## Aim per weapon + settings lock - first test (2026-10-14, build 2026-10-14.2)

**Per weapon.** PvP page, `aim takes · each weapon its own`: four rows - **Fruit**,
**Fighting**, **Sword**, **Gun** - each with its own M1 Z X C V F. Dark = yours (your
mouse), lit = aimed. Default: only the **Sword's Z** is yours; your fruit's Z, your
fighting style's Z, your gun's Z stay aimed. The weapon in your hand decides (the fox =
your fruit); a sword Z still playing when you swap stays yours until it ends. The lead
line says the one in your hand: `sword: aimed M1 X C V F · yours Z`.

**Lock.** Home -> **Lock & stats** -> **Lock my settings** on. Everything you changed
from the defaults goes to your executor's workspace folder, `bff_settings_<your
UserId>.json` (saved at once, then 2 s after any change), and comes back at every load
(console: `[BFF] settings lock: N of your settings back`). Only what you changed is kept,
so a default I fix in a later build still reaches the rest. Off = the next load starts
from the defaults. Test: lock, change two things, reload the script - both still set.

## PvP: which attacks the aim takes - first test (2026-10-14, build 2026-10-14.1)

Your report (build .3): with **Lead a moving player** on, not one hit landed - always in
front / beside / above / below him; off, you hit (Buddy Sword X). So the lead is now OFF
by default: aim = where he is. And the aim is per attack: PvP page **Aim takes** - six
keys, lit = that attack goes at him, dark = yours (it goes where your mouse points, and
your body is not turned). Default: M1 X C V F aimed, **Z yours**.

1. **Z yours.** Buddy Sword Z goes where your mouse is; X still lands on him. The lead
   line starts `aimed M1 X C V F · yours Z`.
2. **A charged Z** (hold, then let go): still yours at the release - the aim stays out
   until the move ends.
3. **Try other keys** dark / lit and tell me which land better aimed and which by hand.

## PvP: hits land on a fast player - first test (2026-10-13, build 2026-10-13.1)

Why you missed fast players: the game's server runs your skills, and it hits where he is
on the SERVER - your ping plus the screen's buffer ahead of what you see - plus the move's
travel time. Now every skill, fruit M1 (the fox too) and slow gun (Cannon, Bazooka) goes
where he WILL be when it lands. Ray guns (every other gun) and sword / melee swings are
checked by your own client against what you see - those stay aimed at him as he is.
Everything is on from load (PvP page: **Lead a moving player**, **Lead strength 1.0x**,
**Keep aiming while the move plays**).

1. **The lead line.** PvP on, mouse near a running player. The PvP page shows
   `ping N ms · him N studs/s · skills N s ahead = N studs`. Standing still = 0 studs.
   With a gun: `gun: a ray at him, no lead` (most guns) or `gun N s ahead` (Cannon / Bazooka).
2. **The hits.** Fight a fast one with your usual skills. Hits that land **behind** him:
   raise **Lead strength** (1.2, 1.4). Land **ahead** of him: lower it (0.8). Tell me
   which moves land and which miss - each move flies at its own speed (default 300
   studs/s), one slider covers all.
3. **His Ken.** The PLAYER line says `HIS KEN ON (N dodges left)` while his Observation
   is up: those misses are his dodges, not the aim.
4. **During the windup.** `sent again while moves play: N` counts as you fight. If any
   move behaves oddly (fires twice, cancels), turn **Keep aiming while the move plays** off
   and tell me which move.
5. **The pick holds on.** A fast player who slips a little outside the catch area stays
   picked (1.5x the area for the one you are on), and while your move plays it keeps going
   to the one you cast it at even if your mouse slips onto someone else.
6. **Dragonstorm M1 (build 2026-10-13.2).** Every shot was already aimed at him; the gun's
   own spread (up to 1.5 deg each way on 3 shots of 4) threw it off - at 100 studs about a
   third missed. Now **Gun shots straight** (on) takes the spread off while you aim at
   him. The lead line says `gun: a ray at him, no lead, straight (no spread)` and
   `gun: N shots at him · his HP went down N times while you shot`. Many shots, few HP
   drops on a FAST player = your client hits but the server will not take them - tell me
   the two numbers (that is the next fix, not the aim).

## PvP: your mouse picks the player, he is highlighted - first test (2026-10-12, build 2026-10-12.8)

Your job: aim with your mouse, pick the weapon, press the attacks. The player nearest your
mouse gets every attack (the cursor need not be exactly on him) and is highlighted red; the
script turns your body to him. (Build .7 took the nearest to YOU and locked him - in a crowd
your attacks went to the one behind you. Moving you is not built - you walk.)

1. **The pick.** PvP on, two or three players. Move your mouse near one: the PvP page line
   says `<name> · N studs · your mouse is on him`, and he turns red (a red fill, a white
   outline, a red diamond over his head). Move the mouse to another: the red jumps to him.
   Nobody within **Mouse catch area** (200 px) of the cursor = `nobody near your mouse` and
   your attacks go where your mouse points, as normal.
2. **Through the blasts.** Fight in fire / explosion effects: the red body and the diamond
   should stay visible. Tell me if the red body vanishes in some effects (the diamond is a
   screen layer and should not).
3. **The hits.** A long-range move fired with the mouse a bit off him should land on him;
   behind you / beside you never get it unless your mouse is near them.
4. **Facing** (as before): any attack turns your body to him from the press, while you hold
   the key and the move plays, and 0.4 s after - only within **Face him within** (100 studs).
   `attacks turned to him` counts.

## Race V4 / V3: first test (2026-10-12, build 2026-10-12.5)

Nothing to switch on - the three switches on the Attack page are on from load.

1. **V4:** fight until the meter is full. Console `[BFF] race: V4 on - the game's Y`
   (or `- the Awakening call`). `V4 refused - meter full but no transform` = neither
   way worked: send the line. When it ends: `V4 over after N s`.
2. **Every weapon while V4:** the Attack page line says `V4 ON ... every weapon: <your
   weapons>`; Details -> hit counts: each weapon's keys "hit the pile". Home says
   `V4 - every weapon`. Back to your Attack page setup when V4 ends.
3. **V3:** console `[BFF] race: V3 on (DracoRace.Roar)`; the Attack page line counts
   `V3 on 12 s ago (...)  ·  next T in 16 s`, then `pressing T every 0.5 s` from 28 s.
   If it says `no V3 signal seen yet` / `on the clock`, your V3 shows something else:
   send `workspace/bff_race_probe.txt` (what the game put on you after the T's).
4. **The probe file** also lists what V4 put on your character. A child named like a
   fruit's form (`Dragon`, ...) is harmless now (no fruit = no form), but say if you see one.
5. **PvP:** V4 and V3 fire the same while PvP mode is on (you fight yourself).
6. **Idle (build .6):** load the script, start nothing - no T, no Y, ever. The Attack page
   line says `waits - nothing running (a mode, or PvP)`.
7. **The circuit has an Off (build .6):** after load Home says `No mode`; `Start  ·  No mode`
   starts nothing (`no mode on - pick one in Modes`). Circuit farm page -> its switch On =
   the circuit; Off = no mode. Raid / Random / a hunt switched off = no mode, not the circuit
   back; the farm stops by itself when no mode is left (the volcano switch alone waits).

## Fruits kept in the backpack: first test (2026-10-12, build 2026-10-12.4)

1. **Fruit hunt on, a fruit there:** "last" ends in `IN YOUR BACKPACK <name> ...
   - not stored (for raid chips)`; your backpack holds it, your inventory does not.
2. **The hop after it:** console `[BFF] hop: stored <name> before leaving` for each
   fruit carried, then the join. `could NOT store <name> (...)` = the game refused
   (send the words in brackets) - that fruit stays in the old server.
3. **Raid mode next, raid loop on:** `[BFF] raid loop: a <theme> chip - paid with
   <the carried fruit>` - the backpack's fruit is spent first. A dear one carried
   says `... is in your backpack - the scientist could take it; store it first`.

## Fruits the game spawns: first test (2026-10-12, build 2026-10-12.3)

1. **Leave the script running a while** (a server spawns a fruit about once an
   hour). The news strip should now say `FRUIT ON THE MAP: <name>  (server spawn)`.
2. **Send `workspace/bff_fruit_seen.txt`** (in `D:\Velocity\Workspace`) after the
   first spawn - one line per shape: `fruit seen (SPAWN): Name=... Class=...
   attributes: ... children: ...`. A line with `not read as a fruit` = something
   named a fruit the finder still refuses: that line is the next fix.
3. **Fruit hunt on, a spawn there:** `going for <name> (..., server spawn)` and
   `STORED ...`; an unnamed one also prints `[BFF] fruit: the unknown spawn was ...`.

## Dodging per attacker: first test (2026-10-12, build 2026-10-12.2)

1. **A Sea Beast:** you no longer hang still over it - you circle it fast.
   Sea events page "now": `... 90 up  ·  round it 40-60 studs at 350/s  ·  last: ...`.
   Its hits should miss you; say which attack still lands (the beam, the
   splash, the bite).
2. **Rumbling Waters (three beasts):** round one at a time, never flying
   through the other two.
3. **A dive:** "under the water - waiting over it" - you keep circling 200 up
   until it is back.
4. **A Terrorshark:** `round it 40-60 studs at 350/s` on its line.
5. **Travel & boat page "pulled back"** (top line): if it climbs during a
   fight, 350 is too fast for the server - lower "Sea Beast: moving at" /
   "Terrorshark: moving at" on Fighting at sea (300 is near what the public
   hubs fly at) and tell me the number that holds.

## Sea events always travelling: first test (2026-10-12, build 2026-10-12.1)

1. **Travel & boat page -> Auto**, then the **Sea events** mode on. The boat
   leaves Tiki west and never circles: Sea events page "now" counts the meters
   up (`travelling · N m from Tiki (of 17000)`).
2. **At 17,000 m:** console `[BFF] seaev: 17000 m from Tiki - 120 deg left,
   7000 m more (turn 1)`; every 7,000 m after it, turn 2, 3 ... - it should
   never hop and never stand still.
3. **After a fight:** back at the wheel and moving again at once.
4. **A ship raid:** `AWAY from ...`, then `clear of ... · never toward it` -
   the boat keeps moving, sliding past it.
5. **I steer:** the same as on the Prehistoric hunt - W goes (and keeps
   going), S stops, A / D turn.

## Water: first test (2026-10-11, build 2026-10-11.4)

1. **Legendary Sword hunt, Second Sea:** hop a few servers. You should never swim
   or take water damage. A flight to his model now only happens when he is
   loaded IN THE WORLD and silent - the console says `[BFF] sword: no answer
   from here - flying to his model at (x, y, z)`: send that line (it says
   where he stands). Never to a copy parked in ReplicatedStorage.
2. **Any mode:** a flight whose end is low, over the sea - you arrive standing
   on the water, never in it.
3. **Submerged Island:** still reached by the submarine and fought down there
   (the deep sea is not touched).

## Panel: first look (2026-10-11, build 2026-10-11.3)

Nothing in the farm changed - only where things are on the panel.

1. **Home:** no scroll bar; 8 rows; the big button says the mode (`Start  ·  Circuit farm`).
2. **Mode -> Modes:** exactly one row says **On** (green). Open Haki berries, pick
   berries, read the line under its switch (`One mode at a time - On turns Raid off`
   if raid was on), switch it on: Raid's row loses its On.
3. **PvP:** on -> Modes shows PvP On; Home's button says `Stop  ·  PvP` and only
   turns PvP off; then your mode is On again.
4. **No text under a switch** anywhere - a long line makes its row taller. Any
   overlap or cut-off word: a screenshot of that page.
5. **Attack -> Details:** the hit-count columns line up (fixed-width font).
6. **Sea events -> Fighting at sea -> Back** = Sea events (not Home).
7. **Mirage:** with it off, pick "Advanced Fruit Dealer", then switch it on: the
   dealer job runs (`[BFF] ... dealer hunt on`).
8. Every mode you use does exactly what it did before.

## Legendary Sword hunt: first test (2026-10-11, build 2026-10-11.2)

Second Sea, at least $2,000,000. Hunt page: **Legendary Sword hunt** on (and Hop on). The swords were renamed in Update 24: **Shizu = Shisui, Saishi = Saddi, Oroshi = Wando** - the switches use the new names; the hunt understands both.

1. At the start the console says `[BFF] sword: <name> is yours already - switched off` for each one you own. Wrong (one you do NOT own switched off, or one you own left on) = tell me which.
2. Each server: Hunt page `here  he is not here now` within a second, then the next server. No Cafe Manager, no 10 minutes.
3. He is there: `[BFF] sword: Shizu: bought` (from where you stand). If it says `not bought - the game said ...`, or you see the character fly to him first, send the line: that means the server wants you close.
4. All three yours: the hunt stops - `now 300 mastery on each, then the Mysterious Man`.

## PvP mode: first test (2026-10-11, build 2026-10-11.1)

Home: **PvP mode** on (it stops the farm), or the PvP page. You fight with your own hands; each helper has its own switch on the PvP page.

1. **Observation view (the most important).** Ken (V2) on, let an NPC or a player hit you until the dodges run out. The outlines and your clean V2 screen should **stay**. PvP page: `view  ON · the game's own view · N offs kept off` (N goes up each time the game tried to turn it off). `would not take the switch` or `a copy of the game's view` = send the line.
2. **Ken back.** Same moment: `ken  OFF · cooldown - back the moment it ends`, then `ON · x / y dodges` without you pressing E. In PvP your **E always turns Ken ON** (it can't turn the view off).
3. **Clean screen.** Next to a Ghoul or Angel V4 with their V4 on: no red / grey tint, no dark edges, no shake. `screen  N effects switched off` counts what was removed. Still dark / grey = say whose race and what it looked like.
4. **Aim.** A player near with PvP on: `PLAYER  <name> · N studs`. A skill / fruit M1 with your cursor pointed away from him: it should go to him (`aimed` shows on the line). Gun: the same. **Since build .7:** your body turns to him on EVERY attack (see "PvP: one opponent, always faced" below). If a flying move now steers to him too, turn **Aim at the player** off for it and tell me.
5. **Dash.** One Q dash on flat ground: `dash  yours N studs · last N studs · x1.5`. The next dashes should go about 1.5x as far. `a guess - never measured` = send it.
6. **Speed.** Run: `speed  112 now · goal 112`. If you get pulled back while running (rubber-band), lower **Run speed** and tell me at what number it stops.

PvP off puts everything back: the view goes back in step with your real Ken, the screen effects, the shake, the speed and dash attributes.

## PvP: speed through V4 and transformations - first test (2026-10-23, build 2026-10-23.1)

Asked (voice): PvP mode's run speed was lost the moment V4 went on, and in Kitsune form (any transformation) - back to base. Now it is kept.

Why it was lost: in a form the script gave the game's own value back on purpose (the old rule "a transformation has its own speed"); and V4 going on makes the SERVER write `SpeedMultiplier = 1.1` over the script's value (seen in your `bff_race_probe.txt`), which was answered only at a moment you were not Busy - in a fight, seconds later. Now: a form gets the attribute in ITS units (the game counts it at a quarter in Kitsune form, so 4x the value; Tiger half; the West Dragon barely - a big number there), and any server write or form change is answered at once with the same speed added, then trimmed to your goal at the next free moment.

1. PvP on, run: `speed  182 now · goal 182`.
2. **V4** (Y) while running / fighting: the number stays ~182 (a blink of the transform animation is the game's own, it holds you still). PvP page shows `· V4`.
3. **Kitsune form** (V): `speed  182 now · goal 182 · Kitsune form` - the fox runs at 182, faster than before. Out of the form: back to 182 as normal.
4. Rubber-band (pulled back while running) in a form only = say which form and the number shown.

## PvP: see far, past the Pale Scarf - first test (2026-10-23, build 2026-10-23.2)

Asked (voice): the Pale Scarf gives 10x vision - in PvP see that far or farther whatever accessory you wear.

How (read in the game's client): the Pale Scarf is `ObservationRange = 10` (x10). The server turns it into `player.VisionRadius` (your Observation level - maxed = 3,000 - x the accessories), and the game's own Ken loop grows the view to that number every 0.3 s and never past it. Nothing else reads it. So in PvP that number is held at **Vision range** (PvP page, default **50,000 studs**; the scarf on a maxed Observation = 30,000) - never lower than your gear's own. The game draws the outlines itself, as with the scarf. PvP off puts the server's number back.

1. PvP on, Ken on: PvP page `far  50000 studs · your gear's own 3000` (with the scarf: `30000`).
2. Players and enemies far away get the Ken outline + HP bar, as far as with the scarf or farther.
3. A player you know is far but NOT outlined = the game has not loaded him on your client (too far for the server to send him) - no number changes that. Say how far he was.
4. Frame drops with many enemies outlined = lower **Vision range**.

## PvP: dash, legs and run speed - first test (2026-10-23, build 2026-10-23.3)

Asked (voice): the dash feels slow - make its animation faster; the run animation does not need to keep up with the speed (legs at a normal pace); and run faster than 182, whatever you wear.

Read in the game's own Dodge script (its bytecode, disassembled): **every dash moves you for 0.3 s**, at a top speed that eases off - your base (Draco 92.5, + 15 with Kitsune's 3 tails, up to 120; Mink evolved 112.5, ...) **+ the `DashLength` attribute**. The animation does not move you: it is only a look, played at 1.65x. So:
- **Dash** slider (PvP page) = how many times as **fast** - and so as far (up to 5x). It is now worked out from the game's own numbers. It used to MEASURE your first dash by being faster than your run - with your run at 182, a plain dash never was, so it fell back to a guess: the old x2.5 was much less than 2.5x.
- **Dash animation** = the look, 2x the game's by default (1 = the game's own).
- **Legs at a normal pace**: the run animation held at the pace of a 50 studs/s run however fast you go.
- **Run speed** slider now up to **400**. Yours is a number the game is made to reach - not a multiple of your gear - so Pale Scarf or Pilot Helmet changes nothing; only the slider's old 185 held you.

1. PvP page: `dash  top speed 108 -> 269 studs/s · x2.5 · 0.3 s each` (Draco with 3 tails). Q: clearly faster and farther than before.
2. Console, first 3 dashes: `[BFF] dash anim: <name> / <name> (dash)`. `(nil)` instead of `(dash)` = its name is not what I read - send the line.
3. `anim  x2.0 · N dashes sped` goes up with each Q; the dash pose snaps faster.
4. Run at 182+: `legs  held at a 50 run · you 182` - the legs no longer blur.
5. Run speed 250 / 300 / 350: pulled back (rubber-band) at some number = send that number. A dash slower than your run (x low, run high) feels like a brake - raise Dash.

## PvP: hop to busy servers - first test (2026-10-23, build 2026-10-23.4)

Asked (voice): every hop landed in a server with one player - no one to fight. The hop sorted servers fewest players first (made for the hunts: fewer hunters). Now:
- **PvP mode on** = every hop goes **most players first** (PvP page "Busy servers", on by default). Full servers are skipped (they cannot be joined); the busiest one with a free slot goes first, then the next.
- The hunts keep their own order (Servers page) - that radio also has "Most players first" now.
- PvP page, servers: **Hop to a busy server** button and the hop's own line.

1. PvP on, **Hop to a busy server**: the line says `hop: joining a server with N players` with N near the server's size (11 of 12, ...), not 1.
2. After the join, PvP mode is on again by itself (your saved setting).
3. Joins refused one after another (busy servers fill up fast) = send the `[BFF] hop:` console lines.

## Draco V4 trial mode (v4_trial.lua, its own script)

The Trial of Flames: relics at the bottom of the cave, extractors ~1,300 studs up, lava
climbing every eruption. This flies it. A separate script, not a fast_farm page: turning it
on stops fast_farm (fast_farm's body lock writes the character every frame and would fight
the flight).

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/v4_trial.lua?cb=" .. tick()))()
```

Panel "V4 TRIAL" (top right, drag by the title). **TRIAL MODE** on = you fly:
**WASD** flat where the camera faces, **Space** up, **Ctrl** down, no keys = hang still.
Noclip, and the lava guard keeps you on top of the lava while it climbs (with room for
its speed). **Next** flies you to what is next (relic pad / its extractor / the way out):
up = climb first, then across; down = across first, then down. **Auto** (off) = Next
until all three are in; a fly key takes over and switches it off.

How the trial works was read from the game's own client, not guessed - see the header of
`v4_trial.lua`. The relic shield is the game's own: a relic in your hands + still for 1 s.
Hovering is still, so a held relic shields you while you hover.

### First test (each answer decides the next fix)

1. Load it anywhere first: TRIAL MODE on, fly round with WASD / Space / Ctrl. Anything
   pulling you back (rubber-banding) = say so, with the speed shown.
2. In the trial (after the Statue's "Yes"): the panel's `Relics 0/3` line appears. `not in
   the trial` there = send a screenshot (Map.DracoTrial was not found).
3. **Next** -> it flies to relic 1 (green). Does hovering over the pad PICK IT UP? (`Hands
   green (1)`.) If not: press E there yourself, and tell me what the game showed (a prompt?
   nothing?).
4. **Next** again -> up to extractor 1. Does hovering there DELIVER it? (`Relics 1/3`.)
5. During an eruption: does `Lava  HOLDING YOU UP` show, and are you ever sent back to the
   floor anyway (= the server has its own lava check - tell me)?
6. Console lines `[BFV4] ...` from the whole run.

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
python tools/locate_test.py                      # where a species is + the pile, real code, 54 checks (Sky Bandit, new spawns, raid pile, sides, random mode, the pile holds)
python tools/raid_test.py                        # raid mode's view of the game: both timer paths, newest Island N, stale islands (within RaidReach of you; farther only while the timer is up)
python tools/raidloop_test.py                    # raid mode's life, real code, 35 checks: the raid over = stay (no flight, nothing fought), the stuck watch (12 s no HP off = relocate in a fight and out of one, spots, the straggler outside the radius, skips forgotten, HP off / a kill = progress), the loop (cheapest stored fruit under the cap - 3 inventory reads - never the dear one, a dear one carried = nothing traded, the $100,000 way, level 0 = off, the button flown to / clicked / not loaded / no fireclickdetector, no raid = 10 s, third = 2 min)
python tools/pose_test.py                        # where you hang + the remote hit's reach, real code: Port Town, ledge, 120 up, stay above
python tools/probe_test.py                       # the M1 probe, real code: the game's own hit sender tried first; "nothing landed" tried again after 12 s, not final for the server
python tools/fire_test.py                        # where each M1 way goes, real code: remote (both shapes), fruit click per enemy, held gun, past the heat, a gun's click aimed for its burst, a sword's click
python tools/gun_test.py                         # a gun's M1, real code: the one enemy (kept while it lives, then the weakest), the button through a whole heat cycle (press / keep / let go / locked / again), the frame watchdog, the game's own shot found + paced + seen as the game's, the mastery farm (only that weapon, loaded, read, stops at 500 once)
python tools/team_test.py                        # the team pick, real code: SetTeam until on a team, the screen's button never fired, Marines when picked, never a switch, off = nothing
python tools/berry_test.py                       # the berry pick, real code: a real hold first (a game refusing the instant fire still gets picked), fireproximityprompt as the fallback, ~15 s then left a minute, taken by another = out at once, a stop = out at once
python tools/autoexec_test.py                    # autoexec_team.lua, real file: Pirates at every join, other games untouched, never a switch, a minute at most, place read after load, call errors survived
python tools/leash_test.py                       # checkPutBack: pull limit measured (contrast rule), random mode's in-place escalation
python tools/magnet_test.py                      # the magnet's frame, real code: frozen while held (again if undone), each keeps its own ring spot through deaths / reorders
python tools/flower_test.py                      # the Fire Flower hunt, real code: the flower found, held like a player (fire fallback), stuck / gone / picked, the clock from the first kill, 3-min no-kill exit, Third Sea, hop off stays, camps in turn
python tools/aim_test.py                         # the aim lock's camera solve, real code, every cursor pixel lands on the pile
python tools/hidden_test.py                      # camera-free aim, real camera block in a simulated frame loop: drawn = your view, keys see the aim
python tools/sea_test.py                         # the Prehistoric hunt + volcano event, real code, 288 checks: sea travel (your keys even on auto, islands sailed past, no clock, no hop, a lost boat = off), a bone 0.5-1 s, the egg 4 s still after E, home by respawn (Health 0 -> BreakJoints -> Head only while alive, at Tiki, never flown back, once, chalice / switch off = none, refused = hop after 20 s), relic-first priority (free golem > vent unless pressure high + relic healthy), the golem holder (lifted, held = a write that stuck), never put back, meters (Humanoid / attribute / screen text, this panel ignored), learned vent keys, aimed M1 at the vent, the wheel seat (not the harpoon's), your keys (A/D turn, W go, S stop, chat typing ignored, no hop by distance), meters, the Mirage hunts (Mirage = onto it only; dealer: front of his face, ReplicatedStorage / workspace / nil instances, a stale far copy skipped, the island searched until he streams in, a parked spot corrected, again on the same Mirage; chests only, wait for the island; gear: worth it by the sky, sailed past, hands off, run over, Part fallback, gone on your turn; no Mirage = sail), the wheel, buy/sit/sail/far edge/boat lost, start/defend/loot/idle, vents (4 live signs, fruit first, aimed at the vent, key that did not fire skipped, aimed M1), golems caged / fight broken by a vent / magnet off, lava off, bones, egg
python tools/seaev_test.py                       # the sea events hunt, real code, 305 checks: dodging per attacker (a beast circled at 350 in 40-60, the band kept / eased / re-picked / clamped, Terrorshark the same, Piranha + Leviathan unchanged, Rumbling Waters' other beasts kept out but never nearer the one fought than 40, a dived beast circled 200 up); HP text / value / attribute, the names (Terrorshark not a Shark, every ship raid), groups (five piranhas = one, three beasts = Rumbling Waters = one, named only once all are in), kill verdict (HP 0, gone at 10%; despawned = not counted), count kept across sessions + reset, the Spy only ever asked ("1", never "2"), past-cooldown kept, goal + stop, always travelling (the wheel's own steering, auto legs that never hop - 300,000 m sailed in the test, never nearer Tiki than 9,500 m - manual = no legs, a fresh run near Tiki), away from a ship / clear of it (never toward it, never stopped) / travel, the beast fight (off the seat, boat held 150 up, 90 over, aim on its body, in close after 6 s, dive = wait), fish fight (M1 + every skill, in place, switched-off never picked), whose M1, a lost boat, a lifted boat's water line, the 60-stud hitbox (grown / put back / only a HumanoidRootPart / hunt off mid-fight), the camera 90 off, transformed = only that fruit's moves; the Leviathan (its parts, HealthEnabled, the part to hit - your share per segment, the head LAST even with every part enabled / segments respawned, no boat touched, the circle with the hunt off, its heart = hands off, its head down = count reset, the switch on = only it: waiting = hands off, gone mid-fight = held over the water 20 s, switched off = undone; its attacks: out of a red area / off a beam's line sideways (pure), the Bubble kept 7 s after it goes, the beam charge / beam / tornado shapes, an ice spear near = up, every part's animations watched, a segment back mid-fight watched, in close to 25 after 6 s; HP from a Humanoid last; the hitbox never shrunk); Kitsune form first (verdict pure + live, V in / out / cooling / dead 3x, form per class, re-test every 5th, fish in form = caster, fish out of form = the farm's fight with Dragon Talon M1, fruit + melee only, no inventory loads, out of form before the wheel, fish learning saved)
python tools/body_test.py                        # the body lock, real code: held where asked; a sea fight's floor (never under the water, asked or every frame); a knockback / pull under 500 studs not adopted in a sea fight, a respawn still followed, the old rule outside
python tools/silent_test.py                      # the silent aim, real code: nothing hooked at load; __index only while casting, the game's own back 3 s after / on stop; __namecall never; the game's skill aim (ReplicatedStorage.Mouse): its Hit / Target the target while casting, its own every-frame writes kept aside and put back, its metatable restored, works with no hookmetamethod
python tools/ember_test.py                       # the Blaze Ember hunt, real code: quest text, trees' order (giants never, bamboo last), afar -> at the Dragon Hunter, the Head back notice, embers first, the stops
python tools/rotate_test.py                      # every weapon you carry, the inventory rotation (LoadItem order, rested, gap, put back at stop), the saved-keys cleaner
python tools/vmagnet_test.py                     # the Volcanic Magnet before the sail: held = sail, craft (here, else at the Dragon Hunter, 3 refusals = without), scrap (Forest / Millionaire), embers borrowed (blocked = without)
python tools/fruitguard_test.py                  # the fruit guard, real code: never a weapon, never equipped, no click with one in hand
python tools/elite_test.py                       # the hunt, real code, 95 checks: Elite Hunter words, server pick, pickFruit (price, drops, traders), berries (names, nearest wanted), the Barista Cousin's recipe (not here / not picked / learned / cannot pay), the Legendary Sword Dealer (29 checks: asked from here, old names, owned from the item list / legacy list / backpack, a count of 0 is not owning, flown to him only when loaded, money first, already yours, Second Sea only, waits for your character), hop() refusing on the chalice, the join (always the game's; a token refusal remembered; why in words), carry-over, the director (the chalice in every hunt; ONLY the hunt switched on)
python tools/news_test.py                        # the server news, real code, 96 checks: MoonPhase attribute / decal / blue, day+night number round the clock (the noon turn, midnight), the full moon tonight / now / in N nights in real minutes, the measured speed (jumps, stops, gaps ignored), the turn learned + bff_sky.json, islands (up at the join / spawned / gone / lasted), elites + raid bosses, Cake Prince asked only on screen, fruit, order + BREAKING, the chip
python tools/pvp_test.py                         # PvP mode, real code, 289 checks: who is picked (the one nearest your MOUSE on the screen within the catch area - the cursor beats distance to you, both screen axes, never behind the camera / dead / past the range / with no screen place, two Marines never; the one you are on keeps 1.5x the area, stolen only when another is 0.8x nearer), per attack PER WEAPON (the held weapon's own switches; a sword Z still playing after a swap stays the sword's; a held key switched off = your own mouse, also at its release while its move plays - Busy or Holding - never turned, never re-sent), the face window (every attack key / M1 held, the move playing within 3 s of an attack, 0.4 s after, only in range, never shortened), WHERE HE WILL BE (his path: velocity, gravity in a jump, a teleport forgets (also a blink your screen smooths over 3 frames; a 300 studs/s dash kept), a blink in progress leads 15 studs at most, a dash dies out, a flight kept; the lead time: none for a ray gun, ping + buffer + travel, scaled, <= 1 s; on the ground = over the floor ahead, a jump falls, a flight straight, never under the floor; the whole chain against a simulated network lands within 0.5 stud of where the server has him), THE AIM WIRING on Roblox stubs (pick -> his path -> the skill / gun points, a ray gun at him as seen, a Cannon ahead at its own speed, lead off / strength, up a slope, onto a ledge, a move keeps its target, a swing faced at him as he is / a skill at where he will be, the aim re-sent while a move plays - legacy remote first, CFrame for a Mouse value, never Love, never a swing, stops with the move, 20 a second - the game's gun snap off only while aiming, his Ken said, a teleport = no wild lead, COOLDOWN TESTS (Flash Step's cut on the game's own FlashstepCooldown over the server's gear value, capped 95 %, put back; the skills test's IgnoreCooldowns only on a skill tool, only ours taken off, presses vs moves started), a ray gun's spread off only for a single-ray gun aimed at him and put back - another gun's first, never a shotgun - your shots at him against his HP drops), far vision (the game's VisionRadius held at the goal, never under the server's own - the Pale Scarf's 30,000 over ours answered, a goal under it = the server's, a level up = the new base), the speed attribute (the game's own 36 x formula hits the goal in one write and stays; helmet = the base; already faster = the base back; capped at +288 speed in any form; every form's rate is the game's own - Kitsune / Tiger / West Dragon / Mammoth / Buddha reach the goal in their units and stay; V4's server 1.1 over ours = written again at once while Busy, trimmed to the goal at the next clean look - the probe's own 3.8556; V4 over = at once; into / out of Kitsune while Busy = the same speed carried at once, a stale look in the new form skipped), the dash (the game's own base speed per race / form - Draco 92.5, tails +15 to 120, Mink evolved 112.5 / Agility 120, Ghoul at night, Heightened Senses, Leopard, Mammoth - and x of base + gear exactly, gear over ours = the new base), the animations (Dash* = dash, run / walk family = legs, skills untouched; the legs held at a 50 run's pace, ours kept, the game's rewrite held again, under the pace / standing = the game's own), the Ken clock (2 s, every 0.5 s, cooldown waits, 3 s after 20 refusals), blinding effects; the Ken view switch on a fake game object (the game's OFF dropped in PvP, through for a dead life / PvP off / view off, unwrap gives the class method back and syncs to your real Ken, a new life's old object gets no OFF, a frozen object refused)
python tools/lock_test.py                        # the settings lock, real code, 27 checks: only what you changed is written (never a function), reload = yours back, a NEW default reaches untouched settings, a key / weapon a new build added keeps its default, a list is yours whole, a setting whose kind changed = the new default, unlock = defaults next load, an unlocked file's settings never used, cannot write = said NOT kept, a broken file ignored
python tools/panel_test.py                       # the panel, real code, 694 checks: builds, 28 pages, Home fits its body, one mode at a time (PvP / Leviathan on top, off = the mode underneath, the circuit has its own Off - nothing on = No mode), the line under a mode's switch, the Mirage job kept while off, Start names the mode, Back walks the pages you came through, each mode page's own switch first / folds last; CENSUS - every control fired: each of the 172 CFG keys the old panel changed is still changed, from ONE page, nothing new but MirageJob; every page within 3 taps of Home
python tools/panel_preview.py                    # not a test: draws every page as HTML (tools/panel_preview.html) - spacing, overlap, cut-off words at a glance
python tools/water_test.py                       # water is rock in EVERY mode, real code (BODY + TRAVEL): the line (slab top + 4, only over the slab, not in the deep sea, right before the raise too), the lock never under it in any mode (a sea fight's own floor when higher), thrown under = lifted, a flight to a point under the water never written under it and arriving ON it, a flight starting under it, an instant hop, off the slab and at Submerged Island untouched
python tools/race_test.py                        # race V4 / V3 (2026-10-12), real code, 117 checks: nothing fires while the script is idle (no mode running, PvP off); Start with no mode starts nothing; the V4 gate; the user's V3 clock (28 s from a SEEN activation, then every 0.5 s; no signal = a 3 s burst, the next wait from its end) simulated against a fake cooldown of 29 / 29.5 / 30 s - never missed, lateness bounded; whose roar (yours / streamed / a stand-in, never an ally's that buffed you); V4's weapons (no Awakening / ability tool, sword first, a transformation fruit's V never, a fruit's form only it); M1s in turn; the live ticker on a fake game (the game's Y, the Awakening call as the fallback and kept, both refused = 3 s, your own Y, no tool / dead / off, V3 on the roar / the ability child, not an ability TOOL, the moon turn, the probe file, the panel lines, unhook). rhythm / rotate / seaev / sea suites check the V4 wiring (M1 turns, fast keys, no loads, the attack list, the sea's types, the moon stamp)
python tools/trial_test.py                       # v4_trial.lua's pure decisions, real code, 41 checks: relic by its painted metal (not gem / particles), Next's step (carried -> its extractor, empty -> lowest not in, all in -> out), the lava floor (+ the climb's lookahead, none for draining), the route (up: climb first; down: across first), travel never overshoots / hitch-capped, the fly keys (flat W never sinks, diagonal not faster), the game's teleports adopted, drift held
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
