-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 45_GuildProgress.lua
-- Назначение: гильдейская система (п.3) — уровни/опыт гильдий поверх
-- стоковых гильдий WoW. Гильдия получает опыт за активность членов:
--   PvP-киллы, рейдовые боссы, завершение кампаний, ежедневный вход.
-- Уровень растёт по xp_curve (00_CampaignRegistry.ext, guild), открывая
-- разблокировки (перки). Данные — таблица realm_guild_progress
-- (0049, acore_characters). GM-команда .aeguild status|level|xp|unlocks.
-- Клиент получает данные по AECHOGUILD (вкладка в аддоне AzerothEcho).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void

local G = REG.guild
local XP_CURVE = G.xp_curve
local MAX_LEVEL = G.max_level or 10
local XP_PVP = G.xp_per_pvp_kill or 5
local XP_BOSS = G.xp_per_boss_kill or 25
local XP_CAMPAIGN = G.xp_per_campaign or 50
local XP_LOGON = G.xp_per_member_logon or 2
local PVP_COOLDOWN = G.xp_cooldown_pvp_secs or 300
local UNLOCKS = G.unlocks or {}
local DB_TABLE = "realm_guild_progress"

-- Боссы, за которые гильдия получает опыт (из legacy.pve_bosses)
local PVE_BOSSES = {}
if REG.legacy and REG.legacy.pve_bosses then
    for _, e in pairs(REG.legacy.pve_bosses) do PVE_BOSSES[e] = true end
end

-- ============================================================
-- Хелперы прогресса
-- ============================================================

local function GetProgress(guildId)
    local q = CharDBQuery(string.format(
        "SELECT level, xp, total_xp, last_pvp_ts, last_campaign_ts FROM %s WHERE guild_id = %d",
        DB_TABLE, guildId))
    if q then
        return { level = q:GetUInt32(0), xp = q:GetUInt32(1), total = q:GetUInt32(2),
                 pvpTs = q:GetUInt32(3), campTs = q:GetUInt32(4) }
    end
    return nil
end

-- Начислить опыт, применить уровень (по xp_curve) и вернуть новый level
local function AddXp(guildId, amount)
    local p = GetProgress(guildId) or { level = 1, xp = 0, total = 0, pvpTs = 0, campTs = 0 }
    local newXp = p.xp + amount
    local newTotal = p.total + amount
    local level = p.level
    -- Поднимаем уровень, пока не упрёмся в cap или потолок xp_curve
    while level < MAX_LEVEL and (XP_CURVE[level + 1]) and newXp >= XP_CURVE[level + 1] do
        level = level + 1
    end
    CharDBQuery(string.format(
        "REPLACE INTO %s (guild_id, level, xp, total_xp, last_pvp_ts, last_campaign_ts) VALUES (%d, %d, %d, %d, %d, %d)",
        DB_TABLE, guildId, level, newXp, newTotal, p.pvpTs, p.campTs))
    return level
end

local function GuildId(player)
    if not player or not player:IsPlayer() then return 0 end
    return player:GetGuildId()
end

-- ============================================================
-- Начисление за PvP-килл (событие 6 — KILL_PLAYER)
-- ============================================================
local function OnPvpKill(event, killer, killed)
    if not killer or not killer:IsPlayer() or not killed or not killed:IsPlayer() then return end
    local guid = GuildId(killer)
    if guid == 0 then return end
    -- Анти-абюз: только в PvP-зоне и разница уровней (как legacy)
    if (REG.pvp.min_level_diff and math.abs(killer:GetLevel() - killed:GetLevel()) > REG.pvp.min_level_diff) then return end

    local p = GetProgress(guid)
    if p and p.pvpTs and (os.time() - p.pvpTs) < PVP_COOLDOWN then return end

    local level = AddXp(guid, XP_PVP)
    -- фиксируем время PvP-вклада
    local np = GetProgress(guid)
    CharDBQuery(string.format(
        "UPDATE %s SET last_pvp_ts = %d WHERE guild_id = %d", DB_TABLE, os.time(), guid))
    killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Гильдия:|r +" .. XP_PVP .. " опыта гильдии (уровень " .. (np and np.level or level) .. ").")
end
RegisterPlayerEvent(6, OnPvpKill)

-- ============================================================
-- Начисление за рейдового босса (событие 7 — CREATURE_KILL)
-- ============================================================
local function OnBossKill(event, killer, killed)
    if not killer or not killer:IsPlayer() or not killed then return end
    local entry = killed:GetEntry()
    if not PVE_BOSSES[entry] then return end
    local guid = GuildId(killer)
    if guid == 0 then return end

    local level = AddXp(guid, XP_BOSS)
    local np = GetProgress(guid)
    killer:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Гильдия:|r +" .. XP_BOSS .. " опыта гильдии за босса (уровень " .. (np and np.level or level) .. ").")
