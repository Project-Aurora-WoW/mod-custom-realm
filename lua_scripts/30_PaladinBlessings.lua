-- ============================================================
-- 30_PaladinBlessings.lua — продление благословений паладина
--
-- Референс: Youpeoples/ACScripts (extend_paladin_buffs.lua, MIT).
-- Адаптация под конвенции реалма: локализация ru/en по DBC-локали
-- клиента (8 = ruRU), регистрация PLAYER_EVENT_ON_LOGIN (3), единый
-- формат заголовка и print-лога.
--
-- Механика: благословения (Blessing of Might/Wisdom/Kings/Sanctuary и
-- Greater-варианты) автоматически продлеваются до 60 минут. Проверка —
-- раз в 2 сек: если бафф есть и ещё не продлён — снимаем и накладываем
-- заново с длительностью 60 мин; когда бафф исчез — снимаем пометку.
--
-- QoL-настройка (без БД/пересборки/патчей клиента). Включается/управляется
-- только длительностью ниже и списком спеллов.
-- ============================================================

-- Длительность продлённого благословения (минуты)
local EXTENDED_DURATION = 60
local EXTENDED_MS = EXTENDED_DURATION * 60 * 1000   -- 60 мин в мс

-- Все ID благословений паладина (базовые + Greater-варианты + Sanctuary)
local BLESSING_IDS = {
    -- Blessing of Might
    [19740] = true, [19834] = true, [19835] = true, [19836] = true,
    [19837] = true, [19838] = true, [25291] = true, [27140] = true,
    [48931] = true, [48932] = true,
    -- Greater Blessing of Might
    [25782] = true, [25916] = true, [27141] = true, [48933] = true, [48934] = true,
    -- Blessing of Wisdom
    [19742] = true, [19850] = true, [19852] = true, [19853] = true,
    [19854] = true, [25290] = true, [27142] = true, [48935] = true, [48936] = true,
    -- Greater Blessing of Wisdom
    [25894] = true, [25918] = true, [27143] = true, [48937] = true, [48938] = true,
    -- Blessing of Kings
    [20217] = true,
    -- Greater Blessing of Kings
    [25898] = true,
    -- Blessing of Sanctuary
    [20911] = true,
    -- Greater Blessing of Sanctuary
    [25899] = true,
}

-- Таблица отслеживания уже продлённых баффов: [guid] = { [spellId] = true }
local extended = {}

local function UpdateBlessings(eventId, delay, repeats, player)
    if not player or not player:IsInWorld() then return end
    local guid = player:GetGUIDLow()
    extended[guid] = extended[guid] or {}

    for spellId in pairs(BLESSING_IDS) do
        local aura = player:GetAura(spellId)
        if aura and not extended[guid][spellId] then
            local caster = aura:GetCaster()
            if caster then
                player:RemoveAura(spellId)
                local newAura = player:AddAura(spellId, caster)
                if newAura then
                    newAura:SetDuration(EXTENDED_MS)
                    extended[guid][spellId] = true
                end
            end
        elseif not aura and extended[guid][spellId] then
            extended[guid][spellId] = nil
        end
    end
end

-- На логине запускаем периодическую проверку благословений
local function OnLogin(event, player)
    player:RegisterEvent(UpdateBlessings, 2000, 0)   -- раз в 2 сек, вечный
end

-- На логауте снимаем таймер и чистим пометки
local function OnLogout(event, player)
    player:RemoveEvents()
    extended[player:GetGUIDLow()] = nil
end

RegisterPlayerEvent(3, OnLogin)    -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, OnLogout)   -- PLAYER_EVENT_ON_LOGOUT

print("[EchoOfTheVoid] 30_PaladinBlessings.lua загружен (благословения паладина продлеваются до " .. EXTENDED_DURATION .. " мин).")