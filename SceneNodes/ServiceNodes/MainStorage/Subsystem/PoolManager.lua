local PoolManager = {
    pools = {}
}

function PoolManager.Init()
end

function PoolManager.CreatePool(name, parent)
    -- 一种Pool同时间只能存在一个
    if PoolManager.pools[name] then
        print('Pool ' .. name .. ' already exists!')
        return PoolManager.pools[name]
    end

    local pool = require(script:FindFirstChild(name)).New()
    -- 创建Pool根节点
    pool.poolRoot = SandboxNode.new('Transform', parent)
    pool.poolRoot.Name = name .. 'Root'
    pool:Init()

    PoolManager.pools[name] = pool

    return pool
end

function PoolManager.DestroyPool(name)
    local pool = PoolManager.pools[name]
    if not pool then
        print('Pool ' .. name .. ' does not exist!')
        return
    end
    local a = 0
    -- 销毁所有节点
    for _, node in pairs(pool.nodesReady) do
        if node and node.Destroy then
            node:Destroy()
            a = a + 1
        end
    end
    -- for node, _ in pairs(pool.activeNodes) do
    --     if node and node.Destroy then
    --         node:Destroy()
    --     end
    -- end

    -- 销毁Pool根节点
    if pool.poolRoot and pool.poolRoot.Destroy then
        pool.poolRoot:Destroy()
    end

    PoolManager.pools[name] = nil
    print('Destroyed pool: ' .. name)
end

return PoolManager
