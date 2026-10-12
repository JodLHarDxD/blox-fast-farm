# Race V3 / V4 - plan

Status: **BUILT 2026-10-12 (build 2026-10-12.5)** on your "go": every decision at its
recommended option, D3 = your V3 rule. Added while building: a rig child whose fruit you
do not carry is no fruit form (auto V4 now fires at sea too - a race model named like a
rig must not lock every weapon out). README "Race V4 / V3: first test".
Date: 2026-10-12. Script: fast_farm (the voice message said "the script"; farm_pro is
not used any more - say so if you meant something else).

Note: on 2026-10-10 you said "leave V4 as it is" when I offered an auto V4. This request
replaces that.

## What I understood

Two things, both **ON by default**, in **every** situation - farming, raids, Random, the
elite hunt, sea events (Sea Beasts - "CB" in the voice message), the Leviathan, PvP, or
you playing with the farm stopped:

1. **Race V3 and V4 fire by themselves.**
   - V3 (your T): pressed the moment its cooldown is over.
   - V4 (your Y): pressed the moment the V4 meter is full.
2. **While V4 is on, the script attacks with every weapon you have.** Fighting style,
   fruit, sword, gun: every skill and every M1, whatever the Attack page says. The Attack
   page setup is only for when you are NOT transformed; when V4 ends, it is back.
   - Every attack is aimed at the NPC, never at your mouse (silent aim, as today).
   - The one exception you named: Sea Beast fights - no M1 there (M1 does not hurt them).

Why every weapon is worth it - the game's own text for the first V4 gear of every race
(`PlayerGui/TempleGui/Draco.lua`, Draco "Ancient Powers"): **"Upon transforming, receive MAX
STATS as well as increased damage and speed, and heal by 10%."** So in V4 a weapon with 0
points hits like a maxed one.

In PvP you press the keys yourself (PvP mode does not attack - built that way on 10-11).
There the script only fires V3 and V4.

## What the game does - read in its own client code (decompiled v4623)

**V3 (T)** - `StarterCharacterScripts/RaceAbility`:
- T exists only if one of these tools is in your Backpack or character: Last Resort (Human),
  Agility (Mink), Water Body (Fishman), Heavenly Blood (Skypiea), Heightened Senses (Ghoul),
  Energy Core (Cyborg), **Primordial Reign (Draco)**.
- T sends `Remotes.CommE:FireServer("ActivateAbility")` if you are alive. That is all. There
  is **no cooldown check on your side** - the server decides; a T while cooling does nothing.
- The cooldown itself is nowhere the client can read (no bar, no attribute in the code I read).
  Public hubs (HOSTI/Opensurs, Tw3ch1k, hiuhub, a PvP hub) all just send it every 0.5-1 s.

**V4 (Y)** - `Controllers/UI/RaceV4Button`:
- Meter = `Character.RaceEnergy` (0 to 1). Transformed = `Character.RaceTransformed`. Both
  are written by the server (your 10-10 test: a fake-full meter is refused).
- Y: if not transformed and the meter >= 1 -> `ReplicatedStorage.Events.ActivateRaceV4:Fire()`.
  The `Awakening` tool (in your Backpack) listens and asks the server.
- Three public hubs skip that and call the tool's server function directly:
  `Awakening.RemoteFunction:InvokeServer(true)`.
