-- ============================================================
-- 35_BandPerformance.lua — Живое выступление труппы «Песнь Пустоты»
--
-- Референс-идея: BlackWolfsDen/L70ETC_Band (код НЕ используется —
-- своя реализация живого НПС-«концерта» как эпизод лора Эха Пустоты).
--
-- Механика (исправлено по аудиту):
--   • НПС-труппа 70390–70394 спавнится в Дюротаре (миграция 0036);
--   • ВЫСТУПЛЕНИЕ: спавним отдельных «актёров» через PerformIngameSpawn
--     (spawntype=1, entry, mapId, 0, x,y,z,o, false, durms) и кастуем
--     эффект через их экземпляр (через возврат WorldObject->Creature);
--     кастовый интерфейс каст — unit:CastSpell/HandleEmoteCommand;
--   • экспорт глобальной _BAND_PLAY(mapId) — её вызывает 36_BandQuest
--     при сдаче Струн (фикс сопряжения);
--   • опция #bandplay (для GM/теста) и #bandtp (телепорт к сцене);
--   • анонс в world-чат.
--
-- Требует: НПС 70390–70394 (0036), предметы/цепочку (0037 → 36_BandQuest).
-- ============================================================

local CFG = {
    TICK_MS          = 4000,
    PERFORMANCE_SEC  = 60,
    BAND_ENTRIES     = { 70390, 70391, 70392, 70393, 70394 },
    SPELLS           = { 18137, 25042, 36150 }, -- эффект-вспышка/фейерверк/проч.
    EMOTES           = { 1, 2, 5, 15, 30 },
}

local TAG = AzerothEchoCampaigns and AzerothEchoCampaigns.meta
    and AzerothEchoCampaigns.meta.tag or "|cff9b59b6[Эхо Пустоты]|r"

-- фразы выступления (ru/en) — «диалоги» труппы
local SHOUTS = {
    { "«За Песнь Пустоты!»", "«For the Song of the Void!»" },
    { "«Пусть звучит наша боль!»", "«Let our pain be heard!»" },
    { "«Эхо ответит нам!»", "«The Echo will answer us!»" },
    { "«Рок для Эха Пустоты!»", "«Rock for the Echo of the Void!»" },
}

local STAGE = { map = 1, x = 1274.9, y = -4337.3, z = 33.1 }

local phase = 1
local running = false

-- Воспроизвести «такт»: спавн эфемерного актёра на сцене + эффект в точке.
-- (В ALE нет глобального геттера существ по guid; используем PerformIngameSpawn:
--  он возвращает Player/GameObject/Creature-экземпляр, на котором можно CastSpell.)
local function PlayTick(step)
    local entry = CFG.BAND_ENTRIES[((step - 1) % #CFG.BAND_ENTRIES) + 1]
    local spell = CFG.SPELLS[((step - 1) % #CFG.SPELLS) + 1]
    local emote = CFG.EMOTES[math.random(#CFG.EMOTES)]

    -- «диалог» труппы: случайная фраза в мир-чат (world-анонсы — ру, как 24_Lottery)
    local shout = SHOUTS[math.random(#SHOUTS)]
    SendWorldMessage(TAG .. " " .. shout[1])

    -- спавн «актёра» в точке сцены (кратко), получаем экземпляр
    local obj = PerformIngameSpawn(1, entry, STAGE.map, 0,
        STAGE.x, STAGE.y, STAGE.z, 0, false, 2500, 1)
    if obj then
        -- объект-актёр: эмоут + каст эффекта в точке (если доступны)
        local castable = (obj.CastSpell and obj) or nil
        if castable then
            pcall(function() castable:CastSpell(obj, spell, true) end)
        end
        if obj.HandleEmoteCommand then
            pcall(function() obj:HandleEmoteCommand(emote) end)
        end
    end
end

-- Главный запуск выступления (экспорт для 36_BandQuest)
local function BandPlay(mapId)
    if running then return end
    running = true
    phase = 1
    SendWorldMessage(TAG .. " «Песнь Пустоты»: труппа начинает выступление!")

    local steps = math.floor(CFG.PERFORMANCE_SEC * 1000 / CFG.TICK_MS)
    local function tick()
        if phase > steps then
            SendWorldMessage(TAG .. " Выступление завершено.")
            running = false
            return
        end
        PlayTick(phase)
        phase = phase + 1
        CreateLuaEvent(tick, CFG.TICK_MS, 1)
    end
    tick()
end
_G._BAND_PLAY = BandPlay          -- экспорт для 36_BandQuest (фикс сопряжения)

-- #bandplay (GM/тест) и #bandtp (телепорт к сцене)
local function OnChat(event, player, msg)
    if not player then return end
    local m = msg or ""
    if m:sub(1,1) ~= "#" then return end
    local cmd = m:match("^#(%S+)")
    if not cmd then return end
    local c = cmd:lower()

    if c == "bandplay" then
        if not player:IsGM() then return false end
        BandPlay(player:GetMapId())
        return false
    end
    if c == "bandtp" then
        player:TeleportTo(STAGE.map, STAGE.x, STAGE.y, STAGE.z, 0)
        return false
    end
    return false
end
RegisterPlayerEvent(18, OnChat)

print("[EchoOfTheVoid] 35_BandPerformance.lua загружен (выступление «Песнь Пустоты»; _BAND_PLAY экспортирован).")