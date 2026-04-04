# agent-army

用 Cursor Agent 作为主控，通过 `/army` slash command 统一调度 cc（Claude Code/Kimi）和 codex（OpenAI Codex CLI），实现配额互补、能力分工、自动降级的 AI 编程工作流。

---

## 动机

| 痛点 | 解法 |
|---|---|
| Cursor Pro+ 配额有限，重任务很快耗尽 | 执行类任务外派给 cc，节省 Cursor quota |
| 单个模型能力有上限 | 不同任务用不同模型，扬长避短 |
| codex 依赖 TUN，网络不稳定时失效 | 完整降级链路，任何一方挂了不阻塞 |
| 每次新对话都要重新说明分工 | 极简 rule 提供基础认知，`/army` 在需要时拉起完整协作流程 |
| 同一套 Skill 太长，没必要次次全读 | Skill 拆主文件 + 3 个子文档，按需加载 |

---

## 工具清单

| 工具 | 接入方式 | 模型 | 特点 |
|---|---|---|---|
| **Cursor Agent** | 当前对话 | 由用户开对话时选定（不可中途切换） | 唯一实时交互节点；调度主控 |
| **cc**（Claude Code） | `<CC_PATH>` | opus[1m]，接 Kimi API | token 量大、工具丰富、可并行多实例 |
| **codex**（OpenAI Codex CLI） | `/opt/homebrew/bin/codex` | gpt-5.4（可切 mini） | 推理最强；需要 TUN |

---

## 分工原则

```
用户需求
  → 先看入口
      ├─ /army            → 完整协作流程（计划、确认、执行、汇报）
      ├─ “用 cc 干 xxx”   → 直接调 cc
      ├─ “用 codex 干 xxx”→ 直接调 codex
      └─ 其他普通请求      → Cursor 自己做或按需外派
```

**铁律：**
- `rule` 只放基础认知和入口路由，不承载完整调度逻辑
- `/army` 才进入完整协作模式：先出计划，再等确认，再执行
- 用户明确说「用 cc」或「用 codex」时，可直接调用，不必先走 `/army`
- **所有工具产出必须写到文件**，Cursor 只读摘要，保护 Cursor quota
- codex 是稀缺资源，只用在真正需要 gpt-5.4 推理的任务上
- 涉及多方协作时，计划写到 `_agent_work/plans/`，执行日志写到 `_agent_work/logs/`
- `_agent_work/` 是刻意保留在仓库里的协作样例，不需要加入 `.gitignore`

**自动外派触发条件（即使没有 `/army` 也生效）：**
- 需要对 ≥3 个文件做同类操作 → 派 cc
- 单次产出 ≥100 行 → 派 cc
- 需要深度 review 或架构决策 → 派 codex
- 连续做了 3 个以上类似的编辑步骤 → 停下来，剩余的批量派 cc

---

## 模型选择策略

### Codex

| 场景 | 模型 | 命令 |
|---|---|---|
| 简单执行、语法修复 | `gpt-5.4-mini` | `-m gpt-5.4-mini` |
| 常规任务、review | `gpt-5.4`（默认） | 不加 `-m` |
| 深度推理、复杂 bug | `gpt-5.4` + 高 effort | `-c model_reasoning_effort=high` |

### cc

用 `--effort` 控制深度，不影响费用：
- `--effort low`：梳理、简单执行、并行子任务
- 默认：常规任务
- `--effort high`：复杂分析、作为 codex 降级替代

### Cursor 自身

- 模型由用户开对话时选定，中途不可切换
- 纯执行任务 → 派给 cc，不消耗 Cursor quota
- 当前模型不够用 → 告知用户，建议开新对话换模型

---

## 降级链路

```
codex 无 TUN   → cc --effort high  或  Cursor 自己做
codex 配额紧   → 优先 gpt-5.4-mini，能用 cc 的不用 codex
Cursor quota 紧 → 重活全派 cc，Cursor 只调度汇报
两者都挂       → Cursor 独立完成，告知用户
```

---

## 常用命令速查

所有示例遵循"产出写文件、不回传大段 stdout"原则。

