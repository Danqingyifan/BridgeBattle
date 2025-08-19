local WorkSpace = game:GetService('WorkSpace')
local MainStorage = game:GetService('MainStorage')
local RunService = game:GetService('RunService')
local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')

local GameCenterBridge = require(MainStorage.Common.GameCenterBridge)
local EventManager = require(MainStorage.Common.EventManager)
local CameraRun = require(MainStorage.Camera.CameraRun)
local Utils = require(MainStorage.Common.Utils)

local SoundManager = require(MainStorage.Subsystem.SoundManager)

local PlayerCharacter = require(MainStorage.Player.PlayerCharacter)
local PoolManager = require(MainStorage.Subsystem.PoolManager)

local PlayerController = {
    eventObject = EventManager.SystemRegister('PlayerController'),
    eventNames = {
        'OnPlayerDataRefresh',
        'OnEnterLobby',
        'OnEnterLevelPrepare',
        'OnEnterLevelStart',
        'OnEnterLevelBattle',
        'OnEnterLevelEnd'
    },
    playerCardLoadout = require(MainStorage.Player.PlayerCardLoadout),
    playerHUD = require(MainStorage.Player.PlayerHUD)
}

local TweenService = game:GetService('TweenService')

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
        _G.GameNet:RegServerMsgCallback(
            'SET_SELECTED_LEVEL_RESPONSE',
            function(levelName, levelDifficulty)
                PlayerController.selectedLevel = levelName
                PlayerController.selectedLevelDifficulty = levelDifficulty
                EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnLeaderSelectLevel', levelName, levelDifficulty)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'SET_SELECTED_LEVEL_MODE_RESPONSE',
            function(levelMode)
                PlayerController.selectedLevelMode = levelMode
                EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnLeaderSelectLevelMode', levelMode)
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'GET_SELECTED_LEVEL_RESPONSE',
            function(levelName, levelDifficulty)
                PlayerController.selectedLevel = levelName
                PlayerController.selectedLevelDifficulty = levelDifficulty
            end
        )
        _G.GameNet:RegServerMsgCallback(
            'GET_SELECTED_LEVEL_MODE_RESPONSE',
            function(levelMode)
                PlayerController.selectedLevelMode = levelMode
            end
        )
        _G.GameCenterBridge.Event.OnTeamInfoChanged.Notify:Connect(
            function()
                PlayerController.isInTeam = _G.GameCenterBridge.Data.TeamInfo and next(_G.GameCenterBridge.Data.TeamInfo) ~= nil
                if PlayerController.isInTeam then
                    PlayerController.teamLeader = _G.GameCenterBridge.Data.TeamInfo.leader
                else
                    PlayerController.teamLeader = nil
                end
            end
        )
    end
    RegisterEvents()
    RegisterServerCallback()

    PlayerController.playerCardLoadout.Init()
    PlayerController.playerHUD.Init()

    -- Team
    PlayerController.isInTeam = _G.GameCenterBridge.Data.TeamInfo and next(_G.GameCenterBridge.Data.TeamInfo) ~= nil
    if PlayerController.isInTeam then
        _G.GameNet:SendMsgToServer('GET_SELECTED_LEVEL_MODE_REQUEST', Players.LocalPlayer.UserId)
        PlayerController.teamLeader = _G.GameCenterBridge.Data.TeamInfo.leader
        _G.GameNet:SendMsgToServer('GET_SELECTED_LEVEL_REQUEST', Players.LocalPlayer.UserId)
    else
        PlayerController.teamLeader = nil
        PlayerController.selectedLevelMode = 'Career'
        PlayerController.selectedLevel = 'Lobby'
        PlayerController.selectedLevelDifficulty = 0
        PlayerController.maxDifficulty = 3
    end
end

