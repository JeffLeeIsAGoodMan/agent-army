# cc（Claude Code）调用参考

## 基本信息

- 路径：`<CC_PATH>`
- 模型：`opus[1m]`（Kimi），token 量大
- 所有命令加 `--dangerously-skip-permissions` 跳过确认

---

## 任务描述模板

给 cc 写 prompt 时，按以下结构组织，避免漏关键信息：

```
## 目标
一句话说明要达成什么

## 上下文
- 相关文件/背景（cc 需要知道的前提）
- 当前状态（什么已经做了、什么没做）

## 约束
- 不能改什么 / 必须遵守什么规范
- 输出格式要求

## 产物
- 结果写到 _agent_work/<子目录>/<工具>-<任务简述>-<YYYYMMDD>.md
- 最后输出「完成」
```

简单任务可以精简，但「目标」和「产物」不能省。

**何时写中间文档**：如果 prompt 超过 5 行，先写到 `_agent_work/plans/` 下，让 cc 自己读文件执行，不要硬塞进命令行。格式：`_agent_work/plans/cursor-<任务简述>-<YYYYMMDD>.md`。

---

## 按复杂度选 effort

```bash
# 纯执行（跑命令、改文件、简单梳理）
claude -p "<任务>" --effort low --dangerously-skip-permissions 2>&1

# 常规任务
claude -p "<任务>" --dangerously-skip-permissions 2>&1

# 深度分析（或 codex 不可用时的降级）
claude -p "<任务>" --effort high --dangerously-skip-permissions 2>&1
```

---

## 输出写文件（保护 Cursor token）

```bash
mkdir -p _agent_work/context
claude -p "分析结构，按交接模板写到 _agent_work/context/cc-summary-$(date +%Y%m%d).md，最后输出'完成'" \
  --effort low --dangerously-skip-permissions 2>&1 | tail -3
```

---

## 并行多实例

每个实例写独立文件，禁止并行写同一文件。

```bash
mkdir -p _agent_work/context
claude -p "任务A，结果写到 _agent_work/context/a-$(date +%Y%m%d).md" \
  --effort low --dangerously-skip-permissions > /dev/null 2>&1 &
claude -p "任务B，结果写到 _agent_work/context/b-$(date +%Y%m%d).md" \
  --effort low --dangerously-skip-permissions > /dev/null 2>&1 &
wait
```

---

## 其他常用参数

| 参数 | 用途 |
|---|---|
| `--continue` / `--resume <id>` | 续接上次 session |
| `--name <名字>` | 命名 session 便于 resume |
| `--tools "Bash,Read,Edit"` | 限制工具范围 |
| `--output-format json` | 结构化输出 |

---

## 「只让你执行」模式

用户说「直接做」「不用分析」「执行就行」时：

1. 文件操作/命令执行派给 cc（`--effort low`）
2. Cursor 只做最终验收和汇报
