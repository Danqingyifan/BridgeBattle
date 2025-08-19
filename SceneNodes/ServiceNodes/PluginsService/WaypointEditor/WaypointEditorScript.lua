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
local Points = nil
local Lines = nil
local Sims = nil
local is_ready = false
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
	Points = nil
	Lines = nil
	Sims = nil
	for _, node in ipairs(game.WorkSpace.Children) do
		Root = node.Waypoint
		if Root then
			break
		end
	end
	if not Root then
		if not is_ready then
			return
		end
        Root = game.WorkSpace
        Root = get_or_create("Waypoint")
	end
	Points = get_or_create("Points")
	if #Points.Children == 0 then
		return
	end
	Lines = get_or_create("Lines")
	Sims = get_or_create("Sims")
end

local function status_select(title, list, func)
	plugin:addContextMenuButton(title)
	local buttons = {}
	local old_list = {}
	local selectd = nil
	local function update()
		for i, name in ipairs(list) do
			if i == selectd then
				buttons[i].Text = "✅"..name
			else
				buttons[i].Text = "⬛️"..name
			end
		end
	end
	local function select(n)
		selectd = n
		update()
		func(n)
	end
	local function fix_list(new_list)
		for i, v in ipairs(new_list) do
			local btn = buttons[i]
			if not btn then
				btn = plugin:addContextMenuButton()
				btn.Click:Connect(function()
					select(i)
				end)
				buttons[i] = btn
			end
		end
		for i = #buttons, #new_list + 1, -1 do
			plugin:RemoveContextMenuButton(buttons[i])
			buttons[i] = nil
		end
		update()
	end
	fix_list(list)
	return select, fix_list
end

local import_all_csv	-- 后面定义
plugin:addContextMenuButton("🚀导入刷怪CSV").Click:Connect(function() import_all_csv() end)

--==辅助线==--
local created_nodes = {}
local line_worker = nil
local last_lines = {}
local new_lines = {}
local function line_stop()
	check_nodes()
	if Lines then
		--Lines:DestroyAllChildren()
		Lines:ClearAllChildren()
	end
	if line_worker then
		line_worker:stop()
		line_worker = nil
	end
end
local function line_getsize(node)
	local size = node.LocalScale.X
	if node.LocalScale.Y < size then
		size = node.LocalScale.Y
	end
	if node.LocalScale.Z < size then
		size = node.LocalScale.Z
	end
	return size * 100
end
local function line_fixpos(info)
	local from = info.from
	local to = info.to
	local stick = info.stick
	local arrow = info.arrow
	local len = (from.Position - to.Position).Length
	local from_size = line_getsize(from)
	local to_size = line_getsize(to)
	local slen = len-(to_size+from_size)/2-100
	if slen < 1 then
		slen = 1
	end
	local dir = (to.Position - from.Position):Normalize()
	local c = 180 / math.pi
	local euler = Vector3.new(math.atan2(dir.Z, dir.Y)*c, 0, math.asin(-dir.X)*c)
	stick.LocalScale = Vector3.new(0.2, slen/120, 0.2)
	stick.Position = from.Position + dir * ((slen + from_size) / 2)
	stick.Euler = euler
	arrow.LocalScale = Vector3.new(0.5, 1, 0.5)
	arrow.Position = to.Position - dir * (to_size / 2 + 60)
	arrow.Euler = euler
end
local function line_getnode(node)
	local id = node.ID
	local node_info = created_nodes[id]
	if not node_info then
		node_info = {
			node = node,
			lines = {},
		}
		created_nodes[id] = node_info
		node_info.attr_event = node.AttributeChanged:Connect(function(name)
			if name=="Position" then
				local info = created_nodes[id]
				if info then
					for _, line in ipairs(info.lines) do
						line_fixpos(line)
					end
				end
			end
		end)
		node_info.parent_event = node.ParentChanged:Connect(function(parent)
			if not parent then
				local info = created_nodes[id]
				info.attr_event:Disconnect()
				info.parent_event:Disconnect()
				created_nodes[id] = nil
				local error_node = Lines and Lines["ERROR_"..id]
				if error_node then
					error_node:Destroy()
				end
			end
		end)
	end
	return node_info
