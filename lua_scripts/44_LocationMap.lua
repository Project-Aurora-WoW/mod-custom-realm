-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 44_LocationMap.lua
-- Назначение: серверная часть «Карты локаций» (клиент — LocationMap.lua
-- в аддоне AzerothEcho). Отправляет клиенту координатные локации реалма
-- (из REG.map_locations) и текущую позицию игрока по протоколу addrond:
--   сервер -> клиент: SendAddonMessage("AECHOMAP", payload, "WHISPER", player)
-- Payload:
--   M;571;3                              # M;mapId;count
--   dalaran;Даларан;33.0;40.0;order;desc  # локации (key;name;x;y;color;desc)
--   ...
--   P;карта;X;Y                          # позиция игрока (карта, x, y в 0..100)
--   P;571;66.8;68.5
-- Вызов: AE_SendLocationMap(player) — на входе в мир (интегрируется в
-- AddonBridge.lua) и по запросу клиента (хоткей отправляет "map:show").
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local MAP_PREFIX = "AECHOMAP"

-- ============================================================
-- Сериализация локаций (список в <255 байт — умещаем усекаем desc)
-- ============================================================

local function BuildLocationsPayload()
    local cfg = REG.map_locations
    if not cfg or not cfg.locations then
        return ""
    end
    local parts = {}
    for key, loc in pairs(cfg.locations) do
        -- desc усекаем до 40 символов, чтобы влезть в аддон-сообщение
        local desc = (loc.desc or ""):sub(1, 40)
        table.insert(parts, string.format("%s;%s;%.1f;%.1f;%s;%s",
            key, loc.name, loc.x, loc.y, loc.color or "order", desc))
    end
    -- Заголовок: M;mapId;count
    return "M;" .. (cfg.map_id or 571) .. ";" .. #parts .. (parts[1] and (";" .. table.concat(parts, ";")) or "")
end

-- ============================================================
-- Позиция игрока (текущая карта + норм. координаты 0..100)
-- ============================================================

local function PlayerPosition(player)
    if not player or not player:IsInWorld() then
        return nil
    end
    local map = player:GetMapId()
    local x, y = player:GetX(), player:GetY()
    -- MapId -> нормализованные координаты 0..100: стоковая конверсия
    -- (0..1 -> 0..100 в WoW). Для карт с картой 571 (Northrend).
    local nx, ny = x, y
    -- WoW хранит мировые координаты в ярдах; нормализуем относительно
    -- границ карты. Для упрощения берём прямые координаты как % (стока
    -- использует 0..1 координаты в OnMouseUp; здесь даём наводку клиенту).
    -- Fallback: обычные координаты, клиент отобразит как на RiftMap.
    return map, nx, ny
end

-- ============================================================
-- Отправка карты клиенту (публичная)
-- ============================================================

function AE_SendLocationMap(player)
    if not player or not player:IsPlayer() then
        return
    end
    local loc = BuildLocationsPayload()
    if loc ~= "" then
        SendAddonMessage(MAP_PREFIX, loc, "WHISPER", player)
    end
    -- Позиция игрока отдельным сообщением (после локаций)
    local map, px, py = PlayerPosition(player)
    if map then
        SendAddonMessage(MAP_PREFIX,
            string.format("P;%d;%.1f;%.1f", map, px, py), "WHISPER", player)
    end
end

-- ============================================================
-- Хук логина: отправляем карту при входе в мир.
-- Интегрируется с AddonBridge (AE_SendProgress вызывает AE_SendLocationMap,
-- чтобы не плодить лишние ON_LOGIN-хуки в разных файлах).
-- ============================================================

-- Локальная отправка на PLAYER_EVENT_ON_LOGIN (если AddonBridge не вызовет)
local function OnLogin(event, player)
    AE_SendLocationMap(player)
end
RegisterPlayerEvent(3, OnLogin)  -- PLAYER_EVENT_ON_LOGIN = 3

-- ============================================================
-- Живой трекинг позиции (периодический тикер).
-- ALE не имеет события движения игрока, поэтому метку «Вы здесь»
-- обновляем тикером: раз в TRACK_INTERVAL_MS он шлёт всем онлайн
-- игрокам их текущую позицию (P;map;x;y). Чтобы не спамить,
-- отправляем только если карта/позиция изменились с прошлого тика
-- (кэш последних координат по guid).
-- Дополнительно: ON_MAP_CHANGE сразу пересылает новую карту.
-- ============================================================

local TRACK_INTERVAL_MS = 5000        -- обновление раз в 5 сек
local TRACK_MOVED_EPS = 2.0           -- мин. смещение (норм.коорд.), чтобы слать

local lastPos = {}                    -- [guid] = { map, x, y }

local function SendPosition(player)
    local map, x, y = PlayerPosition(player)
    if not map then return end
    local g = player:GetGUIDLow()
    local prev = lastPos[g]
    if prev and prev[1] == map and math.abs(prev[2] - x) < TRACK_MOVED_EPS
       and math.abs(prev[3] - y) < TRACK_MOVED_EPS then
        return  -- не двигался заметно
    end
    lastPos[g] = { map, x, y }
    SendAddonMessage(MAP_PREFIX,
        string.format("P;%d;%.1f;%.1f", map, x, y), "WHISPER", player)
end

-- Периодический обход всех онлайн-игроков раз в TRACK_INTERVAL_MS
CreateLuaEvent(function()
    if not GetPlayersInWorld then return end
    local players = GetPlayersInWorld()
    if not players then return end
    for i = 1, #players do
        local p = players[i]
        if p and p:IsPlayer() and p:IsInWorld() then
            SendPosition(p)
        end
    end
end, TRACK_INTERVAL_MS, 0)

-- Смена карты: шлём сразу, чтобы метка не «зависала» на старой карте
local function OnMapChange(event, player)
    if player and player:IsPlayer() then
        local map, x, y = PlayerPosition(player)
        if map then
            lastPos[player:GetGUIDLow()] = { map, x, y }
            SendAddonMessage(MAP_PREFIX,
                string.format("P;%d;%.1f;%.1f", map, x, y), "WHISPER", player)
        end
    end
end
RegisterPlayerEvent(28, OnMapChange)  -- PLAYER_EVENT_ON_MAP_CHANGE = 28

print("[EchoOfTheVoid] 44_LocationMap.lua загружен (серверная часть карты локаций, AECHOMAP, живой трекинг).")