-- Event
function PlayerController.Update(eventName, ...)
    -- Scene Change
    if eventName == 'OnEnterLobby' then
        PlayerController.SetFov(50)

        if PlayerController.playerCharacter then
            PlayerController.playerCharacter:Destroy()
            PlayerController.playerCharacter = nil
        end
        PlayerController:KeyMouseUnbinding()

        CameraRun:Stop()
        SoundManager.ReplaceBackground(SoundManager.SoundId_HallBackground)

        wait(0.2)
        CameraRun:Start('RouteLobby', true)
        if PlayerController.CameraLobbyPos == nil then
            PlayerController.CameraLobbyPos = WorkSpace.CurrentCamera.LocalPosition
            PlayerController.CameraLobbyEuler = WorkSpace.CurrentCamera.LocalRotation
        else
            WorkSpace.CurrentCamera.LocalPosition = PlayerController.CameraLobbyPos
            WorkSpace.CurrentCamera.LocalRotation = PlayerController.CameraLobbyEuler
        end
        print('PlayerController.CameraLobbyPos', PlayerController.CameraLobbyPos)
        print('PlayerController.CameraLobbyEuler', PlayerController.CameraLobbyEuler)
    elseif eventName == 'OnEnterLevelPrepare' then
        -- camera
        local cameraData = select(1, ...)
        CameraRun:Stop()

        local Camera = WorkSpace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Scriptable

        Camera.Position = cameraData.Position
        Camera.Euler = cameraData.Euler

        -- Init PlayerCharacter
        PlayerController.BindPlantingModeContext()
        PlayerController.playerCharacter = PlayerCharacter.New()
        PlayerController.playerCharacter:Init()
    elseif eventName == 'OnEnterLevelStart' then
        --EffectManager.AddRain()
        CameraRun:Start(
            'RouteEnter',
            false,
            function()
                EventManager.FireEvent(PlayerController.eventObject, 'OnEnterLevelBattle')
                EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnEnterLevelBattle')
            end
        )
        PlayerController.UnbindPlantingModeContext()
        PlayerController.BindTPSContext()
        -- 播放背景音乐
        SoundManager.ReplaceBackground(SoundManager.SoundId_BattleBackground)
        SoundManager.Play(SoundManager.SoundId_BattleBegin, false)
        SoundManager.Play(SoundManager.SoundId_ZombieComing, false, 5000)
    elseif eventName == 'OnEnterLevelBattle' then
        PlayerController.playerCharacter:EnterLevelBattle()
    elseif eventName == 'OnEnterLevelEnd' then
        --EffectManager.RemoveRain()
        local win = ...
        local soundId = SoundManager.SoundId_ResultDefeat
        if win then
            soundId = SoundManager.SoundId_ResultWin
        end
        SoundManager.Play(soundId, false, 5000)
        PlayerController.KeyMouseUnbinding()
    end
end

-- Input Event
function PlayerController.OnFireInputBegin(vector2)
    if _G.PlayerController.playerHUD.GetUIRoot('GuideManager') then
        _G.PlayerController.playerHUD.GetUIRoot('GuideManager'):PassGuide('LevelBattelFire')
    end

    EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnFireInputBegin')
    -- 记录按下的位置
    if vector2 then

        PlayerController.fireInputBeginPos = vector2
    end
    -- 这一句只能放在最下面，否则会堵塞后面的语句执行
    PlayerController.playerCharacter:PullTrigger()
end

function PlayerController.OnFireInputMove(vector2)
    -- 计算移动的距离

    local moveDistance = vector2 - PlayerController.fireInputBeginPos
    -- 更新按下的位置
    PlayerController.fireInputBeginPos = vector2
    PlayerController.playerCharacter.cameraController:InputMove(moveDistance.x, moveDistance.y)
end

function PlayerController.OnFireInputEnd()
    EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnFireInputEnd')

    PlayerController.playerCharacter:ReleaseTrigger()
end

function PlayerController.OnSwitchPlant(index)
    PlayerController.isSwitchingPlant = true
    if _G.PlayerController.playerHUD.GetUIRoot('GuideManager') then
        _G.PlayerController.playerHUD.GetUIRoot('GuideManager'):PassGuide('LevelSwichPlant')
    end
    PlayerController.playerCharacter:SwitchPlant(index)
end

function PlayerController.OnSwitchPlantByPos(pos)
    PlayerController.isSwitchingPlant = true
    if _G.PlayerController.playerHUD.GetUIRoot('GuideManager') then
        _G.PlayerController.playerHUD.GetUIRoot('GuideManager'):PassGuide('LevelSwichPlant')
    end
    PlayerController.playerCharacter:SwitchPlantByPos(pos)
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

