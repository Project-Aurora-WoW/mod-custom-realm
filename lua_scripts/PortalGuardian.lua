-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- PortalGuardian.lua
-- Назначение: gossip-диалог и телепорты НПС «Портальный Страж»
-- (entry 70001, спавны в Штормграде и Оргриммаре).
-- Диалог основан на лоре вселенной (docs/lore/universe.md):
-- таймлайн, фракции, правила Пустоты, ключевые локации.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local GUARDIAN_ENTRY = 70001

local TAG = "|cff9b59b6[Эхо Пустоты]|r"
local VOID_COLOR = "|cff8e44ad"    -- цвет Пустоты
local ORDER_COLOR = "|cff5dade2"   -- цвет Ордена Рассвета
local CULT_COLOR = "|cffc0392b"    -- цвет Культа Усмешки Бездны

-- ID пунктов gossip-меню
local MENU_ROOT = 1
local MENU_LORE = 2
local MENU_FACTIONS = 3
local MENU_RULES = 4
local MENU_DANGER = 5

-- Точки телепорта (map, x, y, z, o) для клиента 3.3.5a.
-- Карта 5000 — кастомные зоны (patch-Z.MPQ, референс RStijn/custom-maps);
-- телепорт работает только при установленном клиентском патче
-- (см. docs/client-patch.md, Часть 6 «Кастомные карты»).
local TELEPORTS = {
    { name = "Даларан — штаб Ордена Рассвета",   map = 571, x = 5808.63,  y = 587.94,   z = 657.67, o = 2.17 },
    { name = "Драконий Погост — эпицентр аномалии", map = 571, x = 3864.53, y = 6985.11, z = 146.11, o = 4.68 },
    { name = "Штормград",                        map = 0,   x = -8960.14, y = 1335.64,  z = 96.10,  o = 5.21 },
    { name = "Оргриммар",                        map = 1,   x = 1591.31,  y = -4434.98, z = 39.42,  o = 3.32 },
    { name = "Остров Морза — флотский перевал",  map = 5000, x = -13950,  y = 2877,     z = 9,      o = 0 },
    { name = "Долина Предательства",             map = 5000, x = 10461,   y = -9574,    z = 22,     o = 0 },
}

-- Текст лор-рассказа (концепция + таймлайн вселенной)
local LORE_TEXT = {
    "Ты слышал шёпот, не так ли? Тот самый, что будит магов среди ночи...",
    "Когда Король-лич пал, от его трона откололся осколок. Он упал в " .. VOID_COLOR .. "Драконий Погост|r.",
    "Пустота пропитала осколок. Теперь он шепчет — и зовёт своих.",
    VOID_COLOR .. " Культ Усмешки Бездны|r собирает одержимых, чтобы разбудить то, что спит внутри.",
    ORDER_COLOR .. " Орден Рассвета|r должен сорвать ритуал. Ищем таких, как ты.",
}

-- Текст о фракциях (раздел 3 лора)
local FACTIONS_TEXT = {
    ORDER_COLOR .. "Орден Рассвета|r — коалиция Альянса и Орды. Штаб в Даларане. Мы — агенты Ордена.",
    VOID_COLOR .. "Культ Усмешки Бездны|r — их пророк, " .. VOID_COLOR .. "Нал'кур|r, зовёт Пустоту «очищением». База — Драконий Погост и Зул'Драк.",
    VOID_COLOR .. "Стражи Пустоты|r — драконы всех полётов. Нейтральны... пока не докажешь свою верность.",
}

-- Правила вселенной (раздел 5 лора)
local RULES_TEXT = {
    "Правило первое: Пустота не убивает. Она " .. VOID_COLOR .. "иссушает|r — жертвы становятся «Иссушенными», пустыми телами, помнящими свои жизни.",
    "Правило второе: рядом с разломом шёпот громче. Игроки слышат " .. VOID_COLOR .. "Эхо Шёпота|r — замедление и галлюцинации.",
    "Правило третье: Старые Боги спят. Усмешка Бездны — лишь осколок сознания. Разбудить его может только ритуал Культа.",
    "Правило четвёртое: вблизи разлома магия слабеет и работает иначе. Не полагайся на привычные заклинания.",
}

