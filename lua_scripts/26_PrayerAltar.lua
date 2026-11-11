-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 26_PrayerAltar.lua
-- Назначение: алтарь молитвы (адаптация
-- eluna-scripts/Npc/prayToNpc.lua и prayObilisk.lua, Cloticc).
-- НПС 70178 «Алтарь Ордена» (0024): игрок, стоя рядом (<=2 ярда)
-- и выполнив /kneel (эмоут 59 «колени»), получает набор
-- благословений-баффов Sayge's Dark Fortune (строки алтаря
-- Праздника Силы Тысяч Cобак / Darkmoon; стоковые баффы 3.3.5a).
--
-- Отличия от оригинала:
--   - два скрипта (prayObilisk / prayToNpc) слиты в один; общий
--     хендлер события текстового эмоута (24) вместо «двух регистраций»
--     — в оригинале оба скрипта одновременно вешают один и тот же
--     хендлер на одно событие (конфликт);
--   - оригинал берёт «первое существо в радиусе 100 ярдов» и НЕ
--     проверяет дальность — берётся ближайшая НПС-цель, проверка
--     GetDistance <= maxRange (добавлена; в prayObilisk было в коде);
--   - добавлен кулдаун (REG.prayer.cooldown_secs) против пере-каста
--     баффов (в оригинале нет);
--   - экипируем баффы только если они не активны (AddAura на
--     существующей ауре просто обновляет стак — вызов безвреден);
--   - локализация ru/en.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order

local CFG = REG.tier_b and REG.tier_b.prayer
if not CFG or not CFG.enabled then
    print("[EchoOfTheVoid] 26_PrayerAltar.lua загружен, но выключен (REG.tier_b.prayer.enabled = false).")
    return
end

local NPC_ALTAR = CFG.npc
local EMOTE_KNEEL = CFG.emote          -- 59 = /kneel
local MAX_RANGE = CFG.max_range        -- ярдов
local SEARCH_RANGE = 100               -- радиус поиска ближайшего алтаря
local COOLDOWN = CFG.cooldown_secs

-- Баффы Sayge's Dark Fortune (стоковые 3.3.5a, Darkmoon Faire)
local BUFF_IDS = {
    23735, -- Sayge's Dark Fortune of Strength
    23737, -- Sayge's Dark Fortune of Stamina
    23738, -- Sayge's Dark Fortune of Spirit (в оригинале — Stamina dup)
    23766, -- Sayge's Dark Fortune of Intelligence
    23767, -- Sayge's Dark Fortune of Armor
    23736, -- Sayge's Dark Fortune of Agility
}

local PLAYER_EVENT_ON_TEXT_EMOTE = 24

local lastCast = {}  -- [guidLow] = os.time()

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        ok = "Your prayers are heard. The Order's blessings empower you.",
        far = "You are too far from the altar to offer your prayers.",
        cooldown = "The altar is spent. Return soon.",
        wrong = "You kneel, but nothing answers. This is not the Order's altar.",
    },
    ru = {
        ok = "Твои молитвы услышаны. Благословения Ордена наполняют тебя.",
        far = "Ты слишком далеко от алтаря, чтобы вознести молитву.",
        cooldown = "Алтарь остыл. Загляни позже.",
        wrong = "Ты преклоняешь колени, но в ответ — тишина. Это не алтарь Ордена.",
    },
}

local function L10n(player)
    return (player:GetSession():GetSessionDbcLocale() == 8) and L.ru or L.en
end

local function OnEmote(event, player, textEmote, emoteNum, guid)
    if textEmote ~= EMOTE_KNEEL then
        return
    end
    local t = L10n(player)

    -- Ближайший алтарь (entry 70178) в радиусе поиска
    local targets = player:GetCreaturesInRange(SEARCH_RANGE, NPC_ALTAR)
    if not targets or #targets == 0 then
        return -- рядом нет алтаря — ничего
    end
    local altar = targets[1]

    -- Дальность до алтаря (в оригинале не проверялось)
    local dist = player:GetDistance(altar)
    if not dist or dist > MAX_RANGE then
        player:SendBroadcastMessage(TAG .. " " .. t.far)
        return
    end

    -- Кулдаун (добавлен к оригиналу)
    local g = player:GetGUIDLow()
    local now = os.time()
    if lastCast[g] and (now - lastCast[g]) < COOLDOWN then
        player:SendBroadcastMessage(TAG .. " " .. t.cooldown)
        return
    end
    lastCast[g] = now

    -- Применить благословения
    for _, bid in ipairs(BUFF_IDS) do
        if not player:HasAura(bid) then
            player:AddAura(bid, player)
        end
    end

    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. t.ok .. "|r")
end

RegisterPlayerEvent(PLAYER_EVENT_ON_TEXT_EMOTE, OnEmote)

print(string.format(
    "[EchoOfTheVoid] 26_PrayerAltar.lua загружен (алтарь молитвы НПС %d, эмоут %d).",
    NPC_ALTAR, EMOTE_KNEEL))