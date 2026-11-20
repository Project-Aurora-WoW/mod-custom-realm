-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0063_rai_tables.sql  (acore_world)
--
-- Таблицы RAI (Roaming Adventurer Incursions — странствующие искатели).
-- Порт из WaloriaOld/scripts/RAI/rai.sql, таблицы переименованы под
-- префикс реалма realm_rai_*.
--
-- Что входит (из rai.sql, только rai_*; custom_* — уже адаптированы в
-- 0058..0062 как realm_custom_spell_*):
--   * rai_creature       -> realm_rai_creature        (пуск: список entry
--                                                        искателей, заполняется runtime)
--   * rai_line_spawns    -> realm_rai_line_spawns     (лимки: точки спавна линии)
--   * rai_line_moveto    -> realm_rai_line_moveto     (точки движения линии)
--   * rai_spawns         -> realm_rai_spawns          (отдельные спавны, пусто в дампе)
--   * rai_zone_level     -> realm_rai_zone_level      (минимакс-уровни по зонам)
--
-- Данные — как в исходном дампе (rai_zone_level 46 записей,
-- rai_line_spawns 13, rai_line_moveto 12; creature/spawns пусты).
-- ============================================================

-- ------------------------------------------------------------
-- realm_rai_zone_level: уровень искателей по зонам
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `realm_rai_zone_level`;
CREATE TABLE `realm_rai_zone_level` (
  `zone`     int(11) DEFAULT NULL,
  `minlevel` int(11) DEFAULT '5',
  `maxlevel` int(11) DEFAULT '10'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `realm_rai_zone_level` (`zone`, `minlevel`, `maxlevel`) VALUES
  (12,   5, 12), (40,  11, 21), (10,  20, 30), (33, 30, 40), (41, 45, 60),
  (4,   50, 54), (8,   33, 42), (44,  14, 24), (46, 52, 60), (3,  33, 43),
  (51,  38, 48), (1,    5, 12), (38,  12, 22), (11, 19, 32), (45, 32, 44),
  (47,  38, 48), (267, 20, 30), (130, 10, 20), (85,  5, 10), (28, 50, 55),
  (139, 55, 60), (3433,10, 20), (3430, 5, 10), (3525,10, 20), (3524,5, 10),
  (141,  5, 10), (148, 10, 22), (493,  5, 60), (618,52, 60), (361, 44, 54),
  (331, 20, 32), (16,  44, 54), (406, 22, 28), (405, 33, 40), (17,  10, 22),
  (14,   5, 10), (215,  5, 10), (357, 38, 48), (400,23, 33), (1377,55, 60),
  (490, 46, 54), (440, 33, 46), (1477,55, 60), (25,  55, 60), (36,  32, 38),
  (15,  32, 42);

-- ------------------------------------------------------------
-- realm_rai_creature: registry искателей (entry). Пуст в дампе.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `realm_rai_creature`;
CREATE TABLE `realm_rai_creature` (
  `creature_entry` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------
-- realm_rai_spawns: отдельные спавны. Пусто в дампе.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `realm_rai_spawns`;
CREATE TABLE `realm_rai_spawns` (
  `creature_entry` int(11) DEFAULT NULL,
  `map`     int(11) DEFAULT NULL,
  `zone`    int(11) DEFAULT NULL,
  `area`    int(11) DEFAULT NULL,
  `x`       float DEFAULT NULL,
  `y`       float DEFAULT NULL,
  `z`       float DEFAULT NULL,
  `o`       float DEFAULT NULL,
  `osTime`  int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------
-- realm_rai_line_spawns: точки спавна линий (13 записей).
-- entry 100060 / зона 40 (Западные Королевства), ветки 11/119.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `realm_rai_line_spawns`;
CREATE TABLE `realm_rai_line_spawns` (
  `id`             int(11) NOT NULL AUTO_INCREMENT,
  `creature_entry` int(11) DEFAULT NULL,
  `faction`        int(11) DEFAULT NULL,
  `map`            int(11) DEFAULT NULL,
  `zone`           int(11) DEFAULT NULL,
  `area`           int(11) DEFAULT NULL,
  `x`              float DEFAULT NULL,
  `y`              float DEFAULT NULL,
  `z`              float DEFAULT NULL,
  `o`              float DEFAULT NULL,
  `osTime`         int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8;

INSERT INTO `realm_rai_line_spawns`
  (`id`,`creature_entry`,`faction`,`map`,`zone`,`area`,`x`,`y`,`z`,`o`,`osTime`) VALUES
  (73, 100060, 119, 0, 40,  40, -10384.3,  1190.03, 41.7606, 3.40941, 1480523055),
  (74, 100060,  11, 0, 40, 108, -10482.3,  1163.12,  48.419, 0.252553, 1480523072),
  (75, 100060,  11, 0, 40,  40, -10438.9,  1174.55, 38.9902, 0.259098, 1480523118),
  (77, 100060,  11, 0, 40, 108, -10479.8,  1159.30, 47.7998, 0.292774, 1480523273),
  (78, 100060, 119, 0, 40,  40, -10383.2,  1185.17, 40.7688,  3.3951, 1480523294),
  (79, 100060,  11, 0, 40, 108, -10478.0,  1156.24, 47.2096, 0.240415, 1480523330),
  (80, 100060,  11, 0, 40, 108, -10475.7,  1152.44, 46.5622, 0.277151, 1480523393),
  (81, 100060,  11, 0, 40, 108, -10474.8,  1147.65, 45.9234, 0.375239, 1480523407),
  (82, 100060,  11, 0, 40, 108, -10472.4,  1144.08, 45.2929, 0.305511, 1480523440),
  (83, 100060, 119, 0, 40,  40, -10382.9,  1181.43, 39.9548, 3.39692, 1480523458),
  (84, 100060, 119, 0, 40,  40, -10382.6,  1177.33, 38.9379, 3.38166, 1480523469),
  (85, 100060, 119, 0, 40,  40, -10382.8,  1173.13, 37.9829, 3.44056, 1480523483),
  (86, 100060, 119, 0, 40,  40, -10382.3,  1169.63, 37.3602, 3.38602, 1480523498);

-- ------------------------------------------------------------
-- realm_rai_line_moveto: точки движения линий (12 записей).
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `realm_rai_line_moveto`;
CREATE TABLE `realm_rai_line_moveto` (
  `linespawn` int(11) DEFAULT NULL,
  `x`   float DEFAULT NULL,
  `y`   float DEFAULT NULL,
  `Z`   float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `realm_rai_line_moveto` (`linespawn`, `x`, `y`, `Z`) VALUES
  (73, -10431.5, 1177.06, 40.0895),
  (74, -10438.9, 1174.55, 38.9902),
  (77, -10437.6, 1170.69, 38.6898),
  (78, -10437.6, 1169.94, 38.6969),
  (79, -10437.7, 1166.12, 38.8037),
  (80, -10436.6, 1163.15, 38.7062),
  (81, -10434.9, 1161.98, 38.5041),
  (82, -10435.2, 1155.80, 38.6716),
  (83, -10437.1, 1165.78, 38.7125),
  (84, -10436.8, 1163.82, 38.7109),
  (85, -10435.9, 1156.77, 38.7314),
  (86, -10435.1, 1156.83, 38.6446);