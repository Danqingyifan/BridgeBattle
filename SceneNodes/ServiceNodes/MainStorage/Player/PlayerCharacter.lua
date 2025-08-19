local MainStorage = game:GetService('MainStorage')

local EventManager = require(MainStorage.Common.EventManager)
local CameraController = require(MainStorage.Camera.CameraController)

local PlayerCharacter = {}

function PlayerCharacter.New()
    local ret = {
        eventObject = EventManager.SystemRegister('PlayerCharacter'),
        eventNames = {}
    }

    for k, v in pairs(PlayerCharacter) do
        if k ~= 'New' then
            ret[k] = v
        end
    end

    local function RegisterEvents()
        for _, eventName in pairs(ret.eventNames) do
            EventManager.AddListener(
                ret.eventObject,
                eventName,
                function(...)
                    ret:Update(eventName, ...)
                end
            )
        end
    end
    RegisterEvents()
    return ret
end

function PlayerCharacter:Init()
    self.cameraController = CameraController.New()
end

function PlayerCharacter:EnterLevelBattle()
    self.cameraController:StartClient()
end

function PlayerCharacter:Update(eventName, ...)

end

-- 战斗阶段的函数
function PlayerCharacter:AttachCameraComponent()
end

function PlayerCharacter:UnAttachCameraComponent()
end


function PlayerCharacter:Destroy()
    self.cameraController:Destroy()
    self.cameraController = nil
end

return PlayerCharacter
