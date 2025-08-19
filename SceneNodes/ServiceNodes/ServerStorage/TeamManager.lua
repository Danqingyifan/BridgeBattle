local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')
local MainStorage = game:GetService('MainStorage')
local SMatch = require(ServerStorage.SGameCenter.SMatch)
local PlayerDataManager = require(ServerStorage.PlayerDataManager)
local CustomConfig = require(MainStorage.Common.CustomConfig)
local PlantConfig = require(MainStorage.Config.PlantConfig)
local RankingListService = require(ServerStorage.RankingListService)
local RankingData = require(MainStorage.Common.RankingData)
local Utils = require(MainStorage.Common.Utils)

local TeamManager = {
    selectedLevel = 'Lobby',
    selectedLevelMode = 'Career',
    selectedLevelDifficulty = 0,
    teamInfoList = {}
}

function TeamManager.Init()
    local function RegisterStartBattleEvent()
        -- 队长开始战斗了
        SMatch.OnTeamStartBattle.Notify:Connect(
            function(teamInfo, startBattleArgs)
                table.insert(TeamManager.teamInfoList, Utils.DeepCopy(teamInfo))
                local playerList = {}
                for _, teamPlayerInfo in ipairs(teamInfo.players) do
                    local uin = teamPlayerInfo.uin
                    local player = Players:GetPlayerByUserId(uin)
                    table.insert(playerList, player)
                end
                print('TeamManager.Init', startBattleArgs.levelName, 'Infinite')
                LogicHub:StartServer(playerList, startBattleArgs.levelName, 'Infinite', startBattleArgs.levelDifficulty)
            end
        )
    end
    local function RegisterClientCallback()
        _G.GameNet:RegClientMsgCallback(
            'GET_SELECTED_LEVEL_REQUEST',
            function(playerId)
                _G.GameNet:SendMsgToClient(
                    playerId,
                    'GET_SELECTED_LEVEL_RESPONSE',
                    TeamManager.selectedLevel,
                    TeamManager.selectedLevelDifficulty
                )
            end
        )
        _G.GameNet:RegClientMsgCallback('GET_STOP_SETTLEMENT', TeamManager.OnGetStopSettlement)
        _G.GameNet:RegClientMsgCallback(
            'GET_SELECTED_LEVEL_MODE_REQUEST',
            function(playerId)
                _G.GameNet:SendMsgToClient(playerId, 'GET_SELECTED_LEVEL_MODE_RESPONSE', TeamManager.selectedLevelMode)
            end
        )

        _G.GameNet:RegClientMsgCallback(
            'SET_SELECTED_LEVEL_REQUEST',
            function(playerId, levelName, levelDifficulty)
                TeamManager.selectedLevel = levelName
                TeamManager.selectedLevelDifficulty = levelDifficulty
                _G.GameNet:BroadcastMsg(
                    'SET_SELECTED_LEVEL_RESPONSE',
                    TeamManager.selectedLevel,
                    TeamManager.selectedLevelDifficulty
                )
            end
        )
    end

    RegisterStartBattleEvent()
    RegisterClientCallback()
end

