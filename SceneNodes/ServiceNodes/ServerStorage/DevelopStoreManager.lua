--商店
local DeveloperStoreService = game:GetService("DeveloperStoreService")
local ServerStorage = game:GetService('ServerStorage')
local PlayerServerData = require(ServerStorage.PlayerServerData)
local StoreManager = {
    StoreConfig = {
        [530004] = {
            goodId = 530004,
            -- 开发者商店可配置
            name = "1000金币",
            -- 开发者商店可配置
            desc = "1000个金币",
            -- 仅此
            costNum = 1,
            addCurrency = 1000,
        },
        [530005] = {
            goodId = 530005,
            name = "10000金币",
            desc = "10000个金币",
            costNum = 10,
            addCurrency = 10000,
        },
        [530006] = {
            goodId = 530006,
            name = "50000金币",
            desc = "50000个金币",
            costNum = 50,
            addCurrency = 50000,
        },
        [530007] = {
            goodId = 530007,
            name = "500000金币",
            desc = "500000个金币",
            costNum = 500,
            addCurrency = 500000,
        },
        [530008] = {
            goodId = 530008,
            name = "1体力",
            desc = "1个体力",
            costNum = 1,
        },
        

    }
}

function StoreManager.Init()
    StoreManager:RegisterCallback()
end

--注册购买回调
function StoreManager:RegisterCallback()
    DeveloperStoreService.RemoteBuyGoodsCallBack:Connect(function(uin, goodsid, code, msg, num)
        if code ~= 0 then
            print("Goods purchase failed.")
            print("Error code: ",code)
            print("Error message : ",msg)
            --0-购买成功
            --1001-地图未上传
            --1002-用户取消购买
            --1003-此商品查询失败
            --1004-请求失败
            --1005-迷你币不足
            --
            --710-商品不存在
            --711-商品状态异常
            --712-不能购买自己的商品
            --713-已购买该商品，不能重复购买
            --714-购买失败，购买数量已达上限
            --
            return
        end
        --code=0 购买成功
        print("购买成功.")
        print("RemoteBuyGoodsCallBack - uin : ",uin)
        print("RemoteBuyGoodsCallBack - goodsid: ",goodsid)
        print("RemoteBuyGoodsCallBack - num: ",num)
        if goodsid == 530008 then   
            --体力
            print("购买体力".. tostring(num) .. " 购买数量：" .. tostring(num * 10))
            local info = {
                uin = uin,
                itemType = 'energy',

                cfgId = 0,
                reason = 'StorePurchase'
            }
            PlayerServerData:AddData(info, num * 10)

            local content = string.format("获得体力<font color='#00FF00'>%d</font>！", num * 10)
            _G.GameNet:SendMsgToClient(uin, 'SHOW_WARN_POP', 'ENERGY', content)
        else
            --金币
            local addCurrency = StoreManager.StoreConfig[goodsid].addCurrency
            local info = {
                uin = uin,
                itemType = 'currency',

                cfgId = 0,
                reason = 'StorePurchase'
            }
            PlayerServerData:AddData(info, num * addCurrency)

            local content = string.format("获得金币<font color='#00FF00'>%d</font>！", num * addCurrency)
            _G.GameNet:SendMsgToClient(uin, 'SHOW_WARN_POP', 'CURRENCY', content)
        end
    end)
end

return StoreManager