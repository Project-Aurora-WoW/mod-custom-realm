-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign9.lua
-- Назначение: кампания 9 «Экскурсия в Мир Проклятых» (главы 1–4).
-- Требования: завершена кампания 8 (item 70012 «Осколок Наследия»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 9).
-- НПС: 70270 Эмиссар Проклятых (старт), 70271 Проклятая Тень,
--       70272 Склеп Проклятия, 70273 Тюремщик Проклятых,
--       70541 Страж Проклятого Склепа.
-- Награда: item 70014 «Осколок Проклятия» (валюта модуля cursed).
-- Параллельный модуль (42_CurseWorld.lua) начисляет осколки за
-- убийство босса 70541 (cursed.pve_bosses). Синергия: прохождение
-- кампании даёт сюжет, а бой с боссом — очки турнира «Мир Проклятых».
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[9]
local CAMPAIGN_ID = 9
local DB_TABLE = REG.meta.db_table
local SHADE_REQUIRED = 4     -- глава 1: Проклятых Теней
local RELIC_TOTAL = 3        -- глава 2: Склепов Проклятия
local WARDEN_REQUIRED = 3    -- глава 3: Тюремщиков Проклятых
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Осколок Проклятия»
local REWARD_MAIL_DELAY = 60

-- Требование: «Осколок Наследия» (финал кампании 8)
local CAMPAIGN8_TOKEN = REG.campaigns[8].rewards.token

local NPC_HERALD = CAMPAIGN.npc.herald   -- Эмиссар Проклятых (старт)
local NPC_SHADE  = CAMPAIGN.npc.shade    -- Проклятая Тень (kill гл. 1)
local NPC_RELIC  = CAMPAIGN.npc.relic    -- Склеп Проклятия (interact гл. 2)
local NPC_WARDEN = CAMPAIGN.npc.warden   -- Тюремщик Проклятых (kill гл. 3)
local NPC_BOSS   = CAMPAIGN.npc.boss     -- Страж Проклятого Склепа (гл. 4)

local MENU_ROOT = 1
local MENU_START = 2   -- принять экскурсию
local MENU_RELIC = 3   -- коснуться Склепа Проклятия

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign8Token(player)
    return player:HasItem(CAMPAIGN8_TOKEN)
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
        "Осколок Проклятия",
        "Экскурсия в Мир Проклятых завершена. Ты прошёл проклятый склеп и " ..
        "сокрушил его Стража. Этот осколок — валюта сезона «Мир Проклятых». " ..
        "Пусть проклятие признает в тебе хозяина. — Эмиссар Проклятых",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Экскурсия в Мир Проклятых» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Осколок Проклятия»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " осилил экскурсию в Мир Проклятых и низверг его Стража!")
end

-- ============================================================
-- Старт кампании: Эмиссар Проклятых (Даларан, gossip 70270)
-- ============================================================

local function ShowHeraldMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Экскурсия пройдена. Проклятие над тобой не властно.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Мир Проклятых не для слабых. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign8Token(player) then
            player:GossipMenuAddItem(0, "«Эмиссар, почему проклятие зовёт меня?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Принеси Осколок Наследия. Только принявший наследие Иллидана слышит зов проклятого склепа.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 3 then
        player:GossipMenuAddItem(0, "«Состояние экскурсии?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnHeraldSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign8Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Эмиссар Проклятых:|r «Сначала Осколок Наследия. Ты ещё не готов.»")
            player:GossipComplete()
            return
        end
        player:Teleport(571, 3865.00, 7035.00, 150.00, 2.10)
        WriteCounter(player, 1, "shade", 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Проклятия»|r — развей " .. SHADE_REQUIRED .. " Проклятых Теней.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Эмиссар Проклятых:|r «" .. GetClassLine(player) .. "»")
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
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Проклятия»|r — выполнено. Тени рассеялись.")
            killer:SendBroadcastMessage(TAG .. " Найди " .. ORDER_COLOR .. "Склепы Проклятия|r — " .. RELIC_TOTAL .. " шт.")
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
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Тюремщики Проклятых»|r — выполнено. Стражи пали.")
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Страж Проклятого Склепа|r просыпается в центре. Убей его.")
        else
            WriteCounter(killer, 3, "warden", n)
            killer:SendBroadcastMessage(TAG .. " Тюремщик повержен (" .. n .. "/" .. WARDEN_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 4 «Страж Проклятого Склепа»|r — выполнено. Проклятие признало тебя.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 2: Склепы Проклятия (gossip 70272)
-- ============================================================

local function ShowRelicMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 2 then
        player:GossipMenuAddItem(0, "Коснуться Склепа Проклятия.", 0, MENU_RELIC)
    else
        player:GossipMenuAddItem(0, "Склеп дышит чужим проклятием. Он ждёт достойного.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnRelicSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 2 and not completed then
        local n = ReadCounter(player, "relic") + 1
        if n >= RELIC_TOTAL then
            SaveProgress(player, 3, false, "relic=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 2 «Склепы Проклятия»|r — выполнено. Проклятие узнало тебя.")
            player:SendBroadcastMessage(TAG .. " Прорвись через " .. VOID_COLOR .. "Тюремщиков Проклятых|r, стерегущих Страж.")
        else
            WriteCounter(player, 2, "relic", n)
            player:SendBroadcastMessage(TAG .. " Склеп откликнулся (" .. n .. "/" .. RELIC_TOTAL .. ").")
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

print("[EchoOfTheVoid] Campaign9.lua загружен (кампания 9 «Экскурсия в Мир Проклятых», главы 1–4).")