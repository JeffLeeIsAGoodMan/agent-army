## 目标

批量修改 skills/dispatch-ai-agents/ 下的 4 个 md 文件，统一格式。

## 上下文

目标文件：
1. skills/dispatch-ai-agents/SKILL.md
2. skills/dispatch-ai-agents/cc-reference.md
3. skills/dispatch-ai-agents/codex-reference.md
4. skills/dispatch-ai-agents/collaboration.md

## 约束

对每个文件做以下两项修改：

1. **在文件最开头（frontmatter 之后、正文之前）加一行**：`> 最后更新：2026-04-04`，后跟一个空行
   - 如果文件有 YAML frontmatter（`---` 包围），加在 frontmatter 结束的 `---` 之后
   - 如果没有 frontmatter，加在第一行之前
2. **所有 `#` 一级标题改为带编号**：按出现顺序编号为 `# 1. xxx`、`# 2. xxx`、`# 3. xxx`...
   - 只改一级标题（`# `），二级及以下标题不动
   - 如果一级标题已经有编号，跳过

不要改动文件的其他内容。

## 产物

- 直接原地修改 4 个文件
- 最后输出「完成」
