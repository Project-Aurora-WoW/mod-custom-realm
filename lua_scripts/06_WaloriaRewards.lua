-- ============================================================
-- 06_WaloriaRewards.lua — Награды за уровни (подход Waloria)
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
-- Единый логгер с кириллицей (extensions/00_EchoLog.ext), часть п.3.
local LOG = EchoLog or print

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
-- Выдача набора: если в сумке есть место — AddItem напрямую,
-- иначе (сумки полны) отправляем набор по почте, чтобы игрок
-- не потерял награду. Отметку о выдаче anti-dupe НЕ трогаем —
-- письмо на почте "доедет" до освобождения места.
-- @player Player
-- @subject string  тема письма
-- @body string     текст письма
-- @items table of { entry, count }
-- ============================================================
local function GiveOrMail(player, subject, body, items)
    local count = 0
    for _, it in ipairs(items) do count = count + 1 end

    if player:GetInventoryFreeSlots() >= count then
        for _, it in ipairs(items) do
            player:AddItem(it[1], it[2])
        end
        return "item"
    else
        -- Сумки полны: отправляем весь набор одной почтой (до 12 предметов).
        local args = { subject, body, player:GetGUIDLow() }
        for _, it in ipairs(items) do
            args[#args + 1] = it[1]
            args[#args + 1] = it[2]
        end
        SendMail(unpack(args))
        return "mail"
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
        local payload = {}
        payload[#payload + 1] = { WELCOME_ITEM, 1 }
        for _, it in ipairs(WELCOME_SUPPLIES) do payload[#payload + 1] = it end
        local via = GiveOrMail(
            player,
            ru and "Паёк Ордена" or "Order's Ration",
            ru and "Орден Рассвета приветствует ваши первые шаги. Награда выслана письмом — в сумке нет места." or
                "The Order of Dawn salutes your first steps. Reward mailed — no bag space.",
            payload)
        local msg = (via == "mail")
            and (ru and "Припасы Ордена отправлены письмом (в сумке нет места)." or "Order supplies mailed (no bag space).")
            or  (ru and "Орден Рассвета приветствует ваши первые шаги: «Паёк Ордена» и припасы — в вашей сумке.|r")
            or  "The Order of Dawn salutes your first steps: an 'Order's Ration' and supplies await in your bags.|r"
        player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. msg)
        return
    end

    -- Level-up reward (каждые 5 уровней)
    if newLevel % LEVEL_STEP == 0 and not AlreadyGranted(player, newLevel) then
        Grant(player, newLevel)
        local payload = {}
        payload[#payload + 1] = { BAG_ITEM, 1 }
        for _, it in ipairs(BAG_REWARDS) do payload[#payload + 1] = it end
        local via = GiveOrMail(
            player,
            ru and "Награда «Сумка Эха»" or "Echo Bag reward",
            ru and "За верную службу (уровень " .. newLevel .. "). Выслано письмом — в сумке нет места." or
                "For faithful service (level " .. newLevel .. "). Mailed — no bag space.",
            payload)
        if ru then
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                ((via == "mail") and ("Награда за уровень " .. newLevel .. " отправлена письмом (сумка полна).|r")
                    or ("За верную службу — «Сумка Эха» с наградой! (уровень " .. newLevel .. ")|r")))
        else
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR ..
                ((via == "mail") and ("Reward for level " .. newLevel .. " mailed (bag full).|r")
                    or ("For faithful service — an 'Echo Bag' with rewards! (level " .. newLevel .. ")|r")))
        end
    end
end

RegisterPlayerEvent(12, OnLevelUp)  -- PLAYER_EVENT_ON_LEVEL_UP = 12

LOG("INFO", "06_WaloriaRewards.lua загружен (награды за уровни, Waloria-подход).")
