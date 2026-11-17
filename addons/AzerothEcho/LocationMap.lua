-- ============================================================
-- AzerothEcho — LocationMap.lua (WoW 3.3.5a)
-- Карта локаций реалма «Эхо Пустоты» (серверная синхронизация).
-- Данные приходят с сервера по протоколу AECHOMAP (44_LocationMap.lua):
--   M;<mapId>;<count>;<key;name;x;y;color;desc>...   локации
--   P;<map>;<x>;<y>                                   позиция игрока
-- Открытие: /aemap, /ae map, хоткей (RiftMap-style кнопка на панели).
-- Пины локаций + метка позиции игрока на стоковой карте Northrend.
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR

-- ============================================================
-- Состояние (серверные данные)
-- ============================================================

local mapLocations = {}   -- { key = {name,x,y,color,desc} }
local playerMark = nil    -- { map, x, y }

-- ============================================================
-- Персональные метки (личные заметки на карте, savedVariables)
-- ============================================================

AzerothEchoMapDB = AzerothEchoMapDB or {}
AzerothEchoMapDB.marks = AzerothEchoMapDB.marks or {}

local MARK_META = { }
local markUI = {}   -- { pin frames }

-- Добавить/обновить метку на месте игрока
function AE.AddMapMark(name)
    name = name or ("Метка " .. (AzerothEchoMapDB.marks and #AzerothEchoMapDB.marks + 1 or 1))
    local map = GetCurrentMapContinent()
    local x, y = GetPlayerMapPosition("player")
    local key = string.format("%s:%s", map, y)
    table.insert(AzerothEchoMapDB.marks, {
        name = name,
        map  = map,
        x    = (x or 50) * 100,
        y    = (y or 50) * 100,
    })
    AE.NotifyChanged()
    if AE.ShowLocationMap and WorldMapFrame:IsShown() then
        AE.ShowLocationMap()
    end
end

-- Удалить метки (все на текущей карте)
function AE.ClearMapMarks()
    local map = GetCurrentMapContinent()
    for i = #AzerothEchoMapDB.marks, 1, -1 do
        if AzerothEchoMapDB.marks[i].map == map then
            table.remove(AzerothEchoMapDB.marks, i)
        end
    end
    AE.NotifyChanged()
    if AE.ShowLocationMap and WorldMapFrame:IsShown() then
        AE.ShowLocationMap()
    end
end

-- ============================================================
-- Парсинг payload сервера (AECHOMAP)
-- ============================================================

function AE.ParseLocationMap(payload)
    if not payload or payload == "" then return end
    local seg1 = string.match(payload, "^(M;[^;]+;[^;]+;.*)$")
    local segP = string.match(payload, "^(P;[^;]+;[^;]+;[^;]+.*)$")
    if seg1 and not segP then
        -- Начало списка локаций: M;mapId;count;...
        local _, count = string.match(seg1, "^M;%d+;(%d+)")
        mapLocations = {}
        -- Токены после заголовка
        local i = 0
        for tok in string.gmatch(seg1, "[^;]+") do
            i = i + 1
            -- токены: 1=M, 2=mapId, 3=count, затем группы по 6
        end
        -- Простой разбор: после 3 токенов заголовка идут блоки key;name;x;y;color;desc
        local body = string.match(seg1, "^M;%d+;%d+;(.*)$")
        if body then
            -- Разбиваем на блоки по 6 токенов
            local tokens = {}
            for t in string.gmatch(body, "[^;]+") do
                table.insert(tokens, t)
            end
            for idx = 1, #tokens, 6 do
                local key, name, x, y, color, desc =
                    tokens[idx], tokens[idx+1], tokens[idx+2], tokens[idx+3],
                    tokens[idx+4], tokens[idx+5]
                if key and name and x and y then
                    mapLocations[key] = {
                        name  = name,
                        x     = tonumber(x) or 50,
                        y     = tonumber(y) or 50,
                        color = color or "order",
                        desc  = desc or "",
                    }
                end
            end
        end
        AE.NotifyChanged()
    elseif segP then
        -- P;map;x;y
        local map, x, y = string.match(segP, "^P;(%d+);([%d%.]+);([%d%.]+)$")
        if map and x and y then
            playerMark = { map = tonumber(map), x = tonumber(x), y = tonumber(y) }
            UpdatePlayerPin()
            AE.NotifyChanged()
        end
    end
end

-- ============================================================
-- Пины локаций
-- ============================================================

local pins = {}

-- Постоянный пин позиции игрока (живой трекинг): переживает перерисовку
-- карты и двигается при каждом новом P от сервера, не пересоздаваясь.
local playerPin = nil

local COLOR_RGB = {
    order  = { 0.37, 0.55, 0.89 },
    void   = { 0.56, 0.27, 0.68 },
    cult   = { 0.75, 0.22, 0.17 },
    gold   = { 1.0, 1.0, 0.0 },
    red    = { 1.0, 0.27, 0.27 },
    blue   = { 0.0, 0.8, 1.0 },
}

local function countGen(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function ClearPins()
    for _, pin in ipairs(pins) do
        pin:Hide()
        pin:SetParent(nil)
    end
    pins = {}
end

-- Обновить позицию постоянного пина игрока на карте.
-- Создаёт пин при первом появлении, далее только двигает (без пересоздания).
local function UpdatePlayerPin()
    if not playerMark then return end
    if not WorldMapFrame:IsShown() then return end
    if not playerPin then
        playerPin = MakePin(WorldMapFrame, playerMark.x, playerMark.y,
            "Interface\\Minimap\\PlayerLocation", { 1, 1, 1 }, 14)
        playerPin:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(C.gold .. "Вы здесь|r")
            GameTooltip:Show()
        end)
        playerPin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        playerPin:ClearAllPoints()
        playerPin:SetPoint("CENTER", WorldMapFrame, "TOPLEFT",
            (playerMark.x / 100) * WorldMapFrame:GetWidth(),
            -(playerMark.y / 100) * WorldMapFrame:GetHeight())
    end
end

local function MakePin(frame, x, y, tex, rgb, size)
    local pin = CreateFrame("Frame", nil, frame)
    pin:SetWidth(size or 18)
    pin:SetHeight(size or 18)
    pin:SetFrameLevel(frame:GetFrameLevel() + 5)
    local t = pin:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(pin)
    t:SetTexture(tex or "Interface\\Minimap\\Ping")
    t:SetVertexColor(rgb[1], rgb[2], rgb[3])
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", frame, "TOPLEFT",
        (x / 100) * frame:GetWidth(),
        -(y / 100) * frame:GetHeight())
    return pin, t
end

-- ============================================================
-- Публичный API: показать карту локаций
-- ============================================================

function AE.ShowLocationMap()
    WorldMapFrame:Show()
    SetMapByID(571) -- Northrend

    ClearPins()

    -- Пины локаций из серверных данных
    for key, loc in pairs(mapLocations) do
        if loc.name then
            local rgb = COLOR_RGB[loc.color] or COLOR_RGB.order
            local pin = MakePin(WorldMapFrame, loc.x, loc.y, nil, rgb, 18)
            pin:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText((C[loc.color] or C.order) .. loc.name .. "|r")
                GameTooltip:AddLine(loc.desc, 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
            table.insert(pins, pin)
        end
    end

    UpdatePlayerPin()

    -- Персональные метки (личные заметки)
    local sway = 1
    for _, mark in ipairs(AzerothEchoMapDB.marks) do
        local pin = MakePin(WorldMapFrame, mark.x, mark.y,
            "Interface\\GroupFrame\\UI-Group-Ping-Blue", { 0.6, 1.0, 0.6 }, 14)
        pin:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(C.green .. mark.name .. "|r")
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Небольшое смещение, чтобы метки не накладывались точно друг на друга
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", WorldMapFrame, "TOPLEFT",
            (mark.x / 100) * WorldMapFrame:GetWidth() + (sway % 7 - 3) * 2,
            -(mark.y / 100) * WorldMapFrame:GetHeight() + (sway % 5 - 2) * 2)
        sway = sway + 1
        table.insert(pins, pin)
    end

    local locCount = countGen(mapLocations)
    local markCount = #AzerothEchoMapDB.marks
    DEFAULT_CHAT_FRAME:AddMessage(
        AE.TAG .. " Карта локаций реалма (" .. locCount .. " локаций, " ..
        markCount .. " меток). /aemap — открыть, /aemark — добавить метку."
    )
end

-- Приём серверного payload через AzerothEcho.lua (добавим префикс AECHOMAP)
AE.SetRiftsHandler = AE.SetRiftsHandler or function() end

-- Подключение кнопки панели «Карта локаций» к открытию окна
AE.SetMapToolsHandler(AE.ShowLocationMap)