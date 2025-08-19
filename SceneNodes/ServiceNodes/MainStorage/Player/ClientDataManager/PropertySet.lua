-- 客户端数据
--[[
    CardList = {
    -- 具体请看PlantCard.lua
        -- [植物ID] = {
        --     cardLevel = 卡牌等级,
        --     cardExp = 卡牌经验
        -- },
    },
    LevelProgressList = {
        -- {
        --     levelId = 1,
        --     levelMode = 'Career',
        --     levelDifficulty = 1,
        --     levelRecord = 0
        -- },
    },
    PurchaseTreasureCount = 0,
    Currency = 0,
    Energy = {
        -- Value = 0,
        -- Time = 0,
        -- RemainingRecoveryTime = 0,
        -- RemainingPurchaseCount = 0,
    }
]]

_G.PropertyEnum = {
    CardList = "table",
    LevelProgressList = "table",
    PurchaseTreasureCount = "number",
    Currency = "number",
    Energy = "table",
    GuideData = "table",
    GuideLines = "table",
}

-- 数据可以保存在这里,
local PropertySet = {
    _propertyMap = {},
    _propertyChangedListeners = {},
}

function PropertySet:Get(propertyKey, defVal)
    if not PropertyEnum[propertyKey] then
        error("PropertySet:Get invalid propertyKey: " .. tostring(propertyKey))
    end
    return self._propertyMap[propertyKey] or defVal
end

function PropertySet:Set(propertyKey, value)
    local propertyType = PropertyEnum[propertyKey]
    if not propertyType then
        error("PropertySet:Set invalid propertyKey: " .. tostring(propertyKey))
    end
    if type(value) ~= propertyType and type(value) ~= "nil" then 
        error("PropertySet:Set invalid value type: " .. propertyKey)
    end
    local oldValue = self._propertyMap[propertyKey]
    self._propertyMap[propertyKey] = value

    local listener = self._propertyChangedListeners[propertyKey]
    if listener then
        listener:Fire(value, oldValue)
    end
end


-- 添加属性变化监听
-- propertyKey:  属性名
-- callback:     function(newValue, oldValue) 
-- obj:          可选, 如果有就是成员函数
-- return:       SBXConnection
function PropertySet:AddChangedListener(propertyKey, callback, obj)
    if not PropertyEnum[propertyKey] then
        error("PropertySet:AddChangedListener invalid propertyKey: " .. tostring(propertyKey))
    end
    local listener = self._propertyChangedListeners[propertyKey]
    if listener == nil then
        self._propertyChangedListeners[propertyKey] = SandboxNode.New("CustomNotify")
        listener = self._propertyChangedListeners[propertyKey]
    end
    if obj then
        return listener.Notify:Connect(function(newValue, oldValue)
            callback(obj, newValue, oldValue)
        end)
    else
        return listener.Notify:Connect(callback)   
    end
end

function PropertySet:Init()

end

return PropertySet