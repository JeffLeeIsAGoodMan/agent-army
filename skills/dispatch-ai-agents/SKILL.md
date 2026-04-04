---
name: dispatch-ai-agents
description: 调度 cc（Claude Code/Kimi）和 codex（OpenAI Codex CLI）完成编程任务。当需要派发子任务给 cc 或 codex 时使用，包含模型选择、CLI 参数、降级策略、输出捕获方式。
---

# Dispatch AI Agents

调度 cc 和 codex 的完整参考，含模型选择、任务路由、协作规范。

## 环境信息

- **cc**：`<CC_PATH>`，模型固定 `opus[1m]`（Kimi），token 量大
- **codex**：`/opt/homebrew/bin/codex`，需 TUN（Clash 7890），默认 `gpt-5.4`（当前观察值，可能随版本变化）
- **我（Cursor）**：fast quota 有限，auto/API 用量分开计

---

## Codex 可用性检测（每次用 codex 前必做）

**网络 + CLI 双检**，比单纯检测 TUN 更可靠：

```bash
curl -s --max-time 3 https://api.openai.com > /dev/null 2>&1 && \
  codex --version > /dev/null 2>&1 && echo "codex_ok" || echo "codex_unavail"
```

`codex_unavail` 可能原因：网络不通、CLI 未安装、未登录、模型不可用——无论哪种都直接降级，不要尝试继续调用。

---

## 任务路由：四维决策矩阵

按 **推理强度 × 执行规模 × 失败代价 × 可验证性** 决定派给谁，而不是按任务类型：

| 推理强度 | 执行规模 | 失败代价 | 派给 |
|---|---|---|---|
| 低 | 大（文件多/并行） | 低 | **cc** |
| 低 | 小 | 低 | **Cursor 自己做** |
| 高 | 任意 | 任意 | **codex**（TUN 可用时） |
| 低 | 任意 | **高**（迁移/生产/删除） | codex 先出方案，cc 按检查点执行 |
| 高不确定 | 小 | 低，可快速验证 | cc 探路 → codex 审核方案 |

**Codex 只做高价值推理，不当第二个执行器：**
- 适合：根因分析、方案对比、patch 风险审查、边界条件识别
- 不适合：批量文件通读、机械重构、简单执行

---

## 派发前确认（铁律）

涉及多方协作的任务，**必须先向用户展示分工计划，用户确认后再执行**。

计划内容至少包含：谁做什么、用什么编排模式、预期产物路径。

计划本身写到 `_agent_work/plans/`，命名格式同协作文件规范：`cursor-<任务简述>-<YYYYMMDD>.md`。

---

## 推荐编排模式

| 模式 | 适用场景 | 流程 |
|---|---|---|
| **A** | 批量执行 | Cursor 决策 → cc 批量执行 → Cursor 验收 |
| **B** | 复杂改动 | cc 探路读上下文 → Codex 定方案 → cc 落地 → Codex review |
| **C** | 小改 + 把关 | Cursor 小改 → Codex review |
| **D** | 高风险操作 | Codex 出方案和检查点 → cc 按检查点逐步执行 → Codex 验收 |

---

## 协作文件规范

**所有 cc/codex 的输出文件写到当前项目的 `_agent_work/` 下，禁止写 `/tmp/`。**

### 子目录分层

```
_agent_work/
├── context/    # cc 搜集的上下文摘要、项目分析
├── plans/      # 分工计划、codex 出的方案、检查点
├── reviews/    # codex/cc review 结果
└── logs/       # 执行日志（每次多方协作完成后记录）
```

### 命名规范

格式：`<工具>-<任务简述>-<YYYYMMDD>.md`

```
_agent_work/context/cc-arch-summary-20260404.md
_agent_work/plans/codex-refactor-plan-20260404.md
_agent_work/reviews/codex-review-20260404.md
```

加日期后缀，重跑不覆盖旧产物，便于回溯。

> `_agent_work/` 是否 commit 由用户决定，可加入 `.gitignore`。

---

## 任务交接模板

多工具串行时，每个工具的产物必须包含以下字段，让下一棒工具可靠消费：

```markdown
## Status
success | partial | failed

## Summary
一句话总结做了什么

## Done
- 已完成的事项

## Assumptions
- 哪些是推断/猜测，非确认事实

## Open
- 未解决的问题、待验证点

## Handoff
建议下一步交给谁做什么
```

---

## 模型选择决策树

### Cursor 自身

**我无法在对话中途切换模型**，模型由用户开对话时决定。

| 场景 | 正确做法 |
|---|---|
| 纯执行任务，想省 quota | 派给 cc（`--effort low`），我只验收 |
| 需要最强推理但当前模型不够 | 告知用户，建议开新对话换模型 |
| 当前模型够用 | 直接做 |

