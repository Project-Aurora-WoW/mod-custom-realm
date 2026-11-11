-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 16_GoldStorage.lua
-- Назначение: НПС-казначей золота (адаптация
-- eluna-scripts/QoL/GoldStorage, автор Cloticc). НПС 70173
-- «Хранитель Золота» (0018): депозит/снятие золота (на
-- аккаунт), баланс в меню, лидерборд топ-5 казны.
-- Отличия от оригинала:
--   - self-создание таблицы заменено миграцией 0018
--     (realm_gold_storage, acore_characters — по нашей
--     конвенции, вместо custom_gold_storage);
--   - entry НПС и имя таблицы — в реестре (REG.gold_storage);
--   - исправлен баг оригинала: снятие делало UPDATE без
--     проверки результата и выдавало деньги даже при
--     недостаточном балансе — теперь проверка SELECT'ом и
--     атомарный UPDATE ... AND gold >= amount;
--   - исправлен баг оригинала: депозит принимал отрицательные
--     и нулевые суммы (превращаясь в способ обнуления казны);
--   - депозит/снятие — только целые золотые (>= 1);
--   - GetUInt32 в оригинале обрезал суммы > 4.29 млрд меди —
--     BIGINT читается корректно (GetDouble для больших сумм);
--   - лидерборд: GROUP BY account в оригинале возвращал имя
--     произвольного персонажа аккаунта — убрано SUM-дублирование,
--     казна per-аккаунт (PK = account);
--   - локализация ru/en (DbcLocale 8 → русский).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local GS = REG.gold_storage

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        balance   = "Your vault holds %s gold.",
        store     = "Deposit gold (type amount)...",
        withdraw  = "Withdraw gold (type amount)...",
        leaderboard = "----- Vault leaderboard -----",
        stored    = "Deposited %d gold. Vault balance: %s.",
        withdrawn = "Withdrawn %d gold. Vault balance: %s.",
        notEnoughGold = "Not enough gold in your pockets.",
        notEnoughVault = "Not enough gold in your vault.",
        badAmount = "Enter a whole positive amount of gold.",
        topRow    = "%d. %s — %s gold",
    },
    ru = {
        balance   = "В казне хранится %s зол.",
        store     = "Внести золото (введите сумму)...",
        withdraw  = "Снять золото (введите сумму)...",
        leaderboard = "----- Лидерборд казны -----",
        stored    = "Внесено %d зол. В казне: %s.",
        withdrawn = "Снято %d зол. В казне: %s.",
        notEnoughGold = "Недостаточно золота при вас.",
        notEnoughVault = "В казне недостаточно золота.",
        badAmount = "Введите целую положительную сумму золота.",
        topRow    = "%d. %s — %s зол.",
    },
}

local function GetLocale(player)
    if player and player:GetDbcLocale() == 8 then
        return L.ru
    end
    return L.en
end

-- ============================================================
-- Утилиты
-- ============================================================

-- Разделение тысяч: 1234567 -> 1,234,567
local function CommaValue(n)
    local formatted = tostring(n)
    while true do
        local k
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function GetBalance(accountId)
    local q = CharDBQuery(string.format(
        "SELECT gold FROM `%s` WHERE account = %d", GS.db_table, accountId))
    if not q then
        return 0
    end
    -- BIGINT: читаем через GetDouble, чтобы не обрезать суммы
    return math.floor(q:GetDouble(0))
end

-- ============================================================
-- Депозит / снятие
-- ============================================================

local function StoreGold(player, amountGold, loc)
    amountGold = tonumber(amountGold)
    if not amountGold or amountGold ~= math.floor(amountGold) or amountGold < 1 then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.badAmount)
        return
    end

    local copper = amountGold * 10000
    if player:GetCoinage() < copper then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.notEnoughGold)
        return
    end

    local accountId = player:GetAccountId()
    CharDBExecute(string.format([[
        INSERT INTO `%s` (account, name, gold)
        VALUES (%d, '%s', %d)
        ON DUPLICATE KEY UPDATE gold = gold + %d, name = VALUES(name)
    ]], GS.db_table, accountId, REG.escape(player:GetName()), amountGold, amountGold))

    player:ModifyMoney(-copper)
    player:SendAreaTriggerMessage(TAG .. " "
        .. string.format(loc.stored, amountGold,
            CommaValue(GetBalance(accountId))))
end

local function WithdrawGold(player, amountGold, loc)
    amountGold = tonumber(amountGold)
    if not amountGold or amountGold ~= math.floor(amountGold) or amountGold < 1 then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.badAmount)
        return
    end

    local accountId = player:GetAccountId()
    local copper = amountGold * 10000

    -- Проверка баланса ДО списания (баланс в золоте, меди — с
    -- запасом точности BIGINT; исправление бага оригинала,
    -- выдававшего деньги без проверки)
    local balanceGold = GetBalance(accountId)
    if balanceGold < amountGold then
        player:SendAreaTriggerMessage(TAG .. " " .. loc.notEnoughVault)
        return
    end

    -- Атомарный UPDATE: сработает, даже если баланс уменьшился
    -- между SELECT и UPDATE (гонка) — защита от дюпа
    CharDBExecute(string.format(
        "UPDATE `%s` SET gold = gold - %d WHERE account = %d AND gold >= %d",
        GS.db_table, amountGold, accountId, amountGold))

    local newBalance = GetBalance(accountId)
    if newBalance >= balanceGold then
        -- UPDATE не применился (баланс изменился в гонке)
        player:SendAreaTriggerMessage(TAG .. " " .. loc.notEnoughVault)
        return
    end

    player:ModifyMoney(copper)
    player:SendAreaTriggerMessage(TAG .. " "
        .. string.format(loc.withdrawn, amountGold,
            CommaValue(newBalance)))
end

-- ============================================================
-- Gossip
-- ============================================================

local function ShowMenu(event, player, creature)
    local loc = GetLocale(player)
    local accountId = player:GetAccountId()

    player:GossipSetText(string.format(loc.balance, CommaValue(GetBalance(accountId))))

    -- Ввод суммы: поле code у GossipMenuAddItem (как в оригинале)
    player:GossipMenuAddItem(7, loc.store, 0, 1, true)
    player:GossipMenuAddItem(7, loc.withdraw, 0, 2, true)

    player:GossipMenuAddItem(0, loc.leaderboard, 0, 3)

    local q = CharDBQuery(string.format([[
        SELECT name, gold FROM `%s`
        WHERE gold > 0
        ORDER BY gold DESC
        LIMIT %d
    ]], GS.db_table, GS.top_count))
    if q then
        local i = 0
        repeat
            i = i + 1
            player:GossipMenuAddItem(0, string.format(loc.topRow,
                i, q:GetString(0), CommaValue(math.floor(q:GetDouble(1)))), 0, 0)
        until not q:NextRow()
    end

    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code, menu_id)
    local loc = GetLocale(player)
    if intid == 1 then
        StoreGold(player, code, loc)
    elseif intid == 2 then
        WithdrawGold(player, code, loc)
    end
    ShowMenu(event, player, creature)
end

RegisterCreatureGossipEvent(GS.npc, 1, ShowMenu)
RegisterCreatureGossipEvent(GS.npc, 2, OnSelect)

print(string.format(
    "[EchoOfTheVoid] 16_GoldStorage.lua загружен (казначей НПС %d, таблица %s).",
    GS.npc, GS.db_table))
