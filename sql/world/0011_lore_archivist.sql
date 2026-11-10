-- ============================================================
-- 0011_lore_archivist.sql
-- НПС «Хронист Ордена» (entry 70180) — лор-архив реалма.
-- Спавн в Даларане рядом с НПС кампаний. Скрипт: LoreArchive.lua.
-- СХЕМА: AzerothCore 3.3.5 (creature_template + creature_template_model;
-- creature.id1). Идемпотентна (DELETE+INSERT).
-- Зависимости: 0001.
-- ============================================================

SET NAMES utf8mb4;

-- --- 1. Шаблон НПС ------------------------------------------
-- Мирный НПС (npcflag 1 = gossip), не атакует и не атакуем.
DELETE FROM `creature_template` WHERE `entry` = 70180;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`,
 `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`,
 `unit_flags2`, `type`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`,
 `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`,
 `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(70180, 'Хронист Ордена', 'Хранитель архива Эха Пустоты', 'Talk', 0, 80, 80,
 35, 1, 1.0, 1.14286, 0, 2, 33554432,
 2048, 7, 0, 0, '', 0, 3,
 1.0, 71.0, 1.0, 1.0, 1.0,
 2, '', 12340);

-- --- 2. Модель ----------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` = 70180;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70180, 0, 24991, 1.00, 1.0);

-- --- 3. Спавн в Даларане (у штаба Ордена) -------------------
-- guid 7000180: диапазоны 7000100–7000164 заняты кампаниями 1–3 (0003/0005/0007).
DELETE FROM `creature` WHERE `id1` = 70180;
INSERT INTO `creature` (`guid`, `id1`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `curpower`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000180, 70180, 571, 4395, 4395, 1, 1, 0,
 5800.32, 640.85, 647.75, 4.60, 300, 0, 1000000, 0, 0, 0, 0, 0, 0, 12340);
