-- 客户端请求协议
_G.ClientMsgID = {
    'TEST', --  测试
    -- GM指令
    -- 卡牌相关
    'GET_ZOMBIE_STORM_CARDS', --  获取僵尸风暴卡牌
    'UPGRADE_ZOMBIE_STORM_CARD', --  升级僵尸风暴卡牌
    -- 商店相关
    'PURCHASE_TREASURE', --  购买宝箱

    'CHECK_ENERGY_ENOUGH', -- 检查体力是否足够
    -- 迷你地图相关
    'TELEPORT_REQUEST', --  传送请求
    -- 关卡相关
    'UNLOCK_LEVEL_PROGRESS', --  解锁关卡进度
    'SET_SELECTED_LEVEL_MODE_REQUEST', --  设置选择模式
    'SET_SELECTED_LEVEL_REQUEST', --  设置选择关卡
    'GET_SELECTED_LEVEL_MODE_REQUEST', --  获取选择模式
    'GET_SELECTED_LEVEL_REQUEST', --  获取选择关卡
    'GET_STOP_SETTLEMENT',
    'CLIENT_DATA_LEVEL_PROGRESS_LIST',
    --结束奖励
    -- 组队相关
    'MATCH_REQUEST', --  匹配请求
    'RequestTeamInfo', --  请求队伍信息
    'TeamInvitation', --  组队邀请相关
    'UpdateCenterPlayerInfo', --  更新中心服玩家信息

    'HallTextChatClientMsg', -- 大厅文本聊天消息
    'GameTextChatClientMsg', -- 游戏文本聊天消息
    'FriendChatRecordMsg', -- 请求好友聊天记录

    'CardChatClientMsg', -- 卡片通知信息
    'VoiceClientMsg', -- 语音客户端消息
    'NewcomerGiftPackClientMsg', -- 新人礼包信息
    -- 客户端kv加载完成
    'CLIENT_KV_LOADFINISHED', -- 客户端kv加载完成
    'GM_COMMON_MSG', -- GM通用消息

    'RankingListClientMsg',     -- 排行榜客户端信息
    'RankingHubServerMsg',      -- 排行榜服务器信息, Hub使用

    'GUIDE_APPLY_SET', -- 新手引导记录步骤
}

-- 服务器返回协议
_G.ServerMsgID = {
    'TEST_RESPONSE', --  测试响应
    -- GM指令
    'CLEAR_ZOMBIE_STORM_CARDS_RESPONSE', --  清除僵尸风暴卡牌响应
    'ADD_DIAMOND_RESPONSE', --  添加钻石响应
    'STUDIO_SERVER_PLAYER', --  本地云服玩家信息
    -- 货币相关
    'UPDATE_CURRENCY_COUNT', -- 更新货币数量
    -- 卡牌相关
    'UPDATE_ZS_CARD_EXP', --  更新僵尸风暴卡牌经验
    'UPDATE_ZS_CARD_LEVEL', --  更新僵尸风暴卡牌等级

    'GET_ZOMBIE_STORM_CARDS_RESPONSE', --  获取僵尸风暴卡牌响应
    'UPGRADE_ZOMBIE_STORM_CARD_RESPONSE', --  升级僵尸风暴卡牌响应
    'ADD_ZSCARD_RESPONSE', --  添加僵尸风暴卡牌响应
    -- 商店相关
    'PURCHASE_TREASURE_RESPONSE', --  购买宝箱响应
    -- 体力相关
    'UPDATE_TEAM_END_RESPONSE', --  更新队伍结束响应
    'UPDATE_ENERGY_VALUE', -- 增加体力响应
    'CHECK_ENERGY_ENOUGH_RESPONSE', -- 检查体力是否足够响应
    -- 迷你地图相关
    'TELEPORT_RESPONSE', --  传送响应
    -- 关卡相关
    'UNLOCK_LEVEL_PROGRESS_RESPONSE', --  解锁关卡进度响应
    'GET_SELECTED_LEVEL_MODE_RESPONSE', --  获取选择模式响应
    'GET_SELECTED_LEVEL_RESPONSE', --  获取选择关卡响应
    'SET_SELECTED_LEVEL_MODE_RESPONSE', --  设置选择模式响应
    'SET_SELECTED_LEVEL_RESPONSE', --  设置选择关卡响应
    'SETTLEMENT_REWARD_RESPONSE', --  结算奖励响应
    -- 组队相关
    'MATCH_RESPONSE', --  匹配响应
    'SERVER_LOADFINISHED', --  服务器加载完成
    'GC_DISCONNECT', --  中心服断开连接
    'HallTextChatServerMsg', -- 大厅文本聊天消息
    'GameTextChatServerMsg', -- 游戏文本聊天消息
    'FriendChatRecordMsg', -- 请求好友聊天记录

    'CardChatServerMsg', -- 卡片通知信息
    'VoiceServerMsg', -- 语音服务器消息
    'RoomPlayerIndexUpdate', -- 房间玩家数更新
    'NewcomerGiftPackServerMsg', -- 新人礼包信息
    -- 客户端kv加载完成
    'CLIENT_KV_LOADFINISHED_RESPONSE', -- 客户端kv加载完成响应
    'SHOW_WARN_POP', -- 显示警告弹窗
    --客户端数据管理
    'CLIENT_DATA_LOADFINISHED',--客户端数据初始化
    'CLIENT_DATA_LEVEL_PROGRESS_LIST',--客户端数据关卡进度列表

    'RankingListServerMsg',     -- 排行榜服务器信息
    'RankingHubServerMsg',      -- 排行榜服务器信息, 返回给Hub使用

    'GUIDE_UPDATE_DATA', -- 新手引导更新步骤
}

local ClientMsgMap = {}
for idx, msgName in ipairs(ClientMsgID) do
    ClientMsgMap[msgName] = idx
end

local ServerMsgMap = {}
for idx, msgName in ipairs(ServerMsgID) do
    ServerMsgMap[msgName] = idx
end

_G.GetClientMsgId = function(key)
    return ClientMsgMap[key]
end

_G.GetServerMsgId = function(key)
    return ServerMsgMap[key]
end
