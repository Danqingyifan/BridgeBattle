-- 桥管理器
local Vec3 = require(game.MainStorage.Common.Math.Vec3)
local BlockManager = require(script.BlockManager)
local BridgeConfig = require(game.MainStorage.Config.BridgeConfig)

local BridgeManager = {}

-- 初始化桥管理器
function BridgeManager.new()
    local manager = {}
    manager.blockManager = BlockManager.new()
    manager.bridgeStartPos = Vec3.new(0, 0, 0) -- 桥的起始位置
    return manager
end

-- 生成桥的方块
function BridgeManager:GenerateBridge()
    local config = BridgeConfig
    local startPos = self.bridgeStartPos

    -- 左手坐标系
    local rightDirection = Vec3.new(1, 0, 0)   -- +X 向右
    local upDirection = Vec3.new(0, 1, 0)      -- +Y 向上
    local forwardDirection = Vec3.new(0, 0, 1) -- +Z 向前

    local bridgeLength = config.BridgeLength
    local bridgeWidth = config.BridgeWidth
    local bridgeThickness = config.BridgeThickness
    local guardHeight = config.BridgeGuardHeight
    local blockSize = config.BlockSize
    local lengthBlocks = math.ceil(bridgeLength / blockSize)
    local widthBlocks = math.ceil(bridgeWidth / blockSize)
    local thicknessBlocks = math.ceil(bridgeThickness / blockSize)
    local guardBlocks = math.ceil(guardHeight / blockSize)
    -- 生成桥面方块
    for l = 0, lengthBlocks - 1 do
        for w = 0, widthBlocks - 1 do
            for t = 0, thicknessBlocks - 1 do
                local logicPos = Vec3.new(l, t, w)
                local worldPos = startPos +
                    forwardDirection * (l * blockSize) +
                    rightDirection * (w * blockSize) +
                    upDirection * (t * blockSize)
                local blockState = config.BlockState.Normal
                -- todo:生成实体方块
                local obj = nil
                -- 创建方块数据
                self.blockManager:AddBlock(logicPos, obj, blockState)
            end
        end
    end

    -- 生成护栏
    for l = 0, lengthBlocks - 1 do
        for h = 0, guardBlocks - 1 do
            local leftLogicPos = Vec3.new(l, thicknessBlocks + h, 0)
            local leftWorldPos = startPos +
                forwardDirection * (l * blockSize) +
                upDirection * ((thicknessBlocks + h) * blockSize)
            -- todo:生成实体方块
            local obj = nil
            self.blockManager:AddBlock(leftLogicPos, obj, config.BlockState.Normal)
            
            local rightLogicPos = Vec3.new(l, thicknessBlocks + h, widthBlocks - 1)
            local rightWorldPos = startPos +
                forwardDirection * (l * blockSize) +
                rightDirection * ((widthBlocks - 1) * blockSize) +
                upDirection * ((thicknessBlocks + h) * blockSize)
            -- todo:生成实体方块
            local obj = nil
            self.blockManager:AddBlock(rightLogicPos, obj, config.BlockState.Normal)
        end
    end
    print("桥生成完成，总共生成", self.blockManager:GetBlockCount(), "个方块")
end

-- 炸毁指定位置的方块
function BridgeManager:DestroyBlock(logicPos)
    local block = self.blockManager:GetBlock(logicPos)
    if block then
        self.blockManager:SetBlockState(logicPos, BridgeConfig.BlockState.Destroyed)
        print("方块被炸毁：", logicPos.x, logicPos.y, logicPos.z)
        -- todo: 炸毁逻辑
        return true
    end
    print("炸毁方块不存在：", logicPos.x, logicPos.y, logicPos.z)
    return false
end

-- 根据逻辑坐标查找其连接的所有炸毁的方块
function BridgeManager:FindConnectedDestroyedBlocks(logicPos)
    local block = self.blockManager:GetBlock(logicPos)
    if block then
        return self.blockManager:FindConnectedBlocksByState(block, BridgeConfig.BlockState.Destroyed)
    end
    return {}
end

-- 修复指定逻辑位置指定个数的炸毁方块
function BridgeManager:RepairBlock(logicPos, count)
    local connectedBlocks = self:FindConnectedDestroyedBlocks(logicPos)
    for i = 1, count do
        if #connectedBlocks > 0 then
            local block = table.remove(connectedBlocks, 1)
            local ret = self.blockManager:SetBlockState(block:GetLogicPos(), BridgeConfig.BlockState.Normal)
            if ret then
                -- todo: 修复逻辑
            end
        end
    end
end

-- 重置桥
function BridgeManager:ResetBridge()
    self.blockManager:ResetAllBlocks(BridgeConfig.BlockState.Normal)
    print("桥已重置")
end

-- 获取方块管理器
function BridgeManager:GetBlockManager()
    return self.blockManager
end

-- 获取桥的状态信息
function BridgeManager:GetBridgeStatus()
    local totalBlocks = self.blockManager:GetBlockCount()
    local destroyedBlocks = #self.blockManager:GetBlocksByState(BridgeConfig.BlockState.Destroyed)
    local intactBlocks = totalBlocks - destroyedBlocks

    return {
        totalBlocks = totalBlocks,
        destroyedBlocks = destroyedBlocks,
        intactBlocks = intactBlocks,
        destructionRate = totalBlocks > 0 and (destroyedBlocks / totalBlocks) or 0
    }
end

return BridgeManager
