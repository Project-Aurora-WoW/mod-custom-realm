-- ============================================================
-- gpt_npc.lua — GPT-НПС (Фаза 4)
--
-- НПС из allowlist (gpt_npc_config.lua) отвечают игроку «живым»
-- текстом от внешнего LLM (OpenAI). Обмен идёт через БД-очередь
-- realm_gpt_queue (acore_characters, миграция 0031), т.к. в ALE
-- (mod-ale) нет HTTP-клиента:
--   • игрок шлёт в /say сообщение рядом с allowlist-НПС;
--   • gpt_npc.lua пишет запрос (status=0) с текстом в локали ru/en;
--   • внешний Python-сервис (service/gpt_npc.py) опрашивает очередь,
--     вызывает OpenAI, пишет ответ (status=1);
--   • gpt_npc.lua на таймере (poll_interval_ms) читает готовые ответы
--     и шлёт игроку шёпот (reply_channel) от имени НПС.
--
-- Анти-спам: rate_limit_seconds на игрока; 1 активный запрос за раз
-- (последующие сбрасываются). Модель/ключ — в Python-сервисе (вне репо).
--
-- НЕ содержит API-ключа. Требует mod-ale (ALE) и таблицу 0031.
-- ============================================================

local AIO = AIO or nil
-- конфиг отдельным файлом (загружается раньше gpt_npc.lua по имени)
local CFG = _G["GPT_NPC_CONFIG"] or {}
if not CFG.enabled then
    print("[EchoOfTheVoid] gpt_npc.lua загружен, но выключен (GPT_NPC_CONFIG.enabled = false).")
    return
end

local TAG = AzerothEchoCampaigns and AzerothEchoCampaigns.meta
    and AzerothEchoCampaigns.meta.tag or "|cff9b59b6[Эхо Пустоты]|r"

local DB_TABLE = CFG.db_table or "realm_gpt_queue"
local RATE_LIMIT_MS = (CFG.rate_limit_seconds or 10) * 1000
local POLL_MS = CFG.poll_interval_ms or 2000
local MAX_PROMPT = CFG.max_prompt_len or 400
local MAX_REPLY = CFG.max_reply_len or 500
local MAX_ACTIVE = CFG.max_active_per_player or 3
local REPLY_CHANNEL = CFG.reply_channel or "WHISPER"

-- последняя отправка на игрока (spam-защита); [guid] = timestamp(ms)
local lastSent = {}

-- ------------------------------------------------------------------
-- Вспомогательные
-- ------------------------------------------------------------------
local function NowMs()
    return GetTime() * 1000
end

local function IsLocaleRu(player)
    -- DbcLocale 8 = ruRU (как в остальных скриптах реалма)
    local loc = player:GetSession() and player:GetSession():GetSessionDbcLocale()
    return (loc == 8)
end

local function Trim(s)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- НПС рядом с игроком, из allowlist (ближайший в радиусе)
local function NearAllowedNpc(player, radius)
    local minDist, best = radius + 1, nil
    local npcs = player:GetCreaturesInRange(radius or 10, 0, 0)
    for _, c in ipairs(npcs or {}) do
        local entry = c:GetEntry()
        if CFG.allowed_npcs and CFG.allowed_npcs[entry] then
            local d = player:GetDistance(c)
            if d < minDist then
                minDist, best = d, entry
            end
        end
    end
    return best
end

local function EscapeSql(s)
    if not s then return "" end
    return (s:gsub("'", "''"):gsub("\\", "\\\\"))
end

