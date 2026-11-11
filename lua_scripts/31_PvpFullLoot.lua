-- ============================================================
-- 31_PvpFullLoot.lua — Full-Loot PvP («добыча войны»)
--
-- Референс: Youpeoples/Ultimate-Full-Loot-Pvp (MIT).
-- Адаптация под реалм «Эхо Пустоты»:
--   • команда .pvpfull и GM-команды идут через PLAYER_EVENT_ON_CHAT (18),
--     т.к. PLAYER_EVENT_ON_COMMAND (42) в ALE-wotlk отсутствует;
--   • MMR (ObjectVariables GetData/SetData) по умолчанию ВЫКЛЮЧЕН —
--     не подтверждён в ALE, как и наш Parangon (см. 29_Parangon.lua);
--   • сундук и таблицы НЕ создаются в рантайме — миграция 0032;
--   • сообщения локализованы ru/en (DbcLocale 8 = ruRU).
--
-- Механика: при PvP-килле в открытом мире предметы и золото жертвы
-- (по фильтрам CFG) выпадают в FFA-сундуки вокруг трупа. Анти-фарм уже
-- встроен (window/max kills, level-diff, зоны-блоклисты, AFK, spirit healer).
--
-- Требует: сундук gameobject (миграция 0032), entry в CFG.CHEST_ENTRY.
-- ============================================================