end
local function line_create_one(from, to)
	local key = from.ID.."-"..to.ID
	if new_lines[key] then
		return
	end
	local line = last_lines[key]
	if line then
		last_lines[key] = nil
	else
		line = {
			from = from,
			to = to,
		}
		-- 创建线
		line.stick = SandboxNode.new("GeoSolid", Lines)
		line.stick.Name = from.Name.."-"..to.Name.."-stick"
		line.stick.GeoSolidShape = Enum.GeoSolidShape.Cylinder
		line.stick.Color = ColorQuad.new(255, 255, 0, 255)
		-- 创建箭头
		line.arrow = SandboxNode.new("GeoSolid", Lines)
		line.arrow.Name = from.Name.."-"..to.Name.."-arrow"
		line.arrow.GeoSolidShape = Enum.GeoSolidShape.Cone
		line.arrow.Color = ColorQuad.new(255, 255, 0, 255)
		line_fixpos(line)
	end
	new_lines[key] = line
	table.insert(line_getnode(from).lines, line)
	table.insert(line_getnode(to).lines, line)
end
local function line_tick(all)
	check_nodes()
	if not Root then
		return
	end
	for id, node_info in pairs(created_nodes or {}) do
		node_info.lines = {}
	end
	local names = {}
	for _, node in ipairs(all and Points.Children or {plugin:Selection()}) do
		if node.Parent==Points then
			names[node.Name] = node
		end
	end
	for _, node in ipairs(Points.Children) do
		-- 本节点是选中的：显示所有
		-- 本节点不是选中的：只显示能连接到选中的
		local nodes = (names[node.Name] == node) and Points or names
		local err = {}
		for _, sub in ipairs(node.Children) do
			if sub:IsA("String") then
				local nn = nodes[sub.Name]
				if nn then
					line_create_one(node, nn)
				else
					table.insert(err, sub.Name)
				end
			end
		end
		local err_key = "ERROR_"..node.ID
		local err_node = Lines[err_key]
		if err[1] then
			if not err_node then
				err_node = SandboxNode.new("UIRoot3D", Lines)
				err_node.Name = err_key
				local txt = SandboxNode.new("UITextLabel", err_node)
				txt.Name = "Text"
				txt.TextVAlignment = Enum.TextVAlignment.Center
				txt.TextHAlignment = Enum.TextHAlignment.Center
				txt.FontSize = 36
				txt.TitleColor = ColorQuad.new(255, 0, 0, 255)
				txt.IsAutoSize = Enum.AutoSizeType.BOTH
			end
			err_node.Position = node.Position + Vector3.new(0, 60, 0)
			err_node.Euler = node.Euler
			err_node.Text.Title = table.concat(err, "\r\n")
		elseif err_node then
			err_node:Destroy()
		end
	end
	for _, line in pairs(last_lines) do
		line.stick:Destroy()
		line.arrow:Destroy()
	end
	last_lines = new_lines
	new_lines = {}
end
local function line_start(status)
	line_stop()
	if status == 1 then
		return
	end
	line_worker = create_work(0.1, line_tick, "line")
	line_worker:start(status == 3)
	for _, node_info in pairs(created_nodes) do
		node_info.attr_event:Disconnect()
		node_info.parent_event:Disconnect()
	end
	last_lines = {}
	new_lines = {}
	created_nodes = {}
end

status_select("⬇️辅助线⬇️", {"不显示", "显示选中", "显示全部"}, line_start)(1)

--==模拟怪==--
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SPEED_MAP = {
	run = 200,
	jump = 400,
	climb = 20,
	default = 100,
}
local SPAWN_SPEED = 10	-- 生成速度（每秒）
local BLOCK_WIDTH = 100	-- 阻挡宽度
local BLOCK_DEEPTH = 30	-- 阻挡厚度
local BLOCK_HEIGHT = 80	-- 阻挡高度
local BLOCK_CAP = 2		-- 阻挡容量
local sim_worker = nil
local sim_count = 0
local sim_block_zombie = {}
local sim_spawn_list = {}
local function sim_stop()
	check_nodes()
	if Sims then
		--Sims:DestroyAllChildren()
		Sims:ClearAllChildren()
	end
	if sim_worker then
		sim_worker:stop()
		sim_worker = nil
	end
	sim_node_zombie = {}
