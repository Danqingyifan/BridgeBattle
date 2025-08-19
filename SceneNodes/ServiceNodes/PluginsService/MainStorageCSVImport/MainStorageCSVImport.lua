local pluginButton = {}

-- 通用的UTF-16到UTF-8转换函数
function ConvertUTF16ToUTF8(utf16String, isLittleEndian)
    local utf8String = ""
    local i = 1
    
    while i <= #utf16String do
        -- 读取UTF-16字符
        local firstByte = utf16String:byte(i)
        local secondByte = utf16String:byte(i + 1)
        
        if not secondByte then
            break -- 不完整的字符
        end
        
        -- 根据字节序计算Unicode码点
        local unicode
        if isLittleEndian then
            -- 小端序：低字节在前
            unicode = firstByte + (secondByte * 256)
        else
            -- 大端序：高字节在前
            unicode = (firstByte * 256) + secondByte
        end
        
        -- 转换为UTF-8
        if unicode < 0x80 then
            -- 单字节UTF-8
            utf8String = utf8String .. string.char(unicode)
        elseif unicode < 0x800 then
            -- 双字节UTF-8
            local byte1 = 0xC0 + math.floor(unicode / 0x40)
            local byte2 = 0x80 + (unicode % 0x40)
            utf8String = utf8String .. string.char(byte1, byte2)
        elseif unicode < 0x10000 then
            -- 三字节UTF-8
            local byte1 = 0xE0 + math.floor(unicode / 0x1000)
            local byte2 = 0x80 + math.floor((unicode % 0x1000) / 0x40)
            local byte3 = 0x80 + (unicode % 0x40)
            utf8String = utf8String .. string.char(byte1, byte2, byte3)
        else
            -- 四字节UTF-8（代理对处理）
            if unicode >= 0xD800 and unicode <= 0xDBFF then
                -- 高代理项
                local lowSurrogateFirst = utf16String:byte(i + 3)
                local lowSurrogateSecond = utf16String:byte(i + 4)
                if lowSurrogateFirst and lowSurrogateSecond then
                    local lowSurrogate
                    if isLittleEndian then
                        lowSurrogate = lowSurrogateFirst + (lowSurrogateSecond * 256)
                    else
                        lowSurrogate = (lowSurrogateFirst * 256) + lowSurrogateSecond
                    end
                    
                    if lowSurrogate >= 0xDC00 and lowSurrogate <= 0xDFFF then
                        -- 计算完整的Unicode码点
                        local codePoint = 0x10000 + ((unicode - 0xD800) * 0x400) + (lowSurrogate - 0xDC00)
                        
                        -- 转换为四字节UTF-8
                        local byte1 = 0xF0 + math.floor(codePoint / 0x40000)
                        local byte2 = 0x80 + math.floor((codePoint % 0x40000) / 0x1000)
                        local byte3 = 0x80 + math.floor((codePoint % 0x1000) / 0x40)
                        local byte4 = 0x80 + (codePoint % 0x40)
                        utf8String = utf8String .. string.char(byte1, byte2, byte3, byte4)
                        
                        i = i + 2 -- 跳过低代理项
                    end
                end
            else
                -- 直接转换（非代理项）
                local byte1 = 0xF0 + math.floor(unicode / 0x40000)
                local byte2 = 0x80 + math.floor((unicode % 0x40000) / 0x1000)
                local byte3 = 0x80 + math.floor((unicode % 0x1000) / 0x40)
                local byte4 = 0x80 + (unicode % 0x40)
                utf8String = utf8String .. string.char(byte1, byte2, byte3, byte4)
            end
        end
        
        i = i + 2 -- UTF-16每个字符占2字节
    end
    
    return utf8String
end

-- UTF-16LE到UTF-8转换函数
function ConvertUTF16LEToUTF8(utf16leString)
    return ConvertUTF16ToUTF8(utf16leString, true)
end

-- UTF-16BE到UTF-8转换函数
function ConvertUTF16BEToUTF8(utf16beString)
    return ConvertUTF16ToUTF8(utf16beString, false)
end

-- 获取文件名
function GetFileName(filePath)
    local fileName = filePath:match("([^\\/]+)$")
    if fileName then
        -- 移除扩展名
        return fileName:match("(.+)%.[^%.]*$") or fileName
    end
    return nil
end

