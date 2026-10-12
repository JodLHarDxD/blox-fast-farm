# PvP: your attacks go to the player your mouse is on - and he is highlighted - plan v3

Status: **BUILT 2026-10-12 (build 2026-10-12.8)** on your "go".
Date: 2026-10-12. Script: fast_farm, PvP mode (build 2026-10-12.7 now).
v1 / v2 (two modes, Flash Step, side buttons, screen look) DROPPED - you: "don't make it complicated".

## What I understood

PvP stays as it is - it is good. ONE problem: in a crowd you aim your mouse at the player you
want (instinct), but the script ignored the mouse and hit someone behind / beside you. So:

1. **The player your mouse is on - or NEAR - is the one.** Every attack goes to him (the
   aim assist: your cursor does not have to be exactly on him). Two near the cursor: the one
   closer to the cursor. Nobody near: your attack goes where your mouse is, as normal.
2. **That player is highlighted** - red, drawn over every fiery / blast effect - so you always
   see who your attacks go to.

## What changes (nothing else)

- The pick: **nearest your CURSOR on the screen, within 200 pixels of it** (slider), alive,
  PvP on, not your side, within 300 studs, in front of the camera - picked again every frame.
  It replaces "nearest to you + locked at your first attack" (the cause of the hits behind you).
- The highlight: red fill + white outline on his whole body, always on top, plus a small red
  marker over his head. Only your screen. Switch "Highlight him" (on).
- Your body still turns to him on every attack (as now), now to the one your mouse picked.
- Panel: "Next player" and the "locked" wording go (the mouse picks now); new slider
  "Mouse catch area" (50-500 px, 200); the readout says who your mouse has.

## The build, if you say go

PVP LOGIC `L.cursorPick` + tools/pvp_test.py cases (cursor beats distance, nobody near = none,
behind the camera = never) and mutation checks; the highlight; panel; README first test.
