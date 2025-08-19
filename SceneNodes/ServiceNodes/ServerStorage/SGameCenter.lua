local CloudService = game:GetService("CloudService")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local SMatch = require(script.SMatch)
local MapTime = os.date("%Y%m%d_%H%M%S", RunService:GetCurMapUpdateTimestamp())
local MapIdMap = {
    -- 正式图
    ["12839541415348"] = "35074587106740",  -- PVZ大厅
    ["12835246448052"] = "35074587106740",  -- PVZ射击
    ["77203921313204"] = "35074587106740",  -- PVZ新塔防
    ["11832672551085"] = "35098510393517",  -- PVZ番薯
    ["58056929683297"] = nil,               -- PVZ旧塔防

    -- 测试图
    ["45850660052404"] = "26274199117236",  -- PVZ射击测试图
    ["26278494084532"] = "26274199117236",  -- PVZ大厅测试图
    ["26282789051828"] = "26274199117236",  -- PVZ塔防测试图
}

local MyMapId = RunService:GetCurMapOwid()
local CenterMapId = MapIdMap[MyMapId]
local CenterMapTag = "pvzgc"

local SGameCenter = {}
_G.SGameCenter = SGameCenter
SGameCenter.MapIdMap = MapIdMap

SGameCenter.CenterRID = nil     -- 用于广播消息的RoomId
SGameCenter.CenterRoomId = nil  -- 用于Tcp连接的RoomId
SGameCenter.CenterHandler = {}

local function send_message(list, ...)
    assert(#list == 1)
    if GameCenterSim then -- 模拟中心服
        assert(list[1] == "single")
        GGameCenter:OnServerMessage("single", ...) 
    else
        CloudService:SendMessage(list, ...)
    end
end

function SGameCenter:Init()
    print("SGameCenter:Init", MapTime, MyMapId, CenterMapId)

    SMatch:Init(self)

    -- 客户端更新中心服的玩家信息
    GameNet:RegClientMsgCallback("UpdateCenterPlayerInfo", function(uin, ...)
        self:ToCenter("UpdateGCPlayerInfo", uin, ...)   
    end)

    if GameCenterSim then   -- 模拟中心服
        print("SGameCenter:Init GameCenterSim")
        self.CenterRID = "single"
        self:OnCenterConnected(true, "single")
        return
    end

    if RunService:GetAppPlatformName()~="CloudServer" then  -- 仅在线云服运行
        return
    end
    if not CenterMapId then
        print("SGameCenter:Init no CenterMapId", MyMapId)
        return
    end

    -- 通知：Server上线
    CloudService:PublishAsync("ServerOnline", MapTime)

    -- 收到：Center上线
    CloudService:SubscribeAsync("CenterOnline", function(rid, ver)
        self:OnCenterOnline(rid, ver)
    end)

    -- 收到：Center消息
    CloudService.NotifyOnMessage:Connect(function(rid, typ, ...)
        self:OnCenterMessage(typ, ...)
    end)

    -- 唤起Center（如果没启动的话）
    CloudService:GetCenterServerAsync(
        CenterMapTag,
        CenterMapId,
        function(ret, roomId) end
    )

    if CloudService.NotifyOnConnectionMessage then
        CloudService.NotifyOnConnectionMessage:Connect(function(event, roomid)
            print("NotifyOnConnectionMessage:", event, roomid)
            if event == 1 then  -- 连接断开
                self:OnCenterDisconnected()
                Wait(math.random(10))  -- 等待一段时间后重连
                CloudService:GetCenterServerAsync(
                    CenterMapTag,
                    CenterMapId,
                    function(ret, roomId)
                        self:OnCenterConnected(ret, roomId)
                    end
                )
            end
        end)
    end
end

function SGameCenter:OnCenterOnline(rid, mpt)
    local CenterRID = self.CenterRID
    print("CenterOnline", rid, mpt, CenterRID, MapTime)
    if CenterRID then   -- 之前的Center掉线
        self:OnCenterDisconnected()
    end
    self.CenterRID = rid
    -- 获取游戏中心房间ID
    CloudService:GetCenterServerAsync(
        CenterMapTag,
        CenterMapId,
        function(ret, roomId)
            self:OnCenterConnected(ret, roomId)
        end
    )
end

function SGameCenter:OnCenterConnected(ret, roomId)
    print("SGameCenter:OnCenterConnected", ret, roomId)
    self.CenterRoomId = roomId
    self:ToCenter("Init", MapTime, CloudService:GetServerID(), MyMapId)
    -- 补调已上线玩家
    for _, p in ipairs(game.Players:GetPlayers()) do
        self:OnPlayerAdded(p, true)
    end
end

function SGameCenter:OnCenterDisconnected()
    self.CenterRoomId = nil
    -- 通知所有客户端：Center断线
    GameNet:BroadcastMsg("GC_DISCONNECT", {reason = "CenterDisconnect"})
end

function SGameCenter:OnCenterMessage(typ, ...)
    local fun = self.CenterHandler[typ]
    if not fun then
        print("SGameCenter:OnCenterMessage no handler:", typ)
        return
    end
    local ok, msg = pcall(fun, self.CenterHandler, ...)
    if not ok then
        print("SGameCenter:OnCenterMessage error", typ, msg)
    end
end

function SGameCenter:OnPlayerAdded(player, second)
    -- 上线通知
    local uin = player.UserId
    print("SGameCenter:OnPlayerAdded", uin, second, self.CenterRoomId, RoomType)
    if not second then    -- 不是第二次
        -- 首次上线处理
    end
    if self.CenterRoomId then   -- 如果Center已连接
        self:ToCenter("PlayerAdded", uin, self:GetPlayerInfo(player))
    end
end

function SGameCenter:OnPlayerRemoved(player)
    -- 下线通知
    if self.CenterRoomId then
        self:ToCenter("PlayerRemoved", player.UserId)
    end
end

function SGameCenter:ToCenter(typ, ...)
    print("Server->Center", typ, ...)
    assert(self.CenterRoomId, "GameCenter not ready")
    send_message({self.CenterRoomId}, typ, ...)
end 

-- 构建玩家信息同步给Center，以便后期查询、匹配用
-- 如有更新，可以另加协议通知Center
function SGameCenter:GetPlayerInfo(player)
    return {
        uin = player.UserId,
        name = player.Nickname,

    }
end

---- Center->Server Handler ----
function SGameCenter.CenterHandler:ToClient(uin, msgkey, ...)
    print("Center->Client", uin, msgkey, ...)
    GameNet:SendMsgToClient(uin, "MATCH_RESPONSE", msgkey, ...)
end

-- 发送消息给组队(把消息发送给中心服)
function SGameCenter:SendMessageToTeam(uin, msg, utc)
    
    if self.CenterRoomId then
        print("SendMessageToTeam Success", uin, msg)
        self:ToCenter("SendMessageToTeam", uin, msg)
        return
    end
    print("SendMessageToTeam Failed", uin, msg)
end

function SGameCenter.CenterHandler:ToBroadcast(msgkey, ...)
    GameNet:BroadcastMsg("MATCH_RESPONSE", msgkey, ...)
end

function SGameCenter:OnTeamBattleFinished(tid, cls)
    SMatch:OnTeamBattleFinished(tid, cls)
end

return SGameCenter
