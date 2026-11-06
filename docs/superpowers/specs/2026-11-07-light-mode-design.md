# Light mode

Goal: in every server, without a button press, the game's Fast Mode on and its camera shake and
background music off. Approved by the user 2026-11-07: one switch, on by default.

Source: the game's Settings LocalScript (tlredz/decompiledGames, blox-fruits v4623).

- Music: fire `RS.Events.ToggleMusic` with true. Skip if `Global.isMusicMuted()` already says so.
- Shake: `SetEnabled(false)` on `RS.Util.CameraShake` and `RS.Util.CameraShaker`.
- Fast Mode: private to that script, so its steps are copied, with `Global.FastMode`, `reducing`
  and `FastModeCache` set as the game sets them, so its own Off button still works.
- `RS.Global` returns the game's `_G`.

Rules:
- Only with a team. Music and shake twice, 6 s apart, because the Settings script resets them at join.
- Client only. No `ChangeSetting` remote. No `firesignal`.
- Water parts keep their material: `partWater` reads it.
- Anything missing is reported in `P.light.note` and the log line, never an error.

Tests: `tools/light_test.py` cuts the real section out of `fast_farm.lua`.
Out of scope: quality settings, removing effects beyond what Fast Mode does.
