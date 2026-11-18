-- =============================================
-- 0009_event_pvp.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0009_event_pvp_characters.sql
-- =============================================

-- --- 2. PvP-статистика (ПРИМЕНЯТЬ В acore_characters!) ------
-- Выполнять: mysql -u <user> -p acore_characters < 0009_event_pvp.sql
-- (таблица item_template выше при этом не применится — создайте отдельно
--  в acore_world, либо примените файл дважды в обе БД; INSERT идемпотентен)
CREATE TABLE IF NOT EXISTS `realm_pvp_stats` (
  `guid`           INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `kills`          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Всего PvP-убийств (зачётные)',
  `deaths`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Смертей от игроков (зачётных)',
  `streak`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Текущая серия убийств',
  `best_streak`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Лучшая серия',
  `zone_kills`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Киллов в PvP-зоне (Драконий Погост)',
  `tokens_earned`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Жетонов Эха заработано в PvP',
  `last_victim`    INT UNSIGNED NULL COMMENT 'GUID последней жертвы (анти-фарм)',
  `last_kill_time` INT UNSIGNED NULL COMMENT 'Время последнего зачётного килла (unix)',
  `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'PvP-статистика реалма Эхо Пустоты';
