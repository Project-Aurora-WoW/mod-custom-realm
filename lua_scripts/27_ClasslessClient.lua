-- ============================================================
-- 27_ClasslessClient.lua — клиентский AIO-UI Classless (полная версия)
-- Серверная логика: 27_Classless.lua (функции Learn/Unlearn/Reset,
-- реестр талантов из БД ядра talent_dbc/talenttab_dbc).
--
-- Доставляется клиенту через AIO (паттерн Store_Client.lua):
--   AIO.AddAddon() регистрирует файл для рассылки клиенту;
--   после guard'а выполняется ТОЛЬКО на клиенте.
--
-- Хендлер клиента: AIO.AddHandlers("CLASSLESS_UI", ...)
--   Index  — реестр талантов (дерево): talentID -> {classIdx,tabID,tier,col,maxRank,spellIDs}
--   Status — текущее состояние игрока (очки, изученные спеллы/глифы/таланты, resetCost)
--   Error  — сообщение об ошибке серверной валидации
--
-- Экран: фрейм с вкладками ЧУЖИХ классов -> внутри 3 спек-таба ->
-- сетка талантов (как стандартное окно талантов): ЛКМ = учить ранг,
-- ПКМ = снять, ховер = тултип спелла. Иконки/тултипы клиент берёт
-- сам через GetSpellTexture/GetSpellInfo по спеллу ранга.
-- ============================================================

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local L = {
    title = "|cff9b59b6Classless|r",
    tabs = "Классы",
    spec = { "Спек 1", "Спек 2", "Спек 3" },
    reset = "Сброс",
    rune = "Очки спеллов",
    tal = "Очки талантов",
    gM = "Глифы (бол.)",
    gm = "Глифы (мал.)",
    cost = "Цена:",
    nocard = "Нет данных Classless (серверный AIO недоступен).",
    reqOwn = "Это твой класс.",
    unavailable = "Нет доступа",
}

local CL = {
    index = nil,
    status = nil,
    curClass = nil,
    curTab = nil,
    ownClass = 0,   -- classIdx игрока (терминах CLASS_NAMES) для фильтра
    classes = {},   -- [classIdx] = { tabID = { specRows = {talentID=...}, specMeta } }
    specCache = {}, -- classIdx,tabID -> { width, height, cells }
    frame = nil,
}

local CL_UI = AIO.AddHandlers("CLASSLESS_UI", {})

-- Классы: classIdx (CLASS_NAMES 1..10) -> читаемое имя
local CLASS_NAMES = { "DK","Druid","Hunter","Mage","Paladin","Priest","Rogue","Shaman","Warlock","Warrior" }

function CL_UI.Index(player, index, ownClass)
    CL.index = index or {}
    CL.ownClass = ownClass or 0
    CL:BuildClasses()
    CL:RepaintClasses()
end

function CL_UI.Status(player, status)
    CL.status = status
    if CL.frame then
        CL:UpdateHeader()
        CL:UpdateGrid()
    end
end

function CL_UI.Error(player, msg)
    UIErrorsFrame:AddMessage("|cffff5555Classless: " .. tostring(msg) .. "|r", 1.0, 0.4, 0.4, 3)
end

-- ============================================================
-- Сборка структуры дерева из реестра
-- ============================================================
function CL:BuildClasses()
    CL.classes = {}
    for tid, e in pairs(CL.index or {}) do
        local ci, tab, tier, col, maxRank, spellIDs = e[1], e[2], e[3], e[4], e[5], e[6]
        if ci and ci > 0 and tab then
            CL.classes[ci] = CL.classes[ci] or { tabs = {} }
            CL.classes[ci].tabs[tab] = CL.classes[ci].tabs[tab] or { rows = {} }
            CL.classes[ci].tabs[tab].rows[tier] = CL.classes[ci].tabs[tab].rows[tier] or {}
            CL.classes[ci].tabs[tab].rows[tier][col] = {
                talentID = tid, maxRank = maxRank or 1, spellIDs = spellIDs or {},
            }
        end
    end
    -- вычислить размеры сетки по каждому (classIdx, tabID)
    CL.specCache = {}
    for ci, cl in pairs(CL.classes) do
        for tab, t in pairs(cl.tabs) do
            local width, height = 0, 0
            for tier, row in pairs(t.rows) do
                for col in pairs(row) do
                    if col > width then width = col end
                    if tier > height then height = tier end
                end
            end
            if width < 1 then width = 1 end
            if height < 1 then height = 1 end
            CL.specCache[ci] = CL.specCache[ci] or {}
            CL.specCache[ci][tab] = { width = width, height = height }
        end
    end
end

