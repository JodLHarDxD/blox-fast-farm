# Sea Beast hunt + Leviathan - plan

2026-10-08. Status: **BUILT 2026-10-09 (build 2026-10-09.1), with the scope you changed:**
- Fought: Sea Beast, Rumbling Waters, Terrorshark, Piranha (Shark a switch, off).
- Ship raids (brigades, the Fish Boat and its crew, haunted ships): ALWAYS fled, never fought.
- The Leviathan: no code at all (D4 dropped). The Spy is only ASKED (read only) for the count.
- New: the sea event COUNT for the Spy's cooldown (20+ killed sea events after a Frozen Dimension).
- D2b (Kitsune transformed first, V pressed by the script) NOT built: how to read "transformed"
  is unknown, and a blind V can untransform you. The HP learning ranks whatever lands instead.
What was built is in the fast_farm.lua header of "SEA EVENTS" and README "Sea events hunt".

## What I understood

You want fast_farm to hunt Sea Beasts and the Leviathan. You are right that they are
not normal NPCs, and you asked how to deal with that. This file answers that question
first, then lists the build choices. You can approve or reject each one (D1-D7).

## Why the normal farm cannot fight them

The normal fight works like this: find enemies in `workspace.Enemies`, read their
Humanoid health, pull them into a pile with the magnet, hit the pile with the M1
remote, and add skills on top. A Sea Beast breaks every one of those steps, and the
Leviathan breaks even more.

| | Normal enemy | Sea Beast | Leviathan |
|---|---|---|---|
| Where it is | `workspace.Enemies` | `workspace.SeaBeasts`, named `SeaBeast1`... | `workspace.SeaBeasts`: `Leviathan` (the head), `Leviathan Segment`, `Leviathan Tail` |
| Health | `Humanoid.Health` | no Humanoid: a `Health` value inside it (plus a `HealthBBG` text label) | the same, plus a `HealthEnabled` attribute that is true only while the part can be hurt |
| Magnet | works | **no**: it is a giant model the server owns | **no** |
| M1 (hit remote) | works | **immune**. Some fruit M1s are the exception, and **Kitsune base and full form is one of them** (wiki) | immune, except Dragon, Kitsune, Gas, Yeti, Tiger, Mammoth, Gravity and explosive guns |
| Skills | all of them | **area skills only**. Single-target skills do 0 (wiki example: Shadow Z) | area skills only (Magma X is the exception) |
| Hides | never | **dives**: it goes under the water, and while it is under you cannot see it or hurt it | Frostbite Dive does the same |
| How it spawns | its camp respawns it | only near a boat at sea, Sea Danger 1-6 (every 4-10 min at 5, every 2-5 min at 6) | Frozen Dimension at Danger 6, then the Frozen Watcher, **who needs 5 or more players in your boat group**. Solo option: a Levi fish caught with a rod that has the Curse of the Leviathan |
| Reward | last hit / quest | your share of the damage, given automatically | at least **8% of the damage on EACH segment**. The heart must be harpooned with the Beast Hunter and towed to Tiki within about 1-2 min, and if you die you lose it |

So adding their names to the target list will not work. They need their own
**target adapter** and their own **fight loop**:

```
find it (SeaBeasts folder)
 -> is it up?  (surfaced near the sea plane / HealthEnabled = true)
     no  -> wait above where it went, cast nothing (keep cooldowns)
     yes -> hover where its moves miss (high: Water Beam can't push you into the sea)
            -> fire every ready area key, aimed at it (silent aim)
            -> read its Health before/after each key = LEARN which keys hurt it
 -> dead -> back to the boat -> wait for the next one
```

The learning step answers "which of my moves work on it?" without a hand-written
list. A single-target move never lowers the HP, so it sinks to the bottom of the order
on its own. If the Kitsune M1 does lower the HP, it gets used.

## What fast_farm already has (reused, not rewritten)

- **Boat**: bought at the Tiki back dealer, you seated, driven by writing its pivot,
  boat HP read, a new one bought when it is lost (SEA HUNT / Prehistoric hunt).
- **Silent aim at a point**: the vents. Skills land where the script points while
  your mouse stays free.
- **Learned keys**: the vent code already learns which key closes a vent. The beast
  version is the same idea with "HP went down" in place of "vent went out".
- Weapon rotation, cooldown bars, energy, haki, escape, the panel kit, and the
  game's own inventory count (fragments / beli before and after).

About 70% of what is needed exists. New code: the beast adapter, the fight loop, a
patrol at the chosen danger level, the Leviathan rules, and a panel section.

## Decisions (approve or veto each)

### D1 Where it goes
**Recommend: inside fast_farm**, as new switches on the Hunt page. Each one does only
its own job, like the other hunts (your rule). The other option is a standalone script
like v4_trial.lua, but that copies about 1,500 lines of boat and aim code. Because of
the 200-register limit, the code goes in a builder block like the other sea code.

