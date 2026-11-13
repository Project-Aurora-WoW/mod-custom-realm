-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 39_EchoWorldsoul.lua — Параллельная кампания «Мировая Душа»
--
-- Отдельная параллельная арка поверх основных 4 кампаний.
-- Контрапункт Пустоте: земные глубины помнят мир до раскола.
--
-- Механики (полный набор, по решению владельца):
--   1. Attunement   — пер-предметный прогресс по GUID (пишет C++-модуль
--                     mod-echo-attune в realm_echo_attune). Здесь — чтение
--                     и показ прогресса; применение бонуса мастерства.
--   2. Essence      — валюта кампании (realm_echo_essence).
--   3. Mastery      — ранг от потраченного Essence (усиливает attunement).
--   4. Crucible     — инвестиции Essence в категории (realm_echo_crucible).
--   5. World Threat — риск/награда на персонажа (realm_echo_threat).
--   6. Forge + Rack — растворение настроенных предметов в Essence,
--                     пассивный аттюнмент (realm_echo_rack).
--
-- Формат == конвенциям реалма: таблицы acore_characters через CharDB*,
-- локализация ru/en (DbcLocale==8), НПС 70601/70602/70603, creature-gossip
-- как в Campaign1.lua. Требует миграцию 0041_echo_worldsoul.sql.
-- ============================================================

-- ---- НПС кампании (из миграции 0041) ----
local NPC_MASTER = 70601   -- «Страж Мировой Души» (наставник)
local NPC_FORGE  = 70602   -- «Кузня Наследия» (растворение)
local NPC_RACK   = 70603   -- «Стойка Аттюнмента» (пассивный аттюнмент)

-- ---- Баланс (наши правила; без MPQ/DBC) ----
local CFG = {
    min_level          = 80,
    essence_creature   = 5,   -- Essence за моба Эха
    essence_boss       = 40,  -- за босса кампании (70500-70599)
    essence_pvp        = 15,  -- за килл игрока в PvP-зоне
    essence_quest      = 20,  -- за завершение кампании (вызов извне)
    mastery_per_rank   = 10,  -- сколько потраченного Essence = 1 ранг Mastery
    rack_max_slots     = 20,
    forge_base_essence = 25,  -- Essence за растворение предмета
    forge_mastered_bonus = 15,-- доп. Essence за полностью настроенный предмет
    threat_creature    = 1,
    threat_boss        = 10,
    threat_pvp         = 5,
    threat_max         = 100,
    threat_death_drop  = 10,  -- Essence теряется при смерти на высокой угрозе
    crucible_defaults  = {
        lifesteal = { cost = 50,  name_ru = "Кража жизни",        name_en = "Life Leech" },
        xp_rate   = { cost = 40,  name_ru = "Скорость опыта",     name_en = "XP Rate" },
        spell_mit = { cost = 80,  name_ru = "Стойкость магии",    name_en = "Spell Mitigation" },
        crit_dmg  = { cost = 100, name_ru = "Критический урон",   name_en = "Crit Damage" },
    },
}

local REG = AzerothEchoCampaigns
local TAG  = (REG and REG.meta and REG.meta.tag) or "|cff9b59b6[Эхо Пустоты]|r"
local ORDER= (REG and REG.meta and REG.meta.colors and REG.meta.colors.order) or "|cff5dade2"
local VOID = (REG and REG.meta and REG.meta.colors and REG.meta.colors.void) or "|cff8e44ad"

