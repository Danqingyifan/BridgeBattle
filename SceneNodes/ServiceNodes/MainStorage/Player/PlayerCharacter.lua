local MainStorage = game:GetService('MainStorage')
local Players = game:GetService('Players')
local EventManager = require(MainStorage.Common.EventManager)

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
    self.bindCharacter = Players.LocalPlayer.Character
end

function PlayerCharacter:Update(eventName, ...)
end

function PlayerCharacter:Destroy()
    self.bindCharacter = nil
end

return PlayerCharacter
