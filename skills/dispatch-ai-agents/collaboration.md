# 协作文件规范

多方协作时的文件管理和交接规范。

---

## 文件目录

所有 cc/codex 的输出文件写到当前项目的 `_agent_work/` 下，禁止写 `/tmp/`。

```
_agent_work/
├── context/    # cc 搜集的上下文摘要、项目分析
├── plans/      # 分工计划、codex 出的方案、检查点
├── reviews/    # codex/cc review 结果
└── logs/       # 执行日志（每次多方协作完成后记录）
```

---

## 中间文档规则

给 cc/codex 的任务 prompt 超过 5 行时，必须先写成文档再让它读取执行，不要硬塞进命令行。

- 写到 `_agent_work/plans/`，命名格式同下方规范
- 文档内容按任务描述模板组织（目标/上下文/约束/产物）
- 执行命令变为：`claude -p "读 _agent_work/plans/xxx.md，按要求执行，最后输出'完成'"`

5 行以内的简单任务可以直接写在 prompt 里。

---

## 命名规范

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

多工具串行时，每个工具的产物必须包含以下字段：

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
