-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 42_CurseWorld.lua
-- Назначение: модуль «Мир Проклятых» — ежемесячный турнир PvP+PvE.
-- Механика:
--   1. За зачётные PvP-киллы в зоне (Драконий Погост, 4080) и убийство
--      рейдовых боссов (REG.cursed.pve_bosses) игрок получает
--      «Осколок Проклятия» (item 70014).
--   2. Сезон длится REG.cursed.month_secs (30 дней). Счёт хранится в
--      realm_cursed_score (acore_characters, guid+season).
--   3. По итогам сезона игроки top-10 получают награды почтой
--      (REG.cursed.monthly_rewards) — выдача вручную GM-командой
--      .ae cursed reward (авто-тикер может закрыть сезон).
--   4. GM-команда .ae cursets — статус/топ/выдача/сброс.
-- Зависимость: 00_CampaignRegistry.ext (cursed), 0002 (campaign), 0046.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void
local ORDER_COLOR = REG.meta.colors.order

local CFG = REG.cursed
local TOKEN = CFG.token_item
local PVP_TOKEN_REWARD = CFG.token_reward_pvp
local PVE_TOKEN_REWARD = CFG.token_reward_pve
local ZONE_ID = CFG.zone_id
local RANK_TOP = CFG.rank_top
local MONTH_SECS = CFG.month_secs
local MONTHLY = CFG.monthly_rewards
local PVE_BOSSES = CFG.pve_bosses
local SCORE_TABLE = "realm_cursed_score"

local MIN_LEVEL_DIFF = REG.pvp.min_level_diff
local FARM_COOLDOWN = REG.pvp.farm_cooldown_secs

-- ============================================================
-- Локализация ru/en
-- ============================================================
local L = {
    ru = {
        pvpStart  = "+%d %sОсколок Проклятия|r — зачётный PvP-килл в проклятой зоне!",
        pveStart  = "+%d %sОсколок Проклятия|r — ты сокрушил проклятого босса!",
        status    = "== Мир Проклятых ==",
        statusRow = "Сезон: %d | Ваш счёт: %d (PvP %d + PvE %d)",
        topTitle  = "== Мир Проклятых: топ-%d сезона %d ==",
        topRow    = "%d. %s — %d осколков (PvP %d / PvE %d)",
        topEmpty  = "Пока никого. Сезон только начался.",
        rewardDone= "Награды сезона %d выданы. Топ-%d получателей.",
        rewardNone= "Сезон %d: некого награждать.",
        resetDone = "Сезон %d сброшен.",
        help      = ".ae cursed status|top|reward|reset",
    },
    en = {
        pvpStart  = "+%d %sShard of Curse|r — counted PvP kill in cursed zone!",
        pveStart  = "+%d %sShard of Curse|r — cursed boss slain!",
        status    = "== World of the Cursed ==",
        statusRow = "Season: %d | Your score: %d (PvP %d + PvE %d)",
        topTitle  = "== World of the Cursed: season %d top-%d ==",
        topRow    = "%d. %s — %d shards (PvP %d / PvE %d)",
        topEmpty  = "No one yet. The season just started.",
        rewardDone= "Season %d rewards issued. Top-%d recipients.",
        rewardNone= "Season %d: nobody to reward.",
        resetDone = "Season %d reset.",
        help      = ".ae cursed status|top|reward|reset",
    },
}
local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end
local function Loc(player, s, ...)
    local t = IsRu(player) and L.ru or L.en
    return string.format(t[s] or s, ...)
end

-- ============================================================
-- Сезон
-- ============================================================
local function CurrentSeason()
    -- Номер сезона: количество month_secs-интервалов от фиксированной
    -- эпохи (начинается с 1). Стабилен между рестартами.
    local epoch = 1262620800 -- 2010-01-05 UTC (произвольная точка отсчёта)
    return math.floor((os.time() - epoch) / MONTH_SECS) + 1
end

