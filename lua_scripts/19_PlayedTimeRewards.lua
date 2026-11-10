-- ============================================================
-- 19_PlayedTimeRewards.lua — награды за наигранное время
-- Референс: public-scripts/PlayedTime_RewardSystem (JadaDev,
-- версия Artamedes с кэшем; C++ → порт на ALE).
--
-- Механика: при логине сверяем наигранное время персонажа с таблицей
-- realm_played_time_rewards (acore_characters, 0021) и выдаём
-- недополученные награды (Жетоны Эха + золото). Идемпотентность —
-- realm_played_time_rewards_claimed (PK guid+reward_id, REPLACE).
--
-- Отличия от оригинала:
--   1. Lua вместо C++ (без правки ядра — конвенция реалма).
--   2. Награды реалма: Жетон Эха (70005) + золото (вместо item+gold
--      оригинала); дублируется сообщение в личку на языке клиента.
--   3. Выдача — через CampaignManager.GrantTokens если доступен
--      (единый журнал), иначе напрямую AddItem.
--   4. Guard: отсутствие таблиц не роняет скрипт.
-- ============================================================

local TAG = "|cff9b59b6[Эхо Пустоты]|r"

local REWARDS = {}          -- { {id, played_time, tokens, gold, msg_ru, msg_en}, ... }
local CLAIMED = {}          -- {[guid] = {[reward_id] = true}}

-- Жетон Эха (entry из реестра — валюта реалма)
local TOKEN_ITEM = 70005

local function LoadRewards()
    REWARDS = {}
    CLAIMED = {}

    local q = CharDBQuery("SELECT id, played_time, reward_tokens, reward_gold, message_ru, message_en FROM realm_played_time_rewards ORDER BY played_time ASC")
    if q then
        repeat
            table.insert(REWARDS, {
                id = q:GetUInt32(0),
                time = q:GetUInt32(1),
                tokens = q:GetUInt32(2),
                gold = q:GetUInt32(3),
                msg_ru = q:GetString(4),
                msg_en = q:GetString(5),
            })
        until not q:NextRow()
    end

    local q2 = CharDBQuery("SELECT guid, reward_id FROM realm_played_time_rewards_claimed")
    if q2 then
        repeat
            local guid = q2:GetUInt32(0)
            CLAIMED[guid] = CLAIMED[guid] or {}
            CLAIMED[guid][q2:GetUInt32(1)] = true
        until not q2:NextRow()
    end

    print("[EchoOfTheVoid] 19_PlayedTimeRewards: загружено наград: " .. #REWARDS)
end

local function GiveReward(player, reward)
    local isRu = player:GetSession():GetSessionDbcLocale() == 8
    local guid = player:GetGUIDLow()

    -- Жетоны Эха: через менеджер кампаний (журнал), если доступен
    local tokensGiven = false
    if reward.tokens > 0 then
        local M = AzerothEchoManager
        if M and M.GrantTokens then
            M.GrantTokens(player, reward.tokens, "played_time:" .. reward.id)
            tokensGiven = true
        else
            tokensGiven = player:AddItem(TOKEN_ITEM, reward.tokens)
        end
        if not tokensGiven then
            -- Сумки полны — письмо (fallback Artamedes-версии)
            player:SendItemRetrievalMail({ { TOKEN_ITEM, reward.tokens } })
        end
    end

    if reward.gold > 0 then
        player:ModifyMoney(reward.gold)
    end

    -- Учёт + сообщение
    CharDBExecute("REPLACE INTO realm_played_time_rewards_claimed (guid, reward_id) VALUES (" .. guid .. ", " .. reward.id .. ")")
    CLAIMED[guid] = CLAIMED[guid] or {}
    CLAIMED[guid][reward.id] = true

    local msg = isRu and reward.msg_ru or reward.msg_en
    if msg ~= "" then
        player:SendBroadcastMessage(TAG .. " " .. msg)
    end
end

local function OnLogin(event, player)
    if #REWARDS == 0 then
        return
    end

    local guid = player:GetGUIDLow()
    local played = player:GetTotalPlayedTime() -- секунды

    for _, reward in ipairs(REWARDS) do
        if played >= reward.time then
            local claimed = CLAIMED[guid] and CLAIMED[guid][reward.id]
            if not claimed then
                GiveReward(player, reward)
            end
        else
            break -- отсортировано по времени — дальше порогов не будет
        end
    end
end

LoadRewards()
RegisterPlayerEvent(3, OnLogin) -- PLAYER_EVENT_ON_LOGIN

print("[EchoOfTheVoid] 19_PlayedTimeRewards.lua загружен (награды за наигранное время).")
