local MainStorage = game:GetService('MainStorage')
local WorkSpace = game:GetService('WorkSpace')
local WorldService = game:GetService('WorldService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

local TargetUtils = require(MainStorage.Common.Utils.TargetUtils)
local CustomConfig = require(MainStorage.Common.CustomConfig)
local TimerFactory = require(MainStorage.Common.TimerFactory)
local EnumConfig = require(MainStorage.Config.EnumConfig)

local PoolManager = require(MainStorage.Subsystem.PoolManager)
local ZombieManager = _G.LevelManager.ZombieManager

local BulletManager = {
    bullets = {},
    timeList = {},
    timers = {}
}
local TIME_INTERVAL = 0.1

local PerformTween
local CalculateParabolicPath

function BulletManager.Init()
    local bulletPool = SandboxNode.New('SandboxNode', WorkSpace)
    bulletPool.Name = 'BulletPool'
    bulletPool.Parent = _G.LevelManager.currentLevel.levelInstance
    BulletManager.bulletPool = bulletPool
end

function BulletManager.GetBulletConfig(bulletName)
    return CustomConfig.GetConfig('Bullet', bulletName)
end

function BulletManager.GetDeriveConfig(deriveName)
    return CustomConfig.GetConfig('Derive', deriveName)
end

function BulletManager.CreateBullet(bulletName, parent, localPosition, localEuler, spawner)
    local bulletConfigData, bulletConfigNode = BulletManager.GetBulletConfig(bulletName)

    local bulletModel = bulletConfigNode.Model:Clone()
    local bullet = {
        bulletConfigData = bulletConfigData,
        bindActor = bulletModel,
        enabled = false,
        spawner = spawner,
        -- 子弹属性
        bulletType = bulletConfigData.bulletType, -- 子弹类型
        bulletEffect = bulletConfigData.bulletEffect, -- 子弹特效
        damage = spawner.damage, -- 子弹伤害
        speed = spawner.bulletSpeed, -- 子弹速度
        lifetime = spawner.bulletRange / spawner.bulletSpeed, -- 子弹生命周期
        hitVFXScale = bulletConfigData.hitVFXScale,
        hitGroundVFXScale = bulletConfigData.hitGroundVFXScale,
        deriveName = bulletConfigData.deriveName,
        deriveSplitNum = bulletConfigData.deriveSplitNum or 0
    }
    -- 0: 普通子弹，1: 爆炸子弹
    if bullet.bulletType == 0 then
        bullet.penetrateTimesMax = bulletConfigData.penetrateTimes -- 子弹穿透次数
    elseif bullet.bulletType == 1 then
        bullet.explosionRange = bulletConfigData.explosionRange -- 子弹爆炸范围
    end

    -- 衍生物
    if bullet.deriveName ~= nil and bullet.deriveName ~= '' then
        bullet.deriveConfigData, bullet.deriveConfigNode = BulletManager.GetDeriveConfig(bullet.deriveName)
    end

    bullet.bindActor.Name = bulletName
    bullet.bindActor.Parent = parent
    bullet.bindActor.LocalPosition = localPosition
    bullet.bindActor.LocalEuler = localEuler
    bullet.bindActor.CollideGroupID = 4
    bullet.bindActor.Visible = false

    BulletManager.bullets[bullet.bindActor.ID] = bullet
    return bullet
end

-- 创建衍生物效果（支持分裂）
function BulletManager.CreateDerive(bullet, position)
    local effectPool = PoolManager.pools['EffectPool']
    local soundPool = PoolManager.pools['SoundPool']

    local deriveSplitNum = bullet.deriveSplitNum or 1

    -- 计算分裂角度
    local angleStep = 360 / deriveSplitNum -- 每个衍生物之间的角度间隔

    for i = 1, deriveSplitNum do
        local derive = {
            deriveVFX = nil,
            deriveTimer = nil,
            deriveTimerCount = 0
        }

        -- 计算衍生物位置
        local derivePosition
        if deriveSplitNum == 1 then
            -- 只有一个衍生物时，位置就在命中点
            derivePosition = position
        else
            -- 多个衍生物时，计算位置偏移
            local currentAngle = (i - 1) * angleStep
            local angleRadians = math.rad(currentAngle)

            -- 计算衍生物的位置偏移（在XZ平面上）
            local offsetDistance = 500 -- 衍生物距离中心点的距离
            local offsetX = math.cos(angleRadians) * offsetDistance
            local offsetZ = math.sin(angleRadians) * offsetDistance
            derivePosition = position + Vector3.New(offsetX, 0, offsetZ)
        end

        if EnumConfig.MapDeriveTypeEnumToString(bullet.deriveConfigData.deriveType) == 'Normal' then
            -- 创建衍生物特效
            derive.deriveVFX =
                effectPool:ActivateEffectNode(
                bullet.deriveConfigData.deriveVFXAssetID,
                _G.LevelManager.currentLevel.levelInstance,
                derivePosition,
                Vector3.New(0, 0, 0),
                bullet.deriveConfigData.deriveVFXScale
            )

            -- 衍生物施加效果
            derive.deriveTimerCount = ((bullet.deriveConfigData.deriveLifeTime - bullet.deriveConfigData.deriveEffectDelay) / bullet.deriveConfigData.deriveEffectInterval) + 1
            derive.deriveTimer =
                TimerFactory.CreateTimer(
                bullet.deriveConfigData.deriveEffectDelay,
                bullet.deriveConfigData.deriveEffectInterval,
                true,
                function()
                    derive.deriveTimerCount = derive.deriveTimerCount - 1

                    local deriveZombieList = {}
                    TargetUtils:OverlapBox(
                        derivePosition,
                        bullet.deriveConfigData.deriveRange,
                        Vector3.new(0, 0, 0),
                        {3},
                        function(obj) -- 找到目标的回调
                            local zombie = ZombieManager.ActorZombiesMap[obj.ID]
                            if zombie then
                                table.insert(deriveZombieList, zombie.logicZombie.id)
                            end
                        end
                    )

                    if next(deriveZombieList) then
                        for _, zombieId in pairs(deriveZombieList) do
                            soundPool:ActivateEffectNode(
                                bullet.deriveConfigData.deriveHitSoundAssetID,
                                _G.LevelManager.currentLevel.levelInstance,
                                ZombieManager.LogicZombiesMap[zombieId].actorZombie.Position,
                                bullet.deriveConfigData.deriveHitSoundAssetVolume
                            )
                        end
                        _G.LogicHub:ClientApply(
                            'hit',
                            bullet.spawner.positionIndex,
                            'Derive',
                            deriveZombieList,
                            bullet.CurrentOwnerID,
                            bullet.deriveConfigData.deriveDamage,
                            bullet.deriveConfigData.deriveEffect
                        )
                        deriveZombieList = {} -- 清空表
                    end

                    if derive.deriveTimerCount <= 0 then
                        derive.deriveTimer:Stop()
                        effectPool:RecycleEffectNode(derive.deriveVFX)

                        --销毁衍生物
                        derive.deriveVFX = nil
                        derive.deriveTimer = nil
                        derive.deriveTimerCount = 0
                        derive = nil
                    end
                end
            )
            derive.deriveTimer:Start()
        elseif EnumConfig.MapDeriveTypeEnumToString(bullet.deriveConfigData.deriveType) == 'Explosive' then
            local timer =
                TimerFactory.CreateTimer(
                bullet.deriveConfigData.deriveEffectDelay,
                bullet.deriveConfigData.deriveEffectDelay,
                false,
                function()
                    derive.deriveVFX =
                        effectPool:ActivateEffectNode(
                        bullet.deriveConfigData.deriveVFXAssetID,
                        _G.LevelManager.currentLevel.levelInstance,
                        derivePosition,
                        Vector3.New(0, 0, 0),
                        bullet.deriveConfigData.deriveVFXScale
                    )
                    local deriveZombieList = {}
                    TargetUtils:OverlapBox(
                        derivePosition,
                        bullet.deriveConfigData.deriveRange,
                        Vector3.new(0, 0, 0),
                        {3},
                        function(obj) -- 找到目标的回调
                            local zombie = ZombieManager.ActorZombiesMap[obj.ID]
                            if zombie then
                                table.insert(deriveZombieList, zombie.logicZombie.id)
                            end
                        end
                    )
                    if next(deriveZombieList) then
                        _G.LogicHub:ClientApply(
                            'hit',
                            bullet.spawner.positionIndex,
                            'Derive',
                            deriveZombieList,
                            bullet.CurrentOwnerID,
                            bullet.deriveConfigData.deriveDamage,
                            bullet.deriveConfigData.deriveEffect
                        )
                    end
                end
            )
            table.insert(BulletManager.timers, timer)
            timer:Start()
        end
    end
end

--[[ 计算抛物线的K值，MarkDown：
```math
k = \frac{v^2}{g t_x} \left(1 \pm \sqrt{1 - \frac{2 g t_y}{v^2} - \frac{g^2 t_x^2}{v^4}}\right)\\
v_x = \frac{v}{\sqrt{1 + k^2}}\\
v_y = \frac{k v}{\sqrt{1 + k^2}}\\
```
返回：vx, vy, 是否命中
]]
local function calcV(g, v, tx, ty, sign, maxDeg)
    local d = 1 - (2 * g * ty) / (v * v) - (g * g * tx * tx) / (v ^ 4)
    if d < 0 then
        local vx = v / math.sqrt(2)
        return vx, vx, false
    end
    local k = (v * v) / (g * tx) * (1 + (sign and 1 or -1) * math.sqrt(d))
    if maxDeg > 0 then
        local maxK = math.tan(math.rad(maxDeg))
        if k > maxK then
            k = maxK
        end
    end
    local vx = v / math.sqrt(1 + k * k)
    return vx, k * vx, true
end

function BulletManager.FireBullet(bullet, targetPosition, uid)
    -- 子弹穿透次数
    bullet.penetrateTimes = bullet.penetrateTimesMax
    bullet.CurrentOwnerID = uid
    local initPos = bullet.bindActor.Position
    local targetDir = targetPosition - initPos
    local gravity = bullet.bindActor.Gravity
    local velocity
    if gravity <= 0 then
        Vector3.Normalize(targetDir)
        velocity = targetDir * bullet.speed
        gravity = 0
    else
        local lx = math.sqrt(targetDir.X * targetDir.X + targetDir.Z * targetDir.Z)
        local ly = targetDir.Y
        local cfg = bullet.bulletConfigData
        local tx, ty, _hit = calcV(gravity, bullet.speed, lx, ly, cfg.parabolaSign, cfg.parabolaMaxDeg or 0)
        local l = tx / lx
        velocity = Vector3.New(l * targetDir.X, ty, l * targetDir.Z)
    end

    local calcFunc = CalculateParabolicPath(initPos, velocity, gravity)
    PerformTween(bullet, calcFunc, 0)
end

-- 获取发射数据
function BulletManager.GetFireBulletInfo(StartPos_V3, targetPosition, bullet)
    local initPos = StartPos_V3
    local targetDir = targetPosition - initPos
    local gravity = bullet.bindActor.Gravity
    local velocity
    if gravity <= 0 then
        Vector3.Normalize(targetDir)
        velocity = targetDir * bullet.speed
        gravity = 0
    else
        local lx = math.sqrt(targetDir.X * targetDir.X + targetDir.Z * targetDir.Z)
        local ly = targetDir.Y
        local cfg = bullet.bulletConfigData
        local tx, ty, _hit = calcV(gravity, bullet.speed, lx, ly, cfg.parabolaSign, cfg.parabolaMaxDeg or 0)
        local l = tx / lx
        velocity = Vector3.New(l * targetDir.X, ty, l * targetDir.Z)
    end
    return initPos, velocity, gravity
end

function PerformTween(bullet, calcFunc, currentTime)
    local needToBeRecycled = false

    local nextTime = currentTime + TIME_INTERVAL
    if nextTime >= bullet.lifetime then
        nextTime = bullet.lifetime
        needToBeRecycled = true
    end

    -- 理论上的下一个位置（如果没有碰撞）
    local nextPosition = calcFunc(nextTime)

    local ret_list = DetectHitByLineTrace(bullet.bindActor.Position, nextPosition)
    if next(ret_list) then
        -- 根据距离排序
        table.sort(
            ret_list,
            function(a, b)
                return a.distance < b.distance
            end
        )
        -- 如果遇到一个CollideID为1的，则说明为墙体，将其作为最后一个目标
        local wallIndex = #ret_list
        for index, ret_table in ipairs(ret_list) do
            if ret_table.obj.CollideGroupID == 1 then
                wallIndex = index
                break
            end
        end

        local finalPositionIndex = ret_list[bullet.penetrateTimes] or ret_list[wallIndex]
        if finalPositionIndex ~= nil then
            local finalPosition = finalPositionIndex.position
            nextPosition = finalPosition
        end
    end

    -- 增加子弹自旋转
    local nextLocalEuler = Vector3.New(bullet.bindActor.LocalEuler.X, bullet.bindActor.LocalEuler.Y, bullet.bindActor.LocalEuler.Z)
    if bullet.bindActor.Gravity > 0 then
        nextLocalEuler.X = nextLocalEuler.X + 50
    end

    local tweenInfo = TweenInfo.new(TIME_INTERVAL, Enum.EasingStyle.Linear)
    bullet.tween =
        TweenService:Create(
        bullet.bindActor,
        tweenInfo,
        {
            Position = nextPosition,
            LocalEuler = nextLocalEuler
        }
    )
    bullet.tween.Completed:Connect( -- 子弹碰撞检测
        function()
            local zombiesIdList = {}
            local isHit = false
            local isHitGround = false

            if EnumConfig.MapBulletTypeEnumToString(bullet.bulletType) == 'Normal' then
                for _, ret_table in ipairs(ret_list) do
                    isHit = true
                    if ret_table.obj.CollideGroupID == 3 and ZombieManager.ActorZombiesMap[ret_table.obj.ID] ~= nil then
                        if bullet.penetrateTimes > 0 then
                            bullet.penetrateTimes = bullet.penetrateTimes - 1
                            local zombie = ZombieManager.ActorZombiesMap[ret_table.obj.ID]
                            if zombie then
                                zombiesIdList[#zombiesIdList + 1] = zombie.logicZombie.id
                            end
                        else
                            break
                        end
                    elseif ret_table.obj.CollideGroupID == 1 then
                        isHitGround = true
                    end
                end
            elseif EnumConfig.MapBulletTypeEnumToString(bullet.bulletType) == 'Explosive' then
                for _, ret_table in pairs(ret_list) do
                    if ret_table.obj.CollideGroupID == 1 or ret_table.obj.CollideGroupID == 3 then
                        isHit = true
                        _G.PlayerController.playerCharacter.controlledPlant:ApplyCameraShake(bullet.bindActor.Name)
                        TargetUtils:OverlapBox(
                            bullet.bindActor.Position,
                            bullet.explosionRange,
                            Vector3.new(0, 0, 0),
                            {3},
                            function(obj)
                                local zombie = ZombieManager.ActorZombiesMap[obj.ID]
                                if zombie then
                                    zombiesIdList[#zombiesIdList + 1] = zombie.logicZombie.id
                                end
                            end
                        )
                    end
                end
            end

            if next(zombiesIdList) then
                _G.LogicHub:ClientApply('hit', bullet.spawner.positionIndex, 'Bullet', zombiesIdList, bullet.CurrentOwnerID, bullet.damage, bullet.bulletEffect)

                if bullet.spawner.hitAndBomb == 1 then
                    for _, zombieId in pairs(zombiesIdList) do
                        local zombie = ZombieManager.LogicZombiesMap[zombieId]
                        if zombie then
                            local explosiveEffectAssetID = 'sandboxId://PVZ_VFX/Prefab/M79_Hit_new.prefab'
                            PoolManager.pools['EffectPool']:ActivateEffectNode(
                                explosiveEffectAssetID,
                                _G.LevelManager.currentLevel.levelInstance,
                                bullet.bindActor.Position,
                                Vector3.New(0, 0, 0),
                                Vector3.New(1, 1, 1)
                            )

                            local zombiesIdList = {}
                            TargetUtils:OverlapBox(
                                zombie.actorZombie.Position,
                                Vector3.new(200, 200, 200),
                                Vector3.new(0, 0, 0),
                                {3},
                                function(obj)
                                    local damagedZombie = ZombieManager.ActorZombiesMap[obj.ID]
                                    if damagedZombie then
                                        zombiesIdList[#zombiesIdList + 1] = damagedZombie.logicZombie.id
                                    end
                                end
                            )
                            if next(zombiesIdList) then
                                _G.LogicHub:ClientApply('hit', bullet.spawner.positionIndex, 'Bullet', zombiesIdList, bullet.CurrentOwnerID, bullet.damage * 0.2, 0)
                            end
                        end
                    end
                end
            end
            function twoSum(nums, target)
                local map = {'abbbcde'}
                if map == nil then
                    return nil
                end
                local left = 0
                local right = 0
                local maxnum = 0
                for i = 1, #map do
                    right = i
                    local cur = left
                    while cur <= right do
                        if map[cur] == map[right] then
                            left = right
                            maxnum = math.max(maxnum, right - left)
                        end
                    end
                end
                maxnum = math.max(maxnum, right - left)
            end
            if isHit then
                -- Effect
                local effectPool = PoolManager.pools['EffectPool']
                local soundPool = PoolManager.pools['SoundPool']
                if isHitGround == true then
                    effectPool:ActivateEffectNode(
                        bullet.bulletConfigData.hitGroundVFXAssetID,
                        _G.LevelManager.currentLevel.levelInstance,
                        bullet.bindActor.Position,
                        Vector3.New(0, 0, 0),
                        bullet.hitGroundVFXScale
                    )
                    soundPool:ActivateEffectNode(
                        bullet.bulletConfigData.hitGroundSoundAssetID,
                        _G.LevelManager.currentLevel.levelInstance,
                        bullet.bindActor.Position,
                        bullet.bulletConfigData.hitGroundSoundAssetVolume
                    )
                else
                    effectPool:ActivateEffectNode(
                        bullet.bulletConfigData.hitVFXAssetID,
                        _G.LevelManager.currentLevel.levelInstance,
                        bullet.bindActor.Position,
                        Vector3.New(0, 0, 0),
                        bullet.hitVFXScale
                    )
                    soundPool:ActivateEffectNode(
                        bullet.bulletConfigData.hitSoundAssetID,
                        _G.LevelManager.currentLevel.levelInstance,
                        bullet.bindActor.Position,
                        bullet.bulletConfigData.hitSoundAssetVolume
                    )
                end

                -- 生成衍生物
                if bullet.deriveConfigData ~= nil then
                    BulletManager.CreateDerive(bullet, bullet.bindActor.Position)
                end
                needToBeRecycled = true
            end

            bullet.tween:Destroy()
            bullet.tween = nil
            if needToBeRecycled then
                bullet.spawner:RecycleBullet(bullet)
                return
            end

            PerformTween(bullet, calcFunc, nextTime)
        end
    )
    bullet.tween:Play()
end

function CalculateParabolicPath(initialPosition, initialVelocity, gravity)
    -- 返回一个函数，该函数接受时间作为参数并返回位置
    return function(time)
        return initialPosition + initialVelocity * time - Vector3.new(0, gravity * time * time / 2, 0)
    end
end

function DetectHitByLineTrace(currentPosition, nextPosition)
    local bulletDirection = nextPosition - currentPosition
    local depth = bulletDirection.Length
    return WorldService:RaycastAll(currentPosition, bulletDirection, depth, false, {1, 3})
end

function DetectHitByCollision(bullet)
end

function BulletManager.DestroyAllBullets()
    for _, bullet in pairs(BulletManager.bullets) do
        bullet.bindActor:Destroy()
        bullet = nil
    end
    BulletManager.bullets = {}

    if BulletManager.bulletPool then
        BulletManager.bulletPool:Destroy()
        BulletManager.bulletPool = nil
    end
end

return BulletManager
