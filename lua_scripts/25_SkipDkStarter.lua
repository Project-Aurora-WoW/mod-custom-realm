-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 25_SkipDkStarter.lua
-- Назначение: пропуск стартовой зоны Рыцаря Смерти (адаптация
-- eluna-scripts/Quality of life stuff/npc_mission_dk v2.lua,
-- автор оригинала — суба-редакция eluna-scripts). НПС 70177
-- «Вестник Забвения» (0024) за Жетоны Эха-Cost пропускает
-- стартовую цепочку DK: выдаёт все награды цепочки, экипирует
-- финальный сет 58-ур., телепортирует в столицу фракции.
--
-- Отличия от оригинала:
--   - оригинал вешался на НПС 25462 (Король-лич) с регистрацией
--     без спавна; тут отдельный НПС 70177 в реестре;
--   - обучение бесплатно в оригинале → цена REG.tier_b.skipdk.price
--     (Сдаётся Жетоном Эха 70005; проверка ДО применения);
--   - doQuest в оригинале возвращал (reward and status==REWARDED)
--     только при выданной награде — экипировка привязывалась к
--     флагу; у нас применяет forceEquip при complete+rewarded;
--   - forceEquip в оригинале имел потенциальный уничтожитель
--     предмета (RemoveItem wore + AddItem(entry) при полной сумке);
--     у нас безопасный порядок: проверить наличие, не пересоздавать;
--   - getFreeBagSlots: точный подсчёт свободных слотов (как оригинал);
--   - GM-only опция убрана (все могут, но платно).
-- Требуется модуль mod-ale (ALE). Спеллы/предметы — стоковые 3.3.5a.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order

local CFG = REG.tier_b and REG.tier_b.skipdk
if not CFG or not CFG.enabled then
    print("[EchoOfTheVoid] 25_SkipDkStarter.lua загружен, но выключен (REG.tier_b.skipdk.enabled = false).")
    return
end

local NPC_SKIP = CFG.npc
local TOKEN_ITEM = REG.meta.token_item  -- Жетон Эха (70005)
local TOKEN_COST = CFG.token_cost
local TARGET_LEVEL = CFG.target_level    -- 58

-- Статусы квестов (Eluna)
local QS_NONE = 0
local QS_COMPLETE = 1
local QS_INCOMPLETE = 3
local QS_FAILED = 5
local QS_REWARDED = 6

local RACE_HUMAN = 1
local RACE_ORC = 2
local RACE_DWARF = 3
local RACE_NIGHTELF = 4
local RACE_UNDEAD = 5
local RACE_TAUREN = 6
local RACE_GNOME = 7
local RACE_TROLL = 8
local RACE_BLOODELF = 10
local RACE_DRAENEI = 11

-- Расовые квесты «Особый сюрприз» (фракционный финал цепочки)
local RACE_QUEST = {
    [RACE_HUMAN]      = 12742,
    [RACE_ORC]        = 12748,
    [RACE_DWARF]      = 12744,
    [RACE_NIGHTELF]   = 12743,
    [RACE_UNDEAD]     = 12750,
    [RACE_TAUREN]     = 12739,
    [RACE_GNOME]      = 12745,
    [RACE_TROLL]      = 12749,
    [RACE_BLOODELF]   = 12747,
    [RACE_DRAENEI]    = 12746,
}

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        hello = "The Void's whispers are heavy on fresh Death Knights. Skip the trials for a price?",
        option = "Skip the Death Knight starter questline (" .. TOKEN_COST .. " Echo Tokens)",
        cancel = "Nevermind",
        done = "The trials are complete. Welcome to the world at level " .. TARGET_LEVEL .. ".",
        no_tokens = "Not enough Echo Tokens.",
        need_slots = "You need at least 21 free bag slots.",
        low_level = "This service is for Death Knights (class 6).",
    },
    ru = {
        hello = "Шёпот Пустоты тяжек над новыми Рыцарями Смерти. Пропустить испытания — за плату?",
        option = "Пропустить стартовую цепочку Рыцаря Смерти (" .. TOKEN_COST .. " Жетонов Эха)",
        cancel = "Ничего не нужно",
        done = "Испытания пройдены. Добро пожаловать в мир на уровне " .. TARGET_LEVEL .. ".",
        no_tokens = "Недостаточно Жетонов Эха.",
        need_slots = "Нужно как минимум 21 свободный слот в сумке.",
        low_level = "Услуга только для Рыцарей Смерти (класс 6).",
    },
}

local function L10n(player)
    return (player:GetSession():GetSessionDbcLocale() == 8) and L.ru or L.en
end

-- ============================================================
-- Прогресс квестов
-- ============================================================
-- Выдать/завершить/наградить квест; true — награда получена.
local function doQuest(player, id)
    local reward = false
    local st = player:GetQuestStatus(id)
    if st == QS_FAILED then
        player:RemoveQuest(id)
    elseif st == QS_NONE then
        player:AddQuest(id)
    end
    st = player:GetQuestStatus(id)
    if st == QS_INCOMPLETE then
        player:CompleteQuest(id)
    elseif st == QS_COMPLETE then
        reward = true
        player:RewardQuest(id)
    end
    return reward
end

local function forceEquip(player, slot, itemId)
    local cur = player:GetEquippedItemBySlot(slot)
    if cur and cur:GetEntry() == itemId then
        return -- уже надето
    end
    local item = player:GetItemByEntry(itemId)
    if item then
        player:EquipItem(item, slot)
    else
        -- нет в инвентаре: добавить и надеть (безопасно, с учётом места)
        player:EquipItem(itemId, slot)
    end
