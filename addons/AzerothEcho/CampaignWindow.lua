-- ============================================================
-- AzerothEcho — CampaignWindow.lua (WoW 3.3.5a)
-- Принудительное окно выбора кампании (бриф: стартовое окно, логин).
--
-- Сервер (40_CampaignWindow.lua, ALE) при логине/создании персонажа,
-- если кампания не выбрана/флаг принудительного показа, блокирует
-- управление (SetPlayerLock) и шлёт аддон-сообщение:
--   AECHOUI  campaign:show
--
-- Здесь:
--   1) обработчик AECHOUI -> ShowCampaignSelector() — показывает
--      блокирующее okno (модально поверх мира);
--   2) блокировка ESC и кликов по миру до выбора;
--   3) подтверждение выбора шлётся серверу addon-сообщением
--      AECHOSEL  campaign:<id>
--   4) двуязычность ru/en, график событий внутри окна.
-- ============================================================

local AE = AzerothEcho

-- Локализация (ru/en автоподбор по клиенту)
local L
if GetLocale and GetLocale() == "ruRU" then
    L = {
        title   = "Выбор кампании",
        subtitle= "Эхо Пустоты — выбери свой путь",
        select  = "Выбрать",
        locked  = "Сделай выбор, герой: мир ждёт.",
        events  = "График событий",
        camp1   = "Эхо Шёпота",
        camp2   = "Пепел Зул'Драка",
        camp3   = "Пробуждение",
        camp4   = "Второе Эхо",
        camp1d  = "Кампания 1 — первые шаги Ордена Рассвета.",
        camp2d  = "Кампания 2 — восстание пепла Зул'Драка.",
        camp3d  = "Кампания 3 — пробуждение древних сил.",
        camp4d  = "Кампания 4 — второе Эхо Пустоты.",
        done    = "Кампания выбрана!",
    }
else
    L = {
        title   = "Campaign Select",
        subtitle= "Echo of the Void — choose your path",
        select  = "Select",
        locked  = "Make your choice, hero: the world awaits.",
        events  = "Event Schedule",
        camp1   = "Whisper of the Void",
        camp2   = "Ashes of Zul'Drak",
        camp3   = "Awakening",
        camp4   = "Second Echo",
        camp1d  = "Campaign 1 — first steps of the Dawn Order.",
        camp2d  = "Campaign 2 — the ash uprising of Zul'Drak.",
        camp3d  = "Campaign 3 — ancient powers awaken.",
        camp4d  = "Campaign 4 — the second Echo of the Void.",
        done    = "Campaign selected!",
    }
end

AE.CAMPAIGN_SELECTOR = AE.CAMPAIGN_SELECTOR or {}
local CS = AE.CAMPAIGN_SELECTOR

-- Флаг блокировки мира (пока окно активно)
CS.blocking = false

-- ============================================================
-- Создание окна (однократно, при первом показе)
-- ============================================================
local function CreateFrame_()
    if CS.frame then return end

    local f = CreateFrame("Frame", "AzerothEchoCampaignSelect", UIParent, "BackdropTemplate")
    f:SetPoint("CENTER")
    f:SetSize(420, 420)
    f:SetFrameStrata("HIGH")          -- поверх мира, ниже диалогов
    f:EnableMouse(true)               -- ловить клики (блокировка)
    f:SetMovable(false)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32,
        edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(0, 0, 0, 0.92)
    f:Hide()

    -- Заголовок
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText(L.title)

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    subtitle:SetPoint("TOP", 0, -40)
    subtitle:SetText(L.subtitle)

    -- Список кампаний (4 кнопки)
    local names = { L.camp1, L.camp2, L.camp3, L.camp4 }
    local descs = { L.camp1d, L.camp2d, L.camp3d, L.camp4d }
    local buttons = {}
    local startY = -78
    for i = 1, 4 do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(300, 44)
        b:SetPoint("TOP", 0, startY - (i - 1) * 54)
        local bt = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bt:SetPoint("CENTER")
        bt:SetText(names[i])
        b:SetScript("OnClick", function()
            CS:Select(i)
        end)
        buttons[i] = b
    end

    -- Подпись-блокировка
    local locked = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    locked:SetPoint("BOTTOM", 0, 40)
    locked:SetText(L.locked)

    -- График событий
    local evHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    evHeader:SetPoint("BOTTOM", 0, 20)
    evHeader:SetText(L.events)
    local evText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    evText:SetPoint("BOTTOM", 0, 2)
    evText:SetWidth(380)
    evText:SetJustifyH("CENTER")

    CS.frame = f
    CS.title = title
    CS.subtitle = subtitle
    CS.locked = locked
    CS.evHeader = evHeader
    CS.evText = evText
