--客户端数据管理
local MainStorage = game:GetService('MainStorage')
local EventManager = require(MainStorage.Common.EventManager)
local PlayerCardLoadout = require(MainStorage.Player.PlayerCardLoadout)
local GuideData = require(MainStorage.Player.GuideData)

local ClientDataManager = {
    PropertySet = nil,
    EnergyConfig = {
        InitialEnergy = 200, -- 初始体力
        MaxEnergy = 200, -- 最大体力
        RecoveryInterval = 60 * 6, -- 恢复间隔（秒）：6分钟
        PurchaseLimit = 20, --每日购买体力上限
        RecoveryAmount = 1, -- 每次恢复的体力点数
        EnergyCountPerPurchase = 50 --每份体力点数
    }
}

-- 检查引导lines是否为空
function ClientDataManager:IsGuideLinesEmpty(guideLines)
    for _, value in pairs(guideLines) do
        if value then
            return false
        end
    end
    return true
end

function ClientDataManager:Init()
    self.PropertySet = require(script.PropertySet)

    -- 注册服务器回调
    local function RegisterServerCallback()
        _G.GameNet:RegServerMsgCallback(
            'CLIENT_DATA_LOADFINISHED',
            function(data)
                print('客户端数据初始化完成', tostring(data.Currency))
                local cardList = {}

                for key, value in pairs(data.CardList) do
                    local card = PlayerCardLoadout.CreateCard('Plant')
                    card:Init(key)
                    cardList[key] = card
                    local cardLevel, cardExp = value.cardLevel, value.cardExp
                    card:SetPlantCardLevel(cardLevel, cardExp)
                end
                self.PropertySet:Set('CardList', cardList)
                self.PropertySet:Set('Currency', data.Currency)
                self.PropertySet:Set('Energy', data.Energy)
                self.PropertySet:Set('PurchaseTreasureCount', data.PurchaseTreasureCount)
                self.PropertySet:Set('LevelProgressList', data.LevelProgressList)
                self.PropertySet:Set('GuideData', data.GuideData)
                local guideLines = GuideData:Load(data.GuideData)
                for key, value in pairs(guideLines) do
                    print('引导数据: ' .. key, value)
                end
                self.PropertySet:Set('GuideLines', guideLines)

                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateCurrencyCount')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateEnergyCount')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnGetPurchaseTreasureCount')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'UpdateLevelProgress')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateGuideData')

                --开启体力恢复协程
                coroutine.work(
                    function()
                        while true do
                            local energy = self.PropertySet:Get('Energy')
                            if energy.Value < self.EnergyConfig.MaxEnergy then
                                -- 体力恢复
                                energy.RemainingRecoveryTime = energy.RemainingRecoveryTime - 1
                                if energy.RemainingRecoveryTime <= 0 then
                                    energy.Value = energy.Value + self.EnergyConfig.RecoveryAmount
                                    energy.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval
                                    self.PropertySet:Set('Energy', energy)
                                    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateEnergyCount')
                                end
                            else
                            end
                            EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateEnergyRemainTime')
                            wait(1)
                        end
                    end
                )
            end
        )

        _G.GameNet:RegServerMsgCallback(
            'GET_ZOMBIE_STORM_CARDS_RESPONSE',
            function(cardTables)
                local cardList = self.PropertySet:Get('CardList')
                for cardId, cardTable in pairs(cardTables) do
                    local card = PlayerCardLoadout.CreateCard('Plant')
                    card:Init(cardId)
                    cardList[cardId] = card

                    local cardLevel, cardExp = cardTable.cardLevel, cardTable.cardExp
                    card:SetPlantCardLevel(cardLevel, cardExp)
                end
                self.PropertySet:Set('CardList', cardList)

                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnPlayerDataLoadFinish')
            end
        )

        _G.GameNet:RegServerMsgCallback(
            'UPDATE_ZS_CARD_EXP',
            -- 更新僵尸风暴卡牌经验
            function(cardId, exp)
                print('客户端收到更新卡牌经验: ' .. tostring(cardId) .. ' ' .. '当前经验：' .. tostring(exp))
                local cardList = self.PropertySet:Get('CardList')
                local card = cardList[cardId]
                card:SetPlantCardLevel(card.level, exp)
                self.PropertySet:Set('CardList', cardList)
            end
        )

        _G.GameNet:RegServerMsgCallback(
            'UPDATE_ZS_CARD_LEVEL',
            -- 更新僵尸风暴卡牌等级
            function(cardId, level)
                print('客户端收到更新卡牌等级: ' .. tostring(cardId) .. ' ' .. '当前等级：' .. tostring(level))
                local cardList = self.PropertySet:Get('CardList')
                local card = cardList[cardId]
                card:SetPlantCardLevel(level, card.exp)
                self.PropertySet:Set('CardList', cardList)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpgradeZombieStormCard', cardId)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'ADD_ZSCARD_RESPONSE',
            function(cardId)
                print('客户端收到添加卡牌请求: ' .. tostring(cardId))
                local cardList = self.PropertySet:Get('CardList')
                local card = cardList[cardId]
                if not card then
                    card = PlayerCardLoadout.CreateCard('Plant')
                    card:Init(cardId)
                    cardList[cardId] = card
                    self.PropertySet:Set('CardList', cardList)
                end
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'PURCHASE_TREASURE_RESPONSE',
            function(rewardList, isGuaranteeDraw)
                if not rewardList then
                    print('购买宝箱失败')
                    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnShowNoCurrency')
                    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnPurchaseTreasureFailed')
                    return
                end
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnPurchaseTreasureSuccess', rewardList, isGuaranteeDraw)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'SETTLEMENT_REWARD_RESPONSE',
            function(settlementReward, RankingLevel)
                print('SETTLEMENT_REWARD_RESPONSE')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnSettlementReward', settlementReward, RankingLevel)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'UPDATE_TEAM_END_RESPONSE',
            function(energyValue, currency)
                self.PropertySet:Set('Energy', {Value = energyValue, RemainingRecoveryTime = 0, RemainingPurchaseCount = 0})
                self.PropertySet:Set('Currency', currency)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateEnergyCount')
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateCurrencyCount')
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'UPDATE_ENERGY_VALUE',
            -- 增加体力
            function(energyValue)
                local energy = self.PropertySet:Get('Energy')
                energy.Value = energyValue
                self.PropertySet:Set('Energy', energy)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateEnergyCount')
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'CHECK_ENERGY_ENOUGH_RESPONSE',
            -- 检查体力是否足够
            function(success)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnCheckEnergyEnough', success)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
            function(levelProgress)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUnlockLevelProgress', levelProgress)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'SHOW_WARN_POP',
            function(type, content)
                if type == 'ENERGY' then
                elseif type == 'CURRENCY' then
                end
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'UPDATE_CURRENCY_COUNT',
            -- 更新货币数量
            function(currency)
                self.PropertySet:Set('Currency', currency)
                _G.PlayerController.playerHUD.GetUIRoot('GuideManager'):SetTriggerCondition('LevelEnd_GoShop', currency >= 50000)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateCurrencyCount')
            end
        )

        _G.GameNet:RegServerMsgCallback(
            'GUIDE_UPDATE_DATA',
            -- 引导数据更新
            function(completedGuideKey)
                print('客户端收到引导更新: ' .. completedGuideKey)
                local guideLines = self.PropertySet:Get('GuideLines')
                GuideData:Set(guideLines, completedGuideKey)
                self.PropertySet:Set('GuideLines', guideLines)
                EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateGuideData')
            end
        )
    end
    RegisterServerCallback()
end

return ClientDataManager
