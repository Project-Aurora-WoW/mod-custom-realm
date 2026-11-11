-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 28_RandomEnchant.lua
-- Назначение: НПС «Рандомный Зачарователь» (70192) — применяет
-- СЛУЧАЙНЫЙ энчант из пула тира к надетому оружию (слот 15/16)
-- за фиксированную цену. Пул и веса — из таблицы
-- item_enchantment_random_tiers (миграция 0028), локализация ru/en.
--
-- Отличия/принципы (консистентно с 15_Enchanter.lua):
--   - оплата строго до наложения (single-point charge);
--   - пункт меню с тиром и подписью, случайный выбор — по весу;
--   - применяется item:SetEnchantment() на слот заклинания 0
--     (тот же механизм, что и 15_Enchanter).
-- Зависимости: реестр AzerothEchoCampaigns (services.random_enchanter).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ENC = REG.services.random_enchanter

-- Слоты оружия, которые обрабатываем
local WEAPON_SLOTS = { 15, 16 } -- правая/левая рука (2H надето в 15)

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        menuTitle = "Random enchant — %d gold",
        pickSlot = "Select weapon:",
        right = "[Right hand]",
        left = "[Left hand]",
        tiers = "Enchant tiers: %d",
        cost = "Cost: %d gold. Random enchant for %s.",
        back = "[Back]",
        noItem = "No weapon equipped in that slot!",
        noGold = "Not enough gold (price: %d gold).",
        enchanted = "Applied random enchant!",
        noTier = "Item level too low for any tier — nothing applied.",
    },
    ru = {
        menuTitle = "Случайный энчант — %d зол.",
        pickSlot = "Выберите оружие:",
        right = "[Правая рука]",
        left = "[Левая рука]",
        tiers = "Тиры энчантов: %d",
        cost = "Цена: %d зол. Случайный энчант на %s.",
        back = "[Назад]",
        noItem = "В этом слоте нет оружия!",
        noGold = "Недостаточно золота (цена: %d зол.).",
        enchanted = "Применён случайный энчант!",
        noTier = "Уровень предмета ниже любого тира — ничего не применено.",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Загрузка тиров из БД
-- ============================================================
local Tiers = {}
local function LoadTiers()
    Tiers = {}
    local q = WorldDBQuery("SELECT id, tierName, default_enchant_id, min_itemlevel, max_itemlevel, weight FROM " .. ENC.db_table)
    if q then
        repeat
            table.insert(Tiers, {
                id          = q:GetUInt32(0),
                tierName    = q:GetString(1),
                enchant     = q:GetUInt32(2),
                minIlvl     = q:GetUInt32(3),
                maxIlvl     = q:GetUInt32(4),
                weight      = q:GetUInt32(5),
            })
        until not q:NextRow()
    end
end
LoadTiers()

-- Выбор случайного энчанта по весу среди подходящих по ilvl тиров.
-- Возвращает enchantId или nil.
local function PickRandomEnchant(item)
    local ilvl = item:GetItemLevel() or 0
    -- Отбираем тиры, в диапазон которых попадает ilvl (0 = без ограничения)
    local pool = {}
    for _, t in ipairs(Tiers) do
        local okLow = (t.minIlvl == 0) or (ilvl >= t.minIlvl)
        local okHigh = (t.maxIlvl == 0) or (ilvl <= t.maxIlvl)
        if okLow and okHigh then
            table.insert(pool, t)
        end
    end
    if #pool == 0 then
        return nil
    end

    -- Взвешенный выбор
    local total = 0
    for _, t in ipairs(pool) do
        total = total + t.weight
    end
    local r = math.random(1, total)
    for _, t in ipairs(pool) do
        r = r - t.weight
        if r <= 0 then
            return t.enchant
        end
    end
    return pool[#pool].enchant
end

-- ============================================================
-- Меню
-- ============================================================

-- Меню выбора слота
local function ShowSlotMenu(event, player, object)
    local loc = GetLocale(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, loc.right, 0, 15)
    player:GossipMenuAddItem(0, loc.left,  0, 16)
    player:GossipMenuAddItem(0, loc.back,  0, 500)
    player:GossipSendMenu(1, object)
end

-- Меню подтверждения для слота (показывает тир-подпись товара)
local function ShowConfirmMenu(event, player, object, slotKey)
    local loc = GetLocale(player)
    local item = player:GetEquippedItemBySlot(slotKey)
    player:GossipClearMenu()
    if not item then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.noItem)
        --- вернуться к выбору слота
        ShowSlotMenu(event, player, object)
        return
    end

    local tierCount = #Tiers
    local slotName = (slotKey == 15) and loc.right or loc.left
    player:GossipMenuAddItem(0, string.format(loc.cost, ENC.price / 10000, slotName),
        0, 100 + slotKey, false, string.format(loc.tiers, tierCount), ENC.price)
    player:GossipMenuAddItem(0, loc.back, 0, 501)
    player:GossipSendMenu(1, object)
end

-- ============================================================
-- Обработчики gossip
-- ============================================================
local pVar = {}

local function OnHello(event, player, object)
    pVar[player:GetName()] = nil
    ShowSlotMenu(event, player, object)
end

local function OnSelect(event, player, object, sender, intid, code, menu_id)
    local loc = GetLocale(player)

    if intid == 500 then
        ShowSlotMenu(event, player, object)
        return
    end
    if intid == 501 then
        local slotKey = pVar[player:GetName()]
        if slotKey then
            ShowConfirmMenu(event, player, object, slotKey)
        end
        return
    end
    if intid == 15 or intid == 16 then
        pVar[player:GetName()] = intid
        ShowConfirmMenu(event, player, object, intid)
        return
    end
    -- Подтверждение покупки: 100+slotKey (115/116)
    if intid == 115 or intid == 116 then
        local slotKey = intid - 100
        local item = player:GetEquippedItemBySlot(slotKey)
        if not item then
            player:SendAreaTriggerMessage(TAG .. " " .. loc.noItem)
            ShowConfirmMenu(event, player, object, slotKey)
            return
        end

        -- Оплата строго до наложения
        if player:GetCoinage() < ENC.price then
            player:SendAreaTriggerMessage(TAG .. " " .. string.format(loc.noGold, ENC.price / 10000))
            ShowConfirmMenu(event, player, object, slotKey)
            return
        end

        -- Случайный выбор
        local enchantId = PickRandomEnchant(item)
        if not enchantId then
            player:SendAreaTriggerMessage(TAG .. " " .. loc.noTier)
            ShowConfirmMenu(event, player, object, slotKey)
            return
        end

        -- Оплата и применение
        player:ModifyMoney(-ENC.price)
        item:ClearEnchantment(0, 0)
        item:SetEnchantment(enchantId, 0, 0)
        player:CastSpell(player, ENC.visual_spell)
        player:SendAreaTriggerMessage(TAG .. " " .. loc.enchanted)
        ShowConfirmMenu(event, player, object, slotKey)
        return
    end

    player:GossipComplete()
end

RegisterCreatureGossipEvent(ENC.npc, 1, OnHello)   -- GOSSIP_EVENT_ON_HELLO
RegisterCreatureGossipEvent(ENC.npc, 2, OnSelect)  -- GOSSIP_EVENT_ON_SELECT

print(string.format(
    "[EchoOfTheVoid] 28_RandomEnchant.lua загружен (рандомный энчант НПС %d, тиров: %d).",
    ENC.npc, #Tiers))