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

-- ============================================================
-- Локализация ru/en (системные/игровые сообщения; лор-цитаты — на русском)
-- ============================================================
local L = {
    ru = {
        notReady     = "«%s:|r Сначала %s. Ты ещё не готов.»",
        ch1Start     = "Глава 1 «Тень Светлой Лжи»|r — развей %d Теней лжесвятого.",
        ch1Done      = "Глава 1 «Тень Светлой Лжи»|r — выполнено. Тени рассеялись.",
        ch1Find      = "Найди %sЧасовни Лжи|r — %d шт.",
        ch1Progress  = "Тень развеяна (%d/%d).",
        ch2Done      = "Глава 2 «Часовни Лжи»|r — выполнено. Истина увидела тебя.",
        ch2Next      = "Прорвись через %sСтражей-отступников|r, стерегущих Плащаницу.",
        ch2Progress  = "Часовня откликнулась (%d/%d).",
        ch3Done      = "Глава 3 «Стражи-отступники»|r — выполнено. Стражи пали.",
        ch3Next      = "%sПлащаница Светлой Лжи|r просыпается в центре. Обличи её.",
        ch3Progress  = "Страж-отступник повержен (%d/%d).",
        ch4Done      = "Глава 4 «Плащаница Светлой Лжи»|r — выполнено. Ложь изгнана.",
        comp         = "Кампания «Светлая Ложь Альянса» завершена!",
        reward       = "Награда — %s«Свет Истины»|r — придёт почтой.",
        worldDone    = " обличил Светлую Ложь Альянса и низверг её Плащаницу!",
    },
    en = {
        notReady     = "«%s:|r First, %s. You are not ready yet.»",
        ch1Start     = "Chapter 1 «Shade of the Bright Lie»|r — dispel %d false-saint shades.",
        ch1Done      = "Chapter 1 «Shade of the Bright Lie»|r — done. Shades dispelled.",
        ch1Find      = "Find %sChaplins of the Lie|r — %d pcs.",
        ch1Progress  = "Shade dispelled (%d/%d).",
        ch2Done      = "Chapter 2 «Chaplins»|r — done. Truth saw you.",
        ch2Next      = "Break through the %sRenegade Guards|r guarding the Shroud.",
        ch2Progress  = "Chapel responded (%d/%d).",
        ch3Done      = "Chapter 3 «Renegade Guards»|r — done. Guards fallen.",
        ch3Next      = "%sShroud of the Bright Lie|r awakens. Expose it.",
        ch3Progress  = "Renegade slain (%d/%d).",
        ch4Done      = "Chapter 4 «Shroud of the Lie»|r — done. The lie is vanquished.",
        comp         = "Campaign «The Bright Lie of the Alliance» completed!",
        reward       = "Reward — %sLight of Truth|r — will arrive by mail.",
        worldDone    = " exposed the Bright Lie of the Alliance and brought down its Shroud!",
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
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. Loc(player, "comp") .. "|r")
    player:SendBroadcastMessage(TAG .. " " .. Loc(player, "reward", ORDER_COLOR))
    SendWorldMessage(TAG .. " " .. player:GetName() .. Loc(player, "worldDone"))
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
            player:SendBroadcastMessage(TAG .. Loc(player, "notReady", "Праведник Мораин", "Осколок Проклятия"))
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
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. Loc(killer, "ch1Done") .. "|r")
            killer:SendBroadcastMessage(TAG .. " " .. Loc(killer, "ch1Find", ORDER_COLOR, RELIC_TOTAL))
        else
            WriteCounter(killer, 1, "shade", n)
            killer:SendBroadcastMessage(TAG .. Loc(killer, "ch1Progress", n, SHADE_REQUIRED))
        end
        return
    end

    if entry == NPC_WARDEN and chapter == 3 then
        local n = ReadCounter(killer, "warden") + 1
        if n >= WARDEN_REQUIRED then
            SaveProgress(killer, 4, false, "warden=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. Loc(killer, "ch3Done") .. "|r")
            killer:SendBroadcastMessage(TAG .. " " .. Loc(killer, "ch3Next", CULT_COLOR))
        else
            WriteCounter(killer, 3, "warden", n)
            killer:SendBroadcastMessage(TAG .. Loc(killer, "ch3Progress", n, WARDEN_REQUIRED))
        end
        return
    end

    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. Loc(killer, "ch4Done") .. "|r")
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
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. Loc(player, "ch2Done") .. "|r")
            player:SendBroadcastMessage(TAG .. " " .. Loc(player, "ch2Next", VOID_COLOR))
        else
            WriteCounter(player, 2, "relic", n)
            player:SendBroadcastMessage(TAG .. Loc(player, "ch2Progress", n, RELIC_TOTAL))
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