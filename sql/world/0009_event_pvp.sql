-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0009_event_pvp.sql
-- Назначение: контент ивентов и PvP-системы:
--   item 70005 — «Жетон Эха» (валюта ивентов и PvP-зоны)
--   таблица realm_pvp_stats — PvP-статистика игроков
-- ВНИМАНИЕ: realm_pvp_stats применяется в acore_characters
-- (скрипты читают через CharDBQuery), см. docs/deployment.md.
-- ============================================================

-- --- 1. Предмет «Жетон Эха» (world-БД) -----------------------
DELETE FROM `item_template` WHERE `entry` = 70005;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `soundoverridesubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`, `StatsCount`,
 `ScalingStatDistribution`, `ScalingStatValue`, `armor`,
 `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
 `delay`, `ammo_type`, `RangedModRange`, `bonding`, `description`,
 `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
 `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`,
 `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`,
 `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(70005, 12, 0, -1, 'Жетон Эха', 38625,
 3, 32768, 0, 1, 0, 0,
 0, -1, -1, 80, 0,
 0, 0, 0, 0,
 0, 0, 0,
 0, 20, 0, 0,
 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Валюта Ордена Рассвета. Добывается в ивентах реалма и в PvP-зоне Драконьего Погоста.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 12340);

-- --- 2. PvP-статистика (ПРИМЕНЯТЬ В acore_characters!) ------
-- Выполнять: mysql -u <user> -p acore_characters < 0009_event_pvp.sql
-- (таблица item_template выше при этом не применится — создайте отдельно
--  в acore_world, либо примените файл дважды в обе БД; INSERT идемпотентен)
CREATE TABLE IF NOT EXISTS `realm_pvp_stats` (
  `guid`           INT UNSIGNED NOT NULL COMMENT 'GUID игрока (characters.guid)',
  `kills`          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Всего PvP-убийств (зачётные)',
  `deaths`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Смертей от игроков (зачётных)',
  `streak`         INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Текущая серия убийств',
  `best_streak`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Лучшая серия',
  `zone_kills`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Киллов в PvP-зоне (Драконий Погост)',
  `tokens_earned`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Жетонов Эха заработано в PvP',
  `last_victim`    INT UNSIGNED NULL COMMENT 'GUID последней жертвы (анти-фарм)',
  `last_kill_time` INT UNSIGNED NULL COMMENT 'Время последнего зачётного килла (unix)',
  `updated_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'PvP-статистика реалма Эхо Пустоты';