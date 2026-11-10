-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- Campaign1.lua
-- Назначение: кампания 1 «Эхо Шёпота» (главы 1–3).
-- Прогресс хранится в realm_campaign_progress (campaign_id = 1).
-- НПС: 70100 Ахерон-Пустотник, 70110 Пленный маг Талвин,
--       70120 Архимаг Элианна (квестодатель, Даларан).
-- Награда: item 70001 «Слеза Рассвета».
-- Лор: docs/lore/universe.md, docs/campaigns/README.md.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

-- Константы — из центрального реестра кампаний (00_CampaignRegistry.lua)
local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR = REG.meta.colors.void

local CAMPAIGN = REG.campaigns[1]
local CAMPAIGN_ID = 1
local DB_TABLE = REG.meta.db_table
local KILLS_REQUIRED = 5          -- глава 2: сколько Пустотников нужно убить
local WHISPER_AURA = REG.meta.whisper_aura -- дебафф «Эхо Шёпота» рядом с разломом
local REWARD_ITEM = CAMPAIGN.rewards.token -- «Слеза Рассвета»
local REWARD_MAIL_DELAY = 60      -- сек. задержка письма с наградой

-- НПС кампании (entry из реестра)
local NPC_VOID_SPAWN = CAMPAIGN.npc.void_spawn      -- Ахерон-Пустотник (kill-кредит главы 2)
local NPC_CAPTURED_MAGE = CAMPAIGN.npc.captured_mage -- Пленный маг Талвин (глава 3)
local NPC_ARCHMAGE = CAMPAIGN.npc.archmage          -- Архимаг Элианна (глава 1)

-- ID пунктов gossip-меню
local MENU_ROOT = 1
local MENU_BRIEFING = 2           -- глава 1: принять брифинг
local MENU_TELEPORT = 3           -- глава 1: телепорт к разлому
local MENU_RESCUE = 4             -- глава 3: освободить Талвина

-- Минимальный уровень для кампаний (гейт уровня)
local MIN_LEVEL = REG.meta.min_level

-- Получить классовую реплику игрока (из реестра)
local function GetClassLine(player)
    return REG.class_greetings[player:GetClass()] or ""
end

-- Получить расовую реплику игрока (из реестра)
local function GetRaceLine(player)
    return REG.race_greetings[player:GetRace()] or ""
end

-- ============================================================
-- Работа с прогрессом (realm_campaign_progress)
-- ============================================================

