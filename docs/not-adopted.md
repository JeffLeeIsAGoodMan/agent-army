# 暂不采纳的建议

来源：cc 和 codex 对本项目的 review（2026-04-04），原始建议见 `_agent_work/cc-suggestions.md` 和 `_agent_work/codex-suggestions.md`。

---

## 结构化任务输入（JSON 格式）

**来源**：cc

建议用 JSON 或固定 Markdown 模板描述派发给 cc/codex 的任务，包含 task_type、context_files、output_format、constraints 等字段。

**暂不采纳原因**：自然语言描述目前够用，加格式约束会增加日常使用的摩擦。如果未来发现任务理解频繁出错，再引入。

---

## 错误码体系

**来源**：cc

建议定义 E001（权限不足）、E002（文件不存在）、E003（任务过于复杂）等错误码，让 cc/codex 以结构化方式向 Cursor 汇报失败原因。

**暂不采纳原因**：cc 在输出文件里用自然语言描述错误已经够用，维护一套错误码体系的成本高于收益。

---

## 权限三级细分

**来源**：cc、codex

建议把 `--dangerously-skip-permissions` 从默认命令降级为特例，区分只读/工作区写/高风险三级权限策略。

**暂不采纳原因**：目前任务都在可控范围内，`--dangerously-skip-permissions` 带来的便利性收益大于风险。若未来出现误操作事故，再收紧。

---

## 用量与调度阈值联动

**来源**：codex

建议把 check-ai-usage 的结果接入调度决策，当 Cursor fast quota 低于阈值时自动禁止大上下文读取，Codex 周额度低时只保留 review 用途等。

**暂不采纳原因**：需要写自动化检测脚本，当前手动 check 用量够用。等调度频率高到需要自动化时再实现。

---

## review 输出结构化（Confirmed/Inferred/Needs Verification）

**来源**：codex

建议 Codex 的 review 产物固定包含三个区块：已确认、推断、待验证，以及 Findings/Severity/Suggested fix/Verification status 等字段。

**暂不采纳原因**：可以作为 prompt 提示语加入任务描述，不必写成硬规范。用自然语言 prompt 引导 codex 分层输出成本更低。

---

## 任务大小预拆分机制

**来源**：cc

建议定义任务大小评估标准（文件数、预估 token 数、步骤数），超过阈值时 Cursor 预先拆分或 cc 返回建议拆分方案。

**暂不采纳原因**：目前任务规模可控，拆分逻辑由 Cursor 在调度时按经验判断即可，不需要形式化。

---

## 模型名能力探测

**来源**：codex

建议不硬编码模型名，增加"能力探测"步骤，把"默认模型"表述为"当前观察值"而非强约束事实。

**部分采纳**：已在 skill 里把模型名标注为"当前推荐值，随版本可能变化"。完整的运行时探测机制暂不实现。
