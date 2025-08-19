local MainStorage = game:GetService("MainStorage")
local WorldService = game:GetService("WorldService")

local Math = require(MainStorage.Common.Math)
local Vec3 = Math.Vec3
local Quat = Math.Quat

local TargetUtils = {}

--选择box内的目标
function TargetUtils:OverlapBox(center, extent, angle, filterGroup, filterFunc)
    local results =
        WorldService:OverlapBox(
        Vector3.New(extent.x, extent.y, extent.z),
        Vector3.New(center.x, center.y, center.z),
        Vector3.New(angle.x, angle.y, angle.z),
        false,
        filterGroup
    )

    local retActors = {}
    for _, v in ipairs(results) do
        local obj = v.obj
        table.insert(retActors, obj)
        if filterFunc then
            filterFunc(obj)
        end
    end
    return retActors
end

--将结果按近到远排序
-- function TargetUtils:SortByNear(actors, orginPos)
--     table.sort(
--         actors,
--         function(a, b)
--             local disA = a.AvatarComponent:GetPosition():Distance(orginPos)
--             local disB = b.AvatarComponent:GetPosition():Distance(orginPos)
--             return disA < disB
--         end
--     )
-- end

--选择圆柱内的目标
function TargetUtils:SelectCylinderTargets(center, radius, height, filterGroup, filterFunc)
    if radius == 0 or height == 0 then
        return {}
    end
    local cylinderFilter = function(bindActor)
        --判断是否在半径内，忽略y坐标
        local centerPos = center
        local targetPos = bindActor.Position
        centerPos.y = 0
        targetPos.y = 0
        local distance = (centerPos - targetPos).length
        if distance > radius then
            return false
        end
        if filterFunc then
            return filterFunc(bindActor)
        end
        return true
    end
    local halfHeight = height / 2
    local results =
        self:OverlapBox(
        Vec3.new(center.x, center.y + halfHeight, center.z),
        Vec3.new(radius, halfHeight, radius),
        Vec3.new(0, 0, 0),
        filterGroup,
        cylinderFilter
    )
    return results
end

--选择扇形内目标
function TargetUtils:SelectFanTargets(center, direction, radius, height, angle, filterGroup, filterFunc)
    if radius == 0 or height == 0 then
        return {}
    end
    local fanFilter = function(bindActor)
        --判断是否在扇形内
        local targetPos = bindActor.Position
        local dir = targetPos - center
        dir:Normalize()
        if direction:AngleBetween(dir) > angle / 2 then
            return false
        end
        if filterFunc then
            return filterFunc(bindActor)
        end
        return true
    end
    local results = self:SelectCylinderTargets(center, radius, height, filterGroup, fanFilter)
    return results
end

--选择一条线上的目标
function TargetUtils:SelectLineTargets(startPos, dir, distance, width, height, filterGroup, filterFunc)
    if width == 0 then
        return {}
    end
    local startPoint = startPos
    -- - dir * width / 2
    local endPoint = startPos + dir * distance --(distance + width / 2)
    -- endOffset.y  = height
    local halfOffset = Vec3.new(0, 0, distance / 2)
    local lineFilter = function(bindActor)
        local actorPos = bindActor.Position
        actorPos.y = startPoint.y
        local lineDis = actorPos:DistanceToLine(startPoint, endPoint)
        if lineDis > width / 2 then
            return false
        end
        if filterFunc then
            return filterFunc(bindActor)
        end
        return true
    end
    local lookDir = dir:Clone()
    lookDir.y = 0
    local orient = Quat.new()
    orient:FromLookRotation(lookDir, Vec3.new(0, 1, 0))
    local euler = orient:ToEuler()
    local orgin = startPos + orient * halfOffset
    local radius = (distance + width) / 2

    local results =
        self:OverlapBox(orgin, Vec3.new(radius, height / 2, radius), Vec3.new(0, 0, 0), filterGroup, lineFilter)
    return results
end

return TargetUtils
