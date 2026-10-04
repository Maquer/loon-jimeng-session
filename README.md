# 即梦 Session ID 自动抓取插件

## 简介
Loon 插件，自动抓取即梦 AI 创作平台的 Session ID，通过 Bark 推送通知。

## 版本说明

| 版本 | 文件 | 说明 |
|------|------|------|
| v1 | jimeng-session-extractor.lua | 基础版 |
| v3 | jimeng-session-extractor-v3.lua | 调试版 |
| **v5** | **jimeng-session-extractor-v5.lua** | **增强诊断版（推荐）** |

## 快速开始

### 1. 导入 Loon 配置

在 Loon 中点击「网络导入」，粘贴以下 URL：
```
https://api.github.com/repos/Maquer/loon-jimeng-session/contents/jimeng-session.conf
```

### 2. 下载 v5 脚本

在 Safari 中访问：
```
https://api.github.com/repos/Maquer/loon-jimeng-session/contents/jimeng-session-extractor-v5.lua
```

复制 `content` 字段中的 Base64 内容，解码后保存为 `jimeng-session-extractor-v5.lua`。

或者直接在 Loon 中通过「脚本管理」添加。

### 3. 配置 Bark Key

脚本中已配置：
```
BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
```

如需修改，编辑 Lua 脚本替换 Key 值。

### 4. 启用插件

在 Loon 中：
- **脚本管理** → 启用 `jimeng-session-extractor-v5.lua`
- **MITM** → 开启 HTTPS 解密
- **网络代理** → 连接代理

## 使用流程

```
1. iPhone 连接 Loon 代理
   ↓
2. Safari 访问 https://jimeng.jianying.com
   ↓
3. 登录即梦
   ↓
4. 刷新页面触发 API 请求
   ↓
5. 收到 Bark 通知推送 Session ID
```

## 诊断模式

v5 脚本包含诊断模式，会发送详细的调试信息：
- 捕获所有即梦相关请求
- 检查所有 Cookie 和 Header
- 查找所有可能的 session 字段
- 发送诊断通知

## 排查问题

如果登录即梦后没有收到 Session ID 通知：

1. **检查 MITM 是否开启**
   - Loon → 编辑配置 → MITM → 确认 `*.jianying.com` 已添加

2. **检查证书是否信任**
   - iPhone 设置 → 通用 → 关于本机 → 证书信任设置 → 信任 Loon 证书

3. **检查脚本是否启用**
   - Loon → 脚本管理 → 确认 `jimeng-session-extractor-v5.lua` 已启用

4. **检查网络代理**
   - iPhone 必须连接 Loon 代理才能抓包

5. **查看诊断通知**
   - v5 脚本会发送详细的诊断信息到 Bark
   - 如果收到「未找到 sessionid」通知，说明脚本执行但没找到

## 注意事项

- 需要信任 Loon 证书（HTTPS 解密）
- iPhone 必须连接 Loon 代理
- 同一 Session ID 不会重复推送（去重缓存）
- sessionid 是 HttpOnly Cookie，只能通过 Loon 抓包获取

---

Created by 小蒋 | 2026-10-04