### D2 Sea Beast hunt (the first build, playable solo)
1. No boat: buy one (your pick; default Beast Hunter, then Guardian / Lantern) and sit.
2. Sail to **Danger N** (slider 1-6, **default 5**) and **patrol there slowly in a
   circle**. Sea events keep coming while a boat is near, whether it moves or not
   (wiki). This is not the Prehistoric hunt's race to the west.
3. A beast is up (a `SeaBeast*` with HP > 0 within 2,500 studs): stop the boat and
   **park it lifted 150 studs up** (the beast's moves and Piranhas miss it there),
   then fly to the beast. The boat is lowered back after the fight.
4. Fight **one beast at a time**: the nearest, kept until it dies (wiki advice; Rumbling
   Waters brings 3).
   - Surfaced (its root within 175 studs of the sea plane): hover **80 up / 50 back**
     (slider). If nothing lowers its HP for 6 s, move in closer. This is fast_farm's
     existing "from high -> close" rule, needed because a Kitsune M1 has to reach the
     beast.
   - Dived: wait at sea + 200 above where it went, and cast nothing.
   - **ATTACK = M1 AND skills, both, always** (your rule, 2026-10-08: normal farming
     is M1 only, sea events are not). Between M1s, every ready key of the current
     loadout (D2b) is fired, ranked by what has been learned. A key used 4 times
     without lowering the HP goes last.
   - **AIM LOCKED ON THE TARGET**, the same as the Dragonstorm mastery farm. From the
     moment a target is picked until it dies, the silent aim follows its body every
     frame: `Mouse.Hit / Target / X / Y / UnitRay` answer for the target, and the
     camera is turned to it. So every M1 click and every skill lands on it, and your
     cursor is ignored. The hook goes in only for the fight and comes out 3 s after it
     ends (the existing rule; a hook left on for the whole session hid NPCs).
   - The M1 is the game's own click, aimed (the Kitsune M1, the Skull Guitar M1). The
     hit remote is built for Humanoid enemies in `Enemies`, and a sea beast has neither.
     Terrorshark / Piranha / Shark do have a Humanoid, so the normal M1 ways work on
     them too.

### D2b Loadout, Kitsune first (your plan, 2026-10-08)
- **Round 1 = Kitsune form.** V transforms once the tail bar is full. While
  transformed only fruit moves exist: **M1 + Z X C F**, all of them aimed.
- **Verdict** after the target has been up for 20 s (slider). The damage per second is
  read from its HP, and each action is credited with the HP it took off.
  "Lands" = at least the floor (slider, default 0.3% of its max HP per second, which
  is a kill in under 6 min). Below the floor it **untransforms and switches to Base**:
  - **Sanguine Art** M1 + Z X C V (wiki: "All moves hit Sea Beasts", and its Z bats
    hit even though Z is single-target),
  - **Kitsune base** Z X C F,
  - **Skull Guitar** M1 + skills (the wiki's Guns page: the only 3 explosive guns,
    Cannon / Bazooka / **Skull Guitar**, have M1s that hurt sea events),
  - Dragonstorm **skills only** (see the research below).
- The verdict is **not forever**. It is re-tested on every 5th target, because a "no"
  that is never re-checked is the old M1-probe mistake. A panel switch lets you
  force it: **Auto / Kitsune form only / Base only**.
- The panel shows what was measured, for example `Kitsune form 1,240 HP/s · Base
  2,010 HP/s · best key: Kitsune C`.

### Research answers (2026-10-08)
- **Dragonstorm held M1 on a Sea Beast / the Leviathan: NO.** Its wiki page says
  "[TAP] Normal Attack: Cannot damage Sea Beast and Leviathan ... Single target". The
  decompiled client says the same: `HitscanSingleShot` = one raycast that hits one
  part, and sea beasts ignore single-target hits.
- **Dragonstorm on a Terrorshark: YES**, it is a good choice. Wiki: "Great for
  Terrorshark and Ship Raid hunts", and the X knockback helps against it. The
  Terrorshark is a normal Humanoid enemy, so the held-gun code works as it does now.
- **Dragonstorm skills on a beast: probably yes.** Z Draconic Cascade and X Infernal
  Comet both explode with an area hit (X needs mastery 250). The HP learning confirms
  it on the first beast.
- **Kitsune**: the wiki's Sea Beast page lists Kitsune base AND full form, with "all
  five clicks", as M1s that work, and the Leviathan page lists it too. Transformed C
  = "massive AoE, extremely long range". Transformed can walk on water. Not known:
  how far the transformed M1 reaches from a hover, hence the move-in-closer rule.
- **Sanguine Art**: "All moves hit Sea Beasts". It is the right fallback, as you
  guessed.
5. Dead (HP 0 or the model gone): count it, plus the fragments / beli gained (the
   game's own count, not a guess), then go back to the seat and patrol.
6. The boat is sunk or lost: buy a new one (existing code). The hunt never hops.

### D3 Other sea events on the way (one choice each)
- **Terrorshark** (150k HP, follows the boat, knocks you off the seat): **FIGHT it**
  (you, 2026-10-08), with the same rules as a beast: M1 + skills, aim locked, the
  Kitsune-first loadout, and Dragonstorm held M1 allowed because it works on the
  Terrorshark. It is a normal `workspace.Enemies` NPC. A Monster Magnet turns it into
  the Anchored Terrorshark (195k HP, a guaranteed Shark Anchor).
- **Piranha / Shark / Fish Crew** near you: **default = kill them**. They count as sea
  events for the Spy's cooldown (see L1). The other option is to ignore them.
- **Rough Sea** (lightning knocks you off the seat): sidestep 150 studs.
- Ghost ship / pirate brigades: ignored.

### D4 Leviathan, honestly
One script cannot summon it through the Spy, because the Watcher needs 5+ real players
on your boat. So there are three small pieces, each its own switch, and you choose
which ones you want:
- **L1 Spy status (read only)**: `CommF_("InfoLeviathan","1")` gives 1-5, meaning
  "on cooldown" / "wants fragments, n of 4" / "Leviathan is out there". Shown on the
  Sea page and in the news strip. Bribing (1,500 fragments each, 4 needed) is a
  **separate button you press**, never automatic.
- **L2 Frozen Dimension finder** (when you are the group's driver): the same boat
  sails Danger 6 until the Frozen Dimension appears, brings the boat to the gate, and
  then **hands the character back to you** so you and the group talk to the Watcher.
- **L3 Leviathan fight** (it runs whenever Leviathan parts exist):
  - It only hits parts whose `HealthEnabled` is true.
  - It **spreads the damage**: once you have done 10% of a segment's max HP (the
    reward line is 8%), it moves to the next segment. The head comes last, because it
    cannot be hurt before the segments are gone.
  - It hovers above the segment (Redz: +75), waits out the dives, and keeps away from
    the head's roar.
  - The tail's red zone dodge: the part's name is **unknown**, so the first fight
    logs it (D5).
  - **The heart: the character goes back to you with a loud notice.** The harpoon is
    WASD + M1 on the Beast Hunter and its remote is unknown. Doing it automatically
    is v2, after the log shows how it works. Nothing risky runs during the heart phase
    (dying loses the heart).

### D5 Probe built in (no separate run)
The first beast and the first Leviathan seen write their structure to
`workspace/bff_beast_probe.txt`: their children, values, attributes, the HealthBBG
text, their height against the sea plane, the animation IDs playing, and every
Leviathan part with its HealthEnabled. The volcano meters did the same, and that is
how they got fixed in one round.

### D6 Offline tests (luau, the real code cut out, like trial_test.py)
HP read (value / text "12,500/100,000" / attribute), surfaced or dived, the target
kept until it dies, key credit from an HP drop, the segment rotation at 10%, the
event policies, and the boat parked / lowered. Also the loadout verdict: below the
floor -> Base, re-tested on the 5th target, the forced modes win. And the aim lock:
on from the pick to the death, its point moving with the target, off after. A broken
copy of each must fail its test.

### D7 Order
**Sea Beast hunt first** (D2 + D3 + D5), then your in-game test, then the Leviathan
pieces you picked.

## What is not known yet (what can go wrong)
- 2026 hubs read the beast's HP three different ways (a `Health` value, the HealthBBG
  text, an attribute). The script reads all three, and the probe shows which one is
  live.
- Whether fast_farm's M1 (the hit remote) hurts a beast with Kitsune, or only the
  fruit's own hitbox does. The HP learning settles it either way.
- Whether a lifted boat still counts as "a boat nearby" for spawning. It is only
  lifted during a fight, so patrol keeps spawning normally.
- The attack animation IDs (8708221792 / 8708222556) come from one hub of unknown
  age, so they are logged only and not used for dodging until the probe confirms them.
- **How the script knows you are transformed** (Kitsune form): unknown. The probe
  logs your character's attributes and children before and after V, and the tail
  bar. Until it is read, "transformed" is judged from which moves the hotbar shows,
  and V is pressed only when the bar is full.
- Whether the silent aim catches the transformed Kitsune M1. If its lunge reads the
  mouse it does; if it lunges the way your body faces, the body is turned at the target
  as well (the dash camera trick already in farm_pro).

## Not doing
Summon Sea Beast (10M bounty; it drops nothing), fishing for a Levi, auto-bribe, and
auto-harpoon in v1.

## Sources
Wiki (api.php wikitext, 2026-10-08): Sea Beast, Rumbling Waters, Leviathan, Frozen
Dimension, Frozen Watcher, Spy, Leviathan Heart, Sea Exploration Group, Levi. Hubs on
disk: BFX bfxnew.lua (2026-09-24; SeaBeasts targeting, boat lift 150, hover Y 100),
SHX p_1.lua (surfaced test 175 vs WaterBase-Plane, hover 300/50, Leviathan / Segment /
Tail loops), Redz mp_9.lua (HealthEnabled, FrozenHeart, segment Head +75, head Y 60,
dodge ring 60), OVL (InfoLeviathan "2" bribe), hosti (InfoLeviathan "1" = 1-5, the
HealthBBG parse).
