-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 18_VoidCorruption.lua
-- Назначение: система «Пустотная порча» (адаптация
-- eluna-scripts/Systems/corruption, автор Cloticc). Ношение
-- предметов Пустоты (item 70008 «Осколок Пустоты», 0018)
-- накапливает стаки порчи на кастомном спелле 70050
-- (spell_dbc, 0018). Пороги стаков включают дебаффы
-- (REG.corruption.debuffs): чем больше порчи — тем сильнее
-- гнёт Пустоты. Лор: осколки — «семена» осколков Усмешки.
-- Отличия от оригинала:
--   - ID предметов/спеллов/пороги — в реестре (REG.corruption);
--   - исправлен краш-баг оригинала: player:GetItemByEntry(id)
--     возвращает nil, когда предмет в сумке (не надет), и
--     вызов :IsEquipped() на nil падал — теперь проверка;
--   - стаки считаются корректно: в оригинале предмет в сумке
--     давал стак, при надевании сбрасывался (инверсия логики);
--     у нас: сумка ИЛИ надетый предмет = стак (простая модель
--     «носишь — портишься»);
--   - пороговые дебаффы оригинала — заглушки (там помечены как
--     пример); фактические ID — в реестре, подлежат выверке
--     на тестовом реалме (см. комментарий в реестре);
--   - событие 5 (ON_SPELL_CAST) из оригинала не переносится:
--     пересчёт на каждом касте — лишняя нагрузка; период
--     проверки — REG.corruption.check_interval_secs;
--   - локализация анонса пороги ru/en.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local COR = REG.corruption

if not COR.enabled then
    print("[EchoOfTheVoid] 18_VoidCorruption.lua загружен, но выключен (REG.corruption.enabled = false).")
    return
end

local WORLD_EVENT_ON_UPDATE = 13
local PLAYER_EVENT_ON_LOGIN = 3

local corruptionStacks = {} -- [guidLow] = totalStacks

-- ============================================================
-- Локализация (сообщения порогов)
-- ============================================================
local L = {
    en = {
        threshold = "The Void's corruption deepens within you... (%d stacks)",
        cleansed  = "The Void's corruption recedes.",
    },
    ru = {
        threshold = "Порча Пустоты глубже проникает в тебя... (%d стаков)",
        cleansed  = "Порча Пустоты отступает.",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Пересчёт порчи игрока
-- ============================================================

-- Подсчёт стаков по предметам: предмет в сумке ИЛИ надетый
-- (HasItem покрывает оба случая — модель «носишь — портишься»)
local function ComputeStacks(player)
    local total = 0
    for entry, stacks in pairs(COR.items) do
        if player:HasItem(entry) then
            total = total + stacks
        end
    end
    if total > COR.max_stacks then
        total = COR.max_stacks
    end
    return total
end

local function ApplyCorruption(player)
    if player:IsDead() then
        return
    end

    local guid = player:GetGUIDLow()
    local total = ComputeStacks(player)
    local prev = corruptionStacks[guid] or 0
    local loc = GetLocale(player)

    if total == 0 then
        if prev > 0 then
            -- Порча ушла: снять спелл и все пороговые дебаффы
            player:RemoveAura(COR.spell)
            for _, debuffs in pairs(COR.debuffs) do
                for _, debuff in ipairs(debuffs) do
                    player:RemoveAura(debuff)
                end
            end
            corruptionStacks[guid] = nil
            player:SendBroadcastMessage(TAG .. " " .. loc.cleansed)
        end
        return
    end

    -- Визуальный стакающийся маркер
    if not player:HasAura(COR.spell) then
        player:AddAura(COR.spell, player)
    end
    local aura = player:GetAura(COR.spell)
    if aura then
        aura:SetStackAmount(total)
    end

    -- Пороговые дебаффы
    for threshold, debuffs in pairs(COR.debuffs) do
        for _, debuff in ipairs(debuffs) do
            if total >= threshold then
                if not player:HasAura(debuff) then
                    player:AddAura(debuff, player)
                end
            else
                player:RemoveAura(debuff)
            end
        end
    end

    -- Сообщение при пересечении порога вверх
    for threshold, _ in pairs(COR.debuffs) do
        if total >= threshold and prev < threshold then
            player:SendBroadcastMessage(TAG .. " "
                .. string.format(loc.threshold, total))
            break
        end
    end

    corruptionStacks[guid] = total
end

-- ------------------------------------------------------------
-- Мир-тик: пересчёт всех игроков раз в check_interval_secs
-- (замена BOTH world-update-цикла и ON_SPELL_CAST оригинала)
-- ------------------------------------------------------------
local lastCheck = os.time()
local function OnWorldUpdate(event, diff)
    local now = os.time()
    if now - lastCheck < COR.check_interval_secs then
        return
    end
    lastCheck = now

    local players = GetPlayersInWorld()
    if not players then
        return
    end
    for _, player in ipairs(players) do
        if player and player:IsInWorld() then
            ApplyCorruption(player)
        end
    end
end

-- Быстрый первый пересчёт при логине (не ждать тик)
local function OnLogin(event, player)
    player:RegisterEvent(function(_, _, _, p)
        if p and p:IsInWorld() then
            ApplyCorruption(p)
        end
    end, 3000, 1)
end

RegisterServerEvent(WORLD_EVENT_ON_UPDATE, OnWorldUpdate)
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, OnLogin)

local itemCount = 0
for _ in pairs(COR.items) do itemCount = itemCount + 1 end
print(string.format(
    "[EchoOfTheVoid] 18_VoidCorruption.lua загружен (порча: спелл %d, предметов %d, период %d сек).",
    COR.spell, itemCount, COR.check_interval_secs))
