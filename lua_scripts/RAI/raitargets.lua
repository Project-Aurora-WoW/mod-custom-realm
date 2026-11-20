local tableHelper = require("raitablehelper").new()

local RaiTargets = {}

--[[
  Damage Targets
  ---------------
  1 = Main target
  2 = Random Target
  3 = All enemies

  Healing Targets
  ----------------
  1 = Self

  Buff Targets
  ----------------
  1 = Self
--]]

function RaiTargets.new()

  function RaiTargets:SelectTargets(phase)
    local targets = {}

    local damageTargets = RaiTargets:SelectDamageTargets(phase["damage"])
    local healingTargets = RaiTargets:SelectHealingTargets(phase["healing"])
    local buffTargets = RaiTargets:SelectBuffTargets(phase["buff"])

    targets = tableHelper:Merge(targets, damageTargets)
    targets = tableHelper:Merge(targets, healingTargets)
    targets = tableHelper:Merge(targets, buffTargets)

    return targets
  end

  function RaiTargets:SelectDamageTargets(spells)
    local spellTargets = { }

    for i=1, #spells do
      local spell = spells[i]
      local target = RaiTargets:SelectDamageTarget()

      spellTargets[spell] = target
    end

    return spellTargets
  end

  function RaiTargets:SelectDamageTarget()
    return math.random(1, 2)
  end

  function RaiTargets:SelectHealingTargets(spells)
    local spellTargets = {}

    for i=1, #spells do
      local spell = spells[i]
      local target = RaiTargets:SelectHealingTarget()

      spellTargets[spell] = target
    end

    return spellTargets
  end

  function RaiTargets:SelectHealingTarget()
    return math.random(1, 1)
  end

  function RaiTargets:SelectBuffTargets(spells)
    local spellTargets = {}

    for i=1, #spells do
      local spell = spells[i]
      local target = RaiTargets:SelectBuffTarget()

      spellTargets[spell] = target
    end

    return spellTargets
  end

  function RaiTargets:SelectBuffTarget()
    return math.random(1, 1)
  end

  return RaiTargets
end

return RaiTargets