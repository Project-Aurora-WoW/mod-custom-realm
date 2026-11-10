-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 05_VoidAuras.lua
-- Назначение: скриптовая система аур Пустоты «Эхо Шёпота».
-- Стоковый дебафф (33757) — визуальная основа; вся балансная
-- логика (стаки, шёпот, коллапс рассудка) в Lua, параметры —
-- в реестре (00_CampaignRegistry.lua -> void_aura).
-- Локализация: русский (ruRU-клиент) и английский — определяется
-- автоматически по локали клиента игрока.
-- Зависимость: глобальная таблица AzerothEchoCampaigns
-- (00_CampaignRegistry.lua, префикс 00_ гарантирует порядок).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local BASE_AURA = REG.meta.whisper_aura        -- визуальный дебафф (33757)
local DRAGONBLIGHT_ZONE = REG.meta.dragonblight_zone
local CFG = REG.void_aura
if not CFG then
    print("[EchoOfTheVoid] 05_VoidAuras.lua: в реестре нет секции void_aura — модуль отключён.")
    return
end

-- ============================================================
-- Локализация (ru по умолчанию, en для остальных локалей)
-- ============================================================

local L = {
    ru = {
        enter = "Эхо Шёпота|r проникает в разум...",
        stack_gained = "Шёпот усиливается... (%d/%d)",
        whisper = {
            "«Слышу тебя...», — шепчет разлом.",
            "«Ты не первый, кто слушал... и не последний, кто остался.»",
            "«Осколок помнит каждого, кто дошёл до него.»",
            "«Культ дарит покой. Пустота дарит вечность.»",
            "«Усмехнись... мы уже знаем твоё имя.»",
            "«Твой Свет здесь гаснет быстрее, чем свеча.»",
            "«Оглянись. Мы уже за твоей спиной.»",
        },
        collapse = "РАССУДОК ДРОБИТСЯ! Разум ваш не ваш...",
        leave = "Шёпот стихает. Разум возвращается под ваш контроль.",
    },
    en = {
        enter = "Whisper of the Echo|r creeps into your mind...",
        stack_gained = "The whisper grows stronger... (%d/%d)",
        whisper = {
            "\"I hear you...\", the rift whispers.",
            "\"You are not the first who listened... nor the last who remained.\"",
            "\"The Shard remembers everyone who reached it.\"",
            "\"The Cult offers peace. The Void offers eternity.\"",
            "\"Smile... we already know your name.\"",
            "\"Your Light fades faster than a candle here.\"",
            "\"Look behind you. We are already there.\"",
        },
        collapse = "YOUR MIND SHATTERS! Your will is no longer your own...",
        leave = "The whisper fades. Your mind returns to your control.",
    },
}

-- Определить локаль игрока ("ru" | "en")
local function GetPlayerLocale(player)
    -- DBC-локали 3.3.5a: 0=enUS, 1=koKR, 2=frFR, 3=deDE, 4=zhCN, 5=zhTW,
    -- 6=esES, 7=esMX, 8=ruRU
    local ok, loc = pcall(function() return player:GetDbcLocale() end)
    if ok and loc == 8 then return "ru" end
    return "en"
end

-- Локализованная строка по ключу
local function L10N(player, key)
    local loc = L[GetPlayerLocale(player)] or L.ru
    return loc[key]
end

-- ============================================================
-- Состояние стаков (в памяти; сброс при выходе из зоны)
-- ============================================================

local playerStacks = {}

local function GetStacks(player)
    return playerStacks[player:GetGUIDLow()] or 0
end

local function SetStacks(player, n)
    playerStacks[player:GetGUIDLow()] = n
end

local function ClearStacks(player)
    playerStacks[player:GetGUIDLow()] = nil
end

local function HasBaseAura(player)
    return player:HasAura(BASE_AURA)
end

local function ApplyBaseAura(player)
    if not HasBaseAura(player) then
        player:AddAura(BASE_AURA, player)
    end
end

-- ============================================================
-- Тик стаков: у разлома каждые stack_interval_secs секунд +1 стак
-- ============================================================

local function StackTick(eventId, delay, repeats, player)
    if not player or not player:IsInWorld() then return end
    if player:GetZoneId() ~= DRAGONBLIGHT_ZONE or not HasBaseAura(player) then return end

    local stacks = GetStacks(player)
    if stacks >= CFG.max_stacks then return end

    stacks = stacks + 1
    SetStacks(player, stacks)
    player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. string.format(L10N(player, "stack_gained"), stacks, CFG.max_stacks))

    -- Коллапс рассудка при достижении max_stacks
    if stacks >= CFG.max_stacks then
        local dmg = math.floor(player:GetMaxHealth() * CFG.collapse_damage_pct / 100)
        if dmg > 0 then
            player:DealDamage(player, dmg, nil, false)
        end
        player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. L10N(player, "collapse"))
    end
end

-- ============================================================
-- Тик шёпота: локализованные реплики + урон рассудка за стаки
-- ============================================================

local function WhisperTick(eventId, delay, repeats, player)
    if not player or not player:IsInWorld() then return end
    if not HasBaseAura(player) then return end

    local stacks = GetStacks(player)
    if stacks <= 0 then return end

    local msgTable = L10N(player, "whisper")
    local whisper = msgTable[math.random(1, #msgTable)]
    player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. whisper)

    -- «Иссушение рассудка»: % от макс. HP за каждый стак
    local dmg = math.floor(player:GetMaxHealth() * CFG.sanity_damage_pct / 100 * stacks)
    if dmg > 0 then
        player:DealDamage(player, dmg, nil, false)
    end
end

-- ============================================================
-- Вход/выход из зоны разлома
-- ============================================================

local function OnUpdateZone(event, player, newZone, newArea)
    if newZone == DRAGONBLIGHT_ZONE then
        -- Лор: разлом действует на всех игроков независимо от кампании
        ApplyBaseAura(player)
        SetStacks(player, 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. L10N(player, "enter"))

        -- Периодические тики: стаки + шёпот/урон
        player:RegisterEvent(StackTick, CFG.stack_interval_secs * 1000, 0)
        player:RegisterEvent(WhisperTick, CFG.whisper_interval_secs * 1000, 0)
    else
        if HasBaseAura(player) then
            player:RemoveAura(BASE_AURA)
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. L10N(player, "leave"))
        end
        ClearStacks(player)
        player:RemoveEvents() -- отменяет RegisterEvent-тики игрока
    end
end

RegisterPlayerEvent(42, OnUpdateZone)   -- PLAYER_EVENT_ON_UPDATE_ZONE = 42

print("[EchoOfTheVoid] 05_VoidAuras.lua загружен (ауры Пустоты, ru/en).")