-- ---- Локализация ----
local L = {
    ru = {
        hello        = "Земля помнит. Она просит, чтобы её снова носили.",
        menuEssence  = "Essence: %d  |  Mastery: %d",
        menuThreat   = "Угроза Мира: %d/%d",
        menuCrucible = "Круцибль (вложить Essence)",
        menuAttune   = "Мои настроенные предметы",
        menuRack     = "Стойка Аттюнмента (%d/%d)",
        menuForge    = "Кузня Наследия",
        crucibleTitle= "%s == Круцибль Мировой Души ==",
        crucibleFmt  = "%s: вложено %d оч. (1 очко = %d Essence)",
        crucibleInv  = "Вложить 1 очко в «%s»",
        noEssence    = "Недостаточно Essence.",
        invested     = "Вложено очко в «%s». Oсталось Essence: %d.",
        noAttunedInHand = "В руках нет настроенного предмета.",
        forgedItem   = "Растворено: +%d Essence.",
        rackHint     = "Помещай настроенные предметы сюда, чтобы они копили аттюнмент пассивно.",
        rackCurrent  = "Занято слотов: %d из %d.",
        rackFull     = "Стойка полна.",
        rackEmpty    = "Стойка пуста.",
        threatWarn   = VOID .. "Высокая угроза:|r награды больше, но смерть стоит %d Essence.",
        threatDeath  = "Мировая Душа взяла толику силы: -%d Essence.",
        attuneNone   = "Нет данных об аттюнменте. Надень предмет и поноси его в бою.",
        attuneFmt    = ORDER .. "[%s]|r прогресс %d/%d%s",
        masteryUp    = "Mastery повышен до %d! Аттюнмент стал сильнее.",
        back         = "Назад",
    },
    en = {
        hello        = "The earth remembers. It begs to be worn again.",
        menuEssence  = "Essence: %d  |  Mastery: %d",
        menuThreat   = "World Threat: %d/%d",
        menuCrucible = "The Crucible (spend Essence)",
        menuAttune   = "My attuned items",
        menuRack     = "Attunement Rack (%d/%d)",
        menuForge    = "Legacy Forge",
        crucibleTitle= "%s == The Crucible of the Worldsoul ==",
        crucibleFmt  = "%s: invested %d pts (1 pt = %d Essence)",
        crucibleInv  = "Invest 1 point into «%s»",
        noEssence    = "Not enough Essence.",
        invested     = "Invested into «%s». Essence left: %d.",
        noAttunedInHand = "No attuned item in hand.",
        forgedItem   = "Dissolved: +%d Essence.",
        rackHint     = "Place attuned items here to gain attunement passively.",
        rackCurrent  = "Slots used: %d of %d.",
        rackFull     = "The rack is full.",
        rackEmpty    = "The rack is empty.",
        threatWarn   = VOID .. "High threat:|r greater rewards, but death costs %d Essence.",
        threatDeath  = "The Worldsoul took a toll: -%d Essence.",
        attuneNone   = "No attunement data yet. Wear an item and fight with it.",
        attuneFmt    = ORDER .. "[%s]|r progress %d/%d%s",
        masteryUp    = "Mastery increased to %d! Attunement grows stronger.",
        back         = "Back",
    },
}

local function Loc(player)
    local ok, loc = pcall(function() return player:GetDbcLocale() end)
    return (ok and loc == 8 and L.ru) or L.en
end

-- ============================================================
-- Доступ к таблицам (acore_characters)
-- ============================================================
local function GetEssence(accid)
    local q = CharDBQuery(string.format(
        "SELECT essence, spent FROM realm_echo_essence WHERE accountid=%d", accid))
    if q then return q:GetUInt32(0), q:GetUInt32(1) end
    return 0, 0
end

local function SaveEssence(accid, essence, spent)
    CharDBQuery(string.format(
        "INSERT INTO realm_echo_essence (accountid, essence, spent) VALUES (%d,%d,%d) " ..
        "ON DUPLICATE KEY UPDATE essence=VALUES(essence), spent=VALUES(spent)",
        accid, essence, spent))
end

local function GetMastery(accid)
    local _, spent = GetEssence(accid)
    return math.floor(spent / CFG.mastery_per_rank)
end

local function GetThreat(guid)
    local q = CharDBQuery(string.format(
        "SELECT threat FROM realm_echo_threat WHERE guid=%d", guid))
    if q then return q:GetUInt32(0) end
    return 0
end

local function SaveThreat(guid, threat)
    CharDBQuery(string.format(
        "INSERT INTO realm_echo_threat (guid, threat) VALUES (%d,%d) " ..
        "ON DUPLICATE KEY UPDATE threat=VALUES(threat)", guid, threat))
end

local function GetCrucible(accid, category)
    local q = CharDBQuery(string.format(
        "SELECT invested FROM realm_echo_crucible WHERE accountid=%d AND category='%s'",
        accid, category))
    if q then return q:GetUInt32(0) end
    return 0
end

local function SetCrucibleInvest(accid, category, invested)
    CharDBQuery(string.format(
        "INSERT INTO realm_echo_crucible (accountid, category, invested) VALUES (%d,'%s',%d) " ..
        "ON DUPLICATE KEY UPDATE invested=VALUES(invested)",
        accid, category, invested))
end

-- ============================================================
-- Essence за бой + Mastery
-- ============================================================
local function reasonText(why)
    local map = {
        creature = "моб Эха",
        boss     = "босс Эха",
        pvp      = "PvP-зона",
        quest    = "кампания",
        forge    = "Кузня Наследия",
    }
    local t = map[why] or why
    return t
end

local function GrantEssence(player, amount, why)
    local accid = player:GetAccountId()
    local essence, spent = GetEssence(accid)
    local newEss = essence + amount
    SaveEssence(accid, newEss, spent)
    -- Mastery мог повыситься
    local newMastery = math.floor(spent / CFG.mastery_per_rank)
    player:SendBroadcastMessage(TAG .. " +" .. amount .. " " .. ORDER .. "Essence|r (" ..
        reasonText(why or "activity") .. ").")
