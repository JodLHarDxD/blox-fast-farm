# Fire Flower hunt (Draco V2) - design

2026-10-04. Status: approved in chat (user), built from this.

## Goal
Draco V2 needs 5 Fire Flowers + $1,000,000 at the Dragon Wizard. The user holds 2.
A hunt that kills Third Sea enemies until a flower lies on the ground, picks it at
once, and goes to the next server. Runs until switched off - no target count.

## Facts it rests on
- Fandom (Fire Flower, Draco): while the Dragon Wizard's V2 quest is running, any
  Third Sea kill can drop one. It appears on the ground a while after the kill,
  only for you, and must be picked up like a berry. After one spawns, that server
  gives no other for 5-15 min; a new server resets it.
- Three public hubs (Opensurs, ZDuck, nyannos, 2026): flowers are Models in
  `workspace.FireFlowers` (PrimaryPart, or a MeshPart inside), picked with the
  ProximityPrompt inside the model (Opensurs) or by holding E 1.5 s next to it.
  Quest remote: `Modules.Net["RF/InteractDragonQuest"]` {NPC="Dragon Wizard",
  Command="Speak"|"Ascension"...} - not used here (user already has the quest).
- Inventory count: `CommF_("getInventory")` item "Fire Flower" (as berries).

## Behaviour
- Fifth hunt switch, "Fire Flower hunt". One hunt at a time (user mandate).
  Third Sea only: anywhere else it stops and says why.
- Per server:
  1. A flower lying in `workspace.FireFlowers` -> grab it (step 3).
  2. None -> farm **Forest Pirate + Mythological Pirate** (Floating Turtle; user's
     two flowers came from there). **No magnet** (user): the nearest one is fought
     WHERE IT STANDS, on the ground, one at a time, kept until it dies; then the
     next nearest. No damage 6 s from high -> close; 15 s even close -> skipped
     a minute. None loaded -> fly to the camps in turn.
     The fight breaks off the moment a flower lies there (checked every pass,
     ~0.1-0.5 s).
  3. Grab: fly onto it, hold its prompt like a player (berries' holdPrompt), the
     instant fireproximityprompt every third try; ~15 s. Picked = inventory count
     went up (or, count unreadable, it left the folder). Up to 3 grabs.
  4. After a flower spawned (picked or not) -> hop. A server you picked one in is
     not rejoined for 10 min longer than the usual revisit (its 5-15 min cooldown).
  5. **No flower 2.5 min after the FIRST KILL in the server** (user: the clock starts
     at the first kill, not the join, and runs straight through - respawn waits
     count; 2.5 min = 50-60+ kills, plenty) -> hop. Slider 1-5 min.
     Safety: nothing died 3 min after reaching the camp -> hop (else the clock
     would never start).
- Hop switch off: never leaves; keeps farming here (the next flower comes after
  the cooldown).
- The chalice rule (no hop holding a God's Chalice) applies as in every hunt.

## Not done (on purpose)
No Dragon Wizard visits (quest taken, turn-in manual), no count target, no other
hunt mixed in.

## Panel
Hunt page: switch + "fire flower hunt (Draco V2)" section - last note, picked,
you have N (inventory, read by the hunt), this server (killing m:ss / no flower
yet), lying now; slider "Give up after (from the first kill)". Home readout count.

## Tests (offline, real code cut out, luau)
flowersLying (folder missing, nested MeshPart), grab (hold / fire fallback / never
-> stuck / count unreadable), the clock (starts at first kill; 2 min; 3 min no
kill), Third Sea check, hop off keeps farming, picked -> hop held longer, nearest
in-place target kept until dead and unhurtable skipped, hop(why, holdSecs).
