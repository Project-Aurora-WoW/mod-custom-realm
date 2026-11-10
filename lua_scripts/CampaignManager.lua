-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- CampaignManager.lua
-- СЛУЖЕБНЫЙ МОДУЛЬ управления кампаниями.
-- Назначение: единая точка управления жизненным циклом кампаний:
--   1. API для скриптов кампаний (гейты, прогресс, награды, жетоны)
--   2. Игрок-команды `.ae ...` — аналоги команд аддона:
--        .ae help | status | tokens | rifts | pvp | events
--   3. GM-команды `.aecampaign ...` — управление кампаниями:
--        .aecampaign list | status <id> [игрок] | set <id> <глава>
--        .aecampaign complete <id> | reset <id|all> | tokens <N>
--   4. Журналирование действий в realm_campaign_log
--      (acore_characters, миграция 0013_campaign_manager.sql)
-- Зависимости: 00_CampaignRegistry.lua, AddonBridge.lua (AE_SendProgress).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order
local VOID_COLOR  = REG.meta.colors.void
local TOKEN_ITEM  = REG.meta.token_item
local BAL = REG.balance
local DB_TABLE = REG.meta.db_table
local LOG_TABLE = "realm_campaign_log"
local MIN_LEVEL = REG.meta.min_level

-- ============================================================
-- Журналирование (realm_campaign_log, acore_characters)
-- ============================================================

--- Записать действие в журнал кампаний.
-- action: start/chapter/complete/reward/reset/tokens/gm_*
local function LogAction(guid, campId, chapter, action, detail)
    CharDBQuery(string.format(
        "INSERT INTO %s (guid, campaign_id, chapter, action, detail) VALUES (%d, %d, %d, '%s', '%s')",
        LOG_TABLE, guid, campId or 0, chapter or 0,
        tostring(action or "unknown"),
        string.sub(tostring(detail or ""), 1, 250)
    ))
end

-- ============================================================
-- Прогресс: чтение/запись (единая точка для всех кампаний)
-- ============================================================

--- Прогресс игрока по кампании: chapter, completed, data.
local function GetProgress(player, campId)
    local q = CharDBQuery(string.format(
        "SELECT chapter, completed, progress_data FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), campId
    ))
    if q then
        return q:GetUInt8(0), q:GetUInt8(1) == 1, q:GetString(2) or ""
    end
    return 0, false, ""
end

--- Сохранить главу/статус кампании (с сохранением progress_data).
local function SetChapter(player, campId, chapter, completed)
    local _, _, data = GetProgress(player, campId)
    CharDBQuery(string.format(
        "REPLACE INTO %s (guid, campaign_id, chapter, completed, progress_data) VALUES (%d, %d, %d, %d, '%s')",
        DB_TABLE, player:GetGUIDLow(), campId, chapter, completed and 1 or 0, data
    ))
end

--- Полный сброс кампании (удаление строки прогресса).
local function ResetCampaign(player, campId)
    CharDBQuery(string.format(
        "DELETE FROM %s WHERE guid = %d AND campaign_id = %d",
        DB_TABLE, player:GetGUIDLow(), campId
    ))
end

-- ============================================================
-- Гейты (единые проверки доступа к кампании)
-- ============================================================

--- Может ли игрок начать кампанию: уровень + требуемый токен.
-- Возвращает true, причина отказа (nil если true).
local function CanStart(player, campId)
    local camp = REG.campaigns[campId]
    if not camp then
        return false, "неизвестная кампания"
    end
    if player:GetLevel() < MIN_LEVEL then
        return false, "требуется " .. MIN_LEVEL .. "-й уровень"
    end
    if camp.required_token and not player:HasItem(camp.required_token) then
        return false, "требуется item " .. camp.required_token .. " (прошлая кампания)"
    end
    return true, nil
end

-- ============================================================
-- Награды (единая точка выдачи)
-- ============================================================

--- Выдать Жетоны Эха с журналированием.
local function GrantTokens(player, amount, reason)
    if amount <= 0 then
        return
    end
    player:AddItem(TOKEN_ITEM, amount)
    player:SendBroadcastMessage(TAG .. " +" .. amount .. " " .. VOID_COLOR .. "Жетон Эха|r" ..
        (reason and (" (" .. reason .. ")") or "") .. ".")
    LogAction(player:GetGUIDLow(), 0, 0, "tokens", (amount) .. " " .. (reason or ""))
end

