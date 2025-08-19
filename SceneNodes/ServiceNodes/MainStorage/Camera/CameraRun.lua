local CameraRun = {}
local MOVE_INTERVAL = 0.1
local TweenService = game:GetService("TweenService")
local SunLight = game.WorkSpace.Environment.SunLight

local function createLightTween(light, time, func)
    local tweenInfo = TweenInfo.New(time, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, 1, false)
	local tween = TweenService:Create(SunLight, tweenInfo, {Intensity=light})
    tween.Completed:Connect(function()
        tween:Destroy()
        if func then
            func()
        end
    end)
    tween:Play()
end

local function nextFlash(count, light)
    if count<=0 then
        wait(math.random()*10)
        light = math.random() + 1.5
        count = math.random(1, 4)
    else
        light = math.random() * (light - 1) + 1
    end
    SunLight.Intensity = light
    wait(0.05)
    local time = math.random() * 0.15 + 0.05
    createLightTween(0.8, time, function()
        nextFlash(count - 1, light)
    end)
end

function CameraRun:Init()
	local Root = nil
	for _, node in ipairs(game.WorkSpace.Children) do
        Root = node.CameraTransport
		if Root then
			break
		end
	end
    self.Root = Root
    nextFlash(1, 0.8)
end

local function calc_curve_value(values, t)
    local n = #values
    if n == 2 then
        return values[1] * (1 - t) + values[2] * t
    end
    local new_values = {}
    for i = 1, n-1 do
        table.insert(new_values, values[i] * (1 - t) + values[i+1] * t)
    end
    return calc_curve_value(new_values, t)
end

local function calc_angle(f, t)
    local d = t - f
    if d > 180 then
        d = d - 360
    elseif d < -180 then
        d = d + 360
    end
    return f + d
end

function CameraRun:GoNext(index, points, time, total_time)
    if time >= total_time then
        points = {}
        total_time = 0
        time = 0
        while true do
            local point = self.Nodes[index]
            table.insert(points, point)
            if points[2] then   -- 不是第一个点
                total_time = total_time + point:GetAttribute("Time")
                if not point:GetAttribute("Curve") then
                    break
                end
                assert(#points < 10)    -- 全是曲线的情况下，防止死循环
            end
            index = index + 1
            if not self.Nodes[index] then
                if self.isLoop then
                    index = 1
                else
                    if self.OnComplete then
                        self.OnComplete()
                    end
                    return
                end
            end
        end
    end
    if time == 0 then
        self.Camera.Position = points[1].Position
        self.Camera.Euler = points[1].Euler
    end
    local end_time = time + MOVE_INTERVAL
    if end_time > total_time then
        end_time = total_time
    end
    local poss = {}
    local eulers = {}
    local le = Vector3.new(0,0,0)
    for _, point in ipairs(points) do
        table.insert(poss, point.Position)
        local ne = point.Euler
        le = Vector3.new(calc_angle(le.X, ne.X), calc_angle(le.Y, ne.Y), calc_angle(le.Z, ne.Z))
        table.insert(eulers, le)
    end
    local pos = calc_curve_value(poss, end_time / total_time)
    local euler = calc_curve_value(eulers, end_time / total_time)
    local fe = self.Camera.Euler
    local te = Vector3.new(calc_angle(fe.X, euler.X), calc_angle(fe.Y, euler.Y), calc_angle(fe.Z, euler.Z))
    local tween_info = TweenInfo.New(end_time - time, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, 0, false)
	local tween = TweenService:Create(self.Camera, tween_info, {Position = pos, Euler = te})
	tween.Completed:Connect(function()
        tween:Destroy()
        if self.tween == tween then
            self.tween = nil
        end
		if self.Camera then
			self:GoNext(index, points, end_time, total_time)
		end
	end)
    self.tween = tween
	tween:Play()
end

function CameraRun:Start(name, isLoop, funcCallBack)
    print("CameraRun:Start", name)
    CameraRun:Init()
    if not self.Root then
        return
    end
    self.isLoop = isLoop
    self.OnComplete = funcCallBack
    local Route = self.Root[name]
    if not Route then
        print("CameraRun:Start Route not found")
        return
    end
    self.Nodes = Route.Children
    if not self.Nodes[1] then
        print("CameraRun:Start Nodes not found")
        return
    end
    self.Camera = game.WorkSpace.CurrentCamera
    self.Camera.CameraType = Enum.CameraType.Scriptable
    self:GoNext(1, {}, 0, 0)
end

function CameraRun:GetPoint(name, pointName)
    CameraRun:Init()
    if not self.Root then
        return nil
    end
    local Route = self.Root[name]
    if not Route then
        return nil
    end
    return Route[pointName]
end

function CameraRun:Stop()
    self.Camera = nil
    self.Nodes = nil
    if self.tween then
        self.tween:Destroy()
        self.tween = nil
    end
end

return CameraRun
