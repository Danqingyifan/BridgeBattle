--[[
-- 强化
local Players = game:GetService("Players")
local uin = Players.LocalPlayer.UserId
_G.LogicHub.CurrentLogic:Notify('game_action', 'buildUp', uin)

--补给
_G.LogicHub.CurrentLogic:Notify('game_action','bonus')

--增加体力（要替换UIN）
local ZSDataService = require(game.ServerStorage.KVStorage.ZSDataService)
ZSDataService:_AddEnergy(你的UIN, 1000)

--增加体力（纯单机，不用写UIN）
local ZSDataService = require(game.ServerStorage.KVStorage.ZSDataService)
ZSDataService:_AddEnergy(game.Players.LocalPlayer.UserId, 1000)

--战斗立即胜利（false为失败）
_G.LogicHub.CurrentLogic:GameEnd(true)

--跳过引导
_G.PlayerController.playerHUD:GM_REMOVEGUIDE()
]]
