-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign3.lua
-- Назначение: кампания 3 «Пробуждение» (главы 1–4) — финал арки.
-- Требование: завершена кампания 2 (Клеймо Стражей, item 70004).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 3).
-- НПС: 70160 Советник Мортега (глава 1), 70105 Пустотные Стражи
--       (глава 2), 70106 Очаги Ритуала (глава 3), 70510 Усмешка
--       Бездны (глава 4, рейд-босс с 3 фазами по HP).
-- Награды: item 70002 «Печать Хранителя Эха» (титул-токен),
--          item 70003 «Бездна-Пегас» (маунт-токен).
-- Лор: docs/lore/universe.md, docs/campaigns/README.md.
-- ============================================================

-- Константы — из центрального реестра кампаний (00_CampaignRegistry.lua)
local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[3]
local CAMPAIGN_ID = 3
local DB_TABLE = REG.meta.db_table
local GUARDS_REQUIRED = 10       -- глава 2: elite-мобов для прорыва
local RITUAL_FIRES = 3           -- глава 3: очагов ритуала
local BOSS_PHASE_HP = { 0.75, 0.50, 0.25 } -- пороги фаз босса (75/50/25%)
local PHASE_ADD_ENTRY = CAMPAIGN.npc.void_spawn -- Ахерон-Пустотники призываются в фазах
local REWARD_ITEM_TITLE = CAMPAIGN.rewards.title_token -- «Печать Хранителя Эха»
local REWARD_ITEM_MOUNT = CAMPAIGN.rewards.mount_token -- «Бездна-Пегас»
local REWARD_MAIL_DELAY = 60

-- Требование: «Клеймо Стражей Пустоты» (финал кампании 2) — из реестра
local CAMPAIGN2_TOKEN = REG.campaigns[2].rewards.token

-- Проверка: у игрока есть токен кампании 2 и достаточный уровень
local MIN_LEVEL = REG.meta.min_level

local function HasCampaign2Token(player)
    return player:HasItem(CAMPAIGN2_TOKEN)
end

-- Классовая реплика игрока (из реестра)
local function GetClassLine(player)
    return REG.class_greetings[player:GetClass()] or ""
end

