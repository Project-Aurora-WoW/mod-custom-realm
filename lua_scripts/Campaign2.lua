-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign2.lua
-- Назначение: кампания 2 «Пепел Зул'Драка» (главы 1–5).
-- Требования: завершена кампания 1 (см. Campaign1.lua).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 2).
-- НПС: 70101 культисты, 70103 алтари, 70500 Хора Шёпота,
--       70130 Пророк Нал'кур, 70140 Сквернозор, 70150 Валирия.
-- Награда: item 70004 «Клеймо Стражей Пустоты».
-- Лор: docs/lore/universe.md, docs/campaigns/README.md.
-- ============================================================

-- Константы — из центрального реестра кампаний (00_CampaignRegistry.lua)
local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[2]
local CAMPAIGN_ID = 2
local DB_TABLE = REG.meta.db_table
local WAVE_MOBS_REQUIRED = 8      -- глава 1: культистов для прорыва
local ALTARS_TOTAL = 4            -- глава 4: алтарей нужно сжечь
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Клеймо Стражей Пустоты»
local REWARD_MAIL_DELAY = 60

-- Требование: «Слеза Рассвета» (финал кампании 1) — из реестра
local CAMPAIGN1_TOKEN = REG.campaigns[1].rewards.token

-- НПС кампании (entry из реестра)
local NPC_CULTIST = CAMPAIGN.npc.cultist      -- культисты (kill-кредит главы 1)
local NPC_BOSS = CAMPAIGN.npc.boss            -- Хора Шёпота (глава 2)
local NPC_PROPHET = CAMPAIGN.npc.prophet      -- Пророк Нал'кур (глава 3)
local NPC_ALTAR = CAMPAIGN.npc.altar          -- ритуальный алтарь (глава 4)
local NPC_DRAGON = CAMPAIGN.npc.dragon        -- Сквернозор (глава 5)
local NPC_COMMANDER = CAMPAIGN.npc.commander  -- Командир Валирия (старт)

-- Пункты gossip-меню
local MENU_ROOT = 1
local MENU_START = 2              -- принять осаду
local MENU_TALK = 3               -- диалог с Пророком
local MENU_REP = 4                -- отчёт Сквернозору

-- Проверка: у игрока есть токен кампании 1 и достаточный уровень
local MIN_LEVEL = REG.meta.min_level

local function HasCampaign1Token(player)
    return player:HasItem(CAMPAIGN1_TOKEN)
end

-- Классовая/расовая реплика игрока (из реестра)
local function GetClassLine(player)
    return REG.class_greetings[player:GetClass()] or ""
end

local function GetRaceLine(player)
    return REG.race_greetings[player:GetRace()] or ""
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
        "Клеймо Стражей Пустоты",
        "Ты доказал Стражам свою верность: культисты разбиты, алтари сожжены. " ..
        "Драконы признают тебя союзником. Это клеймо даст тебе право призыва дракона в финальной кампании. — Сквернозор",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Пепел Зул'Драка» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Клеймо Стражей Пустоты»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " снёс пепел Зул'Драка! Драконы признали нового союзника.")
end

-- ============================================================
-- Старт кампании: Командир Валирия (Даларан, gossip 70150)
-- ============================================================

