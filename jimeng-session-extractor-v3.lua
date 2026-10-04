-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 自动抓取 + Bark 推送（诊断版 v3.0）
-- 创建：2026-10-04
-- 用途：捕获所有可能的 session 信息，发送诊断通知

-- ============================================
-- 配置区
-- ============================================

BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
BARK_ICON = "https://www.jianying.com/favicon.ico"
BARK_SOUND = "pop"
BARK_GROUP = "jimeng"
BARK_IS_ARCHIVE = 1
BARK_CLICK_URL = "https://jimeng.jianying.com"

-- 调试模式：1=发送详细诊断，0=关闭
DEBUG_MODE = 1

-- 捕获模式：1=捕获所有即梦相关请求，2=只捕获包含 session 的请求
CAPTURE_MODE = 1

-- 缓存文件路径
CACHE_FILE = "/tmp/jimeng_last_session.txt"

-- ============================================
-- 工具函数
-- ============================================

-- 发送 Bark 通知
local function sendBark(title, body, sound)
    if not sound then sound = BARK_SOUND end
    
    local encodedBody = body:gsub("\n", "%0A"):gsub(" ", "%%20"):gsub("%", "%%25")
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&sound=%s&group=%s&isArchive=%s&click=%s",
        BARK_KEY,
        title,
        encodedBody,
        BARK_ICON,
        sound,
        BARK_GROUP,
        BARK_IS_ARCHIVE,
        BARK_CLICK_URL
    )
    
    http.get(url, function(response)
        print("[BARK] 通知发送: " .. response.status)
    end)
end

-- 发送诊断通知
local function sendDiagnosis(title, body)
    if DEBUG_MODE == 1 then
        sendBark("🔍 " .. title, body, "alarm")
    end
end

-- 提取 Cookie 值
local function extractCookie(headers, name)
    local cookieStr = headers["cookie"] or headers["Cookie"] or ""
    local pattern = name .. "=([^;]+)"
    return cookieStr:match(pattern)
end

-- 提取所有 Cookie 名值对
local function extractAllCookies(headers)
    local cookieStr = headers["cookie"] or headers["Cookie"] or ""
    local cookies = {}
    
    for name, value in cookieStr:gmatch("([^;=]+)=([^;]+)") do
        table.insert(cookies, name .. "=" .. value)
    end
    
    return cookies
end

-- 查找可能的 session 字段
local function findSessionFields(headers)
    local results = {}
    
    -- 检查 Cookie 中的 session 相关字段
    local cookies = extractAllCookies(headers)
    for _, cookie in ipairs(cookies) do
        local name = cookie:match("^([^=]+)=")
        if name:lower():find("session") or name:lower():find("auth") or 
           name:lower():find("token") or name:lower():find("sid") or
           name:lower():find("passport") or name:lower():find("key") then
            table.insert(results, "Cookie: " .. cookie)
        end
    end
    
    -- 检查请求头中的 session 相关字段
    local sessionHeaders = {
        "authorization", "x-auth-token", "x-session-id",
        "x-csrf-token", "x-request-id", "x-signature"
    }
    
    for _, header in ipairs(sessionHeaders) do
        local value = headers[header] or headers[string.upper(header)]
        if value then
            table.insert(results, "Header: " .. header .. "=" .. value)
        end
    end
    
    return results
end

-- 格式化表为字符串
local function tableToString(tbl)
    local lines = {}
    for k, v in pairs(tbl) do
        table.insert(lines, k .. ": " .. tostring(v))
    end
    return table.concat(lines, "\n")
end

-- ============================================
-- 主逻辑
-- ============================================

-- 检查域名
local isJimeng = response.url:find("jimeng\\.jianying\\.com", 1, true)
local isJianying = response.url:find("jianying\\.com", 1, true)

if not isJimeng and not isJianying then
    print("[SKIP] 非即梦域名: " .. response.url)
    return
end

print("[INFO] 捕获请求: " .. response.url)

-- 获取请求头
local headers = response.headers or {}

-- 构建诊断信息
local diagnosis = {}

-- 1. 基本信息
table.insert(diagnosis, "URL: " .. response.url)
table.insert(diagnosis, "Method: " .. response.method)
table.insert(diagnosis, "Status: " .. response.status)

-- 2. 所有响应头
local headerLines = {}
for k, v in pairs(headers) do
    table.insert(headerLines, "  " .. k .. ": " .. tostring(v))
end
table.insert(diagnosis, "Headers:\n" .. table.concat(headerLines, "\n"))

-- 3. 查找 session 相关字段
local sessionFields = findSessionFields(headers)
if #sessionFields > 0 then
    table.insert(diagnosis, "Session 相关字段:\n" .. table.concat(sessionFields, "\n"))
else
    table.insert(diagnosis, "⚠️ 未找到 session 相关字段")
end

-- 4. 提取所有 Cookie
local allCookies = extractAllCookies(headers)
table.insert(diagnosis, "所有 Cookie (" .. #allCookies .. " 个):")
for _, cookie in ipairs(allCookies) do
    table.insert(diagnosis, "  " .. cookie)
end

-- 5. 尝试提取 sessionid
local sessionId = extractCookie(headers, "sessionid")

if sessionId then
    print("[FOUND] sessionid: " .. sessionId)
    
    -- 发送成功通知
    sendBark("✅ 即梦 Session ID", 
        "🎯 抓取成功！\n\n🔑 Session: " .. sessionId .. 
        "\n\n⏰ 时间：" .. os.date("%Y-%m-%d %H:%M:%S") ..
        "\n\n📋 使用方法：\n1. 复制 Session ID\n2. export JIMENG_SESSION_ID=\"" .. sessionId .. "\"\n3. 运行海报生成脚本")
    
    -- 保存缓存
    local cache = io.open(CACHE_FILE, "w")
    if cache then
        cache:write(sessionId)
        cache:close()
    end
    
else
    -- 发送诊断通知
    local diagnosisStr = table.concat(diagnosis, "\n\n")
    sendDiagnosis("未找到 sessionid", 
        "请检查以下内容：\n\n1. MITM 是否开启\n2. 证书是否信任\n3. 域名是否正确\n\n诊断信息：\n\n" .. diagnosisStr)
    
    print("[WARN] 未找到 sessionid，发送诊断通知")
end

-- 4. 发送诊断通知（如果开启）
if DEBUG_MODE == 1 then
    sendDiagnosis("捕获到请求", 
        "URL: " .. response.url ..
        "\n\n状态：找到 " .. #sessionFields .. " 个 session 字段\n\n" ..
        (#sessionFields > 0 and table.concat(sessionFields, "\n") or "无"))
end