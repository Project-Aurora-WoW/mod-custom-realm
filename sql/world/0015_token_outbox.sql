-- ============================================================
-- 0015_token_outbox.sql
-- Outbox-механизм выдачи Жетонов Эха (паттерн wow-mod-delves:
-- durable intent + receipts, антимультифарм).
--
-- Мотивация (референс data/sql/characters/2026_10_28_01_delves_rewards.sql):
-- прямое AddItem при событии теряет награду при рестарте между
-- событием и выдачей; outbox хранит намерение до подтверждённой
-- доставки и не даёт одному событию заплатить дважды.
--
-- Первые источники намерений:
--   echo-pvp  — «Месть Эха» не участвует (это бафф), но жетоны
--               за килл в зоне могут переноситься в outbox;
--   echo-pve  — дроп Жетона Эха с пустотных существ (кулдаун
--               остаётся; outbox добавляет durable-гарантию).
-- ============================================================
-- Отложенные награды: одно намерение = один платёж.
-- reward_key уникален (формат '<source>:<guid>:<event_id>:<salt>'),
-- повторная попытка с тем же ключом не создаёт дубликат.
CREATE TABLE IF NOT EXISTS `realm_token_outbox` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `reward_key`   CHAR(64)  CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `guid`         INT UNSIGNED NOT NULL,
  `account`      INT UNSIGNED NOT NULL,
  `tokens`       INT UNSIGNED NOT NULL,
  `reason`       VARCHAR(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `created_at`   INT UNSIGNED NOT NULL DEFAULT 0,
  `delivered`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reward_key` (`reward_key`),
  KEY `pending_member` (`guid`, `delivered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Outbox наград реалма (жетоны Эха): durable intent + delivery';

-- Квитанции доставки: факт + время; используется для аудита и
-- идемпотентной повторной доставки (как в delfes: Paid/AlreadyPaid).
CREATE TABLE IF NOT EXISTS `realm_token_receipt` (
  `reward_key`   CHAR(64)  CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `guid`         INT UNSIGNED NOT NULL,
  `tokens`       INT UNSIGNED NOT NULL,
  `delivered_at` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`reward_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Квитанции выдачи Жетонов Эха (realm_token_outbox)';
