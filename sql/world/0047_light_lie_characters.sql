-- ============================================================
-- 0047_light_lie.sql -> characters (acore_characters)
-- Применять: mysql -u <user> -p acore_characters < sql/world/0047_light_lie_characters.sql
-- Таблица realm_lightlie_score — сезонный счёт модуля «Светлая Ложь Альянса».
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Таблица рейтинга (acore_characters) — сезонный счёт
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_lightlie_score` (
  `guid`            INT UNSIGNED NOT NULL,
  `season`          INT UNSIGNED NOT NULL COMMENT 'номер сезона (мум. месяц)',
  `pvp_score`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'зач. PvP-киллы',
  `pve_score`       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'зач. PvE-боссы',
  `total_score`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'pvp+pve (Свет Истины)',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `season`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Сезонный счёт модуля «Светлая Ложь Альянса» (acore_characters)';

-- Индекс для выборки топа сезона.
SET @has_idx := (SELECT COUNT(*) FROM information_schema.statistics
                 WHERE table_schema = DATABASE()
                   AND table_name = 'realm_lightlie_score'
                   AND index_name = 'idx_lightlie_season');
SET @sql_idx := IF(@has_idx = 0,
  'CREATE INDEX `idx_lightlie_season` ON `realm_lightlie_score` (`season`, `total_score`)',
  'SELECT 1');
PREPARE stmt_idx_ll FROM @sql_idx;
EXECUTE stmt_idx_ll;
DEALLOCATE PREPARE stmt_idx_ll;