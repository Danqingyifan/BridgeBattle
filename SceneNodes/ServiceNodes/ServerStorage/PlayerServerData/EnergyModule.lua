-- 体力模块
local EnergyModule = {}

function EnergyModule.Init()
    local function RegisterClientCallback()
        _G.GameNet:RegClientMsgCallback(
            'UPDATE_CLIIENT_ENERGY',
            function(playerId)
                local energy = EnergyModule.GetEnergy(playerId)
                _G.GameNet:SendMsgToClient(playerId, 'GET_ENERGY_RESPONSE', energy)
            end
        )
        _G.GameNet:RegClientMsgCallback(
            'SET_ENERGY',
            function(playerId, count)
                EnergyModule.SetEnergy(playerId, count)
                _G.GameNet:SendMsgToClient(playerId, 'SET_ENERGY_RESPONSE', count)
            end
        )
    end
    RegisterClientCallback()
end

function EnergyModule.GetEnergy(playerId)
    return PlayerDataService:GetEnergy(playerId)
end

function EnergyModule.SetEnergy(playerId, count)
    return PlayerDataService:SetEnergy(playerId, count)
end

return EnergyModule
