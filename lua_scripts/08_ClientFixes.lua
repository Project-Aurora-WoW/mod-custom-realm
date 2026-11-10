-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 08_ClientFixes.lua
-- Назначение: клиентские фиксы и мировые анонсы реалма.
--   1. Фикс визуального бага «голый персонаж» (nakedbugfix,
--      адаптация из waloriaold/scripts/nakedbugfix.lua): спелл
--      54844 добавляется и сразу снимается, заставляя клиент
--      перечитать видимость предметов.
--   2. Лор-анонсы мира (адаптация announcer.lua): периодические
--      сообщения на языке реалма с лором «Эха Пустоты».
-- Локализация: ru/en по локали DBC игрока (анонсы — на обоих
-- языках в одном сообщении, т.к. SendWorldMessage глобальный).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag

-- ============================================================
-- 1. Фикс «голого персонажа» (waloriaold/nakedbugfix.lua)
-- Хук на вход в мир (3) и смену зоны/карты (27/28)
-- ============================================================

local NAKED_FIX_SPELL = 54844

local function NakedBugFix(event, player)
    if not player then return end
    if not player:HasAura(NAKED_FIX_SPELL) then
        player:AddAura(NAKED_FIX_SPELL, player)
        player:RemoveAura(NAKED_FIX_SPELL)
    end
end

RegisterPlayerEvent(3, NakedBugFix)    -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(27, NakedBugFix)   -- PLAYER_EVENT_ON_UPDATE_ZONE
RegisterPlayerEvent(28, NakedBugFix)   -- PLAYER_EVENT_ON_MAP_CHANGE

-- ============================================================
-- 2. Лор-анонсы мира (waloriaold/announcer.lua → наш лор)
-- Сообщения двуязычные (ru // en) — SendWorldMessage глобален
-- ============================================================

local ANNOUNCE_INTERVAL_SECS = 600  -- каждые 10 минут

local announces = {
    "Орден Рассвета ищет добровольцев: шёпот в Драконьем Погосте усилился. // The Order of Dawn seeks volunteers: the whisper in Dragonblight grows stronger.",
    "Не слушай шёпот у разлома — он назовёт твоё имя. // Do not listen to the whisper at the rift — it knows your name.",
    "Жетоны Эха принимают у Интенданта Ордена в Даларане. // Echo Tokens are accepted by the Order's Quartermaster in Dalaran.",
    "Культ Усмешки Бездны совершает ритуалы у разлома каждые три часа. // The Cult of the Grinning Abyss performs rituals at the rift every three hours.",
    "Хронист Ордена в Даларане знает историю Эха. Спросите его. // The Order's Chronicler in Dalaran knows the history of the Echo. Ask him.",
    "Победителям у разлома — слава. Павшим — эхо ярости. // To victors at the rift — glory. To the fallen — the echo of fury.",
}

local function Announce(eventId, delay, repeats)
    local msg = announces[math.random(1, #announces)]
    SendWorldMessage(TAG .. " " .. msg)
end

local function StartAnnouncer(event)
    CreateLuaEvent(Announce, ANNOUNCE_INTERVAL_SECS * 1000, 0)
end

RegisterServerEvent(33, StartAnnouncer)  -- ALE_EVENT_ON_LUA_STATE_OPEN (после загрузки всех скриптов)

print("[EchoOfTheVoid] 08_ClientFixes.lua загружен (фикс «голого персонажа», лор-анонсы).")
