local MainStorage = game:GetService('MainStorage')

local EventManager = require(MainStorage.Common.EventManager)
local PlayerCharacter = require(MainStorage.Player.PlayerCharacter)

local MapManager = {}

function MapManager.New()
    local ret = {
        eventObject = EventManager.SystemRegister('MapManager'),
        eventNames = {},
    }

    for k, v in pairs(MapManager) do
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

-- 初始化地图管理器
function MapManager:Init()
    self:GenerateMap()
end

-- 生成地图
function MapManager:GenerateMap()
    self:CreateBase()
    self:CreateBridge()
end

function MapManager:CreateBase()
end

-- 创建桥
function MapManager:CreateBridge()
end

-- 玩家加入处理
function MapManager:OnPlayerAdded(player)

end

-- 玩家离开处理
function MapManager:OnPlayerRemoving(player)
end

-- 生成玩家角色
function MapManager:SpawnPlayer(player)
    local playerCharacter = PlayerCharacter.New()
    playerCharacter:Init()
end

-- 更新函数
function MapManager:Update(eventName, ...)
end

-- 销毁地图
function MapManager:Destroy()
end

return MapManager