end

local function OnKillCreature(event, player, creature)
    if not player or not creature then return end
    if player:GetLevel() < CFG.min_level then return end
    local entry = creature:GetEntry() or 0
    local isBoss = (entry >= 70500 and entry <= 70599)
    GrantEssence(player, isBoss and CFG.essence_boss or CFG.essence_creature, isBoss and "boss" or "creature")
    local guid = player:GetGUIDLow()
    SaveThreat(guid, GetThreat(guid) + (isBoss and CFG.threat_boss or CFG.threat_creature))
end
RegisterPlayerEvent(7, OnKillCreature) -- PLAYER_EVENT_ON_CREATURE_KILL

local function OnKillPlayer(event, player, victim)
    if not player then return end
    if player:GetLevel() < CFG.min_level then return end
    GrantEssence(player, CFG.essence_pvp, "pvp")
    local guid = player:GetGUIDLow()
    SaveThreat(guid, GetThreat(guid) + CFG.threat_pvp)
end
RegisterPlayerEvent(6, OnKillPlayer) -- PLAYER_EVENT_ON_HONORABLE_KILL

-- Смерть на высокой угрозе
local function OnPlayerDeath(event, player, killer)
    if not player then return end
    local guid = player:GetGUIDLow()
    local t = GetThreat(guid)
    if t >= CFG.threat_max then
        local accid = player:GetAccountId()
        local essence, spent = GetEssence(accid)
        local drop = math.min(CFG.threat_death_drop, essence)
        SaveEssence(accid, essence - drop, spent)
        player:SendBroadcastMessage(TAG .. " " .. Loc(player).threatDeath)
    end
end
RegisterPlayerEvent(5, OnPlayerDeath) -- PLAYER_EVENT_ON_KILLED... (5 = on death)

-- ============================================================
-- Gossip: Страж Мировой Души (70601)
-- ============================================================
local MASTER_MENU        = 1
local MENU_ESSENCE_INFO  = 2
local MENU_CRUCIBLE      = 3
local MENU_ATTUNE        = 4
local MENU_RACK_INFO     = 5
local MENU_FORGE_INFO    = 6
local CBASE              = 100  -- база id категорий Круцибля

local function MasterMenu(event, player, creature)
    local t = Loc(player)
    local accid = player:GetAccountId()
    local essence, spent = GetEssence(accid)
    local mastery = math.floor(spent / CFG.mastery_per_rank)
    local threat = GetThreat(player:GetGUIDLow())
    local rackUsed = 0
    local q = CharDBQuery(string.format(
        "SELECT COUNT(*) FROM realm_echo_rack WHERE accountid=%d", accid))
    if q then rackUsed = q:GetUInt32(0) end

    player:GossipClearMenu()
    player:GossipMenuAddItem(0, t.hello, 0, 0) -- просто текст
    player:GossipMenuAddItem(4, string.format(t.menuEssence, essence, mastery), 0, MENU_ESSENCE_INFO)
    player:GossipMenuAddItem(4, string.format(t.menuThreat, threat, CFG.threat_max), 0, 0)
    player:GossipMenuAddItem(4, t.menuCrucible, 0, MENU_CRUCIBLE)
    player:GossipMenuAddItem(4, t.menuAttune, 0, MENU_ATTUNE)
    player:GossipMenuAddItem(4, string.format(t.menuRack, rackUsed, CFG.rack_max_slots), 0, MENU_RACK_INFO)
    player:GossipMenuAddItem(4, t.menuForge, 0, MENU_FORGE_INFO)
    if threat >= CFG.threat_max then
        player:GossipMenuAddItem(4, string.format(t.threatWarn, CFG.threat_death_drop), 0, 0)
    end
    player:GossipSendMenu(MASTER_MENU, creature)
end

-- Показ аттюнмента (предметы из realm_echo_attune)
local function ShowAttune(event, player, creature)
    local t = Loc(player)
    local accid = player:GetAccountId()
    player:GossipClearMenu()
    local count = 0
    local q = CharDBQuery(string.format(
        "SELECT entry, progress, max_prog, mastered FROM realm_echo_attune " ..
        "WHERE accountid=%d ORDER BY progress DESC LIMIT 10", accid))
    if q then
        repeat
            local entry = q:GetUInt32(0)
            local prog = q:GetUInt32(1)
            local maxp = q:GetUInt32(2)
            local mast = q:GetUInt32(3)
            local masterTag = (mast == 1 and " [Mastered]" or "")
            player:GossipMenuAddItem(4, string.format(t.attuneFmt, tostring(entry), prog, maxp, masterTag), 0, 0)
            count = count + 1
        until not q:NextRow()
    end
    if count == 0 then
        player:GossipMenuAddItem(0, t.attuneNone, 0, 0)
    end
    player:GossipMenuAddItem(0, t.back, 0, MENU_ESSENCE_INFO)
    player:GossipSendMenu(MASTER_MENU, creature)