-- 根据编码读取文件内容
function LoadCSVFileContent(filePath)
    local encoding = detectFileEncoding(filePath)
    print("检测到文件编码: " .. encoding .. " - " .. filePath)
    
    local file, err = io.open(filePath, "rb") -- 使用二进制模式
    if not file then
        error("无法打开文件: " .. (err or "未知错误"))
    end
    
    local content = file:read("*all")
    file:close()
    
    -- 根据编码处理内容
    if encoding == "UTF-8" then
        -- 移除BOM（如果存在）
        if content:sub(1,3) == "\239\187\191" then
            content = content:sub(4)
        end
    elseif encoding == "UTF-16LE" then
        -- 移除BOM并转换UTF-16LE到UTF-8
        if content:sub(1,2) == "\255\254" then
            content = content:sub(3)
        end
        content = ConvertUTF16LEToUTF8(content)
    elseif encoding == "UTF-16BE" then
        -- 移除BOM并转换UTF-16BE到UTF-8
        if content:sub(1,2) == "\254\255" then
            content = content:sub(3)
        end
        content = ConvertUTF16BEToUTF8(content)
    end
    return content
end


local PluginModule = {}
function PluginModule:Init()
    self.scanPath = plugin:GetAssetPath().. "/CSV/MainStorage"
    self.autoRemoveRedundantNode = false

    self.autoRemoveRedundantNodeBtn = plugin:addContextMenuButton("⬛️导入时自动清理多余的节点")
    self.autoRemoveRedundantNodeBtn.Click:Connect(function()
        self.autoRemoveRedundantNode = not self.autoRemoveRedundantNode
        self.autoRemoveRedundantNodeBtn.Text = self.autoRemoveRedundantNode and "✅自动删除多余的节点" or "⬛️自动删除多余的节点"
    end)

    plugin:addContextMenuButton("🗂导入所有目录").Click:Connect(function() 
        for dirPath in pairs(self.DirectoryBtnList) do
            self:HandleDirectory(dirPath)
        end
    end)

    self.DirectoryBtnList = {}
    self:CreateDirectoryBtn()

    plugin:RemoveFileWatcher(_G.DirFileWatcherHandle)
    _G.DirFileWatcherHandle = plugin:AddFileWatcher(self.scanPath, function()
        self:ClearDirectoryBtn()
        self:CreateDirectoryBtn()
    end)
end

function PluginModule:CreateDirectoryBtn()
    local directories = {}
    for path, fileType in pairs(plugin:GetDirEntryList(self.scanPath)) do
        print(path, fileType)
        if fileType == "dir" then
            table.insert(directories, path)
        end
    end

    for _, dir in ipairs(directories) do
        local buttonName = string.gsub(dir, self.scanPath .. "/", "")
        local button = plugin:addContextMenuButton(string.format("📁导入%s目录", buttonName))
        button.Click:Connect(function()
            self:HandleDirectory(dir)
        end)
        self.DirectoryBtnList[dir] = button
    end
end

function PluginModule:HandleDirectory(dirPath)
    local dirName = GetFileName(dirPath)
    local MainStorage = game.MainStorage
    local CSVNode = game.MainStorage.Config.CSV
    local ConfigRoot = CSVNode[dirName]
    if not ConfigRoot then
        ConfigRoot = SandboxNode.New("SandboxNode")
        ConfigRoot.Name = dirName
        ConfigRoot.Parent = CSVNode
    end

    local files = {}
    for path, fileType in pairs(plugin:GetDirEntryList(dirPath)) do
        if fileType == "file" and string.find(path, "%.csv$") then
            table.insert(files, path)
        end
    end

    local filesMap = {}
    for _, filePath in ipairs(files) do
        local fileName = GetFileName(filePath)  
        local csvNode = ConfigRoot[fileName]
        if not csvNode then
            csvNode = SandboxNode.New("StringValue")
            csvNode.Name = fileName
            csvNode.Parent = ConfigRoot
        end
        local fullPath = dirPath .. "/" .. filePath
        csvNode.Value = LoadCSVFileContent(filePath)
        filesMap[fileName] = true
    end

    if self.autoRemoveRedundantNode then
        local deleteNodes = {}
        for _, node in ipairs(ConfigRoot.Children) do
            if not filesMap[node.Name] then
                table.insert(deleteNodes, node)
            end
        end
        for _, node in ipairs(deleteNodes) do
            node.Parent = nil
        end
    end
end

function PluginModule:ClearDirectoryBtn()
    for path, btn in pairs(self.DirectoryBtnList or {}) do
        plugin:RemoveContextMenuButton(btn)
    end
    self.DirectoryBtnList = {}
end

PluginModule:Init()