function PlayerController.BindPlantingModeContext()
    local function OnPlantingMode(actionName, inputState, inputObj)
        if inputState == Enum.UserInputState.InputBegin.Value then
            local raycastResult2 = Utils.TryGetRaycastUnderCursor(inputObj, 3000, false, {2})
            local teamInfo = _G.GameCenterBridge.Data.TeamInfo
            local plant = raycastResult2.obj
            if raycastResult2.isHit and plant.Parent.Parent:GetAttribute('PositionIndex') then
                if not teamInfo or next(teamInfo) == nil then
                    -- 单人模式
                    local positionIndex = plant.Parent.Parent:GetAttribute('PositionIndex')

                    _G.LogicHub:ClientApply('destroy_plant', positionIndex)
                    return
                else
                    -- 多人模式
                    if _G.LogicHub.CurrentLogic.Players[Players.LocalPlayer.UserId].ready == true  or _G.LogicHub.CurrentLogic.Players[Players.LocalPlayer.UserId].IsBegin == true then
                        return
                    end
                    local positionIndex = plant.Parent.Parent:GetAttribute('PositionIndex')
                    local currentPlant = _G.LogicHub.CurrentLogic.Plants[positionIndex]
                    if currentPlant.player.uin == Players.LocalPlayer.UserId then   
                        _G.LogicHub:ClientApply('destroy_plant', positionIndex)
                    end
                end
            end
        end

        if PlayerController.isPlantingMode == false then
            return
        end

        if inputState == Enum.UserInputState.InputBegin.Value then
            -- 花盆的碰撞层级是5
            local raycastResult = Utils.TryGetRaycastUnderCursor(inputObj, 3000, false, {5})

            local plantPos = raycastResult.obj
            if raycastResult.isHit and plantPos:GetAttribute('GameplayTag') == 'WeaponPlantPosition' then
                local positionIndex = plantPos:GetAttribute('PositionIndex')
                -- selectedCard 在 LevelPrepare 中已经设置
                -- 多人模式
                local teamInfo = _G.GameCenterBridge.Data.TeamInfo
                if teamInfo and next(teamInfo) ~= nil then
                    local plant = _G.LogicHub.CurrentLogic.Plants[positionIndex]
                    if plant then
                        return
                    end
                    if _G.PlayerController.playerCharacter.isReady == true then
                        return
                    end
                    for _, plant in pairs(_G.LogicHub.CurrentLogic.Players[Players.LocalPlayer.UserId].plants) do
                        print('多人模式，已经达到最大种植数量')
                        EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnPlantMaxCount')
                        return
                    end
                    _G.LogicHub:ClientApply('create_plant', positionIndex, PlayerController.selectedCard.name, PlayerController.selectedCard.level)
                    PlayerController.playerCharacter:ReservePlant(positionIndex, PlayerController.selectedCard)
                else
                    -- 单人模式，直接种植
                    local plant = _G.LogicHub.CurrentLogic.Plants[positionIndex]
                    if plant then
                        _G.LogicHub:ClientApply('destroy_plant', positionIndex)
                    end
                    _G.LogicHub:ClientApply('create_plant', positionIndex, PlayerController.selectedCard.name, PlayerController.selectedCard.level)
                end
            end
            PlayerController.isPlantingMode = false
            PlayerController.selectedCard = nil
            EventManager.FireEvent(PlayerController.playerHUD.eventObject, 'OnPlantEnd')
        end
    end

    if RunService:IsPC() then
        ContextActionService:BindContext(
            'PlantingModePC',
            function(actionName, inputState, inputObj)
                OnPlantingMode(actionName, inputState, inputObj)
            end,
            false,
            Enum.UserInputType.MouseButton1
        )
    end

    if RunService:IsMobile() then
        ContextActionService:BindContext(
            'PlantingModeMobile',
            function(actionName, inputState, inputObj)
                OnPlantingMode(actionName, inputState, inputObj)
            end,
            false,
            Enum.UserInputType.Touch
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

function PlayerController.UnbindPlantingModeContext()
    if RunService:IsPC() then
        ContextActionService:UnbindContext('PlantingModePC')
    end
    if RunService:IsMobile() then
        ContextActionService:UnbindContext('PlantingModeMobile')
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

-- Camera相关
function PlayerController.SetFov(fov)
    if PlayerController.Fov == fov then
        return
    end
    PlayerController.Fov = fov

    if PlayerController.cameraTween then
        PlayerController.cameraTween:Destroy()
    end
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
    PlayerController.cameraTween = TweenService:Create(WorkSpace.CurrentCamera, tweenInfo, {FieldOfView = fov})
    PlayerController.cameraTween:Play()
end

function PlayerController.SetPostProcessing(chromaticAberrationIntensity, chromaticAberrationStartOffset, chromaticAberrationIterationStep, chromaticAberrationIterationSamples)
    local postProcessing = WorkSpace.Environment.PostProcessing
    postProcessing.ChromaticAberrationIntensity = chromaticAberrationIntensity
    postProcessing.ChromaticAberrationStartOffset = chromaticAberrationStartOffset
    postProcessing.ChromaticAberrationIterationStep = chromaticAberrationIterationStep
    postProcessing.ChromaticAberrationIterationSamples = chromaticAberrationIterationSamples
end

function PlayerController.ExitGame()
    PoolManager.DestroyPool('SoundPool')
    PoolManager.DestroyPool('EffectPool')
    _G.LogicHub:ClientExit(_G.LevelManager.GetReportExtra())
    EventManager.FireEvent(_G.LevelManager.eventObject, 'OnEnterLobby')
    EventManager.FireEvent(_G.PlayerController.eventObject, 'OnEnterLobby')
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnEnterLobby')
    if GameCenterBridge:HasTeamInfo() then
        GameCenterBridge.PlayerRequest:LeaveTeam()
    end
    GameCenterBridge.PlayerRequest:MarkPlayerPlaying(false)
end

function LogicNotifyHandler.player_exit(exiterUin)
    -- 将退出玩家的植物变灰色
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnExitGame', exiterUin)
end

return PlayerController
