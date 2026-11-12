-- ============================================================
-- 36_BandQuest.lua — Скриптовая квест-цепочка «Песнь Пустоты»
--
-- Ввод к живому выступлению (35_BandPerformance.lua, НПС 70390–70394).
-- Цепочка для ВСЕХ фракций (НПС 70395 стоит и у Орды, и у Альянса):
--   1. «Затишье» — Капельмейстер просит найти 3 Струны Пустоты;
--   2. «Настройка» — игрок собирает их (sсам/бой в зонах Эха);
--   3. «Премьера» — сдаёт, получает Жетон Песни + Жетоны Эха, труппа играет.
--
-- Скриптовый подход (как кампании), БЕЗ quest_template.
-- Состояние этапа — в таблице realm_band_quest (acore_characters).
-- Требует: миграцию 0037 (НПС 70395 + предметы 70115–70118).
-- ============================================================

local CFG = {
    MAESTRO       = 70395,               -- «Капельмейстер Пустоты»
    STRINGS       = { 70115, 70116, 70117 },  -- «Струны Пустоты»
    TOKEN_SONG    = 70118,               -- «Жетон Песни Пустоты»
    TOKEN_ECHO    = 70005,               -- Жетон Эха (награда)
    ECHO_REWARD   = 5,                   -- сколько жетонов Эха за завершение
    -- Зоны кампании Эха, где дропаются Струны (зона Эха — Драконий Погост)
    ECHO_ZONES    = { [4080] = true },
    TB            = "realm_band_quest",  -- состояние этапа
}

local TAG = AzerothEchoCampaigns and AzerothEchoCampaigns.meta
    and AzerothEchoCampaigns.meta.tag or "|cff9b59b6[Эхо Пустоты]|r"

-- ---- Локализация ----
local L = {
    hello      = { "Труппа молчит с тех пор, как Бездна коснулась наших песен. Собери три Струны Пустоты — и мы заиграем вновь.", "The band fell silent since the Void touched our songs. Gather three Strings of the Void, and we will play again." },
    have       = { "У тебя есть Струны? Принеси их — и дождёмся Премьеры.", "Do you have the Strings? Bring them — and let the Premiere begin." },
    notAll     = { "Струн не хватает (нужно 3). Убивай порождений Бездны и собирай их.", "Strings are missing (need 3). Slay Void-spawned and gather them." },
    done       = { "Труппа снова играет! Прими Жетон Песни в знак благодарности.", "The band plays again! Take the Song-Token in thanks." },
    already    = { "Ты уже внёс вклад в наше возрождение, {name}. Вернись к Премьере.", "You already helped our rebirth, {name}. Come back for the Premiere." },
    reward     = { "Ты получил(а) Жетон Песни Пустоты и {n} Жетонов Эха.", "You received the Song-Token of the Void and {n} Echo Tokens." },
    menuTask   = { "Посмотреть задание", "View the task" },
    menuTurn   = { "Сдать Струны (3)", "Turn in Strings (3)" },
    menuGo     = { "Пойти на Премьеру", "Go to the Premiere" },
    go         = { "Телепортирую тебя к сцене в Дюротаре.", "Teleporting you to the stage in Durotar." },
}

local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end
local function line(t, player)
    return t[IsRu(player) and 1 or 2]
end

-- ---- Состояние этапа на аккаунт (save в characters) ----
local function GetStage(player)
    local accid = player:GetAccountId()
    local ok, q = pcall(CharDBQuery, string.format(
        "SELECT stage FROM %s WHERE account_id = %d", CFG.TB, accid))
    if ok and q then return q:GetUInt32(0) or 0 end
    return 0
end
local function SetStage(player, stage)
    local accid = player:GetAccountId()
    pcall(CharDBExecute, string.format(
        "REPLACE INTO %s (account_id, stage, updated_at) VALUES (%d, %d, %d)",
        CFG.TB, accid, stage, os.time()))
end

-- Сколько Струн у игрока в сумке
local function CountStrings(player)
    local n = 0
    for _, entry in ipairs(CFG.STRINGS) do
        n = n + (player:GetItemCount(entry) or 0)
    end
    return n
end

-- ============================================================
-- Gossip: Капельмейстер
-- ============================================================
local function OnHello(event, player, creature)
    if creature:GetEntry() ~= CFG.MAESTRO then return end
    local t = line(L, player)
    local stage = GetStage(player)

    player:GossipClearMenu()
    if stage >= 3 then
        player:GossipMenuAddItem(0, t.already:gsub("{name}", player:GetName()), 0, 3)
    else
        player:GossipSetText(t.hello)
        player:GossipMenuAddItem(0, t.menuTask, 0, 1)
        player:GossipMenuAddItem(0, t.menuTurn, 0, 2)
    end
    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    if creature:GetEntry() ~= CFG.MAESTRO then return end
    local t = line(L, player)
    local stage = GetStage(player)

    -- Пойти на Премьеру (телепорт к сцене, если завершено)
    if intid == 3 then
        player:TeleportTo(1, 1274.9, -4337.3, 33.1, 0)
        player:SendBroadcastMessage(TAG .. " " .. t.go)
        player:GossipComplete()
        return
    end

    if intid == 1 then
        player:GossipSendMenu(1, creature)
        return
    end

    -- Сдача (этап 3: настройка завершена)
    if intid == 2 then
        local n = CountStrings(player)
        if n < 3 then
            player:SendBroadcastMessage(TAG .. " " .. t.notAll)
        else
            -- списать по одной Струне (по одной копии — разные entry)
            for _, entry in ipairs(CFG.STRINGS) do
                player:RemoveItem(entry, 1)
            end
            -- награда
            player:AddItem(CFG.TOKEN_SONG, 1)
            player:AddItem(CFG.TOKEN_ECHO, CFG.ECHO_REWARD)
            SetStage(player, 3)
            player:SendBroadcastMessage(TAG .. " " .. t.done)
            player:SendBroadcastMessage(TAG .. " " .. t.reward:gsub("{n}", tostring(CFG.ECHO_REWARD)))
            -- триггер выступления (35_BandPerformance экспортирует _BAND_PLAY)
            if rawget(_G, "_BAND_PLAY") then _BAND_PLAY(player:GetMapId()) end
        end
    end
    OnHello(event, player, creature)
end

RegisterCreatureGossipEvent(CFG.MAESTRO, 1, OnHello)
RegisterCreatureGossipEvent(CFG.MAESTRO, 2, OnSelect)

-- ============================================================
-- Этап «Затишье»: убийство порождений Бездны даёт Струны (дроп)
-- Простейший способ — давать Струну по киллу (для этапа < 3).
-- ============================================================
local function OnKill(event, player, creature)
    if not player then return end
    local stage = GetStage(player)
    if stage >= 3 then return end
    -- Струны дропаются только в зонах Эха (порождения Бездны там)
    local zone = player:GetZoneId()
    if not CFG.ECHO_ZONES[zone] then return end
    -- дроп Струны с шансом в эхо-зоне
    if math.random(100) <= 25 then
        local entry = CFG.STRINGS[math.random(#CFG.STRINGS)]
        player:AddItem(entry, 1)
        player:SendBroadcastMessage(TAG .. " Ты подобрал(а) Струну Пустоты. Принеси её Капельмейстеру.")
    end
end
RegisterPlayerEvent(7, OnKill) -- ON_KILL_CREATURE

print("[EchoOfTheVoid] 36_BandQuest.lua загружен (цепочка «Песнь Пустоты»; НПС 70395, миграция 0037).")