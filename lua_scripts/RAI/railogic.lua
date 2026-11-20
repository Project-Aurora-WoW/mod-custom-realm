local combat = require("raicombat").new()

local RaiLogic = {}

local spellCooldownMin = 100
local spellCooldownMax = 500

function RaiLogic.new()

  function RaiLogic:RegisterPhase(creature, phase)
    RaiLogic:RegisterDamage(creature, phase)
    RaiLogic:RegisterHeal(creature, phase)
    RaiLogic:RegisterBuff(creature, phase)
  end

  function RaiLogic:RegisterDamage(creature, phase)
    for i=1, #phase["damage"] do
      creature:RegisterEvent(function() combat:CastSpell(creature, phase["damage"][i], phase["targets"][phase["damage"][i]]) end, math.random(spellCooldownMin, spellCooldownMax), 0)
    end
  end

  function RaiLogic:RegisterHeal(creature, phase)
    for i=1, #phase["healing"] do
      creature:RegisterEvent(function() combat:CastHeal(creature, phase["healing"][1]) end, math.random(spellCooldownMin, spellCooldownMax), 0)
    end
  end

  function RaiLogic:RegisterBuff(creature, phase)
    for i=1, #phase["buff"] do
      creature:RegisterEvent(function() combat:CastBuff(creature, phase["buff"][1]) end, math.random(spellCooldownMin, spellCooldownMax), 0)
    end
  end

  return RaiLogic
end

return RaiLogic