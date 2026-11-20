local dbHelper = require("raidbhelper").new()
local tableHelper = require("raitablehelper").new()

local RaiSpellPicker = {}

function RaiSpellPicker.new()

  function RaiSpellPicker:Heal(entry)
    return RaiSpellPicker:FetchSpellCategory(entry, 2)
  end

  function RaiSpellPicker:Damage(entry)
    return RaiSpellPicker:FetchSpellCategory(entry, 1)
  end

  function RaiSpellPicker:Buff(entry)
    return RaiSpellPicker:FetchSpellCategory(entry, 3)
  end

  function RaiSpellPicker:Utility(entry)
    return RaiSpellPicker:FetchSpellCategory(entry, 4)
  end

  function RaiSpellPicker:FetchSpellCategory(entry, category)
    local level = dbHelper:GetCreatureLevel(entry)
    local spells = RaiSpellPicker:FetchSpells(level, category)
    return tableHelper:Random(spells)
  end

  function RaiSpellPicker:FetchSpells(level, category)
    local maxLevelDifference = 7
    local query = WorldDBQuery(string.format("SELECT * FROM realm_custom_spell_system JOIN realm_custom_spell_categories ON realm_custom_spell_system.spellID = realm_custom_spell_categories.spellID AND category=%i AND spellLevel > %i - %i AND spellLevel < %i", category, level, maxLevelDifference, level))
    local spells = {}

    if query then
      repeat
      local row = query:GetRow()
      spells[#spells+1] = row["spellID"]
      until not query:NextRow()
    end

    return spells
  end

  return RaiSpellPicker
end

return RaiSpellPicker