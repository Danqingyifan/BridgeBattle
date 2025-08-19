local MainStorage = game:GetService('MainStorage')
local CustomConfig = require(MainStorage.Common.CustomConfig)

local PlantConfig = CustomConfig.GetConfigs('Plant')
local BulletConfig = CustomConfig.GetConfigs('Bullet')

local CameraShakeConfig = {}

for _, config in pairs(PlantConfig) do
    local plantName = config.ConfigNode.Name

    local shakeConfig = config.ConfigData.shakeConfig
    if shakeConfig then
        CameraShakeConfig[plantName] = shakeConfig
    end
end

for _, config in pairs(BulletConfig) do
    local bulletName = config.ConfigNode.Name
    local shakeConfig = config.ConfigData.shakeConfig
    if shakeConfig then
        CameraShakeConfig[bulletName] = shakeConfig
    end
end

return CameraShakeConfig
