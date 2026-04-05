## 目标

检查 skills/dispatch-ai-agents/ 下 4 个 md 文件之间的引用一致性。

## 上下文

目标文件：
1. skills/dispatch-ai-agents/SKILL.md
2. skills/dispatch-ai-agents/cc-reference.md
3. skills/dispatch-ai-agents/codex-reference.md
4. skills/dispatch-ai-agents/collaboration.md

这 4 个文件组成一个 skill 的文档体系，SKILL.md 是主文件，其他三个是子文档。
主文件 SKILL.md 底部有子文档索引表，引用了其他三个文件。

## 约束

检查以下内容：
1. SKILL.md 的子文档索引表中的文件名是否与实际文件名一致
2. 文件之间有没有断链（引用了不存在的文件或锚点）
3. 文件内部有没有引用不一致的地方（如同一概念用了不同名称）
4. 各文件中对 cc/codex 的描述是否一致（路径、参数名等）

## 产物

- 结果写到 _agent_work/reviews/cc-ref-check-20260404.md
- 使用交接模板格式（Status / Summary / Done / Assumptions / Open / Handoff）
- 最后输出「完成」
