-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 46_Home.lua
-- Назначение: система домов (п.4) — телепорт-убежище игрока.
-- Механика:
--   .ae home        — телепорт в дом (точка из realm_homes; кулдаун).
--   .ae homehere    — установить точку дома на текущем месте.
--   .ae homeset <n> — задать имя/пометку дома.
-- Точка хранится в realm_homes (0050, acore_characters). Если дома нет —
-- используется точка по умолчанию (реестр home.default). Клиент получает
-- данные по AECHOHOME (вкладка «Дом» в аддоне AzerothEcho).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void

local H = REG.home
local DEFAULT = H.default
local COOLDOWN = H.cooldown_secs or 60
local DB_TABLE = "realm_homes"
local HOME_PREFIX = H.prefix or "AECHOHOME"

-- ============================================================
-- Хелперы
-- ============================================================

local lastTeleport = {}   -- [guid] = unix-время последнего .ae home

local function GetHome(player)
    local g = player:GetGUIDLow()
    local q = CharDBQuery(string.format(
        "SELECT map, position_x, position_y, position_z, orientation, label FROM %s WHERE guid = %d",
        DB_TABLE, g))
    if q then
        return {
            map = q:GetUInt32(0), x = q:GetFloat(1), y = q:GetFloat(2),
            z = q:GetFloat(3), o = q:GetFloat(4), label = q:GetString(5),
        }
    end
    return nil
end

local function SaveHome(player, home)
    CharDBQuery(string.format(
        "REPLACE INTO %s (guid, map, position_x, position_y, position_z, orientation, label) VALUES (%d, %d, %.2f, %.2f, %.2f, %.2f, '%s')",
        DB_TABLE, player:GetGUIDLow(), home.map, home.x, home.y, home.z, home.o,
        (home.label or ""):sub(1, 64)))
end

-- ============================================================
-- Отправка данных в аддон (AECHOHOME).
-- Формат: "none" | "map;x;y;label;cdLeft"
-- ============================================================
function AE_SendHomePayload(player)
    if not player or not player:IsPlayer() then return end
    local home = GetHome(player)
    local g = player:GetGUIDLow()
    local cd = (lastTeleport[g] or 0) + COOLDOWN - os.time()
    if cd < 0 then cd = 0 end
    if not home then
        SendAddonMessage(HOME_PREFIX, "none", "WHISPER", player)
        return
    end
    SendAddonMessage(HOME_PREFIX,
        string.format("%d;%.1f;%.1f;%s;%d", home.map, home.x, home.y, home.label or "", cd),
        "WHISPER", player)
end

-- ============================================================
-- Команда .ae home|homehere|homeset <label>
-- ============================================================

local function OnPlayerChat(event, player, msg, lang, typ)
    if not player or not player:IsPlayer() then return end
    local cmd, arg = string.match(msg, "^%.ae%s+(%a+)%s*(.*)$")
    if not cmd then return end
    cmd = string.lower(cmd)

    -- .ae home — телепорт в дом
    if cmd == "home" then
        local g = player:GetGUIDLow()
        local now = os.time()
        local last = lastTeleport[g] or 0
        if now - last < COOLDOWN then
            local left = COOLDOWN - (now - last)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Дом:|r " .. VOID_COLOR ..
                "подожди ещё " .. left .. " сек.|r")
            return false
        end
        local home = GetHome(player) or DEFAULT
        player:Teleport(home.map, home.x, home.y, home.z, home.o)
        lastTeleport[g] = now
        local label = home.label ~= "" and (" («" .. home.label .. "»)") or ""
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Дом:|r " .. VOID_COLOR ..
            "ты вернулся домой" .. label .. ".|r")
        -- клиент обновит кулдаун
        if AE_SendHomePayload then AE_SendHomePayload(player) end
        return false
    end

    -- .ae homehere — установить точку дома на текущем месте
    if cmd == "homehere" then
        if not player:IsInWorld() then return false end
        local home = {
            map = player:GetMapId(),
            x = player:GetX(), y = player:GetY(), z = player:GetZ(), o = player:GetO(),
            label = (GetHome(player) or {}).label or "",
        }
        SaveHome(player, home)
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Дом:|r " .. VOID_COLOR ..
            "точка дома установлена здесь.|r")
        if AE_SendHomePayload then AE_SendHomePayload(player) end
        return false
    end

    -- .ae homeset <label> — имя дома (без переполнения 64 симв.)
    if cmd == "homeset" then
        local home = GetHome(player)
        if not home then
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Дом:|r Сначала установи точку (.ae homehere).")
            return false
        end
        local label = (arg or ""):gsub(";", ","):sub(1, 64)
        if label == "" then
            player:SendBroadcastMessage(TAG .. " Формат: .ae homeset <имя дома>")
            return false
        end
        home.label = label
        SaveHome(player, home)
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Дом:|r назван «" .. label .. "».")
        if AE_SendHomePayload then AE_SendHomePayload(player) end
        return false
    end

    return true
end
RegisterPlayerEvent(18, OnPlayerChat)

-- ============================================================
-- Отправка при входе
-- ============================================================
local function OnLogin(event, player)
    AE_SendHomePayload(player)
end
RegisterPlayerEvent(3, OnLogin)

print("[EchoOfTheVoid] 46_Home.lua загружен (система домов, .ae home/homehere/homeset).")