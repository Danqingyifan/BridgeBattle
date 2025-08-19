local PlayerKVDatabaseClass = {}
PlayerKVDatabaseClass.__index = PlayerKVDatabaseClass
local PlayerKVTableClass = require(script.Parent.PlayerKVTableClass)

function PlayerKVDatabaseClass.New(playerId)
    local obj = {
        _playerId = playerId,
        _loadFinish = false,
        _hasError = false,
        _database = {},
        _callbackCount = 0,                                      
    }
    setmetatable(obj, PlayerKVDatabaseClass)
    return obj
end

function PlayerKVDatabaseClass:LoadData()
    for _, key in pairs(PlayerKVTableEnum) do 
        local kvTable = PlayerKVTableClass.New(self._playerId, key)
        kvTable:GetLoadFinishEvent().Notify:Connect(function(hasError)
            self:OnTableLoadFinish(hasError)
        end)
        self._database[key] = kvTable
    end
    for key, kvTable in pairs(self._database) do
        kvTable:LoadAsync() 
    end
end

local PlayerKVTableEnumCount = 0
for _, _ in pairs(PlayerKVTableEnum) do
    PlayerKVTableEnumCount = PlayerKVTableEnumCount + 1
end

function PlayerKVDatabaseClass:OnTableLoadFinish(hasError)
    if hasError then
        self._hasError = true 
    end

    self._callbackCount = self._callbackCount + 1
    if self._callbackCount < PlayerKVTableEnumCount then
        return
    end

    for _, kvTable in pairs(self._database) do
        kvTable:GetLoadFinishEvent().Notify:Clear() 
    end

    self._loadFinished = true
    if self._hasError then
        KVStoreService:_MakeKVTableLoadFailed(self._playerId)
    else
        KVStoreService:_MakeKVTableLoadFinished(self._playerId)
    end
end

function PlayerKVDatabaseClass:Save()
    if not self._loadFinished then      -- 没有加载成功就存档, 直接不保存
        return true
    end

    for _, dbTable in pairs(self._database) do
        if not dbTable:Save(self._playerId) then
            return false
        end
    end
    return true
end

function PlayerKVDatabaseClass:SaveAsync()
    if not self._loadFinished then      -- 没有加载成功就存档, 直接不保存
        return true
    end

    for _, dbTable in pairs(self._database) do
        if not dbTable:SaveAsync(self._playerId) then
            return false
        end
    end
    return true
end

function PlayerKVDatabaseClass:IsLoadFinished()
    return self._loadFinished and not self._hasError
end

function PlayerKVDatabaseClass:GetKVTable(tableType)
    assert(self:IsLoadFinished(), "PlayerKVDatabaseClass:GetKVTable: not load finished")
    local kvTable = self._database[tableType]
    assert(kvTable, "PlayerKVDatabaseClass:GetKVTable: not found tableType")
    return kvTable
end

return PlayerKVDatabaseClass