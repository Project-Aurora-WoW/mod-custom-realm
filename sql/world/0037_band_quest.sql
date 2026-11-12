-- ============================================================
-- 0037_band_quest.sql — Скриптовая квест-цепочка «Песнь Пустоты»
--
-- Ввод к живому выступлению труппы (35_BandPerformance.lua, НПС 70390–70394).
-- Скриптовая цепочка «Затишье → Настройка → Концерт» для ВСЕХ фракций.
--
-- Содержимое:
--   • НПС «Капельмейстер Пустоты» (70395) — в Оргриммаре (Орда) и Штормграде (Альянс);
--   • 3 предмета «Струны Пустоты» (70115–70117) — yainer для сбора/сдачи;
--   • награда на финале — Жетоны Эха (70005) + Жетон Песни (70118).
-- Логика этапов — в 36_BandQuest.lua (сбор/сдача через словарь, не quest_template).
-- Идемпотентно: DELETE+INSERT.
-- ============================================================

SET @MAESTRO = 70395;
SET @HORDE_ZONE = 1;   -- Оргриммар (Орда)
SET @ALLI_ZONE  = 0;   -- Штормград (Альянс)

-- --- НПС «Капельмейстер Пустоты» ---
DELETE FROM `creature_template` WHERE `entry` = @MAESTRO;
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmg_multiplier`, `baseattacktime`, `rangeattacktime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `minrangedmg`, `maxrangedmg`, `rangedattackpower`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(@MAESTRO, 0,0,0, 0,0, 1294,0,0,0, 'Капельмейстер Пустоты', 'Труппа «Песнь Пустоты»', 'Speak', 0, 80,80, 2, 84, 1, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = @MAESTRO;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(@MAESTRO, 0, 1294, 1, 1);

-- Спавны: Оргриммар (Орда) + Штормград (Альянс)
DELETE FROM `creature` WHERE `id1` = @MAESTRO;
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`) VALUES
(94010, @MAESTRO, 0,0, 1, 1637, 1637, 1, 1, 0, 0, 1575.9, -4412.4, 8.0, 5.5, 300, 0, 0, 0, 0, 0, 1, 0, 0, '', 12340),   -- Оргриммар
(94011, @MAESTRO, 0,0, 0, 1519, 1519, 1, 1, 0, 0, -8851.9, 605.4, 100.4, 5.5, 300, 0, 0, 0, 0, 0, 1, 0, 0, '', 12340);  -- Штормград

-- --- Таблица состояния цепочки (acore_characters) ---
CREATE TABLE IF NOT EXISTS `realm_band_quest` (
    `account_id` INT UNSIGNED NOT NULL,
    `stage`      TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0=нет,1=затишье,2=настройка,3=премьера
    `updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --- Предметы «Струны Пустоты» (yainer сбора) ---
DELETE FROM `item_template` WHERE `entry` IN (70115, 70116, 70117, 70118);
INSERT INTO `item_template` (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`, `SellPrice`, `InventoryType`, `ItemLevel`, `RequiredLevel`, `maxcount`, `stackable`, `description`, `VerifiedBuild`) VALUES
(70115, 12, 0, 'Струна Меланхолии', 34158, 2, 0, 1, 0, 0, 0, 1, 1, 0, 20, 'Струна, извлекающая тоску по дому.', 12340),
(70116, 12, 0, 'Струна Ярости', 34159, 2, 0, 1, 0, 0, 0, 1, 1, 0, 20, 'Струна, вплетённая в боевые песни.', 12340),
(70117, 12, 0, 'Струна Надежды', 34160, 3, 0, 1, 0, 0, 0, 1, 1, 0, 20, 'Струна, звучащая лишь в тишине после битвы.', 12340),
(70118, 12, 0, 'Жетон Песни Пустоты', 34161, 3, 0, 1, 0, 0, 0, 1, 1, 0, 1, 'Память о первом концерте труппы в Эхе Пустоты.', 12340);