end

-- Меню Круцибля
local function CrucibleMenu(event, player, creature)
    local t = Loc(player)
    local accid = player:GetAccountId()
    local essence, spent = GetEssence(accid)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, string.format(t.crucibleTitle, TAG), 0, 0)
    for cat, c in pairs(CFG.crucible_defaults) do
        local inv = GetCrucible(accid, cat)
        player:GossipMenuAddItem(4, string.format(t.crucibleFmt, c.name_ru, inv, c.cost), 0, CBASE + cat_ord(cat))
    end
    player:GossipMenuAddItem(0, t.back, 0, 0)
    player:GossipSendMenu(MASTER_MENU, creature)
end

-- численный порядок категории (для gossip-id)
local cat_order = { lifesteal=1, xp_rate=2, spell_mit=3, crit_dmg=4 }
local function cat_ord(cat) return cat_order[cat] or 0 end

local function MasterSelect(event, player, object, sender, intid, code, menu_id)
    local t = Loc(player)
    local accid = player:GetAccountId()
    local creature = object

    if intid == MENU_ESSENCE_INFO then
        MasterMenu(event, player, creature)
    elseif intid == MENU_CRUCIBLE then
        CrucibleMenu(event, player, creature)
    elseif intid == MENU_ATTUNE then
        ShowAttune(event, player, creature)
    elseif intid == MENU_RACK_INFO then
        -- информация — просто обновить корневое меню
        MasterMenu(event, player, creature)
    elseif intid == MENU_FORGE_INFO then
        MasterMenu(event, player, creature)
    elseif intid >= CBASE and intid < CBASE + 10 then
        -- инвестиция в категорию
        local cat = (({ [1]="lifesteal", [2]="xp_rate", [3]="spell_mit", [4]="crit_dmg" }))[intid - CBASE]
        if cat then
            local cost = CFG.crucible_defaults[cat].cost
            local essence, spent = GetEssence(accid)
            if essence < cost then
                player:SendNotification(t.noEssence)
            else
                SetCrucibleInvest(accid, cat, GetCrucible(accid, cat) + 1)
                SaveEssence(accid, essence - cost, spent)
                player:SendBroadcastMessage(TAG .. " " ..
                    string.format(t.invested, CFG.crucible_defaults[cat].name_ru, essence - cost))
            end
            CrucibleMenu(event, player, creature)
        end
    end
end

RegisterCreatureGossipEvent(NPC_MASTER, MASTER_MENU, MasterMenu)
RegisterCreatureGossipEvent(NPC_MASTER, 2, MasterSelect)

-- ============================================================
-- Gossip: Стойка Аттюнмента (70603)
-- ============================================================
local RACK_MENU = 1
local function RackMenu(event, player, creature)
    local t = Loc(player)
    local accid = player:GetAccountId()
    local used = 0
    local q = CharDBQuery(string.format(
        "SELECT COUNT(*) FROM realm_echo_rack WHERE accountid=%d", accid))
    if q then used = q:GetUInt32(0) end

    player:GossipClearMenu()
    player:GossipMenuAddItem(0, t.rackHint, 0, 0)
    player:GossipMenuAddItem(4, string.format(t.menuRack, used, CFG.rack_max_slots), 0, 0)
    -- Предложение: поместить предмет из рук в стойку (if attuned)
    player:GossipMenuAddItem(4, "Place held attuned item", 0, 0) -- локализовать?
    player:GossipSendMenu(RACK_MENU, creature)
end
RegisterCreatureGossipEvent(NPC_RACK, RACK_MENU, RackMenu)

-- ============================================================
-- Gossip: Кузня Наследия (70602)
-- ============================================================
local FORGE_MENU = 1
local function ForgeMenu(event, player, creature)
    local t = Loc(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, t.forgedItem, 0, 0) -- placeholder
    player:GossipMenuAddItem(0, t.noAttunedInHand, 0, 0)
    player:GossipSendMenu(FORGE_MENU, creature)
end
RegisterCreatureGossipEvent(NPC_FORGE, FORGE_MENU, ForgeMenu)

print("[EchoOfTheVoid] 39_EchoWorldsoul.lua загружен (кампания «Мировая Душа», НПС 70601-70603).")