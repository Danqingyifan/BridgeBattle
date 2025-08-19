--客户端数据管理
local MainStorage = game:GetService('MainStorage')
local EventManager = require(MainStorage.Common.EventManager)

local ClientDataManager = {}

function ClientDataManager:Init()
    -- 注册服务器回调
    local function RegisterServerCallback()
        _G.GameNet:RegServerMsgCallback(
            'CLIENT_DATA_LOADFINISHED',
            function(data)
            end
        )
    end
    RegisterServerCallback()
end

return ClientDataManager
