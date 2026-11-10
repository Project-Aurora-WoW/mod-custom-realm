-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- AddonBridge.lua
-- Назначение: мост между клиентским аддоном AzerothEcho
-- (Interface/AddOns/AzerothEcho) и сервером.
-- Протокол:
--   клиент -> сервер: whisper "ae<space>status" боту-команде
--                     или chat message ".ae status"
--   сервер -> клиент: SendAddonMessage("AECHO", payload, "WHISPER", player)
-- Payload (разделитель ;): campaign;chapter;completed;progress
-- ============================================================

local TAG = AzerothEchoCampaigns.meta.tag
local ADDON_PREFIX = "AECHO"

-- Префикс аддон-сообщений и список кампаний — из центрального реестра
-- (см. 00_CampaignRegistry.ext)
local PREFIX = AzerothEchoCampaigns.meta.prefix

--- Собрать payload прогресса игрока по всем кампаниям.
local function BuildProgressPayload(player)
    local parts = {}
    for campId, camp in pairs(AzerothEchoCampaigns.campaigns) do
        local chapter, completed = 0, false
        local q = CharDBQuery(string.format(
            "SELECT chapter, completed FROM %s WHERE guid = %d AND campaign_id = %d",
            AzerothEchoCampaigns.meta.db_table, player:GetGUIDLow(), campId
        ))
        if q then
            chapter = q:GetUInt8(0)
            completed = q:GetUInt8(1) == 1
        end
        table.insert(parts, string.format("%d:%d:%s", campId, chapter, completed and "done" or tostring(camp.chapters)))
    end
    return table.concat(parts, ";")
end

--- Собрать payload статуса ивентов (для аддона, префикс AECHOEV).
-- Формат: key:active:minutesLeft:nextStartMinutes;...
local function BuildEventsPayload()
    local parts = {}
    for key, cfg in pairs(AzerothEchoCampaigns.events) do
        if key ~= "rift" and _G["AE_EventActive"] then
            local active, left = _G["AE_EventActive"](key)
            local nextStart = _G["AE_EventNext"] and _G["AE_EventNext"](key) or 0
            table.insert(parts, key .. ":" .. (active and 1 or 0) .. ":" .. left .. ":" .. nextStart)
        end
    end
    return table.concat(parts, ";")
end

--- Собрать личную строку валюты игрока (tokens:N) — заработано в PvP.
local function BuildTokensPayload(player)
    local tokens = 0
    local q = CharDBQuery(string.format(
        "SELECT tokens_earned FROM realm_pvp_stats WHERE guid = %d",
        player:GetGUIDLow()
    ))
    if q then
        tokens = q:GetUInt32(0)
    end
    return "tokens:" .. tokens
end

--- Собрать payload PvP-статистики игрока (для аддона, префикс AECHOPVP).
-- Формат: kills:N;deaths:N;streak:N;best:N;zone:N (tokens идут в AECHOEV)
local function BuildPvpPayload(player)
    local payload = { kills = 0, deaths = 0, streak = 0, best = 0, zone = 0 }
    local q = CharDBQuery(string.format(
        "SELECT kills, deaths, streak, best_streak, zone_kills FROM realm_pvp_stats WHERE guid = %d",
        player:GetGUIDLow()
    ))
    if q then
        payload = {
            kills  = q:GetUInt32(0),
            deaths = q:GetUInt32(1),
            streak = q:GetUInt32(2),
            best   = q:GetUInt32(3),
            zone   = q:GetUInt32(4),
        }
    end
    return string.format(
        "kills:%d;deaths:%d;streak:%d;best:%d;zone:%d",
        payload.kills, payload.deaths, payload.streak, payload.best, payload.zone
    )
end

--- Публичная функция отправки всех payload'ов аддону.
-- Используется CampaignManager.lua (.ae status/tokens/pvp/events)
-- и при входе в мир.
function AE_SendProgress(player)
    local payload = BuildProgressPayload(player)
    -- AddonWhisperMessage: (prefix, msg, type, player) в ALE
    SendAddonMessage(ADDON_PREFIX, payload, "WHISPER", player)
    -- Статус ивентов + личная валюта отдельным префиксом
    local events = BuildEventsPayload()
    if events ~= "" then
        SendAddonMessage("AECHOEV", events .. ";" .. BuildTokensPayload(player), "WHISPER", player)
    end
    -- PvP-статистика отдельным префиксом (таблица может отсутствовать
    -- до первого PvP-килла — шлём нули, аддон отобразит корректно)
    SendAddonMessage("AECHOPVP", BuildPvpPayload(player), "WHISPER", player)
end

--- Обработка аддон-сообщений клиент -> сервер ("hello").
-- Аддон шлёт SendAddonMessage("AECHO", "hello", "WHISPER", self) при входе
-- в мир; отвечаем полным набором payload'ов (по запросу).
-- Примечание: в ALE аддон-сообщения (в т.ч. LANG_ADDON) обрабатываются
-- через RegisterServerEvent(30) (ADDON_EVENT_ON_MESSAGE); для совместимости
-- дублируем логикой ON_LOGIN.
local function OnPlayerLogin(event, player)
    AE_SendProgress(player)
end

RegisterPlayerEvent(3, OnPlayerLogin)  -- PLAYER_EVENT_ON_LOGIN = 3

print("[EchoOfTheVoid] AddonBridge.lua загружен (аддон AzerothEcho, AE_SendProgress экспортирован).")