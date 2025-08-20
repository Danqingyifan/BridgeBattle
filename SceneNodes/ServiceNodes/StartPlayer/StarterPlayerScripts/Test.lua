-- 测试代码
local BridgeManager = require(game.MainStorage.GamePlay.BridgeManager)
local CollideDefines = require(game.MainStorage.Common.CollideDefines)
local Utils = require(game.MainStorage.Common.Utils)
local Vec3 = require(game.MainStorage.Common.Math.Vec3)

-- 测试桥管理器
local function TestBridgeManager()
    print("=== 开始测试 BridgeManager ===")
    -- 模拟根节点
    local workspace = game:GetService("WorkSpace")
    local mockRootNode = workspace:WaitForChild("Bridge")
    -- 测试1: 创建桥管理器
    print("--- 测试1: 创建桥管理器 ---")
    local bridgeManager = BridgeManager.new()
    assert(bridgeManager ~= nil, "桥管理器创建失败")
    assert(bridgeManager.blockManager ~= nil, "方块管理器未初始化")
    print("✓ 桥管理器创建成功")

    -- 测试2: 生成红队桥梁
    print("--- 测试2: 生成红队桥梁 ---")
    local redTeamType = CollideDefines.CollideType.redTeam
    bridgeManager:GenerateBridge(mockRootNode, redTeamType)

    local blockManager = bridgeManager:GetBlockManager()
    local totalBlocks = blockManager:GetBlockCount()
    print("✓ 桥梁生成完成，总方块数:", totalBlocks)

    -- 测试3: 修复方块
    print("--- 测试3: 修复方块 ---")
    local repairCount = 320
    local successCount, failCount = bridgeManager:RepairBlock(Vec3.new(5, 0, 5), repairCount)
    print("修复方块成功数量:", successCount, "修复方块失败数量:", failCount)
    local repairedStatus = bridgeManager:GetBridgeStatus()
    print("修复后状态:",
        "总方块数:", repairedStatus.totalBlocks,
        "炸毁方块数:", repairedStatus.destroyedBlocks,
        "完整方块数:", repairedStatus.intactBlocks)

    -- 测试4: 炸毁方块
    print("--- 测试4: 炸毁方块 ---")
    local destroyResult = bridgeManager:DestroyBlock(Vec3.new(5, 0, 5))
    assert(destroyResult == true, "方块炸毁失败")
    destroyResult = bridgeManager:DestroyBlock(Vec3.new(5, 0, 6))
    assert(destroyResult == true, "方块炸毁失败")
    destroyResult = bridgeManager:DestroyBlock(Vec3.new(5, 0, 7))
    assert(destroyResult == true, "方块炸毁失败")
    destroyResult = bridgeManager:DestroyBlock(Vec3.new(5, 1, 7))
    assert(destroyResult == true, "方块炸毁失败")

    -- 测试5: 获取桥梁状态
    print("--- 测试5: 获取桥梁状态 ---")
    local status = bridgeManager:GetBridgeStatus()
    print("桥梁状态:",
        "总方块数:", status.totalBlocks,
        "炸毁方块数:", status.destroyedBlocks,
        "完整方块数:", status.intactBlocks,
        "破坏率:", string.format("%.2f%%", status.destructionRate * 100))
    assert(status.totalBlocks == totalBlocks, "总方块数不匹配")
    assert(status.intactBlocks + status.destroyedBlocks == status.totalBlocks, "方块数计算错误")

    -- 测试6: 查找连接的炸毁方块
    print("--- 测试6: 查找连接的炸毁方块 ---")
    local connectedBlocks = bridgeManager:FindConnectedDestroyedBlocks(Vec3.new(5, 0, 5))
    print("连接的炸毁方块数量:", #connectedBlocks)
    assert(#connectedBlocks > 0, "应该找到连接的炸毁方块")

    -- 测试7: 重置桥梁
    print("--- 测试7: 重置桥梁 ---")
    bridgeManager:ResetBridge()
    local resetStatus = bridgeManager:GetBridgeStatus()
    print("重置后状态:",
        "总方块数:", resetStatus.totalBlocks,
        "炸毁方块数:", resetStatus.destroyedBlocks,
        "完整方块数:", resetStatus.intactBlocks)

    assert(resetStatus.intactBlocks == 0, "重置后不应该有完整的方块")
    assert(resetStatus.destroyedBlocks == resetStatus.totalBlocks, "重置后所有方块应该是炸毁的")
end

-- 测试RPG炸桥代码
local function TestRPG()
    print("=== 开始测试 RPG伪代码 ===")

    local workspace = game:GetService("WorkSpace")
    local mockRootNode = workspace:WaitForChild("Bridge")
    local bridgeManager = BridgeManager.new()
    local redTeamType = CollideDefines.CollideType.redTeam -- 红队桥梁
    bridgeManager:GenerateBridge(mockRootNode, redTeamType)
    bridgeManager:RepairBlock(Vec3.new(0, 0, 0), 300)

    local worldService = game:GetService("WorldService")
    local collideGroup = CollideDefines:GetBridgeCollideGroupByType(redTeamType)
    local radius = 100
    game:GetService("UserInputService").InputBegan:Connect(function(inputObj, bGameProcessd)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1.Value  then
            local retData = Utils.TryGetRaycastUnderCursor(inputObj, 100000, false, { collideGroup })
            if retData.isHit then
                local hitObjects = worldService:OverlapSphere(radius, retData.position, false, { collideGroup })
                local destroyedBlocks = 0
                for _, hitObject in ipairs(hitObjects) do
                    if bridgeManager:DestroyBlockByObj(hitObject.obj) then
                        destroyedBlocks = destroyedBlocks + 1
                    end
                end
                print("炸毁方块数量:", destroyedBlocks)
            end
        end
    end)
end


-- 运行所有测试
local function RunAllTests()
    print("开始运行 BridgeManager 测试套件...")

    local success, error = pcall(function()
        -- TestBridgeManager()
        TestRPG()
    end)

    if success then
        print("🎉 所有测试成功完成！")
    else
        print("❌ 测试失败:", error)
    end
end

-- 执行测试
RunAllTests()
