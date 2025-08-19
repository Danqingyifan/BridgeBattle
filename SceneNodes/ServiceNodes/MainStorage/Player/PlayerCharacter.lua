local MainStorage = game:GetService('MainStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local EventManager = require(MainStorage.Common.EventManager)
local CameraController = require(MainStorage.Camera.CameraController)

local LogicHub = _G.LogicHub

local PlayerCharacter = {}

function PlayerCharacter.New()
    local ret = {
        eventObject = EventManager.SystemRegister('PlayerCharacter'),
        eventNames = {
            'OnReservePlant',
            'OnCancelReservePlant',
            'OnCreatePlant',
            'OnDestroyPlant',
            'OnUpdateReadyCount',
            'OnUpdateCountdown',
            'OnLevelWave',
            'OnUpdatePlantCount',
            'OnLevelPause'
        }
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
    -- 准备阶段
    self.plantCards = {}
    self.reservedPlants = {}
    self.isReady = false
    -- 战斗阶段
    self.plants = {} -- 可能只能有一个植物，但是保留多个植物的能力
    self.controlledPlant = nil
    self.pullingTrigger = false
    self.originRotation = nil
end

function PlayerCharacter:EnterLevelBattle()
    for _, plant in pairs(self.plants) do
        if plant then
            self.controlledPlant = plant
            self.cameraController.owner = plant
            self.cameraController:Init()
            break
        end
    end

    self:SwitchPlant(self.controlledPlant.positionIndex)
    self.cameraController:StartClient()

    self.directionUpdateConnection =
        RunService.Stepped:Connect(
            function()
                if not self.controlledPlant then
                    print('no controlledPlant')
                    return
                end

                local plantRotation = self.controlledPlant.bindContainer.LocalRotation
                if self.originRotation == plantRotation then
                    return
                end
                self.originRotation = plantRotation
                _G.LogicHub:ClientApply('direct', self.controlledPlant.positionIndex, plantRotation)
            end
        )

    self.pullingTriggerRenderSteppedConnection =
        RunService.RenderStepped:Connect(
            function()
                if self.pullingTrigger then
                    if RunService:CurrentSteadyTimeStampMS() - self.pullingTriggerBeginTime > 150 then
                        _G.PlayerController.SetFov(30)
                    end

                    local targetPosition = _G.PlayerController:GetPositionUnderCursor()
                    _G.LogicHub:ClientApply('fire', self.controlledPlant.positionIndex, targetPosition)
                end
            end
        )
end

function PlayerCharacter:Update(eventName, ...)

    if eventName == 'OnCreatePlant' then
        local localPlayerUin = Players.LocalPlayer.UserId
        local uin, positionIndex, plant = ...
        if uin == localPlayerUin then
            self.plants[positionIndex] = plant
            -- 从ClientDataManager中找到与PlantName名字对应的Card
            local cardList = _G.ClientDataManager.PropertySet:Get('CardList')
            for _, card in pairs(cardList) do
                if card.name == plant.plantName then
                    self.plantCards[positionIndex] = card
                    break
                end
            end
        end
    elseif eventName == 'OnDestroyPlant' then
        local localPlayerUin = Players.LocalPlayer.UserId
        local uin, positionIndex = ...
        if uin == localPlayerUin then
            self.plants[positionIndex] = nil
            self.plantCards[positionIndex] = nil
        end
    elseif eventName == 'OnLevelWave' then
        for _, plant in pairs(self.plants) do
            if plant then
                _G.LogicHub:ClientApply('remove_outdated_bonus', 'plant', plant.positionIndex)
                _G.LogicHub:ClientApply('remove_outdated_bonus', 'player', Players.LocalPlayer.UserId)
            end
        end
        _G.LogicHub:ClientApply('remove_outdated_bonus', 'level', Players.LocalPlayer.UserId)
    elseif eventName == 'OnLevelPause' then
        local isPause = ...
        if isPause then
            self:ReleaseTrigger()
        end
    end
end

-- 传命令给LogicHub
function PlayerCharacter:ReservePlant(positionIndex, plantCard, Iscreate)
    LogicHub:ClientApply('reserve_plant', positionIndex, plantCard.name, plantCard.level, Iscreate)
end

function PlayerCharacter:ConfirmPlant()
    _G.PlayerController.playerCharacter.isReady = true

    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnConfirmPlant')

    _G.LogicHub:ClientApply('ready', true)
    return true
end

function PlayerCharacter:CancelConfirmPlant()
    _G.PlayerController.playerCharacter.isReady = false

    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnCancelConfirmPlant')

    _G.LogicHub:ClientApply('ready', false)
end

-- 战斗阶段的函数
function PlayerCharacter:AttachCameraComponent(plant)
    self.cameraController.owner = plant
    plant.bindContainer.UseCameraAngle = true

    if plant.pullingTrigger then
        plant:ReleaseTrigger()
    end
    -- 添加后座力恢复更新
    plant.recoilRecoveryFunc = function(deltaTime)
        if not self.pullingTrigger then
            -- -- 恢复垂直后座力
            -- if math.abs(plant.accumulatedVerticalRecoil) > 0.01 then
            --     local recoveryAmount = plant.recoilVerticalCorrectSpeed * deltaTime
            --     plant.accumulatedVerticalRecoil = math.max(0, math.abs(plant.accumulatedVerticalRecoil) - recoveryAmount) * (plant.accumulatedVerticalRecoil > 0 and 1 or -1)
            --     if self.cameraController then
            --         self.cameraController:InputMove(0, -plant.accumulatedVerticalRecoil)
            --     end
            -- end

            -- -- 恢复水平后座力
            -- if math.abs(plant.accumulatedHorizontalRecoil) > 0.01 then
            --     local recoveryAmount = plant.recoilHorizontalCorrectSpeed * deltaTime
            --     plant.accumulatedHorizontalRecoil = math.max(0, math.abs(plant.accumulatedHorizontalRecoil) - recoveryAmount) * (plant.accumulatedHorizontalRecoil > 0 and 1 or -1)
            --     if self.cameraController then
            --         self.cameraController:InputMove(-plant.accumulatedHorizontalRecoil, 0)
            --     end
            -- end
        end
    end

    -- 开始后座力恢复更新
    -- if not plant.recoilRecoveryConnection then
    --     plant.recoilRecoveryConnection = RunService.RenderStepped:Connect(plant.recoilRecoveryFunc)
    -- end

    plant:ActiveActive()
end

function PlayerCharacter:UnAttachCameraComponent(plant)
    if plant.isFiring then
        self:ReleaseTrigger()
    end

    plant.bindContainer.UseCameraAngle = false

    if plant.recoilRecoveryConnection then
        plant.recoilRecoveryConnection:Disconnect()
        plant.recoilRecoveryConnection = nil
    end
    plant:EndActive()
end

function PlayerCharacter:SwitchPlant(index)
    local plant = self.plants[index]
    if plant ~= nil then
        if self.controlledPlant ~= nil and self.controlledPlant ~= plant then
            self:UnAttachCameraComponent(self.controlledPlant)
        end
        self.controlledPlant = plant
        self:AttachCameraComponent(self.controlledPlant)

        self.originRotation = nil

        -- 埋点记录
        _G.LevelManager.reportExtra.plants[index].active = _G.LevelManager.reportExtra.plants[index].active + 1
    end
end

function PlayerCharacter:SwitchPlantByPos(pos)
    local maxIndex = 0
    for idx, plant in pairs(self.plants) do
        if plant then
            maxIndex = math.max(maxIndex, idx)
        end
    end

    local index = nil
    for i = 1, maxIndex do
        local plant = self.plants[i]
        if plant then
            pos = pos - 1
        end
        if pos == 0 then
            index = i
            break
        end
    end
    if index ~= nil then
        self:SwitchPlant(index)
    end
end

function PlayerCharacter:PullTrigger()
    if _G.LevelManager.currentLevel.levelPause then
        return
    end

    if not self.controlledPlant then
        return
    end

    self.pullingTriggerBeginTime = RunService:CurrentSteadyTimeStampMS()
    self.pullingTrigger = true
end

function PlayerCharacter:ReleaseTrigger()
    if self.pullingTrigger then
        _G.PlayerController.SetFov(50)
        self.pullingTrigger = false

        if self.controlledPlant then
            local targetPosition = _G.PlayerController:GetPositionUnderCursor()
            _G.LogicHub:ClientApply('stop_fire', self.controlledPlant.positionIndex, targetPosition)
        end
    end
end

function PlayerCharacter:Destroy()
    self.pullingTrigger = false

    self.cameraController:Destroy()
    self.cameraController = nil
    if self.directionUpdateConnection then
        self.directionUpdateConnection:Disconnect()
        self.directionUpdateConnection = nil
    end
end

function LogicNotifyHandler.remove_bonus_player(uin, bonus)
    if uin == Players.LocalPlayer.UserId then
        -- DoNothing
    end
end

return PlayerCharacter
