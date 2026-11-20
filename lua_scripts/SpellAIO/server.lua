-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- SpellAIO/server.lua  (адаптация из WaloriaOld/scripts/SpellAIO)
--
-- Серверная часть системы выбора кастомных спеллов. Порт на mod-ale:
--   * использует AOI (наш вшитый Rochet2/AIO);
--   * события игрока — номера ALE (совпадают с Eluna):
--       FIRST_LOGIN=30, LOGIN=3, DELETE=2, LEVEL_CHANGE=13, COMMAND=42;
--   * команда GM — .ae spell (заменяет .waloria);
--   * локаль ru/en через L().
-- ============================================================

local AIO = AIO
if not AIO then
    print("[EchoOfTheVoid] SpellAIO/server: AIO не найден — не загружен.")
    return
end

local SpellClass = require("SpellAIO.spellclass").new()

local HANDLER = "SpellAIO"

local MyHandlers = AIO.AddHandlers(HANDLER, {})

local unlearnToggle = {}

local function L(player, key)
    -- Локализация: локализуем ключевые сообщения консоли/чата.
    local loc = player:GetSession():GetSessionDbcLocale()
    local ru = {
        receivedManual = "Вы получили свиток спелла.",
        receivedMail = "Вы получили письмо со свитком спелла.",
        alreadyHigh = "У вас уже максимальное число кастомных спеллов.",
        diffCat = "Выберите категорию.",  -- справочно
        openChoice = "Открыть выбор кастомного спелла.",
        closeGossip = "Закрыть.",
        tomeEmpty = "Свиток Пустоты пуст.",
        tomeLearned = "Вы изучили спелл из Свитка Пустоты.",
    }
    local en = {
        receivedManual = "You have received a spell scroll.",
        receivedMail = "You have received a mail with your spell scroll.",
        alreadyHigh = "You already know the max amount of custom spells.",
        diffCat = "Choose a category.",
        openChoice = "Open the custom spell picker.",
        closeGossip = "Close.",
        tomeEmpty = "The Void Scroll is empty.",
        tomeLearned = "You learned a spell from the Void Scroll.",
    }
    local t = (loc == 8) and ru or en
    return t[key] or ""
end

local function CheckPlayerSpellChoice(player)
    if SpellClass:HasSpellChoices(player) then
        local spells = SpellClass:NextSpellChoice(player)
        AIO.Handle(player, HANDLER, "ShowFrame", spells)
    end
end

local function CheckCategorySelectionChoice(player)
    if SpellClass:HasCategoryChoice(player) then
        AIO.Handle(player, HANDLER, "ShowCategory", SpellClass:GetAvailableCategories(player))
    end
end

local function SaveThenOpen(player)
    SpellClass:SaveCategoryChoice(player)
    CheckCategorySelectionChoice(player)
end

-- Команда GM .ae spell — открыть окно выбора вручную.
local function OnCommand(event, player, command)
    if not player then return true end
    if not player:IsGM() then return true end
    if command == "ae spell" then
        CheckCategorySelectionChoice(player)
        CheckPlayerSpellChoice(player)
        return false
    end
    return true
end
RegisterPlayerEvent(42, OnCommand)

-- Первый вход: показать окно выбора категории/спеллов.
local function OnFirstLogin(event, player)
    SaveThenOpen(player)
end
RegisterPlayerEvent(30, OnFirstLogin)

-- НПС-тренер 70179 «Хранитель Спеллов»: повторно открыть окно выбора.
local TRAINER_ENTRY = 70179
local function OnTrainerGossip(event, player, creature)
    if creature:GetEntry() ~= TRAINER_ENTRY then return true end
    player:GossipMenuAddItem(0, L(player, "openChoice"), 0, 1)
    player:GossipMenuAddItem(4, L(player, "closeGossip"), 0, 2)
    player:GossipSendMenu(1, creature)
    return false
end
RegisterCreatureEvent(TRAINER_ENTRY, 1, OnTrainerGossip)  -- GOSSIP_EVENT_ON_HELLO

local function OnTrainerGossipSelect(event, player, creature, sender, action)
    if creature:GetEntry() ~= TRAINER_ENTRY then return true end
    if action == 1 then
        CheckCategorySelectionChoice(player)
        CheckPlayerSpellChoice(player)
    end
    player:GossipComplete()
    return false
end
RegisterCreatureEvent(TRAINER_ENTRY, 2, OnTrainerGossipSelect)  -- GOSSIP_EVENT_ON_SELECT

-- Каждый вход / смена уровня.
local function OnLogin(event, player)
    CheckCategorySelectionChoice(player)
    CheckPlayerSpellChoice(player)
end
RegisterPlayerEvent(3, OnLogin)

local function OnLevelChange(event, player, oldLevel)
    SpellClass:SaveCategoryChoice(player)
    CheckCategorySelectionChoice(player)
