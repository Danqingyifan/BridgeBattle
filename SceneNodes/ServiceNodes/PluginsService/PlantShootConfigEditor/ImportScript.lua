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

-- 从完整路径中提取文件名（不包含扩展名）
function GetFileName(filePath)
    local fileName = filePath:match("([^\\/]+)$")
    if fileName then
        -- 移除扩展名
        return fileName:match("(.+)%.[^%.]*$") or fileName
    end
    return nil
end

-- 检测文件编码
function detectFileEncoding(filePath)
    local file = io.open(filePath, "rb")
    if not file then
        return "UTF-8" -- 默认编码
    end
    
    local bom = file:read(3)
    file:close()
    
    if bom == "\239\187\191" then
        return "UTF-8"
    elseif bom == "\255\254" then
        return "UTF-16LE"
    elseif bom == "\254\255" then
        return "UTF-16BE"
    else
        -- 重新打开文件检查更多字节
        file = io.open(filePath, "rb")
        local firstBytes = file:read(4)
        file:close()
        
        if firstBytes:sub(1,2) == "\255\254" then
            return "UTF-16LE"
        elseif firstBytes:sub(1,2) == "\254\255" then
            return "UTF-16BE"
        else
            return "UTF-8" -- 默认假设为UTF-8
        end
    end
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

function ScanFiles(directoryPath, fileSuffix, callback)
    local matchStr = string.format("%%.%s$", fileSuffix)
    local files = {}
    
    -- 使用单次命令获取所有文件信息，避免多次打开控制台
    local cmd = 'dir "' .. directoryPath .. '" /b /a-d 2>nul'
    local dir = io.popen(cmd)
    if dir then
        for file in dir:lines() do
            -- 只处理文件（不包含目录），并且匹配指定后缀
            if file:lower():match(matchStr) then
                local fullPath = directoryPath .. "\\" .. file
                table.insert(files, fullPath)
            end
        end
        dir:close()
    end
    
    -- 如果提供了回调函数，则对每个文件执行回调
    if callback then
        for _, filePath in ipairs(files) do
            callback(filePath)
        end
    end
    return files
end

local CustomConfigService = game:GetService("CustomConfigService")
function LoadPlantFireConfig(path)
    local PlantNode = CustomConfigService.ConfigGroup.Plant
    local handleCSV = function(filePath)
        local fileName = GetFileName(filePath)
        if not PlantNode[fileName] then
            print("没有找到" .. fileName .. "节点, 跳过导入CSV")
            return
        end

        local plantRoot = PlantNode[fileName]
        local shootConfigNode = plantRoot["ShootConfig"]     
        if not shootConfigNode then
            print("为" .. fileName .. "创建ShootConfig节点")
            shootConfigNode = SandboxNode.New("StringValue")
            shootConfigNode.Parent = plantRoot
            shootConfigNode.Name = "ShootConfig"
        end
        
        print("正在处理CSV文件：" .. filePath)
        shootConfigNode.Value = LoadCSVFileContent(filePath)
    end

    print("开始扫描CSV文件!")
    local files = ScanFiles(path, "csv")
    for _, filePath in ipairs(files) do
        handleCSV(filePath)
    end
    print("CSV文件扫描完成!")
end

plugin:addContextMenuButton("Import").Click:Connect(function()
    local path = plugin:GetAssetPath() .. "/CSV/ShootConfig"
    LoadPlantFireConfig(path)
end)