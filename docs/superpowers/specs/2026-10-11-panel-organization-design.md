# Panel organization - plan

2026-10-11. Status: **BUILT the same day (build 2026-10-11.3), every decision at A** (your "go").
- D2-A done without touching the farm: the panel reads the mode by the main loop's own order
  (PvP, Leviathan, hunt, random, raid, circuit), so PvP / Leviathan off shows the mode underneath.
- D7: 342 x 666 (not 650) - what Home's 8 rows + status + Start need with no scroll bar.
- Found while drawing every page (tools/panel_preview.py) and fixed: a picker row's name ran
  under its right-hand tag (the old panel too: "After the loot: the next server" under "the hunt
  goes on there"); now the name stops short of the tag. Long tags moved into How it works.
- Every readout / caption / setter moved by a script from the old file (verbatim, by statement);
  five captions that pointed at a moved item were reworded ("the line below" -> "at the top").
- Guard: tools/panel_test.py, 657 checks, 14/14 planted mistakes caught.

## What I understood

"First firm script" = **fast farm** (same as last time; if you meant farm_pro, say so).
The panel works, but things are scattered. You want it organized so well that someone who
has never seen it opens it and already knows where everything is - no learning. Every
setting in one obvious place, every hunt / event easy to find.

This is a **layout job only**. No farming behaviour changes (two small exceptions are
decisions D2 and D3 below, and you can say no to both).

## What is wrong now (read in the code - the panel is lines 12407-14994)

1. **Home is a wall.** Under Start: 20 switches (PvP, Raid, Raid loop, Random, 14 hunts,
   Volcano, Leviathan), each with a long subtitle, then 10 page rows. About 1,700 px of
   scrolling inside a 488 px window. The thing you need most (what is it doing?) is buried.
2. **The same control lives in two places.** The 14 hunt switches are on Home AND on the
   Hunt page. Volcano: Home + Sea page. Leviathan: Home + Sea page. PvP: Home + PvP page.
   Two copies = you never know which one is "the real one".
3. **Settings sit where the code is, not where you would look:**
   - Raid settings (pull radius, island reach, stuck time, the chip, the fruit price) are
     on the **Magnet** page.
   - Random mode's reach is on the **Magnet** page.
   - **Silent aim** (all guns, every mode) is on the **Sea** page, between volcano readouts.
   - Team pick is on the Hunt page under "after a hop".
   - Prehistoric, Mirage, Sea events and Sea travel are switched on the **Hunt** page, but
     all their settings are on the **Sea** page.
4. **Two giant pages.** Hunt = 7 hunts' settings in one scroll (11 headings, 12 paragraphs,
   10 readouts). Sea = 7 different things in one scroll: 32 sliders, 13 switches,
   17 headings, 17 paragraphs, 14 readouts.
5. **Everything is mixed together.** Settings, live status, learned tables and long
   explanations are interleaved. About 57 explanation paragraphs; the Leviathan one is 16
   lines. You read through text to find a switch.
6. **A hidden rule.** The hunts look like independent switches, but turning one on turns the
   others off (and Raid turns Random off). The panel never says so - you find out when a
   switch flips by itself. (Your own rule from farm_pro: "no control may cancel another".)
7. **Two visual bugs** (found by reading the code - not yet seen on a screenshot):
   - Switch subtitles do not wrap. 40 of the 43 are longer than the ~210 px they get, so the
     text runs under the On/Off word and the switch.
   - Readouts are written for a fixed-width font (`now       `, `joined    `) but drawn in
     Gotham, so the columns do not line up.

## The idea: three questions, one place each

```
  What is it doing?      ->  top of Home (status + Start/Stop)
                             and the top of every page, always the same spot
  What should it do?     ->  MODE: one list of everything the script can do,
                             each mode with ONE page holding all its settings
  How does it fight?     ->  FIGHT: Attack, Magnet, Position, Safety & haki -
                             shared by every mode
  (the rest)             ->  MORE: Travel & boat, Servers & team, Stats & debug
```

**The rule for every setting:** it lives on the page of the thing it changes. If it changes
several things, it lives on the shared page named after that mechanism (boat speed ->
Travel & boat), and each page that uses it gets a link row to it. Nothing exists twice.

**Every page has the same shape**, top to bottom - learn it once, you know all 28 pages:

```
  Back   Title
  status: what this is doing now (1-3 lines)
  the main switch (mode pages only)
  SECTION
    rows...
  SECTION
    rows...
  Link rows  (e.g. "Server hop & team  >")
  How it works          Show     <- the long explanations, closed
  Details               Show     <- learned tables, probes, lists, closed
```

