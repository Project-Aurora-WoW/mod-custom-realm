-- =============================================
-- 0024_tier_b.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0024_tier_b_characters.sql
-- =============================================

-- ================== ЧАСТЬ 1: acore_characters ==================
-- Лотерея: розыгрыш по неделям (week_number = максимум)
CREATE TABLE IF NOT EXISTS `realm_lottery` (
  `week_number` int unsigned NOT NULL,
  `number1` int unsigned NOT NULL DEFAULT 0,
  `number2` int unsigned NOT NULL DEFAULT 0,
  `number3` int unsigned NOT NULL DEFAULT 0,
  `number4` int unsigned NOT NULL DEFAULT 0,
  `number5` int unsigned NOT NULL DEFAULT 0,
  `number6` int unsigned NOT NULL DEFAULT 0,
  `amount` bigint unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`week_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Билеты лотереи (одна строка = один билет)
CREATE TABLE IF NOT EXISTS `realm_lottery_tickets` (
  `ticket_id` int unsigned NOT NULL AUTO_INCREMENT,
  `week_number` int unsigned NOT NULL,
  `player_guid` int unsigned NOT NULL,
  `player_account_id` int unsigned NOT NULL,
  `number1` int unsigned NOT NULL,
  `number2` int unsigned NOT NULL,
  `number3` int unsigned NOT NULL,
  `number4` int unsigned NOT NULL,
  `number5` int unsigned NOT NULL,
  `number6` int unsigned NOT NULL,
  PRIMARY KEY (`ticket_id`),
  KEY `idx_week` (`week_number`),
  KEY `idx_player` (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
