-- 桥管理器
local Vec3 = require(game.MainStorage.Common.Math.Vec3)
local BlockManager = require(script.BlockManager)
local CollideDefines = require(game.MainStorage.Common.CollideDefines)
local BridgeConfig = require(game.MainStorage.Config.BridgeConfig)

local BridgeManager = {}
BridgeManager.__index = BridgeManager

-- 初始化桥管理器
function BridgeManager.new()
    local manager = {}
    setmetatable(manager, BridgeManager)
    manager.blockManager = BlockManager.new()
    manager.bridgeStartPos = Vec3.new(0, 0, 0) -- 桥的起始位置
    return manager
end

-- 生成实体方块
function BridgeManager:GenerateEntityBlock(props)
    local obj = SandboxNode.new('GeoSolid', props.rootNode)
    obj.Position = Vector3.New(props.position.x, props.position.y, props.position.z)
    obj.CollideGroupID = CollideDefines:GetBridgeCollideGroupByType(props.collideType)
    obj:AddAttribute("logicPos", Enum.AttributeType.Vector3)
    obj:SetAttribute("logicPos", Vector3.New(props.logicPos.x, props.logicPos.y, props.logicPos.z))
    obj:AddAttribute("collideType", Enum.AttributeType.Number)
    obj:SetAttribute("collideType", props.collideType)
    return obj
end

-- 生成桥的方块
function BridgeManager:GenerateBridge(rootNode, collideType)
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
    -- 生成桥面方块
    for l = 0, bridgeLength - 1 do
        for w = 0, bridgeWidth - 1 do
            for t = 0, bridgeThickness - 1 do
                local logicPos = Vec3.new(l, t, w)
                local worldPos = startPos +
                    forwardDirection * (l * blockSize) +
                    rightDirection * (w * blockSize) +
                    upDirection * (t * blockSize)
                local blockState = config.BlockState.Destroyed
                local obj = self:GenerateEntityBlock({
                    logicPos = logicPos,
                    rootNode = rootNode,
                    position = worldPos,
                    collideType = collideType
                })
                self.blockManager:AddBlock(logicPos, obj, blockState)
            end
        end
    end

    -- 生成护栏
    for l = 0, bridgeLength - 1 do
        for h = 0, guardHeight - 1 do
            -- 左护栏
            local leftLogicPos = Vec3.new(l, bridgeThickness + h, 0)
            local leftWorldPos = startPos +
                forwardDirection * (l * blockSize) +
                upDirection * ((bridgeThickness + h) * blockSize)
            local objLeft = self:GenerateEntityBlock({
                logicPos = leftLogicPos,
                rootNode = rootNode,
                position = leftWorldPos,
                collideType = collideType
            })
            self.blockManager:AddBlock(leftLogicPos, objLeft, config.BlockState.Destroyed)

            -- 右护栏
            local rightLogicPos = Vec3.new(l, bridgeThickness + h, bridgeWidth - 1)
            local rightWorldPos = startPos +
                forwardDirection * (l * blockSize) +
                rightDirection * ((bridgeWidth - 1) * blockSize) +
                upDirection * ((bridgeThickness + h) * blockSize)
            local objRight = self:GenerateEntityBlock({
                logicPos = rightLogicPos,
                rootNode = rootNode,
                position = rightWorldPos,
                collideType = collideType
            })
            self.blockManager:AddBlock(rightLogicPos, objRight, config.BlockState.Destroyed)
        end
    end
    self:ResetBridge()
    print("桥生成完成，总共生成", self.blockManager:GetBlockCount(), "个方块")
end

-- 炸毁指定obj的方块
function BridgeManager:DestroyBlockByObj(obj)
    local logicPos = obj:GetAttribute("logicPos")
    if logicPos then
        return self:DestroyBlock(Vec3.new(logicPos.X, logicPos.Y, logicPos.Z))
    end
    print("炸毁方块不存在：", logicPos.x, logicPos.y, logicPos.z)
    return false
end

-- 炸毁指定位置的方块
function BridgeManager:DestroyBlock(logicPos)
    local block = self.blockManager:GetBlock(logicPos)
    if block then
        if block.state == BridgeConfig.BlockState.Destroyed then
            print("方块被重复炸毁：", logicPos.x, logicPos.y, logicPos.z)
            return false
        end
        self.blockManager:SetBlockState(logicPos, BridgeConfig.BlockState.Destroyed)
        print("方块被炸毁：", logicPos.x, logicPos.y, logicPos.z)
        self:DestroyLogic(block)
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
-- @param logicPos 逻辑位置
-- @param count 修复个数
-- @retuen 修复方块成功数量、修复方块失败数量
function BridgeManager:RepairBlock(logicPos, count)
    local connectedBlocks = self:FindConnectedDestroyedBlocks(logicPos)
    local successCount = 0
    for i = 1, count do
        if #connectedBlocks > 0 then
            local block = table.remove(connectedBlocks, 1)
            local ret = self.blockManager:SetBlockState(block:GetLogicPos(), BridgeConfig.BlockState.Normal)
            if ret then
                self:RepairLogic(block)
                successCount = successCount + 1
            end
        else
            break
        end
    end
    return successCount, count - successCount
end

-- 重置桥
function BridgeManager:ResetBridge()
    self.blockManager:ResetAllBlocks(BridgeConfig.BlockState.Destroyed)
    for _, block in ipairs(self.blockManager:GetAllBlocks()) do
        self:DestroyLogic(block)
    end
    print("桥已重置")
end

-- 桥炸毁逻辑
function BridgeManager:DestroyLogic(block)
    -- todo: 炸毁逻辑
    block.obj.CollideGroupID = CollideDefines.CollideGroup.destroyedBridge
    block.obj.Visible = false
end

-- 桥修复逻辑
function BridgeManager:RepairLogic(block)
    -- todo: 修复逻辑
    local collideType = block.obj:GetAttribute("collideType")
    block.obj.CollideGroupID = CollideDefines:GetBridgeCollideGroupByType(collideType)
    block.obj.Visible = true
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
