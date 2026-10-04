-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 抓取 v7
-- 修复：使用 http-request 从请求头中提取 Cookie sessionid

-- ============================================
-- 配置区
-- ============================================

BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
BARK_ICON = "https://www.jianying.com/favicon.ico"

-- ============================================
-- 工具函数
-- ============================================

local function urlencode(str)
    if not str then return "" end
    str = str:gsub("\r\n", "\n")
    str = str:gsub("([^%w ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "%%20")
    return str
end

local function notify(title, body)
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&group=jimeng&sound=pop",
        BARK_KEY,
        urlencode(title),
        urlencode(body),
        urlencode(BARK_ICON)
    )
    http.get(url, function()
        print("[BARK] sent")
    end)
end

-- ============================================
-- 主逻辑
-- ============================================

-- 获取请求头（http-request 模式）
local reqHeaders = $request.headers or {}
local reqUrl = $request.url or "unknown"

-- 从请求头中提取 Cookie
local cookieStr = reqHeaders["Cookie"] or reqHeaders["cookie"] or ""

-- 提取 sessionid
local sessionId = nil
for sid in cookieStr:gmatch("sessionid=([^;]+)") do
    sessionId = sid
    break
end

if sessionId and sessionId ~= "" then
    print("[FOUND] sessionid: " .. sessionId)
    notify("✅ 即梦 Session ID",
        "🔑 " .. sessionId ..
        "\n⏰ " .. os.date("%Y-%m-%d %H:%M:%S") ..
        "\n\n📋 export JIMENG_SESSION_ID=\"" .. sessionId .. "\"")
else
    -- 未找到，发送诊断信息
    local debugInfo = "URL: " .. reqUrl ..
        "\n\nCookie 长度: " .. #cookieStr ..
        "\n\nCookie 内容:\n" .. (cookieStr ~= "" and cookieStr or "（无）")
    notify("❓ 未找到 sessionid", debugInfo)
end