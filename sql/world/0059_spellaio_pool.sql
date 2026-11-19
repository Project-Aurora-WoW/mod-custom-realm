-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0059_spellaio_pool.sql  (acore_world)
--
-- Наполнение пула выбора кастомных спеллов (SpellAIO). Выполняется ПОСЛЕ
-- 0058_custom_spell_system.sql (создаёт таблицы realm_custom_spell_*).
--
-- В пул входят только спеллы, реально существующие в нашем spell_dbc и в
-- клиентском патче реалма (клиент их отображает через GetSpellInfo):
--   * 70050 «Пустотная порча»  — установлен в 0058 (маркер/счётчик порчи);
--   * 90515–90521 — кастуемые археологические спеллы mod-archaeology
--     (урон/хил/бафф/утилита), присутствуют в server spell_dbc и в патче.
--
-- Категории: 1=Damage, 2=Healing, 3=Buff, 4=Utility (числовые коды;
-- тексты локализованы в lua_scripts/SpellAIO/client.lua, ru/en).
-- ============================================================

-- Каталог спеллов (идемпотентно: сброс затем полная вставка).
DELETE FROM `realm_custom_spell_system`;
INSERT INTO `realm_custom_spell_system` (`id`, `spellID`, `spellName`, `spellLevel`) VALUES
    (1,  70050, 'Пустотная порча',              10),  -- 0018, маркер/счётчик порчи (Damage)
    (2,  90515, 'Thaurissan''s Ember',           10),  -- огненный урон (Damage)
    (3,  90516, 'Highborne Focus',               10),  -- восстановление силы (Utility)
    (4,  90517, 'Zandalari Vigor',               10),  -- хаст (Buff)
    (5,  90518, 'Amber Ward',                    10),  -- абсорб-щит (Buff)
    (6,  90519, 'Light of the Naaru',            10),  -- исцеление (Healing)
    (7,  90520, 'Ahn''kahar Venom',              10),  -- природный урон, стаки (Damage)
    (8,  90521, 'Val''kyr''s Mercy',             10);  -- пережить смертельный удар (Utility)

-- Категории для добавленных спеллов.
DELETE FROM `realm_custom_spell_categories`;
INSERT INTO `realm_custom_spell_categories` (`spellID`, `category`) VALUES
    (70050, 1),   -- Damage
    (90515, 1),   -- Damage
    (90520, 1),   -- Damage
    (90519, 2),   -- Healing
    (90517, 3),   -- Buff
    (90518, 3),   -- Buff
    (90516, 4),   -- Utility
    (90521, 4);   -- Utility