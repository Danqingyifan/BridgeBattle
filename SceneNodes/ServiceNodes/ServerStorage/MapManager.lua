local CloudService = game:GetService('CloudService')
local RunService = game:GetService('RunService')

local MapManager = {}

function MapManager.Init()
    _G.GameNet:RegClientMsgCallback(
        'TELEPORT_REQUEST',
        function(playerId)
            local curMapId = tonumber(RunService:GetCurMapOwid())
            local hallMapId = 0

            if curMapId == 12835246448052 then
                -- 正式图
                hallMapId = 12839541415348
            elseif curMapId == 45850660052404 then
                -- 测试图
                hallMapId = 26278494084532
            end
            MapManager.TeleportPlayerToMap(playerId, hallMapId)
        end
    )
end

function MapManager.TeleportPlayerToMap(uid, mapId)
    local customInfo = ''
    local reportInfo = ''
    local showConfirmationDialog = false
    local result = CloudService:TeleportToMap(mapId, uid, customInfo, reportInfo, showConfirmationDialog)
    print('uid', uid, ' go to map ', mapId, ' result is ', tostring(result))
end

return MapManager