end

local function getFreeBagSlots(player)
    local free = 0
    for i = 23, 38 do -- рюкзак (BACKPACK_SLOT_ITEM_START..END)
        if not player:GetItemByPos(255, i) then free = free + 1 end
    end
    for i = 19, 22 do -- надетые сумки
        local bag = player:GetItemByPos(255, i)
        if bag then
            for x = 0, bag:GetBagSize() - 1 do
                if not player:GetItemByPos(i, x) then free = free + 1 end
            end
        end
    end
    return free
end

-- ============================================================
-- Сам пропуск (последовательность квестов DK-ссылки; из оригинала)
-- ============================================================
local function skipDKStarter(player)
    -- Слот 0..18; предметы-награды финальной цепочки DK-стартера
    local function eq(slot, item) forceEquip(player, slot, item) end

    -- Первая цепочка (руны)
    doQuest(player, 12593)
    doQuest(player, 12619)
    doQuest(player, 12842)
    doQuest(player, 12848)
    doQuest(player, 12636)
    doQuest(player, 12641)
    if doQuest(player, 12657) then eq(1, 38662) end
    doQuest(player, 12850)
    doQuest(player, 12670)
    if doQuest(player, 12678) then eq(10, 38671) end

    -- Вторая цепочка (скакун)
    doQuest(player, 12680)
    if doQuest(player, 12687) then eq(17, 39208) end

    -- Ещё квесты
    if doQuest(player, 12679) then
        eq(14, 39320)
        if not player:GetItemByEntry(39322) then player:AddItem(39322) end
        if not player:GetItemByEntry(38664) then player:AddItem(38664) end
    end
    doQuest(player, 12733)

    -- Третья цепочка
    doQuest(player, 12697)
    if doQuest(player, 12698) then eq(12, 38674) end
    doQuest(player, 12700)
    if doQuest(player, 12701) then eq(8, 38666) end
    if doQuest(player, 12706) then eq(6, 38669) end
    doQuest(player, 12714)
    doQuest(player, 12715)
    doQuest(player, 12719)
    if doQuest(player, 12720) then eq(11, 38672) end

    -- Следующие
    if doQuest(player, 12722) then eq(7, 38670) end
    if doQuest(player, 12716) then eq(5, 38668) end
    doQuest(player, 12717)
    doQuest(player, 12723)
    if doQuest(player, 12724) then eq(9, 38667) end

    -- Четвёртая цепочка
    doQuest(player, 12725)
    if doQuest(player, 12727) then eq(4, 38665) end
    doQuest(player, 12728)

    -- Расовая часть
    local rq = RACE_QUEST[player:GetRace()]
    if rq then doQuest(player, rq) end
    if doQuest(player, 12751) then eq(13, 38675) end

    -- Пятая цепочка
    doQuest(player, 12754)
    doQuest(player, 12755)
    doQuest(player, 12756)
    if doQuest(player, 12757) then eq(2, 38663) end

    -- Шестая цепочка
    doQuest(player, 12778)
    if doQuest(player, 12779) then eq(0, 38661) end
    doQuest(player, 12800)

    -- Финальная цепочка
    if doQuest(player, 12801) then
        eq(15, 38632)
        if not player:GetItemByEntry(38633) then player:AddItem(38633) end
    end
    doQuest(player, 13165)
    doQuest(player, 13166)

    -- Финал: телепорт в столицу фракции + камни дома
    if player:GetTeam() == 0 then -- Альянс
        doQuest(player, 13188)
        player:Teleport(0, -8833.37, 628.62, 94.00, 1.06) -- Штормград
    else
        doQuest(player, 13189)
        player:Teleport(1, 1569.59, -4397.63, 16.06, 0.54) -- Оргриммар
    end

    player:AddItem(6948) -- Камень возвращения
    if player:GetLevel() < TARGET_LEVEL then
        player:SetLevel(TARGET_LEVEL)
    end
    player:SaveToDB()
end

-- ============================================================
-- Gossip НПС 70177
-- ============================================================
local function OnHello(event, player, creature)
    if creature:GetEntry() ~= NPC_SKIP then return end
    local t = L10n(player)
    player:SendBroadcastMessage(TAG .. " «" .. t.hello .. "»")
    if player:GetClass() == 6 then
        player:GossipMenuAddItem(0, t.option, 0, 1)
    else
        player:GossipMenuAddItem(0, t.low_level, 0, 2)
    end
    player:GossipMenuAddItem(0, t.cancel, 0, 2)
    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    local t = L10n(player)
    if intid == 2 then
        player:GossipComplete()
        return
    end
    if intid ~= 1 or player:GetClass() ~= 6 then
        player:GossipComplete()
        return
    end

    if getFreeBagSlots(player) < 21 then
        player:SendBroadcastMessage(TAG .. " " .. t.need_slots)
        player:GossipComplete()
        return
    end
    if not player:HasItem(TOKEN_ITEM, TOKEN_COST) then
        player:SendBroadcastMessage(TAG .. " " .. t.no_tokens)
        player:GossipComplete()
        return
    end

    player:RemoveItem(TOKEN_ITEM, TOKEN_COST)
    skipDKStarter(player)
    player:SendBroadcastMessage(TAG .. " " .. t.done)
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_SKIP, 1, OnHello)
RegisterCreatureGossipEvent(NPC_SKIP, 2, OnSelect)

print(string.format(
    "[EchoOfTheVoid] 25_SkipDkStarter.lua загружен (пропуск DK-стартера НПС %d).",
    NPC_SKIP))