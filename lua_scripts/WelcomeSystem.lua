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
    { TAG .. " Король-лич пал. Ледяная Корона разрушена... но мир не обрёл покой.",
      TAG .. " The Lich King has fallen. Icecrown is broken... yet the world knows no peace." },
    { TAG .. " Осколок Трона упал в " .. ORDER_COLOR .. "Драконий Погост|r — и пропитался энергией Пустоты.",
      TAG .. " A shard of the Throne fell into " .. ORDER_COLOR .. "Dragonblight|r — soaked in Void energy." },
    { TAG .. ORDER_COLOR .. " Маги пропадают один за другим|r. Из осколка доносится шёпот...",
      TAG .. ORDER_COLOR .. " Mages vanish one by one|r. A whisper rises from the shard..." },
    { TAG .. ORDER_COLOR .. " Культ Усмешки Бездны|r готовит ритуал пробуждения Старого Бога.",
      TAG .. ORDER_COLOR .. " The Cult of the Void Grin|r prepares a ritual to awaken an Old God." },
}

local WELCOME_L = {
    personal = {
        "Орден Рассвета зовёт тебя. Шёпот осколка слышит каждый, кто связан с магией.",
        "the Dawn Order calls you. Every magic-bound soul hears the shard's whisper.",
    },
    hint = {
        "Найди " .. ORDER_COLOR .. "Портального Стража|r в столице — он расскажет об Эхе Пустоты и откроет путь в Даларан.",
        "Find the " .. ORDER_COLOR .. "Portal Guardian|r in a capital — he will tell of the Echo of the Void and open the way to Dalaran.",
    },
    announce = {
        " присоединился к Ордену Рассвета. Эхо Пустоты слышит тебя.",
        " has joined the Dawn Order. The Echo of the Void hears you.",
    },
}
local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end

-- Расовый флейвор при входе (из центрального реестра)
local function GetRaceLine(player)
    return AzerothEchoCampaigns.race_greetings[player:GetRace()] or ""
end

--- Приветствие при входе игрока в мир.
local function OnPlayerLogin(event, player)
    local name = player:GetName()
    local ru = IsRu(player)

    -- Личное приветствие от Ордена Рассвета
    player:SendBroadcastMessage(
        TAG .. " " .. ORDER_COLOR .. name .. "|r, " .. WELCOME_L.personal[ru and 1 or 2]
    )

    -- Лор-вступление: события после падения Короля-лича
    for _, pair in ipairs(LORE_INTRO) do
        player:SendBroadcastMessage(pair[ru and 1 or 2])
    end

    -- Расовый флейвор (реплика Ордена по расе игрока)
    local raceLine = GetRaceLine(player)
    if raceLine ~= "" then
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. raceLine)
    end

    -- Подсказка: точка входа в кампании — Портальный Страж
    player:SendBroadcastMessage(TAG .. " " .. WELCOME_L.hint[ru and 1 or 2])

    -- Объявление о входе для игроков, достигших ANNOUNCE_LEVEL
    if player:GetLevel() >= ANNOUNCE_LEVEL then
        SendWorldMessage(TAG .. " " .. name .. WELCOME_L.announce[ru and 1 or 2])
    end
end

RegisterPlayerEvent(3, OnPlayerLogin) -- PLAYER_EVENT_ON_LOGIN = 3

print("[EchoOfTheVoid] WelcomeSystem.lua загружен.")