local PlayerServerData = {
    PlayerList = {}
}

-- 初始化玩家数据
function PlayerServerData.Init()
    _G.GameNet:RegClientMsgCallback(
        'CLIENT_KV_LOADFINISHED',
        function(playerId, msgBody)
            PlayerServerData.OnPlayerAdded(playerId, msgBody)
        end
    )
end

function PlayerServerData.OnPlayerAdded(playerId, msgBody)
    --玩家加入，发送数据
    PlayerServerData.PlayerList[playerId] = {}
    local data = {}
    _G.GameNet:SendMsgToClient(playerId, 'CLIENT_DATA_LOADFINISHED', data)
end

function PlayerServerData.OnPlayerRemoved(player)
    PlayerServerData.PlayerList[player.UserId] = nil
end

return PlayerServerData
