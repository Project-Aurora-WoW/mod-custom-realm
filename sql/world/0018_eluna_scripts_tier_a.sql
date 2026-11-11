-- ============================================================
-- Azeroth: Эхо Пустоты — миграция 0018
-- 0018_eluna_scripts_tier_a.sql
-- Назначение: контент для систем Tier A, адаптированных из
-- референса eluna-scripts (sourcecraft.dev/m-orlovrus59/eluna-scripts,
-- автор Cloticc; лицензия и кредиты — в lua_scripts/README.md):
--   1. Таблица `realm_gold_storage` (acore_characters!):
--      НПС-банкир золота «Хранитель Золота» (16_GoldStorage.lua).
--   2. NPC 70172 «Рунный Обжиг» — зачарователь за золото
--      (15_Enchanter.lua; 70180 занят Хронистом Ордена, 0011).
--   3. NPC 70173 «Хранитель Золота» — банкир золота
--      (16_GoldStorage.lua).
--   4. NPC 70190 «Разлом Пустоты» (портал, временный спавн) и
--      NPC 70191 «Иссушенный из Разлома» — ивент «Разломы
--      Пустоты» (17_TimeRift.lua; спавнятся скриптом, в БД —
--      только шаблоны).
--   5. Спелл 70050 «Пустотная порча» (spell_dbc, acore_world):
--      визуальная основа системы Corruption (18_VoidCorruption.lua).
--      ⚠️ Кастомный спелл требует строк в клиентском DBC при
--      полном отображении (см. docs/client-patch.md ч. 4c; эталон
--      миграции — 0016_dbc_reference_sample.sql). До DBC-патча
--      спелл работает серверно (стаки видны через иконку-заглушку
--      или логику ядра — проверить на тестовом реалме).
--   6. Предмет 70008 «Осколок Пустоты» — источник порчи
--      (18_VoidCorruption.lua; entry свободен: 70001–70007 заняты
--      кампаниями, 70100/70101 — Waloria-награды).
-- ============================================================
-- ПРИМЕНЕНИЕ:
--   mysql -u <user> -p acore_world < sql/world/0018_eluna_scripts_tier_a.sql
--   mysql -u <user> -p acore_characters < sql/world/0018_eluna_scripts_tier_a.sql
-- ============================================================

SET NAMES utf8mb4;

-- ============================================================
-- ЧАСТЬ 1 (acore_world): NPC-шаблоны
-- ============================================================
-- ------------------------------------------------------------
-- 1.1. NPC 70172 «Рунный Обжиг» — зачарователь за золото.
-- Мирный НПС (npcflag 1 = gossip), модель зачарователя.
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70172;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70172, 'Рунный Обжиг', 'Зачарователь Ордена Рассвета', 'Talk', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 2, '', 0, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70172;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70172, 0, 24991, 1.00, 1.0);

-- Спавн: Даларан, у штаба Ордена (рядом с Хронистом 70180 и Интендантом 70170)
-- guid 7000172 — свободен (0010: 7000170; 0011: 7000180)
DELETE FROM `creature` WHERE `id` = 70172;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000172, 70172, 571, 4395, 4395, 1, 1, 0,
 5796.50, 647.10, 647.75, 4.75, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- ------------------------------------------------------------
-- 1.2. NPC 70173 «Хранитель Золота» — банкир золота.
-- Мирный НПС (npcflag 1 = gossip), модель дворфа-банкира.
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70173;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70173, 'Хранитель Золота', 'Казначей Ордена Рассвета', 'Banker', 0, 80, 80,
 35, 1, 1.0, 1.14286, 0, 2, 33554432,
 2048, 7, 0, 0, '', 0, 3,
 1.0, 71.0, 1.0, 1.0, 1.0,
 2, '', 0, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70173;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70173, 0, 24991, 1.00, 1.0);

-- Спавн: Даларан, у штаба Ордена
-- guid 7000173 — свободен
DELETE FROM `creature` WHERE `id` = 70173;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000173, 70173, 571, 4395, 4395, 1, 1, 0,
 5798.90, 650.40, 647.75, 4.75, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- ------------------------------------------------------------
