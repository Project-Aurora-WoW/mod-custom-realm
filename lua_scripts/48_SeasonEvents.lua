-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 48_SeasonEvents.lua
-- Назначение: сезонные эвенты (п.5) — надстройка над авто-ивентами.
-- Механика:
--  1. Календарные сезоны (4 цикла по месяцам): во время активного сезона
--     циклические ивенты дают доп. жетоны (token_mult) и сезонную валюту
--     (currency_item из реестра season_events.seasons).
--  2. Праздничные ивенты (по дате): в праздничный день выдаётся валюта
--     праздника (holidays[].currency_item).
--  3. Ежегодный сезон с этапами («Цикл Осколка»): активный этап считается
--     от start_month/start_day; личный прогресс этапа хранится в
--     realm_season_state. 
-- Клиент получает статус по AECHOSEASON.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local GOLD_COLOR = REG.meta.colors.gold

local SE = REG.season_events
local SEASONS = SE.seasons
local HOLIDAYS = SE.holidays
local ANNUAL = SE.annual
local PREFIX = SE.prefix or "AECHOSEASON"
local STATE_TABLE = "realm_season_state"

-- ============================================================
-- Текущая дата (год, месяц, день)
-- ============================================================

local function NowDate()
    local t = os.date("*t", os.time())
    return t.year, t.month, t.day
end

-- Активный календарный сезон (по месяцу); возвращает table nil если нет
local function ActiveSeason(month)
    for key, s in pairs(SEASONS) do
        for _, m in ipairs(s.months) do
            if m == month then
                return s
            end
        end
    end
    return nil
end

-- Активный праздник (по месяцу+дню); nil если нет
local function ActiveHoliday(month, day)
    for _, h in ipairs(HOLIDAYS) do
        if h.month == month and h.day == day then
            return h
        end
    end
    return nil
end

-- Текущий этап ежегодного сезона (1..N) и прогресс внутри этапа
local function AnnualStage(year, month, day)
    -- день года от старта сезона (start_month/start_day)
    local startOrd = os.time({ year = year, month = ANNUAL.start_month, day = ANNUAL.start_day })
    local now = os.time({ year = year, month = month, day = day })
    if now < startOrd then startOrd = os.time({ year = year - 1, month = ANNUAL.start_month, day = ANNUAL.start_day }) end
    local days = math.floor((now - startOrd) / 86400)
    local stage = math.floor(days / ANNUAL.stage_len_days) + 1
    if stage > #ANNUAL.stages then stage = #ANNUAL.stages end
    local daysInStage = days % ANNUAL.stage_len_days
    return stage, daysInStage
end

-- ============================================================
-- Бонус к авто-ивентам: множитель жетонов активного сезона
-- (экспортируем для 10_EventSystem.lua)
-- ============================================================

local function SeasonTokenMult(month)
    local s = ActiveSeason(month or NowDate())
    return s and (s.token_mult or 1) or 1
end

-- Экспорт: другие модули (10_EventSystem.lua) могут спросить множитель
_G.SeasonTokenMult = SeasonTokenMult

-- Сезонная валюта активного сезона (item entry) или 0
local function SeasonCurrency(month)
    local s = ActiveSeason(month or NowDate())
    return s and s.currency_item or 0
end

-- ============================================================
-- Выдача сезонной/праздничной валюты при активности в ивенте
-- (интегрируется с 10_EventSystem.lua через публичную функцию)
-- ============================================================

function AE_GrantSeasonReward(player, baseTokens)
    if not player or not player:IsPlayer() then return end
    local _, month, day = NowDate()

    -- Сезонная валюта (каждый зачётный ивент во время сезона)
    local seasonItem = SeasonCurrency(month)
    if seasonItem > 0 then
        player:AddItem(seasonItem, math.max(1, math.floor(baseTokens / 2)))
    end

    -- Праздничная валюта (только в праздничный день)
    local hol = ActiveHoliday(month, day)
    if hol then
        player:AddItem(hol.currency_item, baseTokens)
        player:SendBroadcastMessage(TAG .. " " .. GOLD_COLOR .. "Праздник «" .. hol.name .. "»!|r +валюта праздника.")
    end
end

-- ============================================================
-- AECHOSEASON payload (вкладка «Ивенты» в аддоне)
-- Формат: season;seasonName;holiday;holidayName;stage;stageName;stageGoal;stageDays
-- ============================================================

function AE_SendSeasonPayload(player)
    if not player or not player:IsPlayer() then return end
    local year, month, day = NowDate()
    local s = ActiveSeason(month)
    local h = ActiveHoliday(month, day)
    local stage, stageDays = AnnualStage(year, month, day)
    local stageCfg = ANNUAL.stages[stage]

    local payload = string.format("%s;%s;%s;%s;%d;%s;%s;%d",
        s and s.key or "none", s and s.name or "",
        h and h.key or "none", h and h.name or "",
        stage, stageCfg.name, stageCfg.goal, ANNUAL.stage_len_days - stageDays)
    SendAddonMessage(PREFIX, payload, "WHISPER", player)
end

-- ============================================================
-- Отправка при входе
-- ============================================================
local function OnLogin(event, player)
    AE_SendSeasonPayload(player)
end
RegisterPlayerEvent(3, OnLogin)

print("[EchoOfTheVoid] 48_SeasonEvents.lua загружен (сезонные эвенты, сезоны/праздники/ежегодный сезон).")