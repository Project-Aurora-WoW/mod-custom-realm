-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign5.lua
-- Назначение: кампания 5 «Война Черной и Красной Розы» (главы 1–4).
-- Требования: завершена кампания 4 (item 70006 «Сердце Второго Эха»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 5).
-- НПС: 70211 Эмиссар Верин (старт), 70212 Адепт Красной Розы,
--       70213 Адепт Чёрной Розы, 70214 Перехваченный приказ,
--       70521 Владыка Шёпота (финальный босс).
-- Награда: item 70009 «Червоное Семя».
-- Лор (арка «Хроники увядания»): после развеяния Усмешка начинает
-- искажать память и время. Здесь — тайная война двух роз, разжигаемая
-- шёпотом, чтобы отвлечь Орден от настоящего разлома.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[5]
local CAMPAIGN_ID = 5
local DB_TABLE = REG.meta.db_table
local RED_ROSE_REQUIRED = 5      -- глава 1: адептов Красной Розы
local BLACK_ROSE_REQUIRED = 6    -- глава 2: адептов Чёрной Розы
local ORDERS_TOTAL = 3           -- глава 3: перехваченных приказов
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Червоное Семя»
local REWARD_MAIL_DELAY = 60

-- Требование: «Сердце Второго Эха» (финал кампании 4)
local CAMPAIGN4_TOKEN = REG.campaigns[4].rewards.token

local NPC_EMISSARY  = CAMPAIGN.npc.emissary    -- Эмиссар Верин (старт)
local NPC_RED_ROSE  = CAMPAIGN.npc.red_rose    -- Адепт Красной Розы (гл. 1)
local NPC_BLACK_ROSE = CAMPAIGN.npc.black_rose -- Адепт Чёрной Розы (гл. 2)
local NPC_SCROLL   = CAMPAIGN.npc.scroll       -- Перехваченный приказ (гл. 3)
local NPC_BOSS     = CAMPAIGN.npc.boss         -- Владыка Шёпота (гл. 4)

local MENU_ROOT = 1
local MENU_START = 2     -- принять расследование войны роз
local MENU_SCROLL = 3    -- вскрыть перехваченный приказ
local MENU_REPORT = 4    -- отчитаться Верину

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign4Token(player)
    return player:HasItem(CAMPAIGN4_TOKEN)
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
        "Червоное Семя",
        "Война двух роз кончилась тем, что обеих развёл один шёпот. " ..
        "Это семя проросло из пепла. Посади его у разлома — оно укажет, " ..
        "где настоящее утро, а где обман. — Эмиссар Верин",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Война Черной и Красной Розы» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Червоное Семя»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " оборвал войну двух роз и добрался до корня шёпота.")
end

-- ============================================================
-- Старт кампании: Эмиссар Верин (Даларан, gossip 70211)
-- ============================================================

local function ShowEmissaryMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Семя посажено. Теперь пустим корни в само время.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Война роз — не для слабых. Займись разломом на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign4Token(player) then
            player:GossipMenuAddItem(0, "«Эмиссар, что за война между Красной и Чёрной Розой?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Ты ещё не добрался до сути Второго Эха. Принеси Сердце Второго Эха.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 3 then
        player:GossipMenuAddItem(0, "«Статус расследования?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnEmissarySelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign4Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Верин:|r «Сначала Сердце Второго Эха. Без него ты не увидишь общей картины.»")
            player:GossipComplete()
            return
        end
        -- Телепорт на арену войны роз, старт главы 1
        player:Teleport(571, 3899.60, 7049.10, 151.40, 0.30)
        WriteCounter(player, 1, "red_rose", 0)
        player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 1 «Красные клинки»|r — разберись с " .. RED_ROSE_REQUIRED .. " адептами Красной Розы.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Верин:|r «" .. GetClassLine(player) .. "»")
        player:GossipComplete()
        return
    end
    player:GossipComplete()
end

-- ============================================================
-- Главы 1–2: kill-кредиты адептов обеих роз
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_RED_ROSE and entry ~= NPC_BLACK_ROSE and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_RED_ROSE and chapter == 1 then
        local n = ReadCounter(killer, "red_rose") + 1
        if n >= RED_ROSE_REQUIRED then
            SaveProgress(killer, 2, false, "red_rose=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 1 «Красные клинки»|r — выполнено. Красная Роза отступила.")
            killer:SendBroadcastMessage(TAG .. " Но за ней тянется след Чёрной. Найди " .. BLACK_ROSE_REQUIRED .. " адептов Чёрной Розы.")
        else
            WriteCounter(killer, 1, "red_rose", n)
            killer:SendBroadcastMessage(TAG .. " Адепт Красной Розы повержен (" .. n .. "/" .. RED_ROSE_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BLACK_ROSE and chapter == 2 then
        local n = ReadCounter(killer, "black_rose") + 1
        if n >= BLACK_ROSE_REQUIRED then
            SaveProgress(killer, 3, false, "black_rose=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 2 «Чёрная Роза»|r — выполнено. Обе розы разбиты.")
            killer:SendBroadcastMessage(TAG .. " Подбери " .. VOID_COLOR .. "перехваченные приказы|r — в них имя настоящего дирижёра.")
        else
            WriteCounter(killer, 2, "black_rose", n)
            killer:SendBroadcastMessage(TAG .. " Адепт Чёрной Розы повержен (" .. n .. "/" .. BLACK_ROSE_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 4 «Владыка Шёпота»|r — выполнено. Война роз завершена.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 3: перехваченные приказы (gossip 70214)
-- ============================================================

local function ShowScrollMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 3 then
        player:GossipMenuAddItem(0, "Вскрыть приказ обеих роз.", 0, MENU_SCROLL)
    else
        player:GossipMenuAddItem(0, "Письмо напитано шёпотом. Оно ждёт своего часа.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnScrollSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 3 and not completed then
        local n = ReadCounter(player, "orders") + 1
        if n >= ORDERS_TOTAL then
            SaveProgress(player, 4, false, "orders=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 3 «Приказы из тьмы»|r — выполнено. Обе розы писали один и тот же почерк.")
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Владыка Шёпота|r — тот, кто водил обеими руками. Убей его.")
        else
            WriteCounter(player, 3, "orders", n)
            player:SendBroadcastMessage(TAG .. " Приказ вскрыт (" .. n .. "/" .. ORDERS_TOTAL .. "). Внутри — общий почерк Пустоты.")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_EMISSARY, 1, ShowEmissaryMenu)
RegisterCreatureGossipEvent(NPC_EMISSARY, 2, OnEmissarySelect)
RegisterCreatureGossipEvent(NPC_SCROLL, 1, ShowScrollMenu)
RegisterCreatureGossipEvent(NPC_SCROLL, 2, OnScrollSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign5.lua загружен (кампания 5, главы 1–4).")