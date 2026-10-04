# 即梦 Session ID 自动抓取插件

## 简介
Loon 插件，自动抓取即梦 AI 创作平台的 Session ID，通过 Bark 推送通知。

## 文件列表

| 文件 | 说明 |
|------|------|
| jimeng-session.conf | Loon 配置文件 |
| jimeng-session-extractor.lua | 基础版脚本 |
| jimeng-session-extractor-v2.lua | 调试版脚本 |
| jimeng-session-extractor-v3.lua | 增强诊断版脚本（推荐）|

## 快速开始

### 1. 导入 Loon 配置
```
https://api.github.com/repos/Maquer/loon-jimeng-session/contents/jimeng-session.conf
```

### 2. 下载脚本
```
https://api.github.com/repos/Maquer/loon-jimeng-session/contents/jimeng-session-extractor-v3.lua
```

### 3. 配置 Bark Key
脚本中已配置：
```
BARK_KEY = "Av8DkzMpStcsmsW3KfqEMc"
```

## 使用流程

1. iPhone 连接 Loon 代理
2. Safari 访问 https://jimeng.jianying.com
3. 登录即梦
4. 等待 Bark 通知推送 Session ID

## 诊断模式

v3 脚本包含诊断模式，会发送详细的调试信息：
- 捕获所有即梦相关请求
- 检查所有 Cookie 和 Header
- 查找所有可能的 session 字段
- 发送诊断通知

## 注意事项

- 需要信任 Loon 证书（HTTPS 解密）
- iPhone 必须连接 Loon 代理
- 同一 Session ID 不会重复推送

---

Created by 小蒋 | 2026-10-04
