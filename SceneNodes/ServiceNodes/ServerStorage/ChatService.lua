
local CloudService = game:GetService("CloudService")
local VoiceChatService = game:GetService("VoiceChatService")

local ChatService = {}
_G.ChatService = ChatService

local ChatTypeEnum = {
    Room = 0, -- 当前房间
    All = 1, -- 所有房间
    Private = 2, -- 私密
    Team = 3, -- 组队
}

local ClientMsgType = {
    Hall = 0, -- 大厅消息
    Game = 1, -- 游戏消息
    Card = 2, -- 卡片消息
}

local ActiveTipEnum = {
    AddFriend = 0, -- 添加好友提示
    InviteTeam = 1, -- 邀请组队
}
function ChatService:Init()
    -- 大厅消息
    GameNet:RegClientMsgCallback("HallTextChatClientMsg", function (playerId, MsgInfo)
        local utcNow = os.time()
        print("HallTextChatClientMsg", MsgInfo.Id, playerId, MsgInfo.Msg , utcNow)
        if MsgInfo.Id == ChatTypeEnum.Private then
            ChatService.UpdateFriendChatRecord(playerId, MsgInfo.Target, {message = MsgInfo.Msg, utc = utcNow})
            ChatService.SendMessageToTargetPlayer(MsgInfo.Target, MsgInfo.Msg, playerId, false, ClientMsgType.Hall, utcNow)
        elseif MsgInfo.Id == ChatTypeEnum.Team then
            ChatService.SendMessageToTeam(MsgInfo.Target, MsgInfo.Msg,playerId, ClientMsgType.Hall, utcNow)
        else
            ChatService.SendMessageToAllClient(playerId, MsgInfo.Id, MsgInfo.Msg, ClientMsgType.Hall, utcNow)
        end
    end)

    -- 游戏内消息
    GameNet:RegClientMsgCallback("GameTextChatClientMsg", function (playerId, MsgInfo)
        local utcNow = os.time()
        print("GameTextChatClientMsg", MsgInfo.Id, playerId, MsgInfo.Msg, utcNow)
        if MsgInfo.Id == ChatTypeEnum.Team then
            ChatService.SendMessageToTeam(MsgInfo.Target, MsgInfo.Msg,playerId, ClientMsgType.Game, utcNow)
        else
            ChatService.SendMessageToAllClient(playerId, ChatTypeEnum.Room, MsgInfo.Msg, ClientMsgType.Game, utcNow)
        end
    end)

    -- 卡片通知消息
    GameNet:RegClientMsgCallback("CardChatClientMsg",function (playerId, MsgInfo)
        local utcNow = os.time()
        if MsgInfo.Id == ActiveTipEnum.AddFriend then
            ChatService.SendMessageToTargetPlayer(MsgInfo.Target, MsgInfo.Msg, playerId, false, ClientMsgType.Card, utcNow)
        end
    end)

    -- 语音加入消息
    GameNet:RegClientMsgCallback("VoiceClientMsg",function (playerId, MsgInfo)
        
        if MsgInfo.bSpeakerStatus then -- 扬声器开关
            VoiceChatService:SetSpeakerStatus(playerId, MsgInfo.status)
            --local SpeakerStatus = VoiceChatService:GetSpeakerStatus(playerId)
            local SpeakerStatus = MsgInfo.status
            GameNet:SendMsgToClient(playerId, "VoiceServerMsg", {playId = playerId, status = SpeakerStatus, enum = nil, bSpeakerStatus = true})
            return
        end

        if MsgInfo.Id == nil then
            local bSuccess = VoiceChatService:QuitAllVoiceChannel(playerId)
            if bSuccess == false then
                print("Error: Quit Voice , ID:", playerId)
            end
            GameNet:SendMsgToClient(playerId, "VoiceServerMsg", {playId = playerId, status = bSuccess, enum = nil})
            return
        end
        if MsgInfo.PlayerTeamId and MsgInfo.Id == ChatTypeEnum.Team then -- 是否有队伍
            local bSuccess = ChatService.JoinTeamVoiceChannel(playerId, MsgInfo.PlayerTeamId)
            --local bSuccess = VoiceChatService:JoinVoiceChannel(playerId, "GameTeamVoice_" .. tostring(ChatMgr.PlayerTeamId))
            --local bSuccess = VoiceChatService:JoinVoiceChannel(playerId, VoiceChatService.Team.ChannelID) -- 对应VoiceChatService.Team
            if bSuccess == false then
                print("Error: Join Team Voice , ID:", playerId)
            end
            GameNet:SendMsgToClient(playerId, "VoiceServerMsg", {playId = playerId, status = bSuccess, enum = ChatTypeEnum.Team})
            return
        end

        if MsgInfo.Id == ChatTypeEnum.Room then
            local ServerID = CloudService:GetServerID()
            --local bSuccess = VoiceChatService:JoinVoiceChannel(playerId, "GameRoomVoice_" .. tostring(ServerID))
            
            local bSuccess = VoiceChatService:JoinVoiceChannel(playerId, VoiceChatService.Room.ChannelID) -- 对应VoiceChatService.Room
            if bSuccess == false then
                print("Error: Join Room Voice , ID:", playerId)
            end
            GameNet:SendMsgToClient(playerId, "VoiceServerMsg", {playId = playerId, status = bSuccess, enum = ChatTypeEnum.Room})
        end

    end)

    GameNet:RegClientMsgCallback("FriendChatRecordMsg", ChatService.RequestFriendChatRecord)

    CloudService:SubscribeAsync("AllRoomChatMsg", function(uid, msgInfo) 
        print("SubscribeAsync: AllRoomChatMsg", msgInfo.owner, msgInfo)
        ChatService.SendMessageToAllClient(msgInfo.owner, ChatTypeEnum.Room, msgInfo.msg, msgInfo.type, msgInfo.utc, true) 
    end)
    CloudService:SubscribeAsync("TargetPlayerChatMsg", function(uid, msgInfo) 
        if msgInfo.ServerId == CloudService:GetServerID() then return end --同一个服务器不再发送
        ChatService.SendMessageToTargetPlayer(msgInfo.owner, msgInfo.Msg, msgInfo.playId, true, msgInfo.type, msgInfo.utc)
    end)

    -- 聊天记录缓存
    ChatService.ChatRecordMapCache = {--[[
      [聊天记录Key] = {
        dirty = false,
        messages = { 消息内容... }      
      }  
    ]]}

    -- 聊天记录保存队列
    ChatService.ChatRecordSaveKeyQueue = {}

    -- 聊天记录定时保存协程
    coroutine.work(function()
        while true do
            Wait(10)                        -- 十秒钟保存一条聊天记录
            if #ChatService.ChatRecordSaveKeyQueue > 0 then
                local chatRecordKey = table.remove(ChatService.ChatRecordSaveKeyQueue, 1)
                local chatRecord = ChatService.ChatRecordMapCache[chatRecordKey]
                if chatRecord and chatRecord.dirty then
                    chatRecord.dirty = false
                    CloudService:SetTableAsync(chatRecordKey, chatRecord.messages, function(success)end)
                end
            end
        end
    end)
