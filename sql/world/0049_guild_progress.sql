-- ============================================================
-- 0049_guild_progress.sql
-- Система гильдий (п.3): уровни/опыт гильдий поверх стоковых гильдий.
--   Таблица: realm_guild_progress (acore_characters) — прогресс гильдии.
--   Механика: опыт начисляется в 45_GuildProgress.lua за активность
--   членов (PvP, боссы, кампании); уровень растёт по xp_curve из
--   реестра (00_CampaignRegistry.ext, guild).
-- СХЕМА: AzerothCore 3.3.5 (guildId = стоковый guild.id). Идемпотентна.
-- Lua — 45_GuildProgress.lua; реестр — 00_CampaignRegistry.ext (guild).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Таблица прогресса гильдии (acore_characters)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_guild_progress` (
  `guild_id`        INT UNSIGNED NOT NULL COMMENT 'стоковый guild.id',
  `level`           INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'уровень гильдии',
  `xp`              INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'накопленный опыт на уровне',
  `total_xp`        INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'суммарный опыт (за всю жизнь)',
  `last_pvp_ts`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'unix-время последнего PvP-вклада члена',
  `last_campaign_ts` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'unix-время последнего вклада кампании',
  `updated_at`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guild_id`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Прогресс уровня/опыта гильдии (acore_characters)';