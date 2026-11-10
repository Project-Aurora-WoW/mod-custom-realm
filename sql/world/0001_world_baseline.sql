-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0001_world_baseline.sql
-- Назначение: базовый контент мира — НПС «Портальный Страж»
-- и его спавны в столицах.
-- СХЕМА: AzerothCore 3.3.5 (creature_template без minhealth/
-- maxhealth — HP через HealthModifier; creature.id1 вместо id).
-- Кириллица: SET NAMES utf8mb4 обязателен.
-- ============================================================

SET NAMES utf8mb4;

-- --- 1. Шаблон НПС «Портальный Страж» (entry 70001) ---------
DELETE FROM `creature_template` WHERE `entry` = 70001;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`,
 `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`,
 `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`,
 `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`,
 `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70001, 'Портальный Страж', 'Смотритель Эха Пустоты', 'Talk', 0, 80, 80,
 35, 1, 1.0, 1.14286, 1, 2, 33554432,
 2048, 7, 0, 0, '', 0, 3,
 1.0, 71.0, 1.0, 1.0, 1.0,
 2, '', 12340);

-- --- 2. Спавны в столицах -----------------------------------
-- Координаты Standard 3.3.5a: Штормград (Альянс) и Оргриммар (Орда).
DELETE FROM `creature` WHERE `id1` = 70001;
INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `curpower`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
-- Штормград: площадь перед Кафедральным собором
(7000101, 70001, 0, 1519, 1519, 1, 1, 0,
 -8960.14, 1335.64, 96.10, 5.21,
 300, 0, 1000000, 0, 0, 0, 0, 0, 0, 12340),
-- Оргриммар: площадь перед входом в залы, рядом с банком
(7000102, 70001, 1, 1637, 1637, 1, 1, 0,
 1591.31, -4434.98, 39.42, 3.32,
 300, 0, 1000000, 0, 0, 0, 0, 0, 0, 12340);
