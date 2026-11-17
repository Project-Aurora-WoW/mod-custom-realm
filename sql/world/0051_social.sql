-- ============================================================
-- 0051_social.sql
-- Система социальных отношений (п.5):
--   realm_social_links  — связи «спутник/партнёр» между игроками с
--                          уровнем связи (растёт за совместную игру).
--   realm_mentor        — пара «наставник/ученик» (уровневый патронаж).
-- Механика: опыт связи в 47_Social.lua за совместные действия (PvP,
-- боссы, кампании) когда спутники в группе и в пределах дистанции;
-- бонусы за присутствие; наставник даёт ускоренный прогресс ученику.
-- СХЕМА: AzerothCore 3.3.5 (guids = character.guid). Идемпотентна.
-- Lua — 47_Social.lua; реестр — 00_CampaignRegistry.ext (social).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Связи (спутники/партнёры)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_social_links` (
  `guid_a`   INT UNSIGNED NOT NULL COMMENT 'игрок A',
  `guid_b`   INT UNSIGNED NOT NULL COMMENT 'игрок B',
  `level`    INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'уровень связи',
  `xp`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'опыт связи',
  `total_xp` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'суммарный опыт связи',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid_a`, `guid_b`),
  KEY `idx_social_b` (`guid_b`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Социальные связи игроков (acore_characters)';

-- ------------------------------------------------------------
-- Наставник/ученик
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_mentor` (
  `mentor_guid` INT UNSIGNED NOT NULL COMMENT 'наставник (опытный игрок)',
  `student_guid` INT UNSIGNED NOT NULL COMMENT 'ученик',
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`student_guid`),
  KEY `idx_mentor_g` (`mentor_guid`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Пары наставник/ученик (acore_characters)';