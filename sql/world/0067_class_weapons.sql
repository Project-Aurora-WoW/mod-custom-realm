-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 0067_class_weapons.sql  (acore_world)
--
-- Классовое оружие «Эха Пустоты»: по одному эпическому оружию
-- на ключевой класс (эндгейм ilvl~245, качество 4). П.2: описание,
-- статы, визуализация, совместимость с трансмогрификацией.
--
-- Дизайн (9 классов, entry 70061..70069):
--   * AllowableClass — битовая маска класса (см. дизайн ниже).
--   * class 2 (оружие), subclass: 1=1H меч, 4=булава, 3=лук,
--     8/10=посох 2H, 13=кинжал.
--   * Статы — stat_type1..10 + dmg_min/dmg_max + delay.
--   * description — лор-описание (ru/en через item_template_locale).
--   * displayid — уникальные модели оружия (визуализация в руке/на
--     спине у 2H); трансмог работает без патчей (стоковый Binding
--     с ты — предмет бросается/одаривается, и мод-transmog применяет).
--
-- Маски классов (AllowableClass):
--   1 Воин | 2 Паладин | 4 Охотник | 8 Разбойник | 16 Жрец |
--   32 Рыцарь смерти | 64 Шаман | 128 Маг | 256 Чернокнижник | 1024 Друид
--
-- Идемпотентно: DELETE+INSERT.
-- ============================================================

DELETE FROM `item_template` WHERE `entry` BETWEEN 70061 AND 70069;
DELETE FROM `item_template_locale` WHERE `ID` BETWEEN 70061 AND 70069;

INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`,
 `Quality`, `Flags`, `FlagsExtra`, `BuyCount`, `BuyPrice`, `SellPrice`,
 `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `RequiredSkill`, `RequiredSkillRank`, `requiredspell`, `requiredhonorrank`,
 `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
 `maxcount`, `stackable`, `ContainerSlots`,
 `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`,
 `stat_type3`, `stat_value3`, `stat_type4`, `stat_value4`,
 `stat_type5`, `stat_value5`, `stat_type6`, `stat_value6`,
 `stat_type7`, `stat_value7`, `stat_type8`, `stat_value8`,
 `stat_type9`, `stat_value9`, `stat_type10`, `stat_value10`,
 `ScalingStatDistribution`, `ScalingStatValue`,
 `dmg_min1`, `dmg_max1`, `dmg_type1`, `dmg_min2`, `dmg_max2`, `dmg_type2`,
 `armor`, `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
 `delay`, `ammo_type`, `RangedModRange`,
 `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
 `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`,
 `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`,
 `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`,
 `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`,
 `bonding`, `description`, `PageText`, `LanguageID`, `PageMaterial`, `startquest`, `lockid`, `Material`, `sheath`,
 `RandomProperty`, `RandomSuffix`, `block`, `itemset`, `MaxDurability`, `area`, `Map`,
 `BagFamily`, `TotemCategory`, `socketColor_1`, `socketContent_1`,
 `socketColor_2`, `socketContent_2`, `socketColor_3`, `socketContent_3`,
 `socketBonus`, `GemProperties`, `RequiredDisenchantSkill`, `ArmorDamageModifier`,
 `duration`, `ItemLimitCategory`, `HolidayId`, `ScriptName`, `DisenchantID`,
 `FoodType`, `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`, `VerifiedBuild`)
VALUES
-- Рыцарь смерти (маска 32) — двуручный меч, 2H (InvType 17)
(70061, 2, 8, -1, 'Лезвие Забвения Рыцаря', 58923,
  4, 0, 0, 1, 1800000, 450000, 17, 32, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  38, 45, 7, 55, 45, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 620, 840, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 3600, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Лезвие, высеченное из осколка Трона в Драконьем Погосте. Шёпот разлома угасает в его стали.', 0,0,0,0,0, 1, 4,
  0, 0, 0, 0, 120, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Воин (маска 1) — одноручный меч (InvType 21)
(70062, 2, 1, -1, 'Варварский Клинок Ордена', 52921,
  4, 0, 0, 1, 1200000, 300000, 21, 1, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  7, 50, 38, 45, 31, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 390, 590, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 2600, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Клинок легионеров Ордена, сражавшихся у разлома. Выкован для тех, кто держит строй.', 0,0,0,0,0, 1, 3,
  0, 0, 0, 0, 105, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Паладин (маска 2) — одноручная булава (InvType 21)
(70063, 2, 4, -1, 'Молот Света Стража', 53062,
  4, 0, 0, 1, 1100000, 275000, 21, 2, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  5, 50, 7, 40, 6, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 370, 550, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 2400, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Молот паладинов Ордена Света, благословлённый в часовне Даларана против тварей Пустоты.', 0,0,0,0,0, 2, 3,
  0, 0, 0, 0, 100, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Охотник (маска 4) — лук (InvType 26)
(70064, 2, 3, -1, 'Лук Преследователя Пустоты', 55847,
  4, 0, 0, 1, 1300000, 325000, 26, 4, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  3, 45, 31, 35, 49, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 460, 660, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 2900, 2, 100,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Лук следопытов, что прочёсывают Морзу и Предательство. Тетива звенит голосом разлома.', 0,0,0,0,0, 2, 0,
  0, 0, 0, 0, 90, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Разбойник (маска 8) — кинжал (InvType 21)
(70065, 2, 13, -1, 'Кинжал Шепота Теней', 52918,
  4, 0, 0, 1, 800000, 200000, 21, 8, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  3, 40, 31, 30, 45, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 300, 460, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 1800, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Кинжал теневых убийц Культа, обращённый против своих хозяев. Не отражает света.', 0,0,0,0,0, 1, 3,
  0, 0, 0, 0, 75, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Жрец (маска 16) — посох 2H (InvType 17)
(70066, 2, 8, -1, 'Посох Проклятых Литаний', 59506,
  4, 0, 0, 1, 1500000, 375000, 17, 16, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  5, 60, 7, 45, 6, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 500, 700, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 3200, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Посох жрецов, читающих литании умирающих. Сталь помнит каждое проклятие разлома.', 0,0,0,0,0, 2, 1,
  0, 0, 0, 0, 115, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Шаман (маска 64) — одноручная булава (InvType 21)
(70067, 2, 4, -1, 'Молот Бури Элементов', 55225,
  4, 0, 0, 1, 1100000, 275000, 21, 64, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  5, 50, 7, 40, 36, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 370, 550, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 2400, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Молот, в котором бушуют четыре стихии. Заклинатели стихий Драконьего Погоста ковали его в буре.', 0,0,0,0,0, 2, 3,
  0, 0, 0, 0, 100, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Маг (маска 128) — посох 2H (InvType 17)
(70068, 2, 8, -1, 'Скипетр Арканы Бездны', 59504,
  4, 0, 0, 1, 1500000, 375000, 17, 128, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  5, 65, 7, 45, 42, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 500, 700, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 3000, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Скипетр, направляющий аркану сквозь ткань Пустоты. Создан магами Даларана в час нужды.', 0,0,0,0,0, 2, 1,
  0, 0, 0, 0, 110, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340),
-- Чернокнижник (маска 256) — посох 2H (InvType 17)
(70069, 2, 8, -1, 'Жезл Скверны Культа', 59446,
  4, 0, 0, 1, 1500000, 375000, 17, 256, -1, 245, 80,
  0, 0, 0, 0, 0, 0, 0,
  0, 1, 0,
  5, 60, 7, 45, 43, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 500, 700, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 3000, 0, 0,
  0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1, 0,0,0,0,-1,0,-1,
  1, 'Жезл чернокнижников Культа, сдерживающий демонов разлома. Питается жертвенной силой.', 0,0,0,0,0, 1, 1,
  0, 0, 0, 0, 110, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, '', 0, 0, 0, 0, 0, 12340);

-- --- Английские локализации (item_template_locale) ---
INSERT INTO `item_template_locale` (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`) VALUES
(70061, 'enUS', 'Death Knight Blade of Oblivion', 'A blade carved from a shard of the Throne in Dragonblight. The rift whisper fades in its steel.', 12340),
(70062, 'enUS', 'Barbaric Order Blade', 'A blade of Order legionaries who fought at the rift. Forged for those who hold the line.', 12340),
(70063, 'enUS', 'Light of the Guardian Mace', 'A paladin mace of the Order of Light, blessed in Dalaran against Void creatures.', 12340),
(70064, 'enUS', 'Void Stalker Bow', 'A bow of rangers scouring Morzath and Betrayal. The string rings with the rift voice.', 12340),
(70065, 'enUS', 'Whisper of Shadows Dagger', 'A dagger of the cult shadow assassins, turned against their masters. Reflects no light.', 12340),
(70066, 'enUS', 'Staff of Cursed Litany', 'A staff of priests reading litanies of the dying. The steel remembers every curse of the rift.', 12340),
(70067, 'enUS', 'Mace of Elemental Storm', 'A mace where four elements rage. Elemental summoners of Dragonblight forged it in the storm.', 12340),
(70068, 'enUS', 'Sceptre of the Void Arcana', 'A sceptre guiding arcana through the Void cloth. Created by Dalaran mages in their hour of need.', 12340),
(70069, 'enUS', 'Cult Fel Staff', 'A staff of the cult warlocks, binding rift demons. Feeds on sacrificial power.', 12340);