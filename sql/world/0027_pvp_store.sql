-- ============================================================
-- 0027_pvp_store.sql — перенос PvP-шопа в AIO-магазин
--
-- Фаза 1.2 плана ROADMAP-Features.md.
-- Переносит ассортимент «Интенданта Ордена» (НПС 70170, lua_scripts/30_PvpShop.lua)
-- в категорию AIO-магазина. Товары = услуги типа 1 (предметы через почту),
-- валюта = Жетон Эха (id 2). Цены/количества повторяют реестр shop.items
-- (00_CampaignRegistry.ext) для бесшовной замены.
--
-- Зависимости: 0020 (таблицы realm_store_*), 0009 (жетоны item 70005).
-- Идемпотентно: INSERT ... ON DUPLICATE KEY UPDATE.
-- ============================================================

-- ---- 1. Категория «Снабжение Ордена» (id 10) ----
INSERT INTO `realm_store_categories` (`id`, `name`, `icon`, `requiredRank`, `flags`, `enabled`)
VALUES (10, 'Снабжение Ордена', 'inv_misc_bag_08', 0, 0, 1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `icon` = VALUES(`icon`),
  `requiredRank` = VALUES(`requiredRank`), `flags` = VALUES(`flags`), `enabled` = VALUES(`enabled`);

-- ---- 2. Ассортимент PvP-шопа как услуги (id 20–25, тип 1 = предметы) ----
-- Цены/количества повторяют 00_CampaignRegistry.ext shop.items.
INSERT INTO `realm_store_services`
    (`id`, `type`, `name`, `tooltipName`, `tooltipType`, `tooltipText`, `icon`,
     `price`, `currency`, `hyperlinkId`, `creatureEntry`, `discountAmount`, `flags`,
     `reward_1`, `reward_2`, `reward_3`, `reward_4`, `reward_5`, `reward_6`, `reward_7`, `reward_8`,
     `rewardcount_1`, `rewardcount_2`, `rewardcount_3`, `rewardcount_4`, `rewardcount_5`, `rewardcount_6`, `rewardcount_7`, `rewardcount_8`,
     `new`, `enabled`)
VALUES
    -- 20: Рунное зелье исцеления ×5
    (20, 1, 'Рунное зелье\r\nисцеления ×5', 'Рунное зелье исцеления', 'item',
     'Восстанавливает здоровье. Пять штук.',
     'inv_potion_54', 2, 2, 33471, 0, 0, 0, 33471, 0, 0, 0, 0, 0, 0, 0,
     5, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 21: Рунное зелье маны ×5
    (21, 1, 'Рунное зелье маны ×5', 'Рунное зелье маны', 'item',
     'Восстанавливает ману. Пять штук.',
     'inv_potion_32', 2, 2, 33476, 0, 0, 0, 33476, 0, 0, 0, 0, 0, 0, 0,
     5, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 22: Флакон бесконечной ярости
    (22, 1, 'Флакон\r\nбесконечной ярости', 'Флакон бесконечной ярости', 'item',
     'Мощный флакон на ярость/силу.',
     'inv_potion_66', 5, 2, 40078, 0, 0, 0, 40078, 0, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 23: Флакон ледяного дракона
    (23, 1, 'Флакон\r\nледяного дракона', 'Флакон ледяного дракона', 'item',
     'Флакон, усиливающий силу заклинаний.',
     'inv_potion_97', 5, 2, 40081, 0, 0, 0, 40081, 0, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 24: Рунные полоски мяса ×5 (еда)
    (24, 1, 'Рунные полоски\r\nмяса ×5', 'Рунные полоски мяса', 'item',
     'Сытная еда для приключений. Пять порций.',
     'inv_misc_food_86', 3, 2, 43005, 0, 0, 0, 43005, 0, 0, 0, 0, 0, 0, 0,
     5, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 25: Турбо-скудохранитель (косметика)
    (25, 1, 'Турбо-скудохранитель', 'Турбо-скудохранитель', 'item',
     'Инженерная косметика. Турбо-скудохранитель у входа.',
     'inv_misc_punchingbag', 10, 2, 69237, 0, 0, 0, 69237, 0, 0, 0, 0, 0, 0, 0,
     1, 0, 0, 0, 0, 0, 0, 0, 0, 1)
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`), `name` = VALUES(`name`), `tooltipName` = VALUES(`tooltipName`),
    `tooltipType` = VALUES(`tooltipType`), `tooltipText` = VALUES(`tooltipText`), `icon` = VALUES(`icon`),
    `price` = VALUES(`price`), `currency` = VALUES(`currency`), `hyperlinkId` = VALUES(`hyperlinkId`),
    `creatureEntry` = VALUES(`creatureEntry`), `reward_1` = VALUES(`reward_1`),
    `reward_2` = VALUES(`reward_2`), `reward_3` = VALUES(`reward_3`), `reward_4` = VALUES(`reward_4`),
    `reward_5` = VALUES(`reward_5`), `reward_6` = VALUES(`reward_6`), `reward_7` = VALUES(`reward_7`),
    `reward_8` = VALUES(`reward_8`), `new` = VALUES(`new`), `enabled` = VALUES(`enabled`);

-- ---- 3. Связи: все товары в категорию «Снабжение Ордена» (10) ----
INSERT IGNORE INTO `realm_store_category_service_link` (`category`, `service`) VALUES
    (10, 20), (10, 21), (10, 22), (10, 23), (10, 24), (10, 25);

-- ---- 4. ПРИМЕЧАНИЕ про старый PvP-шоп ----
-- НПС 70170 и lua_scripts/30_PvpShop.lua остаются (ассортимент прежний).
-- Перенос не удаляет их: в категории AIO появились те же товары, чтобы игроки,
-- у кого нет клиента AIO, могли покупать по-прежнему через НПС. Если решено
-- полностью вытеснить НПС-шоп — отключите скрипт 30_PvpShop.lua отдельно.