local ServerGlobalEvent = {
    -- func(playerId)
    OnPlayerKVLoadFinished = SandboxNode.New("CustomNotify"),   -- 玩家KV数据加载完成事件

    -- func(playerId)
    OnPlayerKVLoadFailed = SandboxNode.New("CustomNotify"),      -- 玩家KV数据加载失败事件

    -- func(playerId)
    OnPlayerDataSaving = SandboxNode.New("CustomNotify"),       -- 玩家KV数据保存事件

    -- func(dt)
    OnServerUpdate = SandboxNode.New("CustomNotify"),          -- 服务端每帧更新事件

    -- func(player)
    OnPlayerAdded = SandboxNode.New("CustomNotify"),           -- 玩家加入事件

    -- func(player)
    OnPlayerRemoving = SandboxNode.New("CustomNotify"),        -- 玩家离开事件
}

return ServerGlobalEvent