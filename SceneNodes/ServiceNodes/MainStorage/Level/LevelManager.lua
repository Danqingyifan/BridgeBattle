local MainStorage = game:GetService('MainStorage')
local WorkSpace = game:GetService('WorkSpace')
local Players = game:GetService('Players')
local Environment = WorkSpace.Environment

local GameCenterBridge = require(MainStorage.Common.GameCenterBridge)
local CustomConfig = require(MainStorage.Common.CustomConfig)
local EventManager = require(MainStorage.Common.EventManager)
local PoolManager = require(MainStorage.Subsystem.PoolManager)

-- Init
local LevelManager = {
    eventObject = EventManager.SystemRegister('LevelManager'),
    eventNames = {
        'OnEnterLobby'
    }
}

local LOADING_TEXT = {
    '正在给豌豆射手刷牙，请勿打扰它的晨间仪式',
    '向日葵正在练习微笑，阳光产量+10%',
    '寒冰射手正在冰箱里挑选今日的冷冻套餐',
    '火爆辣椒正在热身，准备喷出火焰',
    '坚果墙在做俯卧撑，争取变得更硬',
    '樱桃炸弹在数倒计时，但总是数错',
    '土豆地雷在地下偷偷挖洞，想给你一个惊喜',
    '双发射手正在调试双管，确保射击精准',
    '大喷菇正在练习深呼吸，准备喷得更远',
    '胆小菇躲在被窝里，需要一点鼓励',
    '玉米加农炮在超市抢购黄油，请稍候',
    '卷心菜投手在练习抛物线数学题',
    '西瓜投手在切西瓜，但总切不均匀',
    '大蒜正在磨刀，准备吓跑僵尸',
    '三叶草正在充气，准备吹飞所有气球',
    '仙人掌在给自己的刺做发型',
    '磁力菇在吸硬币，凑钱买新装备',
    '火爆辣椒在做热身运动，避免拉伤',
    '高坚果在量身高，看看有没有长高',
    '小喷菇在努力长大，想变成大喷菇',
    '僵尸们正在排队化妆，准备上镜',
    '读报僵尸在读报纸，暂时没空理你',
    '铁桶僵尸在找他的桶，可能丢在路上了',
    '舞王僵尸在练习新舞步，准备惊艳全场',
    '撑杆跳僵尸在找杆子，可能被借走了',
    '博士僵尸在修理他的机器，但说明书不见了'
}

function LevelManager.Init()
    local function RegisterEvents()
        -- 监听事件
        for _, eventName in pairs(LevelManager.eventNames) do
            EventManager.AddListener(
                LevelManager.eventObject,
                eventName,
                function(...)
                    LevelManager.Update(eventName, ...)
                end
            )
        end
    end
    RegisterEvents()
end

function LevelManager.Update(eventName, ...)
    if eventName == 'OnEnterLobby' then
        LevelManager.CreateLevel('Lobby')
    end
end

function LevelManager.CreateLevel(LevelName)
    LevelManager.DestroyCurrentLevel()
    LevelManager.LoadLevel(LevelName)
end

function LevelManager.DestroyCurrentLevel()
    if LevelManager.PlantManager then
        LevelManager.PlantManager.DestroyAllPlants()
    end
    if LevelManager.BulletManager then
        LevelManager.BulletManager.DestroyAllBullets()
    end
    if LevelManager.ZombieManager then
        LevelManager.ZombieManager.DestroyAllZombies()
    end

    if LevelManager.currentLevel ~= nil then
        LevelManager.currentLevel.levelInstance:Destroy()
        LevelManager.currentLevel = nil
    end
end

