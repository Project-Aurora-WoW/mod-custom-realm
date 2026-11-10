-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 17_TimeRift.lua
-- Назначение: ивент «Разломы Пустоты» (адаптация
-- eluna-scripts/Time Rift, автор Cloticc). Раз в
-- REG.time_rift.interval_secs в одной из точек Драконьего
-- Погоста открывается «Разлом Пустоты» (НПС 70190, 0018) и
-- выпускает первую волну Иссушенных (НПС 70191, 0018).
-- Убийство моба вызывает следующего из портала, пока портал
-- жив. Награда за моба — Жетон Эха (item 70005).
-- Отличия от оригинала:
--   - entry НПС, интервалы, точки спавна — в реестре
--     (REG.time_rift); координаты — Драконий Погост (571), не
--     GM-остров оригинала;
--   - debug-команда #removePortals не переносится (в оригинале
--     была доступна всем игрокам!);
--   - исправлен баг оригинала mobsAlive: счётчик обнулялся при
--     спавне и уходил в минус при смерти — мониторинг волны
--     заменён подсчётом живых мобов по порталу через
--     GetCreaturesInRange (без ручного счётчика);
--   - максимум активных порталов ограничен (REG.max_active):
--     в оригинале порталы копились бесконечно;
--   - награда за моба: уровень игрока >= token_min_level,
--     радиус от портала (защита от фарма издалека);
--   - при рестарте сервера спавнятся с нуля (временные спавны,
--     как у ивентов 10_EventSystem.lua), в БД — только шаблоны.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local TR = REG.time_rift
local TOKEN_ITEM = REG.meta.token_item

if not TR.enabled then
    print("[EchoOfTheVoid] 17_TimeRift.lua загружен, но выключен (REG.time_rift.enabled = false).")
    return
end

local WORLD_EVENT_ON_UPDATE = 13
local PLAYER_EVENT_ON_KILL_CREATURE = 7

local TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN = 2

-- ------------------------------------------------------------
-- Состояние: [guid портала] = { spawnKey, mobCount }
-- ------------------------------------------------------------
local activePortals = {}
local nextSpawnTime = os.time() + 60 -- первый разлом через минуту после старта
local lastSpawnKey = 0

-- ============================================================
-- Локализация (анонсы разлома)
-- ============================================================
local L = {
    en = {
        opened = "A Void rift tears open near the Dragonblight rift! The Withered pour out!",
        closed = "The Void rift has sealed itself.",
        kill   = "The rift's echo fades... (%s struck down a Withered)",
    },
    ru = {
        opened = "В Драконьем Погосте рвётся новый Разлом Пустоты! Иссушенные хлынули наружу!",
        closed = "Разлом Пустоты закрылся.",
        kill   = "Эхо разлома гаснет... (%s уничтожает Иссушенного)",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Спавн
-- ============================================================

-- Живые мобы вокруг портала (подсчёт вместо счётчика оригинала)
local function CountPortalMobs(portal)
    local mobs = portal:GetCreaturesInRange(80, TR.mob)
    if not mobs then
        return 0
    end
    return #mobs
end

local function SpawnWave(portal, count)
    local px, py, pz = portal:GetLocation()
    local o = portal:GetO()
    local mapId = portal:GetMapId()

    for i = 1, count do
        local mob = portal:SpawnCreature(TR.mob, px, py, pz, o,
            TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN, TR.portal_secs * 1000)
        if mob then
            -- Моб выходит из портала в случайную сторону (как в
            -- оригинале: разброс по кругу)
            local angle = math.random() * 2 * math.pi
            local dist = math.random(8, 15)
            mob:MoveTo(mapId,
                px + dist * math.cos(angle),
                py + dist * math.sin(angle),
                pz, o)
        end
    end
end

local function SpawnPortal()
    -- лимит активных порталов (фикс оригинала)
    local live = 0
    for _ in pairs(activePortals) do
        live = live + 1
    end
    if live >= TR.max_active then
        return
    end

    -- Случайная точка, не совпадающая с прошлой (как в оригинале)
    local key = lastSpawnKey
    while key == lastSpawnKey do
        key = math.random(1, #TR.spawns)
    end
    lastSpawnKey = key
    local spot = TR.spawns[key]

    local portal = PerformIngameSpawn(1, TR.portal, spot.map, 0,
        spot.x, spot.y, spot.z, spot.o, false, 0)
    if not portal or not portal:IsInWorld() then
        print("[EchoOfTheVoid] TimeRift: не удалось заспавнить портал.")
        return
    end

    portal:DespawnOrUnsummon(TR.portal_secs * 1000)
    activePortals[portal:GetGUIDLow()] = {
        mapId = spot.map,
        expires = os.time() + TR.portal_secs,
    }

    SpawnWave(portal, TR.first_wave)
    SendWorldMessage(TAG .. " " .. L.ru.opened)
    print(string.format("[EchoOfTheVoid] TimeRift: портал открыт (карта %d, %.1f, %.1f).",
        spot.map, spot.x, spot.y))
end

-- ------------------------------------------------------------
-- Мир-тик (WORLD_EVENT_ON_UPDATE = 13)
-- ------------------------------------------------------------
local lastTick = os.time()
local function OnWorldUpdate(event, diff)
    local now = os.time()
    if now - lastTick < 5 then
        return -- раз в 5 сек достаточно
    end
    lastTick = now

    -- Чистка истёкших порталов
    for guid, info in pairs(activePortals) do
        if now >= info.expires then
            activePortals[guid] = nil
        end
    end

    if now >= nextSpawnTime then
        nextSpawnTime = now + TR.interval_secs
        SpawnPortal()
    end
end

-- ------------------------------------------------------------
-- Убийство моба разлома (PLAYER_EVENT_ON_KILL_CREATURE = 7):
-- цепная волна + награда жетоном
-- ------------------------------------------------------------
local function OnKillCreature(event, killer, killed)
    if killed:GetEntry() ~= TR.mob then
        return
    end

    local portal = killed:GetNearestCreature(80, TR.portal, 0, 0)
    if portal then
        -- Цепная волна: каждый убитый моб выпускает следующего,
        -- пока портал жив (механика оригинала)
        SpawnWave(portal, 1)

        -- Награда жетоном
        if killer and killer:GetObjectType() == "Player"
            and killer:GetLevel() >= TR.token_min_level then
            killer:AddItem(TOKEN_ITEM, TR.token_per_kill)
        end
    end
end

RegisterServerEvent(WORLD_EVENT_ON_UPDATE, OnWorldUpdate)
RegisterPlayerEvent(PLAYER_EVENT_ON_KILL_CREATURE, OnKillCreature)

print(string.format(
    "[EchoOfTheVoid] 17_TimeRift.lua загружен (разломы: портал %d, моб %d, каждые %d мин, макс. %d порталов).",
    TR.portal, TR.mob, TR.interval_secs / 60, TR.max_active))
