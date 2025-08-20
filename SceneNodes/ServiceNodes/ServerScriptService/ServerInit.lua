local MainStorage = game:GetService('MainStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

_G.GameNet = require(MainStorage.Common.GameNet)

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

_G.PlayerServerData = require(ServerStorage.PlayerServerData)

local TeamManager = require(ServerStorage.TeamManager)
local DevelopStoreManager = require(ServerStorage.DevelopStoreManager)

local MapManager = require(ServerStorage.MapManager)

local function Init()
    PlayerServerData.Init()
    -- TeamManager.Init()
    -- StoreManager.Init()
    -- ChatService:Init()
    -- RankingListService:Init()
    -- -- 玩家上线
    -- Players.PlayerAdded:Connect(
    --     function(player)
    --         KVStoreService:OnPlayerAdded(player)
    --     end
    -- )
    -- -- 玩家离线
    -- Players.PlayerRemoving:Connect(
    --     function(player)
    --         ServerGlobalEvent.OnPlayerDataSaving:Fire(player.UserId)
    --         ChatService.OnPlayerRemoving(player)
    --         KVStoreService:OnPlayerRemoving(player)
    --     end
    -- )

    -- -- 下线
    -- RunService.Stepped:Connect(
    --     function()
    --         KVStoreService:Update()
    --     end
    -- )

    -- ServerGlobalEvent.OnPlayerKVLoadFinished.Notify:Connect(
    --     function(playerId)
    --         _G.GameNet:SendMsgToClient(playerId, 'SERVER_LOADFINISHED')
    --     end
    -- )
end

Init()
