-- ============================================================
-- 0038_store_vip_expansion.sql — Расширение магазина: VIP-доступ
--
-- Часть фазы 1.1 (Наполнение магазина).
--
-- Что делает:
--   1. VIP-категорию (id 8) переводит с requiredRank=4 (GM-ориентир) на 1,
--      чтобы доступ определялся VIP-рангом игрока (realm_vip, 34_VipSystem).
--      Сервер (Store_Server.lua) отдаёт accountRank = max(GMRank, VipRank).
--   2. Существующие услуги (титул id 2, бафф id 3) дополнительно связывает
--      с VIP-категорией — VIP-игрок видит их и в обычной, и в VIP-категории.
--   3. Добавляет VIP-эксклюзив: бафф «Печать Бездны» (ид услуги 20) только
--      в VIP-категории, за Жетоны Эха (currency 2).
--
-- Идемпотентно: корректирующие UPDATE + INSERT ... ON DUPLICATE KEY UPDATE.
-- ============================================================

-- 1) VIP-категория доступна VIP-рангу >= 1 (не только GM)
UPDATE `realm_store_categories`
SET `requiredRank` = 1
WHERE `id` = 8 AND `name` = 'VIP';

-- 2) Связать заодно титул и бафф с VIP-категорией (без дублей)
INSERT INTO `realm_store_category_service_link` (`category`, `service`) VALUES
    (8, 2),   -- титул «Хранитель Эха»
    (8, 3)    -- бафф «Благословение Рассвета»
ON DUPLICATE KEY UPDATE `service` = `service`;

-- 3) VIP-эксклюзив: бафф «Печать Бездны» (спелл 70051), только VIP, Жетоны Эха
INSERT INTO `realm_store_services`
    (`id`, `type`, `name`, `tooltipName`, `tooltipType`, `tooltipText`, `icon`, `price`, `currency`,
     `hyperlinkId`, `creatureEntry`, `discountAmount`, `flags`,
     `reward_1`, `reward_2`, `reward_3`, `reward_4`, `reward_5`, `reward_6`, `reward_7`, `reward_8`,
     `rewardcount_1`, `rewardcount_2`, `rewardcount_3`, `rewardcount_4`, `rewardcount_5`, `rewardcount_6`, `rewardcount_7`, `rewardcount_8`,
     `new`, `enabled`)
VALUES
    (20, 5, 'Печать Бездны\r\n(VIP-бафф)', 'Печать Бездны', 'spell', 'Уникальный VIP-бафф Эха Пустоты на 1 час. Только для VIP.', 'spell_shadow_antishadow', 20, 2,
     70051, 0, 0, 0, 70051, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0, 1, 1)
ON DUPLICATE KEY UPDATE `enabled` = 1;

INSERT INTO `realm_store_category_service_link` (`category`, `service`) VALUES
    (8, 20)
ON DUPLICATE KEY UPDATE `service` = `service`;