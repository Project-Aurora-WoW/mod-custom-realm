-- =============================================
-- 0047_light_lie.sql -> world (acore_world)
-- mysql -u user -p acore_world < sql/world/0047_light_lie_world.sql
-- =============================================

-- ============================================================
-- 0047_light_lie.sql
-- Модуль «Светлая Ложь Альянса» (ежемесячный турнир PvP+PvE + кампания 10):
--   Items: 70016 «Свет Истины» (валюта сезона),
--          70017 «Печать Светлой Истины» (награда за 1-е место)
--   НПС:   70542 «Плащаница Светлой Лжи» (финальный босс кампании 10),
--          quest-giver кампании 10 — 70280 «Праведник Мораин» (старт),
--          интерактив/миньоны — 70281 «Тень Светлой Лжи»,
--          70282 «Часовня Лжи», 70283 «Страж-отступник»
--   Таблица: realm_lightlie_score (acore_characters) — счёт сезона.
-- СХЕМА: AzerothCore 3.3.5 (HealthModifier; creature_template_model;
-- creature.id1). Идемпотентна (DELETE+INSERT). Lua — 43_LightLie.lua,
-- 47_Campaign10.lua; реестр — 00_CampaignRegistry.ext (lightlie, campaigns[10]).
-- ============================================================

SET NAMES utf8mb4;
-- ------------------------------------------------------------
-- 2. Предметы
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` IN (70016, 70017);
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
(70016, 12, 0, -1, 'Свет Истины', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Валюта сезонного модуля «Светлая Ложь Альянса». Добывается за зачётные PvP-киллы в зоне и убийства лже-святых боссов.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70017, 12, 0, -1, 'Печать Светлой Истины', 65170,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак триумфа сезонного модуля «Светлая Ложь Альянса». Имя обладателя — в летописи Истины.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340);
-- ------------------------------------------------------------
-- 3. НПС кампании 10 «Светлая Ложь Альянса»
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` IN (70280, 70281, 70282, 70283, 70542);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Праведник Мораин: мирный quest-giver, старт кампании 10
(70280, 'Праведник Мораин', 'Голос Светлой Истины', 'Talk', 0, 80, 80, 0, 29, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 250.0, 1.0, 1.0, 2, '', 12340),
-- Тень Светлой Лжи: kill-кредит главы 1
(70281, 'Тень Светлой Лжи', 'Ложь, ставшая плотью', '', 0, 80, 80, 0, 16, 0, 1.0, 1.14286, 1, 0, 1.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 40.0, 1.0, 1.0, 0, '', 12340),
-- Часовня Лжи: interact-объект главы 2
(70282, 'Часовня Лжи', 'Осквернённая реликвия', '', 0, 80, 80, 0, 29, 1, 1.0, 1.14286, 1, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 100.0, 1.0, 1.0, 2, '', 12340),
-- Страж-отступник: kill-кредит главы 3 (elite)
(70283, 'Страж-отступник', 'Защитник Церкви Лжи', '', 0, 82, 82, 0, 16, 0, 1.0, 1.14286, 2, 0, 3.0, 1, 32768, 0, 0, 4, 0, 0, 0, '', 0, 1.0, 120.0, 1.0, 1.0, 0, '', 12340),
-- Плащаница Светлой Лжи: финальный рейд-босс кампании 10 (rank 3)
(70542, 'Плащаница Светлой Лжи', 'Верховный Лжесвятой', '', 0, 84, 84, 0, 14, 0, 1.0, 1.14286, 3, 0, 22.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 480.0, 1.0, 1.0, 0, '', 0, 12340);
-- ------------------------------------------------------------
-- 4. Модели
-- ------------------------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70280, 70281, 70282, 70283, 70542);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70280, 0, 20023, 1.00, 1.0),   -- Праведник Мораин (человек-клирик)
(70281, 0, 16141, 1.00, 1.0),   -- Тень Светлой Лжи (элементал тьмы)
(70282, 0, 1958,  1.00, 1.0),   -- Часовня Лжи (алтарь/саркофаг)
(70283, 0, 16139, 1.20, 1.0),   -- Страж-отступник (андед-страж)
(70542, 0, 19282, 2.20, 1.0);
-- Плащаница Светлой Лжи (демоническая форма)

-- ------------------------------------------------------------
-- 5. Спавны: quest-giver и интерактивы — Даларан (guid 7000900+);
--    босс — юг Драконьего Погоста (7000910).
-- ------------------------------------------------------------
DELETE FROM `creature` WHERE `id1` IN (70280, 70281, 70282, 70283, 70542);
INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000900, 70280, 571, 4395, 4395, 1, 1, 0, 5824.00, 615.00, 647.80, 2.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340),
(7000901, 70281, 571, 4080, 4365, 1, 1, 0, 3890.00, 7040.00, 151.40, 0.30, 300, 0, 160000, 0, 0, 0, 0, 0, 12340),
(7000902, 70282, 571, 4080, 4365, 1, 1, 0, 3905.00, 7055.00, 152.00, 0.00, 300, 0, 400000, 0, 0, 0, 0, 0, 12340),
(7000903, 70283, 571, 4080, 4365, 1, 1, 0, 3895.00, 7045.00, 151.60, 0.00, 300, 0, 480000, 0, 0, 0, 0, 0, 12340),
(7000910, 70542, 571, 4080, 4365, 1, 1, 0, 3902.00, 7060.00, 153.00, 0.30, 300, 0, 4800000, 0, 0, 1, 0, 0, 0, 0, 12340);
