-- ============================================================
-- 0045_legacy_illidan.sql -> characters (acore_characters)
-- Применять: mysql -u <user> -p acore_characters < sql/world/0045_legacy_illidan_characters.sql
-- Таблица realm_legacy_score — сезонный счёт модуля «Наследие Иллидана».
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Таблица рейтинга (acore_characters) — сезонный счёт
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_legacy_score` (
  `guid`            INT UNSIGNED NOT NULL,
  `season`          INT UNSIGNED NOT NULL COMMENT 'номер сезона (мум. месяц)',
  `pvp_score`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'зач. PvP-киллы',
  `pve_score`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'зач. PvE-боссы',
  `total_score`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'pvp+pve (Осколки)',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `season`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Сезонный счёт модуля «Наследие Иллидана» (acore_characters)';

-- Индекс для выборки топа сезона.
SET @has_idx := (SELECT COUNT(*) FROM information_schema.statistics
                 WHERE table_schema = DATABASE()
                   AND table_name = 'realm_legacy_score'
                   AND index_name = 'idx_legacy_season');
SET @sql_idx := IF(@has_idx = 0,
  'CREATE INDEX `idx_legacy_season` ON `realm_legacy_score` (`season`, `total_score`)',
  'SELECT 1');
PREPARE stmt_idx FROM @sql_idx;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;