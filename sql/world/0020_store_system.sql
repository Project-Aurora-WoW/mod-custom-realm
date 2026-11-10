-- ============================================================
-- 0020_store_system.sql — AIO-магазин «Эхо Пустоты»
--
-- Референс: eluna-aio-storesystem (AIO Store System).
-- Отличия от оригинала:
--   1. Таблицы realm_store_* в acore_world (вместо отдельной БД store).
--   2. Демо-журнал store_logs оригинала НЕ переносится (тестовые данные).
--   3. Валюты реалма: золото (id 1) + Жетон Эха item 70005 (id 2).
--   4. Демо-услуги реалма: маунт «Бездна-Пегас» (спелл 70010, item 70003),
--      титул «Хранитель Эха» (48 — требует DBC-патча, client-patch.md ч. 1),
--      баффы, стартовые услуги (смена имени). Цены в Жетонах Эха.
-- ============================================================

-- ---- Категории навигации ----
CREATE TABLE IF NOT EXISTS `realm_store_categories` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(765) NOT NULL DEFAULT '',
  `icon` varchar(765) NOT NULL DEFAULT '',
  `requiredRank` int NOT NULL DEFAULT 0,
  `flags` int unsigned NOT NULL DEFAULT 0,
  `enabled` int unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `realm_store_categories`;
INSERT INTO `realm_store_categories` (`id`, `name`, `icon`, `requiredRank`, `flags`, `enabled`) VALUES
    (1, 'Новинки',            'inv_misc_toy_07',                 0, 2, 1),
    (2, 'Титулы',             'inv_scroll_11',                   0, 0, 1),
    (3, 'Предметы',           'ability_warrior_challange',       0, 0, 1),
    (4, 'Маунты и питомцы',   'inv_box_petcarrier_01',           0, 0, 1),
    (5, 'Усиления',           'spell_holy_surgeoflight',         0, 0, 1),
    (6, 'Услуги',             'vas_charactertransfer',           0, 0, 1),
    (7, 'Скидки',             'inv_misc_toy_07',                 0, 1, 1),
    (8, 'VIP',                'inv_misc_note_03',                4, 0, 1);

