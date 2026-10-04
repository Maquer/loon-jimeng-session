-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 抓取 - 诊断版 v6
-- 用途：全面诊断，捕获所有请求并发送诊断信息

-- ============================================
-- 配置区
-- ============================================

BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
BARK_ICON = "https://www.jianying.com/favicon.ico"

-- ============================================
-- 工具函数
-- ============================================

-- URL 编码
local function urlencode(str)
    if not str then return "" end
    str = str:gsub("\r\n", "\n")
    str = str:gsub("(%c)", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "%%20")
    return str
end

-- 发送 Bark 通知
local function notify(title, body)
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&group=jimeng",
        BARK_KEY,
        urlencode(title),
        urlencode(body),
        urlencode(BARK_ICON)
    )
    http.get(url, function(resp)
        print("[BARK] " .. resp.status)
    end)
end

-- ============================================
-- 主逻辑
-- ============================================

-- 1. 检查是否是即梦相关请求
local url = response.url or ""
local isTarget = url:find("jianying\\.com", 1, true) or 
                 url:find("douyin\\.com", 1, true) or 
                 url:find("bytedance\\.com", 1, true)

if not isTarget then
    return  -- 非目标域名，静默退出
end

-- 2. 构建诊断信息
local diag = {}
table.insert(diag, "URL: " .. url)
table.insert(diag, "Status: " .. tostring(response.status))

-- 3. 提取所有 headers
local headerLines = {}
if response.headers then
    for k, v in pairs(response.headers) do
        table.insert(headerLines, k .. "=" .. tostring(v))
    end
end
table.insert(diag, "Headers (" .. #headerLines .. " 个):\n" .. table.concat(headerLines, "\n"))

-- 4. 提取所有 Cookie
local cookieStr = ""
if response.headers then
    cookieStr = response.headers["cookie"] or response.headers["Cookie"] or ""
end

local allCookies = {}
for name, value in cookieStr:gmatch("([^;=]+)=([^;]+)") do
    table.insert(allCookies, name .. "=" .. value)
end

table.insert(diag, "Cookies (" .. #allCookies .. " 个):")
for _, cookie in ipairs(allCookies) do
    table.insert(diag, "  " .. cookie)
end

-- 5. 查找所有可能的 session 字段
local sessionFound = {}

-- 检查常见 session 字段
local sessionPatterns = {
    "sessionid",
    "sessionid_ss",
    "passport_auth_status",
    "sid_ucp_v1",
    "sid_guard",
    "uid_tt",
    "sid_tt",
    "auth_token",
    "token",
    "session_key"
}

for _, pattern in ipairs(sessionPatterns) do
    local v = cookieStr:match(pattern .. "=([^;]+)")
    if v then
        table.insert(sessionFound, pattern .. "=" .. v)
    end
end

-- 检查 Header 中的 auth 字段
local authHeaders = {
    "authorization", "x-auth-token", "x-session-id"
}

for _, header in ipairs(authHeaders) do
    local v = response.headers[header] or response.headers[string.upper(header)]
    if v then
        table.insert(sessionFound, header .. "=" .. v)
    end
end

-- 6. 发送诊断通知
local diagStr = table.concat(diag, "\n\n")
notify("🔍 即梦诊断 v6", diagStr)

-- 7. 如果找到 session 字段，单独发送
if #sessionFound > 0 then
    local sessionStr = table.concat(sessionFound, "\n")
    notify("✅ Session 字段已找到", sessionStr)
end