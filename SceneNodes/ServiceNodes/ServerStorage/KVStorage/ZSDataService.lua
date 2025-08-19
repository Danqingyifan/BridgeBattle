local MainStorage = game:GetService('MainStorage')
local PlantConfig = require(MainStorage.Config.PlantConfig)
local CardUpgradeCostConfig = require(MainStorage.Config.CardUpgradeCostConfig)
local GuideData = require(MainStorage.Player.GuideData)

local ZSDataService = {}

-- 体力系统配置
ZSDataService.EnergyConfig = {
    InitialEnergy = 200, -- 初始体力
    MaxEnergy = 200, -- 最大体力
    RecoveryInterval = 60 * 6, -- 恢复间隔（秒）：6分钟
    PurchaseLimit = 20, --每日购买体力上限
    RecoveryAmount = 1, -- 每次恢复的体力点数
    EnergyCountPerPurchase = 50 --每份体力点数
}
--#region 僵尸风暴卡牌相关
--获取僵尸风暴卡牌列表
function ZSDataService:GetZombieStormCardList(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)

    local plantList = PlayerDataService:GetPlantList(playerId)
    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})

    for _, plantId in ipairs(plantList) do
        --没有该植物，自动添加
        if not ZombieStormCards[plantId] then
            ZombieStormCards[plantId] = {
                cardLevel = 1,
                cardExp = 0
            }

            print('ZSDataService:GetZombieStormCardList: 添加植物: ' .. tostring(plantId))
            ZombieStormkvTable:Set('ZombieStormCards', ZombieStormCards)
        end
    end

    return ZombieStormCards
end

--获取僵尸风暴卡牌
function ZSDataService:GetZombieStormCard(playerId, cardId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})
    return ZombieStormCards[cardId]
end

--添加僵尸风暴卡牌
function ZSDataService:_AddZombieStormCard(info)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local plantList = PlayerDataService:GetPlantList(info.uin)
    local isPlantExist = false
    for _, plantId in ipairs(plantList) do
        if plantId == info.cardId then
            isPlantExist = true
            break
        end
    end

    if not isPlantExist then
        PlayerDataService:AddPlant(info.uin, info.cardId)
    end

    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})
    ZombieStormCards[info.cardId] = {
        cardLevel = 1,
        cardExp = 0
    }

    ZombieStormkvTable:Set('ZombieStormCards', ZombieStormCards)
    local plantConfig = PlantConfig:GetPlantConfigByPlantId(info.cardId)
    info.newCount = 1
    info.name = plantConfig and plantConfig.PlantName
    return true
end

-- 添加僵尸风暴卡牌经验
function ZSDataService:_AddZombieStormCardExp(info, count)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})
    local card = ZombieStormCards[info.cardId]
    local newExp = card.cardExp + count
    print('添加僵尸风暴卡牌经验：' .. '卡牌ID： ' .. tostring(info.cardId) .. '之前经验' .. tostring(card.cardExp) .. ' 添加经验： ' .. tostring(count) .. ' 当前经验： ' .. tostring(newExp))
    card.cardExp = newExp
    ZombieStormkvTable:Set('ZombieStormCards', ZombieStormCards)

    local plantConfig = PlantConfig:GetPlantConfigByPlantId(info.cardId)
    info.newCount = newExp
    info.name = plantConfig and plantConfig.PlantName
    return true
end

-- 消耗僵尸风暴卡牌经验
function ZSDataService:_ConsumeZombieStormCardExp(info)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})
    local card = ZombieStormCards[info.cardId]

    local plantConfig = PlantConfig:GetPlantConfigByPlantId(info.cardId)
    local costCardNum = CardUpgradeCostConfig[plantConfig.PlantQuality][card.cardLevel + 1]
    print('ZSData:当前卡牌ID = ' .. tostring(info.cardId) .. ' 当前卡牌等级 = ' .. tostring(card.cardLevel) .. ' 当前卡牌经验 = ' .. tostring(card.cardExp) .. ' 升级消耗 = ' .. tostring(costCardNum))

    if card.cardExp < costCardNum then
        print('ZSData:当前卡牌经验不足，无法消耗')
        return false
    end

    card.cardExp = card.cardExp - costCardNum
    print('ZSData:升级成功  卡牌ID = ' .. tostring(info.cardId) .. ' 卡牌经验 = ' .. tostring(card.cardExp))
    ZombieStormkvTable:Set('ZombieStormCards', ZombieStormCards)
    info.newCount = card.cardExp
    info.count = -costCardNum
    info.name = plantConfig and plantConfig.PlantName
    return true
