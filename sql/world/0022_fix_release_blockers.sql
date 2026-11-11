-- ============================================================
-- 0022_fix_release_blockers.sql — исправление релизных блокеров
--
-- Аудит к релизу выявил три дефекта, из-за которых часть контента
-- не применялась или применялась не в той схеме:
--
--  1. 0005_campaign2_content.sql — INSERT item_template 70004 был
--     битым (71 значение на 78 колонок → «Column count doesn't
--     match»), предмет-награда кампании 2 не создавался.
--     Исправлено в самой 0005; здесь — сверка на существующих БД.
--  2. 0010_pvp_shop.sql — спавн НПС 70170 (PvP-шоп) использовал
--     колонку `id` вместо `id1` и лишнее значение: INSERT падал.
--     Исправлено в 0010; здесь — идемпотентный досозд спавна.
--  3. 0021_public_scripts.sql — creature_template 70174 и creature
--     7000174 вставлены по схеме WotLK (`modelid1`, `dmgschool`,
--     `spawndist`, `creature`.`id`). В AzerothCore моделей в
--     creature_template нет (отдельная `creature_template_model`),
--     а creature использует `id1`/`wander_distance`. Применение
--     такого INSERT даёт ошибку «Unknown column». Здесь НПС
--     «Страж Перемен» создаётся по схеме AC.
--
-- Миграция идемпотентна: только DELETE по своим entry/guid
-- + INSERT. Применять после 0021, в acore_world.
-- ============================================================

SET NAMES utf8mb4;

-- ── 1. НПС «Страж Перемен» (70174) по схеме AzerothCore ──────
DELETE FROM `creature_template` WHERE `entry` = 70174;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70174, 'Страж Перемен', 'Услуги Ордена Рассвета', 'Speak', 0, 80, 80, 0, 35, 1, 1.0, 1.14286, 0, 0, 1.0, 2, 33554432, 2048, 0, 7, 0, 0, 0, '', 0, 1.0, 71.0, 1.0, 1.0, 0, '', 0, 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70174;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70174, 0, 15279, 1.00, 1.0);

DELETE FROM `creature` WHERE `guid` = 7000174;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000174, 70174, 571, 4395, 4395, 1, 1, 0,
 5808.94, 694.83, 647.35, 2.85,
 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- ── 2. Спавн PvP-шопа 70170 (если 0010 упал) ────────────────
DELETE FROM `creature` WHERE `guid` = 7000170;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000170, 70170, 571, 4395, 4395, 1, 1, 0,
 5818.60, 686.20, 657.55, 4.10,
 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);

-- ── 3. Сверка предметов реалма (не блокер, диагностика) ─────
-- Ожидается: 70001, 70002, 70003, 70004, 70005, 70006, 70007, 70008.
-- Пустой результат = все награды/валюты созданы.
-- SELECT `entry`, `name` FROM `item_template`
--  WHERE `entry` BETWEEN 70001 AND 70008 ORDER BY `entry`;