local function ShowCommanderMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Пепел осел. Теперь — Пробуждение.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Зул'Драк перемелет тебя. Возвращайся на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign1Token(player) then
            player:GossipMenuAddItem(0, "«Командир, культ закрепился в Зул'Драке. Начинаем осаду?»", 0, MENU_START)
        else
            player:GossipMenuAddItem(0, "«Кто ты такой? Орден не берёт в осаду без Слезы Рассвета.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 and chapter <= 4 then
        player:GossipMenuAddItem(0, "«Статус операции?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnCommanderSelect(event, player, creature, sender, intid, code)
    if intid == MENU_START then
        if not HasCampaign1Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Валирия:|r «Сначала заслужи Слезу Рассвета в Драконьем Погосте.»")
            player:GossipComplete()
            return
        end
        -- Телепорт к воротам Зул'Драка, старт главы 1
        player:Teleport(571, 5700.00, 3020.00, 745.00, 2.10)
        WriteCounter(player, 1, "wave", 0)
        player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 1 «Осада»|r — прорвись через " .. WAVE_MOBS_REQUIRED .. " культистов к храму.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Валирия:|r «" .. GetClassLine(player) .. "»")
        player:GossipComplete()
        return
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 1: kill-кредит культистов
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_CULTIST and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_CULTIST and chapter == 1 then
        local wave = ReadCounter(killer, "wave") + 1
        if wave >= WAVE_MOBS_REQUIRED then
            SaveProgress(killer, 2, false, "wave=" .. wave)
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 1 «Осада»|r — выполнено. Ворота пали.")
            killer:SendBroadcastMessage(TAG .. " Внутри храма ждёт " .. VOID_COLOR .. "Хора Шёпота|r. Убей его.")
        else
            WriteCounter(killer, 1, "wave", wave)
            killer:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Культист повержен (" .. wave .. "/" .. WAVE_MOBS_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_BOSS and chapter == 2 then
        SaveProgress(killer, 3, false, "boss=1")
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Храм Шёпота»|r — выполнено. Хора Шёпота пала.")
        killer:SendBroadcastMessage(TAG .. " Пророк " .. VOID_COLOR .. "Нал'кур|r ждёт у алтаря. Поговори с ним.")
    end
end

-- ============================================================
-- Глава 3: Пророк Нал'кур — иллюзия (gossip 70130)
-- ============================================================

local function ShowProphetMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 3 then
        player:GossipMenuAddItem(0, "«Пророк! Зачем ты губишь этот мир?»", 0, MENU_TALK)
    else
        player:GossipMenuAddItem(0, "«Шёпот... шёпот... всё есть шёпот...»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnProphetSelect(event, player, creature, sender, intid, code)
    if intid == MENU_TALK then
        local chapter, completed = LoadProgress(player)
        if chapter == 3 and not completed then
            -- Сюжетный поворот: Нал'кур оказывается иллюзией
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Нал'кур:|r «Мир? Мир — это ткань. А ткань рвётся. Я — нить.»")
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Нал'кур:|r «Ты победил Хору... но не меня. Я никогда не был здесь.»")
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Иллюзия рассеивается! Пророк был лишь отражением Пустоты.|r")
            SaveProgress(player, 4, false, "prophet=illusion")
            player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 3 «Пророк Нал»|r — выполнено. Найди и сожги " .. ALTARS_TOTAL .. " ритуальных алтаря.")
            player:GossipComplete()
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 4: сжигание алтарей (gossip 70103)
-- ============================================================

local function ShowAltarMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 4 then
        player:GossipMenuAddItem(0, "Поджечь алтарь Культа.", 0, MENU_ROOT)
    else
        player:GossipMenuAddItem(0, "Алтарь покрыт чёрной слизью Пустоты.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnAltarSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 4 and not completed then
        local burned = ReadCounter(player, "altars") + 1
        if burned >= ALTARS_TOTAL then
            SaveProgress(player, 5, false, "altars=" .. burned)
            player:SendBroadcastMessage(TAG .. " " .. CULT_COLOR .. "Глава 4 «Пепел и пепелище»|r — выполнено. Все алтари сожжены.")
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Сквернозор|r ждёт на вершине. Докажи Стражам свою верность.")
        else
            WriteCounter(player, 4, "altars", burned)
            player:SendBroadcastMessage(TAG .. " Алтарь пылает! (" .. burned .. "/" .. ALTARS_TOTAL .. ")")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 5: Слово Дракона (gossip 70140)
-- ============================================================

local function ShowDragonMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 5 then
        player:GossipMenuAddItem(0, "«Великий Сквернозор, я сжёг алтари Культа. Прими мой союз.»", 0, MENU_REP)
    else
        player:GossipMenuAddItem(0, "«Дракон смотрит сквозь тебя, оценивая каждый твой шаг.»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnDragonSelect(event, player, creature, sender, intid, code)
    if intid == MENU_REP then
        local chapter, completed = LoadProgress(player)
        if chapter == 5 and not completed then
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Сквернозор:|r «Мы видели. Пепел Зул'Драка — твоя рекомендация.»")
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Сквернозор:|r «Стражи Пустоты признают тебя союзником. Когда ритуал начнётся — мы придём.»")
            SaveProgress(player, 6, true, "campaign_done=1")
            GrantReward(player)
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_COMMANDER, 1, ShowCommanderMenu)
RegisterCreatureGossipEvent(NPC_COMMANDER, 2, OnCommanderSelect)
RegisterCreatureGossipEvent(NPC_PROPHET, 1, ShowProphetMenu)
RegisterCreatureGossipEvent(NPC_PROPHET, 2, OnProphetSelect)
RegisterCreatureGossipEvent(NPC_ALTAR, 1, ShowAltarMenu)
RegisterCreatureGossipEvent(NPC_ALTAR, 2, OnAltarSelect)
RegisterCreatureGossipEvent(NPC_DRAGON, 1, ShowDragonMenu)
RegisterCreatureGossipEvent(NPC_DRAGON, 2, OnDragonSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign2.lua загружен (кампания 2, главы 1–5).")