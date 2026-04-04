# 更新 docs/ 下三个文件

## 目标

docs/ 下的 concept.md、roadmap.md、not-adopted.md 与当前架构脱节，需要同步更新。

## 上下文

项目刚完成一次架构重构，核心变化：

1. 新增 `/army` slash command 作为协作入口，用户手动触发才走协作流程
2. rule 精简到 ~10 行（只放基础认知+路由），不再承载完整调度逻辑
3. skill 拆成主文件 + 3 个子文档（cc-reference.md、codex-reference.md、collaboration.md）按需加载
4. 删掉了 cursor-settings-rules.txt 和 cursor-settings-rules-local.txt
5. 加了任务描述模板（目标/上下文/约束/产物）
6. 验证了 `~/.cursor/rules/` 全局生效

核心理念变化：**协作是按需触发的（/army），不是每次对话的默认行为**。用户说"用 cc 干 xxx"可以直接调用，不需要走计划流程。

## 三个文件的改动要点

### concept.md

- 第二章（三个角色）：调度者角色修正——默认自己做，/army 才分工
- 第三章（核心原则）：新增"用户控制协作时机"原则
- 第六章（持久化）：改为三层架构 rule→command→skill，不再是"全局规则写入完整分工"
- 第九章（从零搭建）：步骤重排，加入 command 和 skill 分层
- 其他章节（动机、路由矩阵、编排模式、反模式等）不涉及具体实现，不用改

### roadmap.md

- 现状描述：改为当前架构（/army + 极简 rule + skill 分层）
- 已完成列表：加上本次改动
- 1.1：标为 ✅ 已完成
- 1.3：删掉"自动生成 local 版本"
- 3.1（用量感知调度）：标注与当前理念冲突，降级为可选
- 3.2（dispatch.sh）：标注不再计划
- 决策记录：加一行本次架构重构
- 优先级建议：更新

### not-adopted.md

- 结构化任务输入：改为"部分采纳"（已加 Markdown 任务描述模板）
- 用量与调度阈值联动：改为"不再计划"
- 其他条目不动

## 约束

- 保持 concept.md 的"工具无关"定位，用举例而非硬编码
- 保持各文件原有的行文风格
- 不要改 _agent_work/ 下的其他文件

## 产物

- 直接修改 docs/concept.md、docs/roadmap.md、docs/not-adopted.md
- 最后输出「完成」
