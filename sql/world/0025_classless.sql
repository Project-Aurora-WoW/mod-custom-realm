-- ============================================================
-- 0025_classless.sql — Classless-арка К5: таблица навыков
--
-- Референс: Shikifuyin/AzerothCore-ClassLess-Solo
-- (ClassLess/SQL/CLCreateTable.sql). Адаптация под реалм
-- «Эхо Пустоты» (AzerothCore).
--
-- Минимальная версия (без AIO-UI): таблица хранит изученные
-- игроком «чужие» классовые спеллы и глифы строками CSV
-- (список ID, активно изучил скрипт 27_Classless.lua).
-- Таланты в минимальной версии НЕ включены (см. 27_Classless.lua,
-- раздел «Объём»): данные референса завязаны на C++-класс
-- талант-дескрипторов и пет-талантов, ненадёжно снимаемые через
-- RemoveSpell в Eluna/ALE.
--
-- ОСНОВНАЯ СХЕМА: acore_characters.
--
-- ДВОЙНОЕ ПРИМЕНЕНИЕ: идемпотентно (CREATE TABLE IF NOT EXISTS).
-- ============================================================

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `character_classless` (
  `guid` int unsigned NOT NULL COMMENT 'Player GUID (Low)',
  `spells` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CSV чужих изученных спеллов (текущие ранги)',
  `glyphs` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'CSV чужих изученных глифов',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Classless (арка К5) — миним. версия, спеллы+глифы';