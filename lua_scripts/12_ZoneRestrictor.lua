-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 12_ZoneRestrictor.lua
-- Назначение: ограничитель зон/карт (адаптация
-- waloriaold/scripts/tbcwotlkrestricter.lua, автор оригинала —
-- команда Waloria). Не-GM игрок, вошедший в запрещённую зону
-- или карту, телепортируется в точку выселения.
-- Отличия от оригинала:
--   - список запрещённых зон/карт и точка выселения — в реестре
--     (REG.restrictor), не зашиты в код;
--   - ПО УМОЛЧАНИЮ ВЫКЛЮЧЕНО и список пуст: оригинал был костылём
--     waloria-сервера (бан Outland + выселение из Нордскола по
--     фракциям) — для нашего WotLK-реалма это отрезало бы
--     кампании; включать осознанно через реестр;
--   - фракционное выселение из Нордскола из оригинала НЕ переносится
--     (Нордскол — основной контент реалма);
--   - телепорт вместо player:Teleport(map,x,y,z,o) из оригинала
--     оставлен как есть (сигнатура совпадает с ALE);
--   - лог выселений в консоль для диагностики.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local RS = REG.restrictor

local function IsBanned(target)
    return RS.banned_zones[target] ~= nil or RS.banned_maps[target] ~= nil
end

local function Banish(player, reason)
    local pos = RS.banish
    player:Teleport(pos.map, pos.x, pos.y, pos.z, pos.o)
    print(string.format("[EchoOfTheVoid] ZoneRestrictor: %s (guid %d) выселен из %s %d",
        player:GetName(), player:GetGUIDLow(), reason, 0))
end

-- Смена зоны (PLAYER_EVENT_ON_UPDATE_ZONE = 27)
local function OnZoneChange(event, player, newZone, newArea)
    if not RS.enabled or not player or player:IsGM() then
        return
    end
    if RS.banned_zones[newZone] then
        Banish(player, "zone")
    end
end

-- Смена карты (PLAYER_EVENT_ON_MAP_CHANGE = 28)
local function OnMapChange(event, player)
    if not RS.enabled or not player or player:IsGM() then
        return
    end
    local mapId = player:GetMap() and player:GetMap():GetMapId() or 0
    if RS.banned_maps[mapId] then
        Banish(player, "map")
    end
end

RegisterPlayerEvent(27, OnZoneChange)
RegisterPlayerEvent(28, OnMapChange)

print(string.format(
    "[EchoOfTheVoid] 12_ZoneRestrictor.lua загружен (ограничитель зон/карт: %s, зон: %d, карт: %d).",
    RS.enabled and "ВКЛЮЧЁН" or "выключен",
    #RS.banned_zones,
    #RS.banned_maps))
