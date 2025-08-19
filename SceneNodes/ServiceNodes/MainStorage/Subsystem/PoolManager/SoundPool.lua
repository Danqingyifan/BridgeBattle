local SoundPool = {}

function SoundPool.New()
    local ret = {}
    for k, v in pairs(SoundPool) do
        if k ~= 'New' then
            ret[k] = v
        end
    end
    return ret
end
function SoundPool:Init()
    self.nodesReady = {}
    self.nodesActive = {}

    self.initialSize = 64
    self.expandSize = 16
    self.maxSize = 192

    for i = 1, self.initialSize do
        local effectNode = SandboxNode.new('Sound', self.poolRoot)
        effectNode.Name = 'SoundNode' .. i
        self.nodesReady[effectNode.ID] = effectNode
    end
end

function SoundPool:ActivateEffectNode(soundAssetID, parent, localPosition, volume)
    if soundAssetID == '' or soundAssetID == nil then
        return
    end

    local ID,effectNode = next(self.nodesReady)
    if effectNode == nil then
        self:ExpandPool()
        ID,effectNode = next(self.nodesReady)
    end


    effectNode.SoundPath = soundAssetID
    effectNode.Parent = parent
    effectNode.FixPos = localPosition
    effectNode.Volume = volume or 1

    effectNode:PlaySound()

    table.remove(self.nodesReady, 1)
    table.insert(self.nodesReady, effectNode)

    return effectNode
end

function SoundPool:ExpandPool()
    -- 检查是否超过最大大小
    if #self.nodesReady + self.expandSize > self.maxSize then
        print('Warning: Pool ' .. self.name .. ' reached max size limit!')
        return false
    end

    for i = 1, self.expandSize do
        local node = SandboxNode.new('Sound', self.poolRoot)
        node.Name = 'SoundNode' .. (#self.nodesReady  + i)


        table.insert(self.nodesReady, node)
    end

    self.currentSize = self.currentSize + self.expandSize

    return true
end
function SoundPool:RecycleSoundNode(soundNode)
    soundNode.SoundPath = ''
    soundNode.Parent = self.poolRoot
    soundNode:StopSound()

    self.nodesReady[soundNode.ID] = soundNode
    self.nodesActive[soundNode.ID] = nil
end

return SoundPool
