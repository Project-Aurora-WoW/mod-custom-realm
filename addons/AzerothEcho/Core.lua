-- ============================================================
-- AzerothEcho — Core.lua (WoW 3.3.5a)
-- Общие константы, состояние и парсинг payload'ов сервера.
-- Работает в паре с AddonBridge.lua (ALE):
--   AECHO   -> прогресс кампаний: "id:chapter:total|done;..."
--   AECHOEV -> ивенты + жетоны:   "storm:1:25:40;blood:0:0:180;tokens:12"
--   AECHOPVP -> PvP-статистика:   "kills:12;deaths:3;streak:4;best:9;zone:5;tokens:12"
-- ============================================================

AzerothEcho = AzerothEcho or {}
local AE = AzerothEcho

AE.NAME    = "AzerothEcho"
AE.PREFIX  = "AECHO"
AE.TAG     = "|cff9b59b6[Эхо Пустоты]|r"

-- Цветовая палитра реалма (синхронизирована с 00_CampaignRegistry.lua)
AE.COLOR = {
    void    = "|cff8e44ad",   -- Пустота
    order   = "|cff5dade2",   -- Орден Рассвета
    cult    = "|cffc0392b",   -- Культ Усмешки Бездны
    green   = "|cff00ff00",
    blue    = "|cff00ccff",
    gold    = "|cffffff00",
    gray    = "|cff555555",
    orange  = "|cffff9944",
    red     = "|cffff4444",
    white   = "|cffffffff",
}

-- Названия кампаний (id -> name)
AE.CAMPAIGN_NAMES = {
    [1] = "Эхо Шёпота",
    [2] = "Пепел Зул'Драка",
    [3] = "Пробуждение",
    [4] = "Второе Эхо",
}

-- Число глав (id -> total) для отображения до ответа сервера
AE.CAMPAIGN_TOTALS = { [1] = 3, [2] = 5, [3] = 4, [4] = 5 }

-- Названия ивентов
AE.EVENT_NAMES = { storm = "Шторм Пустоты", blood = "Кровавая Луна Культа" }

-- ============================================================
-- Состояние
-- ============================================================

AE.progress = {}     -- [id] = { chapter, total, done }
AE.events   = {}     -- [key] = { active, left, next }
AE.pvp      = { kills = 0, deaths = 0, streak = 0, best = 0, zone = 0, tokens = 0 }
AE.tokens   = 0

-- Подписчики на обновление данных (UI перерисовывается по колбеку)
AE.listeners = {}
function AE.OnDataChanged(fn)
    table.insert(AE.listeners, fn)
end

function AE.NotifyChanged()
    for _, fn in ipairs(AE.listeners) do
        pcall(fn)
    end
end

-- ============================================================
-- Парсинг payload'ов
-- ============================================================

-- Прогресс кампаний: "1:2:3;2:0:5;3:4:done"
function AE.ParseProgress(payload)
    AE.progress = {}
    for entry in string.gmatch(payload or "", "[^;]+") do
        local id, chapter, total = string.match(entry, "^(%d+):(%d+):(.+)$")
        if id then
            local done = (total == "done")
            AE.progress[tonumber(id)] = {
                chapter = tonumber(chapter) or 0,
                total   = done and 0 or (tonumber(total) or 0),
                done    = done,
            }
        end
    end
    AE.NotifyChanged()
end

-- Ивенты + жетоны: "storm:1:25:40;blood:0:0:180;tokens:12"
function AE.ParseEvents(payload)
    AE.events = {}
    for entry in string.gmatch(payload or "", "[^;]+") do
        local tval = string.match(entry, "^tokens:(%d+)$")
        if tval then
            AE.tokens = tonumber(tval)
        else
            local key, active, left, nextStart = string.match(entry, "^(%a+):(%d):(%d+):(%d+)$")
            if key then
                AE.events[key] = {
                    active = (active == "1"),
                    left   = tonumber(left) or 0,
                    next   = tonumber(nextStart) or 0,
                }
            end
        end
    end
    AE.NotifyChanged()
end

-- PvP-статистика: "kills:12;deaths:3;streak:4;best:9;zone:5;tokens:12"
function AE.ParsePvp(payload)
    AE.pvp = { kills = 0, deaths = 0, streak = 0, best = 0, zone = 0, tokens = 0 }
    for key, val in string.gmatch(payload or "", "(%a+):(%d+)") do
        local n = tonumber(val) or 0
        if     key == "kills"  then AE.pvp.kills  = n
        elseif key == "deaths" then AE.pvp.deaths = n
        elseif key == "streak" then AE.pvp.streak = n
        elseif key == "best"   then AE.pvp.best   = n
        elseif key == "zone"   then AE.pvp.zone   = n
        elseif key == "tokens" then AE.tokens     = n
        end
    end
    AE.NotifyChanged()
end
