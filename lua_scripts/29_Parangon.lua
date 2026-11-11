-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 29_Parangon.lua
-- Назначение: система Parangon («псевдо-уровни», как в Diablo 3).
-- На каждый уровень Parangon (за опыт за PvE/PvP) аккаунт получает
-- очки, которые персонаж тратит на стаки штатных аур 7464 (Сила) /
-- 7471 (Ловкость) / 7477 (Выносливость) / 7468 (Интеллект).
--
-- Адаптация lua-parangon (Open-Wow/Khalar, AGPL) на конвенции реалма:
--   - конфиг в реестре (REG.parangon), не в теле скрипта;
--   - локализация ru/en (DbcLocale == 8 → русский);
--   - команда .parangon через PLAYER_EVENT_ON_CHAT (как .aepvp), а не
--     через PLAYER_EVENT_ON_COMMAND(42) (его нет в ALE-stack wotlk);
--   - очки = level*pointsPerLevel − уже потраченные (вычисляются);
--   - без бага: референс использовал неинициализированный pGuid
--     в setParangonLevelUp — здесь очки пересчитываются в setStatsIncrease
--     и после level-up, с корректным guid;
--   - таблицы account_parangon / characters_parangon (acore_characters, 0029).
-- Зависимости: реестр AzerothEchoCampaigns (parangon).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local P = REG.parangon

