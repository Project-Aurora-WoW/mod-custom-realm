local spellPicker = require("raispellpicker").new()
local dbHelper = require("raidbhelper").new()
local target = require("raitargets").new()

local RaiPhase = {}

function RaiPhase.new()

  function RaiPhase:Generate(entry)
    local phase = {

    }

    phase["damage"] = RaiPhase:PickDamageSpells(entry, math.random(2, 4))
    phase["healing"] = RaiPhase:PickHealingSpells(entry, math.random(1, 2))
    phase["buff"] = RaiPhase:PickBuffSpells(entry, math.random(1))
    phase["utility"] = RaiPhase:PickUtilitySpells(entry, math.random(1))

    phase["targets"] = target:SelectDamageTargets(phase["damage"])

    return phase
  end

  function RaiPhase:PickDamageSpells(entry, amount)
    local damageSpells = {}

    for i=1, amount do
      damageSpells[#damageSpells + 1] = spellPicker:Damage(entry)
    end

    return damageSpells
  end

  function RaiPhase:PickHealingSpells(entry, amount)
    local healingSpells = {}

    for i=1, amount do
      healingSpells[#healingSpells + 1] = spellPicker:Heal(entry)
    end

    return healingSpells
  end

  function RaiPhase:PickBuffSpells(entry, amount)
    local buffSpells = {}

    for i=1, amount do
      buffSpells[#buffSpells + 1] = spellPicker:Buff(entry)
    end

    return buffSpells
  end

  function RaiPhase:PickUtilitySpells(entry, amount)
    local utilitySpells = {}

    for i=1, amount do
      utilitySpells[#utilitySpells + 1] = spellPicker:Utility(entry)
    end

    return utilitySpells
  end

  return RaiPhase
end

return RaiPhase