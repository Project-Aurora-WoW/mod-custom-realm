-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- PortalGuardian.lua
-- Назначение: gossip-диалог и телепорты НПС «Портальный Страж»
-- (entry 70001, спавны в Штормграде и Оргриммаре).
--
-- ЛОР НЕ ХРАНИТСЯ ЗДЕСЬ. Все тексты берутся из 00_LoreRegistry.ext
-- (AzerothEchoLore) — единого источника правды. Секции фильтруются
-- по стадии истории игрока (AzerothEchoLore.Stage), поэтому Страж
-- говорит разное до и после каждой кампании.
--
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local GUARDIAN_ENTRY = 70001

-- Локализация системных сообщений (лор-тексты — из 00_LoreRegistry.ext)
local L = {
    ru = { portal = "Портал открыт. Пусть Эхо не услышит твоего имени." },
    en = { portal = "The portal opens. May the Echo never hear your name." },
}
local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end

local Lore = AzerothEchoLore
local TAG = Lore.meta.tag
local VOID_COLOR = Lore.meta.colors.void
local ORDER_COLOR = Lore.meta.colors.order

-- ID пунктов gossip-меню
local MENU_ROOT = 1
local MENU_SECTION_BASE = 10   -- ниже: 10..10+N — секции лора
local MENU_BACK = 2

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
    { name = "Зул'Драк — осада Культа",          map = 571, x = 4778.00,  y = -2020.00, z = 229.00, o = 0.00 },
}

--- Список секций, доступных игроку на текущей стадии.
local function AvailableSections(player)
    return Lore.VisibleSections(Lore.Stage(player))
end

--- Отрисовка корневого меню: лор по секциям + телепорты.
local function ShowRootMenu(event, player, creature)
    player:GossipClearMenu()

    player:GossipMenuAddItem(0,
        ORDER_COLOR .. "Что мне нужно знать?|r (лор)", 0, MENU_ROOT)

    local sections = AvailableSections(player)
    for i, section in ipairs(sections) do
        player:GossipMenuAddItem(0, "  " .. section.title, 0, MENU_SECTION_BASE + i)
    end

    for i, tp in ipairs(TELEPORTS) do
        player:GossipMenuAddItem(0, VOID_COLOR .. "Телепорт:|r " .. tp.name, 0, 100 + i)
    end

    player:GossipSendMenu(1, creature)
end

--- Страница одной секции: строки кликабельны, ведут назад в корень.
local function ShowSectionPage(event, player, creature, index)
    local sections = AvailableSections(player)
    local section = sections[index]
    if not section then
        ShowRootMenu(event, player, creature)
        return
    end

    player:GossipClearMenu()
    for _, line in ipairs(Lore.PageLines(section)) do
        player:GossipMenuAddItem(0, line, 0, MENU_ROOT)
    end
    player:GossipMenuAddItem(0, ORDER_COLOR .. "[К другим разделам]|r", 0, MENU_ROOT)
    player:GossipSendMenu(1, creature)
end

--- Обработчик выбора пункта меню.
local function OnGossipSelect(event, player, creature, sender, intid, code)
    -- Телепорты: intid 101..100+N
    if intid >= 101 and intid <= 100 + #TELEPORTS then
        local tp = TELEPORTS[intid - 100]
        player:SendBroadcastMessage(TAG .. " " .. (IsRu(player) and L.ru.portal or L.en.portal))
        player:Teleport(tp.map, tp.x, tp.y, tp.z, tp.o)
        player:GossipComplete()
        return
    end

    -- Секции лора: intid 11..10+N
    if intid > MENU_SECTION_BASE then
        ShowSectionPage(event, player, creature, intid - MENU_SECTION_BASE)
        return
    end

    -- Корень и «назад»
    ShowRootMenu(event, player, creature)
end

--- Обработчик открытия диалога с НПС.
local function OnGossipHello(event, player, creature)
    if creature:GetEntry() ~= GUARDIAN_ENTRY then
        return
    end

    local stage = Lore.Stage(player)

    -- Расовая реплика — из центрального реестра кампаний
    local raceLine = AzerothEchoCampaigns.race_greetings[player:GetRace()] or ""
    if raceLine ~= "" then
        player:SendBroadcastMessage(TAG .. " «" .. raceLine .. "»")
    end

    -- Реплика Стража, зависит от стадии истории
    local npcLine = Lore.NpcLine("guardian", stage)
    if npcLine ~= "" then
        player:SendBroadcastMessage(TAG .. " " .. npcLine)
    end

    ShowRootMenu(event, player, creature)
end

RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 1, OnGossipHello)    -- GOSSIP_EVENT_ON_HELLO = 1
RegisterCreatureGossipEvent(GUARDIAN_ENTRY, 2, OnGossipSelect)   -- GOSSIP_EVENT_ON_SELECT = 2

print("[EchoOfTheVoid] PortalGuardian.lua загружен (НПС " .. GUARDIAN_ENTRY .. ", лор из 00_LoreRegistry).")