function LevelManager.LoadLevel(LevelName)
    local level = {
        levelName = LevelName,
        levelInstance = CustomConfig.GetCustomConfigNode('Level', LevelName).Prefab:Clone(),
        levelPause = false
    }
    level.levelInstance.Name = LevelName
    level.levelInstance.Parent = WorkSpace

    LevelManager.currentLevel = level

    local ENUMS = {
        SkyBoxType = {
            Enum.SkyBoxType.Game,
            Enum.SkyBoxType.Custom,
            Enum.SkyBoxType.Advance,
            Enum.SkyBoxType.Disable
        },
        SkyLightType = {
            Enum.SkyLightType.Skybox,
            Enum.SkyLightType.Color,
            Enum.SkyLightType.Gradient
        },
        FogType = {
            Enum.FogType.Disable,
            Enum.FogType.Linear
        },
        ShadowCascadeCount = {
            Enum.ShadowCascadeCount.ONE,
            Enum.ShadowCascadeCount.TWO,
            Enum.ShadowCascadeCount.THREE,
            Enum.ShadowCascadeCount.FOUR
        },
        AntialiasingMethod = {
            Enum.AntialiasingMethodDesc.kAntialiasingMethodFXAA,
            Enum.AntialiasingMethodDesc.kAntialiasingMethodSMAA
        },
        AntialiasingQuality = {
            Enum.AntialiasingQualityDesc.kAntialiasingQualityLow,
            Enum.AntialiasingQualityDesc.kAntialiasingQualityMedium,
            Enum.AntialiasingQualityDesc.kAntialiasingQualityHigh
        },
        LUTsTemperatureType = {
            Enum.LUTsTemperatureType.WhilteBalance,
            Enum.LUTsTemperatureType.Color
        },
        VignetteMode = {
            Enum.VignetteMode.Classic,
            Enum.VignetteMode.Masked
        }
    }

    -- Init Environment
    local function PreStartLevel()
        local configNode = CustomConfig.GetCustomConfigNode('Level', LevelManager.currentLevel.levelName)
        local environmentConfig = require(configNode.Data)
        for name, tb in pairs(environmentConfig) do
            local node
            if name == 'AreaCameraConfig' or name == 'LevelConfig' then
                node = nil
                tb = {}
            elseif name == 'Skydome' then
                node = Environment.SkyDome
            else
                node = assert(Environment[name], name)
            end
            for key, value in pairs(tb) do
                if name == 'SunLight' then
                    if key == 'SunLightColor' then
                        key = 'Color'
                    elseif key == 'SunLightEuler' then
                        key = 'Euler'
                    end
                elseif name == 'Skydome' then
                    if key == 'AdvanceMaterialAssetID' then
                        key = nil
                        node:SetAdvanceMaterialAssetID(
                            value,
                            function()
                            end
                        )
                    end
                end
                if key then
                    if ENUMS[key] then
                        value = ENUMS[key][value + 1]
                    end
                    if value ~= nil then
                        node[key] = value
                    end
                end
            end
        end
    end

    PreStartLevel()
    LevelManager.LoadLevelAssetAsset(LevelName)
end

local function check_loading(node)
    local total = 0
    local loaded = 0
    if node:IsA('Model') and #node.ModelId > 10 then
        total = total + 1
        if node:IsLoadFinish() then
            loaded = loaded + 1
        end
    end
    for _, child in ipairs(node.Children) do
        local t, c = check_loading(child)
        total = total + t
        loaded = loaded + c
    end
    return total, loaded
end

local loading_count = 0
function LevelManager.StartCheckLoading()
    loading_count = 0
    coroutine.work(
        function()
            while true do
                local node = LevelManager.currentLevel.levelInstance
                local total, loaded = check_loading(node)
                loading_count = loading_count + 1
                print('Loading:', total, loaded, loading_count)
                if loaded + 3 >= total then
                    game.GameSetting:SetLoadingCustomPartFinished(true)
                    return
                end
                local index = math.floor(loading_count / 2) % #LOADING_TEXT + 1
                game.GameSetting:SetLoadingCustomPartLog(LOADING_TEXT[index])
                wait(1)
            end
        end
    )
end

function LevelManager.LoadLevelAssetAsset(levelName)
    if levelName == 'Lobby' then
        return
    end
    coroutine.work(
        function()
            AssetLoadingUI.show()
            local bLoading = false
            while true do
                if bLoading then
                    AssetLoadingUI.hide()
                    return
                end
                local node = LevelManager.currentLevel.levelInstance
                local total, loaded = check_loading(node)
                print('Loading:', total, loaded)
                AssetLoadingUI.progress(loaded / total)
                if loaded + 5 >= total then
                    bLoading = true
                end
                wait(1)
            end
        end
    )
end

