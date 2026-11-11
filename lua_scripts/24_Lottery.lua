-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 24_Lottery.lua
-- Назначение: лотерея (адаптация eluna-scripts/lotteryDB.lua,
-- Cloticc). НПС 70176 «Хранитель Тиражей» (Даларан, 0024):
-- билет = 6 чисел 1–32, недельный розыгрыш с джекпотом.
-- Награда — письмом с золотом при совпадении всех чисел.
--
-- Отличия от оригинала:
--   - таблицы в acore_characters (realm_lottery/realm_lottery_tickets),
--     а не world; НЕ создаются в скрипте (конвенция реалма — миграция
--     0024), загрузка безопасна при их отсутствии (pcall-запрос);
--   - чинится ряд багов оригинала:
--       • розыгрыш зависел от игрового события (game_event 89) —
--         здесь цикл по расписанию (interval_secs) через тик мира;
--       • в оригинале все призы читались из column 0 (number1==number1
--         всегда) — фактически каждый билет был выигрышным в цикле
--         winnings=amount/winners внутри while → отправка писем в цикл;
--         у нас матч — строгое равенство всех 6 чисел, письмо 1 раз;
--       • winnings=amount/winners делилось ВНУТРИ цикла на всех —
--         здесь приз делится на число победителей ПОСЛЕ подсчёта;
--       • genealogy вне цикла (не было итерации по ticket_id);
--   - недельная ставка (регенерируется числа) — параметры в реестре.
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local VOID_COLOR = REG.meta.colors.void

local CFG = REG.tier_b and REG.tier_b.lottery
if not CFG or not CFG.enabled then
    print("[EchoOfTheVoid] 24_Lottery.lua загружен, но выключен (REG.tier_b.lottery.enabled = false).")
    return
end

local NPC_LOTTERY = CFG.npc
local PRICE = CFG.ticket_price      -- медь за билет
local JACKPOT_TICK = CFG.jackpot_tick -- прирост джекпота за билет
local MAX_TICKETS = CFG.max_tickets_per_player
local MIN_NUM, MAX_NUM = CFG.number_range[1], CFG.number_range[2]
local PICK_COUNT = CFG.pick_count
local DRAW_EXTRA_SECS = CFG.draw_extra_secs -- случайный сдвиг розыгрыша

local TBL = "realm_lottery"
local TBL_T = "realm_lottery_tickets"

local WORLD_UPDATE = 13

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        welcome = "Welcome to the Echo Lottery! Buy a ticket for %d gold. Jackpot: %s gold.",
        buy = "Buy lottery ticket (6 numbers 1-%d)",
        tickets = "Your tickets:",
        max_reached = "You have reached the maximum amount of tickets.",
        no_gold = "You do not have enough gold for a ticket.",
        bought = "Your ticket is purchased! Good luck!",
        draw = "The Echo Lottery draw has concluded. Winners were rewarded by mail.",
        none = "You have no tickets.",
    },
    ru = {
        welcome = "Добро пожаловать в Лотерею Эха! Билет за %d зол. Джекпот: %s зол.",
        buy = "Купить билет лотереи (6 чисел 1-%d)",
        tickets = "Ваши билеты:",
        max_reached = "Достигнут максимум билетов на игрока.",
        no_gold = "У вас недостаточно золота на билет.",
        bought = "Ваш билет куплен! Удачи!",
        draw = "Розыгрыш Лотереи Эха завершён. Победителей наградили письмом.",
        none = "У вас пока нет билетов.",
    },
}

local function L10n(player)
    return (player:GetSession():GetSessionDbcLocale() == 8) and L.ru or L.en
end

local function GoldOf(v)
    return math.floor((v or 0) / 10000)
end

-- ============================================================
-- Работа с БД (безопасно при отсутствии таблиц — миграция 0024)
-- ============================================================
local function CurrentWeek()
    local ok, q = pcall(CharDBQuery, string.format(
        "SELECT MAX(week_number) FROM `%s`", TBL))
    if ok and q and q:GetUInt32(0) then
        return q:GetUInt32(0)
    end
    return 0
end

local function Jackpot()
    local ok, q = pcall(CharDBQuery, string.format(
        "SELECT amount FROM `%s` WHERE week_number = %d", TBL, CurrentWeek()))
    if ok and q then
        return q:GetUInt64(0) or 0
    end
    return 0
end

local function WeekNumbers(week)
    local rows = {}
    local ok, q = pcall(CharDBQuery, string.format(
        "SELECT number1, number2, number3, number4, number5, number6, amount FROM `%s` WHERE week_number = %d", TBL, week))
    if ok and q then
        for i = 0, 5 do rows[i + 1] = q:GetUInt32(i) end
        rows[7] = q:GetUInt64(6) or 0
    end
    return rows
end

-- Начать новый недельный тираж (генерирует числа, обнуляет джекпот)
local function StartWeek()
    local week = CurrentWeek() + 1
    local n = {}
    for i = 1, PICK_COUNT do n[i] = math.random(MIN_NUM, MAX_NUM) end
    local ok = pcall(CharDBExecute, string.format(
        "INSERT INTO `%s` (week_number, number1, number2, number3, number4, number5, number6, amount) VALUES (%d, %d, %d, %d, %d, %d, %d, 0)",
        TBL, week, n[1], n[2], n[3], n[4], n[5], n[6]))
    return ok
