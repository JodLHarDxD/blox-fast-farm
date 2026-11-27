# Passives - plan

Status: DROPPED (user, 2026-10-12: "I don't need the passive that importantly").
Kept as a record; nothing of it was built. Was: PLAN, waiting for your GO.
Date: 2026-10-12. Already built and pushed today, separately: the fruit
finder sees the game's own spawns (9dd3fe4, build 2026-10-12.3).

## What you asked

Today every switch is an ACTIVE mode: it is the one job, and when its job is
not there it hops. You want PASSIVES as well: switches that watch the server
while any mode runs (sea events, PvP, the elite hunt, anything), and the
moment their thing happens they break in, do it, and give the server back:

- **Fruit**: a valuable fruit appears in this server -> drop what you are
  doing, fly to it, take it, store it. Never a hop to look for one.
- **Pirate raid**: pirates come to the Castle on the Sea -> fly there, fight
  the raid, then back to what you were doing.

The active mode stays your main job. A passive only interrupts it.

## How it would work

```
every step of the main loop - and every 0.1 s inside a fight:
  escape / haki (as now)
  PASSIVES, each its own switch, in this order:
    1. Fruit        a fruit worth it lies in THIS server
                    -> the active mode pauses; fly, take, store
    2. Pirate raid  raid pirates at the Castle on the Sea
                    -> the active mode pauses; fly there, fight to the end
  then the ACTIVE mode, exactly as now
    (Leviathan / hunt / random / raid / circuit; PvP - see D5)
```

After a passive the active mode resumes in the same server: sea events and the
Prehistoric / Mirage hunts fly back to the boat and take the wheel; the elite
hunt looks for its elite again; the circuit goes to its camp again.

## Decisions - pick or veto each one

**D1 - which passives.** A: Fruit + Pirate raid now (what you asked).
Later ones go the same way (one switch each, the same layer).

**D2 - order.** A: Fruit first, then Pirate raid (you: the fruit is worth
more; a raid lasts minutes, a fruit can be taken in seconds).

**D3 - what a passive may break.** A (recommended): everything, except
where leaving loses something you cannot get back:
- a fruit raid in progress (leaving its island fails the raid and the chip),
- the Leviathan fight in the Frozen Dimension (another place - the fruit is
  not reachable from there),
- the Mirage gear moment (the character is already yours - hands off),
- the Pirate raid passive does not break a Volcano event in progress (the
  Fruit passive does: a short detour, then back).
B: everything, no exceptions.

**D4 - the elite fight. This conflicts with your rule of 2026-09-29.** Then
you said "nothing breaks off an elite fight" (the chalice goes to the LAST
hit). A (recommended): a fruit waits until the elite you are hitting is
dead. An elite dies in 10-30 s; a spawned fruit lies about 20 min unless
someone takes it. B: the fruit breaks the elite fight too.

**D5 - the farm stopped (you play yourself, or PvP mode).** PvP mode stops
the farm's loop, so today nothing of the farm runs. A: the passives run
anyway. For the job they take the character (flight, noclip, your keys off),
then give it back where it was, and PvP is on again. B: passives only while
the farm runs. A is what you asked ("whatever I am doing, PvP too"). It is
also the riskiest part of the build.

**D6 - which fruits.** A: the Fruit hunt's own rules, one place: minimum
price, include players' drops, take a spawn that cannot be named. The Fruit
hunt mode is then "fruits as the main job, and hop"; the Fruit passive is
"the same fruits, this server only, any mode". B: its own settings.

**D7 - how a raid is seen.** A: Third Sea only. A raid pirate = an enemy
within 750 studs of the castle's raid point (-5556, 314, -2988) - the farm's
Random-mode rule, from the redz hub - looked for in `workspace.Enemies` AND
among the enemies the game parks in ReplicatedStorage (it parks enemies with
no player near, as it does the elites). Also the game's own warning (20 s
before the raid) once a probe has found its text - that is a start before
the first pirate lands.

**D8 - the raid fight.** A: Random mode's own fight round the castle - every
pirate in the area, the magnet within it, the big last one fought to its
death (the last hit gets a random fruit; every pirate you killed counts for
the fragments). Over = no raid pirate for 15 s, or the game's "stopped
raiding" message. Then back.

**D9 - hops.** A: a passive never hops. An active mode about to hop waits
while a passive has work in this server.

**D10 - the panel.** A: Home gets a "Passives" row -> one page: the two
switches, and a line saying what it is doing now (`passive: going for Dough
Fruit - sea events paused`). The news strip says it too.

## What only your first run can tell

- What a game-spawned fruit is made of: `workspace/bff_fruit_seen.txt` from
  today's build (README "Fruits the game spawns: first test").
- Whether raid pirates far from you are seen (in `workspace.Enemies`, or
  parked in ReplicatedStorage), and the warning's exact words. The build
  would write a probe file for both the first time a raid is seen.

## The build, if you say go

- New section PASSIVES after MAIN LOOP (`P.passive`): each passive is
  `{ on, due(), run() }`. The main loop asks before every mode. `fight()`
  gets one break ("a passive has work"); the sea fights check it too.
- D5 A: a small runner of its own while the farm is stopped. It takes the
  body only for the job, then hands it back.
- Tests: a new `tools/passive_test.py` (order, exceptions, the elite rule,
  resume, no hop, farm stopped), plus the panel census. Mutation-checked
  like the rest.
