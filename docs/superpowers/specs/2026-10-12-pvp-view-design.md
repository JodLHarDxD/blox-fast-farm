# PvP: the screen exactly as Observation V2, and the one you fight easy to follow - plan

Status: **SUPERSEDED by 2026-10-12-pvp-assist-mode-design.md.** D3 (the mark, picked) moved
there. D4 (4th mouse button) DROPPED for now by you. D1 / D2 PARKED (screen look).
Date: 2026-10-12. Script: fast_farm, PvP mode (build 2026-10-12.7 now).

## What I understood

In PvP the screen is BRIGHTER than when you press E yourself with Observation V2. In a crowd
fight the attack effects wash the screen and you lose the players. You want the screen exactly
like real Observation V2 (V1 = much darker; V2 = a little darker and clear). If the screen
stays bright, then the players must stand out much more.

## Ken V2's look, measured in the game's own code (decompiled v4623)

`ReplicatedStorage.ObservationManager.ScreenEffects.setActive(on, isV2, instant)` - the only
thing that changes the screen when Ken goes on or off:

| | V1 | **V2** | Ken off |
|---|---|---|---|
| Lighting.ExposureCompensation | -1 | **-0.5** | 0 |
| Lighting.Blur.Size | 7.5 | **1** | 0 (then off) |
| Lighting.ColorCorrection.TintColor | 125,255,255 | **125,255,255** (cyan) | white |

(The 0.3 s fade is a tween; "instant" sets the values at once.) The outlines and HP bars are
not in this look - they are drawn on a screen layer over the world.

## Why the PvP screen can come out brighter (read in fast_farm)

1. **Clean screen can switch the V2 look itself off.** Clean screen keeps only the effects
   that were there when PvP went on AND looked harmless then. The game's own
   `Lighting.ColorCorrection` (the one carrying V2's cyan tint) is not protected: if its
   island values count as "hard contrast / grey" at that moment, clean screen keeps it OFF the
   whole fight -> no V2 tint -> brighter. Same for any game lighting effect that appears later
   (a new island, the night, the sea) - every NEW effect is switched off, darkening ones too.
2. **Bright flashes are never switched off.** Other players' move flashes go through one shared
   ColorCorrection on your camera. It is made the first time anyone's move flashes, so it is
   usually there already when PvP goes on -> counted as harmless -> white flashes pass.
3. **Nothing puts the V2 values back** if something drops them while the view is still on
   (only "view off -> on again" is watched, not the look).

Which one hits you I cannot tell from here - the panel will show it (the readout below).

## Decisions - pick or veto each one

**D1 - the screen look.**
A (recommended): **the exact V2 look, held while PvP is on**: exposure -0.5, blur 1, cyan tint,
the game's own objects. Put back within 0.1 s whenever something drops it (Ken out of dodges,
the cooldown, a new life, an effect). Plus a slider "Screen brightness" from -1.0 (V1 dark) to
0 (no Ken look), **default -0.5 = V2**, so you can go darker if V2 is still too bright.
PvP off: the game's own look as Ken is (on = V2, off = normal).
B: as now.

**D2 - clean screen.**
A (recommended): the game's own V2 objects (Lighting.ColorCorrection, Lighting.Blur) are
never touched by clean screen. Every other screen effect is judged by what it does NOW, every
0.1 s - darkens, greys, hard contrast, heavy blur, or **a bright flash** (brightness up) -> off
till PvP ends. Ghoul / Angel V4 and the Dark screen stay off as today.
B: as now (only "not there at the start").

**D3 - the one you fight stands out. PICKED: A.**
A: the LOCKED player gets a strong highlight - red fill + white outline, drawn OVER every
attack effect (a Roblox Highlight, always on top) - plus a red marker over his head (a screen
layer, so even a blast that covers his whole body cannot hide where he is). Only on your
screen; others see nothing. Everyone else keeps the game's Ken outline. Switch "Mark the one I
fight" on the PvP page. The mark jumps the moment you switch player (D4).
(B every player in range / C none - not picked.)

**D4 - switch the player with your mouse's 4th button (you: "not the wheel - it zooms").**
Fact: Roblox never sees a mouse's 4th / 5th (side) buttons - its input knows only left, right,
middle, the wheel and movement. Two ways round it, both built, the script uses what works:
1. **Read the buttons directly**, if your executor (Velocity) has `iskeypressed` (Windows' own
   key state: 4th = VK 0x05, 5th = VK 0x06). Unknown until you load it - the PvP page says
   "side buttons: read directly" or "not readable here - use way 2". Only while the Roblox
   window has focus (a 4th-button "back" in your browser does nothing in game).
2. **Always works:** your mouse's own app (Logitech G Hub, Razer Synapse, your mouse's app, or
   the free X-Mouse Button Control) makes the 4th button press the key **]** and the 5th **[**.
   The script listens to ] and [ (the game uses neither; you can also press them by hand).
The roll, as you asked: **4th = next player, 5th = the one before** (none? 4th only), round
and round - with two players, two presses = back to the first. The order is nearest first,
taken at your first press and kept while you keep pressing (2 s), so a quick double press is
never reshuffled by players moving. The one you land on is LOCKED (the mark, the aim, the
facing all go to him). Players within "Keep him locked within" (300) count.
Not a typing box: while you type in chat the keys do nothing.

## What the panel will show (to check in the first fight)

`look  exposure -0.50  ·  blur 1  ·  tint cyan  (V2)  ·  put back 3x`
`screen  4 effects switched off: EffectContainer-ColorCorrection, ...` (names, not just a count)

## The build, if you say go

- PVP LOGIC (pure): the V2 numbers, `L.lookDrift(cur, want)` (what to put back), and
  `L.blinding` + the flash rule; `L.roll(order, cur, step)` (next / previous, wrap) and the
  2 s frozen order; the side-button press edge; tools/pvp_test.py cases + mutation checks.
- The side buttons: `iskeypressed` polled each frame only if it exists and the window has
  focus (UserInputService.WindowFocused / WindowFocusReleased); ] and [ through InputBegan.
- The PvP loop: a look holder (0.1 s check; on drift the game's ScreenEffects instant-on
  first, which cancels its own fade, then the values), clean screen with the two objects
  exempt and judged by values each tick, the highlight on the locked player (one instance,
  moved when the lock changes, removed when PvP ends).
- Panel: "Observation V2 screen" switch, "Screen brightness" slider, "Mark the one I fight"
  switch, the two readout lines. README first-test list.

## What only your first fight can tell

- That the screen now matches pressing E with V2 (the readout says the values; your eyes say
  the rest).
- Whether a game effect we now hold off was a useful one (its name will be in the list).
