-- LuLuLaLa 小蒋出品
-- 即梦 Session ID 自动抓取 + Bark 推送
-- 创建：2026-10-04
-- 版本：1.0.0

-- ============================================
-- 配置区（请修改）
-- ============================================

BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"  -- ← 你的 Bark Key
BARK_ICON = "https://www.jianying.com/favicon.ico"
BARK_SOUND = "pop"  -- 通知声音
BARK_GROUP = "jimeng"  -- 分组名
BARK_IS_ARCHIVE = 1  -- 1=归档, 0=不归档
BARK_CLICK_URL = "https://jimeng.jianying.com"  -- 点击跳转

-- ============================================
-- 去重配置
-- ============================================

-- 缓存文件路径（Loon 沙盒内）
CACHE_FILE = "/tmp/jimeng_last_session.txt"
-- 通知间隔（秒），0=每次都发
NOTIFY_INTERVAL = 0

-- ============================================
-- 主逻辑
-- ============================================

-- 从 Cookie 头提取 sessionid
local function extractSessionId(headers)
    local cookieHeader = headers["cookie"] or headers["Cookie"] or ""
    for sid in cookieHeader:gmatch("sessionid=([^;]+)") do
        return sid
    end
    return nil
end

-- 检查是否已推送过
local function isDuplicate(sessionId)
    local cache = io.open(CACHE_FILE, "r")
    if not cache then
        return false
    end
    local cached = cache:read("*all")
    cache:close()
    return cached == sessionId
end

-- 保存已推送记录
local function saveCache(sessionId)
    local cache = io.open(CACHE_FILE, "w")
    if cache then
        cache:write(sessionId)
        cache:close()
    end
end

-- 发送 Bark 通知
local function sendBark(sessionId)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local title = "✅ 即梦 Session ID"
    local body = string.format(
        "🎯 抓取成功！\n\n🔑 Session: %s\n\n⏰ 时间：%s\n\n📋 使用方法：\n1. 复制 Session ID\n2. 设置环境变量：\nexport JIMENG_SESSION_ID=\"%s\"\n3. 运行海报生成脚本\n\n🎨 下一步：生成手绘风格封面",
        sessionId,
        timestamp,
        sessionId
    )
    
    -- Bark API URL 编码
    local encodedBody = body:gsub("\n", "%0A"):gsub(" ", "%%20")
    local url = string.format(
        "https://api.day.app/%s/%s/%s?icon=%s&sound=%s&group=%s&isArchive=%s&copy=%s&click=%s",
        BARK_KEY,
        title,
        encodedBody,
        BARK_ICON,
        BARK_SOUND,
        BARK_GROUP,
        BARK_IS_ARCHIVE,
        "0",
        BARK_CLICK_URL
    )
    
    -- 发送通知
    http.get(url, function(response)
        if response.status == 200 then
            print("[OK] Bark 通知已发送")
            saveCache(sessionId)
        else
            print("[FAIL] Bark 通知失败: " .. response.status)
        end
    end)
end

-- ============================================
-- 入口：处理响应
-- ============================================

-- 检查域名是否为即梦
if not response.url:find("jimeng\\.jianying\\.com", 1, true) then
    return
end

-- 提取 sessionid
local sessionId = extractSessionId(response.headers)
if not sessionId then
    print("[SKIP] 未找到 sessionid")
    return
end

print(string.format("[FOUND] sessionid: %s", sessionId))

-- 检查是否重复
if isDuplicate(sessionId) then
    print("[SKIP] 已推送过，跳过")
    return
end

-- 发送通知
sendBark(sessionId)