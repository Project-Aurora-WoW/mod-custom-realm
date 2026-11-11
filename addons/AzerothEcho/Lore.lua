-- ============================================================
-- AzerothEcho — Lore.lua (WoW 3.3.5a)
-- Вкладка «Лор»: каталог реестра лора с сервера.
-- Данные приходят префиксом AECHOLORE (payload из
-- 00_LoreRegistry.ext: function Lore.Serialize(stage)).
-- Формат: stage:N|v:VER|s:id~title~line1^line2^...;...
-- До прихода данных показывается краткая справка (fallback).
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

AE.lore = { stage = 0, version = 0, sections = {}, order = {} }

-- ------------------------------------------------------------
-- Разбор payload'а от сервера
-- ------------------------------------------------------------
local function ParseLore(payload)
    local stage, version = 0, 0
    local sections, order = {}, {}

    for entry in string.gmatch(payload or "", "[^|]+") do
        local st = string.match(entry, "^stage:(%d+)$")
        local ver = string.match(entry, "^v:(%d+)$")
        if st then
            stage = tonumber(st) or 0
        elseif ver then
            version = tonumber(ver) or 0
        else
            local body = string.match(entry, "^s:(.+)$")
            if body then
                local id, title, rawLines = string.match(body, "^([^~]+)~([^~]+)~(.*)$")
                if id and title then
                    local lines = {}
                    for line in string.gmatch(rawLines or "", "[^^]+") do
                        table.insert(lines, line)
                    end
                    sections[id] = { id = id, title = title, lines = lines }
                    table.insert(order, id)
                end
            end
        end
    end

    AE.lore.stage = stage
    AE.lore.version = version
    AE.lore.sections = sections
    AE.lore.order = order
    AE.NotifyChanged()
end

AE.ParseLore = ParseLore

-- ------------------------------------------------------------
-- Страница вкладки «Лор»
-- ------------------------------------------------------------
local LORE_PAGE_INDEX = 4

local function BuildLorePage()
    local page = AE.pages and AE.pages[LORE_PAGE_INDEX]
    if not page then
        return
    end

    if page.scroll then
        page.scroll:Hide()
    end

    local fs = page.text
    if not fs then
        fs = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
        fs:SetJustifyH("LEFT")
        fs:SetWidth(300)
        page.text = fs
    end

    local parts = {}

    if #AE.lore.order == 0 then
        -- Fallback до ответа сервера
        parts[#parts + 1] = C.order .. "Орден Рассвета|r — коалиция Альянса и Орды."
        parts[#parts + 1] = C.cult .. "Культ Усмешки Бездны|r — служит шёпоту осколка."
        parts[#parts + 1] = ""
        parts[#parts + 1] = "Осколок Трона Короля-лича пропитался Пустотой."
        parts[#parts + 1] = "Пустота не убивает — она «иссушает»."
        parts[#parts + 1] = ""
        parts[#parts + 1] = C.void .. "Жетон Эха|r — валюта ивентов и PvP-зоны."
        parts[#parts + 1] = C.gray .. "Полный архив лора придёт с сервера.|r"
    else
        parts[#parts + 1] = C.gray .. "Стадия истории: " ..
            (AE.lore.stage or 0) .. " (v" .. (AE.lore.version or 0) .. ")|r"
        parts[#parts + 1] = ""

        for _, id in ipairs(AE.lore.order) do
            local s = AE.lore.sections[id]
            if s then
                parts[#parts + 1] = C.order .. "== " .. s.title .. " ==|r"
                for _, line in ipairs(s.lines) do
                    parts[#parts + 1] = line
                end
                parts[#parts + 1] = ""
            end
        end
    end

    fs:SetText(table.concat(parts, "\n"))
end

-- Перерисовка при поступлении новых данных
AE.OnDataChanged(BuildLorePage)

AE.BuildLorePage = BuildLorePage
