-- ============================================================
-- 34_VipSystem.lua — VIP-система реалма «Эхо Пустоты»
--
-- Референс-идеи: BlackWolfsDen/Eluna-Grumboz_VIP_System-Complete
-- Адаптация (совместимые фичи, без конфликтов):
--   • VIP-ранг хранится в acore_characters.realm_vip (НЕ auth.account);
--   • валюта/доступы — команды, без MG (Magic Gold);
--   • фичи: #vip (статус), #vipbuff (баффы по рангу), #vipself (revive вне БГ),
--            #viprepair (бесплатный ремонт по рангу);
--   • автобафф на логине (ON_LOGIN) при активном VIP.
-- Требует: таблица realm_vip (миграция 0035 → acore_characters).
-- ============================================================

local CFG = {
    MAX_RANK       = 10,                 -- макс. VIP-ранг (как в референсе)
    -- Баффы по рангу (spellId: [minRank..maxRank]) — свет/сила, пример
    BUFFS          = {
        { spell = 5007, min = 1, max = 3 },   -- Thorns
        { spell = 48161, min = 4, max = 6 },  -- Power Word: Fortitude
        { spell = 48469, min = 7, max = 10 }, -- Mark of the Wild (пример)
    },
    REPAIR_MIN_RANK= 3,                  -- с какого ранга доступен #viprepair
    SELF_MIN_RANK  = 5,                  -- с какого ранга доступен #vipself (revive)
}

local TBL = "realm_vip"

-- ---- Локализация ----
local L = {
    status      = { "Твой VIP-уровень: |cff00ff00%d|r/%d%s.", "Your VIP rank: |cff00ff00%d|r/%d%s." },
    none        = { "У тебя нет VIP-статуса. Купи его в магазине.", "You have no VIP status. Buy it in the store." },
    exp         = { " (истекает)", " (expires)" },
    help        = { "#vip — статус | #vipbuff — баффы | #vipself — revive вне БГ | #viprepair — ремонт.", "#vip — status | #vipbuff — buffs | #vipself — revive outside BG | #viprepair — repair." },
    needRank    = { "Требуется VIP-ранг |cffffff00%d|r.", "Requires VIP rank |cffffff00%d|r." },
    buffs       = { "VIP-баффы применены!", "VIP buffs applied!" },
    noBuffs     = { "Нет баффов для твоего ранга.", "No buffs for your rank." },
    revived     = { "VIP-воскрешение применено.", "VIP resurrection applied." },
    notDead     = { "Ты не мёртв.", "You are not dead." },
    inBg        = { "Нельзя использовать в поле боя/арене.", "Cannot use in battleground/arena." },
    repaired    = { "VIP-ремонт выполнен (бесплатно).", "VIP repair done (free)." },
    noVip       = { "Нет прав на VIP-команду (ранг 0).", "No VIP access (rank 0)." },
}

local function IsRu(player)
    local ok, loc = pcall(function() return player:GetSession():GetSessionDbcLocale() end)
    return (ok and loc == 8) or false
end
local function line(t, player)
    return t[IsRu(player) and 1 or 2]
end

-- ---- Доступ к VIP-рангу (безопасно: pcall, если таблицы нет) ----
local function GetVipRank(player)
    local ok, q = pcall(CharDBQuery, string.format(
        "SELECT vip_rank FROM %s WHERE account_id = %d", TBL, player:GetAccountId()))
    if ok and q then
        return q:GetUInt32(0) or 0
    end
    return 0
end

-- ---- Автобафф на логине ----
local function OnLogin(event, player)
    local rank = GetVipRank(player)
    if rank <= 0 then return end
    local t = line(L, player)
    for _, b in ipairs(CFG.BUFFS) do
        if rank >= b.min and rank <= b.max and player:HasSpell(b.spell) == false then
            -- CastSpell на себя (triggered) — безопасно
            player:AddAura(b.spell, player)
        end
    end
    player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. string.format(t.status, rank, CFG.MAX_RANK, ""))
end
RegisterPlayerEvent(3, OnLogin)

-- ---- Команды #vip* ----
local function OnChat(event, player, msg)
    if not player then return end
    local m = msg or ""
    if m:sub(1, 1) ~= "#" then return end
    local cmd = m:match("^#(%S+)")
    if not cmd then return end
    local c = cmd:lower()

    local t = line(L, player)
    local rank = GetVipRank(player)

    -- #vip — статус
    if c == "vip" then
        if rank <= 0 then
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.none)
        else
            local exp = ""
            -- проверка expiry опционально (у нас бессрочно по умолчанию)
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. string.format(t.status, rank, CFG.MAX_RANK, exp))
            player:SendBroadcastMessage(t.help)
        end
        return false
    end

    -- #vipbuff — баффы по рангу
    if c == "vipbuff" then
        if rank <= 0 then player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.noVip); return false end
        local applied = false
        for _, b in ipairs(CFG.BUFFS) do
            if rank >= b.min and rank <= b.max then
                player:AddAura(b.spell, player)
                applied = true
            end
        end
        player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. (applied and t.buffs or t.noBuffs))
        return false
    end

    -- #vipself — revive вне БГ
    if c == "vipself" then
        if rank < CFG.SELF_MIN_RANK then
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. string.format(t.needRank, CFG.SELF_MIN_RANK))
            return false
        end
        if player:InBattleground() or player:InArena() then
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.inBg)
            return false
        end
        local isDead = player:IsDead()
        if not isDead then
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.notDead)
            return false
        end
        player:ResurrectPlayer(1.0, false)
        player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.revived)
        return false
    end

    -- #viprepair — бесплатный ремонт
    if c == "viprepair" then
        if rank < CFG.REPAIR_MIN_RANK then
            player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. string.format(t.needRank, CFG.REPAIR_MIN_RANK))
            return false
        end
        -- DurabilityRepairAll(takeCost=0, discountMod=0, guildBank=false) — бесплатный ремонт
        player:DurabilityRepairAll(0, 0, 0)
        player:SendBroadcastMessage("|cff00ccff[VIP]|r " .. t.repaired)
        return false
    end

    return false
end
RegisterPlayerEvent(18, OnChat)

print("[EchoOfTheVoid] 34_VipSystem.lua загружен (VIP-система; таблица realm_vip, миграция 0035).")