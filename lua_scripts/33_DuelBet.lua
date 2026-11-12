-- ============================================================
-- 33_DuelBet.lua — Ставки на дуэли (Duel Bet)
--
-- Референс: zyggy123/mod-duel-bet (AGPL-3.0).
-- Порт на ALE (mod-ale) под реалм «Эхо Пустоты»:
--   • команды через PLAYER_EVENT_ON_CHAT (18): префикс "#duelbet"
--     (#duelbet <amount> / #duelbet cancel / #duelbet stats);
--   • GetData/SetData (RAM) — из ALE-расширения ObjectVariables.ext;
--   • Escrow в БД (acore_characters.duel_bets) + mail-возврат (SendMail);
--   • сообщения ru/en (DbcLocale 8 = ruRU);
--   • вход-валидация: лимиты, кулдаун, выбор цели, баланс золота.
--
-- Требует: таблицы duel_bets и duel_bet_stats (миграция 0034 → acore_characters).
-- ============================================================

-- ---- Конфиг (менять здесь) ----
local CFG = {
    MIN_BET_GOLD       = 1,        -- мин ставка (золото)
    MAX_BET_GOLD       = 100000,   -- макс ставка (золото)
    COOLDOWN_SECONDS   = 10,       -- кулдаун между вызовами #duelbet
    MENU_ID            = 59321,    -- gossip-menu id для PlayerGossip
}

-- ---- Локализация ----
local L = {
    help      = { "Используй |cff00ff00#duelbet <золото>|r — вызвать на дуэль с целью, |cff00ff00#duelbet cancel|r — отменить, |cff00ff00#duelbet stats|r — статистика.", "Use |cff00ff00#duelbet <gold>|r to challenge your target, |cff00ff00#duelbet cancel|r to cancel, |cff00ff00#duelbet stats|r for stats." },
    usageAmt  = { "Использование: #duelbet <золото> (или cancel / stats).", "Usage: #duelbet <gold> (or cancel / stats)." },
    noTarget  = { "Выбери другого игрока чтобы поставить.", "You must select another player to bet with." },
    cupid     = { "У одного из вас уже есть активная ставка!", "One of you already has an active or pending bet!" },
    noGold    = { "У тебя недостаточно золота.", "You do not have enough gold." },
    tgtGold   = { "%s не имеет достаточно золота.", "%s does not have enough gold." },
    cooldown  = { "Подожди %d сек.", "Please wait %d seconds." },
    invite    = { "Вызвал(а) %s на дуэль за %d золота.", "Challenged %s for %d gold." },
    inviteRecv= { "%s вызвал(а) тебя на дуэль за %d золота!", "%s challenged you for %d gold!" },
    accNone   = { "Нет активной ставки для отмены.", "No active or pending bet to cancel." },
    accInProg = { "Нельзя отменить ставку, пока идёт дуэль!", "You cannot cancel a bet while a duel is in progress!" },
    cancl     = { "Ставка отменена.", "Bet cancelled." },
    noBet     = { "Ставка устарела или недействительна.", "This bet has expired or is invalid." },
    decl      = { "Ты отклонил(а) ставку.", "You declined the bet." },
    tgtNoGold = { "У тебя недостаточно золота (как у отвечающего).", "You don't have enough gold (as opponent)." },
    lock      = { "Ставка принята! Оба залочили %d золота. Начинайте дуэль!", "Bet accepted! Both locked %d gold. Start the duel!" },
    started   = { "Дуэль началась! Твои %d золота залочены.", "Duel started! Your %d gold is locked in." },
    won       = { "Ты победил(а)! Получаешь %d золота.", "You won! You receive %d gold." },
    lost      = { "Ты проиграл(а) %d золота.", "You lost %d gold." },
    interr    = { "Дуэль прервана — ставка возвращена.", "Duel interrupted — bet refunded." },
    refund    = { "Ставка отменена (%s). Твои %d золота возвращены.", "The bet was cancelled (%s). Your %d gold was refunded." },
    mailBody  = { "Твоя ставка на дуэль была отменена: %s. %d золота возвращены тебе на почту.", "Your duel bet was cancelled: %s. %d gold has been safely refunded to your mailbox." },
    mailSubj  = { "Купюра Duel Bet", "Duel Bet Refund" },
    stats     = { "Статистика -> Матчи: %d | Победы: %d | Прибыль: %d золота", "Stats -> Matches: %d | Wins: %d | Net Profit: %d Gold" },
    noStats   = { "Ты ещё не играл(а) денежных дуэлей.", "You haven't played any money duels yet." },
}

-- локаль
local function IsRu(player)
    local loc = player:GetSession() and player:GetSession():GetSessionDbcLocale()
    return (loc == 8)
end
local function line(t, ru) return t[ru and 1 or 2] end

local function ToCopper(g) return g * 10000 end

local function SendMsg(player, msg)
    if player then player:SendBroadcastMessage("|cff00ccff[Duel Bet]|r " .. msg) end
end

-- SafeRefund: если игрок онлайн в мире — вернуть золото сразу; иначе — на почту.
local function SafeRefund(guidLow, copperAmount, reason, forceMail)
    local ru
    local player = GetPlayerByGUID(guidLow)
    if player and player:IsInWorld() and not forceMail then
        ru = IsRu(player)
        player:ModifyMoney(copperAmount)
        SendMsg(player, string.format(line(L.refund, ru), reason, copperAmount / 10000))
        player:SetData("DuelBet_ID", nil)
        player:SetData("DuelBet_Amount", nil)
    else
        -- SendMail(subject, text, receiverGUIDLow, sender?, stationary?, delay?, money?, cod?)
        if player then ru = IsRu(player) end
        SendMail(line(L.mailSubj, ru or false),
                 string.format(line(L.mailBody, ru or false), reason, copperAmount / 10000),
                 guidLow, 0, 0, 0, copperAmount, 0)
        if player then
            SendMsg(player, "Ставка отменена. Ты выходишь — золото отправлено на почту.")
        end
    end
end

-- ==========================================
-- 1. КОМАНДА: #duelbet
-- ==========================================
local function OnChat(event, player, msg)
    if not player then return end
    local m = msg or ""
    if m:sub(1, 1) ~= "#" then return end
    local cmd, arg = m:match("^#(%S+)%s*(.*)")
    if not cmd or cmd:lower() ~= "duelbet" then return end

    local ru = IsRu(player)
    local pGuid = player:GetGUIDLow()

    -- STATS
    if arg == "stats" then
        local q = CharDBQuery("SELECT total_duels, total_won, total_profit FROM duel_bet_stats WHERE guid = " .. pGuid)
        if q then
            SendMsg(player, string.format(line(L.stats, ru), q:GetUInt32(0), q:GetUInt32(1), q:GetInt32(2) / 10000))
        else
            SendMsg(player, line(L.noStats, ru))
        end
        return false
    end

    -- CANCEL
    if arg == "cancel" then
        local q = CharDBQuery("SELECT id, player1_guid, player2_guid, amount, status FROM duel_bets WHERE player1_guid = " .. pGuid .. " OR player2_guid = " .. pGuid)
        if not q then
            SendMsg(player, line(L.accNone, ru))
            return false
        end
        local betId, p1, p2, amt, status = q:GetUInt32(0), q:GetUInt32(1), q:GetUInt32(2), q:GetUInt32(3), q:GetUInt8(4)
        if status == 2 then
            SendMsg(player, line(L.accInProg, ru))
            return false
        end
        CharDBExecute("DELETE FROM duel_bets WHERE id = " .. betId)
        if status == 0 then
            SafeRefund(p1, amt, "cancelled by challenger", false)
            local target = GetPlayerByGUID(p2)
            if target then target:GossipComplete(); SendMsg(target, line(L.cancl, IsRu(target))) end
        elseif status == 1 then
            SafeRefund(p1, amt, "cancelled manually", false)
            SafeRefund(p2, amt, "cancelled manually", false)
        end
        SendMsg(player, line(L.cancl, ru))
        return false
    end

    -- INITIATE
    local playerName = player:GetName()

    local playerCooldown = player:GetData("DuelBetCooldown")
    if playerCooldown and playerCooldown > os.time() then
        SendMsg(player, string.format(line(L.cooldown, ru), playerCooldown - os.time()))
        return false
    end

    local amount = tonumber(arg)
    if not amount or amount < CFG.MIN_BET_GOLD or amount > CFG.MAX_BET_GOLD then
        SendMsg(player, line(L.usageAmt, ru))
        return false
    end

    local target = player:GetSelection()
    if not target or target:GetTypeId() ~= 4 or target == player then
        SendMsg(player, line(L.noTarget, ru))
        return false
    end

    local tGuid = target:GetGUIDLow()
    local qCheck = CharDBQuery("SELECT id FROM duel_bets WHERE player1_guid = " .. pGuid .. " OR player2_guid = " .. pGuid .. " OR player1_guid = " .. tGuid .. " OR player2_guid = " .. tGuid)
    if qCheck then
        SendMsg(player, line(L.cupid, ru))
        return false
    end

    local copperAmount = ToCopper(amount)
    if player:GetCoinage() < copperAmount then SendMsg(player, line(L.noGold, ru)); return false end
    if target:GetCoinage() < copperAmount then SendMsg(player, string.format(line(L.tgtGold, ru), target:GetName())); return false end

    player:SetData("DuelBetCooldown", os.time() + CFG.COOLDOWN_SECONDS)
    player:ModifyMoney(-copperAmount)
    CharDBExecute("INSERT INTO duel_bets (player1_guid, player2_guid, amount, status) VALUES (" .. pGuid .. ", " .. tGuid .. ", " .. copperAmount .. ", 0)")

    SendMsg(player, string.format(line(L.invite, ru), target:GetName(), amount))
    SendMsg(target, string.format(line(L.inviteRecv, IsRu(target)), playerName, amount))

    target:GossipClearMenu()
    target:GossipMenuAddItem(0, string.format("Accept Duel Bet (%d gold)", amount), 0, 1, false, string.format("Accept and lock in %d gold?", amount))
    target:GossipMenuAddItem(0, "Decline", 0, 2)
    target:GossipSendMenu(1, target, CFG.MENU_ID)

    return false
end
RegisterPlayerEvent(18, OnChat)   -- PLAYER_EVENT_ON_CHAT

-- ==========================================
-- 2. GOSSIP SELECT (принятие/отклонение)
-- ==========================================
local function OnGossipSelect(event, player, object, sender, intid, code)
    local ru = IsRu(player)
    local tGuid = player:GetGUIDLow()
    local q = CharDBQuery("SELECT id, player1_guid, amount FROM duel_bets WHERE player2_guid = " .. tGuid .. " AND status = 0")

    if not q then
        SendMsg(player, line(L.noBet, ru)); player:GossipComplete(); return
    end

    local betId, pGuid, copperAmount = q:GetUInt32(0), q:GetUInt32(1), q:GetUInt32(2)

    -- DECLINE
    if intid == 2 then
        CharDBExecute("DELETE FROM duel_bets WHERE id = " .. betId)
        SafeRefund(pGuid, copperAmount, "declined by opponent", false)
        SendMsg(player, line(L.decl, ru)); player:GossipComplete(); return
    end

    -- ACCEPT
    if intid == 1 then
        if player:GetCoinage() < copperAmount then
            CharDBExecute("DELETE FROM duel_bets WHERE id = " .. betId)
            SafeRefund(pGuid, copperAmount, "opponent didn't have enough gold", false)
            SendMsg(player, line(L.tgtNoGold, ru)); player:GossipComplete(); return
        end

        player:ModifyMoney(-copperAmount)
        CharDBExecute("UPDATE duel_bets SET status = 1 WHERE id = " .. betId)

        -- RAM-кэш: сохранить детали ставки на время дуэли (без SQL в бою)
        player:SetData("DuelBet_ID", betId)
        player:SetData("DuelBet_Amount", copperAmount)

        local challenger = GetPlayerByGUID(pGuid)
        if challenger then
            challenger:SetData("DuelBet_ID", betId)
            challenger:SetData("DuelBet_Amount", copperAmount)
            SendMsg(challenger, string.format(line(L.lock, IsRu(challenger)), copperAmount / 10000))
        end

        SendMsg(player, string.format(line(L.lock, ru), copperAmount / 10000))
        player:GossipComplete()
    end
end
RegisterPlayerGossipEvent(CFG.MENU_ID, 2, OnGossipSelect)   -- GOSSIP_EVENT_ON_SELECT

-- ==========================================
-- 3. DUEL START
-- ==========================================
local function OnDuelStart(event, player1, player2)
    local betId1 = player1:GetData("DuelBet_ID")
    local betId2 = player2:GetData("DuelBet_ID")

    if betId1 and betId1 == betId2 then
        CharDBExecute("UPDATE duel_bets SET status = 2 WHERE id = " .. betId1)
        local amountGold = (player1:GetData("DuelBet_Amount") or 0) / 10000
        SendMsg(player1, string.format(line(L.started, IsRu(player1)), amountGold))
        SendMsg(player2, string.format(line(L.started, IsRu(player2)), amountGold))
    end
end
RegisterPlayerEvent(10, OnDuelStart)   -- PLAYER_EVENT_ON_DUEL_START

-- ==========================================
-- 4. DUEL END
-- ==========================================
local function OnDuelEnd(event, winner, loser, type)
    if not winner or not loser then return end

    local betId = winner:GetData("DuelBet_ID")
    if betId and betId == loser:GetData("DuelBet_ID") then
        local amountCopper = winner:GetData("DuelBet_Amount") or 0
        local totalPrize = amountCopper * 2

        CharDBExecute("DELETE FROM duel_bets WHERE id = " .. betId)

        -- DUEL_WON
        if type == 1 then
            local wGuid, lGuid = winner:GetGUIDLow(), loser:GetGUIDLow()
            winner:ModifyMoney(totalPrize)
            SendMsg(winner, string.format(line(L.won, IsRu(winner)), totalPrize / 10000))
            SendMsg(loser, string.format(line(L.lost, IsRu(loser)), amountCopper / 10000))

            CharDBExecute("INSERT INTO duel_bet_stats (guid, total_duels, total_won, total_profit) VALUES (" .. wGuid .. ", 1, 1, " .. amountCopper .. ") ON DUPLICATE KEY UPDATE total_duels = total_duels + 1, total_won = total_won + 1, total_profit = total_profit + " .. amountCopper)
            CharDBExecute("INSERT INTO duel_bet_stats (guid, total_duels, total_won, total_profit) VALUES (" .. lGuid .. ", 1, 0, -" .. amountCopper .. ") ON DUPLICATE KEY UPDATE total_duels = total_duels + 1, total_profit = total_profit - " .. amountCopper)
        else
            SafeRefund(winner:GetGUIDLow(), amountCopper, "duel interrupted", false)
            SafeRefund(loser:GetGUIDLow(), amountCopper, "duel interrupted", false)
        end

        winner:SetData("DuelBet_ID", nil)
        winner:SetData("DuelBet_Amount", nil)
        loser:SetData("DuelBet_ID", nil)
        loser:SetData("DuelBet_Amount", nil)
    end
end
RegisterPlayerEvent(11, OnDuelEnd)   -- PLAYER_EVENT_ON_DUEL_END

-- ==========================================
-- 5. LOGOUT / CRASH RECOVERY
-- ==========================================
local function OnPlayerLogout(event, player)
    local guid = player:GetGUIDLow()
    local q = CharDBQuery("SELECT id, player1_guid, player2_guid, amount, status FROM duel_bets WHERE player1_guid = " .. guid .. " OR player2_guid = " .. guid)

    if q then
        repeat
            local betId, p1, p2, amount, status = q:GetUInt32(0), q:GetUInt32(1), q:GetUInt32(2), q:GetUInt32(3), q:GetUInt8(4)
            CharDBExecute("DELETE FROM duel_bets WHERE id = " .. betId)

            if status == 0 then
                SafeRefund(p1, amount, "player logged out", (p1 == guid))
            elseif status >= 1 then
                SafeRefund(p1, amount, "player logged out (abandoned)", (p1 == guid))
                SafeRefund(p2, amount, "player logged out (abandoned)", (p2 == guid))
            end
        until not q:NextRow()
    end
end
RegisterPlayerEvent(4, OnPlayerLogout)   -- PLAYER_EVENT_ON_LOGOUT

print("[EchoOfTheVoid] 33_DuelBet.lua загружен (ставки на дуэли; escrow acore_characters.duel_bets).")