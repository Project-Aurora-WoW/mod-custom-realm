-- ============================================================
-- Azeroth: Эхо Пустоты (Azeroth Custom Realm)
-- SpellAIO/spellclass.lua  (адаптация из WaloriaOld/scripts/SpellAIO)
--
-- Ядро логики системы выбора кастомных спеллов. Порт на конвенции реалма:
--   * таблицы переименованы: realm_custom_spell_*;
--   * счётчик изученных ведём на Lua (realm_custom_spell_learned),
--     НЕ патчем ядра (в Waloria — C++-метод GetCustomSpellAmount);
--   * локализация сообщений — в вызывающем коде (L(), не здесь);
--   * максимум изученных настраивается константой MAX_CUSTOM_SPELLS.
-- ============================================================

local SpellClass = {}

-- Максимум одновременно изученных кастомных спеллов на персонажа.
-- (В Waloria — жёсткий лимит 25; оставляем настраиваемым.)
SpellClass.MAX_CUSTOM_SPELLS = 25

-- Категории выбора (числовые коды; тексты — в client.lua/UI).
SpellClass.CATEGORY = {
    DAMAGE  = 1,
    HEALING = 2,
    BUFF    = 3,
    UTILITY = 4,
}

function SpellClass.new()
    -- Получить characterGUID (characters.guid) по имени персонажа.
    function SpellClass:GetPlayerCharacterGUID(player)
        local query = CharDBQuery(string.format(
            "SELECT guid FROM characters WHERE name='%s'", player:GetName()))
        if query then
            return tonumber(query:GetRow()["guid"])
        end
        return nil
    end

    -- Случайная выборка `amount` спеллов из пула (без повторов).
    -- Если уникальных спеллов в пуле меньше `amount`, отдаём столько, сколько есть
    -- (иначе цикл по подбору уникальных никогда бы не завершился).
    function SpellClass:SelectSpellsFromPool(spellPool, amount)
        local spells = {}
        local want = math.min(amount, #spellPool)
        for i = 1, want do
            local idx = math.random(1, #spellPool)
            local selected = spellPool[idx]
            while SpellClass:IsInArray(selected, spells) do
                idx = math.random(1, #spellPool)
                selected = spellPool[idx]
            end
            spells[i] = selected
        end
        return spells
    end

    function SpellClass:IsInArray(value, array)
        for i = 1, #array do
            if value == array[i] then return true end
        end
        return false
    end

    -- Кандидаты-спеллы определённой категории, начиная с уровня `level`
    -- и вниз, которых игрок ещё не изучил. (Не жёстко 6: достаточно набрать
    -- по толщине пула, чтобы выбор открылся даже при каталоге из 1 спелла).
    function SpellClass:SpellCandidates(player, level, category)
        local spells = {}
        local curr = level
        while curr >= 1 do
            local q = WorldDBQuery(string.format(
                "SELECT s.spellID FROM realm_custom_spell_system s " ..
                "INNER JOIN realm_custom_spell_categories c ON c.spellID = s.spellID " ..
                "WHERE s.spellLevel = %i AND c.category = %i;", curr, category))
            if q then
                repeat
                    local row = q:GetRow()
                    local sid = tonumber(row["spellID"])
                    if not player:HasSpell(sid) then
                        spells[#spells + 1] = sid
                    end
                until not q:NextRow()
            end
            curr = curr - 1
        end
        return spells
    end

    -- Есть ли у пула категории хотя бы один кандидат для текущего уровня.
    function SpellClass:HasAnyCandidate(player, level, category)
        local q = WorldDBQuery(string.format(
            "SELECT COUNT(*) AS n FROM realm_custom_spell_system s " ..
            "INNER JOIN realm_custom_spell_categories c ON c.spellID = s.spellID " ..
            "WHERE s.spellLevel <= %i AND c.category = %i;", level, category))
        if not q then return false end
        return tonumber(q:GetRow()["n"]) > 0
    end

    -- Есть ли кандидаты (>= 4) для категории у текущего уровня.
    function SpellClass:ExistsCandidates(player, level, category)
        local q = WorldDBQuery(string.format(
            "SELECT COUNT(*) AS n FROM realm_custom_spell_system s " ..
            "INNER JOIN realm_custom_spell_categories c ON c.spellID = s.spellID " ..
            "WHERE s.spellLevel <= %i AND c.category = %i;", level, category))
        local n = 0
        if q then n = tonumber(q:GetRow()["n"]) or 0 end
        return n >= 4
    end

    -- Категории, доступные для выбора (в которых есть хотя бы один кандидат).
    function SpellClass:GetAvailableCategories(player)
        local level = player:GetLevel()
        local out = {}
        for cat = 1, 4 do
            if SpellClass:HasAnyCandidate(player, level, cat) then
                out[cat] = cat
            end
        end
        return out
    end

    -- Случайный выбор спеллов категории для окна выбора (не больше, чем есть в пуле).
    function SpellClass:RandomSpellSelection(player, category)
        local level = player:GetLevel()
        local pool = SpellClass:SpellCandidates(player, level, category)
        if #pool == 0 then return nil end
        return SpellClass:SelectSpellsFromPool(pool, math.min(4, #pool))
    end

    -- ---- Сохранение выбора в БД ----

    function SpellClass:SaveCategoryChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        WorldDBExecute(string.format(
            "INSERT INTO realm_custom_spell_category_choices (characterGUID, level) VALUES (%i, %i)",
            g, player:GetLevel()))
    end

    function SpellClass:HasCategoryChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        return WorldDBQuery(string.format(
            "SELECT id FROM realm_custom_spell_category_choices WHERE characterGUID=%i LIMIT 1", g)) ~= nil
    end

    function SpellClass:NextCategoryChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        local q = WorldDBQuery(string.format(
            "SELECT * FROM realm_custom_spell_category_choices WHERE characterGUID=%i LIMIT 1", g))
        if q then return q:GetRow() end
        return nil
    end

    function SpellClass:DeleteNextCategoryChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        WorldDBExecute(string.format(
            "DELETE FROM realm_custom_spell_category_choices WHERE characterGUID=%i LIMIT 1", g))
    end

    function SpellClass:SaveSpellChoices(player, spells)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        WorldDBExecute(string.format(
            "INSERT INTO realm_custom_spell_choices (characterGUID, spellID1, spellID2, spellID3, spellID4, level) " ..
            "VALUES (%i, %i, %i, %i, %i, %i)",
            g, spells[1], spells[2], spells[3], spells[4], player:GetLevel()))
    end

    function SpellClass:HasSpellChoices(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        return WorldDBQuery(string.format(
            "SELECT id FROM realm_custom_spell_choices WHERE characterGUID=%i LIMIT 1", g)) ~= nil
    end

    function SpellClass:NextSpellChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        local q = WorldDBQuery(string.format(
            "SELECT * FROM realm_custom_spell_choices WHERE characterGUID=%i ORDER BY level LIMIT 1", g))
        if q then
            local row = q:GetRow()
            return { tonumber(row["spellID1"]), tonumber(row["spellID2"]),
                     tonumber(row["spellID3"]), tonumber(row["spellID4"]) }
        end
        return nil
    end

    function SpellClass:DeleteNextSpellChoice(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        WorldDBExecute(string.format(
            "DELETE FROM realm_custom_spell_choices WHERE characterGUID=%i ORDER BY level LIMIT 1", g))
    end

    function SpellClass:DeleteAllSpellChoices(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        WorldDBExecute(string.format("DELETE FROM realm_custom_spell_choices WHERE characterGUID=%i", g))
    end

    function SpellClass:CanLearnSpellFromChoice(player, spellID)
        local spells = SpellClass:NextSpellChoice(player)
        if not spells then return false end
        for i = 1, 4 do
            if spells[i] == spellID then return true end
        end
        return false
    end

    function SpellClass:ValidSpellToRemove(spellID)
        return WorldDBQuery(string.format(
            "SELECT id FROM realm_custom_spell_system WHERE spellID=%i LIMIT 1", spellID)) ~= nil
    end

    -- Свиток (item) для спелла: в Waloria 90000+id. У нас — свой диапазон
    -- реалма 7xxxx; item создаётся отдельной миграцией. Возврат entry или 0.
    function SpellClass:ComputeTomeItemIDFromSpellID(spellID)
        return 0  -- TODO: связать с 7xxxx item-маном, когда создадим ману
    end

    -- ---- Лимиты изучения (Lua-замена GetCustomSpellAmount) ----

    function SpellClass:GetLearnedCount(player)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        local q = CharDBQuery(string.format(
            "SELECT COUNT(*) AS n FROM realm_custom_spell_learned WHERE characterGUID=%i", g))
        if q then return tonumber(q:GetRow()["n"]) or 0 end
        return 0
    end

    function SpellClass:CanLearnCustomSpell(player)
        return (SpellClass:GetLearnedCount(player) + 1) <= SpellClass.MAX_CUSTOM_SPELLS
    end

    function SpellClass:MarkLearned(player, spellID)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        CharDBExecute(string.format(
            "INSERT IGNORE INTO realm_custom_spell_learned (characterGUID, spellID) VALUES (%i, %i)",
            g, spellID))
    end

    function SpellClass:MarkUnlearned(player, spellID)
        local g = SpellClass:GetPlayerCharacterGUID(player)
        CharDBExecute(string.format(
            "DELETE FROM realm_custom_spell_learned WHERE characterGUID=%i AND spellID=%i", g, spellID))
    end

    return SpellClass
end

return SpellClass