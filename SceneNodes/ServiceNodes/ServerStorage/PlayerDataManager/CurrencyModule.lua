local CurrencyModule = {}
local ServerStorage = game:GetService('ServerStorage')
local ZSDataService = require(ServerStorage.KVStorage.ZSDataService)

function CurrencyModule.Init()
    _G.GameNet:RegClientMsgCallback(
        'GET_CURRENCY',
        function(playerId)
            CurrencyModule.GetCurrency(playerId)
        end
    )

    _G.GameNet:RegClientMsgCallback(
        'ADD_CURRENCY',
        function(playerId, amount, reason)
            CurrencyModule.AddCurrency(playerId, amount, reason)
        end
    )
    _G.GameNet:RegClientMsgCallback(
        'CONSUME_CURRENCY',
        function(playerId, amount)
            CurrencyModule.ConsumeCurrency(playerId, amount)

        end
    )
end

function CurrencyModule.GetCurrency(playerId)
    print("服务器收到获取货币请求".. "玩家ID：".. tostring(playerId))
    local currency = ZSDataService:GetZombieStormCurrency(playerId)
    _G.GameNet:SendMsgToClient(playerId, 'GET_CURRENCY_RESPONSE', currency)
    _G.GameNet:SendMsgToClient(playerId, 'UPDATE_CURRENCY_COUNT', currency)
end

function CurrencyModule.CheckCurrency(playerId, amount)
    return ZSDataService:CheckZombieStormCurrency(playerId, amount)
end

function CurrencyModule.ConsumeCurrency(playerId, amount, reason)
    print("服务器收到消耗货币请求".. "玩家ID：".. tostring(playerId).. " 消耗货币：".. tostring(amount))
    local success, currency = ZSDataService:ConsumingZombieStormCurrency(playerId, amount, reason)
    _G.GameNet:SendMsgToClient(playerId, 'UPDATE_CURRENCY_COUNT', currency)
    return currency
end

function CurrencyModule.AddCurrency(playerId, amount, reason)
    print("服务器收到添加货币请求".. "玩家ID：".. tostring(playerId).. " 添加货币：".. tostring(amount))
    local currency = ZSDataService:AddZombieStormCurrency(playerId, amount, reason)
    _G.GameNet:SendMsgToClient(playerId, 'UPDATE_CURRENCY_COUNT', currency)
    return currency
end

function CurrencyModule.SetCurrency(playerId, amount)
    print("服务器收到设置货币请求".. "玩家ID：".. tostring(playerId).. " 设置货币：".. tostring(amount))
    local currency = ZSDataService:SetZombieStormCurrency(playerId, amount)
    _G.GameNet:SendMsgToClient(playerId, 'UPDATE_CURRENCY_COUNT', currency)
    return currency
end

return CurrencyModule