```bash
# /army：进入完整多 Agent 协作模式
# 例：/army 把这个模块拆分重构，先给我分工计划

# 直接调用 cc（结果写文件，tail 只看完成信号）
mkdir -p _agent_work/context
claude -p "分析结构，结果写到 _agent_work/context/cc-summary-$(date +%Y%m%d).md，最后输出'完成'" \
  --effort low --dangerously-skip-permissions 2>&1 | tail -3

# 直接调用 codex（在 prompt 里要求写文件，不依赖 -o）
mkdir -p _agent_work/logs
codex exec "<任务>。结果写到 _agent_work/logs/codex-result-$(date +%Y%m%d).md" \
  --sandbox workspace-write < /dev/null

# codex 可用性检测（每次调用前必做）
curl -s --max-time 3 https://api.openai.com > /dev/null 2>&1 && \
  codex --version > /dev/null 2>&1 && echo "codex_ok" || echo "codex_unavail"

# cc - 并行多实例（每个实例写独立文件）
mkdir -p _agent_work/reviews
claude -p "review src/auth.py，结果写到 _agent_work/reviews/cc-review-auth-$(date +%Y%m%d).md，最后输出'完成'" \
  --dangerously-skip-permissions > /dev/null 2>&1 &
claude -p "review src/api.py，结果写到 _agent_work/reviews/cc-review-api-$(date +%Y%m%d).md，最后输出'完成'" \
  --dangerously-skip-permissions > /dev/null 2>&1 &
wait

# codex - review（用 exec 包装让它写文件）
mkdir -p _agent_work/reviews
codex exec "review 当前未提交的改动，结果写到 _agent_work/reviews/codex-review-$(date +%Y%m%d).md" \
  --sandbox workspace-write < /dev/null

# 经典组合：cc 搜集 → Cursor 决策 → codex 执行 → codex review
mkdir -p _agent_work/{context,reviews}
claude -p "读项目文件，按交接模板写到 _agent_work/context/cc-arch-$(date +%Y%m%d).md，最后输出'完成'" \
  --effort low --dangerously-skip-permissions 2>&1 | tail -3
# Cursor 读 _agent_work/context/cc-arch-*.md 决定方案
codex exec "<方案>。结果写到 _agent_work/logs/codex-exec-$(date +%Y%m%d).md" \
  --sandbox workspace-write < /dev/null
codex exec "review 未提交改动，结果写到 _agent_work/reviews/codex-review-$(date +%Y%m%d).md" \
  --sandbox workspace-write < /dev/null
```
---

## 文件结构

```
agent-army/
├── README.md                        # 本文件
├── .gitignore                       # Git 忽略规则
├── install.sh                       # 一键安装到 ~/.cursor/
├── .cursor/
│   └── commands/
│       └── army.md                  # /army slash command（多 Agent 协作模式）
├── rules/
│   └── ai-dispatch.mdc              # 极简规则（cc/codex 基础认知 + 路由，每次对话自动注入）
├── skills/
│   ├── dispatch-ai-agents/
│   │   ├── SKILL.md                 # 主文件（army 流程、路由矩阵、编排模式、降级）
│   │   ├── cc-reference.md          # cc 调用模板、参数（按需加载）
│   │   ├── codex-reference.md       # codex 调用模板、模型选择（按需加载）
│   │   └── collaboration.md         # 协作文件规范、交接模板（按需加载）
│   └── check-ai-usage/
│       └── SKILL.md                 # 三方用量查看
├── docs/
│   ├── concept.md                   # 多 Agent 调度体系思路（工具无关）
│   ├── test-scenarios.md            # 分工测试任务集（迭代验证用）
│   ├── not-adopted.md               # 暂不采纳的建议留档
│   └── roadmap.md                   # 演进路线图
└── _agent_work/                     # 协作中间文件（cc/codex 输出，本仓库保留实际示例）
    ├── context/                     # 上下文摘要
    ├── plans/                       # 分工计划、方案和检查点
    ├── reviews/                     # review 结果
    └── logs/                        # 执行日志
```

---

## 安装

```bash
bash install.sh
```

自动安装 rules、commands、skills 到 `~/.cursor/`。

---

## 测试与迭代

改完规则/skill 后，用标准测试任务集验证分工是否达标：

```
改规则 → 跑 2-3 个测试任务（/army 触发，只看计划） → 记录分工占比 → 对比期望 → 继续改
```

核心指标：**Cursor 自己做的步骤 ≤ 40%**。详见 [docs/test-scenarios.md](docs/test-scenarios.md)。

---

## 演进路线图

详见 [docs/roadmap.md](docs/roadmap.md)。