-- 1.3. NPC 70190 «Разлом Пустоты» — портал ивента «Разломы
-- Пустоты» (временный спавн через PerformIngameSpawn из
-- 17_TimeRift.lua, в БД — только шаблон;creature-спавна НЕТ).
-- faction 14 = hostile to all; unit_flags 32768 = passive при
-- спавне — мобы выходят, портал не атакуют.
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70190;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70190, 'Разлом Пустоты', '', '', 0, 80, 80,
 35, 0, 1.0, 1.14286, 0, 2, 33554432,
 2048, 10, 0, 0, '', 0, 3,
 1.0, 1.0, 1.0, 1.0, 1.0,
 2, '', 0, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70190;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70190, 0, 26501, 1.20, 1.0);

-- ------------------------------------------------------------
-- 1.4. NPC 70191 «Иссушенный из Разлома» — моб волн ивента
-- «Разломы Пустоты» (спавн: PerformIngameSpawn из 17_TimeRift.lua;
-- в БД — только шаблон, creature-спавна НЕТ).
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70191;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70191, 'Иссушенный из Разлома', 'Порождение Пустоты', '', 0, 80, 80,
 14, 0, 1.0, 1.14286, 0, 2, 64,
 2048, 10, 0, 0, '', 1, 3,
 1.0, 1.0, 1.0, 1.0, 1.0,
 0, '', 0, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70191;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70191, 0, 25272, 1.00, 1.0);

-- ------------------------------------------------------------
-- 1.5. Предмет 70008 «Осколок Пустоты» — источник порчи
-- (18_VoidCorruption.lua). Не продаётся, падает с мобов разлома
-- (лоутабл добавляется позже отдельной миграцией).
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` = 70008;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
 `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
 `ItemLevel`, `RequiredLevel`, `Material`, `bonding`, `description`, `Stackable`, `maxcount`)
VALUES
(70008, 12, -1, 'Осколок Пустоты', 6289, 2, 0,
 0, 0, 0, -1, -1,
 80, 70, -1, 0,
 'Тяжёлый осколок с побережья разлома. Чем больше их при тебе, тем громче шёпот Пустоты в твоей голове...', 20, 0);

-- ============================================================
-- ЧАСТЬ 2 (acore_world): кастомный спелл «Пустотная порча»
-- Эталон схемы spell_dbc: 0016_dbc_reference_sample.sql /
-- azerothcore-wotlk-classless (data/sql/base/db_world/spell_dbc.sql).
-- Стакающийся дебафф-маркер (StackAmount до 100) — визуальная
-- основа системы Corruption; эффекты порогов (20/40/60/80/100
-- стаков) накладываются Lua-скриптом отдельными стоковыми
-- дебаффами, сам спелл 70050 — только счётчик/иконка.
-- ⚠️ Требует клиентского DBC-патча для полного отображения
-- (docs/client-patch.md ч. 4c). До патча — серверная работа.
-- ============================================================
DELETE FROM `spell_dbc` WHERE `Id` = 70050;
INSERT INTO `spell_dbc`
(`Id`, `SpellNameLang`, `DispelType`, `Mechanic`, `Attributes`,
 `Stances`, `CastingTimeIndex`, `DurationIndex`, `RangeIndex`,
 `StackAmount`, `EquippedItemClass`, `AuraDescriptionLang`,
 `Effect_1`, `EffectDieSides_1`, `EffectBasePoints_1`, `EffectApplyAuraName_1`)
VALUES
(70050, 'Пустотная порча', 0, 0, 0,
 0, 1, 21, 1,
 100, -1, 'Пустота просачивается в тебя сквозь осколки...',
 6, 1, 0, 0);

-- ============================================================
-- ЧАСТЬ 3 (acore_characters): таблица казны золота
-- ============================================================
CREATE TABLE IF NOT EXISTS `realm_gold_storage` (
  `account` INT UNSIGNED NOT NULL,
  `name`    VARCHAR(255) NOT NULL,
  `gold`    BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Казна золота НПС-банкира (16_GoldStorage.lua, 0018)';
