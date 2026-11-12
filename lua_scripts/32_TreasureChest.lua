-- ============================================================
-- 32_TreasureChest.lua — Сундуки Пустоты (Solo treasure chests)
--
-- Референс: zyggy123/Treasure-Chest-System (AGPL-3.0). Адаптация
-- под реалм «Эхо Пустоты» («Сундуки Пустоты»):
--   • entry сундука 700021 (миграция 0033), а не 800001 оригинала;
--   • GM-команды прошли через PLAYER_EVENT_ON_CHAT (18);
--   • лор-текст и локализация ru/en (DbcLocale 8 = ruRU);
--   • Eluna-специфика оригинала (GiveLootToPlayer, PerformIngameSpawn,
--     GetAreaName) заменена на ALE-безопасные вызовы.
--
-- Механика: GM создаёт сундук с кастомным лутом и подсказкой; игроки
-- находят и лутают его, в мир уходит анонс находки. Лут/золото/подсказка
-- хранятся в таблицах (миграция 0033), сундук персистентен.
-- ============================================================

local CONFIG = {
    CHEST_ENTRY  = 700021,                       -- сундук (миграция 0033)
    MIN_GM_LEVEL = 3,
    LOOT_TABLE   = "custom_treasure_chest_loot",
    CONFIG_TABLE = "custom_treasure_chest_config",
    SPAWN_TABLE  = "custom_treasure_chest_spawn",

    COLORS = {
        ERROR   = "|cFFFF0000",
        WARNING = "|cFFFFFF00",
        INFO    = "|cFF00FFFF",
        SUCCESS = "|cFF00FF00",
        SYSTEM  = "|cFFFF8000",
        PLAYER  = "|cFFFFFF00",
        ZONE    = "|cFFADD8E6",
        RESET   = "|r",
    },
    PREFIX = { CHAT = "[Сундук Пустоты]", EVENT = "[Сундук Пустоты]" },
}

-- ---- Локализация (ru/en) ----
local L = {
    helpTitle = { "=== Команды Сундука Пустоты ===", "=== Treasure Chest Commands ===" },
    invalidId = { "Неверный ID предмета: %d", "Invalid item ID: %d" },
    added     = { "Добавлено: %s x%d в лут сундука.", "Added %s x%d to the chest loot." },
    live      = { "Изменения применяются сразу — спавн нового сундука обновит лут.", "Changes are live — spawn a new chest to use updated loot." },
    goldSet   = { "GM %s установил золото сундука: %d золота!", "GM %s set treasure chest gold to %d gold!" },
    goldOk    = { "Золото установлено: %d. Перезагрузка не нужна.", "Gold set to %d. No reload needed." },
    cleared   = { "GM %s очистил сундук!", "GM %s cleared the treasure chest!" },
    clearOk   = { "Лут и золото очищены. Перезагрузка не нужна.", "Chest loot and gold cleared. No reload needed." },
    configHdr = { "=== Конфигурация сундука ===", "=== Chest Configuration ===" },
    configEnd = { "=== Конец ===", "=== End ===" },
    noItems   = { "  Не настроено ни одного предмета.", "  No items configured." },
    goldItem  = { "  Золото: %d", "  Gold: %d" },
    hintItem  = { "  Подсказка: %s", "  Hint: %s" },
    emptyChest= { "Нельзя спавнить пустой сундук. Сначала добавь предметы или золото!", "Cannot spawn an empty chest. Add items or gold first!" },
    chestAt   = { "Сундук Пустоты появился в: %s!", "A treasure chest has appeared in %s!" },
    spawned   = { "Сундук создан! (сохранён в мире)", "Chest spawned! (It is now saved in the world)" },
    spawnFail = { "Не удалось создать сундук! Проверьте логи сервера.", "Failed to spawn chest! Check server logs." },
    cleanupOk = { "Очистка завершена! Снято %d активных сундуков и очищена БД.", "Cleanup complete! Despawned %d active chests and cleared DB." },
    hintSaved = { "Подсказка сохранена: %s", "Hint saved: %s" },
    hintShow  = { "[Сундук Пустоты] Подсказка: %s", "[Treasure] Hint: %s" },
    hintLoc   = { "[Сундук Пустоты] Сундук в последний раз видели в: %s", "[Treasure] The treasure was last seen around: %s" },
    usageAdd  = { "Использование: #chest add <itemID> <count>", "Usage: #chest add <itemID> <count>" },
    usageGold = { "Использование: #chest gold <amount>", "Usage: #chest gold <amount>" },
    usageHint = { "Использование: #chest addhint <text>", "Usage: #chest addhint <text>" },
    needGm    = { "Нужна GM-привилегия %d+ для команд сундука.", "You need GM level %d+ to use chest commands." },
    helpLine  = { "#chest hint — подсказка для всех", "#chest hint — hint for everyone" },
    looted    = { "Сундук разграблен! Проверь сумки%s.", "Treasure looted! Check your bags%s." },
    empty     = { "Сундук был пуст...", "The chest was empty..." },
    invFull   = { "Инвентарь полон!", "Inventory full!" },
    found     = { "%s нашёл сундук Пустоты! Повезёт в следующий раз!", "%s found the treasure chest! Better luck next time!" },
}

