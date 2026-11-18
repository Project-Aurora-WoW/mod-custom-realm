-- =============================================
-- 0018_eluna_scripts_tier_a.sql -> characters (acore_characters)
-- mysql -u user -p acore_characters < sql/world/0018_eluna_scripts_tier_a_characters.sql
-- =============================================

-- ============================================================
-- Azeroth: Эхо Пустоты — миграция 0018
-- 0018_eluna_scripts_tier_a.sql
-- Назначение: контент для систем Tier A, адаптированных из
-- референса eluna-scripts (sourcecraft.dev/m-orlovrus59/eluna-scripts,
-- автор Cloticc; лицензия и кредиты — в lua_scripts/README.md):
--   1. Таблица `realm_gold_storage` (acore_characters!):
--      НПС-банкир золота «Хранитель Золота» (16_GoldStorage.lua).
--   2. NPC 70172 «Рунный Обжиг» — зачарователь за золото
--      (15_Enchanter.lua; 70180 занят Хронистом Ордена, 0011).
--   3. NPC 70173 «Хранитель Золота» — банкир золота
--      (16_GoldStorage.lua).
--   4. NPC 70190 «Разлом Пустоты» (портал, временный спавн) и
--      NPC 70191 «Иссушенный из Разлома» — ивент «Разломы
--      Пустоты» (17_TimeRift.lua; спавнятся скриптом, в БД —
--      только шаблоны).
--   5. Спелл 70050 «Пустотная порча» (spell_dbc, acore_world):
--      визуальная основа системы Corruption (18_VoidCorruption.lua).
--      ⚠️ Кастомный спелл требует строк в клиентском DBC при
--      полном отображении (см. docs/client-patch.md ч. 4c; эталон
--      миграции — 0016_dbc_reference_sample.sql). До DBC-патча
--      спелл работает серверно (стаки видны через иконку-заглушку
--      или логику ядра — проверить на тестовом реалме).
--   6. Предмет 70008 «Осколок Пустоты» — источник порчи
--      (18_VoidCorruption.lua; entry свободен: 70001–70007 заняты
--      кампаниями, 70100/70101 — Waloria-награды).
-- ============================================================
-- ПРИМЕНЕНИЕ:
--   mysql -u <user> -p acore_world < sql/world/0018_eluna_scripts_tier_a.sql
--   mysql -u <user> -p acore_characters < sql/world/0018_eluna_scripts_tier_a.sql
-- ============================================================

SET NAMES utf8mb4;
-- ============================================================
-- ЧАСТЬ 3 (acore_characters): таблица казны золота
-- ============================================================
CREATE TABLE IF NOT EXISTS `realm_gold_storage` (
  `account` INT UNSIGNED NOT NULL,
  `name`    VARCHAR(255) NOT NULL,
  `gold`    BIGINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Казна золота НПС-банкира (16_GoldStorage.lua, 0018)';
