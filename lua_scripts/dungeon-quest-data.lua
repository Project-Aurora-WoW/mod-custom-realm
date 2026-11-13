-- =====================================================================
--  DungeonQuestNPC - the dungeons, their NPCs and their quests
--
--  DQN.DUNGEONS[dungeonId] holds one entry per instance:
--      name          the instance's name
--      key           slug (wailing_caverns), matched by Config.DISABLE
--      giver/ender   creature_template entries of the two NPCs
--      start         quests the start NPC offers
--      giverSpawns   { map, x, y, z, o } - the entrances; the return
--                    portal sends you to the one in the map you are
--                    standing in (Coilfang has three wings).
--
--  DQN.TAGS holds the quests the database cannot classify: the ones
--  that are not finished inside the instance ("outside") and the
--  attunement and key chains ("attunement").  Add your own the same
--  way.
--
--  Nothing about the quests themselves is stored here: titles, levels,
--  requirements and chain links are read from the world database at
--  runtime, so they stay in sync with your server and come out in the
--  player's own language.  Turn-ins are not listed either - the core
--  reads those from creature_questender, which dungeon-quest.sql
--  writes.
--
--  Every dungeon is listed.  The configuration block at the top of
--  dungeon-quest.sql decides which ones get NPCs in the database; a
--  dungeon without them is simply never spoken to.  The dungeons
--  below are grouped by expansion and party size.
-- =====================================================================

DQN = DQN or {}
DQN.DUNGEONS = {}

-- The quest kinds nothing in the database can describe, keyed by
-- quest id: "outside" (not completed inside the instance) and
-- "attunement" (an attunement or key chain).  Add your own here.
DQN.TAGS = {
    [167]   = "outside",
    [168]   = "outside",
    [722]   = "outside",
    [959]   = "outside",
    [1051]  = "outside",
    [2922]  = "outside",
    [3906]  = "outside",
    [4742]  = "attunement",
    [4743]  = "attunement",
    [4788]  = "attunement",
    [6521]  = "outside",
    [6602]  = "attunement",
    [6626]  = "outside",
    [7068]  = "outside",
    [7070]  = "outside",
    [7487]  = "attunement",
    [7761]  = "attunement",
    [7848]  = "attunement",
    [8600]  = "outside",
    [10091] = "outside",
    [10901] = "outside",
    [11492] = "attunement",
    [14353] = "outside",
}

local D = DQN.DUNGEONS


-- -------------------------------------------------------------------------
--  Classic (5 man)
-- -------------------------------------------------------------------------

-- Blackrock Depths (dungeon 2)
D[2] = { name="Blackrock Depths", key="blackrock_depths",
  giver=9200002, ender=9300002,
  start={3801,3802,3906,3907,3981,4002,4003,4024,4063,4081,4082,4083,4121,4122,4123,4126,4128,4132,4133,4134,4136,4201,4241,4263,4286,4324,4341,4342,4361,4362,7201,7487,7848,8961,9015},
  giverSpawns={
    {230,441.683,20.376,-70.653,5.858},
  },
}

-- Wailing Caverns (dungeon 14)
D[14] = { name="Wailing Caverns", key="wailing_caverns",
  giver=9200014, ender=9300014,
  start={914,959,962,1486,1487,1489,1490,1491},
  giverSpawns={
    {43,-160.793,131.587,-73.66,2.688},
  },
}

-- Ragefire Chasm (dungeon 15)
D[15] = { name="Ragefire Chasm", key="ragefire_chasm",
  giver=9200015, ender=9300015,
  start={5722,5723,5724,5725,5728,5761,14356},
  giverSpawns={
    {389,-3.069,-19.276,-19.197,1.349},
  },
}

-- Shadowfang Keep (dungeon 16)
D[16] = { name="Shadowfang Keep", key="shadowfang_keep",
  giver=9200016, ender=9300016,
  start={1013,1014,1098,1740,9692},
  giverSpawns={
    {33,-232.172,2112.34,76.89,6.176},
  },
}

