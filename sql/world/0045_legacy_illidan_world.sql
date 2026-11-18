-- =============================================
-- 0045_legacy_illidan.sql -> world (acore_world)
-- mysql -u user -p acore_world < sql/world/0045_legacy_illidan_world.sql
-- =============================================

-- ============================================================
-- 0045_legacy_illidan.sql
-- Модуль «Наследие Иллидана» (ежемесячный турнир PvP+PvE + кампания 8):
--   Items: 70012 «Осколок Наследия» (валюта сезона),
--          70013 «Печать Наследия Иллидана» (награда за 1-е место)
--   НПС:   70540 «Страж Иллидана» (финальный босс кампании 8),
--          quest-giver кампании 8 — 70240 «Изгнанник Кель'Тас» (старт)
--   Таблица: realm_legacy_score (acore_characters) — счёт сезона.
-- СХЕМА: AzerothCore 3.3.5 (HealthModifier; creature_template_model;
-- creature.id1). Идемпотентна (DELETE+INSERT). Lua — 44_LegacyIllidan.lua,
-- 45_Campaign8.lua; реестр — 00_CampaignRegistry.ext (legacy, campaigns[8]).
-- ============================================================

SET NAMES utf8mb4;
-- ------------------------------------------------------------
-- 2. Предметы
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` IN (70012, 70013);
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
(70012, 12, 0, -1, 'Осколок Наследия', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Валюта ежемесячного турнира «Наследие Иллидана». Добывается за зачётные PvP-киллы и убийства рейдовых боссов.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70013, 12, 0, -1, 'Печать Наследия Иллидана', 65170,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак триумфа ежемесячного турнира. Имя его обладателя — в летописи Наследия.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340);
-- ------------------------------------------------------------
-- 3. НПС кампании 8 «Наследие Иллидана»
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` IN (70240, 70540);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Изгнанник Кель'Тас: мирный quest-giver, старт кампании 8
(70240, 'Изгнанник Кель''Тас', 'Голос преданного Наследия', 'Talk', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 250.0, 1.0, 1.0, 2, '', 12340),
-- Страж Иллидана: финальный рейд-босс (rank 3)
(70540, 'Страж Иллидана', 'Наследие предателя', '', 0, 84, 84, 0, 14, 0, 1.0, 1.14286, 3, 0, 22.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 480.0, 1.0, 1.0, 0, '', 0, 12340);
-- ------------------------------------------------------------
-- 4. Модели
-- ------------------------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70240, 70540);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70240, 0, 20023, 1.00, 1.0),   -- Изгнанник Кель'Тас (эльф крови)
(70540, 0, 19282, 2.20, 1.0);
-- Страж Иллидана (демоническая форма)

-- ------------------------------------------------------------
-- 5. Спавны: quest-giver в Даларане (guid 7000700);
--    босс — юг Драконьего Погоста (7000710).
-- ------------------------------------------------------------
DELETE FROM `creature` WHERE `id` IN (70240, 70540);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000700, 70240, 571, 4395, 4395, 1, 1, 0, 5812.00, 625.00, 647.80, 2.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340),
(7000710, 70540, 571, 4080, 4365, 1, 1, 0, 3899.60, 7049.10, 151.40, 0.30, 300, 0, 4800000, 0, 0, 1, 0, 0, 0, 0, 12340);