local function v2s(value)
    local typ = type(value)
    if typ == 'string' then
        return string.format('%q', value)
    elseif typ ~= 'table' then
        return tostring(value)
    end
    local result = {}
    if value[1] then
        for i, v in ipairs(value) do
            result[i] = v2s(v)
        end
        return '[' .. table.concat(result, ',') .. ']'
    end
    for k, v in pairs(value) do
        result[#result + 1] = string.format('%q:%s', k, v2s(v))
    end
    return '{' .. table.concat(result, ',') .. '}'
end

function LevelManager.GetReportExtra()
    local logic = _G.LogicHub.CurrentLogic
    local re = {}
    for k, v in pairs(LevelManager.reportExtra) do
        re[k] = v
    end
    re.totalTime = logic:Now()
    local plants = {}
    for index, plant in pairs(re.plants) do
        plant.level = logic.Plants[index].level
        plants[#plants + 1] = plant
    end
    re.plants = plants
    return v2s(re)
end

-- LogicNotifyHandler
function LogicNotifyHandler.create(levelName)
    LevelManager.CreateLevel(levelName)
    LevelManager.ZombieManager = require(script.ZombieManager)
    LevelManager.PlantManager = require(script.PlantManager)
    LevelManager.BulletManager = require(script.BulletManager)

    LevelManager.ZombieManager.Init()
    LevelManager.PlantManager.Init()
    LevelManager.BulletManager.Init()
    local configNode = CustomConfig.GetCustomConfigNode('Level', LevelManager.currentLevel.levelName)
    local config = require(configNode.Data)

    LevelManager.reportExtra = {
        startTime = -1,
        totalTime = -1,
        plants = {},
        zombie = 0,
        kill = 0,
        sunflower = _G.LogicHub.CurrentLogic.SunflowerHP,
        bonus = {},
        waveCount = 0
    }

    EventManager.FireEvent(_G.PlayerController.eventObject, 'OnEnterLevelPrepare', config.AreaCameraConfig[1])
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnEnterLevelPrepare')

    _G.LogicHub.StopClientApply = false
end

function LogicNotifyHandler.sync(time)
end

function LogicNotifyHandler.stop(reason, win, sorted, stopInfo)
    _G.LogicHub.StopClientApply = true
    EventManager.FireEvent(_G.PlayerController.eventObject, 'OnEnterLevelEnd', win)
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnEnterLevelEnd', win)
    PoolManager.DestroyPool('SoundPool')
    PoolManager.DestroyPool('EffectPool')

    if reason == 'game_result' then
        local teamInfo = GameCenterBridge.Data.TeamInfo
        local playerInfo = teamInfo and teamInfo.players and teamInfo.players[1]
        if teamInfo == nil or next(teamInfo) == nil or (playerInfo and playerInfo.uin == Players.LocalPlayer.UserId) then
            print('发送结算请求',win, sorted, stopInfo)
            GameNet:SendMsgToServer('GET_STOP_SETTLEMENT', win, sorted, stopInfo)
        end
    end
end

function LogicNotifyHandler.game_begin()
    EventManager.FireEvent(_G.PlayerController.eventObject, 'OnEnterLevelStart')
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnEnterLevelStart')

    PoolManager.CreatePool('SoundPool', LevelManager.currentLevel.levelInstance)
    PoolManager.CreatePool('EffectPool', LevelManager.currentLevel.levelInstance)

    for _, plant in pairs(LevelManager.PlantManager.Plants) do
        plant:PreEnterBattle()
    end

    LevelManager.reportExtra.startTime = _G.LogicHub.CurrentLogic:Now()
end
--更新准备人数ui
function LogicNotifyHandler.update_ready_count(readyCount, playerCount,ok)
    print('进行UI更新')
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateReadyCount', readyCount, playerCount,ok)
end
--更新游戏倒计时的UI
function LogicNotifyHandler.update_countdown(player,position,needCreate)
    print('倒计时更新',player,position)
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnUpdateCountdown', player,position,needCreate)
end

function LogicNotifyHandler.game_wave()
    -- 第一波开始
    if _G.LogicHub.CurrentLogic.waveCount == 1 then
        for _, plant in pairs(LevelManager.PlantManager.Plants) do
            plant:EnterBattle()
            plant.bindContainer.Parent.PlantReserveBoard.Visible = false
        end
        EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnSunflowerHealthUpdate', _G.LogicHub.CurrentLogic.SunflowerHP)
    end
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnLevelWave')
    EventManager.FireEvent(_G.PlayerController.playerCharacter.eventObject, 'OnLevelWave')

    LevelManager.reportExtra.waveCount = _G.LogicHub.CurrentLogic.waveCount
end

function LogicNotifyHandler.game_action(action, ...)
    EventManager.FireEvent(_G.PlayerController.playerCharacter.eventObject, 'OnLevelAction', action, ...)
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnLevelAction', action, ...)
end

function LogicNotifyHandler.game_result(...)
    _G.LogicHub:ClientToHub('game_result', LevelManager.GetReportExtra(), ...)
end

function LogicNotifyHandler.add_bonus_level(uin, bonus)
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnSunflowerHealthUpdate', _G.LogicHub.CurrentLogic.SunflowerHP)
end

function LogicNotifyHandler.remove_bonus_level(uin, bonus)
    EventManager.FireEvent(_G.PlayerController.playerHUD.eventObject, 'OnSunflowerHealthUpdate', _G.LogicHub.CurrentLogic.SunflowerHP)
end

function LogicNotifyHandler.pause()
    LevelManager.currentLevel.levelPause = true
    EventManager.FireEvent(_G.PlayerController.playerCharacter.eventObject, 'OnLevelPause', true)
end

function LogicNotifyHandler.resume()
    LevelManager.currentLevel.levelPause = false
    EventManager.FireEvent(_G.PlayerController.playerCharacter.eventObject, 'OnLevelPause', false)
end

return LevelManager
