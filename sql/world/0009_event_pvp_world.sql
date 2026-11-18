-- =============================================
-- 0009_event_pvp.sql -> world (acore_world)
-- mysql -u user -p acore_world < sql/world/0009_event_pvp_world.sql
-- =============================================

-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0009_event_pvp.sql
-- Назначение: контент ивентов и PvP-системы:
--   item 70005 — «Жетон Эха» (валюта ивентов и PvP-зоны)
--   таблица realm_pvp_stats — PvP-статистика игроков
-- ВНИМАНИЕ: realm_pvp_stats применяется в acore_characters
-- (скрипты читают через CharDBQuery), см. docs/deployment.md.
-- ============================================================

-- --- 1. Предмет «Жетон Эха» (world-БД) -----------------------
DELETE FROM `item_template` WHERE `entry` = 70005;
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
 `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(70005, 12, 0, -1, 'Жетон Эха', 38625,
 3, 32768, 0, 1, 0, 0,
 0, -1, -1, 80, 0,
 0, 0, 0, 0,
 0, 0, 0,
 0, 20, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Валюта Ордена Рассвета. Добывается в ивентах реалма и в PvP-зоне Драконьего Погоста.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340);
