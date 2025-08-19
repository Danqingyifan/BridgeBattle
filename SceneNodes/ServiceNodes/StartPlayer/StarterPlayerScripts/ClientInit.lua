local MainStorage = game:GetService('MainStorage')
local FriendService = game:GetService("FriendsService")
local RunService = game:GetService("RunService")

_G.GameNet = require(MainStorage.Common.GameNet)

-- Logic Block
_G.Logic = require(MainStorage.Logic.Logic)
_G.LogicHub = require(MainStorage.Logic.LogicHub)

_G.ReportData = require(MainStorage.Common.ReportData)

-- Notify Handler
_G.LogicNotifyHandler = {}

function Logic.OnNotify(logic, typ, ...)
    local func = LogicNotifyHandler[typ]
    if func then
        func(...)
    end
end

-- Logic Block End

local EventManager = require(MainStorage.Common.EventManager)

local PoolManager = require(MainStorage.Subsystem.PoolManager)




_G.SoundManager = require(MainStorage.Subsystem.SoundManager)

local LevelManager = require(MainStorage.Level.LevelManager)
local PlayerController = require(MainStorage.Player.PlayerController)
_G.LevelManager = LevelManager
_G.PlayerController = PlayerController

local GameCenterBridge = require(MainStorage.Common.GameCenterBridge)
_G.GameCenterBridge = GameCenterBridge
_G.ClientDataManager = require(MainStorage.Player.ClientDataManager)

local function Init()
    ClientDataManager:Init()

    LevelManager.Init()
    PlayerController.Init()

    LevelManager.CreateLevel('Lobby')
    LevelManager.StartCheckLoading()

    EventManager.FireEvent(PlayerController.eventObject, 'OnEnterLobby')
    EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnEnterLobby')
    --客户端初始化完成，通知服务器得到数据
    _G.GameNet:SendMsgToServer('CLIENT_KV_LOADFINISHED', {
        IsStudio = RunService:IsStudio(),
    })

    local LocalPlayer = game.Players.LocalPlayer
    local actor = LocalPlayer.Character
    actor.Visible = true
    actor.Visible = false
    actor.Position = Vector3.new(0, -500, 0)
end

local StudioServerFriendList = nil

function _G.GetFriendsList()
    if StudioServerFriendList then
        return StudioServerFriendList
    end
    if FriendService.IsQueryFriendInfoDone then
        while not FriendService:IsQueryFriendInfoDone() do
            Wait(0.1)
        end
    end
    local list = {}
    local count = FriendService:GetSize()
    for i = 1, count do
        local uin, nickName, online = FriendService:GetFriendsInfoByIndex(i-1)
        list[i] = {
            uin = uin,
            nickName = nickName,
            online = online
        }
    end
    return list
end

if RunService:IsStudio() then
    _G.GMCommandHandle = function(commondType, ...)
        GameNet:SendMsgToServer('GM_COMMON_MSG', commondType, ...)
    end
end

_G.GameNet:RegServerMsgCallback(
    'STUDIO_SERVER_PLAYER',
    function(player)
        local myUin = game.Players.LocalPlayer.UserId
        StudioServerFriendList = {}
        if player.uin ~= myUin then
            table.insert(StudioServerFriendList, player)
        end
        for i, uin in ipairs({1834694669, 1834699729, 1834719343, 1835924593}) do
            if uin ~= myUin then
                table.insert(StudioServerFriendList, {
                    uin = uin,
                    nickName = "测试玩家" .. i,
                    online = true,
                })
            end
        end
    end
)

local isLoaded = false

_G.GameNet:RegServerMsgCallback(
    'SERVER_LOADFINISHED',
    function(msg)
        isLoaded = true
        local mapId = msg.MapId
        print('MapId', mapId)
        GameCenterBridge.Data.SelectedMapId = tonumber(mapId)

        if msg.SimulatePlayerId then
            print(string.format("正在使用玩家 %s 的数据游玩", msg.SimulatePlayerId))
        end
    end
)

while not isLoaded do
    wait(1)
end


GameCenterBridge.PlayerRequest:RequestTeamInfo()

local maxWaitTime = 10

local waitTime = 0
while not GameCenterBridge.Data.TeamInfo do
    waitTime = waitTime + 1
    if waitTime > maxWaitTime then
        GameCenterBridge.Data.TeamInfo = {}
        break
    end
    wait(1)
end

Init()