- `RaceTransformed = true` is how the script knows V4 is on (the game's HUD glow reads it).

## How it would work

```
RACE  (own small ticker - runs whether the farm runs or not, PvP too)
  V4: the meter reaches full (the game's own value-changed signal, + a check every 0.25 s)
      and not transformed and the Awakening tool is carried
        -> the game's Y            (D2)
        -> not transformed 1.5 s later -> the Awakening call
        -> the way that worked is used first from then on; both refused = try again in 3 s
  V3: a race ability tool is carried                                   (D3, your rule)
        -> V3 seen going on (your T or the script's) = the clock starts
        -> nothing for 28 s
        -> then T every 0.5 s until V3 is seen going on again -> the clock again

ATTACK  (the farm's fights)
  RaceTransformed and "Every weapon while V4" on:
      every weapon you carry, every key (D4, D5)
      skills: each the moment it is ready, the next key the moment the game took the last
              (the sea fights' rule)
      M1: every weapon's M1 in turn, in the gaps (D6)
      fights with their own rule keep it (D7)
  else: your Attack page, exactly as today
```

## Decisions - pick or veto each one

**D1 - when V3 / V4 fire.**
A (what you said): any moment you are alive and the switch is on - farm running or stopped,
any mode, PvP, playing yourself.
B: only while a mode runs or PvP mode is on.
Note on A: V3 also fires while you stand in town, so its cooldown runs before your next fight.
The V4 meter fills in fights, so A practically never wastes V4.

**D2 - how V4 is fired.**
A: the game's own Y first; if you are not transformed 1.5 s later, the Awakening tool's
server call (the hubs'). Whichever worked is used first from then on.
B: the game's own Y only.

**D3 - V3 timing - YOUR RULE (2026-10-12): V3 cools about 29-30 s.** From the moment V3
really goes on, nothing for 28 s; then T every 0.5 s until it goes on again; then 28 s again.
No blind spamming. "28 s" and "0.5 s" are sliders.

"Really goes on" has to be SEEN - the game sends nothing back for a T. What the client sees
(decompiled v4623):
- **Draco:** the game's effect `DracoRace.Roar` arrives on `Remotes.FX` naming you as the one
  who roared (a roar that buffs allies and debuffs enemies for 10 s in 150 studs -
  `DragonRaceVariables`). Most likely your V3 (Primordial Reign) - the first run confirms it.
- **Other races:** the game marks Mink's Agility and Ghoul's Heightened Senses with a child of
  that name on your HumanoidRootPart (the game's own run-speed code reads it); the same is
  watched for every ability name.
- **Your own T counts too** - the clock starts from whoever pressed it.
- **Nothing ever seen** (an unknown race, or the game changed): the clock starts from the
  burst - T every 0.5 s for 3 s after the 28 s, then 28 s from that. About 7 presses a
  cooldown instead of 60, never more than about 1 s late, and it never drifts.
- **The Mirage moon + T** (the Mirage hunt hands you the character, "YOUR TURN"): the script
  sends no T - your own T has to find V3 ready, or the gear does not come.

**D4 - which weapons in V4.**
A: every weapon you **carry** (your slots: fighting style, fruit, sword, gun).
B: A + swords / guns loaded from your inventory when every carried skill is cooling (the
Attack page's "Swords and guns from your inventory"). More skills; each load costs about
0.5-1.5 s, which is little in a V4 that lasts minutes, but it swaps your sword / gun out
(put back when the farm stops).

**D5 - which keys in V4.**
A: Z X C V F on every weapon, **except a transformation fruit's V** (Kitsune's V puts you in
the fox form; while in a fruit form the game refuses every other weapon, so V4's "every
weapon" would end there).
B: A without F (F is a movement move on some fruits).

**D6 - M1 in V4.**
A: every weapon's M1 in turn - 4 swings each (slider), sword -> fighting style -> fruit ->
gun - in the gaps between skills. A switch of weapon costs about 0.12 s.
B: one M1 weapon, as today (your pick, else the sword); only the skills widen to every weapon.

**D7 - fights that already have their own weapon rule.**
- **Sea fights** (Sea Beasts, Rumbling Waters, Terrorshark, Piranha, Leviathan): no M1 out of
  Kitsune form - unchanged. Out of form, the weapons widen from your sea setting
  (fruit + melee) to all four while V4 is on. In Kitsune form only Kitsune's moves - the game's
  rule, nothing to choose.
- **A fruit form on land** (Kitsune, Dragon, ...): only its moves - the game's rule.
- **The mastery farm** (one weapon, e.g. Dragonstorm to 500):
  A: it stays that one weapon in V4 (another weapon's hits share the kill's mastery).
  B: V4 wins - every weapon.
- **The volcano**: vents unchanged (they already use every carried tool); the golems keep
  their M1 weapon (Cursed Dual Katana), their skills widen to every weapon.

**D8 - the panel.** A: the Attack page gets a "Race V3 / V4" part at the top:
- switches "V3 when ready", "V4 when the meter is full", "Every weapon while V4" (all ON),
  the "M1s per weapon in V4" slider (D6 A);
- one line: `V4 meter 73 %  ·  V3 sent 0.4 s ago  ·  attack: your Attack page`, and in V4:
  `V4 ON  ·  every weapon: Dragon Talon, Kitsune, Cursed Dual Katana, Dragonstorm`.
The status line at the top says `V4 - every weapon` while it lasts.

Silent aim: nothing new. Every key the script presses is already aimed at the NPC (Silent aim
switch, on); in V4 the extra weapons go through the same caster, so they are aimed the same.

## What only your first run can tell

- How V4 went on: console `[BFF] race: V4 on - the game's Y` or `- the Awakening call`, or
  `V4 refused` (meter full but no transform with both).
- Which signal showed your V3: console `[BFF] race: V3 on (DracoRace.Roar)` and the panel
  line `V3 on 12 s ago - next T in 16 s`. If the panel says `V3: no signal - pressing on the
  clock`, the probe file says what to watch instead.
- A probe file `workspace/bff_race_probe.txt`: what the game puts on your character (children,
  attributes) and which effects name you, in the second after a T and when V4 starts. It also
  shows that Draco V4 adds nothing that looks like a fruit form (if it added a child named
  "Dragon", the script would think you are in the Dragon FRUIT's form and use only Dragon
  moves).
- V4: you said it lasts as long as you keep attacking (3-4 minutes when attacking properly) -
  the panel line shows the meter while transformed, so we see how every weapon keeps it up.
- In V4, the Attack page's per-skill lines: every weapon should say "hit the pile".

## The build, if you say go

- New section RACE (a builder function - the main chunk is at its 200-local limit): `P.race`
  with the ticker, `P.race.allNow()` (transformed and the switch on), the probe, the readout.
- WEAPONS / RHYTHM: `usedWeapons()` gets the V4 branch (after the mastery farm, before the
  Attack page); `attackTick()` turns the M1 in turn and skills-first while V4; the inventory
  rotation stays out in V4 (D4 A); the sea fights' weapon-type filter passes every type in V4.
- Tests: a new `tools/race_test.py` (+ stubs / cases): the V4 gate (meter, transformed,
  Awakening carried, fallback, refusal wait), V3 (tool carried, rate, Mirage pause), the attack
  list in V4 (every weapon, V never on a transformation fruit, F per D5, mastery / golems /
  sea / fruit form rules), M1 in turn, back to the Attack page when V4 ends; panel census
  (new keys in panel_cases NEW_OK). Every suite green + mutation check, like the rest.
- README "Race V3 / V4: first test". Build stamp 2026-10-12.5 (another session is landing the
  fruit-storage change as .4 right now; this build starts from its push).
