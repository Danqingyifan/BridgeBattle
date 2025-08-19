local MainStorage = game:GetService("MainStorage")
local PlantConfig = require(MainStorage.Config.PlantConfig)

-- KV接口层
local PlayerDataService = {}


-- 获取玩家上次进入的关卡ID
function PlayerDataService:GetLastMapID(playerId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    return kvTable:Get("LastMapID", {})
end

-- 保存玩家上次进入的关卡ID
function PlayerDataService:SetLastMapID(playerId, MapId)
    print("PlayerDataService:SetLastMapID", playerId, MapId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    kvTable:Set("LastMapID", MapId)
end


-- 获得植物列表
function PlayerDataService:GetPlantList(playerId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    return kvTable:Get('PlantList', {})
end

-- 判断是否有这个植物
function PlayerDataService:HasPlant(playerId, plantId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    local plantList = kvTable:Get('PlantList', {})
    for _, id in ipairs(plantList) do
        if id == plantId then
            return true
        end
    end
    return false
end

-- 添加植物
function PlayerDataService:AddPlant(playerId, plantId, reason, actionId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    local plantList = kvTable:Get('PlantList', {})
    for _, id in ipairs(plantList) do
        if id == plantId then
            return false
        end
    end
    table.insert(plantList, plantId)
    return kvTable:Set('PlantList', plantList)
end

-- 获取玩家拥有的表情列表
function PlayerDataService:GetEmoteActionList(playerId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    return kvTable:Get('EmoteActionList', {})
end

-- 判断是否有这个表情动作
function PlayerDataService:HasEmoteAction(playerId, emoteActionId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    local emoteActionList = kvTable:Get('EmoteActionList', {})
    for _, id in ipairs(emoteActionList) do
        if id == emoteActionId then
            return true
        end
    end
    return false
end

-- 获得一个表情动作
function PlayerDataService:AddEmoteAction(playerId, emoteActionId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.PlayerAttributes)
    local emoteActionList = kvTable:Get('EmoteActionList', {})
    for _, id in ipairs(emoteActionList) do
        if id == emoteActionId then
            return false
        end
    end
    table.insert(emoteActionList, emoteActionId)
    return kvTable:Set('EmoteActionList', emoteActionList)
end

-- 获得钻石数量
function PlayerDataService:GetDiamondCount(playerId)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.CurrencyTable)
    return kvTable:Get('DiamondCount', 0)
end

-- 添加钻石数量
function PlayerDataService:AddDiamonds(playerId, count)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.CurrencyTable)
    local diamondCount = kvTable:Get('DiamondCount', 0)
    return kvTable:Set('DiamondCount', diamondCount + count)
end

-- 判断钻石是否足够
function PlayerDataService:CheckDiamondCount(playerId, count)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.CurrencyTable)
    local diamondCount = kvTable:Get('DiamondCount', 0)
    return diamondCount >= count
end

-- 消耗钻石
function PlayerDataService:ConsumingDiamonds(playerId, count)
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.CurrencyTable)
    local diamondCount = kvTable:Get('DiamondCount', 0)
    if diamondCount < count then
        return false
    end
    return kvTable:Set('DiamondCount', diamondCount - count)
end

return PlayerDataService
