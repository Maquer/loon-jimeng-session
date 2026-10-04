-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 抓取 - 最小诊断版 v5
-- 用途：诊断 Loon 是否正确捕获请求 + 检查 sessionid 存储位置

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

-- 发送 Bark 通知（简化版）
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

-- 1. 打印所有捕获的响应（先确认脚本被执行）
print("[DIAG] Response URL: " .. tostring(response.url))
print("[DIAG] Response status: " .. tostring(response.status))
print("[DIAG] Response headers type: " .. type(response.headers))

-- 2. 检查是否是即梦域名
local url = response.url or ""
local isTarget = url:find("jianying\\.com", 1, true) or url:find("douyin\\.com", 1, true) or url:find("bytedance\\.com", 1, true)

if not isTarget then
    -- 非目标域名，静默退出
    return
end

print("[DIAG] 匹配目标域名，准备提取 session")

-- 3. 构建完整诊断信息
local diag = {}
table.insert(diag, "URL: " .. url)
table.insert(diag, "Status: " .. tostring(response.status))

-- 4. 提取所有 headers
local headerLines = {}
if response.headers then
    for k, v in pairs(response.headers) do
        table.insert(headerLines, k .. "=" .. tostring(v))
    end
end
table.insert(diag, "Headers (" .. #headerLines .. " 个):\n" .. table.concat(headerLines, "\n"))

-- 5. 尝试多种 session 提取方式
local sessionFound = {}

-- 方式 A：Cookie sessionid
local cookieStr = ""
if response.headers then
    cookieStr = response.headers["cookie"] or response.headers["Cookie"] or ""
end

local sessionId = cookieStr:match("sessionid=([^;]+)")
if sessionId then
    table.insert(sessionFound, "Cookie sessionid=" .. sessionId)
end

-- 方式 B：Cookie sessionid_ss
local sessionIdSs = cookieStr:match("sessionid_ss=([^;]+)")
if sessionIdSs then
    table.insert(sessionFound, "Cookie sessionid_ss=" .. sessionIdSs)
end

-- 方式 C：其他常见 auth 字段
for name, pattern in pairs({
    ["passport_auth_status"] = "passport_auth_status=([^;]+)",
    ["sid_ucp_v1"] = "sid_ucp_v1=([^;]+)",
    ["sid_guard"] = "sid_guard=([^;]+)",
    ["uid_tt"] = "uid_tt=([^;]+)",
    ["sid_tt"] = "sid_tt=([^;]+)",
}) do
    local v = cookieStr:match(pattern)
    if v then
        table.insert(sessionFound, name .. "=" .. v)
    end
end

if #sessionFound > 0 then
    table.insert(diag, "✅ 找到的 session 相关字段:\n" .. table.concat(sessionFound, "\n"))
else
    table.insert(diag, "❌ 未找到 session 字段")
    table.insert(diag, "")
    table.insert(diag, "📋 排查清单：")
    table.insert(diag, "1. 是否登录了即梦？（刷新页面看看是否显示已登录状态）")
    table.insert(diag, "2. Loon 证书是否信任？（设置-通用-描述-证书信任设置）")
    table.insert(diag, "3. MITM 是否包含 jianying.com 域名？")
    table.insert(diag, "4. 是否是 HttpOnly Cookie？（浏览器无法读取，Loon 应该能）")
    table.insert(diag, "5. 尝试用 Safari 直接访问 https://jimeng.jianying.com 并刷新")
end

-- 6. 发送完整诊断
local diagStr = table.concat(diag, "\n\n")
notify("🔍 即梦诊断 v5", diagStr)

-- 7. 如果找到 sessionid，发送完整 session 信息
if #sessionFound > 0 then
    local sessionStr = table.concat(sessionFound, "\n")
    notify("✅ Session 已找到", sessionStr)
end