end

--增加卡牌等级(1级)
function ZSDataService:_AddZombieStormCardLevel(info)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCards = ZombieStormkvTable:Get('ZombieStormCards', {})
    local card = ZombieStormCards[info.cardId]
    local plantConfig = PlantConfig:GetPlantConfigByPlantId(info.cardId)
    card.cardLevel = card.cardLevel + 1

    local MAXLEVEL = #CardUpgradeCostConfig[plantConfig.PlantQuality]
    if card.cardLevel > MAXLEVEL then
        card.cardLevel = MAXLEVEL
        print('ZSData:卡牌等级已达到最大等级：' .. tostring(MAXLEVEL))
        return false
    end

    ZombieStormkvTable:Set('ZombieStormCards', ZombieStormCards)

    info.newCount = card.cardLevel
    info.name = plantConfig and plantConfig.PlantName
    return true
end

--#endregion

--#region 僵尸风暴关卡相关
-- 获取玩家僵尸风暴关卡进度列表
-- 获取玩家僵尸风暴特定关卡进度
function ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)

    local ZombieStormLevelProgress = ZombieStormkvTable:Get('ZombieStormLevelProgress', {})
    for _, progress in pairs(ZombieStormLevelProgress) do
        if progress.levelId == levelId and progress.levelDifficulty == levelDifficulty then
            return progress
        end
    end

    return {}
end

-- 是否解锁僵尸风暴特定关卡
function ZSDataService:CheckZombieStormLevelUnlocked(playerId, levelId, levelMode, levelDifficulty)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)

    local ZombieStormLevelProgress = ZombieStormkvTable:Get('ZombieStormLevelProgress', {})
    for _, progress in pairs(ZombieStormLevelProgress) do
        if progress.levelId == levelId and progress.levelDifficulty == levelDifficulty then
            return true
        end
    end
    return false
end

-- 解锁僵尸风暴特定关卡
function ZSDataService:UnlockZombieStormLevel(playerId, levelId, levelMode, levelDifficulty)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)

    local ZombieStormLevelProgress = ZombieStormkvTable:Get('ZombieStormLevelProgress', {})
    local newProgress = {levelId = levelId, levelMode = levelMode, levelDifficulty = levelDifficulty, levelRecord = 0}
    table.insert(ZombieStormLevelProgress, newProgress)
    ZombieStormkvTable:Set('ZombieStormLevelProgress', ZombieStormLevelProgress)
    return newProgress or {}
end

-- 更新僵尸风暴特定关卡进度
function ZSDataService:SetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty, levelRecord)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)

    local ZombieStormLevelProgress = ZombieStormkvTable:Get('ZombieStormLevelProgress', {})

    for _, progress in pairs(ZombieStormLevelProgress) do
        if progress.levelId == levelId and progress.levelMode == levelMode and progress.levelDifficulty == levelDifficulty then
            progress.levelRecord = levelRecord
            ZombieStormkvTable:Set('ZombieStormLevelProgress', ZombieStormLevelProgress)
            return progress
        end
    end

    return {}
end

