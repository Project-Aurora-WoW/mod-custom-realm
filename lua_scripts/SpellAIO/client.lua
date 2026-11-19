-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- SpellAIO/client.lua  (адаптация из WaloriaOld/scripts/SpellAIO)
--
-- Клиентская часть (AIO) системы выбора кастомных спеллов.
-- Стандартный AIO-аддон: окно с 4 кнопками выбора категории/спелла.
-- Категории локализованы ru/en по локали клиента.
-- ============================================================

local AIO = AIO
if AIO.AddAddon() then
    return
end

local MyHandlers = AIO.AddHandlers("SpellAIO", {})
local spellButtons = {}

local nButtons = 4

local frame = nil

local function GetLocaleTag()
    return (GetLocale() == "ruRU") and "ru" or "en"
end

local CATEGORIES = {
    ru = { "Боевой", "Исцеление", "Усиление", "Полезный" },
    en = { "Damage", "Healing", "Buff", "Utility" },
}

local CATEGORY_TOOLTIPS = {
    ru = {
        "|cffFFFF00Выберите новый боевой спелл.",
        "|cffFFFF00Выберите новый исцеляющий спелл.",
        "|cffFFFF00Выберите новое усиление.",
        "|cffFFFF00Выберите новый полезный спелл.",
    },
    en = {
        "|cffFFFF00Select a new damaging spell.",
        "|cffFFFF00Select a new healing spell.",
        "|cffFFFF00Select a new buff.",
        "|cffFFFF00Select a new utility spell.",
    },
}

local CATEGORY_ICONS = {
    "Interface\\Icons\\ability_warrior_offensivestance",
    "Interface\\Icons\\spell_holy_flashheal",
    "Interface\\Icons\\spell_nature_wispsplode",
    "Interface\\Icons\\inv_misc_enggizmos",
}

local function buildAndShowFrame()
    frame = CreateFrame("Frame", "AESpellAIOFrame", UIParent)
    frame:SetWidth((40 * 4) + 20)
    frame:SetHeight(60)
    frame:ClearAllPoints()
    frame:SetBackdrop(StaticPopup1:GetBackdrop())
    frame:SetPoint("TOP", UIParent)
    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    AIO.SavePosition(frame)

    for i = 1, nButtons do
        local btn = CreateFrame("Button", "AESpellButton" .. i, frame, "ActionButtonTemplate")
        btn:SetWidth(40)
        btn:SetHeight(40)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 13 + (i - 1) * 45, -13)
        spellButtons[i] = btn
    end
    frame:Hide()
end

local function hideButtons()
    for i = 1, #spellButtons do spellButtons[i]:Hide() end
end

local function showButtons()
    for i = 1, #spellButtons do spellButtons[i]:Show() end
end

local function buttonTooltip(btn, text)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(text, 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function setButtonIcon(btn, texture)
    local ntex = btn:CreateTexture()
    ntex:SetTexture(texture)
    ntex:SetTexCoord(0, 1, 0, 1)
    ntex:SetAllPoints()
    btn:SetNormalTexture(ntex)
    local ptex = btn:CreateTexture()
    ptex:SetTexture(texture)
    ptex:SetTexCoord(0, 1, 0, 1)
    ptex:SetAllPoints()
    btn:SetPushedTexture(ptex)
end

local function updateCategorySelection(visibleCategories)
    local tag = GetLocaleTag()
    for i = 1, #visibleCategories do
        local cat = visibleCategories[i]
        local btn = spellButtons[i]
        setButtonIcon(btn, CATEGORY_ICONS[cat])
        buttonTooltip(btn, CATEGORY_TOOLTIPS[tag][cat])
        btn:SetScript("OnClick", function()
            AIO.Handle("SpellAIO", "CategorySelection", cat)
            frame:Hide()
            hideButtons()
        end)
    end
end

local function updateSpellButtons(spellTable)
    local tag = GetLocaleTag()
    for i = 1, nButtons do
        local btn = spellButtons[i]
        local spellID = spellTable[i]
        local name, _, icon = GetSpellInfo(spellID)
        if name then
            setButtonIcon(btn, icon)
            local warn = (tag == "ru") and "|cffFC0000Внимание: выбор спелла постоянен." or
                "|cffFC0000Warning: Spell selection is permanent."
            buttonTooltip(btn, warn)
            btn:SetScript("OnClick", function()
                AIO.Handle("SpellAIO", "SpellSelection", spellID)
                frame:Hide()
                hideButtons()
            end)
        end
    end
end

buildAndShowFrame()

function MyHandlers.ShowFrame(player, spellTable)
    updateSpellButtons(spellTable)
    frame:Show()
    showButtons()
end

function MyHandlers.ShowCategory(player, visibleCategories)
    updateCategorySelection(visibleCategories)
    frame:Show()
    showButtons()
    if #visibleCategories < nButtons then
        spellButtons[nButtons]:Hide()
    end
end

print("[EchoOfTheVoid] SpellAIO/client загружен.")