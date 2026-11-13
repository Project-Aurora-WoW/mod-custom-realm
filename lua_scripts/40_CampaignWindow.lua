-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 40_CampaignWindow.lua — Принудительное окно выбора кампании
--
-- Бриф: «Стартовое окно выбора кампаний, мониторинг активности».
-- При создании персонажа и при каждом входе сервер проверяет профиль
-- кампании (realm_campaign_profile, миграция 0042):
--   • строки нет          → force_show_window=1, campaign_id=NULL (первый вход);
--   • force_show_window=1  → принудительно открыть окно выбора;
--   • campaign_id IS NULL  → открыть окно (кампания не выбрана).
-- Если окно нужно — сервер:
--   1) блокирует управление игроком (SetClientControl 0);
--   2) шлёт клиенту аддон-пакет AECHOSHOW (префикс AECHOUI, "campaign:show");
--   3) после подтверждения клиента (AECHOSEL) снимает блокировку,
--      сбрасывает флаг и записывает выбранную кампанию.
--
-- Таблица в acore_characters (CharDB*). Локализация ru/en по DbcLocale==8.
-- Требует: миграцию 0042, аддон AzerothEcho (обработчик AECHOUI).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG and REG.meta.tag or "|cff9b59b6[Эхо Пустоты]|r"
local DB_CAMPS = REG and REG.meta.db_table or "realm_campaign_progress"
local PROFILE = "realm_campaign_profile"
local UI_PREFIX = "AECHOUI"
local LOCALE_RU = 8

-- ---- Функции профиля ----
local function GetProfile(guid)
    local q = CharDBQuery(string.format(
        "SELECT force_show_window, campaign_id FROM %s WHERE guid = %d", PROFILE, guid))
    if q then
        return q:GetUInt8(0) == 1, q:GetUInt32(1)
    end
    return true, 0 -- строки нет: показать окно (campaign_id = 0 трактуем как NULL)
end

local function SetProfile(guid, force, campaignId)
    if campaignId and campaignId > 0 then
        CharDBExecute(string.format(
            "INSERT INTO %s (guid, force_show_window, campaign_id) VALUES (%d, %d, %d) " ..
            "ON DUPLICATE KEY UPDATE force_show_window=VALUES(force_show_window), campaign_id=VALUES(campaign_id)",
            PROFILE, guid, force and 1 or 0, campaignId))
    else
        CharDBExecute(string.format(
            "INSERT INTO %s (guid, force_show_window, campaign_id) VALUES (%d, %d, NULL) " ..
            "ON DUPLICATE KEY UPDATE force_show_window=VALUES(force_show_window), campaign_id=NULL",
            PROFILE, guid, force and 1 or 0))
    end
end

-- ---- Открыть окно: блокировка + пакет клиенту ----
local function UnlockPlayer(player)
    -- Снятие блокировки: сброс pacified/silenced + возврат управления.
    if player and player.SetPlayerLock then
        pcall(function() player:SetPlayerLock(false) end)
    end
end

local function OpenCampaignWindow(player)
    if not player then return end
    -- Блокировка управления: pacified/silenced + SetClientControl(0)
    -- (метод ALE SetPlayerLock(true) делает и то и другое).
    pcall(function() player:SetPlayerLock(true) end)
    -- Серверный UI-пакет (аддон AzerothEcho слушает AECHOUI)
    local ok, plrName = pcall(function() return player:GetName() end)
    if ok and plrName then
        pcall(function() player:SendAddonMessage(UI_PREFIX, "campaign:show", "WHISPER", plrName) end)
    end
end

-- ---- При создании персонажа ----
-- Бриф: «при создании сервер устанавливает флаг в true». Создаём
-- профиль с force_show_window=1 (окно откроется при первом входе).
local function OnPlayerCreate(event, player)
    if not player then return end
    local guid = player:GetGUIDLow()
    SetProfile(guid, true, 0) -- 0 трактуем как невыбранную кампанию
end
RegisterPlayerEvent(1, OnPlayerCreate) -- PLAYER_EVENT_ON_CHARACTER_CREATE

-- ---- При входе игрока ----
local function OnPlayerLogin(event, player)
    if not player then return end
    local guid = player:GetGUIDLow()

    -- Профиль: если нет строки — первый вход, показать окно.
    local force, campaignId = GetProfile(guid)
    local needShow = force or (campaignId == 0)

    if needShow then
        -- Помечаем профиль force=1 (чтобы при логине снова не терялся флаг,
        -- пока не выбран). Дата/время — для мониторинга.
        SetProfile(guid, true, campaignId)
        OpenCampaignWindow(player)
    end
end
RegisterPlayerEvent(3, OnPlayerLogin) -- PLAYER_EVENT_ON_LOGIN

-- ---- Подтверждение выбора кампании от клиента ----
-- Клиент шлёт аддон-сообщение с префиксом "AECHOSEL" и телом "campaign:<id>".
-- Получаем через серверное событие ADDON_EVENT_ON_MESSAGE (30).
local SEL_PREFIX = "AECHOSEL"
local function OnAddonMessage(event, sender, msgtype, prefix, msg, target)
    local player = sender
    if not player then return end
    local pref = prefix or ""
    local body = msg or ""
    local camp = string.match(body, "^campaign:(%d+)$")
    if pref == SEL_PREFIX and camp then
        local id = tonumber(camp)
        local guid = player:GetGUIDLow()
        -- Валидация: разрешённые ID кампаний 1..4
        if id and id >= 1 and id <= 4 then
            SetProfile(guid, false, id)  -- сброс флага + запись кампании
            UnlockPlayer(player)
            local campName = REG and REG.campaigns[id] and REG.campaigns[id].name or ("Кампания " .. id)
            player:SendBroadcastMessage(TAG .. " Выбрана кампания: |cff5dade2" .. campName .. "|r")
            return false
        end
    end
end
RegisterServerEvent(30, OnAddonMessage) -- ADDON_EVENT_ON_MESSAGE

-- ---- Команда повторного открытия окна ----
local function OnCommand(event, player, command, handler)
    if not player then return end
    local cmd = string.lower(command or "")
    if cmd == "ae campaign" or cmd == "ae camp" then
        OpenCampaignWindow(player)
        return false
    end
end
RegisterPlayerEvent(42, OnCommand) -- PLAYER_EVENT_ON_COMMAND

print("[EchoOfTheVoid] 40_CampaignWindow.lua загружен (принудительное окно выбора кампании).")