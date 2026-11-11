-- ============================================================
-- 0021_public_scripts.sql — системы из public-scripts (JadaDev)
--
-- Референс: m-orlovrus59/public-scripts:
--   • PlayedTime_RewardSystem (награды за наигранное время) —
--     портировано на ALE в 19_PlayedTimeRewards.lua (вместо C++)
--   • FactionChange — 21_FactionChanger.lua (НПС 70174)
--   • Sanctuary_PvP_Area_Zone — 22_SanctuaryPvP.lua (списки в скрипте)
--
-- ПЕРЕМЕНЫ ПРОТИВ ОРИГИНАЛА:
--   • reward_played_time/reward_system → realm_played_time_rewards +
--     realm_played_time_rewards_claimed (PK, REPLACE-идемпотентность),
--     префикс realm_ и колонки message_ru/message_en
--   • TokenID 55555 → Жетон Эха 70005 (item реалма), цена 25 шт.
--   • НПС 70000 → 70174 «Страж Перемен» (guid 7000174, Даларан)
--
-- ДВОЙНОЕ ПРИМЕНЕНИЕ (как 0018):
--   mysql -u root -p acore_characters < 0021_public_scripts.sql
--   mysql -u root -p acore_world      < 0021_public_scripts.sql
-- ============================================================

-- ================== ЧАСТЬ 1: acore_characters ==================
-- Таблица наград за наигранное время (seconds → награда)
CREATE TABLE IF NOT EXISTS `realm_played_time_rewards` (
  `id` int unsigned NOT NULL,
  `played_time` int unsigned NOT NULL DEFAULT 0,
  `reward_tokens` int unsigned NOT NULL DEFAULT 0,
  `reward_gold` int unsigned NOT NULL DEFAULT 0,
  `message_ru` varchar(255) NOT NULL DEFAULT '',
  `message_en` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DELETE FROM `realm_played_time_rewards`;
-- Пороги реалма (порт демо-данных JadaDev на экономику жетонов)
INSERT INTO `realm_played_time_rewards`
    (`id`, `played_time`, `reward_tokens`, `reward_gold`, `message_ru`, `message_en`) VALUES
    (1, 1800,   2,  0,   '30 минут в мире Эха! Орден благодарит вас — 2 Жетона Эха.',
                          '30 minutes in the world of the Echo! The Order thanks you — 2 Echo Tokens.'),
    (2, 9000,   5,  50000000, '2.5 часа в мире Эха! Награда: 5 Жетонов Эха и 500 золота.',
                          '2.5 hours in the world of the Echo! Reward: 5 Echo Tokens and 500 gold.'),
    (3, 86400,  10, 0,   'Целый день в мире Эха! Награда: 10 Жетонов Эха.',
                          'A full day in the world of the Echo! Reward: 10 Echo Tokens.');

-- Учёт полученных наград (идемпотентность REPLACE)
CREATE TABLE IF NOT EXISTS `realm_played_time_rewards_claimed` (
  `guid` int unsigned NOT NULL,
  `reward_id` int unsigned NOT NULL,
  `claimed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`,`reward_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ================== ЧАСТЬ 2: acore_world ==================
-- НПС 70174 «Страж Перемен» (смена фракции за Жетоны Эха)
-- displayid: маг человека (штатный 15279 — как служебные НПС Ордена)
DELETE FROM `creature_template` WHERE `entry` = 70174;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
    (70174, 15279, 'Страж Перемен', 'Услуги Ордена Рассвета', 'Speak', 0, 80, 80,
     35, 1, 1.0, 1.14286, 0, 0, 2000, 2000,
     2, 2, 7, '', '', 0);

DELETE FROM `creature` WHERE `guid` = 7000174;
INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `spawndist`, `MovementType`, `VerifiedBuild`)
VALUES
    (7000174, 70174, 571, 4395, 4395, 1, 1,
     5808.94, 694.83, 647.35, 2.85,
     300, 0, 0, 0);
