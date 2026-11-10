-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- 07_StartingZone.lua
-- Назначение: выбор стартовой зоны у Портального Стража (70001)
-- для новичков 1-го уровня (подход Waloria: startingzonepicker).
-- Лор: Орден даёт герою право выбрать, где начать путь против
-- Пустоты; выбор обновляет «дом» (сердцекамень).
-- Источник координат: waloriaold/scripts/90000_startingzonepicker.lua
-- Локализация: ru/en по локали DBC клиента.
-- Требуется модуль mod-ale (ALE). НПС 70001 — миграция 0001.
-- ============================================================

local REG = AzerothEchoCampaigns
local TAG = REG.meta.tag
local ORDER_COLOR = REG.meta.colors.order

local NPC_PORTAL_GUARDIAN = REG.campaigns[1].npc.portal_guardian -- 70001
local REQUIRED_LEVEL = 1         -- выбор доступен только на 1-м уровне

-- Координаты стартовых зон (waloriaold, выверены на их реалме)
local zones = {
    [0] = { -- Альянс
        [1] = { "Человек",      0,  -8949.950195,  -132.492996,  83.531197, 0.000000 },
        [2] = { "Ночной эльф",  1,  10311.299805,  832.463013,  1326.407837, 5.696320 },
        [3] = { "Дворф",        0,  -6240.319824,  331.032990,  382.757996, 6.177160 },
        [4] = { "Гном",         0,  -6240.319824,  331.032990,  382.757996, 6.177160 },
        [5] = { "Драэней",      530, -3961.639893, -13931.200195, 100.613525, 2.083640 },
    },
    [1] = { -- Орда
        [6] = { "Орк",          1,  -618.518005,  -4251.669922, 38.717999, 0.000000 },
        [7] = { "Тролль",       1,  -618.518005,  -4251.669922, 38.717999, 0.000000 },
        [8] = { "Нежить",       0,  1676.709961,  1678.310059, 121.669998, 3.163933 },
        [9] = { "Таурен",       1,  -2917.580078, -257.980011, 52.996799, 0.000000 },
        [10] = { "Эльф крови",  530, 10349.599609, -6357.290039, 33.402599, 5.316050 },
    },
}

-- Локализация
local function L(player, ru, en)
    local ok, loc = pcall(function() return player:GetDbcLocale() end)
    return (ok and loc == 8) and ru or en
end

-- ============================================================
-- Gossip: меню выбора стартовой зоны
-- ============================================================

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()

    if player:GetLevel() > REQUIRED_LEVEL then
        local msg = L(player,
            "Выбор зоны доступен только на 1-м уровне.",
            "Zone selection is only available at level 1.")
        player:GossipMenuAddItem(0, msg, 0, 0)
        player:GossipSendMenu(1, creature)
        return
    end

    local msg = L(player,
        "Орден даёт вам право выбрать, где начать путь. Куда отправимся?",
        "The Order grants you the right to choose where to begin. Where shall we go?")
    player:GossipMenuAddItem(0, msg, 0, 0)

    local options = zones[player:GetTeam()]
    for intid, v in pairs(options) do
        player:GossipMenuAddItem(4, v[1], 0, intid)
    end

    player:GossipSendMenu(1, creature)
end

-- ============================================================
-- Gossip: обработка выбора — телепорт + обновление «дома» (ХС)
-- ============================================================

local function OnGossipSelect(event, player, creature, sender, intid, code)
    local options = zones[player:GetTeam()]

    if intid >= 1 and intid <= 10 and options[intid] then
        local v = options[intid]
        local zoneName = v[1]

        -- Телепорт к стартовой зоне
        player:Teleport(v[2], v[3], v[4], v[5], v[6])

        -- Лор-сообщение (подход Waloria: при выборе зоны обновляется ХС)
        if zoneName then
            local msg = L(player,
                "Разлом слышен отсюда слабее. Путь начат — «дом» привязан к этой земле.",
                "The rift sounds fainter here. The journey begins — your 'home' is bound to this land.")
            player:SendBroadcastMessage(TAG .. " " .. ORDER_COLOR .. msg)
        end
    end

    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_PORTAL_GUARDIAN, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_PORTAL_GUARDIAN, 2, OnGossipSelect)

print("[EchoOfTheVoid] 07_StartingZone.lua загружен (выбор стартовой зоны, НПС 70001).")
