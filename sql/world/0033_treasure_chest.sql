-- ============================================================
-- 0033_treasure_chest.sql — Сундуки Пустоты (Solo treasure chests)
--
-- Фаза: GM-система сундуков-сокровищ (референс zyggy123/Treasure-Chest-System,
-- AGPL-3.0). Потребляет 32_TreasureChest.lua.
--
-- В acore_world:
--   • gameobject 700021 «Сундук Пустоты» (type 3 GO_CHEST, displayId 8686);
--   • таблицы custom_treasure_chest_loot / _config / _spawn —
--     лут, подсказки и золото сундука (GM-управляемые).
--
-- Идемпотентно (INSERT IGNORE / CREATE TABLE IF NOT EXISTS).
-- ============================================================

SET NAMES utf8mb4;

-- ---- 1. Сундук ----
INSERT IGNORE INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
 `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`,
 `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`,
 `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(700021, 3, 8686, 'Сундук Пустоты', '', '', '', 1,
 1634, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0);

-- ---- 2. Таблицы ----
CREATE TABLE IF NOT EXISTS `custom_treasure_chest_loot` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `item_entry` INT UNSIGNED NOT NULL DEFAULT 0,
  `min_count`  INT UNSIGNED NOT NULL DEFAULT 1,
  `max_count`  INT UNSIGNED NOT NULL DEFAULT 1,
  `chance`     FLOAT NOT NULL DEFAULT 100,
  `comment`    VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Сундук Пустоты: лут';

CREATE TABLE IF NOT EXISTS `custom_treasure_chest_config` (
  `config_key`   VARCHAR(64) NOT NULL,
  `config_value` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Сундук Пустоты: золото и подсказки';

INSERT IGNORE INTO `custom_treasure_chest_config` (`config_key`, `config_value`) VALUES
  ('gold_amount', '0'),
  ('hint', '');

CREATE TABLE IF NOT EXISTS `custom_treasure_chest_spawn` (
  `id`      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `map_id`  INT UNSIGNED NOT NULL DEFAULT 0,
  `pos_x`   FLOAT NOT NULL DEFAULT 0,
  `pos_y`   FLOAT NOT NULL DEFAULT 0,
  `pos_z`   FLOAT NOT NULL DEFAULT 0,
  `pos_o`   FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Сундук Пустоты: точки спавна (резерв)';