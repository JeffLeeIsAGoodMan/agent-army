# codex（OpenAI Codex CLI）调用参考

## 基本信息

- 路径：`/opt/homebrew/bin/codex`
- 默认模型：`gpt-5.4`（当前观察值，可能随版本变化）
- 需要 TUN（Clash 7890）
- **所有 codex exec 必须加 `< /dev/null`，否则会阻塞在等待 stdin**

---

## 可用性检测（每次调用前必做）

```bash
curl -s --max-time 3 https://api.openai.com > /dev/null 2>&1 && \
  codex --version > /dev/null 2>&1 && echo "codex_ok" || echo "codex_unavail"
```

`codex_unavail` → 直接降级，不要尝试继续调用。

---

## 任务描述模板

给 codex 写 prompt 时，按以下结构组织：

```
## 目标
一句话说明要达成什么

## 上下文
- 相关文件/背景（codex 需要知道的前提）
- 当前状态（什么已经做了、什么没做）

## 约束
- 不能改什么 / 必须遵守什么规范
- 输出格式要求

## 产物
- 结果写到 _agent_work/<子目录>/<工具>-<任务简述>-<YYYYMMDD>.md
```

简单任务可以精简，但「目标」和「产物」不能省。

**何时写中间文档**：如果 prompt 超过 5 行，先写到 `_agent_work/plans/` 下，让 codex 自己读文件执行，不要硬塞进命令行。格式：`_agent_work/plans/cursor-<任务简述>-<YYYYMMDD>.md`。

---

## 模型选择

| 场景 | 模型 | 命令 |
|---|---|---|
| 纯执行、简单重构、语法修复 | `gpt-5.4-mini` | `-m gpt-5.4-mini` |
| 常规任务、代码 review | `gpt-5.4`（默认） | 不加 `-m` |
| 复杂架构、硬 bug、深度分析 | `gpt-5.4` + 高 effort | `-c model_reasoning_effort=high` |

Codex 只做高价值推理，不当第二个执行器：
- 适合：根因分析、方案对比、patch 风险审查、边界条件识别
- 不适合：批量文件通读、机械重构、简单执行

---

## exec（执行任务）

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

---

## review

```bash
mkdir -p _agent_work/reviews
codex review --uncommitted < /dev/null
codex review --base <分支名> < /dev/null
codex review --commit <SHA> < /dev/null
```
