-- FSM 类定义
local FSM = {}

-- state = {
--     name = 'stateName',
--     propertyListeners = { propertyListener1, propertyListener2, ... },
--     onEnter = function()
--     end,
--     onExit = function()
--     end
-- }

-- properties = {
--     [propertyName1] = propertyValue1,
--     [propertyName2] = propertyValue2,
--     ...
-- }

-- propertyListener = {
--     propertyName = propertyName,
--     condition = function(propertyValue)
--         return true or false
--     end,
--     targetStateName = targetStateName
-- }

function FSM.New(states, properties, initialStateName)
    local fsm = {
        states = states,
        properties = properties,
        currentStateName = 'Entry' -- 初始状态
    }

    for k, v in pairs(FSM) do
        if k ~= 'New' then
            fsm[k] = v
        end
    end

    fsm:ChangeState(initialStateName)

    return fsm
end

-- 更新属性值并检查是否需要切换状态
function FSM:UpdateProperty(propertyName, value)
    self.properties[propertyName] = value
    for _, propertyListener in pairs(self.states[self.currentStateName].propertyListeners) do
        if propertyListener.propertyName == propertyName then
            if propertyListener.condition(value) then
                self:ChangeState(propertyListener.targetStateName)
            end
        end
    end
end

-- 切换状态（传入需要切换的状态）
function FSM:ChangeState(newStateName)
    if self.currentStateName == newStateName then
        --print("状态未改变：".. newState)
        return -- 忽略相同状态
    end

    local oldState = self.states[self.currentStateName]
    if oldState then
        oldState.onExit()
    end

    self.currentStateName = newStateName

    if self.states[newStateName] then
        self.states[newStateName].onEnter()
    else
        error("状态 '" .. newStateName .. "' 未定义。")
    end
end

return FSM
