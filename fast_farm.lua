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
               it came in.

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
    -- than others that still do.
    MaxPull            = 300,
    LearnLeash         = true,
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
    M1Every            = 0.12,   -- seconds between M1s
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
    CamDistance        = 30,     -- the camera this far from the pile
    CamPitch           = 55,     -- looking down at most this steeply (degrees)

    -- ---------- WEAPONS ----------
    -- [tool name] = { use, M1, Z, X, C, V, F, hold = { Z = seconds, ... } }
    -- Filled from your backpack. Everything off except, on the very first
    -- load, M1 of whatever is in your hand.
    Weapons            = {},
    WeaponOrder        = {},

    -- ---------- TRAVEL ----------
    TravelSpeed        = 330,    -- studs/s. The public hubs all settled on 330.
    InstantHop         = 150,    -- shorter than this: one write, no flight

    -- ---------- RAID MODE ----------
    -- Species and quests forgotten: every living enemy, any kind, within
    -- RaidRadius of the newest raid island (of you, outside a raid) goes in
    -- one pile. Observation is not pressed (raids switch it off).
    RaidMode           = false,
    RaidRadius         = 450,    -- the public raid scripts' "on this island"

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
    HuntKind           = "elite",    -- "elite" | "fruit" | "berry"
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
    -- ELITE PIRATE HUNT (Third Sea). Diablo, Deandre, Urban (and Tyrant of
    -- the Skies while he is up): one per server, back 8 min 45 s after the
    -- last one died. Only the LAST hit gets the drops -- the God's Chalice
    -- among them. Fought where it stands, never pulled.
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

local P = { running = false, config = CFG }
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
    for _, src in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
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
    if not P.running then return end
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
    if not P.running then return end
    local _, r, h = parts()
    if not r or not h then return end
    h.AutoRotate = false
    if not flying then
        -- SOMETHING ELSE MOVED THE BODY. A respawn, the submarine, the game's
        -- own teleport: the body is far from where this script last put it.
        -- Stay where the game put us instead of dragging the body back.
        if lastWritten and (r.Position - lastWritten).Magnitude > 50 then
            local rot = lockCF and (lockCF - lockCF.Position) or (r.CFrame - r.CFrame.Position)
            lockCF = CFrame.new(r.Position) * rot
        end
        if not lockCF then lockCF = r.CFrame end
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
        local at = target + (away * math.cos(e) + Vector3.new(0, math.sin(e), 0)) * (CFG.CamDistance or 30)
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
    local cap = math.max(1, math.floor(CFG.GrabMax or 12))

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

    for _, e in ipairs(others) do
        if #group >= cap then break end
        if (homeOf(e) - centre).Magnitude <= (CFG.OthersRadius or 100) then
            table.insert(group, e)
        end
    end
    return group, centre
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
        local cap = math.max(1, math.floor(CFG.GrabMax or 12))
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
-- (P.raidAt), or round you outside a raid, within RaidRadius - every one
-- pulled (raid enemies have no leash). One that takes no damage when pulled
-- is no longer put back and LEFT OUT: that left the wave stuck with it alive
-- while the farm waited over the island (2026-09-28, "2 of 5 never hurt").
-- It is fought where it stands once the free ones are dead.
P.raidAt, P.raidNote = nil, "raid mode: starting"
local function buildRaidPile()
    local _, r = parts()
    if not r then return {}, nil, false end
    return buildRandomPile(P.raidAt or r.Position, CFG.RaidRadius or 450, true)
end