end

function ChatService.JoinTeamVoiceChannel(uin, teamId)
    local bSuccess = false
    if teamId then
        bSuccess = VoiceChatService:SpecificJoinVoiceChannel(uin, "GameTeamVoice_" .. tostring(teamId)) -- 对应VoiceChatService.Team
    end

    return bSuccess
end

function ChatService.GetSendMsgID(type)
    local SendMsgID = "HallTextChatServerMsg"
    if type == ClientMsgType.Game then
        SendMsgID = "GameTextChatServerMsg"
    elseif type == ClientMsgType.Card then
        SendMsgID = "CardChatServerMsg"
    end
    return SendMsgID
end

-- 发送消息给所有客户端
function ChatService.SendMessageToAllClient(uid, enum, msg, type, utc, bMul)
    if #msg == 0 then return end
    if uid then
        if enum == ChatTypeEnum.All then
            print("PublishAsync: AllRoomChatMsg")
            CloudService:PublishAsync("AllRoomChatMsg", {msg = msg, type = type, owner = uid, utc = utc})
        elseif enum == ChatTypeEnum.Room then
            if bMul then
                GameNet:BroadcastMsg(ChatService.GetSendMsgID(type), {playId = uid, message = msg, enum = ChatTypeEnum.All , utc = utc})
            else
                GameNet:BroadcastMsg(ChatService.GetSendMsgID(type), {playId = uid, message = msg, enum = enum , utc = utc})
            end
        end
    end
end

function ChatService.SendRoomPlayerIndex(Index)
    print("SendRoomPlayerIndex", Index)
    GameNet:BroadcastMsg("RoomPlayerIndexUpdate", {Index = Index})
end

