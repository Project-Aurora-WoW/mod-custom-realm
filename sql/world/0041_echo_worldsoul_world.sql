-- =============================================
-- 0041_echo_worldsoul.sql -> world (acore_world)
-- mysql -u user -p acore_world < sql/world/0041_echo_worldsoul_world.sql
-- =============================================

-- ============================================================
-- НПС кампании (диапазон 70600+, свободный пул после 70560)
-- ============================================================
SET @GIRDLE_MASTER := 70601;
-- «Страж Мировой Души» (наставник, Даларан)
SET @GIRDLE_FORGE := 70602;
-- «Кузня Наследия» (растворение)
SET @GIRDLE_RACK  := 70603;
-- «Стойка Аттюнмента»

DELETE FROM `creature_template` WHERE `entry` IN (@GIRDLE_MASTER,@GIRDLE_FORGE,@GIRDLE_RACK);
-- INSERT по схеме Saxon свежего ядра (модели — отдельно в creature_template_model).
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIRDLE_MASTER, 0,0,0, 0,0, 'Страж Мировой Души', 'Кампания «Мировая Душа»', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 0, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, '', 12340),
(@GIRDLE_FORGE, 0,0,0, 0,0, 'Кузня Наследия', 'Растворение настроенных предметов', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 0, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, '', 12340),
(@GIRDLE_RACK,  0,0,0, 0,0, 'Стойка Аттюнмента', 'Пассивный аттюнмент предметов', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 0, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, '', 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@GIRDLE_MASTER,@GIRDLE_FORGE,@GIRDLE_RACK);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(@GIRDLE_MASTER, 0, 1006, 1, 1),
(@GIRDLE_FORGE,  0, 1006, 1, 1),
(@GIRDLE_RACK,   0, 1006, 1, 1);
