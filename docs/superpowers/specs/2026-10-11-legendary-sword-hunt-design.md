# Legendary Sword Dealer hunt (for True Triple Katana) - plan

2026-10-11. Status: **BUILT the same day (build 2026-10-11.2), D1-D5.** D6 / D7 not built.
Found while building: the swords were RENAMED in Update 24 - Shisui = Shizu, Saddi = Saishi,
Wando = Oroshi (the game's item table has only the new names: Shizu 66, Saishi 69, Oroshi 70).
The switches use the new names; the dealer's answer is read under either name. Owned swords are
read with the same item reader the Volcanic Magnet check uses (user: it works on their client).

## What I understood

A new **Hunt** (not PvP): find the **Legendary Sword Dealer** in the Second Sea - the NPC who
sells the three swords you need for True Triple Katana (**Shisui, Saddi, Wando**) - much faster
than asking the Café Manager, who makes you wait 10 minutes after you join a server.

## What the game does (read in its own client, decompiled v4623)

- **The dealer's own dialogue** asks the server:
  - `CommF_:InvokeServer("LegendarySwordDealer", "1")` -> the **name of the sword he sells here**
    (Shisui / Saddi / Wando), or nothing if he is not here.
  - `CommF_:InvokeServer("LegendarySwordDealer", "2")` -> buys it for **$2,000,000**. Answers:
    `1` bought, `0` not enough money, `2` you already own it, anything else = he is gone.
- **The Manager** asks `CommF_("Manager", "1")`: `0` = OK, `-1` = "Are you new to this island?"
  (that is the 10-minute rule), anything else = "too early" (Bartilo's quest not done). Then
  `("Manager", "2")` gives the text of where he was last seen. **We do not need the Manager at
  all**: the dealer's own call answers directly.
- **Public hubs** ask `"1"` and buy with `"2"` **from anywhere on the map** (no flying to him), then
  hop to the next server. So the server probably does not check how far you are from him. (Not
  proven on your account: that is first-test item 1.)
- fast_farm already has this exact shape: the **Aura recipe hunt** (Barista Cousin): asked from
  anywhere, learned, otherwise the next server. The sword hunt copies it.
- Wiki: he stands at one of **7 spots** in the Second Sea (the Colosseum's top arch, under the
  Kingdom of Rose, a Green Zone beanstalk leaf, the rocks by Fajita, the Graveyard pillar, near the
  Factory by Jeremy, the central house on Remote Island) and comes back every few hours per server.
  So hopping servers and asking each one is the fast way.

## How the hunt works

```
join a server (Second Sea)
 -> ask "1" from where you are (instant, no waiting, no Manager)
     nothing  -> his model loaded anyway? (workspace.NPCs / ReplicatedStorage.NPCs)
                   yes -> fly to him, ask again (in case the server does check distance)
                   no  -> next server
     a sword  -> one you still need?
                   no  -> next server
                   yes -> buy ("2") from where you are
                            refused -> fly to him, buy again
                            bought  -> that sword's switch goes off; all done = the hunt stops
                            no money -> the hunt STOPS (another server will not fix it)
```

## Decisions - approve or reject each one

**D1. The switch.** Hunt page / Home: "Legendary Sword hunt" (HuntKind `sword`), like the other
hunts (only one on at a time). Second Sea only. In another sea it says "go to the Second Sea" and
does nothing (no auto travel).

**D2. Which swords.** Three switches: Shisui, Saddi, Wando, all on. A sword bought (or "you already
own it") switches itself off. All three off = the hunt stops and says "take them to the Mysterious
Man for TTK".

**D3. Owned swords skipped at the start.** Your inventory is read when the hunt starts (if your
client lets it be read); swords you already own are switched off, so it never hops for one you have.

**D4. Money first.** Less than $2,000,000 = it does not start (and says so), instead of hopping
for nothing.

**D5. Faster per server.** The hunt waits 1 s after a join instead of the usual 3 s before hopping
(the answer does not need the world to load).

**D6. (Optional) Server news line.** In the Second Sea, the news strip under the panel title shows
"Sword Dealer: here (Saddi)" or "not here", asked once every 30 s. Useful even with the hunt off.

**D7. (Not planned) The Mysterious Man / TTK purchase itself.** Say if you want that too.

## Risks

- Buying from afar is what the public hubs do; if your server refuses it, the hunt flies to him
  (his spot is loaded in ReplicatedStorage or workspace). The first test shows which one works.
- He only sells **one** of the three per visit, so getting all three takes several servers.

## Tests (after "go")

`tools/elite_test.py` gets the sword step (sword here / not here / not picked / bought / owned /
no money / refused from afar -> flown to / all done -> stop / another sea). README "Legendary
Sword hunt: first test".
