-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0065_rai_levels_endgame.sql  (acore_world)
--
-- Балансировка уровней RAI под игровой контур реалма «Эхо Пустоты».
--
-- Исходная realm_rai_zone_level (миграция 0063) содержала 46 валорийских
-- записей зон Восточных Королевств/Калимдора уровней 5–60, которые НЕ
-- используются игровым контуром реалма (реалм — эндгейм Northrend:
-- кампании требуют 80, meta.min_level=80, зоны 4080/4395/4181/5000).
-- RAI при таком раскладе спавнил бы искателей уровней 5–60 в неиспользуемых
-- зонах, а в реальных зонах (4080/5000) искателей не было бы вовсе.
--
-- Решение: привести realm_rai_zone_level к фактическим внешним зонам
-- реалма с уровнем искателей 80 (эндгейм). Валорийские зоны 5–60 удалить.
-- Сетка (карта 571 / кастомная 5000):
--   * 4080 Драконий Погост (area 4365) — главная PvP/эндгейм-зона, кампании;
--   * 4181 Зул'Драк — храм Культа, кампании;
--   * 5000 Остров Морза / Долина Предательства — кастомная PvE-зона (мобы 82–84).
--   (4395 Даларан — хаб, агрессивных RAI-искателей там НЕ ставим.)
--
-- Уровень 80 -> entry 100080 (формула 100000+level из raicreaturepicker).
-- Нужен шаблон + модель (у нас был только до 100060) и запись в
-- realm_rai_creature (иначе raiserver не вешает боевые ALE-события).
--
-- Идемпотентно: DELETE+INSERT.
-- ============================================================

-- --- Уровневая сетка зон RAI ---
DELETE FROM `realm_rai_zone_level`;

INSERT INTO `realm_rai_zone_level` (`zone`, `minlevel`, `maxlevel`) VALUES
  (4080, 80, 80),   -- Драконий Погост
  (4181, 80, 80),   -- Зул'Драк
  (5000, 80, 80);   -- Морза / Долина Предательства

-- --- Шаблон искателя 80 уровня (100080) ---
DELETE FROM `creature_template` WHERE `entry` = 100080;

INSERT INTO `creature_template`
  (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
   `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`,
   `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`,
   `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
   `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`,
   `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`,
   `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
   `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`,
   `RacialLeader`, `movementId`, `RegenHealth`, `flags_extra`, `ScriptName`,
   `VerifiedBuild`) VALUES
(100080, 0,0,0, 0,0, 'Странствующий искатель', 'Странник Пустоты', '', 0, 80,80, 0, 190, 0, 1, 1.14286, 0, 0, 1, 2000, 2000, 1, 0x08000000, 2048, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, '', 12340);

-- --- Модель искателя 80 (100080) ---
DELETE FROM `creature_template_model` WHERE `CreatureID` = 100080;

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(100080, 0, 3363, 1, 1);

-- --- Реестр искателей: добавить 100080 ---
DELETE FROM `realm_rai_creature` WHERE `creature_entry` = 100080;

INSERT INTO `realm_rai_creature` (`creature_entry`) VALUES (100080);