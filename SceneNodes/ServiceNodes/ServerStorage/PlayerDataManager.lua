local ServerStorage = game:GetService('ServerStorage')
local ZSDataService = require(ServerStorage.KVStorage.ZSDataService)
local GuideData = require(game.MainStorage.Player.GuideData)

local PlayerDataManager = {
    PlayerList = {}
}


-- 初始化玩家数据
function PlayerDataManager.Init()
    _G.GameNet:RegClientMsgCallback(
        'CLIENT_KV_LOADFINISHED',
        function(playerId, msgBody)
            PlayerDataManager.OnPlayerAdded(playerId, msgBody)
        end
    )
    _G.GameNet:RegClientMsgCallback(
        'CHECK_ENERGY_ENOUGH',
        -- 检查体力是否足够
        function(playerId, amount)
            local success = ZSDataService:_CheckEnergy(playerId, amount)
            _G.GameNet:SendMsgToClient(playerId, 'CHECK_ENERGY_ENOUGH_RESPONSE', success)
        end
    )
    _G.GameNet:RegClientMsgCallback(
        'UPGRADE_ZOMBIE_STORM_CARD',
        -- 升级僵尸风暴卡牌
        function(playerId, cardType, cardId)
            local actionId = _G.ReportData:GetActionId()
            local info = {
                uin = playerId,
                itemType = 'plant_exp',
                cardId = cardId,
                reason = 'LevelUp',
                cfgId = cardId,
            }

            -- 消耗卡牌经验
            local isSuccess = PlayerDataManager:SubData(info, 0, actionId)
            if not isSuccess then
                return false
            end

            local info2 = {
                uin = playerId,
                itemType = 'plant_level',
                cardId = cardId,
                reason = 'LevelUp',
                cfgId = cardId,
            }
            -- 增加卡牌等级
            isSuccess = PlayerDataManager:AddData(info2, 1, actionId)
        end
    )
    _G.GameNet:RegClientMsgCallback(
        'GUIDE_APPLY_SET',
        function(playerId, key)
            PlayerDataManager:GuideApplySet(playerId, key)
        end
    )

    -- 玩家数据保存事件
    _G.ServerGlobalEvent.OnPlayerDataSaving.Notify:Connect(
        function(playerId)
            local playerData = PlayerDataManager.PlayerList[playerId]
            ZSDataService:SaveGuideData(playerId, playerData.GuideLines)
        end
    )
    
    print('PlayerDataManager:Init')
end

function PlayerDataManager.OnPlayerAdded(playerId, msgBody)
    --玩家加入，发送数据

    local guideLines, guideData = ZSDataService:LoadGuideData(playerId)

    PlayerDataManager.PlayerList[playerId] = {
        IsStudio = msgBody.IsStudio,
        GuideLines = guideLines,
    }

    local energy, remainTime, remainingPurchaseCount = ZSDataService:_GetEnergy(playerId)
    local cardList = ZSDataService:GetZombieStormCardList(playerId)
    local currency = ZSDataService:_GetZombieStormCurrency(playerId)
    local purchaseTreasureCount = ZSDataService:GetZombieStormPurchaseTreasureCount(playerId)

    local levelProgressList = ZSDataService:GetZSLevelProgressList(playerId)
    local data = {
        Energy = {
            Value = energy,
            RemainingRecoveryTime = remainTime,
            RemainingPurchaseCount = remainingPurchaseCount
        },
        CardList = cardList,
        Currency = currency,
        LevelProgressList = levelProgressList,
        PurchaseTreasureCount = purchaseTreasureCount,
        GuideData = guideData,
    }
    _G.GameNet:SendMsgToClient(playerId, 'CLIENT_DATA_LOADFINISHED', data)
end

function PlayerDataManager.OnPlayerRemoved(player)
    PlayerDataManager.PlayerList[player.UserId] = nil
end

