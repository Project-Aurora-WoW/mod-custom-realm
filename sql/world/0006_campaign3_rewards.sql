-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0006_campaign3_rewards.sql
-- Назначение: награды кампании 3 «Пробуждение»:
--   item 70002 — «Печать Хранителя Эха» (титул-токен)
--   item 70003 — «Бездна-Пегас» (маунт-токен)
-- ПРИМЕЧАНИЕ: кастомный титул и кастомная модель маунта
-- требуют DBC-патча клиента 3.3.5a; токены выдаются почтой
-- скриптом Campaign3.lua (в разработке).
-- ============================================================

DELETE FROM `item_template` WHERE `entry` IN (70002, 70003);
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
-- Печать Хранителя Эха: quest-предмет, даёт право на титул
(70002, 12, 0, -1, 'Печать Хранителя Эха', 38625,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 80, 0,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Знак тех, кто остановил Пробуждение. Право на титул «Хранитель Эха» (нужен DBC-патч клиента).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340),
-- Бездна-Пегас: маунт-токен (требует кастомный спелл призыва при DBC-патче)
(70003, 15, 0, -1, 'Бездна-Пегас', 6449,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 80, 0,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Теневой скакун, рождённый из разлома Пустоты. Требует кастомный спелл призыва (DBC-патч клиента).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340);