-- Blackfathom Deeps (dungeon 17)
D[17] = { name="Blackfathom Deeps", key="blackfathom_deeps",
  giver=9200017, ender=9300017,
  start={908,971,1198,1199,1200,1275,1740,6561,6562,6563,6565,6921},
  giverSpawns={
    {48,-155.757,107.471,-40.006,0.014},
  },
}

-- Razorfen Kraul (dungeon 18)
D[18] = { name="Razorfen Kraul", key="razorfen_kraul",
  giver=9200018, ender=9300018,
  start={1101,1102,1109,1142,1221,1701,1838},
  giverSpawns={
    {47,1943.569,1547.576,82,4.522},
  },
}

-- Gnomeregan (dungeon 19)
D[19] = { name="Gnomeregan", key="gnomeregan",
  giver=9200019, ender=9300019,
  start={2841,2842,2843,2922,2923,2924,2925,2926,2927,2928,2929,2930,2931,2947,2949,2951,2952,2962,4601,4602,4605,4606},
  giverSpawns={
    {90,-340.015,-0.724,-152.848,5.663},
    {90,-739.51,2.715,-249.99,6.282},
  },
}

-- Razorfen Downs (dungeon 20)
D[20] = { name="Razorfen Downs", key="razorfen_downs",
  giver=9200020, ender=9300020,
  start={3341,3636,6521,6626,14353},
  giverSpawns={
    {129,2592.633,1104.501,51.29,1.598},
  },
}

-- The Deadmines (dungeon 21)
D[21] = { name="The Deadmines", key="deadmines",
  giver=9200021, ender=9300021,
  start={166,167,168,214,2040},
  giverSpawns={
    {36,-19.578678,-377.40036,60.81927,5.296197},
  },
}

-- The Stockade (dungeon 22)
D[22] = { name="The Stockade", key="stockade",
  giver=9200022, ender=9300022,
  start={377,378,386,387,388,391},
  giverSpawns={
    {34,57.229,0.21,-18.34,3.118},
  },
}

-- Scarlet Monastery (dungeon 23)
D[23] = { name="Scarlet Monastery", key="scarlet_monastery",
  giver=9200023, ender=9300023,
  start={1048,1049,1050,1051,1053,1113,1951,14355},
  giverSpawns={
    {189,1691.99,1053.484,18.677,3.143},
    {189,858.683,1321.505,18.671,3.143},
    {189,1613.83,-323.442,18.674,3.139},
    {189,258.346,-209.14,18.677,3.125},
  },
}

-- Uldaman (dungeon 24)
D[24] = { name="Uldaman", key="uldaman",
  giver=9200024, ender=9300024,
  start={17,704,709,721,722,1139,1360,1956,2199,2200,2201,2202,2204,2240,2278,2279,2280,2283,2284,2318,2338,2339,2340,2341,2342,2361,2398,2418,2848,2855,3375},
  giverSpawns={
    {70,-226.261,52.041,-46.03,4.532},
    {70,-211.387,385.045,-38.769,3.642},
  },
}

-- Zul'Farrak (dungeon 25)
D[25] = { name="Zul'Farrak", key="zul_farrak",
  giver=9200025, ender=9300025,
  start={2768,2770,2846,2861,2864,2865,2936,2991,3042,3527},
  giverSpawns={
    {209,1216.464,841.014,8.93,2.948},
  },
}

-- Maraudon (dungeon 26)
D[26] = { name="Maraudon", key="maraudon",
  giver=9200026, ender=9300026,
  start={7028,7029,7041,7044,7046,7064,7065,7066,7067,7068,7070},
  giverSpawns={
    {349,1022.547,-457.395,-43.43,3.452},
    {349,753.508,-613.59,-33.11,4.512},
  },
}

-- Sunken Temple (dungeon 27)
D[27] = { name="Sunken Temple", key="sunken_temple",
  giver=9200027, ender=9300027,
  start={1445,1446,1475,3380,3446,3447,3528,4143,4146,8232,8236,8253,8257,8413,8418,8422,8425,8733,9053,10593},
  giverSpawns={
    {109,-322.236,99.755,-131.85,0.048},
  },
}

