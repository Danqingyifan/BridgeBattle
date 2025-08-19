
local RunService = game:GetService("RunService")
local CloudService = game.CloudService
local MainStorage = game:GetService('MainStorage')
local ServerStorage = game:GetService('ServerStorage')
local ZSDataService = require(ServerStorage.KVStorage.ZSDataService)

local NewcomerGiftConfig = require(MainStorage.Config.NewcomerGiftConfig)
local NewcomerGiftService = {}

function NewcomerGiftService:Init()
    self.TypeSuceess = {}
    GameNet:RegClientMsgCallback("NewcomerGiftPackClientMsg", function (playerId,msgType, ...)
        local func = NewcomerGiftService[msgType]
        if func then
            local ok, result = pcall(func, self, playerId, ...)
            if not ok then
                print("NewcomerGiftService:NewcomerGiftPackClientMsg error", msgType, result )
                return
            end
        end
    end)
end


-- 领取新人礼包
function NewcomerGiftService:PlayerGetGiftPackage(playerId)
    local actionId = _G.ReportData:GetActionId()
    for index, value in ipairs(NewcomerGiftConfig.PlantConfig) do
        local info = {
            uin = playerId,
            itemType = 'plant',
            cardId = value,
            reason = "NewcomerGift",
            cfgId = value,
        }
        PlayerDataManager:AddData(info, 1)

    end
    local LastMapID =  PlayerDataService:GetLastMapID(playerId)
    local zombieStormCards = ZSDataService:GetZombieStormCardList(playerId)
    _G.GameNet:SendMsgToClient(playerId, 'GET_ZOMBIE_STORM_CARDS_RESPONSE', zombieStormCards)
    print("GetLastMapId", LastMapID)
    local bJumpRoom = false
    --if LastMapID then
    --    local HallId = NewcomerGiftConfig.GetJumpHallID(LastMapID)
    --    if HallId then
    --        bJumpRoom = true
    --    end
    --end

    GameNet:SendMsgToClient(playerId, "NewcomerGiftPackServerMsg", "Handle_PlayerGetGiftPackage", true, bJumpRoom)
end

-- 是否已经领取礼包
function NewcomerGiftService:DidPlayerClaimIt(playerId, Type)
    self.TypeSuceess[Type] = 1 
    if #self.TypeSuceess < 2 then --需要KV和客户端都准备好
        return
    end

    local PlantList = PlayerDataService:GetPlantList(playerId)
    local bGetGift = #PlantList > 0 -- 逻辑改为查看是否有棋子，有则代表已经领取新手礼包
    --for index, value in ipairs(NewcomerGiftConfig.PlantConfig) do
    --    if not PlayerDataService:HasPlant(playerId, value) then
    --        bGetGift = false
    --        break
    --    end
    --end
    local bHall = NewcomerGiftConfig.IsItHallRoom(RunService:GetCurMapOwid())

    GameNet:SendMsgToClient(playerId, "NewcomerGiftPackServerMsg", "Handle_DidPlayerClaimIt", bGetGift, bHall)
end

function NewcomerGiftService:JumpHallMap(playerId)
    local mapId = NewcomerGiftConfig.GetJumpHallID(RunService:GetCurMapOwid())
    if mapId == nil then
        error("CurrentMap Don't Jump Hall, MapID:" .. tostring(RunService:GetCurMapOwid()))
        return
    end
    local customInfo = {}
    local reportInfo = {}
    local skipConfirmationDialog = true
    local result = CloudService:TeleportToMap(mapId, tonumber(playerId), customInfo, reportInfo, skipConfirmationDialog)
end

function NewcomerGiftService:JumpLastGame(playerId)
    local LastMapID =  PlayerDataService:GetLastMapID(playerId)
    if LastMapID == nil then
        return
    end

    local customInfo = {}
    local reportInfo = {}
    local skipConfirmationDialog = true
    local result = CloudService:TeleportToMap(LastMapID, tonumber(playerId), customInfo, reportInfo, skipConfirmationDialog)
end

return NewcomerGiftService