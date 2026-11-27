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
  Each on / off, in the user's own order. A secondary **never hops**: it acts
  only when its event is up on this server, then hands back.
- A mode is never both: the primary's own kind is skipped in the secondary
  list (Fruits primary + Fruits secondary = Fruits primary).

## The loop (approach A, chosen)

In `step()` (MAIN LOOP), after the Leviathan and before the primary:

```
for id in CFG.SideOrder:
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

## Cutting in

Each step re-checks, so a higher secondary takes the next turn on its own.
Long blocking actions — `fight()`, a flight, a grab — get a `breakIf` that is
true when a secondary **higher in the order** than the one running is ready.
Example: order Fruit, Factory — a fruit mid-raid is grabbed, then back to the
Core.

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
SideOrder = { "fruit", "factory", "elite", "prehistoric" },
```

Saved with the rest; carried over a hop.

## Panel

Modes page, a section **ALONGSIDE · in your order** (replaces the Volcano-only
"alongside any mode"): four rows — name, one line, On / Off, ↑ ↓. A row whose
pack is locked on this key shows locked. Home's status line names a running
secondary: "Fruit (secondary) — then back to Circuit farm".

## Packs

A secondary needs its own pack open: fruit = fruits, factory = raid,
elite = raid, prehistoric = prehistoric (`PACK_OF`).

## Tests

- `sideNext`: order respected, off skipped, primary's kind skipped, nothing
  ready = nil, a higher one wins.
- `breakIf`: true only for a higher ready one.
- Panel: the section's rows, the arrows reorder `SideOrder`, locked rows.
- Load: `Volcano = true` → `Side.prehistoric = true`.
- In game (user): circuit + fruit secondary → a spawned fruit is stored, the
  circuit's quest kept; factory secondary → the console's core line, the Core
  broken, back to the circuit.

## Not in this version

Sea events, Mirage, berries, swords, Halloween as secondaries; secondaries
hopping to find their event.
