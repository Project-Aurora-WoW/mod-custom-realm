-- ============================================================
-- 0026_store_expansion.sql — расширение AIO-магазина «Эхо Пустоты»
--
-- Фаза 1.1 плана ROADMAP-Features.md:
--   1. Новая валюта id 3 — SERVER_HANDLED «Очки Возмездия»
--      (источник: realm_pvp_stats.tokens_earned, ПРИМЕНЯЕТСЯ В acore_characters).
--   2. VIP-категория id 9 (requiredRank = 4).
--   3. Дополнительные маунты за Жетоны Эха.
--   4. Связи категорий и услуг.
--
-- Зависимости: 0020 (таблицы realm_store_*), 0009 (жетоны), 0015/0021 (валюты).
-- Идемпотентно: UPDATE/INSERT по ключам, без DELETE широкого скоупа.
-- ============================================================

-- ---- 1. Валюта SERVER_HANDLED «Очки Возмездия» (id 3) ----
-- data = 0 (тип SERVER_HANDLED не ссылается на item; значение читает
-- Store_Server.lua из realm_pvp_stats.tokens_earned по GUID игрока).
INSERT INTO `realm_store_currencies` (`id`, `type`, `name`, `icon`, `data`, `tooltip`)
VALUES (3, 3, 'Очки Возмездия', 'Ability_PvPAura', 0, 'SERVER_HANDLED: очки из PvP (realm_pvp_stats.tokens_earned).')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `type` = VALUES(`type`),
  `icon` = VALUES(`icon`), `data` = VALUES(`data`), `tooltip` = VALUES(`tooltip`);

-- ---- 2. VIP-категория (id 9, requiredRank = 4) ----
INSERT INTO `realm_store_categories` (`id`, `name`, `icon`, `requiredRank`, `flags`, `enabled`)
VALUES (9, 'VIP-арсенал', 'inv_misc_note_03', 4, 0, 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `icon` = VALUES(`icon`),
  `requiredRank` = VALUES(`requiredRank`), `flags` = VALUES(`flags`), `enabled` = VALUES(`enabled`);

-- ---- 3. Дополнительные маунты за жетоны (тип 3 = маунт) ----
-- Спеллы штатные (3.3.5a), creatureEntry — превью-модели. Диапазоны id услуг:
-- 10–12 (свободны после 0020). Валюты: 2 = Жетон Эха, 3 = Очки Возмездия.
INSERT INTO `realm_store_services`
    (`id`, `type`, `name`, `tooltipName`, `tooltipType`, `tooltipText`, `icon`,
     `price`, `currency`, `hyperlinkId`, `creatureEntry`, `discountAmount`, `flags`,
     `reward_1`, `reward_2`, `reward_3`, `reward_4`, `reward_5`, `reward_6`, `reward_7`, `reward_8`,
     `rewardcount_1`, `rewardcount_2`, `rewardcount_3`, `rewardcount_4`, `rewardcount_5`, `rewardcount_6`, `rewardcount_7`, `rewardcount_8`,
     `new`, `enabled`)
VALUES
    -- 10: Северный небесный скакун (спелл 63640; превью «Грифон-Ветрокрыл», 27692)
    (10, 3, 'Северный небесный\r\nскакун', 'Северный небесный скакун', 'spell',
     'Боевой крылатый скакун Ордена.\r\n\r\n|cff00FFFFНажмите для просмотра!|r',
     'ability_mount_epicflight', 25, 2, 63640, 27692, 0, 0, 63640, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 11: Возмездие Механического (механоцикл, спелл 43900) — за Очки Возмездия (валюта 3)
    (11, 3, 'Возмездие\r\nМеханоцикла', 'Возмездие Механоцикла', 'spell',
     'Механоцикл Инженерной Гильдии.\r\n\r\nТребует 80 Очков Возмездия.',
     'inv_misc_enggizmos_04', 80, 3, 43900, 27960, 0, 0, 43900, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 12: VIP — Боевой вепрь Возмездия (спелл 23214; VIP-категория, requiredRank=4)
    (12, 3, 'Боевой вепрь\r\nВозмездия', 'Боевой вепрь Возмездия', 'spell',
     'Элитный кабан Возмездия — VIP-маунт Ордена.\r\n\r\nТребуется ранг 4 (VIP).',
     'ability_mount_boar', 40, 2, 23214, 31849, 0, 0, 23214, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 1, 1)
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`), `name` = VALUES(`name`), `tooltipName` = VALUES(`tooltipName`),
    `tooltipType` = VALUES(`tooltipType`), `tooltipText` = VALUES(`tooltipText`), `icon` = VALUES(`icon`),
    `price` = VALUES(`price`), `currency` = VALUES(`currency`), `hyperlinkId` = VALUES(`hyperlinkId`),
    `creatureEntry` = VALUES(`creatureEntry`), `reward_1` = VALUES(`reward_1`),
    `reward_2` = VALUES(`reward_2`), `reward_3` = VALUES(`reward_3`), `reward_4` = VALUES(`reward_4`),
    `reward_5` = VALUES(`reward_5`), `reward_6` = VALUES(`reward_6`), `reward_7` = VALUES(`reward_7`),
    `reward_8` = VALUES(`reward_8`), `new` = VALUES(`new`), `enabled` = VALUES(`enabled`);

-- ---- 4. Связи категорий и услуг ----
-- 10 (небесный скакун) → «Маунты и питомцы» (кат. 4); 11 (механоцикл) → «Усиления»/PvP;
-- 12 (VIP вепрь) → VIP (кат. 9) и «Новинки» (кат. 1).
INSERT IGNORE INTO `realm_store_category_service_link` (`category`, `service`) VALUES
    (4, 10),
    (5, 11),
    (9, 12),
    (1, 12);

-- ---- 5. Прелюдия к SERVER_HANDLED (оставлено для Store_Server.lua) ----
-- Комментарий: реальное списание/начисление Очков Возмездия читает
-- realm_pvp_stats (acore_characters) — см. lua_scripts/Store_Server.lua.
-- ВАЖНО: таблица realm_pvp_stats живёт в acore_characters, а realm_store_* —
-- в acore_world. Связка игрок↔очки идёт через CharDBQuery(guid).