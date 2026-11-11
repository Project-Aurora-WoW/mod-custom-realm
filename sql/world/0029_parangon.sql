-- ============================================================
-- 0029_parangon.sql — Parangon (система уровня «как в Diablo 3»)
--
-- Фаза 3 плана ROADMAP-Features.md (Lua-only, без пересборки ядра).
-- Адаптация lua-parangon (Open-Wow/Khalar, AGPL) на конвенции реалма.
--
-- Parangon: на каждый «псевдо-уровень» аккаунта (за опыт PvE/PvP)
-- выдаются очки Parangon, которые персонаж тратит на стаки штатных
-- аур 7464 (сила) / 7471 (ловкость) / 7477 (выносливость) / 7468
-- (интеллект). Данные — per-account (уровень/опыт) и per-character
-- (распределённые очки).
--
-- ВАЖНО: таблицы применяются в acore_characters (скрипты читают их
-- через CharDBQuery/CharDBExecute), как realm_pvp_stats (0009).
-- ============================================================

-- ---- Часть 1: уровень/опыт Parangon на аккаунт ----
-- account_parangon: id аккаунта, уровень Parangon, опыт текущего
-- уровня. Свободные очки вычисляются скриптом (очки = level*pointsPerLevel
-- минус уже потраченные) — это производное значение, здесь не хранится.
CREATE TABLE IF NOT EXISTS `account_parangon` (
  `accountid` INT UNSIGNED NOT NULL,
  `level`    INT UNSIGNED NOT NULL DEFAULT 1,
  `exp`      INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Parangon: уровень и опыт на аккаунт';

-- ---- Часть 2: распределённые очки Parangon на персонажа ----
CREATE TABLE IF NOT EXISTS `characters_parangon` (
  `accountid` INT UNSIGNED NOT NULL,
  `guid`      INT UNSIGNED NOT NULL,
  `strenght`  INT UNSIGNED NOT NULL DEFAULT 0,
  `agility`   INT UNSIGNED NOT NULL DEFAULT 0,
  `stamina`   INT UNSIGNED NOT NULL DEFAULT 0,
  `intellect` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`accountid`,`guid`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Parangon: потраченные очки по персонажу';

-- ---- Идемпотентность ----
-- create_if_not_exists достаточно; данные не сидируют, запись — через
-- INSERT ... ON DUPLICATE KEY UPDATE или reset (см. скрипт 29).