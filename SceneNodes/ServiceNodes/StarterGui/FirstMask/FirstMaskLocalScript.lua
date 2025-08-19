print("first mask cllient!")

local handler = {}
local FirstMaskEvent = game.MainStorage.FirstMaskEvent
local Camera = game.WorkSpace.CurrentCamera

Camera.Enabled = true
Camera.Enabled = false
script.Parent.Visible = true

FirstMaskEvent.OnClientNotify:Connect(function(typ, ...)
    handler[typ](...)
end)

script.Parent.UIImage.Click:Connect(function()
    game.CoreUI:ExitGame()
end)

function handler.mask(mask)
    script.Parent.Visible = false
    Camera.Enabled = true
end

function handler.show(list)
    local l = {}
    local i
    for k, v in pairs(list) do
        i = #l+1
        l[i] = tostring(k) .. "=" .. tostring(v)
        if i%50==0 then
            print("list["..i.."]:", "\n"..table.concat(l, "\n").."\n")
            l = {}
        end
    end
    if #l > 0 then
        print("list["..i.."]:", "\n"..table.concat(l, "\n").."\n")
    end
end

function _G._wl(uin, mask)
    if uin then
        FirstMaskEvent:FireServer("list_set", uin, mask)
    end
    FirstMaskEvent:FireServer("whitelist")
end

function _G._wls(str, mask)
	local list = {}
	for line in str:gmatch("[^\r\n]+") do
		list[#list+1] = tonumber(line)
	end
	print("add:", unpack(list))
    FirstMaskEvent:FireServer("list_sets", list, mask)
end
