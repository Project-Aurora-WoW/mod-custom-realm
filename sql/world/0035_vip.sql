-- ============================================================
-- 0035_vip.sql — VIP-система (референс: BlackWolfsDen/Eluna-Grumboz_VIP_System)
--
-- Адаптация под реалм «Эхо Пустоты»:
--   • VIP-ранг на АККАУНТ (не auth.account — своя таблица в acore_characters);
--   • валюта/доступ — через команды и скрипты 34_VipSystem.lua;
--   • без MG (Magic Gold) — используется Жетон Эха / золото;
--   • совместимые фичи: статус-ранг, VIP-бафф, self-revive, мгновенный
--     ремонт/банк-доступ по рангу (если включено в конфиге).
--   Идемпотентно: CREATE TABLE IF NOT EXISTS.
-- ============================================================

-- VIP-статусы аккаунтов.
-- account_id  — id аккаунта (auth.account.id, но таблица в characters).
-- vip_rank    — текущий VIP-уровень (0 = нет, 1..10 как в референсе).
-- vip_expiry  — unix-время окончания подписки VIP (0 = бессрочно).
-- flags       — битовая маска (зарезервировано).
CREATE TABLE IF NOT EXISTS `realm_vip` (
    `account_id` INT UNSIGNED NOT NULL COMMENT 'account id (auth.account.id)',
    `vip_rank`   TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'VIP rank 0..10',
    `vip_expiry` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'unix expiry, 0=permanent',
    `flags`      INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'reserved bitmask',
    PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;