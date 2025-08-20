local CollideDefines = {}

CollideDefines.CollideGroup =
{
    redPlayer = 1,       -- 红队玩家
    redBridge = 2,       -- 红队桥梁
    yellowPlayer = 3,    -- 黄队玩家
    yellowBridge = 4,    -- 黄队桥梁
    bluePlayer = 5,      -- 蓝队玩家
    blueBridge = 6,      -- 蓝队桥梁
    destroyedBridge = 7, -- 炸毁的桥梁
}

CollideDefines.CollideType =
{
    redTeam = 1,
    yellowTeam = 2,
    blueTeam = 3,
}

CollideDefines.TeamConfig = {
    [CollideDefines.CollideType.redTeam] = {
        player = CollideDefines.CollideGroup.redPlayer,
        bridge = CollideDefines.CollideGroup.redBridge,
        name = "红队"
    },
    [CollideDefines.CollideType.yellowTeam] = {
        player = CollideDefines.CollideGroup.yellowPlayer,
        bridge = CollideDefines.CollideGroup.yellowBridge,
        name = "黄队"
    },
    [CollideDefines.CollideType.blueTeam] = {
        player = CollideDefines.CollideGroup.bluePlayer,
        bridge = CollideDefines.CollideGroup.blueBridge,
        name = "蓝队"
    }
}

-- 通过碰撞类型获取对应的玩家碰撞组
function CollideDefines:GetPlayerCollideGroupByType(teamType)
    if not self.TeamConfig[teamType] then
        return nil
    end
    return self.TeamConfig[teamType].player
end

-- 通过碰撞类型获取对应的桥梁碰撞组
function CollideDefines:GetBridgeCollideGroupByType(teamType)
    if not self.TeamConfig[teamType] then
        return nil
    end
    return self.TeamConfig[teamType].bridge
end

-- 通过碰撞类型获取对应的碰撞组
function CollideDefines:GetCollideGroupByType(teamType)
    local config = self.TeamConfig[teamType]
    if config then
        return { config.player, config.bridge }
    end
    return {}
end

return CollideDefines
