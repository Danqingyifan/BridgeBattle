local EffectPool = {}

function EffectPool.New()
    local ret = {}
    for k, v in pairs(EffectPool) do
        if k ~= 'New' then
            ret[k] = v
        end
    end
    return ret
end
function EffectPool:Init()
    self.nodesReady = {}
    self.nodesActive = {}

    self.initialSize = 64
    self.expandSize = 16
    self.maxSize = 192
    self.currentSize = 64

    for i = 1, self.initialSize do
        local effectNode = SandboxNode.new('EffectObject', self.poolRoot)
        effectNode.Name = 'EffectNode' .. i
        effectNode.Visible = false
        effectNode:Pause()
        self.nodesReady[#self.nodesReady + 1] = effectNode
    end
end

function EffectPool:ActivateEffectNode(effectAssetID, parent, localPosition, localEuler, localScale)
    if effectAssetID == '' or effectAssetID == nil then
        return
    end

    local ID, effectNode = next(self.nodesReady)
    if effectNode == nil then
        self:ExpandPool()
        ID, effectNode = next(self.nodesReady)
    end

    effectNode.Parent = parent
    effectNode.LocalPosition = localPosition
    effectNode.LocalEuler = localEuler
    effectNode.LocalScale = localScale
    effectNode.Visible = true

    effectNode.AssetID = ''
    effectNode.AssetID = effectAssetID

    table.remove(self.nodesReady, 1)
    table.insert(self.nodesReady, effectNode)
    return effectNode
end

function EffectPool:ExpandPool()
    -- 检查是否超过最大大小
    if #self.nodesReady + self.expandSize > self.maxSize then
        print('Warning: Pool ' .. self.name .. ' reached max size limit!')
        return false
    end

    for i = 1, self.expandSize do
        local node = SandboxNode.new('EffectObject', self.poolRoot)
        node.Name = 'EffectNode' .. (#self.nodesReady + i)

        -- 根据类型设置初始属性
        node.Visible = false
        node:Pause()

        self.nodesReady[node.ID] = node
    end

    return true
end

function EffectPool:RecycleEffectNode(effectNode)
    effectNode.AssetID = ''
    effectNode.Visible = false
    effectNode.Parent = self.poolRoot
    effectNode:Pause()

    self.nodesReady[effectNode.ID] = effectNode
    self.nodesActive[effectNode.ID] = nil
end

return EffectPool
