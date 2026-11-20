local RaiCreaturePicker = {}

function RaiCreaturePicker:new()

  function RaiCreaturePicker:PickEntry(spawnpoint)
    if spawnpoint["creature_entry"] ~= -1 then return spawnpoint["creature_entry"] end

    local minMax = RaiCreaturePicker:FetchMinAndMaxLevel(spawnpoint["zone"])
    if not minMax then return -1 end

    local selectedLevel = math.random(minMax["min"], minMax["max"])
    return RaiCreaturePicker:ConstructCreatureEntry(selectedLevel)
  end

  function RaiCreaturePicker:FetchMinAndMaxLevel(zone)
    local query = WorldDBQuery(string.format("SELECT minlevel, maxlevel FROM realm_rai_zone_level WHERE zone=%i", zone))

    if query then
      local row = query:GetRow()

      local data = {}
      data["min"] = row["minlevel"]
      data["max"] = row["maxlevel"]
      return data
    else
      print("RaiCreaturePicker: Could not find min and max level for zone "..tostring(zone))
      return nil
    end
  end

  function RaiCreaturePicker:ConstructCreatureEntry(level)
    return 100000 + level
  end

  return RaiCreaturePicker
end

return RaiCreaturePicker