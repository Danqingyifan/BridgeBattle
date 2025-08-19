local configDesc = {
    {
        AttrName = 'deriveID',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveType',
        AttrType = 'enum',
        EnumValues = 'Normal,Explosive',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveRange',
        AttrType = 'vector3',
        DefaultValue = Vector3.New(0, 0, 0)
    },
    {
        AttrName = 'deriveEffect',
        --伤害类型
        AttrType = 'enum',
        EnumValues = 'None,Burning,Frozen,Dizzy',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveDamage',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveEffectDelay',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveEffectInterval',
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveLifeTime',
        --持续时间
        AttrType = 'double',
        DefaultValue = 0
    },
    {
        AttrName = 'deriveVFXAssetID',
        --衍生物
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'deriveVFXScale',
        AttrType = 'vector3',
        DefaultValue = Vector3.New(1, 1, 1)
    },
    {
        AttrName = 'deriveHitSoundAssetID',
        AttrType = 'string',
        DefaultValue = ''
    },
    {
        AttrName = 'deriveHitSoundAssetVolume',
        AttrType = 'double',
        DefaultValue = 1.0
    }
}
return configDesc
