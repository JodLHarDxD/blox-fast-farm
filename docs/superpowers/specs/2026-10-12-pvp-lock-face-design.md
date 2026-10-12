# PvP: one opponent, and always facing him - plan

Status: **BUILT 2026-10-12 (build 2026-10-12.7)** - your answer "A" (D6 turning only), D1-D4 at A.
Date: 2026-10-12. Script: fast_farm, PvP mode.

## What I understood

1. **One opponent at a time.** The one you choose / attack first is THE target. Every aimed
   attack goes to him until he is dead or gone - never the player beside him, never one behind
   you. An AOE that also hits others is fine; the aim is still him.
2. **Always face him when you attack.** Whatever attack (Kitsune moves, transformed or not,
   M1, every skill), your body turns to him, so nothing looks odd (body forward, attack going
   behind). Within 60-100 studs - your Kitsune range; most of your special attacks land inside 60.

## Why it happens today (read in the code)

- **Who:** PvP mode picks the NEAREST attackable player within 300 studs, then keeps him while
  he is within 330. So if someone behind you is nearer than the one you are looking at, the
  aim goes to the one behind - your skills fly backwards.
- **Facing:** the script turns your body only for a melee / sword M1, only within 25 studs.
  For every other attack the GAME turns your body toward your real mouse (decompiled
  CombatController: in combat, the body follows the point under your cursor every frame),
  while silent aim sends the skill to the target. Mouse one way, skill the other -> the odd look.

## Decisions - pick or veto each one

**D1 - who is "the one I chose".** (You: "not my mouse - I just press the buttons; the
character and the aim are the script's job.")
A (recommended): **the nearest player to you at your first attack** while nobody is locked
(within 100 studs). Your first button press locks him. Wrong one? "Next player" on the panel.
B: the player nearest the MIDDLE of your screen (where your camera looks - not the cursor).
C: the player nearest your mouse cursor.

**D2 - how long he stays.**
A (recommended): until he dies, leaves PvP, goes past the aim range (330 studs), or you press
"Next player". Nobody else takes the aim meanwhile, even if nearer.
B: as A, plus: attacking with your mouse right ON another player switches to him.

**D3 - which attacks turn your body.**
A (recommended): **every attack** - M1 of any weapon and every skill key (Z X C V F), fruit
transformed or not: the body is turned to him from the key press, the whole time the key is
held and the move plays, and 0.4 s after. Not movement (Q dash, jump), not when no one is
locked or he is out of the facing range.
B: skills and melee / sword M1 only (not a fruit's M1, not a gun).
C: as today (melee / sword M1 only).

**D4 - the facing range.** A (recommended): **100 studs** (slider 25-150). Inside 100 you face
him; farther, your body is yours.

**D5 - nothing else changes:** the aim range (300), lead off, Ken / speed / dash / clean screen
as they are.

**D6 - MOVING your character (you: "totally moving the character ... the script's job").**
Not sure which you mean - pick one:
A: **turning only** - the script turns your body to him (D3) and aims every attack; you still
walk with WASD. This build.
B: **also moving** - while he is locked, the script keeps you at your attack distance from him
(e.g. 30-50 studs, a slider), follows him when he runs, circles round him so you are harder to
hit; your WASD takes over the moment you press it. You only pick the weapon and press the
attacks. A bigger build (movement, walls, water, his dashes) - I would plan it as a second step
after A works in a fight.

## What only your first fight can tell

- Whether a move that dashes or charges keeps its direction when the body turns mid-move
  (it should go at him - that is the point - but say if one flies off oddly).
- In the fox form, that the whole fox turns with your body (it follows your root part).

## The build, if you say go

- PVP LOGIC (pure): the screen-nearest pick + the lock rule; face window per attack.
- The input watch (already there for M1 / Q) gets every attack key; faceNow keeps running at
  the end of each frame (after the game's own turn), as it does now for M1.
- tools/pvp_test.py: the pick (cursor, not nearest; behind you never), the lock (nearer one
  never steals; dead / far / Next = release), the face window (keys, held, the move playing,
  range, movement keys not), plus mutation checks.
