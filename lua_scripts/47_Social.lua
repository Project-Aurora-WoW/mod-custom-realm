-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 47_Social.lua
-- Назначение: социальная система (п.5) — спутники/партнёры с уровнем
-- связи, бонусы за присутствие друзей, наставник/ученик.
--   .aesocial friend <имя>  — добавить спутника (взаимно)
--   .aesocial status        — список своих связей и уровней
--   .aesocial mentor <имя>  — стать наставником игрока
--   .aesocial break <имя>   — разорвать связь
-- Опыт связи растёт за совместные действия (PvP-килл, босс) когда
-- спутники в группе и в пределах REG.social.shared_distance.
-- Уровень связи по level_curve; бонус опыта по bonus_xp_pct.
-- Таблицы: realm_social_links (0051), realm_mentor (0051).
-- Клиент — вкладка «Социальное» (payload AECHOSOCIAL).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local S = REG.social
local LEVEL_CURVE = S.level_curve
local MAX_LEVEL = S.max_level or 5
local XP_PVP = S.xp_pvp_kill or 10
local XP_BOSS = S.xp_boss_kill or 40
local SHARED_DIST = S.shared_distance or 80
local BONUS_XP = S.bonus_xp_pct or {}
local SOCIAL_PREFIX = S.prefix or "AECHOSOCIAL"

local LINKS_TABLE = "realm_social_links"
local MENTOR_TABLE = "realm_mentor"

-- Рейдовые боссы (из legacy.pve_bosses) — за них начисляется опыт связи.
local PVE_BOSSES = {}
if REG.legacy and REG.legacy.pve_bosses then
    for _, e in pairs(REG.legacy.pve_bosses) do PVE_BOSSES[e] = true end
end

