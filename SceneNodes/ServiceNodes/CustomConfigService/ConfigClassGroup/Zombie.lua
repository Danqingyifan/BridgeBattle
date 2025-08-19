local speedAttrs = {
    {AttrName = 'walk', AttrType = 'double', DefaultValue = 50},
    --子弹速度
    {AttrName = 'run', AttrType = 'double', DefaultValue = 150},
    --子弹伤害
    {AttrName = 'crawlslow', AttrType = 'double', DefaultValue = 100},
    --子弹速度
    {AttrName = 'crawlfast', AttrType = 'double', DefaultValue = 150},
    --子弹伤害
    {AttrName = 'jump', AttrType = 'double', DefaultValue = 300},
    --子弹速度
    {AttrName = 'climb', AttrType = 'double', DefaultValue = 100},
    --子弹伤害
    {AttrName = 'attack', AttrType = 'double', DefaultValue = 0},
    --子弹速度
    {AttrName = 'idle', AttrType = 'double', DefaultValue = 0}
    --子弹伤害
}

local configDesc = {
    {
        AttrName = 'zombieID',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'health',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'damage',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'attackSpeed',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'speedMap',
        AttrType = 'table',
        SubAttrs = speedAttrs,
        SubAttrsClass = 'speedAttrs',
        DefaultValue = {}
    },
    {
        AttrName = 'hasArmor',
        AttrType = 'bool',
        DefaultValue = false
    },
    {
        AttrName = 'armorName',
        AttrType = 'string',
        DependAttr = 'hasArmor',
        DependAttrValue = true,
        DefaultValue = ''
    },
    {
        AttrName = 'worth',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'avatarIconAssetID',
        AttrType = 'string',
        DefaultValue = ''
    }
}
return configDesc
