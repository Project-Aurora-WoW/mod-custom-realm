-- ============================================================
-- 0030_classless_full.sql — Classless «полная версия»: таланты
--
-- Фаза 3 плана ROADMAP-Features.md. Расширяет минимальную версию
-- (0025, спеллы+глифы) на таланты — добавляет колонку `talents`
-- в таблицу character_classless (acore_characters).
--
-- Формат хранения талантов: CSV «talentSpellID|talentID|rank»,
-- разделитель строк — ;  (списки упорядочены, как и в референсе).
--   talentSpellID — спелл таланта (после применения к персонажу);
--   talentID      — id таланта из БД талантов (для LearnTalent);
--   rank          — текущий ранг (1..max).
--
-- Пример: '12345|1234|3;12346|1235|1'
--
-- Обратная совместимость: колонка добавляется к существующей
-- таблице 0025; старые строки получают пустой список талантов.
-- Идемпотентно: ADD COLUMN IF NOT EXISTS (MySQL 8.0.29+).
-- ============================================================

SET NAMES utf8mb4;

ALTER TABLE `character_classless`
  ADD COLUMN IF NOT EXISTS `talents` mediumtext COLLATE utf8mb4_unicode_ci
  NOT NULL COMMENT 'CSV Classless-талантов: talentSpellID|talentID|rank; разделитель ;'
  AFTER `glyphs`;

-- ---- Обновить комментарий таблицы (отражает полную версию) ----
-- (опционально; MySQL не поддерживает ALTER на COMMENT колонки в той же
--  транзакции как IF NOT EXISTS — оставляем как есть для совместимости.)