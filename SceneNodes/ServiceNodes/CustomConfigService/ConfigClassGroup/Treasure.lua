local rewardConfig = {
    {AttrName = 'rewardType', AttrType = 'enum', EnumValues = 'Card,Currency', DefaultValue = 0},
    {AttrName = 'rewardCardQuality', AttrType = 'enum', EnumValues = 'None,C,B,A,S', DependAttr = 'rewardType', DependAttrValue = 0, DefaultValue = 1},
    {AttrName = 'rewardProbability', AttrType = 'double', DependAttr = 'rewardType', DependAttrValue = 0, DefaultValue = 0},
    {AttrName = 'rewardCardCountMin', AttrType = 'double', DependAttr = 'rewardType', DependAttrValue = 0, DefaultValue = 0},
    {AttrName = 'rewardCardCountMax', AttrType = 'double', DependAttr = 'rewardType', DependAttrValue = 0, DefaultValue = 0},
    {AttrName = 'rewardCurrencyMin', AttrType = 'double', DependAttr = 'rewardType', DependAttrValue = 1, DefaultValue = 0},
    {AttrName = 'rewardCurrencyMax', AttrType = 'double', DependAttr = 'rewardType', DependAttrValue = 1, DefaultValue = 0}
}

local treasureConfig = {
    {AttrName = 'miniPrice', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'gamePrice', AttrType = 'double', DefaultValue = 0},
    {AttrName = 'rewardList', AttrType = 'table array', SubAttrs = rewardConfig, SubAttrsClass = 'Reward'}
}
return treasureConfig