## The new map

### Home - fits without scrolling (D7)

```
 +--------------------------------------------+
 | Fast Farm · 2026-10-11.3            * Hide |
 | [NIGHT 3 of 8  4:12] Mirage up 2 min ·...  |
 |                                            |
 |  Raid · Island 3                           |  <- what it is doing
 |  fight · 120 kills · 14/min · pile 6       |
 |  +--------------------------------------+  |
 |  |             Stop  ·  Raid            |  |  <- D8
 |  +--------------------------------------+  |
 |  MODE                                      |
 |  Mode          Raid · island 3 of 5     >  |  -> the Modes list
 |  FIGHT  ·  EVERY MODE                      |
 |  Attack        Auto M1 · Z X C          >  |
 |  Magnet        On · 6 held              >  |
 |  Position      auto · 25 up             >  |
 |  Safety & haki out under 30% · Ken on   >  |
 |  MORE                                      |
 |  Travel & boat 330 fly · 300 boat       >  |
 |  Servers & team hop on · Pirates        >  |
 |  Stats & debug 14.2 kills/min           >  |
 +--------------------------------------------+
```

Eight rows. No switch on Home except Start/Stop. The Mode row's value says what is on
("Raid", "Berry hunt · 3 picked", "Raid + Volcano").

### The Modes list - everything the script can do, grouped by what it is

```
  Back   Modes
  FARM  ·  fights enemies
  Circuit farm      your targets, by level   On  >
  Random            anything near you            >
  Raid              the raid's island            >
  HUNT  ·  one thing, next server if not here
  Elite pirates     Diablo · Deandre · Urban     >
  Fruits            on the ground, stored        >
  Haki berries      Legendary Aura colors        >
  Aura recipe       the Barista Cousin           >
  Legendary swords  Shizu · Saishi · Oroshi      >
  Fire Flower       Draco V2                     >
  Blaze Ember       Hydra Island quests          >
  SEA  ·  from a boat
  Sea travel        you steer                    >
  Sea events        beasts, sharks, piranhas     >
  Prehistoric       island + volcano loop        >
  Mirage            onto it · dealer · chests... >   <- D3
  Leviathan         Frozen Dimension             >   <- D2
  YOU FIGHT
  PvP               the farm stops               >   <- D2
  ALONGSIDE ANY MODE
  Volcano event     when Prehistoric is up  Off  >
```

Fixed order (rows never move, so your eye learns where each one is). The one that is on
says **On** in green. Tap a row = open its page (D1).

### A mode page - example: Haki berries

```
  Back   Haki berries
  picked 3 · you have Pink 12 · White 4 · Red 9      <- status
  Haki berries                         On  (o--)     <- the mode switch
  one mode at a time - On turns Raid off             <- says what it cancels, BEFORE you tap
  WHICH BERRIES
  [ Pink Pig Berry        Winter Sky 15        ]     <- filled = picked (D6)
  [ White Cloud Berry     Snow White 10        ]
    Red Cherry Berry      Pure Red 15
    ...
  Server hop & team                              >   <- link (shared page)
  How it works                                Show
  Details  (on the bushes here)               Show
```

### Every page and what it holds

**FIGHT (every mode)**

| Page | Sections, top to bottom |
|---|---|
| **Attack** | status (now / last skill) · M1 WEAPON (picker) · SKILLS (Every weapon you carry + Z X C V chips, inventory swap, per-weapon list -> Weapon page) · RHYTHM (skills first / M1 first, M1 between, waits) · AIM (lock on the pile, camera free, **Silent aim** - moved here from Sea) · GUNS (hold the button, past the heat, shot every) · MASTERY FARM (weapon, stop at) · M1 METHOD (how M1 lands, M1 every, remote reach, try again) · How it works · Details (hit counts + Clear, M1 per weapon, hit sender, gun / inventory / mastery notes) |
| Weapon (from Attack) | as now: Use, M1 + key chips, hold per key, move up |
| **Magnet** | status (held / staying put / put back) · Magnet · THE PILE (pull every one loaded, pull at most, within, most in one pile, width) · OTHER SPECIES (pull them, camp radius) · KEEPING THEM HITTABLE (put back after, learn the limit) · How it works · Details (why no damage + Clear, learned limits + Forget) |
| **Position** | as now, status on top, paragraphs folded |
| **Safety & haki** | as now (escape below / come back at, J, E, check every), paragraphs folded |

