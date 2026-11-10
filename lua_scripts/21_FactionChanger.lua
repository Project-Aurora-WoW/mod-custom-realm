-- ============================================================
-- 21_FactionChanger.lua — смена фракции
-- Референс: public-scripts/FactionChange (JadaDev).
--
-- Механика: НПС 70174 «Страж Перемен» (Даларан, 0021) за 25 Жетонов
-- Эха ставит AtLogin-флаг 8 (FACTION_CHANGE) — после релогина игрок
-- меняет фракцию персонажа в стиле VAS (штатное ядро).
--
-- Отличия от оригинала:
--   1. НПС 70000 → 70174 (кастомный диапазон реалма), Даларан.
--   2. Токен 55555 → Жетон Эха 70005 ×25.
--   3. Локализация ru/en (DbcLocale 8 → русский).
--   4. Иконки в пунктах меню, проверка уровня гейта кампаний (80+,
--      смена фракции ломает прогресс фракционных кампаний — гейт).
-- ============================================================

local GUARDIAN_ENTRY = 70174
local TOKEN_ITEM = 70005
local TOKEN_COST = 25
local MIN_LEVEL = 80

local TAG = "|cff9b59b6[Эхо Пустоты]|r"

local MENU_CHANGE = 1
local MENU_CANCEL = 2

local L = {
    ru = {
        menu_change = "|TInterface\\Icons\\Ability_DualWieldSpecialization:30:30|tСменить фракцию (" .. TOKEN_COST .. " Жетонов Эха)",
        menu_cancel = "|TInterface\\Icons\\Spell_Shadow_SacrificialShield:30:30|tНичего не нужно",
        hello = "Перемена стороны — серьёзный шаг, агент. Орден оформит документы... за установленную плату.",
        done = "Жетоны приняты. Перезайдите в мир — и оформите перемену фракции персонажа.",
        no_tokens = "Недостаточно Жетонов Эха (нужно " .. TOKEN_COST .. ").",
        low_level = "Перемена фракции доступна с " .. MIN_LEVEL .. " уровня.",
    },
    en = {
        menu_change = "|TInterface\\Icons\\Ability_DualWieldSpecialization:30:30|tChange faction (" .. TOKEN_COST .. " Echo Tokens)",
        menu_cancel = "|TInterface\\Icons\\Spell_Shadow_SacrificialShield:30:30|tNevermind",
        hello = "Changing sides is a serious step, agent. The Order will handle the paperwork... for the established fee.",
        done = "Tokens accepted. Re-login and complete your character's faction change.",
        no_tokens = "Not enough Echo Tokens (" .. TOKEN_COST .. " required).",
        low_level = "Faction change is available from level " .. MIN_LEVEL .. ".",
    },
}

local function L10n(player)
    return (player:GetSession():GetSessionDbcLocale() == 8) and L.ru or L.en
end

local function OnGossipHello(event, player, creature)
    if creature:GetEntry() ~= GUARDIAN_ENTRY then
        return
    end

    local t = L10n(player)
    player:SendBroadcastMessage(TAG .. " «" .. t.hello .. "»")
    player:GossipMenuAddItem(0, t.menu_change, 0, MENU_CHANGE)
    player:GossipMenuAddItem(0, t.menu_cancel, 0, MENU_CANCEL)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == MENU_CANCEL then
        player:GossipComplete()
        return
    end

    if intid ~= MENU_CHANGE then
        player:GossipComplete()
        return
    end

    local t = L10n(player)

    if player:GetLevel() < MIN_LEVEL then
        player:SendBroadcastMessage(TAG .. " " .. t.low_level)
        player:GossipComplete()
        return
    end

    if not player:HasItem(TOKEN_ITEM, TOKEN_COST) then
        player:SendBroadcastMessage(TAG .. " " .. t.no_tokens)
        player:GossipComplete()
        return
    end

    -- Списание + флаг смены фракции (проверка перед списанием)
    player:RemoveItem(TOKEN_ITEM, TOKEN_COST)
    player:SetAtLoginFlag(8) -- AT_LOGIN_FLAG_CHANGE_FACTION
    player:SendBroadcastMessage(TAG .. " " .. t.done)
    player:GossipComplete()
end

RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 2, OnGossipSelect)

print("[EchoOfTheVoid] 21_FactionChanger.lua загружен (НПС " .. GUARDIAN_ENTRY .. ", смена фракции за Жетоны Эха).")
