-- ============================================================
-- 0042_campaign_profile.sql — Профиль кампании персонажа
--
-- Нужно для «стартового окна выбора кампаний» (бриф: реализация и
-- проверка стартового окна, мониторинга активности, интеграции
-- аддонов). Хранит принудительный показ окна и выбранную кампанию.
--
-- Отдельная таблица realm_* (по конвенции проекта не трогаем схему
-- ядра characters): данные реалма живут в realm_*/custom_*.
--
-- Колонки:
--   guid                — characters.guid (PK)
--   force_show_window   — 1 = сервер обязан принудительно открыть окно
--                         при входе; 0 = уже выбран/подтверждён
--   campaign_id         — выбранная кампания (см. docs/campaigns/README.md);
--                         NULL = ещё не выбрана
--   updated_at          — время последнего обновления
--
-- Применяется в acore_characters (как 0002/0029) через CharDB*.
-- Идемпотентно: CREATE TABLE IF NOT EXISTS.
-- ============================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `realm_campaign_profile` (
  `guid`              INT UNSIGNED NOT NULL COMMENT 'characters.guid',
  `force_show_window` TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '1 = принудительно открыть окно выбора кампании при входе',
  `campaign_id`       TINYINT UNSIGNED NULL COMMENT 'Выбранная кампания; NULL = ещё не выбрана',
  `updated_at`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ремовый профиль кампании: принудительный показ окна и выбранная кампания';

-- При создании персонажа профиль не существует — скрипт 40_CampaignWindow.lua
-- при первом входе читает окружение: если строки нет, трактует как
-- force_show_window=1, campaign_id=NULL (первый выбор).