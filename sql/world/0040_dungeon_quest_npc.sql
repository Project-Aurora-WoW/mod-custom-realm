-- ============================================================
-- 0040_dungeon_quest_npc.sql — Данж-квест-раздатчик (mod-eluna-dungeon-quest-giver)
--
-- Источник: rkr87/mod-eluna-dungeon-quest-giver (Eluna/ALE, Lua-only).
-- Внедрено 2026-11-14 по решению владельца проекта. Lua-код:
--   lua_scripts/dungeon-quest-npc.lua (адаптирован: creature.id -> id1)
--   lua_scripts/dungeon-quest-data.lua
-- (см. ROADMAP-Features.md, раздел "Кандидат Фазы 5 ... mod-eluna-dungeon-quest-giver").
--
-- Атрибуция лицензии: списки квестов/инстансов заимствованы из
-- Tntdruid/mod-dungeon-quest-npc (AGPL-3.0); у исходника rkr87 файл LICENSE
-- отсутствует — внедрение выполнено по явному решению владельца проекта.
--
-- Что делает (для каждого инстанса; все 48 данжей включены):
--   1. НПС-раздатчик квестов (92000xx) у входа — меню «весь данж сразу».
--   2. НПС-сдатчик (93000xx) у последнего босса + возвратный портал
--      (94000xx) на выходе (телепорт обратно к входу карты).
--   3. npc_text 92000 — текст меню раздатчика.
-- Отключение отдельных данжей — на рантайме через Config.DISABLE в
-- lua_scripts/dungeon-quest-npc.lua (см. README исходника).
--
-- Адаптация под нашу схему AzerothCore: таблица спауна использует
-- колонку `creature`.`id1` (современный AC), не `id`.
--
-- Идемпотентно: DELETE собственных строк перед INSERT.
-- ============================================================

SET NAMES utf8mb4;
-- ===========================================================================
--  THE RETURN PORTAL
-- ---------------------------------------------------------------------------
--  Every end NPC has a portal next to him; right clicking it sends you back
--  to the entrance of the map you are in.  It is a plain game object using
--  one of the standard portal models - the same one a mage's Portal: spell
--  leaves behind - so it needs no custom assets of your own.
--
--  Some other portal models from AzerothCore's own object data, if you would
--  rather it looked different:
--      4393 Darnassus   4394 Ironforge      4395 Orgrimmar
--      4396 Stormwind   4397 Thunder Bluff  4398 Undercity
--      7146 Shattrath (the big ring portal) 6787-6790 Naxxramas portals
-- ===========================================================================

SET @PORTAL_DISPLAY := 4396;

-- =========================================================================
-- DungeonQuestNPC - world data
-- =========================================================================

SET @GIVER := 9200000;
SET @ENDER := 9300000;
SET @GUID  := 9200000;
SET @MODEL := 1006;

DELETE FROM `creature` WHERE `guid` BETWEEN @GUID + 0 AND @GUID + 999 AND `id1` BETWEEN @GIVER AND @ENDER + 99;
DELETE FROM `creature_queststarter` WHERE `id` BETWEEN @GIVER + 0 AND @GIVER + 99;
DELETE FROM `creature_questender` WHERE `id` BETWEEN @ENDER + 0 AND @ENDER + 99;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN @GIVER + 0 AND @GIVER + 99;
DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN @ENDER + 0 AND @ENDER + 99;
DELETE FROM `creature_template` WHERE `entry` BETWEEN @GIVER + 0 AND @GIVER + 99;
DELETE FROM `creature_template` WHERE `entry` BETWEEN @ENDER + 0 AND @ENDER + 99;

SET @PORTAL := 9400000;            -- gameobject entries of the return portals

DELETE FROM `gameobject` WHERE `id` BETWEEN @PORTAL + 0 AND @PORTAL + 99;
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN @PORTAL + 0 AND @PORTAL + 99;

-- =========================================================================
-- Classic (5 man)
-- =========================================================================

-- -------------------------------------------------------------------------
-- Blackrock Depths   -   dungeon 2
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 2, 'Dungeon Quest', 'Blackrock Depths', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 2, 'Dungeon Quest Turn-in', 'Blackrock Depths', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(@ENDER + 2, 3801), -- Dark Iron Legacy
(@ENDER + 2, 3802), -- Dark Iron Legacy
(@ENDER + 2, 3906), -- Disharmony of Flame
(@ENDER + 2, 3907), -- Disharmony of Fire
(@ENDER + 2, 3981), -- Commander Gorshak
(@ENDER + 2, 3982), -- What Is Going On?
(@ENDER + 2, 4001), -- What Is Going On?
(@ENDER + 2, 4002), -- The Eastern Kingdoms
(@ENDER + 2, 4003), -- The Royal Rescue
(@ENDER + 2, 4004), -- The Princess Saved?
(@ENDER + 2, 4024), -- A Taste of Flame
(@ENDER + 2, 4063), -- The Rise of the Machines
(@ENDER + 2, 4081), -- KILL ON SIGHT: Dark Iron Dwarves
(@ENDER + 2, 4082), -- KILL ON SIGHT: High Ranking Dark Iron Officials
(@ENDER + 2, 4083), -- The Spectral Chalice
(@ENDER + 2, 4121), -- Precarious Predicament
(@ENDER + 2, 4122), -- Grark Lorkrub
(@ENDER + 2, 4123), -- The Heart of the Mountain
(@ENDER + 2, 4126), -- Hurley Blackbreath
(@ENDER + 2, 4128), -- Ragnar Thunderbrew
(@ENDER + 2, 4132), -- Operation: Death to Angerforge
(@ENDER + 2, 4133), -- Vivian Lagrave
(@ENDER + 2, 4134), -- Lost Thunderbrew Recipe
(@ENDER + 2, 4136), -- Ribbly Screwspigot
(@ENDER + 2, 4201), -- The Love Potion
(@ENDER + 2, 4241), -- Marshal Windsor
(@ENDER + 2, 4242), -- Abandoned Hope
(@ENDER + 2, 4263), -- Incendius!
(@ENDER + 2, 4264), -- A Crumpled Up Note
(@ENDER + 2, 4282), -- A Shred of Hope
(@ENDER + 2, 4286), -- The Good Stuff
(@ENDER + 2, 4322), -- Jail Break!
(@ENDER + 2, 4324), -- Yuka Screwspigot
(@ENDER + 2, 4341), -- Kharan Mighthammer
(@ENDER + 2, 4342), -- Kharans Tale
(@ENDER + 2, 4361), -- The Bearer of Bad News
(@ENDER + 2, 4362), -- The Fate of the Kingdom
(@ENDER + 2, 4363), -- The Princesss Surprise
(@ENDER + 2, 7201), -- The Last Element
(@ENDER + 2, 7487), -- Attunement to the Core
(@ENDER + 2, 7848), -- Attunement to the Core
(@ENDER + 2, 8961), -- Three Kings of Flame
(@ENDER + 2, 9015); -- The Challenge

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 21, @GIVER + 2, 230, 0, 0, 1, 1, 0, 441.683, 20.376, -70.653, 5.858, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Blackrock Depths'),
(@GUID + 22, @ENDER + 2, 230, 0, 0, 1, 1, 0, 1358.2495, -807.4423, -85.15223, 2.46855, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Blackrock Depths, check position in-game');

DROP TEMPORARY TABLE IF EXISTS `tmp_dungeon_quest_theme`;
CREATE TEMPORARY TABLE `tmp_dungeon_quest_theme` (`npc` INT UNSIGNED NOT NULL, `theme` INT UNSIGNED NOT NULL);
INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 2, 12944), -- Lokhtos Darkbargainer
(@ENDER + 2, 9021); -- Kharan Mighthammer

-- -------------------------------------------------------------------------
-- Blackrock Depths   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 2;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 2, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 2;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 620, @PORTAL + 2, 230, 0, 0, 1, 1, 1360.120, -805.097, -85.152, 2.469, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Blackrock Depths');

-- -------------------------------------------------------------------------
-- Wailing Caverns   -   dungeon 14
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 14, 'Dungeon Quest', 'Wailing Caverns', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 14, 'Dungeon Quest Turn-in', 'Wailing Caverns', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Wailing Caverns
(@ENDER + 14, 914), -- Leaders of the Fang
(@ENDER + 14, 959), -- Trouble at the Docks
(@ENDER + 14, 962), -- Serpentbloom
(@ENDER + 14, 1486), -- Deviate Hides
(@ENDER + 14, 1487), -- Deviate Eradication
(@ENDER + 14, 1489), -- Hamuul Runetotem
(@ENDER + 14, 1490), -- Nara Wildmane
(@ENDER + 14, 1491), -- Smart Drinks
(@ENDER + 14, 6981); -- The Glowing Shard

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 141, @GIVER + 14, 43, 0, 0, 1, 1, 0, -160.793, 131.587, -73.66, 2.688, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Wailing Caverns'),
(@GUID + 142, @ENDER + 14, 43, 0, 0, 1, 1, 0, 123.397, 239.598, -94.021, 3.089, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Wailing Caverns, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 14, 5770), -- Nara Wildmane
(@ENDER + 14, 3678); -- Disciple of Naralex

-- -------------------------------------------------------------------------
-- Wailing Caverns   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 14;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 14, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 14;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 740, @PORTAL + 14, 43, 0, 0, 1, 1, 123.555, 242.594, -94.021, 3.089, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Wailing Caverns');

