-- ============================================================
-- 0023_echo_schema_alignment.sql
-- Назначение: добрать в echo_world отсутствующие предметы реалма,
-- не трогая уже работающий контент (42 шаблона, 48 спавнов).
--
-- Схема: echo_* (НЕ стоковый AzerothCore):
--   creature_template — 55 колонок, малый набор обязательных;
--   item_template     — 138 колонок, нет StatsCount;
--                       10 стат-пар stat_type1..10 / stat_value1..10.
--
-- Добавляется:
--   70001 «Слеза Рассвета» — награда кампании 1, токен доступа к К2
--   70005 «Жетон Эха»      — валюта ивентов/PvP/магазина
--
-- Идемпотентно: DELETE по своим entry + INSERT.
-- Применять в echo_world.
-- ============================================================

SET NAMES utf8mb4;

-- ── 1. «Слеза Рассвета» (70001) — предмет кампании 1 ─────────
DELETE FROM `item_template` WHERE `entry` = 70001;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `InventoryType`, `ItemLevel`, `RequiredLevel`,
 `stackable`, `bonding`, `description`, `VerifiedBuild`)
VALUES
(70001, 12, 0, -1, 'Слеза Рассвета', 38625,
 5, 32768, 0, 80, 0,
 1, 1,
 'Реликвия Ордена Рассвета. Токен доступа к кампании «Пепел Зул''Драка». Шёпот осколка умолкает рядом с ней.',
 12340);

-- ── 2. «Жетон Эха» (70005) — валюта реалма ───────────────────
DELETE FROM `item_template` WHERE `entry` = 70005;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `InventoryType`, `ItemLevel`, `RequiredLevel`,
 `stackable`, `bonding`, `description`, `VerifiedBuild`)
VALUES
(70005, 12, 0, -1, 'Жетон Эха', 38625,
 3, 32768, 0, 80, 0,
 20, 1,
 'Валюта Ордена Рассвета. Добывается в ивентах реалма и в PvP-зоне Драконьего Погоста.',
 12340);

-- ── 3. Контроль: оба предмета должны найтись ────────────────
-- SELECT `entry`, `name`, `Quality`, `stackable` FROM `item_template`
--  WHERE `entry` IN (70001, 70005);