-- ELITE HUNT's pile: the one elite, nearest you, fought WHERE IT STANDS. Never
-- pulled: a pulled one that took no damage would be put back and left alone
-- for thirty seconds -- on the one target the hunt is for.
local function buildElitePile(cur)
    local _, r = parts()
    if not r then return {}, nil end
    local best, bd = nil, math.huge
    for _, e in ipairs(liveEnemies({ [cur.name] = true })) do
        local d = (e.root.Position - r.Position).Magnitude
        if d < bd then best, bd = e, d end
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
    elseif pileCur.elite then
        list, centre = buildElitePile(pileCur)
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
local function magnetTick()
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
    local n = #pile
    local held, owned = 0, 0
    for i, e in ipairs(pile) do
        if e.model.Parent and e.hum.Health > 0 then
            -- Owned = where we wrote it last frame is where it still is.
            local prev = lastDest[e.model]
            if prev and (e.root.Position - prev).Magnitude < 4 then owned += 1 end
            local a    = (i - 1) / math.max(n, 1) * math.pi * 2
            local rad  = (n > 1) and (CFG.PileSpread or 3) or 0
            local dest = pileCentre + Vector3.new(math.cos(a) * rad, 0, math.sin(a) * rad)
            pcall(function()
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
    end
    P.pileHeld, P.pileOwned = held, owned
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
function P.noteNoDamage(e, how)
    local bits = {}
    -- Only while it is being pulled: in place, lastDest is an old pull's.
    local dest = (not P.pileInPlace) and lastDest[e.model] or nil
    if dest then
        local gap = (e.root.Position - dest).Magnitude
        table.insert(bits, (gap > 4) and string.format("NOT OURS (really %.0f from where it was put)", gap) or "held, ours")
    end
    if isnetworkowner then
        local ok, own = pcall(isnetworkowner, e.root)
        if ok then table.insert(bits, own and "network owner you" or "network owner NOT you") end
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
        if not j then
            pileJoin[e.model] = { at = now, hp = e.hum.Health, act = actions }
        elseif e.hum.Health < j.hp - 0.5 then
            j.at, j.hp, j.act, j.hit = now, e.hum.Health, actions, true
        elseif now - j.at > 6 and actions - j.act >= 6 and not P.forceClose then
            P.noteNoDamage(e, "in place, from high")
            P.forceClose = true          -- poseTarget takes you close from the next frame
        elseif now - j.at > 15 and actions - j.act >= 15 then
            P.noteNoDamage(e, "in place, close")
            -- An elite is never skipped: it is the only one there is.
            if not (pileCur and pileCur.elite) then
                P.randomSkip[e.model] = now + 60
                P.randomCant += 1
            end
            pileJoin[e.model] = nil
        end
        return
    end
    if not CFG.Magnet then return end
    for _, e in ipairs(pile) do
        local j = pileJoin[e.model]
        if not j then
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
        elseif now - j.at > (CFG.PutBackAfter or 3) and actions - j.act >= 6 then
            -- No damage. If one pulled from NEARER its spawn in this same pile
            -- did take damage, the distance is why: that is the limit for its
            -- kind. (Without that contrast it may just not be ours to move.)
            local spawnAt = homePos[e.model]
            if CFG.LearnLeash and spawnAt and pileCentre and e.name then
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
            P.noteNoDamage(e, "pulled")
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
    for _, e in ipairs(pile) do
        if e.model.Parent and e.hum.Health > 0 then return e.root.Position end
    end
    return pileCentre
end

-- =========================================================
-- WHERE YOU HANG
-- =========================================================
local wantPose = "safe"      -- "safe" (high) or "melee" (close beside)

local function poseTarget()
    if not pileCentre then return nil end
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
    return c + Vector3.new(0, CFG.HeightSafe or 20, 0)
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

-- The weapons that are on AND in your backpack, in your order.
local function usedWeapons()
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
            if w[k] then
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
-- kept, per weapon. The panel says which.
local m1Plan  = {}           -- [weapon] = chosen way, or false (nothing landed)
P.m1Notes     = {}
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
        return out
    end

    local function m1Remote(variant, list)
        local ra = netRemote("RE", "RegisterAttack")
        local rh = netRemote("RE", "RegisterHit")
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
        else
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
    return "key press, " .. where
end
P.describeWay = describeWay

local probeM1
do
    local function waysFor(tool)
        local t = toolType(tool)
        local all = {}
        if t == "Melee" or t == "Sword" then
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
                task.wait(math.max(CFG.M1Every or 0.12, 0.06))
            end
            task.wait(0.2)
            local landed = (hp0 - sumHP()) > 0.5
            table.insert(tried, describeWay(way) .. (landed and ": landed" or ": nothing"))
            if landed then
                probing = false
                m1Plan[name] = way
                P.m1Notes[name] = describeWay(way)
                say(name .. " M1: " .. describeWay(way))
                return way
            end
        end
        probing = false
        if #tried == 0 then return nil end              -- interrupted: try again later
        m1Plan[name] = false
        P.m1Notes[name] = "nothing landed  (" .. table.concat(tried, "; ") .. ")"
        return false
    end
end

function P.reprobe()
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

local function castSkill(u, k)
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
    holdKey(KEYCODE[k], hold, before)
    local c = cdOf(u.name, k)
    c.lastCast = os.clock()
    stats.casts += 1
    actions += 1
    task.wait(CFG.CastWait or 0.45)
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
    if b == false then
        stats.castsTook += 1
        tally.fired += 1
        P.lastCast = key .. ": fired" .. tail
    elseif b == true then
        stats.castsMissed += 1
        P.lastCast = key .. ": key sent, the skill did NOT fire"
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

    if anySkill and (not m1u or m1Count >= (CFG.M1Between or 0)) then
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
        if not m1u then
            P.nextNote = "every skill cooling"
            task.wait(0.1)
            return
        end
    end

    if m1u then
        if not equip(m1u.name) then task.wait(0.1) return end
        local way = m1Plan[m1u.name]
        if way == nil then
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
            task.wait(math.max(CFG.M1Every or 0.12, 0.03))
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
    local bits, anyM1, anyKey = {}, false, false
    for _, name in ipairs(CFG.WeaponOrder) do
        local w = CFG.Weapons[name]
        if w and w.use then
            local s = wSummary(name)
            if s ~= "off" then table.insert(bits, name .. " " .. s) end
            if w.M1 then anyM1 = true end
            for _, k in ipairs(KEYS) do if w[k] then anyKey = true end end
        end
    end
    if #bits == 0 then return "nothing on" end
    local key = table.concat(bits, "  +  ")
    if anyM1 and anyKey then
        key = key .. string.format(",  %d M1 between, %s first", CFG.M1Between or 0,
            CFG.StartWith == "M1" and "M1" or "skills")
    end
    return key
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
            for i = 5, 1, -1 do
                local p = loc:FindFirstChild("Island " .. i)
                local pos = p and ((p:IsA("BasePart") and p.Position) or (p:IsA("Model") and p:GetPivot().Position))
                if pos then return on, pos, i, text end
            end
        end
        return on, nil, 0, text
    end
    P.raidState = raidState

    function raidStep()
        local on, islandPos, n, text = raidState()
        P.raidAt = islandPos
        local list = buildRaidPile()
        if islandPos or on then
            P.raidNote = string.format("in a raid  ·  Island %d%s  ·  %d enemies here", n,
                text and ("  ·  " .. text) or "", #list)
        else
            P.raidNote = string.format("not in a raid  ·  everything within %d studs of you  ·  %d enemies",
                math.floor(CFG.RaidRadius or 450), #list)
        end
        -- The damage check at work: fought where it stands (it took no damage
        -- when pulled), and how many could not be hurt at all.
        if P.pileInPlace then P.raidNote = P.raidNote .. "  ·  one fought where it stands" end
        if P.randomCant > 0 then P.raidNote = P.raidNote .. "  ·  could not hurt " .. P.randomCant end
        if #list > 0 then
            activeName = "raid"
            fight({ name = "raid", raid = true }, nil)
            return
        end
        -- Nobody here: over the newest island, and wait for its wave.
        local _, r = parts()
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
        say(islandPos and ("raid: Island " .. n .. " - waiting for enemies")
            or "raid mode: no enemy near you")
        task.wait(0.25)
    end

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
                v = 1, userId = player.UserId, resume = resume and true or false,
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
            if type(t.cfg) == "table" then
                for k, v in pairs(t.cfg) do
                    if CFG[k] ~= nil then CFG[k] = v end
                end
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
        -- every teleport call.
        local function hop(why)
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
            E.visited[game.JobId] = now
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

        -- Fly to the bush and fire each berry's prompt (as the hubs do, from
        -- within 15 studs) until the bush names none. Picked = your count went
        -- up; gone without that = someone else, or the count cannot be read.
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
            local t0 = os.clock()
            while os.clock() - t0 < 6 and not stale(myEpoch) do
                local okA, attrs = pcall(function() return b.bush:GetAttributes() end)
                if not okA or #berryNames(attrs) == 0 then break end
                local prompts = {}
                pcall(function()
                    for _, d in ipairs(b.bush:GetDescendants()) do
                        if d:IsA("ProximityPrompt") then table.insert(prompts, d) end
                    end
                end)
                for _, pr in ipairs(prompts) do
                    local at = b.pos
                    pcall(function()
                        local p = pr.Parent
                        if p:IsA("BasePart") then at = p.Position
                        elseif p:IsA("Attachment") then at = p.WorldPosition
                        elseif p:IsA("Model") then at = p:GetPivot().Position end
                    end)
                    lockAt(at + Vector3.new(0, 3, 0))
                    task.wait(0.05)
                    if fireproximityprompt then
                        pcall(fireproximityprompt, pr)
                    else
                        pcall(function()
                            pr:InputHoldBegin()
                            task.wait((pr.HoldDuration or 0) + 0.05)
                            pr:InputHoldEnd()
                        end)
                    end
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
                E.berryNote = "PICKED " .. table.concat(got, " + ")
                notify("Berry: " .. table.concat(got, " + "))
            elseif #left == 0 then
                E.berryNote = table.concat(b.names, " + ") .. ": gone from the bush, your count did not go up"
                    .. (now.read and "" or " (inventory not readable)")
            else
                E.berrySkip[b.bush] = os.clock() + 60
                E.berryNote = table.concat(left, " + ") .. ": could not pick - left for a minute"
            end
            E.note = E.berryNote
            say(E.berryNote)
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
                hop(E.why or "nothing worth doing here")
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
            CFG.Hunt = x and true or false
            releasePile()
            if x then
                CFG.RaidMode, CFG.RandomMode = false, false
                E.used = true
                lookAgain()
                E.note = tostring(CFG.HuntKind) .. " hunt on"
            else
                carryOff()
                E.note = "hunt off"
            end
            say(E.note)
        end
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
    if healthPct() < (CFG.EscapeBelow or 0.35) then
        escape()
        return
    end
    pcall(keepHaki)

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

    local panel = mk("Frame", {
        Size = UDim2.fromOffset(342, 540),
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
        TextColor3 = C.text, Text = "Fast Farm", Parent = panel,
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
        Size = UDim2.new(1, 0, 1, -52), Position = UDim2.fromOffset(0, 52),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = panel,
    })

    local folded = false
    foldBtn.Activated:Connect(function()
        folded = not folded
        bodyFrame.Visible = not folded
        foldBtn.Text = folded and "Show" or "Hide"
        tween(panel, { Size = UDim2.fromOffset(342, folded and 52 or 540) })
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
        home = "Fast Farm", target = "Targets", attack = "Attack", weapon = "Weapon",
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
            "Every enemy near you, any kind - no quests, no Observation",
            function() return CFG.RaidMode end,
            function(x)
                if x and CFG.Hunt then P.setHunt(false) end
                CFG.RaidMode = x
                if x then CFG.RandomMode = false end
                releasePile()
                say(x and "raid mode on" or "raid mode off - back to the circuit")
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
        readout(v, function()
            if CFG.Hunt then
                local t = P.elite.tally
                local k = CFG.HuntKind
                local count = (k == "fruit") and string.format("%d fruits stored", t.fruits or 0)
                    or (k == "berry") and string.format("%d berries picked", t.berries or 0)
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
        heading2(v, "weapons")
        caption(v, "Tap a weapon to choose what it fires. Nothing is on unless "
            .. "you switch it on; the lit ones fire.")

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
            if #lines == 0 then return "no weapon has M1 on" end
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
            "One that stops taking damage further out lowers its limit",
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
            .. "the side nearest you, then the other when it is empty. How far "
            .. "the game lets one go is published nowhere - the farm measures "
            .. "it: pulled ones that stop taking damage while nearer ones still "
            .. "do lower the limit for their kind.")
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
        caption(v, "Of the newest raid island (Island 1 to 5), or of you outside "
            .. "a raid. Every kind of enemy in that circle goes in the pile.")
        heading2(v, "keeping them hittable")
        caption(v, "The pile sits at the middle of the camp's spawn points - the "
            .. "spot where the farthest pull is shortest, so every one stays "
            .. "inside its own area (an enemy dragged out of it takes no damage). One that is held and hit with no HP change goes back "
            .. "where it came from and is left alone for 30 s. 'Staying put' is "
            .. "how many are really yours to move.")
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
        if P.running and CFG.AimSkills and CFG.AimHidden and pileCentre and os.clock() < aimUntil then
            pcall(aimSwapIn, aimPoint(), pileCentre)
        end
        if attacking and meas then meas.fight += dt end
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
    if not (gui and gui.Parent) then pcall(buildUI) end

    task.spawn(mainLoop)
    task.spawn(sideLoop)
    print("[BFF] running. _G.BFF.stop() to halt.")
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

-- Arrived by an elite hunt's hop: its settings back, and the hunt goes on.
do
    local resumed = false
    pcall(function() resumed = P.takeCarry() end)
    pcall(syncWeapons)
    say(resumed and ("elite hunt carried over (" .. tostring(P.elite.carried) .. ")")
        or "loaded - pick targets, then press Start")
    pcall(buildUI)
    if resumed then task.defer(P.start) end
end
-- Water is land from load, farm running or not (farm_pro's, unchanged).
task.spawn(function()
    while _G.BFF == P do
        pcall(keepWater)
        task.wait(0.25)
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
