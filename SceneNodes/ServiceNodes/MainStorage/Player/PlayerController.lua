local WorkSpace = game:GetService('WorkSpace')
local MainStorage = game:GetService('MainStorage')
local RunService = game:GetService('RunService')
local ContextActionService = game:GetService('ContextActionService')

local EventManager = require(MainStorage.Common.EventManager)
local Utils = require(MainStorage.Common.Utils)

local PlayerController = {
    eventObject = EventManager.SystemRegister('PlayerController'),
    eventNames = {},
}

-- Binding depending on the Device
function PlayerController.Init()
    local function RegisterEvents()
        for _, eventName in pairs(PlayerController.eventNames) do
            EventManager.AddListener(
                PlayerController.eventObject,
                eventName,
                function(...)
                    PlayerController.Update(eventName, ...)
                end
            )
        end
    end

    local function RegisterServerCallback()
        
    end
    RegisterEvents()
    RegisterServerCallback()
end

-- Event
function PlayerController.Update(eventName, ...)

end

-- Input Event
function PlayerController.OnFireInputBegin(vector2)
end

function PlayerController.OnFireInputMove(vector2)
end

function PlayerController.OnFireInputEnd()
end

-- Input
-- For PC(Touch Device use UI Event)
function PlayerController.BindInputContext()
    if RunService:IsPC() then
        -- Left Mouse Button for Shooting
        ContextActionService:BindContext(
            'Fire',
            function(actionName, inputState, inputObj)
                if inputState == Enum.UserInputState.InputBegin.Value then
                    local vector2 = Vector2.new(inputObj.Position.x, inputObj.Position.y)
                    PlayerController.OnFireInputBegin(vector2)
                elseif inputState == Enum.UserInputState.InputEnd.Value then
                    PlayerController.OnFireInputEnd()
                end
            end,
            false,
            Enum.UserInputType.MouseButton1
        )
        -- Right Mouse Button for Aiming
        ContextActionService:BindContext(
            'Aim',
            function(actionName, inputState, inputObj)
                if inputState == Enum.UserInputState.InputBegin.Value then
                end
                if inputState == Enum.UserInputState.InputEnd.Value then
                end
            end,
            false,
            Enum.UserInputType.MouseButton2
        )
    end
end

function PlayerController.GetPositionUnderCursor()
    local windowCenterCursor = {
        Position = {
            x = WorkSpace.CurrentCamera.ViewportSize.x / 2,
            y = WorkSpace.CurrentCamera.ViewportSize.y / 2
        }
    }
    local rayLength = 10000
    local raycastResult = Utils.TryGetRaycastUnderCursor(windowCenterCursor, rayLength, false, {1, 3})
    return raycastResult.position
end

return PlayerController
