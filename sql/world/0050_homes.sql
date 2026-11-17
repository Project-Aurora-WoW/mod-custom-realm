-- ============================================================
-- 0050_homes.sql
-- Система домов (п.4): телепорт-убежище игрока.
--   Таблица: realm_homes (acore_characters) — точка дома каждого игрока.
--   Механика: команды .ae home (телепорт домой), .ae homehere
--   (установить точку на месте), .ae homeset <label>. Клиент — вкладка
--   «Дом» в аддоне AzerothEcho (payload AECHOHOME).
-- СХЕМА: AzerothCore 3.3.5. Идемпотентна (REPLACE).
-- Lua — 46_Home.lua; реестр — 00_CampaignRegistry.ext (home).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Таблица домов (acore_characters)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_homes` (
  `guid`       INT UNSIGNED NOT NULL COMMENT 'character guid (владелец дома)',
  `map`        INT UNSIGNED NOT NULL DEFAULT 571 COMMENT 'mapId точки дома',
  `position_x` FLOAT NOT NULL DEFAULT 0,
  `position_y` FLOAT NOT NULL DEFAULT 0,
  `position_z` FLOAT NOT NULL DEFAULT 0,
  `orientation` FLOAT NOT NULL DEFAULT 0,
  `label`      VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'имя/пометка дома',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Телепорт-убежище игрока (acore_characters)';