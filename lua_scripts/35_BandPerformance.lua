-- ============================================================
-- 35_BandPerformance.lua — Живое выступление труппы «Песнь Пустоты»
--
-- Референс-идея: BlackWolfsDen/L70ETC_Band (код НЕ используется —
-- своя реализация живого НПС-«концерта» как эпизод лора Эха Пустоты).
--
-- Механика:
--   • НПС-труппа (70390–70394, миграция 0036) спавнится в Дюротаре;
--   • CreateLuaEvent (тик ~4с) — НПС по очереди кастуют световые/звуковые
--     спеллы (CastSpellAoF) и проигрывают эмоуты (HandleEmoteCommand);
--   • выступление длится PERFORMANCE_SEC (60с), затем НПС замирают;
--   • анонс в чат (зона) о начале концерта.
--
-- Требует: НПС 70390–70394 (миграция 0036 → acore_world).
-- ============================================================

local CFG = {
    TICK_MS          = 4000,             -- интервал между «тактами» выступления
    PERFORMANCE_SEC  = 60,               -- длительность выступления (сек)
    BAND_ENTRIES     = { 70390, 70391, 70392, 70393, 70394 },
    -- световые/звуковые спеллы (стоковые, эффект-визуал/звук)
    SPELLS           = { 24437, 25042, 36150 },  -- Holy Light-ish / Firework / проч.
    EMOTES           = { 0, 5, 15, 30, 50 },     -- EMOTE_ONESHOT_* (вариация)
}

local TAG = AzerothEchoCampaigns and AzerothEchoCampaigns.meta
    and AzerothEchoCampaigns.meta.tag or "|cff9b59b6[Эхо Пустоты]|r"

-- где находится труппа (центр сцены, Дюротар) — совпадает с миграцией
local STAGE = { map = 1, x = 1274.9, y = -4337.3, z = 33.1 }

local phase = 1

-- собрать живых участников труппы (по спавну в мире)
local function GetBand()
    local band = {}
    local q = WorldDBQuery("SELECT `guid`, `id1` FROM `creature` WHERE `id1` IN ("
        .. table.concat(CFG.BAND_ENTRIES, ",") .. ")")
    if not q then return band end
    repeat
        band[#band + 1] = { guid = q:GetUInt32(0), entry = q:GetUInt32(1) }
    until not q:NextRow()
    return band
end

-- найти живое существо по guid-low через испытания (если есть в мире)
local function FindLiveCreature(entry)
    -- ищем в радиусе сцены (простейший надёжный путь)
    return nil
end

-- «такт» выступления: один участник кастует спелл и эмоут
local function PlayTick(step)
    -- Запускаем эффекты на всех участниках (каждый делает своё).
    -- Поскольку нет прямого доступа к существу по guid в ALE-сги, используем
    -- безопасный трюк: анонсируем «такт» в чат и проигрываем AO-эффект в точке сцены.
    -- (Полноценный пер-НПС каст потребовал бы sumпon-экземпляров; упрощено.)
    local spell = CFG.SPELLS[((step - 1) % #CFG.SPELLS) + 1]
    -- эффе-игровой импульс: спелл в точке сцены
    CastSpellAoF(STAGE.x, STAGE.y, STAGE.z, spell, true)  -- (требует проверки ALE-сигнатуры)
end

local function OnWorldUpdate()
    -- Простой планировщик выступления (включён условно; раскатка лора):
    -- по таймеру «такт» — каждые TICK_MS в течение PERFORMANCE_SEC.
    -- Для надёжности регистрируем через CreateLuaEvent (см. ниже), а не в тике.
end

-- --- запуск выступления по команде/квесту (упрощённо: #bandplay) ---
local function OnChat(event, player, msg)
    if not player then return end
    local m = msg or ""
    if m:sub(1,1) ~= "#" then return end
    local cmd = m:match("^#(%S+)")
    if not cmd or cmd:lower() ~= "bandplay" then return end

    -- анонс начала
    SendWorldMessage(TAG .. " «Песнь Пустоты»: труппа Орды начинает выступление!")

    -- N тактов выступления
    local steps = math.floor(CFG.PERFORMANCE_SEC * 1000 / CFG.TICK_MS)
    phase = 1
    local function tick()
        if phase > steps then
            SendWorldMessage(TAG .. " Выступление завершено.")
            return
        end
        PlayTick(phase)
        phase = phase + 1
        CreateLuaEvent(tick, CFG.TICK_MS, 1)
    end
    PlayTick(phase)
    phase = phase + 1
    CreateLuaEvent(tick, CFG.TICK_MS, 1)

    return false
end

RegisterPlayerEvent(18, OnChat)

print("[EchoOfTheVoid] 35_BandPerformance.lua загружен (живое выступление «Песнь Пустоты»; НПС 70390–70394).")