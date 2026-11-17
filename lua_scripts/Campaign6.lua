-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign6.lua
-- Назначение: кампания 6 «Утро было вчера» (главы 1–5).
-- Требования: завершена кампания 5 (item 70009 «Червоное Семя»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 6).
-- НПС: 70220 Глашатай Мимолётности (старт), 70221 Ложное Воспоминание,
--       70222 Семя Разлома, 70223 Эхо Сна, 70224 Страж Излома времени,
--       70522 Пожиратель Утр (финальный босс).
-- Награда: item 70010 «Вчерашний Рассвет».
-- Лор (арка «Хроники увядания»): Пустота больше не иссушает —
-- она пишет поддельные воспоминания. Время сломано: утро наступает
-- не тогда, когда должно. Кампания учит отличать чужой сон от своего.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[6]
local CAMPAIGN_ID = 6
local DB_TABLE = REG.meta.db_table
local FALSE_MEM_REQUIRED = 5   -- глава 1: ложных воспоминаний
local SEEDS_TOTAL = 3          -- глава 2: семян разлома
local DREAM_ECHO_REQUIRED = 4  -- глава 3: эхо сна
local WATCHER_TOTAL = 1        -- глава 4: страж излома времени
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Вчерашний Рассвет»
local REWARD_MAIL_DELAY = 60

-- Требование: «Червоное Семя» (финал кампании 5)
local CAMPAIGN5_TOKEN = REG.campaigns[5].rewards.token

local NPC_HERALD    = CAMPAIGN.npc.herald    -- Глашатай Мимолётности (старт)
local NPC_FALSE_MEM = CAMPAIGN.npc.false_mem -- Ложное Воспоминание (гл. 1)
local NPC_RIFT_SEED = CAMPAIGN.npc.rift_seed -- Семя Разлома (гл. 2)
local NPC_DREAM_ECHO = CAMPAIGN.npc.dream_echo -- Эхо Сна (гл. 3)
local NPC_WATCHER   = CAMPAIGN.npc.watcher   -- Страж Излома времени (гл. 4)
local NPC_BOSS      = CAMPAIGN.npc.boss      -- Пожиратель Утр (гл. 5)

local MENU_ROOT = 1
local MENU_START = 2   -- принять расследование
local MENU_SEED  = 3   -- разбудить семя
local MENU_WATCH = 4   -- спросить стража

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign5Token(player)
    return player:HasItem(CAMPAIGN5_TOKEN)
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
        "Вчерашний Рассвет",
        "Ты понял: утро — это не время, а выбор. Пустота дала тебе чужой сон, " ..
        "а ты выбрал своё. Этот рассвет — твой. — Глашатай Мимолётности",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Утро было вчера» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Вчерашний Рассвет»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " вернул утро в настоящее. Время вновь течёт вперёд.")
end

-- ============================================================
-- Старт кампании: Глашатай Мимолётности (Даларан, gossip 70220)
-- ============================================================

