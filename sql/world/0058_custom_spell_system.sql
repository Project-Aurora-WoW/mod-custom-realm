-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0058_custom_spell_system.sql  (acore_world)
--
-- Система выбора спеллов (порт SpellAIO из WaloriaOld/scripts/SpellAIO,
-- адаптация под конвенции реалма). Игрок получает окно выбора 1 из 4
-- случайных спеллов заданной категории и может «работать» с ними
-- (обучение / возврат в свиток). Не использует 2036 спеллов Waloria —
-- только кастомные спеллы реалма (spell_dbc 70xxx, пополняется).
--
-- Структура повторяет оригинал (custom_spell_system*), но:
--   * таблицы переименованы под префикс реалма realm_custom_spell_*;
--   * category_choices/choices — на acore_characters (пер-персонаж);
--   * категории локализованы в Lua (ru/en), здесь только числовые коды.
-- ============================================================

-- ------------------------------------------------------------
-- МИР (acore_world)
-- ------------------------------------------------------------

-- Каталог кастомных спеллов, доступных для выбора.
DROP TABLE IF EXISTS `realm_custom_spell_system`;
CREATE TABLE `realm_custom_spell_system` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `spellID`     INT(11) NOT NULL,
    `spellName`   VARCHAR(64) NOT NULL,
    `spellLevel`  INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `spellID` (`spellID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Привязка спелла к категории (1=Damage, 2=Healing, 3=Buff, 4=Utility).
DROP TABLE IF EXISTS `realm_custom_spell_categories`;
CREATE TABLE `realm_custom_spell_categories` (
    `spellID` INT(11) NOT NULL,
    `category` TINYINT(4) NOT NULL,
    PRIMARY KEY (`spellID`, `category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Наполнение (начальное): кастомные спеллы реалма, доступные для выбора.
-- Здесь добавляем подтверждённые кастомные спеллы 70xxx. Пополняется по мере
-- добавления новых spell_dbc в кампании.
DELETE FROM `realm_custom_spell_system`;
INSERT INTO `realm_custom_spell_system` (`id`, `spellID`, `spellName`, `spellLevel`) VALUES
    (1, 70050, 'Пустотная порча', 10);  -- spell_dbc (0018), дебафф/счётчик

-- Категории выбора для уже добавленных спеллов.
DELETE FROM `realm_custom_spell_categories`;
INSERT INTO `realm_custom_spell_categories` (`spellID`, `category`) VALUES
    (70050, 1);  -- Damage

-- ------------------------------------------------------------
-- ПЕРСОНАЖИ (acore_characters)
-- ------------------------------------------------------------

-- Очередь выбора спелла конкретного персонажа (из оригинального
-- custom_spell_system_choices). characterGUID = characters.guid.
DROP TABLE IF EXISTS `realm_custom_spell_choices`;
CREATE TABLE `realm_custom_spell_choices` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `characterGUID` INT(11) NOT NULL,
    `spellID1`    INT(11) NOT NULL,
    `spellID2`    INT(11) NOT NULL,
    `spellID3`    INT(11) NOT NULL,
    `spellID4`    INT(11) NOT NULL,
    `level`       INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `characterGUID` (`characterGUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Выбранная категория персонажа на определённом уровне.
DROP TABLE IF EXISTS `realm_custom_spell_category_choices`;
CREATE TABLE `realm_custom_spell_category_choices` (
    `id`            INT(11) NOT NULL AUTO_INCREMENT,
    `characterGUID` INT(11) NOT NULL,
    `level`         INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `characterGUID` (`characterGUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Изученные персонажем кастомные спеллы (замена C++-метода
-- GetCustomSpellAmount/UpdateCustomSpellAmount из Waloria — считаем на Lua).
DROP TABLE IF EXISTS `realm_custom_spell_learned`;
CREATE TABLE `realm_custom_spell_learned` (
    `characterGUID` INT(11) NOT NULL,
    `spellID`       INT(11) NOT NULL,
    `learnedAt`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`characterGUID`, `spellID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;