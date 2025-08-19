local PlayerKVTableEnum = {

    -- 玩家多个地图互通的相关属性
    --[[
	    PlantList = { 植物ID },              -- 植物列表
        EmoteActionList = { 表情动作ID },    -- 表情动作列表
        
        LastMapID = 上一个关卡ID
    ]]
    PlayerAttributes = 'PlayerAttributes_1',

    -- 货币相关数据
    --[[
        Diamond = 钻石数量,
    ]]
    CurrencyTable = 'Currency_1',


    -- 大厅相关数据
    --[[

        PlantMorphID = 植物ID,               -- 当前变身的植物 ID
        SkinID = 皮肤ID,                     -- 迷你皮肤ID
        
        EmoteActionSlotMap = {              -- 每个植物装备的表情动作
            [植物ID] = {
                [槽位索引] = 表情动作ID,
            }
        },
        
        AvatarInfo = {
            PlantMorphID = 植物ID,
            SkinID = 皮肤ID,
            PartGroup = {
                [部件名] = 部件 ModelID
            }
        }
    ]]
    HallData = 'HallData_1',

    -- 射击游戏相关数据
    --[[
        ZombieStormCards = {
            [植物ID] = {
                cardLevel = 卡牌等级,
                cardExp = 卡牌经验
            },
        },
        ZombieStormLevelProgress = {
            {
                levelId = 关卡ID,
                stars = 星星数量,
            },
        },
        PurchaseTreasureCount = 开启宝箱次数,
        ZombieStormCurrency = 僵尸风暴货币,
        Energy = {
            Value = 体力值,
            Time = 上次更新时间,
            RemainingRecoveryTime = 下次恢复的剩余时间,
            RemainingPurchaseCount = 每日剩余购买次数,
        },
        RankingList = {
            PVZ_Gun_CareerRanking_1 =  生涯总榜
            PVZ_Gun_CareerSingleLevel_1 =  生涯单榜
            PVZ_Gun_EndlessRanking_1 = 无尽总榜
            PVZ_Gun_EndlessSingleLevel_1 =  无尽单榜
            PVZ_Gun_TeamEndlessRanking_1 =  组队无尽总榜
            PVZ_Gun_TeamEndlessSingleLevel_1 = 组队无尽单榜
        },
        GuideList = {key1, key2, ...}, -- 已经完成的引导步骤列表
        ifPurchasedTreasure = 是否购买过宝箱,
    ]]
    ZombieStormData = 'ZombieStormData_1',


    --塔防数据
    --[[
        TDCards = {
        [植物ID] = {
            cardLevel = 卡牌等级,
            cardExp = 卡牌经验
        },
        TDLevelProgress = {
        {
            levelId = 关卡ID,
            starts = 星星数量
        },
        TDTreasure = {
        {
            reasureId = 宝箱ID,
            treasureLevel = 宝箱等级
        },
        PurchaseTreasureCount = 开启宝箱次数,
        TDCurrency = 塔防货币数量
    ]]
    TDData = "TDData_1",
}

return PlayerKVTableEnum
