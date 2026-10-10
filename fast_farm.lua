--[[
    BLOX FRUITS FAST FARM
    =====================
    The loud one. farm_pro walks, looks, and shows the server nothing a player
    could not do. This does the opposite, on purpose, for speed.

      MAGNET   every enemy of the quest species in the camp is pulled into one
               pile at the middle of where they SPAWNED, and held there every
               frame. Knockback (a Kitsune hit) is undone before it moves them.
               The middle of their spawns is inside every one's own area, which
               is what keeps a pulled enemy damageable.
      LOCK     you are held at a fixed spot over the pile. A lunge cannot drag
               you off it.
      NOCLIP   no collisions at all while running. Pillars, trunks, rough
               ground: none of it exists for you.
      TRAVEL   short hops are instant; long trips fly at the speed you set.
      M1       one hit call can name every enemy in the pile. Or your fruit's
               own click, or plain keys -- whichever ACTUALLY does damage,
               found by trying each one against the pile.
      COMBO    per-weapon switches for M1 Z X C V F. Ready skills are read off
               the game's own cooldown bars; M1 fills the gaps between them.
      CIRCUIT  the species on the Targets page: A's pile, B's pile, back to A,
               respawned by now. No quests (max level; removed 2026-09-28).
      HUNT     ONE hunt, the one you switch on: elite pirates (God's
               Chalice), fruits on the ground (grabbed, STORED, never eaten)
               or berries (the Haki colors). Nothing for it here = the next
               server. The God's Chalice ends it: no hop, ever, in the server
               it came in. Or the Prehistoric Island: a boat driven into
               Sea Danger 6 until it comes.
      VOLCANO  its own switch: a Prehistoric Island up = its event, vents
               closed with aimed skills, Lava Golems held off the relic and
               killed, then the bones and the egg.

    TAKEN FROM FARM_PRO UNCHANGED: the level table, Enhancement + Observation,
    walk on water. Its panel too -- made opaque, because farm_pro's background was
    94-100% see-through (a UIGradient's transparency applies TO its frame).

    USE IT ON AN ACCOUNT YOU CAN AFFORD TO LOSE. Flight, noclip, hovering and
    enemies moved by your client are exactly what anti-cheat and player
    reports look for. farm_pro is the one for your main.

    CONTROL
        _G.BFF.start()          _G.BFF.stop()          _G.BFF.config
]]

-- "reload": a new copy replacing this one, not you stopping -- an elite hunt
-- carried over a hop stays carried.
if _G.BFF and _G.BFF.stop then pcall(_G.BFF.stop, "reload") end
-- farm_pro and this both drive the character; two at once fight each other.
-- Clearing _G.BFP also ends farm_pro's water loop, which runs while it is itself.
if _G.BFP and _G.BFP.stop then
    pcall(_G.BFP.stop)
    _G.BFP = nil
end

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser  = game:GetService("VirtualUser")
local VIM          = game:GetService("VirtualInputManager")
local player       = Players.LocalPlayer

pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    local old = pg and pg:FindFirstChild("BFPHUD")
    if old then old:Destroy() end
end)

-- =========================================================
-- CONFIG
-- =========================================================
-- Every field is independent. Nothing here turns anything else off.
local CFG = {
    -- ---------- TARGETS ----------
    -- The circuit, in the order it runs. Empty means the species for your
    -- level, alone.
    Targets            = {},

    -- ---------- MAGNET ----------
    Magnet             = true,
    -- Every loaded one of the quest species goes in the pile, however far it
    -- is, and one that spawns while the pile is being hit joins it at once.
    -- The pile sits at the middle of the camp's spawn points: the one spot
    -- where the farthest pull is shortest, so every one stays in its area.
    PullAll            = true,
    -- How far one can be pulled from where it spawned and still take damage.
    -- Nobody publishes the game's number; the hubs pull within 250-350. A camp
    -- wider than this (Port Town) is piled one side at a time. LearnLeash
    -- lowers it per species when a pulled one stops taking damage further out
    -- than others that still do. OFF by default (user, 2026-09-30: "with it
    -- off the pile holds"): it only ever lowers, and a hit that never reached
    -- the back of the pile looked exactly like a limit -- the camp was then
    -- split into sides and piled a few at a time.
    MaxPull            = 300,
    LearnLeash         = false,
    GrabRadius         = 300,    -- PullAll off: spawned this close to the camp = pulled
    GrabMax            = 30,     -- most enemies in one pile
    PileSpread         = 3,      -- the pile is a ring this wide, not one point
    -- Other species on your circuit that spawn IN THIS CAMP go in the pile
    -- too: free kills, and the hit call names them anyway. Only the quest
    -- species counts for the quest.
    PullOthers         = true,
    OthersRadius       = 100,    -- "in this camp" = spawned this close to the pile
    -- An enemy held in the pile and hit this long with no HP change is out
    -- of its own area (or not yours to move). It goes back where it came from
    -- and is left alone for thirty seconds.
    PutBackAfter       = 3,

    -- ---------- WHERE YOU HANG ----------
    -- "auto": high over the pile when the hit reaches from there (remote hit,
    -- fruit skills), close beside it when it does not (keys, melee skills).
    -- "fixed": one spot, whatever is firing.
    HeightMode         = "auto",
    -- On: never down to the close spot -- every attack is fired from HeightSafe
    -- over the highest enemy in the pile. What cannot reach from there (a
    -- sword swing, a short melee skill) will show up as MISSED / nothing landed.
    StayHigh           = true,
    HeightSafe         = 20,
    HeightMelee        = 3,
    MeleeDistance      = 5,      -- close = this far out to the side, pile in front
    HeightFixed        = 12,
    SideFixed          = 0,

    -- ---------- M1 ----------
    -- "auto" tries each way of landing an M1 against the pile and keeps the
    -- first one that takes HP off. The others force one way.
    M1Method           = "auto", -- "auto" | "remote" | "click" | "keys"
    M1Every            = 0.06,   -- seconds between M1s (user, 2026-10-05: 0.06)
    HitRange           = 60,     -- the remote hit names enemies this close

    -- ---------- RHYTHM (when M1 AND skills are on) ----------
    StartWith          = "Skills", -- "Skills" | "M1"
    M1Between          = 4,      -- M1 swings between skills; 0 = skills whenever ready
    CastWait           = 0.45,   -- after a skill, before the next action
    EquipWait          = 0.12,   -- after a weapon swap, before using it
    -- Skills and clicks fire where the cursor points. On: while the pile is
    -- being hit, the camera is turned every frame so the line through YOUR
    -- cursor -- wherever it is -- goes through the pile. The cursor stays free.
    AimSkills          = true,
    -- On: your camera and cursor are never moved. The aim is put on the
    -- camera only in the part of a frame that is never drawn, right when the
    -- key is read, and your view is back before the frame is drawn.
    -- Off: the view itself turns so the pile is under your cursor.
    AimHidden          = true,
    -- SILENT AIM (user, 2026-10-04: "my mouse should be totally ignored"):
    -- while a skill or an aimed M1 is fired by this script, the game is told
    -- the mouse points AT the target - Mouse.Hit / Target / X / Y / UnitRay.
    -- Hooked only while casting, let go 3 s after; your own clicks never.
    SilentAim          = true,
    CamDistance        = 30,     -- the camera this far from the pile
    CamPitch           = 55,     -- looking down at most this steeply (degrees)

    -- ---------- WEAPONS ----------
    -- [tool name] = { use, M1, Z, X, C, V, F, hold = { Z = seconds, ... } }
    -- Filled from your backpack. Everything off except, on the very first
    -- load, M1 of whatever is in your hand.
    Weapons            = {},
    WeaponOrder        = {},
    -- EVERY WEAPON YOU CARRY: no Attack-page setup - M1 as M1Weapon picks, the
    -- AutoKeys of every weapon you carry. OFF by default (user, 2026-10-05: it
    -- was for the volcano, and two M1s do that now - Hallow Scythe on the
    -- golems, Skull Guitar on the vents). Off: the Attack page's own choices.
    AutoAttack         = false,
    -- WHICH WEAPON SWINGS M1, in every fight (user, 2026-10-05: "I picked the
    -- sword, it still swings the fighting style"). "" = auto: a sword first,
    -- then a fighting style, the fruit, a gun. A name = that one, always.
    M1Weapon           = "",
    AutoKeys           = { Z = true, X = true, C = true, V = false },
    -- FROM YOUR INVENTORY: every carried skill cooling = the next sword or gun
    -- in your inventory is put in your hands (CommF_ "LoadItem" - no menu)
    -- and its skills fired. What you carried goes back when the farm stops.
    InvSwap            = true,
    InvSwapGap         = 1.5,        -- seconds between two loads, at least
    InvSkip            = {},         -- [name] = true: never loaded
    -- THE MASTERY FARM (user, 2026-10-07: Dragonstorm to 500 for Draco v4,
    -- Dragonheart already done). A weapon named here is the ONLY one that
    -- hurts anything, in every fight: its M1 and its AutoKeys (a key not
    -- unlocked yet never fires and is left alone). Nothing else swings,
    -- nothing is loaded from the inventory - a kill another weapon helps
    -- with shares the mastery. Not carried = loaded from your inventory.
    -- The farm stops when it reaches MasteryStop (0 = never). "" = off.
    MasteryWeapon      = "",
    MasteryStop        = 500,
    -- A GUN'S M1 (user, 2026-10-07: "for the gun to work best it should hold
    -- down"). On: a gun that fires while held (Dragonstorm) gets the button
    -- HELD like a player - the game's own fire loop, every shot silently aimed
    -- at one enemy until it dies. The game caps it: 12.5 shots/s, 3 s of heat,
    -- then 1 s locked. Off: a click per M1 (3 shots).
    GunHold            = true,
    -- PAST THE HEAT: the game's own shot (its validator kept in step), called
    -- every GunFastEvery seconds - no heat, no lockout. What the public hubs
    -- do; the wiki says long gun M1 streams get kills marked suspicious.
    -- OFF by default.
    GunFast            = false,
    GunFastEvery       = 0.08,       -- seconds a shot (0.08 = the gun's own speed)

    -- ---------- TRAVEL ----------
    TravelSpeed        = 330,    -- studs/s. The public hubs all settled on 330.
    InstantHop         = 150,    -- shorter than this: one write, no flight

    -- ---------- RAID MODE ----------
    -- Species and quests forgotten: every living enemy, any kind, within
    -- RaidRadius of the newest raid island (of you, outside a raid) goes in
    -- one pile. Observation is not pressed (raids switch it off).
    RaidMode           = false,
    RaidRadius         = 450,    -- the public raid scripts' "on this island"
    -- STALE ISLANDS (user, 2026-10-10: the raid over and back at the Castle
    -- on the Sea, it flew off to the raid's islands). An island marker
    -- counts within RaidReach of you (the public hubs: 2500), a farther one
    -- only while the raid timer is up. Outside a raid nothing is fought and
    -- you stay where you are (the loop's own steps excepted).
    RaidReach          = 2500,
    -- THE STUCK FIGHT (user, 2026-10-10: the last island's last enemies
    -- "stuck, not killing"): no kill and no HP off any enemy within
    -- RaidStuckReach of the island for RaidStuckSecs = relocate - the
    -- nearest one fought where it stands from a new spot (over it, then
    -- round it), its skip forgotten; again while it lasts.
    RaidStuckSecs      = 12,
    RaidStuckReach     = 1500,
    -- THE LOOP (user, 2026-10-10): the raid over - a RaidChip chip from the
    -- Mysterious Scientist for your cheapest STORED fruit worth at most
    -- RaidFruitMax (loaded into the backpack, never your hand; none = his
    -- $100,000 way, every 2 h), the raid button pressed, the raid again.
    -- Anything that fails = you stay where you are, tried again later.
    RaidLoop           = true,
    RaidChip           = "Flame",    -- Flame Ice Quake Light Dark Spider Magma Buddha Sand
    RaidFruitMax       = 200000,     -- Beli: the common fruits (Rocket .. Spike)

    -- ---------- RANDOM MODE ----------
    -- Quests forgotten: every living enemy within RandomRadius of you -- at
    -- the Castle on the Sea, of the pirate raid's area -- and EVERY one of
    -- them damaged. Pulled only within its pull limit (a far or diagonal one
    -- gets its own pile after); one that takes no damage when pulled is fought
    -- where it stands, from close if high does not hurt it.
    RandomMode         = false,
    RandomRadius       = 750,

    -- ---------- THE HUNT ----------
    -- ONE hunt at a time, the one you switch on; it does only that, then the
    -- next server. Nothing picks for you.
    Hunt               = false,
    HuntKind           = "elite",    -- "elite" | "fruit" | "berry" | "recipe" | "flower" | "ember" | "prehistoric"
                                     -- | "mirage" | "dealer" | "mchest" | "gear" (the four Mirage hunts)
                                     -- | "seaevents" | "sail" (Sea travel: the boat only)
    -- FRUIT HUNT: fruits on the ground, grabbed and STORED, never eaten.
    -- Worth it = the game's own price at least this (0 = any). Player drops
    -- are mostly trades (dropped and picked up within a second): off =
    -- server spawns only.
    FruitMinPrice      = 0,
    FruitPlayerDrops   = false,
    -- BERRY HUNT: the Haki colors. The Barista turns berries into Aura
    -- colors: Snow White 10 White Cloud, Winter Sky 15 Pink Pig, Pure Red 15
    -- Red Cherry (Legendary, + 7,500 fragments each). At most 4 in a server,
    -- a new one every 15 min, gone after an hour, anyone can take one. Only
    -- the ones switched on here are flown to.
    BerryWant          = {
        ["Pink Pig Berry"] = true, ["White Cloud Berry"] = true, ["Red Cherry Berry"] = true,
        ["Blue Icicle Berry"] = true, ["Green Toad Berry"] = true, ["Orange Berry"] = true,
        ["Purple Jelly Berry"] = true, ["Yellow Star Berry"] = true,
    },
    -- AURA RECIPE HUNT: the Barista Cousin (Second and Third Sea) teaches
    -- ONE recipe per server. The ones switched on here are learned when he
    -- teaches them; anything else = the next server. A recipe learned is
    -- switched off by itself. Needs Aura stage 5 ("Iron Man" title).
    RecipeWant         = {
        ["Winter Sky"] = true, ["Snow White"] = true, ["Pure Red"] = true,
    },
    -- FIRE FLOWER HUNT (Draco V2, Third Sea): Forest + Mythological Pirates
    -- killed one at a time where they stand (no magnet), the flower picked
    -- the moment it lies there, then the next server. None this long after
    -- the FIRST kill in a server (not the join): the next server.
    FlowerGiveUp       = 2.5,        -- minutes, from the first kill (respawn waits count)
    -- BLAZE EMBER HUNT (Third Sea): the Dragon Hunter's quests on Hydra
    -- Island, over and over - 3 Hydra Enforcers / 3 Venomous Assailants /
    -- 10 trees - and the 3 embers each one drops. Needs Dragon Talon 500
    -- mastery + the Dojo's Yellow Belt.
    EmberStopAt        = 99,         -- stop with this many (99 = the most you can hold)
    EmberTreeMax       = 120,        -- trees taller than this are never tried (the two giants)
    -- PREHISTORIC HUNT (Third Sea): a boat bought at Tiki Outpost's BACK boat
    -- dealer and driven west into Sea Danger 6 until the island comes. None
    -- by SeaSearchTo = the next server. The island up = the hunt's job done;
    -- the Volcano event switch (below) does the event.
    SeaBoat            = "Beast Hunter",
    SeaSpeed           = 300,        -- studs/s, 250-350 (the boat sails ~140 by itself)
    -- THE SEARCH, auto (user, 2026-10-06): out to SeaSearchTo m from Tiki; no
    -- island = a SeaTurnBack-degree turn to the LEFT and SeaLeg2 m more (as
    -- sailed); still none = the next server. The island mostly came late.
    -- (user, 2026-10-10: 17,000 out, 7,000 after the turn)
    SeaSearchTo        = 17000,      -- meters from Tiki: the first leg ends here
    SeaTurnBack        = 120,        -- degrees left at the end of it
    SeaLeg2            = 7000,       -- meters sailed after the turn (0 = the next server at once)
    -- THE SERVER'S CLOCK (user, 2026-10-06): the legs are the plan; this is
    -- the safety cap - whatever goes wrong (back at Tiki, a boat that will
    -- not come, stuck in a loop), no island this many minutes after the hunt
    -- started in this server = the next server. The island up = the clock no
    -- longer counts (the event, the loot, then the hop). 0 = off.
    SeaSearchMinutes   = 21,
    -- THE VOLCANIC MAGNET first (user, 2026-10-06): in your inventory = sail;
    -- not = crafted (15 Blaze Ember + 10 Scrap Metal at the Dragon Hunter),
    -- the materials farmed first when short. The 21 min start at the sail.
    SeaMagnet          = true,
    -- The compass meter in studs, counted from the Tiki boat dealer (user's
    -- compass, 2026-10-04: Danger 6 ~2,600 m = 26.3k studs; the Prehistoric
    -- came ~5,000 m = 50k studs). The panel shows both.
    SeaStudsPerM       = 10,
    -- AUTO STEERING (user, 2026-10-06: not a straight line - "left a little,
    -- then right, then straight"). Every SeaTurnEvery..2x seconds, at random:
    -- left, right or straight on; a turn is SeaTurnMax/2..SeaTurnMax degrees
    -- from where it heads now, never more than 45 off west.
    SeaTurnEvery       = 60,         -- seconds (random up to twice this)
    SeaTurnMax         = 20,         -- degrees a turn, at most (half of it at least)
    -- WHO STEERS. "manual" (user, 2026-10-04: the spawn wants time on the sea,
    -- so you keep the boat where you want): your keys at the wheel - A / D
    -- (or the arrows) turn, W goes (and keeps going), S stops - at SeaSpeed;
    -- never the next server by distance. "auto": west, the heading wandering,
    -- the next server at SeaSearchTo. SEA TRAVEL (the Hunt page; user,
    -- 2026-10-10: "just the boat fast" - for the Leviathan, no island wanted)
    -- is always your keys, never an island, never the next server.
    SeaSteer           = "manual",
    SeaTurnRate        = 60,         -- degrees a second while A / D is held
    -- THE MIRAGE: FOUR HUNTS, each its own switch on the Hunt page (user,
    -- 2026-10-07: "the hunts separated"). A Mirage already up = straight to
    -- the job; none = the same boat and search first.
    --   "mirage"  onto the Mirage - nothing else
    --   "dealer"  in front of the Advanced Fruit Dealer, his shop open
    --   "mchest"  every chest on it, nearest first
    --   "gear"    the Blue Gear: your turn at the moon (a high point, face it,
    --             T - never the script's), the gear picked the moment it shows
    -- Each done = the character is yours and the farm stops, on the Mirage.
    -- Which Mirage the GEAR hunt stops for (it lives 15 min; the gear needs
    -- night; the other three take every one):
    --   "any" every one  ·  "night" one that sees night  ·  "full" a full-moon night
    MirageNeed         = "night",
    -- SEA EVENTS HUNT (user, 2026-10-09; Third Sea): the same boat patrols a
    -- slow circle at Sea Danger SeaEvDanger and what comes is FOUGHT or FLED,
    -- each its own switch. Ship raids (the pirate brigades, the Fish Boat and
    -- its crew, the haunted ships) are ALWAYS fled - slow, and they break the
    -- boat. The Leviathan: its own switch (LeviFight, below). Never the next server.
    SeaEvDanger        = 5,          -- 1-6: where the boat patrols
    SeaEvFight         = { ["Sea Beast"] = true, ["Rumbling Waters"] = true, Terrorshark = true,
        Piranha = true, Shark = false },
    -- Every carried weapon fires these at a sea event (the Attack page is for
    -- the normal farm), each the INSTANT it is ready (user, 2026-10-09). NO M1
    -- at a sea event (user, 2026-10-09: an untransformed M1 does nothing to
    -- one - never, not even to test) - only Kitsune's, in Kitsune form.
    -- V is never fired on a transformation fruit (Kitsune's V transforms) -
    -- on everything else it is (Dragon Talon's V).
    SeaEvKeys          = { Z = true, X = true, C = true, V = true, F = true },
    -- DODGING (user, 2026-10-09: "not held on a position to take attacks"):
    -- round a Terrorshark / Piranha / Shark all the time, the direction
    -- changing, the aim locked on it; up DodgeUp the moment it starts an
    -- attack, charges at you or leaps, back down after DodgeTime.
    SeaDodge           = true,
    DodgeRadius        = 30,         -- studs round it
    DodgeSpeed         = 50,         -- studs/s along the circle
    DodgeUp            = 40,         -- studs up when it attacks
    DodgeTime          = 1.0,        -- seconds up
    BeastHeight        = 90,         -- over the sea while a Sea Beast is fought
    FishHeight         = 30,         -- over a Terrorshark / Piranha / Shark
    BoatLift           = 150,        -- the boat held this high while you fight (0 = left on the water)
    FleeTo             = 1500,       -- a ship raid this near the boat: sailed away until it is this far
    -- THE COUNT (the Spy: after a Frozen Dimension, 20 or more KILLED sea
    -- events before he takes fragments again - the wiki). Kept across joins.
    SeaEvGoal          = 20,
    SeaEvStopAtGoal    = false,      -- on: the hunt stops the moment the count reaches the goal
    -- THE LOADOUT AT SEA (user, 2026-10-09: stats in fruit + melee, Kitsune +
    -- Dragon Talon). "auto": Kitsune FORM first (V pressed for you), its M1
    -- tested on each kind of target (Sea Beasts / Terrorshark-Piranha-Shark):
    -- it hurts that kind = stay in form for it; it does not = untransformed
    -- Kitsune + your fighting style. Re-tested every 5th target. "form" /
    -- "base" force one.
    SeaEvForm          = "auto",
    SeaEvTrial         = 20,         -- seconds in form, at most, for the test
    -- The weapons that fight at sea out of form (your points: fruit + melee).
    SeaEvWeapons       = { ["Blox Fruit"] = true, Melee = true, Sword = false, Gun = false },
    -- THE LEVIATHAN (user, 2026-10-09): its own switch. ON = only the
    -- Leviathan (switch it on inside the Frozen Dimension - it starts the
    -- run): its segments first, the head LAST, fought like a Sea Beast
    -- (every ready key, no M1 out of Kitsune form, round it, the water a
    -- floor), its attacks dodged off the game's own warnings; each segment
    -- until your share (the reward needs 8% of the damage on each); its
    -- heart = the character is yours. No boat is touched.
    LeviFight          = false,
    LeviHeight         = 75,         -- over the part being hit (the hubs: 75)
    LeviShare          = 15,         -- % of a segment's HP before the next (others' hits count in it)

    -- ---------- THE VOLCANO EVENT ----------
    -- Its own switch, any mode: whenever a Prehistoric Island is up in this
    -- server - flown to, started at the relic, the vents closed (the volcano's
    -- pressure points), the Lava Golems killed, then the bones and the egg.
    Volcano            = false,
    -- The keys fired at a vent, every carried weapon's (fruit, melee, sword,
    -- gun). Only moves that break things close one.
    VentKeys           = { Z = true, X = true, C = true, V = false },
    VentDistance       = 12,
    -- THE CRATER (user, 2026-10-06: arriving, the character went to the
    -- island's middle - the volcano - touched the lava and died). Flights on
    -- the island go ROUND this disc (studs from the volcano's middle), never
    -- across it; with only the far marker, the island's edge on your side.
    VolcanoKeepOut     = 220,
    -- THE GOLEM WEAPON (user, 2026-10-06: Cursed Dual Katana hits 4100+ a
    -- swing, Hallow Scythe 3755): its M1 on the Lava Golems. Carried or in
    -- your inventory = loaded at the event and kept. "" = the Attack page's
    -- "M1 with" pick.
    GolemWeapon        = "Cursed Dual Katana",
    -- THE GUN M1 AT THE VENTS (user, 2026-10-04; the wiki: Skull Guitar's M1
    -- has Destructible Physics and a short cooldown, "can be used on the
    -- pressure points"; Bazooka and Cannon too). Carried or in your inventory
    -- = loaded and fired at the vent, stood still, before any skill. Skull
    -- Guitar: its own remote ("TAP", the vent) - no mouse. Its M1 costs 20
    -- energy: under that, the skills until it is back.
    VentGuitar         = true,
    -- THE LOOP (user, 2026-10-05): the Prehistoric hunt runs the event itself
    -- (the relic held, E as a fallback), and when it is over and the bones +
    -- the egg are picked: "hop" = the next server, the hunt goes on there;
    -- "again" = the event again on this island (the wiki: no cooldown).
    VolcanoAfter       = "hop",
    -- AFTER THE LOOT (user, 2026-10-07: bones + an egg lost - the loop left
    -- the server ~3 s after the last bone). A pick counts only when the
    -- game's own count goes up; then the hunt stays this many seconds after
    -- the last pick before the next server, so the game saves it. The next
    -- server checks the count the last one said - less = the hunt stops.
    -- (user, 2026-10-10: 20 s, the inventory checked, then home)
    LootStay           = 20,
    -- THE PICKS, slowly (user, 2026-10-10: bones taken "at light speed"; the
    -- egg goes into the inventory by a ~3 s animation - leave before it ends
    -- and it is not yours). Each bone: BoneMin..BoneMax s (random) stood on
    -- it. The egg: stood still EggStay s after E, whatever the count says.
    BoneMin            = 0.5,
    BoneMax            = 1.0,
    EggStay            = 4,
    -- HOME BY RESPAWN (user, 2026-10-10): the stay over, the character is
    -- reset - the game puts you back at your spawn (Tiki Outpost, where the
    -- sail began), never a flight. No new character in RespawnWait s = the
    -- next server from where you stand. Never with the God's Chalice on you.
    RespawnHome        = true,
    RespawnWait        = 20,
    VentM1Every        = 0.3,        -- seconds between shots
    VentM1Time         = 3,          -- seconds of shots at one vent per turn         -- stand this far out from a vent (and 8 up), aiming at it
    -- Magnet on: every golem is held this far from the relic (away from the
    -- volcano) while the vents are closed - a held golem cannot hit the relic.
    -- Magnet off: golems before vents, fought where they stand.
    GolemCage          = 60,
    GolemLift          = 60,         -- ...and held this high over the relic (up in the air)
    -- THE PRIORITY (user, 2026-10-04: lost on the relic's health). A golem
    -- that is NOT held goes first - it is the one hurting the relic - unless
    -- the pressure is over PressureMax while the relic is still over
    -- RelicMin. Held golems are killed whenever no vent is open.
    RelicMin           = 90,         -- percent
    PressureMax        = 70,         -- percent
    VolcanoLoot        = true,       -- after a win: the bones, then the egg
    -- ELITE PIRATE HUNT (Third Sea). Diablo, Deandre, Urban (and Tyrant of
    -- the Skies while he is up): one per server, back 8 min 45 s after the
    -- last one died. Only the LAST hit gets the drops -- the God's Chalice
    -- among them. Fought where it stands, never pulled.
    -- THE TEAM a new server asks for before you spawn (every hop): picked
    -- for you. Never switches the team you are already on.
    AutoTeam           = true,
    Team               = "Pirates",  -- "Pirates" | "Marines"
    -- Nothing worth doing here: the next server. Off: wait in this one.
    -- With the chalice in your backpack or hand there is no hop at all,
    -- whatever this says.
    HuntHop            = true,
    HopOrder           = "fewest",   -- "fewest" (players first) | "random"
    -- The Elite Hunter's quest (the cat at the Castle on the Sea): progress
    -- toward Yama (30), money, EXP. The chalice does not need it.
    EliteQuest         = true,
    EliteLook          = 8,          -- seconds after a join to look before leaving
    HopRevisit         = 10,         -- minutes before a server looked at is tried again

    -- ---------- THE CIRCUIT (Targets page) ----------
    -- One species alone: its camp empty = wait this long for the respawn.
    RespawnMax         = 45,
    -- A boss on the circuit that is up goes before the rest.
    BossFirst          = true,

    -- ---------- SAFETY ----------
    -- There is no real god mode: health lives on the server. What keeps you
    -- alive is height, a pinned pile, Observation, and this.
    EscapeBelow        = 0.35,
    ReturnAt           = 0.80,
    AutoBuso           = true,
    AutoKen            = true,
    KenEvery           = 300,

    Debug              = false,
}

-- THE BUILD (user, 2026-10-07: "did you really push it?"): printed at load,
-- on the panel's title, and in the hop carry - bumped with every change.
local P = { running = false, config = CFG, handsOff = false, build = "2026-10-10.2" }
_G.BFF = P

-- =========================================================
-- LEVEL -> ENEMY -> WHERE IT LIVES
-- =========================================================
-- Rebuilt 2026-09-14 from the published level tables, cross-read against the
-- wiki. The rows that were here before had Third Sea enemies filed at Second
-- Sea levels, so "by my level" resolved to a species that does not live where
-- it then sent you.
-- 2026-09-26: the points below that were off by 250+ studs from where three
-- public hubs (which agree with each other within 150) put the camp were
-- replaced with the hubs' average: Gorilla, Sky Bandit, Dark Master, Toga Warrior, Military Soldier, Military Spy, Royal Squad, Raider, Vampire, Lab Subordinate, Horned Warrior, Arctic Warrior.
-- They are only the LAST way of finding a camp now -- see WHERE A SPECIES IS.
local LEVELS = {
    {1,9,"Bandit",Vector3.new(1059.4,16.5,1546.6)},
    {10,14,"Monkey",Vector3.new(-1445.1,23.5,-48.8)},
    {15,29,"Gorilla",Vector3.new(-1169.8,29.0,-508.9)},
    {30,39,"Pirate",Vector3.new(-1181.3,4.5,3803.5)},
    {40,59,"Brute",Vector3.new(-1145.2,14.8,4321.7)},
    {60,74,"Desert Bandit",Vector3.new(932.2,6.5,4482.0)},
    {75,89,"Desert Officer",Vector3.new(1609.1,6.5,4369.8)},
    {90,99,"Snow Bandit",Vector3.new(1386.8,87.3,-1297.1)},
    {100,119,"Snowman",Vector3.new(1198.2,105.5,-1237.0)},
    {120,149,"Chief Petty Officer",Vector3.new(-4881.1,4.5,4257.4)},
    {150,174,"Sky Bandit",Vector3.new(-4968.3,289.4,-2873.1)},
    {175,189,"Dark Master",Vector3.new(-5243.5,403.7,-2259.7)},
    {190,209,"Prisoner",Vector3.new(5309.8,0.5,475.5)},
    {210,249,"Dangerous Prisoner",Vector3.new(5086.1,2,466.4)},
    {250,274,"Toga Warrior",Vector3.new(-1808.1,48.8,-2740.0)},
    {275,299,"Gladiator",Vector3.new(-1309.9,7.5,-3251.6)},
    {300,324,"Military Soldier",Vector3.new(-5394.1,21.2,8483.3)},
    {325,374,"Military Spy",Vector3.new(-5802.0,97.0,8803.7)},
    {375,399,"Fishman Warrior",Vector3.new(61122.7,18.5,1569.1)},
    {400,449,"Fishman Commando",Vector3.new(61922.6,18.5,1493.9)},
    {450,474,"God's Guard",Vector3.new(-4721.9,845.3,-1954.4)},
    {475,524,"Shanda",Vector3.new(-7685.1,5567.8,-502.1)},
    {525,549,"Royal Squad",Vector3.new(-7659.8,5624.0,-1456.7)},
    {550,624,"Royal Soldier",Vector3.new(-7836.8,5607.8,-1540.5)},
    {625,649,"Galley Pirate",Vector3.new(5551.0,42.5,3946.3)},
    {650,699,"Galley Captain",Vector3.new(5436.0,38.5,4757.8)},

    -- SECOND SEA
    {700,724,"Raider",Vector3.new(-741.5,39.1,2391.3)},
    {725,774,"Mercenary",Vector3.new(-864.9,122.5,1453.2)},
    {775,799,"Swan Pirate",Vector3.new(1065.4,137.6,1324.4)},
    {800,874,"Factory Staff",Vector3.new(533.2,128.5,355.6)},
    {875,899,"Marine Lieutenant",Vector3.new(-2489.3,84.6,-3151.9)},
    {900,949,"Marine Captain",Vector3.new(-2335.2,79.8,-3245.9)},
    {950,974,"Zombie",Vector3.new(-5536.5,101.1,-835.6)},
    {975,999,"Vampire",Vector3.new(-6031.7,6.7,-1315.3)},
    {1000,1049,"Snow Trooper",Vector3.new(535.2,432.7,-5484.9)},
    {1050,1099,"Winter Warrior",Vector3.new(1234.5,457.0,-5174.1)},
    {1100,1124,"Lab Subordinate",Vector3.new(-5775.6,40.0,-4476.2)},
    {1125,1174,"Horned Warrior",Vector3.new(-6403.4,24.4,-5811.8)},
    {1175,1199,"Magma Ninja",Vector3.new(-5461.8,130.4,-5836.5)},
    {1200,1249,"Lava Pirate",Vector3.new(-5251.2,55.2,-4774.4)},
    {1250,1274,"Ship Deckhand",Vector3.new(921.1,126.0,33088.3)},
    {1275,1299,"Ship Engineer",Vector3.new(886.3,40.5,32800.8)},
    {1300,1324,"Ship Steward",Vector3.new(943.9,129.6,33444.4)},
    {1325,1349,"Ship Officer",Vector3.new(955.4,181.1,33331.9)},
    {1350,1374,"Arctic Warrior",Vector3.new(6016.5,43.2,-6207.2)},
    {1375,1424,"Snow Lurker",Vector3.new(5628.5,57.6,-6618.4)},
    {1425,1449,"Sea Soldier",Vector3.new(-3185.0,58.8,-9663.6)},
    {1450,1499,"Water Fighter",Vector3.new(-3262.9,298.7,-10552.5)},

    -- THIRD SEA
    {1500,1524,"Pirate Millionaire",Vector3.new(81.2,43.8,5724.7)},
    {1525,1574,"Pistol Billionaire",Vector3.new(81.2,43.8,5724.7)},
    {1575,1599,"Dragon Crew Warrior",Vector3.new(6242.0,51.5,-1244.0)},
    {1600,1624,"Dragon Crew Archer",Vector3.new(6488.9,383.4,-110.7)},
    {1625,1649,"Female Islander",Vector3.new(5825.2,682.9,704.6)},
    {1650,1699,"Giant Islander",Vector3.new(4530.4,656.8,-131.6)},
    {1700,1724,"Marine Commodore",Vector3.new(2490.1,190.4,-7160.1)},
    {1725,1774,"Marine Rear Admiral",Vector3.new(3951.4,229.1,-6912.8)},
    {1775,1799,"Fishman Raider",Vector3.new(-10322.4,390.9,-8580.1)},
    {1800,1824,"Fishman Captain",Vector3.new(-11194.5,442.0,-8608.8)},
    {1825,1849,"Forest Pirate",Vector3.new(-13225.8,428.2,-7753.1)},
    {1850,1899,"Mythological Pirate",Vector3.new(-13869.2,565.0,-7084.4)},
    {1900,1924,"Jungle Pirate",Vector3.new(-11982.2,376.3,-10451.4)},
    {1925,1974,"Musketeer Pirate",Vector3.new(-13282.3,496.2,-9565.2)},
    {1975,1999,"Reborn Skeleton",Vector3.new(-8817.9,191.2,6298.7)},
    {2000,2024,"Living Zombie",Vector3.new(-10125.2,184.0,6242.0)},
    {2025,2049,"Demonic Soul",Vector3.new(-9712.0,204.7,6193.3)},
    {2050,2074,"Posessed Mummy",Vector3.new(-9545.8,69.6,6339.6)},
    {2075,2099,"Peanut Scout",Vector3.new(-2126.4,90.6,-10302.0)},
    {2100,2124,"Peanut President",Vector3.new(-2118.8,70.3,-10509.3)},
    {2125,2149,"Ice Cream Chef",Vector3.new(-685.3,96.3,-10957.6)},
    {2150,2199,"Ice Cream Commander",Vector3.new(-635.7,143.0,-11335.2)},
    {2200,2224,"Cookie Crafter",Vector3.new(-2321.7,36.7,-12216.7)},
    {2225,2249,"Cake Guard",Vector3.new(-1418.1,36.7,-12255.7)},
    {2250,2274,"Baking Staff",Vector3.new(-1980.4,36.7,-12983.8)},
    {2275,2299,"Head Baker",Vector3.new(-2251.6,52.3,-13033.4)},
    {2300,2324,"Cocoa Warrior",Vector3.new(168.0,26.2,-12238.9)},
    {2325,2349,"Chocolate Bar Battler",Vector3.new(701.3,25.6,-12708.2)},
    {2350,2374,"Sweet Thief",Vector3.new(-140.3,25.6,-12652.3)},
    {2375,2399,"Candy Rebel",Vector3.new(47.9,25.6,-13029.2)},
    {2400,2424,"Candy Pirate",Vector3.new(-1437.6,17.1,-14385.7)},
    {2425,2449,"Snow Demon",Vector3.new(-916.2,17.1,-14638.8)},
    {2450,2474,"Isle Outlaw",Vector3.new(-16162.8,11.7,-96.5)},
    {2475,2499,"Island Boy",Vector3.new(-16357.3,20.6,1005.6)},
    {2500,2524,"Sun-kissed Warrior",Vector3.new(-16357.3,20.6,1005.6)},
    {2525,2549,"Isle Champion",Vector3.new(-16848.9,21.7,1041.4)},
    {2550,2574,"Serpent Hunter",Vector3.new(-16621.4,121.4,1290.7)},
    {2575,2600,"Skull Slayer",Vector3.new(-16811.6,84.6,1542.2)},
    -- Submerged Island, Update 27.1: the bottom of the sea under Tiki Outpost
    -- (Y about -2000), reached only by the submarine. Spots from public farm
    -- tables (two agree on each).
    {2600,2624,"Reef Bandit",Vector3.new(10943.1,-2083.0,9177.3)},
    {2625,2649,"Coral Pirate",Vector3.new(10713.4,-2093.0,9307.1)},
    {2650,2674,"Sea Chanter",Vector3.new(10647.6,-2077.6,10080.0)},
    {2675,2699,"Ocean Prophet",Vector3.new(11056.1,-2001.7,10117.4)},
    {2700,2724,"High Disciple",Vector3.new(9843.6,-1993.5,9696.5)},
    {2725,2800,"Grand Devotee",Vector3.new(9591.1,-1993.5,9808.7)},
}
P.levels = LEVELS

-- =========================================================
-- BOSSES AND SEAS
-- =========================================================
-- QUEST BOSSES. Ids, tiers and levels from the game's own quest module (dump
-- of 2025-05, tlredz/Scripts GameModules/Quests.lua). Three were renamed since
-- (the 2025-10 and 2026-09 public tables): Fajita -> Orbitus, Bobby -> Chef,
-- Island Empress -> Hydra Leader. Every name of one boss maps to its quest;
-- the Targets page shows the one the game has. Spawn = where the 2025-10
-- table sends you; only the LAST way of finding one (see WHERE A SPECIES IS).
-- The quest id and tier columns are the game's data, unused since the quest
-- engine was removed (2026-09-28).
local BOSS = {}          -- name -> { id, tier, lv, spot, names }
do
    local rows: { any } = {   -- plain data: typed so, the checker skips inferring each row
        { { "The Gorilla King" },               "JungleQuest",         3,   20, Vector3.new(-1128, 6, -451) },
        { { "Chef", "Chief", "Bobby" },         "BuggyQuest1",         3,   55, Vector3.new(-1131, 14, 4080) },
        { { "Yeti" },                           "SnowQuest",           3,  105, Vector3.new(1185, 106, -1518) },
        { { "Vice Admiral" },                   "MarineQuest2",        2,  130, Vector3.new(-4807, 21, 4360) },
        { { "Warden" },                         "ImpelQuest",          1,  220, Vector3.new(5230, 4, 749) },
        { { "Chief Warden" },                   "ImpelQuest",          2,  230, Vector3.new(5230, 4, 749) },
        { { "Swan" },                           "ImpelQuest",          3,  240, Vector3.new(5230, 4, 749) },
        { { "Magma Admiral" },                  "MagmaQuest",          3,  350, Vector3.new(-5694, 18, 8735) },
        { { "Fishman Lord" },                   "FishmanQuest",        3,  425, Vector3.new(61350, 31, 1095) },
        { { "Wysper" },                         "SkyExp1Quest",        3,  500, Vector3.new(-7927, 5551, -637) },
        { { "Thunder God" },                    "SkyExp2Quest",        3,  575, Vector3.new(-7751, 5607, -2315) },
        { { "Cyborg" },                         "FountainQuest",       3,  675, Vector3.new(6138, 10, 3939) },
        -- Second Sea
        { { "Diamond" },                        "Area1Quest",          3,  750, Vector3.new(-1569, 199, -31) },
        { { "Jeremy" },                         "Area2Quest",          3,  850, Vector3.new(2316, 449, 787) },
        { { "Orbitus", "Fajita" },              "MarineQuest3",        3,  925, Vector3.new(-2086, 73, -4208) },
        { { "Smoke Admiral" },                  "IceSideQuest",        3, 1150, Vector3.new(-5078, 24, -5352) },
        { { "Awakened Ice Admiral" },           "FrostQuest",          3, 1400, Vector3.new(6473, 297, -6944) },
        { { "Tide Keeper" },                    "ForgottenQuest",      3, 1475, Vector3.new(-3711, 77, -11469) },
        -- Third Sea
        { { "Stone" },                          "PiratePortQuest",     3, 1550, Vector3.new(-1049, 40, 6791) },
        { { "Hydra Leader", "Island Empress" }, "VenomCrewQuest",      3, 1675, Vector3.new(5836, 1019, -83) },
        { { "Kilo Admiral" },                   "MarineTreeIsland",    3, 1750, Vector3.new(2904, 509, -7349) },
        { { "Captain Elephant" },               "DeepForestIsland",    3, 1875, Vector3.new(-13393, 319, -8423) },
        { { "Beautiful Pirate" },               "DeepForestIsland2",   3, 1950, Vector3.new(5370, 22, -89) },
        { { "Cake Queen" },                     "IceCreamIslandQuest", 3, 2175, Vector3.new(-710, 382, -11150) },
    }
    P.bosses = {}
    for _, b in ipairs(rows) do
        local rec = { names = b[1], id = b[2], tier = b[3], lv = b[4], spot = b[5] }
        table.insert(P.bosses, rec)
        for _, n in ipairs(b[1]) do
            BOSS[n] = rec
        end
    end
end
P.BOSS = BOSS

-- Seas are separate servers. A species from another sea cannot be reached
-- from this one, so the circuit skips it and says so.
-- Each sea runs under an old and a newer place id (the newer ones from the
-- 2025-10 and 2026-08 public scripts); an unknown id = sea unknown.
local SEA_OF_PLACE = {
    [2753915549] = 1, [85211729168715] = 1,
    [4442272183] = 2, [79091703265657] = 2,
    [7449423635] = 3, [100117331123089] = 3,
}
local function mySea() return SEA_OF_PLACE[game.PlaceId] end
local function seaOfLevel(lv)
    if lv < 700 then return 1 elseif lv < 1500 then return 2 end
    return 3
end
local function rowOf(name)
    for _, row in ipairs(LEVELS) do
        if row[3] == name then return row end
    end
    return nil
end
P.rowOf = rowOf

-- The level a species belongs to: its level-table row, or its boss quest.
local function levelOf(name)
    local row = rowOf(name)
    if row then return row[1] end
    return BOSS[name] and BOSS[name].lv or nil
end

-- =========================================================
-- STATE
-- =========================================================
local stats = {
    kills = 0, piles = 0, m1 = 0, casts = 0,
    castsTook = 0, castsMissed = 0, castsHit = 0,
    swaps = 0, flights = 0, hops = 0, pulledBack = 0, putBack = 0,
    escapes = 0, probes = 0, hakiPresses = 0, startedAt = 0,
}

local state          = "IDLE"
local statusLine     = "idle"
local stateEnteredAt = 0
local conns          = {}
local moveEnabled    = true
-- The invisible floor kept at the deep sea's surface (Submerged Island).
local waterFloor     = nil
local activeName     = nil     -- the species being fought right now
local countedDead    = {}
local circuitIdx     = 1

-- THE ABORT EPOCH. Every long operation captures this on entry and gives up
-- the moment it changes. Stop bumps it, so stop means stop.
local epoch = 0
local function stale(e) return e ~= epoch end

local function track(c) table.insert(conns, c) return c end
local function log(m) if CFG.Debug then print("[BFF] " .. tostring(m)) end end
local function say(s) statusLine = tostring(s) end

local function setState(s)
    if state ~= s then
        state = s
        stateEnteredAt = os.clock()
        log("state -> " .. s)
    end
end

-- =========================================================
-- CHARACTER
-- =========================================================
local function parts()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return char, nil, nil end
    return char, root, hum
end

local function healthPct()
    local _, _, hum = parts()
    if not hum or hum.MaxHealth <= 0 then return 1 end
    return hum.Health / hum.MaxHealth
end

local function playerLevel()
    local ls = player:FindFirstChild("leaderstats")
    local lv = ls and ls:FindFirstChild("Level")
    if lv and tonumber(lv.Value) then return tonumber(lv.Value) end
    local d = player:FindFirstChild("Data")
    local l2 = d and d:FindFirstChild("Level")
    return l2 and tonumber(l2.Value) or nil
end

local function levelRow()
    local lv = playerLevel()
    if not lv then return nil end
    for _, row in ipairs(LEVELS) do
        if lv >= row[1] and lv <= row[2] then return row end
    end
    return LEVELS[#LEVELS]
end
P.levelRow = levelRow

local function heldTool()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Tool")
end
P.heldTool = function()
    local t = heldTool()
    return t and t.Name or nil
end

-- A PHYSICAL FRUIT (one to eat or store, "Kitsune Fruit" with an EatRemote -
-- not your eaten fruit's power, "Kitsune-Kitsune") is never a weapon: it is
-- never listed, never equipped, and nothing is clicked while one is in your
-- hand. A click with it held EATS it and replaces your fruit (user, main
-- account, 2026-09-28). Roblox puts a tool you touch straight into your hand.
function P.isPhysicalFruit(t)
    if not (t and t:IsA("Tool")) then return false end
    if string.find(t.Name, " Fruit$") then return true end
    local ok, er = pcall(function() return t:FindFirstChild("EatRemote", true) end)
    return ok and er ~= nil
end

local function findTool(name)
    local bp   = player:FindFirstChild("Backpack")
    local char = player.Character
    local t = (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
    if t and t:IsA("Tool") and not P.isPhysicalFruit(t) then return t end
    return nil
end

local function toolNames()
    local out, seen = {}, {}
    -- Not ipairs: it stops at the first nil (no Backpack for a moment).
    local srcs = { player:FindFirstChild("Backpack"), player.Character }
    for i = 1, 2 do
        local src = srcs[i]
        if src then
            for _, t in ipairs(src:GetChildren()) do
                if t:IsA("Tool") and not seen[t.Name] and not P.isPhysicalFruit(t) then
                    seen[t.Name] = true
                    table.insert(out, t)
                end
            end
        end
    end
    return out
end

-- "Blox Fruit", "Melee", "Sword", "Gun" -- the game's own label on the tool.
local function toolType(tool)
    if not tool then return "?" end
    local tip = tool.ToolTip
    if type(tip) == "string" and #tip > 0 then return tip end
    local wt = tool:GetAttribute("WeaponType")
    return wt and tostring(wt) or "?"
end
P.toolType = toolType

-- =========================================================
-- INPUT
-- =========================================================
local function pressKey(code)
    pcall(function()
        VIM:SendKeyEvent(true, code, false, game)
        task.wait(0.04)
        VIM:SendKeyEvent(false, code, false, game)
    end)
end

-- Some skills fire on release after a hold; the hold is yours, per key.
-- `before`, if given, runs right before each of the two key events (the
-- hidden aim puts the camera on the pile for exactly that instant).
local function holdKey(code, secs, before)
    if before then before() end
    pcall(function() VIM:SendKeyEvent(true, code, false, game) end)
    task.wait(math.max(secs or 0.05, 0.03))
    if before then before() end
    pcall(function() VIM:SendKeyEvent(false, code, false, game) end)
end

local function pressM1()
    -- A fruit in hand: the click would EAT it. Put it away instead.
    local held = heldTool()
    if held and P.isPhysicalFruit(held) then
        local _, _, h = parts()
        if h then pcall(function() h:UnequipTools() end) end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vs = cam.ViewportSize
    local x, y = vs.X * 0.5, vs.Y * 0.5
    pcall(function() VIM:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
    task.wait(0.04)
    pcall(function() VIM:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(x, y), cam.CFrame)
        VirtualUser:Button1Up(Vector2.new(x, y), cam.CFrame)
    end)
end

-- =========================================================
-- REMOTES
-- =========================================================
-- Looked up when first needed, never at load: a lookup made before the game
-- has finished building is nil for the whole session (farm_pro learned that
-- one the hard way with the spawn folders).
local function commF()
    local r = RS:FindFirstChild("Remotes")
    return r and r:FindFirstChild("CommF_")
end

-- ReplicatedStorage.Modules.Net holds the combat remotes as "RE/<name>" and
-- "RF/<name>". The public hubs also reach them through the Net module itself
-- (require(Net):RemoteEvent(name, true)), which creates one if it is missing.
-- Direct child first, the module second.
local netCache = {}
local function netRemote(kind, name)
    local key = kind .. "/" .. name
    local hit = netCache[key]
    if hit and hit.Parent then return hit end
    local mods = RS:FindFirstChild("Modules")
    local net  = mods and mods:FindFirstChild("Net")
    if not net then return nil end
    local r = net:FindFirstChild(key)
    if not r then
        local okM, mod = pcall(require, net)
        if okM and type(mod) == "table" then
            local fn = (kind == "RE") and mod.RemoteEvent or mod.RemoteFunction
            if type(fn) == "function" then
                local okR, rr = pcall(fn, mod, name, true)
                if okR and typeof(rr) == "Instance" then r = rr end
            end
        end
    end
    netCache[key] = r
    return r
end
P.netRemote = netRemote

-- =========================================================
-- BODY: NOCLIP AND THE LOCK
-- =========================================================
-- Two per-frame jobs while the farm runs, and they are what make everything
-- else possible:
--   before physics : every part of the character stops colliding
--   after physics  : the body is written to the lock and its velocity zeroed
-- The Humanoid puts collisions back on some of its own parts every step and
-- gravity pulls every frame, so a single write is always undone; these run
-- every frame. With collisions off and nothing holding it, a body falls
-- through the map -- so the body is ALWAYS held: at the lock, or, if there is
-- no lock yet, wherever it is.
local lockCF      = nil
local flying      = false
local lastWritten = nil      -- where this script last put the body
local savedCollide = {}
local bodyChar, bodyList, bodyListAt = nil, {}, 0

local function charParts(char)
    local out = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(out, d) end
    end
    return out
end

local function bodyStepped()
    if not P.running or P.handsOff then return end
    local char = player.Character
    if not char then return end
    if char ~= bodyChar or os.clock() - bodyListAt > 0.5 then
        bodyChar, bodyList, bodyListAt = char, charParts(char), os.clock()
    end
    for _, p in ipairs(bodyList) do
        if p.Parent then
            if savedCollide[p] == nil then savedCollide[p] = p.CanCollide end
            p.CanCollide = false
        end
    end
end

local function bodyHeartbeat()
    if not P.running or P.handsOff then return end
    local _, r, h = parts()
    if not r or not h then return end
    h.AutoRotate = false
    if not flying then
        -- SOMETHING ELSE MOVED THE BODY. A respawn, the submarine, the game's
        -- own teleport: the body is far from where this script last put it.
        -- Stay where the game put us instead of dragging the body back.
        -- P.keepLock (SEA EVENTS): a move under 500 studs is a knockback or a
        -- pull (a Terrorshark's) - not adopted, the body goes back; a respawn
        -- or a teleport is still followed.
        local moved = lastWritten and (r.Position - lastWritten).Magnitude or 0
        if moved > 50 and not (P.keepLock and moved < 500) then
            local rot = lockCF and (lockCF - lockCF.Position) or (r.CFrame - r.CFrame.Position)
            lockCF = CFrame.new(r.Position) * rot
        end
        if not lockCF then lockCF = r.CFrame end
        local fy = P.floorY
        if fy and lockCF.Position.Y < fy then lockCF = lockCF + Vector3.new(0, fy - lockCF.Position.Y, 0) end
        r.CFrame = lockCF
        lastWritten = lockCF.Position
    end
    r.AssemblyLinearVelocity  = Vector3.zero
    r.AssemblyAngularVelocity = Vector3.zero
end

local function restoreBody()
    for part, was in pairs(savedCollide) do
        if part.Parent then pcall(function() part.CanCollide = was end) end
    end
    table.clear(savedCollide)
    local _, _, h = parts()
    if h then pcall(function() h.AutoRotate = true end) end
end

-- Hold at pos, turned (yaw only) to face lookAt if given.
local function lockAt(pos, lookAt)
    -- THE WATER AS ROCK (SEA EVENTS, user 2026-10-09): never under it.
    local fy = P.floorY
    if fy and pos.Y < fy then pos = Vector3.new(pos.X, fy, pos.Z) end
    if lookAt then
        local flat = Vector3.new(lookAt.X, pos.Y, lookAt.Z)
        if (flat - pos).Magnitude > 0.5 then
            lockCF = CFrame.lookAt(pos, flat)
            return
        end
    end
    local rot = lockCF and (lockCF - lockCF.Position) or CFrame.identity
    lockCF = CFrame.new(pos) * rot
end

-- =========================================================
-- THE CAMERA, BORROWED FOR A CAST AND GIVEN BACK
-- =========================================================
local aimPixel = nil         -- a synthetic click's own point; nil = where the mouse is
local aimUntil = 0           -- the hidden aim is put in every frame until this time
local releaseCamera, aimCamera, aimSwapIn, hiddenAim
do
    local InputService = game:GetService("UserInputService")
    local camHeld  = false
    local camBack  = nil         -- which side of the pile the camera stands, fixed while borrowed
    function releaseCamera()
        camBack = nil
        if not camHeld then return end
        camHeld = false
        local cam = workspace.CurrentCamera
        if not cam then return end
        pcall(function()
            local _, _, hum = parts()
            if hum then cam.CameraSubject = hum end
            cam.CameraType = Enum.CameraType.Custom
        end)
    end
    P.releaseCamera = releaseCamera

    -- A skill fires down the line from the camera through the cursor. Instead of
    -- moving the cursor, the camera is turned so that line goes through the pile:
    -- the cursor can be anywhere, the pile is under it. Yaw and pitch only (no
    -- roll), solved exactly:
    --   d = the cursor's direction in the camera's own frame (it depends only on
    --       the cursor's pixel and the field of view, not on where the camera is)
    --   t = the direction from the camera to the pile
    --   find pitch th, yaw psi with  Ry(psi) * Rx(th) * d = t
    --   height first (yaw leaves it alone): d.Y cos th - d.Z sin th = t.Y
    --   then yaw turns the flat part of Rx(th)*d onto the flat part of t.
    local function rayAim(at, target, dl)
        local t = target - at
        if t.Magnitude < 0.01 or dl.Magnitude < 0.01 then return CFrame.new(at) end
        t, dl = t.Unit, dl.Unit
        local amp = math.sqrt(dl.Y * dl.Y + dl.Z * dl.Z)
        if amp < 1e-4 then return CFrame.lookAt(at, target) end
        local phi = math.atan2(dl.Z, dl.Y)
        local ac = math.acos(math.clamp(t.Y / amp, -1, 1))
        local function wrap(x) return (x + math.pi) % (2 * math.pi) - math.pi end
        local th1, th2 = wrap(ac - phi), wrap(-ac - phi)
        local th = (math.abs(th1) <= math.abs(th2)) and th1 or th2
        local z1 = dl.Y * math.sin(th) + dl.Z * math.cos(th)
        local psi = math.atan2(t.X, t.Z) - math.atan2(dl.X, z1)
        return CFrame.new(at) * CFrame.Angles(0, psi, 0) * CFrame.Angles(th, 0, 0)
    end

    -- Where the camera stands. Looking down at an angle e, the pile can only
    -- be put under the cursor without rolling the view if
    --   sin(e) <= sqrt(d.Y^2 + d.Z^2)
    -- -- a cursor near a side edge cannot be pointed steeply down. So the
    -- camera stands CamDistance from the pile, on `away`'s side, as high as
    -- CamPitch, and lower when the cursor is near a side edge: the solve is
    -- then always exact, wherever the cursor is.
    local function aimFrame(target, away, dl)
        local d = dl.Unit
        local amp = math.sqrt(d.Y * d.Y + d.Z * d.Z)
        local e = math.min(math.rad(CFG.CamPitch or 55), math.asin(math.min(amp, 1)) * 0.95)
        -- P.camDistance: a fight's own (SEA EVENTS: a beast is bigger than 30
        -- studs - a camera inside it casts its ray from inside, and misses it).
        local at = target + (away * math.cos(e) + Vector3.new(0, math.sin(e), 0)) * (P.camDistance or CFG.CamDistance or 30)
        return rayAim(at, target, d)
    end

    -- Turn the camera so the line through the cursor (or through aimPixel, for
    -- a synthetic click) lands on targetPos. Called every frame while the pile
    -- is being hit, and right before each cast. centre = the pile's middle.
    function aimCamera(targetPos, centre)
        local cam = workspace.CurrentCamera
        local _, r = parts()
        if not cam or not r then return end
        -- The camera stands on your side of the pile's MIDDLE (not of the body
        -- aimed at: that one sits on the ring, and when it dies the next one
        -- is on another side -- the view would jump). Straight above the
        -- middle: on the side it stood when it was borrowed -- never worked
        -- out from its CURRENT facing, which this turns every frame.
        local c = centre or targetPos
        local away = Vector3.new(r.Position.X - c.X, 0, r.Position.Z - c.Z)
        if away.Magnitude < 1 then
            if not camBack then
                local lv = cam.CFrame.LookVector
                local f = Vector3.new(-lv.X, 0, -lv.Z)
                camBack = (f.Magnitude > 0.1) and f.Unit or Vector3.new(0, 0, 1)
            end
            away = camBack
        end
        pcall(function()
            local px = aimPixel or InputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(px.X, px.Y)
            local dl = cam.CFrame:VectorToObjectSpace(ray.Direction)
            cam.CameraType = Enum.CameraType.Scriptable
            camHeld = true
            cam.CFrame = aimFrame(targetPos, away.Unit, dl)
        end)
    end

    -- THE HIDDEN AIM: your camera stays yours. One frame goes
    --   input (keys are read) -> camera update (render step "Camera") ->
    --   drawn -> physics -> Heartbeat -> the next frame's input
    -- Whatever the camera is between Heartbeat and the next camera update is
    -- never drawn -- yet a key sent then is read inside that window. So: just
    -- after the camera updates, your view is saved; at Heartbeat the aim goes
    -- in; just before the next camera update your view goes back. The camera
    -- script and your screen only ever see your own view; the key sees the aim.
    local savedCF, swapped = nil, false
    function aimSwapIn(targetPos, centre)
        local cam = workspace.CurrentCamera
        if not cam or not savedCF then return end
        local c = centre or targetPos
        local away = Vector3.new(savedCF.Position.X - c.X, 0, savedCF.Position.Z - c.Z)
        if away.Magnitude < 1 then away = Vector3.new(0, 0, 1) end
        pcall(function()
            local px = aimPixel or InputService:GetMouseLocation()
            local ray = cam:ViewportPointToRay(px.X, px.Y)
            local dl = cam.CFrame:VectorToObjectSpace(ray.Direction)
            cam.CFrame = aimFrame(targetPos, away.Unit, dl)
            swapped = true
        end)
    end

    -- Bound while the farm runs (on) and removed at stop (off).
    function hiddenAim(on)
        pcall(function() RunService:UnbindFromRenderStep("BFFAimOut") end)
        pcall(function() RunService:UnbindFromRenderStep("BFFAimSave") end)
        local cam = workspace.CurrentCamera
        if swapped and cam and savedCF then pcall(function() cam.CFrame = savedCF end) end
        swapped, savedCF = false, nil
        if not on then return end
        pcall(function()
            RunService:BindToRenderStep("BFFAimOut", Enum.RenderPriority.Camera.Value - 1, function()
                if not swapped then return end
                swapped = false
                local c = workspace.CurrentCamera
                if c and savedCF then c.CFrame = savedCF end
            end)
            RunService:BindToRenderStep("BFFAimSave", Enum.RenderPriority.Camera.Value + 1, function()
                local c = workspace.CurrentCamera
                if c and not swapped then savedCF = c.CFrame end
            end)
        end)
    end
end

-- =========================================================
-- TRAVEL
-- =========================================================
-- Short: one write. Long: a straight line at TravelSpeed, written every
-- frame, collisions off, so there is nothing in the way to go round. "Pulled
-- back" counts frames where the body was not where it was written -- that is
-- the server correcting you, and the sign the speed is too high.
local SUB_Y    = -1000                                -- below this = Submerged Island
local TIKI_SUB = Vector3.new(-16269, 23, 1371)        -- the Submarine Worker
P.lastFlight = "none yet"

local function flatFace(pos, dir)
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude < 0.1 then
        local rot = lockCF and (lockCF - lockCF.Position) or CFrame.identity
        return CFrame.new(pos) * rot
    end
    return CFrame.lookAt(pos, pos + flat)
end

local flyTo       -- declared here: the submarine leg calls it recursively

-- Submerged Island is not on the sea, it is at the bottom of it, and the only
-- way in is the submarine at Tiki Outpost.
local function toSubmerged(myEpoch)
    say("to the submarine")
    flyTo(TIKI_SUB + Vector3.new(0, 3, 0))
    if stale(myEpoch) then return false end
    local rf = netRemote("RF", "SubmarineWorkerSpeak")
    if not rf then say("no submarine remote here") return false end
    say("taking the submarine down")
    pcall(function() rf:InvokeServer("TravelToSubmergedIsland") end)
    local t0 = os.clock()
    while os.clock() - t0 < 15 and not stale(myEpoch) do
        local _, r = parts()
        if r and r.Position.Y < SUB_Y then return true end
        task.wait(0.2)
    end
    return false
end

flyTo = function(goal, opts)
    opts = opts or {}
    local _, r = parts()
    if not r then return false end
    local myEpoch = epoch
    local arrive = opts.arrive or 3

    if goal.Y < SUB_Y and r.Position.Y > SUB_Y then
        if not toSubmerged(myEpoch) then return false end
        local _, r2 = parts()
        if not r2 then return false end
        r = r2
    end

    local dist = (goal - r.Position).Magnitude
    if dist <= arrive then
        lockAt(goal, opts.face)
        return true
    end
    if dist <= (CFG.InstantHop or 150) then
        stats.hops += 1
        local cf = flatFace(goal, goal - r.Position)
        r.CFrame = cf
        lastWritten = goal
        lockAt(goal, opts.face)
        return true
    end

    stats.flights += 1
    releaseCamera()          -- the view follows you on a flight
    flying = true
    local t0      = os.clock()
    local speed   = math.max(CFG.TravelSpeed or 330, 50)
    local budget  = dist / speed * 2 + 8
    local pulled  = 0
    local wrote   = r.Position
    local arrived = false
    while moveEnabled and not stale(myEpoch) do
        local dt = RunService.Heartbeat:Wait()
        local _, r2 = parts()
        if not r2 then break end
        local here = r2.Position
        if (here - wrote).Magnitude > 25 then pulled += 1 end
        local d = goal - here
        local m = d.Magnitude
        if m <= arrive then arrived = true break end
        if os.clock() - t0 > budget then break end
        speed = math.max(CFG.TravelSpeed or 330, 50)
        local nextPos = here + d.Unit * math.min(m, speed * math.min(dt, 0.1))
        r2.CFrame = flatFace(nextPos, d)
        r2.AssemblyLinearVelocity = Vector3.zero
        wrote = nextPos
        lastWritten = nextPos
    end
    flying = false
    local _, rf = parts()
    local final = rf and rf.Position or goal
    lastWritten = final
    lockAt(arrived and goal or final, opts.face)
    stats.pulledBack += pulled
    P.lastFlight = string.format("%.0f studs in %.1fs%s%s", dist, os.clock() - t0,
        arrived and "" or "  (did not arrive)",
        pulled > 0 and string.format("  pulled back %dx - lower the speed", pulled) or "")

    -- Arrived before the island has: hold still until the enemies stream in.
    if arrived and opts.stream then
        local t1 = os.clock()
        while os.clock() - t1 < 3 and not stale(myEpoch) do
            local f = workspace:FindFirstChild("Enemies")
            local seen = false
            if f then
                for _, m in ipairs(f:GetChildren()) do
                    if string.find(m.Name, opts.stream, 1, true) then seen = true break end
                end
            end
            if seen then break end
            task.wait(0.1)
        end
    end
    return arrived
end
P.flyTo = function(pos) return flyTo(pos) end

-- =========================================================
-- TARGETING
-- =========================================================
local nameCache = setmetatable({}, { __mode = "k" })
local function cleanName(model)
    local hit = nameCache[model]
    if hit then return hit end
    local n = (model.Name:gsub("%s*%b[]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
    nameCache[model] = n
    return n
end

-- names: a set { [name] = true }, or nil for every enemy.
local function liveEnemies(names)
    local folder = workspace:FindFirstChild("Enemies")
    if not folder then return {} end
    local out = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local hum  = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local n = cleanName(m)
                if (not names) or names[n] then
                    table.insert(out, { model = m, hum = hum, root = root, name = n })
                end
            end
        end
    end
    return out
end
P.liveEnemies = liveEnemies

function P.nearbyNames()
    local counts = {}
    for _, e in ipairs(liveEnemies(nil)) do
        counts[e.name] = (counts[e.name] or 0) + 1
    end
    return counts
end

-- =========================================================
-- WHERE A SPECIES IS
-- =========================================================
-- The level table's points are hints, and many were wrong -- Sky Bandit's was
-- its quest giver's island, 420 studs above the camp, which is why the farm
-- hung in the open sky with nothing to pull. farm_pro never trusted them: it
-- fights whatever of the species is loaded, wherever it stands, and only walks
-- toward the point when none are. Same here, and the game is asked before the
-- table, three ways:
--   1. workspace.Enemies                  the ones loaded near you, alive
--   2. workspace._WorldOrigin.EnemySpawns a part at every spawn point, named
--                                         after its enemy -- any distance
--   3. ReplicatedStorage                  where the game parks enemies too far
--                                         away to load, positions intact
local function speciesKey(n)
    n = string.gsub(n, "%s*%b[]", "")
    return string.lower((string.gsub(n, "[^%a]", "")))
end

-- The nearest loaded, living one of this species, anywhere.
local function nearestLoaded(name)
    local _, r = parts()
    if not r then return nil end
    local best, bd = nil, math.huge
    for _, e in ipairs(liveEnemies({ [name] = true })) do
        local d = (e.root.Position - r.Position).Magnitude
        if d < bd then best, bd = e, d end
    end
    return best, bd
end

-- Every point the game says this species spawns at or is parked at.
local function gamePoints(name)
    local key = speciesKey(name)
    local pts, src = {}, nil
    local wo = workspace:FindFirstChild("_WorldOrigin")
    local sp = wo and wo:FindFirstChild("EnemySpawns")
    if sp then
        for _, p in ipairs(sp:GetChildren()) do
            if p:IsA("BasePart") and speciesKey(p.Name) == key then
                table.insert(pts, p.Position)
            end
        end
        if #pts > 0 then src = "spawn points" end
    end
    if #pts == 0 then
        for _, m in ipairs(RS:GetChildren()) do
            if m:IsA("Model") and speciesKey(m.Name) == key then
                local hrp = m:FindFirstChild("HumanoidRootPart")
                if hrp then table.insert(pts, hrp.Position) end
            end
        end
        if #pts > 0 then src = "parked enemies" end
    end
    return pts, src
end

-- The centre of the biggest group of those points (a species can have more
-- than one camp); ties go to the one nearest you. Cached: spawn points do
-- not move.
-- IS A BOSS UP? Loaded near you: here. Alive but far from every player: the
-- game parks it in ReplicatedStorage (the public hubs look there for exactly
-- this). In neither: not spawned. The parked list is read once a second.
-- bossUp: the same, except a parked entry that did not turn up when you were
-- standing on it is not believed for a minute (P.bossStale).
local bossWhere, bossUp
P.bossStale, P.bossMiss = {}, {}
do
    local parkedAt, parked = 0, {}
    function bossWhere(name)
        local e = nearestLoaded(name)
        if e then return e.root.Position, "here" end
        if os.clock() - parkedAt > 1 then
            parkedAt, parked = os.clock(), {}
            for _, m in ipairs(RS:GetChildren()) do
                if m:IsA("Model") then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    local hrp = m:FindFirstChild("HumanoidRootPart")
                    if hrp and (not hum or hum.Health > 0) then parked[speciesKey(m.Name)] = hrp.Position end
                end
            end
        end
        local p = parked[speciesKey(name)]
        if p then return p, "parked" end
        return nil, nil
    end
    function bossUp(name)
        local at, where = bossWhere(name)
        if where == "parked" and os.clock() < (P.bossStale[name] or 0) then return nil, nil end
        return at, where
    end
end
P.bossWhere = bossWhere

local campCache = {}
P.campNotes = {}
local function campOf(name, fallback)
    local c = campCache[name]
    if c and os.clock() - c.at < 30 then return c.pos, c.src end
    local pts, src = gamePoints(name)
    local pos
    if #pts > 0 then
        local _, r = parts()
        local here = r and r.Position
        local best, bestN, bestD = nil, -1, math.huge
        for _, a in ipairs(pts) do
            local n = 0
            for _, b in ipairs(pts) do
                if (a - b).Magnitude <= 250 then n += 1 end
            end
            local d = here and (a - here).Magnitude or 0
            if n > bestN or (n == bestN and d < bestD) then best, bestN, bestD = a, n, d end
        end
        local sum, n = Vector3.zero, 0
        for _, b in ipairs(pts) do
            if (b - best).Magnitude <= 250 then sum += b n += 1 end
        end
        pos = sum / n
        P.campNotes[name] = string.format("%s: %d %s (the game's own)", name, #pts, src)
    elseif fallback then
        pos, src = fallback, "table"
        P.campNotes[name] = name .. ": from the table (the game gave no spawn points)"
    else
        P.campNotes[name] = name .. ": nowhere known"
    end
    campCache[name] = { pos = pos, src = src, at = os.clock() }
    return pos, src
end
P.campOf = campOf

-- =========================================================
-- MAGNET
-- =========================================================
-- A client can only move an NPC whose physics it owns. SimulationRadius
-- raised to the maximum makes the server hand ownership of the NPCs round you
-- to you. Then every frame each pile member is written to its slot on a ring
-- round the pile centre, its velocity zeroed, and any force the game put on it
-- (knockback) removed -- so a hit that should throw it moves it nowhere.
--
-- The centre is the middle of where they SPAWNED. farm_pro measured that an
-- NPC dragged out of its own area arrives and takes no damage; the middle of
-- the camp's spawns is inside every one's area.
local homePos    = setmetatable({}, { __mode = "k" })   -- first place each was seen
local putBack    = setmetatable({}, { __mode = "k" })   -- model -> left alone until
local lastDest   = setmetatable({}, { __mode = "k" })
local pileJoin   = setmetatable({}, { __mode = "k" })   -- model -> { at, hp, act }
local pile       = {}
local pileCentre = nil
local pileSide   = nil       -- which side of the pile "close" stands on
local pileActive = false
local attacking  = false     -- hits are being thrown at the pile right now
local probing    = false     -- an M1 way is being tried; no put-backs meanwhile
local actions    = 0         -- every M1 and every cast, for the put-back clock
local simAt      = 0
P.pileHeld, P.pileOwned = 0, 0
-- model -> when the magnet's last write on it was still where it was put (it
-- is ours, held) - the volcano event reads which golems are really held.
P.heldAt = setmetatable({}, { __mode = "k" })
P.simNote = sethiddenproperty and "SimulationRadius: settable" or "SimulationRadius: this executor cannot set it"

local homeOf, campFor, middleOf, pullLimit
P.leash = {}             -- species -> { ok = farthest pull that still took damage, bad = nearest that did not }
do
    -- Every spawn spot seen, per species (8 studs apart): the camp's middle can
    -- be found even when the game gives no spawn points, and it does not move
    -- when one of them dies.
    local seenHomes = {}
    local function noteHome(name, h)
        local l = seenHomes[name]
        if not l then l = {} seenHomes[name] = l end
        for _, p in ipairs(l) do
            if (p - h).Magnitude < 8 then return end
        end
        if #l < 80 then table.insert(l, h) end
    end

    function homeOf(e)
        local h = homePos[e.model]
        if not h then
            h = e.root.Position
            homePos[e.model] = h
            if e.name then noteHome(e.name, h) end
        end
        return h
    end

    -- THE CAMP'S MIDDLE. Spawn points linked when under CAMP_LINK apart are one
    -- camp. Its middle is the centre of the smallest circle round them (flat),
    -- at half their height span: the spot where the farthest pull is shortest --
    -- the best chance that every one of them is still inside its own area.
    local CAMP_LINK = 400

    local function circle2(a, b)
        local cx, cz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
        return cx, cz, math.sqrt((a[1] - cx) ^ 2 + (a[2] - cz) ^ 2)
    end

    local function circle3(a, b, c)
        local bx, bz = b[1] - a[1], b[2] - a[2]
        local cx, cz = c[1] - a[1], c[2] - a[2]
        local d = 2 * (bx * cz - bz * cx)
        if math.abs(d) < 1e-9 then
            -- In a line: the widest pair holds the third.
            local best = { circle2(a, b) }
            for _, pr in ipairs({ { a, c }, { b, c } }) do
                local x, z, r = circle2(pr[1], pr[2])
                if r > best[3] then best = { x, z, r } end
            end
            return best[1], best[2], best[3]
        end
        local b2, c2 = bx * bx + bz * bz, cx * cx + cz * cz
        local ux = (cz * b2 - bz * c2) / d
        local uz = (bx * c2 - cx * b2) / d
        return a[1] + ux, a[2] + uz, math.sqrt(ux * ux + uz * uz)
    end

    -- Smallest circle round flat points { {x, z}, ... } (Welzl, incremental).
    local function enclosingCircle(pts)
        local cx, cz, r = pts[1][1], pts[1][2], 0
        local function inside(p)
            return (p[1] - cx) ^ 2 + (p[2] - cz) ^ 2 <= r * r + 1e-3
        end
        for i = 2, #pts do
            if not inside(pts[i]) then
                cx, cz, r = pts[i][1], pts[i][2], 0
                for j = 1, i - 1 do
                    if not inside(pts[j]) then
                        cx, cz, r = circle2(pts[i], pts[j])
                        for k = 1, j - 1 do
                            if not inside(pts[k]) then
                                cx, cz, r = circle3(pts[i], pts[j], pts[k])
                            end
                        end
                    end
                end
            end
        end
        return cx, cz, r
    end

    -- The middle of any set of points (the smallest circle round them, flat,
    -- at half their height span), and the farthest pull from it.
    function middleOf(pts)
        local flat, lo, hi = {}, math.huge, -math.huge
        for _, p in ipairs(pts) do
            table.insert(flat, { p.X, p.Z })
            lo, hi = math.min(lo, p.Y), math.max(hi, p.Y)
        end
        local cx, cz, rad = enclosingCircle(flat)
        local half = (hi - lo) / 2
        return Vector3.new(cx, lo + half, cz), math.sqrt(rad * rad + half * half)
    end

    local function campsFrom(pts)
        local n, taken, camps = #pts, {}, {}
        for i = 1, n do
            if not taken[i] then
                taken[i] = true
                local members, queue = {}, { i }
                while #queue > 0 do
                    local a = table.remove(queue)
                    table.insert(members, pts[a])
                    for b = 1, n do
                        if not taken[b] and (pts[a] - pts[b]).Magnitude <= CAMP_LINK then
                            taken[b] = true
                            table.insert(queue, b)
                        end
                    end
                end
                local centre, reach = middleOf(members)
                table.insert(camps, { pts = members, centre = centre, reach = reach })
            end
        end
        return camps
    end

    local ptsCache, campsCache = {}, {}
    local function gamePointsCached(name)
        local c = ptsCache[name]
        if c and os.clock() - c.at < 30 then return c.pts end
        local pts = gamePoints(name)
        ptsCache[name] = { pts = pts, at = os.clock() }
        return pts
    end

    local function campsCached(key, pts)
        local c = campsCache[key]
        if c and c.n == #pts and os.clock() - c.at < 30 then return c.camps end
        local camps = campsFrom(pts)
        campsCache[key] = { n = #pts, at = os.clock(), camps = camps }
        return camps
    end

    local function nearestCamp(camps, near)
        local best, bd = nil, math.huge
        for _, c in ipairs(camps) do
            for _, p in ipairs(c.pts) do
                local d = (p - near).Magnitude
                if d < bd then best, bd = c, d end
            end
        end
        return best, bd
    end

    -- The camp that `near` (a spawn spot) belongs to: the game's spawn points
    -- first, the spots seen here if the game's are not near it.
    function campFor(name, near)
        local g = gamePointsCached(name)
        if #g > 0 then
            local c, d = nearestCamp(campsCached(name .. "|game", g), near)
            if c and d <= CAMP_LINK then return c end
        end
        local seen = seenHomes[name]
        if seen and #seen > 0 then
            return (nearestCamp(campsCached(name .. "|seen", seen), near))
        end
        return nil
    end
    P.pileReach = nil

    -- How far one of this kind can be pulled from its spawn: your "Pull at
    -- most", or less when this farm saw one stop taking damage nearer than
    -- that (checkPutBack writes P.leash).
    function pullLimit(name)
        local lim = CFG.MaxPull or 300
        local l = P.leash[name]
        if CFG.LearnLeash and l and l.bad then lim = math.min(lim, l.bad - 15) end
        return math.max(lim, 30)
    end
end

local function isPutBack(model)
    local u = putBack[model]
    if not u then return false end
    if os.clock() > u then putBack[model] = nil return false end
    return true
end

local pileFor                -- declared here, set by buildPile's caller
local pileCur, pileNames     -- what the pile is being kept for (set by the fight)
local pileWatch  = {}        -- model -> Humanoid of every one that was in the pile
local pileScanAt = 0

-- THE PILE HOLDS. While one pulled into the pile being hit is alive, the pile
-- stays where it is and keeps every living member; new ones are only added to
-- it. The centre used to be worked out again ten times a second from whichever
-- member stood nearest it -- on the ring that is any of them -- so in a camp
-- piled one side at a time it jumped, and every living member whose spawn was
-- now past the limit was let go mid-fight: the scatter (user, 2026-09-30). A
-- new centre is chosen only once the pile is empty.
-- Splits `list` into the ones already in the `name` pile (in the pile's own
-- order) and the rest. held = nil: no pile to hold, choose afresh.
local function splitHeld(list, name)
    if not (CFG.Magnet and name and pileCentre and pileFor == name and #pile > 0) then
        return nil, list
    end
    local byModel = {}
    for _, e in ipairs(list) do byModel[e.model] = e end
    local held, taken = {}, {}
    for _, o in ipairs(pile) do
        local e = byModel[o.model]
        if e and not taken[e.model] then
            taken[e.model] = true
            table.insert(held, e)
        end
    end
    if #held == 0 then return nil, list end
    local fresh = {}
    for _, e in ipairs(list) do
        if not taken[e.model] then table.insert(fresh, e) end
    end
    return held, fresh
end
local function releasePile()
    releaseCamera()          -- the view must not stay on a pile being left
    pileActive, attacking = false, false
    pile, pileCentre, pileSide, pileFor = {}, nil, nil, nil
    pileCur, pileNames = nil, nil
    P.pileReach, P.pileInPlace, P.inPlaceTarget, P.forceClose = nil, false, nil, false
    P.pileHeld, P.pileOwned = 0, 0
end

-- Who goes in the pile, and where its centre is.
-- farm_pro's rule: every LOADED one of the species counts, wherever it stands.
-- PullAll (default): every one of them goes in, however far, and the pile
-- sits at the middle of the camp (campFor). Off: only the ones that spawned
-- within GrabRadius of the anchor, piled at the middle of their spawns.
-- The anchor -- the one nearest the pile already standing, else nearest you --
-- says which camp. The table point plays no part here.
-- cur = { name, spot }; names = every species on the circuit.
local function buildPile(cur, names)
    local _, r = parts()
    if not r then return {}, nil end
    local from = r.Position
    local quest, others = {}, {}
    for _, e in ipairs(liveEnemies(names)) do
        if not isPutBack(e.model) then
            if e.name == cur.name then
                table.insert(quest, e)
            elseif CFG.PullOthers then
                table.insert(others, e)
            end
        end
    end
    if #quest == 0 then return {}, nil end

    if pileFor == cur.name and pileCentre then from = pileCentre end
    local anchor, ad = nil, math.huge
    for _, e in ipairs(quest) do
        local d = (e.root.Position - from).Magnitude
        if d < ad then anchor, ad = e, d end
    end

    if not CFG.Magnet then
        -- No magnet: fight the nearest one where it stands.
        return { anchor }, anchor.root.Position
    end

    local cap = math.max(1, math.floor(CFG.GrabMax or 12))
    -- Other picked species that spawned in this camp, while there is room.
    local function withOthers(group, centre)
        for _, e in ipairs(others) do
            if #group >= cap then break end
            if (homeOf(e) - centre).Magnitude <= (CFG.OthersRadius or 100) then
                table.insert(group, e)
            end
        end
        return group, centre
    end

    local held, fresh = splitHeld(quest, cur.name)
    if held then
        -- The pile holds: a new one joins if it spawned within the limit of it.
        local limit = CFG.PullAll and pullLimit(cur.name) or (CFG.GrabRadius or 300)
        table.sort(fresh, function(a, b)
            return (homeOf(a) - pileCentre).Magnitude < (homeOf(b) - pileCentre).Magnitude
        end)
        for _, e in ipairs(fresh) do
            if #held >= cap then break end
            if (homeOf(e) - pileCentre).Magnitude <= limit then table.insert(held, e) end
        end
        return withOthers(held, pileCentre)
    end

    local home = homeOf(anchor)
    local group = {}
    for _, e in ipairs(quest) do
        if CFG.PullAll or (homeOf(e) - home).Magnitude <= (CFG.GrabRadius or 300) then
            table.insert(group, e)
        end
    end
    table.sort(group, function(a, b)
        return (homeOf(a) - home).Magnitude < (homeOf(b) - home).Magnitude
    end)

    local centre
    local camp = CFG.PullAll and campFor(cur.name, home) or nil
    if camp then
        local limit = pullLimit(cur.name)
        if camp.reach <= limit then
            -- The whole camp fits: one pile at its middle.
            centre, P.pileReach, P.pileSplit = camp.centre, camp.reach, nil
        else
            -- One pile in the middle would drag some past the limit. The side
            -- the anchor is on -- its camp's spawn points within the limit of
            -- it -- now; the far side when this one is empty (the anchor is
            -- then over there). Every point of the side is within the limit of
            -- the anchor, so its middle is too: the anchor always fits.
            local side = {}
            for _, p in ipairs(camp.pts) do
                if (p - home).Magnitude <= limit then table.insert(side, p) end
            end
            if #side == 0 then side = { home } end
            centre, P.pileReach = middleOf(side)
            P.pileSplit = string.format("camp %.0f studs across - one side at a time (pull at most %.0f)",
                camp.reach * 2, limit)
        end
        -- Only the ones whose spawn is within the limit of the pile.
        local keep = {}
        for _, e in ipairs(group) do
            if (homeOf(e) - centre).Magnitude <= limit then table.insert(keep, e) end
        end
        if #keep == 0 then keep = { anchor } end
        group = keep
        while #group > cap do table.remove(group) end
    else
        while #group > cap do table.remove(group) end
        local sum = Vector3.zero
        for _, e in ipairs(group) do sum += homeOf(e) end
        centre = sum / #group
        P.pileReach, P.pileSplit = nil, nil
    end
    return withOthers(group, centre)
end

-- RANDOM MODE's pile -- and RAID MODE's (buildRaidPile, below, is this with
-- the raid island as the centre). Every living enemy, any kind, within the
-- radius of `around` (random: P.randomAt, the Castle on the Sea raid area
-- there, else you).
--   pile   : the nearest free one picks the spot; only the ones whose spawn is
--            within THEIR OWN kind's pull limit of it are pulled -- a far or
--            diagonal one is its own pile, in turn. So everyone pulled is
--            pulled only as far as it can be and still take damage.
--   in place: one that was pulled and took no damage (put back) is not left
--            alone: once no free one is left it is fought where it stands
--            (third return value true = do not move it).
P.randomAt, P.randomNote, P.randomSkip, P.randomCant = nil, "random mode: starting", {}, 0
-- pullAll: no pull limit at all (raid mode: raid enemies roam the whole
-- island to reach you - the user saw no leash there, 2026-09-28).
local function buildRandomPile(around, radius, pullAll)
    local _, r = parts()
    if not r then return {}, nil, false end
    if not around then
        around = P.randomAt or r.Position
        radius = CFG.RandomRadius or 750
        if P.randomAt then radius = math.max(radius, 800) end   -- the raid area is 750 round its centre
    end
    local now = os.clock()
    local free, solo = {}, {}
    for _, e in ipairs(liveEnemies(nil)) do
        if (e.root.Position - around).Magnitude <= radius and not (P.randomSkip[e.model] and now < P.randomSkip[e.model]) then
            if isPutBack(e.model) then table.insert(solo, e) else table.insert(free, e) end
        end
    end
    local from = pileCentre or r.Position
    local function nearest(list)
        local best, bd = nil, math.huge
        for _, e in ipairs(list) do
            local d = (e.root.Position - from).Magnitude
            if d < bd then best, bd = e, d end
        end
        return best
    end
    if #free > 0 then
        local anchor = nearest(free)
        if not CFG.Magnet then return { anchor }, anchor.root.Position, true end
        local cap = math.max(1, math.floor(CFG.GrabMax or 12))
        -- The pile holds (buildPile): a new one joins within its own pull
        -- limit of it; raid mode, any distance.
        local held, fresh = splitHeld(free, pileCur and pileCur.name)
        if held then
            table.sort(fresh, function(a, b)
                return (homeOf(a) - pileCentre).Magnitude < (homeOf(b) - pileCentre).Magnitude
            end)
            for _, e in ipairs(fresh) do
                if #held >= cap then break end
                if pullAll or (homeOf(e) - pileCentre).Magnitude <= pullLimit(e.name) then
                    table.insert(held, e)
                end
            end
            return held, pileCentre, false
        end
        local home = homeOf(anchor)
        local lim = pullAll and math.huge or pullLimit(anchor.name)
        local pts = {}
        for _, e in ipairs(free) do
            local h = homeOf(e)
            if (h - home).Magnitude <= lim then table.insert(pts, h) end
        end
        local centre, reach = middleOf(pts)
        local list = {}
        for _, e in ipairs(free) do
            if pullAll or (homeOf(e) - centre).Magnitude <= pullLimit(e.name) then table.insert(list, e) end
        end
        if #list == 0 then list = { anchor } end
        table.sort(list, function(a, b)
            return (homeOf(a) - centre).Magnitude < (homeOf(b) - centre).Magnitude
        end)
        while #list > cap do table.remove(list) end
        P.pileReach = reach
        return list, centre, false
    end
    if #solo > 0 then
        local e = nearest(solo)
        return { e }, e.root.Position, true
    end
    return {}, nil, false
end

-- RAID MODE's pile: random mode's rules round the newest raid island
-- (P.raidAt; round you if only the timer says raid), within RaidRadius - every one
-- pulled (raid enemies have no leash). One that takes no damage when pulled
-- is no longer put back and LEFT OUT: that left the wave stuck with it alive
-- while the farm waited over the island (2026-09-28, "2 of 5 never hurt").
-- It is fought where it stands once the free ones are dead.
P.raidAt, P.raidNote, P.raidFocus = nil, "raid mode: starting", nil
local function buildRaidPile()
    local _, r = parts()
    if not r then return {}, nil, false end
    -- THE STUCK FIGHT (RAID MODE's watch): the one taken as THE target is
    -- fought where it stands, wherever it is, until it dies.
    local f = P.raidFocus
    if f then
        for _, e in ipairs(liveEnemies(nil)) do
            if e.model == f then return { e }, e.root.Position, true end
        end
        P.raidFocus = nil
    end
    return buildRandomPile(P.raidAt or r.Position, CFG.RaidRadius or 450, true)
end

-- ONE AT A TIME, WHERE IT STANDS: the nearest living one of `names` (a set),
-- never pulled.
--   ELITE HUNT: its one elite. A pulled one that took no damage would be put
--     back and left alone for thirty seconds -- on the one target the hunt is for.
--   FIRE FLOWER HUNT (user, 2026-10-04): no magnet there - a pile hangs in the
--     air, and the flower comes up where the enemy dies.
-- Kept until it dies: this runs ten times a second, and two equally near must
-- not take turns. skip: model -> until when it is left alone (no damage).
local function buildNearestPile(names, skip)
    local _, r = parts()
    if not r then return {}, nil end
    local now = os.clock()
    local best, bd = nil, math.huge
    for _, e in ipairs(liveEnemies(names)) do
        if not (skip and skip[e.model] and now < skip[e.model]) then
            if e.model == P.inPlaceTarget then return { e }, e.root.Position end
            local d = (e.root.Position - r.Position).Magnitude
            if d < bd then best, bd = e, d end
        end
    end
    if not best then return {}, nil end
    return { best }, best.root.Position
end

-- Look again who is loaded: a new spawn joins the pile within a tenth of a
-- second. Called from the fight AND from the frame loop below, because the
-- fight is busy for most of a second on every cast and every M1 probe.
local function refreshPile()
    if not pileCur then return end
    pileScanAt = os.clock()
    local list, centre
    if pileCur.random or pileCur.raid then
        local inPlace
        if pileCur.raid then
            list, centre, inPlace = buildRaidPile()
        else
            list, centre, inPlace = buildRandomPile()
        end
        -- A new in-place target starts from the height you set again.
        local model = inPlace and list[1] and list[1].model or nil
        if model ~= P.inPlaceTarget then P.forceClose = false end
        P.pileInPlace = inPlace
        P.inPlaceTarget = model
    elseif pileCur.build then
        -- A pile its own section builds (the Lava Golems: SEA HUNT).
        local inPlace
        list, centre, inPlace = pileCur.build()
        local model = inPlace and list[1] and list[1].model or nil
        if model ~= P.inPlaceTarget then P.forceClose = false end
        P.pileInPlace = inPlace and true or false
        P.inPlaceTarget = model
    elseif pileCur.elite or pileCur.flower then
        if pileCur.elite then
            list, centre = buildNearestPile({ [pileCur.name] = true })
        else
            list, centre = buildNearestPile(pileNames, P.randomSkip)
        end
        local model = list[1] and list[1].model or nil
        if model ~= P.inPlaceTarget then P.forceClose = false end
        P.pileInPlace = true
        P.inPlaceTarget = model
    else
        P.pileInPlace = false
        list, centre = buildPile(pileCur, pileNames)
    end
    pile = list
    if centre and (not pileCentre or pileFor ~= pileCur.name
        or (centre - pileCentre).Magnitude > 2) then
        pileCentre, pileFor = centre, pileCur.name
    end
    for _, e in ipairs(list) do
        pileWatch[e.model] = e.hum
        countedDead[e.model] = nil   -- alive: a death on record was an earlier life
    end
end

-- Every frame, after physics.
-- ITS OWN PLACE. Each one keeps its spot on the ring for as long as it is in
-- the pile: the lowest spot free when it joined, spots a golden angle apart
-- (any number spread round, a newcomer never lands on another). The spot used
-- to be its index in the pile list, so every death moved every other one
-- across the ring.
-- FROZEN while held, the way the public hubs freeze the ones they bring
-- (WalkSpeed 0, JumpPower 0, PlatformStand), and frozen again any frame it
-- is found unfrozen (the game may set its speed back): held only by this
-- write, one frame without it -- an ownership blip, a rebuild -- and it walked
-- off. They are the Humanoid's own fields on YOUR client: they stop only the
-- simulation you run for it, never the server's.
local magnetTick
do
    local GOLDEN = math.pi * (3 - math.sqrt(5))
    local slotOf = setmetatable({}, { __mode = "k" })

    function magnetTick()
        if not (P.running and pileActive and CFG.Magnet and pileCentre) then return end
        local now = os.clock()
        if now - pileScanAt > 0.1 then refreshPile() end
        if P.pileInPlace then P.pileHeld = 0 return end   -- fought where it stands
        if now - simAt > 1 then
            simAt = now
            if sethiddenproperty then
                pcall(sethiddenproperty, player, "SimulationRadius", math.huge)
            end
        end
        local live = {}
        for _, e in ipairs(pile) do
            if e.model.Parent and e.hum.Health > 0 then table.insert(live, e) end
        end
        -- Spots in use; a spot two claim (one came back to a spot since
        -- given away) goes to the first, the other gets a new one.
        local used = {}
        for _, e in ipairs(live) do
            local s = slotOf[e.model]
            if s and not used[s] then used[s] = true else slotOf[e.model] = nil end
        end
        local rad = (#live > 1) and (CFG.PileSpread or 3) or 0
        local held, owned = 0, 0
        for _, e in ipairs(live) do
            -- Owned = where we wrote it last frame is where it still is.
            local prev = lastDest[e.model]
            if prev and (e.root.Position - prev).Magnitude < 4 then
                owned += 1
                P.heldAt[e.model] = now
            end
            local s = slotOf[e.model]
            if not s then
                s = 1
                while used[s] do s += 1 end
                used[s], slotOf[e.model] = true, s
            end
            local a    = s * GOLDEN
            local dest = pileCentre + Vector3.new(math.cos(a) * rad, 0, math.sin(a) * rad)
            pcall(function()
                local hum = e.hum
                if hum.WalkSpeed ~= 0 or not hum.PlatformStand then
                    hum.WalkSpeed, hum.JumpPower, hum.PlatformStand = 0, 0, true
                end
                e.root.CFrame = CFrame.new(dest)
                e.root.AssemblyLinearVelocity  = Vector3.zero
                e.root.AssemblyAngularVelocity = Vector3.zero
                for _, d in ipairs(e.root:GetChildren()) do
                    if d:IsA("BodyMover") or d:IsA("LinearVelocity") or d:IsA("VectorForce") then
                        d:Destroy()
                    end
                end
            end)
            lastDest[e.model] = dest
            held += 1
        end
        P.pileHeld, P.pileOwned = held, owned
    end
end

-- WHY NO DAMAGE. The moment one stops taking damage, what was true then is
-- written down (Magnet page), so a guess becomes a reading:
--   NOT OURS   the magnet moves it only on your screen; the server has it
--              where the gap says, and judges your hit by THAT position
--   OUT OF REACH  the hit call does not name it at all
--   SHIELDED   a ForceField on it (spawn protection)
--   ours, in reach, no shield, no damage: the server refused the hit itself
--              (its place in the pile shows a cap on how many one hit takes)
P.noDamage = {}
-- Returns false when it was NOT OURS (moved only on your screen).
function P.noteNoDamage(e, how)
    local bits = {}
    local ours = true
    -- Only while it is being pulled: in place, lastDest is an old pull's.
    local dest = (not P.pileInPlace) and lastDest[e.model] or nil
    if dest then
        local gap = (e.root.Position - dest).Magnitude
        if gap > 4 then ours = false end
        table.insert(bits, (gap > 4) and string.format("NOT OURS (really %.0f from where it was put)", gap) or "held, ours")
    end
    if isnetworkowner then
        local ok, own = pcall(isnetworkowner, e.root)
        if ok then
            if not own then ours = false end
            table.insert(bits, own and "network owner you" or "network owner NOT you")
        end
    end
    local _, r = parts()
    if r then
        local reach = P.hitReach and P.hitReach() or (CFG.HitRange or 60)
        local d = (e.root.Position - r.Position).Magnitude
        table.insert(bits, string.format("%s (%.0f of %.0f)", (d <= reach) and "in reach" or "OUT OF REACH", d, reach))
    end
    local ok, ff = pcall(function() return e.model:FindFirstChildOfClass("ForceField") end)
    if ok and ff then table.insert(bits, "SHIELDED") end
    local idx
    for i, o in ipairs(pile) do if o == e then idx = i break end end
    table.insert(bits, string.format("pile %s of %d", tostring(idx or "?"), #pile))
    local h = homePos[e.model]
    if h and pileCentre and not P.pileInPlace then
        table.insert(bits, string.format("pulled %.0f", (h - pileCentre).Magnitude))
    end
    table.insert(P.noDamage, 1, tostring(e.name or "?") .. " - " .. how .. ": " .. table.concat(bits, ", "))
    while #P.noDamage > 6 do table.remove(P.noDamage) end
    return ours
end

-- Held, hit, and not losing HP: out of its area, or not ours to move.
local function checkPutBack()
    if not attacking or probing then return end
    local now = os.clock()
    -- FOUGHT IN PLACE (random and raid mode): never moved or put back. No damage from
    -- the height you set for 6 s: down close for it. None for 15 s even
    -- close: it cannot be hurt by this setup -- left for a minute, counted.
    if P.pileInPlace then
        local e = pile[1]
        if not e then return end
        local j = pileJoin[e.model]
        local focus = (P :: any).gunFocus
        if j and focus and e.root ~= focus and not (e.hum.Health < j.hp - 0.5) then
            -- A gun's shots are going at another one (THE GUN): not its turn.
            j.at, j.act = now, actions
        elseif not j then
            pileJoin[e.model] = { at = now, hp = e.hum.Health, act = actions }
        elseif e.hum.Health < j.hp - 0.5 then
            j.at, j.hp, j.act, j.hit = now, e.hum.Health, actions, true
        elseif now - j.at > 6 and actions - j.act >= 6 and not P.forceClose then
            P.noteNoDamage(e, "in place, from high")
            P.forceClose = true          -- poseTarget takes you close from the next frame
        elseif now - j.at > 15 and actions - j.act >= 15 then
            P.noteNoDamage(e, "in place, close")
            -- An elite is never skipped: it is the only one there is. The M1
            -- way found for it is doubted instead and looked for again (it may
            -- have been "found" while another player's hits took the HP off).
            if not (pileCur and pileCur.elite) then
                P.randomSkip[e.model] = now + 60
                P.randomCant += 1
            elseif P.reprobe then
                P.reprobe()
            end
            pileJoin[e.model] = nil
        end
        return
    end
    if not CFG.Magnet then return end
    -- A GUN SHOOTS ONE ENEMY (THE GUN, P.gunFocus): the rest of the pile is
    -- waiting its turn, not failing to take damage. Their clock is held at
    -- now until it is their turn (or a skill hurts them); judging them put
    -- the whole pile back to its spawns, one by one, while the gun fired.
    local focus = (P :: any).gunFocus
    for _, e in ipairs(pile) do
        local j = pileJoin[e.model]
        if j and focus and e.root ~= focus and not (e.hum.Health < j.hp - 0.5) then
            j.at, j.act = now, actions
        elseif not j then
            pileJoin[e.model] = { at = now, hp = e.hum.Health, act = actions }
        elseif e.hum.Health < j.hp - 0.5 then
            j.at, j.hp, j.act, j.hit = now, e.hum.Health, actions, true
            -- Took damage this far from its spawn: that far is fine.
            local h = homePos[e.model]
            if h and pileCentre and e.name then
                local d = (h - pileCentre).Magnitude
                local l = P.leash[e.name] or {}
                P.leash[e.name] = l
                if not l.ok or d > l.ok then l.ok = d end
            end
        elseif now - j.at > (CFG.PutBackAfter or 3) and actions - j.act >= 6
            and pileCur and pileCur.keepHeld then
            -- A pile that must stay held (the Lava Golems: put back = back on
            -- the relic). Written down once, never let go.
            if not j.noted then
                j.noted = true
                P.noteNoDamage(e, "held, kept held")
            end
        elseif now - j.at > (CFG.PutBackAfter or 3) and actions - j.act >= 6 then
            -- Written down first: whether it was really ours decides below.
            local ours = P.noteNoDamage(e, "pulled")
            -- No damage. If one pulled from NEARER its spawn in this same pile
            -- did take damage, the distance is why: that is the limit for its
            -- kind. (Without that contrast it may just not be ours to move --
            -- and one that is NOT OURS teaches nothing about distance: the
            -- server has it elsewhere, it takes no damage however near.)
            local spawnAt = homePos[e.model]
            if CFG.LearnLeash and ours and spawnAt and pileCentre and e.name then
                local d = (spawnAt - pileCentre).Magnitude
                for _, o in ipairs(pile) do
                    local jo = pileJoin[o.model]
                    local ho = homePos[o.model]
                    if o ~= e and jo and jo.hit and ho and (ho - pileCentre).Magnitude < d - 10 then
                        local l = P.leash[e.name] or {}
                        P.leash[e.name] = l
                        if not l.bad or d < l.bad then l.bad = d end
                        break
                    end
                end
            end
            putBack[e.model] = now + 30
            pileJoin[e.model] = nil
            stats.putBack += 1
            local h = homePos[e.model]
            if h then pcall(function() e.root.CFrame = CFrame.new(h) end) end
        end
    end
end

-- Where skills are aimed: a body in the pile, not its middle. The ring leaves
-- the middle empty, and a line through empty air lands on whatever is behind
-- the pile instead -- the ground, or the sky over a floating camp.
local function aimPoint()
    -- A gun's one enemy (THE GUN) while it is being shot: its skills too.
    local g = (P :: any).gunFocus
    if g and g.Parent then return g.Position end
    for _, e in ipairs(pile) do
        if e.model.Parent and e.hum.Health > 0 then return e.root.Position end
    end
    return pileCentre
end

-- WHERE THE SILENT AIM POINTS: only while this script is firing (aimUntil) -
-- its own point (a vent) first, else the pile. nil = your mouse, untouched.
function P.aimTarget()
    if os.clock() >= aimUntil then return nil end
    local own = (P :: any).aimAt
    if own then return own end
    -- A gun reads the mouse on EVERY shot: its one enemy, whatever the
    -- skill aim switch says.
    local g = (P :: any).gunFocus
    if g and g.Parent then return g.Position end
    if CFG.AimSkills and pileCentre then return aimPoint() end
    return nil
end

-- =========================================================
-- WHERE YOU HANG
-- =========================================================
local wantPose = "safe"      -- "safe" (high) or "melee" (close beside)

local function poseTarget()
    if not pileCentre then return nil end
    -- A fight that places you itself (SEA EVENTS: round a Terrorshark, dodging).
    local own = pileCur and pileCur.pose and pileCur.pose() or nil
    if own then return own end
    -- Height is counted from the HIGHEST living enemy in the pile, not from
    -- the pile's centre: one the magnet does not own stands where it really
    -- is (up on the ledges at Port Town, say), and "60 over them" has to mean
    -- 60 over every one of them.
    local top = pileCentre.Y
    for _, e in ipairs(pile) do
        if e.model.Parent and e.hum.Health > 0 then top = math.max(top, e.root.Position.Y) end
    end
    local c = Vector3.new(pileCentre.X, top, pileCentre.Z)
    if not pileSide then
        local _, r = parts()
        local d = r and Vector3.new(r.Position.X - c.X, 0, r.Position.Z - c.Z) or Vector3.zero
        pileSide = (d.Magnitude > 0.5) and d.Unit or Vector3.new(1, 0, 0)
    end
    if CFG.HeightMode == "fixed" then
        return c + Vector3.new(0, CFG.HeightFixed or 12, 0) + pileSide * (CFG.SideFixed or 0)
    elseif wantPose == "melee" or P.forceClose then
        return c + Vector3.new(0, CFG.HeightMelee or 3, 0) + pileSide * (CFG.MeleeDistance or 5)
    end
    -- A fight's own height (SEA EVENTS: over a Terrorshark, out of its splash).
    local own = pileCur and pileCur.height and pileCur.height() or nil
    return c + Vector3.new(0, own or CFG.HeightSafe or 20, 0)
end

-- Put the lock where the pose says. Far away (back from an escape, a fresh
-- camp) is a flight, not a jump.
local function applyPose()
    local pos = poseTarget()
    if not pos then return end
    local _, r = parts()
    if r and (pos - r.Position).Magnitude > (CFG.InstantHop or 150) then
        local was = attacking
        attacking = false
        flyTo(pos, { face = pileCentre })
        attacking = was
        return
    end
    lockAt(pos, pileCentre)
end

local function setPose(p)
    -- Never down to the close spot -- unless random mode found high does not
    -- hurt the one it is fighting in place (P.forceClose).
    if P.forceClose then p = "melee" elseif CFG.StayHigh then p = "safe" end
    if wantPose ~= p then
        wantPose = p
        applyPose()
        task.wait(0.06)
    end
end

-- =========================================================
-- WEAPONS: WHAT EACH ONE FIRES
-- =========================================================
local KEYS    = { "Z", "X", "C", "V", "F" }
local KEYCODE = {
    Z = Enum.KeyCode.Z, X = Enum.KeyCode.X, C = Enum.KeyCode.C,
    V = Enum.KeyCode.V, F = Enum.KeyCode.F,
}
P.keys = KEYS

local function wcfg(name)
    local w = CFG.Weapons[name]
    if not w then
        w = { use = false, M1 = false, Z = false, X = false, C = false, V = false, F = false,
              hold = { Z = 0.05, X = 0.05, C = 0.05, V = 0.05, F = 0.05 } }
        CFG.Weapons[name] = w
        table.insert(CFG.WeaponOrder, name)
    end
    return w
end
P.wcfg = wcfg

local function wSummary(name)
    local w = CFG.Weapons[name]
    if not w then return "off" end
    local bits, keys = {}, {}
    if w.M1 then table.insert(bits, "M1") end
    for _, k in ipairs(KEYS) do if w[k] then table.insert(keys, k) end end
    if #keys > 0 then table.insert(bits, table.concat(keys, " ")) end
    if #bits == 0 then return "off" end
    return table.concat(bits, " + ") .. (w.use and "" or "  (use off)")
end
P.wSummary = wSummary

-- Every tool you carry gets an entry, all switches off. The very first time
-- this runs, M1 of the one in your hand is switched on, so the first run is
-- plain fast M1 and you add the rest yourself. Fruit first, then fighting
-- style, sword, gun.
local syncWeapons
do
    local TYPE_RANK = { ["Blox Fruit"] = 1, Melee = 2, Sword = 3, Gun = 4 }
    local seeded = false
    function syncWeapons()
        local tools = toolNames()
        local fresh = {}
        for _, t in ipairs(tools) do
            if not CFG.Weapons[t.Name] then table.insert(fresh, t) end
        end
        table.sort(fresh, function(a, b)
            local ra, rb = TYPE_RANK[toolType(a)] or 9, TYPE_RANK[toolType(b)] or 9
            if ra ~= rb then return ra < rb end
            return a.Name < b.Name
        end)
        for _, t in ipairs(fresh) do wcfg(t.Name) end
        if not seeded then
            local held = heldTool()
            if held then
                seeded = true
                -- Only if you have not switched anything on yourself already.
                local anyOn = false
                for _, w in pairs(CFG.Weapons) do
                    if w.M1 then anyOn = true end
                    for _, k in ipairs({ "Z", "X", "C", "V", "F" }) do if w[k] then anyOn = true end end
                end
                if not anyOn then
                    local w = wcfg(held.Name)
                    w.use, w.M1 = true, true
                end
            end
        end
    end
    P.syncWeapons = syncWeapons
end

function P.moveWeaponUp(name)
    local o = CFG.WeaponOrder
    for i, n in ipairs(o) do
        if n == name and i > 1 then
            o[i], o[i - 1] = o[i - 1], o[i]
            return true
        end
    end
    return false
end

-- The weapons that are on AND in your backpack, in your order. AutoAttack:
-- every one you carry (P.autoWeapons, WEAPON ROTATION).
local function usedWeapons()
    -- The mastery farm (THE GUN): that weapon alone, whatever else is set.
    local mu = (P :: any).masteryUsed
    local only = mu and mu()
    if only then return only end
    -- A sea event (SEA EVENTS; user, 2026-10-08): M1 AND every skill of every
    -- weapon you carry, whatever the Attack page says.
    if pileCur and pileCur.allKeys and (P :: any).autoWeapons then
        local list = (P :: any).autoWeapons(pileCur.allKeys())
        -- ...the fight's own weapon rule (SEA EVENTS: fruit + melee, the form's).
        if pileCur.toolOk then
            local only = {}
            for _, u in ipairs(list) do
                if pileCur.toolOk(u.name) then table.insert(only, u) end
            end
            list = only
        end
        -- ...and per key (SEA EVENTS: never V on a transformation fruit;
        -- a key its mastery has not unlocked).
        if pileCur.keyOk then
            for _, u in ipairs(list) do
                for _, k in ipairs(KEYS) do
                    if u.cfg[k] and not pileCur.keyOk(u.name, k) then u.cfg[k] = false end
                end
            end
        end
        return list
    end
    if CFG.AutoAttack and (P :: any).autoWeapons then return (P :: any).autoWeapons() end
    local out = {}
    for _, name in ipairs(CFG.WeaponOrder) do
        local w = CFG.Weapons[name]
        if w and w.use then
            local any = w.M1
            for _, k in ipairs(KEYS) do if w[k] then any = true end end
            local tool = any and findTool(name)
            if tool then table.insert(out, { name = name, cfg = w, tool = tool }) end
        end
    end
    return out
end

local function equip(name)
    local held = heldTool()
    if held and held.Name == name then return true end
    local tool = findTool(name)
    local _, _, h = parts()
    if not tool or not h then return false end
    pcall(function() h:EquipTool(tool) end)
    stats.swaps += 1
    task.wait(CFG.EquipWait or 0.12)
    local now = heldTool()
    return now ~= nil and now.Name == name
end

-- =========================================================
-- COOLDOWNS, READ OFF THE GAME'S OWN BARS
-- =========================================================
-- PlayerGui.Main.Skills[<weapon>][<key>].Cooldown is the bar the game draws
-- over each skill. Width 0 = ready. The bar is the only place the client
-- learns the real cooldown; the timer itself lives on the server, which is
-- why a cooldown cannot be removed from here -- only never wasted.
--
-- While a weapon is in hand its bars are watched and each skill's full
-- cooldown is learned. A weapon NOT in hand may show no bar, so it is judged
-- by that learned time since its last cast.
local cd = {}
local function cdOf(w, k)
    cd[w] = cd[w] or {}
    local c = cd[w][k]
    if not c then c = {} cd[w][k] = c end
    return c
end

local barReady
do
    local function skillBar(w, k)
        local pg = player:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        local sk = main and main:FindFirstChild("Skills")
        local wf = sk and sk:FindFirstChild(w)
        local kf = wf and wf:FindFirstChild(k)
        local bar = kf and kf:FindFirstChild("Cooldown")
        if bar and bar:IsA("GuiObject") then return bar end
        return nil
    end

    -- true ready, false cooling, nil no bar to read.
    function barReady(w, k)
        local bar = skillBar(w, k)
        if not bar then return nil end
        return bar.AbsoluteSize.X <= 0
    end
end

-- Ten times a second: learn how long each switched-on skill cools.
local function cdTick()
    local now = os.clock()
    for name, w in pairs(CFG.Weapons) do
        for _, k in ipairs(KEYS) do
            if w[k] or CFG.AutoAttack or (pileCur and pileCur.allKeys) then
                local b = barReady(name, k)
                if b ~= nil then
                    local c = cdOf(name, k)
                    if b == false then
                        c.coolStart = c.coolStart or now
                    elseif c.coolStart then
                        c.learned = now - c.coolStart
                        c.coolStart = nil
                    end
                end
            end
        end
    end
end

local function skillReady(w, k)
    -- Sent, and its bar never moved: not this weapon's (or not unlocked yet).
    local dead = cd[w] and cd[w][k] and cd[w][k].deadUntil
    if dead and os.clock() < dead then return false end
    local b = barReady(w, k)
    local held = heldTool()
    -- The bar of the weapon in hand is the truth. Others: trust a bar that
    -- says cooling, and otherwise the clock.
    if held and held.Name == w and b ~= nil then return b end
    if b == false then return false end
    local c = cdOf(w, k)
    if c.lastCast then
        return os.clock() - c.lastCast >= (c.learned or 2)
    end
    return true
end

function P.skillState(w)
    local out = {}
    local ww = CFG.Weapons[w]
    if not ww then return "" end
    for _, k in ipairs(KEYS) do
        if ww[k] then
            local c = cdOf(w, k)
            local ready = skillReady(w, k)
            local left = (c.lastCast and c.learned) and math.max(0, c.learned - (os.clock() - c.lastCast)) or nil
            table.insert(out, k .. " " .. (ready and "ready"
                or (left and string.format("%.1fs", left) or "cooling")))
        end
    end
    return table.concat(out, "   ")
end

-- =========================================================
-- WEAPON ROTATION
-- =========================================================
-- EVERY WEAPON YOU CARRY (CFG.AutoAttack): the attack list is simply what
-- you carry - M1 with your SWORD (user, 2026-10-05: Hallow Scythe hits 3755 a
-- swing, the fighting style far less; else a fighting style, the fruit, a
-- gun) and CFG.AutoKeys of all of them, each fired when its bar says ready.
-- The M1 sword is never swapped out by the rotation (P.keepSword).
-- FROM YOUR INVENTORY (CFG.InvSwap): a sword or gun's skills cool per
-- weapon, so when every carried skill is cooling the next sword / gun in
-- your inventory is put in your hands - CommF_("LoadItem", name), the game's
-- own call (the public hubs use it), no menu - and fired. The one loaded
-- longest ago and rested (none of its keys cast within their cooldown) goes
-- first. What you carried when it started goes back when the farm stops.
-- Only P.autoWeapons / P.rotate / P.rotRestore / P.rot leave the block.
do
    local function build()
        local R: { [string]: any } = {
            inv = nil, invAt = 0, lastLoad = 0, loads = 0, note = "-",
            loadedAt = {}, failUntil = {}, original = nil, originalText = nil,
        }
        P.rot = R
        local M1_RANK = { Sword = 1, Melee = 2, ["Blox Fruit"] = 3, Gun = 4 }

        -- THE M1 WEAPON of a fight, from `used` (the attack list): your pick
        -- (CFG.M1Weapon) when you carry it, even if its own M1 switch is off;
        -- else, of the ones with M1 on, a sword first. The old rule - the
        -- FIRST in the weapon list with M1 on - put a fighting style (listed
        -- before swords, and switched on for you on the first run) ahead of
        -- the sword you picked.
        function P.m1Of(used)
            -- The fight's own weapon (the volcano's golems: CFG.GolemWeapon),
            -- then your pick; whichever you carry first.
            local own = pileCur and pileCur.m1Weapon and pileCur.m1Weapon() or nil
            -- The mastery weapon before your pick: another weapon's swing
            -- would share its kills.
            for _, want in ipairs({ own or "", CFG.MasteryWeapon or "", CFG.M1Weapon or "" }) do
                if type(want) == "string" and want ~= "" then
                    local t = findTool(want)
                    if t then return { name = want, cfg = wcfg(want), tool = t } end
                end
            end
            local best, br = nil, math.huge
            for _, u in ipairs(used) do
                if u.cfg.M1 then
                    local r = M1_RANK[toolType(u.tool)] or 9
                    if r < br then best, br = u, r end
                end
            end
            return best
        end

        -- keysIn: a fight's own keys (SEA EVENTS: CFG.SeaEvKeys, F included);
        -- nil = CFG.AutoKeys, never F.
        function P.autoWeapons(keysIn)
            local tools = toolNames()
            table.sort(tools, function(a, b)
                local ra, rb = M1_RANK[toolType(a)] or 9, M1_RANK[toolType(b)] or 9
                if ra ~= rb then return ra < rb end
                return a.Name < b.Name
            end)
            local keys = keysIn or CFG.AutoKeys or {}
            local out = {}
            for _, t in ipairs(tools) do
                local w = wcfg(t.Name)
                -- M1 allowed on all; P.m1Of picks the one that swings.
                local cfg = { use = true, M1 = true, hold = w.hold,
                    Z = keys.Z == true, X = keys.X == true, C = keys.C == true, V = keys.V == true,
                    F = keysIn ~= nil and keys.F == true }
                table.insert(out, { name = t.Name, cfg = cfg, tool = t })
            end
            local m1 = P.m1Of(out)
            P.keepSword = (m1 and toolType(m1.tool) == "Sword") and m1.name or nil
            return out
        end

        -- Your inventory's swords and guns: { name, type, mastery }. 30 s cache.
        local function inventory()
            if R.inv and os.clock() - R.invAt < 30 then return R.inv end
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if ok and type(inv) == "table" then
                local out = {}
                for _, it in pairs(inv) do
                    if type(it) == "table" and (it.Type == "Sword" or it.Type == "Gun") and type(it.Name) == "string" then
                        table.insert(out, { name = it.Name, type = it.Type, mastery = tonumber(it.Mastery) or 0 })
                    end
                end
                R.inv, R.invAt = out, os.clock()
            end
            return R.inv or {}
        end

        -- Every key of it we cast has cooled (by its learned time, 8 s unknown).
        local function rested(name, now)
            for _, k in ipairs(KEYS) do
                local c = cd[name] and cd[name][k]
                if c and c.lastCast and now - c.lastCast < (c.learned or 8) then return false end
            end
            return true
        end

        -- Pure (tools/rotate_test.py): the next one to load, or nil. Not one
        -- you carry, not one switched off, not one that failed to load lately,
        -- rested; the one loaded longest ago (never = first).
        local function pickNext(list, carried, skip, failUntil, loadedAt, now, restedFn)
            local best, bestAt = nil, math.huge
            for _, it in ipairs(list) do
                if not carried[it.name] and not skip[it.name] and now >= (failUntil[it.name] or 0)
                    and restedFn(it.name, now) then
                    local at = loadedAt[it.name] or -math.huge
                    if at < bestAt then best, bestAt = it, at end
                end
            end
            return best
        end
        R.pickNext = pickNext
        R.rested = rested

        -- What you carried, once, to put back at the stop.
        local function remember(tools)
            if R.original then return end
            R.original = {}
            local names = {}
            for _, t in ipairs(tools) do
                local ty = toolType(t)
                if ty == "Sword" or ty == "Gun" then
                    R.original[ty] = t.Name
                    table.insert(names, t.Name)
                end
            end
            R.originalText = (#names > 0) and table.concat(names, ", ") or "nothing"
        end

        function P.invHas(name)
            for _, it in ipairs(inventory()) do
                if it.name == name then return true end
            end
            return false
        end

        -- One by name into your hands (the volcano's Skull Guitar). true = in hand.
        function P.loadItem(name)
            if findTool(name) then return true end
            remember(toolNames())
            local cf = commF()
            pcall(function() cf:InvokeServer("LoadItem", name) end)
            local t0 = os.clock()
            while not findTool(name) and os.clock() - t0 < 1.5 do task.wait(0.05) end
            if findTool(name) then
                R.loads += 1
                R.note = "loaded " .. name .. " (for the vents)"
                return true
            end
            return false
        end

        -- vents = true: the volcano asks (any attack mode). true = a new one
        -- is in your hands. P.keepGun (the volcano's vent gun) = no gun is
        -- swapped in over it.
        function P.rotate(vents)
            if not CFG.InvSwap then return false end
            if not vents and not CFG.AutoAttack and not (pileCur and pileCur.allKeys) then return false end
            -- A fight that takes no sword / gun (SEA EVENTS: fruit + melee): none loaded.
            if not vents and pileCur and pileCur.noRotate and pileCur.noRotate() then return false end
            -- The mastery farm: nothing else is put in your hands.
            if not vents and (CFG.MasteryWeapon or "") ~= "" then return false end
            local now = os.clock()
            if now - R.lastLoad < (CFG.InvSwapGap or 1.5) then return false end
            local carried = {}
            local tools = toolNames()
            for _, t in ipairs(tools) do carried[t.Name] = true end
            -- Kept: the vent gun (P.keepGun), the M1 sword (P.keepSword) - their
            -- slot is never swapped.
            local list = inventory()
            local keep = {}
            if P.keepGun and carried[P.keepGun] then keep.Gun = true end
            if P.keepSword and carried[P.keepSword] then keep.Sword = true end
            if next(keep) then
                local only = {}
                for _, it in ipairs(list) do
                    if not keep[it.type] then table.insert(only, it) end
                end
                list = only
            end
            local pick = pickNext(list, carried, CFG.InvSkip or {}, R.failUntil, R.loadedAt, now, rested)
            if not pick then
                R.note = "nothing rested in your inventory"
                return false
            end
            remember(tools)
            R.lastLoad = now
            local cf = commF()
            pcall(function() cf:InvokeServer("LoadItem", pick.name) end)
            local t0 = os.clock()
            while not findTool(pick.name) and os.clock() - t0 < 1.5 do task.wait(0.05) end
            if findTool(pick.name) then
                R.loads += 1
                R.loadedAt[pick.name] = now
                R.note = "loaded " .. pick.name .. " (" .. pick.type .. ")"
                stats.swaps += 1
                return true
            end
            R.failUntil[pick.name] = now + 120
            R.note = pick.name .. " did not come - left 2 min"
            return false
        end

        -- The farm stopped: what you carried back in your hands.
        function P.rotRestore()
            local o = R.original
            R.original = nil
            if not o then return end
            local cf = commF()
            for _, name in pairs(o) do
                if not findTool(name) then
                    pcall(function() cf:InvokeServer("LoadItem", name) end)
                    task.wait(0.3)
                end
            end
            R.note = "put back: " .. tostring(R.originalText)
        end
    end
    build()
end

-- =========================================================
-- M1: THREE WAYS TO LAND IT, FOUND BY TRYING
-- =========================================================
-- remote : ReplicatedStorage.Modules.Net "RE/RegisterAttack" then
--          "RE/RegisterHit" naming EVERY enemy in the pile -- one swing, the
--          whole pile. Fighting styles and swords. Two argument shapes: the
--          one in the newest public scripts (2026-09-25), and the older one.
-- click  : a fruit's own M1 -- tool.LeftClickRemote, aimed at each enemy.
-- keys   : the mouse click farm_pro uses. Slow, needs you close, but proven.
-- Any of these can stop working with a game update, so none is trusted:
-- each is fired at the pile for a moment and the first that takes HP off is
-- kept, per weapon. The panel says which. The game's own hit sender
-- (_G.SendHitsToServer), when it can be reached, is tried first.
local m1Plan  = {}           -- [weapon] = chosen way, or false (nothing landed)
local m1Retry = {}           -- [weapon] = when a "nothing landed" is tried again
P.m1Notes     = {}

-- Try the ways now? Never tried, or a "nothing landed" whose wait is over.
local function m1Due(name)
    local way = m1Plan[name]
    return way == nil or (way == false and os.clock() >= (m1Retry[name] or 0))
end
local lastProbeMethod = CFG.M1Method

local fireM1
do
    local HIT_TAG = "078da341"
    -- Your reach, or far enough to reach the pile from the height you set
    -- (60 up with a 60 reach named nobody at all). Whether the server takes a
    -- hit from that far is its call: "how M1 lands" shows it. On P so the
    -- no-damage note (checkPutBack) reads the same number the hit uses.
    function P.hitReach()
        local _, r = parts()
        local range = CFG.HitRange or 60
        if r and pileCentre then
            range = math.max(range, (r.Position - pileCentre).Magnitude + (CFG.PileSpread or 3) + 5)
        end
        return range
    end
    -- WHO IS NAMED FIRST TAKES TURNS, one swing each. The pile is ordered
    -- nearest-spawn first; a way that lands on the first names only (a fruit
    -- click per enemy, a cap per call) never reached the back of the pile --
    -- 3 s there with no damage = put back to its spawn mid-fight, and the ones
    -- in front "proved" a pull limit. Same names, same swing, same moment:
    -- only the order turns.
    local hitTurn = 0
    local function hitTargets()
        local _, r = parts()
        if not r then return {} end
        local out = {}
        local range = P.hitReach()
        for _, e in ipairs(pile) do
            if e.model.Parent and e.hum.Health > 0
                and (e.root.Position - r.Position).Magnitude <= range then
                table.insert(out, e)
            end
        end
        if #out > 1 then
            hitTurn += 1
            local k = hitTurn % #out
            if k > 0 then
                local turned = table.move(out, k + 1, #out, 1, {})
                out = table.move(out, 1, k, #turned + 1, turned)
            end
        end
        return out
    end

    -- THE GAME'S OWN HIT SENDER. The game's client sends its hits through
    -- its own function, _G.SendHitsToServer (in its PlayerScripts); a server
    -- whose Flags module has COMBAT_REMOTE_THREAD on appears to take hits
    -- only that way. The 2026-04 and 2026-09-29 public hubs both call it
    -- first and fire RegisterHit themselves only without it. Flags come with
    -- the SERVER's version: servers started after an update run the new
    -- combat, older ones the old -- a raw RegisterHit then lands in some
    -- servers and not in others. Looked for once per server (again every 5 s
    -- while missing).
    local gameHit, gameHitAt = nil, -1e9
    P.hitSender, P.combatFlag = "not looked for yet", nil
    local function findGameHit()
        if gameHit then return gameHit end
        if os.clock() - gameHitAt < 5 then return nil end
        gameHitAt = os.clock()
        pcall(function()
            local fl = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Flags")
            if fl then P.combatFlag = require(fl).COMBAT_REMOTE_THREAD end
        end)
        if getrenv then
            local ok, f = pcall(function() return getrenv()._G.SendHitsToServer end)
            if ok and type(f) == "function" then
                gameHit, P.hitSender = f, "the game's SendHitsToServer (getrenv)"
            end
        end
        if not gameHit and getsenv then
            local ps = player:FindFirstChild("PlayerScripts")
            for _, c in ipairs(ps and ps:GetChildren() or {}) do
                if c:IsA("LocalScript") then
                    local ok, f = pcall(function() return getsenv(c)._G.SendHitsToServer end)
                    if ok and type(f) == "function" then
                        gameHit, P.hitSender = f, "the game's SendHitsToServer (" .. c.Name .. ")"
                        break
                    end
                end
            end
        end
        if not gameHit then
            P.hitSender = (getrenv or getsenv) and "raw RegisterHit - the game has no SendHitsToServer here"
                or "raw RegisterHit - this executor has no getrenv / getsenv"
        end
        print(string.format("[BFF] hits: %s  ·  COMBAT_REMOTE_THREAD = %s", P.hitSender, tostring(P.combatFlag)))
        return gameHit
    end
    P.findGameHit = findGameHit

    local function m1Remote(variant, list)
        local ra = netRemote("RE", "RegisterAttack")
        local rh = netRemote("RE", "RegisterHit")
        if variant == "game" then
            local f = findGameHit()
            if not f or #list == 0 then return false end
            local hits = {}
            for _, e in ipairs(list) do table.insert(hits, { e.model, e.root }) end
            if ra then pcall(function() ra:FireServer(0) end) end
            pcall(f, list[1].root, hits)
            return true
        end
        if not (ra and rh) or #list == 0 then return false end
        local head = list[1].model:FindFirstChild("Head") or list[1].root
        local hits = {}
        for _, e in ipairs(list) do
            if variant == "new" then
                table.insert(hits, { e.model, e.root })
                table.insert(hits, e.model)
            else
                table.insert(hits, { e.model, e.model:FindFirstChild("Head") or e.root })
            end
        end
        pcall(function() ra:FireServer(0) end)
        if variant == "new" then
            pcall(function() rh:FireServer(head, hits, nil, HIT_TAG) end)
        else
            pcall(function() rh:FireServer(head, hits) end)
        end
        return true
    end

    local function m1Click(tool, list)
        local rem = tool and tool:FindFirstChild("LeftClickRemote")
        local _, r = parts()
        if not rem or not r or #list == 0 then return false end
        for _, e in ipairs(list) do
            local d = e.root.Position - r.Position
            if d.Magnitude > 0.1 then pcall(function() rem:FireServer(d.Unit, 1) end) end
        end
        return true
    end

    function fireM1(way, tool)
        local list = hitTargets()
        if way.path == "remote" then
            m1Remote(way.variant, list)
        elseif way.path == "click" then
            m1Click(tool, list)
        elseif way.path == "hold" then
            (P :: any).gunHoldTick(tool)
        elseif way.path == "gunshot" then
            (P :: any).gunShotTick(tool)
        else
            -- A gun's click fires a burst (Dragonstorm: 3 shots, 0.08 s
            -- apart) and the game reads the mouse for EACH shot: the aim is
            -- kept on one enemy for the whole burst, not only the click.
            local ga = (P :: any).gunAimFor
            if ga and toolType(tool) == "Gun" then ga(0.5) end
            -- The click is sent at the middle of the screen, so for this click the
            -- line through the middle has to be the one that lands on the pile.
            local cam = workspace.CurrentCamera
            if CFG.AimSkills and pileCentre and cam then
                aimPixel = cam.ViewportSize * 0.5
                if CFG.AimHidden then
                    RunService.Heartbeat:Wait()
                    aimSwapIn(aimPoint(), pileCentre)
                else
                    aimCamera(aimPoint(), pileCentre)
                end
            end
            pressM1()
            aimPixel = nil
        end
        stats.m1 += 1
        actions += 1
    end
end

local function describeWay(way)
    if not way then return "-" end
    local where = (way.pose == "melee") and "close" or "from above"
    if way.path == "remote" then return "remote hit (" .. way.variant .. "), " .. where end
    if way.path == "click" then return "fruit click, " .. where end
    if way.path == "hold" then return "held like a player (the game's own fire), " .. where end
    if way.path == "gunshot" then return "the game's own shot, past the heat, " .. where end
    return "key press, " .. where
end
P.describeWay = describeWay

local probeM1
do
    local function waysFor(tool)
        local t = toolType(tool)
        local all = {}
        if t == "Melee" or t == "Sword" then
            if P.findGameHit() then
                table.insert(all, { path = "remote", variant = "game", pose = "safe" })
            end
            table.insert(all, { path = "remote", variant = "new", pose = "safe" })
            table.insert(all, { path = "remote", variant = "old", pose = "safe" })
            table.insert(all, { path = "keys", pose = "melee" })
        elseif t == "Blox Fruit" then
            if tool:FindFirstChild("LeftClickRemote") then
                table.insert(all, { path = "click", pose = "safe" })
                table.insert(all, { path = "click", pose = "melee" })
            end
            table.insert(all, { path = "remote", variant = "new", pose = "safe" })
            table.insert(all, { path = "keys", pose = "melee" })
        else
            -- A gun (THE GUN): the game's own shot past the heat when that is
            -- switched on, held like a player when it fires while held
            -- (Dragonstorm), a click per M1 last. Range 400: from above.
            local gi = (P :: any).gunInfo and (P :: any).gunInfo(tool)
            if gi and not gi.custom and CFG.GunFast and (P :: any).gunShotFn() then
                table.insert(all, { path = "gunshot", pose = "safe" })
            end
            if gi and gi.gatling and CFG.GunHold then
                table.insert(all, { path = "hold", pose = "safe" })
            end
            table.insert(all, { path = "keys", pose = "melee" })
        end
        if CFG.StayHigh then
            -- Every way tried from up there; a way listed twice (high and close)
            -- is tried once.
            local out, seen = {}, {}
            for _, w in ipairs(all) do
                local key = w.path .. (w.variant or "")
                if not seen[key] then
                    seen[key] = true
                    table.insert(out, { path = w.path, variant = w.variant, pose = "safe" })
                end
            end
            all = out
        end
        local force = CFG.M1Method
        if force and force ~= "auto" then
            local out = {}
            for _, w in ipairs(all) do if w.path == force then table.insert(out, w) end end
            if #out == 0 then
                table.insert(out, { path = force, variant = "new",
                    pose = (force == "keys") and "melee" or "safe" })
            end
            return out
        end
        return all
    end

    function probeM1(name, tool)
        stats.probes += 1
        probing = true
        local tried = {}
        for _, way in ipairs(waysFor(tool)) do
            if not P.running or #pile == 0 then break end
            say("trying M1: " .. describeWay(way))
            setPose(way.pose)
            task.wait(0.12)
            local snap = {}
            for _, e in ipairs(pile) do table.insert(snap, e) end
            local function sumHP()
                local s = 0
                for _, e in ipairs(snap) do
                    if e.model.Parent and e.hum.Parent then s += math.max(e.hum.Health, 0) end
                end
                return s
            end
            local hp0, t0 = sumHP(), os.clock()
            while os.clock() - t0 < 1.6 and P.running and #pile > 0 do
                fireM1(way, tool)
                task.wait(math.max(CFG.M1Every or 0.06, 0.06))
            end
            task.wait(0.2)
            local landed = (hp0 - sumHP()) > 0.5
            -- A held button that landed nothing is let go before the next way.
            local gr = (P :: any).gunRelease
            if not landed and way.path == "hold" and gr then gr() end
            table.insert(tried, describeWay(way) .. (landed and ": landed" or ": nothing"))
            if landed then
                probing = false
                m1Plan[name] = way
                P.m1Notes[name] = describeWay(way)
                say(name .. " M1: " .. describeWay(way))
                print("[BFF] M1 " .. name .. ": " .. describeWay(way))
                return way
            end
        end
        probing = false
        if #tried == 0 then return nil end              -- interrupted: try again later
        -- NOT FINAL: one bad moment (just arrived, the target turning away)
        -- used to leave M1 off for the rest of the server. Tried again soon.
        m1Plan[name] = false
        m1Retry[name] = os.clock() + 12
        P.m1Notes[name] = "nothing landed  (" .. table.concat(tried, "; ") .. ")  - trying again in 12 s"
        print("[BFF] M1 " .. name .. ": " .. P.m1Notes[name])
        return false
    end
end

function P.reprobe()
    table.clear(m1Retry)
    table.clear(m1Plan)
    table.clear(P.m1Notes)
    say("M1 ways forgotten - each weapon is tried again on the next pile")
end

-- =========================================================
-- THE RHYTHM
-- =========================================================
-- Skills: the first READY one, in your weapon order, Z X C V F inside a
-- weapon; the weapon is swapped to if it is not in hand. M1: the first weapon
-- with M1 on. "M1 swings between skills" is how many M1s come after each
-- cast before the next ready skill is looked for; while nothing is ready M1
-- just keeps going. Nothing ready and no M1 on anywhere: wait.
local m1Count    = 0
P.nextNote = ""
P.lastCast = "none yet"
P.skillTally = {}            -- ["weapon key"] = { cast, fired, hit }

-- THE GAME'S OWN GATES (the decompiled casFunc, v4623): a key is refused
-- while the character is Busy, stunned, or another tool's move is Holding.
-- A key pressed then is not "a key that does not fire" - it was too early.
local function canCast()
    local ch = player and player.Character
    if not ch then return false end
    local busy, stun = ch:FindFirstChild("Busy"), ch:FindFirstChild("Stun")
    if busy and busy.Value == true then return false end
    if stun and (tonumber(stun.Value) or 0) > 0 then return false end
    local tool = ch:FindFirstChildOfClass("Tool")
    local holding = tool and tool:FindFirstChild("Holding")
    if holding and holding.Value == true then return false end
    return true
end
P.canCast = canCast

local function castSkill(u, k)
    -- A gun's held M1 (THE GUN) is let go: the key is pressed alone.
    local gr = (P :: any).gunRelease
    if gr then gr() end
    if not equip(u.name) then return false end
    -- In hand now, so its bar is the truth: if the guess was wrong, no key.
    if barReady(u.name, k) == false then return false end
    local t = toolType(u.tool)
    if CFG.HeightMode ~= "fixed" then
        setPose((t == "Melee" or t == "Sword") and "melee" or "safe")
    end
    local hold = (u.cfg.hold and u.cfg.hold[k]) or 0.05
    local hidden = CFG.AimSkills and CFG.AimHidden and pileCentre ~= nil
    if CFG.AimSkills and pileCentre and not CFG.AimHidden then
        aimCamera(aimPoint(), pileCentre)
        task.wait()
    end
    -- The pile's HP now, to tell a hit from a miss afterwards.
    local snap = {}
    for _, e in ipairs(pile) do snap[e] = e.hum.Health end
    local before = nil
    if hidden then
        -- Held in every frame of the cast (a skill may read the aim on the
        -- press, on the release, or while it plays), and put in right before
        -- each key event.
        aimUntil = os.clock() + hold + (CFG.CastWait or 0.45) + 0.5
        before = function()
            RunService.Heartbeat:Wait()
            if pileCentre then aimSwapIn(aimPoint(), pileCentre) end
        end
    end
    -- A sea event's fight (pileCur.fastCast, user 2026-10-09: "the moment it
    -- is out of cooldown it is pressed"): the key the moment the game takes
    -- it, the next one the frame this one's bar starts - no fixed wait.
    local fast = pileCur and pileCur.fastCast
    if fast then
        -- The move before still playing: wait for it (up to 3 s), never press into it.
        local tw = os.clock()
        while os.clock() - tw < 3 and not canCast() do RunService.Heartbeat:Wait() end
        if not canCast() then return false end
    end
    holdKey(KEYCODE[k], hold, before)
    local c = cdOf(u.name, k)
    c.lastCast = os.clock()
    stats.casts += 1
    actions += 1
    -- DID IT START (user, 2026-10-09: "Kitsune Z and X missed, only C and F"):
    -- a long move's bar starts only when it ENDS, so "no bar yet" read as
    -- refused and the key was put aside. The game marks a move it took at
    -- once - the tool's Holding / the character's Busy (the decompiled
    -- casFunc) - so that counts as fired too.
    local started = false
    if fast then
        local tf = os.clock()
        repeat
            RunService.Heartbeat:Wait()
            if not canCast() then started = true end
        until started or barReady(u.name, k) == false or os.clock() - tf > 0.4
    else
        local tf = os.clock()
        repeat
            RunService.Heartbeat:Wait()
            if not canCast() then started = true end
        until os.clock() - tf >= (CFG.CastWait or 0.45)
    end
    aimUntil = 0
    -- Did it fire (its bar is cooling now)? Did it hit (the pile lost HP)?
    local lost = 0
    for e, hp in pairs(snap) do
        local now = e.hum.Parent and math.max(e.hum.Health, 0) or 0
        lost += math.max(hp - now, 0)
    end
    local hit = lost > 0.5
    local key = u.name .. " " .. k
    local tally = P.skillTally[key] or { cast = 0, fired = 0, hit = 0 }
    P.skillTally[key] = tally
    tally.cast += 1
    if hit then stats.castsHit += 1 tally.hit += 1 end
    local b = barReady(u.name, k)
    local tail = hit and string.format(", hit the pile (-%.0f HP)", lost) or ", MISSED the pile"
    if b == true and started then
        stats.castsTook += 1
        tally.fired += 1
        P.lastCast = key .. ": fired (a long move - its bar starts when it ends)" .. tail
    elseif b == false then
        stats.castsTook += 1
        tally.fired += 1
        P.lastCast = key .. ": fired" .. tail
    elseif b == true then
        stats.castsMissed += 1
        -- A sea event's fight: tried again in 3 s (it may only have been too early).
        c.deadUntil = os.clock() + (fast and 3 or 60)
        P.lastCast = key .. ": key sent, the skill did NOT fire - left " .. (fast and "3 s" or "1 min")
    else
        P.lastCast = key .. ": key sent (no bar to check)" .. tail
    end
    return true
end

local function attackTick()
    local used = usedWeapons()
    if #used == 0 then
        say("nothing switched on - Attack page")
        task.wait(0.3)
        return
    end
    local m1u, anySkill = nil, false
    for _, u in ipairs(used) do
        if u.cfg.M1 and not m1u then m1u = u end
        for _, k in ipairs(KEYS) do if u.cfg[k] then anySkill = true end end
    end
    -- Your M1 pick, else a sword first (P.m1Of, WEAPON ROTATION). A sword
    -- that swings M1 is never swapped out by the rotation (P.keepSword).
    local m1Of = (P :: any).m1Of
    if m1Of then m1u = m1Of(used) end
    -- A fight that swings no M1 at all (SEA EVENTS out of Kitsune form, user
    -- 2026-10-09) - whatever the Attack page, your M1 pick or the mastery say.
    if pileCur and pileCur.noM1 and pileCur.noM1() then m1u = nil end
    P.m1Now = m1u and m1u.name or nil
    if m1u and m1u.tool and toolType(m1u.tool) == "Sword" then P.keepSword = m1u.name end

    -- A held gun (THE GUN) heats while it fires and cools while it does
    -- not, at the same rate - so the time a skill takes costs it no shots
    -- at all. Skills whenever ready, the gun held in between. Past the heat
    -- the same: nothing to wait for.
    local between = CFG.M1Between or 0
    local gi = m1u and m1u.tool and (P :: any).gunInfo and (P :: any).gunInfo(m1u.tool)
    if gi and ((gi.gatling and CFG.GunHold) or CFG.GunFast) then between = 0 end
    -- A sea event: every skill the moment it is ready, M1 in the gaps.
    if pileCur and pileCur.allKeys then between = 0 end

    if anySkill and (not m1u or m1Count >= between) then
        for _, u in ipairs(used) do
            for _, k in ipairs(KEYS) do
                if u.cfg[k] and skillReady(u.name, k) then
                    P.nextNote = u.name .. " " .. k
                    if castSkill(u, k) then
                        m1Count = 0
                        return
                    end
                end
            end
        end
        -- Every carried skill cooling: a rested sword / gun from your inventory.
        local rot = (P :: any).rotate
        if rot and rot(false) then return end
        if not m1u then
            P.nextNote = "every skill cooling"
            task.wait(0.1)
            return
        end
    end

    if m1u then
        if not equip(m1u.name) then task.wait(0.1) return end
        local way = m1Plan[m1u.name]
        if m1Due(m1u.name) then
            way = probeM1(m1u.name, m1u.tool)
            if way == nil then return end
        end
        if way then
            if CFG.HeightMode ~= "fixed" then setPose(way.pose) end
            P.nextNote = anySkill
                and string.format("%s M1  %d/%d before the next skill", m1u.name,
                    m1Count, CFG.M1Between or 0)
                or (m1u.name .. " M1")
            fireM1(way, m1u.tool)
            m1Count += 1
            task.wait(math.max(CFG.M1Every or 0.06, 0.03))
        else
            -- No way of landing this weapon's M1: let the skills carry it.
            m1Count = CFG.M1Between or 0
            P.nextNote = "no M1 lands with " .. m1u.name
            task.wait(0.1)
        end
    end
end

-- =========================================================
-- WHICH SETUP IS BETTER: MEASURED
-- =========================================================
-- Kills per minute of FIGHTING (flying and quest-taking left out, so a setup
-- is not punished for a long flight), and how long a pile takes to clear.
-- Change any attack switch or the M1 count and the old setup is filed under
-- "tried" with its numbers; a fresh count starts.
local meas  = nil
local tried = {}
P.tried = tried

local function setupKey()
    local bits, anyM1, anyKey, anyGun = {}, false, false, false
    for _, name in ipairs(CFG.WeaponOrder) do
        local w = CFG.Weapons[name]
        if w and w.use then
            local s = wSummary(name)
            if s ~= "off" then table.insert(bits, name .. " " .. s) end
            if w.M1 then anyM1 = true end
            for _, k in ipairs(KEYS) do if w[k] then anyKey = true end end
            if w.M1 and toolType(findTool(name)) == "Gun" then anyGun = true end
        end
    end
    -- The mastery farm is its own setup, and a gun's way of firing is part
    -- of one (held vs past the heat: kills per minute side by side).
    local mw = CFG.MasteryWeapon or ""
    if mw ~= "" then anyGun = toolType(findTool(mw)) == "Gun" end
    local gun = not anyGun and ""
        or CFG.GunFast and string.format(",  gun past the heat %.2f s", CFG.GunFastEvery or 0.08)
        or (CFG.GunHold and ",  gun held" or ",  gun clicked")
    if mw ~= "" then return "mastery: " .. mw .. gun end
    if #bits == 0 then return "nothing on" end
    local key = table.concat(bits, "  +  ")
    if anyM1 and anyKey then
        key = key .. string.format(",  %d M1 between, %s first", CFG.M1Between or 0,
            CFG.StartWith == "M1" and "M1" or "skills")
    end
    return key .. gun
end
P.setupKey = setupKey

local function newMeas()
    meas = { key = setupKey(), kills = 0, fight = 0, piles = 0, pileSecs = 0 }
end

local function rollMeas()
    if meas and meas.fight >= 5 then
        table.insert(tried, 1, {
            key  = meas.key,
            kpm  = meas.kills / (meas.fight / 60),
            avg  = (meas.piles > 0) and (meas.pileSecs / meas.piles) or nil,
            secs = meas.fight,
        })
        while #tried > 6 do table.remove(tried) end
    end
    newMeas()
end
newMeas()

function P.measure() return meas end

local function recordPile(secs)
    if meas then
        meas.piles += 1
        meas.pileSecs += secs
    end
end

-- =========================================================
-- THE GUN: HELD LIKE A PLAYER
-- =========================================================
-- How a gun fires, read in the game's own client (decompiled v4623:
-- CombatController, WeaponToolClient, HitscanSingleShot; 2026-10-07):
--   * A click is UserInputService.InputBegan MouseButton1 -> Attack(tool,
--     input). A Gatling gun (Dragonstorm) then fires every 0.08 s for as
--     long as THAT input has not ended - the button held.
--   * Heat: +1 a second while it fires, -1 a second while it does not; at
--     3 it locks for 1 s. Held for good = 3 s of fire, then ~1 s on, 1 s
--     off. A skill cast in the off half costs the gun nothing.
--   * EVERY shot reads the mouse (Mouse.Hit) and casts ONE ray: one enemy a
--     shot, never the whole pile. The old way - a 0.04 s tap, the camera
--     aimed only at the instant of the click - sent the first shot of each
--     3-shot burst at the pile and the other two where your cursor was.
-- So: the button held while the gun can fire and let go when its loop
-- ends, and the silent aim on ONE enemy for every shot - the one being shot
-- while it lives, then the weakest (a kill sooner, the next one sooner).
-- PAST THE HEAT (CFG.GunFast): the game's own shot function on this
-- script's clock - the game's validator advances with it, as it would.
-- THE MASTERY FARM (CFG.MasteryWeapon): that weapon alone; the farm stops at
-- CFG.MasteryStop. Only P.gun* / P.mastery* / P.inGameShot leave the block.
do
    local function build()
        local G: { [string]: any } = {
            down = nil, downAt = 0, holdUntil = 0, focusUntil = 0, bx = 0, by = 0,
            presses = 0, locks = 0, wasLocked = false, lastShot = 0, fast = 0,
            shots0 = nil, shotsAt = 0, rate = 0, loadTry = -100,
        }
        P.gun = G
        P.gunFocus = nil
        P.inGameShot = false
        P.gunNote = "no gun fired yet"
        P.masteryNote = "off"

        -- The game's own table of every weapon (ShootStyle, OverheatLimit,
        -- Cooldown, Range). Read once; false = it cannot be read.
        local wd = nil
        local function weaponData(name)
            if wd == nil then
                local ok, m = pcall(function() return require(RS.Modules.WeaponData) end)
                wd = (ok and type(m) == "table") and m or false
            end
            if not wd then return nil end
            local d = wd[name] or wd[(string.gsub(name, "%s", ""))]
            return type(d) == "table" and d or nil
        end

        -- nil = not a gun. gatling = fires while held. custom = a way of its
        -- own (Skull Guitar's TAP): the game's shot function is not its.
        function P.gunInfo(tool)
            if not tool or toolType(tool) ~= "Gun" then return nil end
            local d = weaponData(tool.Name)
            return {
                gatling = (d and d.ShootStyle == "Gatling") or tool.Name == "Dragonstorm",
                limit   = (d and tonumber(d.OverheatLimit)) or 3,
                range   = (d and tonumber(d.Range)) or 400,
                custom  = (d and d.ShootType == "Custom") or false,
            }
        end

        -- Pure (tools/gun_test.py). The enemy every shot goes at: the one
        -- being shot while it lives and is in reach, else the weakest in
        -- reach. Its root part, or nil.
        local function pickFocus(list, cur, from, range)
            local keep, best, bestHp = false, nil, math.huge
            for _, e in ipairs(list) do
                if e.model.Parent and e.hum.Health > 0 and from
                    and (e.root.Position - from).Magnitude <= range then
                    if e.root == cur then keep = true end
                    if e.hum.Health < bestHp then best, bestHp = e.root, e.hum.Health end
                end
            end
            if keep then return cur end
            return best
        end
        G.pickFocus = pickFocus

        -- Pure (tools/gun_test.py). What the button does now: "press",
        -- "keep", "release" or "wait". down = held by this script; shooting
        -- = the game's loop is firing (IsAutoShooting); locked = overheated or
        -- not enabled; heldFor = seconds since the press.
        local function holdStep(down, shooting, locked, heat, limit, heldFor)
            if down then
                -- Its loop ended (the heat, a skill, a stun): only a NEW press
                -- starts it again.
                if not shooting and heldFor > 0.35 then return "release" end
                return "keep"
            end
            if locked or heat >= limit - 0.05 then return "wait" end
            return "press"
        end
        G.holdStep = holdStep

        -- The aim on one enemy for `secs`: the silent aim and the hidden
        -- camera both read P.gunFocus. false = nobody to shoot.
        function P.gunAimFor(secs, range)
            local _, r = parts()
            local f = pickFocus(pile, P.gunFocus, r and r.Position, range or 400)
            P.gunFocus = f
            if not f then return false end
            local now = os.clock()
            G.focusUntil = now + secs
            aimUntil = math.max(aimUntil, now + secs)
            -- In before the first shot reads the mouse, not a frame later.
            local st = (P :: any).silentTick
            if st then pcall(st, true) end
            return true
        end

        function P.gunRelease()
            if not G.down then return end
            G.down = nil
            local x, y = G.bx, G.by
            pcall(function() VIM:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
        end

        local function press(tool)
            if heldTool() ~= tool then return end
            local cam = workspace.CurrentCamera
            if not cam then return end
            -- The middle of the screen, as the click: a press on a panel's
            -- button is the button's, never the gun's.
            local vs = cam.ViewportSize
            G.bx, G.by = vs.X * 0.5, vs.Y * 0.5
            local x, y = G.bx, G.by
            pcall(function() VIM:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
            G.down, G.downAt = tool, os.clock()
            G.presses += 1
        end

        -- Shots a second, off the game's own count (LocalTotalShots).
        local function countShots(tool, now)
            local n = tonumber(tool:GetAttribute("LocalTotalShots"))
            if not n then return end
            if G.shots0 == nil or now - G.shotsAt > 3 then
                G.shots0, G.shotsAt = n, now
            elseif now - G.shotsAt >= 1 then
                G.rate = (n - G.shots0) / (now - G.shotsAt)
                G.shots0, G.shotsAt = n, now
            end
        end

        local function focusText()
            local f = P.gunFocus
            local m = f and f.Parent
            local h = m and m:FindFirstChildOfClass("Humanoid")
            if not h then return "nobody" end
            return string.format("%s %.0f HP", m.Name, h.Health)
        end

        -- One M1 tick of a gun that fires while held: the button pressed when
        -- it can fire, kept while the game's loop fires, let go when it ends.
        function P.gunHoldTick(tool)
            local gi = P.gunInfo(tool)
            if not gi then return false end
            local now = os.clock()
            if not P.gunAimFor(0.45, gi.range) then
                P.gunRelease()
                P.gunNote = tool.Name .. ": nobody in reach"
                return false
            end
            G.holdUntil = now + 0.45
            if G.down and G.down ~= tool then P.gunRelease() end
            local heat = tonumber(tool:GetAttribute("LocalOverheat")) or 0
            local shooting = tool:GetAttribute("IsAutoShooting") == true
            local locked = (not tool.Enabled) or tool:GetAttribute("IsReloading_Client") == true
            if locked and not G.wasLocked then G.locks += 1 end
            G.wasLocked = locked
            local act = holdStep(G.down ~= nil, shooting, locked, heat, gi.limit, now - G.downAt)
            if act == "release" then
                P.gunRelease()
            elseif act == "press" then
                press(tool)
            end
            countShots(tool, now)
            P.gunNote = string.format("%s held  ·  %s  ·  %.1f shots/s  ·  heat %.1f of %g%s\nat %s  ·  pressed %d  ·  overheated %d",
                tool.Name, act, G.rate, heat, gi.limit, locked and "  LOCKED" or "",
                focusText(), G.presses, G.locks)
            return true
        end

        -- THE GAME'S OWN SHOT: the function CombatController.Attack calls for
        -- every shot - found among Attack's upvalues as the one whose own
        -- upvalues hold the mouse and the validator's numbers. Looked for
        -- again every 10 s while missing.
        local shotFn, shotAt = nil, -1e9
        P.gunShotWhy = "not looked for yet"
        function P.gunShotFn()
            if shotFn then return shotFn end
            if os.clock() - shotAt < 10 then return nil end
            shotAt = os.clock()
            local gu = (debug and (debug :: any).getupvalues) or getupvalues
            if type(gu) ~= "function" then
                P.gunShotWhy = "this executor has no getupvalues"
                return nil
            end
            local okC, cc = pcall(function() return require(RS.Controllers.CombatController) end)
            if not okC or type(cc) ~= "table" or type(cc.Attack) ~= "function" then
                P.gunShotWhy = "the game's CombatController cannot be read"
                return nil
            end
            local okU, ups = pcall(gu, cc.Attack)
            for _, f in pairs((okU and type(ups) == "table") and ups or {}) do
                if type(f) == "function" then
                    local okF, inner = pcall(gu, f)
                    if okF and type(inner) == "table" then
                        local hasMouse, nums = false, 0
                        for _, u in pairs(inner) do
                            if typeof(u) == "Instance" and u:IsA("PlayerMouse") then
                                hasMouse = true
                            elseif type(u) == "number" then
                                nums += 1
                            end
                        end
                        if hasMouse and nums >= 4 then
                            shotFn = f
                            break
                        end
                    end
                end
            end
            P.gunShotWhy = shotFn and "the game's own shot - found" or "the game's shot function not found"
            print("[BFF] gun: " .. P.gunShotWhy)
            return shotFn
        end

        -- One M1 tick past the heat: as many of the game's own shots as
        -- GunFastEvery allows since the last (4 at most), each at the enemy.
        local FAKE_CLICK = { UserInputType = Enum.UserInputType.MouseButton1 }
        function P.gunShotTick(tool)
            local f = P.gunShotFn()
            local gi = P.gunInfo(tool)
            if not (f and gi) then return false end
            if not P.gunAimFor(0.45, gi.range) then
                P.gunNote = tool.Name .. ": nobody in reach"
                return false
            end
            local now = os.clock()
            local every = math.max(tonumber(CFG.GunFastEvery) or 0.08, 0.01)
            local n = math.min(math.floor((now - G.lastShot) / every), 4)
            if n < 1 then return true end
            G.lastShot = now
            P.inGameShot = true
            for _ = 1, n do
                pcall(f, tool, FAKE_CLICK)
                G.fast += 1
            end
            P.inGameShot = false
            countShots(tool, now)
            P.gunNote = string.format("%s past the heat  ·  %.1f shots/s  ·  the server's heat %s\nat %s  ·  %d shots",
                tool.Name, G.rate, tostring(tool:GetAttribute("Overheat") or "-"), focusText(), G.fast)
            return true
        end

        -- Every frame: the button let go and the aim off once the fight stops
        -- calling (a death, a weapon swap, the pile done, the stop).
        function P.gunWatch()
            local now = os.clock()
            if G.down and (not P.running or not attacking or now > G.holdUntil
                or heldTool() ~= G.down) then
                P.gunRelease()
            end
            if P.gunFocus and now > G.focusUntil then P.gunFocus = nil end
        end

        -- ---------- the mastery farm ----------
        -- A weapon's mastery: its tool's Level, else your inventory's.
        function P.masteryOf(name)
            local t = findTool(name)
            local lv = t and t:FindFirstChild("Level")
            local v = lv and tonumber(lv.Value)
            if v then return v end
            local has = (P :: any).invHas
            if has then pcall(has, name) end
            local R = (P :: any).rot
            for _, it in ipairs(R and R.inv or {}) do
                if it.name == name then return it.mastery end
            end
            return nil
        end

        -- usedWeapons() asks first: the mastery weapon alone, {} while it is
        -- being loaded, nil = the farm is off.
        function P.masteryUsed()
            local name = CFG.MasteryWeapon
            if type(name) ~= "string" or name == "" then return nil end
            local tool = findTool(name)
            if not tool then return {} end
            local keys = CFG.AutoKeys or {}
            local w = wcfg(name)
            return { { name = name, tool = tool, cfg = {
                use = true, M1 = true, hold = w.hold, F = false,
                Z = keys.Z == true, X = keys.X == true, C = keys.C == true, V = keys.V == true,
            } } }
        end

        -- Once a second (the side loop): not carried = loaded from your
        -- inventory (every 10 s at most); its mastery read; the stop.
        function P.masteryTick()
            local name = CFG.MasteryWeapon
            if type(name) ~= "string" or name == "" then
                P.masteryNote = "off"
                return
            end
            local now = os.clock()
            if not findTool(name) then
                if now - G.loadTry > 10 then
                    G.loadTry = now
                    local has, load = (P :: any).invHas, (P :: any).loadItem
                    if has and load and has(name) then
                        P.masteryNote = name .. ": not carried - loading it from your inventory"
                        task.spawn(function() pcall(load, name) end)
                    else
                        P.masteryNote = name .. ": not carried, and not in your inventory"
                    end
                end
                return
            end
            local m = P.masteryOf(name)
            local stopAt = tonumber(CFG.MasteryStop) or 0
            P.masteryNote = string.format("%s  mastery %s%s", name, m and tostring(m) or "not readable",
                (stopAt > 0) and ("  ·  stops at " .. stopAt) or "")
            if stopAt > 0 and m and m >= stopAt and P.running then
                local text = string.format("%s reached %d mastery - the farm stopped", name, m)
                P.masteryNote = text
                print("[BFF] " .. text)
                say(text)
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "Fast Farm", Text = text, Duration = 30,
                    })
                end)
                task.spawn(function() pcall(P.stop) end)
            end
        end
    end
    build()
end

-- =========================================================
-- HAKI, AND WHAT A DEATH TAKES WITH IT
-- =========================================================
-- Dying drops the tool, turns Enhancement (J) off and turns Observation (E)
-- off. In the Third Sea the swing does not land without Enhancement, so a
-- respawn without it walks back to the camp and dies again.
--
-- Enhancement can be CHECKED: the character carries a child named HasBuso
-- while it is on. So it is re-asserted whenever it is missing, capped at
-- three presses per life so a wrong marker name can never become a toggle
-- war.
-- OBSERVATION CAN BE READ AFTER ALL. While it is on, the game shows its dodge
-- counter, and that counter is an ImageLabel directly under
-- PlayerGui.ScreenGui -- the same check the public hubs use for their own
-- auto-Ken. Present = on, gone = off. E is a toggle, so it is pressed ONLY
-- when the counter is gone: a press can never turn an on Observation off.
-- It is looked at after every death and every KenEvery seconds (5 minutes).
--
-- The marker is trusted once it has been seen. Until then, a press that does
-- not make it appear is a miss; two misses in a row (two presses, so E is
-- left where it started) and the timed check stops pressing and says so on
-- the panel. A new life still gets its one press either way: a death always
-- turns Observation off, so that press is safe with or without a marker.
P.busoOK   = false
P.kenDone  = false
local kenChar     = nil    -- the life E has been checked for
local seenChar    = nil
local seenCharAt  = 0
local busoTries   = 0
local lastBusoAt  = 0
local kenNextAt   = 0      -- next timed look
local kenVerifyAt = nil    -- a press is waiting to be checked at this time
local kenSeen     = false  -- the marker has been seen: it is real
local kenMisses   = 0
local kenBlind    = false  -- marker never seen and two presses missed
P.kenNote = "not checked yet"

local function hasBuso()
    local char = player.Character
    return char ~= nil and char:FindFirstChild("HasBuso") ~= nil
end
P.hasBuso = hasBuso

-- true = on, false = off, nil = cannot tell (no ScreenGui to look in).
local function kenOn()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    local sg = pg and pg:FindFirstChild("ScreenGui")
    if not sg then return nil end
    return sg:FindFirstChild("ImageLabel") ~= nil
end
P.kenOn = kenOn
P.kenNextIn = function() return math.max(0, kenNextAt - os.clock()) end

local function keepHaki()
    local char, root, hum = parts()
    if not char or not root or not hum then return end
    if char ~= seenChar then
        seenChar, seenCharAt = char, os.clock()
        busoTries = 0
    end
    if os.clock() - seenCharAt < 1.5 then return end   -- let the spawn settle

    if CFG.AutoBuso then
        if hasBuso() then
            P.busoOK = true
        else
            P.busoOK = false
            if busoTries < 3 and os.clock() - lastBusoAt > 2.5 then
                lastBusoAt = os.clock()
                busoTries += 1
                stats.hakiPresses += 1
                pressKey(Enum.KeyCode.J)
                say("enhancement off - pressing J")
            end
        end
    end

    if not CFG.AutoKen or CFG.RaidMode then return end   -- raids switch Observation off
    local now = os.clock()
    local on  = kenOn()
    if on then kenSeen, kenBlind, kenMisses = true, false, 0 end

    -- The last press: did the counter come up?
    if kenVerifyAt and now >= kenVerifyAt then
        kenVerifyAt = nil
        if on then
            P.kenNote = "ON - E worked, dodge counter showing"
        elseif on == false then
            -- Out of dodges puts Observation on a cooldown and E does nothing
            -- until it ends; or the marker is wrong. Look again soon.
            kenMisses += 1
            kenNextAt = now + 20
            if not kenSeen and kenMisses >= 2 then
                kenBlind = true
                P.kenNote = "E pressed twice, dodge counter never appeared - "
                    .. "timed check paused (a death still gets its one press)"
            else
                P.kenNote = "E pressed, counter not up yet - trying again in 20s"
            end
        end
    end
    if kenVerifyAt then return end

    local newLife = (kenChar ~= char)
    if not newLife and now < kenNextAt then return end

    -- A new life waits until the character has proved it takes input (the
    -- Enhancement press landed). A timed look on a settled life does not.
    if newLife then
        local ready
        if CFG.AutoBuso then
            ready = hasBuso()
        else
            ready = (now - seenCharAt) > 3
        end
        if not ready then return end
    end
    kenChar   = char
    kenNextAt = now + math.max(30, CFG.KenEvery or 300)
    P.kenDone = true

    if on then
        P.kenNote = "ON - checked, left alone"
        return
    end
    if on == false and kenBlind and not newLife then
        P.kenNote = "counter not showing, but the marker is unproven - not pressing"
        return
    end
    if on == nil and not newLife then
        P.kenNote = "cannot see PlayerGui.ScreenGui - timed check skipped"
        return
    end
    stats.hakiPresses += 1
    pressKey(Enum.KeyCode.E)
    say("observation off - pressing E")
    P.kenNote = "OFF - pressed E, checking"
    if on ~= nil then kenVerifyAt = now + 2.5 end
end


-- =========================================================
-- WALK ON WATER
-- =========================================================
-- The sea in Blox Fruits is one slab, workspace.Map["WaterBase-Plane"], and it
-- is the FLOOR you stand on in the sea: it sits under the surface, so standing
-- on it means standing in water, which is what hurts a fruit user, and it is
-- why getting out means climbing an island edge from below. Make the slab
-- taller (Size.Y 80 -> 112) and its top comes up to the surface: you run ON
-- the water. No damage, and no edge to climb, because you never went down.
-- The public hubs all do exactly this, and one re-applies it every tenth of a
-- second, so the game evidently puts it back; it is kept here the same way.
-- It is your client's copy of the slab. Nobody else's sea changes.
-- ALWAYS ON, no switch: you never want water damage, so water is land.
local keepWater
do
    local WATER_Y = 112          -- raised: the top is at the surface (the game's is 80)
    P.waterNote = "not looked yet"
    P.waterSets = 0

    function keepWater()
        local map = workspace:FindFirstChild("Map")
        local wp = map and map:FindFirstChild("WaterBase-Plane")
        if not (wp and wp:IsA("BasePart")) then
            P.waterNote = "no WaterBase-Plane in workspace.Map here"
            return
        end
        if math.abs(wp.Size.Y - WATER_Y) > 0.5 then
            wp.Size = Vector3.new(wp.Size.X, WATER_Y, wp.Size.Z)
            P.waterSets += 1
        end
        P.waterNote = "solid - standing on the surface"
    end

    -- ---------------------------------------------------------
    -- THE DEEP SEA: SUBMERGED ISLAND
    -- ---------------------------------------------------------
    -- Submerged Island is not ON the sea, it is at the BOTTOM of it: about
    -- 1900-2200 studs below sea level, reached only by the submarine at Tiki
    -- Outpost, with a sea of its own round it. The slab raised above is the one
    -- at sea level, nowhere near there -- which is why water was land on every
    -- island from Port Town to the Sea of Treats and not on this one.
    --
    -- Nothing public says what that deep sea is made of, so all three things a
    -- Roblox sea can be are handled -- and ONLY down there (below DEEP_Y), so no
    -- other island is touched:
    --   * its own floor slab like the one at sea level (a part named WaterBase):
    --     raised the same way, 32 taller, so its top comes up 16;
    --   * terrain water: the surface is read from the voxels under you;
    --   * a see-through water part you sink into: its top.
    -- For the last two an invisible floor is kept at the surface, under your
    -- feet, following you every frame; if you are already under the surface you
    -- are lifted onto it. The panel says which one it found.
end

local parkFloor, deepTick
do
    local DEEP_Y = -1000
    local deepNote = "not down there"
    local deepSurf, deepSurfAt, deepLiftAt = nil, 0, 0
    local slabOrig = {}
    P.deepLifts = 0
    P.deepNote = function() return deepNote end

    local function deepExcl()
        local excl = {}
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl.Character then table.insert(excl, pl.Character) end
        end
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then table.insert(excl, enemies) end
        if waterFloor then table.insert(excl, waterFloor) end
        return excl
    end

    -- The highest terrain water in this column between yLo and yHi, or nil; and
    -- whether it reached the very top of the window (the surface is higher).
    local function terrainWaterTop(x, z, yLo, yHi)
        local region = Region3.new(Vector3.new(x - 2, yLo, z - 2),
            Vector3.new(x + 2, yHi, z + 2)):ExpandToGrid(4)
        local mats, occs = workspace.Terrain:ReadVoxels(region, 4)
        local sz = mats.Size
        local minY = region.CFrame.Position.Y - region.Size.Y / 2
        for iy = sz.Y, 1, -1 do
            for ix = 1, sz.X do
                for iz = 1, sz.Z do
                    if mats[ix][iy][iz] == Enum.Material.Water then
                        return minY + (iy - 1) * 4 + 4 * math.min(1, occs[ix][iy][iz] or 1),
                            iy == sz.Y
                    end
                end
            end
        end
        return nil
    end

    -- Water parts in this column: the top of the highest one you would sink into
    -- (not collidable, named water or made of water), and any floor slab named
    -- WaterBase.
    local function partWater(pos, yLo, yHi)
        local op = OverlapParams.new()
        op.FilterType = Enum.RaycastFilterType.Exclude
        op.FilterDescendantsInstances = deepExcl()
        op.RespectCanCollide = false
        local hits = workspace:GetPartBoundsInBox(CFrame.new(pos.X, (yLo + yHi) / 2, pos.Z),
            Vector3.new(4, yHi - yLo, 4), op)
        local top, slab = nil, nil
        for _, part in ipairs(hits) do
            local n = string.lower(part.Name)
            if string.find(n, "waterbase", 1, true) then
                slab = slab or part
            elseif not part.CanCollide and (string.find(n, "water", 1, true)
                or part.Material == Enum.Material.Water) then
                local t = part.Position.Y + part.Size.Y / 2
                if t <= yHi and (not top or t > top) then top = t end
            end
        end
        return top, slab
    end

    function parkFloor()
        if waterFloor and waterFloor.Parent then waterFloor.Parent = nil end
    end

    function deepTick()
        -- While the farm runs the body is held by the lock; a lift here
        -- would fight it. Manual play still gets the deep-sea floor.
        if P.running then parkFloor() return end
        local _, r, h = parts()
        if not r or not h then parkFloor() return end
        local pos, now = r.Position, os.clock()
        if pos.Y > DEEP_Y then
            parkFloor()
            deepSurf, deepNote = nil, "not down there"
            return
        end

        -- Read the surface ten times a second; follow it every frame.
        if now - deepSurfAt > 0.1 then
            deepSurfAt = now
            local yLo, yHi = pos.Y - 60, pos.Y + 12
            local okT, tw, capped = pcall(terrainWaterTop, pos.X, pos.Z, yLo, yHi)
            if not okT then tw, capped = nil, false end
            -- Deep under: the water fills the window to its top, so the surface
            -- is higher still. Look further up, 64 studs at a time. Still water
            -- 256 up is the ocean itself, not a sea to stand on: no floor.
            local climbs = 0
            while tw and capped and climbs < 4 do
                climbs += 1
                local ok2, t2, c2 = pcall(terrainWaterTop, pos.X, pos.Z, tw - 4, tw + 64)
                if not ok2 or not t2 then break end
                tw, capped = t2, c2
            end
            if tw and capped then tw = nil end
            local okP, pw, slab = pcall(partWater, pos, yLo, yHi)
            if not okP then pw, slab = nil, nil end
            if slab then
                local o = slabOrig[slab] or slab.Size.Y
                slabOrig[slab] = o
                if math.abs(slab.Size.Y - (o + 32)) > 0.5 then
                    slab.Size = Vector3.new(slab.Size.X, o + 32, slab.Size.Z)
                end
            end
            deepSurf = tw or pw
            if tw and pw then deepSurf = math.max(tw, pw) end
            if deepSurf then
                deepNote = string.format("%s at Y %.0f - standing on it",
                    tw and "terrain water" or ("water part"), deepSurf)
            elseif slab then
                deepNote = "deep floor slab '" .. slab.Name .. "' raised"
            else
                deepNote = "no water under you here"
            end
        end
        if not deepSurf then parkFloor() return end

        if not waterFloor then
            local f = Instance.new("Part")
            f.Name = "BFP_WaterFloor"
            f.Anchored, f.CanCollide, f.CanTouch = true, true, false
            f.Transparency = 1
            f.Size = Vector3.new(24, 1, 24)
            waterFloor = f
        end
        waterFloor.CFrame = CFrame.new(pos.X, deepSurf - 0.5, pos.Z)
        if waterFloor.Parent ~= workspace then waterFloor.Parent = workspace end

        -- Under the surface already: up onto it.
        local feet = pos.Y - (h.HipHeight + r.Size.Y / 2)
        if feet < deepSurf - 0.75 and deepSurf - feet < 300 and now - deepLiftAt > 0.4 then
            deepLiftAt = now
            r.CFrame = r.CFrame + Vector3.new(0, deepSurf - feet + 0.2, 0)
            local v = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, 0), v.Z)
            P.deepLifts += 1
        end
    end
end


-- =========================================================
-- THE CIRCUIT: THE SPECIES ON THE TARGETS PAGE
-- =========================================================
-- No quests (removed 2026-09-28 - max level; git tag quest-engine-2026-09-28
-- has them): each species' camp is piled and killed, then the next one;
-- alone on the circuit, it waits for the respawn.
P.circuitNote = ""
local function circuit()
    local names = CFG.Targets
    if #names == 0 then
        local row = levelRow()
        names = row and { row[3] } or {}
    end
    local sea = mySea()
    local out, skipped = {}, {}
    for _, n in ipairs(names) do
        local row, lv = rowOf(n), levelOf(n)
        if lv and sea and seaOfLevel(lv) ~= sea then
            table.insert(skipped, n)
        else
            table.insert(out, { name = n, spot = row and row[4] or (BOSS[n] and BOSS[n].spot) or nil })
        end
    end
    P.circuitSkipped = skipped
    if #out == 0 then
        P.circuitNote = (#skipped > 0)
            and ("every picked species lives in another sea: " .. table.concat(skipped, ", "))
            or "pick species on Targets"
    else
        P.circuitNote = ""
    end
    return out
end
P.circuit = circuit

local function advance(list)
    circuitIdx = (#list > 0) and (circuitIdx % #list + 1) or 1
end

function P.toggleTarget(name)
    for i, n in ipairs(CFG.Targets) do
        if n == name then
            table.remove(CFG.Targets, i)
            if circuitIdx > math.max(#CFG.Targets, 1) then circuitIdx = 1 end
            say("off the circuit: " .. name)
            return false
        end
    end
    table.insert(CFG.Targets, name)
    say("on the circuit: " .. name)
    return true
end

function P.clearTargets()
    table.clear(CFG.Targets)
    circuitIdx = 1
    say("circuit cleared - the species for your level")
end

local function onKill(name)
    stats.kills += 1
    if meas then meas.kills += 1 end
end

-- ---------------------------------------------------------
-- THE FIGHT AT ONE CAMP
-- ---------------------------------------------------------
-- Pile, lock, hit, count -- until the camp is empty, you are hurt, or thirty
-- seconds pass (then the next step looks again).
local function fight(cur, names)
    local myEpoch = epoch
    setState("FIGHT")
    pileCur, pileNames = cur, names
    local pileStart = nil
    local lastHaki = 0
    local sweepEnd = os.clock() + 30
    m1Count = (CFG.StartWith == "M1") and 0 or (CFG.M1Between or 0)

    while P.running and not stale(myEpoch) and os.clock() < sweepEnd do
        if healthPct() < (CFG.EscapeBelow or 0.35) then
            attacking = false
            return "hurt"
        end
        local now = os.clock()

        for m, hum in pairs(pileWatch) do
            local dead = hum.Health <= 0
            if dead or not m.Parent then
                if dead and not countedDead[m] then
                    countedDead[m] = now
                    onKill(cleanName(m))
                end
                pileWatch[m] = nil
                -- If the game re-uses this model for the next spawn, it starts
                -- fresh: its own spawn spot, and a new no-damage clock.
                homePos[m], pileJoin[m], lastDest[m] = nil, nil, nil
            end
        end

        if now - pileScanAt > 0.1 then refreshPile() end

        if #pile == 0 then
            if pileStart then recordPile(now - pileStart) end
            attacking = false
            return "empty"
        end
        if not pileStart then
            pileStart = now
            stats.piles += 1
            say(string.format("%s - pile of %d", cur.name, #pile))
        end
        if now - lastHaki > 1 then
            lastHaki = now
            pcall(keepHaki)
        end

        -- THE HUNT: the elite hunt switched off, or another hunt picked:
        -- this fight ends now, not at the end of its 30 s.
        if cur.elite and not (CFG.Hunt and CFG.HuntKind == "elite") then
            attacking = false
            return "preempt"
        end
        -- A hunt's own reason to stop now (the Fire Flower hunt: a flower
        -- lies there, or this server has had its time).
        if cur.breakIf and cur.breakIf() then
            attacking = false
            return "break"
        end

        pileActive = true
        attacking  = true
        applyPose()
        attackTick()
        checkPutBack()
    end
    attacking = false
    return "sweep"
end

local function waitRespawn(cur, names)
    local myEpoch = epoch
    setState("WAIT")
    local t0 = os.clock()
    while P.running and not stale(myEpoch) and os.clock() - t0 < (CFG.RespawnMax or 45) do
        say(string.format("waiting for %s to respawn  %.0fs", cur.name, os.clock() - t0))
        if healthPct() < (CFG.EscapeBelow or 0.35) then return true end
        if #buildPile(cur, names) > 0 then return true end
        task.wait(0.1)
    end
    return false
end

-- ---------------------------------------------------------
-- ESCAPE
-- ---------------------------------------------------------
-- Straight up out of everyone's reach, the pile let go, and wait there for
-- the health to come back. The next step flies back down to the camp.
local function escape()
    stats.escapes += 1
    setState("ESCAPE")
    releasePile()
    releaseCamera()
    local _, r = parts()
    if not r then return end
    say(string.format("HP %.0f%% - up out of reach", healthPct() * 100))
    flyTo(r.Position + Vector3.new(0, 250, 0))
    local myEpoch, t0 = epoch, os.clock()
    while P.running and not stale(myEpoch) and os.clock() - t0 < 40 do
        local _, r2 = parts()
        if not r2 then break end
        if healthPct() >= (CFG.ReturnAt or 0.8) then break end
        say(string.format("recovering  HP %.0f%%", healthPct() * 100))
        task.wait(0.25)
    end
end

-- =========================================================
-- RAID MODE
-- =========================================================
-- A fruit raid: five islands, each a wave of enemies of every kind; clear one
-- and the next opens. The game shows it (the public raid scripts, 2025-07 and
-- 2026-08): a raid timer on screen -- PlayerGui.Main.TopHUDList.RaidTimer,
-- older builds Main.Timer -- and each island that has opened is a part in
-- workspace._WorldOrigin.Locations named "Island 1" .. "Island 5". So: the
-- newest island there is where the fight is; nobody left near it = wait over
-- it for the wave, or for the next island to open.
-- The user, 2026-10-10: the raid over (the game puts you back at the Castle
-- on the Sea), it flew off to the raid's islands - their markers stay. Now a
-- marker counts within RaidReach of you (any distance only while the timer
-- is up), and OUTSIDE A RAID nothing is fought and you stay put; with the
-- loop on, a chip and the button (Map["Boat Castle"].RaidSummon2) start the
-- next one. And the last island's last enemies "stuck, not killing": the
-- stuck watch relocates (RaidStuckSecs).
local raidStep, randomStep
do
    local function raidState()
        local pg   = player:FindFirstChild("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        local hud  = main and main:FindFirstChild("TopHUDList")
        local t = (hud and hud:FindFirstChild("RaidTimer")) or (main and main:FindFirstChild("Timer"))
        local on = t ~= nil and t:IsA("GuiObject") and t.Visible
        local text
        if on then
            local l = t:IsA("TextLabel") and t or t:FindFirstChildWhichIsA("TextLabel", true)
            text = l and l.Text or nil
        end
        local wo  = workspace:FindFirstChild("_WorldOrigin")
        local loc = wo and wo:FindFirstChild("Locations")
        if loc then
            -- STALE ISLANDS (user, 2026-10-10): the newest within RaidReach
            -- of you; one only farther counts while the timer is up (a raid's
            -- islands left behind after it ended are not a raid).
            local _, r = parts()
            local reach = tonumber(CFG.RaidReach) or 2500
            local far, farN = nil, 0
            for i = 5, 1, -1 do
                local p = loc:FindFirstChild("Island " .. i)
                local pos = p and ((p:IsA("BasePart") and p.Position) or (p:IsA("Model") and p:GetPivot().Position))
                if pos then
                    if not r or (pos - r.Position).Magnitude <= reach then return on, pos, i, text end
                    if not far then far, farN = pos, i end
                end
            end
            if on and far then return on, far, farN, text end
        end
        return on, nil, 0, text
    end
    P.raidState = raidState

    -- The raid's life, the stuck watch and the loop: a function of their own
    -- (the main chunk is at Luau's register limit). Only P.raid leaves it.
    local function build()
        -- inside: in a raid now; done: raids over this session; n: the newest
        -- island this raid; prog: the stuck watch's last progress; streak:
        -- relocations since the last kill.
        local RD = { inside = false, done = 0, n = 0, overAt = nil, prog = nil, moves = 0, streak = 0,
            checkAt = 0, note = nil }
        -- The loop: tries since the last raid began, when it may try again, what it says.
        local RL = { nextAt = 0, tries = 0, note = "-", chips = 0, presses = 0, paid = nil }
        RD.loop = RL
        P.raid = RD

        -- ---------- THE STUCK FIGHT ----------
        -- Every live enemy within RaidStuckReach of `at`, skipped or not.
        local function wideList(at)
            local out = {}
            local reach = tonumber(CFG.RaidStuckReach) or 1500
            for _, e in ipairs(liveEnemies(nil)) do
                if (e.root.Position - at).Magnitude <= reach then table.insert(out, e) end
            end
            return out
        end
        -- Pure (tools/raidloop_test.py): where relocation k stands round
        -- `pos` - 1 straight over it, close; then round it, 120 deg apart.
        local function spotFor(pos, k)
            local i = (math.max(k, 1) - 1) % 4
            if i == 0 then return pos + Vector3.new(0, 8, 0) end
            local a = math.rad((i - 1) * 120)
            return pos + Vector3.new(math.cos(a) * 14, 5, math.sin(a) * 14)
        end
        -- Progress = a kill, HP off any of them, or how many changed (a wave
        -- came, one left). None for RaidStuckSecs while some are alive =
        -- RELOCATE: the nearest one is THE target (P.raidFocus, fought where
        -- it stands, buildRaidPile), every skip forgotten, a new spot
        -- (spotFor), the pile let go. true = it relocated now.
        local function watch(list, n)
            local now = os.clock()
            local hp = 0
            for _, e in ipairs(list) do hp += e.hum.Health end
            local p = RD.prog
            if not p or #list == 0 or #list ~= p.n or stats.kills ~= p.kills or hp < p.hp - 1 then
                if p and stats.kills ~= p.kills then RD.streak = 0 end
                RD.prog = { at = now, hp = hp, n = #list, kills = stats.kills }
                return false
            end
            if now - p.at < (tonumber(CFG.RaidStuckSecs) or 12) then return false end
            local _, r = parts()
            local from = r and r.Position or list[1].root.Position
            local best, bd = nil, math.huge
            for _, e in ipairs(list) do
                P.randomSkip[e.model] = nil
                local d = (e.root.Position - from).Magnitude
                if d < bd then best, bd = e, d end
            end
            RD.moves += 1
            RD.streak += 1
            P.raidFocus = best.model
            RD.note = string.format("stuck %ds on Island %d (%d left, no HP off) - relocating (%d): %s",
                math.floor(now - p.at), n, #list, RD.streak, best.name)
            print("[BFF] raid: " .. RD.note)
            RD.prog = { at = now, hp = hp, n = #list, kills = stats.kills }
            releasePile()
            return true
        end
        -- The raid's fight: the stuck watch runs inside it (a fight lasts up
        -- to 30 s), twice a second; the relocation's spot while it has a target.
        local RAID_CUR = { name = "raid", raid = true }
        function RAID_CUR.breakIf()
            local now = os.clock()
            if now - RD.checkAt < 0.5 then return false end
            RD.checkAt = now
            local _, r = parts()
            local at = P.raidAt or (r and r.Position)
            return at ~= nil and watch(wideList(at), RD.n)
        end
        function RAID_CUR.pose()
            local f = P.raidFocus
            local root = f and f.Parent and f:FindFirstChild("HumanoidRootPart")
            if not (root and RD.streak > 0) then return nil end
            return spotFor(root.Position, RD.streak)
        end

        -- ---------- THE LOOP: a chip, the button ----------
        -- By the Castle on the Sea's raid button (the Kaitun hub flies here
        -- when the button has not streamed in).
        local BUTTON3 = Vector3.new(-5036, 315, -3179)
        -- Map["Boat Castle"] (Third Sea) / Map.CircleIsland (Second Sea):
        -- RaidSummon2.Button.Main and its ClickDetector (every public hub).
        local function raidButton()
            local map = workspace:FindFirstChild("Map")
            local where = { "Boat Castle", "CircleIsland" }
            for i = 1, 2 do
                local m = map and map:FindFirstChild(where[i])
                local s = m and m:FindFirstChild("RaidSummon2")
                local b = s and s:FindFirstChild("Button")
                local main = b and b:FindFirstChild("Main")
                local cd = main and main:FindFirstChildWhichIsA("ClickDetector")
                if main and cd then return main, cd end
            end
            return nil, nil
        end
        -- Tools you carry (backpack + hand) that `test` says yes to.
        local function carried(test)
            local out = {}
            local holders = { player:FindFirstChild("Backpack"), player.Character }
            for i = 1, 2 do
                local h = holders[i]
                for _, t in ipairs(h and h:GetChildren() or {}) do
                    if t:IsA("Tool") and test(t) then table.insert(out, t) end
                end
            end
            return out
        end
        local function chipTool()
            return carried(function(t) return string.find(string.lower(t.Name), "microchip", 1, true) ~= nil end)[1]
        end
        local function physical() return carried(P.isPhysicalFruit) end
        -- A physical fruit's own name ("Rocket Fruit" -> "Rocket-Rocket").
        local function origOf(t)
            local o = t:GetAttribute("OriginalName")
            if type(o) == "string" and o ~= "" then return o end
            local base = string.match(t.Name, "^(.-) Fruit$")
            return base and (base .. "-" .. base) or t.Name
        end
        -- Prices: the game's list (GetFruits), read every 5 min; these when
        -- it gives nothing (the cheap ones only - the wiki).
        local PRICE_FALLBACK = {
            ["Rocket-Rocket"] = 5000, ["Spin-Spin"] = 7500, ["Blade-Blade"] = 30000, ["Spring-Spring"] = 60000,
            ["Bomb-Bomb"] = 80000, ["Smoke-Smoke"] = 100000, ["Spike-Spike"] = 180000, ["Flame-Flame"] = 250000,
            ["Ice-Ice"] = 350000, ["Sand-Sand"] = 420000, ["Dark-Dark"] = 500000,
        }
        local prices, pricesAt = nil, -1e9
        local function priceOf(orig)
            if os.clock() - pricesAt > 300 then
                pricesAt = os.clock()
                local cf = commF()
                local ok, res = pcall(function() return cf and cf:InvokeServer("GetFruits", false) end)
                if ok and type(res) == "table" then
                    prices = {}
                    for _, f in pairs(res) do
                        if type(f) == "table" and f.Name then prices[f.Name] = tonumber(f.Price) end
                    end
                end
            end
            return (prices and prices[orig]) or PRICE_FALLBACK[orig]
        end
        -- STORED FRUITS. The game's item list counts them under their
        -- "PhysicalFruit" ItemIds (ReplicatedStorage.Economy.ItemId.RawSource,
        -- client v4623); the module itself is read when it loads, these
        -- when it does not.
        local PHYS_IDS = {
            [1389] = "Quake-Quake", [1390] = "Rocket-Rocket", [1391] = "Magma-Magma", [1392] = "Ice-Ice",
            [1393] = "Buddha-Buddha", [1394] = "Flame-Flame", [1395] = "Dark-Dark", [1396] = "Rubber-Rubber",
            [1397] = "Bomb-Bomb", [1398] = "Spike-Spike", [1399] = "Blade-Blade", [1400] = "Smoke-Smoke",
            [1401] = "Phoenix-Phoenix", [1402] = "Spring-Spring", [1403] = "Spider-Spider", [1404] = "Sand-Sand",
            [1405] = "Gravity-Gravity", [1406] = "Pain-Pain", [1407] = "Light-Light", [1408] = "Love-Love",
            [1409] = "Control-Control", [1410] = "Venom-Venom", [1411] = "Spin-Spin", [1412] = "Ghost-Ghost",
            [1413] = "Shadow-Shadow", [1414] = "Portal-Portal", [1415] = "Spirit-Spirit", [1416] = "Blizzard-Blizzard",
            [1417] = "Dough-Dough", [1418] = "Mammoth-Mammoth", [1419] = "Sound-Sound", [1420] = "T-Rex-T-Rex",
            [1421] = "Diamond-Diamond", [1422] = "Gas-Gas", [1423] = "Kitsune-Kitsune", [1424] = "Yeti-Yeti",
            [1425] = "Eagle-Eagle", [1426] = "Creation-Creation", [1427] = "Lightning-Lightning",
            [1428] = "Celestial-Celestial", [1429] = "Oni-Oni", [1430] = "Tiger-Tiger", [1431] = "Meme-Meme",
            [1447] = "Dragon-Dragon",
        }
        local physMap = nil
        local function physIds()
            if physMap then return physMap end
            physMap = {}
            for id, n in pairs(PHYS_IDS) do physMap[id] = n end
            pcall(function()
                local src = require((RS :: any).Economy.ItemId.RawSource)
                for _, row in pairs(src) do
                    local id = type(row) == "table" and row.Id
                    if type(id) == "table" and id.Type == "PhysicalFruit" and tonumber(id.ItemId)
                        and type(id.StorageKey) == "string" then
                        physMap[tonumber(id.ItemId)] = id.StorageKey
                    end
                end
            end)
            return physMap
        end
        -- { [name] = count } of your stored fruits and where it was read;
        -- nil + why. getInventoryFruits (the hubs), the game's item list,
        -- getInventory (legacy) - the first that names any.
        local function storedFruits()
            local cf = commF()
            local ok, res = pcall(function() return cf and cf:InvokeServer("getInventoryFruits") end)
            if ok and type(res) == "table" then
                local out, any = {}, false
                for _, f in pairs(res) do
                    if type(f) == "table" and type(f.Name) == "string" then
                        out[f.Name] = (out[f.Name] or 0) + (tonumber(f.Count) or 1)
                        any = true
                    end
                end
                if any then return out, "getInventoryFruits" end
            end
            local rf = netRemote("RF", "GetAllItemValues")
            local ok2, list = pcall(function() return rf and rf:InvokeServer() end)
            if ok2 and type(list) == "table" then
                local ids, out, any = physIds(), {}, false
                for _, it in pairs(list) do
                    if type(it) == "table" and it.Key == "Quantity" then
                        local n, q = ids[tonumber(it.ItemId) or -1], tonumber(it.Value) or 0
                        if n and q > 0 then
                            out[n] = (out[n] or 0) + q
                            any = true
                        end
                    end
                end
                if any then return out, "the game's item list" end
            end
            local ok3, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if ok3 and type(inv) == "table" then
                local out, any = {}, false
                for _, it in pairs(inv) do
                    if type(it) == "table" and it.Type == "Blox Fruit" and type(it.Name) == "string" then
                        out[it.Name] = (out[it.Name] or 0) + (tonumber(it.Count) or 1)
                        any = true
                    end
                end
                if any then return out, "getInventory" end
            end
            return nil, "no stored fruit read"
        end
        -- Pure (tools/raidloop_test.py): the cheapest of `stored` at most
        -- `cap` (priceFn(name) -> Beli or nil; unpriced = never). -> name, price.
        local function cheapest(stored, cap, priceFn)
            local best, bp = nil, math.huge
            for name, count in pairs(stored) do
                local pr = (count or 0) > 0 and priceFn(name) or nil
                if pr and pr <= cap and (pr < bp or (pr == bp and name < best)) then best, bp = name, pr end
            end
            return best, best and bp or nil
        end

        -- A chip from the Mysterious Scientist (RaidsNpc "Select" <theme>:
        -- 1 = given, 0 = under level 1100, a string = why not - the game's
        -- dialogue). He takes a PHYSICAL fruit (or $100,000 every 2 h): one
        -- you carry worth more than the cap could be the one he takes - none
        -- traded then. -> true, or false + why.
        local function buyChip(myEpoch)
            local theme = tostring(CFG.RaidChip or "Flame")
            local cap = tonumber(CFG.RaidFruitMax) or 200000
            local spend = nil
            for _, t in ipairs(physical()) do
                local o = origOf(t)
                local pr = priceOf(o)
                if not pr or pr > cap then
                    return false, string.format("%s is in your backpack (%s) - the scientist could take it; store it first",
                        t.Name, pr and ("$" .. tostring(pr)) or "price unknown")
                end
                spend = spend or o
            end
            if not spend then
                local st, src = storedFruits()
                local pick, pr = nil, nil
                if st then pick, pr = cheapest(st, cap, priceOf) end
                if pick then
                    local before = #physical()
                    local cf = commF()
                    pcall(function() return cf and cf:InvokeServer("LoadFruit", pick) end)
                    local t0 = os.clock()
                    while #physical() <= before and os.clock() - t0 < 3 and not stale(myEpoch) do task.wait(0.1) end
                    if #physical() <= before then
                        return false, "LoadFruit " .. pick .. " put nothing in your backpack (" .. tostring(src) .. ")"
                    end
                    spend = pick .. " ($" .. tostring(pr) .. ", from " .. tostring(src) .. ")"
                else
                    spend = "no fruit (none stored at most $" .. tostring(cap) .. ": " .. tostring(src)
                        .. ") - his $100,000 way"
                end
            end
            local cf = commF()
            local ok, res = pcall(function() return cf and cf:InvokeServer("RaidsNpc", "Select", theme) end)
            local t0 = os.clock()
            while not chipTool() and os.clock() - t0 < 3 and not stale(myEpoch) do task.wait(0.1) end
            if chipTool() or (ok and res == 1) then
                RL.chips += 1
                RL.paid = spend
                print(string.format("[BFF] raid loop: a %s chip - paid with %s", theme, spend))
                return true
            end
            if ok and res == 0 then
                CFG.RaidLoop = false
                return false, "raids need level 1100 - the raid loop is off"
            end
            return false, string.format("no %s chip - the scientist said %s (offered %s)", theme,
                ok and tostring(res) or ("an error: " .. tostring(res)), spend)
        end

        -- The raid button: flown to, clicked; the raid's start awaited
        -- (the timer, or Island 1 in reach). -> true, or false + why.
        local function pressButton(myEpoch)
            local main, cd = raidButton()
            if not main then
                if mySea() ~= 3 then return false, "the raid button is not loaded here" end
                setState("FLY")
                say("raid loop: to the raid button (Castle on the Sea)")
                flyTo(BUTTON3)
                if stale(myEpoch) then return false, "stopped" end
                task.wait(1)
                main, cd = raidButton()
                if not main then return false, "the raid button did not load at the Castle on the Sea" end
            end
            local _, r = parts()
            if r and (r.Position - main.Position).Magnitude > 12 then
                setState("FLY")
                flyTo(main.Position + Vector3.new(0, 4, 0))
                if stale(myEpoch) then return false, "stopped" end
            end
            if not fireclickdetector then
                return false, "this executor has no fireclickdetector - press the raid button yourself"
            end
            pcall(fireclickdetector, cd)
            RL.presses += 1
            local t0 = os.clock()
            while os.clock() - t0 < 20 and not stale(myEpoch) do
                local on, pos = raidState()
                if on or pos then return true end
                say(string.format("raid loop: button pressed - the raid starting  %.0fs", os.clock() - t0))
                task.wait(0.25)
            end
            return false, "the button was pressed - no raid in 20 s"
        end

        local function loopFail(why, secs)
            RL.note, RL.nextAt = why, os.clock() + secs
            print(string.format("[BFF] raid loop: %s - staying here, again in %d s", why, secs))
        end
        -- OUTSIDE A RAID with the loop on: a chip if you have none, then the
        -- button. Anything that fails = you stay where you are.
        local function loopStep(myEpoch)
            local now = os.clock()
            if RD.overAt and now - RD.overAt < 5 then
                P.raidNote = "raid over - staying here a moment"
                return
            end
            if now < RL.nextAt then
                P.raidNote = string.format("%s - staying here, again in %ds", RL.note, math.ceil(RL.nextAt - now))
                return
            end
            if mySea() == 1 then
                loopFail("raids are Second / Third Sea", 60)
                return
            end
            if not chipTool() then
                P.raidNote = "raid loop: a " .. tostring(CFG.RaidChip) .. " chip from the Mysterious Scientist"
                say(P.raidNote)
                setState("CHIP")
                local ok, why = buyChip(myEpoch)
                if stale(myEpoch) then return end
                if not ok then
                    loopFail(why, 60)
                    return
                end
            end
            P.raidNote = "raid loop: the raid button"
            say(P.raidNote)
            local ok, why = pressButton(myEpoch)
            if stale(myEpoch) then return end
            if ok then
                RL.note, RL.tries = "raid started", 0
                print("[BFF] raid loop: the raid started")
                return
            end
            RL.tries += 1
            loopFail(why, RL.tries >= 3 and 120 or 10)
        end

        function raidStep()
            local myEpoch = epoch
            local on, islandPos, n, text = raidState()
            P.raidAt = islandPos
            local now = os.clock()
            local inRaid = islandPos ~= nil or on
            if inRaid then
                if not RD.inside then
                    RD.inside, RD.n, RD.prog, RD.streak = true, 0, nil, 0
                    print("[BFF] raid: in a raid")
                end
                if n > RD.n then
                    RD.n, RD.prog = n, nil
                    print(string.format("[BFF] raid: Island %d", n))
                end
                RL.tries = 0
            elseif RD.inside then
                RD.inside, RD.overAt = false, now
                RD.done += 1
                P.raidFocus, RD.streak = nil, 0
                print(string.format("[BFF] raid: over (Island %d) - %d this session; staying here%s", RD.n, RD.done,
                    CFG.RaidLoop and ", then the next chip" or ""))
            end
            if not inRaid then
                -- OUTSIDE A RAID (user, 2026-10-10): nothing fought, never
                -- anywhere else - you stay where the game put you (the Castle
                -- on the Sea after a raid). The loop's own steps excepted.
                if pileCur then releasePile() end
                if CFG.RaidLoop then
                    loopStep(myEpoch)
                else
                    P.raidNote = "not in a raid - staying here (the raid loop is off)"
                end
                say(P.raidNote)
                setState("WAIT")
                task.wait(0.25)
                return
            end
            local list = buildRaidPile()
            P.raidNote = string.format("in a raid  ·  Island %d%s  ·  %d enemies here", n,
                text and ("  ·  " .. text) or "", #list)
            -- The damage check at work: fought where it stands (it took no damage
            -- when pulled), and how many could not be hurt at all.
            if P.pileInPlace then P.raidNote = P.raidNote .. "  ·  one fought where it stands" end
            if P.randomCant > 0 then P.raidNote = P.raidNote .. "  ·  could not hurt " .. P.randomCant end
            if RD.streak > 0 and P.raidFocus then
                P.raidNote = P.raidNote .. string.format("  ·  RELOCATED %d", RD.streak)
            end
            local _, r = parts()
            local at = islandPos or (r and r.Position)
            if at and watch(wideList(at), n) then return end
            if #list > 0 then
                activeName = "raid"
                fight(RAID_CUR, nil)
                return
            end
            -- Nobody here: over the newest island, and wait for its wave.
            if islandPos and r then
                local over = islandPos + Vector3.new(0, 45, 0)
                if (r.Position - over).Magnitude > 60 then
                    releasePile()
                    setState("FLY")
                    say("raid: to Island " .. n)
                    flyTo(over)
                end
            end
            setState("WAIT")
            say(islandPos and ("raid: Island " .. n .. " - waiting for enemies") or "raid: waiting for enemies")
            task.wait(0.25)
        end

        -- For the tests.
        RD._t = { spotFor = spotFor, cheapest = cheapest, origOf = origOf, watch = watch, wideList = wideList,
            storedFruits = storedFruits, buyChip = buyChip, pressButton = pressButton, RAID_CUR = RAID_CUR }
    end
    build()

    -- =========================================================
    -- RANDOM MODE
    -- =========================================================
    -- Castle on the Sea pirate raid (Third Sea, every ~1 h 15): the game tags its
    -- mobs "BasicMob", and a raid pirate is one that appears within 750 studs of
    -- (-5556, 314, -2988) -- the redz hub's own definition (2025-10); the 2026-09
    -- hub teleports to (-5128, 314, -2957) when farther than 1000. There, the
    -- area is that circle, however far the pirates spread over the yard. Anywhere
    -- else: RandomRadius round you.
    local CASTLE_RAID = Vector3.new(-5556, 314, -2988)
    function randomStep()
        local _, r = parts()
        if not r then return end
        local sea = mySea()
        local atCastle = (sea == 3 or sea == nil) and (r.Position - CASTLE_RAID).Magnitude <= 1500
        P.randomAt = atCastle and CASTLE_RAID or nil
        local list, _, inPlace = buildRandomPile()
        P.randomNote = string.format("%s  ·  %d to fight%s%s",
            atCastle and "Castle on the Sea raid area" or ("everything within " .. math.floor(CFG.RandomRadius or 750) .. " studs of you"),
            #list, inPlace and "  ·  one fought where it stands" or "",
            P.randomCant > 0 and ("  ·  could not hurt " .. P.randomCant) or "")
        if #list > 0 then
            activeName = "random"
            fight({ name = "random", random = true }, nil)
            return
        end
        -- Nobody: at the castle, over the raid area for the next wave.
        if atCastle then
            local over = CASTLE_RAID + Vector3.new(0, math.max(CFG.HeightSafe or 20, 30), 0)
            if (r.Position - over).Magnitude > 80 then
                releasePile()
                setState("FLY")
                say("random: to the castle's raid area")
                flyTo(over)
            end
        end
        setState("WAIT")
        say(atCastle and "random: waiting for the pirates" or "random mode: no enemy near you")
        task.wait(0.25)
    end
end

-- =========================================================
-- ELITE HUNT AND THE SERVER HOP
-- =========================================================
-- Third Sea. The Elite Pirates -- Diablo, Deandre, Urban, and Tyrant of the
-- Skies while he is up -- are ONE per server, back 8 min 45 s after the last
-- one died (Fandom, 2026-09). Only the LAST hit gets the drops, God's Chalice
-- among them; the Elite Hunter's quest (the cat at the Castle on the Sea)
-- adds progress (Yama at 30), money and EXP, nothing to the drop.
--
-- UP: the game has it loaded (near a player) or parked in ReplicatedStorage
-- (far from every player) -- bossUp reads both -- or the Elite Hunter says so.
-- Neither, after a short look: another server. The list: the game's own
-- server browser (ReplicatedStorage.__ServerBrowser, what its Servers menu
-- calls: a page number gives { [JobId] = { Count, Region } }), the Roblox
-- server list if that one fails. The JOIN: always the game's ("teleport" +
-- JobId: its SERVER starts the teleport). The Third Sea takes only
-- server-started teleports (Roblox "Secure within universe" places): one
-- started here (TeleportToPlaceInstance) is refused with "Cannot teleport
-- without a valid teleport token" (in game, 2026-09-28).
--
-- A teleport ends this script. What it knew -- your settings, the servers
-- already looked at, the counts -- goes with you twice: in the reload queued
-- on the executor (queue_on_teleport) and in a file an autoexec loader reads.
--
-- THE CHALICE ENDS IT. Leaving the server, or dying, with it in your backpack
-- loses it. Once it is seen the hunt stops in that server for good: every hop
-- refuses, and the last look is right before the teleport call itself.
-- Only huntStep leaves the block as a local (the rest are on P): the main
-- chunk is at Luau's 200-local register limit.
local huntStep
do
    -- In a function of its own: registers are per function, and a do block
    -- would still count against the main chunk's.
    local function build()
        local ELITES    = { "Diablo", "Deandre", "Urban", "Tyrant of the Skies" }
        -- The server news says which one is up. Through `any`: the type
        -- checker would otherwise bend ELITES to fit P.
        (P :: any).ELITES = ELITES
        local ELITE_NPC = Vector3.new(-5418.9, 313.7, -2826.2)   -- the Elite Hunter (public hubs' spot)
        local CHALICE   = "God's Chalice"
        -- One file PER ACCOUNT: two accounts share the executor's folder, and
        -- one's settings (eating allowed, say) must never reach the other.
        local HOP_FILE  = "bff_elite_hop_" .. tostring(player.UserId) .. ".json"
        local SOURCE_URL = "https://raw.githubusercontent.com/JodLHarDxD/blox-fast-farm/main/fast_farm.lua"
        -- Where the Elite Hunter's words send you, when no model can be seen: over
        -- the middle of the island, from the camps in LEVELS round it.
        local ELITE_ISLES = {
            { "port town",       Vector3.new(0, 250, 5600) },
            { "hydra",           Vector3.new(5300, 800, 0) },
            { "great tree",      Vector3.new(3000, 400, -7000) },
            { "floating turtle", Vector3.new(-12000, 650, -8500) },
            { "tiki",            Vector3.new(-16500, 250, 700) },
        }

        -- What the Elite Hunter answered: "none" (nothing up), "up" (it named one or
        -- gave its quest), "unknown" (no answer, or words not known here).
        local function eliteReply(r)
            if type(r) ~= "string" or #r == 0 then return "unknown" end
            local s = string.lower(r)
            if string.find(s, "anything for you", 1, true) then return "none" end
            if string.find(s, "roaming", 1, true) or string.find(s, "last seen", 1, true) then return "up" end
            for _, n in ipairs(ELITES) do
                if string.find(s, string.lower(n), 1, true) then return "up" end
            end
            return "unknown"
        end

        -- The island its words name, and a point over it.
        local function eliteIsle(r)
            if type(r) ~= "string" then return nil, nil end
            local s = string.lower(r)
            for _, i in ipairs(ELITE_ISLES) do
                if string.find(s, i[1], 1, true) then return i[1], i[2] end
            end
            return nil, nil
        end

        -- One page of the game's server browser into rows. Returns how many.
        local function browserRows(res, out)
            if type(res) ~= "table" then return 0 end
            local n = 0
            for id, d in pairs(res) do
                if type(id) == "string" and type(d) == "table" then
                    n += 1
                    table.insert(out, {
                        id = id, count = d.Count or d.Players or d.count,
                        max = d.MaxPlayers or d.Max, region = d.Region,
                    })
                end
            end
            return n
        end

        -- The servers worth joining, best first: not this one, not full, not looked
        -- at in the last revisitSecs. "fewest": fewest players first (fewer hunters,
        -- the elite more likely still standing); "random": any order. rand() breaks
        -- ties so two runs do not pile into the same server.
        local function pickServers(rows, here, visited, now, revisitSecs, order, rand)
            local out, seen = {}, {}
            for _, s in ipairs(rows) do
                local id = s.id
                if type(id) == "string" and id ~= here and not seen[id] then
                    seen[id] = true
                    local cnt = tonumber(s.count) or 0
                    local max = tonumber(s.max) or 12
                    local at = visited[id]
                    if cnt < max and not (type(at) == "number" and now - at < revisitSecs) then
                        table.insert(out, { id = id, count = cnt, region = s.region, key = rand() })
                    end
                end
            end
            if order == "random" then
                table.sort(out, function(a, b) return a.key < b.key end)
            else
                table.sort(out, function(a, b)
                    if a.count ~= b.count then return a.count < b.count end
                    return a.key < b.key
                end)
            end
            return out
        end

        -- Servers looked at more than keepSecs ago are forgotten.
        local function pruneVisited(visited, now, keepSecs)
            for id, at in pairs(visited) do
                if type(at) ~= "number" or now - at > keepSecs then visited[id] = nil end
            end
            return visited
        end

        -- The fruit worth going for, of the ones lying in this server:
        -- { orig, price, dropper, dropperNear } -> the dearest that passes, or
        -- nil. A player's drop only if you allow them AND its dropper has
        -- walked off (one standing by it is a trade in progress). No price
        -- known counts as 0: it passes only when the minimum is 0.
        local function pickFruit(list, minPrice, allowDrops)
            local best
            for _, f in ipairs(list) do
                local ok = (not f.dropper) or (allowDrops and not f.dropperNear)
                if ok and (f.price or 0) >= (minPrice or 0) then
                    if not best or (f.price or 0) > (best.price or 0) then best = f end
                end
            end
            return best
        end

        -- BERRIES. The game tags every berry bush "BerryBush"; a bush with
        -- berries on it carries their names as attribute values (read from the
        -- public hubs, 2026-04 and 2026-09-29).
        local BERRIES = {
            "Pink Pig Berry", "White Cloud Berry", "Red Cherry Berry", "Blue Icicle Berry",
            "Green Toad Berry", "Orange Berry", "Purple Jelly Berry", "Yellow Star Berry",
        }
        P.BERRIES = BERRIES
        local IS_BERRY = {}
        for _, n in ipairs(BERRIES) do IS_BERRY[n] = true end

        -- The berries a bush's attributes name, sorted.
        local function berryNames(attrs)
            local out = {}
            if type(attrs) ~= "table" then return out end
            for _, v in pairs(attrs) do
                if type(v) == "string" and IS_BERRY[v] then table.insert(out, v) end
            end
            table.sort(out)
            return out
        end

        -- The nearest bush { names, pos } holding a berry in `want`
        -- ([name] = true), or nil.
        local function pickBerry(list, want, here)
            local best, bd = nil, math.huge
            for _, b in ipairs(list) do
                local wanted = false
                for _, n in ipairs(b.names) do
                    if want and want[n] then wanted = true break end
                end
                if wanted then
                    local d = (b.pos - here).Magnitude
                    if d < bd then best, bd = b, d end
                end
            end
            return best
        end

        -- AURA RECIPES the Barista Cousin teaches (the Berries and Aura/Skins
        -- pages, 2026-09): Legendary first.
        local RECIPES = {
            "Winter Sky", "Snow White", "Pure Red",
            "Bright Yellow", "Slimy Green", "Orange Soda", "Yellow Sunshine", "Absolute Zero",
            "Plump Purple", "Green Lizard", "Blue Jeans", "Fiery Rose", "Heat Wave",
        }
        P.RECIPES = RECIPES

        -- What ("ColorsDealer", "2") answered, in words (the public hubs: 1 or
        -- 2 = done, 0 = cannot pay).
        local function buyWords(res)
            if res == 1 then return "learned" end
            if res == 2 then return "learned (or already yours)" end
            if res == 0 then return "not enough to pay" end
            return "the game said " .. tostring(res)
        end

        -- Everything the hunt knows. `tally` and `visited` survive the hop.
        local E = {
            visited = {},
            tally = { joins = 0, found = 0, kills = 0, chalices = 0, fruits = 0, joinSecs = 0, fails = 0, since = os.time() },
            used = false,            -- the hunt was on at some point in this server
            carried = nil,           -- how this server's copy got its state: "queued reload" / "file"
            queued = false,          -- the reload is queued once per server (each call would add a copy)
            hopping = false,
            chalice = false,         -- seen in this server: no hop here, ever
            safeAt = nil,
            lookStart = nil, foundHere = false,
            asks = 0, askAt = -100, questAskAt = -100, reply = nil, replyText = nil,
            npcVisited = false, dropped = false, isleTried = false,
            missSince = nil, progress = nil, lastKill = nil, lastList = nil,
            listWhy = nil,           -- why the game's server list came up empty
            lastJoin = nil,          -- how the last join went, in words
            clientRefused = false,   -- this place refused a join started here: not tried again
            eliteDoneUntil = 0,      -- this server's elite is down: not looked for till then
            why = nil,               -- why the last "nothing here" said so
            fruitNote = "no fruit gone for yet", fruitSkip = setmetatable({}, { __mode = "k" }),
            berryNote = "no berry gone for yet", berrySkip = setmetatable({}, { __mode = "k" }),
            have = {},               -- berries you hold, from the inventory ([name] = count; read = true)
            offer = nil,             -- what the Barista Cousin teaches in this server, in words
            recipeNote = "no recipe gone for yet",
            flowerNote = "no Fire Flower yet",
            flowerHave = nil,        -- Fire Flowers you hold, from the inventory
            flowerSkip = setmetatable({}, { __mode = "k" }),    -- given up on (3 grabs)
            flowerTries = setmetatable({}, { __mode = "k" }),
            flowerFirstKill = nil, flowerKills0 = 0, flowerAtCamp = nil, flowerTurn = 0,
            keepAway = nil,          -- seconds this server stays off the list beyond the usual
            note = "hunt off",
        }
        P.elite = E

        local HttpService     = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")

        local function holdingChalice()
            return findTool(CHALICE) ~= nil
        end
        P.holdingChalice = holdingChalice

        local function queueFn()
            local q = (syn and syn.queue_on_teleport) or queue_on_teleport or queueonteleport
                or (fluxus and fluxus.queue_on_teleport)
            return type(q) == "function" and q or nil
        end

        -- How the next server gets this script back, in words for the panel.
        function P.reloadWay()
            local q = queueFn() and "queue_on_teleport (your executor has it)"
                or "NO queue_on_teleport on this executor - put the README's loader in its autoexec folder"
            local f = writefile and "file: yes" or "file: this executor cannot write one"
            return q .. "  ·  " .. f
        end

        local function fileRead()
            if not readfile then return nil end
            local ok, s = pcall(readfile, HOP_FILE)
            return (ok and type(s) == "string") and s or nil
        end

        local function fileWrite(s)
            if not writefile or not s then return false end
            return (pcall(writefile, HOP_FILE, s))
        end

        -- The state that goes to the next server. resume = the hunt starts there by
        -- itself. Only for 5 minutes: a hunt you left an hour ago is not resumed.
        local function carryState(resume)
            local cfg = {}
            for k, v in pairs(CFG) do cfg[k] = v end
            local t = {
                v = 1, build = P.build, userId = player.UserId, resume = resume and true or false,
                freshUntil = os.time() + 300, hopAt = os.time(), fromJob = game.JobId,
                visited = E.visited, tally = E.tally, cfg = cfg,
            }
            local ok, s = pcall(function() return HttpService:JSONEncode(t) end)
            if not ok then
                -- Something in your settings will not go into JSON: the hunt
                -- still goes on over there, on that copy's defaults.
                t.cfg = nil
                ok, s = pcall(function() return HttpService:JSONEncode(t) end)
            end
            return ok and s or nil
        end

        local function queueReload(carry)
            if E.queued then return end
            local q = queueFn()
            if not q then return end
            local url = _G.BFF_SOURCE or SOURCE_URL
            local code = "repeat task.wait() until game:IsLoaded()\n"
                .. (carry and string.format("_G.BFF_CARRY = %q\n", carry) or "")
                .. string.format("_G.BFF_SOURCE = %q\n", url)
                .. string.format("pcall(function() loadstring(game:HttpGet(%q .. \"?cb=\" .. tostring(tick())))() end)\n", url)
            if pcall(q, code) then E.queued = true end
        end

        -- On load: state carried from the server before. The file (written at every
        -- teleport attempt) is newer than the queued copy (queued once), so it wins
        -- when both are there. Returns true when the hunt should start by itself.
        local function takeCarry()
            local queued = _G.BFF_CARRY
            _G.BFF_CARRY = nil
            local s, via = fileRead(), "file"
            local t
            if s then
                local ok, d = pcall(function() return HttpService:JSONDecode(s) end)
                if ok and type(d) == "table" then t = d end
            end
            if not t and type(queued) == "string" then
                local ok, d = pcall(function() return HttpService:JSONDecode(queued) end)
                if ok and type(d) == "table" then t, via = d, "queued reload" end
            end
            if not t then return false end
            -- Another account's state: nothing of it is taken.
            if t.userId ~= nil and t.userId ~= player.UserId then return false end
            if type(t.visited) == "table" then E.visited = t.visited end
            if type(t.tally) == "table" then
                for k, v in pairs(t.tally) do
                    if type(v) == "number" then E.tally[k] = v end
                end
            end
            local fresh = tonumber(t.freshUntil) and os.time() <= t.freshUntil
            -- Written in THIS server: nothing hopped (a copy run again by hand).
            if not fresh or t.fromJob == game.JobId then return false end
            -- Settings only from a copy of THIS build: an older copy's would
            -- carry its old defaults through every hop after it (the far edge
            -- 8,000, M1 0.12...) and the update would look like it never came.
            if type(t.cfg) == "table" and t.build == P.build then
                for k, v in pairs(t.cfg) do
                    if CFG[k] ~= nil then CFG[k] = v end
                end
            elseif type(t.cfg) == "table" then
                print("[BFF] hop: settings from build " .. tostring(t.build or "old")
                    .. " not taken - this build's (" .. tostring(P.build) .. ") defaults")
            end
            if not t.resume then return false end
            -- Two loaders in one server (autoexec AND the queue): count the join once.
            if t.arrivedJob ~= game.JobId then
                E.tally.joins += 1
                local secs = os.time() - (tonumber(t.hopAt) or os.time())
                if secs >= 0 and secs < 300 then E.tally.joinSecs += secs end
                t.arrivedJob = game.JobId
                t.tally = E.tally          -- with this join in it
                pcall(function() fileWrite(HttpService:JSONEncode(t)) end)
            end
            CFG.Hunt, CFG.RaidMode, CFG.RandomMode = true, false, false
            E.used, E.carried = true, via
            return true
        end
        P.takeCarry = takeCarry

        -- The next server's copy must not start by itself (you stopped it, or the
        -- chalice came in).
        local function carryOff()
            if E.used then fileWrite(carryState(false)) end
        end
        P.carryOff = carryOff

        local function notify(text)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Fast Farm", Text = text, Duration = 30,
                })
            end)
        end

        -- THE CHALICE: the hunt is over in this server, for good -- not even
        -- turning it off and on hops again here. Marking it is safe from any
        -- thread (the panel's Hop now); the hover is the main loop's.
        local function markChalice()
            if E.chalice then return end
            E.chalice = true
            E.tally.chalices += 1
            carryOff()
            notify("God's Chalice! Elite hunt stopped - no server hop.")
            print("[BFF] God's Chalice - elite hunt stopped in this server, no hop.")
        end

        -- Up out of reach and held there; no hop, no fight. Stop gives you the
        -- character back.
        local function chaliceStop()
            markChalice()
            releasePile()
            local _, r = parts()
            if r and not E.safeAt then
                E.safeAt = r.Position + Vector3.new(0, 300, 0)
                flyTo(E.safeAt)
            end
            setState("CHALICE")
            E.note = holdingChalice()
                and "GOD'S CHALICE - hunt stopped, no hop in this server. Dying or leaving loses it."
                or "the chalice came in this server - the hunt stays stopped here (Stop to take over)"
            say(E.note)
        end

        -- Every server the game's browser lists, a page at a time, until a page adds
        -- nothing new.
        -- What a page came back as, in words: the shape tells a moved format
        -- from an empty one.
        local function shapeOf(res)
            if type(res) ~= "table" then return type(res) .. " " .. tostring(res) end
            local n, k1, v1 = 0, nil, nil
            for k, v in pairs(res) do
                n += 1
                if n == 1 then k1, v1 = k, v end
            end
            if n == 0 then return "an empty table" end
            return string.format("a table of %d, first %s %s -> %s", n, type(k1), tostring(k1), type(v1))
        end

        local function browserList(myEpoch)
            local sb = RS:FindFirstChild("__ServerBrowser")
            if not sb then
                E.listWhy = "the game's server browser (ReplicatedStorage.__ServerBrowser) is missing"
                return nil
            end
            E.listWhy = nil
            local out, seen = {}, {}
            for page = 1, 40 do
                if stale(myEpoch) then break end
                local rows = {}
                local ok, res = pcall(function() return sb:InvokeServer(page) end)
                if not ok or browserRows(res, rows) == 0 then
                    if page == 1 then
                        E.listWhy = ok and ("its page 1 gave " .. shapeOf(res))
                            or ("its page 1 failed: " .. tostring(res))
                    end
                    break
                end
                local new = 0
                for _, row in ipairs(rows) do
                    if not seen[row.id] then
                        seen[row.id] = true
                        new += 1
                        table.insert(out, row)
                    end
                end
                if new == 0 or #out >= 150 then break end
                say(string.format("hop: reading the server list  %d", #out))
            end
            return out
        end

        local function robloxList(myEpoch)
            local out, cursor = {}, ""
            for _ = 1, 3 do
                if stale(myEpoch) then break end
                local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s",
                    game.PlaceId, (cursor ~= "") and ("&cursor=" .. cursor) or "")
                local ok, body = pcall(function() return game:HttpGet(url) end)
                if not ok or type(body) ~= "string" then break end
                local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
                if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then break end
                for _, s in ipairs(data.data) do
                    table.insert(out, { id = s.id, count = s.playing, max = s.maxPlayers })
                end
                cursor = data.nextPageCursor
                if type(cursor) ~= "string" or cursor == "" then break end
            end
            return out
        end

        -- One join. Returns only if it did not happen (a teleport that works ends
        -- this script mid-wait). The game's server join whatever list the JobId
        -- came from; one started here only without it, and never again in this
        -- server once refused for want of a teleport token.
        local function joinServer(id, myEpoch)
            local sb = RS:FindFirstChild("__ServerBrowser")
            local via = sb and "game" or "here"
            if not sb and E.clientRefused then
                E.lastJoin = "no way to join: the game's server join is missing, and this place refuses joins started here"
                return false
            end
            local failed, why, ret = false, nil, nil
            local c1, c2
            pcall(function()
                c1 = TeleportService.TeleportInitFailed:Connect(function(p, result, msg)
                    if p == player then
                        failed = true
                        why = tostring(msg or result)
                    end
                end)
            end)
            pcall(function()
                c2 = player.OnTeleport:Connect(function(st)
                    if st == Enum.TeleportState.Failed then failed = true end
                end)
            end)
            -- Its own thread: the game's server may take its time answering, and
            -- the wait below must still end.
            task.spawn(function()
                local ok, r = pcall(function()
                    if via == "game" then return sb:InvokeServer("teleport", id) end
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player)
                end)
                if ok then ret = r else
                    failed = true
                    why = "the call failed: " .. tostring(r)
                end
            end)
            local t0 = os.clock()
            while not failed and os.clock() - t0 < 15 and not stale(myEpoch) do
                task.wait(0.25)
            end
            if c1 then pcall(function() c1:Disconnect() end) end
            if c2 then pcall(function() c2:Disconnect() end) end
            if not failed then
                why = stale(myEpoch) and "stopped"
                    or ("no teleport within 15 s" .. ((ret ~= nil) and ("  (the game said " .. tostring(ret) .. ")") or ""))
            end
            why = tostring(why or "refused")
            if via == "here" and string.find(string.lower(why), "token", 1, true) then
                E.clientRefused = true
            end
            E.lastJoin = (via == "game" and "game's join: " or "join from here: ") .. why
            print("[BFF] hop: " .. E.lastJoin)
            return false
        end

        -- THE HOP. Refused outright with the chalice; looked at again right before
        -- every teleport call. keepAway: seconds this server stays off the
        -- list beyond the usual (a Fire Flower came here: 5-15 min of none).
        local function hop(why, keepAway)
            if E.chalice or holdingChalice() then
                if holdingChalice() then markChalice() end
                E.note = "hop refused - the God's Chalice is in this server with you"
                say(E.note)
                return false
            end
            if E.hopping then return false end
            E.hopping = true
            local myEpoch = epoch
            releasePile()
            setState("HOP")
            local now = os.time()
            E.visited[game.JobId] = now + (tonumber(keepAway) or 0)
            pruneVisited(E.visited, now, 3600)
            for round = 1, 3 do
                say("hop: reading the server list  (" .. tostring(why) .. ")")
                local rows, via = browserList(myEpoch), "browser"
                if not rows or #rows == 0 then rows, via = robloxList(myEpoch), "roblox" end
                local cands = pickServers(rows or {}, game.JobId, E.visited, os.time(),
                    (CFG.HopRevisit or 10) * 60, CFG.HopOrder, math.random)
                E.lastList = string.format("%d listed, %d worth joining  ·  %s", #(rows or {}), #cands,
                    via == "browser" and "the game's server browser"
                        or ("the Roblox server list - " .. tostring(E.listWhy or "the game's was empty")))
                print("[BFF] hop: " .. E.lastList)
                for i, s in ipairs(cands) do
                    if i > 5 or stale(myEpoch) then break end
                    if holdingChalice() then
                        E.hopping = false
                        markChalice()
                        return false
                    end
                    E.visited[s.id] = os.time()
                    local carry = carryState(CFG.Hunt and P.running)
                    fileWrite(carry)
                    queueReload(carry)
                    E.note = string.format("hop: joining a server with %d players  (%s)", s.count, tostring(why))
                    say(E.note)
                    joinServer(s.id, myEpoch)
                    -- Still here: that one refused (full, gone, or teleports throttled).
                    E.tally.fails += 1
                    task.wait(1)
                end
                if stale(myEpoch) then break end
                task.wait(3 * round)
            end
            E.hopping = false
            E.note = "hop failed three times - trying again shortly  (" .. tostring(E.lastJoin or E.lastList) .. ")"
            say(E.note)
            return false
        end

        function P.hopNow()
            task.spawn(function() hop("by hand") end)
        end

        -- Is one up? The first of the elites the game has loaded or parked.
        local function eliteUp()
            for _, n in ipairs(ELITES) do
                local at, where = bossUp(n)
                if at then return n, at, where end
            end
            return nil, nil, nil
        end

        -- The quest tracker's title (Main.Quest, what the public hubs read). Second
        -- value: it is an elite's.
        local function eliteQuestShown()
            local ok, txt = pcall(function()
                local q = player.PlayerGui.Main.Quest
                if not q.Visible then return nil end
                return q.Container.QuestTitle.Title.Text
            end)
            if not ok or type(txt) ~= "string" then return nil, false end
            for _, n in ipairs(ELITES) do
                if string.find(txt, n, 1, true) then return txt, true end
            end
            return txt, false
        end

        local function askHunter()
            local cf = commF()
            E.asks += 1
            E.askAt = os.clock()
            if not cf then E.reply, E.replyText = "unknown", "no CommF_ remote" return "unknown" end
            local ok, r = pcall(function() return cf:InvokeServer("EliteHunter") end)
            E.reply = eliteReply(ok and r or nil)
            E.replyText = ok and tostring(r) or "error"
            return E.reply
        end

        local function readProgress()
            local cf = commF()
            if not cf then return end
            local ok, r = pcall(function() return cf:InvokeServer("EliteHunter", "Progress") end)
            if ok and tonumber(r) then E.progress = tonumber(r) end
        end

        -- The elite's quest, while it is still up (it counts toward Yama only if held
        -- when it dies). Asked from where you stand; if that gets no answer at all,
        -- once per server from in front of the Elite Hunter.
        local function takeEliteQuest(myEpoch)
            local shown, isElite = eliteQuestShown()
            if isElite then return true end
            if os.clock() - E.questAskAt < 6 then return false end
            E.questAskAt = os.clock()
            if shown and not E.dropped then
                E.dropped = true
                local cf = commF()
                if cf then pcall(function() cf:InvokeServer("AbandonQuest") end) end
                task.wait(0.4)
            end
            local cls = askHunter()
            shown, isElite = eliteQuestShown()
            if isElite then return true end
            if cls == "unknown" and not E.npcVisited then
                E.npcVisited = true
                setState("FLY")
                say("to the Elite Hunter for the quest (asking from here got no answer)")
                flyTo(ELITE_NPC + Vector3.new(0, 3, 0))
                if stale(myEpoch) then return false end
                task.wait(0.5)
                askHunter()
                shown, isElite = eliteQuestShown()
                return isElite
            end
            return false
        end

        -- A fresh look in this server (arrival, or after the last one went down).
        local function lookAgain()
            E.lookStart, E.foundHere, E.asks, E.reply, E.replyText = os.clock(), false, 0, nil, nil
            E.isleTried, E.missSince = false, nil
            -- The Fire Flower clock starts again at the next kill.
            E.flowerFirstKill, E.flowerKills0, E.flowerAtCamp = nil, stats.kills, nil
        end

        -- FRUITS ON THE GROUND (probed in game 2026-09-28): a Tool in
        -- workspace, seen map-wide, Name "X Fruit", attribute OriginalName
        -- "X-X"; a player's drop also carries DroppedBy / DroppedAt / ItemId.
        -- Prices: the game's own list (GetFruits gives every fruit with its
        -- price; OnSale marks today's stock), read every 5 minutes.
        local prices, pricesAt = {}, -1e9
        local function priceOf(orig)
            if os.clock() - pricesAt > 300 then
                pricesAt = os.clock()
                local cf = commF()
                local ok, res = pcall(function() return cf and cf:InvokeServer("GetFruits", false) end)
                if ok and type(res) == "table" then
                    for _, f in pairs(res) do
                        if type(f) == "table" and f.Name then prices[f.Name] = tonumber(f.Price) end
                    end
                end
            end
            return prices[orig]
        end

        local function fruitsLying()
            local out, now = {}, os.clock()
            for _, c in ipairs(workspace:GetChildren()) do
                if c:IsA("Tool") and not (E.fruitSkip[c] and now < E.fruitSkip[c]) then
                    local orig = c:GetAttribute("OriginalName")
                    local h = c:FindFirstChild("Handle")
                    if orig and h then
                        local dropper = c:GetAttribute("DroppedBy")
                        local near = false
                        if dropper then
                            for _, pl in ipairs(Players:GetPlayers()) do
                                local rr = pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
                                if rr and (rr.Position - h.Position).Magnitude < 30 then near = true break end
                            end
                        end
                        table.insert(out, { tool = c, orig = orig, name = c.Name, price = priceOf(orig),
                            dropper = dropper, dropperNear = near, pos = h.Position })
                    end
                end
            end
            return out
        end
        P.fruitsLying = fruitsLying

        local function fruitWanted()
            if not (CFG.Hunt and CFG.HuntKind == "fruit") then return nil end
            return pickFruit(fruitsLying(), CFG.FruitMinPrice, CFG.FruitPlayerDrops)
        end
        P.fruitWanted = fruitWanted

        -- Fly onto it, touch it, and put it away at once: never left in your
        -- hand (a click with it held EATS it), then StoreFruit with the name
        -- the game gave it. Not stored = said so; it stays in your backpack.
        local function grabFruit(f, myEpoch)
            local h = f.tool:FindFirstChild("Handle")
            if not h then E.fruitSkip[f.tool] = os.clock() + 30 return end
            E.fruitNote = string.format("going for %s  (%s, %s)", f.name,
                f.price and ("$" .. tostring(f.price)) or "price unknown",
                f.dropper and ("dropped by " .. tostring(f.dropper)) or "server spawn")
            E.note = E.fruitNote
            say(E.fruitNote)
            releasePile()
            setState("FRUIT")
            flyTo(h.Position)
            if stale(myEpoch) then return end
            local bp = player:FindFirstChild("Backpack")
            local t0 = os.clock()
            while os.clock() - t0 < 6 and not stale(myEpoch) and f.tool.Parent == workspace do
                local _, r = parts()
                if r then
                    lockAt(h.Position)
                    if firetouchinterest then
                        pcall(firetouchinterest, r, h, 0)
                        pcall(firetouchinterest, r, h, 1)
                    end
                end
                task.wait(0.15)
            end
            local where = f.tool.Parent
            if where == workspace then
                E.fruitSkip[f.tool] = os.clock() + 60
                E.fruitNote = f.name .. ": could not pick it up - left for a minute"
            elseif not (where == player.Character or where == bp) then
                E.fruitNote = f.name .. ": someone else took it first"
            else
                local _, _, hum = parts()
                if hum and where == player.Character then
                    pcall(function() hum:UnequipTools() end)
                    task.wait(0.1)
                end
                local cf = commF()
                local ok, res = pcall(function() return cf and cf:InvokeServer("StoreFruit", f.orig, f.tool) end)
                task.wait(0.6)
                if not (f.tool.Parent == player.Character or f.tool.Parent == bp) then
                    E.tally.fruits += 1
                    E.fruitNote = "STORED " .. f.orig .. (f.price and ("  ($" .. tostring(f.price) .. ")") or "")
                    notify("Fruit stored: " .. f.orig)
                else
                    E.fruitNote = f.orig .. " picked up but NOT stored (" .. tostring(ok and res or "error")
                        .. ") - it is in your backpack"
                end
            end
            E.note = E.fruitNote
            say(E.fruitNote)
        end

        -- BERRIES in this server: every tagged bush with one on it. The berry
        -- is a Model inside the bush; no Model = the bush's own spot.
        local CollectionService = game:GetService("CollectionService")
        local function berriesLying()
            local out, now = {}, os.clock()
            local ok, tagged = pcall(function() return CollectionService:GetTagged("BerryBush") end)
            if not ok or type(tagged) ~= "table" then return out end
            for _, bush in ipairs(tagged) do
                if not (E.berrySkip[bush] and now < E.berrySkip[bush]) then
                    local okA, attrs = pcall(function() return bush:GetAttributes() end)
                    local names = berryNames(okA and attrs or nil)
                    if #names > 0 then
                        local okP, pos = pcall(function()
                            local m = bush:FindFirstChildOfClass("Model")
                            return (m and m:GetPivot().Position) or bush.Parent:GetPivot().Position
                        end)
                        if okP and pos then table.insert(out, { bush = bush, names = names, pos = pos }) end
                    end
                end
            end
            return out
        end
        P.berriesLying = berriesLying

        -- How many of each berry you hold (the game's inventory list: Name,
        -- Count). Read by the hunt, never by the panel (a server call).
        local function berryCounts()
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if not (ok and type(inv) == "table") then return E.have end
            local t = { read = true }
            for _, it in pairs(inv) do
                if type(it) == "table" and IS_BERRY[it.Name] then t[it.Name] = tonumber(it.Count) or 0 end
            end
            E.have = t
            return t
        end

        -- The nearest bush with a berry you switched on. One you hold 99 of
        -- (the most the game keeps) is not wanted.
        local function berryWanted()
            if not (CFG.Hunt and CFG.HuntKind == "berry") then return nil end
            local _, r = parts()
            if not r then return nil end
            local want = {}
            for n, on in pairs(CFG.BerryWant or {}) do
                if on and not (E.have.read and (E.have[n] or 0) >= 99) then want[n] = true end
            end
            return pickBerry(berriesLying(), want, r.Position)
        end
        P.berryWanted = berryWanted

        -- Hold a prompt the way a player does: InputHoldBegin, the prompt's own
        -- HoldDuration (and a little), InputHoldEnd. Berries and Fire Flowers.
        local function holdPrompt(pr, myEpoch)
            local d = tonumber(pr.HoldDuration) or 0
            if not pcall(function() pr:InputHoldBegin() end) then return end
            local th = os.clock()
            while os.clock() - th < d + 0.25 and not stale(myEpoch) do task.wait(0.05) end
            pcall(function() pr:InputHoldEnd() end)
        end

        -- Fly to the bush and HOLD each berry's prompt the way a player does
        -- (InputHoldBegin, the prompt's own HoldDuration, InputHoldEnd),
        -- standing at it, until the bush names none. NOT the executor's
        -- fireproximityprompt first: by the sUNC spec it triggers INSTANTLY,
        -- skipping the hold and the distance, and a game's server can refuse
        -- exactly that (2026-09-30: on Velocity about half the berries were
        -- never picked; Solara's version held). It stays the fallback, every
        -- third try. ~15 s while the berry is still there. Picked = your count
        -- went up; gone without that = someone else, or the count cannot be read.
        local function grabBerry(b, myEpoch)
            E.berryNote = "going for " .. table.concat(b.names, " + ")
            E.note = E.berryNote
            say(E.berryNote)
            releasePile()
            setState("BERRY")
            local had = {}
            for k, v in pairs(berryCounts()) do had[k] = v end
            flyTo(b.pos + Vector3.new(0, 3, 0))
            if stale(myEpoch) then return end
            local t0, tries, way, sawPrompt = os.clock(), 0, "hold", false
            while os.clock() - t0 < 15 and not stale(myEpoch) do
                local okA, attrs = pcall(function() return b.bush:GetAttributes() end)
                if not okA or #berryNames(attrs) == 0 then break end
                tries += 1
                -- hold, hold, the instant fire; again
                local useFire = fireproximityprompt and tries % 3 == 0
                way = useFire and "fireproximityprompt" or "hold"
                local prompts = {}
                pcall(function()
                    for _, d in ipairs(b.bush:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
                    end
                end)
                sawPrompt = sawPrompt or #prompts > 0
                for _, pr in ipairs(prompts) do
                    if stale(myEpoch) then break end
                    local at = b.pos
                    pcall(function()
                        local p = pr.Parent
                        if p:IsA("BasePart") then at = p.Position
                        elseif p:IsA("Attachment") then at = p.WorldPosition
                        elseif p:IsA("Model") then at = p:GetPivot().Position end
                    end)
                    lockAt(at + Vector3.new(0, 3, 0))
                    task.wait(0.1)
                    if useFire then pcall(fireproximityprompt, pr) else holdPrompt(pr, myEpoch) end
                end
                task.wait(0.3)
            end
            local okA, attrs = pcall(function() return b.bush:GetAttributes() end)
            local left = berryNames(okA and attrs or nil)
            local now = berryCounts()
            local got, n = {}, 0
            for _, name in ipairs(b.names) do
                local up = (now[name] or 0) - (had[name] or 0)
                if up > 0 and not table.find(got, name) then
                    table.insert(got, name)
                    n += up
                end
            end
            if n > 0 then
                E.tally.berries = (E.tally.berries or 0) + n
                E.berryNote = "PICKED " .. table.concat(got, " + ") .. "  (by " .. way .. ", try " .. tries .. ")"
                notify("Berry: " .. table.concat(got, " + "))
            elseif #left == 0 then
                E.berryNote = table.concat(b.names, " + ") .. ": gone from the bush, your count did not go up"
                    .. (now.read and "" or " (inventory not readable)")
            else
                E.berrySkip[b.bush] = os.clock() + 60
                E.berryNote = table.concat(left, " + ") .. ": could not pick in " .. tries
                    .. (tries == 1 and " try" or " tries")
                    .. (sawPrompt and "" or " (no prompt on the bush)") .. " - left for a minute"
            end
            E.note = E.berryNote
            say(E.berryNote)
            print("[BFF] berry: " .. E.berryNote)
        end

        -- AURA RECIPES: the Barista Cousin (Second and Third Sea) teaches ONE
        -- recipe per server. He comes 20 min after a server starts, stays 20,
        -- is gone 2, and again. Asking works from anywhere (the public hubs'
        -- own check): CommF_("ColorsDealer", "1") -> the recipe's name (and a
        -- rarity, 3 and up = Legendary) while he is there, anything else
        -- while he is not; ("ColorsDealer", "2") learns it.
        local function cousinOffer()
            local cf = commF()
            if not cf then return nil, nil end
            -- Not `cf and cf:InvokeServer(...)`: `and` keeps only the first
            -- value, and the rarity is the second.
            local ok, name, rarity = pcall(function() return cf:InvokeServer("ColorsDealer", "1") end)
            if ok and type(name) == "string" and name ~= "" then return name, tonumber(rarity) end
            return nil, nil
        end

        -- Where he stands, if the game has him loaded (or parked).
        local function cousinAt()
            local folders = { workspace:FindFirstChild("NPCs"), RS:FindFirstChild("NPCs") }
            for i = 1, 2 do
                local m = folders[i] and folders[i]:FindFirstChild("Barista Cousin")
                if m then
                    local ok, p = pcall(function() return m:GetPivot().Position end)
                    if ok and p then return p end
                end
            end
            return nil
        end

        -- true = busy with it here; false = nothing for it here (E.why says).
        -- Learned = its switch goes off and the hunt goes on for the others.
        -- Not learned = the hunt STOPS and says why: another server would not
        -- change fragments or Aura stage.
        local function recipeStep(myEpoch)
            local any = false
            for _, on in pairs(CFG.RecipeWant or {}) do
                if on then any = true break end
            end
            if not any then
                E.recipeNote = "every recipe you picked is learned - pick another"
                E.note = E.recipeNote
                P.stop("recipes done")
                return true
            end
            if mySea() == 1 then
                E.why = "no Barista Cousin in the First Sea"
                return false
            end
            local name, rarity = cousinOffer()
            E.offer = name and (name .. (((rarity or 0) >= 3) and "  (Legendary)" or "")) or "he is not here now"
            if not name then
                E.why = "the Barista Cousin is not here now"
                return false
            end
            if not CFG.RecipeWant[name] then
                E.why = "he teaches " .. name .. " here - not one you picked"
                return false
            end
            E.recipeNote = "he teaches " .. name .. " here - learning it"
            E.note = E.recipeNote
            say(E.note)
            setState("RECIPE")
            local cf = commF()
            local ok, res = pcall(function() return cf and cf:InvokeServer("ColorsDealer", "2") end)
            if not (ok and (res == 1 or res == 2)) then
                -- Not from here: from in front of him.
                local at = cousinAt()
                if at then
                    releasePile()
                    flyTo(at + Vector3.new(0, 3, 0))
                    if stale(myEpoch) then return true end
                    ok, res = pcall(function() return cf and cf:InvokeServer("ColorsDealer", "2") end)
                end
            end
            local words = ok and buyWords(res) or ("error: " .. tostring(res))
            if ok and (res == 1 or res == 2) then
                CFG.RecipeWant[name] = false
                E.tally.recipes = (E.tally.recipes or 0) + 1
                E.recipeNote = name .. ": " .. words
                notify("Aura recipe: " .. name)
            else
                E.recipeNote = name .. ": NOT learned - " .. words .. "  (Aura stage 5 and the price are needed)"
                print("[BFF] recipe: " .. E.recipeNote)
                E.note = E.recipeNote
                P.stop("recipe not learned")
                return true
            end
            E.note = E.recipeNote
            say(E.note)
            print("[BFF] recipe: " .. E.recipeNote)
            return true
        end
        P.cousinOffer = cousinOffer

        -- FIRE FLOWERS (Draco V2: the Dragon Wizard wants 5 and $1,000,000).
        -- While his V2 quest runs, any Third Sea kill can drop one (Fandom,
        -- 2026-10): it comes up from the ground a while after the kill, for
        -- YOU only, and has to be picked like a berry. Then that server gives
        -- none for 5-15 min; a new server, at once. Three public hubs (2026)
        -- agree where it lies: a Model in workspace.FireFlowers (PrimaryPart,
        -- or a MeshPart inside) with a ProximityPrompt in it. So: kill them one
        -- at a time where they stand, pick the flower the moment it lies
        -- there, next server. Forest + Mythological Pirates on Floating Turtle
        -- (the user's two came from there; the hubs farm Forest Pirates).
        local FLOWER_MOBS = { "Forest Pirate", "Mythological Pirate" }
        local FLOWER_SET = {}
        for _, n in ipairs(FLOWER_MOBS) do FLOWER_SET[n] = true end

        -- Every flower lying there, but the ones given up on: { model, pos }.
        local function flowersLying()
            local out = {}
            local folder = workspace:FindFirstChild("FireFlowers")
            if not folder then return out end
            for _, m in ipairs(folder:GetChildren()) do
                local part = m:IsA("BasePart") and m or nil
                if not part and m:IsA("Model") then
                    part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
                end
                if part and not E.flowerSkip[m] then
                    table.insert(out, { model = m, pos = part.Position })
                end
            end
            return out
        end
        P.flowersLying = flowersLying

        -- How many you hold (the game's inventory list). nil = not readable.
        local function flowerCount()
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if not (ok and type(inv) == "table") then return nil end
            local n = 0
            for _, it in pairs(inv) do
                if type(it) == "table" and it.Name == "Fire Flower" then n = tonumber(it.Count) or 0 end
            end
            E.flowerHave = n
            return n
        end

        -- Onto it, and hold its prompt like a player (holdPrompt, as the
        -- berries), the instant fireproximityprompt every third try; ~15 s.
        -- "picked" = your count went up (unreadable: it left the folder);
        -- "gone" = it went, the count did not; "stuck" = still there.
        local function grabFlower(f, myEpoch)
            releasePile()
            setState("FLOWER")
            E.flowerNote = "a Fire Flower is lying here - going for it"
            E.note = E.flowerNote
            say(E.note)
            local had = flowerCount()
            local over = f.pos + Vector3.new(0, 3, 0)
            flyTo(over)
            if stale(myEpoch) then return "stopped" end
            local t0, tries, way, sawPrompt = os.clock(), 0, "hold", false
            while os.clock() - t0 < 15 and f.model.Parent and not stale(myEpoch) do
                tries += 1
                local useFire = fireproximityprompt and tries % 3 == 0
                way = useFire and "fireproximityprompt" or "hold"
                local prompts = {}
                pcall(function()
                    for _, d in ipairs(f.model:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
                    end
                end)
                sawPrompt = sawPrompt or #prompts > 0
                lockAt(over)
                task.wait(0.1)
                for _, pr in ipairs(prompts) do
                    if stale(myEpoch) or not f.model.Parent then break end
                    if useFire then pcall(fireproximityprompt, pr) else holdPrompt(pr, myEpoch) end
                end
                task.wait(0.3)
            end
            if stale(myEpoch) then return "stopped" end
            local now = flowerCount()
            -- It flies to you before the inventory says so: a moment for that.
            local settle = os.clock()
            while had and now and now <= had and not f.model.Parent
                and os.clock() - settle < 2 and not stale(myEpoch) do
                task.wait(0.5)
                now = flowerCount()
            end
            local res
            if had and now then
                res = (now > had) and "picked" or (f.model.Parent and "stuck" or "gone")
            else
                res = f.model.Parent and "stuck" or "picked"
            end
            if res == "picked" then
                E.tally.flowers = (E.tally.flowers or 0) + 1
                E.flowerNote = string.format("PICKED a Fire Flower - you have %s  (by %s, try %d)",
                    now and tostring(now) or "?", way, tries)
                notify("Fire Flower: " .. (now and tostring(now) or "+1"))
            elseif res == "gone" then
                E.flowerNote = "the flower went, your count did not go up"
            else
                E.flowerNote = string.format("could not pick it in %d %s%s", tries,
                    tries == 1 and "try" or "tries", sawPrompt and "" or " (no prompt in it)")
            end
            E.note = E.flowerNote
            say(E.note)
            print("[BFF] flower: " .. E.flowerNote)
            return res
        end

        -- THE CLOCK (user, 2026-10-04): from the FIRST kill in this server,
        -- straight through (respawn waits count) - not from the join: flying
        -- in and loading do not count. 2.5 min = 50-60+ kills. Nothing died 3
        -- min after reaching the camp: leave anyway, or it would never start.
        -- Why to leave this server without a flower, or nil.
        local function flowerGiveUp()
            if not E.flowerFirstKill and stats.kills > (E.flowerKills0 or 0) then
                E.flowerFirstKill = os.clock()
            end
            local now = os.clock()
            if E.flowerFirstKill then
                local limit = (CFG.FlowerGiveUp or 2.5) * 60
                if now - E.flowerFirstKill >= limit then
                    return string.format("no Fire Flower %g min after the first kill", limit / 60)
                end
            elseif E.flowerAtCamp and now - E.flowerAtCamp >= 180 then
                return "nothing died here in 3 min"
            end
            return nil
        end

        -- The fight's reason to stop now: a flower lies there, or time is up.
        local function flowerBreak()
            return #flowersLying() > 0 or flowerGiveUp() ~= nil
        end

        -- No flower lying: the nearest Forest / Mythological Pirate, WHERE IT
        -- STANDS, one at a time (refreshPile: pileCur.flower). None loaded: to
        -- their camps in turn.
        local function flowerFarm(myEpoch)
            local any = false
            for _, n in ipairs(FLOWER_MOBS) do
                if nearestLoaded(n) then any = true break end
            end
            if not any then
                E.flowerTurn = (E.flowerTurn or 0) % #FLOWER_MOBS + 1
                local name = FLOWER_MOBS[E.flowerTurn]
                local row = rowOf(name)
                local dest = campOf(name, row and row[4])
                if not dest then
                    E.flowerNote = "cannot find where " .. name .. " lives"
                    say(E.flowerNote)
                    task.wait(1)
                    return
                end
                releasePile()
                setState("FLY")
                say("to the " .. name .. "s for Fire Flowers")
                flyTo(dest + Vector3.new(0, CFG.HeightSafe or 20, 0), { stream = name })
                -- The no-kill clock runs from the first arrival: camps that never
                -- load must not be flown between for ever.
                if not stale(myEpoch) then E.flowerAtCamp = E.flowerAtCamp or os.clock() end
                return
            end
            E.flowerAtCamp = E.flowerAtCamp or os.clock()
            activeName = "Fire Flowers"
            fight({ name = "Fire Flowers", flower = true, breakIf = flowerBreak }, FLOWER_SET)
        end

        -- true = busy here; false = leave this server (E.why says why). Hop
        -- off: never leaves - the next flower comes after the cooldown.
        local function flowerStep(myEpoch)
            local sea = mySea()
            if sea and sea ~= 3 then
                E.flowerNote = "Fire Flowers drop only in the Third Sea - hunt stopped"
                E.note = E.flowerNote
                say(E.note)
                P.stop("Fire Flowers: not the Third Sea")
                return true
            end
            local f = flowersLying()[1]
            if f then
                local res = grabFlower(f, myEpoch)
                if res == "stopped" then return true end
                if res == "stuck" then
                    local n = (E.flowerTries[f.model] or 0) + 1
                    E.flowerTries[f.model] = n
                    if n < 3 then return true end         -- again
                    E.flowerSkip[f.model] = true
                end
                -- A flower came here: none for 5-15 min.
                E.keepAway = 600
                E.why = (res == "picked") and "Fire Flower picked - none here for 5-15 min"
                    or "a Fire Flower came here - none for 5-15 min"
                if CFG.HuntHop then return false end
                E.flowerFirstKill, E.flowerKills0, E.flowerAtCamp = nil, stats.kills, nil
                return true
            end
            local why = flowerGiveUp()
            if why then
                if CFG.HuntHop then
                    E.why = why
                    return false
                end
                E.flowerFirstKill, E.flowerKills0, E.flowerAtCamp = nil, stats.kills, nil
            end
            flowerFarm(myEpoch)
            return true
        end

        local function eliteFight(name, at, where, myEpoch)
            activeName = name
            if CFG.EliteQuest then takeEliteQuest(myEpoch) end
            if stale(myEpoch) then return end
            local e = nearestLoaded(name)
            local _, r = parts()
            if not r then return end
            local target = e and e.root.Position or at
            local over = target + Vector3.new(0, CFG.HeightSafe or 20, 0)
            if (r.Position - over).Magnitude > 150 and not (pileCentre and pileFor == name) then
                releasePile()
                setState("FLY")
                say(string.format("flying to %s  (%s)", name, where == "parked" and "parked by the game" or "loaded"))
                flyTo(over, { stream = name })
                if stale(myEpoch) then return end
                e = nearestLoaded(name)
            end
            if not e then
                -- Listed as up, not here. A parked entry that does not turn up in
                -- 10 s at its spot is not believed for a minute (bossUp's rule).
                E.missSince = E.missSince or os.clock()
                if os.clock() - E.missSince > 10 then
                    P.bossStale[name] = os.clock() + 60
                    E.missSince = nil
                end
                say(name .. " is listed as up but is not here yet")
                task.wait(0.3)
                return
            end
            E.missSince = nil
            local model, hum = e.model, e.hum
            local why = fight({ name = name, elite = true }, { [name] = true })
            if why ~= "empty" then return end                 -- hurt / 30 s sweep / a fruit: the next step
            if not (hum.Health <= 0 or model.Parent == nil) then return end   -- walked off / parked: look again
            E.tally.kills += 1
            releasePile()
            say(name .. " is down - looking for the chalice")
            local t0 = os.clock()
            while os.clock() - t0 < 4 and not stale(myEpoch) do
                if holdingChalice() then chaliceStop() return end
                task.wait(0.2)
            end
            pcall(readProgress)
            E.lastKill = name .. " down, no chalice"
            -- The next one here is 8 min 45 s away: not looked for till then.
            -- The director hops (or, hop off, waits) when nothing else is here.
            E.eliteDoneUntil = os.clock() + 480
            E.why = name .. " down, no chalice"
        end

        -- THE ELITE TARGET. true = busy with it this step; false = nothing to
        -- do about elites here (E.why says why).
        local function eliteLook(myEpoch)
            local sea = mySea()
            if sea and sea ~= 3 then
                E.why = "no elites outside the Third Sea"
                return false
            end
            if os.clock() < E.eliteDoneUntil then return false end

            local name, at, where = eliteUp()
            -- The Elite Hunter: once on arrival, then every 15 s while nothing is
            -- seen. Its word is the second opinion, and asking takes the quest.
            if E.asks == 0 or (not name and os.clock() - E.askAt > 15) then askHunter() end

            if name then
                if not E.foundHere then
                    E.foundHere = true
                    E.tally.found += 1
                end
                E.note = string.format("%s is up (%s)", name, where == "parked" and "parked by the game" or "loaded")
                eliteFight(name, at, where, myEpoch)
                return true
            end

            local waited = os.clock() - E.lookStart
            if E.reply == "up" then
                -- It names one nobody can see: over the island it names, and look.
                local isle, pos = eliteIsle(E.replyText)
                if pos and not E.isleTried then
                    E.isleTried = true
                    releasePile()
                    setState("FLY")
                    say("the Elite Hunter says " .. isle .. " - flying over it")
                    flyTo(pos)
                    return true
                end
                if waited < 45 then
                    E.note = string.format("the Elite Hunter says one is up - looking  %.0fs", waited)
                    say(E.note)
                    setState("LOOK")
                    task.wait(0.5)
                    return true
                end
            else
                local need = (E.reply == "none") and math.min(3, CFG.EliteLook or 8) or (CFG.EliteLook or 8)
                if waited < need then
                    E.note = string.format("looking for an elite  %.0fs  ·  Elite Hunter: %s", waited, E.reply or "asking")
                    say(E.note)
                    setState("LOOK")
                    task.wait(0.25)
                    return true
                end
            end
            E.why = (E.reply == "none") and "no elite up here" or "no elite seen here"
            return false
        end

        -- THE DIRECTOR. Every step: the chalice stops everything; then ONLY
        -- the hunt you switched on (the user picks, nothing is ranked for
        -- them); nothing for it here = the next server (or, hop off, wait).
        function huntStep()
            local myEpoch = epoch
            if E.chalice or holdingChalice() then
                chaliceStop()
                task.wait(0.5)
                return
            end
            E.used = true
            local kind = CFG.HuntKind
            if not E.lookStart then
                lookAgain()
                if kind == "elite" then pcall(readProgress) end
                if kind == "berry" then pcall(berryCounts) end
                if kind == "flower" then pcall(flowerCount) end
            end

            -- ONLY the hunt you switched on.
            if kind == "fruit" then
                local f = fruitWanted()
                if f then
                    grabFruit(f, myEpoch)
                    return
                end
                E.why = "no fruit worth it here"
            elseif kind == "berry" then
                local b = berryWanted()
                if b then
                    grabBerry(b, myEpoch)
                    return
                end
                E.why = "no berry you want here"
            elseif kind == "recipe" then
                if recipeStep(myEpoch) then return end
            elseif kind == "flower" then
                if flowerStep(myEpoch) then return end
            elseif kind == "ember" then
                -- BLAZE EMBERS: always busy (never hops) - EMBER HUNT.
                if (P :: any).ember.step(myEpoch) then return end
            elseif kind == "prehistoric" or kind == "mirage" or kind == "dealer"
                or kind == "mchest" or kind == "gear" or kind == "sail" then
                -- SEA HUNT: true while it sails (or holds the island); false
                -- = nothing came by the far edge, E.why says so. Sea travel
                -- ("sail"): always true.
                if (P :: any).sea.huntStep(myEpoch, kind) then return end
            elseif kind == "seaevents" then
                -- SEA EVENTS: always busy (never hops).
                if (P :: any).seaev.step(myEpoch) then return end
            elseif eliteLook(myEpoch) then
                return
            end

            -- Nothing worth doing here. A moment after a join first: the
            -- world is still arriving.
            local waited = os.clock() - E.lookStart
            if waited < 3 then
                E.note = string.format("looking  %.0fs", waited)
                say(E.note)
                setState("LOOK")
                task.wait(0.25)
                return
            end
            if CFG.HuntHop then
                hop(E.why or "nothing worth doing here", E.keepAway)
                task.wait(2)          -- still here: the hop failed; do not hammer it
            else
                E.note = tostring(E.why or "nothing here") .. " - waiting (hop is off)"
                say(E.note)
                setState("WAIT")
                task.wait(1)
            end
        end

        -- The hunt switches. `kind` = which hunt ("elite" / "fruit" / "berry");
        -- one on turns the others off. Off: the next server's copy does not
        -- start by itself.
        function P.setHunt(x, kind)
            if kind then CFG.HuntKind = kind end
            P.handsOff = false           -- a hunt changed: the farm drives again
            CFG.Hunt = x and true or false
            -- The Prehistoric hunt's 21-min clock starts again with the switch.
            if x and (P :: any).sea then (P :: any).sea.sailStart = nil end
            -- A Mirage hunt switched on: its job from the start, on the same
            -- Mirage too (one done before would otherwise sit there, done).
            if x and (P :: any).sea and (P :: any).sea.mirage then (P :: any).sea.mirage.kind = nil end
            releasePile()
            if x then
                CFG.RaidMode, CFG.RandomMode = false, false
                E.used = true
                lookAgain()
                E.note = tostring(CFG.HuntKind) .. " hunt on"
            else
                carryOff()
                -- The boat stops with the hunt; you stay in your seat.
                if (P :: any).sea then (P :: any).sea.driving = false end
                E.note = "hunt off"
            end
            say(E.note)
        end
    end
    build()
end

-- =========================================================
-- SEA HUNT
-- =========================================================
-- THE PREHISTORIC HUNT (Third Sea; HuntKind "prehistoric"). The island
-- spawns only round a boat in Sea Danger 6 (the wiki, 2026-09). So: a boat
-- bought at Tiki Outpost's BACK dealer -- CommF_("BuyBoat", "Beast Hunter")
-- answers 1 there (the user's probe, 2026-10-04) -- you put in its
-- VehicleSeat, and the boat moved west every frame at SeaSpeed: its pivot
-- written, its collisions off, the body lock let go (the seat holds you).
-- Sea events are driven through, not fought. Distance is counted from that
-- dealer, in the compass's meters (SeaStudsPerM). The island up (its
-- _WorldOrigin.Locations marker, or workspace.Map.PrehistoricIsland) = the
-- boat is left and you go onto the island: it despawns with nobody on it.
-- Nothing by SeaSearchTo = the next server.
--
-- THE MIRAGE HUNTS (HuntKind "mirage" / "dealer" / "mchest" / "gear"; user,
-- 2026-10-07: each its own hunt). The same boat and search until a Mirage is
-- up (Map.MysticIsland / Locations "Mirage Island"); one up already = no
-- boat. Then ONLY the hunt's job, and when it is done the character is
-- handed back to you (P.handsOff: no lock, no noclip, no keys), the farm
-- stops, you are left on the Mirage:
--   mirage   onto it
--   dealer   the Advanced Fruit Dealer, found wherever the client holds him
--            (workspace.NPCs, ReplicatedStorage.NPCs, the nil instances, the
--            island) - he stands at a random spot on it (the wiki) - else the
--            island searched until he streams in; you stand in front of his
--            face, his shop opened
--   mchest   every chest, nearest first
--   gear     MirageNeed judges the Mirage (it lives 15 min, the gear needs
--            night - off the server news' sky); your turn at the moon (climb,
--            face it, T). The Blue Gear -- the island's MeshPart 10153114969
--            (every hub 2024-26), hidden until the moon resonates -- is run
--            over the moment it shows ("run over it", the wiki). Not worth it:
--            sailed past.
--
-- THE VOLCANO EVENT (CFG.Volcano, its own switch, any mode). The public
-- hubs (2026-03 .. 2026-09) and the wiki agree on the island's insides:
--   Core.ActivationPrompt         the relic's ProximityPrompt: starts it
--   island attribute IsMinigameActive   the event is on
--   Core.VolcanoRocks             one Model per vent; LIVE when its VFXLayer
--                                 Specs / At0.Glow, an At1Beam, or its
--                                 volcanorock's red (185,53,56) says so
--   "Lava Golem"                  workspace.Enemies; one per vent closed, and
--                                 only their M1s hurt the relic
--   workspace.DinoBone, Core.SpawnedDragonEggs   the win's loot
-- THE RELIC FIRST (user's first run, 2026-10-04: lost on the relic's
-- health while vents were being closed and the golems stood on the relic).
--   GOLEMS   every one is held up in the air - GolemCage off the relic, away
--            from the volcano, GolemLift up - by its own frame holder, the
--            whole event, never put back. Held = cannot touch the relic.
--            One NOT held (just landed, or not ours to move) is the threat:
--            it goes first, fought where it stands. Held ones are killed
--            whenever no vent is open (the Attack page's weapons).
--   VENTS    closed by moves that break things (the wiki: destructible
--            physics; M1 only of Skull Guitar / Bazooka / Cannon / Gravity),
--            fired AT the vent through the silent aim - your mouse is not
--            read. Which key closes vents is LEARNED: one that closed one is
--            fired first, one that never did after 4 tries goes last.
--   METERS   the relic's health and the pressure, read where they can be
--            (a Humanoid or attributes on the relic / island, values, the
--            relic's own billboard, the screen's text) - the event's first
--            seconds write every candidate to workspace/bff_volcano_probe.txt.
--            Pressure over PressureMax with the relic over RelicMin = vents
--            before even a free golem.
-- Lava parts are taken off your client (the hubs do), the vents' own excepted.
-- Only P.sea leaves the block (the main chunk is at Luau's register limit).
do
    local function build()
        -- Typed open: its fields come as the hunt runs.
        local S: { [string]: any } = {
            driving = false, note = "off", boatNote = "no boat yet",
            meters = nil, danger = nil, hp = nil, maxHp = nil, ev = nil,
            tally = { found = 0, events = 0, vents = 0, golems = 0, bones = 0, eggs = 0, buys = 0,
                mirages = 0, gears = 0, chests = 0, dealers = 0 },
            mirage = nil,            -- the Mirage being handled: { seenAt, fits, why, landed, got, note }
        }
        P.sea = S
        local TIKI_DEALER = Vector3.new(-16928.9, 7.8, 434.6)   -- the back boat dealer (probe)
        local GOLEMS      = { ["Lava Golem"] = true }
        local VENT_KEYS   = { "Z", "X", "C", "V" }
        local TYPE_RANK   = { ["Blox Fruit"] = 1, Melee = 2, Sword = 3, Gun = 4 }
        -- Vents: shooting moves first (user: "a powerful shooting attack ...
        -- gun is better"); what really closes them is learned on top.
        local VENT_RANK   = { Gun = 1, ["Blox Fruit"] = 2, Sword = 3, Melee = 4 }
        local UP          = Vector3.new(0, 1, 0)

        -- ---------- the arithmetic (pure: tools/sea_test.py) ----------
        local function flat(v) return Vector3.new(v.X, 0, v.Z) end

        -- Meters from the Tiki dealer, the compass's unit.
        local function metersFrom(pos, studsPerM)
            return flat(pos - TIKI_DEALER).Magnitude / math.max(tonumber(studsPerM) or 10, 1)
        end

        -- West, turned `deg` degrees (positive = toward +Z).
        local function headingFor(deg)
            local a = math.rad(deg or 0)
            return Vector3.new(-math.cos(a), 0, math.sin(a))
        end

        -- The yaw a direction faces (CFrame.Angles(0, yaw, 0).LookVector = d),
        -- and the turn toward `want`, at most maxStep, the short way round.
        local function yawOf(d) return math.atan2(-d.X, -d.Z) end
        local function turnStep(cur, want, maxStep)
            local d = (want - cur + math.pi) % (2 * math.pi) - math.pi
            return math.clamp(d, -maxStep, maxStep)
        end

        -- AUTO STEERING, pure (tools/sea_test.py): the next heading (degrees
        -- off west) and how long until the turn after it. rnd() in [0,1).
        -- A third each: left, right, straight on; a turn of turnMax/2 ..
        -- turnMax; kept within +-limit (a turn past it goes the other way).
        local function nextHeading(cur, rnd, every, turnMax, limit)
            local pick = rnd()
            local amount = turnMax * (0.5 + 0.5 * rnd())
            local new = cur
            if pick < 1 / 3 then
                new = cur + amount
            elseif pick < 2 / 3 then
                new = cur - amount
            end
            if new > limit then new = cur - amount end
            if new < -limit then new = cur + amount end
            new = math.clamp(new, -limit, limit)
            return new, every * (1 + rnd())
        end

        -- THE WAY ROUND THE VOLCANO, pure (tools/sea_test.py): waypoints from
        -- `from` to `to` that never cross the disc of `radius` round `centre`
        -- (the crater's lava). The line keeps out of it: straight. Else round
        -- it at 1.25x the radius, the short way, a waypoint every 45 deg, at
        -- the higher of the two heights, then in to `to` along its own bearing
        -- (from outside, on its side - never over the middle). A short hop
        -- (under 30 studs) is straight.
        local function arcPath(from, to, centre, radius)
            if (to - from).Magnitude < 30 then return { to } end
            local a, b = flat(from - centre), flat(to - centre)
            local seg = flat(to - from)
            local t = 0
            if seg.Magnitude > 0.01 then
                t = math.clamp(-a:Dot(seg) / seg:Dot(seg), 0, 1)
            end
            if (a + seg * t).Magnitude >= radius then return { to } end
            local r = radius * 1.25
            local angA = math.atan2(a.Z, a.X)
            local angB = math.atan2(b.Z, b.X)
            if a.Magnitude < 1 then angA = angB end
            local d = (angB - angA + math.pi) % (2 * math.pi) - math.pi
            local steps = math.max(1, math.ceil(math.abs(d) / math.rad(45)))
            local y = math.max(from.Y, to.Y)
            local out = {}
            for i = 0, steps do
                local ang = angA + d * i / steps
                table.insert(out, Vector3.new(centre.X + math.cos(ang) * r, y, centre.Z + math.sin(ang) * r))
            end
            table.insert(out, to)
            return out
        end

        -- The island's edge on your side (only the far marker known): 1.6x
        -- the keep-out from its middle, toward you, 30 up.
        local function edgeOf(mk, from, radius)
            local dir = flat(from - mk)
            if dir.Magnitude < 1 then dir = Vector3.new(1, 0, 0) end
            return mk + dir.Unit * radius * 1.6 + UP * 30
        end

        -- THE SEARCH'S LEGS, pure (tools/sea_test.py). st = the drive (leg,
        -- odo0, base). Out to `to` m from Tiki ("out"); there: turn `back`
        -- degrees left ("turn" once, base += back) and sail `leg2` m more by
        -- the odometer ("back"); done = "hop". leg2 0 = "hop" at `to`.
        local function searchLeg(st, meters, odoM, to, back, leg2)
            if st.leg ~= 2 then
                if meters >= to then
                    if (leg2 or 0) <= 0 then return "hop" end
                    st.leg, st.odo0, st.base = 2, odoM, (st.base or 0) + back
                    return "turn"
                end
                return "out"
            end
            if odoM - (st.odo0 or odoM) >= leg2 then return "hop" end
            return "back"
        end

        -- Where the golems are held: `dist` off the relic, on the far side from
        -- the volcano (the beach side).
        local function cageSpot(relic, volcano, dist)
            local away = flat(relic - volcano)
            if away.Magnitude < 1 then away = Vector3.new(0, 0, 1) end
            return relic + away.Unit * dist
        end

        -- Where to stand for a vent: out from the volcano's middle, and up.
        local function standFor(vent, volcano, dist)
            local out = flat(vent - volcano)
            if out.Magnitude < 1 then out = Vector3.new(1, 0, 0) end
            return vent + out.Unit * dist + UP * 8
        end

        -- What the event needs now.
        local function phase(active, promptOn, lootLeft)
            if active then return "defend" end
            if lootLeft then return "loot" end
            if promptOn then return "start" end
            return "idle"
        end

        -- While it is on. o = { vent, free (a golem NOT held: it can reach the
        -- relic), held, relic %, pressure %, relicMin, pressureMax }.
        --   a free golem first - unless the pressure is over its limit while
        --   the relic is still healthy (or unread): then the vent
        --   a vent next; held golems when nothing else
        local function defendPick(o)
            local pressing = o.vent and o.pressure ~= nil and o.pressure >= (o.pressureMax or 70)
                and (o.relic == nil or o.relic >= (o.relicMin or 90))
            if o.free and not pressing then return "golem" end
            if o.vent then return "vent" end
            if o.free or o.held then return "golem" end
            return "wait"
        end

        -- A meter's percent from a value (0-1 = a fraction, 0-100 = percent,
        -- or out of `max`), or from text ("73%", "1460/2000").
        local function pctFrom(v, max)
            v = tonumber(v)
            if not v then return nil end
            local m = tonumber(max)
            if m and m > 0 then return v / m * 100 end
            if v >= 0 and v <= 1 then return v * 100 end
            if v >= 0 and v <= 100 then return v end
            return nil
        end
        local function pctText(t)
            if type(t) ~= "string" then return nil end
            local a, b = string.match(t, "([%d%.]+)%s*/%s*([%d%.]+)")
            local na, nb = tonumber(a), tonumber(b)
            if na and nb and nb > 0 then return na / nb * 100 end
            local p = string.match(t, "([%d%.]+)%s*%%")
            return p and tonumber(p) or nil
        end

        local function enabled(x)
            if not x then return false end
            local ok, v = pcall(function() return x.Enabled end)
            return ok and v == true
        end

        -- A vent is live: any of the four signs the public hubs read.
        local function ventLive(c)
            local vfx = c:FindFirstChild("VFXLayer")
            if vfx then
                if enabled(vfx:FindFirstChild("Specs")) then return true end
                local at0 = vfx:FindFirstChild("At0")
                if at0 and enabled(at0:FindFirstChild("Glow")) then return true end
            end
            if enabled(c:FindFirstChild("At1Beam", true)) then return true end
            local rock = c:FindFirstChild("volcanorock", true)
            if rock and rock:IsA("BasePart") then
                local col = rock.Color
                if math.abs(col.R * 255 - 185) < 1.5 and math.abs(col.G * 255 - 53) < 1.5
                    and math.abs(col.B * 255 - 56.5) < 1.5 then
                    return true
                end
            end
            return false
        end

        local function posOf(inst)
            if not inst then return nil end
            if inst:IsA("BasePart") then return inst.Position end
            local ok, cf = pcall(function() return inst:GetPivot() end)
            return ok and cf and cf.Position or nil
        end

        -- ---------- what the game shows ----------
        local function island()
            local map = workspace:FindFirstChild("Map")
            return (map and map:FindFirstChild("PrehistoricIsland")) or workspace:FindFirstChild("PrehistoricIsland")
        end
        local function marker()
            local wo = workspace:FindFirstChild("_WorldOrigin")
            local loc = wo and wo:FindFirstChild("Locations")
            return posOf(loc and loc:FindFirstChild("Prehistoric Island"))
        end
        local function core(isle) return isle and isle:FindFirstChild("Core") end
        local function mirageIsle()
            local map = workspace:FindFirstChild("Map")
            return (map and map:FindFirstChild("MysticIsland")) or workspace:FindFirstChild("MysticIsland")
        end
        local function mirageMarker()
            local wo = workspace:FindFirstChild("_WorldOrigin")
            local loc = wo and wo:FindFirstChild("Locations")
            return posOf(loc and loc:FindFirstChild("Mirage Island"))
        end

        -- THE BLUE GEAR: the island's MeshPart with the gear's mesh; second
        -- value true when found by that mesh. Else its child MeshPart named
        -- "Part" (two hubs find it so) - trusted only once seen hidden first.
        local GEAR_MESH = "10153114969"
        local function blueGear(isle)
            if not isle then return nil, false end
            local named = nil
            for _, c in ipairs(isle:GetChildren()) do
                if c:IsA("MeshPart") then
                    local ok, id = pcall(function() return tostring(c.MeshId) end)
                    if ok and string.find(id, GEAR_MESH, 1, true) then return c, true end
                    if c.Name == "Part" then named = named or c end
                end
            end
            return named, false
        end

        local function mmss(sec)
            sec = math.max(0, math.floor(sec or 0))
            return string.format("%d:%02d", sec // 60, sec % 60)
        end

        -- IS THIS MIRAGE WORTH STOPPING FOR? It lives `life` more seconds; the
        -- gear needs night (and the full moon, "full") with `margin` seconds to
        -- climb and resonate. sky = the server news' (night, edge = real
        -- seconds to the next dusk / dawn, full, nights = 0: the full moon
        -- rises tonight).
        local function mirageFits(need, sky, life, margin)
            if need == "any" then return true, "every Mirage is taken" end
            if not sky or sky.edge == nil then return true, "the sky is not read yet - taken" end
            if sky.night then
                if need == "full" and not sky.full then return false, "night, but not the full moon" end
                local usable = math.min(life, sky.edge)
                if usable >= margin then return true, "night now - " .. mmss(usable) .. " to use" end
                return false, "night ends in " .. mmss(sky.edge) .. " - too soon"
            end
            if need == "full" and sky.nights ~= 0 then return false, "tonight is not the full moon" end
            local spare = life - sky.edge
            if spare >= margin then
                return true, "night in " .. mmss(sky.edge) .. ", the Mirage lasts " .. mmss(spare) .. " into it"
            end
            return false, "night in " .. mmss(sky.edge) .. " - the Mirage is gone before (15 min at most)"
        end

        local function relicPos(isle)
            local rel = core(isle) and core(isle):FindFirstChild("PrehistoricRelic")
            return posOf(rel and (rel:FindFirstChild("Skull") or rel))
        end
        local function promptOf(isle)
            local c = core(isle)
            local ap = c and c:FindFirstChild("ActivationPrompt", true)
            local pp = ap and ap:FindFirstChildWhichIsA("ProximityPrompt", true)
            return pp, posOf(ap)
        end
        local function ventPos(c) return posOf(c:FindFirstChild("VFXLayer")) or posOf(c) end
        local function rocks(isle)
            local vr = core(isle) and core(isle):FindFirstChild("VolcanoRocks")
            return vr and vr:GetChildren() or {}
        end
        local function liveVents(isle)
            local out = {}
            for _, c in ipairs(rocks(isle)) do
                if ventLive(c) then
                    local p = ventPos(c)
                    local part = c:FindFirstChild("VFXLayer") or c:FindFirstChild("volcanorock", true)
                    if p then table.insert(out, { model = c, pos = p, part = part }) end
                end
            end
            return out
        end
        -- The volcano's middle: the average of its vents, live or not.
        local function volcanoCentre(isle)
            local sum, n = Vector3.new(0, 0, 0), 0
            for _, c in ipairs(rocks(isle)) do
                local p = ventPos(c)
                if p then sum += p n += 1 end
            end
            if n > 0 then return sum / n end
            return posOf(core(isle)) or posOf(isle)
        end

        -- A flight on / to the island that never crosses the crater.
        local function safeFly(to, isle, mk, myEpoch, opts)
            local _, r = parts()
            if not r then return false end
            local centre = (isle and volcanoCentre(isle)) or mk
            local wps = centre and arcPath(r.Position, to, centre, tonumber(CFG.VolcanoKeepOut) or 220) or { to }
            for i, wp in ipairs(wps) do
                flyTo(wp, (i == #wps) and opts or nil)
                if stale(myEpoch) then return false end
            end
            return true
        end
        S.safeFly = safeFly
        -- Where to wait on the island: 40 studs in front of the T-Rex skull,
        -- on the side away from the volcano, 15 up.
        local function frontOf(isle)
            local rel, c = relicPos(isle), volcanoCentre(isle)
            if not rel then return nil end
            if not c then return rel + UP * 15 end
            return cageSpot(rel, c, 40) + UP * 15
        end

        -- The compass's danger level 0-6 (its own label; the 0-600 attribute
        -- behind it otherwise).
        local function dangerNow()
            local ok, t = pcall(function() return player.PlayerGui.Main.Compass.Frame.DangerLevel.TextLabel.Text end)
            local n = ok and tonumber(t) or nil
            if n then return n end
            local a = tonumber(player:GetAttribute("DangerLevel"))
            return a and math.floor(a / 100) or nil
        end

        local function notify(text)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Fast Farm", Text = text, Duration = 20,
                })
            end)
        end

        local function nearestOf(list, from, at)
            local best, bd = nil, math.huge
            for _, x in ipairs(list) do
                local d = (at(x) - from).Magnitude
                if d < bd then best, bd = x, d end
            end
            return best
        end

        -- Hold a prompt the way a player does; the executor's instant fire
        -- only when the hold did nothing.
        local function holdPrompt(pr, myEpoch)
            local d = tonumber(pr.HoldDuration) or 0
            if pcall(function() pr:InputHoldBegin() end) then
                local th = os.clock()
                while os.clock() - th < d + 0.25 and not stale(myEpoch) do task.wait(0.05) end
                pcall(function() pr:InputHoldEnd() end)
            end
            task.wait(0.4)
            if pr.Parent and pr.Enabled and fireproximityprompt then pcall(fireproximityprompt, pr) end
        end

        -- ---------- the boat ----------
        local function myBoat()
            local f = workspace:FindFirstChild("Boats")
            local any = nil
            for _, b in ipairs(f and f:GetChildren() or {}) do
                local o = b:FindFirstChild("Owner")
                local v = o and o.Value
                if v == player or tostring(v) == player.Name then
                    if b.Name == CFG.SeaBoat then return b end
                    any = any or b
                end
            end
            return any
        end
        S.myBoat = myBoat
        -- THE WHEEL. A Beast Hunter has TWO VehicleSeats (probe, 2026-10-04):
        -- Harpoon.Seat - the hook at the bow, it turns as it aims - and the
        -- boat's own VehicleSeat by the steering wheel. The first one found
        -- was the harpoon (user, the same day: "I am sitting on the hook").
        -- So: the boat's direct child "VehicleSeat"; else any VehicleSeat
        -- that is not part of a harpoon or a cannon.
        local function seatOf(b)
            local own = b:FindFirstChild("VehicleSeat")
            if own and own:IsA("VehicleSeat") then return own end
            for _, d in ipairs(b:GetDescendants()) do
                if d:IsA("VehicleSeat") then
                    local gun = false
                    local x = d.Parent
                    while x and x ~= b do
                        local n = string.lower(tostring(x.Name))
                        if string.find(n, "harpoon", 1, true) or string.find(n, "cannon", 1, true) then gun = true break end
                        x = x.Parent
                    end
                    if not gun then return d end
                end
            end
            return nil
        end
        -- The boat's HP: its "Humanoid" is an IntValue (probe), MaxHealth an attribute.
        local function boatHP(b)
            local h = b:FindFirstChild("Humanoid")
            local v = h and (h:IsA("Humanoid") and h.Health or h.Value)
            return tonumber(v), tonumber(b:GetAttribute("MaxHealth"))
        end

        local drive = { want = 0, wobbleAt = 0, waterY = nil, boat = nil, sitAt = 0, cruise = true,
            base = 0, leg = 1, odo = 0, odo0 = nil }      -- base: the leg's heading (deg off west); odo: studs sailed

        -- Your keys at the wheel (none while you type in chat): steer +1 =
        -- left (A / Left), -1 = right (D / Right); go = W / Up; stop = S / Down.
        local function keysDown()
            local out = { steer = 0, go = false, stop = false }
            pcall(function()
                local UIS = game:GetService("UserInputService")
                if UIS:GetFocusedTextBox() then return end
                local function down(a, b) return UIS:IsKeyDown(a) or UIS:IsKeyDown(b) end
                if down(Enum.KeyCode.A, Enum.KeyCode.Left) then out.steer += 1 end
                if down(Enum.KeyCode.D, Enum.KeyCode.Right) then out.steer -= 1 end
                out.go = down(Enum.KeyCode.W, Enum.KeyCode.Up)
                out.stop = down(Enum.KeyCode.S, Enum.KeyCode.Down)
            end)
            return out
        end

        -- Every frame at the wheel, at the water line the boat had. Auto: turn
        -- toward the heading (45 deg/s at most), move along it at SeaSpeed.
        -- Manual: your A / D turn the boat, it moves the way it faces, W / S
        -- start and stop it.
        local function driveTick(dt)
            if not (P.running and S.driving) then return end
            local b, seat = S.boat, S.seat
            if not (b and b.Parent and seat and seat.Parent) then
                S.driving = false
                return
            end
            local _, r, h = parts()
            if not (r and h) then return end
            if h.SeatPart ~= seat then
                -- Knocked off: back in the seat; the boat waits.
                if os.clock() - drive.sitAt > 0.5 then
                    drive.sitAt = os.clock()
                    pcall(function() r.CFrame = seat.CFrame + UP * 3 end)
                    pcall(function() seat:Sit(h) end)
                end
                return
            end
            local step = math.min(dt, 0.1)
            local speed = math.clamp(tonumber(CFG.SeaSpeed) or 300, 100, 350)
            local pv = b:GetPivot()
            local look = flat(seat.CFrame.LookVector)
            local turn, dir = 0, nil
            -- Steered by another hunt (SEA EVENTS: the patrol, away from a
            -- ship raid): { dir, speed } every frame; nil = the steering below.
            local own = S.steerFn and S.steerFn(pv.Position, look)
            if own then
                dir, speed = own.dir, own.speed
                if look.Magnitude > 0.1 then
                    turn = turnStep(yawOf(look), yawOf(dir), math.rad(90) * step)
                end
            elseif CFG.SeaSteer == "manual" or (CFG.Hunt and CFG.HuntKind == "sail") then
                local k = keysDown()
                if k.go then drive.cruise = true elseif k.stop then drive.cruise = false end
                turn = k.steer * math.rad(tonumber(CFG.SeaTurnRate) or 60) * step
                if look.Magnitude > 0.1 then
                    local yaw = yawOf(look) + turn
                    dir = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
                else
                    dir = headingFor(0)
                end
                if not drive.cruise then speed = 0 end
            else
                local now = os.clock()
                if now >= drive.wobbleAt then
                    local wait
                    drive.want, wait = nextHeading(drive.want or 0, math.random,
                        tonumber(CFG.SeaTurnEvery) or 60, tonumber(CFG.SeaTurnMax) or 20, 45)
                    drive.wobbleAt = now + wait
                end
                dir = headingFor((drive.base or 0) + drive.want)
                drive.odo = (drive.odo or 0) + speed * step
                if look.Magnitude > 0.1 then
                    turn = turnStep(yawOf(look), yawOf(dir), math.rad(45) * step)
                end
            end
            local y = drive.waterY or pv.Position.Y
            local nextPos = Vector3.new(pv.Position.X, y, pv.Position.Z) + dir * speed * step
            b:PivotTo(CFrame.new(nextPos) * CFrame.Angles(0, turn, 0) * (pv - pv.Position))
            pcall(function()
                seat.AssemblyLinearVelocity = Vector3.zero
                seat.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        do
            local conn
            conn = RunService.Heartbeat:Connect(function(dt)
                if _G.BFF ~= P then conn:Disconnect() return end
                if S.driving then pcall(driveTick, dt) end
            end)
        end

        -- Out of the seat, the body lock back on, where you are.
        local function stopDrive()
            local was = S.driving
            S.driving = false
            local _, r, h = parts()
            local sat = h and h.SeatPart ~= nil
            if sat then
                pcall(function() h.Sit = false end)
                for _, w in ipairs(h.SeatPart:GetChildren()) do
                    if w.Name == "SeatWeld" then pcall(function() w:Destroy() end) end
                end
            end
            if was or sat then
                flying = false
                if r then
                    local at = r.Position + UP * 6
                    lastWritten = at
                    lockAt(at)
                end
            end
        end
        S.stopDrive = stopDrive

        local function sit(seat, myEpoch)
            local _, r, h = parts()
            if not (r and h) then return false end
            flying = true            -- the lock lets go: the seat holds you now
            for _ = 1, 3 do
                pcall(function() r.CFrame = seat.CFrame + UP * 3 end)
                pcall(function() seat:Sit(h) end)
                local t0 = os.clock()
                while os.clock() - t0 < 1.5 and not stale(myEpoch) do
                    if h.SeatPart == seat then return true end
                    task.wait(0.1)
                end
            end
            if h.SeatPart == seat then return true end
            flying = false
            lastWritten = r.Position
            lockAt(r.Position)
            return false
        end

        -- To the back dealer, and buy. The boat you asked for, then two others.
        local function buyBoat(myEpoch)
            S.boatNote = "to the Tiki Outpost boat dealer (the back one)"
            say(S.boatNote)
            setState("FLY")
            flyTo(TIKI_DEALER + UP * 4)
            if stale(myEpoch) then return nil end
            local cf = commF()
            if not cf then S.boatNote = "no CommF_ remote" return nil end
            local names, seen = {}, {}
            for _, n in ipairs({ CFG.SeaBoat or "Beast Hunter", "Beast Hunter", "Guardian", "Lantern" }) do
                if not seen[n] then seen[n] = true table.insert(names, n) end
            end
            for _, n in ipairs(names) do
                local ok, res = pcall(function() return cf:InvokeServer("BuyBoat", n) end)
                S.boatNote = string.format("BuyBoat \"%s\" -> %s", n, ok and tostring(res) or ("error " .. tostring(res)))
                print("[BFF] sea: " .. S.boatNote)
                local t0 = os.clock()
                while os.clock() - t0 < 5 and not stale(myEpoch) do
                    local b = myBoat()
                    if b then
                        S.tally.buys += 1
                        return b
                    end
                    task.wait(0.25)
                end
                if stale(myEpoch) then return nil end
            end
            return nil
        end
        -- The boat's parts, for the sea events hunt (SEA EVENTS, after the main loop).
        S.seatOf, S.sit, S.buyBoat, S.boatHP, S.dangerNow, S.notify, S.drive, S.TIKI =
            seatOf, sit, buyBoat, boatHP, dangerNow, notify, drive, TIKI_DEALER

        -- ---------- the Mirage ----------
        local MIRAGE_LIFE, GEAR_MARGIN = 900, 120

        -- The character back to you: no lock, no noclip, your collisions back.
        local function handsOff()
            if P.handsOff then return end
            stopDrive()
            releasePile()
            P.handsOff = true
            flying = false
            pcall(restoreBody)
            releaseCamera()
        end
        -- The farm drives again, from where you are now (not where it left you).
        local function handsOn()
            local _, r = parts()
            if r then
                lastWritten = r.Position
                lockAt(r.Position)
            end
            P.handsOff = false
        end

        -- Run over the gear: onto it, then a few small steps on it, until it
        -- goes (a found gear is not shown to you any more - the wiki).
        local function collectGear(g, m, myEpoch)
            handsOn()
            m.note = "THE BLUE GEAR IS UP - going for it"
            say(m.note)
            print("[BFF] mirage: the Blue Gear showed - going for it")
            flyTo(g.Position)
            local t0, i = os.clock(), 0
            while os.clock() - t0 < 4 and not stale(myEpoch) do
                if not g.Parent or (tonumber(g.Transparency) or 1) >= 1 then break end
                i += 1
                lockAt(g.Position + Vector3.new(((i % 3) - 1) * 1.5, (i % 2 == 0) and 1 or -1, 0))
                task.wait(0.15)
            end
            local got = not g.Parent or (tonumber(g.Transparency) or 1) >= 1
            local cf = commF()
            local okD, door = false, nil
            if cf then okD, door = pcall(function() return cf:InvokeServer("CheckTempleDoor") end) end
            if got then
                m.got = true
                S.tally.gears += 1
                m.note = "BLUE GEAR COLLECTED"
                    .. (okD and ("  (temple door: " .. tostring(door) .. ")") or "")
                print("[BFF] mirage: " .. m.note)
                notify("Blue Gear collected!")
                return
            end
            m.tries = (m.tries or 0) + 1
            m.note = (m.tries >= 3) and "the gear did not pick up 3 times - walk over it yourself"
                or "the gear is still there - trying again"
            print("[BFF] mirage: " .. m.note)
            handsOff()
        end

        -- ---------- the Mirage's chests ----------
        -- The hubs (2026) agree: Map.MysticIsland.Chests, and every chest the
        -- game tags "_ChestTagged"; a taken one has the attribute IsDisabled.
        -- Touch to take. Nearest first; one that will not go in 3 tries is left.
        S.chestSkip = setmetatable({}, { __mode = "k" })
        S.chestTries = setmetatable({}, { __mode = "k" })
        local function chestTaken(c)
            if not c.Parent then return true end
            local ok, off = pcall(function() return c:GetAttribute("IsDisabled") end)
            return ok and off == true
        end
        local function mirageChests(isle)
            local out, seen = {}, {}
            if not isle then return out end
            local function consider(c)
                if seen[c] or S.chestSkip[c] or chestTaken(c) then return end
                seen[c] = true
                local ok, p = pcall(function() return c:GetPivot().Position end)
                if ok and p then table.insert(out, { inst = c, pos = p }) end
            end
            local f = isle:FindFirstChild("Chests")
            for _, c in ipairs(f and f:GetChildren() or {}) do consider(c) end
            local ok, tagged = pcall(function() return game:GetService("CollectionService"):GetTagged("_ChestTagged") end)
            for _, c in ipairs((ok and type(tagged) == "table") and tagged or {}) do
                local okD, inIsle = pcall(function() return c:IsDescendantOf(isle) end)
                if okD and inIsle then consider(c) end
            end
            return out
        end
        S.mirageChests = mirageChests

        -- One chest. true = busy with them; false = none left.
        local function chestStep(isle, m, myEpoch)
            local list = mirageChests(isle)
            if #list == 0 then
                m.chestsDone = true
                print(string.format("[BFF] mirage: chests done - %d taken", m.chests))
                return false
            end
            if P.handsOff then handsOn() end
            local _, r = parts()
            local c = nearestOf(list, r and r.Position or list[1].pos, function(x) return x.pos end)
            m.note = string.format("Mirage chests  ·  %d taken  ·  %d left", m.chests, #list)
            S.note = m.note
            P.elite.note = S.note
            say(m.note)
            setState("CHEST")
            flyTo(c.pos + UP * 2)
            if stale(myEpoch) then return true end
            local t0 = os.clock()
            while not chestTaken(c.inst) and os.clock() - t0 < 2 and not stale(myEpoch) do
                lockAt(c.pos)
                task.wait(0.1)
            end
            if chestTaken(c.inst) then
                m.chests += 1
                S.tally.chests += 1
            else
                local n = (S.chestTries[c.inst] or 0) + 1
                S.chestTries[c.inst] = n
                if n >= 3 then S.chestSkip[c.inst] = true end
            end
            return true
        end

        -- ---------- the Advanced Fruit Dealer ----------
        -- He stands at a random spot on the Mirage (the wiki, 2026), so never a
        -- fixed point: his own root, read wherever the client holds him. The
        -- hubs (2024-26) look in workspace.NPCs (near you), ReplicatedStorage.
        -- NPCs (parked - its CFrame is still where he stands) and the nil
        -- instances; the island's own model last. A copy far off this Mirage is
        -- a stale one, not him. In front = along his own LookVector: his face.
        local DEALER, DEALER_RANGE, DEALER_FRONT = "Advanced Fruit Dealer", 2500, 5
        local function dealerCF(x)
            local root = x:FindFirstChild("HumanoidRootPart") or x:FindFirstChild("Head")
            if root and root:IsA("BasePart") then return root.CFrame end
            return x:GetPivot()
        end
        -- Where he is: { model, cf, from, off (studs from the Mirage's middle) };
        -- else nil, and the nearest copy found off this Mirage. deep = the nil
        -- instances and the island's model too (the hunt; the news reads only
        -- the two folders, once a second).
        local function findDealer(isle, mk, deep)
            local centre = (isle and posOf(isle)) or mk
            local found = {}
            local function add(x, from)
                if not x then return end
                local ok, cf = pcall(dealerCF, x)
                if ok and cf then table.insert(found, { model = x, cf = cf, from = from }) end
            end
            local wsN, rsN = workspace:FindFirstChild("NPCs"), RS:FindFirstChild("NPCs")
            add(wsN and wsN:FindFirstChild(DEALER), "workspace.NPCs")
            add(rsN and rsN:FindFirstChild(DEALER), "ReplicatedStorage.NPCs")
            if deep then
                if getnilinstances then
                    local ok, list = pcall(getnilinstances)
                    for _, x in ipairs((ok and type(list) == "table") and list or {}) do
                        local okN, n = pcall(function() return x.Name end)
                        if okN and n == DEALER then add(x, "the nil instances") end
                    end
                end
                add(isle and isle:FindFirstChild(DEALER, true), "the Mirage's model")
            end
            local far = nil
            for _, d in ipairs(found) do
                d.off = centre and flat(d.cf.Position - centre).Magnitude or 0
                if d.off <= DEALER_RANGE then return d, nil end
                if not far or d.off < far.off then far = d end
            end
            return nil, far
        end
        S.findDealer = findDealer

        -- Nowhere to be read: the island searched - two rings round its middle,
        -- at a third and two thirds of its half-width, 30 up (noclip: hills are
        -- nothing), so whatever brings him in by distance does.
        local function sweepPoints(isle, mk)
            local centre = (isle and posOf(isle)) or mk
            if not centre then return {} end
            local half = 300
            if isle then
                local ok, _, size = pcall(function() return isle:GetBoundingBox() end)
                if ok and size then half = math.clamp(math.max(size.X, size.Z) / 2, 150, 1200) end
            end
            local out = {}
            for _, f in ipairs({ 1 / 3, 2 / 3 }) do
                for i = 0, 7 do
                    local a = i * math.pi / 4
                    table.insert(out, centre + Vector3.new(math.cos(a) * half * f, 30, math.sin(a) * half * f))
                end
            end
            return out
        end

        -- In front of his face: `dist` out along his LookVector, at his root's
        -- height (your feet on his ground).
        local function frontOfDealer(cf, dist)
            local look = flat(cf.LookVector)
            if look.Magnitude < 0.1 then look = Vector3.new(0, 0, -1) end
            return cf.Position + look.Unit * dist
        end

        -- Your view on him: from behind you, a little above, his head in the middle.
        local function viewDealer(stand, d)
            pcall(function()
                local cam = workspace.CurrentCamera
                local head = d.model:FindFirstChild("Head")
                local hp = (head and head:IsA("BasePart")) and head.Position or (d.cf.Position + UP * 1.5)
                local back = flat(stand - d.cf.Position)
                back = (back.Magnitude > 0.1) and back.Unit or Vector3.new(0, 0, 1)
                cam.CFrame = CFrame.lookAt(stand + back * 10 + UP * 4, hp)
            end)
        end

        -- One step. true = still at it (call again); false = done
        -- (m.dealerNote says how). Never a single look (2026-10-07: one miss
        -- made it "not found" for the whole Mirage): not read = the island
        -- searched, ring after ring, until he is.
        local function dealerStep(isle, mk, m, myEpoch)
            if P.handsOff then handsOn() end
            setState("DEALER")
            local d, far = findDealer(isle, mk, true)
            if not d then
                m.sweep = m.sweep or sweepPoints(isle, mk)
                m.looked = (m.looked or 0) + 1
                if m.looked == 1 then
                    print("[BFF] mirage: no Advanced Fruit Dealer in workspace.NPCs, ReplicatedStorage.NPCs, "
                        .. "the nil instances or the island" .. (far and string.format(
                            " (one in %s, %d studs off this Mirage - not him)", far.from, math.floor(far.off)) or "")
                        .. " - searching the island")
                end
                local n = #m.sweep
                m.note = string.format("looking for the Advanced Fruit Dealer - he stands at a random spot (%d/%d)",
                    ((m.looked - 1) % math.max(n, 1)) + 1, n)
                say(m.note)
                if n > 0 then flyTo(m.sweep[((m.looked - 1) % n) + 1]) else task.wait(0.5) end
                return true
            end
            local _, r = parts()
            local stand = frontOfDealer(d.cf, DEALER_FRONT)
            if not m.dealerFrom then
                m.dealerFrom = d.from
                print(string.format("[BFF] mirage: the Advanced Fruit Dealer is in %s - %d studs from you, %d from the Mirage's middle",
                    d.from, r and math.floor((r.Position - d.cf.Position).Magnitude) or -1, math.floor(d.off)))
            end
            m.note = "to the Advanced Fruit Dealer"
                .. (r and string.format(" - %d studs", math.floor((r.Position - stand).Magnitude)) or "")
            say(m.note)
            flyTo(stand, { face = d.cf.Position })
            if stale(myEpoch) then return true end
            -- Read again from beside him: a parked copy's spot against the live one.
            local d2 = findDealer(isle, mk, false) or d
            local stand2 = frontOfDealer(d2.cf, DEALER_FRONT)
            local _, r2 = parts()
            local moved = (stand2 - stand).Magnitude > 4
            local short = r2 ~= nil and (r2.Position - stand2).Magnitude > 8
            if moved or short then
                m.goes = (m.goes or 0) + 1
                if m.goes < 4 then return true end          -- not in front of him yet: again
                if short then
                    m.dealerNote = string.format("could not reach the Advanced Fruit Dealer - %d studs off (%s)",
                        math.floor((r2.Position - stand2).Magnitude), tostring(P.lastFlight or "no flight"))
                    print("[BFF] mirage: " .. m.dealerNote)
                    return false
                end
            end
            lockAt(stand2, d2.cf.Position)
            viewDealer(stand2, d2)
            local opened, err = pcall(function()
                require(player.PlayerGui.Main.UIController.FruitShop):Open("AdvancedFruitDealer")
            end)
            m.dealerSeen = true
            S.tally.dealers += 1
            m.dealerNote = "in front of the Advanced Fruit Dealer" .. (opened and " - his shop is open"
                or (" - talk to him (the shop did not open: " .. tostring(err) .. ")"))
            print("[BFF] mirage: " .. m.dealerNote)
            notify("Advanced Fruit Dealer" .. (opened and " - shop open" or " - in front of you"))
            return false
        end

        -- The hunt's job is done: the character is yours, the farm stops.
        local function mirageDone(m, what)
            m.done = true
            m.note = "MIRAGE DONE - " .. tostring(what) .. " - the farm stopped, you are on the Mirage"
            print("[BFF] mirage: " .. m.note)
            handsOff()
            P.setHunt(false)
            task.defer(function() pcall((P :: any).stop) end)
        end

        -- One step with a Mirage up. true = handled; false = not worth it
        -- (sailed past: the gear hunt's sky judge only). ONLY the hunt's job:
        --   mirage   onto it
        --   dealer   in front of him, his shop open (straight to him when he
        --            can be read already)
        --   mchest   the chests, nearest first
        --   gear     the gear if it already shows (it does not wait), else your
        --            turn at the moon while it is watched
        -- Another hunt on the same Mirage starts its own job (its age kept).
        local MIRAGE_HUNT = { mirage = true, dealer = true, mchest = true, gear = true }
        S.MIRAGE_HUNT = MIRAGE_HUNT
        local function mirageStep(isle, mk, myEpoch, kind)
            local m = S.mirage
            if not m or m.kind ~= kind then
                local seen = m and m.seenAt
                m = { seenAt = seen or os.clock(), tries = 0, chests = 0, kind = kind }
                S.mirage = m
                if not seen then S.tally.mirages += 1 end
                local news = (P :: any).news
                -- Only the gear needs night: every other hunt takes every Mirage.
                local need = (kind == "gear") and CFG.MirageNeed or "any"
                m.fits, m.why = mirageFits(need, news and news.sky, MIRAGE_LIFE, GEAR_MARGIN)
                print(string.format("[BFF] mirage: MIRAGE ISLAND (%s hunt) at %d m from Tiki - %s%s",
                    kind, math.floor(S.meters or 0), m.why, m.fits and "" or " - sailing on"))
                if not seen then
                    notify(m.fits and "Mirage Island is up!"
                        or ("Mirage Island - " .. m.why .. ": sailing on"))
                end
            end
            if not m.fits then return false end
            if m.done then
                say(m.note)
                task.wait(0.5)
                return true
            end
            if not m.landed then
                stopDrive()
                local at = mk or posOf(isle)
                if at and not (kind == "dealer" and findDealer(isle, mk, false)) then
                    setState("FLY")
                    say("onto the Mirage")
                    flyTo(at + UP * 20)
                    if stale(myEpoch) then return true end
                end
                m.landed = true
            end
            if kind == "mirage" then
                mirageDone(m, "you are on it")
                return true
            end
            if kind == "dealer" then
                if dealerStep(isle, mk, m, myEpoch) then return true end
                mirageDone(m, m.dealerNote)
                return true
            end
            if not isle then
                -- Only its marker so far: the island's model is still coming.
                m.waitIsle = m.waitIsle or os.clock()
                if os.clock() - m.waitIsle < 15 then
                    say("on the Mirage - its island still loading")
                    task.wait(0.5)
                    return true
                end
            end
            if kind == "mchest" then
                if not m.chestsDone and chestStep(isle, m, myEpoch) then return true end
                mirageDone(m, m.chests .. " chests taken")
                return true
            end
            -- THE BLUE GEAR.
            local g, byMesh = blueGear(isle)
            if not m.got and g then
                local hidden = (tonumber(g.Transparency) or 1) >= 1
                if hidden then m.sawHidden = true end
                if not hidden and (byMesh or m.sawHidden) and (m.tries or 0) < 3 then
                    collectGear(g, m, myEpoch)
                    if stale(myEpoch) then return true end
                end
            end
            if m.got then
                mirageDone(m, "Blue Gear collected")
                return true
            end
            -- Your turn at the moon; the gear is watched.
            handsOff()
            local left = MIRAGE_LIFE - (os.clock() - m.seenAt)
            local news = (P :: any).news
            local sky = news and news.sky
            local skyText = (sky and sky.edge) and (sky.night and ("night, dawn in " .. mmss(sky.edge))
                or ("day, night in " .. mmss(sky.edge))) or "sky not read"
            if (m.tries or 0) < 3 then
                m.note = "MIRAGE UP - your turn: a high point, face the moon, T. The gear is picked the moment it shows"
            end
            S.note = string.format("%s  ·  %s  ·  Mirage ~%s left", m.note, skyText, mmss(left))
            P.elite.note = S.note
            say(S.note)
            setState("MIRAGE")
            task.wait(0.2)
            return true
        end

        -- HOME BY RESPAWN (user, 2026-10-10): the loot in and the stay over,
        -- the character reset - the game puts the new one at your spawn (Tiki
        -- Outpost, where the sail began), never a flight back. The rungs in
        -- order, the next only while the last left you alive (the ladder of
        -- the old teleport, its spawn-point trick left out): Health 0,
        -- BreakJoints, the Head off. No new character in RespawnWait s = the
        -- next server from where you stand. Once an island (ev.home); never
        -- with the God's Chalice on you (a death loses it); only with
        -- something picked.
        local RESPAWN = {
            { "Health 0", function(_, h) h.Health = 0 end },
            { "BreakJoints", function(c) c:BreakJoints() end },
            { "the Head off", function(c)
                local hd = c:FindFirstChild("Head")
                if hd then hd:Destroy() end
            end },
        }
        local function goHome(ev, myEpoch)
            if ev.home then return end
            ev.home = "skipped"
            local picked = ev.bones + ev.eggs + (ev.bonesUnread or 0) + (ev.eggUnread and 1 or 0)
            if not CFG.RespawnHome or picked == 0 then return end
            local chalice = (P :: any).holdingChalice
            if chalice and chalice() then
                print("[BFF] loot: NOT home by respawn - the God's Chalice is on you (a death loses it)")
                return
            end
            local old = player.Character
            local _, _, h = parts()
            if not (old and h) then return end
            if S.driving then stopDrive() end
            local limit = math.max(tonumber(CFG.RespawnWait) or 20, 1)
            ev.note = "home by respawn (your spawn - Tiki Outpost), then the next server"
            S.note = ev.note
            say(ev.note)
            setState("HOME")
            local t0, i, nextAt, tried = os.clock(), 0, os.clock(), {}
            while os.clock() - t0 < limit and not stale(myEpoch) do
                local c = player.Character
                if c and c ~= old then
                    local _, r = parts()
                    local t1 = os.clock()
                    while not r and os.clock() - t1 < 5 and not stale(myEpoch) do
                        task.wait(0.25)
                        _, r = parts()
                    end
                    flying = false              -- the body lock adopts where the game put you
                    ev.home = "done"
                    local m = r and metersFrom(r.Position, CFG.SeaStudsPerM)
                    local hv = S.have and S.have(S.LOOT, true)
                    print(string.format("[BFF] loot: home by respawn (%s) - %s from Tiki  ·  you have %s",
                        table.concat(tried, ", "), m and (math.floor(m) .. " m") or "?", S.lootText(hv)))
                    return
                end
                -- The next rung only while the last left you alive.
                if os.clock() >= nextAt and i < #RESPAWN and (i == 0 or (tonumber(h.Health) or 0) > 0) then
                    i += 1
                    table.insert(tried, RESPAWN[i][1])
                    pcall(RESPAWN[i][2], old, h)
                    nextAt = os.clock() + 1.5
                end
                task.wait(0.25)
            end
            ev.home = "failed"
            print(string.format("[BFF] loot: no respawn in %d s (tried: %s) - the next server from here",
                math.floor(limit), table.concat(tried, ", ")))
        end

        -- THE HUNT, one step. true = keep going here; false = the next server
        -- (E.why says why). kind: "prehistoric" (default), a Mirage hunt
        -- ("mirage" / "dealer" / "mchest" / "gear"), or "sail" - SEA TRAVEL
        -- (user, 2026-10-10: the boat at sea speed and nothing else - for the
        -- Leviathan; the Mirage / Prehistoric hunts fly you to a Mirage that
        -- is up, or to Hydra for the magnet): your keys at the wheel, no
        -- island, no clock, never the next server.
        function S.huntStep(myEpoch, kind)
            kind = kind or "prehistoric"
            local E = P.elite
            -- Sea travel never leaves the server: what sends a hunt on turns it off.
            local function sailOff(why)
                S.note = why .. " - Sea travel off"
                P.setHunt(false)
                E.note = S.note
                say(S.note)
                return true
            end
            local sea = mySea()
            if sea and sea ~= 3 then
                S.note = (MIRAGE_HUNT[kind] and "the Mirage" or (kind == "sail") and "Sea travel"
                    or "the Prehistoric Island") .. " is Third Sea only - hunt stopped"
                P.setHunt(false)
                E.note = S.note
                say(S.note)
                return true
            end
            if MIRAGE_HUNT[kind] then
                local mi, mmk = mirageIsle(), mirageMarker()
                if mi or mmk then
                    if mirageStep(mi, mmk, myEpoch, kind) then return true end
                elseif S.mirage then
                    -- Gone (15 min, or its spawner left): back to the boat.
                    if S.mirage.fits and not S.mirage.done then print("[BFF] mirage: the Mirage went") end
                    S.mirage = nil
                    if P.handsOff then handsOn() end
                end
            end
            -- The island is up: the hunt's job is done. Never leave it (it
            -- despawns with nobody on it); the Volcano switch does the event.
            local isle, mk = island(), marker()
            if kind == "prehistoric" and (isle or mk) then
                if S.driving then stopDrive() end
                local ev = S.ev
                if ev and ev.complete and (ev.stuck or (CFG.VolcanoAfter or "hop") == "hop") then
                    goHome(ev, myEpoch)
                    if stale(myEpoch) then return true end
                    E.why = ev.stuck and "the volcano event would not start here (the game's bug) - the next server"
                        or string.format("volcano done (%d vents, %d bones, %d egg) - the next server",
                            ev.vents, ev.bones, ev.eggs)
                    return false
                end
                if not S.foundAt then
                    S.foundAt = os.clock()
                    S.tally.found += 1
                    print(string.format("[BFF] sea: PREHISTORIC ISLAND at %d m from Tiki", math.floor(S.meters or 0)))
                    notify("Prehistoric Island is up!")
                end
                -- Never the island's middle (the volcano): in front of the skull,
                -- or, not streamed yet, the island's edge on your side. Its
                -- lava off your client first (the hubs do).
                if isle and S.lavaOff then S.lavaOff(isle) end
                local _, rr = parts()
                local spot = (isle and frontOf(isle)) or (mk and rr and edgeOf(mk, rr.Position,
                    tonumber(CFG.VolcanoKeepOut) or 220)) or nil
                if spot and rr and (rr.Position - spot).Magnitude > 10 then
                    print(isle and "[BFF] sea: island up - to the front of the T-Rex skull (round the volcano)"
                        or "[BFF] sea: island up - to its edge on your side (never the volcano)")
                    safeFly(spot, isle, mk, myEpoch)
                end
                S.note = "PREHISTORIC ISLAND UP - holding on it"
                E.note = S.note
                say(S.note)
                setState("ISLAND")
                task.wait(0.5)
                return true
            end
            S.foundAt = nil
            -- What you have before the hunt (user, 2026-10-07: "check the
            -- inventory before"), once a server - the event says it again.
            if kind == "prehistoric" and not S.baseSaid and S.have then
                S.baseSaid = true
                S.lootBase = S.have(S.LOOT, true)
                print("[BFF] loot: before the hunt - you have " .. S.lootText(S.lootBase))
            end
            -- THE VOLCANIC MAGNET before the boat (P.magnet). Getting it is not
            -- counted in the 21 min: the clock starts at the sail.
            if kind == "prehistoric" and not S.sailStart then
                local g = (P :: any).magnet
                if g and g.step(myEpoch) then
                    S.note = "before the sail: " .. tostring(g.note)
                    E.note = S.note
                    if g.note ~= S.magnetSaid then
                        S.magnetSaid = g.note
                        print("[BFF] magnet: " .. tostring(g.note))
                    end
                    return true
                end
                if g then print("[BFF] magnet: " .. tostring(g.note) .. " - sailing") end
            end
            -- THE SERVER'S CLOCK: the Prehistoric hunt only (user, 2026-10-06 -
            -- not the Mirage hunt, not the farm), from its first step past the
            -- magnet; checked before any boat step - a stuck buy, seat or loop.
            if kind == "prehistoric" then S.sailStart = S.sailStart or os.clock() end
            local capS = (tonumber(CFG.SeaSearchMinutes) or 21) * 60
            if kind == "prehistoric" and capS > 0 and S.sailStart and os.clock() - S.sailStart >= capS then
                if S.driving then stopDrive() end
                S.everDriven = false
                E.why = string.format("no Prehistoric Island in %d min in this server", math.floor(capS / 60 + 0.5))
                return false
            end

            local b = myBoat()
            if not b then
                local _, rr = parts()
                local farOut = rr ~= nil and flat(rr.Position - TIKI_DEALER).Magnitude > 6000
                if S.everDriven and farOut then
                    -- Sunk far out: a new one is a long flight back - the
                    -- next server. Near Tiki: just buy another.
                    S.everDriven = false
                    if kind == "sail" then return sailOff("the boat was lost at sea") end
                    E.why = "the boat was lost at sea"
                    return false
                end
                b = buyBoat(myEpoch)
                if not b then
                    S.buyFails = (S.buyFails or 0) + 1
                    if S.buyFails >= 3 then
                        S.note = "could not buy a boat 3 times (" .. tostring(S.boatNote) .. ") - hunt stopped"
                        P.setHunt(false)
                        E.note = S.note
                        say(S.note)
                    end
                    task.wait(1)
                    return true
                end
                S.buyFails = 0
            end
            local seat = seatOf(b)
            if not seat then
                S.boatNote = b.Name .. " has no VehicleSeat"
                if kind == "sail" then return sailOff(S.boatNote) end
                E.why = S.boatNote
                return false
            end
            S.boat, S.seat = b, seat
            if drive.boat ~= b then
                drive.boat, drive.waterY = b, nil
            end

            local _, _, h = parts()
            if not (h and h.SeatPart == seat) then
                S.driving = false
                local _, r = parts()
                if r and (r.Position - seat.Position).Magnitude > 30 then
                    flying = false
                    S.boatNote = "to your boat"
                    setState("FLY")
                    say(S.boatNote)
                    flyTo(seat.Position + UP * 6)
                    if stale(myEpoch) then return true end
                end
                if not sit(seat, myEpoch) then
                    S.boatNote = "could not sit in " .. b.Name .. " - trying again"
                    say(S.boatNote)
                    task.wait(0.5)
                    return true
                end
                for _, d in ipairs(b:GetDescendants()) do
                    if d:IsA("BasePart") then pcall(function() d.CanCollide = false end) end
                end
                S.boatNote = "at the wheel of " .. b.Name
            end
            if not S.driving then
                drive.waterY = drive.waterY or b:GetPivot().Position.Y
                drive.wobbleAt = 0
                drive.cruise = true
                flying = true            -- seated already (a Stop and Start): the lock still lets go
                S.driving, S.everDriven = true, true
            end

            local pos = b:GetPivot().Position
            S.meters = metersFrom(pos, CFG.SeaStudsPerM)
            S.danger = dangerNow()
            S.hp, S.maxHp = boatHP(b)
            local to = tonumber(CFG.SeaSearchTo) or 17000
            local back, leg2 = tonumber(CFG.SeaTurnBack) or 120, tonumber(CFG.SeaLeg2) or 7000
            local spm = math.max(tonumber(CFG.SeaStudsPerM) or 10, 1)
            setState("SAIL")
            local manual = CFG.SeaSteer == "manual" or kind == "sail"
            -- Near Tiki again (a new boat): a fresh search.
            if S.meters < 2000 then drive.leg, drive.base, drive.odo0 = 1, 0, nil end
            local leg = manual and "manual" or searchLeg(drive, S.meters, (drive.odo or 0) / spm, to, back, leg2)
            if leg == "turn" then
                drive.want, drive.wobbleAt = 0, os.clock() + 20
                print(string.format("[BFF] sea: no island by %d m - %d deg left, %d m more", to, back, leg2))
            end
            local limitS = (kind == "prehistoric") and (tonumber(CFG.SeaSearchMinutes) or 21) * 60 or 0
            local atSea = os.clock() - (S.sailStart or os.clock())
            local clock = (limitS > 0) and string.format("  ·  %s of %s in this server", mmss(atSea), mmss(limitS)) or ""
            local where = manual and "" or ((drive.leg == 2)
                and string.format("  ·  turned back: %d of %d m", math.floor((drive.odo or 0) / spm - (drive.odo0 or 0)), leg2)
                or string.format(" (of %d)", to))
            S.note = string.format("%s  ·  %d m from Tiki%s%s  ·  danger %s%s",
                manual and ("YOU STEER: A/D turn, W go, S stop" .. (drive.cruise and "" or "  (stopped)")) or "sailing",
                math.floor(S.meters), where, clock, tostring(S.danger or "?"),
                S.hp and string.format("  ·  boat %d/%s HP", S.hp, tostring(S.maxHp or "?")) or "")
            E.note = S.note
            say(S.note)
            if leg == "hop" then
                stopDrive()
                S.everDriven = false
                drive.leg, drive.base, drive.odo0 = 1, 0, nil
                local what = MIRAGE_HUNT[kind] and "Mirage" or "Prehistoric Island"
                E.why = (leg2 > 0) and string.format("no %s by %d m, nor %d m after the turn", what, to, leg2)
                    or string.format("no %s by %d m", what, to)
                return false
            end
            task.wait(0.25)
            return true
        end

        -- ---------- the meters: the relic's health, the pressure ----------
        local WORDS = { relic = { "relic" }, pressure = { "pressure", "heat", "erupt" } }
        -- A numeric attribute whose name has one of `words` (not a max), out
        -- of a "max" attribute with the same word when there is one.
        local function attrPct(inst, words)
            if not inst then return nil end
            local ok, a = pcall(function() return inst:GetAttributes() end)
            if not ok or type(a) ~= "table" then return nil end
            for k, v in pairs(a) do
                local lk = string.lower(tostring(k))
                if type(v) == "number" and not string.find(lk, "max", 1, true) then
                    for _, w in ipairs(words) do
                        if string.find(lk, w, 1, true) then
                            local max = nil
                            for k2, v2 in pairs(a) do
                                local l2 = string.lower(tostring(k2))
                                if type(v2) == "number" and string.find(l2, "max", 1, true) then max = v2 end
                            end
                            local pc = pctFrom(v, max)
                            if pc then return pc, inst.Name .. " attribute " .. tostring(k) end
                        end
                    end
                end
            end
            return nil
        end
        -- Text on screen (or on the relic's billboard) naming the meter.
        local guiHit = {}
        local function guiPct(root, words, kind, skipGui)
            local hit = guiHit[kind]
            if hit and hit.Parent then
                local pc = pctText(hit.Text)
                if pc then return pc, "text " .. hit:GetFullName() end
            end
            if not root then return nil end
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and not (skipGui and d:IsDescendantOf(skipGui)) then
                    local lt = string.lower(tostring(d.Text) .. " " .. tostring(d.Name) .. " "
                        .. tostring(d.Parent and d.Parent.Name or ""))
                    for _, w in ipairs(words) do
                        if string.find(lt, w, 1, true) then
                            local pc = pctText(d.Text)
                            if pc then
                                guiHit[kind] = d
                                return pc, "text " .. d:GetFullName()
                            end
                        end
                    end
                end
            end
            return nil
        end
        local function relicMeter(isle)
            local c = core(isle)
            local rel = c and c:FindFirstChild("PrehistoricRelic")
            if rel then
                local h = rel:FindFirstChildWhichIsA("Humanoid", true)
                if h and tonumber(h.MaxHealth) and h.MaxHealth > 0 then
                    return h.Health / h.MaxHealth * 100, "the relic's Humanoid"
                end
            end
            for _, x in ipairs({ rel, c, isle }) do
                local pc, src = attrPct(x, WORDS.relic)
                if pc then return pc, src end
            end
            local pc, src = attrPct(rel, { "health", "hp" })
            if pc then return pc, src end
            for _, d in ipairs(rel and rel:GetDescendants() or {}) do
                if (d:IsA("NumberValue") or d:IsA("IntValue")) then
                    local ln = string.lower(d.Name)
                    if string.find(ln, "health", 1, true) or ln == "hp" then
                        local max = d.Parent and (d.Parent:FindFirstChild("MaxHealth") or d.Parent:FindFirstChild("Max"))
                        local p2 = pctFrom(d.Value, max and max.Value)
                        if p2 then return p2, "value " .. d:GetFullName() end
                    end
                end
            end
            pc, src = guiPct(rel, { "" }, "relicBoard")
            if pc then return pc, src end
            local okG, pg = pcall(function() return player.PlayerGui end)
            local mine = okG and pg and pg:FindFirstChild("BFFHUD") or nil
            return guiPct(okG and pg or nil, WORDS.relic, "relic", mine)
        end
        local function pressureMeter(isle)
            local c = core(isle)
            for _, x in ipairs({ isle, c }) do
                local pc, src = attrPct(x, WORDS.pressure)
                if pc then return pc, src end
            end
            for _, d in ipairs(c and c:GetChildren() or {}) do
                if (d:IsA("NumberValue") or d:IsA("IntValue")) and string.find(string.lower(d.Name), "pressure", 1, true) then
                    local pc = pctFrom(d.Value)
                    if pc then return pc, "value " .. d:GetFullName() end
                end
            end
            local okG, pg = pcall(function() return player.PlayerGui end)
            local mine = okG and pg and pg:FindFirstChild("BFFHUD") or nil
            return guiPct(okG and pg or nil, WORDS.pressure, "pressure", mine)
        end
        -- Read at most twice a second into ev (relicPct / pressurePct + where).
        local function readMeters(isle, ev)
            if os.clock() - (ev.metersAt or -1) < 0.5 then return end
            ev.metersAt = os.clock()
            local okR, r, rs = pcall(relicMeter, isle)
            local okP, pr, ps = pcall(pressureMeter, isle)
            ev.relicPct, ev.relicSrc = okR and r or nil, okR and rs or nil
            ev.pressurePct, ev.pressureSrc = okP and pr or nil, okP and ps or nil
            if ev.relicPct and ev.relicPct < (ev.relicLow or 101) then ev.relicLow = ev.relicPct end
        end

        -- Everything that could be the meters, to a file - once when the event
        -- starts and once 20 s in (the screen's bars may come late).
        local function dumpMeters(isle, ev, tag)
            local out = { "[volcano probe] " .. tag .. "  " .. os.date("!%Y-%m-%d %H:%M:%S") .. "Z" }
            local function attrs(x)
                local ok, a = pcall(function() return x:GetAttributes() end)
                local t = {}
                if ok and type(a) == "table" then
                    for k, v in pairs(a) do table.insert(t, tostring(k) .. "=" .. tostring(v)) end
                end
                return table.concat(t, ", ")
            end
            local c = core(isle)
            local rel = c and c:FindFirstChild("PrehistoricRelic")
            table.insert(out, "island attributes: " .. attrs(isle))
            if c then table.insert(out, "Core attributes: " .. attrs(c)) end
            if rel then
                table.insert(out, "relic attributes: " .. attrs(rel))
                for _, d in ipairs(rel:GetDescendants()) do
                    local v = ""
                    pcall(function()
                        if d:IsA("ValueBase") then v = " = " .. tostring(d.Value)
                        elseif d:IsA("Humanoid") then v = string.format(" = %s / %s", tostring(d.Health), tostring(d.MaxHealth))
                        elseif d:IsA("TextLabel") then v = " text '" .. tostring(d.Text) .. "'" end
                    end)
                    if not d:IsA("BasePart") then table.insert(out, "  relic " .. d:GetFullName() .. " (" .. d.ClassName .. ")" .. v) end
                end
            end
            for _, d in ipairs(c and c:GetChildren() or {}) do
                if d:IsA("ValueBase") then table.insert(out, "  core value " .. d.Name .. " = " .. tostring(d.Value)) end
            end
            local okG, pg = pcall(function() return player.PlayerGui end)
            if okG and pg then
                local mine = pg:FindFirstChild("BFFHUD")
                for _, d in ipairs(pg:GetDescendants()) do
                    if d:IsA("GuiObject") and not (mine and d:IsDescendantOf(mine)) then
                        local txt = (d:IsA("TextLabel") or d:IsA("TextButton")) and tostring(d.Text) or ""
                        local l = string.lower(d.Name .. " " .. txt)
                        for _, w in ipairs({ "relic", "pressure", "volcano", "heat", "erupt", "prehistoric", "timer" }) do
                            if string.find(l, w, 1, true) then
                                table.insert(out, string.format("  gui %s (%s) visible=%s text='%s' size=%s",
                                    d:GetFullName(), d.ClassName, tostring(d.Visible), txt, tostring(d.Size)))
                                break
                            end
                        end
                    end
                end
            end
            readMeters(isle, ev)
            table.insert(out, string.format("read: relic %s (%s)  ·  pressure %s (%s)",
                tostring(ev.relicPct), tostring(ev.relicSrc), tostring(ev.pressurePct), tostring(ev.pressureSrc)))
            local text = table.concat(out, "\n")
            S.probeText = (S.probeText and (S.probeText .. "\n\n") or "") .. text
            if writefile then pcall(writefile, "bff_volcano_probe.txt", S.probeText) end
            print("[BFF] volcano: meters " .. tag .. " - relic " .. tostring(ev.relicSrc or "NOT FOUND")
                .. " · pressure " .. tostring(ev.pressureSrc or "NOT FOUND") .. "  (all candidates: workspace/bff_volcano_probe.txt)")
        end

        -- ---------- the golems ----------
        S.tried = setmetatable({}, { __mode = "k" })     -- model -> when holding it was first tried
        S.cageDest = setmetatable({}, { __mode = "k" })  -- model -> where the holder last put it

        -- Held = a write on it (the magnet's or the holder's) stuck, just now.
        local function golemHeld(e)
            local t = P.heldAt[e.model]
            return t ~= nil and os.clock() - t < 0.6
        end
        -- Not ours to move: tried for 1.5 s, never stuck.
        local function golemWild(e)
            local t = S.tried[e.model]
            return t ~= nil and os.clock() - t > 1.5 and not golemHeld(e)
        end

        -- The fight's pile: a golem that cannot be held first, where it stands
        -- (it is on the relic); else the held ones, at the cage.
        -- The event runs: its own switch, or the Prehistoric hunt (the loop).
        local function volcanoOn()
            return CFG.Volcano or (CFG.Hunt and CFG.HuntKind == "prehistoric")
        end
        S.volcanoOn = volcanoOn

        local function golemBuild()
            local now = os.clock()
            local all = liveEnemies(GOLEMS)
            local mine, wild = {}, {}
            for _, e in ipairs(all) do
                if S.seen then S.seen[e.model] = e.hum end
                if golemWild(e) then table.insert(wild, e) else table.insert(mine, e) end
            end
            local _, r = parts()
            local from = r and r.Position or Vector3.new(0, 0, 0)
            local cage = S.ev and S.ev.cage
            local function at(x) return x.root.Position end
            if not (CFG.Magnet and cage) then
                if #all == 0 then return {}, nil, false end
                local e = nearestOf(all, from, at)
                return { e }, e.root.Position, true
            end
            if #wild > 0 then
                local e = nearestOf(wild, from, at)
                return { e }, e.root.Position, true
            end
            if #mine > 0 then
                table.sort(mine, function(a, b)
                    return (a.root.Position - cage).Magnitude < (b.root.Position - cage).Magnitude
                end)
                local cap = math.max(1, math.floor(CFG.GrabMax or 30))
                while #mine > cap do table.remove(mine) end
                for _, e in ipairs(mine) do S.tried[e.model] = S.tried[e.model] or now end
                return mine, cage, false
            end
            return {}, nil, false
        end

        local function eventOn(isle) return isle ~= nil and isle:GetAttribute("IsMinigameActive") == true end

        -- What is live now, and what goes first.
        local function situation(isle, ev)
            local vents = liveVents(isle)
            local free, held = {}, {}
            for _, e in ipairs(liveEnemies(GOLEMS)) do
                if S.seen then S.seen[e.model] = e.hum end      -- counted when it dies
                if golemHeld(e) then table.insert(held, e) else table.insert(free, e) end
            end
            readMeters(isle, ev)
            local pick = defendPick({
                vent = #vents > 0, free = #free > 0, held = #held > 0,
                relic = ev.relicPct, pressure = ev.pressurePct,
                relicMin = tonumber(CFG.RelicMin) or 90, pressureMax = tonumber(CFG.PressureMax) or 70,
            })
            return pick, vents, free, held
        end

        local GOLEM_CUR = {
            name = "Lava Golem", build = golemBuild,
            keepHeld = true,             -- never put back: back = on the relic
            m1Weapon = function() return CFG.GolemWeapon end,   -- P.m1Of
            -- The fight ends the moment something else goes first (a vent
            -- while every golem is held), or the event or the switch ends.
            breakIf = function()
                if not (volcanoOn() and P.running) then return true end
                local isle = island()
                local ev = S.ev
                if not (eventOn(isle) and ev) then return true end
                return (situation(isle, ev)) ~= "golem"
            end,
        }
        S.GOLEM_CUR = GOLEM_CUR

        -- THE HOLDER: every frame of the event, every golem not in the fight's
        -- pile is put on its spot in the air over the cage, frozen there.
        -- A write that stuck since the last frame = held (P.heldAt).
        local GOLDEN = math.pi * (3 - math.sqrt(5))
        local function cageTick()
            local ev = S.ev
            if not (P.running and not P.handsOff and volcanoOn() and CFG.Magnet and ev and ev.cage and ev.active) then
                return
            end
            local now = os.clock()
            if now - (S.simAt or 0) > 1 then
                S.simAt = now
                if sethiddenproperty then pcall(sethiddenproperty, player, "SimulationRadius", math.huge) end
            end
            local inPile = {}
            if pileActive and pileCur == GOLEM_CUR then
                for _, e in ipairs(pile) do inPile[e.model] = true end
            end
            local i = 0
            for _, e in ipairs(liveEnemies(GOLEMS)) do
                if not inPile[e.model] then
                    i += 1
                    S.tried[e.model] = S.tried[e.model] or now
                    local prev = S.cageDest[e.model]
                    if prev and (e.root.Position - prev).Magnitude < 4 then P.heldAt[e.model] = now end
                    local a = i * GOLDEN
                    local dest = ev.cage + Vector3.new(math.cos(a) * 8, 0, math.sin(a) * 8)
                    pcall(function()
                        local hum = e.hum
                        if hum.WalkSpeed ~= 0 or not hum.PlatformStand then
                            hum.WalkSpeed, hum.JumpPower, hum.PlatformStand = 0, 0, true
                        end
                        e.root.CFrame = CFrame.new(dest)
                        e.root.AssemblyLinearVelocity = Vector3.zero
                        e.root.AssemblyAngularVelocity = Vector3.zero
                    end)
                    S.cageDest[e.model] = dest
                end
            end
            ev.caged = i
        end
        do
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if _G.BFF ~= P then conn:Disconnect() return end
                pcall(cageTick)
            end)
        end

        local function letGolemsGo()
            if pileCur == GOLEM_CUR then releasePile() end
        end

        local function countGolems(ev)
            for m, hum in pairs(S.seen) do
                if hum.Health <= 0 then
                    S.seen[m] = nil
                    ev.golems += 1
                    S.tally.golems += 1
                elseif not m.Parent then
                    S.seen[m] = nil
                end
            end
        end

        -- ---------- the vents ----------
        -- The weapons you carry, fruit first, then melee, sword, gun.
        local function ventTools()
            local list = toolNames()
            table.sort(list, function(a, b)
                local ra, rb = VENT_RANK[toolType(a)] or 9, VENT_RANK[toolType(b)] or 9
                if ra ~= rb then return ra < rb end
                return a.Name < b.Name
            end)
            return list
        end

        -- WHICH KEY CLOSES VENTS, learned: key -> { casts, closed }. A cast
        -- whose vent goes out within 1.2 s closed it. Order: keys that closed
        -- one (best rate first), then untried, then tried < 4 times, then the
        -- ones that never did - still fired when nothing else is ready.
        S.learn = {}
        local function keyScore(key, learn)
            local L = (learn or S.learn)[key]
            if not L or L.casts == 0 then return 1 end
            if L.closed > 0 then return 2 + L.closed / L.casts end
            if L.casts < 4 then return 0.5 end
            return 0
        end
        S.keyScore = keyScore
        -- (S.castAt, below: the ember hunt breaks trees with it.)

        -- A skill whose bar did not start after the key is not one this weapon
        -- has (or not unlocked): left out for 30 s.
        local ventSkip = {}
        local function aimOn(v, secs)
            P.aimAt = v.pos
            P.aimPart = v.part
            aimUntil = os.clock() + secs
        end
        local function aimOff()
            aimUntil = 0
            P.aimAt, P.aimPart = nil, nil
        end
        -- Did the vent (or v.alive's thing: a tree) go within `secs`?
        local function watchClosed(v, secs)
            local function live()
                -- A sea beast (SEA EVENTS): its HP went down = the move landed.
                if v.dropped and v.dropped() then return false end
                if v.alive then return v.alive() end
                return ventLive(v.model)
            end
            local t0 = os.clock()
            repeat
                if not live() then return true end
                task.wait(0.1)
            until os.clock() - t0 >= secs
            return not live()
        end
        local function credit(key, closed, learn)
            learn = learn or S.learn
            local L = learn[key] or { casts = 0, closed = 0 }
            learn[key] = L
            L.casts += 1
            if closed then L.closed += 1 end
        end
        -- A sea beast (SEA EVENTS) brings its own: v.keys / v.keyOn (Z-F and
        -- its switches), v.mark (its HP before each action), v.dropped (went
        -- down since), v.m1Tool (whose M1 to swing), v.m1Watch (seconds).
        local function ventCast(v, rotated)
            local pos = v.pos
            local now = os.clock()
            local function aimIt()
                RunService.Heartbeat:Wait()
                -- P.aimAt: a moving target's live body (SEA EVENTS keeps it on it).
                local at = P.aimAt or pos
                pcall(aimSwapIn, at, at)
            end
            local cands = {}
            for ti, t in ipairs(ventTools()) do
                for ki, k in ipairs(v.keys or VENT_KEYS) do
                    -- v.toolOk: a transformed fruit takes only its own moves (SEA EVENTS).
                    if (v.keyOn or CFG.VentKeys or {})[k] and (not v.toolOk or v.toolOk(t.Name)) then
                        -- v.suffix: " (form)" - a transformed fruit's moves learned apart.
                        local key = t.Name .. " " .. k .. (v.suffix or "")
                        table.insert(cands, { tool = t, k = k, key = key, score = keyScore(key, v.learn), order = ti * 10 + ki })
                    end
                end
            end
            table.sort(cands, function(a, b)
                if a.score ~= b.score then return a.score > b.score end
                return a.order < b.order
            end)
            for _, c in ipairs(cands) do
                if now >= (ventSkip[c.key] or 0) and skillReady(c.tool.Name, c.k)
                    and equip(c.tool.Name) and barReady(c.tool.Name, c.k) ~= false then
                    local w = CFG.Weapons[c.tool.Name]
                    local hold = (w and w.hold and w.hold[c.k]) or 0.05
                    aimOn(v, hold + (CFG.CastWait or 0.45) + 1.5)
                    if v.mark then v.mark() end
                    holdKey(KEYCODE[c.k], hold, aimIt)
                    cdOf(c.tool.Name, c.k).lastCast = os.clock()
                    stats.casts += 1
                    task.wait(CFG.CastWait or 0.45)
                    local fired = barReady(c.tool.Name, c.k) ~= true
                    local closed = watchClosed(v, 0.75)
                    aimOff()
                    if not fired then ventSkip[c.key] = os.clock() + 30 end
                    credit(c.key, closed, v.learn)
                    if not v.learn then S.lastVent = c.key end
                    return c.key, closed
                end
            end
            -- Nothing ready: a rested sword / gun from your inventory, once.
            local rot = (P :: any).rotate
            -- (v.noRotate: a fight that takes no sword / gun - SEA EVENTS.)
            if not rotated and not (v.noRotate and v.noRotate()) and rot and rot(true) then return ventCast(v, true) end
            -- A thing only blasts break (v.noM1, the ember hunt's trees): no
            -- plain M1 - wait for a key. nil key = nothing was fired.
            if v.noM1 then
                task.wait(0.3)
                return nil, false
            end
            -- Still nothing: an aimed M1 with what is in hand (Skull Guitar,
            -- Bazooka, Cannon and Gravity close vents with M1 - the wiki). A
            -- sea beast: the weapon whose M1 hurt it (v.m1Tool) in hand first.
            local want = v.m1Tool and v.m1Tool()
            if want then equip(want) end
            local held = heldTool()
            local key = "M1 " .. (held and held.Name or "(empty hand)") .. (v.suffix or "")
            local cam = workspace.CurrentCamera
            if cam then
                aimOn(v, 1.2)
                if v.mark then v.mark() end
                aimPixel = cam.ViewportSize * 0.5
                aimIt()
                pressM1()
                aimPixel = nil
            end
            local closed = watchClosed(v, v.m1Watch or 0.3)
            aimOff()
            credit(key, closed, v.learn)
            if not v.learn then S.lastVent = key .. " (every key cooling)" end
            task.wait(0.05)
            return key, closed
        end
        S.ventCast = ventCast

        -- ---------- the gun M1 at the vents ----------
        -- Skull Guitar first (its M1 has Destructible Physics - the wiki;
        -- user: "the skull guitar M1 ... really useful"), then Bazooka, Cannon.
        local VENT_M1_GUNS = { "Skull Guitar", "Bazooka", "Cannon" }
        S.gunWay = {}        -- [gun] = "remote" | "click" | "both" (Skull Guitar: proven by its energy)
        S.gunProbe = {}
        local function carriedTool(name)
            for _, t in ipairs(toolNames()) do
                if t.Name == name then return t end
            end
            return nil
        end
        local function ventGun()
            for _, n in ipairs(VENT_M1_GUNS) do
                if carriedTool(n) then return n end
            end
            return nil
        end
        S.ventGun = ventGun
        -- Not carried: the first of them in your inventory, into your hands.
        local function loadVentGun()
            if ventGun() then return end
            local has, load = (P :: any).invHas, (P :: any).loadItem
            if not (has and load) then return end
            for _, n in ipairs(VENT_M1_GUNS) do
                if has(n) then
                    if load(n) then print("[BFF] volcano: " .. n .. " loaded from your inventory for the vents") end
                    return
                end
            end
        end
        local function energy()
            local ok, e = pcall(function()
                local ch = player.Character
                local v = ch and ch:FindFirstChild("Energy")
                return v and tonumber(v.Value)
            end)
            return ok and e or nil
        end
        -- The gun to use on this vent, or nil = the skills: switch off, none
        -- carried, energy low in the last 5 s, or 6 tries of it closed nothing.
        -- learn = whose table judges it (the trees keep their own).
        local function gunForVents(learn)
            if not CFG.VentGuitar then return nil end
            local g = ventGun()
            if not g then return nil end
            if os.clock() - (S.lowEnergyAt or -100) < 5 then return nil end
            local L = (learn or S.learn)[g .. " M1"]
            if L and L.casts >= 6 and L.closed == 0 then return nil end
            return g
        end

        -- Shots at the vent, stood still, for VentM1Time or until it goes.
        -- Skull Guitar: its tool's RemoteEvent ("TAP", the vent) - the public
        -- hubs' gun fast attack; the first shots are checked against its
        -- energy (20 a shot): spent = the remote fires; not = the aimed click
        -- from then on; energy not readable = both. Other guns: the aimed click
        -- (silent aim + the camera on the vent). true closed.
        local function gunM1(v, name)
            if not equip(name) then return name .. " M1", false end
            local tool = carriedTool(name)
            local re = nil
            if name == "Skull Guitar" and tool then
                local okR, r = pcall(function() return tool:FindFirstChild("RemoteEvent") end)
                re = okR and r or nil
            end
            local key = name .. " M1"
            local function aimIt()
                RunService.Heartbeat:Wait()
                pcall(aimSwapIn, v.pos, v.pos)
            end
            local t0, closed, low = os.clock(), false, false
            aimOn(v, (CFG.VentM1Time or 3) + 1)
            while os.clock() - t0 < (CFG.VentM1Time or 3) do
                local e0 = energy()
                if e0 and e0 < 20 then
                    S.lowEnergyAt = os.clock()
                    low = true
                    break
                end
                local way = S.gunWay[name] or (re and "probe" or "click")
                if re and way ~= "click" then
                    pcall(function() re:FireServer("TAP", v.pos) end)
                end
                if not re or way == "click" or way == "both" then
                    local cam = workspace.CurrentCamera
                    if cam then
                        aimPixel = cam.ViewportSize * 0.5
                        aimIt()
                        pressM1()
                        aimPixel = nil
                    end
                end
                stats.casts += 1
                task.wait(CFG.VentM1Every or 0.3)
                if re and way == "probe" then
                    local e1 = energy()
                    if not (e0 and e1) then
                        S.gunWay[name] = "both"
                    elseif e1 < e0 - 5 then
                        S.gunWay[name] = "remote"
                        print("[BFF] volcano: " .. name .. " M1 by its remote - it fires")
                    else
                        S.gunProbe[name] = (S.gunProbe[name] or 0) + 1
                        if S.gunProbe[name] >= 3 then
                            S.gunWay[name] = "click"
                            print("[BFF] volcano: " .. name .. "'s remote spent no energy in 3 shots - the aimed click")
                        end
                    end
                end
                if not (v.alive and v.alive() or (not v.alive and ventLive(v.model))) then
                    closed = true
                    break
                end
            end
            aimOff()
            credit(key, closed, v.learn)
            S.lastVent = low and (key .. " - energy low, the skills for a moment")
                or (key .. " (" .. tostring(S.gunWay[name] or "probing") .. ")")
            return key, closed
        end

        local function patchVent(ev, v, myEpoch)
            local stand = standFor(v.pos, ev.centre or v.pos, CFG.VentDistance or 12)
            ev.note = string.format("closing a vent  ·  %d closed  ·  %d golems down", ev.vents, ev.golems)
            say(ev.note)
            local _, r = parts()
            if not r then return end
            if (r.Position - stand).Magnitude > 4 then
                safeFly(stand, ev.isle, nil, myEpoch, { face = v.pos })
                if stale(myEpoch) then return end
            end
            lockAt(stand, v.pos)
            local key, closed
            local gun = gunForVents()
            if gun then key, closed = gunM1(v, gun) end
            if not closed and not gun then key, closed = ventCast(v) end
            if closed then
                ev.vents += 1
                S.tally.vents += 1
                print(string.format("[BFF] volcano: vent closed by %s  ·  %d this event", tostring(key), ev.vents))
            end
        end

        -- Lava on the volcano kills; the hubs take it off the client. The
        -- vents, the relic, the prompt, the eggs and the cave door stay.
        local function clearLava(isle)
            local c = core(isle)
            local il = c and c:FindFirstChild("InteriorLava")
            if il then pcall(function() il:Destroy() end) end
            local keep = {}
            for _, n in ipairs({ "VolcanoRocks", "PrehistoricRelic", "ActivationPrompt", "SpawnedDragonEggs" }) do
                local x = c and c:FindFirstChild(n)
                if x then table.insert(keep, x) end
            end
            local tt = isle:FindFirstChild("TrialTeleport")
            if tt then table.insert(keep, tt) end
            for _, d in ipairs(isle:GetDescendants()) do
                if d:IsA("BasePart") and string.find(string.lower(d.Name), "lava", 1, true) then
                    local kept = false
                    for _, k in ipairs(keep) do
                        if d:IsDescendantOf(k) then kept = true break end
                    end
                    if not kept then pcall(function() d:Destroy() end) end
                end
            end
        end

        -- The island's lava off your client, at most every 2 s - from the
        -- moment it streams in, not only once the event runs.
        function S.lavaOff(isle)
            if os.clock() - (S.lavaAt or 0) > 2 then
                S.lavaAt = os.clock()
                pcall(clearLava, isle)
            end
        end

        -- ---------- WHAT YOU HAVE: the game's own count ----------
        -- (user, 2026-10-07: bones and an egg "picked" never reached the
        -- inventory - the pick was judged by the bone VANISHING, the egg's
        -- prompt going.) A pick counts only when the game's count goes up.
        -- The game keeps your items in ItemReplicationService (decompile
        -- v4623, 2026-10-05): Net "RF/GetAllItemValues" answers every
        -- { Key, ItemId, Value } you own, "RE/OnItemValueChanged" pushes each
        -- change; a count is Key "Quantity". CommF_("getInventory") is the
        -- legacy path (on the user's client it answered nothing, even 3 min
        -- after a join - 2026-10-06 logs) - the fallback. Ids: the game's
        -- Economy.ItemId.RawSource. Bones and the egg are stored materials,
        -- straight into the inventory, never held (user, 2026-10-07: "same
        -- as Mirror Fractal") - the material ids only.
        local ITEM_IDS = {
            ["Dinosaur Bones"] = { 585 }, ["Dragon Egg"] = { 565 },
            ["Volcanic Magnet"] = { 550 }, ["Blaze Ember"] = { 587 }, ["Scrap Metal"] = { 566 },
        }
        local LOOT = { "Dinosaur Bones", "Dragon Egg" }
        local LOOT_FILE = "bff_loot.json"
        S.LOOT = LOOT

        -- Pure (tools/sea_test.py): { [ItemId] = quantity } off the game's
        -- item-value list.
        local function qtyOf(list)
            local q = {}
            for _, it in pairs(list) do
                if type(it) == "table" and it.Key == "Quantity" then
                    local id = tonumber(it.ItemId)
                    if id then q[id] = (q[id] or 0) + (tonumber(it.Value) or 0) end
                end
            end
            return q
        end

        -- The game's push, kept: S.qty stays current between full reads.
        task.spawn(function()
            local re = netRemote("RE", "OnItemValueChanged")
            if not re then return end
            local conn
            conn = re.OnClientEvent:Connect(function(items)
                if _G.BFF ~= P then conn:Disconnect() return end
                if type(items) ~= "table" or not S.qty then return end
                for _, it in pairs(items) do
                    if type(it) == "table" and it.Key == "Quantity" then
                        local id = tonumber(it.ItemId)
                        if id then S.qty[id] = tonumber(it.Value) or 0 end
                    end
                end
            end)
        end)

        -- A full read from the server. false = could not (S.invWhy says why).
        local function readQty()
            S.qtyTry = os.clock()
            local rf = netRemote("RF", "GetAllItemValues")
            if not rf then
                S.invWhy = "no GetAllItemValues remote"
                return false
            end
            local ok, list = pcall(function() return rf:InvokeServer() end)
            if ok and type(list) == "table" then
                S.qty, S.qtyRead, S.invSrc = qtyOf(list), os.clock(), "the game's item list"
                return true
            end
            S.invWhy = "GetAllItemValues gave " .. (ok and ("a " .. type(list)) or ("an error: " .. tostring(list)))
            return false
        end
        -- The legacy list; nil when its last ask gave nothing.
        local function readLegacy()
            S.legacyTry = os.clock()
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if not (ok and type(inv) == "table") then
                S.legacyInv = nil
                S.invWhy = tostring(S.invWhy) .. "  ·  getInventory gave "
                    .. (ok and ("a " .. type(inv)) or ("an error: " .. tostring(inv)))
                return
            end
            S.legacyInv, S.invSrc = inv, "getInventory (legacy)"
        end
        local function legacyCount(inv, names)
            local out = {}
            for _, n in ipairs(names) do out[n] = 0 end
            for _, it in pairs(inv) do
                if type(it) == "table" and out[it.Name] ~= nil then
                    out[it.Name] += tonumber(it.Count) or 1
                end
            end
            return out
        end

        -- { [name] = count } of `names`, or nil (unreadable - S.invWhy). fresh
        -- = asked of the server now; else the last full read, kept current by
        -- the game's pushes. Not fresh, the server is asked at most every 2 s
        -- (either list) - never a remote a frame.
        function S.have(names, fresh)
            local now = os.clock()
            if fresh or ((not S.qtyRead or now - S.qtyRead > 5) and now - (S.qtyTry or -99) >= 2) then
                readQty()
            end
            if S.qtyRead then
                local out = {}
                for _, n in ipairs(names) do
                    local sum = 0
                    for _, id in ipairs(ITEM_IDS[n] or {}) do sum += (S.qty[id] or 0) end
                    out[n] = sum
                end
                return out
            end
            if fresh or now - (S.legacyTry or -99) >= 2 then readLegacy() end
            return S.legacyInv and legacyCount(S.legacyInv, names) or nil
        end
        -- The count as last known - no call to the server (the panel).
        function S.peek(name)
            if not S.qtyRead then return nil end
            local sum = 0
            for _, id in ipairs(ITEM_IDS[name] or {}) do sum += (S.qty[id] or 0) end
            return sum
        end

        -- Waits up to `secs` for the game's count of `name` to go over
        -- `before` (giveUp() = stop early). -> the count now (nil =
        -- unreadable), and whether it went up.
        local function gained(name, before, secs, myEpoch, giveUp)
            local t0 = os.clock()
            while os.clock() - t0 < secs and not stale(myEpoch) do
                local h = S.have({ name }, false)
                local now = h and h[name]
                if before and now and now > before then return now, true end
                if giveUp and giveUp(os.clock() - t0) then break end
                task.wait(0.15)
            end
            local h = S.have({ name }, true)       -- once more, from the server itself
            local now = h and h[name]
            return now, (before ~= nil and now ~= nil and now > before)
        end

        -- ---------- the loot ----------
        local function bonesLying(isle)
            local c = posOf(isle)
            local out = {}
            for _, d in ipairs(workspace:GetChildren()) do
                if d.Name == "DinoBone" and not S.boneSkip[d] then
                    local p = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart", true)
                    if p and (not c or (p.Position - c).Magnitude < 3000) then
                        table.insert(out, { inst = d, part = p })
                    end
                end
            end
            return out
        end
        local function eggPrompt(isle)
            local se = core(isle) and core(isle):FindFirstChild("SpawnedDragonEggs")
            for _, d in ipairs(se and se:GetDescendants() or {}) do
                if d:IsA("ProximityPrompt") and d.Enabled and not S.eggSkip[d] then return d end
            end
            return nil
        end

        local function counted()
            return tostring(player:GetAttribute("PrehistoricIslandParticipant") == true)
        end
        local function lootText(h)
            if not h then return "not readable (" .. tostring(S.invWhy) .. ")" end
            return string.format("%d Dinosaur Bones, %d Dragon Egg", h["Dinosaur Bones"] or 0, h["Dragon Egg"] or 0)
        end
        S.lootText = lootText

        local function lootStep(isle, ev, myEpoch)
            local _, r = parts()
            if not r then return end
            ev.base = ev.base or S.have(LOOT, true)            -- what you had before the first pick
            local bones = bonesLying(isle)
            if #bones > 0 then
                local bn = nearestOf(bones, r.Position, function(x) return x.part.Position end)
                ev.note = string.format("picking up dinosaur bones  ·  %d lying", #bones)
                say(ev.note)
                local h0 = S.have({ "Dinosaur Bones" }, true)
                local before = h0 and h0["Dinosaur Bones"]
                flyTo(bn.part.Position)
                local onAt = os.clock()
                task.wait(0.3)
                lockAt(bn.part.Position + UP * 2)
                local now, up = gained("Dinosaur Bones", before, 2, myEpoch)
                -- Slowly (user, 2026-10-10): BoneMin..BoneMax s on each bone.
                local lo = math.max(tonumber(CFG.BoneMin) or 0.5, 0)
                local hi = math.max(tonumber(CFG.BoneMax) or 1, lo)
                local dwell = lo + math.random() * (hi - lo)
                while os.clock() - onAt < dwell and not stale(myEpoch) do task.wait(0.05) end
                if up then
                    local n = now - before
                    ev.bones += n
                    S.tally.bones += n
                    ev.lastPickAt = os.clock()
                    S.boneSkip[bn.inst] = true             -- yours: never again, gone or not
                    print(string.format("[BFF] loot: Dinosaur Bones %d -> %d - in your inventory", before, now))
                elseif bn.inst.Parent then
                    local n = (S.boneTries[bn.inst] or 0) + 1
                    S.boneTries[bn.inst] = n
                    if n >= 3 then S.boneSkip[bn.inst] = true end
                elseif before == nil then
                    ev.bonesUnread = (ev.bonesUnread or 0) + 1
                    ev.lastPickAt = os.clock()
                    print("[BFF] loot: a bone went - your inventory is not readable here, NOT confirmed ("
                        .. tostring(S.invWhy) .. ")")
                else
                    ev.bonesGone = (ev.bonesGone or 0) + 1
                    print(string.format("[BFF] loot: a bone went but your Dinosaur Bones stayed %d - NOT given to you"
                        .. " (counted by the game: %s)%s", before, counted(),
                        (before >= 99) and " - 99 is the most you can hold" or ""))
                end
                return
            end
            local pp = eggPrompt(isle)
            if pp then
                local at = posOf(pp.Parent)
                ev.note = "the Dragon Egg"
                say(ev.note)
                local h0 = S.have({ "Dragon Egg" }, true)
                local before = h0 and h0["Dragon Egg"]
                if at then flyTo(at + UP * 3) end
                if stale(myEpoch) then return end
                if at then lockAt(at + UP * 3) end         -- still, right here, the whole pickup
                holdPrompt(pp, myEpoch)
                local pressAt = os.clock()
                local stay = math.max(tonumber(CFG.EggStay) or 4, 0)
                -- Stay by it while the game hands it over (its pickup plays);
                -- a prompt still there after 2.5 s = it was not taken.
                local now, up = gained("Dragon Egg", before, math.max(6, stay + 2), myEpoch, function(t)
                    return t > 2.5 and pp.Parent ~= nil and pp.Enabled
                end)
                -- ITS ANIMATION (user, 2026-10-10: ~3 s into the inventory;
                -- moved before it ends = not yours): stood still EggStay s
                -- after E, the count up or not. Prompt still on = not taken.
                if not (pp.Parent and pp.Enabled) then
                    while os.clock() - pressAt < stay and not stale(myEpoch) do task.wait(0.1) end
                end
                if up then
                    ev.eggs += 1
                    S.tally.eggs += 1
                    ev.lastPickAt = os.clock()
                    S.eggSkip[pp] = true
                    notify("Dragon Egg - in your inventory!")
                    print(string.format("[BFF] loot: Dragon Egg %d -> %d - in your inventory", before, now))
                elseif pp.Parent and pp.Enabled then
                    local n = (S.eggTries[pp] or 0) + 1
                    S.eggTries[pp] = n
                    if n >= 2 then
                        S.eggSkip[pp] = true
                        ev.note = "the egg will not come - it needs the Dragon Tether, a hit on a golem or vent, and the relic over 90%"
                        print("[BFF] volcano: " .. ev.note)
                    end
                elseif before == nil then
                    S.eggSkip[pp] = true
                    ev.eggUnread = true
                    ev.lastPickAt = os.clock()
                    print("[BFF] loot: the egg's prompt went - your inventory is not readable here, NOT confirmed ("
                        .. tostring(S.invWhy) .. ")")
                else
                    S.eggSkip[pp] = true
                    ev.eggGone = true
                    print(string.format("[BFF] loot: the egg's prompt went but your Dragon Egg stayed %d - NOT given to you"
                        .. " (counted by the game: %s)", before, counted()))
                end
            end
        end

        -- The loot over: the game's count now, said; written for the next
        -- server to check (S.checkLastLoot there).
        local function lootDone(ev)
            local h = S.have(LOOT, true)
            local b = ev.base or {}
            local function arrow(n)
                local x, y = b[n], h and h[n]
                if not (x and y) then return string.format("%s %s", n, y and tostring(y) or "not readable") end
                return string.format("%s %d -> %d (%+d)", n, x, y, y - x)
            end
            ev.final = h
            print(string.format("[BFF] volcano: DONE - %d bones, %d egg  ·  %s  ·  %s%s", ev.bones, ev.eggs,
                arrow("Dinosaur Bones"), arrow("Dragon Egg"),
                (((ev.bonesGone or 0) > 0) or ev.eggGone) and "  ·  some went WITHOUT reaching your inventory" or ""))
            if h and writefile then
                pcall(writefile, LOOT_FILE, string.format("bones=%d;eggs=%d;at=%d;job=%s",
                    h["Dinosaur Bones"], h["Dragon Egg"], os.time(), tostring(game.JobId)))
            end
        end

        -- THE LAST SERVER'S LOOT, checked here (user, 2026-10-07: progress
        -- lost). Less here than the last server's game said when it was left
        -- = it was not saved: said, and the Prehistoric hunt stops (the user
        -- decides - "stay after the loot" on the Sea page is the lever).
        function S.checkLastLoot()
            if not readfile then return end
            local ok, s = pcall(readfile, LOOT_FILE)
            if not ok or type(s) ~= "string" or s == "" then return end
            local b, e, at, job = string.match(s, "^bones=(%d+);eggs=(%d+);at=(%d+);job=(.*)$")
            b, e, at = tonumber(b), tonumber(e), tonumber(at)
            if not (b and e and at) then return end
            if job == tostring(game.JobId) then return end          -- a reload in the same server
            if writefile then pcall(writefile, LOOT_FILE, "") end   -- checked once
            if os.time() - at > 1800 then return end                -- old: not this hop
            local h = nil
            for _ = 1, 40 do
                if _G.BFF ~= P then return end
                h = S.have(LOOT, true)
                if h then break end
                task.wait(1)
            end
            if not h then
                S.lootCheck = "the last server's loot NOT checked - your inventory is not readable here ("
                    .. tostring(S.invWhy) .. ")"
                print("[BFF] loot: " .. S.lootCheck)
                return
            end
            local hb, he = h["Dinosaur Bones"], h["Dragon Egg"]
            if hb < b or he < e then
                S.lootCheck = string.format("LOST ON THE HOP - the last server had %d Dinosaur Bones, %d Dragon Egg; "
                    .. "here %d and %d. The game did not save them. Prehistoric hunt stopped - raise \"stay after "
                    .. "the loot\" (Sea page)", b, e, hb, he)
                print("[BFF] loot: " .. S.lootCheck)
                notify("Loot LOST on the hop - the hunt stopped (Sea page)")
                if CFG.Hunt and CFG.HuntKind == "prehistoric" then
                    P.setHunt(false)
                    task.defer(function() pcall((P :: any).stop) end)
                end
            else
                S.lootCheck = string.format("the last server's loot is here: %d Dinosaur Bones, %d Dragon Egg - saved", hb, he)
                print("[BFF] loot: " .. S.lootCheck)
            end
        end

        local function startEvent(isle, ev, myEpoch)
            local pp, at = promptOf(isle)
            if not (pp and at) then return end
            ev.note = "starting the event at the relic"
            say(ev.note)
            safeFly(at + UP * 3, isle, nil, myEpoch)
            if stale(myEpoch) then return end
            local function cameOn(secs)
                local t0 = os.clock()
                while os.clock() - t0 < secs and not stale(myEpoch) do
                    if eventOn(isle) then
                        ev.startedAt = os.clock()
                        S.tally.events += 1
                        ev.note = "THE VOLCANO EVENT IS ON"
                        print("[BFF] volcano: event started")
                        return true
                    end
                    task.wait(0.2)
                end
                return false
            end
            holdPrompt(pp, myEpoch)
            if cameOn(2) or stale(myEpoch) then return end
            -- The key itself, as you would (one hub holds E 1.5 s after the
            -- prompt): standing at it, facing the skull.
            lockAt(at + UP * 3, at)
            holdKey(Enum.KeyCode.E, math.max(1.5, (tonumber(pp.HoldDuration) or 1) + 0.4))
            if cameOn(3) or stale(myEpoch) then return end
            ev.starts += 1
            ev.note = string.format("pressed the relic %d times - the event did not start (the game's own start bug?)", ev.starts)
            print("[BFF] volcano: " .. ev.note)
            -- The wiki: "the event does not start, even after interacting" - a
            -- known bug. Four tries: this island is given up (the hunt hops).
            if ev.starts >= 4 then
                ev.complete, ev.stuck = true, true
                print("[BFF] volcano: the event will not start here - giving this island up")
            end
        end

        local function defend(isle, ev, myEpoch)
            if os.clock() - (S.lavaAt or 0) > 2 then
                S.lavaAt = os.clock()
                pcall(clearLava, isle)
            end
            if not ev.dumped then
                ev.dumped = true
                pcall(dumpMeters, isle, ev, "event start")
            elseif not ev.dumped2 and ev.startedAt and os.clock() - ev.startedAt > 20 then
                ev.dumped2 = true
                pcall(dumpMeters, isle, ev, "20 s in")
            end
            local pick, vents, free, held = situation(isle, ev)
            ev.liveVents, ev.liveGolems, ev.freeGolems = #vents, #free + #held, #free
            local meters = string.format("relic %s  ·  pressure %s",
                ev.relicPct and string.format("%.0f%%", ev.relicPct) or "?",
                ev.pressurePct and string.format("%.0f%%", ev.pressurePct) or "?")
            if pick == "vent" then
                local _, r = parts()
                local from = r and r.Position or ev.centre or vents[1].pos
                patchVent(ev, nearestOf(vents, from, function(x) return x.pos end), myEpoch)
                ev.note = string.format("vents  ·  %s  ·  %d closed  ·  %d held golems", meters, ev.vents, #held)
            elseif pick == "golem" then
                activeName = "Lava Golem"
                ev.note = string.format("%s  ·  %s  ·  %d down",
                    (#free > 0) and (#free .. " golem(s) NOT held - on them first") or (#held .. " held golem(s)"),
                    meters, ev.golems)
                say(ev.note)
                fight(GOLEM_CUR, GOLEMS)
            else
                local at = ev.relic or relicPos(isle)
                if at then safeFly(at + UP * 25, isle, nil, myEpoch) end
                ev.note = string.format("event on - waiting  ·  %s  ·  %d closed  ·  %d down", meters, ev.vents, ev.golems)
                say(ev.note)
                task.wait(0.2)
            end
        end

        -- THE EVENT, one step. true = it is handling the island (nothing else
        -- runs); false = no island here, or the switch is off.
        function S.volcanoStep()
            if not volcanoOn() then
                letGolemsGo()
                return false
            end
            local isle, mk = island(), marker()
            if not (isle or mk) or (mySea() and mySea() ~= 3) then
                letGolemsGo()
                S.ev = nil
                P.keepGun = nil
                return false
            end
            -- Gone home by respawn after the loot (S.huntStep): the island is
            -- behind you, never flown back to - the hunt goes to the next server.
            local home = S.ev and S.ev.home
            if (home == "done" or home == "failed") and CFG.Hunt and CFG.HuntKind == "prehistoric"
                and (CFG.VolcanoAfter or "hop") == "hop" then
                letGolemsGo()
                P.keepGun = nil
                return false
            end
            local myEpoch = epoch
            if S.driving then stopDrive() end
            if isle then S.lavaOff(isle) end
            if not isle then
                -- Only the marker: far away. Fly there; the island streams in.
                local _, r = parts()
                local keep = tonumber(CFG.VolcanoKeepOut) or 220
                if r and (r.Position - mk).Magnitude > keep * 1.6 + 60 then
                    setState("FLY")
                    S.note = "to the Prehistoric Island (its edge - never the volcano)"
                    say(S.note)
                    safeFly(edgeOf(mk, r.Position, keep), nil, mk, epoch)
                else
                    task.wait(0.3)
                end
                return true
            end
            local ev = S.ev
            if not ev or ev.isle ~= isle then
                ev = { isle = isle, vents = 0, golems = 0, bones = 0, eggs = 0, starts = 0, note = "island up" }
                S.ev = ev
                S.seen = setmetatable({}, { __mode = "k" })
                S.boneSkip, S.boneTries = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
                S.eggSkip, S.eggTries = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
            end
            if not ev.cage then
                local rel, centre = relicPos(isle), volcanoCentre(isle)
                if rel and centre then
                    ev.relic, ev.centre = rel, centre
                    ev.cage = cageSpot(rel, centre, CFG.GolemCage or 60) + UP * (tonumber(CFG.GolemLift) or 60)
                end
            end
            countGolems(ev)
            if CFG.VentGuitar and not ev.gunTried then
                ev.gunTried = true
                pcall(loadVentGun)
            end
            -- The golem weapon, from your inventory if not carried.
            local gw = CFG.GolemWeapon
            if type(gw) == "string" and gw ~= "" and not ev.swordTried then
                ev.swordTried = true
                local has, load = (P :: any).invHas, (P :: any).loadItem
                local carried = false
                for _, t in ipairs(toolNames()) do
                    if t.Name == gw then carried = true end
                end
                if carried then
                    S.golemNote = gw .. " - carried"
                elseif has and load and has(gw) then
                    local ok = load(gw)
                    S.golemNote = gw .. (ok and " - loaded from your inventory" or " - in your inventory, would not load")
                    print("[BFF] volcano: " .. S.golemNote)
                else
                    S.golemNote = gw .. " - not found (carried or inventory): the Attack page's M1 pick"
                    print("[BFF] volcano: " .. S.golemNote)
                end
            end
            P.keepGun = CFG.VentGuitar and ventGun() or nil
            local active = eventOn(isle)
            ev.active = active
            if active and not ev.startedAt then ev.startedAt = os.clock() end
            -- Once it is on: whether the game counts you (the wiki: only those
            -- there when the relic was touched get loot) and what you have
            -- before; a death during it is said (no loot after one).
            if active and not ev.saidCounted then
                ev.saidCounted = true
                ev.life = player.Character
                ev.base = ev.base or S.have(LOOT, true)
                print("[BFF] volcano: event on - " .. ((player:GetAttribute("PrehistoricIslandParticipant") == true)
                    and "you ARE counted by the game (PrehistoricIslandParticipant) - the bones and the egg can be yours"
                    or "you are NOT counted by the game (PrehistoricIslandParticipant off) - no bones or egg for you this time")
                    .. "  ·  you have " .. lootText(ev.base))
            end
            if active and ev.life and player.Character ~= ev.life and not ev.died then
                ev.died = true
                print("[BFF] volcano: you died during the event - the game gives no bones or egg after a death (wiki)")
            end
            local pp = promptOf(isle)
            local lootLeft = CFG.VolcanoLoot and not active
                and (#bonesLying(isle) > 0 or eggPrompt(isle) ~= nil)
            -- OVER: it ran here and is not on now. COMPLETE: over, nothing left
            -- to pick (8 s for the bones and the egg to come).
            if active then ev.ran = true end
            if ev.ran and not active and not ev.overAt then
                ev.overAt = os.clock()
                print(string.format("[BFF] volcano: event over - %d vents, %d golems down", ev.vents, ev.golems))
            end
            if ev.overAt and not ev.complete and not lootLeft and os.clock() - ev.overAt > 8 then
                -- Anything picked and the hunt about to leave the server: stay
                -- LootStay s after the last pick first, so the game saves it
                -- (user, 2026-10-07: loot lost - the loop left ~3 s after the
                -- last bone, ~10 s after the egg).
                local picked = ev.bones + ev.eggs + (ev.bonesUnread or 0) + (ev.eggUnread and 1 or 0)
                local leaving = CFG.Hunt and CFG.HuntKind == "prehistoric" and (CFG.VolcanoAfter or "hop") == "hop"
                local stay = (picked > 0 and leaving) and math.max(tonumber(CFG.LootStay) or 20, 0) or 0
                local since = os.clock() - (ev.lastPickAt or ev.overAt)
                if since < stay then
                    letGolemsGo()
                    ev.note = string.format("loot in - staying %s so the game saves it, then %sthe next server",
                        mmss(stay - since), CFG.RespawnHome and "home by respawn and " or "")
                    S.note = ev.note
                    say(ev.note)
                    setState("VOLCANO")
                    task.wait(0.5)
                    return true
                end
                ev.complete = true
                S.tally.done = (S.tally.done or 0) + 1
                lootDone(ev)
            end
            if ev.complete and (ev.stuck or (CFG.VolcanoAfter or "hop") == "hop") then
                letGolemsGo()
                if CFG.Hunt and CFG.HuntKind == "prehistoric" then
                    return false        -- the hunt hops (huntStep: E.why)
                end
                ev.note = "event done - hunt off, so no hop; holding here"
                S.note = ev.note
                say(ev.note)
                task.wait(0.5)
                return true
            end
            if ev.complete then
                -- "again": a fresh event on this island.
                ev.complete, ev.ran, ev.overAt, ev.home = false, false, nil, nil
            end
            local ph = phase(active, pp ~= nil and pp.Enabled, lootLeft)
            ev.phase = ph
            ev.counted = player:GetAttribute("PrehistoricIslandParticipant")
            setState("VOLCANO")
            activeName = "Prehistoric Island"
            if ph ~= "defend" then letGolemsGo() end
            if ph == "defend" then
                defend(isle, ev, myEpoch)
            elseif ph == "loot" then
                lootStep(isle, ev, myEpoch)
            elseif ph == "start" then
                startEvent(isle, ev, myEpoch)
            else
                local at = frontOf(isle)
                if at then safeFly(at, isle, nil, myEpoch) end
                ev.note = "island up - the event is over or not ready; holding at the relic"
                say(ev.note)
                task.wait(0.5)
            end
            S.note = ev.note
            return true
        end

        -- For the tests.
        S._t = {
            metersFrom = metersFrom, headingFor = headingFor, yawOf = yawOf, turnStep = turnStep,
            cageSpot = cageSpot, standFor = standFor, phase = phase, defendPick = defendPick,
            ventLive = ventLive, golemBuild = golemBuild, driveTick = driveTick, drive = drive,
            mirageFits = mirageFits, blueGear = blueGear, keysDown = keysDown, seatOf = seatOf,
            nextHeading = nextHeading, searchLeg = searchLeg, arcPath = arcPath, edgeOf = edgeOf,
            pctFrom = pctFrom, pctText = pctText, readMeters = readMeters, cageTick = cageTick,
            situation = situation, golemHeld = golemHeld, ventCast = ventCast,
            gunM1 = gunM1, gunForVents = gunForVents, qtyOf = qtyOf,
        }
        -- The last server's loot, checked once this one's inventory reads.
        task.defer(function() pcall(S.checkLastLoot) end)
        -- ANY THING TO BREAK (the ember hunt's trees), aimed: v = { pos, part,
        -- model, alive = fn, learn = table }. The gun M1 first (the wiki,
        -- Dragon Hunter: "Skull Guitar or Bazooka ... the m1 can break them"),
        -- else the skills of every weapon you carry; never a plain M1 (user,
        -- 2026-10-05: a fighting style's M1 does nothing to a tree). nil key =
        -- nothing fired (every key cooling).
        function S.castAt(v)
            local g = gunForVents(v.learn)
            if g then return gunM1(v, g) end
            v.noM1 = true
            return ventCast(v)
        end
    end
    build()
end

-- =========================================================
-- EMBER HUNT
-- =========================================================
-- THE BLAZE EMBER HUNT (Third Sea; HuntKind "ember"). The Dragon Hunter in
-- the Dragon Dojo (Hydra Island) gives "Hunt" quests, one at a time, no
-- limit (the wiki, 2026-10): defeat 3 Hydra Enforcers, defeat 3 Venomous
-- Assailants, or destroy 10 trees on Hydra Island. A quest drops 3 Blaze
-- Embers that drift toward you; run through one to take it. He gives
-- nothing without Dragon Talon at 500 mastery and the Dojo's Yellow Belt.
-- Two public hubs (2026) agree on the game's side:
--   Modules.Net["RF/DragonHunter"]:InvokeServer({ Context = "RequestQuest" })
--   Modules.Net["RF/DragonHunter"]:InvokeServer({ Context = "Check" })
--       -> { Text = "Defeat 3 Hydra Enforcers" / "Destroy 10 ..." }, or no Text
--   workspace.EmberTemplate (its Part)        an ember lying there
--   notification "Head back to the Dojo to complete more tasks."   done
-- THE QUEST is asked for from wherever you are (user: "remotely ... no
-- problem"). No quest that way, or one taken that way never finishes (more
-- kills than it asks, no "Head back"), = to the Dragon Hunter from then on.
-- THE TREES (user, 2026-10-04): the medium trees on the ground break, NOT
-- the two giant ones, and the bamboo maybe not. The hubs break the bamboo
-- ("Tree" / Group / "Meshes/bambootree"), so: every tree-like model on the
-- island, the giants left out by height (EmberTreeMax), bamboo LAST, and a
-- tree that stands through 8 casts is left alone for 5 min. Which key breaks
-- trees is learned (as the vents'). Every candidate is written to
-- workspace/bff_ember_trees.txt the first time - to pin the real kind.
do
    local function build()
        local M: { [string]: any } = {
            note = "off", quest = nil, kind = nil, mob = nil, need = nil,
            have = nil, haveAt = 0, progress = 0, back = false,
            mustVisit = false, visits = 0, checkAt = 0,
            tally = { quests = 0, embers = 0, trees = 0 },
            learn = {},          -- which key breaks trees: key -> { casts, closed }
            skip = setmetatable({}, { __mode = "k" }),        -- embers given up on
            treeSkip = setmetatable({}, { __mode = "k" }),    -- tree model -> until when
            treeTries = setmetatable({}, { __mode = "k" }),
            probed = false,
        }
        P.ember = M
        local HUNTER_AT = Vector3.new(5864, 1209, 810)    -- by the Dragon Hunter (redz-style hub)
        local CAMPS = {
            ["Hydra Enforcer"]     = Vector3.new(4620, 1002, 399),
            ["Venomous Assailant"] = Vector3.new(4697, 1100, 946),
        }

        -- ---------- pure (tools/ember_test.py) ----------
        -- What a Check reply asks for: kind ("defeat" | "trees" | "unknown"),
        -- the enemy, how many. nil = no quest.
        local function parseQuest(text)
            if type(text) ~= "string" or text == "" then return nil end
            local low = string.lower(text)
            local n = tonumber(string.match(text, "%d+"))
            if string.find(low, "venom", 1, true) then return "defeat", "Venomous Assailant", n or 3 end
            if string.find(low, "enforcer", 1, true) or (string.find(low, "hydra", 1, true)
                and not string.find(low, "tree", 1, true)) then
                return "defeat", "Hydra Enforcer", n or 3
            end
            if string.find(low, "tree", 1, true) or string.find(low, "destroy", 1, true) then
                return "trees", nil, n or 10
            end
            return "unknown", nil, n
        end

        -- A quest taken from afar that never finishes: more done than it asks
        -- (+3 spare) and no "Head back" = it was not really taken.
        local function remoteFailed(progress, need)
            return need ~= nil and progress >= need + 3
        end

        -- Trees in the order to break them: not too tall (the giants never
        -- break), bamboo last (user), a kind that broke one first, then nearest.
        -- t = { height, bamboo, kind, dist }; kinds = kind -> { tries, broke }.
        local function treeOrder(list, maxH, kinds)
            local out = {}
            for _, t in ipairs(list) do
                if t.height <= maxH then
                    local k = kinds[t.kind]
                    if not (k and k.tries >= 3 and k.broke == 0) then table.insert(out, t) end
                end
            end
            local function rank(t)
                local k = kinds[t.kind]
                if k and k.broke > 0 then return 0 end
                return t.bamboo and 2 or 1
            end
            table.sort(out, function(a, b)
                local ra, rb = rank(a), rank(b)
                if ra ~= rb then return ra < rb end
                return a.dist < b.dist
            end)
            return out
        end
        M.kinds = {}

        -- ---------- the game ----------
        local function hunterRF() return netRemote("RF", "DragonHunter") end
        local function check()
            local rf = hunterRF()
            if not rf then return nil end
            local ok, res = pcall(function() return rf:InvokeServer({ Context = "Check" }) end)
            if ok and type(res) == "table" and type(res.Text) == "string" and res.Text ~= "" then return res.Text end
            return nil
        end
        local function request()
            local rf = hunterRF()
            if rf then pcall(function() return rf:InvokeServer({ Context = "RequestQuest" }) end) end
        end

        local function hunterAt()
            -- Not ipairs: it stops at the first nil (no workspace.NPCs).
            local folders = { workspace:FindFirstChild("NPCs"), RS:FindFirstChild("NPCs") }
            for i = 1, 2 do
                local f = folders[i]
                local m = f and f:FindFirstChild("Dragon Hunter")
                if m then
                    local ok, p = pcall(function() return m:GetPivot().Position end)
                    if ok and p then return p end
                end
            end
            return HUNTER_AT
        end

        local function notify(text)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Fast Farm", Text = text, Duration = 20,
                })
            end)
        end

        -- The game's notification: this quest is done. It stays on screen a
        -- while, so not believed in the first 12 s of a quest just taken.
        local function headBack()
            if os.clock() - (M.takenAt or -100) < 12 then return false end
            local ok, hit = pcall(function()
                local n = player.PlayerGui:FindFirstChild("Notifications")
                for _, d in ipairs(n and n:GetDescendants() or {}) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton"))
                        and string.find(d.Text, "Head back to the Dojo", 1, true) then
                        return true
                    end
                end
                return false
            end)
            return ok and hit
        end

        local function emberCount()
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if not (ok and type(inv) == "table") then return nil end
            local n = 0
            for _, it in pairs(inv) do
                if type(it) == "table" and it.Name == "Blaze Ember" then n = tonumber(it.Count) or 0 end
            end
            M.have, M.haveAt = n, os.clock()
            return n
        end

        local function embersLying()
            local out = {}
            for _, d in ipairs(workspace:GetChildren()) do
                if d.Name == "EmberTemplate" and not M.skip[d] then
                    local p = d:FindFirstChild("Part")
                    if p and p:IsA("BasePart") and p.Position.Y > 0 then
                        table.insert(out, { model = d, part = p })
                    end
                end
            end
            return out
        end
        P.embersLying = embersLying

        -- Onto it and stay on it (it drifts) till it goes; 8 s, else left.
        local function grabEmber(em, myEpoch)
            releasePile()
            setState("EMBER")
            M.note = "a Blaze Ember - going through it"
            say(M.note)
            local _, r = parts()
            if r and (r.Position - em.part.Position).Magnitude > 150 then
                flyTo(em.part.Position)
                if stale(myEpoch) then return end
            end
            local t0 = os.clock()
            while em.model.Parent and em.part.Parent and os.clock() - t0 < 8 and not stale(myEpoch) do
                lockAt(em.part.Position)
                task.wait(0.05)
            end
            if stale(myEpoch) then return end
            if em.model.Parent and em.part.Parent then
                M.skip[em.model] = true
                M.note = "an ember would not be taken in 8 s - left"
            else
                M.tally.embers += 1
                M.note = string.format("Blaze Ember taken  ·  %d this session", M.tally.embers)
                print("[BFF] ember: " .. M.note)
            end
            say(M.note)
        end

        -- ---------- the trees ----------
        local function mainPart(m)
            local best, bv = nil, -1
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA("BasePart") then
                    local v = d.Size.X * d.Size.Y * d.Size.Z
                    if v > bv then best, bv = d, v end
                end
            end
            return best
        end
        -- Every tree-like model on Hydra Island (the outermost one of a nest).
        local function treesHere()
            local map = workspace:FindFirstChild("Map")
            local isle = map and map:FindFirstChild("Waterfall")
            if not isle then return {} end
            local _, r = parts()
            local from = r and r.Position or hunterAt()
            local out = {}
            for _, m in ipairs(isle:GetDescendants()) do
                if m:IsA("Model") and string.find(string.lower(m.Name), "tree", 1, true) then
                    local outer = m.Parent
                    local nested = false
                    while outer and outer ~= isle do
                        if outer:IsA("Model") and string.find(string.lower(outer.Name), "tree", 1, true) then
                            nested = true
                            break
                        end
                        outer = outer.Parent
                    end
                    local part = (not nested) and mainPart(m) or nil
                    if part and part.Anchored and os.clock() >= (M.treeSkip[m] or 0) then
                        local okS, size = pcall(function() return m:GetExtentsSize() end)
                        local h = okS and size.Y or part.Size.Y
                        local bamboo = false
                        for _, d in ipairs(m:GetDescendants()) do
                            if string.find(string.lower(d.Name), "bamboo", 1, true) then bamboo = true break end
                        end
                        local kind = m.Name .. "/" .. part.Name
                        table.insert(out, { model = m, part = part, height = h, bamboo = bamboo,
                            kind = kind, dist = (part.Position - from).Magnitude, at = part.Position })
                    end
                end
            end
            return out
        end
        P.treesHere = treesHere

        local function probeTrees(list)
            if M.probed then return end
            M.probed = true
            local lines = { "[BFF] ember hunt - tree-like models on Hydra Island (" .. #list .. ")",
                "name / main part | height | bamboo | position" }
            for _, t in ipairs(list) do
                table.insert(lines, string.format("%s | %.0f | %s | %.0f, %.0f, %.0f", t.kind, t.height,
                    tostring(t.bamboo), t.at.X, t.at.Y, t.at.Z))
            end
            local text = table.concat(lines, "\n")
            if writefile then pcall(writefile, "bff_ember_trees.txt", text) end
            print(string.format("[BFF] ember: %d tree-like models on the island - list in workspace/bff_ember_trees.txt", #list))
        end

        -- One cast at the first tree in order. true = it broke.
        local function breakTree(myEpoch)
            local all = treesHere()
            probeTrees(all)
            local list = treeOrder(all, CFG.EmberTreeMax or 120, M.kinds)
            local t = list[1]
            if not t then
                M.note = "no tree to break here (all down, too tall, or given up) - waiting"
                say(M.note)
                task.wait(1)
                return false
            end
            local _, r = parts()
            if not r then return false end
            local out = Vector3.new(r.Position.X - t.at.X, 0, r.Position.Z - t.at.Z)
            if out.Magnitude < 1 then out = Vector3.new(1, 0, 0) end
            local stand = t.at + out.Unit * (CFG.VentDistance or 12) + Vector3.new(0, 6, 0)
            if (r.Position - stand).Magnitude > 4 then
                releasePile()
                setState("FLY")
                flyTo(stand, { face = t.at })
                if stale(myEpoch) then return false end
            end
            lockAt(stand, t.at)
            setState("TREE")
            M.note = string.format("breaking trees  ·  %d / %s  ·  %s", M.progress, tostring(M.need or "?"), t.kind)
            say(M.note)
            local pos0 = t.part.Position
            local v = {
                pos = t.at, part = t.part, model = t.model, learn = M.learn,
                alive = function()
                    local p = t.part
                    return t.model.Parent ~= nil and p.Parent ~= nil and p.Anchored
                        and p.Transparency < 1 and (p.Position - pos0).Magnitude < 3
                end,
            }
            local fired, broke = (P :: any).sea.castAt(v)
            if not fired then
                M.note = "every key cooling - waiting (no plain M1 on a tree)"
                return false
            end
            local k = M.kinds[t.kind] or { tries = 0, broke = 0 }
            M.kinds[t.kind] = k
            if broke then
                k.broke += 1
                M.progress += 1
                M.tally.trees += 1
                M.treeTries[t.model] = nil
                print(string.format("[BFF] ember: tree broken (%s)  ·  %d / %s", t.kind, M.progress, tostring(M.need or "?")))
                return true
            end
            local n = (M.treeTries[t.model] or 0) + 1
            M.treeTries[t.model] = n
            if n >= 8 then
                k.tries += 1
                M.treeTries[t.model] = nil
                M.treeSkip[t.model] = os.clock() + 300
                print("[BFF] ember: a tree stood through 8 casts, left 5 min (" .. t.kind .. ")")
            end
            return false
        end

        -- ---------- the quest ----------
        local function takeQuest(text, how)
            local kind, mob, need = parseQuest(text)
            if text ~= M.quest or how then
                M.progress = 0
                if how then M.tally.quests += 1 end
            end
            M.quest, M.kind, M.mob, M.need = text, kind, mob, need
            M.back = false
            M.takenAt = os.clock()
            if how then
                M.how = how
                print(string.format("[BFF] ember: quest (%s): %s", how, text))
            end
        end

        -- The quest to do now, or nil (M.note says why).
        local function quest(myEpoch)
            local now = os.clock()
            if M.quest and not M.back and now - M.checkAt < 15 then return M.quest end
            M.checkAt = now
            local text = check()
            if text and not M.back then
                if text ~= M.quest then takeQuest(text, nil) end
                return text
            end
            -- None, or the last one is done: a new one.
            if not M.mustVisit then
                request()
                task.wait(0.5)
                text = check()
                if text then takeQuest(text, "asked from here") return text end
            end
            local at = hunterAt()
            local _, r = parts()
            if r and (r.Position - at).Magnitude > 8 then
                releasePile()
                setState("FLY")
                M.note = "to the Dragon Hunter (Dragon Dojo) for a quest"
                say(M.note)
                flyTo(at + Vector3.new(0, 3, 0))
                if stale(myEpoch) then return nil end
            end
            lockAt(at + Vector3.new(0, 3, 0))
            request()
            task.wait(0.5)
            text = check()
            if text then
                M.visits = 0
                takeQuest(text, "at the Dragon Hunter")
                return text
            end
            M.visits += 1
            M.note = "the Dragon Hunter gave no quest (" .. M.visits .. ")"
            say(M.note)
            task.wait(2)
            return nil
        end

        local function fightBreak()
            -- Borrowed (the Volcanic Magnet's embers): while the Prehistoric hunt is on.
            local mine = (CFG.Hunt and CFG.HuntKind == "ember")
                or (M.borrowed and CFG.Hunt and CFG.HuntKind == "prehistoric")
            return not mine or #embersLying() > 0 or headBack()
        end

        -- true = busy here (the director's contract; this hunt never hops).
        -- borrowed = run for another job (the Volcanic Magnet): what would stop
        -- the hunt is written to M.blocked instead, and no stop-at count.
        function M.step(myEpoch, borrowed)
            M.borrowed, M.blocked = borrowed and true or false, nil
            local sea = mySea()
            if sea and sea ~= 3 then
                M.note = "Blaze Embers come only from the Third Sea - hunt stopped"
                say(M.note)
                if borrowed then M.blocked = "not the Third Sea" return false end
                P.stop("Blaze Embers: not the Third Sea")
                return true
            end
            local now = os.clock()
            if now - (M.haveAt or 0) > 20 then pcall(emberCount) end
            local stopAt = CFG.EmberStopAt or 99
            if not borrowed and M.have and M.have >= stopAt then
                M.note = string.format("you have %d Blaze Embers (stop at %d) - hunt done", M.have, stopAt)
                say(M.note)
                notify("Blaze Embers: " .. M.have)
                P.stop("Blaze Embers: enough")
                return true
            end
            -- 1. An ember lying there: through it.
            local em = embersLying()[1]
            if em then
                grabEmber(em, myEpoch)
                return true
            end
            -- 2. Done?
            if headBack() and M.quest and not M.back then
                M.back = true
                if M.how == "asked from here" then M.remoteOk = true end
                print("[BFF] ember: quest done - " .. tostring(M.quest))
            end
            if not M.back and M.how == "asked from here" and not M.remoteOk
                and remoteFailed(M.progress, M.need) then
                M.mustVisit, M.back = true, true
                print("[BFF] ember: a quest asked for from afar never finished - to the Dragon Hunter from now on")
            end
            -- 3. The quest.
            local text = quest(myEpoch)
            if stale(myEpoch) then return true end
            if not text then
                if M.visits >= 3 then
                    M.note = "the Dragon Hunter gives no quest - he needs Dragon Talon at 500 mastery "
                        .. "and the Dojo Trainer's Yellow Belt - hunt stopped"
                    say(M.note)
                    if borrowed then
                        M.blocked = "the Dragon Hunter gives no quest (Dragon Talon 500 + Yellow Belt?)"
                        return false
                    end
                    notify("Blaze Embers: no quest (Dragon Talon 500 + Yellow Belt?)")
                    P.stop("Blaze Embers: no quest")
                end
                return true
            end
            if M.kind == "defeat" then
                local mob = M.mob
                if not nearestLoaded(mob) then
                    local dest = campOf(mob, CAMPS[mob])
                    if not dest then
                        M.note = "cannot find where " .. mob .. " lives"
                        say(M.note)
                        task.wait(1)
                        return true
                    end
                    releasePile()
                    setState("FLY")
                    M.note = string.format("to the %ss  ·  %d / %s", mob, M.progress, tostring(M.need))
                    say(M.note)
                    flyTo(dest + Vector3.new(0, CFG.HeightSafe or 20, 0), { stream = mob })
                    task.wait(0.5)
                    return true
                end
                M.note = string.format("defeating %ss  ·  %d / %s", mob, M.progress, tostring(M.need))
                activeName = "Blaze Embers"
                local k0 = stats.kills
                fight({ name = mob, breakIf = fightBreak }, { [mob] = true })
                M.progress += math.max(0, stats.kills - k0)
                return true
            end
            if M.kind == "trees" then
                breakTree(myEpoch)
                return true
            end
            M.note = "a quest this script does not know: " .. tostring(text) .. " - abandon it at the Dragon Hunter"
            say(M.note)
            task.wait(2)
            return true
        end

        M.hunterAt = hunterAt
        M._t = { parseQuest = parseQuest, remoteFailed = remoteFailed, treeOrder = treeOrder }
    end
    build()
end

-- =========================================================
-- VOLCANIC MAGNET
-- =========================================================
-- Before the Prehistoric hunt sails (user, 2026-10-06: with the magnet the
-- island comes far more often - the wiki: "drastically increases the spawn
-- chances"; it is CONSUMED when the island spawns, so every trip wants a new
-- one; you hold at most 1). In your inventory = sail. Not: craft it - 15
-- Blaze Ember + 10 Scrap Metal at the Dragon Hunter,
-- CommF_("CraftItem", "Craft", "Volcanic Magnet") (two hubs; one calls it
-- from anywhere, one at the NPC: from here first, then at him). Short of
-- either: Scrap Metal from Forest Pirates (else Pirate Millionaires - the
-- wiki's Third Sea droppers, the hubs' picks), Blaze Embers by the Ember
-- hunt's own quests. Anything that cannot be done (no Ember quests, the
-- craft refused 3 times, the inventory unreadable) = sail without it, said.
do
    local function build()
        local G: { [string]: any } = { note = "-", crafts = 0, tries = 0, gaveUp = nil, inv = nil, invAt = 0 }
        P.magnet = G
        local SCRAP_MOBS = { "Forest Pirate", "Pirate Millionaire" }
        local SCRAP_AT = {
            ["Forest Pirate"]      = Vector3.new(-13206, 425, -7964),
            ["Pirate Millionaire"] = Vector3.new(81, 43, 5724),
        }
        local NEED_EMBER, NEED_SCRAP = 15, 10

        -- Pure (tools/vmagnet_test.py): what to do with these counts.
        -- "sail" (have one) | "craft" | "scrap" | "embers".
        local function plan(c)
            if (c.magnet or 0) >= 1 then return "sail" end
            if (c.ember or 0) >= NEED_EMBER and (c.scrap or 0) >= NEED_SCRAP then return "craft" end
            if (c.scrap or 0) < NEED_SCRAP then return "scrap" end
            return "embers"
        end

        -- { magnet, ember, scrap } off the game's inventory, 3 s cache; nil = unreadable.
        local function counts(fresh)
            if not fresh and G.inv and os.clock() - G.invAt < 3 then return G.inv end
            -- The game's item list first (P.sea.have): getInventory answered
            -- nothing on the user's client before every sail (2026-10-06,
            -- "inventory not readable"). getInventory below: the fallback.
            local sea = (P :: any).sea
            local h = sea and sea.have and sea.have({ "Volcanic Magnet", "Blaze Ember", "Scrap Metal" }, true)
            if h then
                local c = { magnet = h["Volcanic Magnet"] or 0, ember = h["Blaze Ember"] or 0, scrap = h["Scrap Metal"] or 0 }
                G.inv, G.invAt = c, os.clock()
                return c
            end
            local cf = commF()
            local ok, inv = pcall(function() return cf and cf:InvokeServer("getInventory") end)
            if not (ok and type(inv) == "table") then return nil end
            local c = { magnet = 0, ember = 0, scrap = 0 }
            for _, it in pairs(inv) do
                if type(it) == "table" then
                    local n = tonumber(it.Count) or 1
                    if it.Name == "Volcanic Magnet" then c.magnet = n
                    elseif it.Name == "Blaze Ember" then c.ember = n
                    elseif it.Name == "Scrap Metal" then c.scrap = n end
                end
            end
            G.inv, G.invAt = c, os.clock()
            return c
        end

        local function huntOn() return CFG.Hunt and CFG.HuntKind == "prehistoric" end

        local function craft(myEpoch)
            local cf = commF()
            local function try()
                pcall(function() return cf and cf:InvokeServer("CraftItem", "Craft", "Volcanic Magnet") end)
                task.wait(1)
                local c = counts(true)
                return c and c.magnet >= 1
            end
            G.note = "crafting the Volcanic Magnet"
            say(G.note)
            if try() then
                G.crafts += 1
                G.tries = 0
                print("[BFF] magnet: Volcanic Magnet crafted (from here)")
                return
            end
            -- At the Dragon Hunter.
            local at = ((P :: any).ember and (P :: any).ember.hunterAt and (P :: any).ember.hunterAt())
                or Vector3.new(5864, 1209, 810)
            releasePile()
            setState("FLY")
            G.note = "to the Dragon Hunter to craft the Volcanic Magnet"
            say(G.note)
            flyTo(at + Vector3.new(0, 3, 0))
            if stale(myEpoch) then return end
            lockAt(at + Vector3.new(0, 3, 0))
            if try() then
                G.crafts += 1
                G.tries = 0
                print("[BFF] magnet: Volcanic Magnet crafted (at the Dragon Hunter)")
                return
            end
            G.tries += 1
            G.note = "the craft did not take (" .. G.tries .. ")"
            if G.tries >= 3 then
                G.gaveUp = "the craft was refused 3 times"
                print("[BFF] magnet: " .. G.gaveUp .. " - sailing without it")
            end
        end

        local function farmScrap(c, myEpoch)
            local mob = nil
            for _, n in ipairs(SCRAP_MOBS) do
                if nearestLoaded(n) then mob = n break end
            end
            G.note = string.format("Scrap Metal for the magnet: %d / %d", c.scrap, NEED_SCRAP)
            if not mob then
                mob = SCRAP_MOBS[1]
                local dest = campOf(mob, SCRAP_AT[mob])
                releasePile()
                setState("FLY")
                say(G.note .. "  ·  to the " .. mob .. "s")
                if dest then flyTo(dest + Vector3.new(0, CFG.HeightSafe or 20, 0), { stream = mob }) end
                task.wait(0.3)
                return
            end
            say(G.note)
            activeName = "Scrap Metal"
            local t0 = os.clock()
            fight({ name = mob, breakIf = function()
                -- Every 10 s back here to count again.
                return not huntOn() or os.clock() - t0 > 10
            end }, { [mob] = true })
        end

        -- true = busy getting the magnet; false = sail (have it, or cannot).
        function G.step(myEpoch)
            if not CFG.SeaMagnet then return false end
            if G.gaveUp then
                G.note = "sailing without the Volcanic Magnet - " .. G.gaveUp
                return false
            end
            local c = counts(false)
            if not c then
                G.note = "inventory not readable - sailing without the Volcanic Magnet"
                return false
            end
            local what = plan(c)
            if what == "sail" then
                G.note = "Volcanic Magnet in your inventory"
                return false
            end
            setState("MAGNET")
            if what == "craft" then
                craft(myEpoch)
                return not G.gaveUp
            end
            if what == "scrap" then
                farmScrap(c, myEpoch)
                return true
            end
            local M = (P :: any).ember
            if not (M and M.step) then
                G.gaveUp = "no Blaze Ember hunt"
                return false
            end
            G.note = string.format("Blaze Embers for the magnet: %d / %d  ·  %s", c.ember, NEED_EMBER, tostring(M.note))
            say(G.note)
            M.step(myEpoch, true)
            if M.blocked then
                G.gaveUp = "Blaze Embers: " .. tostring(M.blocked)
                print("[BFF] magnet: " .. G.gaveUp .. " - sailing without it")
                return false
            end
            G.inv = nil            -- an ember may have come: count again
            return true
        end

        G._t = { plan = plan }
    end
    build()
end

-- =========================================================
-- LEARNED KEYS, KEPT
-- =========================================================
-- Which key closes vents (P.sea.learn) and which breaks trees (P.ember.learn)
-- are kept in workspace/bff_learn.json across sessions: "Dragon Talon C
-- never closed one" is learned once, not every event. Read at load, written
-- every 15 s when a cast was added.
do
    local function build()
        local FILE = "bff_learn.json"
        local HS = game:GetService("HttpService")
        local function total(t)
            local n = 0
            for _, L in pairs(t or {}) do n += (tonumber(L.casts) or 0) end
            return n
        end
        -- Pure: a saved table back into { key = { casts, closed } }, bad rows dropped.
        local function clean(t)
            local out = {}
            if type(t) ~= "table" then return out end
            for k, L in pairs(t) do
                if type(k) == "string" and type(L) == "table" then
                    local c, d = tonumber(L.casts), tonumber(L.closed)
                    if c and d and c >= 0 and d >= 0 and d <= c then out[k] = { casts = c, closed = d } end
                end
            end
            return out
        end
        P.learnClean = clean
        if readfile and isfile then
            local ok, data = pcall(function()
                if not isfile(FILE) then return nil end
                return HS:JSONDecode(readfile(FILE))
            end)
            if ok and type(data) == "table" then
                local S, M = (P :: any).sea, (P :: any).ember
                if S then
                    for k, L in pairs(clean(data.vents)) do S.learn[k] = S.learn[k] or L end
                end
                if M then
                    for k, L in pairs(clean(data.trees)) do M.learn[k] = M.learn[k] or L end
                end
            end
        end
        if not writefile then return end
        local saved = -1
        task.spawn(function()
            while _G.BFF == nil or _G.BFF == P do
                task.wait(15)
                local S, M = (P :: any).sea, (P :: any).ember
                local n = total(S and S.learn) + total(M and M.learn)
                if n ~= saved then
                    saved = n
                    pcall(function()
                        writefile(FILE, HS:JSONEncode({ vents = S and S.learn or {}, trees = M and M.learn or {} }))
                    end)
                end
            end
        end)
    end
    build()
end

-- =========================================================
-- MAIN LOOP
-- =========================================================
local function step()
    local _, root = parts()
    if not root then
        say("waiting for character")
        task.wait(0.5)
        return
    end
    -- HANDS OFF (the Mirage: your turn at the moon): nothing but the hunt's
    -- own watch runs - no escape, no haki keys, no other island.
    local off = P.handsOff
    -- At the wheel the boat outruns what hurts you; flying up would leave it.
    if not off and healthPct() < (CFG.EscapeBelow or 0.35) and not (P.sea and P.sea.driving) then
        escape()
        return
    end
    if not off then pcall(keepHaki) end

    -- THE LEVIATHAN: its own switch - on = only the Leviathan (its heart, or
    -- nothing of it up yet = the character is yours; nothing else runs).
    if P.seaev and P.seaev.leviStep() then return end
    -- The volcano event goes before every mode while its island is up.
    if not off and P.sea and P.sea.volcanoStep() then return end
    if CFG.Hunt then huntStep() return end
    if CFG.RandomMode then randomStep() return end
    if CFG.RaidMode then raidStep() return end

    local list = circuit()
    if #list == 0 then
        say(P.circuitNote)
        task.wait(1.5)
        return
    end
    if circuitIdx > #list then circuitIdx = 1 end
    local names = {}
    for _, t in ipairs(list) do names[t.name] = true end

    -- A boss on the circuit that is up goes first.
    if CFG.BossFirst then
        for i, t in ipairs(list) do
            if BOSS[t.name] and bossUp(t.name) then circuitIdx = i break end
        end
    end
    local cur = list[circuitIdx]
    activeName = cur.name

    -- A BOSS is one enemy on a long respawn. While it is not up: the rest of
    -- the circuit, or -- when nothing else on the circuit can be fought (it
    -- is alone, or every other one is a boss that is not up either) -- wait
    -- over its spawn, however long.
    if not BOSS[cur.name] then P.bossWaitSince = nil end
    if BOSS[cur.name] then
        local other = false
        for i, t in ipairs(list) do
            if i ~= circuitIdx and (not BOSS[t.name] or bossUp(t.name)) then other = true break end
        end
        if bossUp(cur.name) then
            P.bossWaitSince = nil
        elseif other then
            say(cur.name .. " has not spawned - next on the circuit")
            advance(list)
            releasePile()
            task.wait(0.2)
            return
        else
            local spot = campOf(cur.name, cur.spot)
            local _, r = parts()
            local over = spot and (spot + Vector3.new(0, CFG.HeightSafe or 20, 0))
            if r and over and (r.Position - over).Magnitude > 150 then
                releasePile()
                setState("FLY")
                say("flying to where " .. cur.name .. " spawns")
                flyTo(over, { stream = cur.name })
            end
            setState("WAIT")
            P.bossWaitSince = P.bossWaitSince or os.clock()
            say(string.format("waiting for %s to spawn  %ds", cur.name,
                math.floor(os.clock() - P.bossWaitSince)))
            task.wait(0.5)
            return
        end
    end

    -- To where the species IS, unless already fighting it. A loaded one is the
    -- truth (its own spawn spot); otherwise the game's spawn points; the
    -- table only if the game says nothing.
    do
        local _, r = parts()
        local e = nearestLoaded(cur.name)
        local dest, src
        if e then
            dest, src = homeOf(e), "loaded"
        else
            dest, src = campOf(cur.name, cur.spot)
        end
        local atPile = pileCentre ~= nil and pileFor == cur.name
        if r and dest and not atPile
            and (r.Position - (dest + Vector3.new(0, CFG.HeightSafe or 20, 0))).Magnitude > 150 then
            releasePile()
            setState("FLY")
            say(string.format("flying to %s  (%s)", cur.name, src))
            flyTo(dest + Vector3.new(0, CFG.HeightSafe or 20, 0), { stream = cur.name })
        elseif not dest then
            say("cannot find where " .. cur.name .. " lives - go near it once")
        end
    end

    local why = fight(cur, names)
    if why == "empty" and BOSS[cur.name] then
        -- Down (someone else's kill, or it left): the next step sees it is not
        -- up and does the rest of the circuit, or waits for it. Still listed
        -- as parked while you stand at it for 10 s: that entry is not believed
        -- for a minute, so the farm cannot hover over nothing for ever.
        local at, where = bossWhere(cur.name)
        local _, r = parts()
        if where == "parked" and r and (at - r.Position).Magnitude < 300 then
            local miss = P.bossMiss[cur.name]
            if not miss then
                P.bossMiss[cur.name] = os.clock()
            elseif os.clock() - miss > 10 then
                P.bossMiss[cur.name] = nil
                P.bossStale[cur.name] = os.clock() + 60
            end
            say(cur.name .. " is listed as up but is not here yet")
        else
            P.bossMiss[cur.name] = nil
            say(cur.name .. " is down")
        end
        task.wait(0.5)
    elseif why == "empty" then
        -- The next camp while this one respawns; alone on the circuit: wait.
        if #list > 1 then
            advance(list)
            releasePile()
        else
            waitRespawn(cur, names)
        end
    end
    -- "hurt" and "sweep": the next step decides.
end

local mainGen = 0

local function mainLoop()
    mainGen += 1
    local gen = mainGen
    while P.running and gen == mainGen do
        local ok, err = pcall(step)
        if not ok then
            log("step error: " .. tostring(err))
            say("recovered from an error: " .. string.sub(tostring(err), 1, 90))
            attacking = false
            task.wait(0.6)
        end
        task.wait(0.03)
    end
end

-- Cooldown bars, the setup measurement, new weapons, housekeeping.
local function sideLoop()
    local gen = mainGen
    local lastSlow = 0
    while P.running and gen == mainGen do
        pcall(cdTick)
        local now = os.clock()
        if now - lastSlow > 1 then
            lastSlow = now
            if meas and setupKey() ~= meas.key then rollMeas() end
            if CFG.M1Method ~= lastProbeMethod then
                lastProbeMethod = CFG.M1Method
                P.reprobe()
            end
            pcall(syncWeapons)
            pcall((P :: any).masteryTick)
            if math.random() < 0.05 then
                for m, t in pairs(countedDead) do
                    if now - t > 120 then countedDead[m] = nil end
                end
            end
        end
        task.wait(0.1)
    end
end

-- =========================================================
-- SEA EVENTS
-- =========================================================
-- THE SEA EVENTS HUNT (HuntKind "seaevents", Third Sea; user, 2026-10-09).
-- The Prehistoric hunt's boat (bought at Tiki's back dealer, you at the
-- wheel, driven by its pivot) patrols a slow circle at Sea Danger
-- SeaEvDanger: sea events come to a boat that is near, moving or not (the
-- wiki). What comes:
--   FOUGHT, each its own switch   Sea Beast, Rumbling Waters (three beasts),
--                                 Terrorshark, Piranha (Shark off by default)
--   FLED, always                  ship raids: the pirate brigades, the Fish
--                                 Boat and its crew, the haunted ships (user:
--                                 slow, and they break the boat)
--   THE LEVIATHAN                 its own switch: on = only the Leviathan
--                                 (LeviFight; user, 2026-10-09 - THE LEVIATHAN, below)
-- A fight: off the seat, the boat held BoatLift up (out of the waves), one
-- target at a time - the nearest, kept until it dies.
--   SEA BEAST   workspace.SeaBeasts, no Humanoid: its HP is a Health value,
--               the HealthBBG text or an attribute (the hubs read all three;
--               the first beast writes which to workspace/bff_beast_probe.txt).
--               Under the water = unhittable: wait over where it went, cast
--               nothing. Up: hover BeastHeight over the sea, every ready key
--               of every weapon you carry (SeaEvKeys) and the M1 between,
--               aimed AT it - the silent aim follows its body every frame.
--               HOW A MOVE LANDS (the decompiled client v4623, 2026-10-09):
--               a skill (and a fruit's M1) sends ReplicatedStorage.Mouse's
--               Hit - the game's own table, answered with the target while
--               casting (SILENT AIM); a gun reads the PlayerMouse (the hook
--               there); a move casting its own camera ray finds the root,
--               made 60 a side on your client (every public sea-event
--               script does), the camera 90 off so it is never inside it.
--               Transformed (a fruit's rig on you), the game refuses every
--               other weapon's key: only that fruit's moves are fired.
-- THE LOADOUT (user, 2026-10-09: points in fruit + melee - Kitsune, Dragon
-- Talon). Kitsune FORM first (V pressed for you, off the seat): its M1 tested
-- per class - Sea Beasts / Terrorshark-Piranha-Shark - credited by the
-- target's HP; it hurts them (2 hits) = form for that class; 20 s and 6 M1s
-- without = out of form, untransformed Kitsune + your fighting style (only
-- SeaEvWeapons' types). In form every fight is the HP-credited caster; out
-- of form a fish is the farm's own fight (Dragon Talon's remote-hit M1).
-- Re-tested every 5th target. The radio: auto / form always / never.
-- EVERY READY KEY, AT ONCE (user, 2026-10-09): pressed the moment the game
-- takes it (not Busy / stunned / another move Holding - its own gates), the
-- next one the frame this one's bar starts or the game goes busy with it (a
-- long move - Kitsune Z / X - starts its bar at its END), never into it; a refused press retried in 3 s;
-- V never on a transformation fruit, on for the rest; mastery-locked keys
-- skipped. THE WATER AS ROCK: every sea fight sets a floor (the sea's top + 4)
-- the lock never goes under, swimming off, a knockback / pull not adopted.
-- DODGING (a Terrorshark / Piranha / Shark): round it all the time, the
-- direction flipping, the aim held on it; up when it starts an attack (a new
-- animation that does not loop), charges at you or leaps.
--               Which key and whose M1 hurt it is LEARNED from its HP (the
--               vent caster, P.sea.ventCast, credited by HP); nothing lands
--               for 6 s = in close.
--   TERRORSHARK / PIRANHA / SHARK   Humanoid enemies: the farm's own fight,
--               where they swim, FishHeight over them, M1 AND every skill
--               whatever the Attack page says.
-- THE COUNT (user: the Spy's cooldown - 20 or more KILLED sea events after a
-- Frozen Dimension, the wiki). One event = one group: the same kind seen
-- within 20 s of each other (five piranhas = one event, the wiki; three
-- beasts = Rumbling Waters = one). Counted when every member is gone and at
-- least one was KILLED (its HP read 0, or gone at 10% or less) - under-counted
-- rather than over. Kept in workspace/bff_sea_events.json. The Spy is asked
-- (read only, CommF_ "InfoLeviathan" "1") at the start, after each count and
-- every 5 min: his word is the truth, the count a guide.
-- Never the next server. Only P.seaev leaves the block.
do
    local function build()
        local S = P.sea
        local SE: { [string]: any } = {
            note = "off", mode = "-", cur = nil, lockPart = nil, parkAt = nil, parkBoat = nil,
            members = {}, groups = {}, shift = 0, wrong = 0,
            count = { total = 0, kinds = {}, since = os.time(), log = {} },
            learn = {}, learnFish = {}, spy = nil, last = "-", fights = 0, flees = 0, seenNames = {},
        }
        P.seaev = SE
        local FILE, PROBE = "bff_sea_events.json", "bff_beast_probe.txt"
        local HS = game:GetService("HttpService")
        local UP = Vector3.new(0, 1, 0)
        -- Sea Danger 1-6: a public hub's points (BFX, 2026-09), checked against
        -- the user's compass (Danger 6 ~2,630 m = 26.3k studs from the Tiki
        -- dealer; zone 6 here is 26.5k).
        local ZONES = {
            Vector3.new(-22814, 0, 448), Vector3.new(-28500, 0, 1099), Vector3.new(-30724, 0, 1704),
            Vector3.new(-34336, 0, 2569), Vector3.new(-38460, 0, 4007), Vector3.new(-42865, 0, 5736),
        }
        local FISH = { Terrorshark = true, Piranha = true, Shark = true }
        local SHIP_WORDS = { "brigade", "fishboat", "fish boat", "fish crew", "ghost", "haunted" }
        local KEYS5 = { "Z", "X", "C", "V", "F" }
        local GROUP_GAP, DONE_WAIT = 20, 5     -- s: a group's members; quiet this long = over
        local RANGE, RADIUS, PATROL = 1500, 400, 60   -- studs: events near the boat; the circle; its speed

        -- ---------- the arithmetic (pure: tools/seaev_test.py) ----------
        local function flat(v) return Vector3.new(v.X, 0, v.Z) end

        -- "12,500/100,000" -> 12500, 100000.
        local function parseHP(t)
            if type(t) ~= "string" then return nil end
            local s = (string.gsub(t, "[,%s]", ""))
            local a, b = string.match(s, "([%d%.]+)/([%d%.]+)")
            return tonumber(a), tonumber(b)
        end

        -- What a name in workspace.Enemies is to this hunt.
        local function kindOf(name)
            if type(name) ~= "string" then return nil end
            if string.find(string.lower(name), "terrorshark", 1, true) then return "Terrorshark" end
            if string.find(name, "Piranha", 1, true) then return "Piranha" end
            local low = string.lower(name)
            for _, w in ipairs(SHIP_WORDS) do
                if string.find(low, w, 1, true) then return "ship" end
            end
            if name == "Shark" then return "Shark" end
            return nil
        end

        -- Three beasts or more = Rumbling Waters (the wiki: "composed of three").
        local function beastKind(size) return (size >= 3) and "Rumbling Waters" or "Sea Beast" end
        local function groupLabel(g) return (g.base == "beast") and beastKind(g.size) or g.base end

        -- A member joins the newest open group of its kind that saw one alive
        -- within GROUP_GAP s; else a new group.
        local function joinGroup(groups, base, now)
            for i = #groups, 1, -1 do
                local g = groups[i]
                if g.base == base and not g.closed and now - g.lastSeen <= GROUP_GAP then return g end
            end
            local g = { base = base, size = 0, killed = 0, lastSeen = now, closed = false }
            table.insert(groups, g)
            return g
        end

        -- A member no longer alive: "killed" (its HP read 0, or it went at 10%
        -- or less - a beast sinks the moment it dies, before the 0 is read)
        -- or "lost" (went with HP left, or HP never read); nil = alive.
        local function verdict(hpZero, gone, frac)
            if hpZero then return "killed" end
            if gone then return (frac ~= nil and frac <= 0.1) and "killed" or "lost" end
            return nil
        end

        -- Over when nothing of it has lived for DONE_WAIT s: "count" with a
        -- kill, else "lost"; nil = still on.
        local function groupOver(g, alive, now)
            if alive > 0 then
                g.lastSeen = now
                return nil
            end
            if now - g.lastSeen < DONE_WAIT then return nil end
            return (g.killed > 0) and "count" or "lost"
        end

        -- The circle: far off it = straight at its middle at `fast`; on it =
        -- round it at `slow`, pulled back onto its edge.
        local function patrolDir(pos, centre, radius, slow, fast)
            local d = flat(pos - centre)
            local r = d.Magnitude
            if r < 1 then return Vector3.new(0, 0, 1), slow end
            if r > radius * 2 then return flat(centre - pos).Unit, fast end
            local out = d.Unit
            local round = Vector3.new(-out.Z, 0, out.X)
            local pull = math.clamp((radius - r) / radius, -1, 1) * 1.5
            return (round + out * pull).Unit, slow
        end

        local function fleeDir(pos, threat)
            local d = flat(pos - threat)
            if d.Magnitude < 1 then return Vector3.new(1, 0, 0) end
            return d.Unit
        end

        -- The wheel with the nearest threat `d` studs off: "flee" inside
        -- fleeTo (fleeTo + 300 once fleeing, so it does not flicker); a ship
        -- still within twice that = "hold" (stopped, out of its way - the
        -- circle may lead back into it); else "patrol".
        local function wheelMode(d, kind, fleeing, fleeTo)
            if d == nil then return "patrol" end
            if d < fleeTo or (fleeing and d < fleeTo + 300) then return "flee" end
            if kind == "ship" and d < fleeTo * 2 then return "hold" end
            return "patrol"
        end

        -- The compass says another level twice running: the circle one step
        -- (1,500 studs) out from Tiki when too low, in when too high; 4 at most.
        local function nudge(shift, danger, want)
            if not danger then return shift end
            if danger < want then return math.min(shift + 1, 4) end
            if danger > want then return math.max(shift - 1, -4) end
            return shift
        end
        local function centreOf(want, shift)
            local z = ZONES[math.clamp(want, 1, #ZONES)]
            return z + flat(z - S.TIKI).Unit * (shift * 1500)
        end

        -- The Spy's answer (read as one public hub reads it, 2026).
        local function spyText(code)
            if code == 1 then return "on cooldown - \"I don't know anything yet\"" end
            if code == 2 or code == 3 or code == 4 then
                return "past the cooldown - takes fragments (stage " .. (code - 1) .. ")"
            end
            if code == 5 then return "\"the Leviathan is out there\"" end
            return "answered " .. tostring(code)
        end

        -- ---------- what the game shows ----------
        local function huntOn() return CFG.Hunt and CFG.HuntKind == "seaevents" end
        SE.huntOn = huntOn
        -- A sea fight may run: the sea events hunt, or the Leviathan switch with one up.
        local function fightAllowed()
            return P.running and (huntOn() or (CFG.LeviFight == true and SE.levi ~= nil
                and (SE.levi.active == true or SE.levi.holdUntil ~= nil)))
        end

        -- The sea plane's middle (the surfaced test's reference, the hubs')
        -- and the water's top (a boat's water line; else the plane's top as
        -- walk on water sets it: Size.Y 112).
        local function seaRef()
            local map = workspace:FindFirstChild("Map")
            local p = map and map:FindFirstChild("WaterBase-Plane")
            return (p and p:IsA("BasePart")) and p.Position.Y or nil
        end
        local function surfaceY()
            if S.drive and S.drive.waterY then return S.drive.waterY end
            local y = seaRef()
            return y and (y + 56) or 0
        end
        -- The sea's TOP as the slab stands now (walk on water keeps it at the
        -- surface, Size.Y 112): what a sea fight never goes under.
        local function seaTop()
            local map = workspace:FindFirstChild("Map")
            local p = map and map:FindFirstChild("WaterBase-Plane")
            if p and p:IsA("BasePart") then
                local ok, sz = pcall(function() return p.Size end)
                if ok and sz then return p.Position.Y + sz.Y / 2 end
                return p.Position.Y + 56
            end
            return surfaceY()
        end

        local function beastRoot(m)
            local r = m:FindFirstChild("HumanoidRootPart")
            if r and r:IsA("BasePart") then return r end
            if m:IsA("Model") and m.PrimaryPart then return m.PrimaryPart end
            return m:FindFirstChildWhichIsA("BasePart", true)
        end

        -- A beast's HP: its Health value, its HealthBBG text, its attribute.
        local function beastHP(m)
            local hv = m:FindFirstChild("Health")
            if hv and hv:IsA("ValueBase") then
                local mx = m:FindFirstChild("MaxHealth")
                local max = (mx and mx:IsA("ValueBase")) and tonumber(mx.Value) or tonumber(m:GetAttribute("MaxHealth"))
                return tonumber(hv.Value), max, "its Health value"
            end
            local bbg = m:FindFirstChild("HealthBBG", true)
            if bbg then
                for _, d in ipairs(bbg:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local a, b = parseHP(d.Text)
                        if a then return a, b, "its HealthBBG text" end
                    end
                end
            end
            local a = tonumber(m:GetAttribute("Health"))
            if a then return a, tonumber(m:GetAttribute("MaxHealth")), "its Health attribute" end
            -- The Leviathan's parts carry a Humanoid (the game's SyncLeviathan
            -- animates them): its Health, the last resort.
            local hum = m:FindFirstChildOfClass("Humanoid")
            if hum then return tonumber(hum.Health), tonumber(hum.MaxHealth), "its Humanoid" end
            return nil, nil, "not found"
        end
        local function hpOf(m)
            local ok, hp = pcall(beastHP, m)
            return ok and hp or nil
        end

        local function beasts()
            local f = workspace:FindFirstChild("SeaBeasts")
            local out = {}
            for _, m in ipairs(f and f:GetChildren() or {}) do
                -- "SeaBeast1".. only: the Leviathan's parts live here too.
                if string.find(string.lower(tostring(m.Name)), "seabeast", 1, true) then
                    local root = beastRoot(m)
                    local ok, hp, max, src = pcall(beastHP, m)
                    if root and ok then
                        table.insert(out, { model = m, root = root, hp = hp, max = max, src = src, kind = "beast" })
                    end
                end
            end
            return out
        end

        -- Where the hunt is: your boat (it stays at sea when you die), else you.
        local function home()
            local b = S.myBoat()
            if b and b.Parent then
                local ok, cf = pcall(function() return b:GetPivot() end)
                if ok and cf then return cf.Position end
            end
            local _, r = parts()
            return r and r.Position or nil
        end
        local function near(pos, a, b, dist)
            return (a ~= nil and flat(pos - a).Magnitude <= dist) or (b ~= nil and flat(pos - b).Magnitude <= dist)
        end

        -- ---------- the probe ----------
        local function probeAdd(text)
            SE.probeText = (SE.probeText and (SE.probeText .. "\n") or "") .. text
            if writefile then pcall(writefile, PROBE, SE.probeText) end
        end
        local function probeBeast(x)
            if SE.probed then return end
            SE.probed = true
            local m = x.model
            local out = { "[sea beast] " .. os.date("!%Y-%m-%d %H:%M:%S") .. "Z  " .. m:GetFullName() .. " (" .. m.ClassName .. ")" }
            local ok, a = pcall(function() return m:GetAttributes() end)
            local t = {}
            if ok and type(a) == "table" then
                for k, v in pairs(a) do table.insert(t, tostring(k) .. "=" .. tostring(v)) end
            end
            table.insert(out, "attributes: " .. table.concat(t, ", "))
            local n = 0
            for _, d in ipairs(m:GetDescendants()) do
                if not d:IsA("BasePart") and n < 80 then
                    n += 1
                    local v = ""
                    pcall(function()
                        if d:IsA("ValueBase") then v = " = " .. tostring(d.Value)
                        elseif d:IsA("TextLabel") then v = " text '" .. tostring(d.Text) .. "'"
                        elseif d:IsA("Animation") then v = " " .. tostring(d.AnimationId) end
                    end)
                    table.insert(out, "  " .. d:GetFullName() .. " (" .. d.ClassName .. ")" .. v)
                end
            end
            local ref = seaRef()
            table.insert(out, string.format("read: HP %s / %s from %s  ·  root %s at Y %.0f  ·  sea plane Y %s",
                tostring(x.hp), tostring(x.max), tostring(x.src), x.root.Name, x.root.Position.Y, tostring(ref)))
            probeAdd(table.concat(out, "\n"))
            print("[BFF] seaev: first Sea Beast - HP from " .. tostring(x.src) .. " (all of it: workspace/" .. PROBE .. ")")
        end
        -- A name near the boat this hunt does not know: said once.
        local function newName(n, where)
            if SE.seenNames[n] then return end
            SE.seenNames[n] = true
            print("[BFF] seaev: near the boat, unknown here: " .. n .. " (" .. where .. ") - left alone")
            probeAdd("[new name] " .. n .. "  in " .. where)
        end

        -- ---------- the count ----------
        local function save()
            if not writefile then return end
            pcall(function()
                writefile(FILE, HS:JSONEncode({
                    total = SE.count.total, kinds = SE.count.kinds, since = SE.count.since,
                    log = SE.count.log, learn = SE.learn, learnFish = SE.learnFish,
                }))
            end)
        end
        local function load()
            if not (readfile and isfile) then return end
            local ok, d = pcall(function()
                if not isfile(FILE) then return nil end
                return HS:JSONDecode(readfile(FILE))
            end)
            if not (ok and type(d) == "table") then return end
            SE.count.total = math.max(0, math.floor(tonumber(d.total) or 0))
            SE.count.since = tonumber(d.since) or SE.count.since
            for k, v in pairs(type(d.kinds) == "table" and d.kinds or {}) do
                if type(k) == "string" and tonumber(v) then SE.count.kinds[k] = math.floor(tonumber(v)) end
            end
            for _, s in ipairs(type(d.log) == "table" and d.log or {}) do
                if type(s) == "string" and #SE.count.log < 8 then table.insert(SE.count.log, s) end
            end
            if P.learnClean then SE.learn, SE.learnFish = P.learnClean(d.learn), P.learnClean(d.learnFish) end
        end
        load()

        function SE.reset()
            SE.count = { total = 0, kinds = {}, since = os.time(), log = {} }
            SE.goalHit = false
            save()
            SE.last = "count reset to 0"
            print("[BFF] seaev: the count is back to 0")
        end

        local spyAsk
        local function addCount(label)
            local c = SE.count
            c.total += 1
            c.kinds[label] = (c.kinds[label] or 0) + 1
            table.insert(c.log, 1, string.format("%s %s", os.date("%H:%M"), label))
            while #c.log > 8 do table.remove(c.log) end
            save()
            local goal = math.max(1, math.floor(tonumber(CFG.SeaEvGoal) or 20))
            SE.last = string.format("%s done - counted (%d of %d)", label, c.total, goal)
            print("[BFF] seaev: " .. SE.last)
            if c.total == goal then
                SE.goalHit = true
                S.notify(goal .. " sea events - the Spy should take fragments again")
            end
            task.spawn(function() pcall(spyAsk) end)
        end

        function spyAsk()
            if SE.spyBusy then return end
            SE.spyBusy, SE.spyAt = true, os.clock()
            local cf = commF()
            local ok, res = pcall(function() return cf and cf:InvokeServer("InfoLeviathan", "1") end)
            SE.spyBusy = false
            local code = ok and tonumber(res) or nil
            local before = SE.spy and SE.spy.code
            -- "Past the cooldown at N" stays until he is on cooldown again.
            local overAt = (code ~= 1) and SE.spy and SE.spy.overAt or nil
            SE.spy = { code = code, at = os.clock(), overAt = overAt,
                text = ok and spyText(code) or ("not answered (" .. tostring(res) .. ")") }
            if before == 1 and code ~= nil and code ~= 1 then
                SE.spy.overAt = SE.count.total
                print(string.format("[BFF] seaev: the Spy is past his cooldown - at %d counted sea events", SE.count.total))
                S.notify("The Spy takes fragments again")
            end
        end
        SE.spyAsk = spyAsk

        -- ---------- the groups, every step ----------
        local function remember(x, now)
            local m = SE.members[x.model]
            if not m then
                local g = joinGroup(SE.groups, x.kind, now)
                g.size += 1
                m = { group = g, kind = x.kind, hum = x.hum }
                SE.members[x.model] = m
                print(string.format("[BFF] seaev: %s up (%s, %d in it)", (x.kind == "beast") and "a Sea Beast" or x.kind,
                    groupLabel(g), g.size))
                if x.kind == "beast" then probeBeast(x) end
            end
            m.group.lastSeen = now
            if x.hp then m.hp = x.hp end
            if x.max then m.max = x.max end
            return m
        end

        -- Everything near: { fights, threats }. Each entry { model, root, kind,
        -- pos, hum?, fight }. Members judged, groups closed and counted.
        local function scan(now)
            local h = home()
            local _, r = parts()
            local me = r and r.Position or nil
            local live, fights, threats, seen = {}, {}, {}, {}
            local function consider(x)
                live[x.model] = x
                x.member = remember(x, now)
                table.insert(seen, x)
            end
            for _, x in ipairs(beasts()) do
                if (x.hp == nil or x.hp > 0) and near(x.root.Position, h, me, RANGE) then consider(x) end
            end
            for _, e in ipairs(liveEnemies(nil)) do
                local k = kindOf(e.name)
                if FISH[k] and near(e.root.Position, h, me, RANGE) then
                    if not (P.randomSkip[e.model] and now < P.randomSkip[e.model]) then
                        consider({ model = e.model, root = e.root, hum = e.hum, name = e.name, kind = k })
                    end
                end
            end
            -- Named once every member is in: the third beast makes the first
            -- two Rumbling Waters too.
            for _, x in ipairs(seen) do
                x.label = groupLabel(x.member.group)
                x.pos = x.root.Position
                x.fight = (CFG.SeaEvFight or {})[x.label] == true
                table.insert(x.fight and fights or threats, x)
            end
            -- Ship raids, any shape (a boat model, its crew): always fled -
            -- seen out to twice FleeTo (kept away from, not only run from).
            local shipRange = math.max(RANGE, (tonumber(CFG.FleeTo) or 1500) * 2 + 300)
            local ef = workspace:FindFirstChild("Enemies")
            for _, m in ipairs(ef and ef:GetChildren() or {}) do
                local n = cleanName(m)
                local k = kindOf(n)
                local ok, cf = pcall(function() return m:GetPivot() end)
                local pos = ok and cf and cf.Position or nil
                if pos and k == "ship" and near(pos, h, me, shipRange) then
                    table.insert(threats, { model = m, kind = "ship", label = n, pos = pos })
                elseif pos and not k and near(pos, h, me, RANGE) then
                    newName(n, "workspace.Enemies")
                end
            end
            local sb = workspace:FindFirstChild("SeaBeasts")
            for _, m in ipairs(sb and sb:GetChildren() or {}) do
                if not string.find(string.lower(tostring(m.Name)), "seabeast", 1, true) then
                    newName(tostring(m.Name), "workspace.SeaBeasts")
                end
            end
            -- Judge the members: alive (near, HP left), killed, or lost.
            local alive = {}
            for model, m in pairs(SE.members) do
                local g = m.group
                if live[model] then
                    alive[g] = (alive[g] or 0) + 1
                elseif not m.out then
                    local gone = model.Parent == nil
                    local hpZero
                    if m.hum then
                        hpZero = m.hum.Health <= 0
                    else
                        -- Read even when gone: its last value is still on it.
                        local hp = hpOf(model)
                        if hp then m.hp = hp end
                        hpZero = hp ~= nil and hp <= 0
                    end
                    -- Alive but left far behind (the boat fled): out of this event.
                    local far = not gone and not hpZero
                    local frac = (m.hp and m.max and m.max > 0) and (m.hp / m.max) or nil
                    local v = verdict(hpZero, gone or far, frac)
                    if v then
                        m.out = v
                        if v == "killed" then g.killed += 1 end
                    end
                end
            end
            for i = #SE.groups, 1, -1 do
                local g = SE.groups[i]
                if not g.closed then
                    local over = groupOver(g, alive[g] or 0, now)
                    if over then
                        g.closed = true
                        for model, m in pairs(SE.members) do
                            if m.group == g then SE.members[model] = nil end
                        end
                        if over == "count" then
                            addCount(groupLabel(g))
                        else
                            SE.last = groupLabel(g) .. " gone without a kill - not counted"
                            print("[BFF] seaev: " .. SE.last)
                        end
                    end
                end
            end
            while #SE.groups > 30 do table.remove(SE.groups, 1) end
            return fights, threats
        end

        -- ---------- the boat ----------
        -- Off the seat; the boat held BoatLift up while you fight.
        local function leaveBoat()
            S.stopDrive()
            local b = S.boat or S.myBoat()
            local lift = tonumber(CFG.BoatLift) or 0
            if b and b.Parent and lift > 0 and SE.parkBoat ~= b then
                local p = b:GetPivot().Position
                local wy = (S.drive and S.drive.waterY) or p.Y
                SE.parkBoat, SE.parkSeat, SE.parkAt = b, S.seatOf(b), Vector3.new(p.X, wy + lift, p.Z)
            end
        end

        -- The boat's water line: its own height, unless it is plainly held up.
        local function waterLine(b)
            local y = b:GetPivot().Position.Y
            local ref = seaRef()
            if ref and y > ref + 56 + 60 then return ref + 56 end
            return y
        end

        -- At the wheel: bought, flown to, sat in. true = driving.
        local function board(myEpoch)
            local b = S.myBoat()
            if not b then
                b = S.buyBoat(myEpoch)
                if not b then
                    SE.buyFails = (SE.buyFails or 0) + 1
                    if SE.buyFails >= 3 then
                        SE.note = "could not buy a boat 3 times (" .. tostring(S.boatNote) .. ") - hunt stopped"
                        P.setHunt(false)
                    end
                    task.wait(1)
                    return false
                end
            end
            SE.buyFails = 0
            local seat = S.seatOf(b)
            if not seat then
                SE.note = b.Name .. " has no VehicleSeat"
                task.wait(1)
                return false
            end
            S.boat, S.seat = b, seat
            if S.drive.boat ~= b then S.drive.boat, S.drive.waterY = b, nil end
            local _, r, h = parts()
            if not (h and h.SeatPart == seat) then
                S.driving = false
                if r and (r.Position - seat.Position).Magnitude > 30 then
                    flying = false
                    S.boatNote = "to your boat"
                    setState("FLY")
                    say(S.boatNote)
                    flyTo(seat.Position + UP * 6)
                    if stale(myEpoch) then return false end
                end
                if not S.sit(seat, myEpoch) then
                    S.boatNote = "could not sit in " .. b.Name .. " - trying again"
                    task.wait(0.5)
                    return false
                end
                for _, d in ipairs(b:GetDescendants()) do
                    if d:IsA("BasePart") then pcall(function() d.CanCollide = false end) end
                end
                S.boatNote = "at the wheel of " .. b.Name
            end
            if not S.driving then
                SE.parkBoat, SE.parkSeat, SE.parkAt = nil, nil, nil     -- the wheel puts it back on the water
                S.drive.waterY = S.drive.waterY or waterLine(b)
                flying = true
                S.driving, S.everDriven = true, true
            end
            return true
        end

        -- The wheel asks every frame (P.sea's driveTick): the patrol, or away.
        function SE.steer(pos, look)
            if not (P.running and huntOn()) then return nil end
            local fast = math.clamp(tonumber(CFG.SeaSpeed) or 300, 100, 350)
            if SE.mode == "flee" and SE.threatPos then
                return { dir = fleeDir(pos, SE.threatPos), speed = fast }
            end
            if SE.mode == "hold" then
                return { dir = (look.Magnitude > 0.1) and look.Unit or Vector3.new(0, 0, 1), speed = 0 }
            end
            if not SE.centre then return nil end
            local dir, spd = patrolDir(pos, SE.centre, RADIUS, PATROL, fast)
            return { dir = dir, speed = spd }
        end
        S.steerFn = SE.steer

        -- Every frame: the boat held up while you fight; the aim on the
        -- target's body while a move is fired.
        do
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if _G.BFF ~= P then conn:Disconnect() return end
                local b, at = SE.parkBoat, SE.parkAt
                if b and at and P.running and not S.driving and b.Parent then
                    pcall(function()
                        local pv = b:GetPivot()
                        b:PivotTo(CFrame.new(at) * (pv - pv.Position))
                        local seat = SE.parkSeat
                        if seat then
                            seat.AssemblyLinearVelocity = Vector3.zero
                            seat.AssemblyAngularVelocity = Vector3.zero
                        end
                    end)
                end
                -- THE FIGHT'S FRAME (declared below, with the fights): round the
                -- target dodging, the aim held on it the whole fight.
                if SE.fightTick then pcall(SE.fightTick) end
                local lp = SE.lockPart
                if lp and lp.Parent and P.running and os.clock() < aimUntil then
                    P.aimAt, P.aimPart = lp.Position, lp
                end
                -- The hunt off (or the farm stopped) mid-fight: nothing of it stays
                -- - the grown box, the far camera, the lock, the water's floor.
                if not fightAllowed() and (SE.grown or SE.lockPart or SE.camSet or SE.ev or P.floorY) then
                    if SE.fightOff then SE.fightOff() end   -- (declared below, with the fights)
                    SE.camSet = nil
                end
                SE.camSet = P.camDistance ~= nil or nil
            end)
        end

        -- ---------- the fights ----------
        -- TRANSFORMED (the game's own rule, MovesetClientRunner v4623): with a
        -- fruit's rig on the character, every other weapon's key is REFUSED -
        -- only that fruit's moves fire. Fired anyway, they would be learned as
        -- "never hurt it". Rig -> the tool names it allows (Lua patterns).
        local RIGS = {
            Kitsune = "Kitsune", Dragon = "%-Dragon", GasRig = "Gas%-Gas", HydraRig = "Venom",
            TigerRig = "Tiger", YetiRig = "Yeti", Mammoth = "Mammoth%-Mammoth", TRex = "T%-Rex", Phoenix = "Phoenix",
        }
        local function formOf()
            local ch = player.Character
            if not ch then return nil end
            for rig, pat in pairs(RIGS) do
                if ch:FindFirstChild(rig) then return pat, rig end
            end
            return nil
        end
        local function toolOk(name)
            local pat = formOf()
            return pat == nil or string.find(name, pat) ~= nil
        end

        -- THE HITBOX (every public sea-event script, 2024-26): the target's
        -- HumanoidRootPart made 60 studs a side on YOUR client, see-through,
        -- no collisions - a ray cast from the camera at it (the game's own
        -- aim, for moves that cast their own) and the game's local hit checks
        -- find it; put back when the fight leaves it. Only a part named
        -- HumanoidRootPart: anything else may be the body you see.
        local GROW = Vector3.new(60, 60, 60)
        local function shrink()
            local g = SE.grown
            SE.grown = nil
            if not (g and g.part) then return end
            pcall(function()
                g.part.Size, g.part.CanCollide, g.part.Transparency = g.size, g.collide, g.transp
            end)
        end
        local function grow(root)
            if SE.grown and SE.grown.part == root then return end
            shrink()
            if not (root and root.Name == "HumanoidRootPart") then return end
            local ok = pcall(function()
                local s = root.Size
                SE.grown = { part = root, size = s, collide = root.CanCollide, transp = root.Transparency }
                -- Never smaller: a side already over 60 (the Leviathan's) keeps its length.
                root.Size = Vector3.new(math.max(s.X, GROW.X), math.max(s.Y, GROW.Y), math.max(s.Z, GROW.Z))
                root.CanCollide, root.Transparency = false, 1
            end)
            if not ok then SE.grown = nil end
        end
        SE.shrink = shrink

        -- ---------- EVERY READY KEY (user, 2026-10-09) ----------
        -- "Anything not in cooldown, pressed immediately - Kitsune all but V
        -- (V transforms), Dragon Talon all." A key fires when: its switch is on
        -- (SeaEvKeys), it is not V on a transformation fruit, and the weapon's
        -- mastery has unlocked it (its skill frame's Level against the tool's
        -- Level - what the public hubs read; unreadable = allowed).
        local function transformFruit(name)
            local t = findTool(name)
            if not (t and toolType(t) == "Blox Fruit") then return false end
            for _, pat in pairs(RIGS) do
                if string.find(name, pat) then return true end
            end
            return false
        end
        local function unlocked(name, k)
            local ok, res = pcall(function()
                local kf = player.PlayerGui.Main.Skills[name][k]
                local lv = kf:FindFirstChild("Level")
                if not lv then return true end
                local txt = (lv.ContentText ~= nil and lv.ContentText ~= "") and lv.ContentText or lv.Text or ""
                local req = tonumber(string.match(tostring(txt), "%d+"))
                if not req then return true end
                local t = findTool(name)
                local lvl = t and t:FindFirstChild("Level")
                local cur = (lvl and lvl:IsA("ValueBase")) and tonumber(lvl.Value) or (t and tonumber(t:GetAttribute("Level")))
                if not cur then return true end
                return cur >= req
            end)
            return (not ok) or res ~= false
        end
        local function keyOk(name, k)
            if (CFG.SeaEvKeys or {})[k] ~= true then return false end
            if k == "V" and transformFruit(name) then return false end
            return unlocked(name, k)
        end

        -- ---------- THE WATER AS ROCK, AND DODGING (user, 2026-10-09) ----------
        -- A sea fight sets P.floorY (the sea's top + 4): the lock never goes
        -- under it - noclip lets you through the slab, and a fish's own height
        -- once took you under with it when it dived. P.keepLock: a knockback /
        -- a pull (under 500 studs) is not adopted - back to the lock. The
        -- Humanoid's Swimming state off. Round a fish (SeaDodge): a circle of
        -- DodgeRadius at DodgeSpeed, the direction flipping every 1.2-3 s, the
        -- aim held on it; DodgeUp for DodgeTime the moment it starts an attack
        -- (a new animation that does not loop - its wind-up), charges at you
        -- (over 60 studs/s toward you) or leaps (its root over the sea + 10,
        -- rising).
        local function dodgeOpts(h)
            return { r = tonumber(CFG.DodgeRadius) or 30, speed = tonumber(CFG.DodgeSpeed) or 50,
                h = h or tonumber(CFG.FishHeight) or 30, up = tonumber(CFG.DodgeUp) or 40, top = seaTop() }
        end
        -- Pure (tools/seaev_test.py): the spot this frame. e = the circle's state.
        local function evadeSpot(e, tp, now, rnd, o)
            local dt = math.clamp(now - (e.lastT or now), 0, 0.1)
            e.lastT = now
            if now >= (e.flipAt or 0) then
                e.dir = -(e.dir or -1)
                e.flipAt = now + 1.2 + rnd() * 1.8
            end
            local r = math.max(o.r, 5)
            e.angle = (e.angle or 0) + e.dir * (o.speed / r) * dt
            local up = (now < (e.dodgeUntil or 0)) and o.up or 0
            local y = math.max(tp.Y, o.top) + o.h + up
            return Vector3.new(tp.X + math.cos(e.angle) * r, y, tp.Z + math.sin(e.angle) * r)
        end
        -- Pure (tools/seaev_test.py): the spot pushed out of each danger's
        -- reach, SIDEWAYS - a ball (an area: its middle c, radius r) or a line
        -- (a beam: from o along dir, half-width w; ahead of o only). Never
        -- down (the water) or up (up does not leave the Leviathan's red area).
        local CLEAR = 15
        local function clearOf(spot, list, margin)
            for _ = 1, 2 do
                for _, d in ipairs(list) do
                    if d.kind == "ball" then
                        local off = Vector3.new(spot.X - d.c.X, 0, spot.Z - d.c.Z)
                        local need = d.r + margin
                        if off.Magnitude < need then
                            local u = (off.Magnitude > 0.5) and off.Unit or Vector3.new(1, 0, 0)
                            spot = Vector3.new(d.c.X + u.X * need, spot.Y, d.c.Z + u.Z * need)
                        end
                    elseif d.kind == "line" then
                        local rel = spot - d.o
                        local t = rel:Dot(d.dir)
                        local perp = rel - d.dir * t
                        local need = d.w + margin
                        if t > 0 and perp.Magnitude < need then
                            local f = Vector3.new(d.dir.X, 0, d.dir.Z)
                            local side = (f.Magnitude > 0.05) and Vector3.new(-f.Z, 0, f.X).Unit or Vector3.new(1, 0, 0)
                            local ps = perp:Dot(side)
                            local q = perp - side * ps
                            local s = math.sqrt(math.max(need * need - q:Dot(q), 0))
                            if ps < 0 then s = -s end
                            spot = spot + side * (s - ps)
                        end
                    end
                end
            end
            return spot
        end
        local function tracksOf(model)
            local anim = model:FindFirstChildWhichIsA("Animator", true)
            if not anim then return {} end
            local ok, list = pcall(function() return anim:GetPlayingAnimationTracks() end)
            return (ok and type(list) == "table") and list or {}
        end
        -- e.watch: every model to watch (the Leviathan: all its parts - its
        -- head roars while you hit a segment); else the target's.
        local function markPlaying(e)
            for _, m in ipairs(e.watch or { e.model }) do
                for _, t in ipairs(tracksOf(m)) do e.seen[t] = true end
            end
        end
        local animSaid = {}
        -- Is it about to hit? -> why, or nil.
        local function attackWatch(e, me, now, top)
            local tp = e.root.Position
            local vel = Vector3.zero
            pcall(function() vel = e.root.AssemblyLinearVelocity or Vector3.zero end)
            local why = nil
            for _, m in ipairs(e.watch or { e.model }) do
                for _, t in ipairs(tracksOf(m)) do
                    if not e.seen[t] then
                        e.seen[t] = true
                        local looped = true
                        pcall(function() looped = t.Looped end)
                        if not looped then
                            local id = "?"
                            pcall(function() id = tostring(t.Animation.AnimationId) end)
                            why = why or ("attack " .. id)
                            if not animSaid[id] then
                                animSaid[id] = true
                                print("[BFF] seaev: " .. tostring(e.name) .. " attack animation " .. id .. " - dodged up")
                            end
                        end
                    end
                end
            end
            local fv = flat(vel)
            if not why and me and fv.Magnitude > 60 then
                local to = flat(me - tp)
                if to.Magnitude > 1 and fv.Unit:Dot(to.Unit) > 0.6 then why = "charge" end
            end
            if not why and top and tp.Y > top + 10 and vel.Y > 20 then why = "leap" end
            return why
        end

        local function fightOff()
            shrink()
            SE.lockPart, SE.ev = nil, nil
            P.camDistance, P.floorY, P.keepLock = nil, nil, nil
            if SE.swimHum then
                local h = SE.swimHum
                SE.swimHum = nil
                pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end)
            end
        end
        SE.fightOff = fightOff
        -- A sea fight on target x: its hitbox, the camera off it, the water a
        -- floor, knockback refused, no swimming, the aim on it; a fish = the circle.
        local function fightOn(x, cls, opts)
            grow(x.root)
            P.camDistance = 90
            P.floorY = seaTop() + 4
            P.keepLock = true
            SE.lockPart = x.root
            local _, _, h = parts()
            if h and SE.swimHum ~= h then
                if pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) end) then SE.swimHum = h end
            end
            if (cls == "fish" or (opts and opts.dodge)) and CFG.SeaDodge then
                if not (SE.ev and SE.ev.root == x.root) then
                    SE.ev = { root = x.root, model = x.model, name = x.label or x.kind, angle = math.random() * 2 * math.pi,
                        dir = 1, flipAt = 0, dodgeUntil = 0, seen = setmetatable({}, { __mode = "k" }),
                        h = opts and opts.height or nil, watch = opts and opts.watch or nil,
                        dangers = opts and opts.dangers or nil }
                    markPlaying(SE.ev)       -- what plays already is not an attack starting now
                elseif opts then
                    SE.ev.watch, SE.ev.dangers = opts.watch, opts.dangers     -- a respawned segment watched too
                end
            else
                SE.ev = nil
            end
        end
        -- Every frame of a fight (the heartbeat above): the aim held on the
        -- target; round a fish, up when it attacks.
        function SE.fightTick()
            if not fightAllowed() or S.driving then return end
            local now = os.clock()
            local lp = SE.lockPart
            if lp and lp.Parent then aimUntil = math.max(aimUntil, now + 0.25) end
            local e = SE.ev
            if not (e and e.root and e.root.Parent and CFG.SeaDodge) then return end
            local _, r = parts()
            if now - (e.watchAt or 0) >= 0.05 then
                e.watchAt = now
                local why = attackWatch(e, r and r.Position or nil, now, seaTop())
                if why then
                    e.dodgeUntil = now + (tonumber(CFG.DodgeTime) or 1)
                    e.dir = -(e.dir or 1)
                    SE.dodges = (SE.dodges or 0) + 1
                    SE.lastDodge = why
                end
            end
            local spot = evadeSpot(e, e.root.Position, now, math.random, dodgeOpts(e.h))
            -- Out of the reach of what is coming (the Leviathan's red area, its beam...).
            if e.dangers then
                local ok, list = pcall(e.dangers)
                if ok and type(list) == "table" and #list > 0 then
                    local s2 = clearOf(spot, list, CLEAR)
                    if (s2 - spot).Magnitude > 0.5 then SE.lastClear = now end
                    spot = s2
                end
            end
            lockAt(spot, e.root.Position)
        end

        -- ---------- THE SEA CASTER ----------
        -- Every call fires the first READY key of the sea's weapons - the one
        -- in hand first - the moment the game takes it (canCast: not Busy, not
        -- stunned, no move Holding), and returns the frame its bar starts
        -- cooling. Nothing ready: an aimed M1 with the weapon whose M1 hurts it.
        -- Credited by the target's HP over the next second WITHOUT waiting
        -- (v.pend); an M1 counts for the form's test only when no key went off
        -- beside it (solo). A key the game would not take twice: 3 s off.
        local refused = {}
        local function credit(v, now)
            local resolved, hp = {}, v.hp()
            for i = #v.pend, 1, -1 do
                local p = v.pend[i]
                local hit = hp ~= nil and p.hp0 ~= nil and hp < p.hp0 - 0.5
                if hit or now - p.t > (p.m1 and 0.6 or 1.2) then
                    table.remove(v.pend, i)
                    local L = v.learn[p.key] or { casts = 0, closed = 0 }
                    v.learn[p.key] = L
                    L.casts += 1
                    if hit then L.closed += 1 end
                    table.insert(resolved, { key = p.key, hit = hit, m1 = p.m1, solo = p.solo })
                end
            end
            return resolved
        end
        local function seaCast(v)
            v.pend = v.pend or {}
            local now = os.clock()
            local resolved = credit(v, now)
            local held = heldTool()
            local tools = {}
            for _, t in ipairs(toolNames()) do
                if v.toolOk(t.Name) then
                    if held and t.Name == held.Name then table.insert(tools, 1, t) else table.insert(tools, t) end
                end
            end
            local function aimed()
                RunService.Heartbeat:Wait()
                local at = P.aimAt or v.pos
                pcall(aimSwapIn, at, at)
            end
            for _, t in ipairs(tools) do
                for _, k in ipairs(KEYS5) do
                    local rk = t.Name .. " " .. k
                    local rf = refused[rk]
                    if v.keyOk(t.Name, k) and not (rf and now < rf.untilT) and skillReady(t.Name, k) then
                        if not equip(t.Name) then break end
                        if barReady(t.Name, k) ~= false then
                            -- The move before still playing: wait for it (up to 3 s).
                            local tw = os.clock()
                            while os.clock() - tw < 3 and not canCast() do RunService.Heartbeat:Wait() end
                            if not canCast() then return nil, resolved end
                            local hp0 = v.hp()
                            local w = (CFG.Weapons or {})[t.Name]
                            local hold = (w and w.hold and w.hold[k]) or 0.05
                            aimUntil = math.max(aimUntil, os.clock() + hold + 1)
                            holdKey(KEYCODE[k], hold, aimed)
                            cdOf(t.Name, k).lastCast = os.clock()
                            stats.casts += 1
                            -- Started = its bar cooling OR the game went busy with it
                            -- (a long move - Kitsune Z / X - starts its bar at the END).
                            local tf, started = os.clock(), false
                            repeat
                                RunService.Heartbeat:Wait()
                                if not canCast() then started = true end
                            until started or barReady(t.Name, k) == false or os.clock() - tf > 0.4
                            if started or barReady(t.Name, k) ~= true then
                                refused[rk] = nil
                                for _, p in ipairs(v.pend) do
                                    if p.m1 then p.solo = false end
                                end
                                local key = rk .. (v.suffix or "")
                                table.insert(v.pend, { key = key, hp0 = hp0, t = os.clock(), m1 = false })
                                for _, x in ipairs(credit(v, os.clock())) do table.insert(resolved, x) end
                                return key, resolved
                            end
                            local n = ((rf and rf.n) or 0) + 1
                            refused[rk] = { n = n, untilT = os.clock() + ((n >= 2) and 3 or 0) }
                        end
                    end
                end
            end
            -- No key ready. NO M1 out of Kitsune form (user, 2026-10-09: an
            -- untransformed M1 does nothing to a sea event - never, not even to
            -- test): wait a moment for the next key. In form, Kitsune's M1.
            if not (v.m1Ok and v.m1Ok()) then
                task.wait(0.05)
                for _, x in ipairs(credit(v, os.clock())) do table.insert(resolved, x) end
                return nil, resolved
            end
            local m1 = v.m1Tool and v.m1Tool()
            if m1 then equip(m1) end
            local h2 = heldTool()
            local key = "M1 " .. (h2 and h2.Name or "(empty hand)") .. (v.suffix or "")
            local solo = true
            for _, p in ipairs(v.pend) do
                if not p.m1 then solo = false end
            end
            local hp0 = v.hp()
            local cam = workspace.CurrentCamera
            if cam then
                aimUntil = math.max(aimUntil, os.clock() + 1)
                aimPixel = cam.ViewportSize * 0.5
                aimed()
                pressM1()
                aimPixel = nil
            end
            table.insert(v.pend, { key = key, hp0 = hp0, t = os.clock(), m1 = true, solo = solo })
            task.wait(math.max(CFG.M1Every or 0.06, 0.03))
            for _, x in ipairs(credit(v, os.clock())) do table.insert(resolved, x) end
            return key, resolved
        end
        SE.caster = seaCast

        -- THE WEAPONS AT SEA (user, 2026-10-09: points in fruit + melee): out
        -- of form, only SeaEvWeapons' types; in a form, its own moves (the
        -- game's rule, above) whatever the types say.
        local function typeOk(name)
            local t = findTool(name)
            local ty = t and toolType(t)
            return ty ~= nil and (CFG.SeaEvWeapons or {})[ty] == true
        end
        local function seaOk(name)
            if not toolOk(name) then return false end
            if formOf() then return true end
            return typeOk(name)
        end
        local function noRotate()
            local w = CFG.SeaEvWeapons or {}
            return not (w.Sword or w.Gun)
        end

        -- ---------- KITSUNE FORM FIRST (user, 2026-10-09) ----------
        -- "If transformed Kitsune's M1 lands on the sea beast / Terrorshark,
        -- good; if not, untransformed Kitsune + Dragon Talon." Per CLASS of
        -- target - "beast" (immune to most M1s, the wiki) and "fish"
        -- (Terrorshark / Piranha / Shark, Humanoids) - one test each: fought in
        -- form, its M1 credited by the target's HP. Re-tested every 5th target.
        local CLASS_NAME = { beast = "Sea Beasts", fish = "Terrorshark / Piranha / Shark" }
        SE.form = { beast = { hits = 0, casts = 0, up = 0, since = 0 }, fish = { hits = 0, casts = 0, up = 0, since = 0 } }
        local function kitsune()
            for _, t in ipairs(toolNames()) do
                if toolType(t) == "Blox Fruit" and string.find(t.Name, "Kitsune", 1, true) then return t.Name end
            end
            return nil
        end
        local function inForm() return select(2, formOf()) == "Kitsune" end
        SE.inForm, SE.kitsune = inForm, kitsune

        -- The verdict (pure): its M1 hurt it twice = "form"; SeaEvTrial s in
        -- form with 6 M1s or more and fewer hits = "base"; else nil (testing).
        local function verdictOf(f, trialSecs)
            if f.hits >= 2 then return "form" end
            if f.up >= trialSecs and f.casts >= 6 then return "base" end
            return nil
        end
        -- In form for this class? (Kitsune carried, the radio, the verdict.)
        local function formWanted(cls)
            local mode = CFG.SeaEvForm or "auto"
            if mode == "base" or not kitsune() then return false end
            if mode == "form" then return true end
            return SE.form[cls].verdict ~= "base"
        end
        -- A new target of this class: one more since the verdict; the 5th = test again.
        local function newTarget(cls)
            local f = SE.form[cls]
            if not f.verdict then return end
            f.since += 1
            if f.since >= 5 then
                SE.form[cls] = { hits = 0, casts = 0, up = 0, since = 0 }
                print("[BFF] seaev: 5 " .. CLASS_NAME[cls] .. " since the Kitsune form's verdict - testing it again")
            end
        end

        -- Into / out of the form: Kitsune in hand, V. Seated, the game refuses
        -- every skill - off the seat first (the caller). V's bar cooling = not
        -- now (the fight goes on as it is). The rig not there / not gone in
        -- 2.5 s, 3 times running = left alone a minute (V may not undo it - a
        -- form then ends by itself; meanwhile only its moves are fired).
        local function setForm(want, myEpoch)
            if inForm() == want then return true end
            if os.clock() < (SE.formRetryAt or 0) then return false end
            local k = kitsune()
            if not k then return false end
            if not equip(k) then return false end
            if barReady(k, "V") == false then
                SE.formNote = want and "Kitsune V cooling - fighting out of form meanwhile" or "Kitsune V cooling"
                SE.formRetryAt = os.clock() + 1
                return false
            end
            holdKey(KEYCODE.V, 0.05)
            cdOf(k, "V").lastCast = os.clock()
            local t0 = os.clock()
            while os.clock() - t0 < 2.5 and not stale(myEpoch) do
                if inForm() == want then
                    SE.formFails = 0
                    SE.formNote = want and "Kitsune FORM" or "out of form"
                    print("[BFF] seaev: " .. (want and "into Kitsune form" or "out of Kitsune form"))
                    return true
                end
                task.wait(0.1)
            end
            SE.formFails = (SE.formFails or 0) + 1
            SE.formRetryAt = os.clock() + ((SE.formFails >= 3) and 60 or 3)
            SE.formNote = string.format("V did not %s (%d)%s", want and "transform" or "untransform", SE.formFails,
                (SE.formFails >= 3) and " - left alone a minute" or "")
            print("[BFF] seaev: " .. SE.formNote)
            if SE.formFails >= 3 then SE.formFails = 0 end
            return false
        end
        SE.setForm = setForm

        -- Whose M1 hurts it: learned ("M1 <weapon>"[" (form)"]); untried ones
        -- fruit first (Kitsune's M1 hits beasts - the wiki), then melee.
        -- Only weapons the sea fight takes (seaOk); in form, the fruit's own.
        local M1_RANK = { ["Blox Fruit"] = 1, Melee = 2, Gun = 3, Sword = 4 }
        local function bestM1(learn, suffix)
            learn = learn or SE.learn
            local best, bs, br = nil, -1, 99
            for _, t in ipairs(toolNames()) do
                if not seaOk(t.Name) then continue end
                local s = S.keyScore("M1 " .. t.Name .. (suffix or ""), learn)
                local rk = M1_RANK[toolType(t)] or 9
                if s > bs or (s == bs and rk < br) then best, bs, br = t.Name, s, rk end
            end
            return best
        end

        -- Where to hang. A beast: BeastHeight over the water, 50 to your side;
        -- close: 25 over, 20 off. A fish: FishHeight over it, 15 off; close:
        -- 8 over, 8 off. Close = nothing landed for 6 s.
        local function hangSpot(rp, from, close, sea, cls, hOwn)
            local side = flat(from - rp)
            side = (side.Magnitude > 1) and side.Unit or Vector3.new(1, 0, 0)
            if cls == "fish" then
                local h = close and 8 or (tonumber(CFG.FishHeight) or 30)
                return Vector3.new(rp.X, math.max(rp.Y, sea) + h, rp.Z) + side * (close and 8 or 15)
            end
            local h = close and 25 or (hOwn or tonumber(CFG.BeastHeight) or 90)
            return Vector3.new(rp.X, math.max(sea, rp.Y) + h, rp.Z) + side * (close and 20 or 50)
        end

        -- THE CASTER FIGHT: a beast (always), a fish in Kitsune form. Every
        -- move aimed at it, credited by its HP (a fish's Humanoid, a beast's
        -- value), learned per class and per form; the form's M1 counted for
        -- the test.
        -- opts (the Leviathan): noBoat - only off the seat, never a boat parked;
        -- height - its own; dodge - round it; onCast(key, hp before, hp after).
        local function fightBeast(x, myEpoch, cls, formNow, opts)
            cls = cls or "beast"
            if formNow == nil then formNow = inForm() end
            if pileCur then releasePile() end
            if opts and opts.noBoat then S.stopDrive() else leaveBoat() end
            if SE.cur ~= x.model then
                SE.cur, SE.fightStart, SE.lastHurt, SE.closeOn = x.model, os.clock(), nil, false
                SE.fights += 1
            end
            activeName = x.label
            setState("FIGHT")
            fightOn(x, cls, opts)       -- the hitbox, the camera off it, the water a floor, the aim, the circle
            local function hpNow()
                if x.hum then return x.hum.Health end
                return hpOf(x.model)
            end
            local ref, sea = seaRef(), surfaceY()
            local rp = x.root.Position
            local _, r = parts()
            if not r then return end
            -- Under the water: it cannot be seen or hurt (the wiki). Wait over
            -- it; the no-damage clock waits too (not a miss of ours).
            if cls == "beast" and ref and math.abs(rp.Y - ref) > 175 then
                SE.lockPart = nil
                SE.lastHurt = os.clock()
                local over = Vector3.new(rp.X, sea + 200, rp.Z)
                SE.note = x.label .. " under the water - waiting over it"
                say(SE.note)
                if (r.Position - over).Magnitude > (CFG.InstantHop or 150) then flyTo(over) else lockAt(over, rp) end
                task.wait(0.3)
                return
            end
            -- Nothing landed for 6 s from up there: in close, for this target.
            if not SE.closeOn and os.clock() - (SE.lastHurt or SE.fightStart) > 6 then
                SE.closeOn = true
                print("[BFF] seaev: nothing hurt " .. x.label .. " for 6 s - in close")
            end
            local close = SE.closeOn
            local hOwn = opts and opts.height or nil
            -- Round it at its own height (the Leviathan); nothing landed for 6 s = 25 over it.
            if SE.ev and hOwn then SE.ev.h = close and 25 or hOwn end
            local spot = hangSpot(rp, r.Position, close, sea, cls, hOwn)
            if (r.Position - spot).Magnitude > (CFG.InstantHop or 150) then
                flyTo(spot, { face = rp })
                if stale(myEpoch) then return end
            end
            lockAt(spot, rp)
            SE.lockPart = x.root
            local learn = (cls == "fish") and SE.learnFish or SE.learn
            local suffix = formNow and " (form)" or nil
            local v = { pos = rp, part = x.root, model = x.model, learn = learn, suffix = suffix,
                keys = KEYS5, keyOn = CFG.SeaEvKeys or {}, m1Watch = 0.5, toolOk = seaOk, noRotate = noRotate,
                keyOk = keyOk, hp = hpNow }
            v.m1Tool = function() return bestM1(learn, suffix) end
            v.m1Ok = function() return inForm() end        -- M1 only in Kitsune form
            v.alive = function()
                local hp = hpNow()
                return x.model.Parent ~= nil and not (hp and hp <= 0)
            end
            v.mark = function() v.hp0 = hpNow() end
            v.dropped = function()
                local hp = v.hp0 and hpNow()
                return hp ~= nil and hp < v.hp0 - 0.5
            end
            local f = SE.form[cls]
            local testing = formNow and (CFG.SeaEvForm or "auto") == "auto" and not f.verdict
            local t0 = os.clock()
            while os.clock() - t0 < 1.5 and fightAllowed() and not stale(myEpoch) and v.alive() do
                local _, r2 = parts()
                if not r2 then break end
                v.pos = x.root.Position
                -- Round a fish, the heartbeat moves you (dodging); else hang here.
                if not SE.ev then lockAt(hangSpot(v.pos, r2.Position, close, sea, cls, hOwn), v.pos) end
                local tc = os.clock()
                local hpb = hpNow()
                local key, resolved = SE.caster(v)
                if opts and opts.onCast then opts.onCast(key, hpb, hpNow()) end
                local landed = false
                for _, rr in ipairs(resolved or {}) do
                    if rr.hit then landed = true end
                    if testing and rr.m1 and rr.solo then
                        f.casts += 1
                        if rr.hit then f.hits += 1 end
                    end
                end
                if landed then SE.lastHurt = os.clock() end
                SE.lastKey = tostring(key or "every key cooling") .. (landed and " - hurt it" or "")
                if testing then f.up += os.clock() - tc end
                -- Its last HP, for the count: a beast sinks the moment it dies.
                local mm = SE.members[x.model]
                if mm and not x.hum then mm.hp = hpOf(x.model) or mm.hp end
            end
            -- The test's verdict for this class.
            if testing then
                local vd = verdictOf(f, tonumber(CFG.SeaEvTrial) or 20)
                if vd then
                    f.verdict, f.since = vd, 0
                    local line = string.format("Kitsune form's M1 %s %s (%d of %d M1s, %.0f s) - %s",
                        (vd == "form") and "HURTS" or "does NOT hurt", CLASS_NAME[cls], f.hits, f.casts, f.up,
                        (vd == "form") and "staying in form for them" or "untransformed Kitsune + your fighting style for them")
                    SE.last = line
                    print("[BFF] seaev: " .. line)
                    if vd == "base" then setForm(false, myEpoch) end
                end
            end
            local hp = hpNow()
            local _, rig = formOf()
            SE.note = string.format("%s  ·  HP %s%s  ·  %s  ·  last: %s%s", x.label,
                hp and tostring(math.floor(hp)) or "?", (x.max and x.max > 0) and (" / " .. math.floor(x.max)) or "",
                close and "IN CLOSE (nothing landed for 6 s)"
                    or (math.floor(tonumber((cls == "fish") and CFG.FishHeight or CFG.BeastHeight) or 90) .. " up"),
                tostring(SE.lastKey or "-"),
                rig and ("  ·  " .. rig .. " FORM" .. (testing and string.format(" (testing its M1: %d of %d)", f.hits, f.casts) or ""))
                    or "")
            say(SE.note)
        end

        -- Terrorshark / Piranha / Shark out of form: the farm's own fight, in
        -- place - every skill of the sea's weapons, NO M1 (user, 2026-10-09).
        local FISH_CUR
        FISH_CUR = {
            name = "sea event",
            allKeys = function() return CFG.SeaEvKeys or {} end,
            height = function() return tonumber(CFG.FishHeight) or 30 end,
            toolOk = function(name) return seaOk(name) end,
            keyOk = function(name, k) return keyOk(name, k) end,
            noRotate = function() return noRotate() end,
            fastCast = true,             -- every key the instant the game takes it (castSkill)
            noM1 = function() return not inForm() end,     -- no M1 out of Kitsune form (attackTick)
            -- Where you are: round it, dodging (the heartbeat writes the same spot).
            pose = function()
                local e = SE.ev
                if not (e and CFG.SeaDodge and e.root and e.root.Parent) then return nil end
                return evadeSpot(e, e.root.Position, os.clock(), math.random, dodgeOpts(e.h))
            end,
            -- The M1: your fighting style first, then the fruit, a sword, a gun
            -- - of the weapons the sea fight takes.
            m1Weapon = function()
                local best, br = nil, 99
                local rank = { Melee = 1, ["Blox Fruit"] = 2, Sword = 3, Gun = 4 }
                for _, t in ipairs(toolNames()) do
                    local rk = rank[toolType(t)] or 9
                    if seaOk(t.Name) and rk < br then best, br = t.Name, rk end
                end
                return best
            end,
            build = function()
                local now = os.clock()
                local h = home()
                local _, r = parts()
                local me = r and r.Position or nil
                local best, bd = nil, math.huge
                for _, e in ipairs(liveEnemies(nil)) do
                    local k = kindOf(e.name)
                    local on = (CFG.SeaEvFight or {})[k] == true
                    if on and FISH[k] and near(e.root.Position, h, me, RANGE)
                        and not (P.randomSkip[e.model] and now < P.randomSkip[e.model]) then
                        if e.model == SE.cur then
                            fightOn({ root = e.root, model = e.model, label = k, kind = k }, "fish")
                            return { e }, e.root.Position, true
                        end
                        local d = me and (e.root.Position - me).Magnitude or 0
                        if d < bd then best, bd = e, d end
                    end
                end
                if not best then return {}, nil, false end
                SE.cur = best.model
                local bk = kindOf(best.name)
                remember({ model = best.model, root = best.root, hum = best.hum, kind = bk }, now)
                fightOn({ root = best.root, model = best.model, label = bk, kind = bk }, "fish")
                return { best }, best.root.Position, true
            end,
            -- Into Kitsune form meanwhile (the test, or its verdict): the caster takes over.
            breakIf = function() return not (P.running and huntOn()) or inForm() end,
        }
        SE.FISH_CUR = FISH_CUR

        local function fightFish(x, myEpoch)
            leaveBoat()
            fightOn(x, "fish")
            if SE.cur ~= x.model then
                SE.cur = x.model
                SE.fights += 1
            end
            activeName = x.label
            SE.note = x.label .. "  ·  every skill, no M1, " .. math.floor(tonumber(CFG.FishHeight) or 30) .. " up"
                .. (CFG.SeaDodge and ", round it, dodging" or "")
            say(SE.note)
            local why = fight(FISH_CUR, FISH)
            if why == "empty" then releasePile() end
        end

        -- The fight's target: the one being fought while it lives, else the nearest.
        local function pick(fights, from)
            for _, x in ipairs(fights) do
                if x.model == SE.cur then return x end
            end
            local best, bd = nil, math.huge
            for _, x in ipairs(fights) do
                local d = from and (x.pos - from).Magnitude or 0
                if d < bd then best, bd = x, d end
            end
            return best
        end

        -- ---------- THE HUNT, one step (always true: it never hops) ----------
        function SE.step(myEpoch)
            local E = P.elite
            local sea = mySea()
            if sea and sea ~= 3 then
                SE.note = "sea events are hunted in the Third Sea only - hunt stopped"
                P.setHunt(false)
                E.note = SE.note
                say(SE.note)
                return true
            end
            local now = os.clock()
            if now - (SE.spyAt or -1000) > 300 then task.spawn(function() pcall(spyAsk) end) end
            local fights, threats = scan(now)
            if SE.goalHit and CFG.SeaEvStopAtGoal then
                SE.goalHit = false
                SE.note = string.format("GOAL: %d sea events - the hunt stopped (go to the Spy)", SE.count.total)
                print("[BFF] seaev: " .. SE.note)
                E.note = SE.note
                say(SE.note)
                P.setHunt(false)
                task.defer(function() pcall((P :: any).stop) end)
                return true
            end
            local _, r = parts()
            local x = pick(fights, r and r.Position or nil)
            if x then
                SE.mode = "fight"
                local cls = (x.kind == "beast") and "beast" or "fish"
                if x.model ~= SE.cur then newTarget(cls) end
                -- Off the seat (seated, the game refuses every skill), then the
                -- form this class wants (KITSUNE FORM FIRST).
                leaveBoat()
                local want = formWanted(cls)
                if want ~= inForm() then setForm(want, myEpoch) end
                local formNow = inForm()
                if cls == "beast" or formNow then fightBeast(x, myEpoch, cls, formNow) else fightFish(x, myEpoch) end
                E.note = SE.note
                return true
            end
            -- Nothing to fight: back at the wheel - out of the form first (it
            -- drains, and a fox does not sit).
            SE.cur = nil
            fightOff()
            if pileCur then releasePile() end
            if inForm() then setForm(false, myEpoch) end
            if not board(myEpoch) then
                E.note = SE.note
                return true
            end
            local b = S.boat
            local bp = b:GetPivot().Position
            -- A ship raid (or what you switched off) near: away from it.
            local threat, td = nil, math.huge
            for _, t in ipairs(threats) do
                local d = flat(t.pos - bp).Magnitude
                if d < td then threat, td = t, d end
            end
            local fleeTo = tonumber(CFG.FleeTo) or 1500
            local fleeing = SE.mode == "flee"
            local wm = wheelMode(threat and td or nil, threat and threat.kind, fleeing, fleeTo)
            if wm == "flee" then
                if not fleeing then
                    SE.flees += 1
                    print(string.format("[BFF] seaev: %s %d studs off - sailing away", tostring(threat.label), math.floor(td)))
                end
                SE.mode, SE.threatPos = "flee", threat.pos
                SE.note = string.format("AWAY from %s  ·  %d of %d studs", tostring(threat.label), math.floor(td), fleeTo)
            elseif wm == "hold" then
                SE.mode, SE.threatPos = "hold", nil
                SE.note = string.format("stopped out of %s's way  ·  %d studs  ·  the patrol when it is %d off or gone",
                    tostring(threat.label), math.floor(td), fleeTo * 2)
            else
                SE.mode, SE.threatPos = "patrol", nil
                local want = math.clamp(math.floor(tonumber(CFG.SeaEvDanger) or 5), 1, 6)
                if SE.want ~= want then SE.want, SE.shift, SE.wrong = want, 0, 0 end
                SE.centre = centreOf(want, SE.shift)
                SE.danger = S.dangerNow()
                if flat(bp - SE.centre).Magnitude <= RADIUS * 2 and now - (SE.checkAt or 0) > 10 then
                    SE.checkAt = now
                    SE.wrong = (SE.danger and SE.danger ~= want) and SE.wrong + 1 or 0
                    if SE.wrong >= 2 then
                        SE.wrong = 0
                        SE.shift = nudge(SE.shift, SE.danger, want)
                        SE.centre = centreOf(want, SE.shift)
                        print(string.format("[BFF] seaev: the compass says danger %s, not %d - the circle moves %s",
                            tostring(SE.danger), want, (SE.danger < want) and "out" or "in"))
                    end
                end
                local dist = flat(bp - SE.centre).Magnitude
                SE.note = string.format("%s danger %d  ·  compass %s%s",
                    (dist > RADIUS * 2) and "sailing to" or "patrolling", want, tostring(SE.danger or "?"),
                    (dist > RADIUS * 2) and string.format("  ·  %d studs to go", math.floor(dist)) or "")
            end
            S.hp, S.maxHp = S.boatHP(b)
            E.note = SE.note
            say(SE.note)
            setState("SAIL")
            task.wait(0.25)
            return true
        end

        -- The learned keys, kept with the count (every 15 s when one was added).
        if writefile then
            task.spawn(function()
                local saved = -1
                while _G.BFF == nil or _G.BFF == P do
                    task.wait(15)
                    local n = 0
                    for _, L in pairs(SE.learn) do n += (tonumber(L.casts) or 0) end
                    for _, L in pairs(SE.learnFish) do n += (tonumber(L.casts) or 0) end
                    if n ~= saved then
                        saved = n
                        save()
                    end
                end
            end)
        end

        -- ---------- THE LEVIATHAN (user, 2026-10-09; CFG.LeviFight) ----------
        -- Its own switch. ON = only the Leviathan (switched on inside the
        -- Frozen Dimension; nothing else runs). Its parts in workspace.SeaBeasts
        -- - "Leviathan" (the head), "Leviathan Segment"s, "Leviathan Tail" (the
        -- hubs, 2026; each with a Humanoid + Animator - the game's own
        -- SyncLeviathan) - fought like a Sea Beast: every ready key aimed at
        -- it, no M1 out of Kitsune form, the water a floor, round it, a dive
        -- waited out. Only a part whose HealthEnabled is true takes damage;
        -- none has the attribute at all = every part taken. THE HEAD LAST
        -- (user): never while a segment / the tail takes damage - they
        -- respawn (the wiki): back to them first.
        -- THE REWARD needs at least 8% of the damage on EACH segment (the
        -- wiki): yours is its HP drop while your keys land (other players'
        -- hits in that moment count too - so the goal is LeviShare, 15%), then
        -- the next segment; every one reached = the nearest until it dies.
        -- ITS ATTACKS (the game's own effects - below): out of each one's reach.
        -- ITS HEART (Map.FrozenHeart): the character is YOURS - the Beast
        -- Hunter's harpoon, tow it to Tiki (dying loses it). KILLED (the head's
        -- HP 0, or gone at 10% or less): the Spy's cooldown starts (each
        -- Frozen Dimension resets his count - the wiki) - the sea event count
        -- back to 0, the kill kept. Nothing of it up: yours (hands off) until
        -- it shows; gone mid-fight: held over the water 20 s first. No boat is
        -- ever touched (a group may be riding yours).
        local LEVI = { ["Leviathan"] = "head", ["Leviathan Segment"] = "segment", ["Leviathan Tail"] = "tail" }
        local LV: { [string]: any } = { active = false, hands = false, waiting = false, note = "-", kills = 0,
            share = setmetatable({}, { __mode = "k" }), maxSeen = setmetatable({}, { __mode = "k" }), lastKeyAt = 0,
            dangers = {}, dangerSaid = {}, now = {} }
        SE.levi = LV

        local function leviRoot(m)
            for _, n in ipairs({ "HumanoidRootPart", "Head" }) do
                local p = m:FindFirstChild(n)
                if p and p:IsA("BasePart") then return p end
            end
            if m:IsA("Model") and m.PrimaryPart then return m.PrimaryPart end
            return m:FindFirstChildWhichIsA("BasePart", true)
        end

        local function leviParts()
            local f = workspace:FindFirstChild("SeaBeasts")
            local out, anyAttr = {}, false
            for _, m in ipairs(f and f:GetChildren() or {}) do
                local kind = LEVI[tostring(m.Name)]
                local root = kind and leviRoot(m)
                if root then
                    local ok, hp, max = pcall(beastHP, m)
                    local attr = m:GetAttribute("HealthEnabled")
                    if attr ~= nil then anyAttr = true end
                    hp, max = ok and hp or nil, ok and max or nil
                    if hp then LV.maxSeen[m] = math.max(LV.maxSeen[m] or 0, hp) end
                    table.insert(out, { model = m, root = root, kind = kind, hp = hp, max = max, maxSeen = LV.maxSeen[m],
                        attr = attr, pos = root.Position, label = "Leviathan " .. kind })
                end
            end
            for _, x in ipairs(out) do x.enabled = (x.attr == true) or not anyAttr end
            return out
        end

        -- THE PART TO HIT (pure: tools/seaev_test.py). Alive and taking damage
        -- only; THE HEAD only when no segment / tail is. One still short of
        -- your share (a segment / the tail - the head has no rule) before the
        -- rest: the one being hit while it is short, else the nearest short
        -- one; every share reached = the one being hit, else the nearest.
        local function leviPick(list, cur, share, goal, from)
            local ok, body = {}, false
            for _, x in ipairs(list) do
                if x.enabled and (x.hp == nil or x.hp > 0) then
                    table.insert(ok, x)
                    if x.kind ~= "head" then body = true end
                end
            end
            if body then
                local b = {}
                for _, x in ipairs(ok) do
                    if x.kind ~= "head" then table.insert(b, x) end
                end
                ok = b
            end
            if #ok == 0 then return nil end
            local function short(x)
                local m = x.max or x.maxSeen
                return x.kind ~= "head" and m ~= nil and m > 0 and (share[x.model] or 0) < goal * m
            end
            local anyShort = false
            for _, x in ipairs(ok) do
                if short(x) then anyShort = true end
            end
            for _, x in ipairs(ok) do
                if x.model == cur and (short(x) or not anyShort) then return x end
            end
            local best, bd = nil, math.huge
            for _, x in ipairs(ok) do
                if short(x) or not anyShort then
                    local d = from and (x.pos - from).Magnitude or 0
                    if d < bd then best, bd = x, d end
                end
            end
            return best
        end

        local function leviDown()
            LV.downSaid = true
            LV.kills += 1
            local c = SE.count
            local was = c.total
            local lev = (c.kinds.Leviathan or 0) + 1
            SE.count = { total = 0, kinds = { Leviathan = lev }, since = os.time(),
                log = { string.format("%s Leviathan down - count reset (was %d)", os.date("%H:%M"), was) } }
            SE.goalHit = false
            save()
            SE.last = string.format("THE LEVIATHAN IS DOWN - the Spy's cooldown starts: the count is back to 0 (was %d)", was)
            print("[BFF] levi: " .. SE.last)
            S.notify("Leviathan down! Sea event count reset to 0")
        end

        -- Its head: down when its HP reads 0, or it went at 10% or less (it sinks).
        local function leviTrack(list)
            local head = nil
            for _, x in ipairs(list) do
                if x.kind == "head" then head = x end
            end
            if head then
                LV.head = head.model
                LV.headHp = head.hp or LV.headHp
                LV.headMax = head.max or head.maxSeen or LV.headMax
                if head.hp ~= nil and head.hp <= 0 and not LV.downSaid then leviDown() end
            elseif LV.head then
                local frac = (LV.headHp and LV.headMax and LV.headMax > 0) and (LV.headHp / LV.headMax) or nil
                if not LV.downSaid and verdict(false, true, frac) == "killed" then leviDown() end
                LV.head = nil
            end
        end

        local function probeLevi(list)
            if LV.probed then return end
            LV.probed = true
            local out = { "[leviathan] " .. os.date("!%Y-%m-%d %H:%M:%S") .. "Z  " .. #list .. " parts" }
            for _, x in ipairs(list) do
                local m = x.model
                local t = {}
                local ok, a = pcall(function() return m:GetAttributes() end)
                if ok and type(a) == "table" then
                    for k, val in pairs(a) do table.insert(t, tostring(k) .. "=" .. tostring(val)) end
                end
                local okh, hp, max, src = pcall(beastHP, m)
                table.insert(out, string.format("%s (%s): HP %s / %s from %s  ·  root %s at Y %.0f  ·  attributes: %s",
                    tostring(m.Name), tostring(m.ClassName), tostring(okh and hp), tostring(okh and max), tostring(okh and src),
                    tostring(x.root.Name), x.root.Position.Y, table.concat(t, ", ")))
                local n = 0
                for _, d in ipairs(m:GetChildren()) do
                    if n < 25 then
                        n += 1
                        table.insert(out, "    " .. tostring(d.Name) .. " (" .. tostring(d.ClassName) .. ")")
                    end
                end
            end
            local map = workspace:FindFirstChild("Map")
            table.insert(out, "Map.FrozenHeart now: " .. tostring(map ~= nil and map:FindFirstChild("FrozenHeart") ~= nil))
            probeAdd(table.concat(out, "\n"))
            print("[BFF] levi: its parts written to workspace/" .. PROBE)
        end

        -- ITS ATTACKS - the game's own client effects (the decompiled client
        -- v4623: EffectContainer/Leviathan, IceSpear), each an object it puts
        -- in workspace._WorldOrigin:
        --   Bubble       Sub-Zero Annihilation's red area (the tail): it
        --                flashes ~5 s, then the swipe launches ice in it. Up
        --                does not save you (the wiki: skycamping fails) - out
        --                of it, sideways; kept 7 s (it goes before the swipe).
        --   MouthCharge  the Freeze Blast's wind-up on its mouth: the beam
        --                leaves along its look.   BeamModel  the beam itself.
        --   IcyTornado   Snowstorm of Death's tornadoes (they move).
        --   IceSpear     the roar's spears: at where you were, 240 studs/s -
        --                up, now (DodgeUp).
        local DANGER_LIFE = { Bubble = 7, MouthCharge = 8, BeamModel = 8, IcyTornado = 15 }
        local DANGER_NAME = { Bubble = "the tail's red area", MouthCharge = "its beam charging", BeamModel = "its beam",
            IcyTornado = "a tornado" }
        local function partOf(i)
            if i:IsA("BasePart") then return i end
            if i:IsA("Model") then return i.PrimaryPart or i:FindFirstChildWhichIsA("BasePart", true) end
            return nil
        end
        local function sizeOf(i)
            if i:IsA("Model") then
                local ok, s = pcall(function() return i:GetExtentsSize() end)
                if ok and s then return s end
            end
            local p = partOf(i)
            if not p then return nil end
            local s = p.Size
            local m = p:FindFirstChildOfClass("SpecialMesh")
            if m and m.Scale then s = Vector3.new(s.X * m.Scale.X, s.Y * m.Scale.Y, s.Z * m.Scale.Z) end
            return s
        end
        -- One attack's reach now -> its shape (nil = not readable yet), over.
        local function dangerShape(d, now)
            if now - d.born > (DANGER_LIFE[d.name] or 8) then return nil, true end
            if d.inst.Parent == nil then
                if d.name ~= "Bubble" then return nil, true end   -- the swipe comes after its Bubble goes
                return d.last, false
            end
            local ok, shape = pcall(function()
                if d.name == "MouthCharge" then
                    local c = d.inst.CFrame
                    return { kind = "line", o = c.Position, dir = c.LookVector, w = 20, name = d.name }
                end
                if d.name == "BeamModel" then
                    -- Its end keeps the beam's own CFrame (the game lerps it out along it).
                    local e = d.inst:FindFirstChild("BeamEnd") or partOf(d.inst)
                    local root = d.inst:FindFirstChild("BeamRoot")
                    local dir = e.CFrame.LookVector
                    return { kind = "line", o = root and root.Position or (e.Position - dir * 2000), dir = dir, w = 20,
                        name = d.name }
                end
                local s = sizeOf(d.inst)
                local pos = d.inst:IsA("Model") and d.inst:GetPivot().Position or partOf(d.inst).Position
                local r = 0
                if s then
                    r = (d.name == "IcyTornado") and math.max(s.X, s.Z) / 2 or math.max(s.X, s.Y, s.Z) / 2
                end
                return { kind = "ball", c = pos, r = math.max(r, (d.name == "Bubble") and 60 or 15), name = d.name }
            end)
            if ok and shape then d.last = shape end
            return d.last, false
        end
        -- Every attack's reach now (the circle steps out of each - SE.fightTick).
        local function leviDangers()
            local now, out, keep, names = os.clock(), {}, {}, {}
            for _, d in ipairs(LV.dangers) do
                local s, over = dangerShape(d, now)
                if not over then
                    table.insert(keep, d)
                    if s then
                        table.insert(out, s)
                        table.insert(names, DANGER_NAME[d.name] or d.name)
                    end
                end
            end
            LV.dangers, LV.now = keep, names
            return out
        end
        -- Each kind once to the probe file: its real size and place (to correct the reach above).
        local function dangerProbe(i)
            local s = sizeOf(i)
            local p = partOf(i)
            local _, r = parts()
            probeAdd(string.format("[leviathan attack] %s (%s)  ·  size %s  ·  at %s  ·  %s studs from you  ·  SpecialMesh %s",
                tostring(i.Name), tostring(i.ClassName), s and string.format("%.0f x %.0f x %.0f", s.X, s.Y, s.Z) or "?",
                p and string.format("%.0f, %.0f, %.0f", p.Position.X, p.Position.Y, p.Position.Z) or "?",
                (p and r) and tostring(math.floor((p.Position - r.Position).Magnitude)) or "?",
                tostring(p ~= nil and p:FindFirstChildOfClass("SpecialMesh") ~= nil)))
        end
        local function dangerSeen(i)
            local name = tostring(i.Name)
            if name == "IceSpear" then
                local e = SE.ev
                local p = partOf(i)
                local _, r = parts()
                if e and p and r and (p.Position - r.Position).Magnitude < 400 then
                    e.dodgeUntil = os.clock() + (tonumber(CFG.DodgeTime) or 1)
                    e.dir = -(e.dir or 1)
                    SE.dodges = (SE.dodges or 0) + 1
                    SE.lastDodge = "its ice spear"
                end
                return
            end
            if not DANGER_LIFE[name] then return end
            table.insert(LV.dangers, { name = name, inst = i, born = os.clock() })
            if not LV.dangerSaid[name] then
                LV.dangerSaid[name] = true
                print("[BFF] levi: " .. DANGER_NAME[name] .. " (" .. name .. ") - out of its reach")
                task.spawn(function()
                    task.wait(0.2)           -- the game sets its place just after
                    pcall(dangerProbe, i)
                end)
            end
        end
        local function leviWatchOff()
            local c = LV.watchConn
            LV.watchConn = nil
            if c then pcall(function() c:Disconnect() end) end
            LV.dangers, LV.now = {}, {}
        end
        local function leviWatchOn()
            if LV.watchConn then return end
            local wo = workspace:FindFirstChild("_WorldOrigin")
            if not wo then return end
            LV.dangers = {}
            for _, c in ipairs(wo:GetChildren()) do pcall(dangerSeen, c) end
            LV.watchConn = wo.ChildAdded:Connect(function(i)
                if _G.BFF ~= P then leviWatchOff() return end     -- a new copy loaded / unloaded
                pcall(dangerSeen, i)
            end)
        end

        -- The character to you (its heart; nothing of it up) / back to the fight.
        local function yours()
            if P.handsOff then return end
            if pileCur then releasePile() end
            P.handsOff, flying = true, false
            pcall(restoreBody)
            pcall(releaseCamera)
        end
        local function farmDrives()
            if not P.handsOff then return end
            local _, rh = parts()
            if rh then
                lastWritten = rh.Position
                lockAt(rh.Position)
            end
            P.handsOff = false
        end
        -- The switch off: nothing of it stays.
        local function leviRelease()
            if LV.hands or LV.waiting then
                LV.hands, LV.waiting = false, false
                farmDrives()
            end
            if LV.active or LV.holdUntil then
                LV.active, LV.holdUntil = false, nil
                fightOff()
            end
            leviWatchOff()
        end

        -- One step. true = the Leviathan has the character - its fight, its
        -- heart, or waiting for it (the switch on = nothing else runs);
        -- false = the switch is off: the other modes run.
        function SE.leviStep()
            local myEpoch = epoch
            if not CFG.LeviFight then
                leviRelease()
                return false
            end
            local map = workspace:FindFirstChild("Map")
            local heart = map and map:FindFirstChild("FrozenHeart")
            if heart then
                if not LV.hands then
                    LV.hands, LV.active, LV.holdUntil, LV.waiting = true, false, nil, false
                    fightOff()
                    leviWatchOff()
                    LV.note = "THE LEVIATHAN'S HEART - the character is YOURS: the Beast Hunter's harpoon "
                        .. "(its seat at the bow, M1), tow it to Tiki Outpost - dying loses it"
                    print("[BFF] levi: " .. LV.note)
                    S.notify("Leviathan heart - yours! Harpoon it, tow it to Tiki")
                end
                yours()
                say(LV.note)
                setState("LEVI")
                task.wait(0.3)
                return true
            end
            if LV.hands then
                LV.hands = false
                print("[BFF] levi: the heart is gone")
            end
            local list = leviParts()
            leviTrack(list)
            local _, r = parts()
            if #list == 0 then
                if LV.active then
                    -- Gone mid-fight (dead before its heart shows, a phase, it
                    -- left): held over the water a while - never dropped in it.
                    LV.active = false
                    fightOff()
                    if r then
                        LV.holdUntil = os.clock() + 20
                        LV.holdAt = Vector3.new(r.Position.X, math.max(r.Position.Y, seaTop() + 20), r.Position.Z)
                    end
                    LV.note = "the Leviathan is gone (under / away) - holding over the water, 20 s"
                    print("[BFF] levi: " .. LV.note)
                end
                if LV.holdUntil and os.clock() < LV.holdUntil then
                    P.floorY, P.keepLock = seaTop() + 4, true
                    lockAt(clearOf(LV.holdAt, leviDangers(), CLEAR))
                    say(LV.note)
                    setState("LEVI")
                    task.wait(0.3)
                    return true
                end
                if LV.holdUntil then
                    LV.holdUntil = nil
                    fightOff()
                end
                leviWatchOff()
                -- Nothing of it here: the switch keeps the character for it -
                -- yours (hands off) until it shows; nothing else runs.
                if not LV.waiting then
                    LV.waiting = true
                    LV.note = "Leviathan fight ON - waiting for it: the character is yours until it shows "
                        .. "(nothing else runs; the switch off = the farm)"
                    print("[BFF] levi: " .. LV.note)
                end
                yours()
                say(LV.note)
                setState("LEVI")
                task.wait(0.3)
                return true
            end
            -- It is up: the fight has the character.
            LV.holdUntil, LV.waiting = nil, false
            farmDrives()
            leviWatchOn()
            if not LV.active then
                LV.active, LV.downSaid, LV.cur = true, false, nil
                LV.share = setmetatable({}, { __mode = "k" })
                print(string.format("[BFF] levi: THE LEVIATHAN - %d parts up", #list))
                S.notify("Leviathan up - fighting it")
                probeLevi(list)
            end
            if not r then return true end
            local goal = math.clamp(tonumber(CFG.LeviShare) or 15, 1, 100) / 100
            local h = tonumber(CFG.LeviHeight) or 75
            -- Every part watched for an attack starting (its head roars while
            -- you hit a segment); its attacks' reach kept out of.
            local models = {}
            for _, p in ipairs(list) do table.insert(models, p.model) end
            local x = leviPick(list, LV.cur, LV.share, goal, r.Position)
            if not x then
                -- Nothing of it takes damage right now (a phase change): round
                -- the nearest part, waiting.
                LV.cur = nil
                local any, bd = list[1], math.huge
                for _, p in ipairs(list) do
                    local d = (p.pos - r.Position).Magnitude
                    if d < bd then any, bd = p, d end
                end
                S.stopDrive()
                fightOn(any, "beast", { dodge = true, height = h, watch = models, dangers = leviDangers })
                SE.lockPart = nil
                local rp = any.root.Position
                lockAt(Vector3.new(rp.X, math.max(rp.Y, seaTop()) + h, rp.Z), rp)
                LV.note = "the Leviathan - no part takes damage right now (HealthEnabled off) - round it, waiting"
                say(LV.note)
                setState("LEVI")
                task.wait(0.3)
                return true
            end
            if LV.cur ~= x.model then
                LV.cur = x.model
                print(string.format("[BFF] levi: on the %s (HP %s)", x.label, x.hp and tostring(math.floor(x.hp)) or "?"))
            end
            S.stopDrive()                  -- seated, the game refuses every skill (never a boat parked)
            local want = formWanted("beast")
            if want ~= inForm() then setForm(want, myEpoch) end
            fightBeast(x, myEpoch, "beast", inForm(), { noBoat = true, dodge = true, height = h, watch = models,
                dangers = leviDangers,
                onCast = function(key, hpb, hpa)
                    if key then LV.lastKeyAt = os.clock() end
                    if hpb and hpa and hpa < hpb and os.clock() - (LV.lastKeyAt or 0) < 1.2 then
                        LV.share[x.model] = (LV.share[x.model] or 0) + (hpb - hpa)
                    end
                end })
            local m = x.max or x.maxSeen
            LV.note = string.format("LEVIATHAN  ·  %s  ·  HP %s%s  ·  your share %s", x.label,
                x.hp and tostring(math.floor(x.hp)) or "?", m and (" / " .. math.floor(m)) or "",
                m and string.format("%.1f%% (the next part at %d%%)", (LV.share[x.model] or 0) / m * 100, math.floor(goal * 100 + 0.5))
                    or "not readable")
            say(LV.note)
            setState("LEVI")
            return true
        end

        -- For the tests.
        SE._t = {
            parseHP = parseHP, kindOf = kindOf, beastKind = beastKind, groupLabel = groupLabel,
            joinGroup = joinGroup, verdict = verdict, groupOver = groupOver, patrolDir = patrolDir,
            fleeDir = fleeDir, wheelMode = wheelMode, nudge = nudge, centreOf = centreOf, spyText = spyText, beastHP = beastHP,
            scan = scan, pick = pick, bestM1 = bestM1, hangSpot = hangSpot, fightBeast = fightBeast,
            board = board, leaveBoat = leaveBoat, ZONES = ZONES, grow = grow, shrink = shrink, toolOk = toolOk, formOf = formOf,
            seaOk = seaOk, typeOk = typeOk, verdictOf = verdictOf, formWanted = formWanted, setForm = setForm,
            newTarget = newTarget, fightFish = fightFish, evadeSpot = evadeSpot, attackWatch = attackWatch,
            keyOk = keyOk, transformFruit = transformFruit, unlocked = unlocked, seaCast = seaCast,
            fightOn = fightOn, fightOff = fightOff, seaTop = seaTop,
            leviParts = leviParts, leviPick = leviPick, leviTrack = leviTrack,
            clearOf = clearOf, dangerShape = dangerShape, leviDangers = leviDangers, leviWatchOn = leviWatchOn,
        }
    end
    build()
end

-- =========================================================
-- SERVER NEWS
-- =========================================================
-- The strip under the panel's title: what THIS server is doing, read from
-- what the game sends every client, at whatever moment you join -- nothing
-- is counted from the server's start (user, 2026-10-04).
--   MOON       Lighting attribute "MoonPhase", 1-8, 5 = the full moon (the
--              public hubs 2024-26), and "IsBlueMoon". The moon decal when the
--              attribute is missing: Roblox's asset list names the game's
--              eight moon1..moon8, moon5 the full one.
--   DAY/NIGHT  Lighting.ClockTime; night is 18:00 -> 05:00. The phase turns at
--              noon, so a day carries the number of the night it leads into:
--              night 4, (noon) day 5, night 5 = the full moon.
--   MINUTES    how fast that clock runs is MEASURED, day and night apart, and
--              so are the hour the phase turns and the order it turns in --
--              kept in bff_sky.json, so the next server starts knowing them.
--              Until measured: a game hour a minute (what makes the wiki's
--              "first full moon 54 min after a server starts" come out).
--   ISLANDS    Mirage, Prehistoric, Kitsune, the Frozen Dimension, where the
--              hubs find them: workspace.Map and _WorldOrigin.Locations. Age =
--              since this client saw one come; one already up when you joined
--              has no known age, and says so.
--   BOSSES     the elites and the raid bosses through bossUp (loaded, or
--              parked in ReplicatedStorage). Cake Prince's count is the game's
--              own answer to "CakePrinceSpawner" -- asked, never summoned --
--              once a minute while the strip is on screen.
-- Read once a second from load, panel open or not. Only P.news leaves the
-- block (the main chunk is at Luau's 200-register limit).
do
    local function build()
        -- Typed open: its fields come as the news is read.
        local N: { [string]: any } = { isles = {}, bosses = {}, fruits = {}, events = {} }
        P.news = N
        local Lighting    = game:GetService("Lighting")
        local HttpService = game:GetService("HttpService")
        local SKY_FILE    = "bff_sky.json"
        local DUSK, DAWN  = 18, 5
        local FULL        = 5
        local HOUR_A_MIN  = 1 / 60           -- game hours a real second, until measured
        local MOON_DECAL  = {
            ["9709135895"] = 1, ["9709139597"] = 2, ["9709143733"] = 3, ["9709149052"] = 4,
            ["9709149431"] = 5, ["9709149680"] = 6, ["9709150086"] = 7, ["9709150401"] = 8,
        }
        local BLUE_DECAL  = "15493317929"
        local PHASE = { "no moon", "crescent", "half moon", "gibbous", "full moon",
            "gibbous, waning", "half moon, waning", "crescent, waning" }
        -- always = said every lap even when not up (the two you look for).
        local ISLES = {
            { key = "mirage", title = "MIRAGE ISLAND", map = "MysticIsland", loc = "Mirage Island",
                life = 900, always = true, why = "Advanced Fruit Dealer, Blue Gear at night" },
            { key = "prehistoric", title = "PREHISTORIC ISLAND", map = "PrehistoricIsland",
                always = true, why = "volcano, Dragon Egg, bones" },
            { key = "kitsune", title = "KITSUNE ISLAND", map = "KitsuneIsland", loc = "Kitsune Island",
                life = 900, why = "Azure Embers, the shrine" },
            { key = "frozen", title = "FROZEN DIMENSION", map = "FrozenDimension", loc = "Frozen Dimension",
                why = "Leviathan" },
        }
        local RAID = { "Dough King", "Cake Prince", "rip_indra True Form", "Soul Reaper" }
        for _, d in ipairs(ISLES) do N.isles[d.key] = { up = false } end

        -- What was learned about the clock and the moon (bff_sky.json).
        local cal: { [string]: any } = { flipAt = 12, succ = {}, flips = 0 }
        N.cal = cal

        local function clockText(c)
            local m = math.floor(c * 60 + 0.5) % 1440
            return string.format("%02d:%02d", m // 60, m % 60)
        end
        -- m:ss under an hour, then 1h 05m (the chip)
        local function dur(s)
            s = math.max(0, math.floor(s + 0.5))
            if s >= 3600 then return string.format("%dh %02dm", s // 3600, (s % 3600) // 60) end
            return string.format("%d:%02d", s // 60, s % 60)
        end
        -- Whole minutes (the crawl: a number changing every second would
        -- make the text after it twitch).
        local function mins(s)
            local m = math.floor(math.max(0, s) / 60 + 0.5)
            if m < 1 then return "under a minute" end
            if m >= 60 then return string.format("%d h %02d min", m // 60, m % 60) end
            return m .. " min"
        end
        N.dur, N.mins, N.clockText = dur, mins, clockText

        local function saveCal()
            if not writefile then return end
            local succ = {}
            for a, b in pairs(cal.succ) do succ[tostring(a)] = b end
            local ok, s = pcall(function()
                return HttpService:JSONEncode({ rateDay = cal.rateDay, rateNight = cal.rateNight,
                    flipAt = cal.flipAt, succ = succ, flips = cal.flips })
            end)
            if ok then pcall(writefile, SKY_FILE, s) end
        end
        local function loadCal()
            if not readfile then return end
            local ok, s = pcall(readfile, SKY_FILE)
            if not ok or type(s) ~= "string" then return end
            local ok2, d = pcall(function() return HttpService:JSONDecode(s) end)
            if not ok2 or type(d) ~= "table" then return end
            local function rate(v)
                v = tonumber(v)
                return (v and v > 0 and v <= 0.2) and v or nil
            end
            cal.rateDay, cal.rateNight = rate(d.rateDay), rate(d.rateNight)
            local f = tonumber(d.flipAt)
            if f and f >= DAWN and f <= DUSK then cal.flipAt = f end
            cal.flips = tonumber(d.flips) or 0
            if type(d.succ) == "table" then
                for a, b in pairs(d.succ) do
                    a, b = tonumber(a), tonumber(b)
                    if a and b and a >= 1 and a <= 8 and b >= 1 and b <= 8 and a ~= b then cal.succ[a] = b end
                end
            end
        end
        N.save = saveCal
        loadCal()

        -- THE SKY ---------------------------------------------------------
        local function isNight(c) return c >= DUSK or c < DAWN end
        local function untilClock(c, h)
            local d = h - c
            if d <= 0 then d += 24 end
            return d
        end
        -- One side measured: the other uses it too, before the default.
        local function rateAt(night)
            return (night and cal.rateNight or cal.rateDay) or cal.rateNight or HOUR_A_MIN
        end
        -- Real seconds for `hours` of game time from clock c, day and night
        -- each at its own speed.
        local function realSpan(c, hours)
            local sec, guard = 0, 0
            while hours > 1e-9 and guard < 64 do
                guard += 1
                local night = isNight(c)
                local step = math.min(hours, untilClock(c, night and DAWN or DUSK))
                sec += step / rateAt(night)
                c = (c + step) % 24
                hours -= step
            end
            return sec
        end
        local function succOf(p) return cal.succ[p] or (p % 8 + 1) end
        local function nightsToFull(p)
            local k = 0
            while p ~= FULL do
                p = succOf(p)
                k += 1
                if k > 8 then return nil end
            end
            return k
        end

        -- The sky at clock c with the server's phase p (nil = not readable).
        --   night   it is night now
        --   no      the number to show: this night's, or the night this day
        --           leads into (before the turn, the next phase)
        --   full    a full moon is up now
        --   edge    real seconds to the next dusk (day) or dawn (night)
        --   nights  0 = the full moon is up / rises tonight, 1 = next night ...
        --   toFull  real seconds until it rises (0 = up)
        local function skyAt(c, p)
            local s = { clock = c, phase = p, night = isNight(c) }
            s.edge = realSpan(c, untilClock(c, s.night and DAWN or DUSK))
            if not p then return s end
            if s.night then
                s.no = p
            else
                s.no = (c >= cal.flipAt) and p or succOf(p)
            end
            s.full = s.night and s.no == FULL
            if s.full then
                s.nights, s.toFull = 0, 0
                return s
            end
            local k = nightsToFull(s.night and succOf(s.no) or s.no)
            if k then
                s.nights = k + (s.night and 1 or 0)
                s.toFull = realSpan(c, untilClock(c, DUSK) + 24 * k)
            end
            return s
        end
        N.skyAt = skyAt

        -- The server's phase: its attribute, else the moon decal shown.
        local function moonRead()
            local raw = Lighting:GetAttribute("MoonPhase")
            local blue = Lighting:GetAttribute("IsBlueMoon") == true
            local n = tonumber(raw)
            if n and n >= 1 and n <= 8 and n % 1 == 0 then return n, blue, "server" end
            local sky = Lighting:FindFirstChild("Sky") or Lighting:FindFirstChild("FantasySky")
                or Lighting:FindFirstChildOfClass("Sky")
            local id = sky and string.match(tostring(sky.MoonTextureId), "(%d+)%D*$")
            if id == BLUE_DECAL then return FULL, true, "decal" end
            if id and MOON_DECAL[id] then return MOON_DECAL[id], blue, "decal" end
            return nil, blue, (raw ~= nil) and ("MoonPhase = " .. tostring(raw)) or "nothing"
        end
        N.moonRead = moonRead

        -- The clock's speed: 20 s samples, each counted for the part of the
        -- day it lies in. A jump, a stop or a long gap (loading) is no speed.
        local lastC, lastT
        local function feedClock(c, t)
            if not lastC then lastC, lastT = c, t return end
            local dt = t - lastT
            if dt < 20 then return end
            local dc = c - lastC
            if dc < -12 then dc += 24 end
            local mid = (lastC + dc / 2) % 24
            lastC, lastT = c, t
            if dt > 120 or dc <= 0 then return end
            local r = dc / dt
            if r > 0.2 then return end
            local key = isNight(mid) and "rateNight" or "rateDay"
            cal[key] = cal[key] and (cal[key] * 0.6 + r * 0.4) or r
            N.samples = (N.samples or 0) + 1
            if N.samples == 3 or N.samples % 30 == 0 then
                print(string.format("[BFF] sky: the clock runs %.2f game hours a minute by day, %.2f by night",
                    rateAt(false) * 60, rateAt(true) * 60))
                saveCal()
            end
        end

        -- A turn of the moon seen while here: what it turned to, at what hour.
        local lastPhase
        local function feedPhase(p, c)
            if p and lastPhase and p ~= lastPhase then
                cal.succ[lastPhase] = p
                cal.flips += 1
                local inDay = c >= DAWN and c <= DUSK
                if inDay then cal.flipAt = math.floor(c * 10 + 0.5) / 10 end
                print(string.format("[BFF] sky: the moon turned %d -> %d at %s%s%s", lastPhase, p, clockText(c),
                    (p == lastPhase % 8 + 1) and "" or " (not the next number)",
                    inDay and "" or " (at night: night numbers may be off)"))
                saveCal()
            end
            if p then lastPhase = p end
        end

        -- ISLANDS, BOSSES, FRUITS ----------------------------------------
        local function isleFind(d)
            local map = workspace:FindFirstChild("Map")
            local m = (map and map:FindFirstChild(d.map)) or workspace:FindFirstChild(d.map)
            if m then return m end
            if not d.loc then return nil end
            local wo = workspace:FindFirstChild("_WorldOrigin")
            local locs = wo and wo:FindFirstChild("Locations")
            return locs and locs:FindFirstChild(d.loc) or nil
        end
        local function posOf(inst)
            local ok, pos = pcall(function()
                if inst:IsA("BasePart") then return inst.Position end
                return inst:GetPivot().Position
            end)
            return ok and pos or nil
        end
        -- One island from one look: came (at the join = age unknown), or
        -- left (how long it lasted, when its start was seen).
        local function isleFeed(st, there, now, atJoin)
            if there and not st.up then
                st.up, st.since, st.atJoin, st.goneAt, st.lasted = true, now, atJoin, nil, nil
                return "up"
            elseif not there and st.up then
                st.up, st.goneAt = false, now
                st.lasted = (not st.atJoin) and (now - st.since) or nil
                return "gone"
            end
            return nil
        end

        local function breaking(key, text, now)
            table.insert(N.events, { key = key, text = text, at = now })
            if #N.events > 16 then table.remove(N.events, 1) end
            N.breakAt = now
            print("[BFF] news: " .. text)
        end

        -- The game's answer to "CakePrinceSpawner", true (a question).
        local function cakeNote(r)
            if type(r) ~= "string" or r == "" then return nil end
            local n = tonumber(string.match(r, "%d+"))
            if n then return { left = n } end
            if string.find(string.lower(r), "portal", 1, true) then return { ready = true } end
            return nil
        end
        N.cakeNote = cakeNote

        local first, cakeAt = true, -1e9
        local fruitSeen = setmetatable({}, { __mode = "k" })
        -- One look at everything. Once a second, from load.
        function N.tick()
            local now = os.clock()
            local c = tonumber(Lighting.ClockTime) or 0
            local p, blue, src = moonRead()
            feedClock(c, now)
            feedPhase(p, c)
            local s = skyAt(c, p)
            s.blue, s.src = blue, src
            local was = N.sky
            if s.full and not (was and was.full) then
                breaking("moon", first and ((blue and "BLUE" or "FULL") .. " MOON IS UP") or "FULL MOON RISING", now)
            elseif s.blue and not (was and was.blue) and not first then
                breaking("moon", "BLUE MOON", now)
            end
            N.sky = s
            local sea = mySea()
            N.sea = sea
            if sea ~= 1 and sea ~= 2 then             -- the Third Sea, or a place id not known yet
                for _, d in ipairs(ISLES) do
                    local st = N.isles[d.key]
                    local inst = isleFind(d)
                    st.inst = inst
                    if isleFeed(st, inst ~= nil, now, first) == "up" then
                        breaking(d.key, d.title .. (first and " IS UP" or " SPAWNED"), now)
                        -- What the game put on it, once: a spawn time may be there.
                        pcall(function()
                            local list = {}
                            for k, v in pairs(inst:GetAttributes()) do table.insert(list, k .. "=" .. tostring(v)) end
                            print("[BFF] sky: " .. inst:GetFullName() .. " attributes: "
                                .. (#list > 0 and table.concat(list, ", ") or "none"))
                        end)
                    end
                end
                local found = {}
                local elites: { string } = (P :: any).ELITES or {}
                for _, list in ipairs({ elites, RAID }) do
                    for _, n in ipairs(list) do
                        local at, where = bossUp(n)
                        if at then
                            found[n] = (where == "here") and "near you" or "far off"
                            if not N.bosses[n] then breaking("boss:" .. n, string.upper(n) .. " IS UP", now) end
                        end
                    end
                end
                N.bosses = found
                local g = N.shown
                if g and g.Parent and now - cakeAt > 60 then
                    cakeAt = now
                    task.spawn(function()
                        local cf = commF()
                        local ok, r = pcall(function() return cf and cf:InvokeServer("CakePrinceSpawner", true) end)
                        if ok then N.cake = cakeNote(r) end
                    end)
                end
            end
            local fr = {}
            for _, ch in ipairs(workspace:GetChildren()) do
                if ch:IsA("Tool") and ch:GetAttribute("OriginalName") and ch:FindFirstChild("Handle") then
                    table.insert(fr, ch.Name)
                    if not fruitSeen[ch] then
                        fruitSeen[ch] = true
                        breaking("fruit", "FRUIT ON THE MAP: " .. ch.Name, now)
                    end
                end
            end
            N.fruits = fr
            first = false
        end

        -- THE NEWS --------------------------------------------------------
        -- { key, tone, title, body, breaking }, most important first; what
        -- happened in the last minute leads.
        function N.headlines(now)
            now = now or os.clock()
            local out, s = {}, N.sky
            local function add(key, tone, title, body)
                table.insert(out, { key = key, tone = tone, title = title, body = body })
            end
            if s then
                if not s.phase then
                    add("moon", "dim", s.night and "NIGHT" or "DAY", "moon phase not readable here ("
                        .. tostring(s.src) .. ") · " .. (s.night and "day in " or "night in ") .. mins(s.edge))
                elseif s.full then
                    add("moon", "full", s.blue and "BLUE MOON" or "FULL MOON", string.format(
                        "night %d/8 · %s left · race trials, Kitsune Island (Sea Danger 6), Skull Guitar",
                        s.no, mins(s.edge)))
                else
                    local when = "full moon: order not known"
                    if s.nights == 0 then when = "FULL MOON TONIGHT, rises in " .. mins(s.toFull)
                    elseif s.nights == 1 then when = "full moon NEXT NIGHT, in " .. mins(s.toFull)
                    elseif s.nights then when = string.format("full moon in %d nights, %s", s.nights, mins(s.toFull)) end
                    if s.night then
                        add("moon", "night", string.format("NIGHT %d/8", s.no),
                            string.format("%s · day in %s · %s", PHASE[s.no], mins(s.edge), when))
                    else
                        add("moon", (s.nights == 0) and "full" or "day", string.format("DAY %d/8", s.no),
                            string.format("tonight %s · night in %s · %s", PHASE[s.no], mins(s.edge), when))
                    end
                end
            end
            if N.sea ~= 1 and N.sea ~= 2 then
                local _, root = parts()
                local here = root and root.Position
                for _, d in ipairs(ISLES) do
                    local st = N.isles[d.key]
                    if st.up then
                        local bits = { st.atJoin and "already up when you joined" or ("came " .. mins(now - st.since) .. " ago") }
                        if d.life then
                            local left = d.life - (now - st.since)
                            table.insert(bits, st.atJoin and ("lives " .. mins(d.life) .. " at most")
                                or (left > 0 and ("gone within " .. mins(left)) or ("up longer than " .. mins(d.life))))
                        end
                        local pos = st.inst and posOf(st.inst)
                        if pos and here then
                            -- The island's MIDDLE (user, 2026-10-07, read it as
                            -- the dealer's distance): said so.
                            table.insert(bits, string.format("its middle %d studs away", math.floor((pos - here).Magnitude + 0.5)))
                        end
                        -- The dealer's own distance, when the client holds him.
                        local sea = (P :: any).sea
                        local dl = (d.key == "mirage" and here and sea and sea.findDealer)
                            and sea.findDealer(st.inst, nil, false) or nil
                        if dl then
                            table.insert(bits, string.format("Advanced Fruit Dealer %d studs away (his hunt takes you to him)",
                                math.floor((dl.cf.Position - here).Magnitude + 0.5)))
                        end
                        table.insert(bits, dl and "Blue Gear at night" or d.why)
                        add(d.key, "up", d.title .. " UP", table.concat(bits, " · "))
                    elseif st.goneAt and now - st.goneAt < 300 then
                        add(d.key, "dim", d.title .. " GONE", "left " .. mins(now - st.goneAt) .. " ago"
                            .. (st.lasted and (", after " .. mins(st.lasted)) or ""))
                    elseif d.always then
                        add(d.key, "dim", "NO " .. d.title, "")
                    elseif d.key == "kitsune" and s and (s.full or s.nights == 0) then
                        add(d.key, "dim", "NO KITSUNE ISLAND", s.full and "full moon up: a boat in Sea Danger 6 spawns it"
                            or "it comes only with the full moon - tonight")
                    end
                end
                local anyElite = false
                local elites: { string } = (P :: any).ELITES or {}
                for _, n in ipairs(elites) do
                    if N.bosses[n] then
                        anyElite = true
                        add("boss:" .. n, "up", "ELITE UP", n .. ", " .. N.bosses[n])
                    end
                end
                if not anyElite then add("elite", "dim", "NO ELITE", "Diablo, Deandre, Urban: none up") end
                for _, n in ipairs(RAID) do
                    if N.bosses[n] then add("boss:" .. n, "up", string.upper(n) .. " UP", N.bosses[n]) end
                end
                local ck = N.cake
                if ck and not N.bosses["Cake Prince"] and not N.bosses["Dough King"] then
                    if ck.left then add("cake", "dim", "CAKE PRINCE", ck.left .. " kills to go")
                    elseif ck.ready then add("cake", "up", "CAKE PRINCE", "ready - the portal can open") end
                end
            end
            if #N.fruits > 0 then
                local names = {}
                for i = 1, math.min(3, #N.fruits) do names[i] = N.fruits[i] end
                add("fruit", "up", "FRUIT ON THE MAP", table.concat(names, ", ")
                    .. ((#N.fruits > 3) and (" +" .. (#N.fruits - 3)) or ""))
            end
            add("server", "dim", "SERVER", string.format("%d/%d players · you joined %s ago",
                #Players:GetPlayers(), Players.MaxPlayers, mins(workspace.DistributedGameTime)))
            local hot = {}
            for _, e in ipairs(N.events) do
                if now - e.at < 60 then hot[e.key] = true end
            end
            local lead, rest = {}, {}
            for _, it in ipairs(out) do
                if hot[it.key] then
                    it.breaking = true
                    table.insert(lead, it)
                else
                    table.insert(rest, it)
                end
            end
            for _, it in ipairs(rest) do table.insert(lead, it) end
            return lead
        end

        -- The chip: word, time (m:ss), tone. BREAKING for 8 s after news,
        -- else the full moon's time left / the day's time to it, else the
        -- day or night number and the time to the next dusk or dawn.
        function N.chip(now)
            now = now or os.clock()
            if N.breakAt and now - N.breakAt < 8 then return "BREAKING", "", "breaking" end
            local s = N.sky
            if not s then return "SKY", "", "dim" end
            if s.full then return s.blue and "BLUE MOON" or "FULL MOON", dur(s.edge), "full" end
            if not s.night and s.nights == 0 then return "FULL IN", dur(s.edge), "full" end
            return (s.night and "NIGHT" or "DAY") .. (s.no and (" " .. s.no) or ""), dur(s.edge),
                s.night and "night" or "day"
        end
    end
    build()
end

-- =========================================================
-- PANEL
-- =========================================================
-- farm_pro's panel piece for piece -- the same switches that say On or Off,
-- the same sliders, choosers and readouts, the same colours -- with one
-- change: it is OPAQUE. farm_pro's carried a UIGradient meant as a faint
-- sheen, and a UIGradient's transparency is applied TO its own frame, so that
-- panel was 94-100% see-through and every row was text over the game world.
-- Solid background, solid dividers, solid list rows.
local gui
local function buildUI()
    local pg = player:WaitForChild("PlayerGui", 10)
    if not pg then return end
    local old = pg:FindFirstChild("BFFHUD")
    if old then old:Destroy() end

    local UIS = game:GetService("UserInputService")

    local C = {
        base    = Color3.fromRGB(18, 17, 16),
        raised  = Color3.fromRGB(31, 29, 27),
        pressed = Color3.fromRGB(42, 39, 36),
        hair    = Color3.fromRGB(53, 50, 46),
        -- Opaque stand-ins for what used to be see-through: the divider
        -- is hair at 50% over base, a list row is raised at 65% over base.
        line    = Color3.fromRGB(36, 34, 31),
        row     = Color3.fromRGB(27, 25, 23),
        text    = Color3.fromRGB(242, 239, 234),
        second  = Color3.fromRGB(154, 149, 141),
        third   = Color3.fromRGB(107, 102, 95),
        ivory   = Color3.fromRGB(232, 224, 212),
        live    = Color3.fromRGB(63, 208, 126),
        warn    = Color3.fromRGB(240, 166, 60),
        stop    = Color3.fromRGB(232, 92, 78),
    }
    local F = { tiny = 11, small = 13, body = 14, label = 15, subject = 21 }

    local function mk(class, props)
        local o = Instance.new(class)
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do o[k] = v end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(o, r)
        mk("UICorner", { CornerRadius = UDim.new(0, r), Parent = o })
        return o
    end
    local EASE  = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local QUICK = TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local function tween(o, props, info)
        TweenService:Create(o, info or EASE, props):Play()
    end

    gui = mk("ScreenGui", {
        Name = "BFFHUD", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 45, Parent = pg,
    })

    -- 30 px taller than farm_pro's: the server news strip under the title.
    local panel = mk("Frame", {
        Size = UDim2.fromOffset(342, 570),
        Position = UDim2.new(1, -360, 0, 18),
        BackgroundColor3 = C.base, BorderSizePixel = 0,
        Active = true, Draggable = true, Parent = gui,
    })
    corner(panel, 20)
    mk("UIStroke", { Color = C.hair, Transparency = 0.45, Parent = panel })
    -- No UIGradient: its transparency applied to the panel itself and
    -- made farm_pro's background 94-100% see-through.

    local backBtn = mk("TextButton", {
        Size = UDim2.fromOffset(54, 30), Position = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.second, Text = "Back", Visible = false,
        AutoButtonColor = false, Parent = panel,
    })
    local heading = mk("TextLabel", {
        Size = UDim2.new(1, -104, 0, 22), Position = UDim2.fromOffset(20, 18),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = F.label, TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = C.text, Text = "Fast Farm  ·  " .. tostring(P.build), Parent = panel,
    })
    local dot = mk("Frame", {
        Size = UDim2.fromOffset(7, 7), Position = UDim2.new(1, -62, 0, 26),
        BackgroundColor3 = C.third, BorderSizePixel = 0, Parent = panel,
    })
    corner(dot, 4)
    local foldBtn = mk("TextButton", {
        Size = UDim2.fromOffset(42, 30), Position = UDim2.new(1, -52, 0, 14),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = C.second, Text = "Hide", AutoButtonColor = false, Parent = panel,
    })

    local bodyFrame = mk("Frame", {
        Size = UDim2.new(1, 0, 1, -82), Position = UDim2.fromOffset(0, 82),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = panel,
    })

    -- THE NEWS STRIP (P.news): under the title, outside the body, so Hide
    -- keeps it. A chip that holds still -- the day or night number and the
    -- time to the next dusk or dawn, or the full moon's -- and a crawl
    -- moving left. News starts the crawl over with it in front. Its own
    -- function: buildUI's registers are its own business.
    local function newsStrip()
        local N = P.news
        if not N then return end
        local W, H, CHIP = 314, 26, 122
        local strip = mk("Frame", {
            Size = UDim2.fromOffset(W, H), Position = UDim2.fromOffset(14, 50),
            BackgroundColor3 = C.row, BorderSizePixel = 0, ClipsDescendants = true, Parent = panel,
        })
        corner(strip, 8)
        local chip = mk("Frame", {
            Size = UDim2.fromOffset(CHIP, H), BackgroundColor3 = C.pressed,
            BorderSizePixel = 0, Parent = strip,
        })
        corner(chip, 8)
        local word = mk("TextLabel", {
            Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.text, Text = "", Parent = chip,
        })
        -- Code: its digits are all one width, so the seconds do not jitter.
        local clock = mk("TextLabel", {
            Size = UDim2.new(1, -8, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code,
            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.text,
            Text = "", Parent = chip,
        })
        local clip = mk("Frame", {
            Size = UDim2.fromOffset(W - CHIP - 6, H), Position = UDim2.fromOffset(CHIP + 6, 0),
            BackgroundTransparency = 1, ClipsDescendants = true, Parent = strip,
        })
        -- Two copies of the crawl, one after the other: it loops seamlessly.
        local function crawlLine()
            return mk("TextLabel", {
                Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
                RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.text, Text = "", Parent = clip,
            })
        end
        local lineA, lineB = crawlLine(), crawlLine()

        local TONES = {
            day = { C.ivory, C.base }, night = { Color3.fromRGB(52, 56, 84), C.ivory },
            full = { C.warn, C.base }, breaking = { C.stop, C.text }, dim = { C.pressed, C.second },
        }
        local HEX = { breaking = "#E85C4E", full = "#F0A63C", up = "#3FD07E", night = "#B4BAE6",
            day = "#E8E0D4", dim = "#9A958D" }
        local SEP = '   <font color="#6B665F">·</font>   '
        local function esc(s)
            return (string.gsub(tostring(s), "[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
        end
        local function compose()
            local bits = {}
            for _, it in ipairs(N.headlines()) do
                local t = string.format('<font color="%s"><b>%s</b></font>', HEX[it.tone] or "#F2EFEA", esc(it.title))
                if it.body and it.body ~= "" then t = t .. "  " .. esc(it.body) end
                if it.breaking then t = '<font color="#E85C4E"><b>BREAKING</b></font>  ' .. t end
                table.insert(bits, t)
            end
            return table.concat(bits, SEP) .. SEP
        end

        local myGui = gui
        N.shown = myGui                 -- Cake Prince is asked only while this is on screen
        local SPEED = 42                -- px a second
        local x, text, seenBreak, since = W - CHIP - 6, nil, N.breakAt, 1
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            if not (myGui and myGui.Parent) then
                conn:Disconnect()
                return
            end
            since += dt
            if since >= 0.5 then
                since = 0
                pcall(function()
                    local w, t, tone = N.chip()
                    local tt = TONES[tone] or TONES.dim
                    word.Text, clock.Text = w, t
                    chip.BackgroundColor3, word.TextColor3, clock.TextColor3 = tt[1], tt[2], tt[2]
                    local nt = compose()
                    if nt ~= text then
                        text = nt
                        lineA.Text, lineB.Text = nt, nt
                    end
                    if N.breakAt ~= seenBreak then
                        seenBreak = N.breakAt
                        x = clip.AbsoluteSize.X           -- start over from the right, the news in front
                    end
                end)
            end
            local wA = lineA.TextBounds.X
            if wA > 0 then
                x -= SPEED * dt
                if x < -wA then x += wA end
                lineA.Position = UDim2.fromOffset(math.floor(x), 0)
                lineB.Position = UDim2.fromOffset(math.floor(x + wA), 0)
            end
        end)
    end
    newsStrip()

    local folded = false
    foldBtn.Activated:Connect(function()
        folded = not folded
        bodyFrame.Visible = not folded
        foldBtn.Text = folded and "Show" or "Hide"
        -- Folded: the title and the news strip stay.
        tween(panel, { Size = UDim2.fromOffset(342, folded and 82 or 570) })
    end)

    local live = {}
    local buildingView = nil
    local function addLive(fn) table.insert(live, { v = buildingView, f = fn }) end

    local views = {}
    local currentView = "home"

    local function makeView(name)
        local v = mk("ScrollingFrame", {
            Name = name,
            Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = C.hair,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false, Parent = bodyFrame,
        })
        mk("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = v,
        })
        mk("UIPadding", { PaddingBottom = UDim.new(0, 16), Parent = v })
        views[name] = v
        buildingView = v
        return v
    end

    local TITLES = {
        home = "Fast Farm  ·  " .. tostring(P.build), target = "Targets", attack = "Attack", weapon = "Weapon",
        magnet = "Magnet", position = "Position", travel = "Travel",
        safety = "Safety", stats = "Stats",
        elite = "Hunt",
    }

    local function show(name, back)
        if name == currentView then return end
        local from, to = views[currentView], views[name]
        if not to then return end
        to.Position = UDim2.fromScale(back and -1 or 1, 0)
        to.Visible = true
        tween(to, { Position = UDim2.fromScale(0, 0) })
        if from then
            tween(from, { Position = UDim2.fromScale(back and 1 or -1, 0) })
            task.delay(0.24, function()
                if currentView ~= from.Name then from.Visible = false end
            end)
        end
        currentView = name
        heading.Text = TITLES[name] or name
        heading.Position = UDim2.fromOffset(name == "home" and 20 or 76, 18)
        backBtn.Visible = (name ~= "home")
    end
    backBtn.Activated:Connect(function()
        show(currentView == "weapon" and "attack" or "home", true)
    end)

    -- =====================================================
    -- PIECES
    -- =====================================================
    local order = 0
    local function nextOrder() order += 1 return order end

    local function gap(view, h)
        mk("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = view,
        })
    end

    local function heading2(view, text)
        local t = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium, TextSize = F.tiny,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.third,
            Text = string.upper(text), LayoutOrder = nextOrder(), Parent = view,
        })
        mk("UIPadding", { PaddingLeft = UDim.new(0, 20), Parent = t })
        return t
    end

    local function hairline(view)
        local holder = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = view,
        })
        mk("Frame", {
            Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(20, 0),
            BackgroundColor3 = C.line, BackgroundTransparency = 0,
            BorderSizePixel = 0, Parent = holder,
        })
        return holder
    end

    local function pressable(btn)
        local base = btn.BackgroundColor3
        btn.MouseButton1Down:Connect(function()
            tween(btn, { BackgroundColor3 = C.pressed }, QUICK)
        end)
        local function release() tween(btn, { BackgroundColor3 = base }, QUICK) end
        btn.MouseButton1Up:Connect(release)
        btn.MouseLeave:Connect(release)
        return btn
    end

    local function caption(view, text)
        local t = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = F.small,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.third,
            TextWrapped = true, Text = text, LayoutOrder = nextOrder(), Parent = view,
        })
        mk("UIPadding", {
            PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), Parent = t,
        })
        gap(view, 6)
        return t
    end

    -- A line that reports what the last action actually did, and keeps
    -- reporting it. This is what a momentary button owes you.
    local function readout(view, fn)
        local t = mk("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = F.small,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.second,
            TextWrapped = true, Text = "", LayoutOrder = nextOrder(), Parent = view,
        })
        mk("UIPadding", {
            PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), Parent = t,
        })
        gap(view, 8)
        addLive(function()
            local ok, v = pcall(fn)
            t.Text = ok and tostring(v or "") or ""
        end)
        return t
    end

    local function navRow(view, label, valueFn, target)
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.base,
            BorderSizePixel = 0, Text = "", AutoButtonColor = false,
            LayoutOrder = nextOrder(), Parent = view,
        })
        mk("TextLabel", {
            Size = UDim2.new(0, 116, 1, 0), Position = UDim2.fromOffset(20, 0),
            BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
            TextSize = F.label, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = C.text, Text = label, Parent = b,
        })
        local val = mk("TextLabel", {
            Size = UDim2.new(1, -176, 1, 0), Position = UDim2.fromOffset(136, 0),
            BackgroundTransparency = 1, Font = Enum.Font.Gotham,
            TextSize = F.body, TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = C.second, TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "", Parent = b,
        })
        mk("TextLabel", {
            Size = UDim2.fromOffset(20, 48), Position = UDim2.new(1, -28, 0, 0),
            BackgroundTransparency = 1, Font = Enum.Font.Gotham,
            TextSize = 14, TextColor3 = C.third, Text = ">", Parent = b,
        })
        pressable(b)
        b.Activated:Connect(function() show(target) end)
        if valueFn then
            addLive(function()
                local ok, v = pcall(valueFn)
                val.Text = ok and tostring(v) or ""
            end)
        end
        return b
    end

    -- THE SWITCH.
    -- Pill, knob, AND the word. The word is the point: a pill on its own still
    -- asks you to remember which side means on.
    local function switchRow(view, label, sub, get, set)
        local h = sub and 60 or 48
        local f = mk("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = view,
        })
        mk("TextLabel", {
            Size = UDim2.new(1, -132, 0, 20),
            Position = UDim2.fromOffset(20, sub and 9 or 14),
            BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
            TextSize = F.label, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = C.text, Text = label, Parent = f,
        })
        if sub then
            mk("TextLabel", {
                Size = UDim2.new(1, -132, 0, 16), Position = UDim2.fromOffset(20, 30),
                BackgroundTransparency = 1, Font = Enum.Font.Gotham,
                TextSize = F.small, TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = C.third, Text = sub, Parent = f,
            })
        end
        local word = mk("TextLabel", {
            Size = UDim2.fromOffset(30, 20),
            Position = UDim2.new(1, -106, 0, (h - 20) / 2),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
            TextSize = F.small, TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = C.third, Text = "Off", Parent = f,
        })
        local pill = mk("TextButton", {
            Size = UDim2.fromOffset(46, 27),
            Position = UDim2.new(1, -66, 0, (h - 27) / 2),
            BackgroundColor3 = C.hair, Text = "", AutoButtonColor = false, Parent = f,
        })
        corner(pill, 13)
        local knob = mk("Frame", {
            Size = UDim2.fromOffset(23, 23), Position = UDim2.fromOffset(2, 2),
            BackgroundColor3 = C.text, BorderSizePixel = 0, Parent = pill,
        })
        corner(knob, 11)
        local function redraw()
            local on = get() and true or false
            tween(pill, { BackgroundColor3 = on and C.live or C.hair }, QUICK)
            tween(knob, { Position = UDim2.fromOffset(on and 21 or 2, 2) }, QUICK)
            word.Text = on and "On" or "Off"
            word.TextColor3 = on and C.live or C.third
        end
        pill.Activated:Connect(function() set(not get()) redraw() end)
        addLive(redraw)
        redraw()
        return f
    end

    -- THE HUNTS: one switch each, one at a time. On = that hunt and nothing
    -- else (the others go off); off = no hunt.
    local HUNTS = {
        { "elite", "Elite pirate hunt", "Diablo, Deandre, Urban - last hit, God's Chalice" },
        { "fruit", "Fruit hunt",        "Fruits on the ground - grabbed and STORED, never eaten" },
        { "berry", "Berry hunt",        "Haki colors - Legendary Aura berries" },
        { "recipe", "Aura recipe hunt", "Barista Cousin - the recipe you pick, else the next server" },
        { "flower", "Fire Flower hunt", "Draco V2 - pirates one at a time, the flower, next server" },
        { "ember", "Blaze Ember hunt",  "Dragon Hunter quests on Hydra Island, over and over - the embers picked" },
        -- Sea travel (user, 2026-10-10): the hunts' fast boat with no target.
        { "sail", "Sea travel", "Your boat at sea speed, you steer (A/D turn, W go, S stop) - no island, never the next server" },
        { "prehistoric", "Prehistoric hunt", "Sail to the island, run the volcano event, loot, next server - the loop" },
        -- The Mirage (user, 2026-10-07): four hunts, each only its job. One
        -- up already = straight to the job; none = the boat sails for one.
        { "mirage", "Mirage hunt", "Sail till a Mirage comes, onto it - nothing else" },
        { "dealer", "Advanced Fruit Dealer hunt", "On the Mirage: in front of him, his shop open - you buy" },
        { "mchest", "Mirage chest hunt", "On the Mirage: every chest, nearest first" },
        { "gear", "Blue Gear hunt", "On the Mirage: your turn at the moon, the gear picked when it shows" },
        { "seaevents", "Sea events hunt", "Beasts, Rumbling Waters, Terrorshark, Piranha fought - ship raids fled - counted" },
    }
    local function huntSwitches(view)
        for _, h in ipairs(HUNTS) do
            local kind = h[1]
            switchRow(view, h[2], h[3],
                function() return CFG.Hunt and CFG.HuntKind == kind end,
                function(x)
                    if x then P.setHunt(true, kind)
                    elseif CFG.HuntKind == kind then P.setHunt(false) end
                end)
        end
    end

    local dragTarget = nil
    UIS.InputChanged:Connect(function(i)
        if dragTarget and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            dragTarget(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragTarget = nil
        end
    end)

    local function sliderRow(view, label, minV, maxV, stepV, get, set, unit)
        local f = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false,
            LayoutOrder = nextOrder(), Parent = view,
        })
        mk("TextLabel", {
            Size = UDim2.new(1, -130, 0, 20), Position = UDim2.fromOffset(20, 10),
            BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
            TextSize = F.label, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = C.text, Text = label, Parent = f,
        })
        local val = mk("TextLabel", {
            Size = UDim2.fromOffset(110, 20), Position = UDim2.new(1, -130, 0, 10),
            BackgroundTransparency = 1, Font = Enum.Font.Code,
            TextSize = F.body, TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = C.second, Text = "", Parent = f,
        })
        local track = mk("Frame", {
            Size = UDim2.new(1, -40, 0, 4), Position = UDim2.fromOffset(20, 42),
            BackgroundColor3 = C.hair, BorderSizePixel = 0, Parent = f,
        })
        corner(track, 2)
        local fill = mk("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.ivory,
            BorderSizePixel = 0, Parent = track,
        })
        corner(fill, 2)
        local knob = mk("Frame", {
            Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.ivory,
            BorderSizePixel = 0, ZIndex = 2, Parent = track,
        })
        corner(knob, 8)

        local function redraw()
            local v = tonumber(get()) or minV
            local a = math.clamp((v - minV) / math.max(maxV - minV, 0.001), 0, 1)
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            val.Text = ((stepV < 1) and string.format("%.2f", v) or tostring(math.floor(v)))
                .. (unit or "")
        end
        local function apply(x)
            local a = math.clamp((x - track.AbsolutePosition.X)
                / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = math.clamp(math.floor((minV + a * (maxV - minV)) / stepV + 0.5) * stepV,
                minV, maxV)
            if stepV < 1 then v = tonumber(string.format("%.2f", v)) end
            set(v)
            redraw()
        end
        f.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                dragTarget = apply
                tween(knob, { Size = UDim2.fromOffset(20, 20) }, QUICK)
                apply(i.Position.X)
            end
        end)
        f.InputEnded:Connect(function()
            tween(knob, { Size = UDim2.fromOffset(16, 16) }, QUICK)
        end)
        addLive(redraw)
        redraw()
        return f
    end

    local function actionRow(view, label, tone, cb)
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.base,
            BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = F.label,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = (tone == "danger") and C.stop or C.ivory, Text = label,
            AutoButtonColor = false, LayoutOrder = nextOrder(), Parent = view,
        })
        mk("UIPadding", { PaddingLeft = UDim.new(0, 20), Parent = b })
        pressable(b)
        b.Activated:Connect(function() task.spawn(function() pcall(cb, b) end) end)
        return b
    end

    local function textRow(view, placeholder, cb)
        local f = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1,
            LayoutOrder = nextOrder(), Parent = view,
        })
        local tb = mk("TextBox", {
            Size = UDim2.new(1, -40, 0, 36), Position = UDim2.fromOffset(20, 8),
            BackgroundColor3 = C.raised, BorderSizePixel = 0,
            ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = F.body,
            TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
            PlaceholderText = placeholder, PlaceholderColor3 = C.third,
            Text = "", Parent = f,
        })
        corner(tb, 10)
        mk("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = tb })
        tb.FocusLost:Connect(function(enter)
            if enter then
                pcall(cb, (tb.Text:gsub("^%s+", ""):gsub("%s+$", "")), tb)
            end
        end)
        return tb
    end

    -- A LIST YOU PICK ONE THING FROM.
    -- Radio, not a cycle. Tapping a row selects it; the selected row is filled
    -- ivory and carries a tick. There is no second tap that means something
    -- else, because that is the state you cannot see.
    local function chooser(view, height)
        local box = mk("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = C.hair,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            LayoutOrder = nextOrder(), Parent = view,
        })
        mk("UIListLayout", { Padding = UDim.new(0, 3), Parent = box })
        mk("UIPadding", {
            PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), Parent = box,
        })
        gap(view, 10)
        return box
    end

    local function chooserRow(box, i, label, tag, chosen, cb)
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = chosen and C.ivory or C.row,
            BackgroundTransparency = 0, BorderSizePixel = 0,
            Font = chosen and Enum.Font.GothamBold or Enum.Font.Gotham,
            TextSize = F.body, TextColor3 = chosen and C.base or C.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = (chosen and "  > " or "      ") .. label,
            AutoButtonColor = false, LayoutOrder = i, Parent = box,
        })
        corner(b, 9)
        if tag and tag ~= "" then
            mk("TextLabel", {
                Size = UDim2.fromOffset(104, 38), Position = UDim2.new(1, -114, 0, 0),
                TextTruncate = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
                TextSize = F.small, TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = chosen and C.base or C.third, Text = tag, Parent = b,
            })
        end
        if not chosen then pressable(b) end
        b.Activated:Connect(function() pcall(cb) end)
        return b
    end

    -- A RADIO: one of a few, the chosen one filled ivory. Rebuilt only when
    -- the choice changes.
    local function radio(view, height, options, get, set)
        local box = chooser(view, height)
        local sig = nil
        local function refresh()
            local cur = get()
            if tostring(cur) == sig then return end
            sig = tostring(cur)
            for _, c in ipairs(box:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            for i, o in ipairs(options) do
                chooserRow(box, i, o[2], o[3], cur == o[1], function()
                    set(o[1])
                    sig = nil
                    refresh()
                end)
            end
        end
        refresh()
        addLive(refresh)
        return box
    end

    local function mmss(s)
        s = math.max(0, s or 0)
        return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
    end

    local editW = nil        -- the weapon the Weapon page is showing

    -- =====================================================
    -- HOME
    -- =====================================================
    do
        local v = makeView("home")
        v.Visible = true
        v.Position = UDim2.fromScale(0, 0)
        gap(v, 4)

        local subject = mk("TextLabel", {
            Size = UDim2.new(1, -40, 0, 26), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = F.subject,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.text,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = "Idle",
            LayoutOrder = nextOrder(), Parent = v,
        })
        mk("UIPadding", { PaddingLeft = UDim.new(0, 20), Parent = subject })

        local detail = mk("TextLabel", {
            Size = UDim2.new(1, -40, 0, 18), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = F.small,
            TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C.second,
            TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
            LayoutOrder = nextOrder(), Parent = v,
        })
        mk("UIPadding", { PaddingLeft = UDim.new(0, 20), Parent = detail })

        addLive(function()
            if P.running then
                subject.Text = tostring(activeName or "Fast farm")
                local mins = math.max((os.clock() - stats.startedAt) / 60, 1 / 60)
                detail.Text = string.format("%s  ·  %d kills  ·  %.0f/min  ·  %s",
                    state, stats.kills, stats.kills / mins, statusLine)
            else
                subject.Text = "Idle"
                detail.Text = statusLine
            end
        end)

        gap(v, 14)

        local hero = mk("TextButton", {
            Size = UDim2.new(1, -40, 0, 52), BackgroundColor3 = C.ivory,
            BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 16,
            TextColor3 = C.base, Text = "Start", AutoButtonColor = false,
            LayoutOrder = nextOrder(), Parent = v,
        })
        corner(hero, 14)
        hero.Activated:Connect(function()
            if P.running then P.stop() else P.start() end
        end)
        hero.MouseButton1Down:Connect(function()
            tween(hero, { Size = UDim2.new(1, -46, 0, 50) }, QUICK)
        end)
        local function heroUp() tween(hero, { Size = UDim2.new(1, -40, 0, 52) }, QUICK) end
        hero.MouseButton1Up:Connect(heroUp)
        hero.MouseLeave:Connect(heroUp)
        addLive(function()
            hero.Text = P.running and "Stop" or "Start"
            hero.BackgroundColor3 = P.running and C.stop or C.ivory
            hero.TextColor3 = P.running and C.text or C.base
        end)

        gap(v, 16)

        switchRow(v, "Raid mode",
            "Every enemy on the raid's island, any kind - outside a raid you stay where you are",
            function() return CFG.RaidMode end,
            function(x)
                if x and CFG.Hunt then P.setHunt(false) end
                CFG.RaidMode = x
                if x then CFG.RandomMode = false end
                releasePile()
                say(x and "raid mode on" or "raid mode off - back to the circuit")
            end)
        switchRow(v, "Raid loop",
            "Raid over: a chip for your cheapest stored fruit, the button, again - else you stay",
            function() return CFG.RaidLoop end,
            function(x)
                CFG.RaidLoop = x
                if x and P.raid then P.raid.loop.nextAt = 0 end
            end)
        switchRow(v, "Random mode",
            "Any enemy near you, every one damaged - Castle on the Sea raid",
            function() return CFG.RandomMode end,
            function(x)
                if x and CFG.Hunt then P.setHunt(false) end
                CFG.RandomMode = x
                if x then CFG.RaidMode = false end
                releasePile()
                say(x and "random mode on" or "random mode off - back to the circuit")
            end)
        huntSwitches(v)
        switchRow(v, "Volcano event",
            "Prehistoric Island up: start it, vents + Lava Golems, bones + egg",
            function() return CFG.Volcano end,
            function(x)
                CFG.Volcano = x
                say(x and "volcano event on - whenever a Prehistoric Island is up" or "volcano event off")
            end)
        switchRow(v, "Leviathan fight",
            "On = only the Leviathan: segments, then the head; its attacks dodged; starts the run",
            function() return CFG.LeviFight end,
            function(x)
                CFG.LeviFight = x
                if x and not P.running then P.start() end
                say(x and "Leviathan fight on - only the Leviathan now" or "Leviathan fight off")
            end)
        readout(v, function()
            local lv = P.seaev and P.seaev.levi
            if CFG.LeviFight and lv then
                return "LEVIATHAN  " .. tostring(lv.note) .. string.format("\n%d Leviathans down  ·  %d dodges",
                    lv.kills, P.seaev.dodges or 0)
            end
            if CFG.Volcano and P.sea.ev then
                local ev = P.sea.ev
                return string.format("VOLCANO  %s\n%d vents closed  ·  %d golems down  ·  %d bones  ·  %d eggs",
                    tostring(ev.note), ev.vents, ev.golems, ev.bones, ev.eggs)
            end
            if CFG.Hunt then
                local t = P.elite.tally
                local k = CFG.HuntKind
                local count = P.sea.MIRAGE_HUNT[k] and string.format("%d Mirages  ·  %d dealers  ·  %d chests  ·  %d Blue Gears  ·  %s",
                        P.sea.tally.mirages, P.sea.tally.dealers, P.sea.tally.chests, P.sea.tally.gears,
                        P.handsOff and "YOUR TURN - the character is yours"
                            or (P.sea.mirage and "on the Mirage")
                            or (P.sea.meters and string.format("%d m from Tiki", math.floor(P.sea.meters)) or "not sailing"))
                    or (k == "seaevents") and string.format("%d of %d sea events  ·  Spy: %s", P.seaev.count.total,
                        math.max(1, math.floor(tonumber(CFG.SeaEvGoal) or 20)),
                        P.seaev.spy and tostring(P.seaev.spy.text) or "not asked yet")
                    or (k == "prehistoric") and string.format("%d islands found  ·  %s", P.sea.tally.found,
                        P.sea.meters and string.format("%d m from Tiki", math.floor(P.sea.meters)) or "not sailing")
                    or (k == "sail") and ((P.sea.driving and P.sea.meters) and string.format("%d m from Tiki  ·  danger %s",
                        math.floor(P.sea.meters), tostring(P.sea.danger or "?")) or "not sailing")
                    or (k == "fruit") and string.format("%d fruits stored", t.fruits or 0)
                    or (k == "berry") and string.format("%d berries picked", t.berries or 0)
                    or (k == "recipe") and string.format("%d recipes learned  ·  here: %s", t.recipes or 0,
                        tostring(P.elite.offer or "not asked yet"))
                    or (k == "ember") and string.format("%d Blaze Embers  ·  you have %s", P.ember.tally.embers,
                        P.ember.have and tostring(P.ember.have) or "?")
                    or (k == "flower") and string.format("%d Fire Flowers picked  ·  you have %s", t.flowers or 0,
                        P.elite.flowerHave and tostring(P.elite.flowerHave) or "?")
                    or string.format("%d elites down  ·  %d chalice", t.kills, t.chalices)
                return string.format("%s\n%d joined  ·  %s", tostring(P.elite.note), t.joins, count)
            end
            if CFG.RandomMode then return tostring(P.randomNote) end
            if CFG.RaidMode then return tostring(P.raidNote) end
            return "raid mode off  ·  random mode off  ·  hunt off"
        end)

        gap(v, 8)

        navRow(v, "Targets", function()
            local list = circuit()
            if #list == 0 then return "none" end
            if #CFG.Targets == 0 then return list[1].name .. "  by level" end
            return #list .. " on the circuit"
        end, "target")
        hairline(v)
        navRow(v, "Attack", function()
            local s = setupKey()
            for _, n in ipairs(CFG.WeaponOrder) do
                local w = CFG.Weapons[n]
                if w and w.use then
                    for _, k in ipairs(KEYS) do if w[k] then return s end end
                end
            end
            return s .. "  ·  no skills on"
        end, "attack")
        hairline(v)
        navRow(v, "Magnet", function()
            if not CFG.Magnet then return "Off" end
            return P.running and (P.pileHeld .. " held") or "On"
        end, "magnet")
        hairline(v)
        navRow(v, "Position", function()
            if CFG.HeightMode == "fixed" then return math.floor(CFG.HeightFixed) .. " up, fixed" end
            return "auto  ·  " .. math.floor(CFG.HeightSafe) .. " up" .. (CFG.StayHigh and ", always" or "")
        end, "position")
        hairline(v)
        navRow(v, "Travel", function()
            return math.floor(CFG.TravelSpeed) .. " studs/s"
        end, "travel")
        hairline(v)
        navRow(v, "Safety", function()
            return "out under " .. math.floor(CFG.EscapeBelow * 100) .. "%"
        end, "safety")
        hairline(v)
        navRow(v, "Hunt", function()
            if P.elite.chalice then return "CHALICE - stopped" end
            if not CFG.Hunt then return "Off" end
            return tostring(CFG.HuntKind) .. (CFG.HuntHop and ", hopping" or ", this server")
        end, "elite")
        hairline(v)
        navRow(v, "Sea", function()
            local s = P.sea
            if CFG.Hunt and CFG.HuntKind == "seaevents" then
                return string.format("sea events  ·  %d of %d", P.seaev.count.total,
                    math.max(1, math.floor(tonumber(CFG.SeaEvGoal) or 20)))
            end
            if s.driving and s.meters then return string.format("sailing  ·  %d m", math.floor(s.meters)) end
            return math.floor(CFG.SeaSpeed) .. " studs/s  ·  to " .. math.floor(CFG.SeaSearchTo) .. " m"
                .. (CFG.Volcano and "  ·  volcano on" or "")
        end, "sea")
        hairline(v)
        navRow(v, "Stats", function()
            local m = meas
            if m and m.fight > 5 then
                return string.format("%.1f kills/min", m.kills / (m.fight / 60))
            end
            return stats.kills .. " killed"
        end, "stats")

        gap(v, 10)
    end

    -- =====================================================
    -- TARGETS
    -- =====================================================
    do
        local v = makeView("target")
        gap(v, 6)
        heading2(v, "the circuit, in order")
        caption(v, "Tap to put a species on the circuit, tap again to take it "
            .. "off. The number is the order it runs in. Nothing picked = the "
            .. "species for your level, alone.")
        readout(v, function()
            local list = circuit()
            if #list == 0 then return P.circuitNote end
            local bits = {}
            for i, t in ipairs(list) do table.insert(bits, i .. " " .. t.name) end
            local s = table.concat(bits, "  >  ")
            if #CFG.Targets == 0 then s = s .. "   (by level)" end
            if P.circuitSkipped and #P.circuitSkipped > 0 then
                s = s .. "\nanother sea, skipped: " .. table.concat(P.circuitSkipped, ", ")
            end
            for _, t in ipairs(list) do
                if P.campNotes[t.name] then s = s .. "\n" .. P.campNotes[t.name] end
            end
            return s
        end)

        local box = chooser(v, 230)
        local signature = nil
        local function refresh()
            local counts = P.nearbyNames()
            local _, r = parts()
            local here = r and r.Position
            local sea = mySea()
            local cand, seen = {}, {}
            local function add(n)
                if seen[n] then return end
                seen[n] = true
                local row = rowOf(n)
                local d = (row and here) and (row[4] - here).Magnitude or 1e9
                if counts[n] then d = math.min(d, 0) end
                table.insert(cand, { name = n, d = d, far = row and here and (row[4] - here).Magnitude })
            end
            for _, n in ipairs(CFG.Targets) do add(n) end
            for n in pairs(counts) do add(n) end
            if here then
                for _, row in ipairs(LEVELS) do
                    if (not sea or seaOfLevel(row[1]) == sea) and (row[4] - here).Magnitude < 2500 then
                        add(row[3])
                    end
                end
            end
            local lr = levelRow()
            if lr then add(lr[3]) end
            -- The quest bosses of this sea, under the name the game has now.
            local lv = playerLevel()
            local bossTag = {}
            for _, rec in ipairs(P.bosses) do
                if not sea or seaOfLevel(rec.lv) == sea then
                    -- Which of its names the game has now: looked up every 10 s.
                    if #rec.names > 1 and os.clock() - (rec.shownAt or -99) > 10 then
                        rec.shownAt, rec.shown = os.clock(), nil
                        for _, n in ipairs(rec.names) do
                            if counts[n] or bossWhere(n) or #gamePoints(n) > 0 then rec.shown = n break end
                        end
                    end
                    local shown = rec.shown or rec.names[1]
                    if counts[shown] == nil then
                        for _, n in ipairs(rec.names) do if counts[n] then shown = n end end
                    end
                    local at, where = bossUp(shown)
                    bossTag[shown] = "boss  ·  " .. ((where == "here" and "up, here")
                        or (where == "parked" and "up") or "not spawned")
                        .. ((lv and lv < rec.lv) and ("  ·  Lv " .. rec.lv .. " for the quest") or "")
                    add(shown)
                    for _, c in ipairs(cand) do
                        if c.name == shown and not counts[shown] then
                            c.d = at and (here and (at - here).Magnitude or 5e7) + 1e7 or 1e8
                            c.far = at and here and (at - here).Magnitude or nil
                        end
                    end
                end
            end

            local order = {}
            for i, n in ipairs(CFG.Targets) do order[n] = i end
            table.sort(cand, function(a, b)
                local oa, ob = order[a.name], order[b.name]
                if oa and ob then return oa < ob end
                if oa or ob then return oa ~= nil end
                if a.d ~= b.d then return a.d < b.d end
                return a.name < b.name
            end)

            local sig = table.concat(CFG.Targets, ",") .. "|"
            for _, c in ipairs(cand) do
                sig = sig .. c.name .. (counts[c.name] or 0) .. (bossTag[c.name] or "") .. ","
            end
            if sig == signature then return end
            signature = sig

            for _, c in ipairs(box:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            for i, c in ipairs(cand) do
                local o = order[c.name]
                local n = counts[c.name]
                local tag = (o and ("#" .. o .. "  ") or "")
                    .. (bossTag[c.name] or (n and (n .. " alive")
                        or (c.far and string.format("%.0f studs", c.far) or "not loaded")))
                chooserRow(box, i, c.name, tag, o ~= nil, function()
                    P.toggleTarget(c.name)
                    signature = nil
                    refresh()
                end)
            end
        end
        refresh()
        addLive(refresh)

        actionRow(v, "Clear the circuit", nil, function()
            P.clearTargets()
            signature = nil
        end)
        heading2(v, "or type a name")
        textRow(v, "Reborn Skeleton", function(val)
            if #val == 0 then return end
            P.toggleTarget(val)
            signature = nil
        end)

        heading2(v, "bosses and respawns")
        switchRow(v, "Bosses first",
            "A boss on the circuit that is up goes before the rest",
            function() return CFG.BossFirst end,
            function(x) CFG.BossFirst = x end)
        readout(v, function()
            if not P.bossWaitSince then return "no boss wait" end
            return string.format("waiting for a boss  %ds", math.floor(os.clock() - P.bossWaitSince))
        end)
        sliderRow(v, "One species alone: wait for it", 10, 120, 5,
            function() return CFG.RespawnMax end,
            function(x) CFG.RespawnMax = x end, " s")
        caption(v, "A boss is found near you, or parked by the game far away. "
            .. "Not up: the rest of the circuit, or, if it is alone, a wait over "
            .. "its spawn for as long as it takes.")
    end

    -- =====================================================
    -- ATTACK
    -- =====================================================
    local function openWeapon(name)
        editW = name
        TITLES.weapon = name
        show("weapon")
    end

    do
        local v = makeView("attack")
        gap(v, 6)
        heading2(v, "M1 with")
        local m1box = chooser(v, 130)
        local m1sig = nil
        local function m1refresh()
            local names = {}
            for _, t in ipairs(toolNames()) do table.insert(names, t.Name) end
            table.sort(names)
            local cur = CFG.M1Weapon or ""
            local sig = cur .. "|" .. table.concat(names, ",") .. "|" .. tostring(P.m1Now)
            if sig == m1sig then return end
            m1sig = sig
            for _, c in ipairs(m1box:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            chooserRow(m1box, 1, "Auto - your sword first", (cur == "" and P.m1Now) and tostring(P.m1Now) or "",
                cur == "", function()
                    CFG.M1Weapon = ""
                    m1sig = nil
                    m1refresh()
                end)
            for i, n in ipairs(names) do
                chooserRow(m1box, i + 1, n, toolType(findTool(n)), cur == n, function()
                    CFG.M1Weapon = n
                    m1sig = nil
                    m1refresh()
                end)
            end
            if cur ~= "" and not table.find(names, cur) then
                chooserRow(m1box, #names + 2, cur, "not carried", true, function() end)
            end
        end
        m1refresh()
        addLive(m1refresh)
        caption(v, "Swings M1 in every fight - the farm, golems, Blaze Ember quests. "
            .. "Auto: your sword (the strongest swing), else a fighting style, fruit, gun.")

        heading2(v, "mastery farm")
        local mbox = chooser(v, 130)
        local msig = nil
        local function mrefresh()
            local names, seen = {}, {}
            for _, t in ipairs(toolNames()) do
                if not seen[t.Name] then seen[t.Name] = true table.insert(names, t.Name) end
            end
            local R = (P :: any).rot
            for _, it in ipairs(R and R.inv or {}) do
                if not seen[it.name] then seen[it.name] = true table.insert(names, it.name) end
            end
            table.sort(names)
            local cur = CFG.MasteryWeapon or ""
            local sig = cur .. "|" .. table.concat(names, ",")
            if sig == msig then return end
            msig = sig
            for _, c in ipairs(mbox:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            chooserRow(mbox, 1, "Off - every weapon as set", "", cur == "", function()
                CFG.MasteryWeapon = ""
                msig = nil
                mrefresh()
            end)
            for i, n in ipairs(names) do
                local t = findTool(n)
                chooserRow(mbox, i + 1, n, t and toolType(t) or "in your inventory", cur == n, function()
                    CFG.MasteryWeapon = n
                    msig = nil
                    mrefresh()
                end)
            end
        end
        mrefresh()
        addLive(mrefresh)
        sliderRow(v, "Stop the farm at", 0, 600, 25,
            function() return CFG.MasteryStop end,
            function(x) CFG.MasteryStop = x end, " mastery")
        readout(v, function() return tostring(P.masteryNote) end)
        caption(v, "The picked weapon alone hurts anything: its M1 and the keys under "
            .. "\"Every weapon you carry\" (a key not unlocked yet is left alone). No "
            .. "other weapon shares its kills. Stop at 0 = never.")

        heading2(v, "a gun's M1")
        switchRow(v, "Hold the button", "Dragonstorm: the game's own fire loop, every shot at one enemy",
            function() return CFG.GunHold end,
            function(x) CFG.GunHold = x P.reprobe() end)
        switchRow(v, "Past the heat", "The game's own shot on the script's clock - no lockout. Loud",
            function() return CFG.GunFast end,
            function(x) CFG.GunFast = x P.reprobe() end)
        sliderRow(v, "Past the heat: a shot every", 0.02, 0.2, 0.01,
            function() return CFG.GunFastEvery end,
            function(x) CFG.GunFastEvery = x end, " s")
        readout(v, function()
            return tostring(P.gunNote) .. "\nthe game's shot  " .. tostring(P.gunShotWhy)
                .. "\nsilent aim  " .. tostring(P.silentNote or "-")
        end)
        caption(v, "Held: 12.5 shots/s for 3 s of heat, then 1 s locked - its skills go "
            .. "in while it cools. Past the heat: no lockout; the wiki says long gun M1 "
            .. "streams get kills marked suspicious. Stats page, \"which setup is "
            .. "better\": kills per minute of each.")

        heading2(v, "every weapon you carry")
        switchRow(v, "Every weapon you carry", "No setup: M1 as picked above, the keys below of all",
            function() return CFG.AutoAttack end,
            function(x) CFG.AutoAttack = x end)
        for _, k in ipairs({ "Z", "X", "C", "V" }) do
            switchRow(v, "    " .. k, (k == "V") and "Often a transformation or a long hold - off by default" or "",
                function() return CFG.AutoKeys[k] == true end,
                function(x) CFG.AutoKeys[k] = x end)
        end
        switchRow(v, "Swords and guns from your inventory",
            "Every skill cooling: the next one is put in your hands, no menu",
            function() return CFG.InvSwap end,
            function(x) CFG.InvSwap = x end)
        readout(v, function()
            local R = (P :: any).rot
            if not R then return "-" end
            local inv = R.inv and #R.inv or 0
            return string.format("inventory  %s\nloaded     %d   ·   %s\nback at stop  %s",
                R.inv and (inv .. " swords / guns") or "not read yet",
                R.loads, tostring(R.note), R.original and tostring(R.originalText) or "-")
        end)
        caption(v, "A key whose skill never fires (not this weapon's, not unlocked) "
            .. "is left alone for a minute. Off: only what you switch on below.")

        heading2(v, "weapons")
        caption(v, "Tap a weapon to choose what it fires (used when \"Every weapon "
            .. "you carry\" is off). The lit ones fire.")

        local box = chooser(v, 170)
        local signature = nil
        local function refresh()
            pcall(syncWeapons)
            local sig = ""
            for _, n in ipairs(CFG.WeaponOrder) do
                sig = sig .. n .. "=" .. wSummary(n) .. (findTool(n) and "" or "?") .. ","
            end
            if sig == signature then return end
            signature = sig
            for _, c in ipairs(box:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            for i, n in ipairs(CFG.WeaponOrder) do
                local carried = findTool(n) ~= nil
                local s = wSummary(n)
                local lit = carried and s ~= "off" and CFG.Weapons[n].use
                chooserRow(box, i, n, carried and s or "not carried", lit, function()
                    openWeapon(n)
                end)
            end
        end
        refresh()
        addLive(refresh)

        heading2(v, "rhythm, when M1 and skills are both on")
        radio(v, 82, {
            { "Skills", "Skills first" },
            { "M1", "M1 first" },
        }, function() return CFG.StartWith end, function(x) CFG.StartWith = x end)
        sliderRow(v, "M1 swings between skills", 0, 10, 1,
            function() return CFG.M1Between end,
            function(x) CFG.M1Between = x end)
        caption(v, "4: a ready skill, then 4 M1, then the next ready skill, "
            .. "and so on. 0: a skill whenever one is ready, M1 only while "
            .. "every skill cools.")
        sliderRow(v, "Wait after a skill", 0.1, 1.5, 0.05,
            function() return CFG.CastWait end,
            function(x) CFG.CastWait = x end, " s")
        sliderRow(v, "Wait after a swap", 0.02, 0.5, 0.02,
            function() return CFG.EquipWait end,
            function(x) CFG.EquipWait = x end, " s")
        switchRow(v, "Lock the aim on the pile",
            "Skills land on the pile wherever your cursor is",
            function() return CFG.AimSkills end,
            function(x) CFG.AimSkills = x if not x then releaseCamera() end end)
        switchRow(v, "Keep my camera free",
            "Your view and cursor are never moved",
            function() return CFG.AimHidden end,
            function(x) CFG.AimHidden = x if x then releaseCamera() end end)
        caption(v, "Camera free: at the instant a key is read, the camera is put "
            .. "on the pile and back before the frame is drawn - you never see "
            .. "it. If the list below keeps saying MISSED for a skill, switch "
            .. "this off: then the view turns so the pile is under your cursor.")
        readout(v, function()
            local lines = { "now  " .. tostring(P.nextNote), "last skill  " .. tostring(P.lastCast) }
            local keys = {}
            for key in pairs(P.skillTally) do table.insert(keys, key) end
            table.sort(keys)
            for _, key in ipairs(keys) do
                local t = P.skillTally[key]
                table.insert(lines, string.format("%s   hit %d of %d  (fired %d)", tostring(key), t.hit, t.cast, t.fired))
            end
            return table.concat(lines, "\n")
        end)
        actionRow(v, "Clear the hit counts", nil, function() table.clear(P.skillTally) end)

        heading2(v, "how M1 lands")
        radio(v, 164, {
            { "auto", "Auto - keep what hurts" },
            { "remote", "Remote hit - whole pile" },
            { "click", "Fruit click" },
            { "keys", "Key press" },
        }, function() return CFG.M1Method end, function(x) CFG.M1Method = x end)
        readout(v, function()
            local lines = {}
            for _, n in ipairs(CFG.WeaponOrder) do
                local w = CFG.Weapons[n]
                if w and w.M1 then
                    table.insert(lines, n .. ":  " .. tostring(P.m1Notes[n] or "not tried yet"))
                end
            end
            if #lines == 0 then table.insert(lines, "no weapon has M1 on") end
            table.insert(lines, "hits sent by  " .. tostring(P.hitSender))
            table.insert(lines, "this server's COMBAT_REMOTE_THREAD  " .. tostring(P.combatFlag))
            return table.concat(lines, "\n")
        end)
        actionRow(v, "Try the M1 ways again", nil, function() P.reprobe() end)
        sliderRow(v, "M1 every", 0.03, 1, 0.01,
            function() return CFG.M1Every end,
            function(x) CFG.M1Every = x end, " s")
        sliderRow(v, "Remote hit reaches", 20, 100, 5,
            function() return CFG.HitRange end,
            function(x) CFG.HitRange = x end, " studs")
        caption(v, "Auto fires each way at the pile for a moment and keeps the "
            .. "first that takes HP off, per weapon. The remote hit names every "
            .. "enemy in the pile, so one swing hits all of them.")
    end

    -- =====================================================
    -- ONE WEAPON
    -- =====================================================
    do
        local v = makeView("weapon")
        gap(v, 6)
        local function W() return editW and CFG.Weapons[editW] or nil end
        readout(v, function()
            if not editW then return "" end
            local tool = findTool(editW)
            local where = (not tool and "not carried")
                or ((heldTool() == tool) and "in hand" or "in backpack")
            local idx = "?"
            for i, n in ipairs(CFG.WeaponOrder) do if n == editW then idx = i end end
            return toolType(tool) .. "  ·  " .. where .. "  ·  #" .. idx .. " in the order"
        end)
        switchRow(v, "Use this weapon", "Off keeps its switches but fires nothing",
            function() local w = W() return w and w.use or false end,
            function(x) if editW then wcfg(editW).use = x end end)
        hairline(v)
        switchRow(v, "M1", "How it lands is on the Attack page",
            function() local w = W() return w and w.M1 or false end,
            function(x)
                if not editW then return end
                local w = wcfg(editW)
                w.M1 = x
                if x then w.use = true end
            end)
        for _, k in ipairs(KEYS) do
            switchRow(v, k, nil,
                function() local w = W() return w and w[k] or false end,
                function(x)
                    if not editW then return end
                    local w = wcfg(editW)
                    w[k] = x
                    if x then w.use = true end
                end)
        end
        readout(v, function() return editW and P.skillState(editW) or "" end)

        heading2(v, "hold each key")
        caption(v, "Some skills fire on release after a hold. 0.05 is a tap.")
        for _, k in ipairs(KEYS) do
            sliderRow(v, "Hold " .. k, 0, 2, 0.05,
                function()
                    local w = W()
                    return (w and w.hold and w.hold[k]) or 0.05
                end,
                function(x)
                    if not editW then return end
                    local w = wcfg(editW)
                    w.hold = w.hold or {}
                    w.hold[k] = x
                end, " s")
        end
        actionRow(v, "Move up in the order", nil, function()
            if editW and P.moveWeaponUp(editW) then say(editW .. " moved up") end
        end)
        caption(v, "Skills are tried weapon by weapon in this order, Z X C V F "
            .. "inside each. M1 uses the first weapon whose M1 is on.")
    end

    -- =====================================================
    -- MAGNET
    -- =====================================================
    do
        local v = makeView("magnet")
        gap(v, 6)
        switchRow(v, "Magnet", "Pull the quest species into one pile and hold it",
            function() return CFG.Magnet end,
            function(x) CFG.Magnet = x end)
        readout(v, function()
            return string.format("held %d   ·   staying put %d   ·   put back %d\n%s",
                P.pileHeld or 0, P.pileOwned or 0, stats.putBack, tostring(P.simNote))
        end)
        heading2(v, "why no damage - the last ones")
        readout(v, function()
            if #P.noDamage == 0 then return "every one hit so far took damage" end
            return table.concat(P.noDamage, "\n")
        end)
        caption(v, "Written the moment one stops taking damage. NOT OURS = the "
            .. "magnet moves it only on your screen, the server has it where the "
            .. "gap says. OUT OF REACH = the hit does not name it. SHIELDED = spawn "
            .. "protection. Ours, in reach, no shield = the server refused the hit; "
            .. "\"pile N of M\" shows whether it is always the last ones (a cap).")
        actionRow(v, "Clear the list", nil, function() table.clear(P.noDamage) end)
        heading2(v, "the pile")
        switchRow(v, "Pull every one loaded",
            "Any distance - a new spawn joins the pile at once",
            function() return CFG.PullAll end,
            function(x) CFG.PullAll = x end)
        readout(v, function()
            if not CFG.PullAll then return "off: only ones spawned within the distance below" end
            return P.pileReach and string.format("pile at the camp's middle  ·  farthest pull %.0f studs",
                P.pileReach) or "pile at the camp's middle (found on the first pile)"
        end)
        sliderRow(v, "Pull at most, from their spawn", 50, 1000, 10,
            function() return CFG.MaxPull end,
            function(x) CFG.MaxPull = x end, " studs")
        switchRow(v, "Learn how far each kind can go",
            "Off by default: it only ever lowers the limit, and split camps",
            function() return CFG.LearnLeash end,
            function(x) CFG.LearnLeash = x end)
        readout(v, function()
            local lines = {}
            if P.pileSplit then table.insert(lines, P.pileSplit) end
            local names = {}
            for n in pairs(P.leash) do table.insert(names, n) end
            table.sort(names)
            for _, n in ipairs(names) do
                local l = P.leash[n]
                table.insert(lines, string.format("%s: hit up to %s from spawn%s  ->  at most %.0f", n,
                    l.ok and string.format("%.0f", l.ok) or "-",
                    l.bad and string.format(", no damage at %.0f", l.bad) or "", pullLimit(n)))
            end
            if #lines == 0 then return "one pile per camp  ·  nothing measured yet" end
            return table.concat(lines, "\n")
        end)
        actionRow(v, "Forget what it measured", nil, function() table.clear(P.leash) end)
        caption(v, "A camp wider than the limit is piled one side at a time: "
            .. "the side nearest you, then the other when it is empty. A pile "
            .. "holds: it does not move and lets nobody go while one of it is "
            .. "alive. Learning on: pulled ones that stop taking damage while "
            .. "nearer ones still do lower the limit for their kind (never one "
            .. "that is NOT OURS).")
        sliderRow(v, "When that is off: within", 50, 600, 10,
            function() return CFG.GrabRadius end,
            function(x) CFG.GrabRadius = x end, " studs")
        sliderRow(v, "Most in one pile", 1, 30, 1,
            function() return CFG.GrabMax end,
            function(x) CFG.GrabMax = x end)
        sliderRow(v, "Pile width", 0, 10, 0.5,
            function() return CFG.PileSpread end,
            function(x) CFG.PileSpread = x end, " studs")
        switchRow(v, "Pull other picked species too",
            "Only ones that spawn in this camp",
            function() return CFG.PullOthers end,
            function(x) CFG.PullOthers = x end)
        sliderRow(v, "This camp means within", 20, 300, 10,
            function() return CFG.OthersRadius end,
            function(x) CFG.OthersRadius = x end, " studs")
        heading2(v, "random mode")
        sliderRow(v, "Random mode reaches", 200, 2000, 50,
            function() return CFG.RandomRadius end,
            function(x) CFG.RandomRadius = x end, " studs")
        caption(v, "Round you; at the Castle on the Sea, round the pirate raid's "
            .. "area (at least 800). Only ones within their pull limit go in a "
            .. "pile - a far one gets its own. One that takes no damage when "
            .. "pulled is fought where it stands, from close if high does not "
            .. "hurt it.")
        heading2(v, "raid mode")
        sliderRow(v, "Raid mode pulls within", 100, 1500, 50,
            function() return CFG.RaidRadius end,
            function(x) CFG.RaidRadius = x end, " studs")
        caption(v, "Of the newest raid island (Island 1 to 5). Every kind of "
            .. "enemy in that circle goes in the pile. Outside a raid nothing "
            .. "is fought and you stay where you are.")
        sliderRow(v, "A raid island counts within", 500, 5000, 100,
            function() return CFG.RaidReach end,
            function(x) CFG.RaidReach = x end, " studs of you")
        sliderRow(v, "Stuck: relocate after", 5, 60, 1,
            function() return CFG.RaidStuckSecs end,
            function(x) CFG.RaidStuckSecs = x end, " s with no HP off")
        readout(v, function()
            local rd = P.raid
            if not rd then return "-" end
            local rl = rd.loop
            return table.concat({
                "raid      " .. tostring(P.raidNote),
                string.format("done      %d raids  ·  %d relocations%s", rd.done, rd.moves,
                    rd.note and ("  ·  last: " .. rd.note) or ""),
                string.format("loop      %s  ·  %d chips  ·  %d presses%s", CFG.RaidLoop and tostring(rl.note) or "off",
                    rl.chips, rl.presses, rl.paid and ("  ·  last paid " .. tostring(rl.paid)) or ""),
            }, "\n")
        end)
        heading2(v, "raid loop: the chip")
        radio(v, 164, {
            { "Flame", "Flame", "" }, { "Ice", "Ice", "" }, { "Quake", "Quake", "" },
            { "Light", "Light", "" }, { "Dark", "Dark", "" }, { "Spider", "Spider", "" },
            { "Magma", "Magma", "" }, { "Buddha", "Buddha", "" }, { "Sand", "Sand", "" },
        }, function() return CFG.RaidChip end, function(x) CFG.RaidChip = x end)
        sliderRow(v, "Trade a stored fruit worth at most", 0, 1000000, 10000,
            function() return CFG.RaidFruitMax end,
            function(x) CFG.RaidFruitMax = x end, " Beli")
        caption(v, "The Mysterious Scientist takes a physical fruit for a chip (or "
            .. "$100,000 every 2 hours): your cheapest stored one under this is "
            .. "loaded into the backpack - never your hand - and traded. A "
            .. "dearer fruit already in your backpack = nothing traded (he "
            .. "could take it). Anything fails: you stay, tried again later.")
        heading2(v, "keeping them hittable")
        caption(v, "The pile sits at the middle of the camp's spawn points - the "
            .. "spot where the farthest pull is shortest, so every one stays "
            .. "inside its own area (an enemy dragged out of it takes no damage). Each "
            .. "one held is frozen (cannot walk) and keeps its own spot. One that is "
            .. "held and hit with no HP change goes back where it came from and is "
            .. "left alone for 30 s. 'Staying put' is how many are really yours to "
            .. "move - fewer than 'held' = another player is nearer those.")
        sliderRow(v, "Put back after no damage for", 1, 10, 0.5,
            function() return CFG.PutBackAfter end,
            function(x) CFG.PutBackAfter = x end, " s")
    end

    -- =====================================================
    -- POSITION
    -- =====================================================
    do
        local v = makeView("position")
        gap(v, 6)
        readout(v, function()
            if CFG.HeightMode == "fixed" then
                return string.format("fixed: %d up, %d out", CFG.HeightFixed, CFG.SideFixed)
            end
            if wantPose == "melee" then
                return string.format("now close: %.1f up, %.1f out", CFG.HeightMelee, CFG.MeleeDistance)
            end
            return string.format("now high: %d over the highest enemy%s", CFG.HeightSafe,
                CFG.StayHigh and "  (always)" or "")
        end)
        radio(v, 82, {
            { "auto", "Auto - high or close" },
            { "fixed", "One fixed spot" },
        }, function() return CFG.HeightMode end, function(x) CFG.HeightMode = x end)
        caption(v, "Auto: high over the pile whenever the hit reaches from "
            .. "there (remote hit, fruit click, fruit skills) - out of their "
            .. "reach. Close beside it when it does not (key presses, "
            .. "fighting-style and sword skills).")
        switchRow(v, "Always stay above them",
            "Never comes down close - every attack from this height",
            function() return CFG.StayHigh end,
            function(x)
                CFG.StayHigh = x
                if x then setPose("safe") end
                P.reprobe()             -- the M1 ways were found at the old height
            end)
        caption(v, "The height is counted from the highest enemy in the pile. "
            .. "Staying above: what cannot reach from up there (a sword swing, "
            .. "a short melee skill) shows as MISSED or 'nothing landed' - "
            .. "lower the height, or switch this off for that weapon.")
        heading2(v, "auto")
        sliderRow(v, "High, over the pile", 5, 150, 1,
            function() return CFG.HeightSafe end,
            function(x) CFG.HeightSafe = x end, " studs")
        sliderRow(v, "Close, height", 0, 10, 0.5,
            function() return CFG.HeightMelee end,
            function(x) CFG.HeightMelee = x end, " studs")
        sliderRow(v, "Close, out to the side", 0, 15, 0.5,
            function() return CFG.MeleeDistance end,
            function(x) CFG.MeleeDistance = x end, " studs")
        heading2(v, "fixed")
        sliderRow(v, "Height", 0, 150, 1,
            function() return CFG.HeightFixed end,
            function(x) CFG.HeightFixed = x end, " studs")
        sliderRow(v, "Out to the side", 0, 20, 1,
            function() return CFG.SideFixed end,
            function(x) CFG.SideFixed = x end, " studs")
    end

    -- =====================================================
    -- TRAVEL
    -- =====================================================
    do
        local v = makeView("travel")
        gap(v, 6)
        sliderRow(v, "Fly speed", 100, 1000, 10,
            function() return CFG.TravelSpeed end,
            function(x) CFG.TravelSpeed = x end, " studs/s")
        caption(v, "The public hubs fly at 330. Faster and the server may "
            .. "pull you back - the line below counts it.")
        sliderRow(v, "Instant under", 0, 400, 10,
            function() return CFG.InstantHop end,
            function(x) CFG.InstantHop = x end, " studs")
        caption(v, "Closer than this is one jump, not a flight.")
        readout(v, function()
            return "last flight  " .. tostring(P.lastFlight)
                .. string.format("\nflights %d   ·   instant hops %d   ·   pulled back %d",
                    stats.flights, stats.hops, stats.pulledBack)
        end)
        caption(v, "Noclip is on for the whole run: no collisions, nothing to "
            .. "get stuck on, and the body is held so it never falls.")
    end

    -- =====================================================
    -- SAFETY
    -- =====================================================
    do
        local v = makeView("safety")
        gap(v, 6)
        heading2(v, "getting out")
        sliderRow(v, "Escape below", 10, 80, 5,
            function() return CFG.EscapeBelow * 100 end,
            function(x) CFG.EscapeBelow = x / 100 end, "%")
        sliderRow(v, "Come back at", 30, 100, 5,
            function() return CFG.ReturnAt * 100 end,
            function(x) CFG.ReturnAt = x / 100 end, "%")
        readout(v, function() return "escapes this run  " .. stats.escapes end)
        caption(v, "There is no real god mode: health lives on the server. "
            .. "What keeps you alive is hanging high over the pile, the pile "
            .. "being pinned so nothing can walk to you, Observation, and "
            .. "this: under the first number you fly 250 up and wait for the second.")

        heading2(v, "haki")
        switchRow(v, "Enhancement (J) - keep it on",
            "Checked every pass; J when the character lacks it",
            function() return CFG.AutoBuso end,
            function(x) CFG.AutoBuso = x end)
        switchRow(v, "Observation (E) - keep it on",
            "After a death and on a timer; E only when it is off",
            function() return CFG.AutoKen end,
            function(x) CFG.AutoKen = x end)
        sliderRow(v, "Check Observation every", 1, 15, 1,
            function() return (CFG.KenEvery or 300) / 60 end,
            function(x)
                CFG.KenEvery = x * 60
                kenNextAt = math.min(kenNextAt, os.clock() + CFG.KenEvery)
            end, " min")
        readout(v, function()
            local lines = {}
            table.insert(lines, CFG.AutoBuso
                and (hasBuso() and "Enhancement: ON" or "Enhancement: OFF - pressing J, up to 3 tries per life")
                or "Enhancement: not managed")
            if CFG.AutoKen then
                local on = kenOn()
                table.insert(lines, "Observation now: "
                    .. (on == true and "ON" or on == false and "OFF" or "cannot tell")
                    .. string.format("   next look in %s", mmss(P.kenNextIn())))
                table.insert(lines, "Last: " .. tostring(P.kenNote))
            else
                table.insert(lines, "Observation: not managed")
            end
            return table.concat(lines, "\n")
        end)
    end

    -- =====================================================
    -- ELITE HUNT
    -- =====================================================
    do
        local v = makeView("elite")
        gap(v, 6)
        huntSwitches(v)
        readout(v, function()
            local el = P.elite
            local t = el.tally
            local avg = (t.joins > 0) and string.format("%.0fs", t.joinSecs / t.joins) or "-"
            return table.concat({
                "now       " .. tostring(el.note),
                string.format("joined    %d   ·   join %s   ·   failed joins %d", t.joins, avg, t.fails),
                "servers   " .. tostring(el.lastList or "not read yet"),
                "last join " .. tostring(el.lastJoin or "none yet"),
                "counting since " .. os.date("%d %b %H:%M", t.since or os.time()),
            }, "\n")
        end)
        caption(v, "The God's Chalice ends the hunt in the server it came in: "
            .. "no hop there, ever - leaving or dying with it loses it. You are "
            .. "held 300 up; Stop gives the character back.")

        heading2(v, "fruit hunt")
        sliderRow(v, "Only if worth at least", 0, 10000000, 100000,
            function() return CFG.FruitMinPrice end,
            function(x) CFG.FruitMinPrice = x end, " Beli")
        caption(v, "The game's own price. 0 = any fruit. 1000000 and up = "
            .. "Legendary and Mythical. The dearest one lying here goes first.")
        switchRow(v, "Include fruits players dropped",
            "Off: server spawns only - drops are mostly trades",
            function() return CFG.FruitPlayerDrops end,
            function(x) CFG.FruitPlayerDrops = x end)
        readout(v, function()
            local el = P.elite
            local lines = { "last      " .. tostring(el.fruitNote),
                string.format("stored    %d", el.tally.fruits or 0) }
            local ok, list = pcall(P.fruitsLying)
            if ok and type(list) == "table" and #list > 0 then
                for _, f in ipairs(list) do
                    table.insert(lines, string.format("   %s  %s  %s", f.name,
                        f.price and ("$" .. tostring(f.price)) or "$?",
                        f.dropper and ("dropped by " .. tostring(f.dropper) .. (f.dropperNear and ", still by it" or ""))
                            or "server spawn"))
                end
            else
                table.insert(lines, "lying in this server: none")
            end
            return table.concat(lines, "\n")
        end)
        caption(v, "The whole server's fruits are seen from anywhere. A player "
            .. "standing by their drop is trading it: never taken, even with "
            .. "player drops on.")

        heading2(v, "berry hunt  -  which berries")
        -- What each one makes at the Barista (recipes from the Barista Cousin).
        local BERRY_USE = {
            ["Pink Pig Berry"]     = "Winter Sky: 15  (Legendary)",
            ["White Cloud Berry"]  = "Snow White: 10  (Legendary)",
            ["Red Cherry Berry"]   = "Pure Red: 15  (Legendary)",
            ["Blue Icicle Berry"]  = "Absolute Zero 5, Blue Jeans 3",
            ["Green Toad Berry"]   = "Slimy Green 1, Green Lizard 1",
            ["Orange Berry"]       = "Orange Soda 1, Heat Wave 2",
            ["Purple Jelly Berry"] = "Plump Purple 3",
            ["Yellow Star Berry"]  = "Bright Yellow 1, Yellow Sunshine 1",
        }
        for _, n in ipairs(P.BERRIES) do
            switchRow(v, n, BERRY_USE[n],
                function() return CFG.BerryWant[n] == true end,
                function(x) CFG.BerryWant[n] = x and true or false end)
        end
        readout(v, function()
            local el = P.elite
            local lines = { "last      " .. tostring(el.berryNote),
                string.format("picked    %d", el.tally.berries or 0) }
            if el.have.read then
                local bits = {}
                for _, n in ipairs(P.BERRIES) do
                    table.insert(bits, string.format("%s %d", (string.gsub(n, " Berry$", "")), el.have[n] or 0))
                end
                table.insert(lines, "you have  " .. table.concat(bits, " · "))
            end
            local _, r = parts()
            local ok, list = pcall(P.berriesLying)
            if ok and type(list) == "table" and #list > 0 then
                for _, b in ipairs(list) do
                    table.insert(lines, string.format("   %s   %s", table.concat(b.names, " + "),
                        r and string.format("%.0f studs", (b.pos - r.Position).Magnitude) or ""))
                end
            else
                table.insert(lines, "on the bushes here: none")
            end
            return table.concat(lines, "\n")
        end)
        caption(v, "At most 4 in a server, a new one every 15 min, gone after an "
            .. "hour - anyone can take one. The Barista makes the colors "
            .. "(+ 7,500 fragments for a Legendary).")

        heading2(v, "aura recipe hunt  -  which recipes")
        for i, n in ipairs(P.RECIPES) do
            switchRow(v, n, (i <= 3) and "Legendary - rip_indra's buttons need all three" or "Rare",
                function() return CFG.RecipeWant[n] == true end,
                function(x) CFG.RecipeWant[n] = x and true or false end)
        end
        readout(v, function()
            local el = P.elite
            return table.concat({
                "here      " .. tostring(el.offer or "not asked yet"),
                "last      " .. tostring(el.recipeNote),
                string.format("learned   %d", el.tally.recipes or 0),
            }, "\n")
        end)
        caption(v, "He teaches ONE recipe per server, asked from anywhere - no "
            .. "flight to find out. He comes 20 min after a server starts, "
            .. "stays 20, is gone 2. Switch off the ones you already have. A "
            .. "recipe learned goes off by itself; not learned (fragments, Aura "
            .. "stage 5) stops the hunt and says why.")

        heading2(v, "fire flower hunt  (Draco V2, Third Sea)")
        readout(v, function()
            local el = P.elite
            local lines = { "last      " .. tostring(el.flowerNote),
                string.format("picked    %d   ·   you have %s", el.tally.flowers or 0,
                    el.flowerHave and tostring(el.flowerHave) or "not read yet") }
            if CFG.Hunt and CFG.HuntKind == "flower" then
                if el.flowerFirstKill then
                    local s = math.floor(os.clock() - el.flowerFirstKill)
                    table.insert(lines, string.format("here      %d:%02d since the first kill  ·  no flower = next server at %g min",
                        s // 60, s % 60, CFG.FlowerGiveUp or 2.5))
                else
                    table.insert(lines, "here      the clock starts at the first kill")
                end
            end
            local ok, list = pcall(P.flowersLying)
            table.insert(lines, (ok and type(list) == "table" and #list > 0)
                and ("lying now " .. #list) or "lying now none")
            return table.concat(lines, "\n")
        end)
        sliderRow(v, "No flower this long after the first kill: leave", 1, 5, 0.5,
            function() return CFG.FlowerGiveUp end,
            function(x) CFG.FlowerGiveUp = x end, " min")
        caption(v, "Needs the Dragon Wizard's V2 quest taken - flowers spawn only "
            .. "then. Forest + Mythological Pirates, one at a time where they "
            .. "stand (no magnet: the flower comes up where one dies). Picked "
            .. "the moment it lies there, then the next server - that one gives "
            .. "none for 5-15 min. Nothing dies for 3 min: the next server too.")

        heading2(v, "blaze ember hunt  (Third Sea)")
        readout(v, function()
            local m = P.ember
            local lines = {
                "now       " .. tostring(m.note),
                "quest     " .. tostring(m.quest or "none yet") .. (m.how and ("  (" .. m.how .. ")") or ""),
                string.format("embers    %d taken   ·   you have %s", m.tally.embers, m.have and tostring(m.have) or "not read yet"),
                string.format("quests    %d   ·   trees broken %d%s", m.tally.quests, m.tally.trees,
                    m.mustVisit and "   ·   asked AT the Dragon Hunter" or ""),
            }
            local best, bn = nil, -1
            for key, L in pairs(m.learn) do
                if L.closed > bn then best, bn = key, L.closed end
            end
            if best then table.insert(lines, string.format("trees     best key %s (%d of %d)", best, m.learn[best].closed, m.learn[best].casts)) end
            return table.concat(lines, "\n")
        end)
        sliderRow(v, "Stop when you have", 15, 99, 1,
            function() return CFG.EmberStopAt end,
            function(x) CFG.EmberStopAt = x end, " embers")
        sliderRow(v, "Trees taller than this are skipped", 30, 300, 10,
            function() return CFG.EmberTreeMax end,
            function(x) CFG.EmberTreeMax = x end, " studs")
        caption(v, "Needs Dragon Talon at 500 mastery and the Dojo's Yellow Belt. "
            .. "The quest is asked for from where you are; if that does not take, "
            .. "at the Dragon Hunter. Enforcers / Assailants are pulled and killed "
            .. "(M1 as the Attack page picks). Trees: blasts only - the Skull Guitar / "
            .. "Bazooka M1 first, else Z/X/C of every weapon, aimed; never a plain M1 "
            .. "(the medium ground trees first, bamboo last, the giants never). Each quest drops 3 "
            .. "embers - run through. The tree list goes to "
            .. "workspace/bff_ember_trees.txt.")

        heading2(v, "elite pirate hunt  (Third Sea)")
        readout(v, function()
            local el = P.elite
            local t = el.tally
            local rate = (t.joins > 0) and string.format("%.0f%%", t.found / t.joins * 100) or "-"
            return table.concat({
                "Elite Hunter  " .. tostring(el.reply or "not asked")
                    .. (el.replyText and ("  \"" .. string.sub(el.replyText, 1, 70) .. "\"") or ""),
                string.format("had one   %d (%s)   ·   down %d   ·   chalices %d", t.found, rate, t.kills, t.chalices),
                "progress  " .. (el.progress and (el.progress .. " / 30 toward Yama") or "not read yet"),
                "last      " .. tostring(el.lastKill or "-"),
            }, "\n")
        end)

        heading2(v, "when nothing here is worth it")
        switchRow(v, "Hop to the next server",
            "Off: wait in this one",
            function() return CFG.HuntHop end,
            function(x) CFG.HuntHop = x end)
        radio(v, 82, {
            { "fewest", "Fewest players first", "fewer hunters" },
            { "random", "Any order",            "" },
        }, function() return CFG.HopOrder end, function(x) CFG.HopOrder = x end)
        sliderRow(v, "Look for", 3, 30, 1,
            function() return CFG.EliteLook end,
            function(x) CFG.EliteLook = x end, " s")
        caption(v, "After a join: this long for an elite to show before leaving. "
            .. "When the Elite Hunter says none is up, 3 s is enough.")
        sliderRow(v, "Try a server again after", 5, 60, 1,
            function() return CFG.HopRevisit end,
            function(x) CFG.HopRevisit = x end, " min")
        caption(v, "One killed there is back 8 min 45 s later.")

        heading2(v, "the quest")
        switchRow(v, "Take the Elite Hunter's quest",
            "Progress toward Yama - the chalice does not need it",
            function() return CFG.EliteQuest end,
            function(x) CFG.EliteQuest = x end)
        caption(v, "Asked from where you stand. If that gets no answer, once per "
            .. "server from in front of the Elite Hunter. A different quest "
            .. "running is dropped for it.")

        heading2(v, "after a hop")
        switchRow(v, "Pick my team on join",
            "The Pirates / Marines screen every new server shows",
            function() return CFG.AutoTeam end,
            function(x) CFG.AutoTeam = x end)
        radio(v, 82, {
            { "Pirates", "Pirates", "" },
            { "Marines", "Marines", "" },
        }, function() return CFG.Team end, function(x) CFG.Team = x end)
        readout(v, function() return "team      " .. tostring(P.teamNote) end)
        readout(v, function() return P.reloadWay() end)
        caption(v, "Your settings, the servers already looked at and these "
            .. "counts go with you. Without queue_on_teleport, the README's "
            .. "three-line loader in the executor's autoexec folder does the same.")

        heading2(v, "by hand")
        actionRow(v, "Hop now", nil, function() P.hopNow() end)
        actionRow(v, "Forget the servers looked at", nil, function()
            table.clear(P.elite.visited)
            P.elite.note = "servers looked at: forgotten"
        end)
        actionRow(v, "Reset the hunt counts", nil, function()
            local t = P.elite.tally
            for k in pairs(t) do t[k] = 0 end
            t.since = os.time()
            P.elite.note = "hunt counts reset"
        end)
    end

    -- =====================================================
    -- SEA: THE PREHISTORIC HUNT AND THE VOLCANO EVENT
    -- =====================================================
    do
        local v = makeView("sea")
        gap(v, 6)
        heading2(v, "sea events hunt  (Third Sea)")
        readout(v, function()
            local s, e = P.sea, P.seaev
            local c = e.count
            local goal = math.max(1, math.floor(tonumber(CFG.SeaEvGoal) or 20))
            local kinds = {}
            for _, k in ipairs({ "Sea Beast", "Rumbling Waters", "Terrorshark", "Piranha", "Shark", "Leviathan" }) do
                if (c.kinds[k] or 0) > 0 then table.insert(kinds, k .. " " .. c.kinds[k]) end
            end
            local spy = e.spy
            return table.concat({
                "now       " .. tostring(e.note),
                string.format("count     %d of %d sea events  ·  since %s", c.total, goal, os.date("%d %b %H:%M", c.since)),
                "          " .. ((#kinds > 0) and table.concat(kinds, "  ·  ") or "none yet"),
                "spy       " .. (spy and string.format("%s  ·  asked %d min ago%s", tostring(spy.text),
                    math.floor((os.clock() - spy.at) / 60),
                    spy.overAt and string.format("  ·  past the cooldown at %d", spy.overAt) or "") or "not asked yet"),
                "last      " .. tostring(e.last),
                string.format("boat      %s%s  ·  %d fights  ·  %d fled", tostring(s.boatNote),
                    s.hp and string.format("  ·  %d / %s HP", s.hp, tostring(s.maxHp or "?")) or "", e.fights, e.flees),
            }, "\n")
        end)
        sliderRow(v, "Patrol at Sea Danger", 1, 6, 1,
            function() return CFG.SeaEvDanger end,
            function(x) CFG.SeaEvDanger = x end, "")
        for _, row in ipairs({
            { "Sea Beast", "Hovered over, every key aimed at it (M1 only in Kitsune form)" },
            { "Rumbling Waters", "Three beasts at once - one at a time, the nearest first" },
            { "Terrorshark", "Round it, dodging - every key (M1 only in Kitsune form)" },
            { "Piranha", "A school of them = one sea event" },
            { "Shark", "Off: sailed away from" },
        }) do
            local k = row[1]
            switchRow(v, "Fight: " .. k, row[2],
                function() return (CFG.SeaEvFight or {})[k] == true end,
                function(x)
                    CFG.SeaEvFight = CFG.SeaEvFight or {}
                    CFG.SeaEvFight[k] = x
                end)
        end
        caption(v, "Off = sailed away from. Ship raids (the pirate brigades, the Fish "
            .. "Boat and its crew, the haunted ships) are always sailed away from - "
            .. "slow, and they break the boat - then the boat waits, stopped, until "
            .. "the ship is twice that far or gone. The Leviathan: its own switch below. The "
            .. "boat patrols a slow circle at the danger you set (sea events come to a "
            .. "boat that is near); a fight takes you off the seat and holds the boat "
            .. "up out of the waves; then back to the wheel. Never the next server.")
        sliderRow(v, "Count goal (the Spy: 20 or more)", 1, 60, 1,
            function() return CFG.SeaEvGoal end,
            function(x) CFG.SeaEvGoal = x end, " events")
        switchRow(v, "Stop at the goal", "The hunt and the farm stop the moment the count reaches it",
            function() return CFG.SeaEvStopAtGoal end,
            function(x) CFG.SeaEvStopAtGoal = x end)
        actionRow(v, "Ask the Spy now", nil, function() P.seaev.spyAsk() end)
        actionRow(v, "Reset the count to 0", "danger", function() P.seaev.reset() end)
        caption(v, "One sea event = one group of the same kind (five piranhas count "
            .. "once - the wiki; three beasts = Rumbling Waters = once), counted when "
            .. "every one of it is gone and at least one was KILLED. Escaped or "
            .. "despawned = not counted. Kept across joins - reset it after each Frozen "
            .. "Dimension. The Spy's own answer (asked from anywhere, read only, every "
            .. "5 min and after each count) is the truth; the count is the guide.")
        heading2(v, "the leviathan")
        switchRow(v, "Leviathan fight", "On = only the Leviathan (inside the Frozen Dimension); starts the run",
            function() return CFG.LeviFight end,
            function(x)
                CFG.LeviFight = x
                if x and not P.running then P.start() end
            end)
        sliderRow(v, "Over the part being hit", 30, 300, 5,
            function() return CFG.LeviHeight end,
            function(x) CFG.LeviHeight = x end, " studs")
        sliderRow(v, "Your share of each segment before the next", 8, 50, 1,
            function() return CFG.LeviShare end,
            function(x) CFG.LeviShare = x end, " %")
        readout(v, function()
            local lv = P.seaev.levi
            local lines = { "now       " .. tostring(lv.note), string.format("down      %d Leviathans", lv.kills),
                string.format("dodged    %d (last: %s)  ·  out of now: %s", P.seaev.dodges or 0,
                    tostring(P.seaev.lastDodge or "-"), (#lv.now > 0) and table.concat(lv.now, ", ") or "nothing") }
            local ok, list = pcall(P.seaev._t.leviParts)
            for _, x in ipairs((ok and list) or {}) do
                local m = x.max or x.maxSeen
                table.insert(lines, string.format("  %-18s HP %s%s  ·  %s  ·  your share %s", x.label,
                    x.hp and tostring(math.floor(x.hp)) or "?", m and (" / " .. math.floor(m)) or "",
                    x.enabled and "takes damage" or "not now",
                    m and string.format("%.1f%%", (lv.share[x.model] or 0) / m * 100) or "?"))
            end
            return table.concat(lines, "\n")
        end)
        caption(v, "On = ONLY the Leviathan: switch it on inside the Frozen Dimension (it "
            .. "starts the run); nothing else runs, and until it shows the character is "
            .. "yours. Its segments first, the head LAST (segments respawn: back to them). "
            .. "Fought like a Sea Beast - every ready key aimed at the part, no M1 out of "
            .. "Kitsune form, round it, the water a floor, dives waited out. ITS ATTACKS, "
            .. "read off the game's own effects: the tail's red area - out of it sideways "
            .. "(up does not save you); the mouth beam's charge and the beam - off its "
            .. "line; the tornadoes - away; the roar's ice spears - up the moment one "
            .. "flies; any other attack animation - up. The reward needs 8% of the damage "
            .. "on EACH segment: yours is read off its HP while your keys land (others' "
            .. "hits in that moment count too), so the next one at your share. Its HEART: "
            .. "the character is yours - the Beast Hunter's harpoon, tow it to Tiki. "
            .. "Killed: the sea event count back to 0 (the Spy's cooldown starts). No "
            .. "boat is touched. The first one writes its parts and each attack's size "
            .. "to workspace/bff_beast_probe.txt.")
        heading2(v, "the loadout at sea")
        radio(v, 122, {
            { "auto", "Kitsune form first, its M1 tested", "hurts them = form; else Kitsune + fighting style" },
            { "form", "Kitsune form, always", "" },
            { "base", "Never transformed", "Kitsune + fighting style (the weapons below)" },
        }, function() return CFG.SeaEvForm end, function(x) CFG.SeaEvForm = x end)
        sliderRow(v, "Test the form's M1 for at most", 10, 60, 5,
            function() return CFG.SeaEvTrial end,
            function(x) CFG.SeaEvTrial = x end, " s")
        readout(v, function()
            local e = P.seaev
            local lines = {}
            for _, cls in ipairs({ "beast", "fish" }) do
                local f = e.form[cls]
                local name = (cls == "beast") and "Sea Beasts" or "Terrorshark etc."
                local what = (f.verdict == "form") and string.format("FORM - its M1 hurt them %d of %d", f.hits, f.casts)
                    or (f.verdict == "base") and string.format("Kitsune + fighting style - the form's M1 hurt them %d of %d", f.hits, f.casts)
                    or ((f.casts > 0) and string.format("testing the form's M1: %d of %d, %.0f s", f.hits, f.casts, f.up) or "not tested yet")
                table.insert(lines, string.format("%-17s %s", name, what))
            end
            table.insert(lines, "you now          " .. (e.inForm() and "KITSUNE FORM" or "not transformed")
                .. (e.kitsune() and "" or "  ·  no Kitsune fruit carried") .. (e.formNote and ("  ·  " .. tostring(e.formNote)) or ""))
            return table.concat(lines, "\n")
        end)
        caption(v, "Out of form, only these weapons fight at sea (your points: fruit + melee). "
            .. "In form, the game takes only the fruit's moves anyway.")
        for _, ty in ipairs({ "Blox Fruit", "Melee", "Sword", "Gun" }) do
            switchRow(v, ty, nil,
                function() return (CFG.SeaEvWeapons or {})[ty] == true end,
                function(x)
                    CFG.SeaEvWeapons = CFG.SeaEvWeapons or {}
                    CFG.SeaEvWeapons[ty] = x
                end)
        end
        heading2(v, "dodging (Terrorshark / Piranha / Shark)")
        switchRow(v, "Dodge", "Round it all the time, the aim locked on it; up the moment it attacks",
            function() return CFG.SeaDodge end,
            function(x) CFG.SeaDodge = x end)
        sliderRow(v, "Round it at", 10, 80, 5,
            function() return CFG.DodgeRadius end,
            function(x) CFG.DodgeRadius = x end, " studs")
        sliderRow(v, "Moving at", 10, 150, 5,
            function() return CFG.DodgeSpeed end,
            function(x) CFG.DodgeSpeed = x end, " studs/s")
        sliderRow(v, "Up when it attacks", 10, 120, 5,
            function() return CFG.DodgeUp end,
            function(x) CFG.DodgeUp = x end, " studs")
        sliderRow(v, "Stay up for", 0.3, 3, 0.1,
            function() return CFG.DodgeTime end,
            function(x) CFG.DodgeTime = x end, " s")
        readout(v, function()
            local e = P.seaev
            return string.format("dodged    %d times  ·  last: %s\nwater     %s", e.dodges or 0, tostring(e.lastDodge or "-"),
                P.floorY and string.format("a floor at Y %.0f - you never go under it (swimming off, knockback refused)", P.floorY)
                    or "a floor during every sea fight")
        end)
        caption(v, "It starts an attack (a new animation), charges at you or leaps: up "
            .. "for a moment, then back. The water is a floor in every sea fight: you "
            .. "are never under it, whatever the target does, and a knockback or a "
            .. "pull is undone the next frame.")
        heading2(v, "fighting at sea")
        sliderRow(v, "Over a Sea Beast", 30, 250, 5,
            function() return CFG.BeastHeight end,
            function(x) CFG.BeastHeight = x end, " studs")
        sliderRow(v, "Over a Terrorshark / Piranha / Shark", 10, 100, 5,
            function() return CFG.FishHeight end,
            function(x) CFG.FishHeight = x end, " studs")
        sliderRow(v, "Boat held up while you fight (0 = left)", 0, 300, 10,
            function() return CFG.BoatLift end,
            function(x) CFG.BoatLift = x end, " studs")
        sliderRow(v, "Ship raid: sail away until it is", 500, 4000, 100,
            function() return CFG.FleeTo end,
            function(x) CFG.FleeTo = x end, " studs off")
        heading2(v, "keys fired at a sea event")
        for _, k in ipairs({ "Z", "X", "C", "V", "F" }) do
            switchRow(v, k, (k == "V") and "Never on a transformation fruit (Kitsune's V transforms) - on for the rest" or nil,
                function() return (CFG.SeaEvKeys or {})[k] end,
                function(x)
                    CFG.SeaEvKeys = CFG.SeaEvKeys or {}
                    CFG.SeaEvKeys[k] = x
                end)
        end
        caption(v, "Every key the INSTANT it is ready (the moment the game takes it - not "
            .. "during another move - and the next one the frame it fires) - your "
            .. "Attack page is left for the normal farm. NO M1 at a sea event (an "
            .. "untransformed M1 does nothing to one): only Kitsune's, in Kitsune form. "
            .. "Which key hurts it is learned from its HP.")
        heading2(v, "what hurts a sea beast (learned)")
        readout(v, function()
            local rows = {}
            for key, L in pairs(P.seaev.learn or {}) do table.insert(rows, { key = key, L = L }) end
            table.sort(rows, function(a, b)
                local sa, sb = P.sea.keyScore(a.key, P.seaev.learn), P.sea.keyScore(b.key, P.seaev.learn)
                if sa ~= sb then return sa > sb end
                return a.key < b.key
            end)
            if #rows == 0 then return "nothing fired at a sea beast yet" end
            local out = {}
            for i, r in ipairs(rows) do
                if i > 10 then break end
                table.insert(out, string.format("%-24s hurt it %d of %d%s", r.key, r.L.closed, r.L.casts,
                    (r.L.closed == 0 and r.L.casts >= 4) and "  - does not" or ""))
            end
            return table.concat(out, "\n")
        end)

        heading2(v, "prehistoric hunt  (Third Sea)")
        readout(v, function()
            local s = P.sea
            local t = s.tally
            return table.concat({
                "now       " .. tostring(s.note),
                "boat      " .. tostring(s.boatNote)
                    .. (s.hp and string.format("  ·  %d / %s HP", s.hp, tostring(s.maxHp or "?")) or ""),
                string.format("where     %s  ·  danger %s",
                    s.meters and string.format("%d m from Tiki (%d studs)", math.floor(s.meters),
                        math.floor(s.meters * (CFG.SeaStudsPerM or 10))) or "not sailing",
                    tostring(s.danger or "-")),
                string.format("found     %d islands  ·  %d boats bought", t.found, t.buys),
            }, "\n")
        end)
        radio(v, 122, {
            { "manual", "I steer (A/D, W go, S stop)", "no hop by distance" },
            { "auto",   "Auto: west, next server at the edge", "" },
        }, function() return CFG.SeaSteer end, function(x) CFG.SeaSteer = x end)
        sliderRow(v, "Turn speed (A / D)", 20, 120, 5,
            function() return CFG.SeaTurnRate end,
            function(x) CFG.SeaTurnRate = x end, " deg/s")
        sliderRow(v, "Boat speed", 250, 350, 5,
            function() return CFG.SeaSpeed end,
            function(x) CFG.SeaSpeed = x end, " studs/s")
        sliderRow(v, "Auto: out to", 3000, 30000, 500,
            function() return CFG.SeaSearchTo end,
            function(x) CFG.SeaSearchTo = x end, " m")
        sliderRow(v, "Auto: then turn left", 0, 180, 5,
            function() return CFG.SeaTurnBack end,
            function(x) CFG.SeaTurnBack = x end, " deg")
        sliderRow(v, "Auto: and sail on (0 = next server)", 0, 20000, 500,
            function() return CFG.SeaLeg2 end,
            function(x) CFG.SeaLeg2 = x end, " m")
        switchRow(v, "Volcanic Magnet first",
            "Not in your inventory: crafted (15 Blaze Ember + 10 Scrap Metal), farmed first if short",
            function() return CFG.SeaMagnet end,
            function(x) CFG.SeaMagnet = x end)
        readout(v, function()
            local g = P.magnet
            if not g then return "-" end
            local c = g.inv
            return string.format("magnet     %s\nhave       %s", tostring(g.note),
                c and string.format("%d magnet  ·  %d / 15 Blaze Ember  ·  %d / 10 Scrap Metal", c.magnet, c.ember, c.scrap)
                    or "not read yet")
        end)
        sliderRow(v, "Safety cap: no island this long in a server (0 = off)", 0, 60, 1,
            function() return CFG.SeaSearchMinutes end,
            function(x) CFG.SeaSearchMinutes = x end, " min")
        sliderRow(v, "One compass meter", 5, 15, 0.5,
            function() return CFG.SeaStudsPerM end,
            function(x) CFG.SeaStudsPerM = x end, " studs")
        caption(v, "Meters are counted from the Tiki back boat dealer. Danger 6 "
            .. "starts about 2,600 m out. Check the \"where\" line against your "
            .. "compass once; if it drifts, move \"One compass meter\".")
        sliderRow(v, "Auto: a turn every", 20, 180, 5,
            function() return CFG.SeaTurnEvery end,
            function(x) CFG.SeaTurnEvery = x end, " s (up to 2x)")
        sliderRow(v, "Auto: a turn up to", 0, 45, 1,
            function() return CFG.SeaTurnMax end,
            function(x) CFG.SeaTurnMax = x end, " deg")
        caption(v, "Auto steering: at each turn, at random, left, right or straight "
            .. "on - never more than 45 deg off west, so it still goes out to sea.")
        caption(v, "The hunt buys a " .. tostring(CFG.SeaBoat) .. " at Tiki Outpost's BACK "
            .. "dealer, puts you at the wheel and drives west through the sea "
            .. "events. Island up: off the boat, onto the island, and it never "
            .. "leaves (the island goes when nobody is on it). Lost the boat at sea, "
            .. "or nothing by the far edge: the next server.")

        heading2(v, "the mirage hunts")
        readout(v, function()
            local s = P.sea
            local m = s.mirage
            local lines = {
                string.format("found     %d Mirages  ·  %d dealers  ·  %d chests  ·  %d Blue Gears",
                    s.tally.mirages, s.tally.dealers, s.tally.chests, s.tally.gears),
            }
            if m then
                table.insert(lines, string.format("this one  %s hunt  ·  %s%s", tostring(m.kind), tostring(m.why),
                    m.fits and "" or "  - sailed past"))
                if m.dealerFrom then table.insert(lines, "dealer    read in " .. tostring(m.dealerFrom)) end
                if m.note then table.insert(lines, "now       " .. tostring(m.note)) end
            end
            if P.handsOff then table.insert(lines, "YOUR TURN - the character is yours") end
            return table.concat(lines, "\n")
        end)
        caption(v, "Four hunts on the Hunt page, each only its job: the Mirage "
            .. "hunt puts you on it; the Advanced Fruit Dealer hunt puts you in "
            .. "front of him with his shop open (he stands at a random spot - "
            .. "not read = the island searched until he is); the chest hunt takes "
            .. "every chest; the Blue Gear hunt gives you the moon (a high point, "
            .. "face it, T) and runs over the gear the moment it shows. A Mirage "
            .. "already up = straight to the job, else the boat sails for one. "
            .. "Done = the farm stops and leaves you on it. A Mirage lives 15 min; "
            .. "dying or leaving makes it go.")
        heading2(v, "blue gear hunt: which mirage")
        radio(v, 122, {
            { "night", "One that sees night", "the gear needs it" },
            { "full",  "A full-moon night only", "" },
            { "any",   "Every Mirage", "" },
        }, function() return CFG.MirageNeed end, function(x) CFG.MirageNeed = x end)
        caption(v, "Only the Blue Gear hunt asks this (the gear needs night, 2 min "
            .. "to climb); the other Mirage hunts take every one.")

        heading2(v, "volcano event")
        switchRow(v, "Volcano event",
            "Whenever a Prehistoric Island is up (the Prehistoric hunt runs it anyway)",
            function() return CFG.Volcano end,
            function(x) CFG.Volcano = x end)
        radio(v, 82, {
            { "hop",   "After the loot: the next server", "the hunt goes on there - the loop" },
            { "again", "After the loot: again on this island", "the wiki: the event has no cooldown" },
        }, function() return CFG.VolcanoAfter end, function(x) CFG.VolcanoAfter = x end)
        sliderRow(v, "Stay after the loot (the game saves it) before the next server", 0, 300, 5,
            function() return CFG.LootStay end,
            function(x) CFG.LootStay = x end, " s")
        switchRow(v, "Home by respawn after the loot",
            "The stay over: reset - back at your spawn (Tiki), then the next server. Never with the chalice",
            function() return CFG.RespawnHome end,
            function(x) CFG.RespawnHome = x end)
        sliderRow(v, "The egg: stand still after E (its animation)", 0, 10, 0.5,
            function() return CFG.EggStay end,
            function(x) CFG.EggStay = x end, " s")
        sliderRow(v, "Each bone, at least", 0, 2, 0.1,
            function() return CFG.BoneMin end,
            function(x)
                CFG.BoneMin = x
                CFG.BoneMax = math.max(tonumber(CFG.BoneMax) or 1, x)
            end, " s")
        sliderRow(v, "Each bone, at most", 0, 3, 0.1,
            function() return CFG.BoneMax end,
            function(x)
                CFG.BoneMax = x
                CFG.BoneMin = math.min(tonumber(CFG.BoneMin) or 0.5, x)
            end, " s")
        readout(v, function()
            local s = P.sea
            local ev = s.ev
            local lines = {}
            local b, e = s.peek("Dinosaur Bones"), s.peek("Dragon Egg")
            table.insert(lines, "you have  " .. ((b and e) and string.format("%d Dinosaur Bones  ·  %d Dragon Egg  (%s)",
                b, e, tostring(s.invSrc)) or ("not readable - " .. tostring(s.invWhy or "not asked yet"))))
            if ev and ev.base then
                table.insert(lines, string.format("this one  bones %d confirmed%s  ·  egg %d confirmed%s  ·  before: %s",
                    ev.bones, ((ev.bonesGone or 0) > 0) and string.format(", %d went WITHOUT reaching you", ev.bonesGone) or "",
                    ev.eggs, ev.eggGone and ", one went WITHOUT reaching you" or "", s.lootText(ev.base)))
            end
            if s.lootCheck then table.insert(lines, "last hop  " .. tostring(s.lootCheck)) end
            return table.concat(lines, "\n")
        end)
        readout(v, function()
            local ev = P.sea.ev
            local t = P.sea.tally
            local lines = {}
            if ev then
                table.insert(lines, "now       " .. tostring(ev.note))
                table.insert(lines, string.format("this one  %s  ·  live vents %s  ·  golems %s  ·  you %s",
                    tostring(ev.phase or "-"), tostring(ev.liveVents or "-"), tostring(ev.liveGolems or "-"),
                    ev.counted and "COUNTED" or "not counted (not there at the start)"))
                table.insert(lines, string.format("          %d vents closed  ·  %d golems down  ·  %d bones  ·  %d eggs",
                    ev.vents, ev.golems, ev.bones, ev.eggs))
                table.insert(lines, string.format("meters    relic %s  ·  pressure %s  ·  relic lowest %s",
                    ev.relicPct and string.format("%.0f%%", ev.relicPct) or "not found",
                    ev.pressurePct and string.format("%.0f%%", ev.pressurePct) or "not found",
                    ev.relicLow and string.format("%.0f%%", ev.relicLow) or "-"))
                table.insert(lines, "read from " .. tostring(ev.relicSrc or "-") .. "  /  " .. tostring(ev.pressureSrc or "-"))
                table.insert(lines, string.format("golems    %s held up in the air  ·  %s NOT held",
                    tostring(ev.caged or 0), tostring(ev.freeGolems or 0)))
                table.insert(lines, "last key  " .. tostring(P.sea.lastVent or "-"))
            else
                table.insert(lines, "no Prehistoric Island in this server")
            end
            table.insert(lines, string.format("all       %d events  ·  %d vents  ·  %d golems  ·  %d bones  ·  %d eggs",
                t.events, t.vents, t.golems, t.bones, t.eggs))
            return table.concat(lines, "\n")
        end)
        heading2(v, "which keys close vents (learned)")
        readout(v, function()
            local rows = {}
            for key, L in pairs(P.sea.learn or {}) do table.insert(rows, { key = key, L = L }) end
            table.sort(rows, function(a, b)
                local sa, sb = P.sea.keyScore(a.key), P.sea.keyScore(b.key)
                if sa ~= sb then return sa > sb end
                return a.key < b.key
            end)
            if #rows == 0 then return "nothing fired at a vent yet" end
            local out = {}
            for i, r in ipairs(rows) do
                if i > 10 then break end
                table.insert(out, string.format("%-24s closed %d of %d%s", r.key, r.L.closed, r.L.casts,
                    (r.L.closed == 0 and r.L.casts >= 4) and "  - does not close them" or ""))
            end
            return table.concat(out, "\n")
        end)
        switchRow(v, "Silent aim", "Skills and aimed M1 go AT the target - your mouse is not read",
            function() return CFG.SilentAim end,
            function(x) CFG.SilentAim = x end)
        readout(v, function()
            return "silent aim  " .. tostring(P.silentNote or "-") .. "  (guns)"
                .. "\nskill aim   " .. tostring(P.gameAimText and P.gameAimText() or "-") .. "  (skills, a fruit's M1)"
        end)
        heading2(v, "the gun M1 at a vent")
        switchRow(v, "Skull Guitar M1 on the vents",
            "Loaded if in your inventory, fired at the vent stood still - before any skill",
            function() return CFG.VentGuitar end,
            function(x) CFG.VentGuitar = x end)
        readout(v, function()
            local S = P.sea
            local g = S.ventGun and S.ventGun()
            if not g then return "vent gun   none carried (Skull Guitar / Bazooka / Cannon)" end
            local L = S.learn[g .. " M1"]
            return string.format("vent gun   %s  ·  %s  ·  closed %d of %d turns", g,
                tostring(S.gunWay[g] or "not fired yet"), L and L.closed or 0, L and L.casts or 0)
        end)
        sliderRow(v, "Seconds between shots", 0.1, 1, 0.05,
            function() return CFG.VentM1Every end,
            function(x) CFG.VentM1Every = x end, " s")
        caption(v, "The wiki: Skull Guitar's M1 breaks things (Destructible Physics) "
            .. "and cools fast - made for the vents; Bazooka and Cannon too. Its M1 "
            .. "costs 20 energy: under that, the skills below until it is back. Six "
            .. "turns closing nothing = the skills instead.")

        heading2(v, "golem weapon")
        local gbox = chooser(v, 130)
        local gsig = nil
        local function grefresh()
            local names = {}
            for _, t in ipairs(toolNames()) do
                local ty = toolType(t)
                if ty == "Sword" or ty == "Melee" then table.insert(names, t.Name) end
            end
            table.sort(names)
            local cur = CFG.GolemWeapon or ""
            if cur ~= "" and not table.find(names, cur) then table.insert(names, 1, cur) end
            local sig = cur .. "|" .. table.concat(names, ",")
            if sig == gsig then return end
            gsig = sig
            for _, c in ipairs(gbox:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            chooserRow(gbox, 1, "The Attack page's M1 pick", "", cur == "", function()
                CFG.GolemWeapon = ""
                gsig = nil
                grefresh()
            end)
            for i, n in ipairs(names) do
                local t = findTool(n)
                chooserRow(gbox, i + 1, n, t and toolType(t) or "inventory", cur == n, function()
                    CFG.GolemWeapon = n
                    gsig = nil
                    grefresh()
                end)
            end
        end
        grefresh()
        addLive(grefresh)
        readout(v, function() return "golems   " .. tostring(P.sea.golemNote or "the event loads it when it starts") end)
        caption(v, "Its M1 swings on the Lava Golems (the strongest swing: Cursed Dual "
            .. "Katana 4100+, Hallow Scythe 3755). Not carried: loaded from your "
            .. "inventory when the event starts, and kept. Not found: the Attack page's pick.")

        heading2(v, "keys fired at a vent")
        for _, k in ipairs({ "Z", "X", "C", "V" }) do
            switchRow(v, k, nil,
                function() return (CFG.VentKeys or {})[k] end,
                function(x)
                    CFG.VentKeys = CFG.VentKeys or {}
                    CFG.VentKeys[k] = x
                end)
        end
        caption(v, "No vent gun (or its energy low): every weapon you carry fires "
            .. "these, guns first, aimed AT the vent. Only moves that break things "
            .. "close one; a key whose skill does not fire is left out for 30 s. "
            .. "Everything cooling: a sword / gun from your inventory, then an aimed M1.")
        sliderRow(v, "Stand off a vent", 4, 30, 1,
            function() return CFG.VentDistance end,
            function(x) CFG.VentDistance = x end, " studs")
        heading2(v, "lava golems")
        sliderRow(v, "Held off the relic", 30, 150, 5,
            function() return CFG.GolemCage end,
            function(x) CFG.GolemCage = x end, " studs")
        sliderRow(v, "Held up in the air", 0, 150, 5,
            function() return CFG.GolemLift end,
            function(x) CFG.GolemLift = x end, " studs")
        caption(v, "Magnet on: every golem is lifted there the moment it lands and "
            .. "held the whole event - held, it cannot touch the relic - and "
            .. "never put back. One that cannot be held (not ours to move) is "
            .. "fought first where it stands. Held ones die when no vent is open "
            .. "(your Attack page weapons). Magnet off: golems first, always.")
        heading2(v, "priority")
        sliderRow(v, "Keep the relic over", 50, 100, 1,
            function() return CFG.RelicMin end,
            function(x) CFG.RelicMin = x end, " %")
        sliderRow(v, "Pressure that comes first", 20, 100, 5,
            function() return CFG.PressureMax end,
            function(x) CFG.PressureMax = x end, " %")
        caption(v, "A golem not held goes first. Only when the pressure is over "
            .. "its limit AND the relic is still over yours does a vent go first "
            .. "instead. The meters are read off the game; the first seconds of "
            .. "each event write what was found to workspace/bff_volcano_probe.txt.")
        switchRow(v, "Bones and the egg after a win", nil,
            function() return CFG.VolcanoLoot end,
            function(x) CFG.VolcanoLoot = x end)
        caption(v, "The egg needs the Dragon Tether, a hit on a golem or vent, and "
            .. "the relic over 90% at the end.")
    end

    -- =====================================================
    -- STATS
    -- =====================================================
    do
        local v = makeView("stats")
        gap(v, 8)
        heading2(v, "which setup is better")
        readout(v, function()
            local lines = {}
            local m = meas
            if m then
                local kpm = (m.fight > 0) and (m.kills / (m.fight / 60)) or 0
                table.insert(lines, "THIS SETUP")
                table.insert(lines, "   " .. m.key)
                table.insert(lines, string.format("   %.1f kills/min  ·  pile %s  ·  %d piles  ·  %s fighting",
                    kpm, (m.piles > 0) and string.format("%.1fs", m.pileSecs / m.piles) or "-",
                    m.piles, mmss(m.fight)))
            end
            if #tried > 0 then
                table.insert(lines, "")
                table.insert(lines, "TRIED")
                for _, t in ipairs(tried) do
                    table.insert(lines, string.format("   %.1f kills/min  ·  %s  ·  %s",
                        t.kpm, t.avg and string.format("pile %.1fs", t.avg) or "pile -", mmss(t.secs)))
                    table.insert(lines, "      " .. t.key)
                end
            end
            return table.concat(lines, "\n")
        end)
        caption(v, "Change any attack switch or the M1 count and this setup "
            .. "moves to TRIED with its numbers. Only fighting time counts, so "
            .. "flights do not punish a setup. Run each a few minutes on the "
            .. "same camp.")
        actionRow(v, "Clear the tried list", nil, function() table.clear(tried) end)

        heading2(v, "counters")
        readout(v, function()
            local mins = math.max((os.clock() - stats.startedAt) / 60, 1 / 60)
            return table.concat({
                string.format("state       %s   %.0fs", state, os.clock() - stateEnteredAt),
                "target      " .. tostring(activeName or "-"),
                "in hand     " .. tostring(P.heldTool() or "-"),
                "kills       " .. stats.kills .. string.format("   %.1f/min overall", stats.kills / mins),
                "piles       " .. stats.piles,
                "M1          " .. stats.m1 .. "   skills " .. stats.casts
                    .. string.format(" (%d fired, %d hit, %d did not fire)", stats.castsTook,
                        stats.castsHit, stats.castsMissed)
                    .. "   swaps " .. stats.swaps,
                "probes      " .. stats.probes .. "   (M1 ways tried)",
                "travel      " .. stats.flights .. " flights   " .. stats.hops .. " hops   "
                    .. stats.pulledBack .. " pulled back",
                "magnet      held " .. tostring(P.pileHeld) .. "   put back " .. stats.putBack,
                "escapes     " .. stats.escapes,
                "haki        " .. stats.hakiPresses .. "   (J/E presses)",
                "status      " .. statusLine,
            }, "\n")
        end)
        actionRow(v, "Reset the counters", nil, function()
            for k in pairs(stats) do stats[k] = 0 end
            stats.startedAt = os.clock()
            say("counters reset")
        end)
        hairline(v)
        switchRow(v, "Print debug to the console", nil,
            function() return CFG.Debug end,
            function(x) CFG.Debug = x end)
        gap(v, 8)
        actionRow(v, "Stop and close the panel", "danger", function()
            P.stop()
            if gui then gui:Destroy() end
        end)
    end

    show("home")

    task.spawn(function()
        while gui and gui.Parent do
            dot.BackgroundColor3 = P.running and C.live or C.third
            for _, e in ipairs(live) do
                if not e.v or e.v.Visible then pcall(e.f) end
            end
            task.wait(0.3)
        end
    end)
end

-- The panel. A failure is SAID now - it used to vanish inside a pcall (no
-- panel, not a word). _G.BFF.panel() builds it again, from the console.
function P.panel()
    local ok, e = pcall(buildUI)
    if not ok then warn("[BFF] the panel failed to build: " .. tostring(e)) end
    return ok
end

-- =========================================================
-- API
-- =========================================================
function P.start()
    if P.running then P.stop() end
    for k in pairs(stats) do stats[k] = 0 end
    stats.startedAt = os.clock()
    activeName, countedDead, circuitIdx = nil, {}, 1
    releasePile()
    table.clear(pileWatch)
    lockCF, lastWritten, flying = nil, nil, false
    P.handsOff = false
    wantPose = "safe"
    P.running   = true
    moveEnabled = true
    pcall(syncWeapons)
    rollMeas()

    -- Haki: as farm_pro. Enhancement off at start = a fresh life, both go
    -- back on; otherwise Observation gets its timed look straight away.
    seenChar, seenCharAt = player.Character, os.clock() - 10
    busoTries = 0
    P.kenDone = false
    kenNextAt, kenVerifyAt, kenMisses, kenBlind = 0, nil, 0, false
    if CFG.AutoBuso and not hasBuso() then
        kenChar = nil
    else
        kenChar = player.Character
    end

    track(RunService.Stepped:Connect(function() pcall(bodyStepped) end))
    track(RunService.Heartbeat:Connect(function(dt)
        pcall(bodyHeartbeat)
        pcall(magnetTick)
        if P.running and os.clock() < aimUntil then
            -- A point of its own (a volcano vent): always aimed at, hidden.
            if P.aimAt then
                pcall(aimSwapIn, P.aimAt, P.aimAt)
            elseif CFG.AimSkills and CFG.AimHidden and pileCentre then
                pcall(aimSwapIn, aimPoint(), pileCentre)
            end
        end
        if attacking and meas then meas.fight += dt end
        pcall((P :: any).gunWatch)
        pcall((P :: any).silentTick, P.aimTarget() ~= nil)
    end))
    -- The aim lock: after the camera scripts, every frame the pile is hit.
    pcall(hiddenAim, true)
    pcall(function() RunService:UnbindFromRenderStep("BFFAim") end)
    pcall(function()
        RunService:BindToRenderStep("BFFAim", Enum.RenderPriority.Camera.Value + 1, function()
            if P.running and attacking and CFG.AimSkills and not CFG.AimHidden and pileCentre then
                aimCamera(aimPoint(), pileCentre)
            end
        end)
    end)
    track(player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end))
    track(player.CharacterAdded:Connect(function()
        releasePile()
        attacking = false
        releaseCamera()
    end))
    if not (gui and gui.Parent) then P.panel() end

    task.spawn(mainLoop)
    task.spawn(sideLoop)
    print("[BFF] running - build " .. tostring(P.build) .. ". _G.BFF.stop() to halt.")
end

-- why = "reload": a new copy of the script is replacing this one (the top of
-- the file) -- not you stopping, so a hunt carried over a hop stays carried.
function P.stop(why)
    if why ~= "reload" then pcall(P.carryOff) end
    P.running = false
    epoch += 1                 -- everything in flight gives up on this line
    moveEnabled = false
    task.delay(0.3, function() moveEnabled = true end)
    releasePile()
    attacking, flying = false, false
    lockCF, lastWritten = nil, nil
    pcall(function() RunService:UnbindFromRenderStep("BFFAim") end)
    aimUntil = 0
    P.aimAt = nil
    pcall((P :: any).gunRelease)
    P.gunFocus = nil
    pcall((P :: any).silentOff)
    task.spawn(function() pcall((P :: any).rotRestore) end)
    if P.sea then P.sea.driving = false end    -- the boat stops; you stay in your seat
    P.handsOff = false
    pcall(hiddenAim, false)
    pcall(releaseCamera)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    pcall(restoreBody)
    setState("IDLE")
    say("stopped")
    print(string.format("[BFF] stopped. kills=%d piles=%d", stats.kills, stats.piles))
end

function P.stats() return stats end
function P.state() return state, statusLine end

-- =========================================================
-- THE TEAM
-- =========================================================
-- Every join asks Pirates or Marines before your character spawns -- so
-- every hop does. Picked for you (CFG.AutoTeam, CFG.Team): CommF_("SetTeam",
-- team), as the public hubs do (2026-04 .. 2026-09-29), every 2 s until you
-- are on one. Only while you have no team: the one you are on is never
-- switched. NOT the screen's own button through getconnections -- firing a
-- game's connections natively is the one call here an executor can crash
-- on (removed 2026-09-30 while client crashes on join were being traced).
P.teamNote = "not needed yet"
function P.pickTeam()
    while _G.BFF == P and player.Team == nil do
        local team = CFG.Team
        if CFG.AutoTeam and (team == "Pirates" or team == "Marines") then
            local cf = commF()
            if cf then pcall(function() cf:InvokeServer("SetTeam", team) end) end
            task.wait(2)
            P.teamNote = (player.Team == nil) and ("asking for " .. team .. " ...") or P.teamNote
        else
            P.teamNote = "choose your team - picking it is off"
            task.wait(1)
        end
    end
    if player.Team then
        P.teamNote = "on " .. player.Team.Name
        -- The team is set; its screen is not needed (the remote does not
        -- always close it).
        pcall(function()
            local ct = player.PlayerGui.Main.ChooseTeam
            if ct.Visible then ct.Visible = false end
        end)
    end
end

-- =========================================================
-- SILENT AIM
-- =========================================================
-- The camera swap points the line through your cursor at the target, but a
-- skill that reads the mouse itself still went where the cursor was (user,
-- the volcano, 2026-10-04). So, while P.aimTarget() names a point (only while
-- this script fires), Mouse.Hit / Target / X / Y / UnitRay answer for the
-- target. The script's own reads (checkcaller) are left alone.
--
-- ONLY __index, and ONLY while casting (user, the same day: NPCs invisible,
-- the sea's darkness gone). The first version also hooked __namecall, for
-- the whole session: every WaitForChild / InvokeServer of every game script
-- went through it, and where the executor's newcclosure cannot yield those
-- scripts died - the NPC loader and the sea's lighting among them. Now the
-- hook goes in when a cast starts and the original goes back 3 s after the
-- last one (and on stop) - nothing of the game's runs through it otherwise.
do
    local function build()
        local IDLE_OFF = 3
        local oldIndex = nil      -- the game's own __index while ours is in
        local lastWant = 0

        local function canHook() return hookmetamethod ~= nil end
        P.silentHooked = function() return oldIndex ~= nil end

        if _G.BFF_SILENT_HOOKED and not _G.BFF_SILENT_V2 then
            -- An older copy's whole-session hook is still in this game, and
            -- it cannot be taken out from here.
            P.silentNote = "an old copy's hook is still in this game - REJOIN (it hides NPCs and the sea's darkness)"
            print("[BFF] " .. P.silentNote)
        elseif not canHook() then
            P.silentNote = "this executor cannot hook calls - the camera aim only"
        else
            P.silentNote = "ready (hooks only while casting)"
        end
        _G.BFF_SILENT_V2 = true

        local function aimNow()
            if not (P.running and CFG.SilentAim) then return nil end
            local ok, t = pcall(P.aimTarget)
            return ok and t or nil
        end

        -- THE GAME'S OWN SKILL AIM (2026-10-09, read in the decompiled client
        -- v4623). Skills, and a fruit's M1 (sent as the key G), never read
        -- your PlayerMouse: MovesetClientRunner's sendMouse does
        -- RemoteEvent:FireServer(Mouse.Hit.Position) with Mouse =
        -- require(ReplicatedStorage.Mouse) - a plain table the game aims
        -- again every frame (a ray from the camera through the cursor). The
        -- hook on the PlayerMouse below reached guns only (CombatController's
        -- shot reads the PlayerMouse). Here, while this script casts, that
        -- table's Hit / Target answer the target; the game's own writes go
        -- to a shadow and are put back the moment the casting is over (the
        -- same 3 s rule). The table's own metatable, pure Lua: no game call
        -- goes through it - only reads of that one table's Hit / Target.
        -- (The public hubs swap the remote's argument with a session-long
        -- __namecall hook instead - the one that broke this game's scripts.)
        local modT, modMt, modOld, shadow = nil, nil, nil, nil
        local function gameMouse()
            if modT then return modT end
            local ok, m = pcall(function()
                local ms = RS:FindFirstChild("Mouse")
                return ms and require(ms)
            end)
            if ok and type(m) == "table" then modT = m end
            return modT
        end
        local function modOn()
            if modOld then return end
            local m = gameMouse()
            if not m then return end
            local mt = getmetatable(m)
            if type(mt) ~= "table" then
                mt = {}
                if not pcall(setmetatable, m, mt) then return end
            end
            modMt, shadow = mt, { Hit = rawget(m, "Hit"), Target = rawget(m, "Target"), writes = 0 }
            modOld = { index = rawget(mt, "__index"), newindex = rawget(mt, "__newindex") }
            local oldIdx = modOld.index
            mt.__newindex = function(t, k, v)
                if k == "Hit" or k == "Target" then
                    shadow[k] = v
                    if k == "Hit" then shadow.writes += 1 end
                    return
                end
                rawset(t, k, v)
            end
            mt.__index = function(t, k)
                if k == "Hit" or k == "Target" then
                    local tgt = aimNow()
                    if tgt then
                        if k == "Target" then
                            local part = P.aimPart
                            if part and part.Parent then return part end
                            return shadow.Target
                        end
                        local cam = workspace.CurrentCamera
                        local o = cam and cam.CFrame.Position or tgt
                        local d = tgt - o
                        return (d.Magnitude > 0.01) and CFrame.lookAt(tgt, tgt + d.Unit) or CFrame.new(tgt)
                    end
                    return shadow[k]
                end
                if type(oldIdx) == "function" then return oldIdx(t, k) end
                if type(oldIdx) == "table" then return oldIdx[k] end
                return nil
            end
            rawset(m, "Hit", nil)
            rawset(m, "Target", nil)
            P.gameAimSeen = P.gameAimSeen or 0
        end
        local function modOff()
            if not modOld then return end
            modMt.__index, modMt.__newindex = modOld.index, modOld.newindex
            modOld = nil
            P.gameAimSeen = (P.gameAimSeen or 0) + shadow.writes
            rawset(modT, "Hit", shadow.Hit or CFrame.new())
            rawset(modT, "Target", shadow.Target)
        end
        P.gameAimHooked = function() return modOld ~= nil end
        -- What the panel says: in / ready, and whether the game was seen
        -- writing to that table (= it IS the game's own, not a copy).
        function P.gameAimText()
            if not gameMouse() then return "the game's skill aim (ReplicatedStorage.Mouse) not found" end
            local seen = (P.gameAimSeen or 0) + (modOld and shadow.writes or 0)
            return (modOld and "in (casting)" or "ready")
                .. ((seen > 0) and "  ·  the game's own table (it aims it, seen)"
                    or (P.gameAimSeen and "  ·  the game never wrote it while hooked - not its table?" or ""))
        end

        function P.silentOff()
            modOff()
            if not oldIndex then return end
            local o = oldIndex
            oldIndex = nil
            pcall(hookmetamethod, game, "__index", o)
            _G.BFF_SILENT_OFF = nil
            if not (_G.BFF_SILENT_HOOKED and P.silentNote and string.find(P.silentNote, "REJOIN", 1, true)) then
                P.silentNote = "ready (hooks only while casting)"
            end
        end

        local function silentOn()
            if oldIndex or not canHook() then return end
            -- A copy that was replaced without its stop: its hook out first.
            if _G.BFF_SILENT_OFF then pcall(_G.BFF_SILENT_OFF) end
            local cc = checkcaller or function() return false end
            local wrap = newcclosure or function(f) return f end
            local mouse = player:GetMouse()
            local mine
            mine = wrap(function(self, key)
                -- The script's own reads see your real mouse - except while it
                -- runs the game's own gun shot (P.inGameShot, THE GUN): that is
                -- the game reading it, on this script's thread.
                if (key == "Hit" or key == "Target" or key == "UnitRay" or key == "X" or key == "Y")
                    and rawequal(self, mouse) and (P.inGameShot or not cc()) then
                    local t = aimNow()
                    if t then
                        local cam = workspace.CurrentCamera
                        local o = cam and cam.CFrame.Position or t
                        local d = t - o
                        if key == "Hit" then
                            return (d.Magnitude > 0.01) and CFrame.lookAt(t, t + d.Unit) or CFrame.new(t)
                        elseif key == "UnitRay" then
                            return Ray.new(o, (d.Magnitude > 0.01) and d.Unit or Vector3.new(0, -1, 0))
                        elseif key == "Target" then
                            local part = P.aimPart
                            if part and part.Parent then return part end
                        elseif cam then
                            local sp = cam:WorldToScreenPoint(t)
                            return (key == "X") and sp.X or sp.Y
                        end
                    end
                end
                return oldIndex(self, key)
            end)
            local ok, old = pcall(hookmetamethod, game, "__index", mine)
            if ok and old then
                oldIndex = old
                _G.BFF_SILENT_OFF = P.silentOff
                if not string.find(tostring(P.silentNote), "REJOIN", 1, true) then
                    P.silentNote = "in (casting)"
                end
            else
                P.silentNote = "the hook failed - the camera aim only"
            end
        end

        -- Every frame: want = the script is firing at a point right now.
        function P.silentTick(want, now)
            now = now or os.clock()
            if want and CFG.SilentAim and P.running then
                lastWant = now
                silentOn()
                modOn()
            elseif (oldIndex or modOld) and (now - lastWant > IDLE_OFF or not CFG.SilentAim or not P.running) then
                P.silentOff()
            end
        end
    end
    build()
end
-- (end of silent aim)

-- Arrived by an elite hunt's hop: its settings back, and the hunt goes on.
do
    local resumed = false
    pcall(function() resumed = P.takeCarry() end)
    -- The team AFTER the carried settings: the one you picked, not the default.
    task.spawn(function() pcall(P.pickTeam) end)
    pcall(syncWeapons)
    say(resumed and ("elite hunt carried over (" .. tostring(P.elite.carried) .. ")")
        or "loaded - pick targets, then press Start")
    P.panel()
    if resumed then task.defer(P.start) end
end
-- Water is land from load, farm running or not (farm_pro's, unchanged).
task.spawn(function()
    while _G.BFF == P do
        pcall(keepWater)
        task.wait(0.25)
    end
end)
-- The server news: one look a second from load, farm running or not.
task.spawn(function()
    while _G.BFF == P do
        pcall(P.news.tick)
        task.wait(1)
    end
end)
do
    local deepConn
    deepConn = RunService.Heartbeat:Connect(function()
        if _G.BFF ~= P then
            deepConn:Disconnect()
            parkFloor()
            return
        end
        pcall(deepTick)
    end)
end
print("[BFF] loaded. Use the panel, or _G.BFF.start()")
