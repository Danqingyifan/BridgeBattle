local Math = {}

Math.MathDefines = require(script.MathDefines)

Math.Vec2 = require(script.Vec2)
Math.Vec3 = require(script.Vec3)
Math.Vec4 = require(script.Vec4)
Math.Matrix3x3 = require(script.Matrix3x3)
Math.Matrix3x4 = require(script.Matrix3x4)
Math.Matrix4x4 = require(script.Matrix4x4)
Math.Quat = require(script.Quat)
Math.Perlin = require(script.PerlinNoise)

-- 数学常量
Math.PI = math.pi


--求半径内的随机点
function Math:RandomPointInRadius(center, radius)
    local angle = math.random(0, 360)
    local x = center.x + radius * math.cos(angle)
    local z = center.z + radius * math.sin(angle)
    return Vec3.new(x, center.y, z)
end
--平滑阻尼插值
function Math:SmoothDamp(current, target, velocity, smoothTime, maxSpeed, deltaTime)
    -- 防止除以零
    if smoothTime == 0 then
        return target
    end

    -- 计算减速度常数
    local timeConstant = math.sqrt(2.0 / smoothTime)

    -- 计算最大速度
    local maxVelocity = maxSpeed * timeConstant

    -- 限制速度
    velocity = math.min(velocity, maxVelocity)
    velocity = math.max(velocity, -maxVelocity)

    -- 计算新的位置
    local remainingTime = smoothTime - deltaTime
    local t = 1 - math.exp(-timeConstant * deltaTime)

    -- 使用线性插值（lerp）来平滑移动
    local smoothedValue = current + (target - current) * t

    -- 更新速度
    velocity = velocity - (target - smoothedValue) / remainingTime

    return smoothedValue, velocity
end

--范围随机数
function Math:Random(min, max)
    return min + math.random() * (max - min)
end
--随机数加偏移
function Math:RandomDeviation(value, dev)
    return value + self:Random(-dev, dev)
end
--在一个圈内随机
function Math:RandomInsideUnitCircle()
    local x = math.random() * 2 - 1
    local y = math.random() * 2 - 1
    local ret = Vec2.new(x, y)
    return ret:Normalized()
end

--判断一个数字是否在某个范围内
function Math:IsInRange(value, min, max)
    return value >= min and value <= max
end

--几乎等于
function Math:IsAlmostEqual(a, b, epsilon)
    return math.abs(a - b) < epsilon
end

--补间
function Math:Lerp(a, b, t)
    return a + (b - a) * t
end
--判断是否为NaN
function Math:IsNaN(x)
    return x ~= x
end
--判断数字是否无穷大
function Math:IsInfinity(x)
    return x == math.huge or x == -math.huge
end
--判断浮点是否等于0，接近即可
function Math:IsZero(x)
    local r = 0.001
    return math.abs(x) <= r
end
--角度差
function Math:DeltaAngle(a, b)
    local delta = (b - a) % 360
    if delta < -180 then
        delta = delta + 360
    elseif delta > 180 then
        delta = delta - 360
    end
    return delta
end

--根据一个向量方向，返回的左边方向
function Math:GetLeftDirection(direction)
    return self:GetRightDirection(direction):Negate()
end
--根据一个向量方向，返回的右边方向
function Math:GetRightDirection(direction)
    if direction.x == 0 and direction.z == 0 then
        return Vec3.new(0, 0, 1)
    end
    local orient = Quat.lookAt(direction)
    return orient * Vec3.new(1, 0, 0)
end

return Math
