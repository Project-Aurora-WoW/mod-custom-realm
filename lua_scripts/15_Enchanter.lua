-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 15_Enchanter.lua
-- Назначение: НПС-зачарователь за золото (адаптация
-- eluna-scripts/QoL/goldEnchant.lua — версия с ценой и
-- подтверждением; авторы Foereaper/rochet/Cloticc). НПС 70172
-- «Рунный Обжиг» (0018) накладывает любой энчант 3.3.5a на
-- надетый предмет слота за фиксированную цену.
-- Отличия от оригинала:
--   - NPC entry и цена — в реестре (REG.services.enchanter);
--   - локализация меню и сообщений ru/en (DbcLocale 8 → русский);
--   - конфликт повторного списания денег исправлен: оригинал
--     списывал цену в CanBuy и УЖЕ удержанной считал при
--     подтверждении gossip (цена в GossipMenuAddItem) — у нас
--     списание только в хендлере применения, поле code
--     используется для подтверждения клиентом цены;
--   - оригинальный баг-регресс брошенного Enchanter.lua
--     (Wtype == 18 с малой буквы) здесь отсутствует.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ENC = REG.services.enchanter

-- ============================================================
-- Таблица энчантов (из goldEnchant.lua без изменений по ID).
-- [slotId] = { { название, enchantId, isShieldOr2H }, ... }
-- Ключи — EquipmentSlot: 0 голова, 2 плечи, 4 грудь, 6 ноги,
-- 7 ботинки, 8 запястья, 9 перчатки, 14 плащ, 15 правая рука,
-- 16 левая рука, 17 дальний бой.
-- ============================================================
local T = {
    ["Menu"] = {
        { "Шлем", 0 },
        { "Наплечники", 2 },
        { "Нагрудник", 4 },
        { "Поножи", 6 },
        { "Обувь", 7 },
        { "Наручи", 8 },
        { "Перчатки", 9 },
        { "Плащ", 14 },
        { "Оружие (правая рука)", 15 },
        { "Двуручное оружие", 151 },
        { "Оружие (левая рука)", 16 },
        { "Щиты", 161 },
        { "Дальний бой", 171 },
    },
    [0] = {
        { "Тайное писание пылающих тайн", 3820, false },
        { "Тайное писание блаженного исцеления", 3819, false },
        { "Тайное писание стойкого защитника", 3818, false },
        { "Тайное писание пытки", 3817, false },
        { "Тайное писание свирепого гладиатора", 3842, false },
        { "Тайное писание триумфа", 3795, false },
        { "Тайное писание доминирования", 3797, false },
    },
    [2] = {
        { "Начертание триумфа", 3793, false },
        { "Начертание доминирования", 3794, false },
        { "Великое начертание гладиатора", 3852, false },
        { "Великое начертание топора", 3808, false },
        { "Великое начертание ущелья", 3809, false },
        { "Великое начертание вершины", 3811, false },
        { "Великое начертание бури", 3810, false },
    },
    [4] = {
        { "Грудь — Мощные характеристики", 3832, false },
        { "Грудь — Колоссальное здоровье", 3297, false },
        { "Грудь — Восстановление маны", 2381, false },
        { "Грудь — Исключительная устойчивость", 3245, false },
        { "Грудь — Улучшенная защита", 1953, false },
    },
    [6] = {
        { "Нагрудник из земли", 3853, false },
        { "Морозная накидка на ноги", 3822, false },
        { "Ледяная накидка на ноги", 3823, false },
        { "Искрящаяся нить", 3719, false },
        { "Сапфировая нить", 3721, false },
    },
    [7] = {
        { "Обувь — Усиленный натиск", 1597, false },
        { "Обувь — Жизнестойкость туслика", 3232, false },
        { "Обувь — Превосходная ловкость", 983, false },
        { "Обувь — Улучшенный дух", 1147, false },
        { "Обувь — Улучшенная живучесть", 3244, false },
        { "Обувь — Ледоход", 3826, false },
        { "Обувь — Улучшенная стойкость", 1075, false },
    },
    [8] = {
        { "Наручи — Могучая выносливость", 3850, false },
        { "Наручи — Превосходная сила заклинаний", 2332, false },
        { "Наручи — Усиленный натиск", 3845, false },
        { "Наручи — Могучий дух", 1147, false },
        { "Наручи — Мастерство", 3231, false },
        { "Наручи — Улучшенные характеристики", 2661, false },
        { "Наручи — Исключительный интеллект", 1119, false },
    },
    [9] = {
        { "Перчатки — Улучшенный взрыв", 3249, false },
        { "Перчатки — Оружейник", 3253, false },
        { "Перчатки — Сокрушитель", 1603, false },
        { "Перчатки — Ловкость", 3222, false },
        { "Перчатки — Точность", 3234, false },
        { "Перчатки — Мастерство", 3231, false },
        { "Перчатки — Исключительная сила заклинаний", 3246, false },
    },
    [14] = {
        { "Плащ — Теневой доспех", 3256, false },
        { "Плащ — Мудрость", 3296, false },
        { "Плащ — Ткань титанов", 1951, false },
        { "Плащ — Улучшенная скорость", 3831, false },
        { "Плащ — Могучий доспех", 3294, false },
        { "Плащ — Основная ловкость", 1099, false },
        { "Плащ — Проникающие заклинания", 1262, false },
    },
    [15] = {
        { "Оружие — Крестоносец", 1900, false },
        { "Оружие — Страж титанов", 3851, false },
        { "Оружие — Точность", 3788, false },
        { "Оружие — Берсерк", 3789, false },
        { "Оружие — Чёрная магия", 3790, false },
        { "Оружие — Могучая сила заклинаний", 3834, false },
        { "Оружие — Превосходная мощь", 3833, false },
        { "Оружие — Ледолом", 3239, false },
        { "Оружие — Хранитель жизни", 3241, false },
        { "Оружие — Питьё крови", 3870, false },
        { "Оружие — Гроза клинков", 3869, false },
        { "Оружие — Исключительная ловкость", 1103, false },
        { "Оружие — Исключительный дух", 3844, false },
        { "Оружие — Палач", 3225, false },
        { "Оружие — Мангуст", 2673, false },
        { "2H — Резня", 3827, true },
        { "2H — Погибель покойника", 3247, true },
        { "2H — Гигантский убийца", 3251, true },
        { "2H — Улучшенная сила заклинаний", 3854, true },
    },
    [16] = {
        { "Оружие — Страж титанов", 3851, false },
        { "Оружие — Точность", 3788, false },
        { "Оружие — Берсерк", 3789, false },
        { "Оружие — Чёрная магия", 3790, false },
        { "Оружие — Могучая сила заклинаний", 3834, false },
        { "Оружие — Превосходная мощь", 3833, false },
        { "Оружие — Ледолом", 3239, false },
        { "Оружие — Хранитель жизни", 3241, false },
        { "Оружие — Питьё крови", 3870, false },
        { "Оружие — Гроза клинков", 3869, false },
        { "Оружие — Исключительная ловкость", 1103, false },
        { "Оружие — Исключительный дух", 3844, false },
        { "Оружие — Палач", 3225, false },
        { "Оружие — Мангуст", 2673, false },
        { "Щит — Защита", 1952, true },
        { "Щит — Улучшенный интеллект", 1128, true },
        { "Щит — Блок щита", 2655, true },
        { "Щит — Устойчивость", 3229, true },
        { "Щит — Могучая выносливость", 1071, true },
        { "Щит — Прочный щит", 2653, true },
    },
    [17] = {
        { "Граненый рефракторный прицел", 3843, true },
        { "Солнечный прицел", 3607, true },
        { "Пронзающий сердца прицел", 3608, true },
    },
}

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        menuTitle = "Enchanting — %s (price: %s)",
        priceLabel = "%d gold",
        noGold = "Not enough gold (price: %d gold).",
        enchanted = "%s enchanted!",
        noItem = "No item equipped in this slot!",
        wrong2H = "You do not have a two-handed weapon equipped!",
        wrongShield = "You do not have a shield equipped!",
        wrongRanged = "You do not have a ranged weapon equipped!",
        back = "[Back]",
    },
    ru = {
        menuTitle = "Зачарование — %s (цена: %s)",
        priceLabel = "%d зол.",
        noGold = "Недостаточно золота (цена: %d зол.).",
        enchanted = "%s зачаровано!",
        noItem = "В этом слоте нет предмета!",
        wrong2H = "На вас не надето двуручное оружие!",
        wrongShield = "На вас не надет щит!",
        wrongRanged = "На вас не надето оружие дальнего боя!",
        back = "[Назад]",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- Меню слотов
local function ShowSlotMenu(event, player, object)
    player:GossipClearMenu()
    local loc = GetLocale(player)
    for _, v in ipairs(T["Menu"]) do
        player:GossipMenuAddItem(0, v[1], 0, v[2])
    end
    player:GossipSendMenu(1, object)
end

-- Меню энчантов слота
local function ShowEnchantMenu(event, player, object, slotKey)
    local loc = GetLocale(player)
    local ID = slotKey
    local filtered = false
    -- 151/161/171 — «расширенные» ключи оригинала (2H/щит/дальний бой)
    if slotKey >= 151 then
        ID = math.floor(slotKey / 10)
        filtered = true
    end

    player:GossipClearMenu()
    if T[ID] then
        for _, v in ipairs(T[ID]) do
            if (not filtered and not v[3]) or (filtered and v[3]) then
                player:GossipMenuAddItem(0, v[1], 0, v[2], false,
                    string.format(loc.priceLabel, ENC.price / 10000), ENC.price)
            end
        end
    end
    player:GossipMenuAddItem(0, loc.back, 0, 500)
    player:GossipSendMenu(1, object)
end

-- Применение энчанта
local function ApplyEnchant(player, slotKey, enchantId, loc)
    local ID = slotKey
    if slotKey >= 151 then
        ID = math.floor(slotKey / 10)
    end

    local item = player:GetEquippedItemBySlot(ID)
    if not item then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.noItem)
        return
    end

    if slotKey >= 151 then
        local subClass = item:GetSubClass()
        if slotKey == 151 then
            -- двуручное: 1 axes, 5 maces, 6 swords, 8 polearms, 10 staves
            if not (subClass == 1 or subClass == 5 or subClass == 6 or subClass == 8 or subClass == 10) then
                player:SendAreaTriggerMessage(TAG .. " " .. loc.wrong2H)
                return
            end
        elseif slotKey == 161 then
            if subClass ~= 6 then -- shields
                player:SendAreaTriggerMessage(TAG .. " " .. loc.wrongShield)
                return
            end
        elseif slotKey == 171 then
            -- дальний бой: 2 bows, 3 guns, 18 crossbows, 19 wands
            if not (subClass == 2 or subClass == 3 or subClass == 18 or subClass == 19) then
                player:SendAreaTriggerMessage(TAG .. " " .. loc.wrongRanged)
                return
            end
        end
    end

    -- Оплата: строго перед наложением (single-point charge)
    if player:GetCoinage() < ENC.price then
        player:SendAreaTriggerMessage(TAG .. " "
            .. string.format(loc.noGold, ENC.price / 10000))
        return
    end
    player:ModifyMoney(-ENC.price)

    item:ClearEnchantment(0, 0)
    item:SetEnchantment(enchantId, 0, 0)
    player:CastSpell(player, ENC.visual_spell)
    player:SendAreaTriggerMessage(TAG .. " " .. string.format(loc.enchanted, item:GetItemLink(0)))
