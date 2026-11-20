local phase = require("raiphase").new()

local RaiEncounter = {}

function RaiEncounter.new()

  function RaiEncounter:Generate(entry)
    local encounter = {}

    local nPhases = RaiEncounter:AmountOfPhases(2, 3)
    encounter["phases"] = nPhases

    for i=1, nPhases do
      encounter[i] = phase:Generate(entry)
    end

    for i=1, nPhases do
      encounter[i]["healthpct"] = RaiEncounter:PhaseHealthPct(i, nPhases)
    end

    return encounter
  end

  function RaiEncounter:AmountOfPhases(min, max)
    return math.random(min, max)
  end

  function RaiEncounter:PhaseHealthPct(phase, phases)
    return math.floor(100 - ((phase/phases)* 100))
  end

  function RaiEncounter:GetPhaseForHealthPct(encounter, health)
    for i=1, encounter["phases"] do
      local phase = encounter[i]

      if i == 1 then
        if health > phase["healthpct"] then
          return phase, i
        end
      end

      local prevPhase = encounter[i-1]
      if health > phase["healthpct"] and health < prevPhase["healthpct"] then
        return phase, i
      end

      if i == encounter["phases"] then
        return phase, i
      end
    end
  end

  return RaiEncounter
end

return RaiEncounter