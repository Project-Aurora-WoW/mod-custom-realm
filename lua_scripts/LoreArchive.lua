-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- LoreArchive.lua
-- Назначение: НПС «Хронист Ордена» (entry 70180, Даларан) —
-- игровой лор-архив реалма.
--
-- ЛОР НЕ ХРАНИТСЯ ЗДЕСЬ. Все тексты берутся из 00_LoreRegistry.ext
-- (AzerothEchoLore). Архив группирует секции по категориям и
-- скрывает те, что ещё не открыты на стадии истории игрока.
--
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local ARCHIVIST_ENTRY = 70180

local Lore = AzerothEchoLore
local TAG = Lore.meta.tag
local VOID_COLOR = Lore.meta.colors.void
local ORDER_COLOR = Lore.meta.colors.order

-- Группировка секций реестра по разделам архива.
-- Секции, не попавшие ни в одну группу, выводятся в «Прочее».
local CATEGORIES = {
    {
        key = "world",
        title = "Мир и Пустота",
        ids = { "prologue", "whisper", "void_nature", "gesalt", "locations", "dragonblight" },
    },
    {
        key = "powers",
        title = "Силы: Орден, Культ, Стражи",
        ids = { "order", "cult", "warders" },
    },
    {
        key = "story",
        title = "Хроника кампаний",
        ids = { "camp1", "camp2", "camp3", "camp4" },
    },
    {
        key = "creatures",
        title = "Фигуры и порождения",
        ids = { "figures", "bestiary", "issush" },
    },
    {
        key = "codes",
        title = "Правила, артефакты, словарь",
        ids = { "rules", "artifacts", "events", "glossary" },
    },
}

-- ID пунктов меню
local MENU_CATEGORY_BASE = 20   -- 20..20+N — категории
local MENU_SECTION_BASE = 100   -- 100.. — конкретные секции
local MENU_ROOT = 1

--- Секции реестра, видимые на стадии (id -> section).
local function VisibleMap(stage)
    local map = {}
    for _, s in ipairs(Lore.VisibleSections(stage)) do
        map[s.id] = s
    end
    return map
end

--- Секции категории, видимые на стадии.
local function CategorySections(category, stage)
    local visible = VisibleMap(stage)
    local out = {}
    for _, id in ipairs(category.ids) do
        if visible[id] then
            out[#out + 1] = visible[id]
        end
    end
    return out
end

--- Количество видимых секций категории (для скрытия пустых пунктов).
local function CategoryCount(category, stage)
    return #CategorySections(category, stage)
end

--- Итоговый список видимых секций по всем категориям (для индексов меню).
local function AllVisible(stage)
    local out = {}
    for _, cat in ipairs(CATEGORIES) do
        for _, s in ipairs(CategorySections(cat, stage)) do
            out[#out + 1] = s
        end
    end
    return out
end

--- Главное меню архива.
local function ShowArchiveMenu(event, player, creature)
    local stage = Lore.Stage(player)
    player:GossipClearMenu()

    player:GossipMenuAddItem(0,
        ORDER_COLOR .. "Покажи каталог разделов.|r", 0, MENU_CATEGORY_BASE)

    for i, cat in ipairs(CATEGORIES) do
        local count = CategoryCount(cat, stage)
        if count > 0 then
            player:GossipMenuAddItem(0,
                "  " .. cat.title .. " (" .. count .. ")", 0, MENU_CATEGORY_BASE + i)
        end
    end

    player:GossipSendMenu(1, creature)
end

--- Меню одной категории.
local function ShowCategoryMenu(event, player, creature, categoryIndex)
    local cat = CATEGORIES[categoryIndex]
    local stage = Lore.Stage(player)
    if not cat then
        ShowArchiveMenu(event, player, creature)
        return
    end

    local sections = CategorySections(cat, stage)
    local allVisible = AllVisible(stage)

    player:GossipClearMenu()
    for _, section in ipairs(sections) do
        local idx = 0
        for i, s in ipairs(allVisible) do
            if s.id == section.id then
                idx = i
                break
            end
        end
        if idx > 0 then
            player:GossipMenuAddItem(0, "  " .. section.title, 0, MENU_SECTION_BASE + idx)
        end
    end
    player:GossipMenuAddItem(0, ORDER_COLOR .. "[К каталогу]|r", 0, MENU_ROOT)
    player:GossipSendMenu(1, creature)
end

--- Страница отдельной секции.
local function ShowSectionPage(event, player, creature, index)
    local stage = Lore.Stage(player)
    local allVisible = AllVisible(stage)
    local section = allVisible[index]
    if not section then
        ShowArchiveMenu(event, player, creature)
        return
    end

    player:GossipClearMenu()
    for _, line in ipairs(Lore.PageLines(section)) do
        player:GossipMenuAddItem(0, line, 0, MENU_ROOT)
    end
    player:GossipMenuAddItem(0, ORDER_COLOR .. "[К каталогу]|r", 0, MENU_ROOT)
    player:GossipSendMenu(1, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    -- Конкретная секция
    if intid > MENU_SECTION_BASE then
        ShowSectionPage(event, player, creature, intid - MENU_SECTION_BASE)
        return
    end

    -- Категория
    if intid > MENU_CATEGORY_BASE then
        ShowCategoryMenu(event, player, creature, intid - MENU_CATEGORY_BASE)
        return
    end

    ShowArchiveMenu(event, player, creature)
end

local function OnGossipHello(event, player, creature)
    if creature:GetEntry() ~= ARCHIVIST_ENTRY then
        return
    end

    local stage = Lore.Stage(player)
    local line = Lore.NpcLine("archivist", stage)
    if line ~= "" then
        player:SendBroadcastMessage(TAG .. ORDER_COLOR .. " Хронист:|r " .. line)
    end

    ShowArchiveMenu(event, player, creature)
end

RegisterCreatureGossipEvent(ARCHIVIST_ENTRY, 1, OnGossipHello)
RegisterCreatureGossipEvent(ARCHIVIST_ENTRY, 2, OnGossipSelect)

print("[EchoOfTheVoid] LoreArchive.lua загружен (НПС " .. ARCHIVIST_ENTRY .. ", архив из 00_LoreRegistry).")
