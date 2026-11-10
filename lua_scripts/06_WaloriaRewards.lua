-- ============================================================
-- 06_WaloriaRewards.lua — Награды за уровни (подход Waloria)
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order

local WELCOME_LEVEL = 2          -- welcome reward (Waloria: на 2-м уровне)
local WELCOME_ITEM = 70100       -- «Паёк Ордена» (0014_waloria_rewards.sql)
local BAG_ITEM = 70101           -- «Сумка Эха» (level-up reward)
local LEVEL_STEP = 5             -- награда каждые 5 уровней
local MAX_LEVEL = 80
local REWARDS_TABLE = "realm_level_rewards"

-- Припасы welcome-награды (реальные, поверх памятного токена)
local WELCOME_SUPPLIES = { { 33470, 3 }, { 33475, 3 }, { 43005, 5 } }

-- Награда «Сумки Эха» за каждые 5 уровней (жетоны + припасы)
local BAG_REWARDS = { { 70005, 2 }, { 33470, 2 }, { 33475, 2 } }

-- Локализация
local function L(player, ru, en)
    local ok, loc = pcall(function() return player:GetDbcLocale() end)
    return (ok and loc == 8) and ru or en
end

-- Отметка о выдаче (антидубль); true — уже выдавалось
local function AlreadyGranted(player, rewardLevel)
    local q = CharDBQuery(string.format(
        "SELECT 1 FROM %s WHERE guid = %d AND reward_level = %d",
        REWARDS_TABLE, player:GetGUIDLow(), rewardLevel))
    return q ~= nil
end

local function Grant(player, rewardLevel)
    CharDBQuery(string.format(
        "REPLACE INTO %s (guid, reward_level, granted_at) VALUES (%d, %d, %d)",
        REWARDS_TABLE, player:GetGUIDLow(), rewardLevel, os.time()))
end

local function GiveItems(player, items)
    for _, it in ipairs(items) do
        player:AddItem(it[1], it[2])
    end
end

-- ============================================================
-- Хендлер достижения уровня
-- ============================================================

local function OnLevelUp(event, player, oldLevel)
    if not player then return end
    local newLevel = player:GetLevel()
    if newLevel >= MAX_LEVEL then return end

    local ru = (L(player, "ru", "en") == "ru")

    -- Welcome reward (уровень 2)
    if newLevel == WELCOME_LEVEL and not AlreadyGranted(player, WELCOME_LEVEL) then
        Grant(player, WELCOME_LEVEL)
        player:AddItem(WELCOME_ITEM, 1)
        GiveItems(player, WELCOME_SUPPLIES)
        if ru then
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                "Орден Рассвета приветствует ваши первые шаги: «Паёк Ордена» и припасы — в вашей сумке.|r")
        else
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                "The Order of Dawn salutes your first steps: an 'Order's Ration' and supplies await in your bags.|r")
        end
        return
    end

    -- Level-up reward (каждые 5 уровней)
    if newLevel % LEVEL_STEP == 0 and not AlreadyGranted(player, newLevel) then
        Grant(player, newLevel)
        player:AddItem(BAG_ITEM, 1)
        GiveItems(player, BAG_REWARDS)
        if ru then
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                "За верную службу — «Сумка Эха» с наградой! (уровень " .. newLevel .. ")|r")
        else
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                "For faithful service — an 'Echo Bag' with rewards! (level " .. newLevel .. ")|r")
        end
    end
end

RegisterPlayerEvent(12, OnLevelUp)  -- PLAYER_EVENT_ON_LEVEL_UP = 12

print("[EchoOfTheVoid] 06_WaloriaRewards.lua загружен (награды за уровни, Waloria-подход).")
