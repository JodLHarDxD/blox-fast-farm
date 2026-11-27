# Secondary modes — design (2026-11-27)

User, 2026-11-27: "Primary is whatever mode I pick. Secondary modes I can turn
on, every one — fruit, factory raid, prehistoric + volcano. If I farm the
circuit, whenever a fruit spawns or the factory raid starts, it goes for it,
then back. The way volcano starts by itself when I get the prehistoric."

## What it is

- **Primary**: the one mode picked today (Circuit, Random, Raid, a hunt, …).
  Unchanged — including its own hop rules: Circuit never hops; a hunt picked
  as primary (Fruits, Elite, …) still hops when its target is not here.
- **Secondaries**: Fruits, Factory raid, Elite pirates, Prehistoric + Volcano.
  Each on / off. A secondary **never hops**: it acts only when its event is
  up on this server, then hands back.
- **Order: fixed, not a setting** (user, 2026-11-27: "very low chance two
  appear at once - I don't care about the order"): fruit, factory,
  prehistoric, elite. Elite last: an elite is alive most of the time, so with
  it on it would hold the character over the primary - the user keeps it off
  mostly; when on, every other secondary still goes first.
- A mode is never both: the primary's own kind is skipped in the secondary
  list (Fruits primary + Fruits secondary = Fruits primary).

## The loop (approach A, chosen)

In `step()` (MAIN LOOP), after the Leviathan and before the primary:

```
for id in SIDE_ORDER:            -- fruit, factory, prehistoric, elite
    if CFG.Side[id] and id ~= primaryKind() and SIDE[id].ready():
        P.sideNow = id
        SIDE[id].step(myEpoch)      -- one step, no hop
        return
P.sideNow = nil
-- primary as today
```

`SIDE[id]` = `{ ready(), step(epoch) }`:

| id | ready() — up on this server | step() — reuses |
|---|---|---|
| fruit | `fruitWanted()` returns a fruit (the Fruit menu's own picks) | `grabFruit(f, epoch)` |
| factory | Second Sea and a model named `Core` with Health > 0 in `workspace.Enemies` | fly to the Core, then the Factory swing (`P.factory`) until it breaks |
| elite | an elite (`ELITES`) alive on this server (`bossUp`) | `eliteLook(epoch)` — its fight, no hop |
| prehistoric | the Prehistoric Island in the map (the news's `prehistoric` headline up) | `P.sea.huntStep(epoch, "prehistoric")`, then `P.sea.volcanoStep()` |

The pure choice is one function, tested offline:
`sideNext(order, on, ready, primary) -> id | nil`.

No cutting in: a running secondary finishes its step; the next step picks
again. (Two events at once is rare - user.)

## Hops

- Secondaries: never.
- The primary's hop waits while a secondary runs (`P.sideNow ~= nil`).
- No primary (`none`) + secondaries on: wait for events, as Volcano alone
  does today ("no mode on - waiting for …").
- Secondaries run only while Start is on (`P.running`).

## Factory as a secondary (the new part)

- Detect: `Core` alive in `workspace.Enemies`, Second Sea.
- Go: fly to a stand spot beside the Core (from the Core's own position + an
  offset, never a hard-coded map spot until measured). The first run prints
  the Core's path, position and size: `[BFF] factory core: ...`; the stand
  offset is then fixed from that.
- Stand: the farm's hold off (Factory never moves you once there), the
  Factory swing loop (`P.factory`) runs until the Core's Health is 0 or it is
  gone, then `P.sideNow = nil`.

## Volcano

`CFG.Volcano` folds into the `prehistoric` secondary: on load, a saved
`Volcano = true` turns `Side.prehistoric` on. The Volcano page and its loot
settings stay as they are.

## Settings

```lua
Side      = { fruit = false, factory = false, elite = false, prehistoric = false },
```

The order is a constant in the script (`SIDE_ORDER`), not a setting.

Saved with the rest; carried over a hop.

## Panel

Modes page, a section **ALONGSIDE** (replaces the Volcano-only
"alongside any mode"): four rows in the fixed order — name, one line,
On / Off. A row whose
pack is locked on this key shows locked. Home's status line names a running
secondary: "Fruit (secondary) — then back to Circuit farm".

## Packs

A secondary needs its own pack open: fruit = fruits, factory = raid,
elite = raid, prehistoric = prehistoric (`PACK_OF`).

## Tests

- `sideNext`: fixed order respected, off skipped, primary's kind skipped,
  nothing ready = nil.
- Panel: the section's four rows switch `Side.*`, locked rows.
- Load: `Volcano = true` → `Side.prehistoric = true`.
- In game (user): circuit + fruit secondary → a spawned fruit is stored, the
  circuit's quest kept; factory secondary → the console's core line, the Core
  broken, back to the circuit.

## Not in this version

- Reordering secondaries, and one cutting into another (user: not needed).

Sea events, Mirage, berries, swords, Halloween as secondaries; secondaries
hopping to find their event.
