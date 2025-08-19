local plantAttributeEnumsTable = {
    'PlantMagazine',
    'PlantMagazineCarry',
    'PlantFireInterval',
    'PlantFireRecoil',
    'PlantFireRange',
    'PlantReloadTime',
    'PlantKillAndBomb',
    'PlantBurstFireNum',
    'PlantHitAndBomb',
    'PlantBulletSplitNum',
    'PlantChargeTime'
}
local bulletAttributeEnumsTable = {
    'BulletSpeed',
    'BulletExplosionRange',
    'BulletPenetrateTime',
    'BulletDamage',
    'BulletEffect',
    'BulletDerive',
    'BulletDeriveSplitNum'
}
local deriveAttributeEnumsTable = {
    'DeriveDamage'
}
local playerAttributeEnumsTable = {
    'PlayerSettlementCurrency'
}
local levelAttributeEnumsTable = {
    'SunflowerHealth',
    'SunflowerDefense',
    'SunflowerReflectDamage'
}

local plantAttributeEnumsValue = table.concat(plantAttributeEnumsTable, ',')
local bulletAttributeEnumsValue = table.concat(bulletAttributeEnumsTable, ',')
local deriveAttributeEnumsValue = table.concat(deriveAttributeEnumsTable, ',')
local playerAttributeEnumsValue = table.concat(playerAttributeEnumsTable, ',')
local levelAttributeEnumsValue = table.concat(levelAttributeEnumsTable, ',')

local singleBonusConfig = {
    {AttrName = 'BonusValue', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'BonusValueType', AttrType = 'enum', EnumValues = 'Percent,Number', DefaultValue = 0},
    {AttrName = 'BonusOperation', AttrType = 'enum', EnumValues = 'Add,Mul,Set', DefaultValue = 0},
    {
        AttrName = 'BonusPlantAttributeType',
        AttrType = 'enum',
        EnumValues = 'Plant,Bullet,Derive',
        DependAttr = 'BonusType',
        DependAttrValue = 0,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusPlantAttribute',
        AttrType = 'enum',
        EnumValues = plantAttributeEnumsValue,
        DependAttr = 'BonusPlantAttributeType',
        DependAttrValue = 0,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusBulletAttribute',
        AttrType = 'enum',
        EnumValues = bulletAttributeEnumsValue,
        DependAttr = 'BonusPlantAttributeType',
        DependAttrValue = 1,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusDeriveAttribute',
        AttrType = 'enum',
        EnumValues = deriveAttributeEnumsValue,
        DependAttr = 'BonusPlantAttributeType',
        DependAttrValue = 2,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusPlayerAttribute',
        AttrType = 'enum',
        EnumValues = playerAttributeEnumsValue,
        DependAttr = 'BonusType',
        DependAttrValue = 1,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusLevelAttribute',
        AttrType = 'enum',
        EnumValues = levelAttributeEnumsValue,
        DependAttr = 'BonusType',
        DependAttrValue = 2,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusHasDuration',
        AttrType = 'bool',
        DefaultValue = false
    },
    {
        AttrName = 'BonusDurationType',
        AttrType = 'enum',
        EnumValues = 'Wave,Second',
        DependAttr = 'BonusHasDuration',
        DependAttrValue = true,
        DefaultValue = 1
    },
    {
        AttrName = 'BonusDurationValue',
        AttrType = 'double',
        DependAttr = 'BonusHasDuration',
        DependAttrValue = true,
        DefaultValue = 1
    }
}

local compositeBonusConfig = {
    {AttrName = 'BonusID', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'BonusPrerequisite', AttrType = 'double array', DefaultValue = {}},
    {AttrName = 'BonusName', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'BonusCategory', AttrType = 'enum', EnumValues = 'Magazine,Buff,BuildUp,None', DefaultValue = 0},
    {AttrName = 'BonusType', AttrType = 'enum', EnumValues = 'Plant,Player,Level', DefaultValue = 0},
    {
        AttrName = 'BonusPlantTarget',
        AttrType = 'enum',
        EnumValues = 'All,PlantType,PlantName',
        DependAttr = 'BonusType',
        DependAttrValue = 0,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusPlantTypeTargetValue',
        AttrType = 'enum',
        EnumValues = 'Shooter,Thrower,Cannoneer,Continuous',
        DependAttr = 'BonusPlantTarget',
        DependAttrValue = 1,
        DefaultValue = 0
    },
    {
        AttrName = 'BonusPlantNameTargetValue',
        AttrType = 'string',
        DependAttr = 'BonusPlantTarget',
        DependAttrValue = 2,
        DefaultValue = ''
    },
    {AttrName = 'BonusSelectType', AttrType = 'enum', EnumValues = 'Once,Repeat', DefaultValue = 0},
    {AttrName = 'BonusList', AttrType = 'table array', SubAttrs = singleBonusConfig, SubAttrsClass = 'SingleBonus'},
    {AttrName = 'BonusQuality', AttrType = 'enum', EnumValues = 'None,C,B,A,S', DefaultValue = 1},
    {AttrName = 'BonusIcon', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'BonusDescription', AttrType = 'string', DefaultValue = ''},
    {AttrName = 'BonusFooter', AttrType = 'string', DefaultValue = ''}
}
return compositeBonusConfig
