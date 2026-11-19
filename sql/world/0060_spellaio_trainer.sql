-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0060_spellaio_trainer.sql  (acore_world)
--
-- НПС «Хранитель Спеллов» (70179) — точка повторного открытия окна выбора
-- кастомных спеллов (SpellAIO). Помимо автоокна при первом входе игрок может
-- вернуться и открыть выбор снова через этого НПС.
--
-- Entry 70179 свободен (заняты 70170–70178, 70180). Логика госсипа —
-- в lua_scripts/SpellAIO/server.lua через RegisterCreatureEvent(70179, 1, ...).
-- ============================================================

-- --- 1. Шаблон НПС ------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70179;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70179, 'Хранитель Спеллов', '<Смена кастомных спеллов>', 'Trainer', 0, 80, 80,
 35, 1000000, 3, 1, 1, 1.0, 1.14286,
 33554432, 2048, 7, 0, 0, 0,
 0, 0, 0, 0, 0, '',
 0, 0, 1.0, 1.0, 1.0,
 1.0, 1.0, 2, 0,
 0, 0, 0, 12340);

-- --- 2. Спавн (Даларан) -------------------------------------
DELETE FROM `creature` WHERE `id` = 70179;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000179, 70179, 571, 4395, 4395, 1, 1, 0,
 5812.00, 625.00, 647.80, 2.20,
 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);