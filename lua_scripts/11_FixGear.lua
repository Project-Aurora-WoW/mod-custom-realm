-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 11_FixGear.lua
-- Назначение: починка экипировки игрока (адаптация
-- waloriaold/scripts/command_fixgear.lua, автор оригинала —
-- команда Waloria). Лечение «сломанного/исчезающего» шмота:
-- команда пересоздаёт каждый надетый предмет в инвентаре,
-- заставляя клиент и БД заново синхронизировать предмет.
-- Отличия от оригинала:
--   - без избыточного запроса GUID по имени (GetGUIDLow напрямую);
--   - учёт в realm_fixgear (0017, acore_characters) вместо
--     custom_fixgear (world); с окном повторной доступности
--     (REG.fixgear.week_secs) вместо «навсегда одна штука»;
--   - трюк AddItem(20023)+RemoveItem заменён на прямое
--     пересоздание: AddItem(entry) → RemoveItem(entry);
--   - предмет берётся из инвентаря, а не удаляется с игрока
--     перед добавлением (безопаснее при полной сумке);
--   - ответы локализованы ru/en (DbcLocale 8 → русский).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local FG = REG.fixgear

-- ============================================================
-- Локализация
-- ============================================================

local L = {
    en = {
        ok      = "Equipped gear has been re-created in your inventory.",
        week    = "Note: the command can be used again in %d days.",
        noSlots = "No fixable items found (nothing equipped or all already fixed).",
        fullBag = "Not enough inventory space — free some slots and retry.",
    },
    ru = {
        ok      = "Надетая экипировка пересоздана в инвентаре.",
        week    = "Примечание: команда снова доступна через %d дн.",
        noSlots = "Починить нечего (ничего не надето или всё уже починено).",
        fullBag = "Недостаточно места в сумках — освободите слоты и повторите.",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Учёт починок (realm_fixgear, acore_characters)
-- ============================================================

local function CanFixItem(guid, entry, now)
    local q = CharDBQuery(string.format(
        "SELECT fixed_at FROM realm_fixgear WHERE guid = %d AND item_entry = %d",
        guid, entry))
    if not q then
        return true
    end
    if not FG.one_week then
        return false -- навсегда одноразово на предмет
    end
    return (now - q:GetUInt32(0)) >= FG.week_secs
end

local function MarkFixed(guid, entry, now)
    CharDBQuery(string.format(
        "REPLACE INTO realm_fixgear (guid, item_entry, fixed_at) VALUES (%d, %d, %d)",
        guid, entry, now))
end

-- ============================================================
-- Команда .fixgear (PLAYER_EVENT_ON_CHAT = 18, в стиле других скриптов)
-- ============================================================

local function OnFixGearChat(event, player, msg)
    if string.lower(msg) ~= FG.command then
        return
    end

    local guid = player:GetGUIDLow()
    local now = os.time()
    local locale = GetLocale(player)
    local fixed, skipped = 0, 0

    for slot = 0, 18 do -- INVENTORY_SLOT_BAG_END-1: все слоты экипировки
        local item = player:GetEquippedItemBySlot(slot)
        if item then
            local entry = item:GetEntry()
            if CanFixItem(guid, entry, now) then
                -- Пересоздание: добавить копию в инвентарь, удалить
                -- надетый оригинал. При нехватке места предмет
                -- остаётся надетым (безопасный порядок).
                if player:AddItem(entry, 1) then
                    player:RemoveItem(entry, 1)
                    MarkFixed(guid, entry, now)
                    fixed = fixed + 1
                else
                    skipped = skipped + 1
                end
            end
        end
    end

    if fixed == 0 and skipped == 0 then
        player:SendBroadcastMessage(TAG .. " " .. locale.noSlots)
        return false
    end

    if skipped > 0 then
        player:SendBroadcastMessage(TAG .. " " .. locale.fullBag)
    end

    if fixed > 0 then
        player:SendBroadcastMessage(TAG .. " " .. locale.ok)
        if FG.one_week then
            player:SendBroadcastMessage(TAG .. " " .. string.format(locale.week, math.ceil(FG.week_secs / 86400)))
        end
    end

    return false -- команда обработана, не отправлять в чат
end

RegisterPlayerEvent(18, OnFixGearChat)

print("[EchoOfTheVoid] 11_FixGear.lua загружен (починка экипировки, " .. FG.command .. ").")
