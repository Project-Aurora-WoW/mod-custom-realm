-- ============================================================
-- 0028_item_enchant_random.sql — random-энчанты предметов
--
-- Фаза 2 плана ROADMAP-Features.md (Lua-хук, без пересборки ядра).
-- НЕ использует item_template.RandomProperty (нужен ядро-патч):
-- реализация — НПС «Рандомный Зачарователь» (70192) + Lua-скрипт
-- 28_RandomEnchant.lua, применяет СЛУЧАЙНЫЙ энчант из пула тира
-- к надетому предмету через item:SetEnchantment() (как 15_Enchanter).
--
-- Таблица тиров (имя по референсу azerothcore-content):
--   id            — ключ тира
--   tierName      — подпись (ru/en через < > не делаем: локализация в Lua)
--   default_enchant_id — рабочий энчант 3.3.5a для этого пула
--   min_itemlevel — мин. ilvl предмета для попадания в тир (0 = любой)
--   max_itemlevel — макс. ilvl (0 = без ограничения)
--   weight        — относительный вес при случайном выборе
--
-- ВАЖНО про идемпотентность: у таблицы нет AUTO_INCREMENT-ссылок в других
-- таблицах, поэтому используем DELETE + INSERT (как 0020/0024).
-- ============================================================

-- ---- 1. Таблица тиров ----
DROP TABLE IF EXISTS `item_enchantment_random_tiers`;
CREATE TABLE `item_enchantment_random_tiers` (
  `id`               INT UNSIGNED NOT NULL,
  `tierName`         VARCHAR(64)  NOT NULL DEFAULT '',
  `default_enchant_id` INT UNSIGNED NOT NULL DEFAULT 0,
  `min_itemlevel`    INT UNSIGNED NOT NULL DEFAULT 0,
  `max_itemlevel`    INT UNSIGNED NOT NULL DEFAULT 0,
  `weight`           INT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci;

DELETE FROM `item_enchantment_random_tiers`;
-- Тиры оружия (валидные энчанты из 15_Enchanter.lua, слот 15/16):
-- T1 < ilvl 213, T2 213–245, T3 > 245, T4 — «престиж» (редкие).
INSERT INTO `item_enchantment_random_tiers`
  (`id`, `tierName`, `default_enchant_id`, `min_itemlevel`, `max_itemlevel`, `weight`) VALUES
  (1, 'T1_Common',   2673, 0, 212, 10),  -- Мангуст
  (2, 'T1_Common',   1900, 0, 212, 10),  -- Крестоносец
  (3, 'T2_Rare',     3789, 213, 245, 8), -- Берсерк
  (4, 'T2_Rare',     3851, 213, 245, 8), -- Страж титанов
  (5, 'T2_Rare',     3788, 213, 245, 8), -- Точность
  (6, 'T3_Epic',     3790, 246, 0, 6),   -- Чёрная магия
  (7, 'T3_Epic',     3833, 246, 0, 6),   -- Превосходная мощь
  (8, 'T3_Epic',     3834, 246, 0, 6),   -- Могучая сила заклинаний
  (9, 'T4_Prestige', 3869, 0, 0, 4),     -- Гроза клинков
  (10, 'T4_Prestige',3870, 0, 0, 4);     -- Питьё крови

-- ---- 2. НПС «Рандомный Зачарователь» (70192, Даларан) ----
-- Схема ЭХА copy с 0018/0022 (Рабочая схема AC). Локализация в Lua.
DELETE FROM `creature_template` WHERE `entry` = 70192;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
 `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`,
 `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`,
 `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`,
 `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(70192, 'Рандомный Зачарователь', '<Случайные энчанты оружия>', 'Vendor', 0, 80, 80,
 0, 1000000, 1000000, 1.0, 1.14286, 0, 0, 1.0,
 2, 33554432, 2048, 0, 7, 0, 0,
 0, '', 0, 1.0, 1.0, 1.0,
 1.0, 2, '', 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 70192;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(70192, 0, 24991, 1.00, 1.0);

-- ---- 3. Спавн (Даларан, штаб Ордена у Хрониста/Интенданта) ----
DELETE FROM `creature` WHERE `id` = 70192;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000192, 70192, 571, 4395, 4395, 1, 1, 0,
 5815.5, 689.5, 657.55, 4.10,
 300, 0, 1000000, 0, 0, 0, 0, 0, 12340);