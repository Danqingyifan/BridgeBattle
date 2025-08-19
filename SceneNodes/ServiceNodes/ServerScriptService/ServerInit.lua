local MainStorage = game:GetService('MainStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local OnlineService = game:GetService('OnlineService')

_G.GameNet = require(MainStorage.Common.GameNet)

-- GameCenter
local SGameCenter = require(ServerStorage.SGameCenter)
--==模拟中心服==--
-- 在GameServer环境中，模拟GameCenter的逻辑
-- 开启方法：从GC导出节点中复制 ServerScriptService\GameCenterMain\GGameCenter
--   到本GS的导出节点 ServerStorage\GGameCenter 处，随后导入节点
--   （包含GGameCenter目录、GGameCenter.json、GGameCenter.lua）
local GGameCenterScript = ServerStorage.GGameCenter
if GGameCenterScript then
    print('GGameCenter simulation start')
    _G.GameCenterSim = true
    require(GGameCenterScript)
end
-- GameCenter End

-- KV
_G.PlayerKVTableEnum = require(ServerStorage.KVStorage.KVStoreService.PlayerKVTableEnum)

local KVStoreService = require(ServerStorage.KVStorage.KVStoreService)
local ServerGlobalEvent = require(ServerStorage.KVStorage.ServerGlobalEvent)
local PlayerDataService = require(ServerStorage.KVStorage.PlayerDataService)

_G.KVStoreService = KVStoreService
_G.ServerGlobalEvent = ServerGlobalEvent
_G.PlayerDataService = PlayerDataService
KVStoreService:StartService()
-- KV End

-- GM
local GMService = require(MainStorage.Common.GMService)
-- GM End

-- Logic
_G.LogicHub = require(MainStorage.Logic.LogicHub)
_G.Logic = require(MainStorage.Logic.Logic)
-- Logic End

_G.ReportData = require(MainStorage.Common.ReportData)
_G.PlayerDataManager = require(ServerStorage.PlayerDataManager)

local MapManager = require(ServerStorage.MapManager)
local TeamManager = require(ServerStorage.TeamManager)
local ShopManager = require(ServerStorage.ShopManager)
local StoreManager = require(ServerStorage.StoreManager)
local ChatService = require(ServerStorage.ChatService)
local NewcomerGiftService = require(ServerStorage.NewcomerGiftService)
local RankingListService = require(ServerStorage.RankingListService)

local IsStudioServer = RunService:GetAppPlatformName()=="PC"
local StudioServerPlayer = nil

_G.TeamManager = TeamManager

local function Init()
    SGameCenter:Init()

    GMService.Init()
    PlayerDataManager.Init()
    MapManager.Init()
    TeamManager.Init()
    ShopManager.Init()
    StoreManager.Init()
    ChatService:Init()
    NewcomerGiftService:Init()

    RankingListService:Init()
    -- 玩家上线
    Players.PlayerAdded:Connect(
        function(player)
            if IsStudioServer then
                StudioServerPlayer = StudioServerPlayer or {
                    uin = player.UserId,
                    nickName = player.Nickname,
                    online = true,
                }
                _G.GameNet:SendMsgToClient(player.UserId, 'STUDIO_SERVER_PLAYER', StudioServerPlayer)
            end
            
            KVStoreService:OnPlayerAdded(player)
            SGameCenter:OnPlayerAdded(player)
            pcall(function ()
                local RoomPlayerIndex = #(Players:GetPlayers())
                ChatService.SendRoomPlayerIndex(RoomPlayerIndex)
            end)

            -- 设置玩家的位置, 避免玩家在大厅里面显示
            local actor = player.Character
            actor.Visible = true
            actor.Visible = false
            actor.Position = Vector3.new(0, -500, 0)
        end
    )

    -- 玩家离线
    Players.PlayerRemoving:Connect(
        function(player)
            PlayerDataService:SetLastMapID(player.UserId, RunService:GetCurMapOwid())
            ServerGlobalEvent.OnPlayerDataSaving:Fire(player.UserId)
            SGameCenter:OnPlayerRemoved(player)
            ChatService.OnPlayerRemoving(player)
            KVStoreService:OnPlayerRemoving(player)
            pcall(function ()
                local RoomPlayerIndex = #(Players:GetPlayers())
                ChatService.SendRoomPlayerIndex(RoomPlayerIndex)
            end)
        end
    )

    -- 下线
    RunService.Stepped:Connect(
        function()
            KVStoreService:Update()
        end
    )

    ServerGlobalEvent.OnPlayerKVLoadFinished.Notify:Connect(
        function(playerId)
            local data = {
                MapId = tonumber(RunService:GetCurMapOwid()),
            }
            if KVStoreService:GetSimulateLoginPlayerId(playerId) ~= playerId then
                data.SimulatePlayerId = KVStoreService:GetSimulateLoginPlayerId(playerId)
            end
            _G.GameNet:SendMsgToClient(playerId, 'SERVER_LOADFINISHED', data)
            NewcomerGiftService:DidPlayerClaimIt(playerId, 1)
        end
    )

    -- 玩家kv数据加载失败, 踢出玩家
    ServerGlobalEvent.OnPlayerKVLoadFailed.Notify:Connect(
        function(playerId)
            print('kv load failed, kick player ', playerId)
            OnlineService:HostKickClient(playerId)
        end
    )
end

Init()