-- ---- Конфиг (менять здесь) ----
local CFG = {
    ENABLE_MOD               = true,          -- вкл/выкл систему

    -- Команды
    NOTIFY_PLAYER_OF_COMMAND = true,          -- приветствие на логине
    ALLOW_PLAYER_COMMAND     = true,          -- .pvpfull для всех (.pvpfull /.pvpfull risk)

    -- Фракция/локализация
    RU_RU                    = true,          -- резерв: если клиент ru (проверка ниже)

    -- Зона/карта фильтры ({} = разрешено всё)
    MAP_ALLOWLIST            = {},
    MAP_BLOCKLIST            = {},
    ZONE_ALLOWLIST           = {},
    ZONE_BLOCKLIST           = { [4197] = true },  -- Озеро Ледяных Оков
    AREA_ALLOWLIST           = {},
    AREA_BLOCKLIST           = { [350] = true },   -- Чилстрийская база (пример)

    -- Уровневые гейты
    MIN_LEVEL                = 1,
    MAX_LEVEL                = 80,
    MIN_LEVEL_DIFF           = 0,
    MAX_LEVEL_DIFF           = 4,

    -- Что просматривать у жертвы
    INCLUDE_EQUIPPED         = true,
    INCLUDE_BACKPACK         = true,
    INCLUDE_BAGS             = true,
    INCLUDE_BANK_ITEMS       = false,

    -- Фильтры предметов
    ITEM_DROP_PERCENT        = 100,
    IGNORE_BOP               = false,
    IGNORE_CONJURED          = false,
    IGNORE_CONSUMABLES       = false,
    IGNORE_ENCHANTED_EQUIPPED= true,
    IGNORE_HEIRLOOMS         = true,
    IGNORE_KEYS              = true,
    IGNORE_NON_TRADABLE_ITEMS= true,
    IGNORE_PROFESSION_BAG_SLOTS = true,
    IGNORE_QUEST_ITEMS       = true,
    IGNORE_REAGENTS          = false,
    IGNORE_SOULBOUND         = false,
    IGNORE_TRADABLE_ITEMS    = false,
    IGNORE_UNIQUE_EQUIPPED   = false,
    IGNORE_QUALITY = {
        [1] = false, [2] = false, [3] = false, [4] = false, [5] = true,
    },
    IGNORE_EQUIPPED_SLOTS = {
        [0] = false, [1] = false, [2] = false, [3] = false, [4] = false,
        [5] = false, [6] = false, [7] = false, [8] = false, [9] = false,
        [10] = false, [11] = false, [12] = false, [13] = false, [14] = false,
        [15] = false, [16] = false, [17] = false, [18] = false,
    },

    -- Золото
    GOLD_CAP_PER_KILL        = 25000000,      -- 2500 gold максимум (медь)
    GOLD_PERCENT_MIN         = 100,
    GOLD_PERCENT_MAX         = 100,
    SPLIT_GOLD_BETWEEN_CHESTS = true,

    -- Пороги
    IGNORE_VENDOR_VALUE_BELOW  = 0,
    IGNORE_ITEMLEVEL_BELOW     = 0,
    IGNORE_REQUIREDLEVEL_BELOW = 0,
    IGNORE_STACK_SIZE_ABOVE    = 0,

    -- Явные allow/deny
    CUSTOM_ALLOW_IDS         = {},
    CUSTOM_IGNORE_IDS        = { [6948] = true, [5976] = true },  -- очаг/табард гильдии
    CUSTOM_IGNORE_CLASSES    = {},

    IGNORE_VICTIM_PLAYER_CLASS = {},
    IGNORE_VICTIM_PLAYER_RACES = {},
    IGNORE_KILLER_PLAYER_CLASS = {},
    IGNORE_KILLER_PLAYER_RACES = {},

    -- Сундук
    CHEST_ENTRY              = 700020,        -- создаётся миграцией 0032
    DESPAWN_SEC              = 60,
    CREATE_DEFAULT_CHEST     = false,         -- НЕ создаём в рантайме (миграция)
    RANDOM_CHEST_ORIENTATION = false,
    CHEST_STACK_STYLE        = "RADIUS",
    STACK_HORIZONTAL_SPACING = 1,
    STACK_VERTICAL_OFFSET    = 1,

    -- Контекстные исключения
    IGNORE_AFK_VICTIM        = false,
    IGNORE_AURA_ON_KILLER    = {},
    IGNORE_AURA_ON_VICTIM    = {},
    IGNORE_ARENA             = true,
    IGNORE_BATTLEGROUND      = true,
    IGNORE_CAPITALS          = true,
    IGNORE_IF_KILLER_DRUNK   = false,
    IGNORE_IF_VICTIM_DRUNK   = false,
    IGNORE_VICTIM_ALLIANCE   = false,
    IGNORE_VICTIM_HORDE      = false,
    IGNORE_NEUTRAL_CITIES    = true,
    IGNORE_RESS_SICKNESS     = true,
    IGNORE_SUICIDE           = false,
    IGNORE_SPIRIT_HEALER_RANGE = true,
    SPIRIT_HEALER_RANGE      = 20,

    -- Анти-фарм
    ENABLE_KILL_FARM_PROTECTION = true,
    KILL_FARM_WINDOW_SEC        = 900,
    KILL_FARM_MAX_KILLS         = 3,

    -- MMR: ВЫКЛЮЧЕН (зависит от ObjectVariables GetData/SetData —
    -- не подтверждено в ALE; как в 29_Parangon). Включить осознанно.
    MMR_ENABLED              = false,

    -- Webhook: ВЫКЛЮЧЕН (внешний, требует curl/os.execute — см. референс)
    ENABLE_WEBHOOK           = false,
    WEBHOOK_URLS             = {},

    DEBUG                    = false,
}

-- ---- Локализация ----
local L = {
    active      = { "|cffff0000Full-Loot PvP|r активен на этом реалме.", "|cffff0000Full-Loot PvP|r is active on this realm." },
    help        = { "Используй |cff00ff00.pvpfull|r — правила зоны, |cff00ff00.pvpfull risk|r — что рискуешь.", "Type |cff00ff00.pvpfull|r for zone rules, |cff00ff00.pvpfull risk|r for your risk." },
    atRisk      = { "Твои вещи |cffff0000ПОД УГРОЗОЙ|r!", "Your possessions |cffff0000ARE|r at risk!" },
    notRisk     = { "Твои вещи |cff00ff00в безопасности|r.", "Your possessions |cff00ff00ARE NOT|r at risk." },
    noItems     = { "Нет предметов, которые можно потерять.", "No items currently eligible for PvP drop." },
    eligible    = { "Подходящих предметов: |cffffff00%d|r", "Eligible Items: |cffffff00%d|r" },
    gmOnly      = { "[Full-Loot] Только для GM.", "[Full-Loot] GM-only command." },
    lootGold    = { "Ты подобрал(а) %s из сундука!", "You looted %s from the spoils chest!" },
    farmPunish  = { "Недостаточно лута — фарм.", "No loot – farming detected." },
}