-- ============================================================
-- Счёт (realm_cursed_score)
-- ============================================================
local function AddScore(guid, season, pvp, pve)
    CharDBQuery(string.format(
        "INSERT INTO %s (guid, season, pvp_score, pve_score, total_score) VALUES (%d, %d, %d, %d, %d) " ..
        "ON DUPLICATE KEY UPDATE pvp_score = pvp_score + %d, pve_score = pve_score + %d, total_score = total_score + %d",
        SCORE_TABLE, guid, season, pvp, pve, pvp + pve, pvp, pve, pvp + pve
    ))
end

local function GetScore(guid, season, key)
    local q = CharDBQuery(string.format(
        "SELECT %s FROM %s WHERE guid = %d AND season = %d", key, SCORE_TABLE, guid, season
    ))
    if q then
        return q:GetUInt32(0)
    end
    return 0
end

-- ============================================================
-- Начисление за PvP-килл (событие 6 — KILL_PLAYER)
-- ============================================================
local function OnPvpKill(event, killer, killed)
    if not killer or not killer:IsPlayer() or not killed or not killed:IsPlayer() then
        return
    end
    -- Только в зоне турнира
    if killer:GetZoneId() ~= ZONE_ID then
        return
    end
    -- Анти-абюз: разница уровней
    if math.abs(killer:GetLevel() - killed:GetLevel()) > MIN_LEVEL_DIFF then
        return
    end
    local season = CurrentSeason()
    AddScore(killer:GetGUIDLow(), season, PVP_TOKEN_REWARD, 0)
    killer:AddItem(TOKEN, PVP_TOKEN_REWARD)
    killer:SendBroadcastMessage(TAG .. " " .. Loc(killer, "pvpStart", PVP_TOKEN_REWARD, VOID_COLOR))
end
RegisterPlayerEvent(6, OnPvpKill)

-- ============================================================
-- Начисление за PvE-босса (событие 7 — CREATURE_KILL)
-- ============================================================
local function OnPveBossKill(event, killer, killed)
    if not killer or not killer:IsPlayer() or not killed then
        return
    end
    local entry = killed:GetEntry()
    -- Проверяем, что убитый — проклятый босс из списка cursed
    local isBoss = false
    for _, e in pairs(PVE_BOSSES) do
        if e == entry then
            isBoss = true
            break
        end
    end
    if not isBoss then
        return
    end
    local season = CurrentSeason()
    AddScore(killer:GetGUIDLow(), season, 0, PVE_TOKEN_REWARD)
    killer:AddItem(TOKEN, PVE_TOKEN_REWARD)
    killer:SendBroadcastMessage(TAG .. " " .. Loc(killer, "pveStart", PVE_TOKEN_REWARD, VOID_COLOR))
end
RegisterPlayerEvent(7, OnPveBossKill)

-- ============================================================
-- GM-команда .ae cursed status|top|reward|reset
-- ============================================================
local function IsGM(player)
    local rank = (player.GetGmRank and player:GetGmRank()) or ""
    return rank ~= "" and rank ~= "player" and rank ~= "0"
end

