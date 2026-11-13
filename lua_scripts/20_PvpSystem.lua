-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 20_PvpSystem.lua
-- Назначение: PvP-подсистема реалма:
--   1. Статистика (таблица realm_pvp_stats, см. 0009_event_pvp.sql):
--      зачётные киллы/смерти, серии (streak), киллы в PvP-зоне.
--   2. Анти-абюз: килл не засчитывается при разнице уровней
--      > REG.pvp.min_level_diff или если тот же киллер убил ту же
--      жертву менее REG.pvp.farm_cooldown_secs назад (фарм-дуэли).
--   3. Killstreak-объявления в мир (пороги из реестра).
--   4. PvP-зона: Драконий Погост — жетоны за зачётные киллы.
--   5. Команда .aepvp top — топ-10 по киллам.
-- Зависимость: 00_CampaignRegistry.lua, 10_EventSystem.lua (жетоны).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void
local ORDER_COLOR = REG.meta.colors.order
local TOKEN_ITEM = REG.meta.token_item
local PVP_ZONE = REG.meta.dragonblight_zone   -- Драконий Погост

local MIN_LEVEL_DIFF = REG.pvp.min_level_diff
local FARM_COOLDOWN = REG.pvp.farm_cooldown_secs
local STREAK_ANNOUNCE = REG.pvp.streak_announce
local ZONE_TOKEN_KILL = REG.pvp.zone_token_kill

-- ============================================================
-- Локализация ru/en (DbcLocale 8 = ruRU, как в остальных скриптах)
-- ============================================================
local L = {
    ru = {
        killDiff      = "Килл не засчитан (разница уровней > %d).",
        killFarm      = "Килл не засчитан (фарм-защита: %d мин до следующего зачёта этой жертвы).",
        killToken     = "+%d %sЖетон Эха|r — килл в PvP-зоне Драконьего Погоста!",
        killVictim    = "Ваша серия прервана. Статистика: %d киллов.",
        topTitle      = "== PvP-Топ-10 реалма ==",
        topRow        = "%d. %s — киллы: %d, лучшая серия: %d, в зоне: %d",
        topEmpty      = "Пока никого. Иди заработай славу в Драконьем Погосте!",
        meRow         = "Ваша статистика: киллы %d | смерти %d | серия %d (лучшая %d) | в PvP-зоне %d | жетонов заработано %d",
        meEmpty       = "Статистика пуста. Первая кровь ждёт в Драконьем Погосте!",
        streak        = "(серия: %d)",
    },
    en = {
        killDiff      = "Kill not counted (level difference > %d).",
        killFarm      = "Kill not counted (farm-protection: %d min until this victim counts again).",
        killToken     = "+%d %sEcho Token|r — kill in Dragonblight PvP zone!",
        killVictim    = "Your streak is over. Stats: %d kills.",
        topTitle      = "== Realm PvP Top-10 ==",
        topRow        = "%d. %s — kills: %d, best streak: %d, in zone: %d",
        topEmpty      = "No one yet. Go earn glory in Dragonblight!",
        meRow         = "Your stats: kills %d | deaths %d | streak %d (best %d) | in PvP zone %d | tokens earned %d",
        meEmpty       = "No stats yet. First blood awaits in Dragonblight!",
        streak        = "(streak: %d)",
    },
}
local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end
local function loc(player, key, ...)
    local t = IsRu(player) and L.ru or L.en
    local s = t[key] or key
    if select('#', ...) > 0 then return string.format(s, ...) end
    return s
end

-- ============================================================
-- Работа со статистикой (realm_pvp_stats)
-- ============================================================

local function GetStats(guid)
    local q = CharDBQuery(string.format(
        "SELECT kills, deaths, streak, best_streak, zone_kills, tokens_earned FROM realm_pvp_stats WHERE guid = %d",
        guid
    ))
    if q then
        return {
            kills = q:GetUInt32(0), deaths = q:GetUInt32(1),
            streak = q:GetUInt32(2), best_streak = q:GetUInt32(3),
            zone_kills = q:GetUInt32(4), tokens_earned = q:GetUInt32(5),
        }
    end
    return nil
end

local function EnsureStatsRow(guid)
    CharDBQuery(string.format(
        "INSERT IGNORE INTO realm_pvp_stats (guid) VALUES (%d)",
        guid
    ))
end

local function UpdateStats(guid, fields)
    -- fields: строка "kills = kills + 1, streak = streak + 1" и т.п.
    CharDBQuery(string.format(
        "UPDATE realm_pvp_stats SET %s WHERE guid = %d",
        fields, guid
    ))
end

-- ============================================================
-- Зачёт килла
-- ============================================================

