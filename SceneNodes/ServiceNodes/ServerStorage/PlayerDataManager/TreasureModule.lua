local TreasureModule = {}

local ServerStorage = game:GetService('ServerStorage')
local ZSDataService = require(ServerStorage.KVStorage.ZSDataService)

function TreasureModule.Init()
    local function RegisterClientCallback()
        _G.GameNet:RegClientMsgCallback(
            'GET_PURCHASE_TREASURE_COUNT',
            function(playerId)
                local purchaseTreasureCount = TreasureModule.GetPurchaseTreasureCount(playerId)
                _G.GameNet:SendMsgToClient(playerId, 'GET_PURCHASE_TREASURE_COUNT_RESPONSE', purchaseTreasureCount)
            end
        )
        _G.GameNet:RegClientMsgCallback(
            'SET_PURCHASE_TREASURE_COUNT',
            function(playerId, count)
                TreasureModule.SetPurchaseTreasureCount(playerId, count)
                _G.GameNet:SendMsgToClient(playerId, 'SET_PURCHASE_TREASURE_COUNT_RESPONSE', count)
            end
        )
    end
    RegisterClientCallback()
end

function TreasureModule.GetPurchaseTreasureCount(playerId)
    return ZSDataService:GetZombieStormPurchaseTreasureCount(playerId)
end

function TreasureModule.SetPurchaseTreasureCount(playerId, count)
    return ZSDataService:SetZombieStormPurchaseTreasureCount(playerId, count)
end

return TreasureModule
