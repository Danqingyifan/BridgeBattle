local EventManager = {}

function EventManager.SystemRegister(instigatorName)
    local eventObject = {
        --自动事件id
        autoEventId = 0,
        --事件列表
        events = {},
        --是否屏蔽事件
        blockEvent = false,
        --正在触发事件中
        triggeringEvent = false,
        addListenerTemp = {},
        removeListenerTemp = {},
        instigatorName = instigatorName
    }
    return eventObject
end

function EventManager.GetAutoEventId(eventObject)
    eventObject.autoEventId = eventObject.autoEventId + 1
    return eventObject.autoEventId
end

--屏蔽事件
function EventManager.BlockEvent(eventObject, block)
    eventObject.blockEvent = block
end

--注册事件
function EventManager.AddListener(eventObject, eventName, callback)
    if eventObject.triggeringEvent then
        if not eventObject.addListenerTemp then
            eventObject.addListenerTemp = {}
        end
        table.insert(eventObject.addListenerTemp, {callback = callback, eventName = eventName})
        return
    end
    EventManager.RemoveListener(eventObject, eventName, callback)
    if eventObject.events == nil then
        eventObject.events = {}
    end
    if eventObject.events[eventName] == nil then
        eventObject.events[eventName] = {}
    end
    local eventId = EventManager.GetAutoEventId(eventObject)
    table.insert(eventObject.events[eventName], {callback = callback, eventId = eventId})
    return eventId
end

--移除事件
function EventManager.RemoveListener(eventObject, eventName, callback)
    if eventObject.triggeringEvent then
        if not eventObject.removeListenerTemp then
            eventObject.removeListenerTemp = {}
        end
        table.insert(eventObject.removeListenerTemp, {callback = callback, eventName = eventName})
        return
    end
    if eventObject.events == nil then
        eventObject.events = {}
        return
    end
    if eventObject.events[eventName] == nil then
        return
    end
    for k, v in pairs(eventObject.events[eventName]) do
        if v.callback == callback then
            table.remove(eventObject.events[eventName], k)
            return
        end
    end
end

function EventManager.RemoveByEventId(eventObject, eventId)
    if eventObject.triggeringEvent then
        if not eventObject.removeListenerTemp then
            eventObject.removeListenerTemp = {}
        end
        table.insert(eventObject.removeListenerTemp, {eventId = eventId})
        return
    end
    for k, v in pairs(eventObject.events) do
        for kk, vv in pairs(v) do
            if vv.eventId == eventId then
                table.remove(eventObject.events[k], kk)
                return
            end
        end
    end
end

--触发事件
function EventManager.FireEvent(eventObject, eventName, ...)
    -- print(eventObject.instigatorName .. " FireEvent: " .. eventName)
    if eventObject.blockEvent then
        return
    end
    if eventObject.events == nil then
        eventObject.events = {}
        return
    end
    if eventObject.events[eventName] == nil then
        return
    end
    eventObject.triggeringEvent = true
    for k, v in pairs(eventObject.events[eventName]) do
        local args = {...}
        -- PCall(
        --     function()
                v.callback(unpack(args))
        --     end
        -- )
    end


    eventObject.triggeringEvent = false
    if eventObject.addListenerTemp then
        for _, v in ipairs(eventObject.addListenerTemp) do
            EventManager.AddListener(eventObject, v.eventName, v.callback)
        end
        eventObject.addListenerTemp = {}
    end

    if eventObject.removeListenerTemp then
        for _, v in ipairs(eventObject.removeListenerTemp) do
            if v.eventId then
                EventManager.RemoveByEventId(eventObject, v.eventId)
            else
                EventManager.RemoveListener(eventObject, v.eventName, v.callback)
            end
        end
        eventObject.removeListenerTemp = {}
    end
end

return EventManager
