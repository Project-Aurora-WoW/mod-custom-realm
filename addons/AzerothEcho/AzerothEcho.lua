-- ============================================================
-- AzerothEcho — точка входа аддона (WoW 3.3.5a)
-- Инициализация, приём данных сервера, уведомления о прогрессе,
-- slash-команды:
--   /ae          — панель (4 вкладки: Кампании, Ивенты, PvP, Справка)
--   /ae rifts    — карта разломов Пустоты
--   /ae pvp      — сразу вкладка PvP
--   /ae events   — сразу вкладка Ивенты
-- Файлы: Core.lua (состояние), Panel.lua (UI), RiftMap.lua (карта).
-- ============================================================

local AE = AzerothEcho
local C = AE.COLOR
local PREFIX = AE.PREFIX

-- ============================================================
-- Приём сообщений сервера (AddonBridge.lua + CampaignManager.lua)
--   AECHO      — прогресс кампаний
--   AECHOEV    — ивенты + жетоны
--   AECHOPVP   — PvP-статистика
--   AECHOUI    — серверная команда UI: "tab:N" (открыть вкладку)
--   AECHORIFTS — серверная команда: "show" (открыть карту разломов)
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message = ...
        if prefix == PREFIX then
            AE.ParseProgress(message)
        elseif prefix == "AECHOEV" then
            AE.ParseEvents(message)
        elseif prefix == "AECHOPVP" then
            AE.ParsePvp(message)
        elseif prefix == "AECHOUI" then
            -- Серверная аналогия slash-команд: .ae pvp -> tab:3 и т.п.
            local tab = string.match(message or "", "^tab:(%d+)$")
            if tab then
                AE.ShowTab(tonumber(tab))
            end
        elseif prefix == "AECHORIFTS" then
            if message == "show" then
                AE.ShowRiftMap()
            end
        elseif prefix == "AECHOLORE" then
            if AE.ParseLore then
                AE.ParseLore(message)
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Запрос данных у сервера
        SendAddonMessage(PREFIX, "hello", "WHISPER", UnitName("player"))
        DEFAULT_CHAT_FRAME:AddMessage(
            AE.TAG .. " Аддон AzerothEcho 2.1 загружен. /ae — панель, /ae rifts — карта разломов, /ae help — помощь."
        )
    end
end)

-- ============================================================
-- Всплывающие уведомления о прогрессе кампаний
-- ============================================================

-- Последний известный прогресс (для отслеживания изменений)
local lastProgress = {}

local function NotifyIfChanged(campId, p)
    local prev = lastProgress[campId]
    local name = AE.CAMPAIGN_NAMES[campId] or ("Кампания " .. campId)

    if prev then
        if p.done and not prev.done then
            UIErrorsFrame:AddMessage(
                name .. ": ЗАВЕРШЕНА!", 0.56, 0.27, 0.68, 3.0, 4
            )
        elseif not p.done and p.chapter > (prev.chapter or 0) then
            UIErrorsFrame:AddMessage(
                name .. ": глава " .. p.chapter .. "/" .. p.total,
                0.56, 0.27, 0.68, 2.0, 4
            )
        end
    end
    lastProgress[campId] = { chapter = p.chapter, total = p.total, done = p.done }
end

AE.OnDataChanged(function()
    for campId = 1, 4 do
        local p = AE.progress[campId]
        if p then
            NotifyIfChanged(campId, p)
        end
    end
end)

-- ============================================================
-- Slash-команды (клиентские аналоги серверных .ae-команд)
-- ============================================================

SLASH_AZEROTHECHO1 = "/ae"
SlashCmdList["AZEROTHECHO"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "rifts" then
        AE.ShowRiftMap()
    elseif msg == "pvp" then
        AE.ShowTab(3)   -- вкладка PvP
    elseif msg == "events" then
        AE.ShowTab(2)   -- вкладка Ивенты
    elseif msg == "campaigns" or msg == "camp" then
        AE.ShowTab(1)   -- вкладка Кампании
    elseif msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " Команды: /ae — панель; /ae rifts — карта разломов;")
        DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " /ae campaigns — кампании; /ae events — ивенты; /ae pvp — статистика.")
        DEFAULT_CHAT_FRAME:AddMessage(AE.TAG .. " Серверные аналоги: .ae help | status | tokens | rifts | pvp | events.")
    else
        AE.TogglePanel()
    end
end
