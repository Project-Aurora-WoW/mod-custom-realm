-- ============================================================
-- AzerothEcho — Hub.lua (WoW 3.3.5a)
-- Панель-хаб: кнопки-ссылки на другие аддоны реалма.
-- Открывает независимые аддоны (Journal, ArchaeologyUI) из любой
-- панели AzerothEcho через их публичные глобальные API.
-- Внешние аддоны НЕ трогаем: вызов только через pcall + проверку
-- существования. Если аддон не установлен — дружелюбное сообщение.
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

-- ============================================================
-- Описание внешних аддонов-хабов
-- ============================================================

local LINKS = {
    {
        label   = "Журнал приключений",
        tag     = "Journal",
        open    = function()
            if Journal and Journal.Toggle then
                Journal.Toggle()
            else
                return false -- аддон не установлен
            end
            return true
        end,
        missing = "Журнал (Journal) не установлен.",
    },
    {
        label   = "Археология",
        tag     = "ArchaeologyUI",
        open    = function()
            if ArchaeologyUI and ArchaeologyUI.ToggleWindow then
                ArchaeologyUI.ToggleWindow()
            else
                return false -- аддон не установлен или окно в другом драйве
            end
            return true
        end,
        missing = "Археология (ArchaeologyUI) не установлена.",
    },
}

-- ============================================================
-- Монтирование в панель AzerothEcho
-- ============================================================

local mounted = false

local function EnsureRow(frame)
    -- Нижний ряд панели уже есть: "Карта разломов" справа и "Закрыть" слева.
    -- Вставляем кнопки-ссылки по центру-слева, между ними.
    if not frame.toolsRow then
        local row = CreateFrame("Frame", nil, frame)
        row:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 42)
        row:SetWidth(300)
        row:SetHeight(24)
        frame.toolsRow = row

        -- Заголовок ряда
        local cap = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cap:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 0, 2)
        cap:SetText(C.gray .. "Прочее:|r")
    end
    return frame.toolsRow
end

local function Mount(frame)
    if mounted or not frame then return end
    mounted = true

    local row = EnsureRow(frame)
    local x = 0
    for _, link in ipairs(LINKS) do
        local btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        btn:SetWidth(140)
        btn:SetHeight(22)
        btn:SetPoint("LEFT", row, "LEFT", x, 0)
        btn:SetText(link.label)
        btn:SetScript("OnClick", function()
            local ok, err = pcall(link.open)
            if not ok or err == false then
                DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " " .. C.gray .. (link.missing or "Недоступно.") .. "|r")
            end
        end)
        x = x + 146
    end
end

-- Монтировать при создании панели (после Panel.lua).
-- Пусть панель будет создана к моменту загрузки Hub (порядок в .toc — осознанный:
-- Hub подключается после Panel.lua).
local panel = _G["AzerothEchoPanel"]
if panel then
    Mount(panel)
else
    -- Панель ещё не создана (например, изменился порядок загрузки) — подождём.
    _G.AzerothEchoHubMount = function() Mount(_G["AzerothEchoPanel"]) end
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addon)
        if addon == "AzerothEcho" then
            _G.AzerothEchoHubMount = nil
            Mount(_G["AzerothEchoPanel"])
            self:UnregisterAllEvents()
        end
    end)
end