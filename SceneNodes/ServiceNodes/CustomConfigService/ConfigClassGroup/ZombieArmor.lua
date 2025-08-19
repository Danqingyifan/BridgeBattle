local effectConfig = {
    {AttrName = 'Effect', AttrType = 'enum', EnumValues = 'None,AntiBurning,AntiFrozen,AntiDizzy,AntiExplosion', DefaultValue = 0},
    {AttrName = 'EffectValue', AttrType = 'double', DefaultValue = 0}
}

local armorConfig = {
    {AttrName = 'ArmorEffects', AttrType = 'table array', SubAttrs = effectConfig, SubAttrsClass = 'Effect'},
    {AttrName = 'ArmorValue', AttrType = 'double', DefaultValue = 0}
}
return armorConfig
