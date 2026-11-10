-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0004_campaign_reward_item.sql
-- Назначение: предмет «Слеза Рассвета» (item 70001) — награда
-- за кампанию 1 «Эхо Шёпота» и токен доступа к кампании 2
-- (см. docs/campaigns/README.md).
-- Выдаётся скриптом lua_scripts/Campaign1.lua.
-- Фикс: убран пробел в имени колонки `holy_res` (ломал INSERT).
-- ============================================================

SET NAMES utf8mb4;

DELETE FROM `item_template` WHERE `entry` = 70001;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `soundoverridesubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`, `stat_type1`, `stat_value1`,
 `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`,
 `ScalingStatDistribution`, `ScalingStatValue`, `armor`, `holy_res`, `fire_res`,
 `nature_res`, `frost_res`, `shadow_res`, `arcane_res`, `delay`, `ammo_type`,
 `RangedModRange`, `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`,
 `startquest`, `lockid`, `Material`, `sheath`, `RandomProperty`, `RandomSuffix`, `block`,
 `itemset`, `MaxDurability`, `area`, `Map`, `BagFamily`, `TotemCategory`,
 `socketColor_1`, `socketContent_1`, `socketColor_2`, `socketContent_2`,
 `socketColor_3`, `socketContent_3`, `socketBonus`, `GemProperties`,
 `RequiredDisenchantSkill`, `ArmorDamageModifier`, `duration`, `ItemLimitCategory`,
 `HolidayId`, `ScriptName`, `DisenchantID`, `FoodType`, `minMoneyLoot`, `maxMoneyLoot`,
 `flagsCustom`, `VerifiedBuild`)
VALUES
(70001, 12, 0, -1, 'Слеза Рассвета', 38625,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 80, 0,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 3, 5, 14,
 6, 10, 7, 9,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 1, 'Реликвия Ордена Рассвета. Токен доступа к кампании «Пепел Зул''Драка». Шёпот осколка умолкает рядом с ней.',
 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, '', 0, 0, 0, 0,
 0, 12340);
