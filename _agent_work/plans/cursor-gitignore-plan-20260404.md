# 分工计划：.gitignore + 首次 commit

**任务**：为 agent-army 制定 `.gitignore`，规划首次 commit 文件范围。

**编排模式**：模式 B（cc 探路 → Cursor 决策 → codex review）

**日期**：2026-04-04

---

## 步骤

| 步骤 | 执行者 | 任务 | 产物 |
|---|---|---|---|
| Step 0 | Cursor | 写分工计划 | `_agent_work/plans/cursor-gitignore-plan-20260404.md`（本文件） |
| Step 1a | cc `--effort low` | 扫描项目所有文件，逐个列出是否应 commit 及原因 | `_agent_work/context/cc-file-audit-20260404.md` |
| Step 1b | cc `--effort low` | 根据项目性质生成 `.gitignore` 初稿 | `_agent_work/context/cc-gitignore-draft-20260404.md` |
| Step 2 | Cursor | 读取 Step 1 两份产物，综合判断，生成最终 `.gitignore` | 项目根目录 `.gitignore` |
| Step 3 | codex | review `.gitignore` 和 commit 范围的合理性 | `_agent_work/reviews/codex-gitignore-review-20260404.md` |
| Step 4 | Cursor | 汇总 review 意见，修正，向用户汇报，确认后执行首次 commit | 最终 commit |

## 降级预案

- codex 不可用 → Step 3 改由 cc `--effort high` 执行
- cc 不可用 → Cursor 独立完成全部步骤

## 备注

- Step 1a 和 Step 1b 并行执行，写独立文件，无冲突
- `_agent_work/` 本身应被 `.gitignore` 排除（或由用户决定是否 commit）
- `cursor-settings-rules-local.txt` 含本地路径，不应 commit
