-- ============================================================
-- 0014_waloria_rewards.sql
-- Награды за уровни по подходу Waloria (референс:
-- sourcecraft.dev/m-orlovrus59/waloria — welcome reward на 2-м
-- уровне и level-up награды каждые 5 уровней).
--
-- Состав:
--   1. Кастомный item 70100 «Паёк Ордена» (welcome reward, лvl 2)
--      — набор расходников одним предметом (лор: Орден встречает
--      новичка припасами).
--   2. Кастомный item 70101 «Сумка Эха» (level-up reward) —
--      «лoot-мешок» с наградой за каждые 5 уровней, выдается
--      Lua-скриптом 06_WaloriaRewards.lua.
--
-- Все предметы BoP, качество uncommon, для всех классов/рас.
-- Entry в диапазоне кастомных предметов 70001–79999 (свободные).
-- ============================================================
-- ------------------------------------------------------------
-- 70100 «Паёк Ордена» — welcome reward (уровень 2)
-- Использование: выдаёт еду/зелья через серверный Lua-хендлер
-- (06_WaloriaRewards.lua, spellitem-подход: item без спелла,
-- логика на ON_ITEM_USE в Lua невозможна — поэтому предмет
-- знаковый (сигнальный), реальные припасы выдаются напрямую
-- при достижении уровня 2, а item 70100 — памятный токен).
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` IN (70100, 70101);
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
 `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
 `ItemLevel`, `RequiredLevel`, `Material`, `bonding`, `description`, `Stackable`, `maxcount`)
VALUES
(70100, 12, -1, 'Паёк Ордена', 6289, 2, 0,
 0, 0, 0, -1, -1,
 1, 1, -1, 1,
 'Памятный знак Ордена Рассвета за первые шаги против Пустоты. (Награда за 2-й уровень)', 20, 0),
(70101, 12, -1, 'Сумка Эха', 6289, 3, 0,
 0, 0, 0, -1, -1,
 5, 1, -1, 1,
 'Мешочек с наградой Ордена за верную службу. (Награда каждые 5 уровней)', 20, 0);

-- ------------------------------------------------------------
-- Таблица выданных наград (антидубль): персонаж × уровень-порог
-- (acore_characters — как остальные игровые таблицы реалма)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_level_rewards` (
  `guid`        INT UNSIGNED NOT NULL,
  `reward_level` TINYINT UNSIGNED NOT NULL,
  `granted_at`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `reward_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Выданные level-up награды (06_WaloriaRewards.lua)';