local function line(t, ru)
    return t[ru and 1 or 2]
end
local function IsRu(player)
    local loc = player:GetSession() and player:GetSession():GetSessionDbcLocale()
    return (loc == 8)
end

-- ---- Логика (адаптация референса, без MMR/webhook/рантайм-БД) ----
local m_floor, m_max, m_random, m_ceil, m_pi, m_cos, m_sin, m_min =
      math.floor, math.max, math.random, math.ceil, math.pi, math.cos, math.sin, math.min

local MapName = {}
local function getAreaNameOf(id)
    local n = GetAreaName and GetAreaName(id)
    if n and n ~= "" then return n end
    local q = WorldDBQuery("SELECT `area_name` FROM `areatable_dbc` WHERE `id` = " .. id)
    if q then return q:GetString(0) end
    return tostring(id)
end

-- Фильтры CFG-кэш (зона:область)
local CachedCFG = {}
local function GetCFG(areaId, zoneId)
    local key = zoneId .. ":" .. areaId
    if CachedCFG[key] then return CachedCFG[key] end
    local cfg = {}
    for k, v in pairs(CFG) do cfg[k] = v end
    CachedCFG[key] = cfg
    return cfg
end

local LootStore, ChestGold = {}, {}   -- [chestGUID] = {...} / pending gold
local MAX_CHEST_ITEMS = 16
local SPIRIT_HEALER_IDS = { [6491] = true, [29259] = true, [32537] = true }

-- anti-farm
local KillFarm = {}
local function isFarmed(killer, victim, cfg)
    local kg, vg = killer:GetGUIDLow(), victim:GetGUIDLow()
    local now = os.time()
    KillFarm[kg] = KillFarm[kg] or {}
    local rec = KillFarm[kg][vg] or { cnt = 0, first = now }
    if now - rec.first > cfg.KILL_FARM_WINDOW_SEC then
        rec.cnt, rec.first = 0, now
    end
    rec.cnt = rec.cnt + 1
    KillFarm[kg][vg] = rec
    if rec.cnt > cfg.KILL_FARM_MAX_KILLS then
        killer:SendBroadcastMessage("|cffff0000[Full-Loot]|r " .. cfg.KILL_FARM_PUNISH_MSG)
        return true
    end
    return false
end