-- 获取玩家数据
function PlayerDataManager.GetPlayerData(playerId)
    return PlayerDataManager.PlayerList[playerId]
end

--GM测试
-- 添加僵尸风暴卡牌经验
function PlayerDataManager.AddPlantExp(playerId, plantId, exp)
    ZSDataService:AddZombieStormCardExp(playerId, plantId, exp, 'GM')
end

--region 体力相关
local function AddEnergy(info, amount)
    local isSuccess = ZSDataService:_AddEnergy(info, amount)
    if isSuccess then
        _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_ENERGY_VALUE', info.newCount)
    end
    return isSuccess
end
local function SubEnergy(info, amount)
    local isSuccess = ZSDataService:_ConsumeEnergy(info, amount)
    if isSuccess then
        _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_ENERGY_VALUE', info.newCount)
    end

    return isSuccess
end

function PlayerDataManager:CheckEnergyEnough(playerId, amount)
    return ZSDataService:_CheckEnergy(playerId, amount)
end

--#endregion

--region 货币相关
local function SubZSCurrency(info, amount)
    local isSuccess = ZSDataService:_ConsumingZombieStormCurrency(info, amount)
    if isSuccess then
        _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_CURRENCY_COUNT', info.newCount)
    end
    return isSuccess
end

local function AddZSCurrency(info, amount)
    local isSuccess = ZSDataService:_AddZombieStormCurrency(info, amount)
    if isSuccess then
        _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_CURRENCY_COUNT', info.newCount)
    end
    return isSuccess
end

--#endregion

--region 僵尸风暴卡牌相关
-- 添加僵尸风暴卡牌
local function AddZSCard(info, count)
    local isSuccess = ZSDataService:_AddZombieStormCard(info)
    if not isSuccess then
        return false
    end
    _G.GameNet:SendMsgToClient(info.uin, 'ADD_ZSCARD_RESPONSE', info.cardId)
    return isSuccess
end

-- 添加僵尸风暴卡牌经验
local function AddZSCardExp(info, count)
    ZSDataService:_AddZombieStormCardExp(info, count)
    --发送当前卡牌经验
    _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_ZS_CARD_EXP', info.cardId, info.newCount)
    return true
end


-- 消耗僵尸风暴卡牌经验
local function SubZSCardExp(info, count)
    local isSuccess = ZSDataService:_ConsumeZombieStormCardExp(info, count)
    if not isSuccess then
        print("消耗经验失败")
        return false
    end
    _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_ZS_CARD_EXP', info.cardId, info.newCount)
    return true
end

-- 添加僵尸风暴卡牌等级
local function AddZSCardLevel(info, count)
    local isSuccess = ZSDataService:_AddZombieStormCardLevel(info, count)
    if not isSuccess then
        print("升级失败")
        return false
    end
    print('升级成功', info.cardId, info.newCount)
    _G.GameNet:SendMsgToClient(info.uin, 'UPDATE_ZS_CARD_LEVEL', info.cardId, info.newCount)
    return true
end

--检查僵尸风暴卡牌是否存在
function PlayerDataManager:CheckZSCardExist(playerId, cardId)
    return ZSDataService:GetZombieStormCard(playerId, cardId)
end
--endregion

--获取购买宝箱次数
function PlayerDataManager:GetZSPurchaseTreasureCount(playerId)
    return ZSDataService:GetZombieStormPurchaseTreasureCount(playerId)
end

--设置购买宝箱次数
function PlayerDataManager:SetZSPurchaseTreasureCount(playerId, count)
    return ZSDataService:SetZombieStormPurchaseTreasureCount(playerId, count)
end


--region 关卡进度相关
function PlayerDataManager:UnlockProgress(playerId, levelId, levelMode, levelDifficulty)
    local isLevelUnlocked = ZSDataService:CheckZombieStormLevelUnlocked(playerId, levelId, levelMode, levelDifficulty)
    if not isLevelUnlocked then
        return ZSDataService:UnlockZombieStormLevel(playerId, levelId, levelMode, levelDifficulty)
    end
    return ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)