local function line(t, ru) return t[ru and 1 or 2] end
local function IsRu(player)
    local loc = player:GetSession() and player:GetSession():GetSessionDbcLocale()
    return (loc == 8)
end

local function Color(key, text)
    return (CONFIG.COLORS[key] or "") .. tostring(text) .. CONFIG.COLORS.RESET
end

local function Msg(player, msg, colorKey)
    player:SendBroadcastMessage(Color("SYSTEM", CONFIG.PREFIX.CHAT) .. " " .. Color(colorKey or "INFO", msg))
end
local function World(msg, colorKey)
    SendWorldMessage(Color("SYSTEM", CONFIG.PREFIX.EVENT) .. " " .. Color(colorKey or "INFO", msg))
end

-- Локация (без хрупкого GetAreaName из оригинала — берём через БД)
local function GetZoneAreaName(id)
    local q = WorldDBQuery("SELECT `area_name` FROM `areatable_dbc` WHERE `id` = " .. id)
    if q then return q:GetString(0) end
    return nil
end
local function GetLocationString(player)
    local zoneId, areaId = player:GetZoneId(), player:GetAreaId()
    local zoneName = GetZoneAreaName(zoneId)
    local areaName = (areaId ~= zoneId) and GetZoneAreaName(areaId) or nil
    if zoneName then
        if areaName and areaName ~= zoneName then return zoneName .. " - " .. areaName end
        return zoneName
    end
    return string.format("Map %d / Zone %d", player:GetMapId(), zoneId)
end

-- ---- Config DB helpers ----
local function GetConfig(key)
    local r = WorldDBQuery(string.format("SELECT config_value FROM %s WHERE config_key = '%s' LIMIT 1;", CONFIG.CONFIG_TABLE, key))
    return r and r:GetString(0) or nil
end
local function SetConfig(key, value)
    WorldDBExecute(string.format("UPDATE %s SET config_value = '%s' WHERE config_key = '%s';", CONFIG.CONFIG_TABLE, tostring(value), key))
end

-- ---- GM check ----
local function IsAuthorized(player)
    if not player:IsGM() then return false end
    if player:GetGMRank() < CONFIG.MIN_GM_LEVEL then return false end
    return true
end

-- ---- Commands ----
local function CmdAdd(player, itemEntry, count, ru)
    local q = WorldDBQuery(string.format("SELECT entry, name FROM item_template WHERE entry = %d LIMIT 1;", itemEntry))
    if not q then
        Msg(player, string.format(line(L.invalidId, ru), itemEntry), "ERROR")
        return
    end
    local safeName = (q:GetString(1) or ""):gsub("'", "''")
    WorldDBExecute(string.format([[INSERT INTO %s (item_entry, min_count, max_count, chance, comment) VALUES (%d, %d, %d, 100, '%s');]],
        CONFIG.LOOT_TABLE, itemEntry, count, count, safeName))
    Msg(player, string.format(line(L.added, ru), safeName, count), "SUCCESS")
    Msg(player, line(L.live, ru), "INFO")
end

local function CmdGold(player, amount, ru)
    SetConfig("gold_amount", tostring(amount))
    World(string.format(line(L.goldSet, ru), player:GetName(), amount), "SUCCESS")
    Msg(player, string.format(line(L.goldOk, ru), amount), "SUCCESS")
end

