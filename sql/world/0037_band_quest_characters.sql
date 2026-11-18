-- =============================================
-- 0037_band_quest.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0037_band_quest_characters.sql
-- =============================================

-- Штормград

-- --- Таблица состояния цепочки (acore_characters) ---
CREATE TABLE IF NOT EXISTS `realm_band_quest` (
    `account_id` INT UNSIGNED NOT NULL,
    `stage`      TINYINT UNSIGNED NOT NULL DEFAULT 0,  -- 0=нет,1=затишье,2=настройка,3=премьера
    `updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
