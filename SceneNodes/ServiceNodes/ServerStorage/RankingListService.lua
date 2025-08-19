local CloudService = game:GetService("CloudService")
local MainStorage = game:GetService('MainStorage')
local Players = game:GetService("Players")
local RankingData = require(MainStorage.Common.RankingData)

local RankingListService = {}

local GetOrderDataCloudStr = function (type, Level, difficulty)
    local GetLevel = Level or 0;
    return type .. "_" .. tostring(GetLevel) .. "_" .. tostring(difficulty or 0)
end

function RankingListService:Init()
    local createCallback = function(msgHandler)
        return function (playerId, msgType, ...)
            local func = RankingListService[msgHandler][msgType]
            if func then
                local ok, result = pcall(func, self, playerId, ...)
                if not ok then
                    print("RankingListService:RankingListClientMsg error", msgType, result)
                    return
                end
            end
        end
    end

    GameNet:RegClientMsgCallback("RankingListClientMsg", createCallback('ServerMsgHandler'))
    GameNet:RegClientMsgCallback("RankingHubServerMsg", createCallback('HubMsgHandler'))

    -- 队伍排行榜的 leader 信息缓存
    self:UpdateCache()
    self.DelayUpdateRankingListUID = {}
    coroutine.work(function ()
        while true do
            Wait(30 * 60)
            --Wait(5 * 60) -- 测试使用，5分钟刷新一次
            self:UpdateCache()
        end
    end)
end

-- 测试使用
function RankingListService:UpdateCache()
    print("UpdateRankingListCache", tostring(os.date("%Y/%m/%d %H:%M", os.time())))
    self.CacheRankingList = {}
    self.teamLeaderInfoCache = {}
    self.CachePlayerInfoList = {}
    self.CacheLevelSelfRankingList = {}
end

-- 测试榜单数据
local TestRankList = 
{
    {key = '2002808418', nick = 'xxx2', value = 101},
    {key = '1997741132', nick = 'xxx1', value = 100},
    {key = '2004094909', nick = 'xxx3', value = 99},
    {key = '2004183276', nick = 'xxx4', value = 98},
    {key = '1884167604', nick = 'xxx5', value = 97},
    {key = '1884167603', nick = 'xxx5', value = 96},
    {key = '1884167602', nick = 'xxx5', value = 95},
    {key = '1884167601', nick = 'xxx5', value = 94},
    {key = '1884167600', nick = 'xxx5', value = 93},
    {key = '1884167599', nick = 'xxx6', value = 92},
}

-- 测试组队榜单数据
local TeamTestRankList = 
{
    {key = '2002808418_1884167601_2004094909', nick = 'xxx2', value = 101, leaderUin = 2004094909},
    {key = '1997741132_2002808418_1884167599', nick = 'xxx1', value = 100, leaderUin = 1997741132},
    {key = '1997741132_2004094909_1884167598', nick = 'xxx3', value = 99, leaderUin = 1997741132},
    {key = '2004183276_1884167604', nick = 'xxx4', value = 98, leaderUin = 1884167604},
    {key = '1884167604_1884167603', nick = 'xxx5', value = 97, leaderUin = 1884167603},
    {key = '1884167603_1884167602_1884167601_1884167600', nick = 'xxx5', value = 96, leaderUin = 1884167603},
    {key = '1884167602_1884167601', nick = 'xxx5', value = 95, leaderUin = 1884167602},
    {key = '1884167601_1884167600', nick = 'xxx5', value = 94, leaderUin = 1884167600},
    {key = '1884167600_1884167599', nick = 'xxx5', value = 93, leaderUin = 1884167600},
    {key = '1884167599_1884167598', nick = 'xxx6', value = 92, leaderUin = 1884167598},
}

-- 通知当前客户端
function RankingListService:ToClient(playerId, FunName, ...)
    GameNet:SendMsgToClient(playerId, "RankingListServerMsg", FunName, ...)
end

function RankingListService:ToClientV2(playerId, MsgName, funcName, ...)
    GameNet:SendMsgToClient(playerId, MsgName, funcName, ...)
end

