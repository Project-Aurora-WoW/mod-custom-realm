local group = require("raigroup").new()
local picker = require("raicreaturepicker").new()

local RaiSpawner = {}

function RaiSpawner:new()

  function RaiSpawner:Spawn(spawnpoint)
    spawnpoint["creature_entry"] = picker:PickEntry(spawnpoint)

    if math.random(1, 2) == 1 then
      RaiSpawner:SpawnPatroller(spawnpoint)
    else
      RaiSpawner:SpawnPack(spawnpoint)
    end
  end

  function RaiSpawner:SpawnPatroller(spawnpoint)
    local creature = PerformIngameSpawn(1, spawnpoint["creature_entry"], spawnpoint["map"], 0, spawnpoint["x"], spawnpoint["y"], spawnpoint["z"], spawnpoint["o"])
    creature:MoveRandom(600)
    creature:SetFaction(17)
  end

  function RaiSpawner:SpawnPack(spawnpoint)
    local packSize = math.random(2, 4)
    local members = {}

    for i=1, packSize do
      local creature = PerformIngameSpawn(1, spawnpoint["creature_entry"], spawnpoint["map"], 0, spawnpoint["x"], spawnpoint["y"], spawnpoint["z"], spawnpoint["o"])
      creature:SetFaction(17)
      members[#members+1] = creature
    end

    group:PrepareCreatureGroup(members)
  end

  function RaiSpawner:SpawnStatic(spawnpoint)
    local creature = PerformIngameSpawn(1, spawnpoint["creature_entry"], spawnpoint["map"], 0, spawnpoint["x"], spawnpoint["y"], spawnpoint["z"], spawnpoint["o"])
    return creature
  end

  return RaiSpawner
end

return RaiSpawner