end
local function sim_get_rand(list)
	if #list<=1 then
		return list[1]
	end
	local total = 0
	for _, tb in ipairs(list) do
		total = total + tb[1]
	end
	local r = math.random(total)
	for _, tb in ipairs(list) do
		r = r - tb[1]
		if r <= 0 then
			return tb
		end
	end
end
local function _get_t(t, key, ...)
	if not key then
		return t
	end
	local v = t[key]
	if v==nil then
		return nil
	end
	return _get_t(v, ...)
end
local function _set_t(t, value, key, key2, ...)
	if not key2 then
		t[key] = value
		return
	end
	local v = t[key]
	if not v then
		v = {}
		t[key] = v
	end
	_set_t(v, value, key2, ...)
end
local sim_next
local function sim_tween_to(node, sim, worker, pos, speed, euler)
	local obj = sim.obj
	local vd = pos - obj.Position
	local tween_info = TweenInfo.New(vd.Length / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, 0, false)
	local tween = TweenService:Create(obj, tween_info, {Position = pos})
	if euler then
		obj.Euler = euler
	else
		local dir = vd:Normalize()
		obj.Euler = Vector3.new(0, math.atan2(dir.X, dir.Z)*180/math.pi, 0)
	end
	tween.Completed:Connect(function()
		if worker:running() then
			sim_next(node, sim, worker)
		end
	end)
	tween:Play()
end
local function sim_stack_check(id, x, y, z, my, mz)
	local function _get_count(y_, z_)
		return _get_t(sim_block_zombie, id, x, y_, z_, "count") or 0
	end
	-- 坠落检测
	for fy = 0, y - 1 do
		if _get_count(fy, z) < BLOCK_CAP then
			return y - 1, z
		end
	end
	-- 当前块
	local cur = _get_count(y, z)
	-- 前方检测
	if z < mz then
		if _get_count(y, z + 1) < BLOCK_CAP
			or _get_count(y + 1, z + 1) < BLOCK_CAP
			or _get_count(y + 2, z + 1) < BLOCK_CAP then
			return y, z + 1
		end
	elseif y >= my then
		return nil, nil	-- 堆叠完成
	end
	if cur <= BLOCK_CAP then	-- 当前块未超饱和，不动
		return y, z
	elseif y < my then	-- 攀爬
		return y + 1, z
	else
		return y, z
	end
end
local function sim_stack_next(node, sim, worker)
	if sim.block then
		sim.block.count = sim.block.count - 1
		sim.block = nil
	end
	local obj = sim.obj
	local id = node.ID
	local rot = node.Rotation
	rot.X = -rot.X
	rot.Y = -rot.Y
	rot.Z = -rot.Z
	local pos = rot * (obj.Position - node.Position)
	local size = node.LocalScale * 100
	local ly = 50 - size.Y / 2
	local x = math.floor(pos.X / BLOCK_WIDTH)
	local y = math.floor((pos.Y - ly) / BLOCK_HEIGHT)
	local z = math.floor(pos.Z / BLOCK_DEEPTH)
	local my = math.floor((size.Y / 2 - 50 - ly) / BLOCK_HEIGHT)
	local mz = math.floor((size.Z - 100) / 2 / BLOCK_DEEPTH)
	local ty, tz = sim_stack_check(id, x, y, z, my, mz)
	--print("stack", id, "pos", pos, "=>", x, y, z, "=>", ty, tz, "@", ly, my, mz)
	if not ty then
		return false
	end
	block = _get_t(sim_block_zombie, id, x, ty, tz)
	if not block then
		block = {count = 0}
		_set_t(sim_block_zombie, block, id, x, ty, tz)
	end
	block.count = block.count + 1
	sim.block = block
	local toY
	if ty <= 0 and tz > z then
		toY = ly
	elseif ty == y and tz > z then
		toY = pos.Y
	else
		toY = ly + (ty + math.random() * 0.5) * BLOCK_HEIGHT
	end
	local toZ
	if tz >= mz then
		toZ = (size.Z - 100) / 2
	elseif tz > z then
		toZ = (tz + math.random()) * BLOCK_DEEPTH
	else
		toZ = pos.Z
	end
	local mX = (size.X - 100) / 2
	local toX = (math.random() * 0.3 - 0.15) * BLOCK_WIDTH + pos.X
	if toX < -mX then
		toX = -mX
	elseif toX > mX then
		toX = mX
	end
	obj.Text.Title = sim.name .. "\n~~~"
	local toPos = node.Rotation * Vector3.new(toX, toY, toZ) + node.Position
	local speed = ty < y and SPEED_MAP.jump or SPEED_MAP.climb
	sim_tween_to(node, sim, worker, toPos, speed, node.Euler)
	return true
