-- 桥配置
local BridgeConfig = {}

-- 方块状态
BridgeConfig.BlockState = {
    Normal = 1,     -- 正常
    Destroyed = 2,  -- 炸毁
}

BridgeConfig.BlockSize = 100 -- 方块边长
BridgeConfig.BridgeLength = 30 -- 桥长
BridgeConfig.BridgeWidth = 8 -- 桥宽
BridgeConfig.BridgeThickness = 1 -- 桥厚度
BridgeConfig.BridgeGuardHeight = 1 -- 桥护栏高度

return BridgeConfig