--- Выдать награды за завершение кампании: предметы реестра почтой + жетоны.
local function GrantCampaignRewards(player, campId)
    local camp = REG.campaigns[campId]
    if not camp or not camp.rewards then
        return
    end

    local delay = 5
    local mailTitle = "Награда: " .. (camp.name or ("Кампания " .. campId))
    local mailBody = "Орден Рассвета благодарит за службу. Кампания «" ..
        (camp.name or campId) .. "» завершена. Награды прилагаются. — Совет Ордена"

    -- Все предметы из rewards.* отправляются почтой
    for _, item in pairs(camp.rewards) do
        SendMail(mailTitle, mailBody, player:GetGUIDLow(), nil, nil, delay, item)
        delay = delay + 5
    end

    -- Жетоны за завершение (баланс реалма)
    local tokens = (BAL and BAL.campaign_completion_tokens) or 0
    if tokens > 0 then
        GrantTokens(player, tokens, "завершение кампании " .. campId)
    end

    LogAction(player:GetGUIDLow(), campId, camp.chapters or 0, "reward",
        "items=" .. #camp.rewards .. ",tokens=" .. tokens)
end

--- Полное завершение кампании: chapter = последняя, completed = 1,
--- награды, журнал, объявление в мир.
local function CompleteCampaign(player, campId, byGM)
    local camp = REG.campaigns[campId]
    if not camp then
        return false, "неизвестная кампания"
    end

    local chapter, completed = GetProgress(player, campId)
    if completed then
        return false, "кампания уже завершена"
    end

    SetChapter(player, campId, camp.chapters or 0, true)
    GrantCampaignRewards(player, campId)

    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. "Кампания «" ..
        (camp.name or campId) .. "» завершена!|r")
    SendWorldMessage(TAG .. " " .. player:GetName() .. " завершил кампанию «" ..
        (camp.name or campId) .. "»!")

    LogAction(player:GetGUIDLow(), campId, camp.chapters or 0,
        byGM and "gm_complete" or "complete", camp.name or "")
    return true, nil
end

-- ============================================================
-- Публичный API модуля (для скриптов кампаний)
-- ============================================================

AzerothEchoManager = {
    GetProgress          = GetProgress,
    SetChapter           = SetChapter,
    ResetCampaign        = ResetCampaign,
    CanStart             = CanStart,
    CompleteCampaign     = CompleteCampaign,
    GrantTokens          = GrantTokens,
    GrantCampaignRewards = GrantCampaignRewards,
    LogAction            = LogAction,
}
local M = AzerothEchoManager

-- ============================================================
-- Игрок-команды `.ae ...` (аналоги команд аддона)
-- ============================================================

local function CmdHelp(player)
    player:SendBroadcastMessage(TAG .. " == Команды Эха Пустоты ==")
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. ".ae status|r — прогресс кампаний (в чат + аддон)")
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. ".ae tokens|r — баланс Жетонов Эха")
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. ".ae rifts|r — карта разломов (как /ae rifts)")
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. ".ae pvp|r — PvP-статистика (откроет вкладку аддона)")
    player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. ".ae events|r — расписание ивентов (вкладка аддона)")
    player:SendBroadcastMessage(TAG .. " Клиент: /ae — панель, /ae rifts — карта разломов.")
end

