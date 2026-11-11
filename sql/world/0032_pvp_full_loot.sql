-- ============================================================
-- 0032_pvp_full_loot.sql — Full-Loot PvP: сундук «Добыча войны»
--
-- Фаза PvP-loss: выпадение предметов и золота жертвы при PvP-килле
-- в открытом мире (потребляет 31_PvpFullLoot.lua). Референс:
-- Youpeoples/Ultimate-Full-Loot-Pvp — там сундук создаётся в рантайме;
-- по конвенциям реалма — только миграцией.
--
-- Сундук: gameobject entry 700020 (диапазон 70xxx, объект, не НПС),
-- тип 3 (GO_CHEST), displayId 259 (стандартный сундук, как в референсе).
-- Data0 = 1634 (лоут-ид 1, режим OPEN + lootable) — совпадает с референсом.
-- Кнопка: пусто — сундук открывается кликом (DON'T need cast bar).
--
-- Идемпотентно: INSERT IGNORE.
-- ============================================================

SET NAMES utf8mb4;

INSERT IGNORE INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
 `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`,
 `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`,
 `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(700020, 3, 259, 'Добыча войны', '', '', '', 1,
 1634, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0);