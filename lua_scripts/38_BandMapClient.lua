-- ============================================================
-- 38_BandMapClient.lua — Клиентский маркер на минимапе: «Песнь Пустоты»
--
-- Доставляется клиенту через AIO (паттерн 27_ClasslessClient.lua):
--   AIO.AddAddon() — рассылка файла клиенту; после guard'а — клиентский код.
-- Сервер: 37_BandMap.lua (AIO-хендлер BAND_MAP).
--
-- Отображение: маркер на кромке минимапа, указывающий азимут на сцену
-- «Песнь Пустоты», когда игрок на той же карте, что и сцена. Локали ru/en.
--
-- Протокол:
--   клиент -> сервер : AIO.Handle("BAND_MAP", "GetCurrentScene")
--   сервер -> клиент : AIO.Handle(player,"BAND_MAP","SetTarget", mapId,x,y)
--   (маркер рисуется только когда игрок на карте сцены; иначе исчезает)
-- ============================================================

local AIO = AIO or require("AIO")
if AIO.AddAddon() then
    return
end

local BM = AIO.AddHandlers("BAND_MAP", {})

local L = {
    scene    = "Сцена «Песнь Пустоты»",
    scene_en = "Song of the Void stage",
}
local function IsRu() return GetLocale() == "ruRU" end
local function SceneName() return IsRu() and L.scene or L.scene_en end

local target = nil       -- { mapId, x, y }
local marker = nil
local onUpdate = nil

local function HideMarker()
    if marker then marker:Hide() end
end

-- Текущая карта игрока (континент). В клиенте 3.3.5a карта определяется
-- через GetCurrentMapAreaID() -> areaID континента. Сцена на карте 1
-- (Kalimdor, Дюротар 14 / Оргриммар 1637); показываем маркер на ней.
local KALIMDOR_AREAS = { [14] = true, [1637] = true }
local function PlayerOnTargetMap()
    if not target then return false end
    if target.mapId ~= 1 then return false end   -- мы поддерживаем только карту 1
    local area = GetCurrentMapAreaID and GetCurrentMapAreaID()
    if area and KALIMDOR_AREAS[area] then
        return true
    end
    -- fallback: какая-то область континента — считаем игрока на нужной карте
    return area == nil
end

local function Refresh()
    if not target or not PlayerOnTargetMap() then HideMarker() return end
    local px, py = UnitPosition("player")
    if not px or not py then return end
    local dx = target.x - px
    local dy = target.y - py
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.001 then HideMarker() return end
    dx, dy = dx / len, dy / len
    if not marker then
        marker = CreateFrame("Button", nil, Minimap)
        marker:SetSize(14, 14)
        marker:SetNormalTexture("Interface\\Minimap\\POIIcons")
        marker:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        marker:RegisterForClicks()
        marker:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(SceneName(), 1, 1, 1)
            GameTooltip:Show()
        end)
        marker:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- повторный расчёт позиции каждый кадр пока маркер виден
        onUpdate = CreateFrame("Frame")
        onUpdate:Hide()
        onUpdate:SetScript("OnUpdate", function()
            if marker and marker:IsShown() then
                local mx, my = UnitPosition("player")
                if mx and my then
                    local ddx = target.x - mx
                    local ddy = target.y - my
                    local dl = math.sqrt(ddx * ddx + ddy * ddy)
                    if dl > 0.001 then
                        marker:SetPoint("CENTER", Minimap, "CENTER",
                            (ddx / dl) * 40, (ddy / dl) * 40)
                    end
                end
            end
        end)
    end
    marker:ClearAllPoints()
    marker:SetPoint("CENTER", Minimap, "CENTER", dx * 40, dy * 40)
    marker:Show()
    onUpdate:Show()
end

function BM.SetTarget(player, mapId, x, y)
    if mapId == nil then
        target = nil
        HideMarker()
        return
    end
    target = { mapId = mapId, x = x, y = y }
    Refresh()
end

local function Request()
    if AIO and AIO.Handle then
        AIO.Handle("BAND_MAP", "GetCurrentScene")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", Request)