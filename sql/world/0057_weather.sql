-- ============================================================
-- 0057_weather.sql
-- Атмосферные данные (погода) по зонам реалма «Эхо Пустоты».
--
-- Таблица game_weather (AzerothCore 3.3.5): погода привязана к ЗОНЕ
-- (zone id из AreaTable.dbc). Для каждой зоны задаётся шанс дождя/снега/
-- бури по сезонам (spring/summer/fall/winter; сумма процентов <= 100).
--
-- Зоны Northrend (571), где идут кампании Ордена:
--   4080 Драконий Погост   — эпицентр разлома Трона: стужа, метель, буря
--   4395 Даларан           — штаб Ордена: умеренный климат, дожди
--   4181 Зул'Драк          — древнее тролльское святилище: холод и туман
--
-- Кастомная карта 5000 НЕ имеет AreaTable/DBC-зоны, однако ядро читает
-- game_weather по произвольному zone id (WeatherMgr::LoadWeatherData
-- кладёт запись в _weatherData[zone_id] без сверки с AreaTable).
-- Поэтому карте 5000 задаём собственный zone id = 5000, погоду вешает
-- Lua-модуль (49_WeatherLoka.lua) через map:SetWeather(5000, ...).
--
-- Идемпотентно (DELETE + INSERT по zone).
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- Кастомная карта 5000: вечный снежный шторм Пустоты
-- (разлом Трона изливает холод в обе кастомные зоны).
-- ------------------------------------------------------------
DELETE FROM `game_weather` WHERE `zone` = 5000;
INSERT INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`,
 `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`,
 `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`,
 `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`,
 `ScriptName`) VALUES
(5000, 0, 40, 60, 0, 45, 55, 0, 40, 60, 0, 50, 50, '');

-- ------------------------------------------------------------
-- 4080 Драконий Погост: холодная метельная зона, высокий шанс
-- снега и бури круглый год (разлом Трона искажает климат).
-- ------------------------------------------------------------
DELETE FROM `game_weather` WHERE `zone` = 4080;
INSERT INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`,
 `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`,
 `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`,
 `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`,
 `ScriptName`) VALUES
(4080, 10, 50, 40, 5, 60, 35, 10, 55, 35, 5, 70, 25, '');

-- ------------------------------------------------------------
-- 4395 Даларан: умеренный климат, периодические дожди, редкий снег.
-- ------------------------------------------------------------
DELETE FROM `game_weather` WHERE `zone` = 4395;
INSERT INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`,
 `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`,
 `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`,
 `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`,
 `ScriptName`) VALUES
(4395, 30, 5, 2, 20, 0, 1, 28, 8, 2, 18, 15, 3, '');

-- ------------------------------------------------------------
-- 4181 Зул'Драк: холодное тролльское плато, снег и метель.
-- ------------------------------------------------------------
DELETE FROM `game_weather` WHERE `zone` = 4181;
INSERT INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`,
 `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`,
 `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`,
 `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`,
 `ScriptName`) VALUES
(4181, 15, 40, 20, 10, 45, 20, 12, 45, 18, 8, 55, 22, '');

-- ============================================================
-- КОНЕЦ 0057_weather.sql
-- ============================================================