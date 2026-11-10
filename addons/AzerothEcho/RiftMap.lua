-- ============================================================
-- AzerothEcho — RiftMap.lua (WoW 3.3.5a)
-- Карта разломов Пустоты: пины на карте Northrend
-- с тултипами и уровнями опасности.
-- Лор-обоснование: docs/lore/universe.md (раздел «Ключевые локации»).
-- Открытие: /ae rifts или кнопка «Карта разломов» на панели.
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

-- Разломы Пустоты (координаты Northrend, mapID 571 — в 3.3.5a
-- континентская карта открывается через SetMapByID(571))
local RIFTS = {
    { name = "Драконий Погост — эпицентр", x = 66.8, y = 68.5, danger = 3, desc = "Осколок Трона. Главные разломы." },
    { name = "Зул'Драк — Храм Шёпота",     x = 74.5, y = 22.5, danger = 2, desc = "Алтари Культа Усмешки Бездны." },
    { name = "Бесплодные земли — перевал", x = 47.0, y = 39.0, danger = 1, desc = "Перевалочный пункт Культа." },
}

local RIFT_PIN_COLORS = {
    [1] = { r = 0.4,  g = 0.7,  b = 1.0 },   -- низкая опасность: голубой
    [2] = { r = 1.0,  g = 0.6,  b = 0.1 },   -- средняя: оранжевый
    [3] = { r = 1.0,  g = 0.15, b = 0.15 },  -- высокая: красный
}

local RIFT_DANGER_COLORS = { C.blue, C.orange, C.red }
local RIFT_DANGER_NAMES  = { "низкая", "средняя", "высокая" }

-- ============================================================
-- Пины
-- ============================================================

local riftPins = {}

local function CreateRiftPin(index, rift)
    local pin = CreateFrame("Frame", "AzerothEchoRiftPin" .. index, WorldMapFrame)
    pin:SetWidth(22)
    pin:SetHeight(22)
    pin:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 5)

    local tex = pin:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(pin)
    tex:SetTexture("Interface\\Minimap\\Ping")
    local color = RIFT_PIN_COLORS[rift.danger] or RIFT_PIN_COLORS[1]
    tex:SetVertexColor(color.r, color.g, color.b)

    -- Позиция: пересчёт процентов в координаты фрейма карты
    pin:ClearAllPoints()
    pin:SetPoint(
        "CENTER", WorldMapFrame, "TOPLEFT",
        (rift.x / 100) * WorldMapFrame:GetWidth(),
        -(rift.y / 100) * WorldMapFrame:GetHeight()
    )

    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText((RIFT_DANGER_COLORS[rift.danger] or C.blue) .. rift.name .. "|r")
        GameTooltip:AddLine(rift.desc, 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine("Опасность: " .. RIFT_DANGER_NAMES[rift.danger] .. " (" .. string.rep("*", rift.danger) .. ")", 1, 1, 0.4)
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return pin
end

local function ClearRiftPins()
    for _, pin in ipairs(riftPins) do
        pin:Hide()
        pin:SetParent(nil)
    end
    riftPins = {}
end

-- ============================================================
-- Публичный API
-- ============================================================

function AE.ShowRiftMap()
    WorldMapFrame:Show()
    SetMapByID(571) -- Northrend

    ClearRiftPins()
    for i, rift in ipairs(RIFTS) do
        table.insert(riftPins, CreateRiftPin(i, rift))
    end

    DEFAULT_CHAT_FRAME:AddMessage(
        AE.TAG .. " Карта разломов Пустоты открыта (" .. #RIFTS .. " разлома)."
    )
end

-- Подключение кнопки панели к карте
AE.SetRiftsHandler(AE.ShowRiftMap)