-- Кэши в памяти за сессию
local Stats = {}   -- [guid] = { [auraId] = потраченные очки }
local Infos = {}   -- [accountId] = { level=, exp=, points= }

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    ru = {
        noParangonYet = "Parangon для уровня %d+.",
        menuTitle   = "%s: уровень Parangon %d",
        menuExp     = "Опыт: %d / %d",
        menuPoints  = "Доступно очков: %d",
        str  = "Сила",
        agi  = "Ловкость",
        sta  = "Выносливость",
        int  = "Интеллект",
        inCombat    = "Нельзя в бою.",
        noPoints    = "Недостаточно очков Parangon.",
        lvlUp       = "Поздравляем! Уровень Parangon повышен до %d.",
        msgHas      = "У вас %d (%s)",
        addStat     = "+%d к %s",
    },
    en = {
        noParangonYet = "Parangon is for level %d+.",
        menuTitle   = "%s: Parangon level %d",
        menuExp     = "Experience: %d / %d",
        menuPoints  = "Points available: %d",
        str  = "Strength",
        agi  = "Agility",
        sta  = "Stamina",
        int  = "Intellect",
        inCombat    = "Cannot do this in combat.",
        noPoints    = "Not enough Parangon points.",
        lvlUp       = "Congratulations! Parangon level reached %d.",
        msgHas      = "You have %d (%s)",
        addStat     = "+%d to %s",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Вспомогательные
-- ============================================================

-- Обновляет UI (пакет SMSG_NPC_TEXT_UPDATE через GossipSetText без
-- зависимости от ядра — метод объявляется локально для Parangon).
local function SendParangonFrame(player)
    local text = CreatePacket(384, 100) -- SMSG_NPC_TEXT_UPDATE
    text:WriteULong(0x7FFFFFFF)
    for _ = 1, 8 do
        text:WriteFloat(0)
        text:WriteString(" ")
        text:WriteString(" ")
        text:WriteULong(0)
        text:WriteULong(0)
        text:WriteULong(0)
        text:WriteULong(0)
        text:WriteULong(0)
        text:WriteULong(0)
    end
    player:SendPacket(text)
end

local function RecalcPoints(accid, guid)
    local spent = 0
    if Stats[guid] then
        for _, v in pairs(Stats[guid]) do
            spent = spent + v
        end
    end
    local lvl = (Infos[accid] and Infos[accid].level) or 1
    Infos[accid].points = (lvl * P.points_per_level) - spent
end

-- Применяет аурстаки Parangon
local function ApplyAuraStacks(player, guid)
    if not (Stats[guid]) then
        return
    end
    for auraId, stacks in pairs(Stats[guid]) do
        player:RemoveAura(auraId)
        if stacks > 0 then
            player:AddAura(auraId, player)
            local aura = player:GetAura(auraId)
            if aura then
                aura:SetStackAmount(stacks)
            end
        end
    end
end

-- ============================================================
-- Загрузка данных при входе
-- ============================================================
local function OnLogin(event, player)
    local guid = player:GetGUIDLow()
    local accid = player:GetAccountId()

    if player:GetLevel() < P.min_player_level then
        player:SendNotification(string.format(GetLocale(player).noParangonYet, P.min_player_level))
        return
    end

    -- Статистика Parangon персонажа (потраченные очки)
    if not Stats[guid] then
        Stats[guid] = { [7464] = 0, [7471] = 0, [7477] = 0, [7468] = 0 }
        local q = CharDBQuery("SELECT `strenght`, `agility`, `stamina`, `intellect` FROM `characters_parangon` WHERE `guid` = " .. guid .. " AND `accountid` = " .. accid)
        if q then
            Stats[guid] = {
                [7464] = q:GetUInt32(0),
                [7471] = q:GetUInt32(1),
                [7477] = q:GetUInt32(2),
                [7468] = q:GetUInt32(3),
            }
        end
    end

    -- Инфо Parangon аккаунта (уровень/опыт)
    if not Infos[accid] then
        Infos[accid] = { level = 1, exp = 0, points = 0 }
        local q = CharDBQuery("SELECT `level`, `exp` FROM `account_parangon` WHERE `accountid` = " .. accid)
        if q then
            Infos[accid].level = q:GetUInt32(0)
            Infos[accid].exp   = q:GetUInt32(1)
        end
    end

    RecalcPoints(accid, guid)
    ApplyAuraStacks(player, guid)
end
RegisterPlayerEvent(3, OnLogin) -- PLAYER_EVENT_ON_LOGIN

-- Сохранение при выходе
local function OnLogout(event, player)
    local guid = player:GetGUIDLow()
    local accid = player:GetAccountId()
    if Stats[guid] and Infos[accid] then
        CharDBExecute("INSERT INTO `characters_parangon` (`accountid`, `guid`, `strenght`, `agility`, `stamina`, `intellect`) VALUES (" ..
            accid .. ", " .. guid .. ", " .. (Stats[guid][7464] or 0) .. ", " .. (Stats[guid][7471] or 0) .. ", " .. (Stats[guid][7477] or 0) .. ", " .. (Stats[guid][7468] or 0) .. ") " ..
            "ON DUPLICATE KEY UPDATE `strenght` = VALUES(`strenght`), `agility` = VALUES(`agility`), `stamina` = VALUES(`stamina`), `intellect` = VALUES(`intellect`)")
        CharDBExecute("INSERT INTO `account_parangon` (`accountid`, `level`, `exp`) VALUES (" ..
            accid .. ", " .. Infos[accid].level .. ", " .. Infos[accid].exp .. ") " ..
            "ON DUPLICATE KEY UPDATE `level` = VALUES(`level`), `exp` = VALUES(`exp`)")
        Stats[guid] = nil
    end
end
RegisterPlayerEvent(4, OnLogout) -- PLAYER_EVENT_ON_LOGOUT

-- ============================================================
-- Опыт за убийства
-- ============================================================
local function GrantExp(event, player, amount)
    local accid = player:GetAccountId()
    if player:GetLevel() < P.min_player_level then
        return
    end
    if not Infos[accid] then
        Infos[accid] = { level = 1, exp = 0, points = 0 }
    end
    Infos[accid].exp = Infos[accid].exp + amount
    local needed = Infos[accid].level * P.max_exp_per_level
    if Infos[accid].exp >= needed then
        Infos[accid].level = Infos[accid].level + 1
        Infos[accid].exp = Infos[accid].exp - needed
        player:SendBroadcastMessage(string.format(TAG .. " " .. GetLocale(player).lvlUp, Infos[accid].level))
        -- пересчитать очки на текущего персонажа, если он онлайн
        local guid = player:GetGUIDLow()
        RecalcPoints(accid, guid)
        ApplyAuraStacks(player, guid)
    end
end

local function OnKillCreature(event, player, creature)
    -- Учитываем только если игрок жив и имеет право
    GrantExp(event, player, P.pve_kill_exp)
end
RegisterPlayerEvent(7, OnKillCreature) -- PLAYER_EVENT_ON_CREATURE_KILL

local function OnKillPlayer(event, player, victim)
    GrantExp(event, player, P.pvp_kill_exp)
end
RegisterPlayerEvent(6, OnKillPlayer) -- PLAYER_EVENT_ON_HONORABLE_KILL

-- ============================================================
-- Команда .parangon
-- ============================================================
local function OnChat(event, player, msg, lang, typ)
    if string.match(msg, "^%.parangon%s*$") then
        local guid = player:GetGUIDLow()
        local accid = player:GetAccountId()

        if player:GetLevel() < P.min_player_level then
            return false
        end
        if not Stats[guid] or not Infos[accid] then
            OnLogin(event, player) -- подстраховка
        end

        local loc = GetLocale(player)
        local lvl = (Infos[accid] and Infos[accid].level) or 1
        local exp = (Infos[accid] and Infos[accid].exp) or 0
        RecalcPoints(accid, guid)
        local points = (Infos[accid] and Infos[accid].points) or 0

        player:GossipClearMenu()
        player:GossipMenuAddItem(4, string.format("%s (%d)  [%d]", loc.str, Stats[guid][7464] or 0, points), 3, 7464)
        player:GossipMenuAddItem(4, string.format("%s (%d)  [%d]", loc.agi, Stats[guid][7471] or 0, points), 3, 7471)
        player:GossipMenuAddItem(4, string.format("%s (%d)  [%d]", loc.sta, Stats[guid][7477] or 0, points), 3, 7477)
        player:GossipMenuAddItem(4, string.format("%s (%d)  [%d]", loc.int, Stats[guid][7468] or 0, points), 3, 7468)
        player:GossipSendMenu(1, player)
        return false
    end
end
RegisterPlayerEvent(18, OnChat) -- PLAYER_EVENT_ON_CHAT

-- По завершении gossip-меню (выбора характеристики)
local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    -- intid = auraId (7464/7471/7477/7468)
    local auraId = intid
    local guid = player:GetGUIDLow()
    local accid = player:GetAccountId()

    if player:IsInCombat() then
        player:SendNotification(GetLocale(player).inCombat)
    elseif (player:GetLevel() < P.min_player_level) then
        player:SendNotification(string.format(GetLocale(player).noParangonYet, P.min_player_level))
    else
        if not Stats[guid] or not Infos[accid] then
            OnLogin(event, player)
        end
        RecalcPoints(accid, guid)
        local points = (Infos[accid] and Infos[accid].points) or 0
        if points < 1 then
            player:SendNotification(GetLocale(player).noPoints)
        else
            Stats[guid][auraId] = (Stats[guid][auraId] or 0) + 1
            RecalcPoints(accid, guid)
            ApplyAuraStacks(player, guid)
            -- заново открываем меню
            OnChat(event, player, ".parangon", 0, 0)
        end
    end
end
RegisterPlayerGossipEvent(1, 2, OnGossipSelect) -- PLAYER_GOSSIP_EVENT_ON_SELECT

print("[EchoOfTheVoid] 29_Parangon.lua загружен (Parangon: аурстаки " ..
    tostring(7464) .. "/" .. tostring(7471) .. "/" .. tostring(7477) .. "/" .. tostring(7468) .. ").")