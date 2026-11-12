-- ============================================================
-- 0036_band_npcs.sql — Живое выступление труппы (эпизод кампании)
--
-- Референс-идея: BlackWolfsDen/L70ETC_Band (код не используется —
-- своя реализация, свои НПС «Песнь Пустоты» в лоре Эха).
--
-- Труппа НПС-«музыкантов» (фракция Орды, Дюротар-площадка) —
-- живой момент кампании: НПС по таймеру кастуют световые/звуковые
-- спеллы и эмоуты (логика в 35_BandPerformance.lua).
-- НПС в нашем диапазоне 70xxx (свободный пул 70390–70394).
-- Идемпотентно: DELETE+INSERT по шаблону AC.
-- ============================================================

SET @BAND1 = 70390;  -- «Скальд Пустоты» (вокал)
SET @BAND2 = 70391;  -- «Барабанщик Рока» (ударные)
SET @BAND3 = 70392;  -- «Струнник Бездны» (лютня)
SET @BAND4 = 70393;  -- «Маэстро Эха» (дирижёр/бас)
SET @BAND5 = 70394;  -- «Хористка Пук» (подпевки/горн)

-- --- НПС-труппа (шаблоны) ---
DELETE FROM `creature_template` WHERE `entry` IN (@BAND1,@BAND2,@BAND3,@BAND4,@BAND5);

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmg_multiplier`, `baseattacktime`, `rangeattacktime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `minrangedmg`, `maxrangedmg`, `rangedattackpower`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(@BAND1, 0,0,0, 0,0, 1329,0,0,0, 'Скальд Пустоты', 'Труппа «Песнь Пустоты»', '', 0, 80,80, 2, 84, 0, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@BAND2, 0,0,0, 0,0, 1317,0,0,0, 'Барабанщик Рока', 'Труппа «Песнь Пустоты»', '', 0, 80,80, 2, 84, 0, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@BAND3, 0,0,0, 0,0, 1348,0,0,0, 'Струнник Бездны', 'Труппа «Песнь Пустоты»', '', 0, 80,80, 2, 84, 0, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@BAND4, 0,0,0, 0,0, 1351,0,0,0, 'Маэстро Эха', 'Труппа «Песнь Пустоты»', '', 0, 80,80, 2, 84, 0, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@BAND5, 0,0,0, 0,0, 1350,0,0,0, 'Хористка Пук', 'Труппа «Песнь Пустоты»', '', 0, 80,80, 2, 84, 0, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340);

-- --- модели НПС (необязательно, использовать стоковые для надёжности) ---
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@BAND1,@BAND2,@BAND3,@BAND4,@BAND5);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(@BAND1, 0, 1329, 1, 1), (@BAND2, 0, 1317, 1, 1), (@BAND3, 0, 1348, 1, 1), (@BAND4, 0, 1351, 1, 1), (@BAND5, 0, 1350, 1, 1);

-- --- спавны: площадка в Дюротаре (Оргриммар) ---
-- Координаты — сцена у Оргриммара (за основу gps из референса-идеи, адаптировано).
DELETE FROM `creature` WHERE `id1` IN (@BAND1,@BAND2,@BAND3,@BAND4,@BAND5);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(94001, @BAND1, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1274.895996, -4337.253418, 33.097614, 6.188954, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 12340),
(94002, @BAND2, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1276.0, -4338.5, 33.1, 6.0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 12340),
(94003, @BAND3, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1273.8, -4338.2, 33.1, 6.2, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 12340),
(94004, @BAND4, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1275.6, -4339.0, 33.1, 6.1, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 12340),
(94005, @BAND5, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1274.1, -4339.4, 33.1, 6.0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 12340);