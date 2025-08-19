local shakeConfigDesc = {
    {AttrName = 'easing', AttrType = 'string', DefaultValue = 'Linear'},
    {AttrName = 'easingStart', AttrType = 'double', DefaultValue = 1.0},
    {AttrName = 'easingEnd', AttrType = 'double', DefaultValue = 0.0},
    {AttrName = 'duration', AttrType = 'double', DefaultValue = 0.05},
    {AttrName = 'frequency', AttrType = 'double', DefaultValue = 0.05},
    {AttrName = 'strength', AttrType = 'double', DefaultValue = 1.0},
    {AttrName = 'rotX', AttrType = 'double', DefaultValue = 20},
    {AttrName = 'rotY', AttrType = 'double', DefaultValue = 20},
    {AttrName = 'rotZ', AttrType = 'double', DefaultValue = 0.0},
    {AttrName = 'posX', AttrType = 'double', DefaultValue = 0.0},
    {AttrName = 'posY', AttrType = 'double', DefaultValue = 0.0},
    {AttrName = 'posZ', AttrType = 'double', DefaultValue = 0.0}
}

local configDesc = {
    {
        AttrName = 'bulletType',
        AttrType = 'enum',
        EnumValues = 'Normal,Explosive',
        DefaultValue = 0
    },
    {
        AttrName = 'bulletEffect',
        AttrType = 'enum',
        EnumValues = 'None,Burning,Frozen,Dizzy',
        DefaultValue = 0
    },
    {
        AttrName = 'penetrateTimes',
        AttrType = 'double',
        DependAttr = 'bulletType',
        DependAttrValue = 0,
        DefaultValue = 1
    },
    {
        AttrName = 'explosionRange',
        AttrType = 'vector3',
        DependAttr = 'bulletType',
        DependAttrValue = 1,
        DefaultValue = Vector3.New(0, 0, 0)
    },
    {
        AttrName = 'shakeConfig',
        AttrType = 'table',
        DependAttr = 'bulletType',
        DependAttrValue = 1,
        SubAttrs = shakeConfigDesc,
        SubAttrsClass = 'shakeConfig',
        DefaultValue = {}
    },
    {
        AttrName = 'hasDerive',
        AttrType = 'bool',
        DefaultValue = false
    },
    {
        AttrName = 'deriveName',
        AttrType = 'string',
        DependAttr = 'hasDerive',
        DependAttrValue = true,
        DefaultValue = ''
    },
    {
        AttrName = 'deriveSplitNum',
        AttrType = 'double',
        DependAttr = 'hasDerive',
        DependAttrValue = true,
        DefaultValue = 1
    },
    {
        AttrName = 'trailVFXAssetID', --拖尾特效
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'trailVFXScale',
        AttrType = 'vector3',
        DefaultValue = Vector3.New(1, 1, 1)
    },
    {
        AttrName = 'hitVFXAssetID', --击中敌人特效
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'hitVFXScale',
        AttrType = 'vector3',
        DefaultValue = Vector3.New(1, 1, 1)
    },
    {
        AttrName = 'hitGroundVFXAssetID', --击中地面特效
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'hitGroundVFXScale',
        AttrType = 'vector3',
        DefaultValue = Vector3.New(1, 1, 1)
    },
    {
        AttrName = 'hitSoundAssetID',
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'hitSoundAssetVolume',
        AttrType = 'double',
        DefaultValue = 1.0
    },
    {
        AttrName = 'hitGroundSoundAssetID',
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'hitGroundSoundAssetVolume',
        AttrType = 'double',
        DefaultValue = 1.0
    },
    {
        AttrName = 'parabolaSign',
        AttrType = 'bool',
        DefaultValue = false
    },
    {
        AttrName = 'parabolaMaxDeg',
        AttrType = 'double',
        DefaultValue = 0
    }
}
return configDesc
