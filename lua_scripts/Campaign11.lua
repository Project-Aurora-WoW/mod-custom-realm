-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign11.lua
-- Назначение: кампания 11 «Узы фракций» (главы 1–3) — фракционная.
-- Требование: завершена кампания 10 (item 70016 «Свет Истины»).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 11).
-- Фракционные ветки (выбор в главе 1):
--   Альянс — старт у Герольда Альянса (70286), цель — Пустотные Стражи,
--             финал — Паладин-Отступник (70543)
--   Орда   — старт у Герольда Орды (70287), цель — Проклятые Стражи,
--             финал — Владыка Волков-Пустотников (70544)
-- Награда: item 70018 «Знамёна Верности» (за любую фракционную линию).
-- Механика: прогресс по ветке хранится в progress_data ("faction=...").
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void
local CULT_COLOR = REG.meta.colors.cult

local CAMPAIGN = REG.campaigns[11]
local CAMPAIGN_ID = 11
local DB_TABLE = REG.meta.db_table
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Знамёна Верности»
local REWARD_MAIL_DELAY = 60

-- Требование: «Свет Истины» (финал К10)
local CAMPAIGN10_TOKEN = REG.campaigns[10].rewards.token

-- Фракционные ветки (из реестра faction + НПС кампании)
local NPC_HERALD_A = CAMPAIGN.npc.herald_alliance -- 70286
local NPC_HERALD_H = CAMPAIGN.npc.herald_horde    -- 70287
local NPC_BOSS_A   = CAMPAIGN.npc.boss_alliance   -- 70543
local NPC_BOSS_H   = CAMPAIGN.npc.boss_horde      -- 70544

-- Цели фракционных веток главы 2 (из реестра faction.branches.combat)
local FACTION_A = REG.faction.branches.alliance
local FACTION_H = REG.faction.branches.horde
local COMBAT_A = FACTION_A.combat.entry  -- 70284 Пустотный Страж
local COMBAT_H = FACTION_H.combat.entry  -- 70285 Проклятый Страж

local MENU_ROOT = 1
local MENU_PICK_A = 2   -- выбрать ветку Альянса
local MENU_PICK_H = 3   -- выбрать ветку Орды

local MIN_LEVEL = REG.meta.min_level
local COMBAT_REQUIRED = 6   -- глава 2: фракционных целей

local function HasCampaign10Token(player)
    return player:HasItem(CAMPAIGN10_TOKEN)
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