-- 发送消息给目标玩家
function ChatService.SendMessageToTargetPlayer(uid, msg, playerId, bMul, type, utc)
    if #msg == 0 then return end

    if not uid then return end
    print("SendMessageToTargetPlayer", uid, msg, playerId, bMul, type)
    for _, player in ipairs(game.Players:GetPlayers()) do
        local uin = player.UserId
        if uin == uid then
            GameNet:SendMsgToClient(uin, ChatService.GetSendMsgID(type), {playId = playerId, message = msg, enum =ChatTypeEnum.Private, utc = utc})
            return
        end
    end

    if bMul then return end
    -- 如果走到这里，证明玩家不在同一频道里面，需要在其他频道找找
    local ServerID = CloudService:GetServerID()
    CloudService:PublishAsync("TargetPlayerChatMsg", {ServerId = ServerID, Msg = msg, playId = playerId, type = type, owner = uid, utc = utc})
    
end

-- 发送消息给组队
function ChatService.SendMessageToTeam(TeamId, msg, playerId, type, utc)
    if #msg == 0 then return end
    print("ChatService::SendMessageToTeam", msg, playerId)
    SGameCenter:SendMessageToTeam(playerId, msg, utc)

    --if TeamId == nil then return end
    --for _, player in ipairs(game.Players:GetPlayers()) do
    --    local uin = player.UserId
    --    --if uin == playerId then goto continue end
    --    local PlayerTeamId = GMatch:GetPlayerTeamId(uin)
    --    if TeamId == PlayerTeamId then
    --        GameNet:SendMsgToClient(uin, ChatService.GetSendMsgID(type), {playId = playerId, message = msg, enum =ChatTypeEnum.Team, utc = utc})
    --    end
    --end

end


function ChatService.CalcFriendChatRecordKey(uin, targetUin)
    local strUin = tostring(uin)
    local strTargetUin = tostring(targetUin)
    if uin < targetUin then
        return "ChatRecord_" .. strUin .. "_" .. strTargetUin
    else
        return "ChatRecord_" .. strTargetUin .. "_" .. strUin
    end
end

function ChatService.SplitFriendChatRecordKey(chatRecordKey)
    local strUin = string.match(chatRecordKey, "ChatRecord_(%d+)_")
    local strTargetUin = string.match(chatRecordKey, "_(%d+)")
    return strUin, strTargetUin
end

-- 玩家下线, 保存聊天记录
function ChatService.OnPlayerRemoving(player)
    local uin = player.UserId
    local eraseKeys = {}
    for chatRecordKey, chatRecord in pairs(ChatService.ChatRecordMapCache) do
        if string.find(chatRecordKey, tostring(uin)) then
            if chatRecord.dirty then
                CloudService:SetTableAsync(chatRecordKey, chatRecord.messages, function(success)end)
                chatRecord.dirty = false
            end
            local strUin, strTargetUin = ChatService.SplitFriendChatRecordKey(chatRecordKey)
            if game.Players:GetPlayerByUserId(tonumber(strTargetUin)) == nil and 
               game.Players:GetPlayerByUserId(tonumber(strUin)) == nil then
                table.insert(eraseKeys, chatRecordKey)  
            end
        end
    end
    
    -- 删除包含该玩家ID的聊天记录缓存
    for _, key in ipairs(eraseKeys) do
        ChatService.ChatRecordMapCache[key] = nil
    end
end

function ChatService.UpdateFriendChatRecord(targetUin, uin, ChatRecord)
    local chatRecordKey = ChatService.CalcFriendChatRecordKey(uin, targetUin)
    local chatRecord = ChatService.ChatRecordMapCache[chatRecordKey]
    if not chatRecord then
        return
    end

    if #chatRecord.messages >= 20 then
        table.remove(chatRecord.messages, 1)
    end
    table.insert(chatRecord.messages, {playId = targetUin, message = ChatRecord.message, utc = ChatRecord.utc})
    chatRecord.dirty = true
    table.insert(ChatService.ChatRecordSaveKeyQueue, chatRecordKey)
end

function ChatService.RequestFriendChatRecord(uin, targetUin)
    local chatRecordKey = ChatService.CalcFriendChatRecordKey(uin, targetUin)
    local chatRecord = ChatService.ChatRecordMapCache[chatRecordKey]
    if chatRecord and chatRecord.messages then
        if #chatRecord.messages > 0 then
            GameNet:SendMsgToClient(uin, "FriendChatRecordMsg", targetUin, chatRecord.messages)
        end
        return
    end

    ChatService.ChatRecordMapCache[chatRecordKey] = {dirty = false, messages = {}}
    coroutine.work(function()
        local ret, data = CloudService:GetTableOrEmpty(chatRecordKey)
        if not ret then
            return
        end

        ChatService.ChatRecordMapCache[chatRecordKey] = {dirty = false, messages = data}
        if #data > 0 then
            GameNet:SendMsgToClient(uin, "FriendChatRecordMsg", targetUin, data)
        end
    end)
end

return ChatService