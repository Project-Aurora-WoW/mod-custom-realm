-- ============================================================
-- AzerothEcho — Panel.lua (WoW 3.3.5a)
-- Панель реалма «Эхо Пустоты» с 4 вкладками:
--   Кампании (прогресс-бары) | Ивенты | PvP | Справка (лор)
-- Открытие: /ae
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

-- ============================================================
-- Каркас окна
-- ============================================================

local PANEL_W, PANEL_H = 340, 300

local frame = CreateFrame("Frame", "AzerothEchoPanel", UIParent)
frame:SetWidth(PANEL_W)
frame:SetHeight(PANEL_H)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("DIALOG")

-- Фон и рамка
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetTexture(0, 0, 0, 0.8)

local border = frame:CreateTexture(nil, "BORDER")
border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
border:SetAllPoints(frame)

-- Заголовок
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText(C.void .. "Эхо Пустоты|r")

-- ============================================================
-- Вкладки
-- ============================================================

local TABS = { "Кампании", "Ивенты", "PvP", "Справка" }
local tabButtons = {}
local pages = {}

local function SelectTab(index)
    for i, btn in ipairs(tabButtons) do
        if i == index then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end
    for i, page in ipairs(pages) do
        if i == index then page:Show() else page:Hide() end
    end
    frame.activeTab = index
end

for i, name in ipairs(TABS) do
    local btn = CreateFrame("Button", "AzerothEchoTab" .. i, frame, "CharacterFrameTabButtonTemplate")
    btn:SetText(name)
    btn:SetID(i)
    if i == 1 then
        btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 10, -2)
    else
        btn:SetPoint("TOPLEFT", tabButtons[i - 1], "TOPRIGHT", -6, 0)
    end
    btn:SetScript("OnClick", function() SelectTab(i) end)
    table.insert(tabButtons, btn)
end

-- Страницы: контейнер под заголовком
for i = 1, #TABS do
    local page = CreateFrame("Frame", nil, frame)
    page:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -40)
    page:SetWidth(PANEL_W - 32)
    page:SetHeight(PANEL_H - 90)
    page:Hide()
    table.insert(pages, page)
end

-- ============================================================
-- Вкладка 1: Кампании (прогресс-бары)
-- ============================================================

local campPage = pages[1]
local campRows = {}

-- Ряды прогресс-баров: 4 кампании (К1–К4)
local CAMPAIGN_IDS = { 1, 2, 3, 4 }

for i = 1, #CAMPAIGN_IDS do
    local row = CreateFrame("Frame", nil, campPage)
    row:SetWidth(PANEL_W - 40)
    row:SetHeight(38)
    row:SetPoint("TOPLEFT", campPage, "TOPLEFT", 4, -6 - (i - 1) * 44)

    -- Полоса-подложка прогресс-бара
    row.barBg = row:CreateTexture(nil, "BACKGROUND")
    row.barBg:SetTexture(0.15, 0.15, 0.15, 0.9)
    row.barBg:SetHeight(18)
    row.barBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)

    -- Заполнение прогресс-бара (задаётся в RefreshPanel по ширине)
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetTexture(0.56, 0.27, 0.68, 0.9)  -- цвет Пустоты
    row.bar:SetHeight(18)
    row.bar:SetPoint("TOPLEFT", row.barBg, "TOPLEFT", 0, 0)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("CENTER", row.barBg, "CENTER", 0, 0)

    table.insert(campRows, row)
end

local function FormatChapter(p, campId)
    if not p then
        return C.gray .. "не начата|r"
    elseif p.done then
        return C.green .. "ЗАВЕРШЕНА|r"
    elseif p.chapter == 0 then
        return C.gold .. "доступна|r"
    else
        return C.gold .. "глава " .. p.chapter .. "/" .. p.total .. "|r"
    end
end

-- ============================================================
-- Вкладка 2: Ивенты
-- ============================================================

local eventsPage = pages[2]
local eventsText = eventsPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
eventsText:SetPoint("TOPLEFT", eventsPage, "TOPLEFT", 0, -4)
eventsText:SetJustifyH("LEFT")
eventsText:SetWidth(PANEL_W - 40)

-- ============================================================
-- Вкладка 3: PvP
-- ============================================================

local pvpPage = pages[3]
local pvpText = pvpPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
pvpText:SetPoint("TOPLEFT", pvpPage, "TOPLEFT", 0, -4)
pvpText:SetJustifyH("LEFT")
pvpText:SetWidth(PANEL_W - 40)

-- ============================================================
-- Вкладка 4: Справка (лор)
-- ============================================================

