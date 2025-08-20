local KVStoreService = {}
local PlayerKVDatabaseClass = require(script.PlayerKVDatabaseClass)
local CloudService = game:GetService("CloudService")

function KVStoreService:StartService()
    self._database = {}
    self._onlinePlayerKVMap = {}
    self._offlinePlayerKVMap = {}
    self._highPrioritySaveJobQueue = {}
    self._lowPrioritySaveJobQueue = {}
    self._loadFailedPlayerMap = {}
    self._loadFinishedPlayerMap = {}
    self._lastTimeoutTime = nil
end

function KVStoreService:StopService()
    while #self._highPrioritySaveJobQueue > 0 or #self._lowPrioritySaveJobQueue > 0 do
        self:DoSaveDB() 
    end
end

function KVStoreService:OnPlayerAdded(player)
    local playerId = player.UserId

    if self._onlinePlayerKVMap[playerId] then
        self._onlinePlayerKVMap[playerId] = self._onlinePlayerKVMap[playerId]
        ServerGlobalEvent.OnPlayerKVLoadFinished:Fire(playerId)
        self._onlinePlayerKVMap[playerId] = nil
        return
    end

    self._onlinePlayerKVMap[playerId] = PlayerKVDatabaseClass.New(playerId)
    self._onlinePlayerKVMap[playerId]:LoadData()
end

function KVStoreService:OnPlayerRemoving(player)
    local playerId = player.UserId
    local database = self._onlinePlayerKVMap[playerId]
    if database:Save() then
        self._onlinePlayerKVMap[playerId] = nil
    else
        self._offlinePlayerKVMap[playerId] = self._onlinePlayerKVMap[playerId]
        self._onlinePlayerKVMap[playerId] = nil
        table.insert(self._highPrioritySaveJobQueue, playerId)
    end
end

function KVStoreService:IsPlayerLoaded(player)
    local playerId = player.UserId
    local database = self._database[playerId]
    if database then
        return database:IsLoadFinished()
    end
    return false
end

function KVStoreService:Update()
    local curTime = os.time()
    if self._lastTimeoutTime == nil then
        self._lastTimeoutTime = curTime
        return
    end

    if curTime - self._lastTimeoutTime >= 6 then
        self._lastTimeoutTime = curTime
        self:DoSaveDB()
    end

    -- 处理加载数据失败的玩家
    local queue = self._loadFailedPlayerMap
    self._loadFailedPlayerMap = {}
    for playerId, _ in pairs(queue) do
        ServerGlobalEvent.OnPlayerKVLoadFailed:Fire(playerId)
    end

    -- 处理加载数据成功
    local queue1 = self._loadFinishedPlayerMap
    self._loadFinishedPlayerMap = {}
    for playerId, _ in pairs(queue1) do
        ServerGlobalEvent.OnPlayerKVLoadFinished:Fire(playerId)
    end
end

function KVStoreService:GetPlayerKVTable(playerId, tableType)
    local database = self._onlinePlayerKVMap[playerId]
    if not database then
        return nil
    end
    return database:GetKVTable(tableType)
end

function KVStoreService:FetchPlayersData(playerIds, tableType)
    local result = {}
    for _, playerId in ipairs(playerIds) do
        local key = string.format("%s_%s", tableType, playerId)
        local code, val = CloudService:GetTableOrEmpty(key)
        result[playerId] = val
    end
    return result
end

-- 开启替身登录, A账号模拟 B 账号的数据, 并设置模拟登录时间
function KVStoreService:SetSimulateLogin(playerId, proxyPlayerId)
    if not OpenSimulateLogin then
        return
    end
    local val = {
        SimulatePlayerId = proxyPlayerId,
        LastLoginTime = os.time(),
    }
    local key = string.format("%s_%s", SimulateLoginData, playerId)
    CloudService:SetTable(key, val)
end


function KVStoreService:ClearSimulateLogin(playerId)
    if not OpenSimulateLogin then
        return
    end
    local key = string.format("%s_%s", SimulateLoginData, playerId)
    CloudService:RemoveKey(key)
end

-- 获取模拟登录的玩家ID
function KVStoreService:GetSimulateLoginPlayerId(playerId)
    return self._simulatePlayerMap[playerId] or playerId
end

-- 拉取玩家数据
function KVStoreService:FetchPlayerData(playerId, tableType)
    local data = self:GetPlayerKVTable(playerId, tableType)
    if data then
        return data:GetKVTableCopy()
    end

    local key = string.format("%s_%s", tableType, playerId)
    local code, val = CloudService:GetTableOrEmpty(key)
    return val
end

function KVStoreService:DoSaveDB()
    local hasError = false
    local doDbSaveImpl = function(jobQueue, dbMap, isHighPriority)
        local index = 1
        local newQueue = {}
        while index <= #jobQueue do
            local playerId = jobQueue[index]
            local database = dbMap[playerId]
            if database then
                if hasError or not database:SaveAsync(playerId) then
                    table.insert(newQueue, playerId)
                    hasError = true
                elseif isHighPriority then
                    dbMap[playerId] = nil
                end 
            end
            index = index + 1
        end
        return newQueue
    end
    self._highPrioritySaveJobQueue = doDbSaveImpl(self._highPrioritySaveJobQueue, self._onlinePlayerKVMap)
    if hasError then
        return
    end
    self._lowPrioritySaveJobQueue = doDbSaveImpl(self._lowPrioritySaveJobQueue, self._onlinePlayerKVMap)
end

function KVStoreService:_MakeKVTableDataDirty(playerId)
    table.insert(self._lowPrioritySaveJobQueue, playerId)
end

function KVStoreService:_MakeKVTableLoadFailed(playerId)
    self._loadFailedPlayerMap[playerId] = true
end

function KVStoreService:_MakeKVTableLoadFinished(playerId)
    self._loadFinishedPlayerMap[playerId] = true
end

return KVStoreService