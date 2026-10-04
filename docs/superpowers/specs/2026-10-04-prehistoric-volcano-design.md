# Prehistoric hunt + Volcano event — design (2026-10-04)

Status: built, offline-tested (tools/sea_test.py, 77 checks, 6/6 mutations caught), **untested in game**.

## Two switches, on purpose (user's question)

| Switch | Job | Ends when |
|---|---|---|
| **Prehistoric hunt** (`HuntKind = "prehistoric"`, a Home hunt switch) | buy the boat, drive, search, next server | the island is up and you are on it |
| **Volcano event** (`CFG.Volcano`, its own Home switch) | the event on any Prehistoric Island up in this server — start, vents, golems, loot | the island goes |

`step()` asks the event first (`P.sea.volcanoStep()`), before every mode, so the hunt hands over by itself and the event also works on an island someone else spawned or one you sailed to by hand. The hunt reuses the hunt director: hop, carry-over, chalice guard.

## The hunt

- Buy: fly to the back dealer `(-16928.9, 7.8, 434.6)`, `CommF_("BuyBoat", SeaBoat)` (1 = bought, probe), then Beast Hunter / Guardian / Lantern; wait for `workspace.Boats[*]` with `Owner == you`.
- Sit: `VehicleSeat:Sit(humanoid)`; the body lock lets go (`flying = true`) while seated.
- Drive (Heartbeat, `driveTick`): heading = west turned by a random ±`SeaWobble`° every 15-30 s; turn ≤ 45°/s; move `SeaSpeed` (100-350 clamp) × min(dt, 0.1); held on the water line the boat had; `Model:PivotTo`; boat collisions off. Knocked off → re-seat, boat waits.
- Meters = flat studs from the dealer / `SeaStudsPerM` (10, from the user's compass: Danger 6 ≈ 2,600 m ≈ 26.3k studs; Prehistoric ≈ 5,000 m ≈ 50k studs). Danger = compass label, else `DangerLevel` attribute / 100.
- Island marker or model → stop, unseat, fly over it, hold (never hop).
- `meters ≥ SeaSearchTo` → hop. Boat gone: > 6,000 studs from Tiki → hop; nearer → buy again.

## The event

Phase = `defend` (IsMinigameActive) > `loot` (bones / an egg prompt, `VolcanoLoot`) > `start` (prompt enabled) > `idle`.

defend:
- Lava parts off the client every 2 s (Core.InteriorLava + BaseParts named *lava*, except VolcanoRocks / relic / prompt / eggs / TrialTeleport).
- Golems held (magnet on): the pile becomes `GOLEM_CUR` (a `pileCur.build` hook in `refreshPile`) and stays active between fights, so `magnetTick` holds every golem at the **cage** = relic + 60 studs away from the volcano's middle.
- Pick (`defendPick`): magnet on → vent > golem; magnet off → golem > vent.
- Vent: stand `VentDistance` out (from the volcano's middle) + 8 up; fire the first ready `VentKeys` key of the carried tools (fruit, melee, sword, gun), aimed with the hidden camera swap at the vent (`P.aimAt`, the Heartbeat aim hook); a key whose bar did not start = skipped 30 s; nothing ready → aimed M1.
- Golem: `fight(GOLEM_CUR)` with the Attack page weapons; `breakIf` = switch off / event over / (magnet on and a vent live).

loot: nearest `workspace.DinoBone` (touch: fly onto it; 3 tries), then `Core.SpawnedDragonEggs` prompt (held; 2 tries → "needs the Dragon Tether ...").

## Unknowns the first run settles

- Does the server keep a pivot-driven boat at 250-350 (no snap-back), and does Danger 6 / the spawn roll count while driven so?
- The meter unit (slider "One compass meter").
- Golems: owned and damageable at the cage, or put back (Magnet page "why no damage")?
- Which skills close vents from 12 out, and does the hidden aim land them on the vent?

## Mirage hunt (added 2026-10-04, user: "your job is hunt the Mirage; I do the moon")

- Same drive (`S.huntStep(myEpoch, "mirage")`); Prehistoric islands ignored on this hunt.
- First sight: `mirageFits(MirageNeed, news.sky, 900, 120)` - night now with >= 2 min usable, or night starting >= 2 min before the 15-min life ends; "full" also needs sky.full / sky.nights == 0. Not fit = sailed past (remembered until it despawns).
- Fit: stop, fly to the marker + 20, `P.handsOff = true` (bodyStepped/bodyHeartbeat return, restoreBody, step() skips escape/haki/volcano).
- Gear: island child MeshPart with MeshId 10153114969 (or a child MeshPart "Part", only after seen hidden). Transparency < 1 = shown -> hands on, fly onto it, small steps 4 s, gone/hidden = got -> CheckTempleDoor printed, hunt off, P.stop deferred. 3 misses = left to the user.
- Mirage gone during hands off -> hands on, back to the boat.

