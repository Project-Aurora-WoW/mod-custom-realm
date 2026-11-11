-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0002_campaign_progress.sql
-- Назначение: хранение прогресса игроков в кампаниях.
-- Используется Lua-скриптами (ALE) и будущими модулями.
-- ============================================================

CREATE TABLE IF NOT EXISTS `realm_campaign_progress` (
  `guid`            INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `campaign_id`     TINYINT UNSIGNED NOT NULL COMMENT 'ID кампании (см. docs/campaigns/README.md)',
  `chapter`         TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Текущая глава кампании',
  `completed`       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 — кампания пройдена',
  `progress_data`   TEXT NULL COMMENT 'Свободное поле для состояния (JSON)',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `campaign_id`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Прогресс игроков в кампаниях кастомного реалма';

-- Индекс для выборки активных кампаний по игроку.
-- MySQL 8 не поддерживает CREATE INDEX IF NOT EXISTS — проверяем наличие.
SET @has_idx := (SELECT COUNT(*) FROM information_schema.statistics
                 WHERE table_schema = DATABASE()
                   AND table_name = 'realm_campaign_progress'
                   AND index_name = 'idx_campaign_progress_guid');
SET @sql_idx := IF(@has_idx = 0,
  'CREATE INDEX `idx_campaign_progress_guid` ON `realm_campaign_progress` (`guid`)',
  'SELECT 1');
PREPARE stmt_idx FROM @sql_idx;
EXECUTE stmt_idx;
DEALLOCATE PREPARE stmt_idx;