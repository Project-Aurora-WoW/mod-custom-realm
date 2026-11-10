-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 09_WorldChat.lua
-- Назначение: глобальный мировой чат реалма (адаптация
-- waloriaold/scripts/worldchat.lua, автор оригинала slp13at420
-- of EmuDevs).
--   1. Игрок включает мировой чат: .chat on — после этого всё,
--      что он пишет в /say, доставляется всему реалму через
--      SendWorldMessage (и локально не дублируется).
--   2. .chat off — отключает канал.
--   3. Антиспам: не чаще REG.worldchat.cooldown_secs секунд
--      между сообщениями одного игрока.
-- Отличия от оригинала:
--   - единый хендлер PLAYER_EVENT_ON_CHAT (18) вместо пары
--     чат/команда (18/42): в оригинале при включённом чате
--     команда выключения «съедалась» чат-хендлером;
--   - исправлен цвет имени Орды (в оригинале обе фракции синие);
--   - параметры в реестре (REG.worldchat), ответы ru/en по
--     локали клиента (DbcLocale 8 → русский);
--   - кликабельные имена (|Hplayer:...|h) сохранены.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local WC = REG.worldchat

-- Цвета сообщений канала
local COLOR_ALLIANCE = "|cff3399ff"   -- имя игрока Альянса
local COLOR_HORDE    = "|cffc0392b"   -- имя игрока Орды
local COLOR_CHANNEL  = "|cff8e44ad"   -- [канал]
local COLOR_MSG      = "|cff00cc00"   -- текст сообщения
local COLOR_OK       = "|cff3399ff"   -- системный ответ (успех)
local COLOR_ERR      = "|cffc0392b"   -- системный ответ (ошибка/спам)

-- ============================================================
-- Локализация (ru/en по локали DBC игрока; 8 = ruRU)
-- ============================================================

local L = {
    en = {
        on         = "World chat enabled. Everything you type in /say goes realm-wide. Disable: .chat off",
        off        = "World chat disabled.",
        spam       = "Do not spam the world chat (cooldown %d sec).",
    },
    ru = {
        on         = "Мировой чат включён. Всё, что вы пишете в /say, увидит весь реалм. Отключить: .chat off",
        off        = "Мировой чат отключён.",
        spam       = "Не спамьте мировым чатом (кулдаун %d сек).",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Состояние канала: account id -> { chat = 0/1, time = os.time() }
-- ============================================================

local WorldChat = {}

local function GetState(accountId)
    if not WorldChat[accountId] then
        WorldChat[accountId] = { chat = 0, time = 0 }
    end
    return WorldChat[accountId]
end

-- ============================================================
-- Единый хендлер чата (PLAYER_EVENT_ON_CHAT = 18)
-- Возврат false — сообщение обработано, не пропускать дальше.
-- ============================================================

local function OnChat(event, player, msg, lang, typ)
    if not player then return end

    local accountId = player:GetAccountId()
    local state = GetState(accountId)
    local locale = GetLocale(player)
    local lower = string.lower(msg)

    -- Команды канала
    if lower == WC.command_on then
        state.chat = 1
        player:SendBroadcastMessage(TAG .. " " .. COLOR_OK .. locale.on .. "|r")
        return false
    end

    if lower == WC.command_off then
        state.chat = 0
        player:SendBroadcastMessage(TAG .. " " .. COLOR_OK .. locale.off .. "|r")
        return false
    end

    -- Канал выключен — обычный /say работает как обычно
    if state.chat ~= 1 then
        return
    end

    -- Канал включён: антиспам + доставка всему реалму
    local now = os.time()
    if (now - state.time) < WC.cooldown_secs then
        player:SendBroadcastMessage(TAG .. " " .. COLOR_ERR .. string.format(locale.spam, WC.cooldown_secs) .. "|r")
        return false
    end

    -- Имя игрока кликабельно (whisper/меню), цвет по фракции
    local nameColor = (player:GetTeam() == 0) and COLOR_ALLIANCE or COLOR_HORDE
    local formatted = string.format(
        "[%s%s|r][%s|h%s|h|r]: %s%s|r",
        COLOR_CHANNEL, WC.channel,
        nameColor, player:GetName(),
        COLOR_MSG, msg
    )

    SendWorldMessage(formatted)
    state.time = now

    -- Сообщение уже доставлено миру — не дублировать локальный /say
    return false
end

RegisterPlayerEvent(18, OnChat) -- PLAYER_EVENT_ON_CHAT

print("[EchoOfTheVoid] 09_WorldChat.lua загружен (мировой чат, .chat on/off).")
