local MainStorage = game:GetService('MainStorage')

local Utils = require(MainStorage.Common.Utils)
local Math = require(MainStorage.Common.Math)
local Vec3 = Math.Vec3
local Perlin = Math.Perlin

local Tween = require(script.ShakeTween)

local ShakeController = {
    shakeDatas = {},
    _shaking = false,
    _shakePosDelta = Vec3.new(0, 0, 0),
    _shakeRotDelta = Vec3.new(0, 0, 0)
}
local ShakeConfig = require(script.ShakeConfig)

-- 震动数据
local ShakeData = {
    -- 曲线类型
    easing = 'Linear',
    -- 曲线参数
    easingStart = 0.0,
    easingEnd = 1.0,
    -- 震动持续时间
    duration = 1.0,
    -- 震动频率
    frequency = 0.05,
    -- 强度
    strength = 1.0,
    -- 旋转参数
    rotX = 0.0,
    rotY = 0.0,
    rotZ = 0.0,
    -- 位移参数
    posX = 0.0,
    posY = 0.0,
    posZ = 0.0,
    -- 运行状态
    loop = false,
    stop = false,
    stopfade = false,
    elapsedtime = 0.0,
    rotDelta = nil,
    posDelta = nil,
    randSeed = nil
}

function ShakeController:GetShakeData(name)
    return ShakeConfig[name]
end

-- 加载震动数据
function ShakeController:LoadData(name)
    local data = self:GetShakeData(name)
    if not data then
        print('Load Shake Data Failed', name)
        return false
    end
    data = Utils.ShallowCopy(data)
    data.stop = true
    data._posShake = data.posX ~= 0.0 or data.posY ~= 0.0 or data.posZ ~= 0.0
    data._rotShake = data.rotX ~= 0.0 or data.rotY ~= 0.0 or data.rotZ ~= 0.0
    self.shakeDatas[name] = data
    self.shakeDatas[name].stop = true
    return true
end

-- 震动屏幕
function ShakeController:Start(name)
    if not self.shakeDatas[name] then
        self:LoadData(name)
    end
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stop = false
    self.shakeDatas[name].loop = false
    self.shakeDatas[name]._times = 0
    self.shakeDatas[name].elapsedtime = 0.0
    self.shakeDatas[name].posDelta = Vec3.new(0, 0, 0)
    self.shakeDatas[name].rotDelta = Vec3.new(0, 0, 0)
    self.shakeDatas[name].randSeed = Math:Random(0, 36)
end
-- 开始持续震动
function ShakeController:StartLoop(name)
    if not self.shakeDatas[name] then
        self:LoadData(name)
    end
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stop = false
    self.shakeDatas[name].loop = true
    self.shakeDatas[name].elapsedtime = 0.0
    self.shakeDatas[name].posDelta = Vec3.new(0, 0, 0)
    self.shakeDatas[name].rotDelta = Vec3.new(0, 0, 0)
    self.shakeDatas[name].randSeed = Math:Random(0, 36)
end
-- 停止持续震动
function ShakeController:StopLoop(name)
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].loop = false
end
-- 淡出震动
function ShakeController:StopFade(name)
    if not self.shakeDatas[name] then
        return
    end
    self.shakeDatas[name].stopfade = true
    self.shakeDatas[name].loop = false
end

-- 停止震动
function ShakeController:Stop(name)
    self.shakeDatas[name].stop = true
    self.shakeDatas[name].loop = false
end

-- 停止全部
function ShakeController:StopAll()
    for name, shakeData in pairs(self.shakeDatas) do
        shakeData.stop = true
        shakeData.loop = false
    end
end

function ShakeController:Update(dt)
    self._shakeRotDelta = Vec3.new(0, 0, 0)
    self._shakePosDelta = Vec3.new(0, 0, 0)

    self._shaking = false
    for name, shakeData in pairs(self.shakeDatas) do
        if not shakeData.stop then
            self._shaking = true
            -- 进行震动
            self:Shake(shakeData, dt)
            self._shakePosDelta = self._shakePosDelta + shakeData.posDelta
            self._shakeRotDelta = self._shakeRotDelta + shakeData.rotDelta
        end
    end
end
-- 震动屏幕
function ShakeController:Shake(shakeData, dt)
    local function Noise2D(x, y)
        return Perlin:StaticNoise2D(x, y)
    end
    if not shakeData.stop and shakeData.elapsedtime < shakeData.duration then
        -- 执行震动
        shakeData.elapsedtime = shakeData.elapsedtime + dt

        local progress = shakeData.elapsedtime / shakeData.duration
        local easingProgress = Tween[shakeData.easing or 'Linear'](progress)
        local easingValue = shakeData.easingStart + (shakeData.easingEnd - shakeData.easingStart) * easingProgress
        if shakeData._rotShake then
            local rx = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 0.0) - 0.5
            local ry = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 1.0) - 0.5
            local rz = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 2.0) - 0.5
            shakeData.rotDelta = Vec3.new(rx, ry, rz) * Vec3.new(shakeData.rotX, shakeData.rotY, shakeData.rotZ) * shakeData.strength * easingValue
        end
        if shakeData._posShake then
            local px = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 3.0) - 0.5
            local py = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 4.0) - 0.5
            local pz = Noise2D(shakeData.elapsedtime * shakeData.frequency, shakeData.randSeed + 5.0) - 0.5
            shakeData.posDelta = Vec3.new(px, py, pz) * Vec3.new(shakeData.posX, shakeData.posY, shakeData.posZ) * shakeData.strength * easingValue
        end

        if shakeData.stopfade then
            shakeData.duration = shakeData.elapsedtime + 1.0
            shakeData.stopfade = false
        end
    elseif shakeData.times then
        shakeData._times = shakeData._times + 1
        if shakeData._times >= shakeData.times then
            shakeData.stop = true
        else
            shakeData.elapsedtime = 0.0
        end
    else
        -- 震动完毕
        if shakeData.loop then
            shakeData.stop = false
            shakeData.elapsedtime = 0.0
        else
            shakeData.stop = true
        end
    end
end
-- 是否正在震动
function ShakeController:IsShaking()
    return self._shaking
end
-- 获取震动位移
function ShakeController:GetPosDelta()
    return self._shakePosDelta
end
-- 获取震动旋转
function ShakeController:GetRotDelta()
    return self._shakeRotDelta
end

return ShakeController
