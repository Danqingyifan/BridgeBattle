local MainStorage = game:GetService('MainStorage')
local ServerStorage = game:GetService('ServerStorage')

local CustomConfig = require(MainStorage.Common.CustomConfig)
local PlantConfig = require(MainStorage.Config.PlantConfig)
local PlayerDataManager = require(ServerStorage.PlayerDataManager)

local ShopManager = {}

-- 初始化宝箱配置
function ShopManager.Init()
    ShopManager.treasureConfigs = {}
    -- 从配置中加载宝箱数据
    for _, config in pairs(CustomConfig.GetConfigs('Treasure')) do
        table.insert(ShopManager.treasureConfigs, config)
    end

    local function RegisterClientCallback()
        -- 打开宝箱
        _G.GameNet:RegClientMsgCallback(
            'PURCHASE_TREASURE',
            function(playerId, treasureName)
                local rewards, isGuaranteeDraw = ShopManager.PurchaseAndOpenTreasure(playerId, treasureName)
                _G.GameNet:SendMsgToClient(playerId, 'PURCHASE_TREASURE_RESPONSE', rewards, isGuaranteeDraw)
            end
        )
    end
    RegisterClientCallback()
end

-- 购买并打开宝箱
function ShopManager.PurchaseAndOpenTreasure(playerId, treasureName)
    local treasureConfig = CustomConfig.GetConfig('Treasure', treasureName)

    if not treasureConfig then
        error('没有宝箱配置')
        return false
    end

    local info = {
        uin = playerId,
        itemType = 'currency',
        cfgId = 0,
        reason = 'BuyTreasure'
    }
    local isSuccess, currency = PlayerDataManager:SubData(info, treasureConfig.gamePrice)
    if not isSuccess then
        print('消耗钻石失败')
        return false
    end

    local isGuaranteeDraw = false
    local purchaseTreasureCount = PlayerDataManager:GetZSPurchaseTreasureCount(playerId)

    --抽50次触发保底
    if purchaseTreasureCount == 49 then
        isGuaranteeDraw = true
    end

    local rewards = {}

    -- 奖励总权重
    local weights = {0}
    local totalWeight = 0
    for _, reward in pairs(treasureConfig.rewardList) do
        -- 只有卡牌有权重，货币必得
        if reward.rewardType == 0 then
            totalWeight = totalWeight + reward.rewardProbability
            table.insert(weights, totalWeight)
        end
    end
    local isPurchased = PlayerDataManager:GetIfPurchasedTreasure(playerId)
    if isPurchased ==false then
        PlayerDataManager:SetIfPurchasedTreasure(playerId, true)
    end
    local isRewardCardS = false
    -- 抽四张卡牌
    for i = 1, 4 do
        local cardReward = nil
        local cardQuality = 1

        -- 处理保底机制
        if isGuaranteeDraw and i == 1 then
            for _, reward in pairs(treasureConfig.rewardList) do
                if reward.rewardType == 0 and reward.rewardCardQuality == 4 then
                    cardReward = reward
                    cardQuality = reward.rewardCardQuality
                    isRewardCardS = true
                    break
                end
            end
       
        else
            -- 根据权重随机抽取
            local randomWeight = math.random() * totalWeight
            for index, reward in pairs(treasureConfig.rewardList) do
                if reward.rewardType == 0 and randomWeight <= weights[index + 1] and randomWeight > weights[index] then
                    cardReward = reward
                    cardQuality = reward.rewardCardQuality
                    if cardQuality == 4 then
                        isRewardCardS = true
                        isGuaranteeDraw = true
                    end
                    break
                end
            end
        end

        -- 获取随机卡牌
        local rewardCount = math.random(cardReward.rewardCardCountMin, cardReward.rewardCardCountMax)
        local plantConfigs = PlantConfig:GetPlantConfigsByQuality(cardQuality)
        local randomIndex = math.random(1, #plantConfigs)
        local cardId = plantConfigs[randomIndex].PlantId
        -- 处理卡牌奖励
        -- 如果卡牌不存在，则添加卡牌，并减少1张卡牌经验
        if isPurchased==false and i==1 then
        --进行第一次打开宝箱的特殊处理
         cardId = 10
        end
        local decreaseNum = 0
        if not PlayerDataManager:CheckZSCardExist(playerId, cardId) then
            local info = {
                uin = playerId,
                itemType = 'plant',
                cardId = cardId,
                reason = 'BuyTreasure',
                cfgId = cardId,
            }
            PlayerDataManager:AddData(info, 1)
            decreaseNum = 1
        end

        local info = {
            itemType = 'plant_exp',
            uin = playerId,
            cardId = cardId,
            reason = 'BuyTreasure',
            cfgId = cardId,
        }

        local cardExp = PlayerDataManager:AddData(info, rewardCount - decreaseNum)
        table.insert(
            rewards,
            {
                rewardType = 'Card',
                cardId = cardId,
                cardCount = rewardCount,--奖励的卡牌数量
                cardExp = cardExp--当前卡牌经验
            }
        )
    
    end

    -- 抽一次货币
    for _, reward in pairs(treasureConfig.rewardList) do
        if reward.rewardType == 1 then
            local rewardCount = math.random(reward.rewardCurrencyMin, reward.rewardCurrencyMax)

            local info = {
                uin = playerId,
                itemType = 'currency',

                cfgId = 0,
                reason = 'BuyTreasure'
            }
            local currency = PlayerDataManager:AddData(info, rewardCount)

            table.insert(rewards, {
                rewardType = 'Currency', 
                currencyType = 'Diamond',
                currencyCount = rewardCount,
                currentCurrency = currency--当前货币数量
            })
            break
        end
    end

    if isRewardCardS then
        PlayerDataManager:SetZSPurchaseTreasureCount(playerId, 0)
    else
        PlayerDataManager:SetZSPurchaseTreasureCount(playerId, purchaseTreasureCount + 1)
    end

    return rewards, isGuaranteeDraw
end

return ShopManager