local lorePage = pages[4]
local loreText = lorePage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
loreText:SetPoint("TOPLEFT", lorePage, "TOPLEFT", 0, -4)
loreText:SetJustifyH("LEFT")
loreText:SetWidth(PANEL_W - 40)
loreText:SetText(
    C.order .. "Орден Рассвета|r — коалиция Альянса и Орды.\n" ..
    C.cult .. "Культ Усмешки Бездны|r — служит шёпоту осколка.\n\n" ..
    "Осколок Трона Короля-лича пропитался Пустотой.\n" ..
    "Пустота не убивает — она «иссушает».\n\n" ..
    C.void .. "Жетон Эха|r — валюта ивентов и PvP-зоны.\n" ..
    "Тратится у Интенданта Ордена (Даларан)."
)

-- ============================================================
-- Кнопки и нижняя панель
-- ============================================================

local riftsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
riftsBtn:SetWidth(140)
riftsBtn:SetHeight(24)
riftsBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
riftsBtn:SetText("Карта разломов")

local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeBtn:SetWidth(90)
closeBtn:SetHeight(24)
closeBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
closeBtn:SetText("Закрыть")
closeBtn:SetScript("OnClick", function() frame:Hide() end)

-- Строка жетонов (общая, под заголовком)
local tokensText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tokensText:SetPoint("TOP", frame, "TOP", 0, -28)

-- ============================================================
-- Обновление содержимого
-- ============================================================

local function RefreshPanel()
    -- Кампании (К1–К4)
    for i, campId in ipairs(CAMPAIGN_IDS) do
        local row = campRows[i]
        local p = AE.progress[campId]
        local name = AE.CAMPAIGN_NAMES[campId] or ("Кампания " .. campId)
        local total = (p and p.total) or AE.CAMPAIGN_TOTALS[campId] or 1

        local frac = 0
        if p and p.done then
            frac = 1
        elseif p and p.total and p.total > 0 then
            frac = p.chapter / p.total
        end

        row.bar:ClearAllPoints()
        row.bar:SetPoint("TOPLEFT", row.barBg, "TOPLEFT", 0, 0)
        row.bar:SetWidth(math.max(2, (row.barBg:GetWidth() or 280) * frac))

        row.label:SetText(name .. " — " .. FormatChapter(p, campId))
    end

    -- Ивенты
    local parts = {}
    for key, name in pairs(AE.EVENT_NAMES) do
        local ev = AE.events[key]
        if ev then
            if ev.active then
                table.insert(parts, C.green .. name .. " — идёт (" .. ev.left .. " мин)|r")
            elseif ev.next > 0 then
                table.insert(parts, C.gray .. name .. " — через " .. ev.next .. " мин|r")
            else
                table.insert(parts, C.gray .. name .. " — скоро|r")
            end
        end
    end
    if #parts > 0 then
        eventsText:SetText(table.concat(parts, "\n"))
    else
        eventsText:SetText(C.gray .. "Расписание ивентов недоступно.\nОно придёт от сервера после входа в мир.|r")
    end

    -- PvP
    local s = AE.pvp
    pvpText:SetText(
        C.order .. "Полевая статистика агента Ордена:|r\n\n" ..
        "Зачётные киллы:      " .. C.white .. s.kills .. "|r\n" ..
        "Смерти:              " .. C.white .. s.deaths .. "|r\n" ..
        "Текущая серия:       " .. C.white .. s.streak .. "|r\n" ..
        "Лучшая серия:        " .. C.white .. s.best .. "|r\n" ..
        "Киллов в PvP-зоне:   " .. C.white .. s.zone .. "|r\n\n" ..
        C.gray .. "PvP-зона: Драконий Погост (жетоны за киллы).\n" ..
        "Анти-фарм: разница уровней и кулдаун на жертву.|r"
    )

    -- Жетоны
    tokensText:SetText(C.void .. "Жетоны Эха: " .. AE.tokens .. "|r")
end

-- Перерисовка при поступлении данных от сервера
AE.OnDataChanged(RefreshPanel)

-- ============================================================
-- Публичный API
-- ============================================================

function AE.ShowPanel()
    RefreshPanel()
    frame:Show()
end

--- Открыть панель на конкретной вкладке (1..4).
function AE.ShowTab(index)
    index = math.max(1, math.min(index, #TABS))
    RefreshPanel()
    frame:Show()
    SelectTab(index)
end

function AE.TogglePanel()
    if frame:IsVisible() then
        frame:Hide()
    else
        AE.ShowPanel()
    end
end

function AE.SetRiftsHandler(fn)
    riftsBtn:SetScript("OnClick", fn)
end

frame:Hide()
SelectTab(1)
