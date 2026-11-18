-- =============================================
-- 0052_season_events.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0052_season_events_characters.sql
-- =============================================

-- ------------------------------------------------------------
-- 2. Таблица состояния игрока в ежегодном сезоне
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_season_state` (
  `guid`         INT UNSIGNED NOT NULL COMMENT 'character guid',
  `year`         SMALLINT UNSIGNED NOT NULL COMMENT 'год ежегодного сезона (Цикл Осколка)',
  `stage`        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'текущий этап (1..N)',
  `stage_xp`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'прогресс внутри этапа',
  `season_item`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'активная сезонная валюта (item entry)',
  `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `year`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Состояние игрока в ежегодном сезоне (acore_characters)';