**MODES**

| Page | Holds |
|---|---|
| Circuit farm | the circuit (old Targets page): picker, Clear, type a name, Bosses first, wait for a lone species |
| Random | its reach (moved from Magnet) |
| Raid | Raid loop, pull within, island counts within, stuck -> relocate, the chip, the fruit price, raid status (all moved from Magnet + Home) |
| Elite pirates | Elite Hunter quest, look-for seconds, elite status; chalice rule in How it works |
| Fruits / Haki berries / Aura recipe / Legendary swords / Fire Flower / Blaze Ember | each its own section from today's Hunt page, + link "Server hop & team" |
| Sea travel | status + link "Travel & boat" |
| Sea events | danger, which kinds to fight (tick list), goal, stop at goal, ship raid flee distance, Ask the Spy, Reset count; link "Fighting at sea" |
| Prehistoric | status, Volcanic Magnet first, safety cap (prehistoric only); links "Travel & boat", "Volcano event" |
| Mirage | the job (D3), which Mirage for Blue Gear, status; link "Travel & boat" |
| Leviathan | height over the part, your share, status; link "Fighting at sea" |
| PvP | as now (Vision, Aim, Movement) - already the best-organized page |
| Volcano event | after the loot (next server / again, stay, home by respawn, egg, bones) · VENTS (vent gun, keys, stand-off) · GOLEMS (golem weapon, held off / up) · PRIORITY (relic, pressure) · loot switch · Details (vents learned, meters) |
| **Fighting at sea** (shared) | loadout (Kitsune form / never), form test time, weapons at sea, keys chips, DODGE (5), heights (beast, fish, boat lift), Details (what hurts a sea beast) - one page for Sea events and Leviathan, which both use it |

**MORE**

| Page | Holds |
|---|---|
| Travel & boat | FLYING (fly speed, instant under) · THE BOAT (speed, A/D turn speed, compass meter) · SEARCHING THE SEA - Prehistoric, Mirage (I steer / auto, out to, turn, sail on, turn every, turn up to) |
| Servers & team | status (joined, servers, last join) · HOP (on/off, order, try again after) · TEAM (pick on join, Pirates / Marines) · BY HAND (hop now, forget servers, reset counts) |
| Stats & debug | as now |

### Where every old control goes (nothing deleted)

| Old place | Control | New place |
|---|---|---|
| Home | PvP / Raid / Raid loop / Random switches | PvP page / Raid page / Raid page / Random page |
| Home + Hunt page | 14 hunt switches (twice) | each hunt's own page, once |
| Home + Sea page | Volcano, Leviathan (twice) | Volcano page, Leviathan page, once |
| Home | the big mode readout | Mode row value (short) + each mode page's status |
| Targets | everything | Circuit farm page |
| Magnet | Random mode reaches | Random page |
| Magnet | Raid pulls within, island counts within, stuck, raid readout, chip, fruit price | Raid page |
| Hunt | fruit / berry / recipe / sword / flower / ember / elite sections | one page each |
| Hunt | hop, order, try again after, team, reload way, by-hand buttons | Servers & team |
| Hunt | Look for N s (elite only) | Elite pirates page |
| Sea | sea events block | Sea events page |
| Sea | loadout, weapons, dodge, heights, keys, learned | Fighting at sea page |
| Sea | boat speed, turn speed, compass meter, steering + search legs | Travel & boat |
| Sea | Volcanic Magnet, safety cap, prehistoric status | Prehistoric page |
| Sea | mirage status, which Mirage | Mirage page |
| Sea | volcano: after loot, egg, bones, vents, golems, priority, loot | Volcano page |
| Sea | **Silent aim** | Attack › Aim |
| Attack, Weapon, Position, Safety, PvP, Stats | the rest | same page, reordered + folded |
| every page | ~57 paragraphs | How it works, per page (D4) |
| every page | learned tables, lists, probe lines | Details, per page (D5) |

## Decisions - approve or reject each one

**D1. How you pick a mode.**
- **A (recommended):** the Modes list opens a page; the page's top row is the mode's own
  On/Off switch (like Wi-Fi in phone Settings). You can set a hunt up (pick berries,
  recipes, swords) BEFORE turning it on - today a hunt switched on while running starts
  hopping at once. Cost: 3 taps to change mode (Home > Modes > page > switch).
- B: the Modes list is a radio list - one tap picks the mode at once; a "Raid settings >"
  row on Home opens the picked mode's page. 2 taps, but a mode's settings can only be
  opened after it is picked.