-- Прочитать фракцию, выбранную игроком в главе 1
local function ReadFaction(player)
    local q = CharDBQuery(string.format(
        "SELECT progress_data FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        return string.match(q:GetString(0) or "", "faction=(%a+)") or "alliance"
    end
    return "alliance"
end

-- НПС кампании (entry из реестра)
local NPC_ADVISOR = CAMPAIGN.npc.advisor      -- Советник Мортега (глава 1)
local NPC_VOID_GUARD = CAMPAIGN.npc.void_guard -- Пустотный Страж (kill-кредит главы 2)
local NPC_RITUAL_FIRE = CAMPAIGN.npc.ritual_fire -- Очаг Ритуала (глава 3)
local NPC_BOSS = CAMPAIGN.npc.boss            -- Усмешка Бездны (глава 4)

-- Пункты gossip-меню
local MENU_ROOT = 1
local MENU_COUNCIL = 2           -- глава 1: начать совет
local MENU_ALLIANCE = 3          -- глава 1: ветка Альянса
local MENU_HORDE = 4             -- глава 1: ветка Орды
local MENU_MARCH = 5             -- глава 1: выступить в поход
local MENU_FIRE = 6              -- глава 3: погасить очаг

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
-- Награда финала
-- ============================================================

local function GrantFinalReward(player)
    SendMail(
        "Печать Хранителя Эха",
        "Усмешка Бездны низвергнута. Эхо умолкает... но Пустота вечна. " ..
        "Носи эту печать — знак того, что ты остановил Пробуждение. — Совет Ордена Рассвета",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM_TITLE
    )
    SendMail(
        "Бездна-Пегас",
        "Сквернозор прислал это: теневой скакун, рождённый из самого разлома. " ..
        "Стражи Пустоты отдают его тебе по праву союза. — Советник Мортега",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY + 5, REWARD_ITEM_MOUNT
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "КАМПАНИЯ «ПРОБУЖДЕНИЕ» ЗАВЕРШЕНА!|r")
    player:SendBroadcastMessage(TAG .. " Награды придут почтой: " .. ORDER_COLOR .. "«Печать Хранителя Эха»|r и " .. VOID_COLOR .. "«Бездна-Пегас»|r.")
    player:SendBroadcastMessage(TAG .. " Ты — " .. VOID_COLOR .. "Хранитель Эха|r. Первая арка завершена... но Пустота вечна.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " одолел Усмешку Бездны! Пробуждение остановлено. Новый Хранитель Эха среди нас!")
end

-- ============================================================
-- Глава 1: Последний совет (gossip НПС 70160)
-- ============================================================

local function ShowAdvisorMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Эхо умолкло. Аракава гордится тобой, Хранитель.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Совет — не место для юнцов. Возвращайся на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if player:HasItem(CAMPAIGN2_TOKEN) then
            player:GossipMenuAddItem(0, "«Советник, культ начинает ритуал. Собираем совет?»", 0, MENU_COUNCIL)
        else
            player:GossipMenuAddItem(0, "«Без Клейма Стражей тебе не место на совете. Стражи должны доверять тебе.»", 0, MENU_ROOT)
        end
    elseif chapter == 1 then
        -- Выбор ветки фракции (механика главы 1)
        player:GossipMenuAddItem(0, "«Я поведу силы Альянса.»", 0, MENU_ALLIANCE)
        player:GossipMenuAddItem(0, "«Я поведу силы Орды.»", 0, MENU_HORDE)
    elseif chapter == 2 then
        -- Фракционный поход: телепорт к точке сбора выбранной фракции
        player:GossipMenuAddItem(0, "«Мы выступаем. Веди к разлому!»", 0, MENU_MARCH)
    else
        player:GossipMenuAddItem(0, "«Культ начал ритуал. Спеши к разлому!»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnAdvisorSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)

    if intid == MENU_COUNCIL and chapter == 0 and not completed then
        if not player:HasItem(CAMPAIGN2_TOKEN) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Мортега:|r «Сначала заслужи Клеймо Стражей в Зул'Драке.»")
            player:GossipComplete()
            return
        end
        if player:GetLevel() < MIN_LEVEL then
            player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Совет не для юнцов. Расти, герой.»")
            player:GossipComplete()
            return
        end
        -- Лор-брифинг главы 1 «Последний совет» + классовая реплика
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «" .. GetClassLine(player) .. "»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Культ вернулся к осколку. Стражи Пустоты подтверждают: ритуал начнётся в полнолуние.»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Впервые со времён Терамор Альянс и Орда встанут плечом к плечу.»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Выбери, чьи знамёна поведёшь к разлому.»")
        SaveProgress(player, 1, false, "")
        player:GossipComplete()
        return
    end

    if chapter == 1 and (intid == MENU_ALLIANCE or intid == MENU_HORDE) then
        local faction
        if intid == MENU_ALLIANCE then
            faction = "alliance"
            player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Знамёна Альянса! Штормградские рыцари будут драться под твоим началом.»")
        else
            faction = "horde"
            player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Мортега:|r «Знамёна Орды! Волки Оргриммара пойдут с тобой в сердце разлома.»")
        end
        SaveProgress(player, 1, false, "faction=" .. faction)
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 1 «Последний совет»|r — выполнено. Скажи, когда выступать.")
        player:GossipComplete()
        return
    end

    -- Фракционный поход: телепорт к точке сбора выбранной ветки (глава 2)
    if intid == MENU_MARCH and chapter == 2 and not completed then
        local faction = ReadFaction(player)
        local rally = CAMPAIGN.faction_rally and CAMPAIGN.faction_rally[faction]
        if rally then
            player:Teleport(rally.map, rally.x, rally.y, rally.z, rally.o)
            if faction == "alliance" then
                player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "«Знамёна Льва над Драконьим Погостом. Северный путь — наш.»")
            else
                player:SendBroadcastMessage(TAG .. CULT_COLOR .. "«Костры Орды горят на юге. Волки идут к разлому.»")
            end
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Разлом в сердце»|r — прорвись через " .. GUARDS_REQUIRED .. " Пустотных Стражей.")
        end
        player:GossipComplete()
        return
    end

    player:GossipComplete()
end

-- ============================================================
-- Глава 2: прорыв (kill-кредит Пустотных Стражей)
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_VOID_GUARD and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_VOID_GUARD and chapter == 2 then
        local guards = ReadCounter(killer, "guards") + 1
        if guards >= GUARDS_REQUIRED then
            SaveProgress(killer, 3, false, "guards=" .. guards)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Разлом в сердце»|r — выполнено. Путь к осколку открыт.")
            killer:SendBroadcastMessage(TAG .. " Погаси " .. RITUAL_FIRES .. " " .. VOID_COLOR .. "Очага Ритуала|r у осколка Трона.")
        else
            WriteCounter(killer, 2, "guards", guards)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Пустотный Страж повержен (" .. guards .. "/" .. GUARDS_REQUIRED .. ").")
        end
        return
    end

    -- Глава 4: убийство рейд-босса завершает кампанию
    if entry == NPC_BOSS and chapter == 4 then
        SaveProgress(killer, 5, true, "campaign_done=1;boss=slain")
        GrantFinalReward(killer)
    end
end

-- ============================================================
-- Глава 3: срыв ритуала (gossip НПС 70106)
-- ============================================================

local function ShowFireMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 3 then
        player:GossipMenuAddItem(0, "Погасить очаг ритуала.", 0, MENU_FIRE)
    else
        player:GossipMenuAddItem(0, "Очаг бьётся черным пламенем Пустоты.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnFireSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 3 and not completed and intid == MENU_FIRE then
        local extinguished = ReadCounter(player, "fires") + 1
        if extinguished >= RITUAL_FIRES then
            SaveProgress(player, 4, false, "fires=" .. extinguished)
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Ритуал»|r — выполнено. Очаги погашены!")
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. " Из тени осколка поднимается... УСМЕШКА БЕЗДНЫ.|r")
            player:SendBroadcastMessage(TAG .. " Убей осколочную форму Старого Бога. Осторожно: в фазах боя он зовёт Пустотников!")
        else
            WriteCounter(player, 3, "fires", extinguished)
            player:SendBroadcastMessage(TAG .. " Очаг погас. (" .. extinguished .. "/" .. RITUAL_FIRES .. ")")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 4: рейд-босс — 3 фазы (призыв аддов по порогам HP)
-- ============================================================

local PHASE_ADDS_PER_TRIGGER = 2

local function OnCreatureDamage(event, attacker, victim, amount)
    if not victim or victim:GetEntry() ~= NPC_BOSS then
        return
    end

    local maxHp = victim:GetMaxHealth()
    if maxHp <= 0 then
        return
    end
    local hpRatio = victim:GetHealth() / maxHp

    -- Определяем текущую фазу по порогам (75/50/25%)
    local phase = 0
    for i, threshold in ipairs(BOSS_PHASE_HP) do
        if hpRatio <= threshold then
            phase = i
        end
    end
    if phase == 0 then
        return
    end

    -- Фаза уже была триггернута (таймер через дату последнего спавна в мире)
    -- Простая защита: не спавнить чаще раза в 30 сек (cooldown через UpdateWorldState не доступен,
    -- поэтому используем хеш по времени)
    local now = os.time()
    local lastTrigger = victim:GetData(0) or 0
    if now - lastTrigger < 30 then
        return
    end
    victim:SetData(0, now)

    -- Призыв Пустотников (слабая версия в фазах)
    for i = 1, PHASE_ADDS_PER_TRIGGER do
        local x = victim:GetX() + math.cos(math.pi * i / PHASE_ADDS_PER_TRIGGER) * 8
        local y = victim:GetY() + math.sin(math.pi * i / PHASE_ADDS_PER_TRIGGER) * 8
        victim:SpawnCreature(PHASE_ADD_ENTRY, x, y, victim:GetZ(), victim:GetO(), 4, 60000)
    end

    -- Лор-фразы фаз
    if phase == 1 then
        victim:SendUnitSay("Осколок трескается... пустота перетекает!", 0)
    elseif phase == 2 then
        victim:SendUnitSay("Я — УСМЕШКА. Я — то, что ОСТАЛОСЬ!", 0)
    elseif phase == 3 then
        victim:SendUnitSay("СМЕЙТЕСЬ! Умрите смеясь... ЭХО ЗАЖИВАЕТ!", 0)
    end
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_ADVISOR, 1, ShowAdvisorMenu)
RegisterCreatureGossipEvent(NPC_ADVISOR, 2, OnAdvisorSelect)
RegisterCreatureGossipEvent(NPC_RITUAL_FIRE, 1, ShowFireMenu)
RegisterCreatureGossipEvent(NPC_RITUAL_FIRE, 2, OnFireSelect)

RegisterPlayerEvent(7, OnCreatureKill)      -- PLAYER_EVENT_ON_CREATURE_KILL = 7
RegisterCreatureEvent(NPC_BOSS, 9, OnCreatureDamage) -- CREATURE_EVENT_ON_DAMAGE_TAKEN = 9

print("[EchoOfTheVoid] Campaign3.lua загружен (кампания 3, главы 1–4, рейд-босс 70510).")