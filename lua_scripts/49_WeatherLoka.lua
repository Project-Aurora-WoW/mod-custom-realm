-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 49_WeatherLoka.lua
-- Атмосфера новых локаций: погода и звуки для кастомной карты 5000
-- (Остров Морза, Долина Предательства), где нет AreaTable-зоны в DBC.
--
-- Механика:
--   * ядро читает game_weather по произвольному zone id (WeatherMgr);
--   * для карты 5000 заведена запись zone = 5000 (0057_weather.sql);
--   * этот модуль при входе игрока на карту 5000 ставит погоду
--     map:SetWeather(5000, WEATHER_TYPE_SNOW/STORM, grade) и привязку
--     звуковой атмосферы (world music/sound), согласованную с лором:
--       Морза          — флотский перевал: метель Пустоты
--       Долина Предательства — разгар разлома: буря/черный дождь
--   * для зон Northrend (571) погоду даёт стоковая таблица
--     game_weather (4080/4395/4181) — здесь только гарантируем
--     перерисовку при входе (на случай, если игрок сменил зону).
--
-- Привязка звука/музыки: используем WorldObject:PlayMusic (на игрока)
-- и PlayDirectSound (для зоны), если ALE-сборка их поддерживает.
-- Интенсивность (grade) — 0..1. Типы: см. MapMethods.h enum WeatherType.
-- ============================================================

local TAG = "[EchoOfTheVoid][49_WeatherLoka]"

-- Константы WeatherType (MapMethods.h)
local WEATHER_FINE      = 0
local WEATHER_RAIN      = 1
local WEATHER_SNOW      = 2
local WEATHER_STORM     = 3
local WEATHER_THUNDERS  = 86
local WEATHER_BLACKRAIN = 90

-- Кастомная карта 5000 и её зоны (координаты якорей из PortalGuardian.lua)
local MAP_CUSTOM = 5000

-- Зона-«ядро» погоды на карте 5000 (запись в game_weather)
local ZONE_CUSTOM = 5000

-- Погода по каждой кастомной зоне карты 5000 (грубые области по координатам).
-- Внутри Морзы (тайлы 25-26/57-58) центр ~(-13950, 2877); Предательства
-- (48-50/12-14) центр ~(10461, -9574).
local function ZoneOf(mapId, x, y)
    if mapId ~= MAP_CUSTOM then return nil end
    -- Морза: X от -20000 до -5000, Y от 0 до 8000 (грубая область)
    if x < -5000 and x > -20000 and y > 0 and y < 8000 then
        return "morza"
    end
    -- Предательство: X от 6000 до 15000, Y от -12000 до -6000
    if x > 6000 and x < 15000 and y > -12000 and y < -6000 then
        return "betrayal"
    end
    return "morza"  -- запасной вариант по умолчанию
end

-- Получить Map-объект (через игрока)
local function GetMapOf(player)
    if not player or not player:IsInWorld() then return nil end
    local map = player:GetMap()
    return map and map.SetWeather ~= nil and map or nil
end

-- Применить погоду текущей зоны игроку
local function ApplyWeather(player)
    if not player or not player:IsInWorld() then return end
    local mapId = player:GetMapId()
    local zone = ZoneOf(mapId, player:GetX(), player:GetY())
    if not zone then
        -- Зоны Northrend: стоковая погода уже действует через game_weather,
        -- ничего не делаем (модуль отвечает только за карту 5000).
        return
    end

    local map = GetMapOf(player)
    if not map then return end

    -- Погода: снежный шторм / буря Пустоты в зависимости от зоны
    if zone == "betrayal" then
        map:SetWeather(ZONE_CUSTOM, WEATHER_STORM, 0.9)     -- буря разлома
    else
        map:SetWeather(ZONE_CUSTOM, WEATHER_SNOW, 0.7)      -- метель перевала
    end

    -- Звуковая атмосфера: фоновая музыка зоны (WorldObject:PlayMusic).
    -- Безопасный вызов: если метод недоступен в сборке — просто пропускаем.
    local playMusicFn = player.PlayMusic
    if type(playMusicFn) == "function" then
        -- Морза — мрачная метель (MusicId 580); Предательство — буря (590).
        pcall(player.PlayMusic, player, zone == "betrayal" and 590 or 580)
    end
end

-- ------------------------------------------------------------
-- Хуки
-- ------------------------------------------------------------

-- При входе в мир и при смене карты/зоны применяем атмосферу.
local function OnLoginOrMapChange(event, player)
    if player and player:IsPlayer() and player:IsInWorld() then
        ApplyWeather(player)
    end
end
RegisterPlayerEvent(3, OnLoginOrMapChange)                  -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(28, OnLoginOrMapChange)                 -- PLAYER_EVENT_ON_MAP_CHANGE

-- Периодически пере-применяем погоду (ядро регенерирует weather по зоне;
-- повторный SetWeather стабилизирует её и ловит смену зоны в пределах карты).
CreateLuaEvent(function()
    if not GetPlayersInWorld then return end
    local players = GetPlayersInWorld()
    if not players then return end
    for i = 1, #players do
        local p = players[i]
        if p and p:IsPlayer() and p:IsInWorld() and p:GetMapId() == MAP_CUSTOM then
            ApplyWeather(p)
        end
    end
end, 15000, 0)  -- каждые 15 сек

print(TAG .. " загружен: атмосфера карты 5000 (погода + звуки).")