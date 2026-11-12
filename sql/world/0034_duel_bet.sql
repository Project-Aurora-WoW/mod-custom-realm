-- ============================================================
-- 0034_duel_bet.sql — Ставки на дуэли (Duel Bet)
--
-- Референс: zyggy123/mod-duel-bet (AGPL-3.0).
-- Адаптация под реалм «Эхо Пустоты»: порт на ALE (33_DuelBet.lua).
-- Таблицы размещаются в acore_characters (как в референсе).
-- Идемпотентно: CREATE TABLE IF NOT EXISTS.
-- ============================================================

-- Ставка на дуэль (эскроу). status:
--   0 = ожидает принятия (деньги challenger удержаны)
--   1 = принято (деньги обоих удержаны, дуэль не началась)
--   2 = дуэль идёт (деньги обоих залочены)
CREATE TABLE IF NOT EXISTS `duel_bets` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player1_guid` INT UNSIGNED NOT NULL DEFAULT 0,  -- challenger
    `player2_guid` INT UNSIGNED NOT NULL DEFAULT 0,  -- opponent
    `amount`      INT UNSIGNED NOT NULL DEFAULT 0,   -- медь (с каждой стороны)
    `status`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_p1` (`player1_guid`),
    KEY `idx_p2` (`player2_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Статистика ставок игрока (матчи/победы/нет-прибыль в меди).
CREATE TABLE IF NOT EXISTS `duel_bet_stats` (
    `guid`         INT UNSIGNED NOT NULL,
    `total_duels`  INT UNSIGNED NOT NULL DEFAULT 0,
    `total_won`    INT UNSIGNED NOT NULL DEFAULT 0,
    `total_profit` INT NOT NULL DEFAULT 0,           -- может быть отрицательным
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;