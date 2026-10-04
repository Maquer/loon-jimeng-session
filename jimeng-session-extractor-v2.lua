-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 自动抓取 + Bark 推送（调试版）
-- 创建：2026-10-04
-- 版本：2.0.0

-- ============================================
-- 配置区
-- ============================================

BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
BARK_ICON = "https://www.jianying.com/favicon.ico"
BARK_SOUND = "pop"
BARK_GROUP = "jimeng"
BARK_IS_ARCHIVE = 1
BARK_CLICK_URL = "https://jimeng.jianying.com"

-- 调试模式：1=开启调试通知，0=关闭
DEBUG_MODE = 1

-- 缓存文件路径
CACHE_FILE = "/tmp/jimeng_last_session.txt"

-- ============================================
-- 调试函数
-- ============================================

-- 发送调试通知
local function sendDebugNotification(title, body)
    if DEBUG_MODE ~= 1 then
        return
    end
    
    local encodedBody = body:gsub("\n", "%0A"):gsub(" ", "%%20")
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&sound=alarm&group=jimeng-debug&isArchive=0",
        BARK_KEY,
        title,
        encodedBody,
        BARK_ICON
    )
    
    http.get(url, function(response)
        print("[DEBUG] 通知发送: " .. response.status)
    end)
end

-- 提取 Cookie 值
local function extractCookieValue(headers, cookieName)
    local cookieHeader = headers["cookie"] or headers["Cookie"] or ""
    local pattern = cookieName .. "=([^;]+)"
    for value in cookieHeader:gmatch(pattern) do
        return value
    end
    return nil
end

-- 检查所有可能的 session 相关字段
local function findSessionData(headers)
    local results = {}
    
    -- 检查常见位置
    local sessionFields = {
        "sessionid",
        "session_id",
        "sessionId",
        "sid",
        "auth_token",
        "token",
        "passport_session",
        "session_key"
    }
    
    for _, field in ipairs(sessionFields) do
        local value = extractCookieValue(headers, field)
        if value then
            table.insert(results, field .. "=" .. value)
        end
    end
    
    -- 检查所有 cookie
    local cookieHeader = headers["cookie"] or headers["Cookie"] or ""
    for name, value in cookieHeader:gmatch("([^;=]+)=([^;]+)") do
        if name:lower():find("session") or name:lower():find("auth") or name:lower():find("token") then
            table.insert(results, name .. "=" .. value)
        end
    end
    
    return results
end

-- ============================================
-- 主逻辑
-- ============================================

-- 检查域名是否为即梦
if not response.url:find("jimeng\\.jianying\\.com", 1, true) and 
   not response.url:find("jianying\\.com", 1, true) then
    print("[SKIP] 非即梦域名: " .. response.url)
    return
end

print("[INFO] 捕获即梦请求: " .. response.url)

-- 获取响应头
local headers = response.headers or {}

-- 调试：记录所有响应头
if DEBUG_MODE == 1 then
    local headerInfo = {}
    for k, v in pairs(headers) do
        table.insert(headerInfo, k .. ": " .. v)
    end
    print("[DEBUG] 响应头:\n" .. table.concat(headerInfo, "\n"))
end

-- 提取 sessionid
local sessionId = extractCookieValue(headers, "sessionid")

-- 如果没找到，尝试查找其他 session 相关字段
if not sessionId then
    local sessionData = findSessionData(headers)
    if #sessionData > 0 then
        -- 使用找到的第一个 session 相关字段
        sessionId = sessionData[1]:gsub(".*=", "")
        
        if DEBUG_MODE == 1 then
            local sessionInfo = table.concat(sessionData, "\n")
            sendDebugNotification("🔍 调试：发现 Session 数据", sessionInfo)
        end
        
        print("[INFO] 找到 session 相关字段: " .. table.concat(sessionData, ", "))
    end
end

-- 如果找到了 sessionid
if sessionId and sessionId ~= "" then
    print("[FOUND] sessionid: " .. sessionId)
    
    -- 发送通知
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local title = "✅ 即梦 Session ID"
    local body = string.format(
        "🎯 抓取成功！\n\n🔑 Session: %s\n\n⏰ 时间：%s\n\n📋 使用方法：\n1. 复制 Session ID\n2. 设置环境变量：\nexport JIMENG_SESSION_ID=\"%s\"\n3. 运行海报生成脚本",
        sessionId,
        timestamp,
        sessionId
    )
    
    -- URL 编码
    local encodedBody = body:gsub("\n", "%0A"):gsub(" ", "%%20")
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&sound=%s&group=%s&isArchive=%s&click=%s",
        BARK_KEY,
        title,
        encodedBody,
        BARK_ICON,
        BARK_SOUND,
        BARK_GROUP,
        BARK_IS_ARCHIVE,
        BARK_CLICK_URL
    )
    
    http.get(url, function(response)
        if response.status == 200 then
            print("[OK] Bark 通知已发送")
            -- 保存缓存
            local cache = io.open(CACHE_FILE, "w")
            if cache then
                cache:write(sessionId)
                cache:close()
            end
        else
            print("[FAIL] Bark 通知失败: " .. response.status)
        end
    end)
    
else
    -- 没找到 sessionid，发送调试通知
    if DEBUG_MODE == 1 then
        local debugInfo = string.format(
            "🔍 调试信息\n\nURL: %s\n\n响应头:\n%s\n\n未找到 sessionid",
            response.url,
            response.headers and response.url or "无"
        )
        sendDebugNotification("❓ 未找到 Session ID", "请检查 Loon 配置和证书")
    end
    
    print("[WARN] 未找到 sessionid")
end