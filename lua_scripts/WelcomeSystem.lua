-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- WelcomeSystem.lua
-- Назначение: приветствие новых игроков и объявление входа
-- в мир. Тексты основаны на лоре вселенной
-- (см. docs/lore/universe.md — таймлайн, событие 5).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local TAG = "|cff9b59b6[Эхо Пустоты]|r"
local ORDER_COLOR = "|cff5dade2" -- цвет Ордена Рассвета в сообщениях

local ANNOUNCE_LEVEL = 10 -- объявлять вход только для игроков 10+ уровня

-- Лор-сообщения игроку при входе (эпилог таймлайна вселенной)
local LORE_INTRO = {
    TAG .. " Король-лич пал. Ледяная Корона разрушена... но мир не обрёл покой.",
    TAG .. " Осколок Трона упал в " .. ORDER_COLOR .. "Драконий Погост|r — и пропитался энергией Пустоты.",
    TAG .. ORDER_COLOR .. " Маги пропадают один за другим|r. Из осколка доносится шёпот...",
    TAG .. ORDER_COLOR .. " Культ Усмешки Бездны|r готовит ритуал пробуждения Старого Бога.",
}

-- Расовый флейвор при входе (из центрального реестра)
local function GetRaceLine(player)
    return AzerothEchoCampaigns.race_greetings[player:GetRace()] or ""
end

--- Приветствие при входе игрока в мир.
local function OnPlayerLogin(event, player)
    local name = player:GetName()

    -- Личное приветствие от Ордена Рассвета
    player:SendBroadcastMessage(
        TAG .. " " .. ORDER_COLOR .. name .. "|r, Орден Рассвета зовёт тебя. Шёпот осколка слышит каждый, кто связан с магией."
    )

    -- Лор-вступление: события после падения Короля-лича
    for _, line in ipairs(LORE_INTRO) do
        player:SendBroadcastMessage(line)
    end

    -- Расовый флейвор (реплика Ордена по расе игрока)
    local raceLine = GetRaceLine(player)
    if raceLine ~= "" then
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. raceLine)
    end

    -- Подсказка: точка входа в кампании — Портальный Страж
    player:SendBroadcastMessage(
        TAG .. " Найди " .. ORDER_COLOR .. "Портального Стража|r в столице — он расскажет об Эхе Пустоты и откроет путь в Даларан."
    )

    -- Объявление о входе для игроков, достигших ANNOUNCE_LEVEL
    if player:GetLevel() >= ANNOUNCE_LEVEL then
        SendWorldMessage(
            TAG .. " " .. name .. " присоединился к Ордену Рассвета. Эхо Пустоты слышит тебя."
        )
    end
end

RegisterPlayerEvent(3, OnPlayerLogin) -- PLAYER_EVENT_ON_LOGIN = 3

print("[EchoOfTheVoid] WelcomeSystem.lua загружен.")