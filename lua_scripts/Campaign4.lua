-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign4.lua
-- Назначение: кампания 4 «Второе Эхо» (главы 1–5) — новая арка.
-- Лор: развеянная в К3 Усмешка не исчезла — она дробится. Осколки-
-- «семена» открывают малые разломы по всему Нордсколу. Архонт
-- Нехал'тхар собирает осколки, чтобы собрать Усмешку заново.
-- Требование: завершена К3 (Печать Хранителя Эха, item 70002).
-- НПС: 70210 Аэрис, 70201 Фантомы, 70202 Легионеры, 70204 Осколок,
--       70520 Нехал'тхар. Награды: 70006 Сердце, 70007 Венец.
-- Баланс: награды за кампанию — из REG.balance (жетоны).
-- Зависимость: 00_CampaignRegistry.lua.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR  = REG.meta.colors.void
local CULT_COLOR  = REG.meta.colors.cult
local TOKEN_ITEM  = REG.meta.token_item
local BAL = REG.balance

local CAMPAIGN = REG.campaigns[4]
local CAMPAIGN_ID = 4
local DB_TABLE = REG.meta.db_table

-- Требование: Печать Хранителя Эха (финал К3)
local CAMPAIGN3_TOKEN = REG.campaigns[3].rewards.title_token

local MIN_LEVEL = REG.meta.min_level

-- НПС (entry из реестра)
local NPC_SENTINEL = CAMPAIGN.npc.sentinel   -- Хранительница Аэрис (гл. 1)
local NPC_PHANTOM  = CAMPAIGN.npc.phantom    -- Осколочный Фантом (гл. 2)
local NPC_LEGION   = CAMPAIGN.npc.legionary  -- Иссушенный Легионер (гл. 3)
local NPC_SHARD    = CAMPAIGN.npc.shard      -- Осколок Эха (гл. 4)
local NPC_BOSS     = CAMPAIGN.npc.boss       -- Архонт Нехал'тхар (гл. 5)

-- Счётчики глав
local PHANTOMS_REQUIRED = 6    -- гл. 2
local LEGIONS_REQUIRED  = 4    -- гл. 3
local SHARDS_REQUIRED   = 3    -- гл. 4

-- Пункты gossip
local MENU_ROOT   = 1
local MENU_HEED   = 2   -- гл. 1: принять зов
local MENU_RIDE   = 3   -- гл. 1: полёт к пепелищу
local MENU_SHARD  = 4   -- гл. 4: извлечь осколок
local MENU_REPORT = 5   -- гл. 5: доклад перед боем

-- ============================================================
-- Прогресс
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

-- Награда жетонами за завершение кампании (баланс из реестра)
local function GrantCompletionTokens(player)
    local n = BAL.campaign_completion_tokens or 0
    if n > 0 then
        player:AddItem(TOKEN_ITEM, n)
        player:SendBroadcastMessage(TAG .. " +" .. n .. " " .. VOID_COLOR .. "Жетон Эха|r — награда за арку.")
    end
end

-- ============================================================
-- Награда финала
-- ============================================================