--- Текстовая сводка прогресса по всем кампаниям + обновление аддона.
local function CmdStatus(player)
    player:SendBroadcastMessage(TAG .. " == Прогресс кампаний ==")
    for campId = 1, #REG.campaigns do
        local camp = REG.campaigns[campId]
        local chapter, completed = GetProgress(player, campId)
        local name = camp.name or ("Кампания " .. campId)
        if completed then
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. name .. "|r — ЗАВЕРШЕНА")
        elseif chapter == 0 then
            player:SendBroadcastMessage(TAG .. " " .. name .. " — не начата")
        else
            player:SendBroadcastMessage(TAG .. " " .. name .. " — глава " ..
                chapter .. "/" .. (camp.chapters or "?"))
        end
    end
    -- Обновить данные в аддоне (все три payload'а)
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

local function CmdTokens(player)
    local count = player:GetItemCount(TOKEN_ITEM)
    player:SendBroadcastMessage(TAG .. " Баланс: " .. VOID_COLOR .. count .. " Жетонов Эха|r" ..
        " (ивенты, PvP-зона; трата — Интендант Ордена, Даларан).")
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

--- Карта разломов: серверный аналог /ae rifts — шлёт команду аддону
--- и дублирует список в чат.
local function CmdRifts(player)
    SendAddonMessage("AECHORIFTS", "show", "WHISPER", player)
    player:SendBroadcastMessage(TAG .. VOID_COLOR .. " Разломы Пустоты:|r")
    player:SendBroadcastMessage(TAG .. " 1. Драконий Погост — эпицентр (осколок Трона) [***]")
    player:SendBroadcastMessage(TAG .. " 2. Зул'Драк — Храм Шёпота (алтари Культа) [**]")
    player:SendBroadcastMessage(TAG .. " 3. Бесплодные земли — перевал Культа [*]")
end

--- PvP: отправить вкладку и статистику (аналог /ae pvp и .aepvp me).
local function CmdPvp(player)
    SendAddonMessage("AECHOUI", "tab:3", "WHISPER", player)
    if AE_SendProgress then
        AE_SendProgress(player)
    end
    player:SendBroadcastMessage(TAG .. " PvP-статистика отправлена. Детали: " ..
        ORDER_COLOR .. ".aepvp me|r, топ: " .. ORDER_COLOR .. ".aepvp top|r.")
end

--- Ивенты: вкладка ивентов в аддоне + статус в чат (аналог /ae events).
local function CmdEvents(player)
    SendAddonMessage("AECHOUI", "tab:2", "WHISPER", player)
    if AE_SendProgress then
        AE_SendProgress(player)
    end
    player:SendBroadcastMessage(TAG .. " Ивенты: Шторм Пустоты (каждые 3 ч), " ..
        "Кровавая Луна Культа (каждые 6 ч). GM: .aeevent status.")
end

-- ============================================================
-- GM-команды `.aecampaign ...`
-- ============================================================

local function IsGM(player)
    local rank = player:GetGmRank and player:GetGmRank() or ""
    return rank ~= "" and rank ~= "player" and rank ~= "0"
end

--- Найти игрока по имени (цель GM-команды) или вернуть самого игрока.
local function ResolveTarget(player, name)
    if name == "" then
        return player
    end
    local target = GetPlayerByName(name)
    return target
end

local function GmList(player)
    player:SendBroadcastMessage(TAG .. " == Реестр кампаний ==")
    for campId, camp in pairs(REG.campaigns) do
        local gate = camp.required_token and ("item " .. camp.required_token) or "—"
        player:SendBroadcastMessage(TAG .. string.format(
            " [%d] %s — глав: %d, вход: %s, награды: %d шт.",
            campId, camp.name or "?", camp.chapters or 0, gate,
            camp.rewards and (function() local n = 0; for _ in pairs(camp.rewards) do n = n + 1 end; return n end)() or 0
        ))
    end
end

local function GmStatus(player, campId, targetName)
    local target = ResolveTarget(player, targetName)
    if not target then
        player:SendBroadcastMessage(TAG .. " Игрок не найден или не в сети.")
        return
    end
    player:SendBroadcastMessage(TAG .. " == Кампания " .. campId .. ": " ..
        target:GetName() .. " ==")
    for _, cid in ipairs({ campId }) do
        local chapter, completed, data = GetProgress(target, cid)
        player:SendBroadcastMessage(TAG .. string.format(
            " глава: %d/%s, завершена: %s, data: %s",
            chapter, (REG.campaigns[cid] and REG.campaigns[cid].chapters) or "?",
            completed and "да" or "нет", data ~= "" and data or "—"
        ))
    end
end

local function GmSet(player, campId, chapter)
    local camp = REG.campaigns[campId]
    if not camp then
        player:SendBroadcastMessage(TAG .. " Неизвестная кампания " .. campId)
        return
    end
    chapter = math.max(0, math.min(chapter, camp.chapters or chapter))
    SetChapter(player, campId, chapter, false)
    player:SendBroadcastMessage(TAG .. " Кампания " .. campId .. ": глава установлена = " .. chapter)
    LogAction(player:GetGUIDLow(), campId, chapter, "gm_set", player:GetName())
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

local function GmComplete(player, campId)
    local ok, why = CompleteCampaign(player, campId, true)
    player:SendBroadcastMessage(TAG .. (ok and (" Кампания " .. campId .. " завершена принудительно.")
        or (" Ошибка: " .. why)))
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

local function GmReset(player, arg)
    if arg == "all" then
        for campId in pairs(REG.campaigns) do
            ResetCampaign(player, campId)
            LogAction(player:GetGUIDLow(), campId, 0, "gm_reset", "all by " .. player:GetName())
        end
        player:SendBroadcastMessage(TAG .. " Прогресс всех кампаний сброшен.")
    else
        local campId = tonumber(arg)
        if not campId or not REG.campaigns[campId] then
            player:SendBroadcastMessage(TAG .. " Укажите ID кампании или 'all'.")
            return
        end
        ResetCampaign(player, campId)
        player:SendBroadcastMessage(TAG .. " Кампания " .. campId .. " сброшена.")
        LogAction(player:GetGUIDLow(), campId, 0, "gm_reset", "by " .. player:GetName())
    end
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

local function GmTokens(player, amount)
    amount = math.max(0, amount)
    GrantTokens(player, amount, "GM")
    if AE_SendProgress then
        AE_SendProgress(player)
    end
end

-- ============================================================
-- Диспетчер чата: .ae и .aecampaign
-- ============================================================

local function OnPlayerChat(event, player, msg, lang, typ)
    local text = string.lower(msg)

    -- ==== Опция источника команд ====
    -- EchoCampaigns.CommandSource (modules/echo-campaigns):
    --   "core" — C++-модуль обрабатывает .ae/.aecampaign, Lua пропускает.
    --   "both" — обрабатывают оба (ответ дублируется, приоритет у первого).
    --   "lua"  — только Lua (по умолчанию, если модуль не установлен).
    local src = (AzerothEchoCampaigns.meta.command_source) or "lua"
    if src == "core" and (text:match("^%.ae") or text:match("^%.aecampaign")) then
        -- Ядро обработает команду через CommandScript; Lua не отвечает.
        return
    end

    -- ==== GM: .aecampaign ====
    if text:match("^%.aecampaign") then
        if not IsGM(player) then
            player:SendBroadcastMessage(TAG .. " Команда доступна только персоналу.")
            return false
        end
        local sub, a1, a2 = string.match(text, "^%.aecampaign%s+(%a+)%s*(%S*)%s*(%S*)")

        if sub == "list" then
            GmList(player)
        elseif sub == "status" then
            local campId = tonumber(a1)
            if not campId or not REG.campaigns[campId] then
                player:SendBroadcastMessage(TAG .. " Формат: .aecampaign status <id> [игрок]")
            else
                GmStatus(player, campId, a2 or "")
            end
        elseif sub == "set" then
            local campId, chapter = tonumber(a1), tonumber(a2)
            if not campId or not chapter then
                player:SendBroadcastMessage(TAG .. " Формат: .aecampaign set <id> <глава>")
            else
                GmSet(player, campId, chapter)
            end
        elseif sub == "complete" then
            local campId = tonumber(a1)
            if not campId then
                player:SendBroadcastMessage(TAG .. " Формат: .aecampaign complete <id>")
            else
                GmComplete(player, campId)
            end
        elseif sub == "reset" then
            if a1 == "" then
                player:SendBroadcastMessage(TAG .. " Формат: .aecampaign reset <id|all>")
            else
                GmReset(player, a1)
            end
        elseif sub == "tokens" then
            local n = tonumber(a1)
            if not n then
                player:SendBroadcastMessage(TAG .. " Формат: .aecampaign tokens <N>")
            else
                GmTokens(player, n)
            end
        else
            player:SendBroadcastMessage(TAG .. " .aecampaign list|status|set|complete|reset|tokens")
        end
        return false
    end

    -- ==== Игрок: .ae ====
    if not text:match("^%.ae") then
        return
    end
    -- Не перехватываем .aeevent/.aepvp (они в других скриптах)
    if text:match("^%.aeevent") or text:match("^%.aepvp") then
        return
    end

    local sub = string.match(text, "^%.ae%s*(%a*)")

    if sub == "help" or sub == "" then
        CmdHelp(player)
    elseif sub == "status" or sub == "progress" then
        CmdStatus(player)
    elseif sub == "tokens" then
        CmdTokens(player)
    elseif sub == "rifts" then
        CmdRifts(player)
    elseif sub == "pvp" then
        CmdPvp(player)
    elseif sub == "events" then
        CmdEvents(player)
    else
        player:SendBroadcastMessage(TAG .. " Неизвестная подкоманда. " .. ORDER_COLOR .. ".ae help|r — список.")
    end
    return false
end

RegisterPlayerEvent(18, OnPlayerChat) -- PLAYER_EVENT_ON_CHAT = 18

print("[EchoOfTheVoid] CampaignManager.lua загружен (API кампаний, .ae*, .aecampaign*, журнал " ..
    LOG_TABLE .. ").")
