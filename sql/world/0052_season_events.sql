-- ============================================================
-- 0052_season_events.sql
-- Система сезонных эвентов (п.5): надстройка над авто-ивентами.
--   Items: 70019-70026 — сезонная валюта (календарные сезоны + праздники)
--   Таблица: realm_season_state (acore_characters) — состояние игрока в
--   ежегодном сезоне с этапами (личный прогресс этапа).
-- Механика: 48_SeasonEvents.lua определяет активный сезон/праздник/этап,
-- даёт доп. жетоны (token_mult) поверх авто-ивентов и сезонную валюту.
-- СХЕМА: AzerothCore 3.3.5. Идемпотентна (DELETE+INSERT/REPLACE).
-- Lua — 48_SeasonEvents.lua; реестр — 00_CampaignRegistry.ext (season_events).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Сезонная валюта (70019-70026)
-- ------------------------------------------------------------
DELETE FROM `item_template` WHERE `entry` BETWEEN 70019 AND 70026;

-- Общая заготовка: валюта (class 12), эпик (Quality 5), макс-стак 1000
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `soundoverridesubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`, `armor`,
 `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
 `delay`, `ammo_type`, `RangedModRange`, `bonding`, `description`,
 `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
 `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`,
 `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`,
 `socketColor_2`, `socketContent_2`,
 `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
(70019, 12, 0, -1, 'Северная Печать Наследия', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Сезонная валюта «Буря Наследия» (зима). Добывается за активность в ивентах во время зимнего сезона.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70020, 12, 0, -1, 'Лепесток Цветения Пустоты', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Сезонная валюта «Цветение Пустоты» (весна). Добывается за активность в ивентах весной.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70021, 12, 0, -1, 'Пепел Середины Лета', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Сезонная валюта «Пепел Середины Лета» (лето). Добывается за активность в ивентах летом.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70022, 12, 0, -1, 'Слеза Урожая Ложных Слёз', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Сезонная валюта «Урожай Ложных Слёз» (осень). Добывается за активность в ивентах осенью.',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70023, 12, 0, -1, 'Хрустальный Осколок Полуночи', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Праздничная валюта «Хрустальный Полночь Наследия» (1 января).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70024, 12, 0, -1, 'Цветок Пробуждения Ордена', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Праздничная валюта «Пробуждение Ордена» (8 марта).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70025, 12, 0, -1, 'Уголь Ночных Костров', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Праздничная валюта «Ночь Костров Пустоты» (21 июня).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340),
(70026, 12, 0, -1, 'Душа Урожая Душ', 64452,
 5, 32768, 0, 1, 0, 0,
 0, -1, -1, 1, 80,
 0, 0, 0, 0,
 0, 0, 0,
 0, 1000, 0, 0,
 0, 0, 0, 0, 0, 0,
 0, 0, 0, 1,
 'Праздничная валюта «Урожай Душ» (31 октября).',
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0,
 0, 0, 0, 0, '', 0,
 0, 0, 0, 0, 0, 12340);

-- ------------------------------------------------------------
-- 2. Таблица состояния игрока в ежегодном сезоне
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `realm_season_state` (
  `guid`         INT UNSIGNED NOT NULL COMMENT 'character guid',
  `year`         SMALLINT UNSIGNED NOT NULL COMMENT 'год ежегодного сезона (Цикл Осколка)',
  `stage`        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'текущий этап (1..N)',
  `stage_xp`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'прогресс внутри этапа',
  `season_item`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'активная сезонная валюта (item entry)',
  `updated_at`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`, `year`)
)
ENGINE = InnoDB
DEFAULT CHARSET = utf8mb4
COMMENT = 'Состояние игрока в ежегодном сезоне (acore_characters)';