-- Dire Maul (dungeon 29)
D[29] = { name="Dire Maul", key="dire_maul",
  giver=9200029, ender=9300029,
  start={5518,5525,7441,7461,7462,7481,7482,7488,7489,7492,7494,7509,7703,7877,8600,8948,8949,8950,8967,8990,9015,9244,9245,9246,13906},
  giverSpawns={
    {429,47.45,-154.822,-2.712,3.142},
    {429,-199.652,-331.282,-2.72,2.078},
    {429,12.311,-837.085,-32.531,3.142},
    {429,-65.966,159.848,-3.462,0.006},
    {429,34.561,159.48,-3.478,3.152},
    {429,255.212,-19.056,-2.587,1.558},
  },
}

-- Scholomance (dungeon 30)
D[30] = { name="Scholomance", key="scholomance",
  giver=9200030, ender=9300030,
  start={4771,5067,5068,5167,5341,5343,5382,5384,5466,5515,5529,5531,8905,8908,8910,8913,8917,8918,8926,8927,8932,8936,8939,8943,8950,8953,8956,8958,8969,8992,8999,9000,9001,9002,9003,9004,9005,9006,9007,9008,9009,9010,9011,9012,9013,9014,9018,9020,9021,10492,10493,10498,10499},
  giverSpawns={
    {289,199.314,126.474,134.91,2.948},
  },
}

-- Stratholme (dungeon 31)
D[31] = { name="Stratholme", key="stratholme",
  giver=9200031, ender=9300031,
  start={5063,5067,5068,5122,5125,5166,5212,5213,5214,5243,5251,5263,5282,5463,5464,5848,6163,8905,8906,8908,8909,8910,8913,8914,8916,8917,8918,8926,8927,8932,8933,8934,8936,8937,8939,8940,8943,8944,8945,8946,8951,8952,8953,8954,8955,8956,8957,8958,8959,8968,8991,9016,9017,9018,9019,9020,9021,9022,10492,10493,10495,10496,10497},
  giverSpawns={
    {329,3594.887,-3649.006,138.5,2.188},
    {329,3398.075,-3379.95,142.702,3.242},
  },
}

-- -------------------------------------------------------------------------
--  Classic (10 man)
-- -------------------------------------------------------------------------

-- Blackrock Spire (dungeon 28)
D[28] = { name="Blackrock Spire", key="blackrock_spire",
  giver=9200028, ender=9300028,
  start={4701,4724,4729,4734,4735,4742,4743,4764,4765,4766,4768,4769,4788,4862,4866,4867,4907,4974,4981,4982,4983,5001,5002,5047,5081,5102,5103,5124,5127,5160,5166,5167,5306,6502,6569,6602,6821,8906,8907,8910,8911,8912,8914,8915,8917,8919,8920,8926,8927,8931,8932,8934,8935,8937,8938,8939,8940,8941,8942,8944,8951,8952,8954,8957,8959,8961,8966,8989,8995,8999,9000,9001,9002,9003,9004,9005,9006,9007,9008,9009,9010,9011,9012,9013,9014,9016,9017,9022,10494,10496,10497,10498,10499},
  giverSpawns={
    {229,79.642,-227.821,49.839,1.958},
  },
}

-- -------------------------------------------------------------------------
--  The Burning Crusade (5 man)
-- -------------------------------------------------------------------------

-- The Blood Furnace (dungeon 3)
D[3] = { name="The Blood Furnace", key="blood_furnace",
  giver=9200003, ender=9300003,
  start={9589,9590,9607,9608},
  giverSpawns={
    {542,-7.468,-2.272,-43.811,0.341},
  },
}

-- Coilfang Reservoir (dungeon 4)
D[4] = { name="Coilfang Reservoir", key="coilfang_reservoir",
  giver=9200004, ender=9300004,
  start={9715,9717,9719,9738,9763,9765,10667,10885,10900,10901},
  giverSpawns={
    {547,130.725,-121.744,-1.591,4.137},
    {546,19.265,-31.758,-2.751,2.067},
    {545,-13.432,4.975,-4.262,5.834},
  },
}

