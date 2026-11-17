-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign7.lua
-- Назначение: кампания 7 «Последняя Любовь Сильваны» (главы 1–5).
-- Требования: завершена кампания 6 (item 70010 «Вчерашний Рассвет»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 7).
-- НПС: 70230 Банши-Куратор (старт), 70231 Чумной Страж,
--       70232 Медальон, 70233 Тень Ветра Строг, 70234 Хранительница Склепа,
--       70523 Королева-Плач (финальный босс).
-- Награда: item 70011 «Пепел Сильваны».
-- Лор (арка «Хроники увядания», финал): Пустота приходит к Сильване
-- с искушением вернуть всё, что она потеряла. Последняя любовь,
-- устоявшая перед шёпотом, — это её выбор. Кампания закрывает арку.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[7]
local CAMPAIGN_ID = 7
local DB_TABLE = REG.meta.db_table
local PLAGUED_REQUIRED = 5   -- глава 1: чумных стражей
local LOCKET_TOTAL = 1       -- глава 4: медальон (gate)
local SHADE_REQUIRED = 3     -- глава 3: теней Ветра Строг
local CRYPT_REQUIRED = 1     -- глава 4: хранительница склепа
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Пепел Сильваны»
local REWARD_MAIL_DELAY = 60

-- Требование: «Вчерашний Рассвет» (финал кампании 6)
local CAMPAIGN6_TOKEN = REG.campaigns[6].rewards.token

local NPC_BANSHEE   = CAMPAIGN.npc.banshee    -- Банши-Куратор (старт)
local NPC_PLAGUED   = CAMPAIGN.npc.plagued    -- Чумной Страж (гл. 1)
local NPC_LOCKET    = CAMPAIGN.npc.locket     -- Медальон (гл. 2)
local NPC_SHADE     = CAMPAIGN.npc.shade      -- Тень Ветра Строг (гл. 3)
local NPC_CRYPT     = CAMPAIGN.npc.crypt_ward -- Хранительница Склепа (гл. 4)
local NPC_BOSS      = CAMPAIGN.npc.boss       -- Королева-Плач (гл. 5)

local MENU_ROOT = 1
local MENU_START = 2   -- принять обет
local MENU_LOCKET = 3  -- коснуться медальона
local MENU_CRYPT = 4   -- открыть склеп

local MIN_LEVEL = REG.meta.min_level

local function HasCampaign6Token(player)
    return player:HasItem(CAMPAIGN6_TOKEN)
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
        "Пепел Сильваны",
        "Она стояла перед шёпотом, который обещал вернуть ей всё, — и выбрала " ..
        "не возвращать, а помнить. Этот пепел — то, что осталось от последней " ..
        "любви, устоявшей перед Пустотой. Храни его. — Банши-Куратор",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Последняя Любовь Сильваны» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Пепел Сильваны»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " стал свидетелем последней любви, устоявшей перед Пустотой.")
end

-- ============================================================
-- Старт кампании: Банши-Куратор (Даларан, gossip 70230)
-- ============================================================

local function ShowBansheeMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Пепел хранит память. Пусть так и будет.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Скорбь — не для слабых. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign6Token(player) then
            player:GossipMenuAddItem(0, "«Почему Пустота чарует именно её?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Принеси Вчерашний Рассвет. Без него не увидишь истинной тени.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 4 then
        player:GossipMenuAddItem(0, "«Как там её испытание?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnBansheeSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign6Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Куратор:|r «Без Вчерашнего Рассвета ты не пройдёшь сквозь её тень.»")
            player:GossipComplete()
            return
        end
        player:Teleport(571, 3850.00, 7030.00, 149.00, 2.10)
        WriteCounter(player, 1, "plagued", 0)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Чумные Стражи»|r — разгони " .. PLAGUED_REQUIRED .. " стражей скорби.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Куратор:|r «" .. GetClassLine(player) .. "»")
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
    if entry ~= NPC_PLAGUED and entry ~= NPC_SHADE and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_PLAGUED and chapter == 1 then
        local n = ReadCounter(killer, "plagued") + 1
        if n >= PLAGUED_REQUIRED then
            SaveProgress(killer, 2, false, "plagued=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Чумные Стражи»|r — выполнено. Стражи рассеялись.")
            killer:SendBroadcastMessage(TAG .. " Найди " .. ORDER_COLOR .. "медальон|r — в нём её память.")
        else
            WriteCounter(killer, 1, "plagued", n)
            killer:SendBroadcastMessage(TAG .. " Чумной Страж повержен (" .. n .. "/" .. PLAGUED_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_SHADE and chapter == 3 then
        local n = ReadCounter(killer, "shade") + 1
        if n >= SHADE_REQUIRED then
            SaveProgress(killer, 4, false, "shade=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Тень Ветра Строг»|r — выполнено. Тень генлера упокоена.")
            killer:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Хранительница Склепа|r ждёт у входа в последнее упокоение.")
        else
            WriteCounter(killer, 3, "shade", n)
            killer:SendBroadcastMessage(TAG .. " Тень развеяна (" .. n .. "/" .. SHADE_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 5 then
        SaveProgress(killer, 6, true, "campaign_done=1;boss=slain")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 5 «Королева-Плач»|r — выполнено. Плач стих.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Глава 2: медальон (gossip 70232)
-- ============================================================

local function ShowLocketMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 2 then
        player:GossipMenuAddItem(0, "Коснуться медальона.", 0, MENU_LOCKET)
    else
        player:GossipMenuAddItem(0, "Медальон хранит её имя. Он молчит.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnLocketSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 2 and not completed then
        local n = ReadCounter(player, "locket") + 1
        if n >= LOCKET_TOTAL then
            SaveProgress(player, 3, false, "locket=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 2 «Медальон»|r — выполнено. Внутри — имя генерала Ветра Строг.")
            player:SendBroadcastMessage(TAG .. " Разведи " .. VOID_COLOR .. "тень Ветра Строг|r, что тянется за ней.")
        else
            WriteCounter(player, 2, "locket", n)
            player:SendBroadcastMessage(TAG .. " Медальон тёплый на миг (" .. n .. "/" .. LOCKET_TOTAL .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 4: Хранительница Склепа (gossip 70234)
-- ============================================================

local function ShowCryptMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 4 then
        player:GossipMenuAddItem(0, "«Открой склеп. Я должен остановить её плач.»", 0, MENU_CRYPT)
    else
        player:GossipMenuAddItem(0, "Склеп заперт печалью, что не отпускает.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnCryptSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 4 and not completed then
        local n = ReadCounter(player, "crypt") + 1
        if n >= CRYPT_REQUIRED then
            SaveProgress(player, 5, false, "crypt=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 4 «Склеп»|r — выполнено. Внутри её плач.")
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Королева-Плач|r ждёт, чтобы не отпустить шёпот. Останови её.")
        else
            WriteCounter(player, 4, "crypt", n)
            player:SendBroadcastMessage(TAG .. " Склеп приоткрылся (" .. n .. "/" .. CRYPT_REQUIRED .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_BANSHEE, 1, ShowBansheeMenu)
RegisterCreatureGossipEvent(NPC_BANSHEE, 2, OnBansheeSelect)
RegisterCreatureGossipEvent(NPC_LOCKET, 1, ShowLocketMenu)
RegisterCreatureGossipEvent(NPC_LOCKET, 2, OnLocketSelect)
RegisterCreatureGossipEvent(NPC_CRYPT, 1, ShowCryptMenu)
RegisterCreatureGossipEvent(NPC_CRYPT, 2, OnCryptSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign7.lua загружен (кампания 7, главы 1–5).")