-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 23_WeaponMaster.lua
-- Назначение: мастер оружия (адаптация
-- eluna-scripts/Quality of life stuff/Weapon Master, Cloticc).
-- НПС 70175 «Рунный Оружейник» (Даларан, 0024) за золото учит
-- игрока владению всеми видами оружия, доступными его классу.
-- Отличия от оригинала:
--   - NpcId ноль в оригинале (скрипт не работал) → 70175 в реестре;
--   - обучение бесплатно в оригинале → цена REG.tier_b.weapon.price
--     (по умолчанию 10 зол., снятие в точке применения;
--     исправление двойного/нулевого списания);
--   - проверка оплаты ПЕРЕД обучением (в оригинале списание и
--     обучение не связаны);
--   - при неверной цене/классе — понятное меню, а не "Wrong Class";
--   - обучаем только отсутствующие спеллы (как в оригинале);
--   - локализация ru/en;
--   - guards: существо должно быть 70175 (в оригинале хендлер
--     висел на nil и не регистрировался).
-- Требуется модуль mod-ale (ALE).
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order

local CFG = REG.tier_b and REG.tier_b.weapon
if not CFG or not CFG.enabled then
    print("[EchoOfTheVoid] 23_WeaponMaster.lua загружен, но выключен (REG.tier_b.weapon.enabled = false).")
    return
end

local NPC_WEAPON = CFG.npc
local PRICE = CFG.price          -- медь

-- Наборы оружия по классу (из оригинала eluna-scripts; ID — спеллы
-- владения 3.3.5a). CLASS_DEATH_KNIGHT = 6.
local CLASS_WARRIOR = 1
local CLASS_PALADIN = 2
local CLASS_HUNTER = 3
local CLASS_ROGUE = 4
local CLASS_PRIEST = 5
local CLASS_DEATH_KNIGHT = 6
local CLASS_SHAMAN = 7
local CLASS_MAGE = 8
local CLASS_WARLOCK = 9
local CLASS_DRUID = 11

local SKILLS = {
    [CLASS_WARRIOR]       = {202,199,197,227,200,201,198,196,266,15590,1180,5011,264},
    [CLASS_PALADIN]       = {202,199,197,200,201,198,196},
    [CLASS_HUNTER]        = {202,197,227,200,201,196,266,15590,1180,5011,264},
    [CLASS_ROGUE]         = {201,198,196,266,15590,1180,5011,264},
    [CLASS_PRIEST]        = {227,198,1180},
    [CLASS_SHAMAN]        = {199,197,227,198,196,15590,1180},
    [CLASS_MAGE]          = {227,201,1180},
    [CLASS_WARLOCK]       = {227,201,1180},
    [CLASS_DRUID]         = {199,227,200,198,15590,1180},
    [CLASS_DEATH_KNIGHT]  = {202,199,197,200,201,198,196},
}

-- ============================================================
-- Локализация
-- ============================================================
local L = {
    en = {
        hello = "Greetings. For the fee I will teach you every weapon your class can wield.",
        option = "Train all weapons (" .. math.floor(PRICE / 10000) .. " gold)",
        cancel = "Nevermind",
        done = "You have learned all your weapon skills!",
        no_gold = "You do not have enough gold.",
        no_class = "Weapon training is not available for your class on this realm.",
    },
    ru = {
        hello = "Приветствую. За плату я научу тебя всем видам оружия, доступным твоему классу.",
        option = "Обучить всё оружие (" .. math.floor(PRICE / 10000) .. " зол.)",
        cancel = "Ничего не нужно",
        done = "Ты обучился всем видам оружия своего класса!",
        no_gold = "У тебя недостаточно золота.",
        no_class = "Для твоего класса обучение оружию на этом реалме не предусмотрено.",
    },
}

local function L10n(player)
    return (player:GetSession():GetSessionDbcLocale() == 8) and L.ru or L.en
end

local function OnHello(event, player, creature)
    if creature:GetEntry() ~= NPC_WEAPON then
        return
    end
    local t = L10n(player)
    player:SendBroadcastMessage(TAG .. " «" .. t.hello .. "»")
    player:GossipMenuAddItem(0, t.option, 0, 1)
    player:GossipMenuAddItem(0, t.cancel, 0, 2)
    player:GossipSendMenu(1, creature)
end

local function OnSelect(event, player, creature, sender, intid, code)
    local t = L10n(player)
    if intid == 2 then
        player:GossipComplete()
        return
    end
    if intid ~= 1 then
        player:GossipComplete()
        return
    end

    -- Проверка поддержки класса
    local pc = player:GetClass()
    local list = SKILLS[pc]
    if not list then
        player:SendBroadcastMessage(TAG .. " " .. t.no_class)
        player:GossipComplete()
        return
    end

    -- Оплата строго в точке применения (до обучения)
    if player:GetCoinage() < PRICE then
        player:SendBroadcastMessage(TAG .. " " .. t.no_gold)
        player:GossipComplete()
        return
    end
    player:ModifyMoney(-PRICE)

    for _, sid in ipairs(list) do
        if not player:HasSpell(sid) then
            player:LearnSpell(sid)
        end
    end

    player:SendBroadcastMessage(TAG .. " " .. t.done)
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_WEAPON, 1, OnHello)
RegisterCreatureGossipEvent(NPC_WEAPON, 2, OnSelect)

print(string.format(
    "[EchoOfTheVoid] 23_WeaponMaster.lua загружен (мастер оружия НПС %d).",
    NPC_WEAPON))