-- ------------------------------------------------------------------
-- Запись запроса в очередь
-- ------------------------------------------------------------------
local function PushRequest(player, npcEntry, msg)
    local guid = player:GetGUIDLow()
    local ru = IsLocaleRu(player)
    local promptRu, promptEn = "", ""
    local prompt = Trim(msg):sub(1, MAX_PROMPT)
    if ru then
        promptRu = prompt
    else
        promptEn = prompt
    end
    local locale = ru and 8 or 0

    -- анти-спам + лимит активных
    local now = NowMs()
    if lastSent[guid] and (now - lastSent[guid]) < RATE_LIMIT_MS then
        player:SendBroadcastMessage(TAG .. " Подожди немного перед следующим вопросом.")
        return false
    end

    -- считаем активные запросы игрока (status=0)
    local actQ = CharDBQuery("SELECT COUNT(*) FROM " .. DB_TABLE
        .. " WHERE guid = " .. guid .. " AND status = 0")
    local act = actQ and actQ:GetUInt32(0) or 0
    if act >= MAX_ACTIVE then
        player:SendBroadcastMessage(TAG .. " Слишком много одновременных вопросов.")
        return false
    end

    CharDBExecute("INSERT INTO " .. DB_TABLE
        .. " (guid, npc_entry, prompt_ru, prompt_en, locale, status) VALUES ("
        .. guid .. ", " .. npcEntry
        .. ", '" .. EscapeSql(promptRu) .. "', '" .. EscapeSql(promptEn) .. "', "
        .. locale .. ", 0)")

    lastSent[guid] = now
    return true
end

-- ------------------------------------------------------------------
-- Опрос очереди: доставить готовые ответы игрокам онлайн
-- ------------------------------------------------------------------
local function PollReplies()
    local q = CharDBQuery("SELECT id, guid, npc_entry, reply, locale FROM " .. DB_TABLE
        .. " WHERE status = 1 ORDER BY id ASC LIMIT 20")
    if not q then return end

    -- карта guid-low -> player онлайн (GetPlayerByGUID в ALE не подтверждён;
    -- используем согласованный с остальными скриптами паттерн GetPlayersInWorld)
    local byGuid = {}
    for _, p in ipairs(GetPlayersInWorld() or {}) do
        if p and p:IsInWorld() then byGuid[p:GetGUIDLow()] = p end
    end

    repeat
        local id = q:GetUInt32(0)
        local guid = q:GetUInt32(1)
        local npcEntry = q:GetUInt32(2)
        local reply = q:GetString(3)
        local locale = q:GetUInt32(4)

        local player = byGuid[guid]
        if player then
            local s = Trim(reply):sub(1, MAX_REPLY)
            if s ~= "" then
                -- ALE не умеет слать шёпот «от имени НПС» (player:Whisper шлёт
                -- от самого игрока), поэтому ответ доставляем системным
                -- сообщением с префиксом имени НПС — как остальные скрипты реалма.
                local who = (CFG.allowed_npcs and CFG.allowed_npcs[npcEntry]) or ("НПС " .. npcEntry)
                player:SendBroadcastMessage("|cff8e44ad" .. who .. "|r: " .. s)
            end
        end
        -- помечаем обработанным (независимо от того, онлайн ли игрок)
        CharDBExecute("UPDATE " .. DB_TABLE .. " SET status = 2 WHERE id = " .. id)
    until not q:NextRow()
end

-- ------------------------------------------------------------------
-- Хук чата: игрок что-то написал в /say рядом с allowlist-НПС
-- ------------------------------------------------------------------
local function OnChat(event, player, msg, lang, typ)
    if not player then return end
    if typ ~= 0 and typ ~= 6 then return end  -- 0=SAY, 6=COMMAND(не наш; пустим SAY)
    -- только настоящий текст, не команды (.ae...) и не GM-команды
    local nm = Trim(msg or "")
    if nm == "" or nm:sub(1, 1) == "." or nm:sub(1, 1) == "/" then return end

    local npcEntry = NearAllowedNpc(player, 10)
    if not npcEntry then return end

    PushRequest(player, npcEntry, nm)
    -- вернуть false не будем: игрок видит свой /say как обычно
end

-- ------------------------------------------------------------------
-- Регистрация
-- ------------------------------------------------------------------
RegisterPlayerEvent(18, OnChat) -- PLAYER_EVENT_ON_CHAT (в стиле репо)
CreateLuaEvent(PollReplies, POLL_MS, 0)

print("[EchoOfTheVoid] gpt_npc.lua загружен (GPT-НПС, allowlist из gpt_npc_config.lua).")