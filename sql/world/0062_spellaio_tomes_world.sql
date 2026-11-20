-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0062_spellaio_tomes_world.sql  (acore_world)
--
-- Свиток-контейнер «Свиток Пустоты» (item 70060) для SpellAIO.
--
-- Единый свиток на всех: при превышении лимита изученных или при unlearn
-- игроку выдаётся свиток, а конкретный спелл откладывается в
-- realm_custom_spell_pending (acore_characters, 0062_characters).
-- При использовании свитка (RegisterItemEvent ON_USE=2, server.lua) спелл
-- изучается. Предмет не имеет собственного spellid — логика в Lua.
--
-- Entry 70060 свободен (заняты 70001–70008, 70100/70101 и др.).
-- ============================================================

DELETE FROM `item_template` WHERE `entry` = 70060;
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`,
 `BuyPrice`, `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`,
 `ItemLevel`, `RequiredLevel`, `Material`, `bonding`, `description`, `Stackable`, `maxcount`)
VALUES
(70060, 12, -1, 'Свиток Пустоты', 7020, 3, 0,
 0, 0, 0, -1, -1,
 1, 1, -1, 1,
 'Хранит выбранный кастомный спелл Пустоты. Используйте, чтобы изучить его после освобождения места.', 20, 0);