local WorkSpace = game:GetService("Workspace")
local WorldService = game:GetService("WorldService")
local CoreUI = game:GetService("CoreUI")

local Utils = {}

function Utils.ShallowCopy(orig, customCopy)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = Utils.ShallowCopy(orig_value, customCopy)
        end
    else -- number, string, boolean, etc
        if customCopy then
            copy = customCopy(orig)
        else
            copy = orig
        end
    end
    return copy
end

function Utils.DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function Utils.str_split(str, sep)
    local tb = {}
    local i = 1
    while true do
        local j = str:find(sep, i)
        if j then
            table.insert(tb, str:sub(i, j - 1))
            i = j + #sep
        else
            table.insert(tb, str:sub(i))
            break
        end
    end
    return tb
end

function Utils.PrintTable(tbl)
    local function _print(value, indent)
        indent = indent or 0
        local shortIndent = string.rep(" ", indent)
       print(shortIndent .. "{")

        indent = indent + 2
        local longIndent = string.rep(" ", indent)

        for k, v in pairs(value) do
            if type(v) == "table" then
               print(longIndent .. k .. "= ")
                _print(v, indent + 2)
            else
               print(longIndent .. k .. ": " .. tostring(v))
            end
        end

       print(shortIndent .. "}")
    end
    _print(tbl)
end

-- LineTrace function
-- 尝试得到鼠标点击的位置的地面位置
function Utils.TryGetRaycastUnderCursor(mouseInputObject, depth, ignoreTrigger, filterGroup)
    local mousePositionX = mouseInputObject.Position.x
    local mousePositionY = mouseInputObject.Position.y
    local viewportSize = WorkSpace.CurrentCamera.ViewportSize
    local ray = WorkSpace.CurrentCamera:ViewportPointToRay(mousePositionX, viewportSize.y - mousePositionY, depth)
    local ret_table = WorldService:RaycastClosest(ray.Origin, ray.Direction, depth, ignoreTrigger, filterGroup)

    if ret_table.isHit == false then
        depth = 1500
        ret_table.position = ray.Origin + ray.Direction * depth
    end

    if ret_table.isHit == true and ret_table.distance < 200 then
        depth = 200
        ret_table.position = ray.Origin + ray.Direction * depth
    end

    return ret_table
end

-- 创建玩家头像
-- @param uin 玩家uin
-- @param size vector2 头像大小
-- @param offset vector2 头像偏移
-- @return 头像节点
function Utils.CreatePlayerHeadIconNode(uin, size, offset)
    offset = offset or vector2.new(0, 0)
    local headNode = CoreUI:GetHeadNode(tostring(uin))
    if headNode then
        headNode.Size = size
        headNode.Position = offset
        headNode.Pivot = Vector2.new(0, 0)
        headNode.IsNotifyEventStop = false

        local MaskImage = SandboxNode.New('UIImage')
        MaskImage.Name = "MaskImage"
        MaskImage.Parent = headNode
        MaskImage.Icon = "sandboxId://PVZ_UI/Common/Bg/Bg_Common_Profile_Dec.png"
        MaskImage.Size = size
        MaskImage.Position = offset
        MaskImage.Pivot = Vector2.new(0, 0)
        MaskImage.IsNotifyEventStop = false
        MaskImage.UIMaskMode = true
    end
    return headNode
end

return Utils