-- 通知所有客户端
function RankingListService:Broadcast(FunName, ...)
    GameNet:BroadcastMsg("RankingListServerMsg",  FunName .. "_Multi", ...)
end

-- 记录排行榜数据
function RankingListService:SetRankingListByUID(key, type, Level, difficulty, value, uid, name)
    print("SetRankingListByUID", key, type, Level, difficulty, value, uid, name)
    local SortRule = RankingData.SortRule[type]
    local JudgeValueIsUp = function (CurrentValue, OldValue)
        if SortRule then
            return OldValue < CurrentValue
        end
        return OldValue > CurrentValue
    end

    local GetDataCloudStr = GetOrderDataCloudStr(type, Level, difficulty)
    local kvTable = KVStoreService:GetPlayerKVTable(uid, PlayerKVTableEnum.ZombieStormData)
    local RankingList = kvTable:Get('RankingList', {})
    local OldPlayerRankingData = RankingList[GetDataCloudStr]
    if OldPlayerRankingData and (not JudgeValueIsUp(value, OldPlayerRankingData)) then -- 如果老数据比新数据高，则不升级
        return
    end
    RankingList[GetDataCloudStr] = value
    kvTable:Set('RankingList', RankingList)
    
    local DataCloudInfo = self.CacheRankingList[GetDataCloudStr]
    local Current = 1
    local LastKeyRanking = nil
    local RankingTable = nil
    if DataCloudInfo and #DataCloudInfo > 0 then
        local Count = #DataCloudInfo
        if Count >= 10 then
            if not JudgeValueIsUp(value, DataCloudInfo[#DataCloudInfo].value) then
                return nil
            end
        end

        for index, Value_1 in ipairs(DataCloudInfo) do
            if Value_1.key == key then
                Count = index
                LastKeyRanking = Value_1
                break
            end
            if JudgeValueIsUp(value, Value_1.value) then
                Count = index
            end
        end
        
        Current = Count 
        if LastKeyRanking then -- 如果老排名分数比新分数高，则不添加
            if not JudgeValueIsUp(value,LastKeyRanking.value) then
                return Current
            end
        end
    else
        RankingTable = CloudService:GetOrderDataCloud(GetDataCloudStr)
        if OldPlayerRankingData == nil then -- 证明没有记录老数据且排行榜没有拉取过，在Ranking表里面找一次
            print("Call OrderData Api GetValueAsync", key, GetDataCloudStr, value)
            RankingTable:GetValueAsync(tostring(key),GetDataCloudStr, function (code, AValue)
                print("GetValue", key, GetDataCloudStr, value, code, AValue)
                if code and not JudgeValueIsUp(value, AValue) then
                    return
                end
                print("Call OrderData Api SetValueAsync", key, GetDataCloudStr, value)
                RankingTable:SetValueAsync(tostring(key), GetDataCloudStr, value, function (code, Avalue)
                    print("SetValueSuccess",key, GetDataCloudStr, value, code, Avalue)
                end)
            end)
            return
        end
    end
    
    if RankingTable == nil then
        RankingTable = CloudService:GetOrderDataCloud(GetDataCloudStr)
    end
    --RankingTable:RemoveKey(tostring(key))
    print("Call OrderData Api SetValueAsync", key, GetDataCloudStr, value)
    RankingTable:SetValueAsync(tostring(key), GetDataCloudStr, value, function (code, Avalue)
        print("SetValueSuccess",key, GetDataCloudStr, value, code, Avalue)
    end)
    
    return Current
end

-- 记录组队排行榜数据
function RankingListService:SetTeamModeRankingList(teamRankingKey, teamInfo, level, score)
    print("SetTeamModeRankingList", teamRankingKey, level, score)
    local type = RankingData.RankingType.TeamEndlessSingleLevel
    local SortRule = RankingData.SortRule[type]
    local function JudgeValueIsUp(CurrentValue, OldValue)
        if SortRule then
            return OldValue < CurrentValue
        end
        return OldValue > CurrentValue
    end

    local GetDataCloudStr = GetOrderDataCloudStr(type, level, 1)
    local function UpdateRankingList(uin, value)
        local kvTable = KVStoreService:GetPlayerKVTable(uin, PlayerKVTableEnum.ZombieStormData)
        local RankingList = kvTable:Get('RankingList', {})
        local OldPlayerRankingData = RankingList[GetDataCloudStr]
        if OldPlayerRankingData and (not JudgeValueIsUp(value, OldPlayerRankingData)) then -- 如果老数据比新数据高，则不升级
            return
        end
        RankingList[GetDataCloudStr] = value
        kvTable:Set('RankingList', RankingList)
    end 

    for _, player in ipairs(teamInfo.players) do
        UpdateRankingList(player.uin, score)
    end

    -- 不满足上榜条件
    local dataCloudInfo = self.CacheRankingList[GetDataCloudStr] or {}
    if #dataCloudInfo >= 10 then
        if not JudgeValueIsUp(score, dataCloudInfo[#dataCloudInfo].value) then
            return nil
        end
    end

    local rankNo = 11
    local oldScore = nil
    for index, rankingInfo in ipairs(dataCloudInfo) do
        if JudgeValueIsUp(score, rankingInfo.value) then
            rankNo = math.min(rankNo, index)
        end
        if rankingInfo.key == teamRankingKey then
            oldScore = rankingInfo.value
            break
        end
    end

    if oldScore == nil or JudgeValueIsUp(score, oldScore) then
        local RankingTable = CloudService:GetOrderDataCloud(GetDataCloudStr)
        if oldScore ~= nil then
            RankingTable:RemoveKey(teamRankingKey)
        end
        RankingTable:SetValueAsync(teamRankingKey, GetDataCloudStr, score, function(code, Avalue)
            print("SetValueSuccess",teamRankingKey, GetDataCloudStr, score, code, Avalue)
        end)
    end

    return rankNo
end

-- 计算组队排行榜的 Key
function RankingListService:CalcTeamModeRankingKey(teamInfo)
    local players = {}
    for _, player in ipairs(teamInfo.players) do
        table.insert(players, player.uin)
    end
    table.sort(players, function (a, b)
        return a < b
    end)
    return table.concat(players, '_')
end

-- 获取组队的排行榜的 Key
function RankingListService:SplitTeamModeRankingKey(rankingKey)
    local players = {}
    for player in string.gmatch(rankingKey, '([^_]+)') do
        table.insert(players, tonumber(player))
    end
    return players
end

-- 设置组队排行榜的 leader
function RankingListService:SetTeamModeRankingLeader(rankingKey, leader)
    CloudService:SetValue(rankingKey, "TeamLeader", tostring(leader))
    self.teamLeaderInfoCache[rankingKey] = leader
end

-- 获取组队排行榜的 leader
function RankingListService:GetTeamModeRankingLeader(rankingKey)
   local leaderId = self.teamLeaderInfoCache[rankingKey]
   if not leaderId then
        local code, leader= CloudService:GetValue(rankingKey, "TeamLeader")
        local LeaderNumber = tonumber(leader)
        if LeaderNumber then
            self.teamLeaderInfoCache[rankingKey] = leader
            leaderId = LeaderNumber
        end
   end
   return leaderId
end

-- 当组队战斗结束时，更新排行榜数据
function RankingListService:OnTeamBattleFinished(teamInfo, level, score)
    print("OnTeamBattleFinished", teamInfo, level, score)
    local teamRankingKey = self:CalcTeamModeRankingKey(teamInfo)
    self:SetTeamModeRankingLeader(teamRankingKey, teamInfo.leader)
    return self:SetTeamModeRankingList(teamRankingKey, teamInfo, level, score)
end


-- 获取排行榜列表
function RankingListService:GetRankingListInternal(playerId, msgName, type, Level, difficulty)
    local GetDataCloudStr = GetOrderDataCloudStr(type, Level, difficulty)

    local List = {}
    if self.CacheRankingList[GetDataCloudStr] then
        List = self.CacheRankingList[GetDataCloudStr]
        print("GetCacheRankingList")
        self:ToClientV2(playerId, msgName, 'OnGetRankingList', type, Level, difficulty, List)
        return
    end 

    if self.DelayUpdateRankingListUID[GetDataCloudStr] then
        self.DelayUpdateRankingListUID[GetDataCloudStr][playerId] = msgName -- 拉取数据中，记录需要更新数据的玩家
        print("recode delay update", GetDataCloudStr, playerId)
        return
    else
        self.DelayUpdateRankingListUID[GetDataCloudStr] = {}
        self.DelayUpdateRankingListUID[GetDataCloudStr][playerId] = msgName
    end

    coroutine.work(function()
        local bIsTeam = (type ==  RankingData.RankingType.TeamEndlessRanking or type ==  RankingData.RankingType.TeamEndlessSingleLevel) -- 是组队则为多个玩家集合
        local RankingTable = CloudService:GetOrderDataCloud(GetDataCloudStr)
        if RankingTable then
            local GetMaxListCount = RankingData.RankingTypeMaxCount[type] or RankingData.DefaultRankingMaxCount
            local SortRule = RankingData.SortRule[type]
            local ApplyRankingList = function (Table, level)
                -- if type == RankingData.RankingType.TeamEndlessSingleLevel then
                --     Table = TeamTestRankList
                -- end
                
                if not Table or not next(Table) then
                    return
                end

                for key, v in pairs(Table) do
                    local leaderUin = nil
                    local players = nil
                    if bIsTeam then
                        leaderUin = self:GetTeamModeRankingLeader(v.key)
                        players = self:SplitTeamModeRankingKey(v.key)
                        if leaderUin == nil  then                       -- 没有找到队长，则用第一个人当队长
                            leaderUin = players[1]
                        end
                    else
                        leaderUin = tonumber(v.key) 
                    end
                    local Info = {key = v.key, value = v["value"] or 0, name = v.nick, leaderUin = leaderUin}
                    if self.CacheLevelSelfRankingList[GetDataCloudStr] == nil then
                        self.CacheLevelSelfRankingList[GetDataCloudStr] = {}
                    end

                    if bIsTeam then
                        local cacheInfo = self.CacheLevelSelfRankingList[GetDataCloudStr]
                        for _, playerId in ipairs(players) do
                            local strPlayerId = tostring(playerId)
                            if self.CacheLevelSelfRankingList[GetDataCloudStr][strPlayerId] == nil then
                                self.CacheLevelSelfRankingList[GetDataCloudStr][strPlayerId] = v.value
                            end
                        end
                    else
                        if self.CacheLevelSelfRankingList[GetDataCloudStr][v.key] == nil then
                            self.CacheLevelSelfRankingList[GetDataCloudStr][v.key] = v.value
                        end
                    end
                    table.insert(List, Info)
                end
            end

            if GetMaxListCount > 100 then
                local LoopIndex = math.floor(GetMaxListCount / 100) -- 因为排行榜拉取最大不能超过100
                local RemainingIndex = GetMaxListCount % 100

                for i = 1, LoopIndex, 1 do
                    local CurrentLevel = ((i - 1) * 100) + 1
                    print("Call OrderData Api GetOrderDataValueArea", CurrentLevel, i * 100)
                    ApplyRankingList(RankingTable:GetOrderDataValueArea(SortRule, CurrentLevel , i * 100), CurrentLevel - 1)
                end
                if RemainingIndex > 0 then
                    print("Call OrderData Api GetOrderDataValueArea", LoopIndex * 100 + 1, GetMaxListCount)
                    ApplyRankingList(RankingTable:GetOrderDataValueArea(SortRule, LoopIndex * 100 + 1, GetMaxListCount), LoopIndex * 100)
                end
            else
                local Table = nil
                if SortRule then
                    print("Call OrderData Api GetTopSync", GetMaxListCount)
                    Table = RankingTable:GetTopSync(GetMaxListCount)
                else
                    print("Call OrderData Api GetBottomSync", GetMaxListCount)
                    Table = RankingTable:GetBottomSync(GetMaxListCount)
                end
                print("GetTopSync", Table)
                ApplyRankingList(Table, 0)
            end
        end

        self.CacheRankingList[GetDataCloudStr] = List
        for playerId, msgName in pairs(self.DelayUpdateRankingListUID[GetDataCloudStr]) do
            self:ToClientV2(playerId, msgName, 'OnGetRankingList', type, Level, difficulty, List)
        end
        self.DelayUpdateRankingListUID[GetDataCloudStr] = nil
    end)
end

-- 查询组队排行榜的 leader
function RankingListService:QueryTeamLeaderInternal(playerId, msgName, rankingKeyList)
    local result = {}
    for _, rankingKey in ipairs(rankingKeyList) do
        result[rankingKey] = self:GetTeamModeRankingLeader(rankingKey)
    end
    self:ToClientV2(playerId, msgName, 'OnQueryTeamLeader', result)
end

-- 获取玩家皮肤数据
function RankingListService:GetRankingPlayerSkinsInternal(playerId, msgName, PlayerInfos)
    local PlayerIndexMap = {}
    local bUpdate =false
    for index, uin in ipairs(PlayerInfos) do
        if self.CachePlayerInfoList[uin] == nil then
            PlayerIndexMap[uin] = index -- 为了防止重复的情况
            bUpdate = true
        end
    end
    
    if bUpdate then
        for key, value in pairs(PlayerIndexMap) do
            local result = KVStoreService:FetchPlayerData(key, PlayerKVTableEnum.HallData)
			local avatarInfo = result.AvatarInfo or {}
			avatarInfo.uin = key
            self.CachePlayerInfoList[key] = avatarInfo
        end
    end

    local SavePlayerMap = {}
    for index, uin in ipairs(PlayerInfos) do
        local cacheInfo = self.CachePlayerInfoList[uin]
        table.insert(SavePlayerMap, cacheInfo)
    end
    self:ToClientV2(playerId, msgName, "OnRankingPlayerSkins", SavePlayerMap)
end

function RankingListService:GetCurrentUIDRankingLevelInternal(playerId, msgName, type, Level, difficulty)
    local GetDataCloudStr = GetOrderDataCloudStr(type, Level, difficulty)
    
    local kvTable = KVStoreService:GetPlayerKVTable(playerId, PlayerKVTableEnum.ZombieStormData)
    local RankingList = kvTable:Get('RankingList', {})
    if RankingList[GetDataCloudStr] then
        local Info = {key = tostring(playerId), value = RankingList[GetDataCloudStr]}
        self:ToClientV2(playerId, msgName, 'OnCurrentRankingLevel', Info)
        return
    end 
    if self.CacheLevelSelfRankingList[GetDataCloudStr] then
        local score = self.CacheLevelSelfRankingList[GetDataCloudStr][tostring(playerId)]
        if score then
            -- 排行榜里面有数据, 但是 kv 里面没有，则更新 kv 数据
            RankingList[GetDataCloudStr] = score
            kvTable:Set('RankingList', RankingList)
            self:ToClientV2(playerId, msgName, 'OnCurrentRankingLevel', { key = tostring(playerId), value = score })
            return
        end
    end
    self:ToClientV2(playerId, msgName, 'OnCurrentRankingLevel', nil)
end

RankingListService.ServerMsgHandler = {}
function RankingListService.ServerMsgHandler:GetRankingList(playerId, type, Level, difficulty)
    self:GetRankingListInternal(playerId, 'RankingListServerMsg', type, Level, difficulty)
end
function RankingListService.ServerMsgHandler:GetRankingPlayerSkins(playerId, PlayerInfos)
    self:GetRankingPlayerSkinsInternal(playerId, 'RankingListServerMsg', PlayerInfos)
end
function RankingListService.ServerMsgHandler:GetCurrentUIDRankingLevel(playerId, type, Level, difficulty)
    self:GetCurrentUIDRankingLevelInternal(playerId, 'RankingListServerMsg', type, Level, difficulty)
end

RankingListService.HubMsgHandler = {}
function RankingListService.HubMsgHandler:GetRankingList(playerId, type, Level, difficulty)
    self:GetRankingListInternal(playerId, 'RankingHubServerMsg', type, Level, difficulty)
end
function RankingListService.HubMsgHandler:GetRankingPlayerSkins(playerId, PlayerInfos)
    self:GetRankingPlayerSkinsInternal(playerId, 'RankingHubServerMsg', PlayerInfos)
end

return RankingListService