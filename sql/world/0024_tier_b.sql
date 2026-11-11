-- ============================================================
-- 0024_tier_b.sql — Tier B из eluna-scripts (Cloticc/Isidorsson)
--
-- Референс: eluna-scripts (Quality of life stuff, Npc, lotteryDB).
-- Адаптация под реалм «Эхо Пустоты» (AzerothCore, схема AC):
--   • 70175 «Рунный Оружейник»      — Weapon Master (мастер оружия
--        за золото; учит оружие под класс)
--   • 70176 «Хранитель Тиражей»     — Lottery (лотерея за золото,
--        таблицы realm_lottery{,_tickets} в acore_characters)
--   • 70177 «Скип DK Стартера»      — Skip DK Starter (пропуск
--        стартовой цепочки Рыцаря Смерти)
--   • Алтари молитвы — GO/НПС-алтарь 70178 «Алтарь Ордена» (в Даларане)
--
-- Все НПС — по схеме AzerothCore (creature_template + отдельная
-- creature_template_model; creature с id1/wander_distance), как 0022.
-- Часть 1 (ценные таблицы) применяется в acore_characters,
-- Часть 2 (НПС/объекты) — в acore_world.
--
-- ОСНОВНАЯ СХЕМА: acore_characters
--
-- ДВОЙНОЕ ПРИМЕНЕНИЕ: идемпотентно (DELETE по entry/guid + INSERT),
-- таблицы — CREATE TABLE IF NOT EXISTS + DELETE данных по демо-ключу.
-- ============================================================

SET NAMES utf8mb4;

-- ================== ЧАСТЬ 1: acore_characters ==================
-- Лотерея: розыгрыш по неделям (week_number = максимум)
CREATE TABLE IF NOT EXISTS `realm_lottery` (
  `week_number` int unsigned NOT NULL,
  `number1` int unsigned NOT NULL DEFAULT 0,
  `number2` int unsigned NOT NULL DEFAULT 0,
  `number3` int unsigned NOT NULL DEFAULT 0,
  `number4` int unsigned NOT NULL DEFAULT 0,
  `number5` int unsigned NOT NULL DEFAULT 0,
  `number6` int unsigned NOT NULL DEFAULT 0,
  `amount` bigint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`week_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Билеты лотереи (одна строка = один билет)
CREATE TABLE IF NOT EXISTS `realm_lottery_tickets` (
  `ticket_id` int unsigned NOT NULL AUTO_INCREMENT,
  `week_number` int unsigned NOT NULL,
  `player_guid` int unsigned NOT NULL,
  `player_account_id` int unsigned NOT NULL,
  `number1` int unsigned NOT NULL,
  `number2` int unsigned NOT NULL,
  `number3` int unsigned NOT NULL,
  `number4` int unsigned NOT NULL,
  `number5` int unsigned NOT NULL,
  `number6` int unsigned NOT NULL,
  PRIMARY KEY (`ticket_id`),
  KEY `idx_week` (`week_number`),
  KEY `idx_player` (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ================== ЧАСТЬ 2: acore_world ==================
-- --- 70175 «Рунный Оружейник» (Weapon Master) ---
DELETE FROM `creature_template` WHERE `entry` = 70175;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70175, 'Рунный Оружейник', 'Услуги Ордена Рассвета', 'Speak', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 0, '', 0, 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 70175;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (70175, 0, 15279, 1.00, 1.0);
DELETE FROM `creature` WHERE `guid` = 7000175;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`) VALUES
(7000175, 70175, 571, 4395, 4395, 1, 1, 0, 5799.0, 690.0, 647.35, 2.85, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- --- 70176 «Хранитель Тиражей» (Lottery) ---
DELETE FROM `creature_template` WHERE `entry` = 70176;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70176, 'Хранитель Тиражей', 'Лотерея Эха', 'Speak', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 0, '', 0, 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 70176;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (70176, 0, 15279, 1.00, 1.0);
DELETE FROM `creature` WHERE `guid` = 7000176;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`) VALUES
(7000176, 70176, 571, 4395, 4395, 1, 1, 0, 5796.5, 693.0, 647.35, 3.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- --- 70177 «Скип DK Стартера» — НПС-инициатор у стартовой зоны ---
DELETE FROM `creature_template` WHERE `entry` = 70177;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70177, 'Вестник Забвения', 'Пропуск старта Рыцаря Смерти', 'Speak', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 0, '', 0, 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 70177;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (70177, 0, 15279, 1.00, 1.0);
DELETE FROM `creature` WHERE `guid` = 7000177;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`) VALUES
(7000177, 70177, 0, 1519, 1519, 1, 1, 0, -9013.75, 863.08, 104.0, 5.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- --- 70178 «Алтарь Ордена» — алтарь молитвы (Prayer)
-- displayid: алтарь-камень (флейвор); тип 10 (не-атакующее ГО-НПС)
DELETE FROM `creature_template` WHERE `entry` = 70178;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70178, 'Алтарь Ордена', 'Молитва', 'Speak', 0, 80, 80, 0, 35, 0, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 10, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 0, '', 0, 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 70178;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES (70178, 0, 15279, 1.00, 1.0);
DELETE FROM `creature` WHERE `guid` = 7000178;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`) VALUES
(7000178, 70178, 571, 4395, 4395, 1, 1, 0, 5805.0, 688.5, 647.35, 1.20, 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);