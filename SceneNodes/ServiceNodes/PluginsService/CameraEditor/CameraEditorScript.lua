local TweenService = game:GetService("TweenService")

_G._works = {}	-- 用来标记是否运行中（同时应对reload的情况）
local function create_work(interval, func, name)
	local work = {}
	_G._works[work] = true
	function work:start(...)
		print("work start", name or func, ...)
		while self:running() do
			func(...)
			wait(interval)
		end
		print("work end", name or func)
	end
	function work:stop()
		_G._works[self] = nil
	end
	function work:running()
		return _G._works[self]
	end
	return work
end

local Root = nil
local Route = nil
local Lines = nil
local function get_or_create(name)
    local node = Root[name]
    if not node then
        node = SandboxNode.new("Transform", Root)
        node.Name = name
    end
    return node
end
local function check_nodes()
	Root = nil
    Route = nil
    Lines = nil
	for _, node in ipairs(game.WorkSpace.Children) do
        Root = node.CameraTransport
		if Root then
			break
		end
	end
    if not Root then
        Root = game.WorkSpace
        Root = get_or_create("CameraTransport")
    end
    if not _G._route_name then
        Lines = Root.Lines
        return
    end
	Route = get_or_create(_G._route_name)
	if #Root.Children == 0 then
		return
	end
	Lines = get_or_create("Lines")
end

plugin:AddContextMenuButton("[创建路径点]", "Camera").Click:Connect(function()
    check_nodes()
    if not Route then
        if Root then
            print("请先选择一条路径（插件上右键菜单）")
        end
        return
    end
    local point = SandboxNode.new("GeoSolid", Route)
    for i = 1, 999 do
        local name = string.format("Point%03d", i)
        if not Route[name] then
            point.Name = name
            break
        end
    end
    local camera = game.WorkSpace.CurrentCamera
    point.GeoSolidShape = Enum.GeoSolidShape.Cuboid
    point.MaterialType = Enum.MaterialTemplate.LambertBlend
    point.Color = ColorQuad.new(255, 255, 80, 255)
    point.Position = camera.Position
    point.Euler = camera.Euler
    point:AddAttribute("Curve", Enum.AttributeType.Bool)
    point:SetAttribute("Curve", false)
    point:AddAttribute("Time", Enum.AttributeType.Number)
    point:SetAttribute("Time", 1)
    print("创建路径点：" .. point.Name)
end)

plugin:AddContextMenuButton("[镜头->此处]", "GeoSolid").Click:Connect(function()
    local camera = game.WorkSpace.CurrentCamera
    local node = plugin:Selection()
    if not node then
        return
    end
    camera.Position = node.Position
    camera.Euler = node.Euler
end)

plugin:AddContextMenuButton("[镜头<-此处]", "GeoSolid").Click:Connect(function()
    local camera = game.WorkSpace.CurrentCamera
    local node = plugin:Selection()
    if not node then
        return
    end
    node.Position = camera.Position
    node.Euler = camera.Euler
end)

local created_nodes = {}
local draw_line_worker = nil
local last_lines = {}
local new_lines = {}
local MOVE_INTERVAL = 0.1
local points_loop = false
local function line_clear()
    check_nodes()
	if Lines then
		--Lines:DestroyAllChildren()
		Lines:ClearAllChildren()
	end
	if draw_line_worker then
		draw_line_worker:stop()
		draw_line_worker = nil
	end
    last_lines = {}
    new_lines = {}
end
local function fix_stick(stick, from, to)
    local d = to - from
	local len = d.Length
	if len < 1 then
		len = 1
	end
	local dir = d:Normalize()
	local c = 180 / math.pi
	stick.LocalScale = Vector3.new(0.2, len/120, 0.2)
	stick.Position = from + dir * (len / 2)
	stick.Euler = Vector3.new(math.atan2(dir.Z, dir.Y)*c, 0, math.asin(-dir.X)*c)
end
local function calc_curve_pos(poss, t)
    local n = #poss
    if n == 2 then
        return poss[1] * (1 - t) + poss[2] * t
    end
    local new_poss = {}
    for i = 1, n-1 do
        table.insert(new_poss, poss[i] * (1 - t) + poss[i+1] * t)
    end
    return calc_curve_pos(new_poss, t)
