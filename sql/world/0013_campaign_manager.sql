-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0013_campaign_manager.sql
-- Назначение: журнал действий кампаний realm_campaign_log —
-- серверный аналог команд (гейт/прогресс/награды/GM).
-- ПРИМЕНЯТЬ В acore_characters (скрипты пишут через CharDBQuery).
-- Используется: lua_scripts/CampaignManager.lua.
-- ============================================================

CREATE TABLE IF NOT EXISTS `realm_campaign_log` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PK журнала',
  `guid`        INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `campaign_id` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'ID кампании (0 — не привязано)',
  `chapter`     TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Глава на момент действия',
  `action`      VARCHAR(32) NOT NULL COMMENT 'start/chapter/complete/reward/tokens/gm_set/gm_complete/gm_reset',
  `detail`      VARCHAR(255) NULL COMMENT 'Детали действия',
  `created_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_campaign_log_guid` (`guid`),
  KEY `idx_campaign_log_action` (`action`),
  KEY `idx_campaign_log_campaign` (`campaign_id`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Журнал действий кампаний реалма Эхо Пустоты (CampaignManager)';