-- упорядоченные таб-списки класса
function CL:GetClassTabsSorted(ci)
    local cl = CL.classes[ci]
    if not cl then return {} end
    local tabs = {}
    for tab in pairs(cl.tabs) do table.insert(tabs, tab) end
    table.sort(tabs)
    return tabs
end

-- ============================================================
-- Фрейм
-- ============================================================
local CELL = 32

function CL:Create()
    if CL.frame then return end
    local f = CreateFrame("Frame", "CLASSLESS_FRAME", UIParent)
    f:SetSize(560, 430)
    f:SetPoint("CENTER", 0, 0)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    tinsert(UISpecialFrames, "CLASSLESS_FRAME")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", f, "TOP", 0, -10)
    f.title:SetText(L.title)

    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    f.close:SetScript("OnClick", function() CL:Toggle() end)

    -- статус-строка
    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.header:SetPoint("TOP", f, "TOP", 0, -40)

    -- класс-вкладки (top)
    f.classTabs = CreateFrame("Frame", nil, f)
    f.classTabs:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -70)
    f.classTabs.buttons = {}

    -- спек-вкладки (second row)
    f.specTabs = CreateFrame("Frame", nil, f)
    f.specTabs:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -98)
    f.specTabs.buttons = {}

    -- прокручиваемая сетка талантов
    f.scroll = CreateFrame("ScrollFrame", nil, f)
    f.scroll:SetPoint("TOPLEFT", 12, -126)
    f.scroll:SetPoint("TOPRIGHT", -12, -126)
    f.scroll:SetPoint("BOTTOMLEFT", 12, 30)
    f.scroll:SetPoint("BOTTOMRIGHT", -12, 30)
    f.scroll.grid = CreateFrame("Frame", nil, f.scroll)
    f.scroll.grid:SetPoint("TOPLEFT", f.scroll, "TOPLEFT")
    f.scroll:SetScrollChild(f.scroll.grid)

    -- reset-кнопка
    f.reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.reset:SetSize(80, 24)
    f.reset:SetPoint("BOTTOM", f, "BOTTOM", 0, 6)
    f.reset:SetText(L.reset)
    f.reset:SetScript("OnClick", function()
        AIO.Handle("CLASSLESS", "Reset")
    end)

    CL.frame = f
end

function CL:Toggle()
    if not CL.frame then CL:Create() end
    if CL.frame:IsShown() then
        CL.frame:Hide()
    else
        -- реестр талантов строится из ReqIndex; статус — из ReqStatus
        AIO.Handle("CLASSLESS", "ReqIndex")
        AIO.Handle("CLASSLESS", "ReqStatus")
        CL:UpdateHeader()
        CL:UpdateGrid()
        CL.frame:Show()
    end
end

function CL:UpdateHeader()
    local f = CL.frame
    local s = CL.status
    if not s then
        f.header:SetText(L.nocard)
        return
    end
    f.header:SetText(string.format(
        "%s %d/%d | %s %d/%d | %s %d/%d | %s %d/%d | %s %d" ,
        L.rune, s.spellPoints.alloc, s.spellPoints.total,
        L.tal, s.talentPoints.alloc, s.talentPoints.total,
        L.gM, s.glyphMajor.alloc, s.glyphMajor.total,
        L.gm, s.glyphMinor.alloc, s.glyphMinor.total,
        L.cost, s.resetCost / 10000))
end

-- вкладки классов
function CL:RepaintClasses()
    local tabBar = CL.frame.classTabs
    for _, b in pairs(tabBar.buttons) do b:Hide() end
    local idx = 0
    for ci, cl in pairs(CL.classes) do
        local name = CLASS_NAMES[ci] or ("Class" .. ci)
        if ci ~= CL.ownClass then -- только ЧУЖИЕ классы (свой — в стандартном окне)
            idx = idx + 1
            local b = tabBar.buttons[idx]
            if not b then
                b = CreateFrame("Button", nil, tabBar, "UIPanelTabTemplate")
                b:SetSize(90, 22)
                b:SetScript("OnClick", function(self)
                    CL.curClass = self.cls
                    for _, bb in pairs(tabBar.buttons) do bb:UnlockHighlight() end
                    self:LockHighlight()
                    CL:RepaintSpecs()
                end)
                tabBar.buttons[idx] = b
            end
            b.cls = ci
            b:SetText(name)
            b:SetPoint("LEFT", 8 + (idx - 1) * 94, 0)
            b:Show()
        end
    end
end