-- Mana-Tombs (dungeon 5)
D[5] = { name="Mana-Tombs", key="mana_tombs",
  giver=9200005, ender=9300005,
  start={10165,10216,10218,10977},
  giverSpawns={
    {557,-6.362,5.497,-0.954,5.986},
  },
}

-- Auchenai Crypts (dungeon 6)
D[6] = { name="Auchenai Crypts", key="auchenai_crypts",
  giver=9200006, ender=9300006,
  start={10164,10167,10168},
  giverSpawns={
    {558,-12.563,5.425,-0.121,3.543},
  },
}

-- Sethekk Halls (dungeon 7)
D[7] = { name="Sethekk Halls", key="sethekk_halls",
  giver=9200007, ender=9300007,
  start={9637,10097,10098},
  giverSpawns={
    {556,-1.08,-6.467,0.006,1.484},
  },
}

-- The Black Morass (dungeon 8)
D[8] = { name="The Black Morass", key="black_morass",
  giver=9200008, ender=9300008,
  start={9836,10296,10297,10298,10902},
  giverSpawns={
    {269,-1496.795,7037.648,32.562,4.899},
  },
}

-- Shadow Labyrinth (dungeon 9)
D[9] = { name="Shadow Labyrinth", key="shadow_labyrinth",
  giver=9200009, ender=9300009,
  start={9831,9832,10091,10094,10095,10177,10178,10649,10666,10885},
  giverSpawns={
    {555,-2.74,-5.946,-1.128,1.566},
  },
}

-- The Shattered Halls (dungeon 10)
D[10] = { name="The Shattered Halls", key="shattered_halls",
  giver=9200010, ender=9300010,
  start={9492,9493,9495,9496,9524,9637,10670,10884},
  giverSpawns={
    {540,-39.541,-17.065,-13.806,4.253},
  },
}

-- The Arcatraz (dungeon 11)
D[11] = { name="The Arcatraz", key="arcatraz",
  giver=9200011, ender=9300011,
  start={9832,10705,10706,10882},
  giverSpawns={
    {552,2.994,4.755,-0.205,3.375},
  },
}

-- The Botanica (dungeon 12)
D[12] = { name="The Botanica", key="botanica",
  giver=9200012, ender=9300012,
  start={10257,10704,10897,10905},
  giverSpawns={
    {553,32.475,-26.565,-1.114,5.164},
  },
}

-- The Mechanar (dungeon 13)
D[13] = { name="The Mechanar", key="mechanar",
  giver=9200013, ender=9300013,
  start={10665,10704},
  giverSpawns={
    {554,-22.967,8.781,-1.813,4.175},
  },
}

-- Hellfire Ramparts (dungeon 32)
D[32] = { name="Hellfire Ramparts", key="hellfire_ramparts",
  giver=9200032, ender=9300032,
  start={9572,9575,9589,9590},
  giverSpawns={
    {543,-1352.886,1642.98,68.249,3.81},
  },
}

-- Old Hillsbrad Foothills (dungeon 33)
D[33] = { name="Old Hillsbrad Foothills", key="old_hillsbrad_foothills",
  giver=9200033, ender=9300033,
  start={10282,12513},
  giverSpawns={
    {560,2738.919,1315.791,14.042,6.102},
  },
}

-- Magisters' Terrace (dungeon 34)
D[34] = { name="Magisters' Terrace", key="magisters_terrace",
  giver=9200034, ender=9300034,
  start={11488,11490,11492},
  giverSpawns={
    {585,10.086,-0.3,-2.8,3.192},
  },
}

-- -------------------------------------------------------------------------
--  Wrath of the Lich King (5 man)
-- -------------------------------------------------------------------------

-- Utgarde Keep (dungeon 35)
D[35] = { name="Utgarde Keep", key="utgarde_keep",
  giver=9200035, ender=9300035,
  start={11252,11262,11272,13205,13206},
  giverSpawns={
    {574,156.651,-85.65,12.551,3.446},
  },
}

-- Utgarde Pinnacle (dungeon 36)
D[36] = { name="Utgarde Pinnacle", key="utgarde_pinnacle",
  giver=9200036, ender=9300036,
  start={13131,13132},
  giverSpawns={
    {575,581.118,-327.915,110.138,6.264},
  },
}