function TeamManager.OnGetStopSettlement(uin, result, sorted, stopInfo)
    local zombieCount = 0
    local diamondNum = 0
    local sortCount=0
    local IsFirstPass = true
    local currentLevelProgress
    local rankList = {}
    local cardrewards = {}
    
    local finishedArgs = {
        killCount = 0,
        levelName = stopInfo.levelName,
        levelMode = stopInfo.levelMode,
        levelDifficulty = stopInfo.levelDifficulty,
        points=0,
    }
    for i,player in pairs(sorted) do
        sortCount=sortCount+player.kc*100
    end


    for i, player in pairs(sorted) do
        zombieCount = player.goldNum
        finishedArgs.killCount = finishedArgs.killCount + player.kc
        finishedArgs.points = finishedArgs.points + player.kc * 100
        if result then
            diamondNum = zombieCount * 1 + player.extraGoldNum
        else
            diamondNum = zombieCount * 1
            if diamondNum < 1 then
                diamondNum = 1
            end
        end

        local num = tonumber(string.match(stopInfo.levelName, '%d+'))
        --波束修改
        local waveCount = math.random(1,4)
        if result == true then
            currentLevelProgress =
                PlayerDataManager:GetProgress(
                player.uin,
                num,
                stopInfo.levelMode,
                stopInfo.levelDifficulty
            )
            IsFirstPass = (currentLevelProgress.levelRecord or 0) <= 0
            if IsFirstPass == true then
                diamondNum = diamondNum + 50000
            end

            local nextLevelProgress =
                PlayerDataManager:GetProgress(
                player.uin,
                num,
                stopInfo.levelMode,
                stopInfo.levelDifficulty + 1
            )
            local mextLevelNumber=
            PlayerDataManager:GetProgress(
                player.uin,
                num+1,
                stopInfo.levelMode,
                1
            )
            --进行关卡解锁
            if IsFirstPass or nextLevelProgress.levelRecord == nil or mextLevelNumber.levelRecord == nil then
                local newLevelProgress
                if stopInfo.levelMode == 'Career' then
                    if num == 3 then
                        newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num + 1,
                            stopInfo.levelMode,
                            1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                        newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num + 2,
                            stopInfo.levelMode,
                            1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                        newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num,
                            stopInfo.levelMode,
                            stopInfo.levelDifficulty + 1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                    elseif num == 6 then
                        -- doNothing
                         newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num,
                            stopInfo.levelMode,
                            stopInfo.levelDifficulty + 1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                    else
                        newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num + 1,
                            stopInfo.levelMode,
                            1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                        newLevelProgress =
                            PlayerDataManager:UnlockProgress(
                            player.uin,
                            num,
                            stopInfo.levelMode,
                            stopInfo.levelDifficulty + 1
                        )
                        _G.GameNet:SendMsgToClient(
                            player.uin,
                            'UNLOCK_LEVEL_PROGRESS_RESPONSE',
                            newLevelProgress
                        )
                    end
                end
            end
            PlayerDataManager:SetProgress(player.uin, num, stopInfo.levelMode, stopInfo.levelDifficulty, stopInfo.time)

        end
        local IsSuccess = PlayerDataManager:CheckEnergyEnough(player.uin, 10) --判断体力是否足够

        if player.uin == uin and IsSuccess then --如果是自身
            --扣除体力增加金币

            local info = {
                uin = player.uin,
                itemType = 'energy',
                cfgId = 0,
                reason = 'Settlement'
            }
            PlayerDataManager:SubData(info, 10) -- 消耗t体力 

            --增加卡片
            local treasureConfig = CustomConfig.GetConfig('Treasure', 'TreasureBattleEnd')
            local weights = {0}
            local totalWeight = 0
            
            for _, reward in pairs(treasureConfig.rewardList) do
                -- 只有卡牌有权重，货币必得
                if reward.rewardType == 0 then
                    totalWeight = totalWeight + reward.rewardProbability
                    table.insert(weights, totalWeight)
                end
            end
            for i=1,waveCount do
                local cardQuality = 1
                local rewardCount = 1

                local randomWeight = math.random()*totalWeight
                for index, reward in pairs(treasureConfig.rewardList) do
                    if reward.rewardType == 0 and randomWeight <= weights[index + 1] and randomWeight > weights[index] then
                        cardQuality = reward.rewardCardQuality
                        rewardCount  = math.random(reward.rewardCardCountMin, reward.rewardCardCountMax)
                        break
                    end
                end
                local plantConfigs = PlantConfig:GetPlantConfigsByQuality(cardQuality)
                local randomIndex = math.random(1, #plantConfigs)
                local cardId = plantConfigs[randomIndex].PlantId
                -- 处理卡牌奖励
                -- 如果卡牌不存在，则添加卡牌，并减少1张卡牌经验
                local decreaseNum = 0
                if not PlayerDataManager:CheckZSCardExist(player.uin, cardId) then
                    local info1 = {
                        uin = player.uin,
                        itemType = 'plant',
                        cardId = cardId,
                        reason = 'Settlement',
                        cfgId = cardId,
                    }
                    PlayerDataManager:AddData(info1, 1)
                    decreaseNum = 1
                end
                local info = {
                    itemType = 'plant_exp',
                    uin = player.uin,
                    cardId = cardId,
                    reason = 'Settlement',
                    cfgId = cardId,
                }
                PlayerDataManager:AddData(info, rewardCount - decreaseNum)

                table.insert(
                    cardrewards,
                    {
                        rewardType = 'Card',
                        cardId = cardId,
                        cardCount = rewardCount,--奖励的卡牌数量
                        cardExp = info.newCount--当前卡牌经验
                    }
                )
            end

            local info2 = {
                uin = uin,
                itemType = 'currency',

                cfgId = 0,
                reason = 'StorePurchase'
            }
            PlayerDataManager:AddData(info2, diamondNum)
        end

        local reward = {
            uin = player.uin,
            result = result, --是否胜利
            diamond = diamondNum, --金币数量
            Ranking = i, --排名
            waveCount = waveCount, --波数
            killedZombieCount =  player.kc, --击杀僵尸数量
            killScore =   sortCount, --击杀分数
            Time = stopInfo.time, --战斗时间
            IsSuccess = IsSuccess, --体力是否足够
            IsFirstPass = IsFirstPass, --是否首次通关
            cardrewards = cardrewards, --卡牌奖励
            difficulty = stopInfo.levelDifficulty, --难度
            levelId=num
        }
        table.insert(rankList, reward)
    end

    finishedArgs.time = stopInfo.time
    finishedArgs.levelMode = stopInfo.levelMode
    local RankingLevel = nil
    local playerData = PlayerDataManager.GetPlayerData(uin)             -- studio 不进榜
    if not playerData.IsStudio then
        local tInfo, idx = TeamManager.GetTeamInfoByUin(uin)
        if tInfo then
            RankingLevel = TeamManager.OnTeamBattleFinished(uin, finishedArgs)
        else
            RankingLevel = TeamManager.OnSingleBattleFinished(uin, result, finishedArgs)
        end
    end

    for i, player in pairs(sorted) do
        _G.GameNet:SendMsgToClient(player.uin, 'SETTLEMENT_REWARD_RESPONSE', rankList, RankingLevel or 0)
    end
    print('Send Settlement Reward Response')
end

function TeamManager.UpdatePlayerSkinID(uin)
    local player = Players:GetPlayerByUserId(uin)
    local actor = player.Character
    local skinId = actor.SkinId

    -- 更新皮肤ID记录, 用于排行榜显示
    if skinId ~= -1 then
        local dbTable = KVStoreService:GetPlayerKVTable(uin, PlayerKVTableEnum.HallData)
        local avatarInfo = dbTable:Get("AvatarInfo") or {}
        avatarInfo.SkinID = skinId
        avatarInfo.PartGroup = {}
        for _, part in pairs(actor.AvatarPartGroup.Children) do
            avatarInfo.PartGroup[part.Name] = part.ModelId
        end
        dbTable:Set("AvatarInfo", avatarInfo)
    end
end

function TeamManager.ClearTeamInfoByUin(uin)
    local tInfo, idx = TeamManager.GetTeamInfoByUin(uin)
    if tInfo then
        print('TeamManager.ClearTeamInfoByUin', uin, idx)
        table.remove(TeamManager.teamInfoList, idx)
    end
end

function TeamManager.GetTeamInfoByUin(uin)
    for i = 1, #TeamManager.teamInfoList do
        local teamInfo = TeamManager.teamInfoList[i]
        for _, teamPlayerInfo in ipairs(teamInfo.players) do
            if teamPlayerInfo.uin == uin then
                return teamInfo, i
            end
        end
    end
    return nil, nil
end

function TeamManager.OnTeamBattleFinished(uin, finishedArgs)
    print('TeamManager.OnTeamBattleFinished', uin)
    local tInfo, idx = TeamManager.GetTeamInfoByUin(uin)
    assert(tInfo, 'TeamManager.OnTeamBattleFinished: tInfo is nil')
    table.remove(TeamManager.teamInfoList, idx)

    local tid = tInfo.tid
    local cls = tInfo.cls
    SGameCenter:OnTeamBattleFinished(tid, cls)
    local RankLevel = RankingListService:OnTeamBattleFinished(tInfo, finishedArgs.levelName, finishedArgs.points)

    for _, playerInfo in ipairs(tInfo.players) do
        TeamManager.UpdatePlayerSkinID(playerInfo.uin)
    end
    print('TeamManager.OnTeamBattleFinished', tInfo.players, RankLevel)
    return RankLevel
end

function TeamManager.OnSingleBattleFinished(uin, win, finishedArgs)
    local RankLevel = nil
    if finishedArgs.levelMode == 'Career' then          -- 生涯要赢了才上榜
        if win then
            RankLevel = RankingListService:SetRankingListByUID(tostring(uin), 
                RankingData.RankingType.CareerSingleLevel, 
                finishedArgs.levelName, 
                finishedArgs.levelDifficulty, 
                finishedArgs.time,
                uin)
        end
    else
        RankLevel = RankingListService:SetRankingListByUID(tostring(uin), 
            RankingData.RankingType.EndlessSingleLevel, 
            finishedArgs.levelName, 
            1, 
            finishedArgs.points,
            uin)
    end
    TeamManager.UpdatePlayerSkinID(uin)
    print('TeamManager.OnSingleBattleFinished', uin, RankLevel)
    return RankLevel
end

return TeamManager