-- ============================================================
-- Локализация ru/en
-- ============================================================
local L = {
    ru = {
        linkUp     = "Связь с %s|r укрепилась (+%d, уровень %d).",
        fmtFriend  = "Формат: .aesocial friend <имя игрока>",
        selfNo     = "Нельзя связаться с самим собой.",
        notFound   = "Игрок «%s» не найден.",
        already    = "Вы уже связаны с %s|r.",
        linkSet    = "Связь с %s|r установлена (уровень 1).",
        circle     = "== Мой социальный круг ==",
        partnerRow = "%s|r — связь ур.%d",
        noPartners = "Пока никого. .aesocial friend <имя>.",
        mentorRow  = "Наставник: %s|r",
        fmtMentor  = "Формат: .aesocial mentor <имя ученика>",
        selfMentor = "Нельзя быть наставником самому себе.",
        mentorSet  = "Ты стал наставником %s.|r",
        fmtBreak   = "Формат: .aesocial break <имя>",
        linkBroken = "Связь с %s|r разорвана.",
        linkNone   = "Связи с %s нет.",
    },
    en = {
        linkUp     = "Link with %s|r strengthened (+%d, level %d).",
        fmtFriend  = "Format: .aesocial friend <player name>",
        selfNo     = "You cannot bond with yourself.",
        notFound   = "Player «%s» not found.",
        already    = "You are already linked to %s|r.",
        linkSet    = "Linked with %s|r (level 1).",
        circle     = "== My social circle ==",
        partnerRow = "%s|r — bond lvl %d",
        noPartners = "No one yet. .aesocial friend <name>.",
        mentorRow  = "Mentor: %s|r",
        fmtMentor  = "Format: .aesocial mentor <student name>",
        selfMentor = "You cannot be your own mentor.",
        mentorSet  = "You became the mentor of %s.|r",
        fmtBreak   = "Format: .aesocial break <name>",
        linkBroken = "Link with %s|r broken.",
        linkNone   = "No link with %s.",
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
-- Хелперы имён/guid (по игроку и по guid из БД)
-- ============================================================

local function PlayerGuid(name)
    local q = CharDBQuery(string.format(
        "SELECT guid FROM characters WHERE name = '%s'", name:gsub("'", "''")))
    if q then return q:GetUInt32(0) end
    return nil
end

local function NameByGuid(guid)
    local q = CharDBQuery(string.format(
        "SELECT name FROM characters WHERE guid = %d", guid))
    return q and q:GetString(0) or ("#" .. guid)
end

-- Ссылка A->B (гарантируем порядок guid_a < guid_b для симметрии)
local function LinkKey(a, b)
    return (a < b) and a .. ":" .. b or b .. ":" .. a
end

local function GetLink(a, b)
    local key = LinkKey(a, b)
    local aG, bG = string.match(key, "^(%d+):(%d+)$")
    local q = CharDBQuery(string.format(
        "SELECT level, xp, total_xp FROM %s WHERE guid_a = %d AND guid_b = %d",
        LINKS_TABLE, tonumber(aG), tonumber(bG)))
    if q then return { level = q:GetUInt32(0), xp = q:GetUInt32(1), total = q:GetUInt32(2) } end
    return nil
end

local function EnsureLink(a, b)
    local key = LinkKey(a, b)
    local aG, bG = string.match(key, "^(%d+):(%d+)$")
    local cur = GetLink(a, b)
    if not cur then
        CharDBQuery(string.format(
            "REPLACE INTO %s (guid_a, guid_b, level, xp, total_xp) VALUES (%d, %d, 1, 0, 0)",
            LINKS_TABLE, tonumber(aG), tonumber(bG)))
        return 1, 0
    end
    return cur.level, cur.xp
end

local function AddLinkXp(a, b, amount)
    local key = LinkKey(a, b)
    local aG, bG = string.match(key, "^(%d+):(%d+)$")
    local cur = GetLink(a, b)
    if not cur then EnsureLink(a, b) end
    cur = GetLink(a, b)
    local xp = (cur and cur.xp or 0) + amount
    local lvl = cur and cur.level or 1
    local total = (cur and cur.total or 0) + amount
    while lvl < MAX_LEVEL and LEVEL_CURVE[lvl + 1] and xp >= LEVEL_CURVE[lvl + 1] do
        lvl = lvl + 1
    end
    CharDBQuery(string.format(
        "UPDATE %s SET level = %d, xp = %d, total_xp = %d WHERE guid_a = %d AND guid_b = %d",
        LINKS_TABLE, lvl, xp, total, tonumber(aG), tonumber(bG)))
    return lvl
end

-- Спутники игрока (список guid)
local function GetPartners(guid)
    local result = {}
    local q = CharDBQuery(string.format(
        "SELECT guid_a, guid_b FROM %s WHERE guid_a = %d OR guid_b = %d",
        LINKS_TABLE, guid, guid))
    if q then
        repeat
            local a, b = q:GetUInt32(0), q:GetUInt32(1)
            local other = (a == guid) and b or a
            result[other] = GetLink(guid, other)
        until not q:NextRow()
    end
    return result
end

-- ============================================================
-- Начисление опыта связи за совместное действие
-- (вызывается из PvP-килла и убийства босса)
-- ============================================================

-- Ищем онлайн-спутника в группе и в пределах дистанции; возвращает guid
local function FindNearbyPartner(pl, parts)
    if not pl:IsInGroup() then return 0 end
    local myX, myY, myZ = pl:GetX(), pl:GetY(), pl:GetZ()
    for guid, _ in pairs(parts) do
        local t = GetPlayerByGUID(guid)
        if t and t:IsInWorld() and pl:IsInSameGroupWith(t) then
            local tx, ty, tz = t:GetX(), t:GetY(), t:GetZ()
            local dx, dy, dz = tx - myX, ty - myY, tz - myZ
            if math.sqrt(dx*dx + dy*dy + dz*dz) <= SHARED_DIST then
                return guid
            end
        end
    end
    return 0
end

local function GrantSharedXp(player, amount)
    if not player or not player:IsInWorld() then return end
    local myGuid = player:GetGUIDLow()
    local partners = GetPartners(myGuid)
    local targetGUID = FindNearbyPartner(player, partners)

    if targetGUID and targetGUID ~= 0 then
        local lvl = AddLinkXp(myGuid, targetGUID, amount)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR ..
            Loc(player, "linkUp", NameByGuid(targetGUID), amount, lvl))
    end
end

-- ============================================================
-- PvP-килл (событие 6)
-- ============================================================
local function OnPvpKill(event, killer, killed)
    if not killer or not killer:IsPlayer() then return end
    GrantSharedXp(killer, XP_PVP)
end
RegisterPlayerEvent(6, OnPvpKill)

-- ============================================================
-- Босс (событие 7)
-- ============================================================
local function OnBossKill(event, killer, killed)
    if not killer or not killer:IsPlayer() or not killed then return end
    -- Фильтр: только рейдовые боссы дают опыт связи (не любой моб)
    local entry = killed:GetEntry()
    if not PVE_BOSSES[entry] then return end
    GrantSharedXp(killer, XP_BOSS)
end
RegisterPlayerEvent(7, OnBossKill)

-- ============================================================
-- Команды .aesocial ...
-- ============================================================

local function HasLink(a, b)
    return GetLink(a, b) ~= nil
end

local function OnPlayerChat(event, player, msg, lang, typ)
    if not player or not player:IsPlayer() then return end
    local cmd, arg = string.match(msg, "^%.aesocial%s+(%a+)%s*(.-)$")
    if not cmd then return end
    cmd = string.lower(cmd)
    local myGuid = player:GetGUIDLow()

    -- .aesocial friend <имя>
    if cmd == "friend" then
        local name = trim(arg or "")
        if name == "" then
            player:SendBroadcastMessage(TAG .. Loc(player, "fmtFriend"))
            return false
        end
        if name == player:GetName() then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. Loc(player, "selfNo") .. "|r")
            return false
        end
        local other = PlayerGuid(name)
        if not other then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. Loc(player, "notFound", name) .. "|r")
            return false
        end
        if HasLink(myGuid, other) then
            player:SendBroadcastMessage(TAG .. Loc(player, "already", ORDER_COLOR .. name) .. ".")
            return false
        end
        EnsureLink(myGuid, other)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. Loc(player, "linkSet", name))
        return false
    end

    -- .aesocial status
    if cmd == "status" then
        player:SendBroadcastMessage(TAG .. Loc(player, "circle"))
        local partners = GetPartners(myGuid)
        local n = 0
        for guid, link in pairs(partners) do
            n = n + 1
            local lvl = link and link.level or 1
            player:SendBroadcastMessage(TAG .. " " .. Loc(player, "partnerRow", ORDER_COLOR .. NameByGuid(guid), lvl))
        end
        if n == 0 then
            player:SendBroadcastMessage(TAG .. Loc(player, "noPartners"))
        end
        -- Наставник/ученик
        local mq = CharDBQuery(string.format(
            "SELECT mentor_guid FROM %s WHERE student_guid = %d", MENTOR_TABLE, myGuid))
        if mq then
            player:SendBroadcastMessage(TAG .. Loc(player, "mentorRow", ORDER_COLOR .. NameByGuid(mq:GetUInt32(0))))
        end
        return false
    end

    -- .aesocial mentor <имя>
    if cmd == "mentor" then
        local name = trim(arg or "")
        if name == "" then
            player:SendBroadcastMessage(TAG .. Loc(player, "fmtMentor"))
            return false
        end
        local student = PlayerGuid(name)
        if not student then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. Loc(player, "notFound", name) .. "|r")
            return false
        end
        if student == myGuid then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. Loc(player, "selfMentor") .. "|r")
            return false
        end
        CharDBQuery(string.format(
            "REPLACE INTO %s (mentor_guid, student_guid) VALUES (%d, %d)",
            MENTOR_TABLE, myGuid, student))
        player:SendBroadcastMessage(TAG .. " " .. Loc(player, "mentorSet", ORDER_COLOR .. name))
        return false
    end

    -- .aesocial break <имя>
    if cmd == "break" then
        local name = trim(arg or "")
        if name == "" then
            player:SendBroadcastMessage(TAG .. Loc(player, "fmtBreak"))
            return false
        end
        local other = PlayerGuid(name)
        if not other then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. Loc(player, "notFound", name) .. "|r")
            return false
        end
        if HasLink(myGuid, other) then
            local key = LinkKey(myGuid, other)
            local aG, bG = string.match(key, "^(%d+):(%d+)$")
            CharDBQuery(string.format(
                "DELETE FROM %s WHERE guid_a = %d AND guid_b = %d", LINKS_TABLE, tonumber(aG), tonumber(bG)))
            player:SendBroadcastMessage(TAG .. Loc(player, "linkBroken", CULT_COLOR .. name))
        else
            player:SendBroadcastMessage(TAG .. Loc(player, "linkNone", name))
        end
        return false
    end

    return true
