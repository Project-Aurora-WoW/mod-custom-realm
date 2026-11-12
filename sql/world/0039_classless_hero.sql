-- ============================================================
-- 0039_classless_hero.sql — Classless: класс Hero (режим)
--
-- Фаза 3.2 (Classless full). Добавляет в character_classless
-- (acore_characters) колонку-флаг `hero` (0/1) — включён ли
-- режим «Класс Hero» для персонажа.
--
-- Что даёт Hero (реализация — в 27_Classless.lua):
--   • усиленные статы через штатные ауры-стаки (паттерн Parangon);
--   • доступен только после траты всех/минимальной части очков
--     талантов (порог CFG.hero_min_talent_points);
--   • команда `.aeclassless hero` включает/выключает.
--
-- Обратная совместимость: колонка добавляется к существующей
-- таблице 0025 (расширенной 0030) идемпотентно (ADD COLUMN
-- IF NOT EXISTS, MySQL 8.0.29+).
-- ============================================================

SET NAMES utf8mb4;

ALTER TABLE `character_classless`
  ADD COLUMN IF NOT EXISTS `hero` TINYINT UNSIGNED NOT NULL DEFAULT 0
  COMMENT 'Classless Hero mode (0/1)'
  AFTER `talents`;