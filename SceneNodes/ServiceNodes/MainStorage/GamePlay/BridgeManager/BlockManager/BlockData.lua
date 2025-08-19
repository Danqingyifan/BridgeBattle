-- 方块数据结构
local Vec3 = require(game.MainStorage.Common.Math.Vec3)

local BlockData = {}

-- 方块数据类
function BlockData.new(logicPos, obj, state)
    local block = {}

    -- 逻辑坐标（整数坐标）
    block.logicPos = logicPos or Vec3.new(0, 0, 0)

    -- 对应的游戏对象实例
    block.obj = obj

    -- 状态
    block.state = state or 1

    return block
end

-- 设置方块状态
function BlockData:SetState(state)
    self.state = state
end

-- 检查方块是否被炸毁
function BlockData:IsDestroyed()
    return self.isDestroyed
end

-- 获取逻辑坐标
function BlockData:GetLogicPos()
    return self.logicPos
end

-- 获取对象实例
function BlockData:GetObj()
    return self.obj
end

function BlockData:Serialize()
    return {
        logicPos = self.logicPos:ToTable(),
        state = self.state,
    }
end

function BlockData:Deserialize(data)
    if data.logicPos then
        self.logicPos = Vec3.new(data.logicPos[1], data.logicPos[2], data.logicPos[3])
    end
    self.state = data.state or 1
end

return BlockData