local function ShowHeraldMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Утро снова твоё. Но у памяти есть цена.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Не торопи время. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign5Token(player) then
            player:GossipMenuAddItem(0, "«Что с временем? Почему утро наступает не тогда?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Червоное Семя не проросло у тебя. Принеси его.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 4 then
        player:GossipMenuAddItem(0, "«Время?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnHeraldSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign5Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Глашатай:|r «Принеси Червоное Семя. Без корня не распутать время.»")
            player:GossipComplete()
            return
        end
        player:Teleport(571, 3865.00, 7035.00, 150.00, 2.10)
        WriteCounter(player, 1, "false_mem", 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Чужая память»|r — развей " .. FALSE_MEM_REQUIRED .. " ложных воспоминаний.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Глашатай:|r «" .. GetClassLine(player) .. "»")
        player:GossipComplete()
        return
    end
    player:GossipComplete()
end

-- ============================================================
-- Главы 1, 3, 5: kill-кредиты
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_FALSE_MEM and entry ~= NPC_DREAM_ECHO and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_FALSE_MEM and chapter == 1 then
        local n = ReadCounter(killer, "false_mem") + 1
        if n >= FALSE_MEM_REQUIRED then
            SaveProgress(killer, 2, false, "false_mem=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Чужая память»|r — выполнено. Ложь рассеялась.")
            killer:SendBroadcastMessage(TAG .. " В сердце аномалии есть " .. VOID_COLOR .. "семена разлома|r. Разбуди " .. SEEDS_TOTAL .. " из них.")
        else
            WriteCounter(killer, 1, "false_mem", n)
            killer:SendBroadcastMessage(TAG .. " Ложное воспоминание развеяно (" .. n .. "/" .. FALSE_MEM_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_DREAM_ECHO and chapter == 3 then
        local n = ReadCounter(killer, "dream_echo") + 1
        if n >= DREAM_ECHO_REQUIRED then
            SaveProgress(killer, 4, false, "dream_echo=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Эхо Сна»|r — выполнено. Сон больше не шепчет.")
            killer:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Страж Излома времени|r держит ключ к утру. Поговори с ним.")
        else
            WriteCounter(killer, 3, "dream_echo", n)
            killer:SendBroadcastMessage(TAG .. " Эхо Сна развеяно (" .. n .. "/" .. DREAM_ECHO_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 5 then
        SaveProgress(killer, 6, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 5 «Пожиратель Утр»|r — выполнено. Утро вернулось.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 2: семена разлома (gossip 70222)
-- ============================================================

local function ShowSeedMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 2 then
        player:GossipMenuAddItem(0, "Разбудить семя разлома.", 0, MENU_SEED)
    else
        player:GossipMenuAddItem(0, "Семя свернулось в клубок времени. Оно спит.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnSeedSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 2 and not completed then
        local n = ReadCounter(player, "seeds") + 1
        if n >= SEEDS_TOTAL then
            SaveProgress(player, 3, false, "seeds=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Семя Разлома»|r — выполнено. Из семян рвётся чужой сон.")
            player:SendBroadcastMessage(TAG .. " Разгони " .. VOID_COLOR .. "эхо Сна|r, что прячется за ними.")
        else
            WriteCounter(player, 2, "seeds", n)
            player:SendBroadcastMessage(TAG .. " Семя пробудилось (" .. n .. "/" .. SEEDS_TOTAL .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 4: Страж Излома времени (gossip 70224)
-- ============================================================

local function ShowWatcherMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 4 then
        player:GossipMenuAddItem(0, "«Страж, где спрятано утро?»", 0, MENU_WATCH)
    else
        player:GossipMenuAddItem(0, "Страж смотрит в прошлое, которого нет.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnWatcherSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 4 and not completed then
        local n = ReadCounter(player, "watcher") + 1
        if n >= WATCHER_TOTAL then
            SaveProgress(player, 5, false, "watcher=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 4 «Излом времени»|r — выполнено. Страж указал на Пожирателя Утр.")
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Пожиратель Утр|r жрёт рассветы. Останови его.")
        else
            WriteCounter(player, 4, "watcher", n)
            player:SendBroadcastMessage(TAG .. " Страж открыл путь к утру (" .. n .. "/" .. WATCHER_TOTAL .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_HERALD, 1, ShowHeraldMenu)
RegisterCreatureGossipEvent(NPC_HERALD, 2, OnHeraldSelect)
RegisterCreatureGossipEvent(NPC_RIFT_SEED, 1, ShowSeedMenu)
RegisterCreatureGossipEvent(NPC_RIFT_SEED, 2, OnSeedSelect)
RegisterCreatureGossipEvent(NPC_WATCHER, 1, ShowWatcherMenu)
RegisterCreatureGossipEvent(NPC_WATCHER, 2, OnWatcherSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign6.lua загружен (кампания 6, главы 1–5).")