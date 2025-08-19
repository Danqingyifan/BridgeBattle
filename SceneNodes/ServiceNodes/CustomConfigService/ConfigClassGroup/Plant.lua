local shootConfigDesc = {
    -- 开火是否需要蓄力
    {AttrName = 'needCharge', AttrType = 'bool', DefaultValue = false},
    {
        AttrName = 'chargeTime',
        AttrType = 'double',
        DependAttr = 'needCharge',
        DependAttrValue = true,
        DefaultValue = 0.000000
    },
    -- 蓄力完成后是否自动开火,true则为蓄力完成后松手才会开火，false则为蓄力完成后按住鼠标左键就会开火
    {
        AttrName = 'releaseToFire',
        AttrType = 'bool',
        DependAttr = 'needCharge',
        DependAttrValue = true,
        DefaultValue = false
    },
    -- 蓄力冷却时间
    {
        AttrName = 'chargeCooldownTime',
        AttrType = 'double',
        DependAttr = 'needCharge',
        DependAttrValue = true,
        DefaultValue = 0.00
    },
    -- 开火能否循环
    {AttrName = 'isLoopFire', AttrType = 'bool', DefaultValue = false},
    -- 自动扳机
    {AttrName = 'autoFireDis', AttrType = 'double', DefaultValue = 0.000000},
    -- 辅助瞄准
    {AttrName = 'autoAimDis', AttrType = 'double', DefaultValue = 0.000000}
}

local shakeConfigDesc = {
    {AttrName = 'easing', AttrType = 'string', DefaultValue = 'Linear'}, -- 缓动类型
    {AttrName = 'easingStart', AttrType = 'double', DefaultValue = 1.0}, -- 缓动开始
    {AttrName = 'easingEnd', AttrType = 'double', DefaultValue = 0.0}, -- 缓动结束
    {AttrName = 'duration', AttrType = 'double', DefaultValue = 0.05}, -- 晃动持续时间(秒)
    {AttrName = 'frequency', AttrType = 'double', DefaultValue = 0.05}, -- 晃动频率
    {AttrName = 'strength', AttrType = 'double', DefaultValue = 1.0}, -- 晃动强度
    {AttrName = 'rotX', AttrType = 'double', DefaultValue = 20}, -- 晃动角度
    {AttrName = 'rotY', AttrType = 'double', DefaultValue = 20}, -- 晃动角度
    {AttrName = 'rotZ', AttrType = 'double', DefaultValue = 0.0}, -- 晃动角度
    {AttrName = 'posX', AttrType = 'double', DefaultValue = 0.0}, -- 晃动位置
    {AttrName = 'posY', AttrType = 'double', DefaultValue = 0.0}, -- 晃动位置
    {AttrName = 'posZ', AttrType = 'double', DefaultValue = 0.0} -- 晃动位置
}

local configDesc = {
    {AttrName = 'plantType', AttrType = 'enum', EnumValues = 'Shooter,Thrower,Cannoneer,Continuous'},
    -- 卡牌基础参数
    {AttrName = 'maxHealth', AttrType = 'double', DefaultValue = 100},
    {AttrName = 'damage', AttrType = 'double', DefaultValue = 100},
    {AttrName = 'magazine', AttrType = 'double', DefaultValue = 30},
    {AttrName = 'magazineCarry', AttrType = 'double', DefaultValue = 99999},
    {AttrName = 'bulletName', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'bulletRange', AttrType = 'double', DefaultValue = 2500},
    {AttrName = 'bulletSpeed', AttrType = 'double', DefaultValue = 4000},
    -- 关于射击的参数
    {
        AttrName = 'shootConfig',
        AttrType = 'table',
        SubAttrs = shootConfigDesc,
        SubAttrsClass = 'shootConfig',
        DefaultValue = {}
    },
    -- 关于震动的参数
    {AttrName = 'shakeConfig', AttrType = 'table', SubAttrs = shakeConfigDesc, SubAttrsClass = 'shakeConfig', DefaultValue = {}},
    -- 特效
    {AttrName = 'fireVFXAssetID', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'fireVFXScale', AttrType = 'vector3', DefaultValue = Vector3.New(1, 1, 1)},
    {AttrName = 'chargeVFXAssetID', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'chargeVFXScale', AttrType = 'vector3', DefaultValue = Vector3.New(1, 1, 1)},
    {AttrName = 'upgradeCoefficient', AttrType = 'table', SubAttrs = upgradeCoefficientDesc, SubAttrsClass = 'upgradeCoefficient', DefaultValue = {}},
    {AttrName = 'avatarIconAssetID', AttrType = 'string', DefaultValue = ''},
    -- 卡牌简介
    {AttrName = 'brief', AttrType = 'string', DefaultValue = ''}
}

return configDesc