end

-- ============================================================
-- Тир мира: расписание розыгрыша (вместо game_event оригинала)
-- ============================================================
local nextDraw = os.time() + (CFG.draw_interval_secs or 604800) + math.random(0, DRAW_EXTRA_SECS)

local function OnWorldUpdate(event, diff)
    local now = os.time()
    if now < nextDraw then
        return
    end
    nextDraw = now + (CFG.draw_interval_secs or 604800) + math.random(0, DRAW_EXTRA_SECS)

    local week = CurrentWeek()
    if week == 0 then
        StartWeek()
        return
    end

    local win = WeekNumbers(week)
    local pot = win[7]

    -- Собрать все билеты недели
    local tickets = {}
    local ok, qt = pcall(CharDBQuery, string.format(
        "SELECT player_guid, number1, number2, number3, number4, number5, number6 FROM `%s` WHERE week_number = %d", TBL_T, week))
    if ok and qt then
        repeat
            local t = { guid = qt:GetUInt32(0) }
            local match = true
            for i = 1, PICK_COUNT do
                if qt:GetUInt32(i) ~= win[i] then match = false break end
            end
            t.match = match
            table.insert(tickets, t)
        until not qt:NextRow()
    end

    -- Подсчитать победителей
    local winners = {}
    for _, t in ipairs(tickets) do
        if t.match then table.insert(winners, t.guid) end
    end

    -- Приз делится между победителями поровну (после подсчёта, не в цикле)
    if #winners > 0 then
        local share = math.floor(pot / #winners)
        for _, guid in ipairs(winners) do
            SendMail(
                "Победа в Лотерее Эха!",
                string.format("Поздравляем! Вы выиграли в лотерее: %d золота.", GoldOf(share)),
                guid, 0, 0, 0, share
            )
        end
    end

    -- Убрать проданные билеты прошедшего тиража
    pcall(CharDBExecute, string.format("DELETE FROM `%s` WHERE week_number = %d", TBL_T, week))

    -- Весь мир: оповещение о розыгрыше
    SendWorldMessage(TAG .. " " .. VOID_COLOR .. L.ru.draw .. "|r")

    -- Новый тираж
    StartWeek()
end
RegisterServerEvent(WORLD_UPDATE, OnWorldUpdate)

-- ============================================================
-- Gossip НПС 70176
-- ============================================================
local function OnHello(event, player, creature)
    if creature:GetEntry() ~= NPC_LOTTERY then return end
    if CurrentWeek() == 0 then StartWeek() end
    local t = L10n(player)
    local pot = GoldOf(Jackpot())
    player:GossipSetText(string.format(t.welcome, GoldOf(PRICE), pot))

    local guid = player:GetGUIDLow()
    local count = 0
    local ok, qp = pcall(CharDBQuery, string.format(
        "SELECT ticket_id, number1, number2, number3, number4, number5, number6 FROM `%s` WHERE player_guid = %d", TBL_T, guid))
    if ok and qp then
        repeat
            local nums = {}
            for i = 0, 5 do nums[i + 1] = qp:GetUInt32(i + 1) end
            player:GossipMenuAddItem(0, string.format("Ticket #%d: %s", qp:GetUInt32(0), table.concat(nums, ", ")), 0, 0)
            count = count + 1
        until not qp:NextRow()
    end
    if count == 0 then
        player:GossipMenuAddItem(0, t.none, 0, 0)
    elseif count >= MAX_TICKETS then
        player:GossipMenuAddItem(0, t.max_reached, 0, 0)
    end

    player:GossipMenuAddItem(0, string.format(t.buy, MAX_NUM), 0, 1)
    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    local t = L10n(player)
    if intid == 1 then
        if CurrentWeek() == 0 then StartWeek() end
        if player:GetCoinage() < PRICE then
            player:GossipComplete()
            player:SendBroadcastMessage(TAG .. " " .. t.no_gold)
            return
        end

        -- Списание + билет
        player:ModifyMoney(-PRICE)
        local numbers = {}
        for i = 1, PICK_COUNT do numbers[i] = math.random(MIN_NUM, MAX_NUM) end
        local week = CurrentWeek()
        pcall(CharDBExecute, string.format(
            "INSERT INTO `%s` (week_number, player_guid, player_account_id, number1, number2, number3, number4, number5, number6) VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d)",
            TBL_T, week, player:GetGUIDLow(), player:GetAccountId(),
            numbers[1], numbers[2], numbers[3], numbers[4], numbers[5], numbers[6]))
        pcall(CharDBExecute, string.format(
            "UPDATE `%s` SET amount = amount + %d WHERE week_number = %d", TBL, JACKPOT_TICK, week))

        player:SendBroadcastMessage(TAG .. " " .. t.bought)
    end
    OnHello(event, player, creature)
end

RegisterCreatureGossipEvent(NPC_LOTTERY, 1, OnHello)
RegisterCreatureGossipEvent(NPC_LOTTERY, 2, OnSelect)

print(string.format(
    "[EchoOfTheVoid] 24_Lottery.lua загружен (лотерея НПС %d).",
    NPC_LOTTERY))