end
function sim_next(node, sim, worker)
	if node.LocalScale.Y > 1 then	-- 堆叠攀爬
		if sim_stack_next(node, sim, worker) then
			return
		end
	end
	local obj = sim.obj
	local id = node.ID
	local list = {}
	for _, sub in ipairs(node.Children) do
		if sub:IsA("String") then
			local v = sub.Tag
			if v <= 0 then
				v = 1
			end
			table.insert(list, {v, sub.Name, sub.Value})
		end
	end
	local tb = sim_get_rand(list)
	if not tb then
		obj:Destroy()
		return
	end
	local act = tb[3]
	obj.Text.Title = sim.name .. "\n" .. act
	local nn = Points[tb[2]]
	if act=="attack" then
		local dir = (nn.Position - obj.Position):Normalize()
		obj.Euler = Vector3.new(0, math.atan2(dir.X, dir.Z)*180/math.pi, 0)
		wait(1)
		if worker:running() then
			obj:Destroy()
		end
		return
	end
	local size = nn.LocalScale
	local posX = 0
	local posZ = 0
	local posY = 50 - size.Y / 2 * 100
	if size.X > 1 then
		posX = sim.randX * (size.X - 1)
	end
	if size.Z > 1 then
		posZ = sim.randZ * (size.Z - 1)
	end
	local d = nn.Euler.Y * math.pi / 180
	local pos = nn.Position + Vector3.new(posX * math.cos(d) + posZ * math.sin(d), posY, posZ * math.cos(d) - posX * math.sin(d))
	local speed = SPEED_MAP[act] or SPEED_MAP.default
	sim_tween_to(nn, sim, worker, pos, speed)
end
local function sim_spawn(node, worker, name)
	name = name or "Sim"
	sim_count = sim_count + 1
	local obj = SandboxNode.new("UIRoot3D", Sims)
	obj.Name = name .. sim_count
	obj.Position = node.Position
	local txt = SandboxNode.new("UITextLabel", obj)
	txt.Name = "Text"
	txt.TextVAlignment = Enum.TextVAlignment.Center
	txt.TextHAlignment = Enum.TextHAlignment.Center
	txt.FontSize = 36
	local sim = {
		name = name,
		obj = obj,
		randX = math.random() * 100 - 50,
		randZ = math.random() * 100 - 50,
	}
	sim_next(node, sim, worker)
end
local function str_split(str, sep)
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
local function read_csv(text)
	local data = {}
	local keys = {}
	local i = 0
	for _, line in ipairs(str_split(text, "\r\n")) do
		local row = {}
		for j, v in ipairs(str_split(line, ",")) do
			if i == 0 then
				keys[j] = v
			else
				row[keys[j]] = v
			end
			j = j + 1
		end
		if i > 0 then
			data[i] = row
		end
		i = i + 1
	end
	return data, keys
end
local function spawn_start_file(text)
	local data = read_csv(text)
	if #data == 0 then
		print("无数据")
		return
	end
	local worker = create_work(0, "file")
	sim_worker = worker
	for _, row in ipairs(data) do
		if row.zombieType and #row.zombieType>0 then
			wait(tonumber(row.waitTime) or 0)
			if not worker:running() then
				break
			end
			check_nodes()
			local node = Points[row.point]
			if node then
				for i = 1, tonumber(row.count) or 1 do
					if i>1 then
						wait(0)
					end
					sim_spawn(node, worker, row.zombieType)
				end
			end
		end
	end
