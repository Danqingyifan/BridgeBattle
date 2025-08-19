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
function PlayerController.BindTPSContext()
    if RunService:IsPC() then
        -- TPS Context Map
        ContextActionService:BindContext(
            'SwitchPlant',
            function(actionName, inputState, inputObj)
                if inputState == Enum.UserInputState.InputBegin.Value then
                    -- 1 2 3 4 5
                    if inputObj.KeyCode == 49 then
                        PlayerController.OnSwitchPlantByPos(1)
                    elseif inputObj.KeyCode == 50 then
                        PlayerController.OnSwitchPlantByPos(2)
                    elseif inputObj.KeyCode == 51 then
                        PlayerController.OnSwitchPlantByPos(3)
                    elseif inputObj.KeyCode == 52 then
                        PlayerController.OnSwitchPlantByPos(4)
                    elseif inputObj.KeyCode == 53 then
                        PlayerController.OnSwitchPlantByPos(5)
                    elseif inputObj.KeyCode == 54 then
                        PlayerController.OnSwitchPlantByPos(6)
                    elseif inputObj.KeyCode == 55 then
                        PlayerController.OnSwitchPlantByPos(7)
                    elseif inputObj.KeyCode == 56 then
                        PlayerController.OnSwitchPlantByPos(8)
                    elseif inputObj.KeyCode == 57 then
                        PlayerController.OnSwitchPlantByPos(9)
                    end
                end
            end,
            false,
            Enum.UserInputType.Keyboard
        )
        -- Left Mouse Button for Shooting
        ContextActionService:BindContext(
            'Fire_1',
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
        ContextActionService:BindContext(
            'Fire_2',
            function(actionName, inputState, inputObj)
                if inputState == Enum.UserInputState.InputBegin.Value then
                    PlayerController.OnFireInputBegin()
                elseif inputState == Enum.UserInputState.InputEnd.Value then
                    PlayerController.OnFireInputEnd()
                end
            end,
            false,
            Enum.KeyCode.Space
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
        ContextActionService:BindContext(
            'Reload',
            function(actionName, inputState, inputObj)
                if inputState == Enum.UserInputState.InputBegin.Value then
                    if PlayerController.playerCharacter.controlledPlant then
                        PlayerController.playerCharacter.controlledPlant:TryReload()
                    end
                end
            end,
            false,
            Enum.KeyCode.R
        )
    end
end


function PlayerController.KeyMouseUnbinding()
    PlayerController.UnbindTPSContext()
end

function PlayerController.UnbindTPSContext()
    ContextActionService:UnbindContext('SwitchPlant')
    ContextActionService:UnbindContext('Fire_1')
    ContextActionService:UnbindContext('Fire_2')
    ContextActionService:UnbindContext('Aim')
    ContextActionService:UnbindContext('Reload')
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
