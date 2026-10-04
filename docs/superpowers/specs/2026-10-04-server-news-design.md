# Server news strip - design

2026-10-04. Status: direction from the user in chat ("breaking news" heading, shown
even when the panel is hidden; read the server's own information at whatever moment
you join, never counted from the server's start). Built from this.

## Goal
One look tells you what THIS server is doing: which night or day it is in the moon's
8, when the full moon comes or how long it has left, whether a Mirage / Prehistoric /
Kitsune island or the Frozen Dimension is up and since when, which elite or raid boss
is up, Cake Prince's count, a fruit lying on the map, players.

## Facts it rests on (research 2026-10-04)
- The server sets `Lighting:GetAttribute("MoonPhase")`, 1-8, 5 = full moon, 4 = the
  night before (public hubs 2024-26: Redz family, Teddy, trackers), and
  `IsBlueMoon`. The moon decal is the fallback: Roblox's asset list names the game's
  eight decals moon1..moon8 (moon5 = full), plus fullbluemoon. Sea 3 `Lighting.Sky`,
  Seas 1-2 `Lighting.FantasySky`.
- Night = `Lighting.ClockTime` 18:00 -> 05:00 (hubs). The phase turns at noon (hubs:
  a full decal 05-12 is "fake", 12-18 means "full moon in 18 - clock").
- Speed: best fit 1 game hour a real minute (the wiki's "first full moon 54 min after
  a server starts": phase 3 at noon, 6 + 24 + 24 min). MEASURED in game, not trusted.
- Islands: `workspace.Map` MysticIsland / KitsuneIsland / PrehistoricIsland /
  FrozenDimension, `workspace._WorldOrigin.Locations` "Mirage Island" / "Kitsune
  Island" / "Frozen Dimension" (hubs). Mirage and Kitsune live 15 min at most;
  Prehistoric has no timer. Blue Gear needs night only (Valentine's update); race
  trials, Kitsune Island and the Skull Guitar need the full moon.
- `workspace.DistributedGameTime` on a client = time since YOU joined, not the
  server's age (Roblox docs) - the server's age is not shown.

## Behaviour
- Read once a second, from load, panel open or not: the moon (attribute, else decal),
  the clock, the islands, the bosses (`bossUp`), lying fruits, players.
- Day/night number: night N = the server's phase N. A day carries the number of the
  night it leads into (before the phase turns at noon: the next one).
- Countdowns turn game hours into real time with the MEASURED clock speed, day and
  night apart (20 s samples, a jump or a stop ignored). Until measured: 1 h a minute.
- Learned from what the game does: the hour the phase turns (only if between 05:00
  and 18:00), the order it turns in (moon a -> b). Saved in `bff_sky.json`; read at
  load. Each turn and each new speed is printed (`[BFF] sky: ...`), each event too
  (`[BFF] news: ...`).
- Island age = since this client saw it come; already up when you joined = age
  unknown (said so). Its attributes are printed once (a spawn time may be there).
- Breaking: an island coming, the full moon rising, an elite / raid boss up, a fruit
  on the map -> the chip says BREAKING for 8 s, the crawl starts over from the right
  with that item first, marked BREAKING for 60 s. At the join, whatever is up already
  is breaking too.
- Cake Prince: `CommF_("CakePrinceSpawner", true)` (a question, never the summon),
  once a minute, Third Sea, only while the strip is on screen.

## Panel
A 26 px strip under the title, inside the panel: a fixed chip on the left
(DAY 4 / NIGHT 4 / FULL MOON / BLUE MOON / BREAKING + m:ss to the next dusk or dawn,
monospace digits) and a crawl moving left (~40 px/s), coloured titles, minutes in the
text (a number changing every second would twitch the text after it). Hide keeps the
title and the strip (52 -> 82 px); open 540 -> 570 px.

## Not done (on purpose)
No Mirage finder (next, separate), no hop on news, no toasts, no server age.

## Tests (offline, real code cut out, luau)
tools/news_test.py: the phase read (attribute / decal / blue / missing), day and
night numbers round the clock (before and after the noon turn, past midnight), the
full moon tonight / now / in N nights and its real minutes, measured speed (day and
night apart, midnight wrap, jumps and stops ignored), the learned turn hour + order,
the save file round trip, islands (seen come, up at the join, gone, lasted),
bosses, Cake Prince's answer, the headline order and BREAKING, the chip.
