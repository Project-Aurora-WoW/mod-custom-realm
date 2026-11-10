-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 10_EventSystem.lua
-- Назначение: авто-ивенты реалма по расписанию + GM-управление.
-- Ивенты (конфиг в 00_CampaignRegistry.lua):
--   storm — «Шторм Пустоты»: волны Ахерон-Пустотников у разлома
--   blood — «Кровавая Луна Культа»: культисты у разлома, жетоны
-- Награда: item 70005 «Жетон Эха» за убийство ивентовых мобов.
-- GM-команды (чат, только GM): .aeevent start|stop|status <key>
-- Спавн: PerformIngameSpawn(persistent=false) — мобы исчезают при
-- рестарте; по завершении ивента деспавн через creature:Despawn()
-- невозможен в ALE без объекта, поэтому спавним с lifetime:
--Creatиure сами исчезнут (см. комментарий к SpawnEventMobs).
-- Зависимость: 00_CampaignRegistry.lua (грузится раньше по алфавиту).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult
local TOKEN_ITEM = REG.meta.token_item
local MIN_LEVEL = REG.meta.min_level

-- Радиус зоны ивента вокруг разлома (yards)
local EVENT_ZONE_RADIUS = 60

-- Состояние ивентов: key = { active, end_time, spawnedCount }
local eventState = {}
for key, _ in pairs(REG.events) do
    if key ~= "rift" then
        eventState[key] = { active = false, end_time = 0, spawnedCount = 0 }
    end
end

-- ============================================================
-- Утилиты
-- ============================================================

local function EventIcon(key)
    return (key == "storm") and VOID_COLOR or CULT_COLOR
end

local function IsEventActive(key)
    return eventState[key].active
end

local function Announce(text)
    SendWorldMessage(TAG .. " " .. text)
end

-- ============================================================
-- Спавн волн ивентовых мобов
-- Мобы спавнятся непостоянно (persistent=false) и с временем жизни,
-- поэтому при рестарте сервера они исчезают сами, а по окончании
-- ивента их деспавнит движок (SpawnCreature с expiry).
-- ============================================================

local function SpawnEventMobs(key)
    local cfg = REG.events[key]
    local rift = REG.events.rift
    local spawned = 0

    for i = 1, cfg.mob_count do
        -- Кольцо вокруг разлома, радиус 10–25 ярдов
        local angle = (2 * math.pi * i / cfg.mob_count) + math.random() * 0.3
        local radius = 10 + math.random(15)
        local x = rift.x + math.cos(angle) * radius
        local y = rift.y + math.sin(angle) * radius

        -- PerformIngameSpawn(type=1 (creature), entry, map, x, y, z, o,
        --   persist=false, spawntimed=0, path=0)
        local creature = PerformIngameSpawn(1, cfg.mob_entry, rift.map, x, y, rift.z, rift.o, false, 0, 0)
        if creature then
            spawned = spawned + 1
        end
    end
    return spawned
end

-- ============================================================
-- Старт / остановка ивента
-- ============================================================

local function StartEvent(key)
    local cfg = REG.events[key]
    local state = eventState[key]
    if state.active then
        return false, "уже идёт"
    end

    state.active = true
    state.end_time = os.time() + cfg.duration_secs
    state.spawnedCount = SpawnEventMobs(key)

    Announce(EventIcon(key) .. cfg.name .. "|r начался! Разлом в Драконьем Погосте извергает врагов (" .. state.spawnedCount .. " шт.).")
    Announce("Убивай их и получай " .. VOID_COLOR .. "Жетоны Эха|r! Ивент продлится " .. math.floor(cfg.duration_secs / 60) .. " мин.")
    return true, "запущен"
end

local function StopEvent(key, silent)
    local cfg = REG.events[key]
    local state = eventState[key]
    if not state.active then
        return false, "не активен"
    end

    state.active = false
    state.end_time = 0
    state.spawnedCount = 0

    if not silent then
        Announce(EventIcon(key) .. cfg.name .. "|r завершён. Разлом затихает... до следующего раза.")
    end
    return true, "остановлен"
end

-- ============================================================
-- Награда за ивентовых мобов
-- Ивентовые мобы используют те же entry, что и обычные спавны,
-- поэтому награда выдаётся только если: ивент активен, моб умер
-- в радиусе разлома (зона ивента), киллер 80+.
-- ============================================================

local function OnEventMobDeath(event, killer, killed)
    if not killer or not killer:IsPlayer() then
        return
    end

    local entry = killed:GetEntry()
    if entry ~= REG.events.storm.mob_entry and entry ~= REG.events.blood.mob_entry then
        return
    end

    local rift = REG.events.rift
    local dist = math.sqrt((killed:GetX() - rift.x) ^ 2 + (killed:GetY() - rift.y) ^ 2)
    if dist > EVENT_ZONE_RADIUS then
        return
    end

    -- Определяем, какому ивенту соответствует entry моба
    local key
    if entry == REG.events.storm.mob_entry and IsEventActive("storm") then
        key = "storm"
    elseif entry == REG.events.blood.mob_entry and IsEventActive("blood") then
        key = "blood"
    end
    if not key then
        return
    end

    if killer:GetLevel() < MIN_LEVEL then
        return
    end

    local cfg = REG.events[key]
    killer:AddItem(TOKEN_ITEM, cfg.token_reward)
    killer:SendBroadcastMessage(TAG .. " +" .. cfg.token_reward .. " " .. VOID_COLOR .. "Жетон Эха|r — награда за ивент!")
