-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0062_spellaio_tomes.sql  (acore_characters)
--
-- Свитки спеллов для SpellAIO. Единый свиток-контейнер entry 70060
-- «Свиток Пустоты»: при превышении лимита изученных (MAX_CUSTOM_SPELLS)
-- или при unlearn игрок получает свиток, а выбранный/снятый спелл
-- откладывается в realm_custom_spell_pending. При использовании свитка
-- (RegisterItemEvent ON_USE=2, lua_scripts/SpellAIO/server.lua) спелл
-- изучается без повторного окна выбора.
--
-- НЕ создаём item на каждый из 1892 спеллов пула — свиток единый,
-- конкретный спелл берётся из realm_custom_spell_pending по персонажу.
--
-- ПРИМЕНЯЕТСЯ К acore_characters (пер-персональные данные).
-- ============================================================

-- Очередь отложенных спеллов к изучению через свиток.
CREATE TABLE IF NOT EXISTS `realm_custom_spell_pending` (
    `characterGUID` INT(11) NOT NULL,
    `spellID`       INT(11) NOT NULL,
    `createdAt`     DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`characterGUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- NOTE: сам item 70060 создаётся в acore_world (item_template).
-- Этот файл отвечает только за пер-персональную таблицу pending.