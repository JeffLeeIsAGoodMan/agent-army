## Status
success

## Summary
本项目是一个以 Cursor Agent 为主控，统一调度 Claude Code（cc）和 OpenAI Codex CLI 的多 Agent 协作配置仓库，包含全局规则、技能手册、安装脚本和理念文档。

## Done
- 读取并分析了 9 个项目文件（已排除 `.git/` 和 `_agent_work/`）
- 梳理出文档层、配置层、脚本层、技能层四层结构
- 明确了每个文件的具体职责和相互关系
- 总结出三方调度原则（Cursor 调度、cc 执行、codex 顾问）、降级链路和协作规范

## Assumptions
- 用户当前环境已安装 Cursor，并计划将规则粘贴到 Settings → Rules for AI
- `<CC_PATH>` 在安装脚本运行后会根据本地 `claude` 命令位置自动替换
- `_agent_work/` 作为协作中间目录，由各 Agent 按需写入但不会自动 commit
- `cursor-settings-rules-local.txt` 比 `cursor-settings-rules.txt` 多了 Ignore 规则，可能用于本地已安装场景

## Open
- `~/.cursor/rules/` 是否被 Cursor 识别为全局目录尚未验证
- session 续接机制（cc `--resume`、codex `exec resume --last`）尚未实现
- 自动调度脚本和用量监控低于阈值自动切换策略尚未实现

## Handoff
- 若用户需要部署，运行 `bash install.sh` 并将 `cursor-settings-rules.txt` 内容粘贴到 Cursor Settings → Rules for AI
- 若需扩展技能，参考 `skills/dispatch-ai-agents/SKILL.md` 的调用模板和 `docs/concept.md` 的思路文档

---

# 项目结构与文件职责

## 1. 文档层（docs/）

| 文件 | 职责 |
|------|------|
| `docs/concept.md` | 工具无关的多 Agent 调度体系思路文档。定义调度者（Dispatcher）、执行者（Executor）、顾问（Consultant）三角色，阐述核心调度原则、任务路由四维决策矩阵、编排模式、反模式和从零搭建步骤。 |
| `docs/not-adopted.md` | 记录 cc 和 codex 对项目 review 后**暂不采纳**的建议及原因，包括结构化任务输入、错误码体系、权限三级细分、用量与调度阈值联动、review 输出结构化、任务大小预拆分机制、模型名能力探测等。 |

## 2. 配置层（Cursor 规则）

| 文件 | 职责 |
|------|------|
| `cursor-settings-rules.txt` | 供用户粘贴到 **Cursor Settings → Rules for AI** 的分工规则，说明三方 AI 工具（Cursor / cc / codex）的角色、调度、降级策略和技能引用。 |
| `cursor-settings-rules-local.txt` | 在基础版之上增加了 **Ignore** 段落，明确要求忽略 `_agent_work/`、`.git/`、`node_modules/`、`.venv/`、`__pycache__/`、`.env` 等敏感或缓存目录。 |
| `rules/ai-dispatch.mdc` | Cursor 全局规则文件（`alwaysApply: true`），以表格和流程图形式固化角色定位、调度原则、模型选择、降级策略和 Token 保护规范。安装后位于 `~/.cursor/rules/`。 |

## 3. 脚本层

| 文件 | 职责 |
|------|------|
| `install.sh` | 一键安装脚本。功能包括：探测 `claude` 命令路径、将 `rules/ai-dispatch.mdc` 和 `skills/*/` 安装到 `~/.cursor/rules/` 和 `~/.cursor/skills/`、替换文件中的 `<CC_PATH>` 占位符。 |

## 4. 技能层（skills/）

| 文件 | 职责 |
|------|------|
| `skills/dispatch-ai-agents/SKILL.md` | 调度 cc 和 codex 的**完整参考手册**。包含环境信息、Codex 可用性检测、任务路由四维决策矩阵、编排模式（A/B/C/D）、协作文件规范（`_agent_work/` 子目录和命名规则）、任务交接模板、模型选择决策树、cc/codex 调用模板、降级策略和经典编排示例。 |
| `skills/check-ai-usage/SKILL.md` | 查看三方 AI 工具（Kimi / Codex / Cursor）用量余额的技能文档。包含 TUN 检测、Chrome DevTools 截图三个控制台页面、用量汇总表格、简短判断和降级处理。 |

## 5. 项目入口

| 文件 | 职责 |
|------|------|
| `README.md` | 项目主文档。介绍 agent-army 的动机（配额互补、能力分工、自动降级）、工具清单、分工原则、模型选择策略、降级链路、常用命令速查、文件结构、安装方式和待完善事项清单。 |