end
local function fix_line(line)
    local stick_index = 0
    local function next_stick()
        stick_index = stick_index + 1
        local stick = line.sticks[stick_index]
        if not stick then
            stick = SandboxNode.new("GeoSolid", Lines)
            stick.Name = line.name.."-"..stick_index.."-stick"
            stick.GeoSolidShape = Enum.GeoSolidShape.Cylinder
            stick.Color = ColorQuad.new(255, 255, 100, 255)
            line.sticks[stick_index] = stick
        end
        return stick
    end
    local poss = {}
    for _, point in ipairs(line.points) do
        table.insert(poss, point.Position)
    end
    local time = MOVE_INTERVAL
    local last_pos = poss[1]
    while time<line.time do
        local pos = calc_curve_pos(poss, time / line.time)
        fix_stick(next_stick(), last_pos, pos)
        last_pos = pos
        time = time + MOVE_INTERVAL
    end
    fix_stick(next_stick(), last_pos, poss[#poss])
    local old_count = #line.sticks
    for i = stick_index+1, old_count do
        line.sticks[i]:Destroy()
        line.sticks[i] = nil
    end
end
local function get_point(point)
	local id = point.ID
	local point_info = created_nodes[id]
	if not point_info then
		point_info = {
			point = point,
			lines = {},
		}
		created_nodes[id] = point_info
		point_info.attr_event = point.AttributeChanged:Connect(function(name)
			if name=="Position" then
				local info = created_nodes[id]
				for _, line in ipairs(info.lines) do
					fix_line(line)
				end
			end
		end)
		point_info.parent_event = point.ParentChanged:Connect(function(parent)
			if not parent then
				local info = created_nodes[id]
				info.attr_event:Disconnect()
				info.parent_event:Disconnect()
				created_nodes[id] = nil
			end
		end)
	end
	return point_info
end
local function line_create(points, total_time)
    if #points < 2 then
        return
    end
    local key = ""
    for _, point in ipairs(points) do
        key = key..point.ID.."-"
    end
	local line = last_lines[key]
	if line then
		last_lines[key] = nil
	else
		line = {
            name = points[1].Name,
			points = points,
            sticks = {},
            time = total_time,
		}
        fix_line(line)
	end
	new_lines[key] = line
    for _, point in ipairs(points) do
        table.insert(get_point(point).lines, line)
    end
end
local function get_line_list()
    local list = {}
    local points = {}
    local total_time = 0
    local children = Route.Children
    if points_loop then
        table.insert(children, children[1])
    end
    for i, point in ipairs(children) do
        local curve = point:GetAttribute("Curve")
        table.insert(points, point)
        if i > 1 then
            total_time = total_time + point:GetAttribute("Time")
        end
        if not curve and points[2] then
            table.insert(list, {points=points, total_time=total_time})
            points = {point}
            total_time = 0
        end
    end
    -- 如果以曲线结尾（配置错），弥补一下
    if points[2] then
        table.insert(list, {points=points, total_time=total_time})
    end
    return list
end
local function draw_line_tick()
	check_nodes()
    if not Route then
        return
    end
	for id, node_info in pairs(created_nodes or {}) do
		node_info.lines = {}
	end
    local line_list = get_line_list()
    for _, line_info in ipairs(line_list) do
        line_create(line_info.points, line_info.total_time)
    end
	
    for _, line in pairs(last_lines) do
        for _, stick in ipairs(line.sticks) do
            stick:Destroy()
        end
	end
    last_lines = new_lines
	new_lines = {}
end

plugin:AddContextMenuButton("⬇️运行状态⬇️")
local function check_btn(name, func)
    local check_status = false
    local btn = plugin:AddContextMenuButton("⬛️"..name)
    local function switch()
        check_status = not check_status
        btn.Text = (check_status and "✅" or "⬛️")..name
        func(check_status)
    end
    btn.Click:Connect(switch)
    return btn
end

check_btn("循环播放", function(status)
    points_loop = status
end)

check_btn("绘制轨迹线", function(status)
    line_clear()
    if status then
        draw_line_worker = create_work(0.2, draw_line_tick, "draw_line_tick")
        draw_line_worker:start()
    end
end)

local Camera = nil
local move_camera_worker = nil
local status_btns = {}
local function cmaera_clear()
    check_nodes()
	if Root and Root.Camera then
		Root.Camera.Visible = false
	end
    Camera = nil
    if move_camera_worker then
        move_camera_worker:stop()
        move_camera_worker = nil
    end
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
local function check_move_status()
    local status = 1
    if move_camera_worker and move_camera_worker:running() then
        if Camera == game.WorkSpace.CurrentCamera then
            status = 3
        else
            status = 2
        end
    end
    status_btns[1].Text = (1 == status and "✅" or "⬛️").."停止运行"
    status_btns[2].Text = (2 == status and "✅" or "⬛️").."模拟运行"
    status_btns[3].Text = (3 == status and "✅" or "⬛️").."真实运行"
    return status
end
local function move_camera_next(worker, line_info, line_index, time)
    local total_time = line_info.total_time
    if time >= total_time then
        local line_list = get_line_list()
        line_index = line_index + 1
        line_info = line_list[line_index]
        if not line_info and points_loop then
            line_index = 1
            line_info = line_list[line_index]
        end
        total_time = line_info and line_info.total_time or 0
        time = 0
    end
    if not line_info then
        worker:stop()
        if move_camera_worker == worker then
            move_camera_worker = nil
        end
        check_move_status()
        return
    end
    if time == 0 then
        Camera.Position = line_info.points[1].Position
        Camera.Euler = line_info.points[1].Euler
    end
    local end_time = time + MOVE_INTERVAL
    if end_time > total_time then
        end_time = total_time
    end
    local poss = {}
    local eulers = {}
    local le = Vector3.new(0,0,0)
    for _, point in ipairs(line_info.points) do
        table.insert(poss, point.Position)
        local ne = point.Euler
        le = Vector3.new(calc_angle(le.X, ne.X), calc_angle(le.Y, ne.Y), calc_angle(le.Z, ne.Z))
        table.insert(eulers, le)
    end
    local pos = calc_curve_pos(poss, end_time / total_time)
    local euler = calc_curve_pos(eulers, end_time / total_time)
    local fe = Camera.Euler
    local te = Vector3.new(calc_angle(fe.X, euler.X), calc_angle(fe.Y, euler.Y), calc_angle(fe.Z, euler.Z))
    local tween_info = TweenInfo.New(end_time - time, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, 0, false)
	local tween = TweenService:Create(Camera, tween_info, {Position = pos, Euler = te})
	tween.Completed:Connect(function()
		if worker:running() then
			move_camera_next(worker, line_info, line_index, end_time)
		end
	end)
	tween:Play()
end
local function move_camera_start(status)
    cmaera_clear()
    if status == 1 then
        return
    end
    if not Route then
        print("请先选择一条路径（插件上右键菜单）")
        return
    end
    if status == 2 then
        Camera = get_or_create("Camera")
        Camera.Visible = true
        if not Camera.Children[1] then
            local geo = SandboxNode.new("GeoSolid", Camera)
            geo.Name = "CameraCone"
            geo.GeoSolidShape = Enum.GeoSolidShape.Cone
            geo.Color = ColorQuad.new(255, 255, 0, 255)
            geo.LocalScale = Vector3.new(2, 2, 2)
            geo.LocalPosition = Vector3.new(0, 0, 100)
            geo.LocalEuler = Vector3.new(-90, 0, 0)
        end
    else
        Camera = game.WorkSpace.CurrentCamera
    end
    local line_list = get_line_list()
    if not line_list[1] then
        print("请先创建路径点")
        return
    end
    move_camera_worker = create_work(0, "move_camera")
    move_camera_next(move_camera_worker, line_list[1], 1, 0)
end
for i = 1, 3 do
    local btn = plugin:AddContextMenuButton()
    status_btns[i] = btn
    btn.Click:Connect(function()
        move_camera_start(i)
        check_move_status()
    end)
end
check_move_status()

local name_buttons = {}
local function refresh_routes()
    check_nodes()
    if not Root then
        return
    end
    local names = {}
    for _, node in ipairs(Root.Children) do
        local name = node.Name
        if name ~= "Lines" and name ~= "Camera" then
            names[name] = true
            local btn = name_buttons[name]
            if not btn then
                btn = plugin:AddContextMenuButton(title)
                name_buttons[name] = btn
                btn.Click:Connect(function()
                    if (_G._route_name == name) then
                        _G._route_name = nil
                        check_nodes()
                    else
                        _G._route_name = name
                    end
                end)
            end
            btn.Text = (name == _G._route_name and "➡️" or "⬛️")..name
        end
    end
    for name, btn in pairs(name_buttons) do
        if not names[name] then
            plugin:RemoveContextMenuButton(btn)
            name_buttons[name] = nil
        end
    end
end

plugin:AddContextMenuButton("⬇️选择一条路径（先创建）⬇️")

wait(1) -- 避免运行状态切换瞬间的混乱问题
line_clear()
cmaera_clear()

create_work(1, refresh_routes, "refresh_routes"):start()