-- -------------------------------------------------------------------------
-- Ragefire Chasm   -   dungeon 15
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 15, 'Dungeon Quest', 'Ragefire Chasm', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 15, 'Dungeon Quest Turn-in', 'Ragefire Chasm', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Ragefire Chasm
(@ENDER + 15, 5722), -- Searching for the Lost Satchel
(@ENDER + 15, 5723), -- Testing an Enemys Strength
(@ENDER + 15, 5724), -- Returning the Lost Satchel
(@ENDER + 15, 5725), -- The Power to Destroy...
(@ENDER + 15, 5728), -- Hidden Enemies
(@ENDER + 15, 5761), -- Slaying the Beast
(@ENDER + 15, 14356); -- The Power to Destroy...

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 151, @GIVER + 15, 389, 0, 0, 1, 1, 0, -3.069, -19.276, -19.197, 1.349, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Ragefire Chasm'),
(@GUID + 152, @ENDER + 15, 389, 0, 0, 1, 1, 0, -391.9634, 139.10864, 7.738529, 1.306379, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Ragefire Chasm');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 15, 11833), -- Rahauro
(@ENDER + 15, 11834); -- Maur Grimtotem

-- -------------------------------------------------------------------------
-- Ragefire Chasm   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 15;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 15, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 15;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 750, @PORTAL + 15, 389, 0, 0, 1, 1, -389.068, 138.325, 7.739, 1.306, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Ragefire Chasm');

-- -------------------------------------------------------------------------
-- Shadowfang Keep   -   dungeon 16
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 16, 'Dungeon Quest', 'Shadowfang Keep', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 16, 'Dungeon Quest Turn-in', 'Shadowfang Keep', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Shadowfang Keep
(@ENDER + 16, 1013), -- The Book of Ur
(@ENDER + 16, 1014), -- Arugal Must Die
(@ENDER + 16, 1098), -- Deathstalkers in Shadowfang
(@ENDER + 16, 1740), -- The Orb of Soranruk
(@ENDER + 16, 9692); -- The Path of the Adept

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 161, @GIVER + 16, 33, 0, 0, 1, 1, 0, -232.172, 2112.34, 76.89, 6.176, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Shadowfang Keep'),
(@GUID + 162, @ENDER + 16, 33, 0, 0, 1, 1, 0, -97.38, 2162.99, 144.921, 4.87, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Shadowfang Keep');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 16, 2934), -- Keeper Beldugur
(@ENDER + 16, 3849); -- Deathstalker Adamant

-- -------------------------------------------------------------------------
-- Shadowfang Keep   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 16;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 16, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 16;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 760, @PORTAL + 16, 33, 0, 0, 1, 1, -100.343, 2162.519, 144.921, 4.870, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Shadowfang Keep');

-- -------------------------------------------------------------------------
-- Blackfathom Deeps   -   dungeon 17
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 17, 'Dungeon Quest', 'Blackfathom Deeps', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 17, 'Dungeon Quest Turn-in', 'Blackfathom Deeps', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Blackfathom Deeps
(@ENDER + 17, 908), -- Amongst the Ruins
(@ENDER + 17, 971), -- Knowledge in the Deeps
(@ENDER + 17, 1198), -- In Search of Thaelrid
(@ENDER + 17, 1199), -- Twilight Falls
(@ENDER + 17, 1200), -- Blackfathom Villainy
(@ENDER + 17, 1275), -- Researching the Corruption
(@ENDER + 17, 1740), -- The Orb of Soranruk
(@ENDER + 17, 6561), -- Blackfathom Villainy
(@ENDER + 17, 6562), -- Trouble in the Deeps
(@ENDER + 17, 6563), -- The Essence of AkuMai
(@ENDER + 17, 6564), -- Allegiance to the Old Gods
(@ENDER + 17, 6565), -- Allegiance to the Old Gods
(@ENDER + 17, 6921); -- Amongst the Ruins

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 171, @GIVER + 17, 48, 0, 0, 1, 1, 0, -155.757, 107.471, -40.006, 0.014, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Blackfathom Deeps'),
(@GUID + 172, @ENDER + 17, 48, 0, 0, 1, 1, 0, -855.17126, -478.2714, -34.012196, 1.215622, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Blackfathom Deeps');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 17, 12736), -- Jeneu Sancrea
(@ENDER + 17, 4787); -- Argent Guard Thaelrid

-- -------------------------------------------------------------------------
-- Blackfathom Deeps   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 17;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 17, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 17;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 770, @PORTAL + 17, 48, 0, 0, 1, 1, -852.359, -479.315, -34.012, 1.216, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Blackfathom Deeps');

-- -------------------------------------------------------------------------
-- Razorfen Kraul   -   dungeon 18
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 18, 'Dungeon Quest', 'Razorfen Kraul', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 18, 'Dungeon Quest Turn-in', 'Razorfen Kraul', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Razorfen Kraul
(@ENDER + 18, 1101), -- The Crone of the Kraul
(@ENDER + 18, 1102), -- A Vengeful Fate
(@ENDER + 18, 1109), -- Going, Going, Guano!
(@ENDER + 18, 1142), -- Mortality Wanes
(@ENDER + 18, 1144), -- Willix the Importer
(@ENDER + 18, 1221), -- Blueleaf Tubers
(@ENDER + 18, 1701), -- Fire Hardened Mail
(@ENDER + 18, 1838), -- Brutal Armor
(@ENDER + 18, 6522); -- An Unholy Alliance

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 181, @GIVER + 18, 47, 0, 0, 1, 1, 0, 1943.569, 1547.576, 82.0, 4.522, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Razorfen Kraul'),
(@GUID + 182, @ENDER + 18, 47, 0, 0, 1, 1, 0, 2179.6938, 1886.0841, 72.400566, 0.941605, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Razorfen Kraul');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 18, 4048), -- Falfindel Waywarder
(@ENDER + 18, 4508); -- Willix the Importer

-- -------------------------------------------------------------------------
-- Razorfen Kraul   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 18;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 18, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 18;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 780, @PORTAL + 18, 47, 0, 0, 1, 1, 2182.119, 1884.319, 72.401, 0.942, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Razorfen Kraul');

-- -------------------------------------------------------------------------
-- Gnomeregan   -   dungeon 19
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 19, 'Dungeon Quest', 'Gnomeregan', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 19, 'Dungeon Quest Turn-in', 'Gnomeregan', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Gnomeregan
(@ENDER + 19, 2841), -- Rig Wars
(@ENDER + 19, 2842), -- Chief Engineer Scooty
(@ENDER + 19, 2843), -- Gnomer-gooooone!
(@ENDER + 19, 2904), -- A Fine Mess
(@ENDER + 19, 2922), -- Save Techbots Brain!
(@ENDER + 19, 2923), -- Tinkmaster Overspark
(@ENDER + 19, 2924), -- Essential Artificials
(@ENDER + 19, 2925), -- Klockmorts Essentials
(@ENDER + 19, 2926), -- Gnogaine
(@ENDER + 19, 2927), -- The Day After
(@ENDER + 19, 2928), -- Gyrodrillmatic Excavationators
(@ENDER + 19, 2929), -- The Grand Betrayal
(@ENDER + 19, 2930), -- Data Rescue
(@ENDER + 19, 2931), -- Castpipes Task
(@ENDER + 19, 2945), -- Grime-Encrusted Ring
(@ENDER + 19, 2947), -- Return of the Ring
(@ENDER + 19, 2949), -- Return of the Ring
(@ENDER + 19, 2951), -- The Sparklematic 5200!
(@ENDER + 19, 2952), -- The Sparklematic 5200!
(@ENDER + 19, 2962), -- The Only Cure is More Green Glow
(@ENDER + 19, 4601), -- The Sparklematic 5200!
(@ENDER + 19, 4602), -- The Sparklematic 5200!
(@ENDER + 19, 4605), -- The Sparklematic 5200!
(@ENDER + 19, 4606); -- The Sparklematic 5200!

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 191, @GIVER + 19, 90, 0, 0, 1, 1, 0, -340.015, -0.724, -152.848, 5.663, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Gnomeregan'),
(@GUID + 192, @GIVER + 19, 90, 0, 0, 1, 1, 0, -739.51, 2.715, -249.99, 6.282, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Gnomeregan'),
(@GUID + 193, @ENDER + 19, 90, 0, 0, 1, 1, 0, -576.383, 639.853, -327.283, 1.488, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Gnomeregan');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 19, 1268), -- Ozzie Togglevolt
(@ENDER + 19, 7853); -- Scooty

-- -------------------------------------------------------------------------
-- Gnomeregan   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 19;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 19, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 19;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 790, @PORTAL + 19, 90, 0, 0, 1, 1, -573.393, 639.605, -327.283, 1.488, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Gnomeregan');

-- -------------------------------------------------------------------------
-- Razorfen Downs   -   dungeon 20
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 20, 'Dungeon Quest', 'Razorfen Downs', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 20, 'Dungeon Quest Turn-in', 'Razorfen Downs', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Razorfen Downs
(@ENDER + 20, 3341), -- Bring the End
(@ENDER + 20, 3523), -- Scourge of the Downs
(@ENDER + 20, 3525), -- Extinguishing the Idol
(@ENDER + 20, 3636), -- Bring the Light
(@ENDER + 20, 6521), -- An Unholy Alliance
(@ENDER + 20, 6522), -- An Unholy Alliance
(@ENDER + 20, 6626), -- A Host of Evil
(@ENDER + 20, 14352), -- An Unholy Alliance
(@ENDER + 20, 14353); -- An Unholy Alliance

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 201, @GIVER + 20, 129, 0, 0, 1, 1, 0, 2592.633, 1104.501, 51.29, 1.598, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Razorfen Downs'),
(@GUID + 202, @ENDER + 20, 129, 0, 0, 1, 1, 0, 2380.8953, 951.7629, 55.34347, 0.848012, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Razorfen Downs, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 20, 2308), -- Andrew Brownell
(@ENDER + 20, 8516); -- Belnistrasz

-- -------------------------------------------------------------------------
-- Razorfen Downs   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 20;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 20, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 20;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 800, @PORTAL + 20, 129, 0, 0, 1, 1, 2383.145, 949.778, 55.343, 0.848, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Razorfen Downs');

-- -------------------------------------------------------------------------
-- The Deadmines   -   dungeon 21
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 21, 'Dungeon Quest', 'The Deadmines', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 21, 'Dungeon Quest Turn-in', 'The Deadmines', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Deadmines
(@ENDER + 21, 166), -- The Defias Brotherhood
(@ENDER + 21, 167), -- Oh Brother. . .
(@ENDER + 21, 168), -- Collecting Memories
(@ENDER + 21, 214), -- Red Silk Bandanas
(@ENDER + 21, 373), -- The Unsent Letter
(@ENDER + 21, 2040); -- Underground Assault

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 211, @GIVER + 21, 36, 0, 0, 1, 1, 0, -19.578678, -377.40036, 60.81927, 5.296197, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Deadmines'),
(@GUID + 212, @ENDER + 21, 36, 0, 0, 1, 1, 0, -72.283676, -834.29755, 40.482197, 0.798052, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Deadmines, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 21, 234), -- Gryan Stoutmantle
(@ENDER + 21, 656); -- Wilder Thistlenettle

-- -------------------------------------------------------------------------
-- The Deadmines   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 21;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 21, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 21;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 810, @PORTAL + 21, 36, 0, 0, 1, 1, -70.136, -836.392, 40.482, 0.798, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Deadmines');

-- -------------------------------------------------------------------------
-- The Stockade   -   dungeon 22
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 22, 'Dungeon Quest', 'The Stockade', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 22, 'Dungeon Quest Turn-in', 'The Stockade', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Stockade
(@ENDER + 22, 377), -- Crime and Punishment
(@ENDER + 22, 378), -- The Fury Runs Deep
(@ENDER + 22, 386), -- What Comes Around...
(@ENDER + 22, 387), -- Quell The Uprising
(@ENDER + 22, 388), -- The Color of Blood
(@ENDER + 22, 391); -- The Stockade Riots

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 221, @GIVER + 22, 34, 0, 0, 1, 1, 0, 57.229, 0.21, -18.34, 3.118, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Stockade'),
(@GUID + 222, @ENDER + 22, 34, 0, 0, 1, 1, 0, 82.28181, -141.88177, -33.93956, 0.750494, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Stockade, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 22, 1719), -- Warden Thelwater
(@ENDER + 22, 270); -- Councilman Millstipe

-- -------------------------------------------------------------------------
-- The Stockade   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 22;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 22, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 22;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 820, @PORTAL + 22, 34, 0, 0, 1, 1, 84.328, -144.076, -33.940, 0.750, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Stockade');

-- -------------------------------------------------------------------------
-- Scarlet Monastery   -   dungeon 23
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 23, 'Dungeon Quest', 'Scarlet Monastery', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 23, 'Dungeon Quest Turn-in', 'Scarlet Monastery', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Scarlet Monastery
(@ENDER + 23, 1048), -- Into The Scarlet Monastery
(@ENDER + 23, 1049), -- Compendium of the Fallen
(@ENDER + 23, 1050), -- Mythology of the Titans
(@ENDER + 23, 1051), -- Vorrels Revenge
(@ENDER + 23, 1053), -- In the Name of the Light
(@ENDER + 23, 1113), -- Hearts of Zeal
(@ENDER + 23, 1951), -- Rituals of Power
(@ENDER + 23, 14355); -- Into The Scarlet Monastery

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 231, @GIVER + 23, 189, 0, 0, 1, 1, 0, 1691.99, 1053.484, 18.677, 3.143, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Scarlet Monastery'),
(@GUID + 232, @GIVER + 23, 189, 0, 0, 1, 1, 0, 858.683, 1321.505, 18.671, 3.143, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Scarlet Monastery'),
(@GUID + 233, @GIVER + 23, 189, 0, 0, 1, 1, 0, 1613.83, -323.442, 18.674, 3.139, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Scarlet Monastery'),
(@GUID + 234, @GIVER + 23, 189, 0, 0, 1, 1, 0, 258.346, -209.14, 18.677, 3.125, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Scarlet Monastery'),
(@GUID + 235, @ENDER + 23, 189, 0, 0, 1, 1, 0, 1809.6632, 1428.6112, -8.797188, 4.847003, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Scarlet Monastery'),
(@GUID + 236, @ENDER + 23, 189, 0, 0, 1, 1, 0, 138.82019, -418.83267, 18.504541, 5.616691, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Scarlet Monastery'),
(@GUID + 237, @ENDER + 23, 189, 0, 0, 1, 1, 0, 1981.1577, -431.5735, 11.272326, 3.173007, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Scarlet Monastery, check position in-game'),
(@GUID + 238, @ENDER + 23, 189, 0, 0, 1, 1, 0, 1163.5769, 1418.0734, 31.96639, 4.097159, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Scarlet Monastery');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 23, 3978), -- Sage Truthseeker
(@ENDER + 23, 3979); -- Librarian Mae Paledust

-- -------------------------------------------------------------------------
-- Scarlet Monastery   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 23;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 23, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 23;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 830, @PORTAL + 23, 189, 0, 0, 1, 1, 1806.690, 1428.209, -8.797, 4.847, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Scarlet Monastery'),
(@GUID + 831, @PORTAL + 23, 189, 0, 0, 1, 1, 136.965, -421.191, 18.505, 5.617, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Scarlet Monastery'),
(@GUID + 832, @PORTAL + 23, 189, 0, 0, 1, 1, 1981.063, -428.575, 11.272, 3.173, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Scarlet Monastery'),
(@GUID + 833, @PORTAL + 23, 189, 0, 0, 1, 1, 1161.127, 1419.805, 31.966, 4.097, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Scarlet Monastery');

-- -------------------------------------------------------------------------
-- Uldaman   -   dungeon 24
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 24, 'Dungeon Quest', 'Uldaman', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 24, 'Dungeon Quest Turn-in', 'Uldaman', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Uldaman
(@ENDER + 24, 17), -- Uldaman Reagent Run
(@ENDER + 24, 704), -- Agmonds Fate
(@ENDER + 24, 709), -- Solution to Doom
(@ENDER + 24, 721), -- A Sign of Hope
(@ENDER + 24, 722), -- Amulet of Secrets
(@ENDER + 24, 1139), -- The Lost Tablets of Will
(@ENDER + 24, 1360), -- Reclaimed Treasures
(@ENDER + 24, 1956), -- Power in Uldaman
(@ENDER + 24, 2198), -- The Shattered Necklace
(@ENDER + 24, 2199), -- Lore for a Price
(@ENDER + 24, 2200), -- Back to Uldaman
(@ENDER + 24, 2201), -- Find the Gems
(@ENDER + 24, 2202), -- Uldaman Reagent Run
(@ENDER + 24, 2204), -- Restoring the Necklace
(@ENDER + 24, 2240), -- The Hidden Chamber
(@ENDER + 24, 2278), -- The Platinum Discs
(@ENDER + 24, 2279), -- The Platinum Discs
(@ENDER + 24, 2280), -- The Platinum Discs
(@ENDER + 24, 2283), -- Necklace Recovery
(@ENDER + 24, 2284), -- Necklace Recovery, Take 2
(@ENDER + 24, 2318), -- Translating the Journal
(@ENDER + 24, 2338), -- Translating the Journal
(@ENDER + 24, 2339), -- Find the Gems and Power Source
(@ENDER + 24, 2340), -- Deliver the Gems
(@ENDER + 24, 2341), -- Necklace Recovery, Take 3
(@ENDER + 24, 2342), -- Reclaimed Treasures
(@ENDER + 24, 2361), -- Restoring the Necklace
(@ENDER + 24, 2398), -- The Lost Dwarves
(@ENDER + 24, 2418), -- Power Stones
(@ENDER + 24, 2848), -- Wild Leather Shoulders
(@ENDER + 24, 2855), -- Wild Leather Shoulders
(@ENDER + 24, 3375); -- Replacement Phial

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 241, @GIVER + 24, 70, 0, 0, 1, 1, 0, -226.261, 52.041, -46.03, 4.532, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Uldaman'),
(@GUID + 242, @GIVER + 24, 70, 0, 0, 1, 1, 0, -211.387, 385.045, -38.769, 3.642, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Uldaman'),
(@GUID + 243, @ENDER + 24, 70, 0, 0, 1, 1, 0, 102.634, 255.188, -51.7, 1.472, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Uldaman, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 24, 6826), -- Talvash del Kissel
(@ENDER + 24, 6906); -- Baelog

-- -------------------------------------------------------------------------
-- Uldaman   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 24;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 24, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 24;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 840, @PORTAL + 24, 70, 0, 0, 1, 1, 105.619, 254.892, -51.700, 1.472, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Uldaman');

-- -------------------------------------------------------------------------
-- Zul'Farrak   -   dungeon 25
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 25, 'Dungeon Quest', 'Zul''Farrak', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 25, 'Dungeon Quest Turn-in', 'Zul''Farrak', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Zul'Farrak
(@ENDER + 25, 2768), -- Divino-matic Rod
(@ENDER + 25, 2770), -- Gahzrilla
(@ENDER + 25, 2846), -- Tiara of the Deep
(@ENDER + 25, 2861), -- Tabethas Task
(@ENDER + 25, 2864), -- Tranrek
(@ENDER + 25, 2865), -- Scarab Shells
(@ENDER + 25, 2936), -- The Spider God
(@ENDER + 25, 2991), -- Nekrums Medallion
(@ENDER + 25, 3042), -- Troll Temper
(@ENDER + 25, 3527); -- The Prophecy of Mosharu

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 251, @GIVER + 25, 209, 0, 0, 1, 1, 0, 1216.464, 841.014, 8.93, 2.948, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Zul''Farrak'),
(@GUID + 252, @ENDER + 25, 209, 0, 0, 1, 1, 0, 1752.6969, 1008.89233, 53.487, 1.562724, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Zul''Farrak, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 25, 7407), -- Chief Engineer Bilgewhizzle
(@ENDER + 25, 7604); -- Sergeant Bly

-- -------------------------------------------------------------------------
-- Zul'Farrak   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 25;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 25, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 25;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 850, @PORTAL + 25, 209, 0, 0, 1, 1, 1755.697, 1008.868, 53.487, 1.563, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Zul''Farrak');

-- -------------------------------------------------------------------------
-- Maraudon   -   dungeon 26
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 26, 'Dungeon Quest', 'Maraudon', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 26, 'Dungeon Quest Turn-in', 'Maraudon', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Maraudon
(@ENDER + 26, 7028), -- Twisted Evils
(@ENDER + 26, 7029), -- Vyletongue Corruption
(@ENDER + 26, 7041), -- Vyletongue Corruption
(@ENDER + 26, 7044), -- Legends of Maraudon
(@ENDER + 26, 7046), -- The Scepter of Celebras
(@ENDER + 26, 7064), -- Corruption of Earth and Seed
(@ENDER + 26, 7065), -- Corruption of Earth and Seed
(@ENDER + 26, 7066), -- Seed of Life
(@ENDER + 26, 7067), -- The Pariahs Instructions
(@ENDER + 26, 7068), -- Shadowshard Fragments
(@ENDER + 26, 7070); -- Shadowshard Fragments

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 261, @GIVER + 26, 349, 0, 0, 1, 1, 0, 1022.547, -457.395, -43.43, 3.452, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Maraudon'),
(@GUID + 262, @GIVER + 26, 349, 0, 0, 1, 1, 0, 753.508, -613.59, -33.11, 4.512, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Maraudon'),
(@GUID + 263, @ENDER + 26, 349, 0, 0, 1, 1, 0, 30.573, 115.544, -131.073, 4.63, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Maraudon, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 26, 13698), -- Keeper Marandis
(@ENDER + 26, 13716); -- Celebras the Redeemed

-- -------------------------------------------------------------------------
-- Maraudon   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 26;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 26, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 26;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 860, @PORTAL + 26, 349, 0, 0, 1, 1, 27.583, 115.791, -131.073, 4.630, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Maraudon');

-- -------------------------------------------------------------------------
-- Sunken Temple   -   dungeon 27
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 27, 'Dungeon Quest', 'Sunken Temple', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 27, 'Dungeon Quest Turn-in', 'Sunken Temple', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Sunken Temple
(@ENDER + 27, 1445), -- The Temple of AtalHakkar
(@ENDER + 27, 1446), -- Jammalan the Prophet
(@ENDER + 27, 1475), -- Into The Temple of AtalHakkar
(@ENDER + 27, 3373), -- The Essence of Eranikus
(@ENDER + 27, 3380), -- The Sunken Temple
(@ENDER + 27, 3446), -- Into the Depths
(@ENDER + 27, 3447), -- Secret of the Circle
(@ENDER + 27, 3528), -- The God Hakkar
(@ENDER + 27, 4143), -- Haze of Evil
(@ENDER + 27, 4146), -- Zapper Fuel
(@ENDER + 27, 8232), -- The Green Drake
(@ENDER + 27, 8236), -- The Azure Key
(@ENDER + 27, 8253), -- Destroy Morphaz
(@ENDER + 27, 8257), -- Blood of Morphaz
(@ENDER + 27, 8413), -- Da Voodoo
(@ENDER + 27, 8418), -- Forging the Mightstone
(@ENDER + 27, 8422), -- Trolls of a Feather
(@ENDER + 27, 8425), -- Voodoo Feathers
(@ENDER + 27, 8733), -- Eranikus, Tyrant of the Dream
(@ENDER + 27, 9053), -- A Better Ingredient
(@ENDER + 27, 10593); -- Ancient Evil

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 271, @GIVER + 27, 109, 0, 0, 1, 1, 0, -322.236, 99.755, -131.85, 0.048, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Sunken Temple'),
(@GUID + 272, @ENDER + 27, 109, 0, 0, 1, 1, 0, -658.338, -43.762, -90.835, 1.576, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Sunken Temple, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 27, 7771), -- Marvon Rivetseeker
(@ENDER + 27, 5598); -- Atalai Exile

-- -------------------------------------------------------------------------
-- Sunken Temple   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 27;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 27, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 27;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 870, @PORTAL + 27, 109, 0, 0, 1, 1, -655.338, -43.746, -90.835, 1.576, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Sunken Temple');

-- -------------------------------------------------------------------------
-- Dire Maul   -   dungeon 29
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 29, 'Dungeon Quest', 'Dire Maul', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 29, 'Dungeon Quest Turn-in', 'Dire Maul', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Dire Maul
(@ENDER + 29, 5518), -- The Gordok Ogre Suit
(@ENDER + 29, 5525), -- Free Knot!
(@ENDER + 29, 7441), -- Pusillin and the Elder AzjTordin
(@ENDER + 29, 7461), -- The Madness Within
(@ENDER + 29, 7462), -- The Treasure of the Shendralar
(@ENDER + 29, 7481), -- Elven Legends
(@ENDER + 29, 7482), -- Elven Legends
(@ENDER + 29, 7488), -- Lethtendriss Web
(@ENDER + 29, 7489), -- Lethtendriss Web
(@ENDER + 29, 7492), -- Camp Mojache
(@ENDER + 29, 7494), -- Feathermoon Stronghold
(@ENDER + 29, 7498), -- Garona: A Study on Stealth and Treachery
(@ENDER + 29, 7499), -- Codex of Defense
(@ENDER + 29, 7500), -- The Arcanists Cookbook
(@ENDER + 29, 7501), -- The Light and How To Swing It
(@ENDER + 29, 7502), -- Harnessing Shadows
(@ENDER + 29, 7504), -- Holy Bologna: What the Light Wont Tell You
(@ENDER + 29, 7505), -- Frost Shock and You
(@ENDER + 29, 7506), -- The Emerald Dream...
(@ENDER + 29, 7507), -- Forors Compendium
(@ENDER + 29, 7508), -- The Forging of QuelSerrar
(@ENDER + 29, 7509), -- The Forging of QuelSerrar
(@ENDER + 29, 7649), -- Enchanted Thorium Platemail: Volume I
(@ENDER + 29, 7650), -- Enchanted Thorium Platemail: Volume II
(@ENDER + 29, 7703), -- Unfinished Gordok Business
(@ENDER + 29, 7877), -- The Treasure of the Shendralar
(@ENDER + 29, 8600), -- The Horde Needs Rugged Leather!
(@ENDER + 29, 8948), -- Anthions Old Friend
(@ENDER + 29, 8949), -- Falrins Vendetta
(@ENDER + 29, 8950), -- The Instigators Enchantment
(@ENDER + 29, 8967), -- The Left Piece of Lord Valthalaks Amulet
(@ENDER + 29, 8990), -- The Right Piece of Lord Valthalaks Amulet
(@ENDER + 29, 9015), -- The Challenge
(@ENDER + 29, 9244), -- Icy Scale Bracers
(@ENDER + 29, 9245), -- Icy Scale Gauntlets
(@ENDER + 29, 9246), -- Icy Scale Breastplate
(@ENDER + 29, 13906); -- They Grow Up So Fast

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 291, @GIVER + 29, 429, 0, 0, 1, 1, 0, 47.45, -154.822, -2.712, 3.142, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 292, @GIVER + 29, 429, 0, 0, 1, 1, 0, -199.652, -331.282, -2.72, 2.078, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 293, @GIVER + 29, 429, 0, 0, 1, 1, 0, 12.311, -837.085, -32.531, 3.142, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 294, @GIVER + 29, 429, 0, 0, 1, 1, 0, -65.966, 159.848, -3.462, 0.006, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 295, @GIVER + 29, 429, 0, 0, 1, 1, 0, 34.561, 159.48, -3.478, 3.152, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 296, @GIVER + 29, 429, 0, 0, 1, 1, 0, 255.212, -19.056, -2.587, 1.558, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Dire Maul'),
(@GUID + 297, @ENDER + 29, 429, 0, 0, 1, 1, 0, 253.43103, -423.8473, -119.962, 4.808383, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Dire Maul, check position in-game'),
(@GUID + 298, @ENDER + 29, 429, 0, 0, 1, 1, 0, 133.323, 633.883, -48.384, 4.625, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Dire Maul, check position in-game'),
(@GUID + 299, @ENDER + 29, 429, 0, 0, 1, 1, 0, 812.3387, 506.14395, 37.31824, 4.717626, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Dire Maul, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 29, 16032), -- Falrin Treeshaper
(@ENDER + 29, 14368); -- Lorekeeper Lydros

-- -------------------------------------------------------------------------
-- Dire Maul   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 29;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 29, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 29;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 890, @PORTAL + 29, 429, 0, 0, 1, 1, 250.445, -424.135, -119.962, 4.808, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Dire Maul'),
(@GUID + 891, @PORTAL + 29, 429, 0, 0, 1, 1, 130.334, 634.145, -48.384, 4.625, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Dire Maul'),
(@GUID + 892, @PORTAL + 29, 429, 0, 0, 1, 1, 809.339, 506.128, 37.318, 4.718, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Dire Maul');

-- -------------------------------------------------------------------------
-- Scholomance   -   dungeon 30
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 30, 'Dungeon Quest', 'Scholomance', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 30, 'Dungeon Quest Turn-in', 'Scholomance', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Scholomance
(@ENDER + 30, 4771), -- Dawns Gambit
(@ENDER + 30, 5067), -- Leggings of Arcana
(@ENDER + 30, 5068), -- Breastplate of Bloodthirst
(@ENDER + 30, 5167), -- Legplates of the Chromatic Defier
(@ENDER + 30, 5341), -- Barov Family Fortune
(@ENDER + 30, 5343), -- Barov Family Fortune
(@ENDER + 30, 5382), -- Doctor Theolen Krastinov, the Butcher
(@ENDER + 30, 5384), -- Kirtonos the Herald
(@ENDER + 30, 5466), -- The Lich, Ras Frostwhisper
(@ENDER + 30, 5515), -- Krastinovs Bag of Horrors
(@ENDER + 30, 5529), -- Plagued Hatchlings
(@ENDER + 30, 5531), -- Betina Bigglezink
(@ENDER + 30, 8829), -- The Ultimate Deception
(@ENDER + 30, 8905), -- An Earnest Proposition
(@ENDER + 30, 8908), -- An Earnest Proposition
(@ENDER + 30, 8910), -- An Earnest Proposition
(@ENDER + 30, 8913), -- An Earnest Proposition
(@ENDER + 30, 8917), -- An Earnest Proposition
(@ENDER + 30, 8918), -- An Earnest Proposition
(@ENDER + 30, 8926), -- Just Compensation
(@ENDER + 30, 8927), -- Just Compensation
(@ENDER + 30, 8932), -- Just Compensation
(@ENDER + 30, 8936), -- Just Compensation
(@ENDER + 30, 8939), -- Just Compensation
(@ENDER + 30, 8943), -- Just Compensation
(@ENDER + 30, 8950), -- The Instigators Enchantment
(@ENDER + 30, 8953), -- Anthions Parting Words
(@ENDER + 30, 8956), -- Anthions Parting Words
(@ENDER + 30, 8958), -- Anthions Parting Words
(@ENDER + 30, 8969), -- The Left Piece of Lord Valthalaks Amulet
(@ENDER + 30, 8992), -- The Right Piece of Lord Valthalaks Amulet
(@ENDER + 30, 8999), -- Saving the Best for Last
(@ENDER + 30, 9000), -- Saving the Best for Last
(@ENDER + 30, 9001), -- Saving the Best for Last
(@ENDER + 30, 9002), -- Saving the Best for Last
(@ENDER + 30, 9003), -- Saving the Best for Last
(@ENDER + 30, 9004), -- Saving the Best for Last
(@ENDER + 30, 9005), -- Saving the Best for Last
(@ENDER + 30, 9006), -- Saving the Best for Last
(@ENDER + 30, 9007), -- Saving the Best for Last
(@ENDER + 30, 9008), -- Saving the Best for Last
(@ENDER + 30, 9009), -- Saving the Best for Last
(@ENDER + 30, 9010), -- Saving the Best for Last
(@ENDER + 30, 9011), -- Saving the Best for Last
(@ENDER + 30, 9012), -- Saving the Best for Last
(@ENDER + 30, 9013), -- Saving the Best for Last
(@ENDER + 30, 9014), -- Saving the Best for Last
(@ENDER + 30, 9018), -- Anthions Parting Words
(@ENDER + 30, 9020), -- Anthions Parting Words
(@ENDER + 30, 9021), -- Anthions Parting Words
(@ENDER + 30, 10492), -- An Earnest Proposition
(@ENDER + 30, 10493), -- An Earnest Proposition
(@ENDER + 30, 10498), -- Saving the Best for Last
(@ENDER + 30, 10499); -- Saving the Best for Last

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 301, @GIVER + 30, 289, 0, 0, 1, 1, 0, 199.314, 126.474, 134.91, 2.948, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Scholomance'),
(@GUID + 302, @ENDER + 30, 289, 0, 0, 1, 1, 0, 194.77, -12.342, 75.646, 2.683, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Scholomance, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 30, 11022), -- Alexi Barov
(@ENDER + 30, 11216); -- Eva Sarkhoff

-- -------------------------------------------------------------------------
-- Scholomance   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 30;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 30, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 30;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 900, @PORTAL + 30, 289, 0, 0, 1, 1, 196.098, -9.652, 75.646, 2.683, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Scholomance');

-- -------------------------------------------------------------------------
-- Stratholme   -   dungeon 31
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 31, 'Dungeon Quest', 'Stratholme', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 31, 'Dungeon Quest Turn-in', 'Stratholme', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Stratholme
(@ENDER + 31, 5063), -- Cap of the Scarlet Savant
(@ENDER + 31, 5067), -- Leggings of Arcana
(@ENDER + 31, 5068), -- Breastplate of Bloodthirst
(@ENDER + 31, 5122), -- The Medallion of Faith
(@ENDER + 31, 5125), -- Aurius Reckoning
(@ENDER + 31, 5166), -- Breastplate of the Chromatic Flight
(@ENDER + 31, 5212), -- The Flesh Does Not Lie
(@ENDER + 31, 5213), -- The Active Agent
(@ENDER + 31, 5214), -- The Great Fras Siabi
(@ENDER + 31, 5243), -- Houses of the Holy
(@ENDER + 31, 5251), -- The Archivist
(@ENDER + 31, 5262), -- The Truth Comes Crashing Down
(@ENDER + 31, 5263), -- Above and Beyond
(@ENDER + 31, 5282), -- The Restless Souls
(@ENDER + 31, 5463), -- Menethils Gift
(@ENDER + 31, 5464), -- Menethils Gift
(@ENDER + 31, 5848), -- Of Love and Family
(@ENDER + 31, 6163), -- Ramstein
(@ENDER + 31, 8829), -- The Ultimate Deception
(@ENDER + 31, 8905), -- An Earnest Proposition
(@ENDER + 31, 8906), -- An Earnest Proposition
(@ENDER + 31, 8908), -- An Earnest Proposition
(@ENDER + 31, 8909), -- An Earnest Proposition
(@ENDER + 31, 8910), -- An Earnest Proposition
(@ENDER + 31, 8913), -- An Earnest Proposition
(@ENDER + 31, 8914), -- An Earnest Proposition
(@ENDER + 31, 8916), -- An Earnest Proposition
(@ENDER + 31, 8917), -- An Earnest Proposition
(@ENDER + 31, 8918), -- An Earnest Proposition
(@ENDER + 31, 8926), -- Just Compensation
(@ENDER + 31, 8927), -- Just Compensation
(@ENDER + 31, 8932), -- Just Compensation
(@ENDER + 31, 8933), -- Just Compensation
(@ENDER + 31, 8934), -- Just Compensation
(@ENDER + 31, 8936), -- Just Compensation
(@ENDER + 31, 8937), -- Just Compensation
(@ENDER + 31, 8939), -- Just Compensation
(@ENDER + 31, 8940), -- Just Compensation
(@ENDER + 31, 8943), -- Just Compensation
(@ENDER + 31, 8944), -- Just Compensation
(@ENDER + 31, 8945), -- Dead Mans Plea
(@ENDER + 31, 8946), -- Proof of Life
(@ENDER + 31, 8951), -- Anthions Parting Words
(@ENDER + 31, 8952), -- Anthions Parting Words
(@ENDER + 31, 8953), -- Anthions Parting Words
(@ENDER + 31, 8954), -- Anthions Parting Words
(@ENDER + 31, 8955), -- Anthions Parting Words
(@ENDER + 31, 8956), -- Anthions Parting Words
(@ENDER + 31, 8957), -- Anthions Parting Words
(@ENDER + 31, 8958), -- Anthions Parting Words
(@ENDER + 31, 8959), -- Anthions Parting Words
(@ENDER + 31, 8968), -- The Left Piece of Lord Valthalaks Amulet
(@ENDER + 31, 8991), -- The Right Piece of Lord Valthalaks Amulet
(@ENDER + 31, 9016), -- Anthions Parting Words
(@ENDER + 31, 9017), -- Anthions Parting Words
(@ENDER + 31, 9018), -- Anthions Parting Words
(@ENDER + 31, 9019), -- Anthions Parting Words
(@ENDER + 31, 9020), -- Anthions Parting Words
(@ENDER + 31, 9021), -- Anthions Parting Words
(@ENDER + 31, 9022), -- Anthions Parting Words
(@ENDER + 31, 10492), -- An Earnest Proposition
(@ENDER + 31, 10493), -- An Earnest Proposition
(@ENDER + 31, 10495), -- Just Compensation
(@ENDER + 31, 10496), -- Anthions Parting Words
(@ENDER + 31, 10497); -- Anthions Parting Words

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 311, @GIVER + 31, 329, 0, 0, 1, 1, 0, 3594.887, -3649.006, 138.5, 2.188, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Stratholme'),
(@GUID + 312, @GIVER + 31, 329, 0, 0, 1, 1, 0, 3398.075, -3379.95, 142.702, 3.242, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Stratholme'),
(@GUID + 313, @ENDER + 31, 329, 0, 0, 1, 1, 0, 3410.9329, -3060.1743, 136.51038, 0.212712, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Stratholme, check position in-game'),
(@GUID + 314, @ENDER + 31, 329, 0, 0, 1, 1, 0, 4022.2688, -3335.2256, 115.05917, 5.284855, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Stratholme, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 31, 10917), -- Aurius
(@ENDER + 31, 16031); -- Ysida Harmon

-- -------------------------------------------------------------------------
-- Stratholme   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 31;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 31, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 31;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 910, @PORTAL + 31, 329, 0, 0, 1, 1, 3411.566, -3063.107, 136.510, 0.213, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Stratholme'),
(@GUID + 911, @PORTAL + 31, 329, 0, 0, 1, 1, 4019.747, -3336.851, 115.059, 5.285, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Stratholme');

-- =========================================================================
-- Classic (10 man)
-- =========================================================================

-- -------------------------------------------------------------------------
-- Blackrock Spire   -   dungeon 28
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 28, 'Dungeon Quest', 'Blackrock Spire', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 28, 'Dungeon Quest Turn-in', 'Blackrock Spire', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Blackrock Spire
(@ENDER + 28, 4701), -- Put Her Down
(@ENDER + 28, 4724), -- The Pack Mistress
(@ENDER + 28, 4729), -- Kiblers Exotic Pets
(@ENDER + 28, 4734), -- Egg Freezing
(@ENDER + 28, 4735), -- Egg Collection
(@ENDER + 28, 4742), -- Seal of Ascension
(@ENDER + 28, 4743), -- Seal of Ascension
(@ENDER + 28, 4764), -- Doomriggers Clasp
(@ENDER + 28, 4765), -- Delivery to Ridgewell
(@ENDER + 28, 4766), -- Mayara Brightwing
(@ENDER + 28, 4768), -- The Darkstone Tablet
(@ENDER + 28, 4769), -- Vivian Lagrave and the Darkstone Tablet
(@ENDER + 28, 4788), -- The Final Tablets
(@ENDER + 28, 4862), -- En-Ay-Es-Tee-Why
(@ENDER + 28, 4866), -- Mothers Milk
(@ENDER + 28, 4867), -- Urok Doomhowl
(@ENDER + 28, 4903), -- Warlords Command
(@ENDER + 28, 4907), -- Tinkee Steamboil
(@ENDER + 28, 4974), -- For The Horde!
(@ENDER + 28, 4981), -- Operative Bijou
(@ENDER + 28, 4982), -- Bijous Belongings
(@ENDER + 28, 4983), -- Bijous Reconnaissance Report
(@ENDER + 28, 5001), -- Bijous Belongings
(@ENDER + 28, 5002), -- Message to Maxwell
(@ENDER + 28, 5047), -- Finkle Einhorn, At Your Service!
(@ENDER + 28, 5081), -- Maxwells Mission
(@ENDER + 28, 5089), -- General Drakkisaths Command
(@ENDER + 28, 5102), -- General Drakkisaths Demise
(@ENDER + 28, 5103), -- Hot Fiery Death
(@ENDER + 28, 5124), -- Fiery Plate Gauntlets
(@ENDER + 28, 5127), -- The Demon Forge
(@ENDER + 28, 5160), -- The Matron Protectorate
(@ENDER + 28, 5166), -- Breastplate of the Chromatic Flight
(@ENDER + 28, 5167), -- Legplates of the Chromatic Defier
(@ENDER + 28, 5306), -- Snakestone of the Shadow Huntress
(@ENDER + 28, 6502), -- Drakefire Amulet
(@ENDER + 28, 6569), -- Oculus Illusions
(@ENDER + 28, 6602), -- Blood of the Black Dragon Champion
(@ENDER + 28, 6821), -- Eye of the Emberseer
(@ENDER + 28, 7761), -- Blackhands Command
(@ENDER + 28, 8906), -- An Earnest Proposition
(@ENDER + 28, 8907), -- An Earnest Proposition
(@ENDER + 28, 8910), -- An Earnest Proposition
(@ENDER + 28, 8911), -- An Earnest Proposition
(@ENDER + 28, 8912), -- An Earnest Proposition
(@ENDER + 28, 8914), -- An Earnest Proposition
(@ENDER + 28, 8915), -- An Earnest Proposition
(@ENDER + 28, 8917), -- An Earnest Proposition
(@ENDER + 28, 8919), -- An Earnest Proposition
(@ENDER + 28, 8920), -- An Earnest Proposition
(@ENDER + 28, 8926), -- Just Compensation
(@ENDER + 28, 8927), -- Just Compensation
(@ENDER + 28, 8931), -- Just Compensation
(@ENDER + 28, 8932), -- Just Compensation
(@ENDER + 28, 8934), -- Just Compensation
(@ENDER + 28, 8935), -- Just Compensation
(@ENDER + 28, 8937), -- Just Compensation
(@ENDER + 28, 8938), -- Just Compensation
(@ENDER + 28, 8939), -- Just Compensation
(@ENDER + 28, 8940), -- Just Compensation
(@ENDER + 28, 8941), -- Just Compensation
(@ENDER + 28, 8942), -- Just Compensation
(@ENDER + 28, 8944), -- Just Compensation
(@ENDER + 28, 8951), -- Anthions Parting Words
(@ENDER + 28, 8952), -- Anthions Parting Words
(@ENDER + 28, 8954), -- Anthions Parting Words
(@ENDER + 28, 8957), -- Anthions Parting Words
(@ENDER + 28, 8959), -- Anthions Parting Words
(@ENDER + 28, 8961), -- Three Kings of Flame
(@ENDER + 28, 8966), -- The Left Piece of Lord Valthalaks Amulet
(@ENDER + 28, 8989), -- The Right Piece of Lord Valthalaks Amulet
(@ENDER + 28, 8995), -- Mea Culpa, Lord Valthalak
(@ENDER + 28, 8999), -- Saving the Best for Last
(@ENDER + 28, 9000), -- Saving the Best for Last
(@ENDER + 28, 9001), -- Saving the Best for Last
(@ENDER + 28, 9002), -- Saving the Best for Last
(@ENDER + 28, 9003), -- Saving the Best for Last
(@ENDER + 28, 9004), -- Saving the Best for Last
(@ENDER + 28, 9005), -- Saving the Best for Last
(@ENDER + 28, 9006), -- Saving the Best for Last
(@ENDER + 28, 9007), -- Saving the Best for Last
(@ENDER + 28, 9008), -- Saving the Best for Last
(@ENDER + 28, 9009), -- Saving the Best for Last
(@ENDER + 28, 9010), -- Saving the Best for Last
(@ENDER + 28, 9011), -- Saving the Best for Last
(@ENDER + 28, 9012), -- Saving the Best for Last
(@ENDER + 28, 9013), -- Saving the Best for Last
(@ENDER + 28, 9014), -- Saving the Best for Last
(@ENDER + 28, 9016), -- Anthions Parting Words
(@ENDER + 28, 9017), -- Anthions Parting Words
(@ENDER + 28, 9022), -- Anthions Parting Words
(@ENDER + 28, 10494), -- Just Compensation
(@ENDER + 28, 10496), -- Anthions Parting Words
(@ENDER + 28, 10497), -- Anthions Parting Words
(@ENDER + 28, 10498), -- Saving the Best for Last
(@ENDER + 28, 10499); -- Saving the Best for Last

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 281, @GIVER + 28, 229, 0, 0, 1, 1, 0, 79.642, -227.821, 49.839, 1.958, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Blackrock Spire'),
(@GUID + 282, @ENDER + 28, 229, 0, 0, 1, 1, 0, -24.665913, -467.59708, 90.9931, 4.354599, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Blackrock Spire, check position in-game'),
(@GUID + 283, @ENDER + 28, 229, 0, 0, 1, 1, 0, 37.73191, -297.50076, 110.954636, 2.435169, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Blackrock Spire, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 28, 9046), -- Scarshield Quartermaster
(@ENDER + 28, 10776); -- Finkle Einhorn

-- -------------------------------------------------------------------------
-- Blackrock Spire   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 28;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 28, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 28;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 880, @PORTAL + 28, 229, 0, 0, 1, 1, -27.476, -466.546, 90.993, 4.355, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Blackrock Spire'),
(@GUID + 881, @PORTAL + 28, 229, 0, 0, 1, 1, 39.679, -295.219, 110.955, 2.435, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Blackrock Spire');

-- =========================================================================
-- The Burning Crusade (5 man)
-- =========================================================================

-- -------------------------------------------------------------------------
-- The Blood Furnace   -   dungeon 3
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 3, 'Dungeon Quest', 'The Blood Furnace', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 3, 'Dungeon Quest Turn-in', 'The Blood Furnace', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Blood Furnace
(@ENDER + 3, 9589), -- The Blood is Life
(@ENDER + 3, 9590), -- The Blood is Life
(@ENDER + 3, 9607), -- Heart of Rage
(@ENDER + 3, 9608); -- Heart of Rage

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 31, @GIVER + 3, 542, 0, 0, 3, 1, 0, -7.468, -2.272, -43.811, 0.341, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Blood Furnace'),
(@GUID + 32, @ENDER + 3, 542, 0, 0, 3, 1, 0, 353.848, -140.56, -25.46, 2.174, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Blood Furnace');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 3, 17479), -- Gunny
(@ENDER + 3, 17558); -- Cazarez

-- -------------------------------------------------------------------------
-- The Blood Furnace   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 3;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 3, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 3;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 630, @PORTAL + 3, 542, 0, 0, 1, 1, 356.319, -138.858, -25.460, 2.174, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Blood Furnace');

-- -------------------------------------------------------------------------
-- Coilfang Reservoir   -   dungeon 4
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 4, 'Dungeon Quest', 'Coilfang Reservoir', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 4, 'Dungeon Quest Turn-in', 'Coilfang Reservoir', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Coilfang Reservoir
(@ENDER + 4, 9715), -- Bring Me A Shrubbery!
(@ENDER + 4, 9717), -- Oh, Its On!
(@ENDER + 4, 9719), -- Stalk the Stalker
(@ENDER + 4, 9738), -- Lost in Action
(@ENDER + 4, 9763), -- The Warlords Hideout
(@ENDER + 4, 9764), -- Orders from Lady Vashj
(@ENDER + 4, 9765), -- Preparing for War
(@ENDER + 4, 10667), -- Underworld Loam
(@ENDER + 4, 10885), -- Trial of the Naaru: Strength
(@ENDER + 4, 10900), -- The Mark of Vashj
(@ENDER + 4, 10901); -- The Cudgel of Kardesh

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 41, @GIVER + 4, 547, 0, 0, 3, 1, 0, 130.725, -121.744, -1.591, 4.137, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Coilfang Reservoir'),
(@GUID + 42, @GIVER + 4, 546, 0, 0, 3, 1, 0, 19.265, -31.758, -2.751, 2.067, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Coilfang Reservoir'),
(@GUID + 43, @GIVER + 4, 545, 0, 0, 3, 1, 0, -13.432, 4.975, -4.262, 5.834, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Coilfang Reservoir'),
(@GUID + 44, @ENDER + 4, 547, 0, 0, 3, 1, 0, -292.66937, -632.1297, 37.097992, 5.211121, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Coilfang Reservoir, check position in-game'),
(@GUID + 45, @ENDER + 4, 546, 0, 0, 3, 1, 0, 149.8875, 42.617092, 27.079924, 4.696674, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Coilfang Reservoir, check position in-game'),
(@GUID + 46, @ENDER + 4, 545, 0, 0, 3, 1, 0, -87.2726, -576.1782, 8.186956, 1.783946, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Coilfang Reservoir, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 4, 17884), -- Watcher Jhang
(@ENDER + 4, 17841); -- Ysiel Windsinger

-- -------------------------------------------------------------------------
-- Coilfang Reservoir   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 4;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 4, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 4;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 640, @PORTAL + 4, 547, 0, 0, 1, 1, -295.304, -633.565, 37.098, 5.211, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Coilfang Reservoir'),
(@GUID + 641, @PORTAL + 4, 546, 0, 0, 1, 1, 146.888, 42.664, 27.080, 4.697, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Coilfang Reservoir'),
(@GUID + 642, @PORTAL + 4, 545, 0, 0, 1, 1, -84.340, -575.544, 8.187, 1.784, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Coilfang Reservoir');

-- -------------------------------------------------------------------------
-- Mana-Tombs   -   dungeon 5
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 5, 'Dungeon Quest', 'Mana-Tombs', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 5, 'Dungeon Quest Turn-in', 'Mana-Tombs', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Mana-Tombs
(@ENDER + 5, 10165), -- Undercutting the Competition
(@ENDER + 5, 10216), -- Safety Is Job One
(@ENDER + 5, 10218), -- Someone Elses Hard Work Pays Off
(@ENDER + 5, 10977); -- Stasis Chambers of the Mana-Tombs

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 51, @GIVER + 5, 557, 0, 0, 3, 1, 0, -6.362, 5.497, -0.954, 5.986, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Mana-Tombs'),
(@GUID + 52, @ENDER + 5, 557, 0, 0, 3, 1, 0, -143.25383, 9.806555, 16.792788, 3.148134, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Mana-Tombs, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 5, 19674), -- Nexus-Prince Haramad
(@ENDER + 5, 19670); -- Artificer Morphalius

-- -------------------------------------------------------------------------
-- Mana-Tombs   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 5;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 5, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 5;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 650, @PORTAL + 5, 557, 0, 0, 1, 1, -143.273, 12.806, 16.793, 3.148, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Mana-Tombs');

-- -------------------------------------------------------------------------
-- Auchenai Crypts   -   dungeon 6
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 6, 'Dungeon Quest', 'Auchenai Crypts', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 6, 'Dungeon Quest Turn-in', 'Auchenai Crypts', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Auchenai Crypts
(@ENDER + 6, 10164), -- Everything Will Be Alright
(@ENDER + 6, 10167), -- Auchindoun...
(@ENDER + 6, 10168); -- What the Soul Sees

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 61, @GIVER + 6, 558, 0, 0, 3, 1, 0, -12.563, 5.425, -0.121, 3.543, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Auchenai Crypts'),
(@GUID + 62, @ENDER + 6, 558, 0, 0, 3, 1, 0, 87.702, -387.49893, 26.590649, 3.220784, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Auchenai Crypts');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 6, 18687), -- Mother Kashur
(@ENDER + 6, 18687); -- Mother Kashur

-- -------------------------------------------------------------------------
-- Auchenai Crypts   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 6;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 6, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 6;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 660, @PORTAL + 6, 558, 0, 0, 1, 1, 87.465, -384.508, 26.591, 3.221, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Auchenai Crypts');

-- -------------------------------------------------------------------------
-- Sethekk Halls   -   dungeon 7
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 7, 'Dungeon Quest', 'Sethekk Halls', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 7, 'Dungeon Quest Turn-in', 'Sethekk Halls', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Sethekk Halls
(@ENDER + 7, 9637), -- Kalynnas Request
(@ENDER + 7, 10097), -- Brother Against Brother
(@ENDER + 7, 10098); -- Terokks Legacy

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 71, @GIVER + 7, 556, 0, 0, 3, 1, 0, -1.08, -6.467, 0.006, 1.484, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Sethekk Halls'),
(@GUID + 72, @ENDER + 7, 556, 0, 0, 3, 1, 0, 80.13596, 287.43195, 26.62932, 3.128284, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Sethekk Halls, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 7, 18933), -- Isfar
(@ENDER + 7, 17636); -- Kalynna Lathred

-- -------------------------------------------------------------------------
-- Sethekk Halls   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 7;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 7, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 7;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 670, @PORTAL + 7, 556, 0, 0, 1, 1, 80.176, 290.432, 26.629, 3.128, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Sethekk Halls');

-- -------------------------------------------------------------------------
-- The Black Morass   -   dungeon 8
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 8, 'Dungeon Quest', 'The Black Morass', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 8, 'Dungeon Quest Turn-in', 'The Black Morass', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Black Morass
(@ENDER + 8, 9836), -- The Masters Touch
(@ENDER + 8, 9837), -- Return to Khadgar
(@ENDER + 8, 10296), -- The Black Morass
(@ENDER + 8, 10297), -- The Opening of the Dark Portal
(@ENDER + 8, 10298), -- Hero of the Brood
(@ENDER + 8, 10902); -- Master of Elixirs

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 81, @GIVER + 8, 269, 0, 0, 3, 1, 0, -1496.795, 7037.648, 32.562, 4.899, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Black Morass'),
(@GUID + 82, @ENDER + 8, 269, 0, 0, 3, 1, 0, -2032.02, 7138.19, 22.727, 5.059, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Black Morass, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 8, 20201), -- Saat
(@ENDER + 8, 20130); -- Andormu

-- -------------------------------------------------------------------------
-- The Black Morass   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 8;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 8, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 8;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 680, @PORTAL + 8, 269, 0, 0, 1, 1, -2034.842, 7137.171, 22.727, 5.059, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Black Morass');

-- -------------------------------------------------------------------------
-- Shadow Labyrinth   -   dungeon 9
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 9, 'Dungeon Quest', 'Shadow Labyrinth', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 9, 'Dungeon Quest Turn-in', 'Shadow Labyrinth', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Shadow Labyrinth
(@ENDER + 9, 9831), -- Entry Into Karazhan
(@ENDER + 9, 9832), -- The Second and Third Fragments
(@ENDER + 9, 10091), -- The Soul Devices
(@ENDER + 9, 10094), -- The Codex of Blood
(@ENDER + 9, 10095), -- Into the Heart of the Labyrinth
(@ENDER + 9, 10177), -- Trouble at Auchindoun
(@ENDER + 9, 10178), -- Find Spy Togun
(@ENDER + 9, 10649), -- The Book of Fel Names
(@ENDER + 9, 10666), -- The Lexicon Demonica
(@ENDER + 9, 10885); -- Trial of the Naaru: Strength

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 91, @GIVER + 9, 555, 0, 0, 3, 1, 0, -2.74, -5.946, -1.128, 1.566, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Shadow Labyrinth'),
(@GUID + 92, @ENDER + 9, 555, 0, 0, 3, 1, 0, -129.43724, -521.1356, 17.077324, 2.531599, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Shadow Labyrinth');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 9, 18891), -- Spy Togun
(@ENDER + 9, 18893); -- Spymistress Mehlisah Highcrown

-- -------------------------------------------------------------------------
-- Shadow Labyrinth   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 9;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 9, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 9;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 690, @PORTAL + 9, 555, 0, 0, 1, 1, -127.719, -518.677, 17.077, 2.532, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Shadow Labyrinth');

-- -------------------------------------------------------------------------
-- The Shattered Halls   -   dungeon 10
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 10, 'Dungeon Quest', 'The Shattered Halls', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 10, 'Dungeon Quest Turn-in', 'The Shattered Halls', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Shattered Halls
(@ENDER + 10, 9492), -- Turning the Tide
(@ENDER + 10, 9493), -- Pride of the Fel Horde
(@ENDER + 10, 9495), -- The Will of the Warchief
(@ENDER + 10, 9496), -- Pride of the Fel Horde
(@ENDER + 10, 9524), -- Imprisoned in the Citadel
(@ENDER + 10, 9637), -- Kalynnas Request
(@ENDER + 10, 10670), -- Tear of the Earthmother
(@ENDER + 10, 10884); -- Trial of the Naaru: Mercy

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 101, @GIVER + 10, 540, 0, 0, 3, 1, 0, -39.541, -17.065, -13.806, 4.253, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Shattered Halls'),
(@GUID + 102, @ENDER + 10, 540, 0, 0, 3, 1, 0, 178.38406, -83.87494, 2.150183, 0.064139, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Shattered Halls, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 10, 16819), -- Force Commander Danath Trollbane
(@ENDER + 10, 3230); -- Nazgrel

-- -------------------------------------------------------------------------
-- The Shattered Halls   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 10;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 10, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 10;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 700, @PORTAL + 10, 540, 0, 0, 1, 1, 178.576, -86.869, 2.150, 0.064, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Shattered Halls');

-- -------------------------------------------------------------------------
-- The Arcatraz   -   dungeon 11
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 11, 'Dungeon Quest', 'The Arcatraz', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 11, 'Dungeon Quest Turn-in', 'The Arcatraz', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Arcatraz
(@ENDER + 11, 9832), -- The Second and Third Fragments
(@ENDER + 11, 10705), -- Seer Udalo
(@ENDER + 11, 10706), -- A Mysterious Portent
(@ENDER + 11, 10882); -- Harbinger of Doom

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 111, @GIVER + 11, 552, 0, 0, 3, 1, 0, 2.994, 4.755, -0.205, 3.375, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Arcatraz'),
(@GUID + 112, @ENDER + 11, 552, 0, 0, 3, 1, 0, 446.152, -179.001, 43.644, 1.606, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Arcatraz, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 11, 21700), -- Akama
(@ENDER + 11, 21962); -- Udalo

-- -------------------------------------------------------------------------
-- The Arcatraz   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 11;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 11, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 11;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 710, @PORTAL + 11, 552, 0, 0, 1, 1, 449.150, -178.895, 43.644, 1.606, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Arcatraz');

-- -------------------------------------------------------------------------
-- The Botanica   -   dungeon 12
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 12, 'Dungeon Quest', 'The Botanica', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 12, 'Dungeon Quest Turn-in', 'The Botanica', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Botanica
(@ENDER + 12, 10257), -- Capturing the Keystone
(@ENDER + 12, 10704), -- How to Break Into the Arcatraz
(@ENDER + 12, 10897), -- Master of Potions
(@ENDER + 12, 10905); -- Master of Potions

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 121, @GIVER + 12, 553, 0, 0, 3, 1, 0, 32.475, -26.565, -1.114, 5.164, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Botanica'),
(@GUID + 122, @ENDER + 12, 553, 0, 0, 3, 1, 0, 98.938, 381.14, -27.41, 2.689, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Botanica');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 12, 19481), -- Archmage Vargoth
(@ENDER + 12, 17909); -- Lauranna Tharwell

-- -------------------------------------------------------------------------
-- The Botanica   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 12;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 12, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 12;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 720, @PORTAL + 12, 553, 0, 0, 1, 1, 100.250, 383.838, -27.410, 2.689, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Botanica');

-- -------------------------------------------------------------------------
-- The Mechanar   -   dungeon 13
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 13, 'Dungeon Quest', 'The Mechanar', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 13, 'Dungeon Quest Turn-in', 'The Mechanar', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Mechanar
(@ENDER + 13, 10665), -- Fresh from the Mechanar
(@ENDER + 13, 10704); -- How to Break Into the Arcatraz

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 131, @GIVER + 13, 554, 0, 0, 3, 1, 0, -22.967, 8.781, -1.813, 4.175, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Mechanar'),
(@GUID + 132, @ENDER + 13, 554, 0, 0, 3, 1, 0, 100.47248, 151.79721, 25.604559, 6.110178, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Mechanar, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 13, 21465), -- David Wayne
(@ENDER + 13, 21465); -- David Wayne

-- -------------------------------------------------------------------------
-- The Mechanar   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 13;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 13, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 13;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 730, @PORTAL + 13, 554, 0, 0, 1, 1, 99.956, 148.842, 25.605, 6.110, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Mechanar');

-- -------------------------------------------------------------------------
-- Hellfire Ramparts   -   dungeon 32
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 32, 'Dungeon Quest', 'Hellfire Ramparts', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 32, 'Dungeon Quest Turn-in', 'Hellfire Ramparts', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Hellfire Ramparts
(@ENDER + 32, 9572), -- Weaken the Ramparts
(@ENDER + 32, 9575), -- Weaken the Ramparts
(@ENDER + 32, 9589), -- The Blood is Life
(@ENDER + 32, 9590); -- The Blood is Life

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 321, @GIVER + 32, 543, 0, 0, 3, 1, 0, -1352.886, 1642.98, 68.249, 3.81, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Hellfire Ramparts'),
(@GUID + 322, @ENDER + 32, 543, 0, 0, 3, 1, 0, -1436.3038, 1767.0138, 82.045494, 5.507824, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Hellfire Ramparts, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 32, 17493), -- Stone Guard Stokton
(@ENDER + 32, 17479); -- Gunny

-- -------------------------------------------------------------------------
-- Hellfire Ramparts   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 32;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 32, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 32;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 920, @PORTAL + 32, 543, 0, 0, 1, 1, -1438.404, 1764.871, 82.045, 5.508, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Hellfire Ramparts');

-- -------------------------------------------------------------------------
-- Old Hillsbrad Foothills   -   dungeon 33
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 33, 'Dungeon Quest', 'Old Hillsbrad Foothills', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 33, 'Dungeon Quest Turn-in', 'Old Hillsbrad Foothills', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Old Hillsbrad Foothills
(@ENDER + 33, 10282), -- Old Hillsbrad
(@ENDER + 33, 10283), -- Tarethas Diversion
(@ENDER + 33, 10284), -- Escape from Durnholde
(@ENDER + 33, 10285), -- Return to Andormu
(@ENDER + 33, 12513); -- Nice Hat...

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 331, @GIVER + 33, 560, 0, 0, 3, 1, 0, 2738.919, 1315.791, 14.042, 6.102, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Old Hillsbrad Foothills'),
(@GUID + 332, @ENDER + 33, 560, 0, 0, 3, 1, 0, 2647.5127, 649.41296, 56.110313, 2.072142, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Old Hillsbrad Foothills, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 33, 18887), -- Taretha
(@ENDER + 33, 17876); -- Thrall

-- -------------------------------------------------------------------------
-- Old Hillsbrad Foothills   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 33;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 33, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 33;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 930, @PORTAL + 33, 560, 0, 0, 1, 1, 2650.144, 650.855, 56.110, 2.072, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Old Hillsbrad Foothills');

-- -------------------------------------------------------------------------
-- Magisters' Terrace   -   dungeon 34
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 34, 'Dungeon Quest', 'Magisters'' Terrace', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 34, 'Dungeon Quest Turn-in', 'Magisters'' Terrace', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Magisters' Terrace
(@ENDER + 34, 11488), -- Magisters Terrace
(@ENDER + 34, 11490), -- The Scryers Scryer
(@ENDER + 34, 11492); -- Hard to Kill

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 341, @GIVER + 34, 585, 0, 0, 3, 1, 0, 10.086, -0.3, -2.8, 3.192, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Magisters'' Terrace'),
(@GUID + 342, @ENDER + 34, 585, 0, 0, 3, 1, 0, 147.62064, 198.13785, -11.957967, 1.401065, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Magisters'' Terrace, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 34, 24813), -- Exarch Larethor
(@ENDER + 34, 24848); -- Kalecgos

-- -------------------------------------------------------------------------
-- Magisters' Terrace   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 34;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 34, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 34;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 940, @PORTAL + 34, 585, 0, 0, 1, 1, 150.578, 197.631, -11.958, 1.401, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Magisters'' Terrace');

-- =========================================================================
-- Wrath of the Lich King (5 man)
-- =========================================================================

-- -------------------------------------------------------------------------
-- Utgarde Keep   -   dungeon 35
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 35, 'Dungeon Quest', 'Utgarde Keep', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 35, 'Dungeon Quest Turn-in', 'Utgarde Keep', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Utgarde Keep
(@ENDER + 35, 11252), -- Into Utgarde!
(@ENDER + 35, 11262), -- Ingvar Must Die!
(@ENDER + 35, 11272), -- A Score to Settle
(@ENDER + 35, 13205), -- Disarmament
(@ENDER + 35, 13206); -- Disarmament

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 351, @GIVER + 35, 574, 0, 0, 3, 1, 0, 156.651, -85.65, 12.551, 3.446, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Utgarde Keep'),
(@GUID + 352, @ENDER + 35, 574, 0, 0, 3, 1, 0, 216.932, -336.13345, 180.45308, 1.043706, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Utgarde Keep, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 35, 24111), -- Defender Mordun
(@ENDER + 35, 23780); -- High Executor Anselm

-- -------------------------------------------------------------------------
-- Utgarde Keep   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 35;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 35, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 35;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 950, @PORTAL + 35, 574, 0, 0, 1, 1, 219.525, -337.643, 180.453, 1.044, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Utgarde Keep');

-- -------------------------------------------------------------------------
-- Utgarde Pinnacle   -   dungeon 36
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 36, 'Dungeon Quest', 'Utgarde Pinnacle', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 36, 'Dungeon Quest Turn-in', 'Utgarde Pinnacle', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Utgarde Pinnacle
(@ENDER + 36, 13131), -- Junk in My Trunk
(@ENDER + 36, 13132); -- Vengeance Be Mine!

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 361, @GIVER + 36, 575, 0, 0, 3, 1, 0, 581.118, -327.915, 110.138, 6.264, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Utgarde Pinnacle'),
(@GUID + 362, @ENDER + 36, 575, 0, 0, 3, 1, 0, 431.21622, -312.79608, 104.76195, 3.70402, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Utgarde Pinnacle, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 36, 30871), -- Brigg Smallshanks
(@ENDER + 36, 30871); -- Brigg Smallshanks

-- -------------------------------------------------------------------------
-- Utgarde Pinnacle   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 36;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 36, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 36;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 960, @PORTAL + 36, 575, 0, 0, 1, 1, 429.616, -310.258, 104.762, 3.704, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Utgarde Pinnacle');

-- -------------------------------------------------------------------------
-- The Nexus   -   dungeon 37
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 37, 'Dungeon Quest', 'The Nexus', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 37, 'Dungeon Quest Turn-in', 'The Nexus', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Nexus
(@ENDER + 37, 11905), -- Postponing the Inevitable
(@ENDER + 37, 11911), -- Quickening
(@ENDER + 37, 11973), -- Prisoner of War
(@ENDER + 37, 13094), -- Have They No Shame?
(@ENDER + 37, 13095); -- Have They No Shame?

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 371, @GIVER + 37, 576, 0, 0, 3, 1, 0, 145.998, -7.557, -16.636, 4.67, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Nexus'),
(@GUID + 372, @ENDER + 37, 576, 0, 0, 3, 1, 0, 288.014, -19.714, -16.566, 0.815, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Nexus, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 37, 25314), -- Archmage Berinand
(@ENDER + 37, 26110); -- Librarian Serrah

-- -------------------------------------------------------------------------
-- The Nexus   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 37;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 37, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 37;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 970, @PORTAL + 37, 576, 0, 0, 1, 1, 290.197, -21.772, -16.566, 0.815, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Nexus');

-- -------------------------------------------------------------------------
-- The Oculus   -   dungeon 38
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 38, 'Dungeon Quest', 'The Oculus', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 38, 'Dungeon Quest Turn-in', 'The Oculus', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Oculus
(@ENDER + 38, 13124), -- The Struggle Persists
(@ENDER + 38, 13126), -- A Unified Front
(@ENDER + 38, 13127), -- Mage-Lord Urom
(@ENDER + 38, 13128); -- A Wing and a Prayer

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 381, @GIVER + 38, 578, 0, 0, 3, 1, 0, 1058.506, 985.312, 361.07, 2.603, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Oculus'),
(@GUID + 382, @ENDER + 38, 578, 0, 0, 3, 1, 0, 1021.86224, 1059.2532, 605.6263, 4.967203, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Oculus, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 38, 27658), -- Belgaristrasz
(@ENDER + 38, 27659); -- Eternos

-- -------------------------------------------------------------------------
-- The Oculus   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 38;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 38, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 38;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 980, @PORTAL + 38, 578, 0, 0, 1, 1, 1018.959, 1058.497, 605.626, 4.967, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Oculus');

-- -------------------------------------------------------------------------
-- Azjol-Nerub   -   dungeon 39
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 39, 'Dungeon Quest', 'Azjol-Nerub', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 39, 'Dungeon Quest Turn-in', 'Azjol-Nerub', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Azjol-Nerub
(@ENDER + 39, 13167), -- Death to the Traitor King
(@ENDER + 39, 13182); -- Dont Forget the Eggs!

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 391, @GIVER + 39, 601, 0, 0, 3, 1, 0, 415.44, 793.851, 831.351, 2.358, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Azjol-Nerub'),
(@GUID + 392, @ENDER + 39, 601, 0, 0, 3, 1, 0, 548.64215, 160.77498, 196.31625, 1.511674, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Azjol-Nerub, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 39, 26653), -- Kilix the Unraveler
(@ENDER + 39, 26653); -- Kilix the Unraveler

-- -------------------------------------------------------------------------
-- Azjol-Nerub   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 39;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 39, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 39;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 990, @PORTAL + 39, 601, 0, 0, 1, 1, 551.637, 160.598, 196.316, 1.512, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Azjol-Nerub');

-- -------------------------------------------------------------------------
-- Ahn'kahet   -   dungeon 40
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 40, 'Dungeon Quest', 'Ahn''kahet', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 40, 'Dungeon Quest Turn-in', 'Ahn''kahet', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Ahn'kahet
(@ENDER + 40, 13187), -- The Faceless Ones
(@ENDER + 40, 13204); -- Funky Fungi

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 401, @GIVER + 40, 619, 0, 0, 3, 1, 0, 370.27618, -1087.4104, 47.360714, 3.699443, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Ahn''kahet'),
(@GUID + 402, @ENDER + 40, 619, 0, 0, 3, 1, 0, 522.61395, -363.38873, 45.946663, 4.677918, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Ahn''kahet, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 40, 26653), -- Kilix the Unraveler
(@ENDER + 40, 26653); -- Kilix the Unraveler

-- -------------------------------------------------------------------------
-- Ahn'kahet   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 40;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 40, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 40;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1000, @PORTAL + 40, 619, 0, 0, 1, 1, 519.616, -363.285, 45.947, 4.678, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Ahn''kahet');

-- -------------------------------------------------------------------------
-- Drak'Tharon Keep   -   dungeon 41
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 41, 'Dungeon Quest', 'Drak''Tharon Keep', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 41, 'Dungeon Quest Turn-in', 'Drak''Tharon Keep', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Drak'Tharon Keep
(@ENDER + 41, 12037), -- Search and Rescue
(@ENDER + 41, 12238), -- Cleansing DrakTharon
(@ENDER + 41, 13129); -- Head Games

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 411, @GIVER + 41, 600, 0, 0, 3, 1, 0, -516.988, -490.955, 11.01, 1.689, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Drak''Tharon Keep'),
(@GUID + 412, @ENDER + 41, 600, 0, 0, 3, 1, 0, -235.46774, -623.4009, 116.48491, 4.682502, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Drak''Tharon Keep, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 41, 26604), -- Mack Fearsen
(@ENDER + 41, 26664); -- Kurzel

-- -------------------------------------------------------------------------
-- Drak'Tharon Keep   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 41;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 41, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 41;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1010, @PORTAL + 41, 600, 0, 0, 1, 1, -238.466, -623.311, 116.485, 4.683, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Drak''Tharon Keep');

-- -------------------------------------------------------------------------
-- The Violet Hold   -   dungeon 42
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 42, 'Dungeon Quest', 'The Violet Hold', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 42, 'Dungeon Quest Turn-in', 'The Violet Hold', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Violet Hold
(@ENDER + 42, 13158), -- Discretion is Key
(@ENDER + 42, 13159); -- Containment

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 421, @GIVER + 42, 608, 0, 0, 3, 1, 0, 1811.82, 803.926, 44.364, 3.14, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Violet Hold'),
(@GUID + 422, @ENDER + 42, 608, 0, 0, 3, 1, 0, 1839.4908, 788.94214, 44.202053, 1.351751, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Violet Hold, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 42, 30658), -- Lieutenant Sinclari
(@ENDER + 42, 16128); -- Rhonin

-- -------------------------------------------------------------------------
-- The Violet Hold   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 42;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 42, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 42;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1020, @PORTAL + 42, 608, 0, 0, 1, 1, 1842.419, 788.290, 44.202, 1.352, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Violet Hold');

-- -------------------------------------------------------------------------
-- Gundrak   -   dungeon 43
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 43, 'Dungeon Quest', 'Gundrak', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 43, 'Dungeon Quest Turn-in', 'Gundrak', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Gundrak
(@ENDER + 43, 13096), -- Galdarah Must Pay
(@ENDER + 43, 13098), -- For Posterity
(@ENDER + 43, 13111); -- One of a Kind

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 431, @GIVER + 43, 604, 0, 0, 3, 1, 0, 1890.302, 834.745, 176.669, 5.251, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Gundrak'),
(@GUID + 432, @GIVER + 43, 604, 0, 0, 3, 1, 0, 1879.32, 631.027, 176.696, 6.283, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Gundrak'),
(@GUID + 433, @ENDER + 43, 604, 0, 0, 3, 1, 0, 1949.809, 703.27325, 135.93068, 2.735156, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Gundrak, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 43, 30676), -- Chronicler BahKini
(@ENDER + 43, 30671); -- Tolmar

-- -------------------------------------------------------------------------
-- Gundrak   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 43;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 43, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 43;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1030, @PORTAL + 43, 604, 0, 0, 1, 1, 1950.995, 706.029, 135.931, 2.735, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Gundrak');

-- -------------------------------------------------------------------------
-- Halls of Stone   -   dungeon 44
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@ENDER + 44, 'Dungeon Quest Turn-in', 'Halls of Stone', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Halls of Stone
(@ENDER + 44, 13207); -- Halls of Stone

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 441, @ENDER + 44, 599, 0, 0, 3, 1, 0, 1303.199, 667.576, 189.691, 3.194, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Halls of Stone, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@ENDER + 44, 28070); -- Brann Bronzebeard

-- -------------------------------------------------------------------------
-- Halls of Stone   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 44;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 44, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 44;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1040, @PORTAL + 44, 599, 0, 0, 1, 1, 1303.042, 670.572, 189.691, 3.194, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Halls of Stone');

-- -------------------------------------------------------------------------
-- Halls of Lightning   -   dungeon 45
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 45, 'Dungeon Quest', 'Halls of Lightning', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 45, 'Dungeon Quest Turn-in', 'Halls of Lightning', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Halls of Lightning
(@ENDER + 45, 13108), -- Whatever it Takes!
(@ENDER + 45, 13109); -- Diametrically Opposed

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 451, @GIVER + 45, 602, 0, 0, 3, 1, 0, 1331.649, 256.624, 53.398, 1.63, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Halls of Lightning'),
(@GUID + 452, @ENDER + 45, 602, 0, 0, 3, 1, 0, 1194.3287, 68.05104, 60.729923, 3.827723, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Halls of Lightning, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 45, 30382), -- Brann Bronzebeard
(@ENDER + 45, 30382); -- Brann Bronzebeard

-- -------------------------------------------------------------------------
-- Halls of Lightning   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 45;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 45, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 45;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1050, @PORTAL + 45, 602, 0, 0, 1, 1, 1192.428, 70.372, 60.730, 3.828, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Halls of Lightning');

-- -------------------------------------------------------------------------
-- The Culling of Stratholme   -   dungeon 46
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 46, 'Dungeon Quest', 'The Culling of Stratholme', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 46, 'Dungeon Quest Turn-in', 'The Culling of Stratholme', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Culling of Stratholme
(@ENDER + 46, 13149), -- Dispelling Illusions
(@ENDER + 46, 13151); -- A Royal Escort

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 461, @GIVER + 46, 595, 0, 0, 3, 1, 0, 1432.398, 554.216, 36.69, 2.018, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Culling of Stratholme'),
(@GUID + 462, @ENDER + 46, 595, 0, 0, 3, 1, 0, 2294.5947, 1506.8448, 128.734, 5.135635, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Culling of Stratholme, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 46, 26527), -- Chromie
(@ENDER + 46, 26499); -- Arthas

-- -------------------------------------------------------------------------
-- The Culling of Stratholme   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 46;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 46, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 46;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1060, @PORTAL + 46, 595, 0, 0, 1, 1, 2291.859, 1505.613, 128.734, 5.136, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Culling of Stratholme');

-- -------------------------------------------------------------------------
-- The Forge of Souls   -   dungeon 48
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 48, 'Dungeon Quest', 'The Forge of Souls', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 48, 'Dungeon Quest Turn-in', 'The Forge of Souls', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- The Forge of Souls
(@ENDER + 48, 14443), -- The Battered Hilt
(@ENDER + 48, 24499), -- Echoes of Tortured Souls
(@ENDER + 48, 24506), -- Inside the Frozen Citadel
(@ENDER + 48, 24510), -- Inside the Frozen Citadel
(@ENDER + 48, 24511), -- Echoes of Tortured Souls
(@ENDER + 48, 24554), -- The Battered Hilt
(@ENDER + 48, 24802); -- Wrath of the Lich King

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 481, @GIVER + 48, 632, 0, 0, 3, 1, 0, 4921.602, 2178.353, 638.734, 5.145, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - The Forge of Souls'),
(@GUID + 482, @ENDER + 48, 632, 0, 0, 3, 1, 0, 5679.851, 2526.6592, 714.6916, 0.806562, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - The Forge of Souls, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 48, 37597), -- Lady Jaina Proudmoore
(@ENDER + 48, 37779); -- Dark Ranger Loralen

-- -------------------------------------------------------------------------
-- The Forge of Souls   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 48;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 48, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 48;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1080, @PORTAL + 48, 632, 0, 0, 1, 1, 5682.017, 2524.583, 714.692, 0.807, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - The Forge of Souls');

-- -------------------------------------------------------------------------
-- Pit of Saron   -   dungeon 49
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 49, 'Dungeon Quest', 'Pit of Saron', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 49, 'Dungeon Quest Turn-in', 'Pit of Saron', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Pit of Saron
(@ENDER + 49, 14443), -- The Battered Hilt
(@ENDER + 49, 24461), -- Reforging The Sword
(@ENDER + 49, 24498), -- The Path to the Citadel
(@ENDER + 49, 24507), -- The Path to the Citadel
(@ENDER + 49, 24554), -- The Battered Hilt
(@ENDER + 49, 24559), -- Reforging The Sword
(@ENDER + 49, 24682), -- The Pit of Saron
(@ENDER + 49, 24683), -- The Pit of Saron
(@ENDER + 49, 24710), -- Deliverance from the Pit
(@ENDER + 49, 24712); -- Deliverance from the Pit

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 491, @GIVER + 49, 658, 0, 0, 3, 1, 0, 438.742, 212.333, 528.709, 3.115, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Pit of Saron'),
(@GUID + 492, @ENDER + 49, 658, 0, 0, 3, 1, 0, 1067.3254, 55.056316, 631.68146, 1.650641, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Pit of Saron, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 49, 36624), -- Caladis Brightspear
(@ENDER + 49, 36642); -- Myralion Sunblaze

-- -------------------------------------------------------------------------
-- Pit of Saron   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 49;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 49, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 49;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1090, @PORTAL + 49, 658, 0, 0, 1, 1, 1070.316, 55.296, 631.681, 1.651, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Pit of Saron');

-- -------------------------------------------------------------------------
-- Halls of Reflection   -   dungeon 50
-- -------------------------------------------------------------------------
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `type`, `flags_extra`, `RegenHealth`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIVER + 50, 'Dungeon Quest', 'Halls of Reflection', 'Speak', 80, 80, 35, 3, 1, 2, 7, 2, 1, '', 0),
(@ENDER + 50, 'Dungeon Quest Turn-in', 'Halls of Reflection', 'Speak', 80, 80, 35, 2, 1, 2, 7, 2, 1, '', 0);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
-- Halls of Reflection
(@ENDER + 50, 14443), -- The Battered Hilt
(@ENDER + 50, 24480), -- The Halls Of Reflection
(@ENDER + 50, 24500), -- Wrath of the Lich King
(@ENDER + 50, 24554), -- The Battered Hilt
(@ENDER + 50, 24561), -- The Halls Of Reflection
(@ENDER + 50, 24711), -- Frostmourne
(@ENDER + 50, 24713), -- Frostmourne
(@ENDER + 50, 24802); -- Wrath of the Lich King

INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(@GUID + 501, @GIVER + 50, 668, 0, 0, 3, 1, 0, 5241.099, 1934.793, 707.695, 3.942, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest giver - Halls of Reflection'),
(@GUID + 502, @ENDER + 50, 668, 0, 0, 3, 1, 0, 5380.018, 1815.291, 760.129, 3.956, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Dungeon Quest turn-in - Halls of Reflection, check position in-game');

INSERT INTO `tmp_dungeon_quest_theme` (`npc`, `theme`) VALUES
(@GIVER + 50, 37582), -- Archmage Koreln
(@ENDER + 50, 37779); -- Dark Ranger Loralen

-- -------------------------------------------------------------------------
-- Halls of Reflection   -   return portal
-- -------------------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry` = @PORTAL + 50;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`, `VerifiedBuild`) VALUES
(@PORTAL + 50, 10, @PORTAL_DISPLAY, 'Return Portal', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 0);

DELETE FROM `gameobject` WHERE `id` = @PORTAL + 50;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(@GUID + 1100, @PORTAL + 50, 668, 0, 0, 1, 1, 5377.836, 1817.350, 760.129, 3.956, 0, 0, 0, 1, 120, 100, 1, '', 0, 'DungeonQuestNPC return portal - Halls of Reflection');

-- Blackrock Depths

-- Blackrock Depths

-- Looks: every NPC copies the model and weapons of an NPC from the dungeon's story
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@GIVER + 2, @ENDER + 2, @GIVER + 3, @ENDER + 3, @GIVER + 4, @ENDER + 4, @GIVER + 5, @ENDER + 5, @GIVER + 6, @ENDER + 6, @GIVER + 7, @ENDER + 7, @GIVER + 8, @ENDER + 8, @GIVER + 9, @ENDER + 9, @GIVER + 10, @ENDER + 10, @GIVER + 11, @ENDER + 11, @GIVER + 12, @ENDER + 12, @GIVER + 13, @ENDER + 13, @GIVER + 14, @ENDER + 14, @GIVER + 15, @ENDER + 15, @GIVER + 16, @ENDER + 16, @GIVER + 17, @ENDER + 17, @GIVER + 18, @ENDER + 18, @GIVER + 19, @ENDER + 19, @GIVER + 20, @ENDER + 20, @GIVER + 21, @ENDER + 21, @GIVER + 22, @ENDER + 22, @GIVER + 23, @ENDER + 23, @GIVER + 24, @ENDER + 24, @GIVER + 25, @ENDER + 25, @GIVER + 26, @ENDER + 26, @GIVER + 27, @ENDER + 27, @GIVER + 28, @ENDER + 28, @GIVER + 29, @ENDER + 29, @GIVER + 30, @ENDER + 30, @GIVER + 31, @ENDER + 31, @GIVER + 32, @ENDER + 32, @GIVER + 33, @ENDER + 33, @GIVER + 34, @ENDER + 34, @GIVER + 35, @ENDER + 35, @GIVER + 36, @ENDER + 36, @GIVER + 37, @ENDER + 37, @GIVER + 38, @ENDER + 38, @GIVER + 39, @ENDER + 39, @GIVER + 40, @ENDER + 40, @GIVER + 41, @ENDER + 41, @GIVER + 42, @ENDER + 42, @GIVER + 43, @ENDER + 43, @ENDER + 44, @GIVER + 45, @ENDER + 45, @GIVER + 46, @ENDER + 46, @GIVER + 48, @ENDER + 48, @GIVER + 49, @ENDER + 49, @GIVER + 50, @ENDER + 50);
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (@GIVER + 2, @ENDER + 2, @GIVER + 3, @ENDER + 3, @GIVER + 4, @ENDER + 4, @GIVER + 5, @ENDER + 5, @GIVER + 6, @ENDER + 6, @GIVER + 7, @ENDER + 7, @GIVER + 8, @ENDER + 8, @GIVER + 9, @ENDER + 9, @GIVER + 10, @ENDER + 10, @GIVER + 11, @ENDER + 11, @GIVER + 12, @ENDER + 12, @GIVER + 13, @ENDER + 13, @GIVER + 14, @ENDER + 14, @GIVER + 15, @ENDER + 15, @GIVER + 16, @ENDER + 16, @GIVER + 17, @ENDER + 17, @GIVER + 18, @ENDER + 18, @GIVER + 19, @ENDER + 19, @GIVER + 20, @ENDER + 20, @GIVER + 21, @ENDER + 21, @GIVER + 22, @ENDER + 22, @GIVER + 23, @ENDER + 23, @GIVER + 24, @ENDER + 24, @GIVER + 25, @ENDER + 25, @GIVER + 26, @ENDER + 26, @GIVER + 27, @ENDER + 27, @GIVER + 28, @ENDER + 28, @GIVER + 29, @ENDER + 29, @GIVER + 30, @ENDER + 30, @GIVER + 31, @ENDER + 31, @GIVER + 32, @ENDER + 32, @GIVER + 33, @ENDER + 33, @GIVER + 34, @ENDER + 34, @GIVER + 35, @ENDER + 35, @GIVER + 36, @ENDER + 36, @GIVER + 37, @ENDER + 37, @GIVER + 38, @ENDER + 38, @GIVER + 39, @ENDER + 39, @GIVER + 40, @ENDER + 40, @GIVER + 41, @ENDER + 41, @GIVER + 42, @ENDER + 42, @GIVER + 43, @ENDER + 43, @ENDER + 44, @GIVER + 45, @ENDER + 45, @GIVER + 46, @ENDER + 46, @GIVER + 48, @ENDER + 48, @GIVER + 49, @ENDER + 49, @GIVER + 50, @ENDER + 50);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT t.`npc`, m.`Idx`, m.`CreatureDisplayID`, m.`DisplayScale`, m.`Probability`, 0
FROM `tmp_dungeon_quest_theme` t JOIN `creature_template_model` m ON m.`CreatureID` = t.`theme`;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT t.`npc`, 0, @MODEL, 1, 1, 0 FROM `tmp_dungeon_quest_theme` t
WHERE NOT EXISTS (SELECT 1 FROM `creature_template_model` m WHERE m.`CreatureID` = t.`npc`);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`)
SELECT t.`npc`, 1, e.`ItemID1`, e.`ItemID2`, e.`ItemID3`, 0
FROM `tmp_dungeon_quest_theme` t JOIN `creature_equip_template` e ON e.`CreatureID` = t.`theme` AND e.`ID` = 1;
UPDATE `creature` SET `equipment_id` = 0 WHERE `guid` BETWEEN @GUID + 0 AND @GUID + 999 AND `id1` BETWEEN @GIVER AND @ENDER + 99;
UPDATE `creature` c JOIN `creature_equip_template` e ON e.`CreatureID` = c.`id1` AND e.`ID` = 1
SET c.`equipment_id` = 1 WHERE c.`guid` BETWEEN @GUID + 0 AND @GUID + 999 AND c.`id1` BETWEEN @GIVER AND @ENDER + 99;
DROP TEMPORARY TABLE IF EXISTS `tmp_dungeon_quest_theme`;
-- ---------------------------------------------------------------------------
--  gossip text  (id referenced by Config.NPC_TEXT_START)
-- ---------------------------------------------------------------------------
DELETE FROM `npc_text` WHERE `ID` = 92000;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `lang0`, `Probability0`)
VALUES (92000,
    'Every quest of this instance that I am allowed to hand out is listed below - which ones those are depends on how I am set up. Your level, class and race always count; everything else can be turned on or off, chains and attunements among them. Anything I will not give you is still listed, with the reason in brackets.',
    'Every quest of this instance that I am allowed to hand out is listed below - which ones those are depends on how I am set up. Your level, class and race always count; everything else can be turned on or off, chains and attunements among them. Anything I will not give you is still listed, with the reason in brackets.',
    0, 1);