-- 获取僵尸风暴关卡进度列表
--用于初始化客户端数据
function ZSDataService:GetZSLevelProgressList(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormLevelProgress = ZombieStormkvTable:Get('ZombieStormLevelProgress', {})
    if not ZombieStormLevelProgress or next(ZombieStormLevelProgress) == nil then
        --没有关卡进度，初始化
        ZombieStormLevelProgress = {
            {levelId = 1, levelMode = 'Career', levelDifficulty = 1, levelRecord = 0},
            {levelId = 1, levelMode = 'Infinite', levelDifficulty = 1, levelRecord = 0}
        }
        ZombieStormkvTable:Set('ZombieStormLevelProgress', ZombieStormLevelProgress)
        print('ZSDATA: 没有关卡进度，初始化')
    end
    return ZombieStormLevelProgress
end
--#endregion

--#region 僵尸风暴宝箱相关
-- 获取购买宝箱次数
function ZSDataService:GetZombieStormPurchaseTreasureCount(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local PurchaseTreasureCount = ZombieStormkvTable:Get('PurchaseTreasureCount', 0)
    if not PurchaseTreasureCount then
        --没有购买次数，设置为0
        PurchaseTreasureCount = 0
        ZombieStormkvTable:Set('PurchaseTreasureCount', PurchaseTreasureCount)
    end
    return PurchaseTreasureCount
end

-- 设置购买宝箱次数
function ZSDataService:SetZombieStormPurchaseTreasureCount(playerId, count)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    return ZombieStormkvTable:Set('PurchaseTreasureCount', count)
end

--#endregion

--#region 僵尸风暴货币相关
-- 获得僵尸风暴货币数量
function ZSDataService:_GetZombieStormCurrency(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local currency = ZombieStormkvTable:Get('ZombieStormCurrency', 0)

    return currency
end

-- 添加僵尸风暴货币数量
function ZSDataService:_AddZombieStormCurrency(info, count)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCurrency = ZombieStormkvTable:Get('ZombieStormCurrency', 0)

    local newCount = ZombieStormCurrency + count
    print('ZSDATA: 添加僵尸风暴货币数量：' .. tostring(count) .. '添加前货币：' .. tostring(ZombieStormCurrency) .. ' 添加后货币：' .. tostring(newCount))
    ZombieStormkvTable:Set('ZombieStormCurrency', newCount)

    info.name = '僵尸风暴货币'
    info.newCount = newCount
    return true
end

-- 判断僵尸风暴货币是否足够
function ZSDataService:_CheckZombieStormCurrency(playerId, count)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCurrency = ZombieStormkvTable:Get('ZombieStormCurrency', 0)
    return ZombieStormCurrency >= count
end

-- 消耗僵尸风暴货币
function ZSDataService:_ConsumingZombieStormCurrency(info, count)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(info.uin, PlayerKVTableEnum.ZombieStormData)
    local ZombieStormCurrency = ZombieStormkvTable:Get('ZombieStormCurrency', 0)
    if ZombieStormCurrency < count then
        print('僵尸风暴货币不足：玩家ID ' .. tostring(info.uin) .. ' 当前货币：' .. tostring(ZombieStormCurrency) .. ' 需要货币：' .. tostring(count))
        return false
    end

    print('ZSDATA: 消耗僵尸风暴货币：' .. tostring(count) .. ' 消耗前货币：' .. tostring(ZombieStormCurrency) .. ' 消耗后货币：' .. tostring(ZombieStormCurrency - count))
    ZombieStormkvTable:Set('ZombieStormCurrency', ZombieStormCurrency - count)

    info.newCount = ZombieStormCurrency - count
    info.name = '僵尸风暴货币'
    return true
end
--#endregion

--#region 体力系统相关
-- 体力系统实现

-- 初始化体力数据
function ZSDataService:_InitializeEnergyData(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local energyData = {
        Value = self.EnergyConfig.InitialEnergy,
        Time = os.time(),
        RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval,
        RemainingPurchaseCount = self.EnergyConfig.PurchaseLimit
    }
    ZombieStormkvTable:Set('Energy', energyData)
    print(
        '初始化体力系统：玩家ID ' ..
            tostring(playerId) ..
                ' 初始体力：' .. tostring(energyData.Value) .. ' 初始剩余恢复时间：' .. tostring(energyData.RemainingRecoveryTime) .. ' 初始剩余购买次数：' .. tostring(energyData.RemainingPurchaseCount)
    )
    return energyData
end

-- 获取体力数据（内部使用，不进行恢复计算）
function ZSDataService:_GetEnergyData(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local energyData = ZombieStormkvTable:Get('Energy', {})

    -- 检查数据完整性
    if not energyData or not energyData.Value or not energyData.Time or not energyData.RemainingRecoveryTime or not energyData.RemainingPurchaseCount then
        return self:_InitializeEnergyData(playerId)
    end

    return energyData
end

-- 更新体力数据（内部使用）
function ZSDataService:_UpdateEnergyData(playerId, energyData)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    ZombieStormkvTable:Set('Energy', energyData)
end

-- 计算体力恢复
function ZSDataService:_CalculateEnergyRecovery(energyData, playerId)
    local currentTime = os.time()
    local lastUpdateTime = energyData.Time
    local currentEnergy = energyData.Value
    local lastRemainingRecoveryTime = energyData.RemainingRecoveryTime
    local initialEnergy = currentEnergy

    -- 如果体力已满，不需要恢复
    if currentEnergy >= self.EnergyConfig.MaxEnergy then
        energyData.Time = currentTime
        energyData.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval
        return energyData, 0
    end

    local timePassed = currentTime - lastUpdateTime

    -- 如果时间没有经过，不需要恢复
    if timePassed <= 0 then
        return energyData, 0
    end

    -- 计算实际可用于恢复的时间
    local availableTime = timePassed
    local recoveredEnergy = 0

    -- 首先检查是否完成了上次的恢复周期
    if availableTime >= lastRemainingRecoveryTime then
        -- 完成了上次的恢复周期
        recoveredEnergy = recoveredEnergy + self.EnergyConfig.RecoveryAmount
        availableTime = availableTime - lastRemainingRecoveryTime

        -- 计算额外的完整恢复周期
        local additionalRecoveries = math.floor(availableTime / self.EnergyConfig.RecoveryInterval)
        recoveredEnergy = recoveredEnergy + additionalRecoveries * self.EnergyConfig.RecoveryAmount

        -- 计算剩余时间
        local remainingTime = availableTime % self.EnergyConfig.RecoveryInterval
        energyData.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval - remainingTime
    else
        -- 没有完成上次的恢复周期
        energyData.RemainingRecoveryTime = lastRemainingRecoveryTime - availableTime
    end

    -- 应用恢复的体力，限制在最大值内
    energyData.Value = math.min(currentEnergy + recoveredEnergy, self.EnergyConfig.MaxEnergy)
    energyData.Time = currentTime

    -- 如果体力已满，重置恢复时间
    if energyData.Value >= self.EnergyConfig.MaxEnergy then
        energyData.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval
    end

    local actualRecoveredEnergy = energyData.Value - initialEnergy

    if actualRecoveredEnergy > 0 then
        print('体力恢复：玩家ID ' .. tostring(playerId) .. ' 离线时长：' .. tostring(timePassed) .. '秒')
        print('计算恢复体力：' .. tostring(recoveredEnergy) .. ' 实际恢复：' .. tostring(actualRecoveredEnergy))
        print('恢复后体力：' .. tostring(energyData.Value) .. ' 剩余恢复时间：' .. tostring(energyData.RemainingRecoveryTime) .. '秒')
    end

    return energyData, actualRecoveredEnergy
end

-- 获取今日剩余购买体力次数
function ZSDataService:_GetEnergyRemainPurchaseCount(playerId)
    local energyData = self:_GetEnergyData(playerId)

    -- 检查并重置每日购买次数（如果跨天了）
    local dateChanged = self:_CheckAndResetDailyPurchaseCount(energyData, playerId)
    if dateChanged then
        self:_UpdateEnergyData(playerId, energyData)
    end

    return energyData.RemainingPurchaseCount
end

-- 检查是否可以购买体力（检查每日上限）
-- 返回值：是否可以购买，已使用次数，最大次数，剩余次数
function ZSDataService:_CanPurchaseEnergy(playerId)
    local remainingCount = self:_GetEnergyRemainPurchaseCount(playerId)
    local usedCount = self.EnergyConfig.PurchaseLimit - remainingCount
    return remainingCount > 0, usedCount, self.EnergyConfig.PurchaseLimit, remainingCount
end

-- 获取体力，会自动计算恢复
-- 返回值：当前体力，剩余恢复时间，剩余购买次数
function ZSDataService:_GetEnergy(playerId)
    local energyData = self:_GetEnergyData(playerId)

    -- 检查并重置每日购买次数
    local dateChanged = self:_CheckAndResetDailyPurchaseCount(energyData, playerId)

    -- 计算体力恢复
    local recoveredEnergy = 0
    energyData, recoveredEnergy = self:_CalculateEnergyRecovery(energyData, playerId)

    -- 如果有数据变化，保存到数据库
    if dateChanged or recoveredEnergy > 0 then
        self:_UpdateEnergyData(playerId, energyData)
    end

    return energyData.Value, energyData.RemainingRecoveryTime, energyData.RemainingPurchaseCount
end

-- 消耗体力
function ZSDataService:_ConsumeEnergy(info, amount)
    local energyData = self:_GetEnergyData(info.uin)
    local dateChanged = self:_CheckAndResetDailyPurchaseCount(energyData, info.uin)
    -- 计算体力恢复
    local recoveredEnergy = 0
    energyData, recoveredEnergy = self:_CalculateEnergyRecovery(energyData, info.uin)
    -- 检查体力是否足够
    if energyData.Value < amount then
        print('体力不足：玩家ID ' .. tostring(info.uin) .. ' 当前体力：' .. tostring(energyData.Value) .. ' 需要体力：' .. tostring(amount))

        -- 如果有恢复或日期变化，需要保存数据
        if dateChanged or recoveredEnergy > 0 then
            self:_UpdateEnergyData(info.uin, energyData)
        end

        info.newCount = energyData.Value
        info.name = '体力'
        return false
    end

    -- 消耗体力
    local oldEnergy = energyData.Value
    energyData.Value = math.max(0, energyData.Value - amount)
    energyData.Time = os.time()

    -- 如果体力从满状态变为不满，开始恢复计时
    if oldEnergy >= self.EnergyConfig.MaxEnergy and energyData.Value < self.EnergyConfig.MaxEnergy then
        energyData.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval
    end

    -- 保存数据
    self:_UpdateEnergyData(info.uin, energyData)
    print('消耗体力：玩家ID ' .. tostring(info.uin) .. ' 消耗：' .. tostring(amount) .. ' 剩余体力：' .. tostring(energyData.Value))

    info.newCount = energyData.Value
    info.name = '体力'
    return true
end

-- 增加体力
function ZSDataService:_AddEnergy(info, amount)
    -- 获取体力数据并计算恢复，避免重复读取
    local energyData = self:_GetEnergyData(info.uin)

    -- 检查并重置每日购买次数
    local dateChanged = self:_CheckAndResetDailyPurchaseCount(energyData, info.uin)

    -- 计算体力恢复
    local recoveredEnergy = 0
    energyData, recoveredEnergy = self:_CalculateEnergyRecovery(energyData, info.uin)

    -- 增加体力
    local oldEnergy = energyData.Value
    energyData.Value = energyData.Value + amount
    energyData.Time = os.time()

    -- 如果体力满了，重置恢复时间
    if energyData.Value >= self.EnergyConfig.MaxEnergy then
        energyData.RemainingRecoveryTime = self.EnergyConfig.RecoveryInterval
    end

    -- 保存数据
    self:_UpdateEnergyData(info.uin, energyData)

    info.newCount = energyData.Value
    info.name = '体力'
    print('增加体力：玩家ID ' .. tostring(info.uin) .. ' 增加：' .. tostring(amount) .. ' 当前体力：' .. tostring(energyData.Value))
    return true
end

-- 检查体力是否足够
function ZSDataService:_CheckEnergy(playerId, amount)
    if not playerId or not amount then
        return false, 0
    end

    local currentEnergy = self:_GetEnergy(playerId)
    return currentEnergy >= amount, currentEnergy
end

-- 检查并重置每日购买次数（如果跨天了）
function ZSDataService:_CheckAndResetDailyPurchaseCount(energyData, playerId)
    if not energyData then
        return false
    end
    if not energyData.Time then
        -- 如果没有时间数据，初始化购买次数
        energyData.RemainingPurchaseCount = self.EnergyConfig.PurchaseLimit
        energyData.Time = os.time()
        return true
    end

    -- 获取上次更新的日期和今天的日期
    local lastUpdateDate = os.date('%Y-%m-%d', energyData.Time)
    local today = os.date('%Y-%m-%d')

    -- 如果日期不同，重置购买次数
    if lastUpdateDate ~= today then
        print('跨天重置购买次数：玩家ID ' .. tostring(playerId) .. ' 上次日期：' .. tostring(lastUpdateDate) .. ' 今天日期：' .. tostring(today))
        energyData.RemainingPurchaseCount = self.EnergyConfig.PurchaseLimit
        return true
    end

    return false
end
--#endregion

--#region 新手引导相关
-- 从数据层加载新手引导数据
function ZSDataService:LoadGuideData(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local data = ZombieStormkvTable:Get('GuideList', {})
    return GuideData:Load(data), data
end
-- 保存新手引导数据到数据层
function ZSDataService:SaveGuideData(playerId, lines)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local data = GuideData:Save(lines)
    ZombieStormkvTable:Set('GuideList', data)
end
--#endregion

--#region GM测试
--GM测试
--减少体力时间（天）
function ZSDataService:DecreaseEnergyTime(playerId, day)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local energyData = ZombieStormkvTable:Get('Energy', {})
    energyData.Time = energyData.Time - day * 24 * 60 * 60
    print('减少体力时间：玩家ID ' .. tostring(playerId) .. ' 减少：' .. tostring(day) .. ' 天')
    print('减少后记录的天数：' .. tostring(os.date('%Y-%m-%d', energyData.Time)))
    ZombieStormkvTable:Set('Energy', energyData)
    return energyData.Time
end

--清理所有植物
--#endregion
function ZSDataService:_GetIfPurchasedTreasure(playerId)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local isPurchased = ZombieStormkvTable:Get('ifPurchasedTreasure', false)
    return isPurchased
end

function ZSDataService:_SetIfPurchasedTreasure(playerId, isPurchased)
    local ZombieStormkvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    ZombieStormkvTable:Set('ifPurchasedTreasure', isPurchased)
end

return ZSDataService
