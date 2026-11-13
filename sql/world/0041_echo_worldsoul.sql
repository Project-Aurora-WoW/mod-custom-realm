-- ============================================================
-- 0041_echo_worldsoul.sql — Параллельная кампания «Мировая Душа»
--
-- Отдельная параллельная арка поверх основных 4 кампаний Эха.
-- Не требует токенов прошлых арок; играется независимо.
-- Контрапункт Пустоте: «земные глубины» помнят мир до раскола.
--
-- Механики (по решению владельца, полный набор):
--   1. Attunement  — пер-предметный прогресс по GUID предмета
--                    (накапливается C++-модулем mod-echo-attune).
--   2. Essence     — валюта кампании за бой/боссов/квесты/PvP.
--   3. Mastery     — ранг от потраченного Essence, усиливает attunement.
--   4. Crucible    — категории постоянных инвестиций Essence.
--   5. World Threat — накопитель риска/награды (персонаж).
--   6. Legacy Forge + Attunement Rack — растворение в Essence и пассивный
--      аттюнмент до 20 предметов в стойке.
--
-- ВАЖНО: таблицы применяются в acore_characters (скрипты читают их
-- через CharDBQuery/CharDBExecute), как realm_pvp_stats (0009) и
-- account_parangon (0029). НПС — в свободном диапазоне 70xxx (70600+).
--
-- Идемпотентно: CREATE TABLE IF NOT EXISTS; НПС — DELETE + INSERT.
-- ============================================================

-- ---- Часть 1: Essence + Mastery на аккаунт ----
-- realm_echo_essence: валюта кампании и ранги мастерства.
CREATE TABLE IF NOT EXISTS `realm_echo_essence` (
  `accountid` INT UNSIGNED NOT NULL,
  `essence`   INT UNSIGNED NOT NULL DEFAULT 0,
  `spent`     INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Worldsoul: Essence currency and Mastery spent';

-- ---- Часть 2: Crucible — инвестиции Essence на аккаунт ----
-- Категории (lifesteal/xp_rate/...): категория -> вложено очков.
CREATE TABLE IF NOT EXISTS `realm_echo_crucible` (
  `accountid`  INT UNSIGNED NOT NULL,
  `category`   VARCHAR(32)  NOT NULL,
  `invested`   INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Worldsoul: Crucible invested points per category';

-- ---- Часть 3: World Threat — риск/награда на персонажа ----
CREATE TABLE IF NOT EXISTS `realm_echo_threat` (
  `guid`       INT UNSIGNED NOT NULL,
  `threat`     INT UNSIGNED NOT NULL DEFAULT 0,
  `max_seen`   INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Worldsoul: World Threat per character';

-- ---- Часть 4: Attunement Rack — пассивный аттюнмент ----
-- До 20 слотов; хранится item_guid предмета, помещённого в стойку.
CREATE TABLE IF NOT EXISTS `realm_echo_rack` (
  `accountid`  INT UNSIGNED NOT NULL,
  `slot`       TINYINT UNSIGNED NOT NULL,
  `item_guid`  INT UNSIGNED NOT NULL DEFAULT 0,
  `item_entry` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`,`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Worldsoul: Attunement Rack (up to 20 slots)';

-- ---- Часть 5: Attunement — пер-предметный прогресс ----
-- Пишется C++-модулем mod-echo-attune (хук смены экипировки + бой).
-- Ключ — item guid (глобальный идентификатор предмета).
CREATE TABLE IF NOT EXISTS `realm_echo_attune` (
  `accountid`  INT UNSIGNED NOT NULL,
  `item_guid`  INT UNSIGNED NOT NULL,
  `entry`      INT UNSIGNED NOT NULL,
  `progress`   INT UNSIGNED NOT NULL DEFAULT 0,
  `max_prog`   INT UNSIGNED NOT NULL DEFAULT 1000,
  `mastered`   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`,`item_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Worldsoul: per-item attunement progress';

-- ============================================================
-- НПС кампании (диапазон 70600+, свободный пул после 70560)
-- ============================================================
SET @GIRDLE_MASTER := 70601;  -- «Страж Мировой Души» (наставник, Даларан)
SET @GIRDLE_FORGE := 70602;   -- «Кузня Наследия» (растворение)
SET @GIRDLE_RACK  := 70603;   -- «Стойка Аттюнмента»

DELETE FROM `creature_template` WHERE `entry` IN (@GIRDLE_MASTER,@GIRDLE_FORGE,@GIRDLE_RACK);

INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `modelid1`, `modelid2`, `modelid3`, `modelid4`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `scale`, `rank`, `dmg_multiplier`, `baseattacktime`, `rangeattacktime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `trainer_type`, `trainer_spell`, `trainer_class`, `trainer_race`, `minrangedmg`, `maxrangedmg`, `rangedattackpower`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `mechanic_immune_mask`, `spell_school_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(@GIRDLE_MASTER, 0,0,0, 0,0, 1006,0,0,0, 'Страж Мировой Души', 'Кампания «Мировая Душа»', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@GIRDLE_FORGE, 0,0,0, 0,0, 1006,0,0,0, 'Кузня Наследия', 'Растворение настроенных предметов', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340),
(@GIRDLE_RACK,  0,0,0, 0,0, 1006,0,0,0, 'Стойка Аттюнмента', 'Пассивный аттюнмент предметов', '', 0, 80,80, 2, 84, 1, 1, 1.14286, 1, 0, 1, 2000, 2000, 1, 33555264, 2048, 0, 0, 0, 0, 0, 0, 1, 1, 100, 7, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 3, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, '', 12340);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (@GIRDLE_MASTER,@GIRDLE_FORGE,@GIRDLE_RACK);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(@GIRDLE_MASTER, 0, 1006, 1, 1),
(@GIRDLE_FORGE,  0, 1006, 1, 1),
(@GIRDLE_RACK,   0, 1006, 1, 1);