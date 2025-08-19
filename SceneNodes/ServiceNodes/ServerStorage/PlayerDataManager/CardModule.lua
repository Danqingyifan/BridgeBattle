local CardModule = {}
local MAX_LEVEL = 15

local ServerStorage = game:GetService('ServerStorage')
local ZSDataService = require(ServerStorage.KVStorage.ZSDataService)

function CardModule.Init()
    local function RegisterClientCallback()
        _G.GameNet:RegClientMsgCallback(
            'CHECK_IF_FIRST_TIME_LOGIN',
            function(playerId)
                --通过拿到的ZombieStormCards表，判断是否为空来判断是否是第一次登录
                local zombieStormCards = CardModule.GetZombieStormCards(playerId, 'Plant')
                if #zombieStormCards > 0 then
                    _G.GameNet:SendMsgToClient(playerId, 'CHECK_IF_FIRST_TIME_LOGIN_RESPONSE', false)
                else
                    _G.GameNet:SendMsgToClient(playerId, 'CHECK_IF_FIRST_TIME_LOGIN_RESPONSE', true)
                end
            end
        )
        _G.GameNet:RegClientMsgCallback(
            'GET_ZOMBIE_STORM_CARDS',
            function(playerId)
                local zombieStormCards = CardModule.GetZombieStormCards(playerId, 'Plant')
                _G.GameNet:SendMsgToClient(playerId, 'GET_ZOMBIE_STORM_CARDS_RESPONSE', zombieStormCards)
            end
        )
        _G.GameNet:RegClientMsgCallback(
            'UPGRADE_ZOMBIE_STORM_CARD',
            function(playerId, cardType, cardId)
                local isSuccess, exp = CardModule.UpgradeZombieStormCard(playerId, cardType, cardId)
                if isSuccess then
                    print('CardModule: 升级成功: ' ..
                    tostring(cardId) .. tostring(isSuccess) .. ' ' .. '当前经验：' .. tostring(exp))
                    _G.GameNet:SendMsgToClient(playerId, 'UPGRADE_ZOMBIE_STORM_CARD_RESPONSE', cardId, exp)
                end
            end
        )
    end

    RegisterClientCallback()
end

function CardModule.GetZombieStormCards(uid, cardType)
    if cardType == 'Plant' then
        return ZSDataService:GetZombieStormCardList(uid)
    end
end

function CardModule.GetZombieStormCard(uid, cardType, cardId)
    if cardType == 'Plant' then
        return ZSDataService:GetZombieStormCard(uid, cardId)
    end
end

function CardModule.AddZombieStormCard(uid, cardType, cardId, reason)
    if cardType == 'Plant' then
        ZSDataService:AddZombieStormCard(uid, cardId, reason)
    end
end

function CardModule.AddZombieStormCardExp(uid, cardType, cardId, exp, reason)
    if cardType == 'Plant' then
        return ZSDataService:AddZombieStormCardExp(uid, cardId, exp, reason)
    end
end

function CardModule.UpgradeZombieStormCard(uid, cardType, cardId)
    -- 检查卡牌等级,满级就返回,按理来说客户端那边有限制，不会有这种情况，此处仅是做保护
    if cardType == 'Plant' then
        local cardTable = ZSDataService:GetZombieStormCard(uid, cardId)
        print('cardTable: ', cardTable)
        local cardLevel = cardTable.cardLevel
        if cardLevel >= MAX_LEVEL then
            return false
        end

        local isSuccess, exp = ZSDataService:CheckZombieStormCardLevelUp(uid, cardId)
        if not isSuccess then
            print('CardModule: 升级失败: ' .. tostring(cardId))
            return false
        end
        return true, exp
    end
end

return CardModule