end
RegisterPlayerEvent(13, OnLevelChange)

local function OnDelete(event, characterGUID)
    -- Очистка записей при удалении персонажа.
    WorldDBExecute(string.format(
        "DELETE FROM realm_custom_spell_choices WHERE characterGUID=%i", characterGUID))
    WorldDBExecute(string.format(
        "DELETE FROM realm_custom_spell_category_choices WHERE characterGUID=%i", characterGUID))
    CharDBExecute(string.format(
        "DELETE FROM realm_custom_spell_learned WHERE characterGUID=%i", characterGUID))
end
RegisterPlayerEvent(2, OnDelete)

-- ---- AIO-обработчики ----

-- Выбор спелла клиентом.
local TOME_ITEM = nil  -- инициализируется ниже (SpellClass.TOME_ITEM_ID)

-- Выдать свиток со спеллом, когда лимит исчерпан (записать pending).
local function GrantTome(player, spellID)
    SpellClass:SetPendingSpell(player, spellID)
    local entry = SpellClass:ComputeTomeItemIDFromSpellID(spellID)
    if player:AddItem(entry, 1) then
        player:SendBroadcastMessage(L(player, "receivedManual"))
    else
        player:SendBroadcastMessage(L(player, "receivedMail"))
    end
end

function MyHandlers.SpellSelection(player, spellID)
    if SpellClass:CanLearnSpellFromChoice(player, spellID) then
        if SpellClass:CanLearnCustomSpell(player) then
            player:LearnSpell(spellID)
            SpellClass:MarkLearned(player, spellID)
        else
            GrantTome(player, spellID)
        end
        SpellClass:DeleteNextSpellChoice(player)
        CheckPlayerSpellChoice(player)
        CheckCategorySelectionChoice(player)
    end
end

-- Выбор категории клиентом.
function MyHandlers.CategorySelection(player, categoryID)
    if categoryID >= 1 and categoryID <= 4 then
        SpellClass:DeleteNextCategoryChoice(player)
        local spells = SpellClass:RandomSpellSelection(player, categoryID)
        SpellClass:SaveSpellChoices(player, spells)
        local g = player:GetGUID()
        CreateLuaEvent(function()
            CheckPlayerSpellChoice(GetPlayerByGUID(g))
        end, 100, 1)
    end
end

-- Unlearn-переключатель.
function MyHandlers.GetToggleState(player)
    local g = SpellClass:GetPlayerCharacterGUID(player)
    if unlearnToggle[g] == nil then unlearnToggle[g] = false end
    return unlearnToggle[g]
end

function MyHandlers.InvertToggleState(player)
    local g = SpellClass:GetPlayerCharacterGUID(player)
    unlearnToggle[g] = not unlearnToggle[g]
end

function MyHandlers.UpdateToggleState(player)
    if player:GetLevel() < 10 then return end
    AIO.Handle(player, HANDLER, "UpdateUnlearnToggle", MyHandlers.GetToggleState(player))
end

function MyHandlers.UnlearnToggle(player)
    MyHandlers.InvertToggleState(player)
    MyHandlers.UpdateToggleState(player)
end

function MyHandlers.UnlearnSpell(player, spellID)
    if MyHandlers.GetToggleState(player)
        and SpellClass:ValidSpellToRemove(spellID)
        and player:HasSpell(spellID) then
        if player:AddItem(SpellClass:ComputeTomeItemIDFromSpellID(spellID), 1) then
            player:RemoveSpell(spellID, false, false)
            player:RemoveAura(spellID)
            SpellClass:MarkUnlearned(player, spellID)
            GrantTome(player, spellID)
        end
    end
end

-- Использование «Свитка Пустоты» (70060): изучить отложенный спелл.
TOME_ITEM = SpellClass.TOME_ITEM_ID
local function OnTomeUse(event, player, item)
    if item:GetEntry() ~= TOME_ITEM then return true end
    local spellID = SpellClass:GetPendingSpell(player)
    if not spellID then
        player:SendAreaTriggerMessage(L(player, "tomeEmpty"))
        return false
    end
    if not SpellClass:CanLearnCustomSpell(player) then
        player:SendAreaTriggerMessage("|cffff0000" .. L(player, "alreadyHigh"))
        return false
    end
    player:LearnSpell(spellID)
    SpellClass:MarkLearned(player, spellID)
    SpellClass:ClearPendingSpell(player)
    player:RemoveItem(TOME_ITEM, 1)
    player:SendAreaTriggerMessage(L(player, "tomeLearned"))
    return false
end
RegisterItemEvent(TOME_ITEM, 2, OnTomeUse)

print("[EchoOfTheVoid] SpellAIO/server загружен: выбор кастомных спеллов (контур ).")