local function CmdClear(player, ru)
    WorldDBExecute("DELETE FROM " .. CONFIG.LOOT_TABLE .. ";")
    SetConfig("gold_amount", "0")
    World(string.format(line(L.cleared, ru), player:GetName()), "WARNING")
    Msg(player, line(L.clearOk, ru), "SUCCESS")
end

local function CmdList(player, ru)
    Msg(player, line(L.configHdr, ru), "INFO")
    local r = WorldDBQuery(string.format([[SELECT item_entry, min_count, max_count, chance, comment FROM %s ORDER BY id;]], CONFIG.LOOT_TABLE))
    if not r then
        Msg(player, line(L.noItems, ru), "WARNING")
    else
        repeat
            Msg(player, string.format("  [%d] %s  x%d-%d  (%.0f%%)", r:GetUInt32(0), r:GetString(4), r:GetUInt32(1), r:GetUInt32(2), r:GetFloat(3)), "INFO")
        until not r:NextRow()
    end
    local gold = tonumber(GetConfig("gold_amount") or "0") or 0
    Msg(player, string.format(line(L.goldItem, ru), gold), "INFO")
    local hint = GetConfig("hint") or ""
    if hint ~= "" then Msg(player, string.format(line(L.hintItem, ru), hint), "INFO") end
    Msg(player, line(L.configEnd, ru), "INFO")
end

local function CmdSpawn(player, ru)
    local lootR = WorldDBQuery(string.format("SELECT COUNT(*) FROM %s;", CONFIG.LOOT_TABLE))
    local lootCount = lootR and lootR:GetUInt32(0) or 0
    local gold = tonumber(GetConfig("gold_amount") or "0") or 0
    if lootCount == 0 and gold == 0 then
        Msg(player, line(L.emptyChest, ru), "ERROR")
        return
    end
    local x, y, z, o = player:GetX(), player:GetY(), player:GetZ(), player:GetO()
    -- Спавн как временный gameobject (сохраняемое не используем: сброс сундука
    -- при рестарте — осознанно, как ивент). Персистентность лута/золота — в таблицах.
    local chest = player:SummonGameObject(CONFIG.CHEST_ENTRY, x, y, z, o, 3600)
    if chest then
        World(string.format(line(L.chestAt, ru), Color("ZONE", GetLocationString(player))), "INFO")
        Msg(player, line(L.spawned, ru), "SUCCESS")
    else
        Msg(player, line(L.spawnFail, ru), "ERROR")
    end
end

local function CmdCleanup(player, ru)
    -- Удаляем из БД (временные спавны в gameobject не пишутся, но на всякий случай)
    WorldDBExecute("DELETE FROM gameobject WHERE id = " .. CONFIG.CHEST_ENTRY .. ";")
    local count = 0
    local gos = player:GetGameObjectsInRange(50000)
    if gos then
        for _, go in ipairs(gos) do
            if go:GetEntry() == CONFIG.CHEST_ENTRY then
                go:RemoveFromWorld()
                count = count + 1
            end
        end
    end
    Msg(player, string.format(line(L.cleanupOk, ru), count), "SUCCESS")
end

local function CmdAddHint(player, text, ru)
    local safe = (text or ""):gsub("'", "''")
    SetConfig("hint", safe)
    Msg(player, string.format(line(L.hintSaved, ru), safe), "SUCCESS")
end

local function CmdHint(player, ru)
    local hint = GetConfig("hint") or ""
    if hint ~= "" then
        player:SendBroadcastMessage(Color("INFO", string.format(line(L.hintShow, ru), hint)))
    else
        player:SendBroadcastMessage(Color("INFO", string.format(line(L.hintLoc, ru), GetLocationString(player))))
    end
end

local HELP = {
    {"#chest spawn",  { "Создать сундук в текущей точке", "Spawns the treasure chest at your location" }},
    {"#chest list",   { "Список лута и золота", "Lists configured loot and gold" }},
    {"#chest cleanup",{ "Удалить все сундуки из мира", "Removes all spawned chests from the world" }},
    {"#chest add <id> <n>", { "Добавить предмет (перезагрузка не нужна)", "Adds item (no reload needed!)" }},
    {"#chest clear",  { "Очистить все предметы и золото", "Clears all items and gold" }},
    {"#chest gold <amount>", { "Установить награду золотом", "Sets gold reward" }},
    {"#chest addhint <text>", { "Установить подсказку для игроков", "Sets a hint for players" }},
    {"#chest hint",   { "Показать подсказку (для всех)", "Shows the hint (available to everyone)" }},
}
local function ShowHelp(player)
    local ru = IsRu(player)
    if player:IsGM() then
        Msg(player, line(L.helpTitle, ru), "INFO")
        for _, row in ipairs(HELP) do
            Msg(player, string.format("  %-28s - %s", row[1], line(row[2], ru)), "INFO")
        end
    else
        player:SendBroadcastMessage(Color("INFO", line(L.helpLine, ru)))
    end
