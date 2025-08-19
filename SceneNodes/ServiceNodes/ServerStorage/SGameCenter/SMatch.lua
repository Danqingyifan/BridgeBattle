-- local MapId = tonumber(game.RunService:GetCurMapOwid())
local SGameCenter = nil
local SMatch = {}

-- 组队开始战斗
-- function(teamInfo, startBattleArgs)
SMatch.OnTeamStartBattle = SandboxNode.New('CustomNotify')

function SMatch:Init(_SGameCenter)
    SGameCenter = _SGameCenter

    -- 客户端至Center的消息，透传一下
    GameNet:RegClientMsgCallback(
        'MATCH_REQUEST',
        function(uin, ...)
            SGameCenter:ToCenter('MatchFromClient', uin, ...)
        end
    )

    GameNet:RegClientMsgCallback(
        'TeamInvitation',
        function(uin, ...)
            SGameCenter:ToCenter('TeamInvitation', uin, ...)
        end
    )

    GameNet:RegClientMsgCallback(
        'RequestTeamInfo',
        function(uin, ...)
            if SGameCenter.CenterRoomId then
                SGameCenter:ToCenter('MatchFromClient', uin, ...)
            else
                -- 中心服没链接上, 伪造一个空队伍信息
                GameNet:SendMsgToClient(uin, 'MATCH_RESPONSE', 'MatchSyncTeam', {})
            end
        end
    )

    -- Center至客户端的消息，透传一下
    function SGameCenter.CenterHandler:MatchToClient(uin, ...)
        GameNet:SendMsgToClient(uin, 'MATCH_RESPONSE', ...)
    end

    -- 匹配成功，进入战场
    function SGameCenter.CenterHandler:EnterTeamMap(uin, gameKey, teleportData)
        local mapId = teleportData.mapId
        print('EnterTeamMap', ' uin:', uin, ' gameKey:', gameKey, ' MapId:', teleportData.mapId)

        local strMapId = tostring(teleportData.mapId)
        if not SGameCenter.MapIdMap[strMapId] then
            return
        end

        print('ReserveServer', 'uin:', uin, 'mapId:', teleportData.mapId, 'gameKey:', gameKey, 'teleportData:', teleportData)
        if game.CloudService:ReserveServer(uin, tonumber(teleportData.mapId), gameKey, teleportData) then
            -- 标记玩家转移地图
            SGameCenter:ToCenter(
                'MatchFromClient',
                uin,
                {
                    typ = 'MarkPlayerTransfering',
                    cls = 'pvz'
                }
            )
        end
    end

    function SGameCenter.CenterHandler:TeleportToServer(uin, teleportData)
        print('TeleportToServer', 'uin:', uin, 'mapId:', teleportData.mapId)
        if teleportData.serverData ~= nil then
            print('ReserveServer', 'uin:', uin, 'mapId:', teleportData.mapId, 'serverData:', teleportData.serverData)
            if (game.CloudService:ReserveServer(uin, teleportData.mapId, teleportData.serverData)) then
                SGameCenter:ToCenter(
                    'MatchFromClient',
                    uin,
                    {
                        typ = 'MarkPlayerTransfering',
                        cls = 'pvz'
                    }
                )
            end
            return
        end

        if teleportData.serverId ~= nil then
            local serverId = game.CloudService:GetServerID()
            if serverId == teleportData.serverId then -- 在同一个房间不用传送
                return
            end

            print('TeleportToServer', 'uin:', uin, 'mapId:', teleportData.mapId, 'serverId:', teleportData.serverId)
            if game.CloudService:TeleportToServer(teleportData.serverId, uin, {}) then
                -- 标记玩家转移地图
                SGameCenter:ToCenter(
                    'MatchFromClient',
                    uin,
                    {
                        typ = 'MarkPlayerTransfering',
                        cls = 'pvz'
                    }
                )
                return
            end
        end

        print('TeleportToMap', 'uin:', uin, 'mapId:', teleportData.mapId, 'serverId:', teleportData.serverId)
        if game.CloudService:TeleportToMap(teleportData.mapId, uin, {}) then
            -- 标记玩家转移地图
            SGameCenter:ToCenter(
                'MatchFromClient',
                uin,
                {
                    typ = 'MarkPlayerTransfering',
                    cls = 'pvz'
                }
            )
            return
        end
    end

    function SGameCenter.CenterHandler:LeaveTeamMap(uin, mapId)
        print('LeaveTeamMap', ' uin:', uin, ' MapId:', mapId)
        -- todo 玩家俩开了队伍专属的地图，需要处理
    end


    -- 开始战斗
    function SGameCenter.CenterHandler:StartBattle(leaderUin, teamInfo, startArgs)
        SMatch.OnTeamStartBattle:Fire(teamInfo, startArgs)
    end
end

function SMatch:OnPlayerAdded(player, second)
    if not second then -- 不是第二次
    -- 首次上线处理
    end
    if self.CenterRoomId then -- 如果Center已连接
    -- 如果有Center有关的事务
    end
end

function SMatch:OnPlayerRemoved(player)
    if SGameCenter.CenterRoomId then
        --下线强制清除一切Match信息
        SGameCenter:ToCenter('MatchRemovePlayer', player.UserId, 'logout')
    end
end

function SMatch:OnTeamBattleFinished(tid, cls)
    SGameCenter:ToCenter("MatchTeamBattleFinished", tid, cls)
end


return SMatch