-- The Nexus (dungeon 37)
D[37] = { name="The Nexus", key="nexus",
  giver=9200037, ender=9300037,
  start={11905,11911,11973,13094,13095},
  giverSpawns={
    {576,145.998,-7.557,-16.636,4.67},
  },
}

-- The Oculus (dungeon 38)
D[38] = { name="The Oculus", key="oculus",
  giver=9200038, ender=9300038,
  start={13124,13127,13128},
  giverSpawns={
    {578,1058.506,985.312,361.07,2.603},
  },
}

-- Azjol-Nerub (dungeon 39)
D[39] = { name="Azjol-Nerub", key="azjol_nerub",
  giver=9200039, ender=9300039,
  start={13167,13182},
  giverSpawns={
    {601,415.44,793.851,831.351,2.358},
  },
}

-- Ahn'kahet (dungeon 40)
D[40] = { name="Ahn'kahet", key="ahn_kahet",
  giver=9200040, ender=9300040,
  start={13187},
  giverSpawns={
    {619,370.27618,-1087.4104,47.360714,3.699443},
  },
}

-- Drak'Tharon Keep (dungeon 41)
D[41] = { name="Drak'Tharon Keep", key="drak_tharon_keep",
  giver=9200041, ender=9300041,
  start={12037,12238,13129},
  giverSpawns={
    {600,-516.988,-490.955,11.01,1.689},
  },
}

-- The Violet Hold (dungeon 42)
D[42] = { name="The Violet Hold", key="violet_hold",
  giver=9200042, ender=9300042,
  start={13158,13159},
  giverSpawns={
    {608,1811.82,803.926,44.364,3.14},
  },
}

-- Gundrak (dungeon 43)
D[43] = { name="Gundrak", key="gundrak",
  giver=9200043, ender=9300043,
  start={13096,13098,13111},
  giverSpawns={
    {604,1890.302,834.745,176.669,5.251},
    {604,1879.32,631.027,176.696,6.283},
  },
}

-- Halls of Stone (dungeon 44)
D[44] = { name="Halls of Stone", key="halls_of_stone",
  giver=0, ender=9300044,
  start={},
  giverSpawns={
  },
}

-- Halls of Lightning (dungeon 45)
D[45] = { name="Halls of Lightning", key="halls_of_lightning",
  giver=9200045, ender=9300045,
  start={13108,13109},
  giverSpawns={
    {602,1331.649,256.624,53.398,1.63},
  },
}

-- The Culling of Stratholme (dungeon 46)
D[46] = { name="The Culling of Stratholme", key="culling_of_stratholme",
  giver=9200046, ender=9300046,
  start={13151},
  giverSpawns={
    {595,1432.398,554.216,36.69,2.018},
  },
}

-- The Forge of Souls (dungeon 48)
D[48] = { name="The Forge of Souls", key="forge_of_souls",
  giver=9200048, ender=9300048,
  start={24499,24506,24510,24802},
  giverSpawns={
    {632,4921.602,2178.353,638.734,5.145},
  },
}

-- Pit of Saron (dungeon 49)
D[49] = { name="Pit of Saron", key="pit_of_saron",
  giver=9200049, ender=9300049,
  start={24461,24498,24559,24682,24683,24710,24712},
  giverSpawns={
    {658,438.742,212.333,528.709,3.115},
  },
}

-- Halls of Reflection (dungeon 50)
D[50] = { name="Halls of Reflection", key="halls_of_reflection",
  giver=9200050, ender=9300050,
  start={24480,24500,24561,24711,24713,24802},
  giverSpawns={
    {668,5241.099,1934.793,707.695,3.942},
  },
}

-- creature entry -> the dungeon it belongs to
DQN.BY_ENTRY = {}
for id, d in pairs(DQN.DUNGEONS) do
    if d.giver and d.giver > 0 then DQN.BY_ENTRY[d.giver] = id end
    if d.ender and d.ender > 0 then DQN.BY_ENTRY[d.ender] = id end
end
