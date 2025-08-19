-- 方块管理器
local Vec3 = require(game.MainStorage.Common.Math.Vec3)
local BlockData = require(script.BlockData)

local BlockManager = {}

-- 初始化方块管理器
function BlockManager.new()
    local manager = {}

    -- 存储所有方块的映射表：blocks[逻辑坐标] = 方块数据
    manager.blocks = {}

    -- 存储所有方块的列表
    manager.blockList = {}

    return manager
end

-- 添加方块
-- @param logicPos 逻辑坐标
-- @param worldPos 世界坐标
-- @param obj 方块对象
-- @param state 方块状态
function BlockManager:AddBlock(logicPos, obj, state)
    local block = BlockData.new(logicPos, obj, state)
    local key = string.format("%d,%d,%d", logicPos.x, logicPos.y, logicPos.z)
    self.blocks[key] = block
    table.insert(self.blockList, block)
    return block
end

-- 根据逻辑坐标获取方块
function BlockManager:GetBlock(logicPos)
    local key = string.format("%d,%d,%d", logicPos.x, logicPos.y, logicPos.z)
    return self.blocks[key]
end

-- 根据逻辑坐标移除方块
function BlockManager:RemoveBlock(logicPos)
    local key = string.format("%d,%d,%d", logicPos.x, logicPos.y, logicPos.z)
    local block = self.blocks[key]

    if block then
        self.blocks[key] = nil
        for i, b in ipairs(self.blockList) do
            if b == block then
                table.remove(self.blockList, i)
                break
            end
        end
    end

    return block
end

-- 设置方块状态
function BlockManager:SetBlockState(logicPos, state)
    local block = self:GetBlock(logicPos)
    if block then
        block:SetState(state)
    end
    return block
end

-- 获取指定状态的方块
function BlockManager:GetBlocksByState(state)
    local blocks = {}
    for _, block in pairs(self.blocks) do
        if block:GetState() == state then
            table.insert(blocks, block)
        end
    end
    return blocks
end

-- 获取所有方块
function BlockManager:GetAllBlocks()
    return self.blockList
end

-- 获取方块数量
function BlockManager:GetBlockCount()
    return #self.blockList
end

-- 检查指定位置是否有方块
function BlockManager:HasBlock(logicPos)
    return self:GetBlock(logicPos) ~= nil
end

-- 获取指定位置方块的状态
function BlockManager:GetBlockState(logicPos)
    local block = self:GetBlock(logicPos)
    return block and block:GetState()
end

local directions = {
    Vec3.new(1, 0, 0),  -- 右
    Vec3.new(-1, 0, 0), -- 左
    Vec3.new(0, 1, 0),  -- 上
    Vec3.new(0, -1, 0), -- 下
    Vec3.new(0, 0, 1),  -- 前
    Vec3.new(0, 0, -1)  -- 后
}
-- 核心功能：查找与指定状态的方块连接的所有方块（包含自己）
-- @param startBlock 起始方块
-- @param state 状态
-- @return 返回连接的方块列表
function BlockManager:FindConnectedBlocksByState(startBlock, state)
    if not startBlock or startBlock:GetState() ~= state then
        return {}
    end
    
    -- BFS
    local connectedBlocks = {}
    local visited = {}
    local queue = { startBlock }
    while #queue > 0 do
        local currentBlock = table.remove(queue, 1)
        local currentPos = currentBlock:GetLogicPos()
        local currentKey = string.format("%d,%d,%d", currentPos.x, currentPos.y, currentPos.z)
        if visited[currentKey] then
            goto continue
        end
        visited[currentKey] = true
        table.insert(connectedBlocks, currentBlock)
        for _, direction in ipairs(directions) do
            local neighborPos = currentPos + direction
            local neighborBlock = self:GetBlock(neighborPos)
            if neighborBlock and neighborBlock:GetState() == state then
                local neighborKey = string.format("%d,%d,%d", neighborPos.x, neighborPos.y, neighborPos.z)
                if not visited[neighborKey] then
                    table.insert(queue, neighborBlock)
                end
            end
        end
        ::continue::
    end

    return connectedBlocks
end

-- 根据逻辑坐标查找指定状态的连接的方块
function BlockManager:FindConnectedBlocksByPos(logicPos, state)
    local block = self:GetBlock(logicPos)
    if block then
        return self:FindConnectedBlocksByState(block, state)
    end
    return {}
end

-- 重置所有方块的状态
function BlockManager:ResetAllBlocks(state)
    for _, block in pairs(self.blocks) do
        block:SetState(state)
    end
end

return BlockManager
