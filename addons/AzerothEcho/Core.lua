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

-- ============================================================
-- Гильдия (AECHOGUILD от 45_GuildProgress.lua)
-- Формат: name;level;xp;total;unlocked  | "none"
-- ============================================================

AE.guild = { name = nil, level = 0, xp = 0, total = 0, unlocked = 0, none = true }

function AE.ParseGuild(payload)
    if not payload or payload == "" then return end
    if payload == "none" then
        AE.guild = { name = nil, level = 0, xp = 0, total = 0, unlocked = 0, none = true }
    else
        local name, level, xp, total, unlocked =
            string.match(payload, "^(.-);(%d+);(%d+);(%d+);(%d+)$")
        if name and level then
            AE.guild = {
                name = name, level = tonumber(level), xp = tonumber(xp),
                total = tonumber(total), unlocked = tonumber(unlocked), none = false,
            }
        end
    end
    -- Обновить вкладку Гильдия, если панель уже создана
    if AE.RefreshGuildPanel then
        AE.RefreshGuildPanel(AE.guild)
    end
    AE.NotifyChanged()
end

-- ============================================================
-- Дом (AECHOHOME от 46_Home.lua)
-- Формат: "none" | "map;x;y;label;cdLeft"
-- ============================================================

AE.home = { map = nil, x = 0, y = 0, label = nil, cd = 0, none = true }

function AE.ParseHome(payload)
    if not payload or payload == "" then return end
    if payload == "none" then
        AE.home = { map = nil, x = 0, y = 0, label = nil, cd = 0, none = true }
    else
        local map, x, y, label, cd =
            string.match(payload, "^(%d+);([%d%.]+);([%d%.]+);(.-);(%d+)$")
        if map then
            AE.home = {
                map = tonumber(map), x = tonumber(x), y = tonumber(y),
                label = (label ~= "" and label) or nil, cd = tonumber(cd), none = false,
            }
        end
    end
    if AE.RefreshHomePanel then
        AE.RefreshHomePanel(AE.home)
    end
    AE.NotifyChanged()
end

-- ============================================================
-- Социальное (AECHOSOCIAL от 47_Social.lua)
-- Формат: count;name1:lvl1;name2:lvl2;... [;MENTOR;имяНаставника]
-- ============================================================

AE.social = { partners = {}, mentor = nil, count = 0 }

function AE.ParseSocial(payload)
    AE.social = { partners = {}, mentor = nil, count = 0 }
    if not payload or payload == "" then
        if AE.RefreshSocialPanel then AE.RefreshSocialPanel(AE.social) end
        return
    end
    local countStr, rest = string.match(payload, "^(%d+);(.*)$")
    local count = tonumber(countStr) or 0
    AE.social.count = count
    -- Разбираем пары name:lvl и метку MENTOR
    for name, lvl in string.gmatch(rest or "", "([^:;]+):(%d+)") do
        table.insert(AE.social.partners, { name = name, level = tonumber(lvl) })
    end
    local mentor = string.match(rest or "", "MENTOR;([^;]+)$")
    if mentor then AE.social.mentor = mentor end
    if AE.RefreshSocialPanel then
        AE.RefreshSocialPanel(AE.social)
    end
    AE.NotifyChanged()
end
