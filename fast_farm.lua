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
      CIRCUIT  several species, one quest at a time: A's quest, A's pile, done
               -> B's quest, fly, B's pile, done -> back to A, respawned by now.

    TAKEN FROM FARM_PRO UNCHANGED: the level / quest / giver tables, the quest
    tracker reader, the quest dialog fallback, Enhancement + Observation, walk
    on water. Its panel too -- made opaque, because farm_pro's background was
    94-100% see-through (a UIGradient's transparency applies TO its frame).

    USE IT ON AN ACCOUNT YOU CAN AFFORD TO LOSE. Flight, noclip, hovering and
    enemies moved by your client are exactly what anti-cheat and player
    reports look for. farm_pro is the one for your main.

    CONTROL
        _G.BFF.start()          _G.BFF.stop()          _G.BFF.config
]]

if _G.BFF and _G.BFF.stop then pcall(_G.BFF.stop) end
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
    GrabRadius         = 300,    -- spawned this close to the camp = pulled
    GrabMax            = 12,     -- most enemies in one pile
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
    -- Fruit skills fire where the cursor points. On: the camera is turned at
    -- the pile and the cursor parked on it for every cast.
    AimSkills          = true,
    CamBack            = 14,
    CamUp              = 6,

    -- ---------- WEAPONS ----------
    -- [tool name] = { use, M1, Z, X, C, V, F, hold = { Z = seconds, ... } }
    -- Filled from your backpack. Everything off except, on the very first
    -- load, M1 of whatever is in your hand.
    Weapons            = {},
    WeaponOrder        = {},

    -- ---------- TRAVEL ----------
    TravelSpeed        = 330,    -- studs/s. The public hubs all settled on 330.
    InstantHop         = 150,    -- shorter than this: one write, no flight

    -- ---------- QUEST ----------
    QuestLoop          = true,
    -- The camp runs out before the quest is full. On: wait there for the
    -- respawn (the count is kept). Off: drop the quest and go to the next.
    WaitRespawn        = true,
    RespawnMax         = 45,     -- seconds; nothing back by then = move on
    QuestRetrySeconds  = 6,
    QuestKillsFallback = 8,      -- tracker unreadable: count this many here

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
local LEVELS = {
    {1,9,"Bandit",Vector3.new(1059.4,16.5,1546.6)},
    {10,14,"Monkey",Vector3.new(-1445.1,23.5,-48.8)},
    {15,29,"Gorilla",Vector3.new(-1119.8,40.5,1839.0)},
    {30,39,"Pirate",Vector3.new(-1181.3,4.5,3803.5)},
    {40,59,"Brute",Vector3.new(-1145.2,14.8,4321.7)},
    {60,74,"Desert Bandit",Vector3.new(932.2,6.5,4482.0)},
    {75,89,"Desert Officer",Vector3.new(1609.1,6.5,4369.8)},
    {90,99,"Snow Bandit",Vector3.new(1386.8,87.3,-1297.1)},
    {100,119,"Snowman",Vector3.new(1198.2,105.5,-1237.0)},
    {120,149,"Chief Petty Officer",Vector3.new(-4881.1,4.5,4257.4)},
    {150,174,"Sky Bandit",Vector3.new(-4841.7,717.8,-2666.9)},
    {175,189,"Dark Master",Vector3.new(-5217.1,12.5,-4836.7)},
    {190,209,"Prisoner",Vector3.new(5309.8,0.5,475.5)},
    {210,249,"Dangerous Prisoner",Vector3.new(5086.1,2,466.4)},
    {250,274,"Toga Warrior",Vector3.new(-3625.0,7.5,-3003.7)},
    {275,299,"Gladiator",Vector3.new(-1309.9,7.5,-3251.6)},
    {300,324,"Military Soldier",Vector3.new(-5316.2,12.5,-2842.5)},
    {325,374,"Military Spy",Vector3.new(-5815.4,84.5,-8972.3)},
    {375,399,"Fishman Warrior",Vector3.new(61122.7,18.5,1569.1)},
    {400,449,"Fishman Commando",Vector3.new(61922.6,18.5,1493.9)},
    {450,474,"God's Guard",Vector3.new(-4721.9,845.3,-1954.4)},
    {475,524,"Shanda",Vector3.new(-7685.1,5567.8,-502.1)},
    {525,549,"Royal Squad",Vector3.new(-7665.2,5839.5,-1818.8)},
    {550,624,"Royal Soldier",Vector3.new(-7836.8,5607.8,-1540.5)},
    {625,649,"Galley Pirate",Vector3.new(5551.0,42.5,3946.3)},
    {650,699,"Galley Captain",Vector3.new(5436.0,38.5,4757.8)},

    -- SECOND SEA
    {700,724,"Raider",Vector3.new(68.9,93.6,2429.7)},
    {725,774,"Mercenary",Vector3.new(-864.9,122.5,1453.2)},
    {775,799,"Swan Pirate",Vector3.new(1065.4,137.6,1324.4)},
    {800,874,"Factory Staff",Vector3.new(533.2,128.5,355.6)},
    {875,899,"Marine Lieutenant",Vector3.new(-2489.3,84.6,-3151.9)},
    {900,949,"Marine Captain",Vector3.new(-2335.2,79.8,-3245.9)},
    {950,974,"Zombie",Vector3.new(-5536.5,101.1,-835.6)},
    {975,999,"Vampire",Vector3.new(-5806.1,16.7,-1164.4)},
    {1000,1049,"Snow Trooper",Vector3.new(535.2,432.7,-5484.9)},
    {1050,1099,"Winter Warrior",Vector3.new(1234.5,457.0,-5174.1)},
    {1100,1124,"Lab Subordinate",Vector3.new(-5720.6,63.3,-4784.6)},
    {1125,1174,"Horned Warrior",Vector3.new(-6292.8,91.2,-5502.7)},
    {1175,1199,"Magma Ninja",Vector3.new(-5461.8,130.4,-5836.5)},
    {1200,1249,"Lava Pirate",Vector3.new(-5251.2,55.2,-4774.4)},
    {1250,1274,"Ship Deckhand",Vector3.new(921.1,126.0,33088.3)},
    {1275,1299,"Ship Engineer",Vector3.new(886.3,40.5,32800.8)},
    {1300,1324,"Ship Steward",Vector3.new(943.9,129.6,33444.4)},
    {1325,1349,"Ship Officer",Vector3.new(955.4,181.1,33331.9)},
    {1350,1374,"Arctic Warrior",Vector3.new(5935.5,77.3,-6472.8)},
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
-- QUEST TABLES
-- =========================================================
-- The server's own quest ids, not the titles the dialog shows.
local QUESTS = {
    ["Bandit"]                = { "BanditQuest1", 1 },
    ["Monkey"]                = { "JungleQuest", 1 },
    ["Gorilla"]               = { "JungleQuest", 2 },
    ["Pirate"]                = { "BuggyQuest1", 1 },
    ["Brute"]                 = { "BuggyQuest1", 2 },
    ["Desert Bandit"]         = { "DesertQuest", 1 },
    ["Desert Officer"]        = { "DesertQuest", 2 },
    ["Snow Bandit"]           = { "SnowQuest", 1 },
    ["Snowman"]               = { "SnowQuest", 2 },
    -- MEASURED: MarineQuest tier 1 handed back "Defeat 5 Trainees", so the
    -- Trainee is tier 1 and the Officer is tier 2.
    ["Trainee"]               = { "MarineQuest", 1 },
    ["Chief Petty Officer"]   = { "MarineQuest", 2 },
    ["Sky Bandit"]            = { "SkyQuest", 1 },
    ["Dark Master"]           = { "SkyQuest", 2 },
    ["Prisoner"]              = { "PrisonerQuest", 1 },
    ["Dangerous Prisoner"]    = { "PrisonerQuest", 2 },
    ["Toga Warrior"]          = { "ColosseumQuest", 1 },
    ["Gladiator"]             = { "ColosseumQuest", 2 },
    ["Military Soldier"]      = { "MagmaQuest", 1 },
    ["Military Spy"]          = { "MagmaQuest", 2 },
    ["Fishman Warrior"]       = { "FishmanQuest", 1 },
    ["Fishman Commando"]      = { "FishmanQuest", 2 },
    ["God's Guard"]           = { "SkyExp1Quest", 1 },
    ["Shanda"]                = { "SkyExp1Quest", 2 },
    ["Royal Squad"]           = { "SkyExp2Quest", 1 },
    ["Royal Soldier"]         = { "SkyExp2Quest", 2 },
    ["Galley Pirate"]         = { "FountainQuest", 1 },
    ["Galley Captain"]        = { "FountainQuest", 2 },

    ["Raider"]                = { "Area1Quest", 1 },
    ["Mercenary"]             = { "Area1Quest", 2 },
    ["Swan Pirate"]           = { "Area2Quest", 1 },
    ["Factory Staff"]         = { "Area2Quest", 2 },
    ["Marine Lieutenant"]     = { "MarineQuest3", 1 },
    ["Marine Captain"]        = { "MarineQuest3", 2 },
    ["Zombie"]                = { "ZombieQuest", 1 },
    ["Vampire"]               = { "ZombieQuest", 2 },
    ["Snow Trooper"]          = { "SnowMountainQuest", 1 },
    ["Winter Warrior"]        = { "SnowMountainQuest", 2 },
    ["Lab Subordinate"]       = { "IceSideQuest", 1 },
    ["Horned Warrior"]        = { "IceSideQuest", 2 },
    ["Magma Ninja"]           = { "FireSideQuest", 1 },
    ["Lava Pirate"]           = { "FireSideQuest", 2 },
    ["Ship Deckhand"]         = { "ShipQuest1", 1 },
    ["Ship Engineer"]         = { "ShipQuest1", 2 },
    ["Ship Steward"]          = { "ShipQuest2", 1 },
    ["Ship Officer"]          = { "ShipQuest2", 2 },
    ["Arctic Warrior"]        = { "FrostQuest", 1 },
    ["Snow Lurker"]           = { "FrostQuest", 2 },
    ["Sea Soldier"]           = { "ForgottenQuest", 1 },
    ["Water Fighter"]         = { "ForgottenQuest", 2 },

    -- THIRD SEA
    ["Pirate Millionaire"]    = { "PiratePortQuest", 1 },
    ["Pistol Billionaire"]    = { "PiratePortQuest", 2 },
    ["Dragon Crew Warrior"]   = { "AmazonQuest", 1 },
    ["Dragon Crew Archer"]    = { "AmazonQuest", 2 },
    ["Female Islander"]       = { "AmazonQuest2", 1 },
    ["Giant Islander"]        = { "AmazonQuest2", 2 },
    ["Marine Commodore"]      = { "MarineTreeIsland", 1 },
    ["Marine Rear Admiral"]   = { "MarineTreeIsland", 2 },
    ["Fishman Raider"]        = { "DeepForestIsland3", 1 },
    ["Fishman Captain"]       = { "DeepForestIsland3", 2 },
    ["Forest Pirate"]         = { "DeepForestIsland", 1 },
    ["Mythological Pirate"]   = { "DeepForestIsland", 2 },
    ["Jungle Pirate"]         = { "DeepForestIsland2", 1 },
    ["Musketeer Pirate"]      = { "DeepForestIsland2", 2 },
    -- HAUNTED CASTLE. Giver 1 is in the grey hut in the middle of the grounds,
    -- giver 2 stands at the castle's front door among the Demonic Souls.
    ["Reborn Skeleton"]       = { "HauntedQuest1", 1 },
    ["Living Zombie"]         = { "HauntedQuest1", 2 },
    ["Demonic Soul"]          = { "HauntedQuest2", 1 },
    ["Posessed Mummy"]        = { "HauntedQuest2", 2 },
    ["Peanut Scout"]          = { "NutsIslandQuest", 1 },
    ["Peanut President"]      = { "NutsIslandQuest", 2 },
    ["Ice Cream Chef"]        = { "IceCreamIslandQuest", 1 },
    ["Ice Cream Commander"]   = { "IceCreamIslandQuest", 2 },
    ["Cookie Crafter"]        = { "CakeQuest1", 1 },
    ["Cake Guard"]            = { "CakeQuest1", 2 },
    ["Baking Staff"]          = { "CakeQuest2", 1 },
    ["Head Baker"]            = { "CakeQuest2", 2 },
    ["Cocoa Warrior"]         = { "ChocQuest1", 1 },
    ["Chocolate Bar Battler"] = { "ChocQuest1", 2 },
    ["Sweet Thief"]           = { "ChocQuest2", 1 },
    ["Candy Rebel"]           = { "ChocQuest2", 2 },
    ["Candy Pirate"]          = { "CandyQuest1", 1 },
    ["Snow Demon"]            = { "CandyQuest1", 2 },
    ["Isle Outlaw"]           = { "TikiQuest1", 1 },
    ["Island Boy"]            = { "TikiQuest1", 2 },
    ["Sun-kissed Warrior"]    = { "TikiQuest2", 1 },
    ["Isle Champion"]         = { "TikiQuest2", 2 },
    ["Serpent Hunter"]        = { "TikiQuest3", 1 },
    ["Skull Slayer"]          = { "TikiQuest3", 2 },
    -- Submerged Island. Ocean Prophet's tier is from the wiki and one table;
    -- the first accept probes tiers anyway and locks the one that matches.
    ["Reef Bandit"]           = { "SubmergedQuest1", 1 },
    ["Coral Pirate"]          = { "SubmergedQuest1", 2 },
    ["Sea Chanter"]           = { "SubmergedQuest2", 1 },
    ["Ocean Prophet"]         = { "SubmergedQuest2", 2 },
    ["High Disciple"]         = { "SubmergedQuest3", 1 },
    ["Grand Devotee"]         = { "SubmergedQuest3", 2 },
}
P.quests = QUESTS

-- The giver's NAME is a hint. The giver's POSITION is the thing that works:
-- the server refuses StartQuest unless you are standing near it, and a
-- coordinate cannot be misspelled or fail to stream in.
local GIVER_POS = {
    ["Raider"]                = Vector3.new(-427.7, 73.0, 1835.9),
    ["Mercenary"]             = Vector3.new(-427.7, 73.0, 1835.9),
    ["Swan Pirate"]           = Vector3.new(635.6, 73.1, 917.8),
    ["Factory Staff"]         = Vector3.new(635.6, 73.1, 917.8),
    ["Marine Lieutenant"]     = Vector3.new(-2441.0, 73.0, -3217.7),
    ["Marine Captain"]        = Vector3.new(-2441.0, 73.0, -3217.7),
    ["Zombie"]                = Vector3.new(-5494.3, 48.5, -794.6),
    ["Vampire"]               = Vector3.new(-5494.3, 48.5, -794.6),
    ["Snow Trooper"]          = Vector3.new(607.1, 401.5, -5370.6),
    ["Winter Warrior"]        = Vector3.new(607.1, 401.5, -5370.6),
    ["Lab Subordinate"]       = Vector3.new(-6061.8, 15.9, -4902.0),
    ["Horned Warrior"]        = Vector3.new(-6061.8, 15.9, -4902.0),
    ["Magma Ninja"]           = Vector3.new(-5429.1, 16.0, -5298.0),
    ["Lava Pirate"]           = Vector3.new(-5429.1, 16.0, -5298.0),
    ["Ship Deckhand"]         = Vector3.new(1040.3, 125.1, 32911.0),
    ["Ship Engineer"]         = Vector3.new(1040.3, 125.1, 32911.0),
    ["Ship Steward"]          = Vector3.new(971.4, 125.1, 33245.5),
    ["Ship Officer"]          = Vector3.new(971.4, 125.1, 33245.5),
    ["Arctic Warrior"]        = Vector3.new(5668.1, 28.2, -6484.6),
    ["Snow Lurker"]           = Vector3.new(5668.1, 28.2, -6484.6),
    ["Sea Soldier"]           = Vector3.new(-3054.6, 236.9, -10147.8),
    ["Water Fighter"]         = Vector3.new(-3054.6, 236.9, -10147.8),

    ["Pirate Millionaire"]    = Vector3.new(-290.1, 42.9, 5581.6),
    ["Pistol Billionaire"]    = Vector3.new(-290.1, 42.9, 5581.6),
    ["Dragon Crew Warrior"]   = Vector3.new(5832.8, 51.7, -1101.5),
    ["Dragon Crew Archer"]    = Vector3.new(5832.8, 51.7, -1101.5),
    ["Female Islander"]       = Vector3.new(5448.9, 601.5, 751.1),
    ["Giant Islander"]        = Vector3.new(5448.9, 601.5, 751.1),
    ["Marine Commodore"]      = Vector3.new(2180.5, 27.8, -6741.6),
    ["Marine Rear Admiral"]   = Vector3.new(2180.5, 27.8, -6741.6),
    ["Fishman Raider"]        = Vector3.new(-10581.7, 330.9, -8761.2),
    ["Fishman Captain"]       = Vector3.new(-10581.7, 330.9, -8761.2),
    ["Forest Pirate"]         = Vector3.new(-13234.0, 331.5, -7625.4),
    ["Mythological Pirate"]   = Vector3.new(-13234.0, 331.5, -7625.4),
    ["Jungle Pirate"]         = Vector3.new(-12680.4, 390.0, -9902.0),
    ["Musketeer Pirate"]      = Vector3.new(-12680.4, 390.0, -9902.0),
    ["Reborn Skeleton"]       = Vector3.new(-9480.8, 142.1, 5566.1),
    ["Living Zombie"]         = Vector3.new(-9480.8, 142.1, 5566.1),
    ["Demonic Soul"]          = Vector3.new(-9517.0, 178.0, 6078.5),
    ["Posessed Mummy"]        = Vector3.new(-9517.0, 178.0, 6078.5),
    ["Peanut Scout"]          = Vector3.new(-2104.4, 38.1, -10194.1),
    ["Peanut President"]      = Vector3.new(-2104.4, 38.1, -10194.1),
    ["Ice Cream Chef"]        = Vector3.new(-820.2, 65.8, -10966.2),
    ["Ice Cream Commander"]   = Vector3.new(-820.2, 65.8, -10966.2),
    ["Cookie Crafter"]        = Vector3.new(-2022.3, 36.9, -12030.9),
    ["Cake Guard"]            = Vector3.new(-2022.3, 36.9, -12030.9),
    ["Baking Staff"]          = Vector3.new(-1928.3, 37.7, -12840.6),
    ["Head Baker"]            = Vector3.new(-1928.3, 37.7, -12840.6),
    ["Cocoa Warrior"]         = Vector3.new(231.8, 23.9, -12200.3),
    ["Chocolate Bar Battler"] = Vector3.new(231.8, 23.9, -12200.3),
    ["Sweet Thief"]           = Vector3.new(151.2, 23.9, -12774.6),
    ["Candy Rebel"]           = Vector3.new(151.2, 23.9, -12774.6),
    ["Candy Pirate"]          = Vector3.new(-1149.3, 13.6, -14445.6),
    ["Snow Demon"]            = Vector3.new(-1149.3, 13.6, -14445.6),
    ["Isle Outlaw"]           = Vector3.new(-16549.9, 55.7, -179.9),
    ["Island Boy"]            = Vector3.new(-16549.9, 55.7, -179.9),
    ["Sun-kissed Warrior"]    = Vector3.new(-16541.0, 54.8, 1051.5),
    ["Isle Champion"]         = Vector3.new(-16541.0, 54.8, 1051.5),
    ["Serpent Hunter"]        = Vector3.new(-16665.2, 104.6, 1579.7),
    ["Skull Slayer"]          = Vector3.new(-16665.2, 104.6, 1579.7),
    ["Reef Bandit"]           = Vector3.new(10780.1, -2087.7, 9261.9),
    ["Coral Pirate"]          = Vector3.new(10780.1, -2087.7, 9261.9),
    ["Sea Chanter"]           = Vector3.new(10883.6, -2086.2, 10032.2),
    ["Ocean Prophet"]         = Vector3.new(10883.6, -2086.2, 10032.2),
    ["High Disciple"]         = Vector3.new(9635.9, -1992.4, 9614.4),
    ["Grand Devotee"]         = Vector3.new(9635.9, -1992.4, 9614.4),
}
P.giverPositions = GIVER_POS

local GIVER_NAMES = {
    ["Bandit"]                = "Bandit Quest Giver",
    ["Monkey"]                = "Adventurer",
    ["Gorilla"]               = "Adventurer",
    ["Pirate"]                = "Pirate Adventurer",
    ["Brute"]                 = "Pirate Adventurer",
    ["Desert Bandit"]         = "Desert Adventurer",
    ["Desert Officer"]        = "Desert Adventurer",
    ["Snow Bandit"]           = "Villager",
    ["Snowman"]               = "Villager",
    ["Chief Petty Officer"]   = "Marine",
    ["Sky Bandit"]            = "Sky Adventurer",
    ["Dark Master"]           = "Sky Adventurer",
    ["Prisoner"]              = "Jail Keeper",
    ["Dangerous Prisoner"]    = "Jail Keeper",
    ["Toga Warrior"]          = "Colosseum Quest Giver",
    ["Gladiator"]             = "Colosseum Quest Giver",
    ["God's Guard"]           = "Sky Quest Giver 2",
    ["Shanda"]                = "Sky Quest Giver 2",
    ["Royal Squad"]           = "Mole",
    ["Royal Soldier"]         = "Mole",
    ["Raider"]                = "Area 1 Quest Giver",
    ["Mercenary"]             = "Area 1 Quest Giver",
    ["Swan Pirate"]           = "Area 2 Quest Giver",
    ["Factory Staff"]         = "Area 2 Quest Giver",
    ["Marine Lieutenant"]     = "Marine Quest Giver",
    ["Marine Captain"]        = "Marine Quest Giver",
    ["Zombie"]                = "Graveyard Quest Giver",
    ["Vampire"]               = "Graveyard Quest Giver",
    ["Snow Trooper"]          = "Snow Quest Giver",
    ["Winter Warrior"]        = "Snow Quest Giver",
    ["Lab Subordinate"]       = "Ice Quest Giver",
    ["Horned Warrior"]        = "Ice Quest Giver",
    ["Magma Ninja"]           = "Fire Quest Giver",
    ["Lava Pirate"]           = "Fire Quest Giver",
    ["Sea Soldier"]           = "Forgotten Quest Giver",
    ["Water Fighter"]         = "Forgotten Quest Giver",
    ["Ship Deckhand"]         = "Front Crew Quest Giver",
    ["Ship Engineer"]         = "Front Crew Quest Giver",
    ["Ship Steward"]          = "Rear Crew Quest Giver",
    ["Ship Officer"]          = "Rear Crew Quest Giver",
    ["Arctic Warrior"]        = "Frost Quest Giver",
    ["Snow Lurker"]           = "Frost Quest Giver",
    ["Pirate Millionaire"]    = "Port Town Quest Giver",
    ["Pistol Billionaire"]    = "Port Town Quest Giver",
    ["Dragon Crew Warrior"]   = "Hydra Town Quest Giver",
    ["Dragon Crew Archer"]    = "Hydra Town Quest Giver",
    ["Female Islander"]       = "Hydra Island Quest Giver",
    ["Giant Islander"]        = "Hydra Island Quest Giver",
    ["Marine Commodore"]      = "Marine Tree Quest Giver",
    ["Marine Rear Admiral"]   = "Marine Tree Quest Giver",
    ["Fishman Raider"]        = "Deep Forest Quest Giver 3",
    ["Fishman Captain"]       = "Deep Forest Quest Giver 3",
    ["Forest Pirate"]         = "Deep Forest Quest Giver",
    ["Mythological Pirate"]   = "Deep Forest Quest Giver",
    ["Jungle Pirate"]         = "Deep Forest Quest Giver 2",
    ["Musketeer Pirate"]      = "Deep Forest Quest Giver 2",
    ["Reborn Skeleton"]       = "Haunted Castle Quest Giver 1",
    ["Living Zombie"]         = "Haunted Castle Quest Giver 1",
    ["Demonic Soul"]          = "Haunted Castle Quest Giver 2",
    ["Posessed Mummy"]        = "Haunted Castle Quest Giver 2",
    ["Peanut Scout"]          = "Peanut Quest Giver",
    ["Peanut President"]      = "Peanut Quest Giver",
    ["Ice Cream Chef"]        = "Ice Cream Quest Giver",
    ["Ice Cream Commander"]   = "Ice Cream Quest Giver",
    ["Cookie Crafter"]        = "Cake Quest Giver 1",
    ["Cake Guard"]            = "Cake Quest Giver 1",
    ["Baking Staff"]          = "Cake Quest Giver 2",
    ["Head Baker"]            = "Cake Quest Giver 2",
    ["Cocoa Warrior"]         = "Chocolate Quest Giver 1",
    ["Chocolate Bar Battler"] = "Chocolate Quest Giver 1",
    ["Sweet Thief"]           = "Chocolate Quest Giver 2",
    ["Candy Rebel"]           = "Chocolate Quest Giver 2",
    ["Candy Pirate"]          = "Candy Cane Quest Giver",
    ["Snow Demon"]            = "Candy Cane Quest Giver",
    ["Isle Outlaw"]           = "Tiki Quest Giver 1",
    ["Island Boy"]            = "Tiki Quest Giver 1",
    ["Sun-kissed Warrior"]    = "Tiki Quest Giver 2",
    ["Isle Champion"]         = "Tiki Quest Giver 2",
    ["Serpent Hunter"]        = "Tiki Quest Giver 3",
    ["Skull Slayer"]          = "Tiki Quest Giver 3",
    ["Reef Bandit"]           = "Submerged Quest Giver 1",
    ["Coral Pirate"]          = "Submerged Quest Giver 1",
    ["Sea Chanter"]           = "Submerged Quest Giver 2",
    ["Ocean Prophet"]         = "Submerged Quest Giver 2",
    ["High Disciple"]         = "Submerged Quest Giver 3",
    ["Grand Devotee"]         = "Submerged Quest Giver 3",
}
P.giverNames = GIVER_NAMES

-- Every name the wiki lists as a farm-quest giver, island not attached. Being
-- on this list is a strong signal on its own, so the nearby scan works even
-- where the enemy mapping above is wrong.
local KNOWN_GIVERS = {}
for _, n in ipairs({
    "Bandit Quest Giver", "Adventurer", "Pirate Adventurer", "Desert Adventurer",
    "Villager", "Marine", "Marine Leader", "Colosseum Quest Giver",
    "Sky Adventurer", "Sky Quest Giver 2", "Mole", "Head Jailer", "Jail Keeper",
    "Freezeburg Quest Giver", "Submerged Quest Giver 1", "Submerged Quest Giver 2",
    "Area 1 Quest Giver", "Area 2 Quest Giver", "Marine Quest Giver",
    "Graveyard Quest Giver", "Snow Quest Giver", "Ice Quest Giver",
    "Fire Quest Giver", "Forgotten Quest Giver", "Front Crew Quest Giver",
    "Rear Crew Quest Giver", "Frost Quest Giver",
    "Port Town Quest Giver", "Pirate Port Quest Giver", "Hydra Town Quest Giver",
    "Hydra Island Quest Giver", "Dragon Crew Quest Giver",
    "Marine Tree Quest Giver", "Turtle Adventure Quest Giver",
    "Deep Forest Quest Giver", "Deep Forest Quest Giver 2",
    "Deep Forest Quest Giver 3", "Haunted Castle Quest Giver 1",
    "Haunted Castle Quest Giver 2", "Cake Quest Giver 1", "Cake Quest Giver 2",
    "Chocolate Quest Giver 1", "Chocolate Quest Giver 2", "Ice Cream Quest Giver",
    "Peanut Quest Giver", "Candy Cane Quest Giver", "Submerged Quest Giver 3",
    "Tiki Quest Giver 1", "Tiki Quest Giver 2", "Tiki Quest Giver 3",
}) do KNOWN_GIVERS[string.lower(n)] = n end
P.knownGivers = KNOWN_GIVERS


-- Seas are separate servers. A species from another sea cannot be reached
-- from this one, so the circuit skips it and says so.
local SEA_OF_PLACE = { [2753915549] = 1, [4442272183] = 2, [7449423635] = 3 }
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

-- =========================================================
-- STATE
-- =========================================================
local stats = {
    kills = 0, piles = 0, quests = 0, questsDone = 0, m1 = 0, casts = 0,
    swaps = 0, flights = 0, hops = 0, pulledBack = 0, putBack = 0,
    escapes = 0, abandons = 0, probes = 0, hakiPresses = 0, startedAt = 0,
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

P.learnedGivers = {}
P.learnedQuests = {}
P.giverSpots    = {}

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

local function findTool(name)
    local bp   = player:FindFirstChild("Backpack")
    local char = player.Character
    local t = (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
    if t and t:IsA("Tool") then return t end
    return nil
end

local function toolNames()
    local out, seen = {}, {}
    for _, src in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
        if src then
            for _, t in ipairs(src:GetChildren()) do
                if t:IsA("Tool") and not seen[t.Name] then
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
local function holdKey(code, secs)
    pcall(function() VIM:SendKeyEvent(true, code, false, game) end)
    task.wait(math.max(secs or 0.05, 0.03))
    pcall(function() VIM:SendKeyEvent(false, code, false, game) end)
end

local function pressM1()
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
local camHeld = false
local function releaseCamera()
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

-- The camera behind and above you, looking at the pile; the cursor at the
-- centre of the screen, which is now the pile. A fruit skill cast down the
-- cursor's ray lands on it.
local function aimCamera(targetPos)
    local cam = workspace.CurrentCamera
    local _, r = parts()
    if not cam or not r then return end
    local eye  = r.Position + Vector3.new(0, 2, 0)
    local flat = targetPos - eye
    flat = Vector3.new(flat.X, 0, flat.Z)
    if flat.Magnitude < 1 then
        -- Straight above the pile: stand the camera off along its own facing.
        local lv = cam.CFrame.LookVector
        flat = Vector3.new(lv.X, 0, lv.Z)
        if flat.Magnitude < 0.1 then flat = Vector3.new(0, 0, -1) end
    end
    local at = eye - flat.Unit * (CFG.CamBack or 14) + Vector3.new(0, CFG.CamUp or 6, 0)
    pcall(function()
        cam.CameraType = Enum.CameraType.Scriptable
        camHeld = true
        cam.CFrame = CFrame.lookAt(at, targetPos)
        local vs = cam.ViewportSize
        VIM:SendMouseMoveEvent(vs.X * 0.5, vs.Y * 0.5, game)
    end)
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

local function homeOf(e)
    local h = homePos[e.model]
    if not h then
        h = e.root.Position
        homePos[e.model] = h
    end
    return h
end

local function isPutBack(model)
    local u = putBack[model]
    if not u then return false end
    if os.clock() > u then putBack[model] = nil return false end
    return true
end

local function releasePile()
    releaseCamera()          -- the view must not stay on a pile being left
    pileActive, attacking = false, false
    pile, pileCentre, pileSide = {}, nil, nil
    P.pileHeld, P.pileOwned = 0, 0
end

-- Who goes in the pile, and where its centre is.
-- cur = { name, spot }; names = every species on the circuit.
local function buildPile(cur, names)
    local _, r = parts()
    local around = cur.spot or (r and r.Position)
    if not around then return {}, nil end
    local list = liveEnemies(names)

    if not CFG.Magnet then
        -- No magnet: fight the nearest one where it stands.
        local best, bd = nil, math.huge
        local from = r and r.Position or around
        for _, e in ipairs(list) do
            if e.name == cur.name and not isPutBack(e.model) then
                local d = (e.root.Position - from).Magnitude
                if d < bd and (homeOf(e) - around).Magnitude <= CFG.GrabRadius then
                    best, bd = e, d
                end
            end
        end
        if not best then return {}, nil end
        return { best }, best.root.Position
    end

    local quest, others = {}, {}
    for _, e in ipairs(list) do
        if not isPutBack(e.model) then
            local h = homeOf(e)
            if (h - around).Magnitude <= CFG.GrabRadius then
                if e.name == cur.name then
                    table.insert(quest, e)
                elseif CFG.PullOthers then
                    table.insert(others, e)
                end
            end
        end
    end
    if #quest == 0 then return {}, nil end
    table.sort(quest, function(a, b)
        return (homeOf(a) - around).Magnitude < (homeOf(b) - around).Magnitude
    end)
    local cap = math.max(1, math.floor(CFG.GrabMax or 12))
    while #quest > cap do table.remove(quest) end

    local sum = Vector3.zero
    for _, e in ipairs(quest) do sum += homeOf(e) end
    local centre = sum / #quest

    for _, e in ipairs(others) do
        if #quest >= cap then break end
        if (homeOf(e) - centre).Magnitude <= (CFG.OthersRadius or 100) then
            table.insert(quest, e)
        end
    end
    return quest, centre
end

-- Every frame, after physics.
local function magnetTick()
    if not (P.running and pileActive and CFG.Magnet and pileCentre) then return end
    local now = os.clock()
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

-- Held, hit, and not losing HP: out of its area, or not ours to move.
local function checkPutBack()
    if not attacking or probing or not CFG.Magnet then return end
    local now = os.clock()
    for _, e in ipairs(pile) do
        local j = pileJoin[e.model]
        if not j then
            pileJoin[e.model] = { at = now, hp = e.hum.Health, act = actions }
        elseif e.hum.Health < j.hp - 0.5 then
            j.at, j.hp, j.act = now, e.hum.Health, actions
        elseif now - j.at > (CFG.PutBackAfter or 3) and actions - j.act >= 6 then
            putBack[e.model] = now + 30
            pileJoin[e.model] = nil
            stats.putBack += 1
            local h = homePos[e.model]
            if h then pcall(function() e.root.CFrame = CFrame.new(h) end) end
        end
    end
end

-- =========================================================
-- WHERE YOU HANG
-- =========================================================
local wantPose = "safe"      -- "safe" (high) or "melee" (close beside)

local function poseTarget()
    if not pileCentre then return nil end
    local c = pileCentre
    if not pileSide then
        local _, r = parts()
        local d = r and Vector3.new(r.Position.X - c.X, 0, r.Position.Z - c.Z) or Vector3.zero
        pileSide = (d.Magnitude > 0.5) and d.Unit or Vector3.new(1, 0, 0)
    end
    if CFG.HeightMode == "fixed" then
        return c + Vector3.new(0, CFG.HeightFixed or 12, 0) + pileSide * (CFG.SideFixed or 0)
    elseif wantPose == "melee" then
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
local TYPE_RANK = { ["Blox Fruit"] = 1, Melee = 2, Sword = 3, Gun = 4 }

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
local seeded = false
local function syncWeapons()
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
local function barReady(w, k)
    local bar = skillBar(w, k)
    if not bar then return nil end
    return bar.AbsoluteSize.X <= 0
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
local HIT_TAG = "078da341"
local m1Plan  = {}           -- [weapon] = chosen way, or false (nothing landed)
P.m1Notes     = {}
local lastProbeMethod = CFG.M1Method

local function hitTargets()
    local _, r = parts()
    if not r then return {} end
    local out = {}
    local range = CFG.HitRange or 60
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

local function fireM1(way, tool)
    local list = hitTargets()
    if way.path == "remote" then
        m1Remote(way.variant, list)
    elseif way.path == "click" then
        m1Click(tool, list)
    else
        pressM1()
    end
    stats.m1 += 1
    actions += 1
end

local function describeWay(way)
    if not way then return "-" end
    local where = (way.pose == "melee") and "close" or "from above"
    if way.path == "remote" then return "remote hit (" .. way.variant .. "), " .. where end
    if way.path == "click" then return "fruit click, " .. where end
    return "key press, " .. where
end
P.describeWay = describeWay

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

local function probeM1(name, tool)
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

local function castSkill(u, k)
    if not equip(u.name) then return false end
    -- In hand now, so its bar is the truth: if the guess was wrong, no key.
    if barReady(u.name, k) == false then return false end
    local t = toolType(u.tool)
    if CFG.HeightMode ~= "fixed" then
        setPose((t == "Melee" or t == "Sword") and "melee" or "safe")
    end
    if CFG.AimSkills and pileCentre then
        aimCamera(pileCentre)
        task.wait()
    end
    holdKey(KEYCODE[k], (u.cfg.hold and u.cfg.hold[k]) or 0.05)
    local c = cdOf(u.name, k)
    c.lastCast = os.clock()
    stats.casts += 1
    actions += 1
    task.wait(CFG.CastWait or 0.45)
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

    if not CFG.AutoKen then return end
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
local WATER_Y = 112          -- raised: the top is at the surface (the game's is 80)
P.waterNote = "not looked yet"
P.waterSets = 0

local function keepWater()
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

local function parkFloor()
    if waterFloor and waterFloor.Parent then waterFloor.Parent = nil end
end

local function deepTick()
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


-- =========================================================
-- QUEST
-- =========================================================
-- Finding a giver, reading the tracker and clicking the quest dialog: all
-- farm_pro's, unchanged.
local function npcSources()
    local out = {}
    for _, n in ipairs({ "NPCs", "Npcs", "Characters", "Map" }) do
        local f = workspace:FindFirstChild(n)
        if f then table.insert(out, f) end
    end
    table.insert(out, workspace)
    return out
end

local function anchorPart(model)
    return model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Head")
        or model:FindFirstChild("Torso")
        or model:FindFirstChildWhichIsA("BasePart")
end

-- Blox Fruits puts no ClickDetector and no ProximityPrompt on a quest giver.
-- The "E Interact" ring is the game's own client-side UI. What a giver DOES
-- have is the "?" billboard reading QUEST above its head, so that is the
-- signal used here.
local function questMarker(model)
    local ok, hit = pcall(function()
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BillboardGui") then
                for _, t in ipairs(d:GetDescendants()) do
                    if (t:IsA("TextLabel") or t:IsA("TextButton"))
                        and type(t.Text) == "string"
                        and string.find(string.lower(t.Text), "quest", 1, true) then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return ok and hit or false
end

local function findQuestGiver(maxRange, wantName, markerOnly)
    local _, root = parts()
    if not root then return nil end
    maxRange = maxRange or 300
    local want = wantName and string.lower(wantName) or nil

    local cands, seen = {}, {}
    for _, src in ipairs(npcSources()) do
        for _, m in ipairs(src:GetChildren()) do
            if m:IsA("Model") and not seen[m] then
                seen[m] = true
                local part = anchorPart(m)
                if part then
                    local d = (part.Position - root.Position).Magnitude
                    if d <= maxRange then
                        local low   = string.lower(m.Name)
                        local named = string.find(low, "quest", 1, true)
                                   or string.find(low, "giver", 1, true)
                        local known  = KNOWN_GIVERS[low] ~= nil
                        local marker = questMarker(m)
                        local exact  = want and (low == want)
                        local score = d
                            - (exact and 50000 or 0)
                            - (known and 20000 or 0)
                            - (marker and 5000 or 0)
                            - (named and 1000 or 0)
                        local accept = exact or known or marker or named
                            or m:FindFirstChildOfClass("Humanoid")
                        if markerOnly then
                            accept = (exact or known or marker) and true or false
                        end
                        if accept then
                            table.insert(cands, {
                                model = m, part = part, dist = d, name = m.Name,
                                score = score,
                                signal = (exact and "exact name")
                                      or (known and "known giver")
                                      or (marker and "QUEST marker")
                                      or (named and "name") or "npc",
                            })
                        end
                    end
                end
            end
        end
    end

    table.sort(cands, function(a, b) return a.score < b.score end)
    P.questCandidates = cands
    local best = cands[1]
    return best, best and best.dist or nil
end
P.findQuestGiver = findQuestGiver

function P.questScan(range)
    findQuestGiver(range or 400)
    local out = {}
    for i, c in ipairs(P.questCandidates or {}) do
        if i > 8 then break end
        table.insert(out, string.format("%s  %.0f studs  (%s)",
            tostring(c.name), c.dist, c.signal))
    end
    if #out == 0 then return { "no NPC models in range" } end
    return out
end

-- ---------------------------------------------------------
-- READING THE TRACKER
-- ---------------------------------------------------------
-- "A GUI called Quest contains some text" is equally true of the quest BOARD
-- standing in front of you, which is why the old check reported a quest as
-- active whenever the board was on screen. The tracker has one thing nothing
-- else has: a live have/need counter beside the word Defeat.
local function shownOnScreen(g)
    local o = g
    while o and o:IsA("GuiObject") do
        if not o.Visible then return false end
        o = o.Parent
    end
    return true
end

local function blockText(frame)
    local acc = {}
    for _, d in ipairs(frame:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            table.insert(acc, d.Text)
        end
    end
    return string.lower(table.concat(acc, " "))
end

local questCache, questCacheAt = nil, 0
-- The exact label the counter lives in, once we have found it once.
local questLabel = nil
P.questScans = 0        -- how many full tree walks this run has cost

-- Read one label. This is the whole job once you know WHICH label.
local function parseCounter(d)
    if not d or not d.Parent then return nil end
    local txt = d.Text
    if type(txt) ~= "string" or #txt == 0 then return nil end
    local have, need = string.match(txt, "(%d+)%s*/%s*(%d+)")
    if not (have and need) then return nil end
    if not shownOnScreen(d) then return nil end
    local blob = d.Parent and blockText(d.Parent) or string.lower(txt)
    if not (string.find(blob, "defeat", 1, true)
        or string.find(blob, "eliminate", 1, true)
        or string.find(blob, "kill", 1, true)) then return nil end
    local enemy = string.match(blob, "defeat%s+%d+%s+([%a%s\'%-]+)")
    if enemy then enemy = (enemy:gsub("%s+$", "")) end
    return {
        have = tonumber(have) or 0, need = tonumber(need) or 0,
        enemy = enemy, text = txt,
    }
end

-- WHY THIS USED TO STALL THE FARM.
-- The counter lives in one TextLabel, and that label does not move. The old
-- version walked EVERY descendant of PlayerGui to find it again on every
-- single call -- and Blox Fruits' PlayerGui is thousands of instances, each
-- TextLabel of which then cost an ancestor walk and a subtree walk on top.
-- Called once every few seconds that is invisible. Called after every kill it
-- is the pause you can watch from outside.
--
-- So the label is remembered. The fast path re-reads the one we hold, which is
-- a text compare and a pattern match. The tree is only walked again when that
-- label has actually gone -- a respawn, a UI reset, a new quest panel.
function P.readQuest(force)
    if not force and (os.clock() - questCacheAt) < 0.5 then return questCache end
    questCacheAt = os.clock()

    local fast
    pcall(function() fast = parseCounter(questLabel) end)
    if fast then
        questCache = (fast.need > 0) and fast or nil
        return questCache
    end
    questLabel = nil

    local pg = player:FindFirstChild("PlayerGui")
    if not pg then questCache = nil return nil end
    local found
    P.questScans += 1
    pcall(function()
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and not d:FindFirstAncestor("BFFHUD") then
                local parsed = parseCounter(d)
                if parsed then
                    questLabel = d
                    found = parsed
                    return
                end
            end
        end
    end)
    questCache = (found and found.need > 0) and found or nil
    return questCache
end

function P.questActive() return P.readQuest() ~= nil end

-- After the giver is triggered a dialog appears with one button per tier.
-- Blox Fruits builds it out of ImageButtons whose caption lives in a child
-- TextLabel, not out of TextButtons, so GuiButton is what has to be scanned.
local function clickQuestDialog(wantName)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end

    local function textOf(b)
        local acc = {}
        if type(b.Text) == "string" and #b.Text > 0 then table.insert(acc, b.Text) end
        for _, d in ipairs(b:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextBox"))
                and type(d.Text) == "string" and #d.Text > 0 then
                table.insert(acc, d.Text)
            end
        end
        return string.lower(table.concat(acc, " "))
    end

    local function click(b)
        local fired = false
        pcall(function()
            if getconnections then
                for _, conn in ipairs(getconnections(b.Activated)) do
                    conn:Fire() fired = true
                end
                if not fired then
                    for _, conn in ipairs(getconnections(b.MouseButton1Click)) do
                        conn:Fire() fired = true
                    end
                end
            end
        end)
        if not fired then
            pcall(function()
                local ap, as = b.AbsolutePosition, b.AbsoluteSize
                local x, y = ap.X + as.X / 2, ap.Y + as.Y / 2
                VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.06)
                VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end)
        end
    end

    local deadline = os.clock() + 4
    while os.clock() < deadline do
        local best, fallback, seen = nil, nil, {}
        for _, d in ipairs(pg:GetDescendants()) do
            -- Our own panel has buttons reading QUEST. Without this guard the
            -- dialog hunt clicks the farm's own UI instead of the game's.
            local mine = d:FindFirstAncestor("BFFHUD") ~= nil
            if not mine and d:IsA("GuiButton") and d.Visible and d.AbsoluteSize.X > 20 then
                local txt = textOf(d)
                if #txt > 2 then
                    table.insert(seen, string.sub(txt, 1, 40))
                    if wantName and string.find(txt, string.lower(wantName), 1, true) then
                        best = d
                    elseif string.find(txt, "quest", 1, true)
                        or string.find(txt, "accept", 1, true)
                        or string.find(txt, "kill", 1, true)
                        or string.find(txt, "defeat", 1, true) then
                        fallback = fallback or d
                    end
                end
            end
        end
        P.lastQuestOptions = seen
        local pick = best or fallback
        if pick then
            click(pick)
            return true, string.sub(textOf(pick), 1, 60)
        end
        task.wait(0.25)
    end
    return false
end



-- ---------------------------------------------------------
-- TAKING A QUEST: FROM WHERE YOU STAND
-- ---------------------------------------------------------
-- farm_pro's engine: ask with the server's own quest id, read the tracker,
-- and only keep a quest whose tracker names the enemy it was taken for; an
-- unknown tier is probed 1-2-3 and the one that matches is remembered. Asked
-- from range first -- on your server that works. Refused from range, it flies
-- to the giver (a second, not a walk) and asks again, talking to the NPC if
-- the remote still says no.
--
-- One quest runs at a time; that is the game's rule. Asking again while one
-- is running resets its count, so nothing here ever asks while one is.
local questSpecies = nil     -- whose quest is running
local questNeed    = nil
local questKills   = 0       -- kills of questSpecies since it was taken
local questBlind   = false   -- sent cleanly, tracker unreadable: counted here
local lastAskAt    = {}
local stalled      = {}      -- species whose camp stopped respawning -> until
local lastPeek     = 0
local nilPeeks     = 0       -- tracker looks in a row that found no tracker
P.lastQuestResult  = "none yet"
P.circuitNote      = ""

local function wanted(trackerEnemy, enemy)
    if not trackerEnemy or not enemy then return true end
    local a = string.lower(tostring(trackerEnemy))
    local b = string.lower(tostring(enemy))
    return string.find(a, b, 1, true) ~= nil or string.find(b, a, 1, true) ~= nil
end

local function questFor(enemy)
    local learned = P.learnedQuests[enemy]
    if learned then return learned.name, learned.tier, true end
    local q = QUESTS[enemy]
    if q then return q[1], q[2], false end
    return nil, nil, false
end

function P.giverFor(enemy)
    local name = P.learnedGivers[enemy] or GIVER_NAMES[enemy]
    local pos  = P.giverSpots[enemy] or GIVER_POS[enemy]
    return name, pos
end

local function abandonQuest(why)
    local cf = commF()
    if cf then pcall(function() cf:InvokeServer("AbandonQuest") end) end
    stats.abandons += 1
    questSpecies, questNeed, questKills, questBlind = nil, nil, 0, false
    say("quest dropped - " .. tostring(why))
    task.wait(0.4)
end
P.abandonQuest = function() abandonQuest("by hand") end

local function acceptFor(enemy, spot)
    local cf = commF()
    if not cf then
        P.lastQuestResult = "no CommF_ remote"
        return false
    end
    if lastAskAt[enemy] and os.clock() - lastAskAt[enemy] < (CFG.QuestRetrySeconds or 6) then
        return false
    end
    lastAskAt[enemy] = os.clock()

    local qname, tier, learned = questFor(enemy)
    if not qname then
        P.lastQuestResult = "no quest id known for " .. enemy .. " - farming it without one"
        say(P.lastQuestResult)
        return false
    end
    tier = tier or 1
    local tiers = { tier }
    if not learned then
        for _, t in ipairs({ 1, 2, 3 }) do
            if t ~= tier then table.insert(tiers, t) end
        end
    end
    local myEpoch = epoch

    local function attempt(atGiver)
        local gotQ, gotOk, gotRes
        for i, t in ipairs(tiers) do
            if stale(myEpoch) then break end
            gotOk, gotRes = pcall(function()
                return cf:InvokeServer("StartQuest", qname, t)
            end)
            task.wait(0.45)
            gotQ = P.readQuest(true)
            if not gotQ and atGiver and i == 1 then
                say("remote refused - talking to the NPC")
                for _ = 1, 3 do
                    pcall(function()
                        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.07)
                        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                    task.wait(0.3)
                end
                pcall(clickQuestDialog, enemy)
                task.wait(0.5)
                gotQ = P.readQuest(true)
            end
            tier = t
            if not gotQ then break end
            if wanted(gotQ.enemy, enemy) then break end
            if i < #tiers then
                say(string.format("tier %d wants %s - trying tier %d", t,
                    tostring(gotQ.enemy), tiers[i + 1]))
            end
        end
        return gotQ, gotOk, gotRes
    end

    setState("QUEST")
    say("taking the " .. enemy .. " quest from here")
    local q, ok, res = attempt(false)

    if not q and not stale(myEpoch) then
        local wantName, gpos = P.giverFor(enemy)
        if not gpos then
            -- No position on file (First Sea): go to the camp and look for it.
            if spot then
                flyTo(spot + Vector3.new(0, CFG.HeightSafe or 20, 0), { stream = enemy })
            end
            local g = (wantName and findQuestGiver(900, wantName)) or findQuestGiver(900, nil, true)
            if g then
                gpos = g.part.Position
                P.learnedGivers[enemy] = g.name
            end
        end
        if gpos and not stale(myEpoch) then
            releasePile()
            say("refused from here - flying to the giver")
            flyTo(gpos + Vector3.new(0, 3, 0))
            task.wait(0.3)
            q, ok, res = attempt(true)
            if q then P.giverSpots[enemy] = gpos end
        end
    end

    local matched = (q ~= nil) and wanted(q.enemy, enemy)
    if q and matched then
        stats.quests += 1
        P.learnedQuests[enemy] = { name = qname, tier = tier }
        questSpecies, questNeed, questKills, questBlind = enemy, q.need, q.have, false
        nilPeeks = 0
    elseif q then
        -- Every tier asked for someone else: this one would never move.
        abandonQuest("no tier of " .. qname .. " asks for " .. enemy)
    elseif ok then
        questSpecies, questNeed, questKills, questBlind =
            enemy, CFG.QuestKillsFallback or 8, 0, true
    end
    P.lastQuestResult = string.format("%s t%d -> %s", qname, tier,
        q and string.format("%s  %d/%d",
                matched and "ACTIVE" or ("WRONG ENEMY, it wants " .. tostring(q.enemy)),
                q.have, q.need)
          or (ok and "sent, tracker unreadable - counting kills here"
                  or ("refused (" .. tostring(res) .. ")")))
    say(P.lastQuestResult)
    return (q ~= nil and matched) or questBlind
end

-- ---------------------------------------------------------
-- THE CIRCUIT
-- ---------------------------------------------------------
local function circuit()
    local names = CFG.Targets
    if #names == 0 then
        local row = levelRow()
        names = row and { row[3] } or {}
    end
    local sea = mySea()
    local out, skipped = {}, {}
    for _, n in ipairs(names) do
        local row = rowOf(n)
        if row and sea and seaOfLevel(row[1]) ~= sea then
            table.insert(skipped, n)
        else
            table.insert(out, { name = n, spot = row and row[4] or nil })
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

-- Make sure the quest running is one the circuit wants; take one if none is.
-- A quest already running for a species on the circuit moves the circuit TO
-- that species, so a running count is never thrown away.
local function ensureQuest(list)
    local q = P.readQuest(true)
    if q and q.have < q.need then
        local idx
        if q.enemy then
            for i, t in ipairs(list) do
                if wanted(q.enemy, t.name) then idx = i break end
            end
        elseif questSpecies then
            for i, t in ipairs(list) do
                if t.name == questSpecies then idx = i break end
            end
        else
            idx = circuitIdx
        end
        local st = idx and stalled[list[idx].name]
        if idx and not (st and os.clock() < st) then
            circuitIdx = idx
            if questSpecies ~= list[idx].name then
                questSpecies, questBlind = list[idx].name, false
                questKills = q.have
            end
            questNeed  = q.need
            questKills = math.max(questKills, q.have)
            return true
        end
        abandonQuest(idx and "its camp stopped respawning"
            or ("it is for " .. tostring(q.enemy) .. ", not on the circuit"))
    elseif questBlind and questSpecies then
        if questKills < (questNeed or 8) then
            for i, t in ipairs(list) do
                if t.name == questSpecies then circuitIdx = i return true end
            end
        end
        questBlind, questSpecies = false, nil
    end
    local cur = list[circuitIdx]
    return acceptFor(cur.name, cur.spot)
end

function P.takeQuestNow()
    local list = circuit()
    if #list == 0 then say(P.circuitNote) return false end
    local cur = list[math.min(circuitIdx, #list)]
    lastAskAt[cur.name] = nil
    return acceptFor(cur.name, cur.spot)
end

-- Is the running quest's count full? Our own kill count says when to look;
-- the tracker is the authority, and it is also glanced at every two seconds
-- in case a kill was missed here. A tracker that has GONE is a finished
-- quest only if our count agrees, or if it stays gone for two looks in a
-- row -- a UI that blinked must not look like a finished quest, because the
-- next quest taken would replace a running count.
local function questFull()
    if not CFG.QuestLoop or not questSpecies then return false end
    if questBlind then return questKills >= (questNeed or CFG.QuestKillsFallback or 8) end
    local now = os.clock()
    local counted = questNeed ~= nil and questKills >= questNeed
    if not counted and now - lastPeek <= 2 then return false end
    lastPeek = now
    local q = P.readQuest(true)
    if q then
        nilPeeks = 0
        if not wanted(q.enemy, questSpecies) then return true end   -- ours is gone
        if q.have >= q.need then return true end
        questKills = q.have
        return false
    end
    if counted then return true end
    nilPeeks += 1
    return nilPeeks >= 2
end

local function onKill(name)
    stats.kills += 1
    if meas then meas.kills += 1 end
    if name == questSpecies then questKills += 1 end
end

-- ---------------------------------------------------------
-- THE FIGHT AT ONE CAMP
-- ---------------------------------------------------------
-- Pile, lock, hit, count -- until the quest is full, the camp is empty, you
-- are hurt, or thirty seconds pass (then the quest is looked at again).
local function fight(cur, names)
    local myEpoch = epoch
    setState("FIGHT")
    local watch = {}
    local pileStart = nil
    local lastBuild, lastHaki = 0, 0
    local sweepEnd = os.clock() + 30
    m1Count = (CFG.StartWith == "M1") and 0 or (CFG.M1Between or 0)

    while P.running and not stale(myEpoch) and os.clock() < sweepEnd do
        if healthPct() < (CFG.EscapeBelow or 0.35) then
            attacking = false
            return "hurt"
        end
        local now = os.clock()

        for m, hum in pairs(watch) do
            local dead = hum.Health <= 0
            if dead or not m.Parent then
                if dead and not countedDead[m] then
                    countedDead[m] = now
                    onKill(cleanName(m))
                end
                watch[m] = nil
            end
        end

        if questFull() then
            if pileStart then recordPile(now - pileStart) end
            attacking = false
            return "done"
        end

        if now - lastBuild > 0.25 then
            lastBuild = now
            local list, centre = buildPile(cur, names)
            pile = list
            if centre and (not pileCentre or (centre - pileCentre).Magnitude > 2) then
                pileCentre = centre
            end
            for _, e in ipairs(list) do watch[e.model] = e.hum end
        end

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

    local list = circuit()
    if #list == 0 then
        say(P.circuitNote)
        task.wait(1.5)
        return
    end
    if circuitIdx > #list then circuitIdx = 1 end
    local names = {}
    for _, t in ipairs(list) do names[t.name] = true end

    if CFG.QuestLoop then ensureQuest(list) end
    if circuitIdx > #list then circuitIdx = 1 end
    local cur = list[circuitIdx]
    activeName = cur.name

    -- To the camp, unless already fighting at it.
    if cur.spot then
        local _, r = parts()
        local camp = cur.spot + Vector3.new(0, CFG.HeightSafe or 20, 0)
        local atPile = pileCentre and (pileCentre - cur.spot).Magnitude <= (CFG.GrabRadius or 300)
        if r and (r.Position - camp).Magnitude > 120 and not atPile then
            releasePile()
            setState("FLY")
            say("flying to " .. cur.name)
            flyTo(camp, { stream = cur.name })
        end
    end

    local why = fight(cur, names)
    if why == "done" then
        stats.questsDone += 1
        questSpecies, questNeed, questKills, questBlind = nil, nil, 0, false
        advance(list)
        if list[circuitIdx].name ~= cur.name then releasePile() end
        say("quest done - next: " .. list[circuitIdx].name)
    elseif why == "empty" then
        if not (CFG.QuestLoop and questSpecies == cur.name) then
            -- No quest holding us here: the next camp while this one respawns.
            if #list > 1 then
                advance(list)
                releasePile()
            else
                waitRespawn(cur, names)
            end
        elseif CFG.WaitRespawn then
            if not waitRespawn(cur, names) then
                stalled[cur.name] = os.clock() + 60
                say(cur.name .. " did not respawn - moving on")
                advance(list)
                releasePile()
            end
        else
            abandonQuest("camp empty, moving on (Wait for the respawn is off)")
            advance(list)
            releasePile()
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
        quest = "Quest circuit", safety = "Safety", stats = "Stats",
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

        switchRow(v, "Quest circuit",
            "Quest, pile, kill - then the next species",
            function() return CFG.QuestLoop end,
            function(x)
                CFG.QuestLoop = x
                say(x and "quest circuit on" or "quest circuit off - farming without quests")
            end)

        gap(v, 8)

        navRow(v, "Targets", function()
            local list = circuit()
            if #list == 0 then return "none" end
            if #CFG.Targets == 0 then return list[1].name .. "  by level" end
            return #list .. " on the circuit"
        end, "target")
        hairline(v)
        navRow(v, "Attack", function() return setupKey() end, "attack")
        hairline(v)
        navRow(v, "Magnet", function()
            if not CFG.Magnet then return "Off" end
            return P.running and (P.pileHeld .. " held") or "On"
        end, "magnet")
        hairline(v)
        navRow(v, "Position", function()
            if CFG.HeightMode == "fixed" then return math.floor(CFG.HeightFixed) .. " up, fixed" end
            return "auto  ·  " .. math.floor(CFG.HeightSafe) .. " up"
        end, "position")
        hairline(v)
        navRow(v, "Travel", function()
            return math.floor(CFG.TravelSpeed) .. " studs/s"
        end, "travel")
        hairline(v)
        navRow(v, "Quest", function()
            if not CFG.QuestLoop then return "Off" end
            local q = P.readQuest()
            if q then return q.have .. " / " .. q.need end
            return questBlind and (questKills .. " counted") or "none running"
        end, "quest")
        hairline(v)
        navRow(v, "Safety", function()
            return "out under " .. math.floor(CFG.EscapeBelow * 100) .. "%"
        end, "safety")
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
            for _, c in ipairs(cand) do sig = sig .. c.name .. (counts[c.name] or 0) .. "," end
            if sig == signature then return end
            signature = sig

            for _, c in ipairs(box:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            for i, c in ipairs(cand) do
                local o = order[c.name]
                local n = counts[c.name]
                local tag = (o and ("#" .. o .. "  ") or "")
                    .. (n and (n .. " alive")
                        or (c.far and string.format("%.0f studs", c.far) or "not loaded"))
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
        switchRow(v, "Aim the camera for skills",
            "Fruit skills fire where the cursor points",
            function() return CFG.AimSkills end,
            function(x) CFG.AimSkills = x if not x then releaseCamera() end end)
        readout(v, function() return "now  " .. tostring(P.nextNote) end)

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
        heading2(v, "the pile")
        sliderRow(v, "Pull from within", 50, 600, 10,
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
        heading2(v, "keeping them hittable")
        caption(v, "The pile sits at the middle of where they spawned, inside "
            .. "every one's own area - an enemy dragged out of its area takes "
            .. "no damage. One that is held and hit with no HP change goes back "
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
            return string.format("now high: %d over the pile", CFG.HeightSafe)
        end)
        radio(v, 82, {
            { "auto", "Auto - high or close" },
            { "fixed", "One fixed spot" },
        }, function() return CFG.HeightMode end, function(x) CFG.HeightMode = x end)
        caption(v, "Auto: high over the pile whenever the hit reaches from "
            .. "there (remote hit, fruit click, fruit skills) - out of their "
            .. "reach. Close beside it when it does not (key presses, "
            .. "fighting-style and sword skills).")
        heading2(v, "auto")
        sliderRow(v, "High, over the pile", 5, 60, 1,
            function() return CFG.HeightSafe end,
            function(x) CFG.HeightSafe = x end, " studs")
        sliderRow(v, "Close, height", 0, 10, 0.5,
            function() return CFG.HeightMelee end,
            function(x) CFG.HeightMelee = x end, " studs")
        sliderRow(v, "Close, out to the side", 0, 15, 0.5,
            function() return CFG.MeleeDistance end,
            function(x) CFG.MeleeDistance = x end, " studs")
        heading2(v, "fixed")
        sliderRow(v, "Height", 0, 60, 1,
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
    -- QUEST
    -- =====================================================
    do
        local v = makeView("quest")
        gap(v, 6)
        switchRow(v, "Quest circuit",
            "Take it from where you are, pile, kill, next species",
            function() return CFG.QuestLoop end,
            function(x) CFG.QuestLoop = x end)
        readout(v, function()
            local q = P.readQuest()
            local running = (q and string.format("%s  %d/%d", tostring(q.enemy or "?"), q.have, q.need))
                or (questBlind and string.format("counting here  %d/%d", questKills, questNeed or 0))
                or "none"
            return table.concat({
                "running  " .. running,
                "for      " .. tostring(questSpecies or "-"),
                "last     " .. tostring(P.lastQuestResult),
                string.format("taken %d   ·   done %d   ·   dropped %d",
                    stats.quests, stats.questsDone, stats.abandons),
            }, "\n")
        end)
        switchRow(v, "Wait for the respawn",
            "Off: drop the quest and go to the next species",
            function() return CFG.WaitRespawn end,
            function(x) CFG.WaitRespawn = x end)
        sliderRow(v, "Wait at most", 10, 120, 5,
            function() return CFG.RespawnMax end,
            function(x) CFG.RespawnMax = x end, " s")
        actionRow(v, "Take the quest now", nil, function() P.takeQuestNow() end)
        actionRow(v, "Drop the running quest", nil, function() P.abandonQuest() end)
        actionRow(v, "Forget learned quests and givers", nil, function()
            table.clear(P.learnedQuests)
            table.clear(P.learnedGivers)
            table.clear(P.giverSpots)
            say("learned quests and givers forgotten")
        end)
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
                "quests      " .. stats.quests .. " taken   " .. stats.questsDone .. " done   "
                    .. stats.abandons .. " dropped",
                "M1          " .. stats.m1 .. "   skills " .. stats.casts .. "   swaps " .. stats.swaps,
                "probes      " .. stats.probes .. "   (M1 ways tried)",
                "travel      " .. stats.flights .. " flights   " .. stats.hops .. " hops   "
                    .. stats.pulledBack .. " pulled back",
                "magnet      held " .. tostring(P.pileHeld) .. "   put back " .. stats.putBack,
                "escapes     " .. stats.escapes,
                "haki        " .. stats.hakiPresses .. "   (J/E presses)",
                "gui scans   " .. tostring(P.questScans or 0),
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
    questSpecies, questNeed, questKills, questBlind = nil, nil, 0, false
    table.clear(lastAskAt)
    table.clear(stalled)
    releasePile()
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
        if attacking and meas then meas.fight += dt end
    end))
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

function P.stop()
    P.running = false
    epoch += 1                 -- everything in flight gives up on this line
    moveEnabled = false
    task.delay(0.3, function() moveEnabled = true end)
    releasePile()
    attacking, flying = false, false
    lockCF, lastWritten = nil, nil
    pcall(releaseCamera)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    pcall(restoreBody)
    setState("IDLE")
    say("stopped")
    print(string.format("[BFF] stopped. kills=%d piles=%d quests=%d",
        stats.kills, stats.piles, stats.questsDone))
end

function P.stats() return stats end
function P.state() return state, statusLine end

pcall(syncWeapons)
say("loaded - pick targets, then press Start")
pcall(buildUI)
-- Water is land from load, farm running or not (farm_pro's, unchanged).
task.spawn(function()
    while _G.BFF == P do
        pcall(keepWater)
        task.wait(0.25)
    end
end)
local deepConn
deepConn = RunService.Heartbeat:Connect(function()
    if _G.BFF ~= P then
        deepConn:Disconnect()
        parkFloor()
        return
    end
    pcall(deepTick)
end)
print("[BFF] loaded. Use the panel, or _G.BFF.start()")