local function fmtCoins(c)
    local g = m_floor(c / 10000); local s = m_floor(c / 100) % 100; local co = c % 100
    local t = {}; if g > 0 then t[#t+1] = g .. "g" end
    if s > 0 then t[#t+1] = s .. "s" end
    if co > 0 or #t == 0 then t[#t+1] = co .. "c" end
    return table.concat(t, " ")
end

-- loot cycle для chest (добавляем лут при смене состояния)
local function OnLootStateChange(event, go, state)
    local list = LootStore[go:GetGUIDLow()]
    if not list or state == 3 then
        if list and state == 3 then LootStore[go:GetGUIDLow()] = nil end
        return
    end
    if state ~= 1 then
        for _, d in ipairs(list) do go:AddLoot(d.entry, d.count) end
        go:SetLootState(1)
    end
end
RegisterGameObjectEvent(CFG.CHEST_ENTRY, 9, OnLootStateChange)

local CAPITALS = { [1637]=true,[1497]=true,[1638]=true,[1519]=true,[1537]=true,[1657]=true }
local NEUTRAL  = { [2255]=true,[35]=true,[976]=true,[2361]=true,[392]=true,[3425]=true,[2268]=true,[1446]=true,[3712]=true,[3786]=true,[3565]=true,[3649]=true,[3958]=true,[4418]=true,[4501]=true,[4152]=true,[3988]=true,[4113]=true,[4161]=true,[4312]=true }

local function ModIsActiveHere(victim, cfg)
    local mapId = victim:GetMapId(); local zoneId = victim:GetZoneId(); local areaId = victim:GetAreaId()
    if not cfg.ENABLE_MOD then return false end
    if cfg.IGNORE_CAPITALS and CAPITALS[areaId] then return false end
    if cfg.IGNORE_NEUTRAL_CITIES and NEUTRAL[areaId] then return false end
    if cfg.MAP_BLOCKLIST[mapId] then return false end
    if cfg.ZONE_BLOCKLIST[zoneId] then return false end
    if cfg.AREA_BLOCKLIST[areaId] then return false end
    if next(cfg.MAP_ALLOWLIST) and not cfg.MAP_ALLOWLIST[mapId] then return false end
    if next(cfg.ZONE_ALLOWLIST) and not cfg.ZONE_ALLOWLIST[zoneId] then return false end
    if next(cfg.AREA_ALLOWLIST) and not cfg.AREA_ALLOWLIST[areaId] then return false end
    return true
end

local function link(it)
    local linkStr = it.GetItemLink and it:GetItemLink() or ""
    local nm = linkStr:match("%[(.-)%]") or "item"
    return string.format("|cffffffff|Hitem:%d|h[%s]|h|r", it:GetEntry(), nm)
end

local function IsNearSpiritHealer(plr, dist)
    for _, cr in pairs(plr:GetCreaturesInRange(dist or 20)) do
        if SPIRIT_HEALER_IDS[cr:GetEntry()] then return true end
    end
    return false
end

local function isEnchanted(it)
    if not it.GetEnchantmentId then return false end
    for slot = 0, 15 do
        local ok, id = pcall(it.GetEnchantmentId, it, slot)
        if ok and id and id > 0 then return true end
    end
    return false
end

local function ShouldDropItem(it, owner, bagSlot, cfg)
    if not it then return false end
    local entry = it:GetEntry()
    local tpl = (it.GetTemplate and it:GetTemplate()) or nil
    local flags = it.GetFlags and it:GetFlags() or (tpl and tpl.GetFlags and tpl:GetFlags() or 0)
    local class = it.GetClass and it:GetClass() or (tpl and tpl.GetClass and tpl:GetClass() or 0)
    local subClass = it.GetSubClass and it:GetSubClass() or (tpl and tpl.GetSubClass and tpl:GetSubClass() or 0)
    local quality = it.GetQuality and it:GetQuality() or (tpl and tpl.GetQuality and tpl:GetQuality() or 0)
    local sellPrice = it.GetSellPrice and it:GetSellPrice() or (tpl and tpl.GetSellPrice and tpl:GetSellPrice() or 0)
    local ilvl = it.GetItemLevel and it:GetItemLevel() or (tpl and tpl.GetItemLevel and tpl:GetItemLevel() or 0)
    local reqLvl = it.GetRequiredLevel and it:GetRequiredLevel() or (tpl and tpl.GetRequiredLevel and tpl:GetRequiredLevel() or 0)
    local tradable = it.CanBeTraded and it:CanBeTraded() or false

    if cfg.CUSTOM_ALLOW_IDS[entry] then return true end
    if cfg.CUSTOM_IGNORE_IDS[entry] then return false end
    if cfg.IGNORE_CONJURED and it:IsConjuredConsumable() then return false end
    if cfg.IGNORE_SOULBOUND and it:IsSoulBound() then return false end
    if cfg.IGNORE_QUEST_ITEMS and tpl and tpl.GetBonding then
        local b = tpl:GetBonding(); if b == 4 or b == 5 then return false end
    end
    if cfg.IGNORE_CONSUMABLES and class == 0 then return false end
    if cfg.IGNORE_REAGENTS and (class == 5 or class == 9) then return false end
    if cfg.IGNORE_KEYS and class == 13 then return false end
    if cfg.IGNORE_HEIRLOOMS and quality == 7 then return false end
    if cfg.IGNORE_UNIQUE_EQUIPPED and tpl and tpl.IsUniqueEquipped and tpl:IsUniqueEquipped() then return false end
    if cfg.IGNORE_ENCHANTED_EQUIPPED and isEnchanted(it) then return false end
    if cfg.IGNORE_TRADABLE_ITEMS and tradable then return false end
    if cfg.IGNORE_NON_TRADABLE_ITEMS and not tradable then return false end
    if cfg.IGNORE_QUALITY[quality] then return false end
    if cfg.IGNORE_BOP and tpl and tpl.GetBonding and tpl:GetBonding() == 1 then return false end
    if cfg.IGNORE_VENDOR_VALUE_BELOW > 0 and sellPrice < cfg.IGNORE_VENDOR_VALUE_BELOW then return false end
    if cfg.IGNORE_ITEMLEVEL_BELOW > 0 and ilvl < cfg.IGNORE_ITEMLEVEL_BELOW then return false end
    if cfg.IGNORE_REQUIREDLEVEL_BELOW > 0 and reqLvl < cfg.IGNORE_REQUIREDLEVEL_BELOW then return false end
    if cfg.IGNORE_STACK_SIZE_ABOVE > 0 and it:GetCount() > cfg.IGNORE_STACK_SIZE_ABOVE then return false end
    if cfg.CUSTOM_IGNORE_CLASSES[tostring(class)] or cfg.CUSTOM_IGNORE_CLASSES[class .. "." .. subClass] then return false end
    return true
end

local function gatherItems(plr, cfg)
    local list = {}
    local function add(it, bagIndex)
        if it and ShouldDropItem(it, plr, bagIndex, cfg) then
            list[#list+1] = { entry = it:GetEntry(), count = it:GetCount(), pretty = link(it) }
        end
    end
    if cfg.INCLUDE_EQUIPPED then
        for slot = 0, 18 do
            if not cfg.IGNORE_EQUIPPED_SLOTS[slot] then add(plr:GetEquippedItemBySlot(slot), nil) end
        end
    end
    if cfg.INCLUDE_BACKPACK then
        for slot = 23, 38 do add(plr:GetItemByPos(255, slot), 0) end
    end
    if cfg.INCLUDE_BAGS then
        for invSlot = 19, 22 do
            local bagItem = plr:GetItemByPos(255, invSlot)
            if bagItem then
                local bagIndex = invSlot - 18
                for slot = 0, bagItem:GetBagSize() - 1 do
                    add(plr:GetItemByPos(invSlot, slot), bagIndex)
                end
            end
        end
    end
    return list
end

local function shuffle(t)
    for i = #t, 2, -1 do local j = m_random(i); t[i], t[j] = t[j], t[i] end
end

local function OnChestUse(event, go, player)
    local gold = ChestGold[go:GetGUIDLow()]
    if gold and gold > 0 then
        player:ModifyMoney(gold)
        ChestGold[go:GetGUIDLow()] = nil
        player:SendAreaTriggerMessage(string.format(line(L.lootGold, IsRu(player)), fmtCoins(gold)))
    end
end
RegisterGameObjectEvent(CFG.CHEST_ENTRY, 14, OnChestUse)

local function getChestPositions(baseX, baseY, baseZ, baseO, totalChests, cfg)
    local positions = {}
    local style = (cfg.CHEST_STACK_STYLE or "RADIUS"):upper()
    if style == "VERTICAL" then
        for i = 1, totalChests do
            positions[#positions+1] = { x = baseX, y = baseY, z = baseZ + (i-1) * cfg.STACK_VERTICAL_OFFSET }
        end
    elseif style == "LINE" then
        local cosO, sinO = m_cos(baseO), m_sin(baseO)
        local hs = cfg.STACK_HORIZONTAL_SPACING
        for i = 1, totalChests do
            local d = (i - (totalChests+1)/2) * hs
            positions[#positions+1] = { x = baseX + cosO*d, y = baseY + sinO*d, z = baseZ }
        end
    else
        local radius = 2.5; local step = (2*m_pi)/totalChests
        for i = 1, totalChests do
            local a = step*(i-1)
            positions[#positions+1] = { x = baseX + m_cos(a)*radius, y = baseY + m_sin(a)*radius, z = baseZ }
        end
    end
    return positions
end

local function spawnChests(killer, victim, items, cfg, ru)
    local take = m_max(1, m_floor(#items * cfg.ITEM_DROP_PERCENT / 100 + 0.5))
    local totalChests = m_ceil(take / MAX_CHEST_ITEMS)

    local victimGold = victim:GetCoinage()
    local pct = m_random(cfg.GOLD_PERCENT_MIN, cfg.GOLD_PERCENT_MAX)
    local rawGive = m_floor(victimGold * pct / 100)
    if cfg.GOLD_CAP_PER_KILL > 0 and rawGive > cfg.GOLD_CAP_PER_KILL then rawGive = cfg.GOLD_CAP_PER_KILL end
    if rawGive > 0 then victim:ModifyMoney(-rawGive) end

    local perChest, remainder = 0, 0
    if rawGive > 0 and cfg.SPLIT_GOLD_BETWEEN_CHESTS then
        perChest = m_floor(rawGive / totalChests); remainder = rawGive - perChest*totalChests
    end

    local baseX, baseY, baseZ, baseO = victim:GetX(), victim:GetY(), victim:GetZ(), victim:GetO()
    local pos = getChestPositions(baseX, baseY, baseZ, baseO, totalChests, cfg)
    local idx = 1
    for slotIdx, p in ipairs(pos) do
        local chest = killer:SummonGameObject(cfg.CHEST_ENTRY, p.x, p.y, p.z, baseO, cfg.DESPAWN_SEC)
        if not chest then break end
        local guid = chest:GetGUIDLow()
        LootStore[guid] = {}
        for i = 1, MAX_CHEST_ITEMS do
            if idx > take then break end
            local data = items[idx]; idx = idx + 1
            chest:AddLoot(data.entry, data.count)
            victim:RemoveItem(data.entry, data.count)
            table.insert(LootStore[guid], { entry = data.entry, count = data.count })
        end
        if rawGive > 0 and cfg.SPLIT_GOLD_BETWEEN_CHESTS then
            local goldThis = (slotIdx == 1) and (perChest + remainder) or perChest
            if goldThis > 0 then ChestGold[guid] = goldThis end
        end
        CreateLuaEvent(function() LootStore[guid] = nil; ChestGold[guid] = nil end, (cfg.DESPAWN_SEC+0.5)*1000, 1)
    end
    return rawGive
end

local function OnKillPlayer(event, killer, victim)
    if not killer or not victim or killer == victim then return end
    local areaId, zoneId = victim:GetAreaId(), victim:GetZoneId()
    local cfg = GetCFG(areaId, zoneId)
    if not ModIsActiveHere(victim, cfg) then return end

    local ru = IsRu(killer)
    if cfg.IGNORE_BATTLEGROUND and victim:InBattleground() then return end
    if cfg.IGNORE_ARENA and (killer:InArena() or victim:InArena()) then return end
    if victim:GetLevel() < cfg.MIN_LEVEL or victim:GetLevel() > cfg.MAX_LEVEL then return end
    local diff = m_abs(killer:GetLevel() - victim:GetLevel())
    if diff < cfg.MIN_LEVEL_DIFF or diff > cfg.MAX_LEVEL_DIFF then return end
    if cfg.IGNORE_SUICIDE and killer:GetGUIDLow() == victim:GetGUIDLow() then return end
    if cfg.ENABLE_KILL_FARM_PROTECTION and isFarmed(killer, victim, cfg) then return end
    if cfg.IGNORE_IF_VICTIM_DRUNK and victim:GetDrunkValue() > 0 then return end
    if cfg.IGNORE_IF_KILLER_DRUNK and killer:GetDrunkValue() > 0 then return end
    if cfg.IGNORE_AFK_VICTIM and victim:IsAFK() then return end
    if cfg.IGNORE_RESS_SICKNESS and victim:HasAura(15007) then return end
    if cfg.IGNORE_SPIRIT_HEALER_RANGE and IsNearSpiritHealer(victim, cfg.SPIRIT_HEALER_RANGE) then return end

    local items = gatherItems(victim, cfg)
    if #items == 0 then return end
    shuffle(items)
    spawnChests(killer, victim, items, cfg, ru)
end
RegisterPlayerEvent(6, OnKillPlayer)   -- PLAYER_EVENT_ON_KILL_PLAYER

-- Таймер очистки устаревших сундуков (страховка)
CreateLuaEvent(function()
    for guid in pairs(LootStore) do LootStore[guid] = nil; ChestGold[guid] = nil end
end, 120000, 0)

-- ---- Команды (через PLAYER_EVENT_ON_CHAT = 18, т.к. 42 нет в ALE-wotlk) ----
local function OnChat(event, player, msg)
    if not player then return end
    local m = msg or ""
    if m:sub(1, 1) ~= "." then return end
    local cmd = m:match("^%.(%S*)")
    if cmd ~= "pvpfull" and cmd ~= "pvplootrisk" then return end

    -- GM-команда reload (через .reload ale при необходимости; здесь игнор)
    if cmd == "pvpfull" and (m:lower() == ".pvpfull reload") then
        if not player:IsGM() then player:SendBroadcastMessage(line(L.gmOnly, IsRu(player))); return false end
        ReloadEluna()
        return false
    end

    local ru = IsRu(player)
    local zoneId, areaId = player:GetZoneId(), player:GetAreaId()
    local cfg = GetCFG(areaId, zoneId)
    local active = ModIsActiveHere(player, cfg)

    if cmd == "pvplootrisk" or m:lower() == ".pvpfull risk" then
        if not active then
            player:SendBroadcastMessage("|cffff0000[Full-Loot]|r " .. line(L.notRisk, ru))
            return false
        end
        local inv = gatherItems(player, cfg)
        player:SendBroadcastMessage("|cffffff00[Full-Loot]|r " .. line(L.atRisk, ru))
        if not inv or #inv == 0 then
            player:SendBroadcastMessage(" • " .. line(L.noItems, ru))
        else
            for _, d in ipairs(inv) do player:SendBroadcastMessage("   - " .. d.pretty) end
            player:SendBroadcastMessage(string.format(" • " .. line(L.eligible, ru), #inv))
        end
        return false
    end

    -- .pvpfull (инфо)
    player:SendBroadcastMessage(string.format(
        "|cffffff00[Full-Loot]|r Zone %d active: %s | Area %d active: %s",
        zoneId, active and "|cff00ff00Yes|r" or "|cffff0000No|r",
        areaId, active and "|cff00ff00Yes|r" or "|cffff0000No|r"))
    player:SendBroadcastMessage(" • " .. (active and line(L.atRisk, ru) or line(L.notRisk, ru)))
    return false
end
RegisterPlayerEvent(18, OnChat)

local function OnLogin(event, player)
    if not CFG.ENABLE_MOD then return end
    if not CFG.NOTIFY_PLAYER_OF_COMMAND then return end
    local ru = IsRu(player)
    player:SendBroadcastMessage(line(L.active, ru))
    player:SendBroadcastMessage(line(L.help, ru))
end
RegisterPlayerEvent(3, OnLogin)

print("[EchoOfTheVoid] 31_PvpFullLoot.lua загружен (Full-Loot PvP; сундук " .. CFG.CHEST_ENTRY .. ", MMR/webhook выключены).")