-- вкладки спеков текущего класса (берём все табы; сортируем по tabID)
function CL:RepaintSpecs()
    local sTabBar = CL.frame.specTabs
    for _, b in pairs(sTabBar.buttons) do b:Hide() end
    local tabs = CL.curClass and CL:GetClassTabsSorted(CL.curClass) or {}
    for i, tab in ipairs(tabs) do
        local b = sTabBar.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, sTabBar, "UIPanelTabTemplate")
            b:SetSize(80, 20)
            b:SetScript("OnClick", function(self)
                CL.curTab = self.tab
                for _, bb in pairs(sTabBar.buttons) do bb:UnlockHighlight() end
                self:LockHighlight()
                CL:UpdateGrid()
            end)
            sTabBar.buttons[i] = b
        end
        b.tab = tab
        b:SetText(L.spec[i] or ("Спек " .. i))
        b:SetPoint("LEFT", 6 + (i - 1) * 84, 0)
        b:Show()
        if i == 1 then b:LockHighlight() end
    end
    if not CL.curTab or tabs and not (CL.curClass and CL:HasTab(CL.curClass, CL.curTab)) then
        CL.curTab = tabs[1]
    end
    CL:UpdateGrid()
end

function CL:HasTab(ci, tab)
    local cl = CL.classes[ci]
    return cl and cl.tabs[tab] ~= nil
end

local function LreqRank(cell, r)
    return "Ранг: " .. (r or 0) .. "/" .. cell.maxRank
end

-- сетка талантов текущего (класс, спек)

function CL:UpdateGrid()
    local g = CL.frame.scroll.grid
    for _, b in pairs(g.cells or {}) do b:Hide() end
    local ci, tab = CL.curClass, CL.curTab
    if not ci or not tab then return end
    local cl = CL.classes[ci]
    local meta = CL.specCache[ci] and CL.specCache[ci][tab]
    if not cl or not cl.tabs[tab] or not meta then return end
    local width, height = meta.width, meta.height
    g.cells = g.cells or {}
    local status = CL.status
    local knownT = status and status.talents or {}
    -- известные спеллы/глифы/таланты игрока
    for tier, row in pairs(cl.tabs[tab].rows) do
        for col, cell in pairs(row) do
            local key = ci .. "_" .. tab .. "_" .. tier .. "_" .. col
            local btn = g.cells[key]
            if not btn then
                btn = CreateFrame("Button", "CL_CELL_" .. ci .. "_" .. tab .. "_" .. tier .. "_" .. col, g)
                btn:SetSize(CELL, CELL)
                btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                btn.icon = btn:CreateTexture(nil, "BACKGROUND")
                btn.icon:SetAllPoints(btn)
                btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.rank = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
                btn.rank:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 2)
                btn.rank:SetTextColor(1, 0.9, 0)
                btn:SetScript("OnEnter", function(self)
                    local ci2, tab2, tier2, col2 = self.cellClass, self.cellTab, self.cellTier, self.cellCol
                    local c2 = CL.classes[ci2].tabs[tab2].rows[tier2][col2]
                    local sp = c2.spellIDs[1]
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if sp then
                        GameTooltip:SetHyperlink("spell:" .. sp)
                        GameTooltip:AddLine(LreqRank(c2, self.dataRank), 1, 0.9, 0)
                    else
                        GameTooltip:AddLine("talent#" .. c2.talentID)
                    end
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                btn:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" then
                        -- учим следующий ранг (текущий + 1); если 0 — ранг 1
                        AIO.Handle("CLASSLESS", "Learn", "talent", self.cellTid, (self.dataRank or 0) + 1)
                    else
                        AIO.Handle("CLASSLESS", "Unlearn", "talent", self.cellTid)
                    end
                end)
                g.cells[key] = btn
            end
            btn.cellClass, btn.cellTab, btn.cellTier, btn.cellCol = ci, tab, tier, col
            btn.cellTid = cell.talentID
            local sp = cell.spellIDs[1]
            btn.icon:SetTexture(sp and GetSpellTexture(sp) or "Interface\\ICONS\\INV_Misc_QuestionMark")
            -- текущий ранг
            local curRank = 0
            for sid, t in pairs(knownT) do
                if t.talentID == cell.talentID then curRank = t.rank break end
            end
            btn.dataRank = curRank
            btn.rank:SetText("")
            btn:SetPoint("TOPLEFT", g, "TOPLEFT", (col - 1) * (CELL + 4), (1 - tier) * (CELL + 0))
            btn:Show()
        end
    end
    g:SetSize(width * (CELL + 4), height * (CELL + 2) + 8)
    CL.frame.scroll:UpdateScrollChildRect()
end

-- ============================================================
-- открытие командами / кнопкой
-- ============================================================
SLASH_CLASSLESS1 = "/classless"
SLASH_CLASSLESS2 = "/acl"
SlashCmdList["CLASSLESS"] = function()
    CL:Toggle()
end