-- Фракция, выбранная игроком (alliance|horde); по умолчанию — по его расе
local function ReadFaction(player)
    local q = CharDBQuery(string.format(
        "SELECT progress_data FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        local f = string.match(q:GetString(0) or "", "faction=(%a+)")
        if f then return f end
    end
    -- Fallback: по расе (1-4,7,10 = Альянс; 2,5,6,8,9 = Орда)
    local race = player:GetRace()
    local allianceRaces = { [1] = true, [3] = true, [4] = true, [7] = true, [10] = true, [11] = true }
    return (allianceRaces[race] and "alliance") or "horde"
end

local function WriteCounter(player, chapter, key, value, faction)
    SaveProgress(player, chapter, false, key .. "=" .. value .. (faction and (";faction=" .. faction) or ""))
end

-- ============================================================
-- Награда
-- ============================================================

local function GrantReward(player)
    SendMail(
        "Знамёна Верности",
        "Ты прошёл линию своей фракции до конца. Этот знак — подтверждение " ..
        "твоей верности, когда мир готов был расколоться. — Орден Рассвета",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Узы фракций» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Знамёна Верности»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " скрепил Узы фракции и доказал свою верность!")
end

-- ============================================================
-- Старт: Герольд Альянса/Орды (gossip 70286/70287)
-- ============================================================

local function factionOfHerald(entry)
    if entry == NPC_HERALD_A then return "alliance" end
    if entry == NPC_HERALD_H then return "horde" end
    return nil
end

local function HeraldBranch(faction)
    return faction == "horde" and FACTION_H or FACTION_A
end

local function ShowHeraldMenu(event, player, creature)
    local entry = creature and creature:GetEntry()
    local heraldFaction = factionOfHerald(entry)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    local branch = HeraldBranch(heraldFaction)

    if completed then
        player:GossipMenuAddItem(0, "«Узы фракции скреплены. Твоё имя вписано в летопись.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Узы фракций требуют силы. Вернись на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        if HasCampaign10Token(player) then
            player:GossipMenuAddItem(0, "«" .. branch.label .. " — я встану под твои знамёна.»", 0,
                heraldFaction == "horde" and MENU_PICK_H or MENU_PICK_A)
        else
            player:GossipMenuAddItem(0, "«Принеси Свет Истины. Только принявший истину слышит зов своей фракции.»", 0, MENU_ROOT)
        end
    elseif chapter >= 1 then
        player:GossipMenuAddItem(0, "«Состояние уз фракции?»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnHeraldSelect(event, player, creature, sender, intid, code)
    local entry = creature and creature:GetEntry()
    local heraldFaction = factionOfHerald(entry)
    local wantFaction = nil
    if intid == MENU_PICK_A then wantFaction = "alliance" end
    if intid == MENU_PICK_H then wantFaction = "horde" end

    if wantFaction then
        if not HasCampaign10Token(player) then
            player:SendBroadcastMessage(TAG .. CULT_COLOR .. "Герольд:|r «Сначала Свет Истины. Ты ещё не готов.»")
            player:GossipComplete()
            return
        end
        -- Записываем выбранную ветку и стартуем главу 2
        local branch = HeraldBranch(wantFaction)
        WriteCounter(player, 2, "combat", 0, wantFaction)
        player:Teleport(571, branch.rally.x, branch.rally.y, branch.rally.z, branch.rally.o)
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 1 «Выбор Zнамён»|r — ветка «" .. (wantFaction == "horde" and "Орда" or "Альянс") .. "» принята.")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Герольд:|r " .. branch.rpl)
        player:SendBroadcastMessage(TAG .. " Прорвись через " .. COMBAT_REQUIRED .. " " .. branch.combat.name)
        player:GossipComplete()
        return
    end
    player:GossipComplete()
end

-- ============================================================
-- Главы 2, 3: kill-кредиты (фракционные цели и босс)
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    local entry = killed:GetEntry()
    local faction = ReadFaction(killer)
    local combatEntry = faction == "horde" and COMBAT_H or COMBAT_A
    local bossEntry = faction == "horde" and NPC_BOSS_H or NPC_BOSS_A

    if entry ~= combatEntry and entry ~= bossEntry then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed then
        return
    end

    if entry == combatEntry and chapter == 2 then
        local n = ReadCounter(killer, "combat") + 1
        if n >= COMBAT_REQUIRED then
            SaveProgress(killer, 3, false, "combat=" .. n .. ";faction=" .. faction)
            killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Прорыв»|r — выполнено. Путь открыт.")
            killer:SendBroadcastMessage(TAG .. " Развяжи узел фракции: убей " .. CULT_COLOR .. (faction == "horde" and "Владыку Волков-Пустотников|r" or "Паладина-Отступника|r") .. ".")
        else
            WriteCounter(killer, 2, "combat", n, faction)
            killer:SendBroadcastMessage(TAG .. " Фракционная цель повержена (" .. n .. "/" .. COMBAT_REQUIRED .. ").")
        end
        return
    end

    if entry == bossEntry and chapter == 3 then
        SaveProgress(killer, 4, true, "campaign_done=1;boss=slain;faction=" .. faction)
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 3 «Узел фракции»|r — выполнено. Узы скреплены.")
        GrantReward(killer)
    end
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_HERALD_A, 1, ShowHeraldMenu)
RegisterCreatureGossipEvent(NPC_HERALD_A, 2, OnHeraldSelect)
RegisterCreatureGossipEvent(NPC_HERALD_H, 1, ShowHeraldMenu)
RegisterCreatureGossipEvent(NPC_HERALD_H, 2, OnHeraldSelect)

RegisterPlayerEvent(7, OnCreatureKill) -- PLAYER_EVENT_ON_CREATURE_KILL = 7

print("[EchoOfTheVoid] Campaign11.lua загружен (кампания 11 «Узы фракций», ветки А/О).")