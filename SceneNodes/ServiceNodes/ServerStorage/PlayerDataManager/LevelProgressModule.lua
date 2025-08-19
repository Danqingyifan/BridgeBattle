local ZSDataService = require(script.Parent.Parent.KVStorage.ZSDataService)

local LevelProgressModule = {}

-- 初始化模块
function LevelProgressModule.Init()
    -- 可以在这里添加初始化逻辑
    
    _G.GameNet:RegClientMsgCallback(
        'GET_LEVEL_PROGRESSES',
        function(playerId)
            local levelProgresses = LevelProgressModule.GetProgresses(playerId)
            if levelProgresses == nil or next(levelProgresses) == nil then
                LevelProgressModule.UnlockProgress(playerId, 1, 'Career', 1)
                LevelProgressModule.UnlockProgress(playerId, 1, 'Infinite', 1)
                levelProgresses = LevelProgressModule.GetProgresses(playerId)
            end
            print('LevelProgressModule:GetProgresses', levelProgresses)
            _G.GameNet:SendMsgToClient(playerId, 'GET_LEVEL_PROGRESSES_RESPONSE', levelProgresses)
        end
    )
    _G.GameNet:RegClientMsgCallback(
        'SET_LEVEL_PROGRESS',
        function(playerId, levelId, levelMode, levelDifficulty, levelRecord)
            local levelProgress = LevelProgressModule.SetProgress(playerId, levelId, levelMode, levelDifficulty, levelRecord)
            _G.GameNet:SendMsgToClient(playerId, 'SET_LEVEL_PROGRESS_RESPONSE', levelProgress)
        end
    )
    --_G.GameNet:RegClientMsgCallback(
        --'UNLOCK_LEVEL_PROGRESS',
        --function(playerId, levelId, levelMode, levelDifficulty)
            --local newLevelProgress = LevelProgressModule.UnlockProgress(playerId, levelId, levelMode, levelDifficulty)
            --_G.GameNet:SendMsgToClient(playerId, 'UNLOCK_LEVEL_PROGRESS_RESPONSE', newLevelProgress)
        --end
    --)

end


-- 获取所有关卡进度
function LevelProgressModule.GetProgresses(playerId)
    return ZSDataService:GetZombieStormLevelProgresses(playerId)
end

-- 获取特定关卡进度
function LevelProgressModule.GetProgress(playerId, levelId, levelMode, levelDifficulty) 
    return ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)
end



-- 更新关卡进度
function LevelProgressModule.SetProgress(playerId, levelId, levelMode, levelDifficulty, levelRecord)
    local currentProgress = ZSDataService:GetZombieStormLevelProgress(playerId, levelId, levelMode, levelDifficulty)
    
    if currentProgress.levelRecord == 0 or currentProgress.levelRecord == nil then
        -- 如果记录为0,说明是首次通关，更新记录
        currentProgress.levelRecord = levelRecord
    elseif levelRecord < currentProgress.levelRecord then
        -- 如果记录更短，更新记录
        currentProgress.levelRecord = levelRecord
    end

    -- 保存更新后的进度
    local updatedProgress =
        ZSDataService:SetZombieStormLevelProgress(
        playerId,
        levelId,
        currentProgress.levelMode,
        currentProgress.levelDifficulty,
        currentProgress.levelRecord
    )
    return updatedProgress
end

-- 解锁关卡进度
function LevelProgressModule.UnlockProgress(playerId, levelId, levelMode, levelDifficulty)
    local isLevelUnlocked = ZSDataService:CheckZombieStormLevelUnlocked(playerId, levelId, levelMode, levelDifficulty)
    if not isLevelUnlocked then
        return ZSDataService:UnlockZombieStormLevel(playerId, levelId, levelMode, levelDifficulty)
    end
    return LevelProgressModule.GetProgress(playerId, levelId, levelMode, levelDifficulty)
end

return LevelProgressModule
