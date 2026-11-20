local RaiCombat = {}

local cooldowns = {
  ["damage"] = 7,
  ["heal"] = 20,
  ["buff"] = 30
}

function RaiCombat.new()

  function RaiCombat:CastSpell(creature, spell, target)
    if not RaiCombat:CanCastNext(creature) then return end

    creature:SetData("lastCastTime", os.time())

    if target == 1 then
      RaiCombat:CastSpellVictim(creature, spell)
    elseif target == 2 then
      RaiCombat:CastSpellRandom(creature, spell)
    elseif target == 3 then
      RaiCombat:CastSpellAll(creature, spell)
    end
  end

  function RaiCombat:Casting(creature)
    return creature:HasUnitState(32768)
  end

  function RaiCombat:CanCastNext(creature)
    if RaiCombat:Casting(creature) then return false end
    if not creature:GetData("lastCastTime") then return true end

    local castingCooldown = cooldowns["damage"]
    return (os.time() - creature:GetData("lastCastTime")) > castingCooldown
  end

  function RaiCombat:CanCastNextHealSelf(creature)
    if RaiCombat:Casting(creature) then return false end
    if creature:GetHealthPct() > 90 then return false end
    if not creature:GetData("lastCastTimeHeal") then return true end

    local castingCooldown = cooldowns["heal"]
    return (os.time() - creature:GetData("lastCastTimeHeal")) > castingCooldown
  end

  function RaiCombat:CanCastNextHealFriendly(creature, spell)
    if RaiCombat:Casting(creature) then return false end
    if not creature:GetData("lastCastTimeHeal") then return true end

    local castingCooldown = cooldowns["heal"]
    return (os.time() - creature:GetData("lastCastTimeHeal")) > castingCooldown
  end

  function RaiCombat:CanCastNextBuffSelf(creature, spell)
    if creature:HasAura(spell) then return false end
    if RaiCombat:Casting(creature) then return false end
    if not creature:GetData("lastCastTimeBuff") then return true end

    local castingCooldown = cooldowns["buff"]
    return (os.time() - creature:GetData("lastCastTimeBuff")) > castingCooldown
  end

  function RaiCombat:CanCastNextBuffFriendly(creature)
    if RaiCombat:Casting(creature) then return false end
    if not creature:GetData("lastCastTimeBuff") then return true end

    local castingCooldown = cooldowns["buff"]
    return (os.time() - creature:GetData("lastCastTimeBuff")) > castingCooldown
  end

  function RaiCombat:CastSpellVictim(creature, spell)
    creature:CastSpell(creature:GetVictim(), spell, true)
  end

  function RaiCombat:CastSpellRandom(creature, spell)
    local targets = creature:GetAITargets()

    local target = nil
    if #targets > 1 then
      target = targets[math.random(1, #targets)]
    else
      target = targets[1]
    end

    if target then
      creature:CastSpell(target, spell, true)
    end
  end

  function RaiCombat:CastSpellAll(creature, spell)
    local targets = creature:GetAITargets()

    for i=1, #targets do
      creature:CastSpell(targets[i], spell, true)
    end
  end

  function RaiCombat:CastHeal(creature, spell)
    if RaiCombat:CanCastNextHealSelf(creature) then
      RaiCombat:CastHealSelf(creature, spell)
    elseif RaiCombat:CanCastNextHealFriendly(creature) then
      RaiCombat:CastHealFriendly(creature, spell)
    end
  end

  function RaiCombat:CastHealSelf(creature, spell)
    creature:SetData("lastCastTimeHeal", os.time())
    creature:CastSpell(creature, spell, true)
  end

  function RaiCombat:CastHealFriendly(creature, spell)
    local creatures = creature:GetCreaturesInRange(15, 0, 2, 1)
    local casted = false

    for k, v in ipairs(creatures) do
      if v:GetHealthPct() < 90 then
        creature:CastSpell(v, spell, true)
        casted = true
      end
    end

    if not casted and creatures ~= nil then
      if #creatures >= 1 then
        local randomFriendly = creatures[math.random(1, #creatures)]

        if randomFriendly ~= nil then
          if randomFriendly:GetHealthPct() < 95 then
            creature:CastSpell(randomFriendly, spell, true)
            casted = true
          end
        end
      end
    end

    if casted then
      creature:SetData("lastCastTimeHeal", os.time())
    end
  end

  function RaiCombat:CastBuff(creature, spell)
    if RaiCombat:CanCastNextBuffSelf(creature, spell) then
      RaiCombat:CastBuffSelf(creature, spell)
    elseif RaiCombat:CanCastNextBuffFriendly(creature) then
      RaiCombat:CastBuffFriendly(creature, spell)
    end
  end

  function RaiCombat:CastBuffSelf(creature, spell)
    creature:SetData("lastCastTimeBuff", os.time())
    creature:CastSpell(creature, spell, true)
  end

  function RaiCombat:CastBuffFriendly(creature, spell)
    local creatures = creature:GetCreaturesInRange(15, 0, 2, 1)
    local target = nil

    for k, v in ipairs(creatures) do
      if not v:HasAura(spell) then
        target = v
      end
    end

    if target ~= nil then
      creature:SetData("lastCastTimeBuff", os.time())
      creature:CastSpell(target, spell, true)
    end
  end

  return RaiCombat
end

return RaiCombat