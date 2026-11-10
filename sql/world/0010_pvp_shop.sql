-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Migration: 0010_pvp_shop.sql
-- Назначение: НПС «Интендант Ордена» (70170) — PvP-шоп за
-- Жетоны Эха (item 70005). Ассортимент задаётся в
-- lua_scripts/30_PvpShop.lua (из реестра 00_CampaignRegistry.lua).
-- Спавн: Даларан, площадка Ордена Рассвета.
-- ============================================================

-- --- 1. Шаблон НПС ------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 70170;
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`,
 `faction`, `minhealth`, `maxhealth`, `rank`, `npcflag`, `speed_walk`, `speed_run`,
 `unit_flags`, `unit_flags2`, `type`, `type_flags`, `family`, `trainer_type`,
 `trainer_spell`, `trainer_class`, `trainer_race`, `mingold`, `maxgold`, `AIName`,
 `MovementType`, `InhabitType`, `HoverHeight`, `HealthModifier`, `ManaModifier`,
 `ArmorModifier`, `DamageModifier`, `RangedModifier`, `unit_class`, `mechanic_immune_mask`,
 `flags_extra`, `VerifiedBuild`)
VALUES
(70170, 'Интендант Ордена', '<Снабжение за Жетоны Эха>', 'Vendor', 0, 80, 80,
 35, 1000000, 1000000, 1, 1, 1.0, 1.14286,
 33554432, 2048, 7, 0, 0, 0,
 0, 0, 0, 0, 0, '',
 0, 3, 1.0, 1.0, 1.0,
 1.0, 1.0, 2, 0,
 0, 0, 0, 12340);

-- --- 2. Спавн (Даларан) -------------------------------------
DELETE FROM `creature` WHERE `id` = 70170;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
 `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `curenergy`, `curpower`,
 `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `VerifiedBuild`)
VALUES
(7000170, 70170, 571, 4395, 4395, 1, 1, 0,
 5818.60, 686.20, 657.55, 4.10,
 300, 0, 1000000, 0, 0, 0, 0, 0, 0, 0, 12340);