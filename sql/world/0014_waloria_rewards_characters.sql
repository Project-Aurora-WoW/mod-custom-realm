-- =============================================
-- 0014_waloria_rewards.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0014_waloria_rewards_characters.sql
-- =============================================

-- ------------------------------------------------------------
-- Таблица выданных наград (антидубль): персонаж × уровень-порог
-- (acore_characters — как остальные игровые таблицы реалма)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_level_rewards` (
  `guid`        INT UNSIGNED NOT NULL,
  `reward_level` TINYINT UNSIGNED NOT NULL,
  `granted_at`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `reward_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Выданные level-up награды (06_WaloriaRewards.lua)';
