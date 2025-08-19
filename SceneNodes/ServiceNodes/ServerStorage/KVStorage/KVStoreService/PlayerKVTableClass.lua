local CloudService = game.CloudService
local PlayerKVTableClass = {}
PlayerKVTableClass.__index = PlayerKVTableClass
local RunService = game:GetService("RunService")

function PlayerKVTableClass.New(playerId, tableType)
    local obj = {
        _playerId = playerId,                                   -- 玩家ID
        _tableType = tableType,                                 -- KV表的类型
        _kvTable = nil,                                         -- KV表的内容
        _kvTableDirty = false,                                  -- KV表是否被修改
        _saveAsync = false,                                     -- 是否异步保存中
        _loadFinish = false,                                    -- 是否加载完成
        _hasError = false,                                      -- 是否加载错误
        _loadFinishEvent = SandboxNode.New("CustomNotify"),     -- 加载完成事件
    }

    local proxyPlayerId = KVStoreService:GetSimulateLoginPlayerId(playerId)
    obj._key = string.format("%s_%s", tableType, proxyPlayerId)

    setmetatable(obj, PlayerKVTableClass)
    return obj
end

function PlayerKVTableClass:LoadAsync()
    if self._loadFinish then
        return
    end

    CloudService:GetTableOrEmptyAsync(self._key, function(success, val)
        if success then 
            self._kvTable = val
        end
        self._hasError = not success
        self._loadFinish = true
        self._loadFinishEvent:Fire(self._hasError)
    end)
end

function PlayerKVTableClass:Save()
    if not self:IsLoadFinished() then
        return false
    end
    if not self._kvTableDirty then
        return true
    end

    local succ = CloudService:SetTable(self._key, self._kvTable)
    if succ then
        self._kvTableDirty = false
    end
    return succ
end
 
function PlayerKVTableClass:SaveAsync()
    if not self:IsLoadFinished() then
        return false
    end
    if not self._kvTableDirty then
        return true
    end
    if self._saveAsync then
        return false
    end

    self._saveAsync = true
    CloudService:SetTableAsync(self._key, self._kvTable, function(code)
        if code then
            self._kvTableDirty = false
        end
        self._saveAsync = false
    end)
    return false
end

function PlayerKVTableClass:GetLoadFinishEvent()
    return self._loadFinishEvent
end

function PlayerKVTableClass:IsLoadFinished()
    return self._loadFinish and not self._hasError
end

function PlayerKVTableClass:Set(key, value)
    assert(self:IsLoadFinished(), "PlayerKVTableClass:Set: KVTable is not loaded")
    self._kvTable[key] = value
    self._kvTableDirty = true
    KVStoreService:_MakeKVTableDataDirty(self._playerId)
    return true
end

local function DeepCopyTable(original)
    local lookup_table = {}
    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        elseif lookup_table[obj] then
            return lookup_table[obj]
        end
        local new_table = {}
        lookup_table[obj] = new_table
        for key, value in pairs(obj) do
            new_table[_copy(key)] = _copy(value)
        end
        return new_table
    end
    return _copy(original)
end

function PlayerKVTableClass:Get(key, defVal)
    assert(self:IsLoadFinished(), "PlayerKVTableClass:Get: KVTable is not loaded")
    local val = self._kvTable[key] or defVal
    if RunService:IsClient() and RunService:IsServer() then
        return DeepCopyTable(val)
    end
    return val
end

function PlayerKVTableClass:Clear()
    assert(self:IsLoadFinished(), "PlayerKVTableClass:Remove: KVTable is not loaded")
    self._kvTable = {}
    self._kvTableDirty = true
    KVStoreService:_MakeKVTableDataDirty(self._playerId)
end

-- 复制返回一个KVTable的副本
function PlayerKVTableClass:GetKVTableCopy()
    return DeepCopyTable(self._kvTable)
end

return PlayerKVTableClass