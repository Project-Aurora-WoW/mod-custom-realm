-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign8.lua
-- Назначение: кампания 8 «Наследие Иллидана» (главы 1–4).
-- Требования: завершена кампания 7 (item 70011 «Пепел Сильваны»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 8).
-- НПС: 70240 Изгнанник Кель'Тас (старт), 70241 Тень Виалии,
--       70242 Реликвия Наследия, 70243 Тюремщик, 70540 Страж Иллидана.
-- Награда: item 70012 «Осколок Наследия» (валюта модуля legacy).
-- Параллельный модуль (41_LegacyIllidan.lua) начисляет осколки за
-- убийство босса 70540 (legacy.pve_bosses). Синергия: прохождение
-- кампании даёт сюжет, а бой с боссом — очки турнира.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[8]
local CAMPAIGN_ID = 8
local DB_TABLE = REG.meta.db_table
local SHADE_REQUIRED = 4     -- глава 1: теней Виалии
local RELIC_TOTAL = 3        -- глава 2: реликвий Наследия
local WARDEN_REQUIRED = 3    -- глава 3: тюремщиков
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Осколок Наследия»
local REWARD_MAIL_DELAY = 60

-- Требование: «Пепел Сильваны» (финал кампании 7)
local CAMPAIGN7_TOKEN = REG.campaigns[7].rewards.token

local NPC_HERALD = CAMPAIGN.npc.herald   -- Изгнанник Кель'Тас (старт)
local NPC_SHADE  = CAMPAIGN.npc.shade    -- Тень Виалии (kill гл. 1)
local NPC_RELIC  = CAMPAIGN.npc.relic    -- Реликвия Наследия (interact гл. 2)
local NPC_WARDEN = CAMPAIGN.npc.warden   -- Тюремщик (kill гл. 3)
local NPC_BOSS   = CAMPAIGN.npc.boss     -- Страж Иллидана (гл. 4)

local MENU_ROOT = 1
local MENU_START = 2   -- принять призвание Наследия
local MENU_RELIC = 3   -- коснуться реликвии

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign7Token(player)
    return player:HasItem(CAMPAIGN7_TOKEN)
end

local function GetClassLine(player)
    return REG.class_greetings[player:GetClass()] or ""
end

-- ============================================================
-- Работа с прогрессом (realm_campaign_progress)
-- ============================================================

local function LoadProgress(player)
    local q = CharDBQuery(string.format(
        "SELECT chapter, completed FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        return q:GetUInt8(0), q:GetUInt8(1) == 1
    end
    return 0, false
end

local function SaveProgress(player, chapter, completed, data)
    CharDBQuery(string.format(
        "REPLACE INTO %s (guid, campaign_id, chapter, completed, progress_data) VALUES (%d, %d, %d, %d, '%s')",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID, chapter, completed and 1 or 0, data or ""
    ))
end

local function ReadCounter(player, key)
    local q = CharDBQuery(string.format(
        "SELECT progress_data FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        return tonumber(string.match(q:GetString(0) or "", key .. "=(%d+)")) or 0
    end
    return 0
end

local function WriteCounter(player, chapter, key, value)
    SaveProgress(player, chapter, false, key .. "=" .. value)
end

-- ============================================================
-- Награда
-- ============================================================

local function GrantReward(player)
    SendMail(
        "Осколок Наследия",
        "Ты принял наследие предателя и доказал, что оно не пятнает, " ..
        "а закаляет. Этот осколок — валюта турнира «Наследие Иллидана». " ..
        "Пусть твоё имя войдёт в летопись. — Изгнанник Кель'Тас",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Наследие Иллидана» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Осколок Наследия»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " явился наследником Иллидана и сокрушил его Стража!")
end

-- ============================================================
-- Старт кампании: Изгнанник Кель'Тас (Даларан, gossip 70240)
-- ============================================================

local function ShowHeraldMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Наследие принято. Шёпот больше не найдёт тебя здесь.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Ты слишком слаб для тени Иллидана. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign7Token(player) then
            player:GossipMenuAddItem(0, "«Изгнанник, почему наследие Иллидана говорит со мной?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Принеси Пепел Сильваны. Только прошедший Хроники увядания слышит это призвание.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 3 then
        player:GossipMenuAddItem(0, "«Состояние наследия?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnHeraldSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign7Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Кель'Тас:|r «Сначала Пепел Сильваны. Ты ещё не готов.»")
            player:GossipComplete()
            return
        end
        player:Teleport(571, 3865.00, 7035.00, 150.00, 2.10)
        WriteCounter(player, 1, "shade", 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Виалии»|r — развей " .. SHADE_REQUIRED .. " теней былого легиона.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Кель'Тас:|r «" .. GetClassLine(player) .. "»")
        player:GossipComplete()
        return
    end
    player:GossipComplete()
end

-- ============================================================
-- Главы 1, 3, 4: kill-кредиты
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_SHADE and entry ~= NPC_WARDEN and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_SHADE and chapter == 1 then
        local n = ReadCounter(killer, "shade") + 1
        if n >= SHADE_REQUIRED then
            SaveProgress(killer, 2, false, "shade=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Виалии»|r — выполнено. Тени рассеялись.")
            killer:SendBroadcastMessage(TAG .. " Найди " .. ORDER_COLOR .. "реликвии Наследия|r — " .. RELIC_TOTAL .. " шт.")
        else
            WriteCounter(killer, 1, "shade", n)
            killer:SendBroadcastMessage(TAG .. " Тень развеяна (" .. n .. "/" .. SHADE_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_WARDEN and chapter == 3 then
        local n = ReadCounter(killer, "warden") + 1
        if n >= WARDEN_REQUIRED then
            SaveProgress(killer, 4, false, "warden=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Тюремщики»|r — выполнено. Стражники пали.")
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Страж Иллидана|r просыпается в центре. Убей его.")
        else
            WriteCounter(killer, 3, "warden", n)
            killer:SendBroadcastMessage(TAG .. " Тюремщик повержен (" .. n .. "/" .. WARDEN_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 4 «Страж Иллидана»|r — выполнено. Наследие принято.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 2: реликвии Наследия (gossip 70242)
-- ============================================================

local function ShowRelicMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 2 then
        player:GossipMenuAddItem(0, "Коснуться реликвии Наследия.", 0, MENU_RELIC)
    else
        player:GossipMenuAddItem(0, "Реликвия дрожит чужим голосом. Она ждёт достойного.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnRelicSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 2 and not completed then
        local n = ReadCounter(player, "relic") + 1
        if n >= RELIC_TOTAL then
            SaveProgress(player, 3, false, "relic=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 2 «Реликвии»|r — выполнено. Наследие узнало тебя.")
            player:SendBroadcastMessage(TAG .. " Прорвись через " .. VOID_COLOR .. "тюремщиков|r, стерегущих Страж.")
        else
            WriteCounter(player, 2, "relic", n)
            player:SendBroadcastMessage(TAG .. " Реликвия откликнулась (" .. n .. "/" .. RELIC_TOTAL .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_HERALD, 1, ShowHeraldMenu)
RegisterCreatureGossipEvent(NPC_HERALD, 2, OnHeraldSelect)
RegisterCreatureGossipEvent(NPC_RELIC, 1, ShowRelicMenu)
RegisterCreatureGossipEvent(NPC_RELIC, 2, OnRelicSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign8.lua загружен (кампания 8 «Наследие Иллидана», главы 1–4).")