end

-- ============================================================
-- Блокировка ESC и кликов по миру
-- ============================================================
local function OnKeyDown(self, key)
    if key == "ESCAPE" and CS.blocking then
        -- заблокировать закрытие
        return true  -- интерпретируется как handled; окно не закрывается
    end
end

local function BlockerOnClick(self, button)
    self:Hide()  -- скрыть подокно, если кликнули; главное окно остаётся
end

-- ============================================================
-- Показ / скрытие
-- ============================================================
function CS:Show()
    CreateFrame_()
    -- Свежий график событий (заполняется клиентом-кэшем или заглушкой)
    self:RefreshEvents()
    self.frame:Show()
    self.blocking = true
    -- Блокируем ESC
    if not CS.keyRegistered then
        CS.keyFrame = CreateFrame("Frame")
        CS.keyFrame:SetScript("OnKeyDown", OnKeyDown)
        CS.keyRegisterID = CS.keyFrame:SetPropagateKeyboardInput(false)
        CS.keyRegistered = true
    end
    -- Блокируем клики по миру: создаём невидимый модальный блок
    if not CS.blocker then
        local blocker = CreateFrame("Frame", nil, UIParent)
        blocker:SetAllPoints(UIParent)
        blocker:SetFrameStrata("HIGH")
        blocker:EnableMouse(true)
        blocker:SetScript("OnMouseDown", BlockerOnClick)
        CS.blocker = blocker
    end
    CS.blocker:Show()
    PlaySound(880) -- выбор в меню
end

function CS:Hide()
    if CS.frame then CS.frame:Hide() end
    if CS.blocker then CS.blocker:Hide() end
    CS.blocking = false
end

-- ============================================================
-- Выбор кампании -> отправить серверу
-- ============================================================
function CS:Select(campId)
    if not campId or campId < 1 or campId > 4 then return end
    -- Отправляем серверу через addon-сообщение (тип WHISPER себе)
    local prefix = "AECHOSEL"
    local body = "campaign:" .. campId
    SendAddonMessage(prefix, body, "WHISPER", UnitName("player"))
    -- Показ: уведомление и закрытие окна
    print(AE.TAG .. " " .. L.done)
    self:Hide()
end

-- ============================================================
-- График событий (кэш от сервера AECHOEV либо заглушки)
-- ============================================================
function CS:RefreshEvents()
    if not CS.evText then return end
    local lines
    if AE.events and AE.events.storm then
        lines = {}
        for key, ev in pairs(AE.events) do
            if ev.name then
                table.insert(lines, ev.name .. ": " .. (ev.state and "active" or "wait"))
            end
        end
    else
        lines = { "Шторм Пустоты / Storm of the Void", "Кровавая Луна / Blood Moon" }
    end
    CS.evText:SetText(table.concat(lines, "  |  "))
end

-- ============================================================
-- Экспорт глобальных функций (для AzerothEcho.lua)
-- ============================================================
AE.ShowCampaignSelector = function() CS:Show() end
AE.HideCampaignSelector = function() CS:Hide() end

-- Разрешить повторное открытие: функция-заглушка вызывается из
-- обработчика AECHOUI (см. AzerothEcho.lua, ветка "campaign:show").

DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " Module CampaignWindow loaded (/ae camp).")