-- ---- Связи категорий и услуг ----
CREATE TABLE IF NOT EXISTS `realm_store_category_service_link` (
  `category` int unsigned NOT NULL,
  `service` int unsigned NOT NULL,
  PRIMARY KEY (`category`,`service`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `realm_store_category_service_link`;
INSERT INTO `realm_store_category_service_link` (`category`, `service`) VALUES
    (1, 1), (1, 2), (1, 3),          -- новинки: Пегас, титул, баффы
    (2, 2),                          -- титулы
    (3, 4),                          -- предметы
    (4, 1),                          -- маунты
    (5, 3), (5, 5),                  -- усиления
    (6, 6), (6, 7),                  -- услуги
    (7, 5);                          -- скидки (авто-категория продублирует)

-- ---- Валюты ----
CREATE TABLE IF NOT EXISTS `realm_store_currencies` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `type` int unsigned NOT NULL DEFAULT 1,
  `name` varchar(50) NOT NULL DEFAULT '',
  `icon` varchar(50) NOT NULL DEFAULT '',
  `data` int NOT NULL DEFAULT 0,
  `tooltip` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `realm_store_currencies`;
INSERT INTO `realm_store_currencies` (`id`, `type`, `name`, `icon`, `data`, `tooltip`) VALUES
    (1, 1, 'Золото',      'Gold',  0,     'Обычное игровое золото.'),
    (2, 2, 'Жетон Эха',   'Token', 70005, 'Жетон Эха — валюта Пустоты (item 70005).');

-- ---- Услуги ----
CREATE TABLE IF NOT EXISTS `realm_store_services` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `type` int unsigned DEFAULT NULL,
  `name` text,
  `tooltipName` text,
  `tooltipType` varchar(765) DEFAULT NULL,
  `tooltipText` text,
  `icon` varchar(765) DEFAULT NULL,
  `price` int DEFAULT NULL,
  `currency` int DEFAULT NULL,
  `hyperlinkId` int DEFAULT NULL,
  `creatureEntry` int DEFAULT NULL,
  `discountAmount` int DEFAULT NULL,
  `flags` int DEFAULT NULL,
  `reward_1` int unsigned DEFAULT NULL,
  `reward_2` int unsigned DEFAULT NULL,
  `reward_3` int unsigned DEFAULT NULL,
  `reward_4` int unsigned DEFAULT NULL,
  `reward_5` int unsigned DEFAULT NULL,
  `reward_6` int unsigned DEFAULT NULL,
  `reward_7` int unsigned DEFAULT NULL,
  `reward_8` int unsigned DEFAULT NULL,
  `rewardcount_1` int unsigned DEFAULT NULL,
  `rewardcount_2` int unsigned DEFAULT NULL,
  `rewardcount_3` int unsigned DEFAULT NULL,
  `rewardcount_4` int unsigned DEFAULT NULL,
  `rewardcount_5` int unsigned DEFAULT NULL,
  `rewardcount_6` int unsigned DEFAULT NULL,
  `rewardcount_7` int unsigned DEFAULT NULL,
  `rewardcount_8` int unsigned DEFAULT NULL,
  `new` int unsigned NOT NULL DEFAULT 0,
  `enabled` int unsigned DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `realm_store_services`;
-- type: 1=предметы, 2=золото, 3=маунт, 4=питомец, 5=бафф, 7=услуга(AtLogin), 8=уровни, 9=титул
INSERT INTO `realm_store_services`
    (`id`, `type`, `name`, `tooltipName`, `tooltipType`, `tooltipText`, `icon`, `price`, `currency`,
     `hyperlinkId`, `creatureEntry`, `discountAmount`, `flags`,
     `reward_1`, `reward_2`, `reward_3`, `reward_4`, `reward_5`, `reward_6`, `reward_7`, `reward_8`,
     `rewardcount_1`, `rewardcount_2`, `rewardcount_3`, `rewardcount_4`, `rewardcount_5`, `rewardcount_6`, `rewardcount_7`, `rewardcount_8`,
     `new`, `enabled`)
VALUES
    -- 1: Маунт «Бездна-Пегас» (спелл 70010; creatureEntry 25279 — превью, шт. крылатая модель)
    (1, 3, 'Бездна-Пегас\r\n(Маунт)', 'Бездна-Пегас', 'spell', 'Призыв: Бездна-Пегас. Летает.\r\n\r\n|cff00FFFFНажмите для просмотра!|r', 'ability_mount_spectraltiger', 30, 2,
     70010, 25279, 0, 0, 70010, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
    -- 2: Титул «Хранитель Эха» (ID 48; требует DBC-патч клиента, client-patch.md ч. 1)
    (2, 9, 'Титул\r\nХранитель Эха', 'Хранитель Эха', '', 'Титул «Хранитель Эха» — награда Ордена Рассвета.\r\n\r\nТребуется DBC-патч клиента (client-patch.md ч. 1).', 'inv_mace_51', 50, 2,
     0, 0, 0, 0, 48, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
    -- 3: «Благословение Рассвета» (штатный бафф могущества 27140; скидка 5 жетонов → попадает в «Скидки»)
    (3, 5, 'Благословение Рассвета\r\n(Бафф)', 'Благословение Рассвета', 'spell', 'Мощное благословение Ордена Рассвета на 1 час.', 'spell_holy_fistofjustice', 10, 2,
     27140, 0, 5, 0, 27140, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 1, 1),
    -- 4: Слеза Рассвета (item 70001) ×3 — предмет за жетоны
    (4, 1, 'Слеза Рассвета ×3', 'Слеза Рассвета', 'item', 'Три Слезы Рассвета — ключи кампаний Ордена.', 'inv_valentine_slip_of_paper', 15, 2,
     70001, 0, 0, 1, 70001, 0, 0, 0, 0, 0, 0, 0,
     3, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 5: Смена имени (AtLogin-флаг 1)
    (6, 7, 'Смена имени', 'Смена имени', '', 'Смена имени персонажа. Применяется после перелогина.', 'vas_namechange', 25, 2,
     0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 1),
    -- 6: Золото: 500 золотых за 10 жетонов
    (7, 2, '500 золота', '500 золота', '', 'Немного золота в кошелёк агента Ордена.', 'inv_misc_coin_01', 10, 2,
     0, 0, 0, 0, 500, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

-- ---- Журнал покупок ----
CREATE TABLE IF NOT EXISTS `realm_store_logs` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `account` int DEFAULT NULL,
  `guid` int DEFAULT NULL,
  `serviceId` int DEFAULT NULL,
  `currencyId` int DEFAULT NULL,
  `cost` int DEFAULT NULL,
  `time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account` (`account`),
  KEY `idx_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