### Codex 模型（当前推荐值，随版本可能变化）

| 场景 | 模型 | 命令 |
|---|---|---|
| 纯执行、简单重构、语法修复 | `gpt-5.4-mini` | `-m gpt-5.4-mini` |
| 常规任务、代码 review | `gpt-5.4`（默认） | 不加 `-m` |
| 复杂架构、硬 bug、深度分析 | `gpt-5.4` + 高 effort | `-c model_reasoning_effort=high` |

---

## cc 调用模板

### 按复杂度选 effort

```bash
# 纯执行（跑命令、改文件、简单梳理）
claude -p "<任务>" --effort low --dangerously-skip-permissions 2>&1

# 常规任务
claude -p "<任务>" --dangerously-skip-permissions 2>&1

# 深度分析（或 codex 不可用时的降级）
claude -p "<任务>" --effort high --dangerously-skip-permissions 2>&1
```

### 输出写文件（保护 Cursor token）

```bash
mkdir -p _agent_work/context
claude -p "分析结构，按交接模板写到 _agent_work/context/cc-summary-$(date +%Y%m%d).md，最后输出'完成'" \
  --effort low --dangerously-skip-permissions 2>&1 | tail -3
```

### 并行多实例（每个实例写独立文件，禁止并行写同一文件）

```bash
mkdir -p _agent_work/context
claude -p "任务A，结果写到 _agent_work/context/a-$(date +%Y%m%d).md" \
  --effort low --dangerously-skip-permissions > /dev/null 2>&1 &
claude -p "任务B，结果写到 _agent_work/context/b-$(date +%Y%m%d).md" \
  --effort low --dangerously-skip-permissions > /dev/null 2>&1 &
wait
# 并行结果由单线程（Cursor 或 cc 新实例）统一汇总
```

### 其他常用参数

| 参数 | 用途 |
|---|---|
| `--continue` / `--resume <id>` | 续接上次 session |
| `--name <名字>` | 命名 session 便于 resume |
| `--tools "Bash,Read,Edit"` | 限制工具范围 |
| `--output-format json` | 结构化输出 |

---

## codex 调用模板

**所有 codex exec 必须加 `< /dev/null`，否则会阻塞在等待 stdin。**

### exec（执行任务）

```bash
mkdir -p _agent_work/logs

# 轻量执行（mini 模型，省配额）
codex exec "<任务>" \
  -m gpt-5.4-mini \
  --sandbox workspace-write \
  --ephemeral \
  -o _agent_work/logs/codex-result-$(date +%Y%m%d).md < /dev/null

# 常规任务
codex exec "<任务>" \
  --sandbox workspace-write \
  -o _agent_work/logs/codex-result-$(date +%Y%m%d).md < /dev/null

# 深度推理
codex exec "<任务>" \
  -c model_reasoning_effort=high \
  --sandbox workspace-write < /dev/null
```

### review

```bash
mkdir -p _agent_work/reviews
codex review --uncommitted < /dev/null
codex review --base <分支名> < /dev/null
codex review --commit <SHA> < /dev/null
```

---

## 「只让你执行」模式

用户说「直接做」「不用分析」「执行就行」时：

1. 真正的文件操作/命令执行派给 cc（`--effort low`）
2. 我只做最终验收和汇报，不消耗 Cursor quota

---

## 降级策略

```
codex_unavail（网络/CLI/登录任一失败）：
  → review/推理 → cc --effort high  或  Cursor 自己做
  → 执行 → cc 正常处理

codex 配额紧张：
  → 优先用 gpt-5.4-mini
  → 能用 cc 的不用 codex

Cursor fast quota 紧张：
  → 重活全派 cc，我只做调度和汇报
  → 告知用户配额情况

两者都挂：
  → 我独立完成，告知用户
```

---

## 经典编排示例

```bash
# 模式 B：cc 探路 → Codex 定方案 → cc 落地 → Codex review
mkdir -p _agent_work/{context,plans,reviews}

# Step 1: cc 读上下文
claude -p "读所有 .swift 文件，按交接模板输出到 _agent_work/context/cc-arch-$(date +%Y%m%d).md" \
  --effort low --dangerously-skip-permissions 2>&1 | tail -3

# Step 2: Cursor 读摘要，让 codex 定方案
codex exec "读 _agent_work/context/cc-arch-*.md，给出重构方案和检查点，写到 _agent_work/plans/codex-plan-$(date +%Y%m%d).md" \
  --sandbox workspace-write < /dev/null

# Step 3: cc 按方案落地
claude -p "读 _agent_work/plans/codex-plan-*.md，按检查点执行改动" \
  --dangerously-skip-permissions 2>&1 | tail -3

# Step 4: codex review
codex review --uncommitted < /dev/null
```
