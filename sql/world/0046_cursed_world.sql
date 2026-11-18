-- =============================================
-- 0046_cursed_world.sql -> world (acore_world)
-- mysql -u user -p acore_world < sql/world/0046_cursed_world_world.sql
-- =============================================

-- ============================================================
-- 0046_cursed_world.sql
-- Модуль «Мир Проклятых» (ежемесячный турнир PvP+PvE + кампания 9):
--   Items: 70014 «Осколок Проклятия» (валюта сезона),
--          70015 «Печать Проклятого Склепа» (награда за 1-е место)
--   НПС:   70541 «Страж Проклятого Склепа» (финальный босс кампании 9),
--          quest-giver кампании 9 — 70270 «Эмиссар Проклятых» (старт),
--          интерактив/миньоны — 70271 «Проклятая Тень»,
--          70272 «Склеп Проклятия», 70273 «Тюремщик Проклятых»
--   Таблица: realm_cursed_score (acore_characters) — счёт сезона.
-- СХЕМА: AzerothCore 3.3.5 (HealthModifier; creature_template_model;
-- creature.id1). Идемпотентна (DELETE+INSERT). Lua — 42_CurseWorld.lua,
-- 46_Campaign9.lua; реестр — 00_CampaignRegistry.ext (cursed, campaigns[9]).
-- ============================================================

SET NAMES utf8mb4;
-- ------------------------------------------------------------
-- 2. Предметы
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` IN (70014, 70015);
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
(70014, 12, 0, -1, 'Осколок Проклятия', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Валюта сезонного модуля «Мир Проклятых». Добывается за зачётные PvP-киллы в проклятой зоне и убийства проклятых боссов.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70015, 12, 0, -1, 'Печать Проклятого Склепа', 65170,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак триумфа сезонного модуля «Мир Проклятых». Имя обладателя — в летописи Проклятого Склепа.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340);
-- ------------------------------------------------------------
-- 3. НПС кампании 9 «Экскурсия в Мир Проклятых»
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` IN (70270, 70271, 70272, 70273, 70541);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Эмиссар Проклятых: мирный quest-giver, старт кампании 9
(70270, 'Эмиссар Проклятых', 'Гид по Миру Проклятых', 'Talk', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 250.0, 1.0, 1.0, 2, '', 12340),
-- Проклятая Тень: kill-кредит главы 1
(70271, 'Проклятая Тень', 'Порождение Проклятия', '', 0, 80, 80, 0, 16, 0, 1.0, 1.14286, 1, 0, 1.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 40.0, 1.0, 1.0, 0, '', 12340),
-- Склеп Проклятия: interact-объект главы 2
(70272, 'Склеп Проклятия', 'Реликвия Проклятых', '', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 100.0, 1.0, 1.0, 2, '', 12340),
-- Тюремщик Проклятых: kill-кредит главы 3 (elite)
(70273, 'Тюремщик Проклятых', 'Страж Проклятых', '', 0, 82, 82, 0, 16, 0, 1.0, 1.14286, 2, 0, 3.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 120.0, 1.0, 1.0, 0, '', 12340),
-- Страж Проклятого Склепа: финальный рейд-босс кампании 9 (rank 3)
(70541, 'Страж Проклятого Склепа', 'Владыка Проклятья', '', 0, 84, 84, 0, 14, 0, 1.0, 1.14286, 3, 0, 22.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 480.0, 1.0, 1.0, 0, '', 0, 12340);
-- ------------------------------------------------------------
-- 4. Модели
-- ------------------------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70270, 70271, 70272, 70273, 70541);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70270, 0, 20023, 1.00, 1.0),   -- Эмиссар Проклятых (эльф крови)
(70271, 0, 16141, 1.00, 1.0),   -- Проклятая Тень (элементал тьмы)
(70272, 0, 1958,  1.00, 1.0),   -- Склеп Проклятия (саркофаг)
(70273, 0, 16139, 1.20, 1.0),   -- Тюремщик Проклятых (андед-страж)
(70541, 0, 19282, 2.20, 1.0);
-- Страж Проклятого Склепа (демоническая форма)

-- ------------------------------------------------------------
-- 5. Спавны: quest-giver и интерактивы — Даларан (guid 7000800+);
--    босс — юг Драконьего Погоста (7000810).
-- ------------------------------------------------------------
DELETE FROM `creature` WHERE `id` IN (70270, 70271, 70272, 70273, 70541);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000800, 70270, 571, 4395, 4395, 1, 1, 0, 5818.00, 620.00, 647.80, 2.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340),
(7000801, 70271, 571, 4080, 4365, 1, 1, 0, 3890.00, 7040.00, 151.40, 0.30, 300, 0, 160000, 0, 0, 0, 0, 0, 12340),
(7000802, 70272, 571, 4080, 4365, 1, 1, 0, 3905.00, 7055.00, 152.00, 0.00, 300, 0, 400000, 0, 0, 0, 0, 0, 12340),
(7000803, 70273, 571, 4080, 4365, 1, 1, 0, 3895.00, 7045.00, 151.60, 0.00, 300, 0, 480000, 0, 0, 0, 0, 0, 12340),
(7000810, 70541, 571, 4080, 4365, 1, 1, 0, 3902.00, 7060.00, 153.00, 0.30, 300, 0, 4800000, 0, 0, 1, 0, 0, 0, 0, 12340);