end

--获取特定关卡进度
function PlayerDataManager:GetProgress(playerId, levelId, levelMode, levelDifficulty)
    return ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)
end

-- 更新关卡进度
function PlayerDataManager:SetProgress(playerId, levelId, levelMode, levelDifficulty, levelRecord)
    local currentProgress = ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)
    print('PlayerDataManager:SetProgress', playerId, levelId, levelMode, levelDifficulty, levelRecord)
    print('当前关卡进度', currentProgress.levelId, currentProgress.levelMode, currentProgress.levelDifficulty, currentProgress.levelRecord)
    if currentProgress.levelRecord == 0 or currentProgress.levelRecord == nil then
        -- 如果记录为0,说明是首次通关，更新记录
        currentProgress.levelRecord = levelRecord
    elseif levelRecord < currentProgress.levelRecord then
        -- 如果记录更短，更新记录
        currentProgress.levelRecord = levelRecord
    end

    -- 保存更新后的进度
    local updatedProgress =
        ZSDataService:SetZombieStormLevelProgress(
        playerId,
        levelId,
        currentProgress.levelMode,
        currentProgress.levelDifficulty,
        currentProgress.levelRecord
    )
    return updatedProgress
end

--#endregion

--region 数据上报
--增加相关的埋点
function PlayerDataManager:AddData(info, count, actionId)
    local isSuccess = false
    if info.itemType == 'energy' then
        isSuccess = AddEnergy(info, count)
    elseif info.itemType == 'plant' then
        isSuccess = AddZSCard(info, count)
    elseif info.itemType == 'currency' then
        isSuccess = AddZSCurrency(info, count)
    elseif info.itemType == 'plant_exp' then
        isSuccess = AddZSCardExp(info, count)
    elseif info.itemType == 'plant_level' then
        isSuccess = AddZSCardLevel(info, count)
    else
        print("AddData 没有找到对应的itemType: " .. info.itemType)
    end
    if not isSuccess then
        return false
    end
    info.count = count
    _G.ReportData:ReportAddItem(info, actionId)
    return true
end

--减少相关的埋点
function PlayerDataManager:SubData(info, count, actionId)
    local isSuccess = false
    local needChange = true

    if info.itemType == 'currency' then
        isSuccess = SubZSCurrency(info, count)
    elseif info.itemType == 'energy' then
        isSuccess = SubEnergy(info, count)
    elseif info.itemType == 'plant_exp' then
        --消耗卡牌经验
        isSuccess = SubZSCardExp(info, count)
        if isSuccess then
            needChange = false
        end
    else
        print("SubData 没有找到对应的itemType: " .. info.itemType)
    end

    if not isSuccess then
        return false
    end

    if needChange then
        info.count = -count
    end

    _G.ReportData:ReportAddItem(info, actionId)
    return true
end

--#endregion

function PlayerDataManager:GuideApplySet(playerId, key)
    local playerData = self.PlayerList[playerId]
    local lines = playerData.GuideLines
    if not GuideData:CanSet(lines, key) then
        print("PlayerDataManager:GuideApplySet: Cannot set guide step for key: " .. key)
        return
    end
    GuideData:Set(lines, key)
    _G.ReportData:ReportGuideStep(playerId, key)
    _G.GameNet:SendMsgToClient(playerId, 'GUIDE_UPDATE_DATA', key)
end

function PlayerDataManager:GetIfPurchasedTreasure(playerId)
    local isPurchased = ZSDataService:_GetIfPurchasedTreasure(playerId)
    return isPurchased
end

function PlayerDataManager:SetIfPurchasedTreasure(playerId, isPurchased)
    ZSDataService:_SetIfPurchasedTreasure(playerId, isPurchased)
end

return PlayerDataManager
