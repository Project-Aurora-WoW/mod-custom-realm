local RaiGroup = {}

function RaiGroup:new()

  function RaiGroup:PrepareCreatureGroup(creatures)
    local leader = creatures[math.random(1, #creatures)]

    for k, creature in ipairs(creatures) do
      RaiGroup:SetCreatureData(creature, creatures, leader)
    end

    RaiGroup:StartPatrolling(creatures[1])
  end

  function RaiGroup:SetCreatureData(creature, members, leader)
    local groupInfo = {}
    groupInfo["members"] = {}
    groupInfo["leader"] = leader:GetGUID()

    for k, member in ipairs(members) do
      table.insert(groupInfo["members"], member:GetGUID())
    end

    creature:SetData("groupInfo", groupInfo)
  end

  function RaiGroup:StartPatrolling(creature)
    local groupInfo = creature:GetData("groupInfo")
    if not groupInfo then return end

    local members = creature:GetCreaturesInRange(70, creature:GetEntry())

    local leader = creature
    leader:SetWalk(true)
    leader:MoveRandom(600)

    for k, v in ipairs(members) do
      if RaiGroup:GUIDPartOfGroupMembers(v:GetGUID(), groupInfo) then
        if k == 1 then
          v:MoveFollow(leader, -5)
        else
          v:MoveFollow(members[k-1])
        end

        v:SetWalk(true)
        v:ClearUnitState(4194304)
      end
    end
  end

  function RaiGroup:GUIDPartOfGroupMembers(guid, groupInfo)
    for k, realMemberGUID in ipairs(groupInfo["members"]) do
      if guid == realMemberGUID then
        return true
      end
    end

    return false
  end

  function RaiGroup:IsLeaderAlive(creature, groupInfo)
    local members = creature:GetCreaturesInRange(40, creature:GetEntry())

    for k, member in ipairs(members) do
      if member:GetGUID() == groupInfo["leader"] then
        return true
      end
    end

    return false
  end

  function RaiGroup:PickLeader(creature, groupInfo, leader)
    local realMembers = RaiGroup:GetGroupMembers(creature, groupInfo)

    for k, member in ipairs(realMembers) do
      RaiGroup:SetCreatureData(member, realMembers, leader)
    end
  end

  function RaiGroup:OnGroupMemberEnterCombat(creature)
    local members = RaiGroup:GetGroupMembers(creature, creature:GetData("groupInfo"))
    local leader = RaiGroup:GetLeader(creature, creature:GetData("groupInfo"))

    if leader == nil then
      leader = creature
    end

    for k, member in ipairs(members) do
      local victim = creature:GetVictim()
      member:SetHomePosition(leader:GetX(), leader:GetY(), leader:GetZ(), leader:GetO())

      if victim then
        member:AddThreat(victim, 100)
        member:AttackStart(creature:GetVictim())
      end
    end
  end

  function RaiGroup:GetGroupMembers(creature, groupInfo)
    local members = creature:GetCreaturesInRange(40, creature:GetEntry())
    local realMembers = {}
    for k, member in ipairs(members) do
      if RaiGroup:GUIDPartOfGroupMembers(member:GetGUID(), groupInfo) then
        table.insert(realMembers, member)
      end
    end

    return realMembers
  end

  function RaiGroup:GetLeader(creature, groupInfo)
    local creatures = creature:GetCreaturesInRange(70, creature:GetEntry())
    local leader = nil
    for k, cr in ipairs(creatures) do
      if cr:GetGUID() == groupInfo["leader"] then
        leader = cr
      end
    end

    return leader
  end

  return RaiGroup
end

return RaiGroup