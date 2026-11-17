-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign10.lua
-- Назначение: кампания 10 «Светлая Ложь Альянса» (главы 1–4).
-- Требования: завершена кампания 9 (item 70014 «Осколок Проклятия»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 10).
-- НПС: 70280 Праведник Мораин (старт), 70281 Тень Светлой Лжи,
--       70282 Часовня Лжи, 70283 Страж-отступник,
--       70542 Плащаница Светлой Лжи.
-- Награда: item 70016 «Свет Истины» (валюта модуля lightlie).
-- Параллельный модуль (43_LightLie.lua) начисляет свет за убийство
-- босса 70542 (lightlie.pve_bosses). Синергия: прохождение кампании
-- даёт сюжет, а бой с боссом — очки турнира «Светлая Ложь Альянса».
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[10]
local CAMPAIGN_ID = 10
local DB_TABLE = REG.meta.db_table
local SHADE_REQUIRED = 4     -- глава 1: Теней Светлой Лжи
local RELIC_TOTAL = 3        -- глава 2: Часовен Лжи
local WARDEN_REQUIRED = 3    -- глава 3: Стражей-отступников
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Свет Истины»
local REWARD_MAIL_DELAY = 60

-- Требование: «Осколок Проклятия» (финал кампании 9)
local CAMPAIGN9_TOKEN = REG.campaigns[9].rewards.token

local NPC_HERALD = CAMPAIGN.npc.herald   -- Праведник Мораин (старт)
local NPC_SHADE  = CAMPAIGN.npc.shade    -- Тень Светлой Лжи (kill гл. 1)
local NPC_RELIC  = CAMPAIGN.npc.relic    -- Часовня Лжи (interact гл. 2)
local NPC_WARDEN = CAMPAIGN.npc.warden   -- Страж-отступник (kill гл. 3)
local NPC_BOSS   = CAMPAIGN.npc.boss     -- Плащаница Светлой Лжи (гл. 4)

local MENU_ROOT = 1
local MENU_START = 2   -- принять призвание Светлой Истины
local MENU_RELIC = 3   -- коснуться Часовни Лжи

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign9Token(player)
    return player:HasItem(CAMPAIGN9_TOKEN)
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
        "Свет Истины",
        "Ты обличил Светлую Ложь и низверг её Плащаницу. Этот свет — валюта " ..
        "сезона «Светлая Ложь Альянса». Пусть твоё имя вспомнят под святым " ..
        "сводом. — Праведник Мораин",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Светлая Ложь Альянса» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Свет Истины»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " обличил Светлую Ложь Альянса и низверг её Плащаницу!")
end

-- ============================================================
-- Старт кампании: Праведник Мораин (Даларан, gossip 70280)
-- ============================================================

local function ShowHeraldMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Светлая Ложь разоблачена. Истина больше не спит.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Против лжи нужен сильный дух. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign9Token(player) then
            player:GossipMenuAddItem(0, "«Праведник, почему Светлая Ложь пускает корни в Альянсе?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Принеси Осколок Проклятия. Только прошедший Мир Проклятых видит ложь под святым светом.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 3 then
        player:GossipMenuAddItem(0, "«Состояние поисков?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnHeraldSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign9Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Праведник Мораин:|r «Сначала Осколок Проклятия. Ты ещё не готов.»")
            player:GossipComplete()
            return
        end
        player:Teleport(571, 3865.00, 7035.00, 150.00, 2.10)
        WriteCounter(player, 1, "shade", 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Светлой Лжи»|r — развей " .. SHADE_REQUIRED .. " Теней лжесвятого.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Праведник Мораин:|r «" .. GetClassLine(player) .. "»")
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
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Тень Светлой Лжи»|r — выполнено. Тени рассеялись.")
            killer:SendBroadcastMessage(TAG .. " Найди " .. ORDER_COLOR .. "Часовни Лжи|r — " .. RELIC_TOTAL .. " шт.")
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
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Стражи-отступники»|r — выполнено. Стражи пали.")
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Плащаница Светлой Лжи|r просыпается в центре. Обличи её.")
        else
            WriteCounter(killer, 3, "warden", n)
            killer:SendBroadcastMessage(TAG .. " Страж-отступник повержен (" .. n .. "/" .. WARDEN_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 4 «Плащаница Светлой Лжи»|r — выполнено. Ложь изгнана.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 2: Часовни Лжи (gossip 70282)
-- ============================================================

local function ShowRelicMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 2 then
        player:GossipMenuAddItem(0, "Коснуться Часовни Лжи.", 0, MENU_RELIC)
    else
        player:GossipMenuAddItem(0, "Часовня гудит чужим гимном. Она ждёт обличителя.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnRelicSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 2 and not completed then
        local n = ReadCounter(player, "relic") + 1
        if n >= RELIC_TOTAL then
            SaveProgress(player, 3, false, "relic=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 2 «Часовни Лжи»|r — выполнено. Истина увидела тебя.")
            player:SendBroadcastMessage(TAG .. " Прорвись через " .. VOID_COLOR .. "Стражей-отступников|r, стерегущих Плащаницу.")
        else
            WriteCounter(player, 2, "relic", n)
            player:SendBroadcastMessage(TAG .. " Часовня откликнулась (" .. n .. "/" .. RELIC_TOTAL .. ").")
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

print("[EchoOfTheVoid] Campaign10.lua загружен (кампания 10 «Светлая Ложь Альянса», главы 1–4).")