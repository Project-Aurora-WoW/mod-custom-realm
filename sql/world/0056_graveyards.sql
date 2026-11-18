-- ============================================================
-- 0056_graveyards.sql
-- Стоковая механика воскрешения в новых локациях.
--
-- WoW 3.3.5: после смерти игрок становится призраком и возрождается
-- на ближайшем кладбище (game_graveyard), выбранном по привязке
-- graveyard_zone (зона -> кладбище, по фракции). Это штатный цикл
-- смерти/воскрешения ядра AzerothCore — здесь мы лишь даём точкам
-- приземления, чтобы в кастомных зонах (карта 5000) и зонах кампаний
-- игрок не «застревал» в бездне и не падал на стоковое кладбище вне
-- зоны боя.
--
-- Добавляем кладбища для:
--   * карты 5000 — Остров Морза (тайлы 25-26/57-58, Z≈9) и Долина
--     Предательства (тайлы 48-50/12-14, Z≈22) — якори PortalGuardian.lua;
--   * Northrend (571) — Драконий Погост / пепелище (zone 4080, area 4365)
--     и Даларан (zone 4395) — сцены кампаний К8–К11.
--
-- Схемы (AzerothCore 3.3.5):
--   game_graveyard(ID, Map, x, y, z, Comment)
--   graveyard_zone(ID, GhostZone, Faction, Comment)  -- Faction 0 = обе фракции
-- Идемпотентно (DELETE + INSERT по ID).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Карта 5000: кладбища в новых зонах
-- ------------------------------------------------------------
DELETE FROM `game_graveyard` WHERE `ID` BETWEEN 50000 AND 50009;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
  -- Остров Морза — точка возрождения у флотского перевала
  (50000, 5000, -13950.00, 2877.00, 9.00, 'Ostrov Morza - flotskij pereval (map 5000)'),
  -- Долина Предательства — точка возрождения в центре долины
  (50001, 5000, 10461.00, -9574.00, 22.00, 'Dolina Predatelstva (map 5000)');

DELETE FROM `graveyard_zone` WHERE `ID` BETWEEN 50000 AND 50009;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
  -- Привязка зон к кладбищам (faction 0 = обе фракции). GhostZone для
  -- кастомных карт неизвестен (нет AreaTable в DBC) — используем 0,
  -- а также явные привязки в зонах кампаний ниже.
  (50000, 0, 0, 'Morza graveyard - all factions'),
  (50001, 0, 0, 'Betrayal graveyard - all factions');

-- ------------------------------------------------------------
-- Northrend (571): кладбища в зонах кампаний Ордена
-- ------------------------------------------------------------
DELETE FROM `game_graveyard` WHERE `ID` IN (57199, 57198);
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
  -- Драконий Погост / пещелище (zone 4080, area 4365) — место финальных боёв
  (57199, 571, 3899.60, 7049.10, 151.40, 'Ashen Wastes - Dragonblight (K8-K11 bosses)'),
  -- Даларан (zone 4395) — штаб Ордена, старт кампаний
  (57198, 571, 5810.00, 620.00, 647.80, 'Dalaran - Order HQ');

DELETE FROM `graveyard_zone` WHERE `ID` IN (57199, 57198);
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
  (57199, 4080, 0, 'Ashen Wastes graveyard - all factions'),
  (57199, 4365, 0, 'Ashen Wastes area graveyard - all factions'),
  (57198, 4395, 0, 'Dalaran Order graveyard - all factions');

-- ============================================================
-- КОНЕЦ 0056_graveyards.sql
-- ============================================================