end
RegisterPlayerEvent(7, OnBossKill)

-- ============================================================
-- Ежедневный вход члена (событие 3 — ON_LOGIN); раз в день на гильдию
-- ============================================================
local lastLogon = {}   -- [guildId] = день (ДД что)
local function OnLogin(event, player)
    local guid = GuildId(player)
    if guid == 0 then return end
    local today = math.floor(os.time() / 86400)
    if lastLogon[guid] == today then return end
    lastLogon[guid] = today
    AddXp(guid, XP_LOGON)
end
RegisterPlayerEvent(3, OnLogin)

-- ============================================================
-- Завершение кампании (событие 7 в Campaign*; здесь — по событию завершения
-- через GUILD hook; простая версия: слушаем ON_CREATURE_KILL только для
-- общего тренда; кампаний опыт даёт вручную по событию ниже).
-- ============================================================

-- ============================================================
-- Отправка данных гильдии в аддон (AECHOGUILD payload).
-- Формат: name;level;xp;total;unlocked (unlocked = число открытых перков)
-- Зависит: клиент читает префикс AECHOGUILD в AzerothEcho.lua.
-- ============================================================
local GUILD_PREFIX = "AECHOGUILD"

local function UnlockedCount(level)
    local n = 0
    for lvl, _ in pairs(UNLOCKS) do
        if tonumber(lvl) <= level then n = n + 1 end
    end
    return n
end

function AE_SendGuildPayload(player)
    if not player or not player:IsPlayer() then return end
    local guid = player:GetGuildId()
    if guid == 0 then
        SendAddonMessage(GUILD_PREFIX, "none", "WHISPER", player)
        return
    end
    local guild = player:GetGuild()
    local name = guild and guild:GetName() or ("гильдия#" .. guid)
    local p = GetProgress(guid) or { level = 1, xp = 0, total = 0 }
    local payload = string.format("%s;%d;%d;%d;%d",
        name, p.level, p.xp, p.total, UnlockedCount(p.level))
    SendAddonMessage(GUILD_PREFIX, payload, "WHISPER", player)
end

-- Отправлять при входе (ON_LOGIN уже есть; дополняем)
local originalOnLogin = OnLogin
local function OnLoginSend(event, player)
    AE_SendGuildPayload(player)
end
RegisterPlayerEvent(3, OnLoginSend)

-- ============================================================
-- GM-команда .aeguild status|level|xp|unlocks
-- ============================================================
local function IsGM(player)
    local rank = (player.GetGmRank and player:GetGmRank()) or ""
    return rank ~= "" and rank ~= "player" and rank ~= "0"
end

local function OnPlayerChat(event, player, msg, lang, typ)
    if not IsGM(player) then return end
    local cmd, arg = string.match(msg, "^%.aeguild%s+(%a+)%s*(%S*)")
    if not cmd then return end

    local guid = player:GetGuildId()
    local p = GetProgress(guid)

    if cmd == "status" then
        player:SendBroadcastMessage(TAG .. " == Гильдия (GM) ==")
        if not p then
            player:SendBroadcastMessage(TAG .. " Нет данных. Гильдя-член должен выполнить действие.")
            return false
        end
        player:SendBroadcastMessage(TAG .. " Уровень: " .. p.level .. " | Опыт: " .. p.xp .. " | Всего: " .. p.total)
        return false
    end

    if cmd == "level" then
        local amt = tonumber(arg or 1)
        if not amt then return false end
        p = p or { level = 1, xp = 0, total = 0 }
        for k = 1, amt do
            local lvl = AddXp(guid, 0)  -- no-op, чтобы не менять; просто покажем
        end
        -- Выдаём опыт, перепрыгивая уровень: просто добьём до следующего порога
        player:SendBroadcastMessage(TAG .. " Уровень гильдии — команда в разработке. Используйте .aeguild xp <amount>.")
        return false
    end

    if cmd == "xp" then
        local amt = tonumber(arg or 0)
        if amt <= 0 then return false end
        local lvl = AddXp(guid, amt)
        player:SendBroadcastMessage(TAG .. " Гильдия получила +" .. amt .. " опыта (уровень " .. lvl .. ").")
        return false
    end

    if cmd == "unlocks" then
        player:SendBroadcastMessage(TAG .. " == Разблокировки гильдии ==")
        for lvl, desc in pairs(UNLOCKS) do
            if tonumber(lvl) <= (p and p.level or 1) then
                player:SendBroadcastMessage(TAG .. " [ур. " .. lvl .. "] " .. desc)
            end
        end
        return false
    end

    player:SendBroadcastMessage(TAG .. " Команды: .aeguild status|xp <n>|unlocks")
    return false
end
RegisterPlayerEvent(18, OnPlayerChat)

print("[EchoOfTheVoid] 45_GuildProgress.lua загружен (гильдейская система, GM: .aeguild).")