-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 30_PvpShop.lua
-- Назначение: gossip-магазин «Интендант Ордена» (НПС 70170):
-- покупка расходников и косметики за Жетоны Эха (item 70005).
-- Ассортимент и цены — в 00_CampaignRegistry.lua (shop.items).
-- Механика: RemoveItem(жетоны) + AddItem(товар) с проверкой баланса.
-- Зависимости: 00_CampaignRegistry.lua.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void
local SHOP = REG.shop
local TOKEN_ITEM = REG.meta.token_item

local NPC_VENDOR = SHOP.npc

-- Guard: НПС-шоп заменён AIO-магазином (категория «Снабжение Ордена», 0027).
-- Включается только при REG.shop.enabled = true (фолбэк без AIO-клиента).
if not SHOP.enabled then
    print("[EchoOfTheVoid] 30_PvpShop.lua: НПС-шоп выключен (REG.shop.enabled = false; ассортимент в AIO-магазине, 0027).")
    return
end

-- Пункты gossip-меню: 100+i — покупка i-го товара
local MENU_ROOT = 1

-- ============================================================
-- Утилиты
-- ============================================================

local function GetTokenCount(player)
    return player:GetItemCount(TOKEN_ITEM)
end

local function FormatItemName(i, item)
    local colored = (item.price >= 10) and "|cffff8000" or (item.price >= 5 and "|cff1eff00" or "|cffffffff")
    return colored .. i .. ". " .. item.name .. " — " .. item.price .. " жет.|r"
end

-- ============================================================
-- Меню магазина
-- ============================================================

local function ShowShopMenu(event, player, creature)
    player:GossipClearMenu()

    local tokens = GetTokenCount(player)
    player:SendBroadcastMessage(TAG .. " Ваш баланс: " .. VOID_COLOR .. tokens .. " Жетонов Эха|r.")

    for i, item in ipairs(SHOP.items) do
        player:GossipMenuAddItem(0, FormatItemName(i, item), 0, 100 + i)
    end
    player:GossipMenuAddItem(0, "|cff555555[Закрыть]|r", 0, MENU_ROOT)
    player:GossipSendMenu(1, creature)
end

local function OnShopSelect(event, player, creature, sender, intid, code)
    -- Покупка товара: intid 101..100+N
    if intid >= 101 and intid <= 100 + #SHOP.items then
        local item = SHOP.items[intid - 100]

        -- Проверки покупки
        if player:GetLevel() < REG.meta.min_level then
            player:SendBroadcastMessage(TAG .. " Снабжение Ордена — только героям 80-го уровня.")
            player:GossipComplete()
            return
        end

        local tokens = GetTokenCount(player)
        if tokens < item.price then
            player:SendBroadcastMessage(TAG .. " Недостаточно Жетонов Эха (нужно " .. item.price .. ", есть " .. tokens .. ").")
            player:SendBroadcastMessage(TAG .. " Зарабатывай в ивентах и PvP-зоне Драконьего Погоста!")
            player:GossipComplete()
            return
        end

        -- Списание жетонов и выдача товара
        player:RemoveItem(TOKEN_ITEM, item.price)
        player:AddItem(item.item, item.qty)
        player:SendBroadcastMessage(TAG .. " Куплено: " .. item.name .. " (-" .. item.price .. " жетонов). Осталось: " .. (tokens - item.price) .. ".")
        player:GossipComplete()

        -- Повторно открыть магазин для удобства
        ShowShopMenu(event, player, creature)
        return
    end

    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_VENDOR, 1, ShowShopMenu)  -- GOSSIP_EVENT_ON_HELLO
RegisterCreatureGossipEvent(NPC_VENDOR, 2, OnShopSelect)  -- GOSSIP_EVENT_ON_SELECT

print("[EchoOfTheVoid] 30_PvpShop.lua загружен (шоп НПС " .. NPC_VENDOR .. ", товаров: " .. #SHOP.items .. ").")