end

-- ---- Chat dispatcher (через PLAYER_EVENT_ON_CHAT = 18) ----
local function OnChat(event, player, msg)
    if not player or not msg then return end
    if msg:sub(1, 1) ~= "#" then return end

    local ru = IsRu(player)
    if msg:match("^#chest%s*$") then
        ShowHelp(player)
        return false
    end
    local cmd, args = msg:match("^#chest%s+(%S+)%s*(.*)")
    if not cmd then return end

    if cmd == "hint" then CmdHint(player, ru); return false end

    if not IsAuthorized(player) then
        Msg(player, string.format(line(L.needGm, ru), CONFIG.MIN_GM_LEVEL), "ERROR")
        return false
    end

    if cmd == "spawn" then CmdSpawn(player, ru)
    elseif cmd == "list" then CmdList(player, ru)
    elseif cmd == "cleanup" then CmdCleanup(player, ru)
    elseif cmd == "add" then
        local id, count = args:match("(%d+)%s+(%d+)")
        if id and count then CmdAdd(player, tonumber(id), tonumber(count), ru)
        else Msg(player, line(L.usageAdd, ru), "WARNING") end
    elseif cmd == "gold" then
        local amount = tonumber(args)
        if amount and amount >= 0 then CmdGold(player, amount, ru)
        else Msg(player, line(L.usageGold, ru), "WARNING") end
    elseif cmd == "clear" then CmdClear(player, ru)
    elseif cmd == "addhint" then
        if args and args ~= "" then CmdAddHint(player, args, ru)
        else Msg(player, line(L.usageHint, ru), "WARNING") end
    else ShowHelp(player) end
    return false
end
RegisterPlayerEvent(18, OnChat)

-- ---- Лут при открытии сундука ----
local chestLooted = {}   -- [GUIDLow] = true, защита от двойного лута

local function GiveLootToPlayer(go, player)
    local ru = IsRu(player)
    local anyReward = false

    local gold = tonumber(GetConfig("gold_amount") or "0") or 0
    if gold > 0 then
        player:ModifyMoney(gold * 10000)
        anyReward = true
    end

    local lootR = WorldDBQuery(string.format("SELECT item_entry, min_count, max_count, chance FROM %s ORDER BY id;", CONFIG.LOOT_TABLE))
    if lootR then
        repeat
            local itemId = lootR:GetUInt32(0)
            local minCount = lootR:GetUInt32(1)
            local maxCount = lootR:GetUInt32(2)
            local chance = lootR:GetFloat(3)
            if math.random(0, 100) <= chance then
                local count = (minCount == maxCount) and minCount or math.random(minCount, maxCount)
                if player:AddItem(itemId, count) then
                    anyReward = true
                else
                    Msg(player, line(L.invFull, ru), "ERROR")
                    break
                end
            end
        until not lootR:NextRow()
    end

    if anyReward then
        Msg(player, string.format(line(L.looted, ru), gold > 0 and string.format(" (+%d золото)", gold) or ""), "SUCCESS")
        World(Color("PLAYER", player:GetName()) .. Color("INFO", line(L.found, ru)))
    else
        Msg(player, line(L.empty, ru), "WARNING")
    end

    go:RemoveFromWorld()
end

local function OnChestInteract(event, go, player)
    local guid = go:GetGUIDLow()
    if chestLooted[guid] then return true end
    chestLooted[guid] = true
    GiveLootToPlayer(go, player)
    CreateLuaEvent(function() chestLooted[guid] = nil end, 5000, 1)
    return true
end
RegisterGameObjectEvent(CONFIG.CHEST_ENTRY, 14, OnChestInteract)

print("[EchoOfTheVoid] 32_TreasureChest.lua загружен (Сундуки Пустоты; сундук " .. CONFIG.CHEST_ENTRY .. ").")