-- Загрузить прогресс игрока. Возвращает chapter, completed.
local function LoadProgress(player)
    local q = CharDBQuery(string.format(
        "SELECT chapter, completed FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        return q:GetUInt8(0), q:GetUInt8(1) == 1
    end
    return 0, false -- не начинал кампанию
end

-- Сохранить прогресс игрока.
local function SaveProgress(player, chapter, completed, data)
    CharDBQuery(string.format(
        "REPLACE INTO %s (guid, campaign_id, chapter, completed, progress_data) VALUES (%d, %d, %d, %d, '%s')",
        DB_TABLE, player:GetGUIDLow(), CAMPAIGN_ID, chapter, completed and 1 or 0, data or ""
    ))
end

-- ============================================================
-- Глава 3: выдача награды
-- ============================================================

local function GrantReward(player)
    -- Награда отправляется письмом (токен доступа к кампании 2)
    SendMail(
        "Слеза Рассвета",
        "Ты сорвал первый ритуал Культа и спас Талвина. Орден Рассвета возвращает тебе эту реликвию. " ..
        "Следующий шёпот донесётся из Зул'Драка — а там нам понадобится твоя Слеза. — Архимаг Элианна",
        player:GetGUIDLow(), nil, nil, REWARD_MAIL_DELAY, REWARD_ITEM
    )
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «Эхо Шёпота» завершена!|r")
    player:SendBroadcastMessage(TAG .. " Награда — " .. ORDER_COLOR .. "«Слеза Рассвета»|r — придёт почтой.")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " завершил кампанию «Эхо Шёпота»! Шёпот в Драконьем Погосте стал тише.")
end

-- ============================================================
-- Глава 1: брифинг Архимага Элианны (gossip НПС 70120)
-- ============================================================

local function ShowArchmageMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Эхо умолкло... но это лишь начало. Впереди новые арки.»", 0, MENU_ROOT)
    elseif player:GetLevel() < MIN_LEVEL then
        player:GossipMenuAddItem(0, "«Орден не берёт в разлом неопытных. Возвращайся на 80-м уровне.»", 0, MENU_ROOT)
    elseif chapter == 0 then
        player:GossipMenuAddItem(0, "«Архимаг, я прибыл по зову Ордена. Что случилось?»", 0, MENU_BRIEFING)
    elseif chapter == 1 then
        player:GossipMenuAddItem(0, "«Я готов. Отправь меня к разлому.»", 0, MENU_TELEPORT)
    else
        player:GossipMenuAddItem(0, "«Пустотники пали. Талвин ждёт у осколка.»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnArchmageSelect(event, player, creature, sender, intid, code)
    if intid == MENU_BRIEFING then
        -- Гейт уровня (защита и при выборе пункта)
        if player:GetLevel() < MIN_LEVEL then
            player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «Разлом не для неопытных. Расти, герой.»")
            player:GossipComplete()
            return
        end
        -- Лор-брифинг главы 1 «Зов Даларана» + персональные реплики
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «" .. GetRaceLine(player) .. "»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «" .. GetClassLine(player) .. "»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «Маги пропадают один за другим. Осколок Трона упал в Драконий Погост.»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «Из него доносится шёпот. Культ Усмешки Бездны пытается разбудить то, что спит внутри.»")
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Элианна:|r «Разведай разлом. Пустотники вышли наружу — " .. KILLS_REQUIRED .. " из них стоят между нами и правдой.»")
        -- Начало кампании: chapter 0 -> 1
        SaveProgress(player, 1, false, "")
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 1 «Зов Даларана»|r — выполнено. Готовься к телепорту.")
        player:GossipComplete()
        return
    end

    if intid == MENU_TELEPORT then
        -- Телепорт к разлому в Драконьем Погосте (глава 1 -> 2)
        player:Teleport(571, 3864.53, 6985.11, 146.11, 4.68)
        SaveProgress(player, 2, false, "")
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Глава 2 «Первый разлом»|r — убей " .. KILLS_REQUIRED .. " Ахерон-Пустотников. Осторожно: рядом с разломом магия слабеет.")
        player:GossipComplete()
        return
    end

    player:GossipComplete()
end

-- ============================================================
-- Глава 2: kill-кредит Пустотников
-- ============================================================

local function OnCreatureKill(event, killer, killed)
    if killed:GetEntry() ~= NPC_VOID_SPAWN then
        return
    end

    local chapter, completed = LoadProgress(killer)
    if completed or chapter ~= 2 then
        return
    end

    -- Подсчёт убийств в progress_data ("kills=N")
    local kills = 0
    local q = CharDBQuery(string.format(
        "SELECT progress_data FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, killer:GetGUIDLow(), CAMPAIGN_ID
    ))
    if q then
        local data = q:GetString(0) or ""
        kills = tonumber(string.match(data, "kills=(%d+)")) or 0
    end
    kills = kills + 1

    if kills >= KILLS_REQUIRED then
        SaveProgress(killer, 3, false, "kills=" .. kills)
        killer:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Глава 2 «Первый разлом»|r — выполнено. Пустотники пали.")
        killer:SendBroadcastMessage(TAG .. " Найди " .. ORDER_COLOR .. "Пленного мага Талвина|r у осколка Трона и освободи его.")
    else
        SaveProgress(killer, 2, false, "kills=" .. kills)
        killer:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Пустотник повержен (" .. kills .. "/" .. KILLS_REQUIRED .. ").")
    end
end

-- Дебафф «Эхо Шёпота» обрабатывается скриптовой системой
-- 05_VoidAuras.lua (стаки, шёпот, коллапс рассудка, ru/en).
-- Здесь остаётся только снятие стоковой ауры при выходе из зоны,
-- чтобы не конфликтовать с новым модулем.
local function OnPlayerUpdateZone(event, player, newZone, newArea)
    local chapter, completed = LoadProgress(player)
    if completed or chapter < 2 then
        return
    end
    -- Драконий Погост: zone из реестра
    if newZone == AzerothEchoCampaigns.meta.dragonblight_zone then
        player:SendBroadcastMessage(TAG .. " " .. VOID_COLOR .. "Эхо Шёпота|r проникает в разум...")
    else
        if player:HasAura(WHISPER_AURA) then
            player:RemoveAura(WHISPER_AURA)
        end
    end
end

-- ============================================================
-- Gossip НПС 70110 (Пленный маг Талвин) — глава 3
-- ============================================================

local function ShowCapturedMageMenu(event, player, creature)
    local chapter, completed = LoadProgress(player)
    player:GossipClearMenu()

    if completed then
        player:GossipMenuAddItem(0, "«Ты в безопасности, Талвин. Возвращайся в Даларан.»", 0, MENU_ROOT)
    elseif chapter == 2 then
        player:GossipMenuAddItem(0, VOID_COLOR .. "«Я слышу шёпот... они держат меня здесь третий день.»", 0, MENU_RESCUE)
    else
        player:GossipMenuAddItem(0, "«Прочь! Культ не выпустит меня живым...»", 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

local function OnCapturedMageSelect(event, player, creature, sender, intid, code)
    if intid == MENU_RESCUE then
        local chapter, completed = LoadProgress(player)
        if chapter == 2 and not completed then
            SaveProgress(player, 3, true, "campaign_done=1")
            player:SendBroadcastMessage(TAG .. ORDER_COLOR .. "Талвин:|r «Свобода... Я видел, что внутри осколка. Там — Усмешка. Она смотрит на нас.»")
            GrantReward(player)
        end
    end
    player:GossipComplete()
end

-- ============================================================
-- Регистрация событий ALE
-- ============================================================

RegisterCreatureGossipEvent(NPC_ARCHMAGE, 1, ShowArchmageMenu)
RegisterCreatureGossipEvent(NPC_ARCHMAGE, 2, OnArchmageSelect)
RegisterCreatureGossipEvent(NPC_CAPTURED_MAGE, 1, ShowCapturedMageMenu)
RegisterCreatureGossipEvent(NPC_CAPTURED_MAGE, 2, OnCapturedMageSelect)

RegisterPlayerEvent(7, OnCreatureKill)        -- PLAYER_EVENT_ON_CREATURE_KILL = 7
RegisterPlayerEvent(42, OnPlayerUpdateZone)   -- PLAYER_EVENT_ON_UPDATE_ZONE = 42

print("[EchoOfTheVoid] Campaign1.lua загружен (НПС 70100/70110/70120).")