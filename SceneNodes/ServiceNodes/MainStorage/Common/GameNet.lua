local RunService = game:GetService("RunService")
local RemoteEvent = script.RemoteEvent
require(script.GameNetProtocol)

local GameNet = {}

local function IsClientMsgId(msgId)
    return ClientMsgID[msgId] ~= nil
end

local function IsServerMsgId(msgId)
    return ServerMsgID[msgId] ~= nil
end


if RunService:IsClient() then
    GameNet.ClientCallbackMap = {}

    -- 注册服务器消息
    -- msgName: 服务器消息名
    -- func: 回调函数, function(...)
    -- obj: 可选的对象, 如果有这个对象就是 func 就是成员函数
    function GameNet:RegServerMsgCallback(msgName, func, obj)
        local msgId = GetServerMsgId(msgName)
        if msgId == nil then
            error("RegServerMessage invalid parameter msgId: "..tostring(msgName))
        end
        if type(func) ~= "function" then
            error("RegServerMessage invalid parameter 'callback'")
        end
        if self.ClientCallbackMap[msgId] then
            error("RegServerMessage func already exists")
        end
        if type(obj) ~= "nil" and type(obj) ~= "table" then
            error("RegServerMessage invalid parameter 'obj'")
        end
        if obj ~= nil then
            self.ClientCallbackMap[msgId] = function(...)
                func(obj, ...)
            end
        else
            self.ClientCallbackMap[msgId] = func
        end
    end

    -- 取消注册的服务器消息
    -- msg: 服务器消息ID
    function GameNet:UnRegServerMsgCallback(msgName)
        local msgId = GetServerMsgId(msgName)
        if msgId == nil then
            error("UnRegServerMessage invalid parameter 'msgId'")
        end
        if self.ClientCallbackMap[msgId] then
            self.ClientCallbackMap[msgId] = nil
        end
    end

    -- 发送消息到服务器
    -- msgName: 客户端协议名
    -- args: 消息内容
    function GameNet:SendMsgToServer(msgName, ...)
        local msgId = GetClientMsgId(msgName)
        if msgId == nil then
            error("SendMessageToServer invalid parameter 'msgId'")
        end
        RemoteEvent:FireServer(msgId, ...)
    end

    RemoteEvent.OnClientNotify:Connect(function(msgId, ...)
        local callback = GameNet.ClientCallbackMap[msgId]
        if callback ~= nil then
            callback(...)
        end
    end) 
end




if RunService:IsServer() then
    GameNet.ServerCallbackMap = {}
    -- 注册客户端消息
    -- msg: 客户端消息ID
    -- func: 回调函数 function(playerId, ...)
    -- obj:  可选的对象, 如果有这个对象就是 func 就是成员函数
    function GameNet:RegClientMsgCallback(msgName, func, obj)
        local msgId = GetClientMsgId(msgName)
        if msgId == nil then
            error("RegClientMessage invalid parameter 'msgId'")
        end
        if type(func) ~= "function" then
            error("RegClientMessage invalid parameter 'callback'")
        end
        if self.ServerCallbackMap[msgId] then
            error("RegClientMessage func already exists")
        end
        if type(obj) ~= "nil" and type(obj) ~= "table" then
            error("RegClientMsgCallback invalid parameter 'obj'")
        end
        if obj ~= nil then
            self.ServerCallbackMap[msgId] = function(playerId, ...)
                func(obj, playerId, ...)
            end
        else
            self.ServerCallbackMap[msgId] = func
        end
    end

    -- 取消注册的客户端消息
    -- msg: 客户端消息ID
    function GameNet:UnRegClientMsgCallback(msgName)
        local msgId = GetClientMsgId(msgName)
        if msgId == nil then
            error("UnRegClientMessage invalid parameter 'msgId'")
        end
        self.ServerCallbackMap[msgId] = nil
    end

    -- 发送消息到客户端
    -- playerId: 玩家ID
    -- msgName: 服务器协议名
    -- args: 消息内容
    function GameNet:SendMsgToClient(playerId, msgName, ...)
        local msgId = GetServerMsgId(msgName)
        if msgId == nil then
            error("UnRegClientMessage invalid parameter 'msgId'")
        end
        RemoteEvent:FireClient(playerId, msgId, ...)
    end

    -- 广播消息到所有客户端
    -- msg: 客户端消息ID
    -- msgBody: 消息体
    function GameNet:BroadcastMsg(msgName, ...)
        local msgId = GetServerMsgId(msgName)
        if msgId == nil then
            error("BroadcastMessage invalid parameter 'msgId'")
        end
        RemoteEvent:FireAllClients(msgId, ...)
    end

    RemoteEvent.OnServerNotify:Connect(function(playerId, msgId, ...)
        local callback = GameNet.ServerCallbackMap[msgId]
        if callback ~= nil then
            callback(playerId, ...)
        end
    end)
end

return GameNet