**D2. PvP and Leviathan.** Today they sit ON TOP of the mode: Leviathan overrides it, PvP
stops the run while Raid (say) stays on underneath. In one list, that shows two "On" at once.
- **A (recommended):** they become modes like the rest - one at a time. Turning PvP or
  Leviathan OFF brings back the mode you had before. The list always shows exactly one On.
- B: keep as now; their rows say "on top of your mode".

**D3. Mirage.**
- **A (recommended):** one Mirage row; its page picks the job (onto it / Advanced Fruit
  Dealer / chests / Blue Gear) - they share the boat and the search, only the job differs.
  Needs one new saved setting (`CFG.MirageJob`) so the job is remembered while Mirage is off.
- B: four rows as now.

**D4. The long explanations.**
- **A (recommended):** each row keeps ONE short subtitle line (wrapped, never under the
  switch). The long text moves into "How it works" at the bottom of that page, closed until
  you tap Show. Nothing deleted.
- B: keep the paragraphs where they are, just shortened.

**D5. Learned tables, lists, probe lines.**
- **A (recommended):** "Details" at the bottom of the page they belong to, closed, in a
  fixed-width font so the columns line up.
- B: all of them on Stats & debug.

**D6. Compact pickers.**
- **A (recommended):** Z X C V F as one row of five chips (filled = on) instead of five
  switch rows; berries, recipes, swords, sea-event kinds as tick lists (filled row = picked,
  like the radio lists). Five key switch rows (~300 px) become one chip row (~48 px); the
  8 berry switches (~480 px) become a ~330 px tick list.
- B: one switch per item, as now.

**D7. Panel height.**
- **A (recommended):** 342 x 650 (from 570) so Home ends without a scroll bar. Still fits a
  720p screen; Hide works as now.
- B: keep 570; Home scrolls a little.

**D8. The Start button says what it starts.** "Start · Berry hunt" / "Stop · Raid".
- **A (recommended):** yes. **B:** just Start / Stop.

## What stays exactly the same (promise)

- Every setting (`CFG`) name, default and meaning. Your saved settings, the hop carry and
  the autoexec loader keep working. Every farming / hunting / fighting function untouched.
- The look you approved: warm near-black, ivory, green On, the switch with the word On/Off,
  sliders, radio lists, the news strip, Hide, drag.
- Only exceptions: D2-A (PvP / Leviathan join the one-at-a-time rule) and D3-A (one new
  saved setting). Say no and they do not happen.

## Risks - plainly

- **Big move: ~2,600 lines rearranged.** A readout or a setter could get lost on the way
  (it has happened: an edit once dropped a branch with every test green). Guard: every
  readout and setter is MOVED as-is, never retyped, and a new test proves nothing was lost
  (below).
- **Luau's 200-register limit.** ~25 pages in one function would hit it. Each page becomes
  an entry in a table of builder functions, not a new local.
- **D1-A is 3 taps to change mode.** If that feels slow in play, D1-B is the faster
  alternative.
- **I cannot see the game.** Sizes are calculated (row 44-48 px, text widths at 13 px). The
  first look in game may need spacing tweaks.

## What gets built after "go"

1. **Pieces:** subtitles that wrap; key chips; tick list; "How it works" / "Details" rows
   that open and close; mode row with the green On; a Back that goes where you came from
   (needed for link rows); fixed-width Details.
2. **Pages rebuilt in the new map** - every closure moved, not rewritten.
3. **`tools/panel_test.py`** (new): runs the REAL panel code in luau.exe with stand-in Roblox
   objects and checks:
   - every page builds without an error;
   - every page is reachable from Home in at most 3 taps, and no link points to a missing page;
   - **census:** every `CFG` key the old panel could change is changed by exactly ONE control
     in the new one (none lost, none doubled);
   - every page follows the shape (status, switch, sections, links, How it works, Details).
4. All 29 suites + `checks.py` green, build stamp bumped, README panel section updated,
   commit + push (as always).

## First look in game (after the build)

1. Home: no scroll bar, 8 rows, status + Start on top, Mode row says the mode.
2. Modes: tap Haki berries, pick berries, turn it on -> Raid's row loses its On.
3. No subtitle runs under a switch anywhere.
4. Details on the Attack page: the hit-count columns line up.
5. Back from Fighting at sea goes to the page you came from (Sea events or Leviathan).
6. Every mode you use still does exactly what it did before.
