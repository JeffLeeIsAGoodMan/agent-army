---
name: check-ai-usage
description: 查看 Kimi（cc）、Codex、Cursor 三方 AI 工具的当前使用量和余额。当用户说「看看用量」「余量还有多少」「各方还剩多少」「check usage」时使用。通过浏览器截图三个控制台页面，汇总成一张表展示给用户。
---

# Check AI Usage

查看三方 AI 工具余量：Kimi（cc）、Codex、Cursor。

## 步骤

1. **检测 TUN 可用性**（影响 Codex 是否可访问）：
```bash
curl -s --max-time 3 https://api.openai.com > /dev/null 2>&1 && echo "tun_ok" || echo "no_tun"
```

2. **用 Chrome DevTools 依次截图三个页面**，页面可能已经打开，先用 `list_pages` 检查，有则直接 select，没有则 navigate：

| 工具 | URL |
|---|---|
| Kimi（cc） | https://www.kimi.com/code/console |
| Codex | https://chatgpt.com/codex/settings/usage |
| Cursor | https://cursor.com/cn/dashboard/spending |

3. **从截图中提取关键数字**，汇总输出：

```
| 工具    | 指标         | 当前值 | 说明 |
|---------|-------------|--------|------|
| Kimi    | 本周用量     | x%     | 重置时间 |
| Kimi    | 频率限制     | x%     | 重置时间 |
| Codex   | 5小时限额    | x% 剩余 | 重置时间 |
| Codex   | 每周限额     | x% 剩余 | 重置时间 |
| Codex   | 代码审查     | x% 剩余 | — |
| Cursor  | 总用量       | x%     | 重置时间 |
| Cursor  | 当前套餐     | Pro/Pro+ | — |
```

4. **给出简短判断**：哪方最紧张、哪方最充裕、当前是否适合跑大任务。

## 降级处理

- Codex 页面需要 TUN，无 TUN 时跳过并标注「TUN 不可用，跳过」
- 页面未登录时告知用户手动登录后重试
