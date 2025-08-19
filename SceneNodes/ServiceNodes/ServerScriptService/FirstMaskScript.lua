print("first mask server!")

local FirstMaskEvent = game.MainStorage.FirstMaskEvent
local CloudService = game.CloudService
local RunService = game:GetService('RunService')

local white_list = {
    [37650605]=1,
    [1884167604]=1,
	[1994323158]=1,
	[1848331313]=1,
	[1834694669]=1,
	[1918588107]=1,
	[1851161948]=1,
	[1751681049]=1,
    [1874312732]=1,
	[1998704648]=1,
	[1999520996]=1,
	[1999585206]=1,
	[1997741132]=1,
	[1884354377]=1
}

local handler = {}

FirstMaskEvent.OnServerNotify:Connect(function(uin, typ, ...)
    handler[typ](uin, ...)
end)

function handler.whitelist(uin)
    FirstMaskEvent:FireClient(uin, "show", white_list)
end

function handler.list_set(uin, luin, mask)
    white_list[luin] = mask
    CloudService:SetTableAsync(
        "white_list",
        white_list,
        function(success)
            print("SetTableAsync white_list", success)
        end
    )
end

function handler.list_sets(uin, list, mask)
	for _, uin in ipairs(list) do
		white_list[uin] = mask
	end
    CloudService:SetTableAsync(
        "white_list",
        white_list,
        function(success)
            print("SetTableAsync white_list", success)
        end
    )
end

game.Players.PlayerAdded:Connect(function(player)
    CloudService:GetTableAsync(
        "white_list",
        function(success, data)
            print("GetTableAsync white_list", success, data)
            if success and type(data) == "table" then
                white_list = data
            end
            local mask = white_list[0] or white_list[player.UserId]
            if mask or RunService:GetAppPlatformName()=="PC" then
                FirstMaskEvent:FireClient(player.UserId, "mask", mask)
            end
        end
    )
end)
