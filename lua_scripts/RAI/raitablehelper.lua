local RaiTableHelper = {}

function RaiTableHelper.new()

  function RaiTableHelper:Random(table)
    local rIndex = math.random(1, #table)
    return table[rIndex]
  end

  function RaiTableHelper:Merge(table1, table2)
    for k,v in pairs(table2) do
      table1[k] = v
    end

    return table1
  end

  return RaiTableHelper
end

return RaiTableHelper