end

-- pVar-паттерн оригинала: хранение выбранного слота между
-- gossip-хендлерами (локальная таблица по имени игрока)
local pVar = {}

local function OnHelloWrap(event, player, object)
    pVar[player:GetName()] = nil
    ShowSlotMenu(event, player, object)
end

local function OnSelectWrap(event, player, object, sender, intid, code, menu_id)
    local loc = GetLocale(player)
    if intid == 500 then
        ShowSlotMenu(event, player, object)
        return
    end
    if intid == 0 or intid == 2 or intid == 4 or intid == 6 or intid == 7
        or intid == 8 or intid == 9 or intid == 14 or intid == 15
        or intid == 16 or intid == 17 or intid == 151 or intid == 161 or intid == 171 then
        pVar[player:GetName()] = intid
        ShowEnchantMenu(event, player, object, intid)
        return
    end
    -- выбор энчанта
    local slotKey = pVar[player:GetName()]
    if slotKey then
        ApplyEnchant(player, slotKey, intid, loc)
        ShowEnchantMenu(event, player, object, slotKey)
    end
end

RegisterCreatureGossipEvent(ENC.npc, 1, OnHelloWrap)
RegisterCreatureGossipEvent(ENC.npc, 2, OnSelectWrap)

print(string.format(
    "[EchoOfTheVoid] 15_Enchanter.lua загружен (зачарователь НПС %d, цена %d зол.).",
    ENC.npc, ENC.price / 10000))
