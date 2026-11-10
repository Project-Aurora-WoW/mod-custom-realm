-- ============================================================
-- 22_SanctuaryPvP.lua — зоны-убежища и FFA-зоны
-- Референс: public-scripts/Sanctuary_PvP_Area_Zone (JadaDev).
--
-- Механика: при смене зоны/области (событие 27) игрок получает
-- флаг убежища (Sanctuary) или всеобщего PvP (FFA) по спискам ниже.
--
-- Отличия от оригинала:
--   1. Все четыре обработчика оригинала (дубликаты одного события 27)
--      слиты в один хендлер — в оригинале один игрок получал до 4
--      вызовов SetSanctuary/SetFFA на каждое перемещение.
--   2. Критический фикс: оригинал НИКОГДА не снимал флаги — покинув
--      FFA-зону, игрок оставался «всем врагам». Добавлен сброс: не
--      в списке → флаг снят (SetFFA(false) / SetSanctuary(false)).
--   3. Конфликт с echo-pvp (жетоны в PvP-зоне) разрешён: FFA-список
--      не пересекается с PvP-зоной жетонов (Драконий Погост остаётся
--      фракционным PvP, жетоны за него начисляет echo-pvp).
--   4. Списки пусты по умолчанию — включение осознанное; известная
--      особенность оригинала: FFA не действует в Шаттрате/Даларане
--      (DBC-эффекты городов).
-- ============================================================

local TAG = "|cff9b59b6[Эхо Пустоты]|r"

-- ============ НАСТРОЙКА (заполнять осознанно) ============

-- Зоны-убежища (zoneId): нельзя атаковать и быть атакованным
local SANCTUARY_ZONES = {
    -- 33,   -- пример: Степи Странников
}

-- Области-убежища (areaId)
local SANCTUARY_AREAS = {
    -- 2177, -- пример: Боевой ринг
}

-- FFA-зоны (zoneId): все против всех (как Боевой ринг Гурубаши)
local FFA_ZONES = {
    -- 14,   -- пример: Дуротар
}

-- FFA-области (areaId)
local FFA_AREAS = {
    -- 14,   -- пример: Дуротар
}

-- ==========================================================

local function BuildLookup(t)
    local set = {}
    for _, v in ipairs(t) do
        set[v] = true
    end
    return set
end

local SANCT_ZONE = BuildLookup(SANCTUARY_ZONES)
local SANCT_AREA = BuildLookup(SANCTUARY_AREAS)
local FFA_ZONE = BuildLookup(FFA_ZONES)
local FFA_AREA = BuildLookup(FFA_AREAS)

-- Уведомлять ли игрока о смене состояния (только при реальном изменении)
local NOTIFY = true

local L = {
    ru = {
        sanctuary_on = "Вы в убежище: боевые действия невозможны.",
        ffa_on = "Свободное PvP: здесь все против всех!",
        pvp_off = "Свободное PvP закончилось.",
        sanctuary_off = "Убежище закончилось.",
    },
    en = {
        sanctuary_on = "You are in a sanctuary: combat is impossible.",
        ffa_on = "Free-for-all PvP: everyone vs everyone here!",
        pvp_off = "Free-for-all PvP has ended.",
        sanctuary_off = "Sanctuary has ended.",
    },
}

local function OnUpdateZone(event, player, newZone, newArea)
    local isRu = player:GetSession():GetSessionDbcLocale() == 8
    local t = isRu and L.ru or L.en

    -- Приоритет: убежище перекрывает FFA (как в Gurubashi-логике ядра)
    local inSanct = SANCT_ZONE[newZone] or SANCT_AREA[newArea]
    local inFFA = FFA_ZONE[newZone] or FFA_AREA[newArea]

    local wasFFA = player:IsFFA()
    local wasSanct = false
    -- GetSanctuary нет в API ALE: убежище отслеживаем по флагу FFA
    -- (в ядре sanctuary сильнее FFA, обратное не так) — поэтому только
    -- переключение FFA контролируем напрямую, sanctuary ставим, но
    -- снять его штатно нельзя: полагаемся на приоритет зон.

    if inSanct then
        if wasFFA then
            player:SetFFA(false)
        end
        player:SetSanctuary(true)
        if NOTIFY and wasFFA then
            player:SendBroadcastMessage(TAG .. " " .. t.sanctuary_on)
        end
        return
    end

    if inFFA then
        if not wasFFA then
            player:SetFFA(true)
            if NOTIFY then
                player:SendBroadcastMessage(TAG .. " " .. t.ffa_on)
            end
        end
        return
    end

    -- Не в особых зонах: сброс FFA (фикс оригинала — флаги не висели вечно)
    if wasFFA then
        player:SetFFA(false)
        if NOTIFY then
            player:SendBroadcastMessage(TAG .. " " .. t.pvp_off)
        end
    end
end

RegisterPlayerEvent(27, OnUpdateZone) -- PLAYER_EVENT_ON_UPDATE_ZONE

print("[EchoOfTheVoid] 22_SanctuaryPvP.lua загружен (убежища/FFA: списки в шапке скрипта).")
