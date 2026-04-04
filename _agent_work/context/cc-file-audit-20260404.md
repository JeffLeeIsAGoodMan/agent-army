# 文件审计报告

**审计日期**: 2026-04-04  
**审计范围**: agent-army 项目根目录（排除 .git）  
**审计人**: Claude Code  

---

## 分类说明

- **COMMIT**: 应提交到远程仓库，供他人使用
- **IGNORE**: 应加入 .gitignore，本地产物/含敏感信息/临时文件

---

## 文件清单

| 文件路径 | 分类 | 原因 |
|---------|------|------|
| `README.md` | **COMMIT** | 项目说明文档，需供他人阅读 |
| `docs/concept.md` | **COMMIT** | 项目概念文档，需供他人阅读 |
| `docs/not-adopted.md` | **COMMIT** | 项目文档，需供他人阅读 |
| `install.sh` | **COMMIT** | 安装脚本，需供他人使用 |
| `cursor-settings-rules.txt` | **COMMIT** | Cursor 规则配置模板，需供他人使用 |
| `rules/ai-dispatch.mdc` | **COMMIT** | AI 调度规则，需供他人使用 |
| `skills/check-ai-usage/SKILL.md` | **COMMIT** | Skill 文档，需供他人使用 |
| `skills/dispatch-ai-agents/SKILL.md` | **COMMIT** | Skill 文档，需供他人使用 |
| `cursor-settings-rules-local.txt` | **IGNORE** | 含本地绝对路径，敏感信息 |
| `_agent_work/reviews/cc-suggestions-20260404.md` | **IGNORE** | 协作中间产物，本地生成 |
| `_agent_work/reviews/codex-suggestions-20260404.md` | **IGNORE** | 协作中间产物，本地生成 |
| `_agent_work/context/cc-project-overview-20260404.md` | **IGNORE** | 协作中间产物，本地生成 |
| `_agent_work/context/cc-file-audit-20260404.md` | **IGNORE** | 本文件，协作中间产物 |
| `_agent_work/plans/cursor-gitignore-plan-20260404.md` | **IGNORE** | 协作中间产物，本地生成 |

---

## 建议的 .gitignore 内容

```gitignore
# 本地配置文件（含敏感路径）
cursor-settings-rules-local.txt

# 协作中间产物目录
_agent_work/
```

---

## 统计

- **COMMIT**: 8 个文件
- **IGNORE**: 6 个文件
- **总计**: 14 个文件

---

## 备注

- `_agent_work/` 目录为 Claude Code 协作工作目录，存放临时审查报告、计划文档等，不应提交
- `cursor-settings-rules-local.txt` 包含本地绝对路径等环境敏感信息，不应提交