local function OnPlayerChat(event, player, msg, lang, typ)
    if not IsGM(player) then
        return
    end
    local cmd, arg = string.match(msg, "^%.ae%s+cursed%s+(%a+)%s*(%S*)")
    if not cmd then
        return
    end

    local season = CurrentSeason()

    if cmd == "status" then
        local g = player:GetGUIDLow()
        local s = GetScore(g, season, "total_score")
        local pvp = GetScore(g, season, "pvp_score")
        local pve = GetScore(g, season, "pve_score")
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "status"))
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "statusRow", season, s, pvp, pve))
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "help"))
        return false
    end

    if cmd == "top" then
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "topTitle", season, RANK_TOP))
        local q = CharDBQuery(string.format(
            "SELECT guid, total_score, pvp_score, pve_score FROM %s WHERE season = %d ORDER BY total_score DESC LIMIT %d",
            SCORE_TABLE, season, RANK_TOP
        ))
        if q then
            local i = 0
            repeat
                i = i + 1
                local chart = CharDBQuery(string.format(
                    "SELECT name FROM characters WHERE guid = %d", q:GetUInt32(0)))
                local name = chart and chart:GetString(0) or ("#" .. q:GetUInt32(0))
                player:SendBroadcastMessage(TAG .. " " .. Loc(player, "topRow",
                    i, name, q:GetUInt32(1), q:GetUInt32(2), q:GetUInt32(3)))
            until not q:NextRow()
        else
            player:SendBroadcastMessage(TAG .. " " .. Loc(player, "topEmpty"))
        end
        return false
    end

    if cmd == "reward" then
        -- Выдать награды top-10 за текущий сезон.
        local q = CharDBQuery(string.format(
            "SELECT guid, total_score FROM %s WHERE season = %d ORDER BY total_score DESC LIMIT %d",
            SCORE_TABLE, season, RANK_TOP
        ))
        local count = 0
        if q then
            local i = 0
            repeat
                i = i + 1
                local guid = q:GetUInt32(0)
                local reward = MONTHLY[i]
                if reward then
                    SendMail(
                        "Награда «Мир Проклятых»",
                        "Твои деяния в сезоне не остались незамеченными. Прими награду за место #" .. i .. ".",
                        guid, nil, nil, 0, reward.item,
                        reward.count or 1
                    )
                    AddScore(guid, season, 0, 0) -- no-op, сохраняем строку
                    count = count + 1
                end
            until not q:NextRow()
        end
        if count > 0 then
            player:SendBroadcastMessage(TAG .. " " .. Loc(player, "rewardDone", season, RANK_TOP))
        else
            player:SendBroadcastMessage(TAG .. " " .. Loc(player, "rewardNone", season))
        end
        return false
    end

    if cmd == "reset" then
        -- GM-сброс текущего сезона (например, перед началом нового месяца)
        CharDBQuery(string.format("DELETE FROM %s WHERE season = %d", SCORE_TABLE, season))
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "resetDone", season))
        return false
    end

    player:SendBroadcastMessage(TAG .. " " .. Loc(player, "help"))
    return false
end
RegisterPlayerEvent(18, OnPlayerChat)

-- ============================================================
-- Авто-закрытие сезона: мировой таймер раз в час, если сезон
-- «старый» (время превысило конец месяца) — выдаёт награды и
-- очищает старые строки. Простая защита от двойной выдачи — флаг
-- в памяти сессии (не персистентен между рестартами; для боевого
-- сервера рекомендуется ручная выдача .ae cursed reward).
-- ============================================================
local rewardGivenFor = 0
CreateLuaEvent(function()
    local season = CurrentSeason()
    -- Если прошло больше одного месяца с начала текущего сезона —
    -- значит сезон закончился, выдаём награды (однократно за рестарт).
    local sEpoch = 1262620800 + (season - 1) * MONTH_SECS
    if os.time() - sEpoch > MONTH_SECS and rewardGivenFor ~= season then
        local q = CharDBQuery(string.format(
            "SELECT guid FROM %s WHERE season = %d ORDER BY total_score DESC LIMIT %d",
            SCORE_TABLE, season, RANK_TOP
        ))
        if q then
            local i = 0
            repeat
                i = i + 1
                local reward = MONTHLY[i]
                if reward then
                    SendMail("Награда «Мир Проклятых»",
                        "Автоматическая выдача за прошедший сезон. Место #" .. i .. ".",
                        q:GetUInt32(0), nil, nil, 0, reward.item, reward.count or 1)
                end
            until not q:NextRow()
        end
        rewardGivenFor = season
        -- Очистка завершённого сезона
        CharDBQuery(string.format("DELETE FROM %s WHERE season = %d", SCORE_TABLE, season))
        SendWorldMessage(TAG .. " " .. ORDER_COLOR .. "Сезон «Мир Проклятых» завершён!|r Награды отправлены лидерам.")
    end
end, 3600000, 0) -- каждый час

print("[EchoOfTheVoid] 42_CurseWorld.lua загружен (модуль «Мир Проклятых», GM: .ae cursed).")