-- Предупреждение о локациях (раздел 4 лора)
local DANGER_TEXT = {
    CULT_COLOR .. "Драконий Погост|r — эпицентр аномалии. Там осколок Трона и разломы Пустоты. Не ходи туда без подготовки.",
    CULT_COLOR .. "Зул'Драк|r — древний город троллей, захваченный Культом. Там проходят ритуалы.",
    CULT_COLOR .. "Бесплодные земли|r — тайный перевалочный пункт Культа. Караваны одержимых идут ночами.",
    CULT_COLOR .. "Остров Морза|r — флотский перевал Культа у неведомых берегов. Оттуда отплывают корабли с одержимыми.",
    CULT_COLOR .. "Долина Предательства|r — глухая долина, где Культ пересчитывает свои легионы. Кто видел её — уже наполовину одержим.",
}

--- Отрисовка корневого меню.
local function ShowRootMenu(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "Расскажи мне об Эхе Пустоты.", 0, MENU_LORE)
    player:GossipMenuAddItem(0, "Кто наши союзники и враги?", 0, MENU_FACTIONS)
    player:GossipMenuAddItem(0, "Какие правила у Пустоты?", 0, MENU_RULES)
    player:GossipMenuAddItem(0, "Какие места опасны?", 0, MENU_DANGER)
    for i, tp in ipairs(TELEPORTS) do
        player:GossipMenuAddItem(0, "Телепорт: " .. tp.name, 0, 100 + i)
    end
    player:GossipSendMenu(1, creature)
end

--- Отрисовка страниц лор-рассказа (возвращает в корень).
local function ShowTextPage(event, player, creature, lines)
    player:GossipClearMenu()
    for _, line in ipairs(lines) do
        player:GossipMenuAddItem(0, line, 0, MENU_ROOT)
    end
    player:GossipSendMenu(1, creature)
end

--- Обработчик выбора пункта меню.
local function OnGossipSelect(event, player, creature, sender, intid, code)
    -- Телепорты: intid 101..100+N
    if intid >= 101 and intid <= 100 + #TELEPORTS then
        local tp = TELEPORTS[intid - 100]
        player:SendBroadcastMessage(TAG .. " Портал открыт. Пусть Эхо не услышит твоего имени.")
        player:Teleport(tp.map, tp.x, tp.y, tp.z, tp.o)
        player:GossipComplete()
        return
    end

    if intid == MENU_LORE then
        ShowTextPage(event, player, creature, LORE_TEXT)
        return
    end

    if intid == MENU_FACTIONS then
        ShowTextPage(event, player, creature, FACTIONS_TEXT)
        return
    end

    if intid == MENU_RULES then
        ShowTextPage(event, player, creature, RULES_TEXT)
        return
    end

    if intid == MENU_DANGER then
        ShowTextPage(event, player, creature, DANGER_TEXT)
        return
    end

    -- Любой другой пункт возвращает в корень меню
    ShowRootMenu(event, player, creature)
end

--- Обработчик открытия диалога с НПС.
local function OnGossipHello(event, player, creature)
    if creature:GetEntry() ~= GUARDIAN_ENTRY then
        return
    end
    -- Расовая реплика Стража (из центрального реестра)
    local raceLine = AzerothEchoCampaigns.race_greetings[player:GetRace()] or ""
    if raceLine ~= "" then
        player:SendBroadcastMessage(TAG .. " «" .. raceLine .. "»")
    end
    -- Лор-фраза при обращении к Стражу
    player:SendBroadcastMessage(TAG .. " «Ах, ещё один, кто слышит шёпот... Подойди, агент Ордена.»")
    ShowRootMenu(event, player, creature)
end

RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 1, OnGossipHello)    -- GOSSIP_EVENT_ON_HELLO = 1
RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 2, OnGossipSelect)   -- GOSSIP_EVENT_ON_SELECT = 2

print("[EchoOfTheVoid] PortalGuardian.lua загружен (НПС " .. GUARDIAN_ENTRY .. ").")