end
RegisterPlayerEvent(18, OnPlayerChat)

-- ============================================================
-- AECHOSOCIAL payload (вкладка «Социальное»)
-- Формат: count;name1:lvl1;name2:lvl2;... ;MENTOR;имяНаставника
-- ============================================================
function AE_SendSocialPayload(player)
    if not player or not player:IsPlayer() then return end
    local myGuid = player:GetGUIDLow()
    local parts = {}
    local partners = GetPartners(myGuid)
    local n = 0
    for guid, link in pairs(partners) do
        n = n + 1
        table.insert(parts, string.format("%s:%d", NameByGuid(guid), link and link.level or 1))
    end
    local payload = n .. ";" .. table.concat(parts, ";")
    local mq = CharDBQuery(string.format(
        "SELECT mentor_guid FROM %s WHERE student_guid = %d", MENTOR_TABLE, myGuid))
    if mq then
        payload = payload .. ";MENTOR;" .. NameByGuid(mq:GetUInt32(0))
    end
    SendAddonMessage(SOCIAL_PREFIX, payload, "WHISPER", player)
end

-- Отправка при входе
local function OnLogin(event, player)
    AE_SendSocialPayload(player)
end
RegisterPlayerEvent(3, OnLogin)

-- Утилита: обрезка пробелов
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

print("[EchoOfTheVoid] 47_Social.lua загружен (соц. система, .aesocial friend/status/mentor/break).")