-- Зачёт килла: PLAYER_EVENT_ON_KILL_PLAYER (6) — киллер убил игрока.
-- ВНИМАНИЕ: событие 21 — это PLAYER_EVENT_ON_GUILD_CHAT (в Eluna
-- событие «Honorable Kill» под номером 21 не существует), прежняя
-- регистрация на 21 не срабатывала никогда.
local function OnPvpKill(event, killer, killed)
    -- Только игроки с обеих сторон
    if not killer or not killer:IsPlayer() or not killed or not killed:IsPlayer() then
        return
    end
    -- Не считать киллы на аренах/бг? В 3.3.5a HonorableKill событие
    -- срабатывает и там; для open-world статистики фильтруем локации
    -- арены (map 559-572 bg/arena идентификаторы опустим: считаем всё,
    -- анти-абюз по уровню и кулдауну отсекает накрутку)

    local killerGuid = killer:GetGUIDLow()
    local victimGuid = killed:GetGUIDLow()

    -- Анти-абюз 1: разница уровней
    if math.abs(killer:GetLevel() - killed:GetLevel()) > MIN_LEVEL_DIFF then
        killer:SendBroadcastMessage(TAG .. " " .. loc(killer, "killDiff", MIN_LEVEL_DIFF))
        return
    end

    -- Анти-абюз 2: повторный килл той же жертвы раньше кулдауна
    local stats = GetStats(killerGuid)
    if stats and stats.last_victim == victimGuid and stats.last_kill_time
       and (os.time() - stats.last_kill_time) < FARM_COOLDOWN then
        local mins = math.ceil((FARM_COOLDOWN - (os.time() - stats.last_kill_time)) / 60)
        killer:SendBroadcastMessage(TAG .. " " .. loc(killer, "killFarm", mins))
        return
    end

    EnsureStatsRow(killerGuid)
    EnsureStatsRow(victimGuid)

    local inZone = killer:GetZoneId() == PVP_ZONE

    -- Обновление киллера: kill++, streak++ (сброс через 10 мин бездействия),
    -- zone_kills++, жетоны в зоне
    local newStreak = (stats and stats.streak or 0) + 1
    UpdateStats(killerGuid, string.format(
        "kills = kills + 1, streak = %d, best_streak = GREATEST(best_streak, %d), last_victim = %d, last_kill_time = %d%s",
        newStreak, newStreak, victimGuid, os.time(),
        inZone and (", zone_kills = zone_kills + 1, tokens_earned = tokens_earned + " .. ZONE_TOKEN_KILL) or ""
    ))

    -- Жетон за килл в PvP-зоне
    if inZone then
        killer:AddItem(TOKEN_ITEM, ZONE_TOKEN_KILL)
        killer:SendBroadcastMessage(TAG .. " " .. loc(killer, "killToken", ZONE_TOKEN_KILL, VOID_COLOR))
    end

    -- Killstreak-объявления (пороги из реестра)
    local announce = STREAK_ANNOUNCE[newStreak]
    if announce then
        SendWorldMessage(TAG .. " " .. ORDER_COLOR .. killer:GetName() .. "|r " .. announce .. " (серия: " .. newStreak .. ")")
    end

    -- Смерть жертвы: deaths++, streak сброс
    UpdateStats(victimGuid, "deaths = deaths + 1, streak = 0")
    local deathMsg = GetStats(victimGuid)
    killed:SendBroadcastMessage(TAG .. " " .. loc(killed, "killVictim", deathMsg and deathMsg.kills or 0))
end

RegisterPlayerEvent(6, OnPvpKill) -- PLAYER_EVENT_ON_KILL_PLAYER = 6 (не 21: 21 = GUILD_CHAT)

-- ============================================================
-- Затухание серии: streak сбрасывается, если игрок 10+ минут
-- без зачётных киллов (проверка при входе в мир и по таймеру)
-- ============================================================

local STREAK_TIMEOUT = 600 -- сек

local function OnPlayerLogin(event, player)
    local stats = GetStats(player:GetGUIDLow())
    if stats and stats.streak > 0 and stats.last_kill_time
       and (os.time() - stats.last_kill_time) > STREAK_TIMEOUT then
        UpdateStats(player:GetGUIDLow(), "streak = 0")
    end
end

RegisterPlayerEvent(3, OnPlayerLogin) -- PLAYER_EVENT_ON_LOGIN

-- ============================================================
-- Команда .aepvp top — топ-10 по зачётным киллам
-- ============================================================

local function OnPvpChat(event, player, msg, lang, typ)
    local cmd, sub = string.match(msg, "^%.aepvp%s+(%a+)%s*(%S*)")
    if not cmd then
        return
    end

    if cmd == "top" then
        local q = CharDBQuery(
            "SELECT p.name, s.kills, s.best_streak, s.zone_kills FROM realm_pvp_stats s " ..
            "JOIN characters c ON c.guid = s.guid " ..
            "WHERE s.kills > 0 ORDER BY s.kills DESC LIMIT 10"
        )
        player:SendBroadcastMessage(TAG .. " " .. loc(player, "topTitle"))
        if q then
            local rank = 1
            repeat
                player:SendBroadcastMessage(
                    TAG .. " " .. loc(player, "topRow", rank, q:GetString(0), q:GetUInt32(1), q:GetUInt32(2), q:GetUInt32(3)))
                rank = rank + 1
            until not q:NextRow()
        else
            player:SendBroadcastMessage(TAG .. " " .. loc(player, "topEmpty"))
        end
        return false
    end

    if cmd == "me" then
        local stats = GetStats(player:GetGUIDLow())
        if stats and stats.kills > 0 then
            player:SendBroadcastMessage(
                TAG .. " " .. loc(player, "meRow", stats.kills, stats.deaths, stats.streak, stats.best_streak, stats.zone_kills, stats.tokens_earned))
        else
            player:SendBroadcastMessage(TAG .. " " .. loc(player, "meEmpty"))
        end
        return false
    end
end

RegisterPlayerEvent(18, OnPvpChat) -- PLAYER_EVENT_ON_CHAT

print("[EchoOfTheVoid] 20_PvpSystem.lua загружен (статистика, killstreak, PvP-зона, .aepvp).")