end
local function utf8_to_utf16(utf8str)
    local utf16str = {"\255\254"}	-- BOM	"\xFF\xFE"
    local i = 1
    while i <= #utf8str do
        local c = utf8str:byte(i)
        local codepoint = 0

        if c < 0x80 then
            codepoint = c
            i = i + 1
        elseif c < 0xE0 then
            codepoint = ((c % 0x20) * 0x40) + (utf8str:byte(i + 1) % 0x40)
            i = i + 2
        elseif c < 0xF0 then
            codepoint = ((c % 0x10) * 0x1000) + ((utf8str:byte(i + 1) % 0x40) * 0x40) + (utf8str:byte(i + 2) % 0x40)
            i = i + 3
        else
            codepoint = ((c % 0x08) * 0x40000) + ((utf8str:byte(i + 1) % 0x40) * 0x1000) +
                        ((utf8str:byte(i + 2) % 0x40) * 0x40) + (utf8str:byte(i + 3) % 0x40)
            i = i + 4
        end

        if codepoint < 0x10000 then
            table.insert(utf16str, string.char(codepoint % 256, math.floor(codepoint / 256)))
        else
            codepoint = codepoint - 0x10000
            local high_surrogate = 0xD800 + math.floor(codepoint / 0x400)
            local low_surrogate = 0xDC00 + (codepoint % 0x400)
            table.insert(utf16str, string.char(high_surrogate % 256, math.floor(high_surrogate / 256)))
            table.insert(utf16str, string.char(low_surrogate % 256, math.floor(low_surrogate / 256)))
        end
    end
    return table.concat(utf16str)
end
local function utf16_to_utf8(utf16str)
    local utf8str = {}
    local i = 1
	if utf16str:byte(1) == 0xFF and utf16str:byte(2) == 0xFE then
		i = 3
	end
    while i < #utf16str do
        local b1, b2 = utf16str:byte(i, i + 1)
        local codepoint = b1 + (b2 * 256)
        i = i + 2

        if codepoint >= 0xD800 and codepoint <= 0xDBFF then
            -- 处理代理对
            local b3, b4 = utf16str:byte(i, i + 1)
            local low_surrogate = b3 + (b4 * 256)
            i = i + 2
            codepoint = 0x10000 + ((codepoint - 0xD800) * 0x400) + (low_surrogate - 0xDC00)
        end

        if codepoint < 0x80 then
            table.insert(utf8str, string.char(codepoint))
        elseif codepoint < 0x800 then
            table.insert(utf8str, string.char(0xC0 + math.floor(codepoint / 0x40), 0x80 + (codepoint % 0x40)))
        elseif codepoint < 0x10000 then
            table.insert(utf8str, string.char(0xE0 + math.floor(codepoint / 0x1000), 
                                              0x80 + (math.floor(codepoint / 0x40) % 0x40), 
                                              0x80 + (codepoint % 0x40)))
        else
            table.insert(utf8str, string.char(0xF0 + math.floor(codepoint / 0x40000), 
                                              0x80 + (math.floor(codepoint / 0x1000) % 0x40), 
                                              0x80 + (math.floor(codepoint / 0x40) % 0x40), 
                                              0x80 + (codepoint % 0x40)))
        end
    end
    return table.concat(utf8str)
end