local function GrantFinalReward(player)
    SendMail(
        "Сердце Второго Эха",
        "Нехал'тхар пал, и осколки рассеялись. Но сердце, что он собрал, всё ещё бьётся. " ..
        "Орден запечатает его в Даларане. Если оно снова забьётся — ты первый, кто узнает. — Хранительница Аэрис",
        player:GetGUIDLow(), nil, nil, 60, CAMPAIGN.rewards.token
    )
    SendMail(
        "Венец Пустоты",
        "Стражи отдают тебе этот венец — знак тех, кто дважды остановил Пустоту. Носи его над разломом. — Сквернозор",
        player:GetGUIDLow(), nil, nil, 65, CAMPAIGN.rewards.cosmetic_token
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "КАМПАНИЯ «ВТОРОЕ ЭХО» ЗАВЕРШЕНА!|r")
    player:SendBroadcastMessage(TAG .. " Награды почтой: " .. VOID_COLOR .. "«Сердце Второго Эха»|r и " .. VOID_COLOR .. "«Венец Пустоты»|r.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " сокрушил Архонта Нехал'тхара! Второе Эхо затихло... пока что.")
end

-- ============================================================
-- Глава 1: Хранительница Аэрис (gossip 70210)
-- ============================================================

local function ShowSentinelMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Дважды Хранитель. Нордскол запомнит твой венец.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Пепел жжёт неопытных. Возвращайся на 80-м.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if player:HasItem(CAMPAIGN3_TOKEN) then
            player:GossipMenuAddItem(0, "«Аэрис, что за сполохи над Погостом?»", 0, MENU_HEED)
        else
            player:GossipMenuAddItem(0, "«Ты не Хранитель. Сначала останови Пробуждение.»", 0, MENU_ROOT)
        end
    elseif chapter == 1 then
        player:GossipMenuAddItem(0, "«Мы готовы. Веди к пепелищу.»", 0, MENU_RIDE)
    else
        player:GossipMenuAddItem(0, "«Разломы ждут. Не мешкай.»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnSentinelSelect(event, player, creature, sender, intid, code)
    if intid == MENU_HEED then
        local chapter, completed = LoadProgress(player)
        if chapter == 0 and not completed then
            if not player:HasItem(CAMPAIGN3_TOKEN) then
                player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Аэрис:|r «Стань Хранителем — тогда и поговорим.»")
                player:GossipComplete()
                return
            end
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Аэрис:|r «Усмешка развеяна — но не убита. Она дробится, как эхо в горах.»")
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Аэрис:|r «Осколки-семена падают в снег и открывают малые разломы. Кто-то собирает их.»")
            player:SendBroadcastMessage(TAG .. VOID_COLOR .. "Аэрис:|r «Стражи зовут его Архонт Нехал'тхар. Найди его пепелище.»")
            SaveProgress(player, 1, false, "")
            player:GossipComplete()
        end
        return
    end

    if intid == MENU_RIDE then
        local chapter, completed = LoadProgress(player)
        if chapter == 1 and not completed then
            -- Телепорт к пепелищу (юг Драконьего Погоста)
            player:Teleport(571, 3900.00, 7040.00, 150.00, 5.40)
            WriteCounter(player, 2, "phantoms", 0)
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Пепел не остыл»|r — выполнено.")
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Осколочные семена»|r — истреби " .. PHANTOMS_REQUIRED .. " Осколочных Фантомов.")
        end
        player:GossipComplete()
        return
    end

    player:GossipComplete()
end

-- ============================================================
-- Главы 2–3: kill-кредиты
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    if entry ~= NPC_PHANTOM and entry ~= NPC_LEGION and entry ~= NPC_BOSS then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == NPC_PHANTOM and chapter == 2 then
        local n = ReadCounter(killer, "phantoms") + 1
        if n >= PHANTOMS_REQUIRED then
            SaveProgress(killer, 3, false, "phantoms=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Осколочные семена»|r — выполнено. Фантомы развеяны.")
            killer:SendBroadcastMessage(TAG .. " Путь преграждают " .. VOID_COLOR .. "Иссушенные Легионеры|r — прорвись (" .. LEGIONS_REQUIRED .. ").")
        else
            WriteCounter(killer, 2, "phantoms", n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Фантом рассеялся (" .. n .. "/" .. PHANTOMS_REQUIRED .. ").")
        end
        return
    end

    if entry == NPC_LEGION and chapter == 3 then
        local n = ReadCounter(killer, "legions") + 1
        if n >= LEGIONS_REQUIRED then
            SaveProgress(killer, 4, false, "legions=" .. n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Легион без воли»|r — выполнено. Легионеры пали.")
            killer:SendBroadcastMessage(TAG .. " Осколки Эха уцелели. Извлеки " .. SHARDS_REQUIRED .. " из пепелища.")
        else
            WriteCounter(killer, 3, "legions", n)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Легионер повержен (" .. n .. "/" .. LEGIONS_REQUIRED .. ").")
        end
        return
    end

    -- Глава 5: финальный босс
    if entry == NPC_BOSS and chapter == 5 then
        SaveProgress(killer, 6, true, "campaign_done=1;boss=slain")
        GrantFinalReward(killer)
        GrantCompletionTokens(killer)
    end
end

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL

-- ============================================================
-- Глава 4: извлечение осколков (gossip 70204)
-- ============================================================

local function ShowShardMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if chapter == 4 then
        player:GossipMenuAddItem(0, "Извлечь осколок Эха.", 0, MENU_SHARD)
    else
        player:GossipMenuAddItem(0, "Осколок мелко дрожит, будто смеётся.", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnShardSelect(event, player, creature, sender, intid, code)
    local chapter, completed = LoadProgress(player)
    if chapter == 4 and not completed and intid == MENU_SHARD then
        local n = ReadCounter(player, "shards") + 1
        if n >= SHARDS_REQUIRED then
            SaveProgress(player, 5, false, "shards=" .. n)
            player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 4 «Сбор осколков»|r — выполнено.")
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. " Из пепла поднимается АРХОНТ НЕХАЛ'ТХАР!|r")
            player:SendBroadcastMessage(TAG .. " Останови сборку Усмешки. В фазах боя он зовёт Пустотников!")
        else
            WriteCounter(player, 4, "shards", n)
            player:SendBroadcastMessage(TAG .. " Осколок извлечён (" .. n .. "/" .. SHARDS_REQUIRED .. ").")
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Глава 5: финальный босс — 3 фазы, адды, лор-фразы
-- ============================================================

local BOSS_PHASE_HP = { 0.70, 0.40, 0.15 }
local PHASE_ADDS_PER_TRIGGER = 2

local function OnBossDamage(event, attacker, victim, amount)
    if not victim or victim:GetEntry() ~= NPC_BOSS then
        return
    end

    local maxHp = victim:GetMaxHealth()
    if maxHp <= 0 then
        return
    end
    local hpRatio = victim:GetHealth() / maxHp

    local phase = 0
    for i, threshold in ipairs(BOSS_PHASE_HP) do
        if hpRatio <= threshold then
            phase = i
        end
    end
    if phase == 0 then
        return
    end

    -- Защита от повторных триггеров (не чаще раза в 30 сек)
    local now = os.time()
    local lastTrigger = victim:GetData(0) or 0
    if now - lastTrigger < 30 then
        return
    end
    victim:SetData(0, now)

    for i = 1, PHASE_ADDS_PER_TRIGGER do
        local x = victim:GetX() + math.cos(math.pi * i / PHASE_ADDS_PER_TRIGGER) * 8
        local y = victim:GetY() + math.sin(math.pi * i / PHASE_ADDS_PER_TRIGGER) * 8
        victim:SpawnCreature(CAMPAIGN.npc.void_spawn, x, y, victim:GetZ(), victim:GetO(), 4, 60000)
    end

    if phase == 1 then
        victim:SendUnitSay("Осколок к осколку... эхо к эху... ОНА СОБИРАЕТСЯ!", 0)
    elseif phase == 2 then
        victim:SendUnitSay("Ты не понял, Хранитель? Усмешку нельзя убить. Её можно только ЗАКОНЧИТЬ!", 0)
    elseif phase == 3 then
        victim:SendUnitSay("Я слышу её... она смеётся... СМЕЙСЯ СО МНОЙ!", 0)
    end
end

RegisterCreatureEvent(NPC_BOSS, 9, OnBossDamage) -- ON_DAMAGE_TAKEN

-- ============================================================
-- Регистрация gossip
-- ============================================================

RegisterCreatureGossipEvent(NPC_SENTINEL, 1, ShowSentinelMenu)
RegisterCreatureGossipEvent(NPC_SENTINEL, 2, OnSentinelSelect)
RegisterCreatureGossipEvent(NPC_SHARD, 1, ShowShardMenu)
RegisterCreatureGossipEvent(NPC_SHARD, 2, OnShardSelect)

print("[EchoOfTheVoid] Campaign4.lua загружен (кампания 4 «Второе Эхо», главы 1–5, босс 70520).")