end

RegisterPlayerEvent(7, OnEventMobDeath) -- PLAYER_EVENT_ON_CREATURE_KILL

-- ============================================================
-- GM-команды .aeevent start|stop|status <key>
-- Только игроки с GM-уровнем (player:GetGmRank() не пустой).
-- ============================================================

local function IsGM(player)
    local rank = player:GetGmRank and player:GetGmRank() or ""
    return rank ~= "" and rank ~= "player" and rank ~= "0"
end

local function OnPlayerChat(event, player, msg, lang, typ)
    if not IsGM(player) then
        return
    end

    local cmd, arg = string.match(msg, "^%.aeevent%s+(%a+)%s*(%S*)")
    if not cmd then
        return
    end

    local validKeys = {}
    for key, _ in pairs(REG.events) do
        if key ~= "rift" then
            table.insert(validKeys, key)
        end
    end
    local hint = table.concat(validKeys, ", ")

    if cmd == "start" or cmd == "stop" then
        if REG.events[arg] and arg ~= "rift" then
            local ok, why = (cmd == "start") and StartEvent(arg) or StopEvent(arg)
            player:SendBroadcastMessage(TAG .. " Ивент '" .. arg .. "': " .. why)
        else
            player:SendBroadcastMessage(TAG .. " Неизвестный ивент. Доступны: " .. hint)
        end
        return false -- блокируем сообщение в чат
    end

    if cmd == "status" then
        player:SendBroadcastMessage(TAG .. " == Статус ивентов ==")
        for key, cfg in pairs(REG.events) do
            if key ~= "rift" then
                local st = eventState[key]
                if st.active then
                    local left = math.max(0, math.floor((st.end_time - os.time()) / 60))
                    player:SendBroadcastMessage(TAG .. " " .. EventIcon(key) .. cfg.name .. "|r: активен, осталось " .. left .. " мин.")
                else
                    player:SendBroadcastMessage(TAG .. " " .. cfg.name .. ": не активен (расписание каждые " .. math.floor(cfg.interval_secs / 3600) .. " ч)")
                end
            end
        end
        return false
    end
end

RegisterPlayerEvent(18, OnPlayerChat) -- PLAYER_EVENT_ON_CHAT

-- ============================================================
-- Авто-расписание: мировой таймер каждые 5 минут.
-- Старт по «остатку от деления» unix-времени: когда текущее время
-- попадает в первые 5 минут интервала ивента — ивент запускается.
-- Для сдвига ивентов относительно друг друга интервалы выбраны
-- разными (3ч / 6ч) — они расходятся по фазе автоматически.
-- ============================================================

CreateLuaEvent(function()
    local now = os.time()
    for key, cfg in pairs(REG.events) do
        if key ~= "rift" and not eventState[key].active then
            if now % cfg.interval_secs < 300 then
                StartEvent(key)
            end
        end
    end

    -- Остановка истёкших ивентов
    for key, state in pairs(eventState) do
        if state.active and os.time() >= state.end_time then
            StopEvent(key)
        end
    end
end, 300000, 0) -- 300000 мс = 5 мин, бесконечно

-- ============================================================
-- Публичный API для других скриптов (AddonBridge.lua):
-- AE_EventActive(key) -> active(bool), minutesLeft(number)
-- AE_EventNext(key)   -> minutes до ближайшего планируемого старта
-- ============================================================

AE_EventActive = function(key)
    local state = eventState[key]
    if state and state.active then
        return true, math.max(0, math.floor((state.end_time - os.time()) / 60))
    end
    return false, 0
end

AE_EventNext = function(key)
    local cfg = REG.events[key]
    if not cfg then
        return -1
    end
    local state = eventState[key]
    -- Если ивент сейчас активен — следующий старт после его окончания:
    -- текущий конец + (interval - duration)
    local now = os.time()
    if state and state.active then
        local afterEnd = state.end_time + (cfg.interval_secs - cfg.duration_secs)
        return math.max(0, math.floor((afterEnd - now) / 60))
    end
    -- Если не активен: ближайший слот старта = следующий момент времени,
    -- кратный interval (слоты: now % interval < 300 => старт)
    local phase = now % cfg.interval_secs
    if phase < 300 then
        return 0 -- старт вот-вот (в текущем окне проверки)
    end
    return math.ceil((cfg.interval_secs - phase) / 60)
end

print("[EchoOfTheVoid] 10_EventSystem.lua загружен (ивенты: storm, blood; GM: .aeevent).")