local function sim_start(status)
	sim_stop()
	if status == 1 then
		return
	end
	if status > 3 then
		spawn_start_file(sim_spawn_list[status - 3])
		return
	end
	local last_nodes = {}
	local worker = nil
	worker = create_work(0.01, function()
		check_nodes()
		local nodes = status==3 and Points.Children or {plugin:Selection()}
		local route_nodes = {}	-- 标记路线节点（无需刷怪）
		for _, node in ipairs(nodes) do
			if node.Parent==Points then
				for _, sub in ipairs(node.Children) do
					if sub:IsA("String") then
						route_nodes[sub.Name] = true
					end
				end
			end
		end
		local now = RunService:CurrentSteadyTimeStampMS()
		local spawn_nodes = {}	-- 存放刷怪节点（起点）
		for _, node in ipairs(nodes) do
			if node.Parent==Points then
				if not route_nodes[node.Name] then	-- 不是路线，即为起点
					local id = node.ID
					local tb = last_nodes[id] or {now, 0}
					spawn_nodes[id] = tb
					local need = (now - tb[1]) * SPAWN_SPEED / 1000 + 1	-- 需要刷怪数量
					if need > tb[2] then
						tb[2] = tb[2] + 1
						sim_spawn(node, worker)
					end
				end
			end
		end
		last_nodes = spawn_nodes	-- 保留上次刷怪信息
	end, "sim")
	sim_worker = worker
	worker:start()
end

local sim_btns = {"不刷怪", "选中刷怪", "全部刷怪"}
local sim_select, sim_fix_list = status_select("⬇️刷怪⬇️", sim_btns, sim_start)
sim_select(1)

local Spawns = nil
local first_error = true
local last_text = {}
local function sim_update_spawns()
	check_nodes()
	if not Root then
		return
	end
	Spawns = get_or_create("Spawns")
	for i, node in ipairs(Spawns.Children) do
		local name = node.Name
		local path = "D:\\pvz\\"..name..".csv"
		local function open_any(flag)
			local file = io.open(path, flag)
			if not file then
				local tp = "E" .. path:sub(2)
				file = io.open(tp, flag)
				if file then
					path = tp
				end
			end
			return file
		end
		local file = open_any("rb")
		local text = node.Value
		if file then
			text = file:read("*a")
			file:close()
			local last = last_text[node.ID]
			if not last or last[1]~=text then
				last = {
					text,
					utf16_to_utf8(text):gsub("\t", "|"),
				}
				last_text[node.ID] = last
			end
			text = last[2]
		else
			if text == "" then
				text = "waitTime,point,zombieType,count,action\r\n"
						.. "0,Spawn01,normal,1,\"tips,第一波！\",\r\n"
			end
			file = open_any("w+b")
			if file then
				file:write(utf8_to_utf16(text:gsub("|", "\t")))
				file:close()
				print("已创建："..path)
			elseif first_error then
				first_error = false
				print("无法创建："..path .. "，请自行创建文件夹")
			end
		end
		node.Value = text
		sim_btns[i + 3] = "表格刷怪："..name
		sim_spawn_list[i] = text
	end
	sim_fix_list(sim_btns)
end

function import_all_csv()
	local NAMES = {
		"Infinite",
		"Career_1",
		"Career_2",
		"Career_3",
		"Career_4",
		"Career_5",
	}
	local function get_or_create(node, child, child_child, ...)
		if not child then
			return node
		end
		local child_node = node[child]
		if not child_node then
			child_node = SandboxNode.new(child_child and "Transform" or "String", node)
			child_node.Name = child
		end
		return get_or_create(child_node, child_child, ...)
	end
	local root_path = plugin:GetAssetPath() .. "/CSV/LevelSpawn/"
	local no_need = 0
    for _, level_node in ipairs(game.CustomConfigService.ConfigGroup.Level.Children) do
		local level_name = level_node.Name
		for _, name in ipairs(NAMES) do
			local node_name = level_name .. "_" .. name
			local file = io.open(root_path .. node_name .. ".csv", "rb")
			if file then
				local text = file:read("*a")
				file:close()
				text = utf16_to_utf8(text):gsub("\t", "|")
				local str_node = get_or_create(level_node, "Prefab", "Waypoint", "Spawns", node_name)
				if str_node.Value ~= text then
					str_node.Value = text
					print("已导入：" .. node_name)
				else
					no_need = no_need + 1
				end
			end
		end
	end
	print("导入完成，" .. no_need .. "个文件无需更新")
end

wait(3) -- 避免运行状态切换瞬间的混乱问题
is_ready = true

create_work(1, sim_update_spawns, "sim_update_spawns"):start()
