-- ============================================================
-- 0048_factions.sql
-- Фракционные механики (п.2): фракционные НПС для веток К3 и
-- фракционной кампании 11 «Узы фракций».
--   НПС:   70284 «Пустотный Страж» (цель ветки Альянса, гл.2 К3)
--          70285 «Проклятый Страж» (цель ветки Орды, гл.2 К3)
--          70286 «Герольд Альянса» (старт ветки А, К11)
--          70287 «Герольд Орды»    (старт ветки О, К11)
--   Боссы: 70543 «Паладин-Отступник» (босс ветки А, К11)
--          70544 «Владыка Волков-Пустотников» (босс ветки О, К11)
--   Предметы: 70018 «Знамёна Верности» (награда К11 за фракционную линию)
-- Таблица: (нет новой — прогресс в realm_campaign_progress).
-- СХЕМА: AzerothCore 3.3.5. Идемпотентна (DELETE+INSERT).
-- Lua: Campaign11.lua, Campaign3.lua; реестр — 00_CampaignRegistry.ext
-- (faction, campaigns[11]).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Предметы
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` IN (70018);
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `soundoverridesubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`, `ScalingStatDistribution`, `ScalingStatValue`, `armor`,
 `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
 `delay`, `ammo_type`, `RangedModRange`, `bonding`, `description`,
 `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
 `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`,
 `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`,
 `socketColor_2`, `socketContent_2`,
 `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(70018, 12, 0, -1, 'Знамёна Верности', 65170,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак верности своей фракции. Выдаётся за прохождение линии Альянса или Орды в кампании «Узы фракций».',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340);

-- ------------------------------------------------------------
-- 2. НПС
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` IN (70284, 70285, 70286, 70287, 70543, 70544);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Цели веток К3 (глава 2): elite-стражи
(70284, 'Пустотный Страж', 'Дозорный Альянса', '', 0, 82, 82, 0, 16, 0, 1.0, 1.14286, 2, 0, 3.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 120.0, 1.0, 1.0, 0, '', 12340),
(70285, 'Проклятый Страж', 'Дозорный Орды', '', 0, 82, 82, 0, 16, 0, 1.0, 1.14286, 2, 0, 3.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 120.0, 1.0, 1.0, 0, '', 12340),
-- Стартовые НПС кампании 11
(70286, 'Герольд Альянса', 'Кампания «Узы фракций»', 'Talk', 0, 80, 80, 0, 29, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 250.0, 1.0, 1.0, 2, '', 12340),
(70287, 'Герольд Орды', 'Кампания «Узы фракций»', 'Talk', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 250.0, 1.0, 1.0, 2, '', 12340),
-- Боссы кампании 11 (по одному на фракцию)
(70543, 'Паладин-Отступник', 'Линия Альянса', '', 0, 84, 84, 0, 14, 0, 1.0, 1.14286, 3, 0, 22.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 480.0, 1.0, 1.0, 0, '', 0, 12340),
(70544, 'Владыка Волков-Пустотников', 'Линия Орды', '', 0, 84, 84, 0, 14, 0, 1.0, 1.14286, 3, 0, 22.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 480.0, 1.0, 1.0, 0, '', 0, 12340);

-- ------------------------------------------------------------
-- 3. Модели
-- ------------------------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70284, 70285, 70286, 70287, 70543, 70544);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70284, 0, 16139, 1.20, 1.0),   -- Пустотный Страж (андед-дозор)
(70285, 0, 16140, 1.20, 1.0),   -- Проклятый Страж (волк-мутант)
(70286, 0, 20023, 1.00, 1.0),   -- Герольд Альянса (человек-рыцарь)
(70287, 0, 20021, 1.00, 1.0),   -- Герольд Орды (орк)
(70543, 0, 19282, 2.20, 1.0),   -- Паладин-Отступник (пал-оборотень)
(70544, 0, 19283, 2.20, 1.0);   -- Владыка Волков (вожак пустотных волков)

-- ------------------------------------------------------------
-- 4. Спавны (Даларан + юг Драконьего Погоста, guid 7001000+)
-- ------------------------------------------------------------
DELETE FROM `creature` WHERE `id1` IN (70284, 70285, 70286, 70287, 70543, 70544);
INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
-- Стартовые НПС в Даларане
(7001000, 70286, 571, 4395, 4395, 1, 1, 0, 5812.00, 615.00, 647.80, 2.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340),
(7001001, 70287, 571, 4395, 4395, 1, 1, 0, 5818.00, 620.00, 647.80, 3.00, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340),
-- Цели К3 и боссы К11 — юг Драконьего Погоста
(7001002, 70284, 571, 4080, 4365, 1, 1, 0, 3890.00, 7040.00, 151.40, 0.30, 300, 0, 480000, 0, 0, 0, 0, 0, 12340),
(7001003, 70285, 571, 4080, 4365, 1, 1, 0, 3890.00, 7040.00, 151.40, 0.30, 300, 0, 480000, 0, 0, 0, 0, 0, 12340),
(7001004, 70543, 571, 4080, 4365, 1, 1, 0, 3902.00, 7060.00, 153.00, 0.30, 300, 0, 4800000, 0, 0, 1, 0, 0, 0, 0, 12340),
(7001005, 70544, 571, 4080, 4365, 1, 1, 0, 3896.00, 7052.00, 152.50, 0.30, 300, 0, 4800000, 0, 0, 1, 0, 0, 0, 0, 12340);