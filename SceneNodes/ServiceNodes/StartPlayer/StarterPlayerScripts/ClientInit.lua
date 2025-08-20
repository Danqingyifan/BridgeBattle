local MainStorage = game:GetService('MainStorage')

_G.GameNet = require(MainStorage.Common.GameNet)
_G.EventManager = require(MainStorage.Common.EventManager)
_G.PoolManager = require(MainStorage.Common.PoolManager)

_G.PlayerClientData = require(MainStorage.Player.PlayerClientData)
_G.PlayerController = require(MainStorage.Player.PlayerController)

local function Init()
    PlayerClientData.Init()
    PlayerController.Init()
    --客户端初始化完成，通知服务器得到数据
    -- _G.GameNet:SendMsgToServer('CLIENT_KV_LOADFINISHED')
end

Init()
