-- ============================================================
-- 0031_gpt_npc.sql — GPT-НПС: очередь запросов/ответов (Фаза 4)
--
-- Внешний Python-сервис вызывает OpenAI API; обмен с ALE-скриптом
-- gpt_npc.lua идёт через БД-очередь (в ALE нет HTTP-клиента).
--   realm_gpt_queue (acore_characters):
--     id            PK AUTO_INCREMENT
--     guid          GUID игрока (инициатора диалога)
--     npc_entry     entry НПС, к которому обращение
--     prompt_ru/en  текст игрока (в локали клиента)
--     reply         текст ответа НПС (заполняет Python-сервис)
--     locale        8 = ru, иначе en (канал ответа + язык модели)
--     status        0 = ждёт сервиса, 1 = ответ готов, 2 = ошибка
--     created_at    время создания
--     updated_at    время ответа сервиса
--
-- Идемпотентно: CREATE TABLE IF NOT EXISTS.
-- ============================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `realm_gpt_queue` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `guid`       INT UNSIGNED NOT NULL DEFAULT 0,
  `npc_entry`  INT UNSIGNED NOT NULL DEFAULT 0,
  `prompt_ru`  TEXT NULL,
  `prompt_en`  TEXT NULL,
  `reply`      TEXT NULL,
  `locale`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `status`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='GPT-НПС: очередь запросов/ответов (Фаза 4)';