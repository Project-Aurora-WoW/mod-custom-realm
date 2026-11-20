local tableHelper = require("raitablehelper").new()
local dbHelper = require("raidbhelper").new()

local RaiCreature = {}

local adventurerAuras = {
  92001,
  92002,
  92003,
  92004,
  92005,
  92006,
  92007,
  92008,
  92009,
  92010
}

function RaiCreature.new()

  function RaiCreature:SetAdventurerAura(creature)
    local aura = creature:GetData("aura")

    if aura ~= nil then
      creature:CastSpell(creature, aura, true)
    else
      local aura = tableHelper:Random(adventurerAuras)
      creature:CastSpell(creature, aura, true)
      creature:SetData("aura", aura)
    end
  end

  function RaiCreature:RemoveAdventurerAuras(creature)
    for i=1, #adventurerAuras do
      local aura = adventurerAuras[i]
      creature:RemoveAura(aura)
    end
  end

  function RaiCreature:SetEquipment(creature)
    local items = dbHelper:GetCreatureWeaponsForLevel(creature)
    local mainHand = tableHelper:Random(items)
    local offHand = tableHelper:Random(items)

    creature:SetEquipmentSlots(mainHand, offHand, 0)
  end

  function RaiCreature:Patrol(creature)
    creature:SetDefaultMovementType(1)
    creature:MoveRandom(150)
  end

  return RaiCreature
end

return RaiCreature