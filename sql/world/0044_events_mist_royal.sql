-- ============================================================
-- 0044_events_mist_royal.sql
-- Мобы ивентов «Туманная аномалия» и «Кровь королей»:
--   70260 Туманный Призрак (ивент mist, обычный моб)
--   70261 Костяной Страж    (ивент royal, элита)
-- Ивенты спавнят мобов ДИНАМИЧЕСКИ через PerformIngameSpawn
-- (10_EventSystem.lua, REG.events.mist/royal) у разлома в Драконьем
-- Погосте, поэтому постоянные spawn-записи в `creature` НЕ создаются —
-- мобы появляются только во время соответствующего ивента.
-- СХЕМА: AzerothCore 3.3.5 (HealthModifier; creature_template_model;
-- creature.id1). Идемпотентна (DELETE+INSERT).
-- Зависимости: 00_CampaignRegistry.ext (events.mist/royal).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. Шаблоны НПС
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` IN (70260, 70261);
INSERT INTO `creature_template`
(`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `dmgschool`, `DamageModifier`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
-- Туманный Призрак: обычный моб туманной аномалии
(70260, 'Туманный Призрак', 'Сгусток тумана у разлома', '', 0, 80, 80, 0, 14, 0, 1.0, 1.14286, 0, 0, 1.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 50.0, 1.0, 1.0, 0, '', 12340),
-- Костяной Страж: элита ивента «Кровь королей»
(70261, 'Костяной Страж', 'Эхо былых королей', '', 0, 82, 82, 0, 14, 0, 1.0, 1.14286, 1, 0, 2.0, 2, 32768, 0, 0, 4, 0, 0, 0, '', 1, 1.0, 150.0, 1.0, 1.0, 0, '', 12340);

-- ------------------------------------------------------------
-- 2. Модели (creature_template_model — схема AC)
-- ------------------------------------------------------------
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (70260, 70261);
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(70260, 0, 27917, 1.00, 1.0),   -- Туманный Призрак (призрачная модель)
(70261, 0, 16134, 1.10, 1.0);   -- Костяной Страж (скелет-страж)