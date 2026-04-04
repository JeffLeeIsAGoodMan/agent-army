# 多 Agent 协作体系：从想法到落地的演进

> 本文记录的是搭建多 AI 工具协作体系的**思考过程**——不是最终方案的说明书，而是一路走来的取舍和弯路。具体工具名称只作举例，思路本身不绑定任何特定工具。

---

## 零、起点：一个人不够用了

大多数人用 AI 编程工具的方式是：打开一个对话，做一件事。工具不够聪明就换一个，配额用完就等明天。

问题出在你同时拥有多个 AI 工具的时候——每个都有明确的长板和短板：

```mermaid
block-beta
  columns 4
  space header1["优势"] header2["短板"] space:1
  A["Cursor Agent\n（调度者）"] A1["实时交互\n理解需求"] A2["配额有限\n做重活快耗尽"] space:1
  B["Claude Code\n（执行者）"] B1["token 量大\n可并行"] B2["非交互式\n不能实时对话"] space:1
  C["Codex CLI\n（顾问）"] C1["推理最强\ngpt-5.4"] C2["依赖 VPN\n最贵最慢"] space:1

  style A fill:#4A90D9,color:#fff
  style B fill:#D4A843,color:#fff
  style C fill:#7B68EE,color:#fff
  style A1 fill:#E8F5E9
  style B1 fill:#E8F5E9
  style C1 fill:#E8F5E9
  style A2 fill:#FFEBEE
  style B2 fill:#FFEBEE
  style C2 fill:#FFEBEE
```

单独用任何一个，都会在某个维度上撞墙。**核心矛盾是：每个工具都有长板和短板，而你的任务不会只落在一个工具的舒适区里。**

自然的想法：让它们分工。

---

## 一、第一版：写一个大 Rule，告诉 AI 该怎么分工

最直觉的做法是写一个详细的全局规则（Rule），每次对话自动注入，告诉 Cursor：

- 你有 cc 和 codex 两个帮手
- 什么任务该派给谁
- 怎么调用、怎么降级

第一版 Rule 写了几十行，包含角色定义、模型选择决策树、调用模板、降级策略……基本上把所有你能想到的东西都塞进去了。

```mermaid
flowchart LR
  subgraph Rule["Rule（~80 行，每次对话都注入）"]
    R1["角色定义"]
    R2["模型选择决策树"]
    R3["cc 调用模板"]
    R4["codex 调用模板"]
    R5["降级策略"]
    R6["协作规范"]
  end
  User["每次对话"] --> Rule
  Rule --> AI["AI 开始工作"]

  style Rule fill:#FFEBEE,stroke:#C62828
  style User fill:#E3F2FD
  style AI fill:#E8F5E9
```

**问题马上来了：**

### 问题 1：Rule 太长，每次对话都要消耗大量 token

Rule 是每次对话都会注入的。写了 80 行的 Rule 意味着每次对话开头，AI 都要先"读"完这 80 行才开始干活。这些 token 大部分时候是浪费的——你 90% 的对话根本不需要协作。

### 问题 2：AI 过度热心地分工

Rule 里详细写了"什么任务该派给谁"，结果 AI 对着简单任务也开始分析"这个要不要派给 cc"。用户只是想改一行代码，AI 却先给你出了一个三方协作计划。

### 问题 3：调用模板写在 Rule 里，改一次就要重新测试全局生效

cc 的参数改了，或者 codex 的调用方式变了，你得去改 Rule。Rule 是全局的，改错了影响所有对话。

**教训：Rule 应该极简。它是"基础认知"，不是"操作手册"。**

---

## 二、第二版：拆分 Rule 和 Skill

解决第一版问题的思路是**分层**：

```mermaid
flowchart LR
  User["每次对话"] --> Rule["Rule（~10 行）\n基础认知 + 路由"]
  Rule -->|需要协作时| Skill["Skill（按需加载）\n调用模板 / 参数 / 降级"]
  Rule -->|不需要时| AI["AI 直接工作"]
  Skill --> AI

  style Rule fill:#E8F5E9,stroke:#2E7D32
  style Skill fill:#FFF3E0,stroke:#E65100
  style User fill:#E3F2FD
  style AI fill:#E8F5E9
```

- **Rule（~10 行）**：只放最基本的认知——"你有 cc 和 codex 两个帮手，用户说用 cc 时调 cc，说用 codex 时调 codex"。每次对话都加载，但成本极低。
- **Skill（按需加载）**：完整的调用模板、参数说明、降级策略写成 Skill 文档，只有需要时才读取。

这解决了 token 浪费和模板维护的问题。但还剩一个核心问题：**什么时候该走完整的协作流程？**

如果让 AI 自己判断"这个任务需不需要多方协作"，它判断得并不好。有时候简单任务被过度拆解，有时候复杂任务它直接自己做了。

**教训：不要让 AI 判断"是否需要协作"。这个决定应该由用户来做。**

---

## 三、第三版：用户触发协作（/army 命令）

关键转折点是一个设计原则的确立：**协作是按需触发的，不是默认行为。**

```mermaid
flowchart TD
  User["用户输入"] --> Check{"入口判断"}
  Check -->|普通请求| Self["Cursor 自己做"]
  Check -->|"用 cc 干 xxx"| CC["直接调 cc\n不需要确认"]
  Check -->|"用 codex 干 xxx"| Codex["直接调 codex\n不需要确认"]
  Check -->|"/army"| Plan["完整协作流程"]

  Plan --> Step1["1. 分析任务"]
  Step1 --> Step2["2. 出分工计划"]
  Step2 --> Step3["3. 等用户确认"]
  Step3 --> Step4["4. 执行"]

  style Check fill:#FFF9C4,stroke:#F57F17
  style Self fill:#E8F5E9
  style CC fill:#FFF3E0
  style Codex fill:#F3E5F5
  style Plan fill:#E3F2FD
  style Step3 fill:#FFCDD2,stroke:#C62828
```

**为什么不让 AI 自动路由？** 因为用户对"这个任务值不值得多方协作"有自己的判断。自动路由带来的便利不如它造成的意外多——用户不知道 AI 什么时候会突然启动一个复杂的协作流程。明确的触发机制让用户有预期。

一个完整的 `/army` 调用看起来像这样：

```
[用户]  /army 重构 utils.py 中的日期处理函数

[Cursor] 分析任务 → 输出分工计划表 → 等用户确认

[用户]  确认

[Cursor] 写任务描述到 _agent_work/plans/refactor-date-20260404.md
[Cursor] 调用 cc：读 plans/... 执行重构
[cc]    执行完成，结果写到 _agent_work/context/cc-refactor-20260404.md

[Cursor] 读摘要，调用 codex review 未提交改动
[codex]  review 结果写到 _agent_work/reviews/codex-review-20260404.md

[Cursor] 读 review 摘要，向用户汇报
```

注意调度者（Cursor）全程只读摘要，不直接消费大段输出。

---

## 四、Skill 也太长了：子文档拆分

Skill 解决了 Rule 太长的问题，但 Skill 本身也会变长。当 cc 的调用模板、codex 的调用模板、协作文件规范、交接模板都放在同一个 SKILL.md 里时，它又变成了一个几百行的大文件。

而实际使用中，不同场景需要的信息不同：

```mermaid
flowchart TD
  Entry{"触发方式"} -->|"/army"| Main["SKILL.md（主文件）\n协作流程 / 路由 / 编排"]
  Entry -->|"用 cc 干 xxx"| CCRef["cc-reference.md\n调用模板 / 参数 / effort"]
  Entry -->|"用 codex 干 xxx"| CodexRef["codex-reference.md\n调用模板 / 模型选择"]

  Main -->|"需要调 cc"| CCRef
  Main -->|"需要调 codex"| CodexRef
  Main -->|"多方协作"| Collab["collaboration.md\n文件规范 / 交接模板"]

  style Entry fill:#FFF9C4,stroke:#F57F17
  style Main fill:#E3F2FD,stroke:#1565C0
  style CCRef fill:#FFF3E0,stroke:#E65100
  style CodexRef fill:#F3E5F5,stroke:#6A1B9A
  style Collab fill:#E8F5E9,stroke:#2E7D32
```

主文件始终加载，子文档按需引用。这样 token 消耗和信息精度都得到了优化。

---

## 五、协作文件：最容易被忽略的胶水

多 Agent 协作有一个隐蔽但致命的问题：**交接失灵**。

A 做完了，B 不知道 A 做了什么。Cursor 给 cc 派了任务，cc 把结果写到一个临时地方，Cursor 找不到。或者 cc 的输出直接回传给 Cursor，几千字的内容把 Cursor 的 token 消耗殆尽。

下面这个序列图展示了**正确的**协作文件流转方式：

```mermaid
sequenceDiagram
  participant U as 用户
  participant C as Cursor（调度者）
  participant CC as cc（执行者）
  participant X as codex（顾问）

  U->>C: /army 重构这个模块
  C->>C: 分析任务，写分工计划
  C-->>U: 展示计划，等确认
  U->>C: 确认

  Note over C: 任务描述 > 5 行<br/>写到 _agent_work/plans/

  C->>CC: 读 plans/xxx.md 执行
  CC->>CC: 执行任务
  CC-->>CC: 结果写到 _agent_work/context/

  C->>C: 只读摘要（保护 token）

  C->>X: review 未提交的改动
  X-->>X: 结果写到 _agent_work/reviews/

  C->>C: 读 review 摘要
  C-->>U: 汇报结果
```

### 第一层：固定目录 + 命名规范

所有协作中间产物写到项目内的 `_agent_work/` 目录：

```
_agent_work/
├── context/    # 上下文搜集结果
├── plans/      # 分工计划和方案
├── reviews/    # review 结果
└── logs/       # 执行日志
```

文件名带日期和任务标识，不会互相覆盖。这个目录不加 `.gitignore`——它本身就是协作的活文档，值得被追踪。

**目录初始化**：调度者在首次派发任务时自动 `mkdir -p _agent_work/{context,plans,reviews,logs}`。不需要用户手动创建，也不需要预先存在——每次调用前确保目录在就行。

### 第二层：长任务描述写成文档

实际使用中发现一个模式：当你给 cc 或 codex 的任务描述超过 5 行时，直接放在命令行参数里不现实，也不可追溯。

更好的做法是：先把任务描述写到 `_agent_work/plans/` 下的一个 Markdown 文件里，然后让 cc/codex 去读这个文件执行。好处是：
- 任务描述有版本记录
- Cursor 自己不需要在 prompt 里塞大量文本
- 下次遇到类似任务可以复用

"5 行"是经验法则，不是硬性阈值。核心判断标准是：命令行里塞不塞得下、事后能不能追溯。

### 第三层：并行编排

当任务可以拆成互不依赖的子任务时，多个 cc/codex 实例可以并行跑。关键约束：**每个实例写独立文件，禁止并行写同一文件。**

```mermaid
sequenceDiagram
  participant C as Cursor（调度者）
  participant CC1 as cc 实例 1
  participant CC2 as cc 实例 2
  participant X as codex

  C->>CC1: review 文件 A → 写 reviews/cc-fileA-0404.md
  C->>CC2: review 文件 B → 写 reviews/cc-fileB-0404.md
  C->>X: review 文件 C → 写 reviews/codex-fileC-0404.md

  CC1-->>C: 完成
  CC2-->>C: 完成
  X-->>C: 完成

  C->>C: 读取三份 review，汇总呈现
```

### 第四层：失败处理

工具调用不总是成功的。常见失败场景和应对：

| 失败场景 | 表现 | 应对 |
|---|---|---|
| codex 网络不通 | 可用性检测返回 `codex_unavail` | 降级到 cc `--effort high` 或 Cursor 自己做 |
| cc/codex 超时 | 后台进程长时间无输出 | 设合理 timeout，超时后检查产物文件是否已写入 |
| 输出文件为空或格式异常 | 文件存在但内容不符合预期 | 调度者检查文件大小，异常时重试或降级 |
| 并行实例部分失败 | 部分文件写入、部分缺失 | 汇总已有结果，对失败任务单独重试 |

原则是：**调用前检测，执行后验收，失败时降级。** 不要假设每次调用都成功。

---

## 六、让工具 review 自己

体系搭到这里，一个有趣的可能性出现了：**让 cc 和 codex 分别 review 这套体系本身。**

```mermaid
flowchart TD
  Input["Rule + Skill + 协作规范\n（作为上下文）"]

  Input --> CC["cc review\n（执行者视角）"]
  Input --> Codex["codex review\n（顾问视角）"]

  CC --> CCOut["关注工程化\n接口统一 / 错误处理 / 输出规范"]
  Codex --> CodexOut["关注系统性\n一致性 / 风险分级 / 验证闭环"]

  CCOut --> Merge["调度者（用户）\n筛选 · 取舍 · 整合"]
  CodexOut --> Merge

  Merge --> Adopt["采纳\n落地改进"]
  Merge --> NotAdopt["不采纳\n记录到 not-adopted.md\n留档备查"]

  style Input fill:#E3F2FD
  style CC fill:#FFF3E0
  style Codex fill:#F3E5F5
  style Merge fill:#FFF9C4,stroke:#F57F17
  style Adopt fill:#E8F5E9,stroke:#2E7D32
  style NotAdopt fill:#FFEBEE,stroke:#C62828
```

实际效果：
- cc 更关注工程化——接口统一、错误处理、输出规范
- codex 更关注系统性——一致性、风险分级、验证闭环
- 两者互补，比你自己想要全面得多

但也要注意：**不是所有建议都应该采纳。** 我们收到了结构化任务输入（JSON 模板）、错误码体系、权限三级细分、用量阈值自动调度等建议。逐一评估后，大部分"过度工程化"的建议被搁置——当前阶段，简单可用比架构完美重要。这些被搁置的建议和理由都记录在 `not-adopted.md` 里，作为未来的参考。

---

## 七、反模式：踩过的坑

```mermaid
flowchart LR
  subgraph 坑["常见反模式"]
    direction TB
    P1["🚫 AI 自动判断是否协作\n简单任务被过度拆解"]
    P2["🚫 Rule 塞太多内容\n90% 对话在为不需要的功能付 token"]
    P3["🚫 协作文件写 /tmp/\n不可追溯，重启丢失"]
    P4["🚫 调度者直接消费大输出\n快速耗尽 token"]
    P5["🚫 并行实例写同一文件\n互相覆盖"]
    P6["🚫 不检测就调用 codex\n VPN 断了 → 莫名失败"]
    P7["🚫 分工原则只在对话里\n新对话全忘"]
    P8["🚫 只有成功路径\n失败了不知道怎么办"]
    P9["🚫 依赖 -o 捕获完整输出\n实际只拿到最后一条消息"]
  end

  subgraph 解["正确做法"]
    direction TB
    S1["✅ 用户用 /army 触发"]
    S2["✅ Rule ≤ 10 行"]
    S3["✅ 写到项目内 _agent_work/"]
    S4["✅ cc 写文件，Cursor 读摘要"]
    S5["✅ 并行任务写独立文件"]
    S6["✅ 调用前做健康检测"]
    S7["✅ 写进 Rule/Skill 持久化"]
    S8["✅ 调用前检测 · 执行后验收 · 失败时降级"]
    S9["✅ 在 prompt 里要求工具写文件"]
  end

  P1 --> S1
  P2 --> S2
  P3 --> S3
  P4 --> S4
  P5 --> S5
  P6 --> S6
  P7 --> S7
  P8 --> S8
  P9 --> S9

  style 坑 fill:#FFEBEE,stroke:#C62828
  style 解 fill:#E8F5E9,stroke:#2E7D32
```

---

## 八、用数据 review 自己

体系搭到 V6，看上去已经很完善了——分层清晰、失败有降级、并行有规范。但有一个关键问题一直被忽略：**体系用起来之后，实际的分工比例到底怎么样？**

答案来自一个简单的操作：**回溯所有历史对话，统计三方工具各自做了多少。**

```mermaid
pie title 历史执行占比（5 轮对话统计）
  "Cursor（调度者）" : 95.7
  "cc（执行者）" : 2.9
  "codex（顾问）" : 1.4
```

数据触目惊心：**调度者承担了 95.7% 的工作**。cc 只被调用了 8 次，codex 只被调用了 4 次。大量本该外派的批量编辑、多文件 review、文档产出，全是 Cursor 自己做的。

逐轮分析暴露了几个典型场景：

| 对话 | Cursor 操作 | cc 调用 | codex 调用 | 问题 |
|---|---|---|---|---|
| #1 初始化项目 | ~86 次 | 3 次 | 1 次 | 大量文件编辑自己做了 |
| #2 写 roadmap | ~29 次 | **0 次** | **0 次** | 完全没外派，用户当场批评 |
| #3 固化体系 | ~89 次 | 4 次 | 2 次 | 批量改 4-5 个文件本该派 cc |
| #4 review + 优化 | ~64 次 | 1 次 | 1 次 | 后续编辑又全自己做 |

**根因**：规则里虽然写了"什么任务该派给谁"，但这些规则只在 `/army` 流程里生效。日常对话中，AI 没有被强制触发外派意识——它总是默认自己做，因为这是阻力最小的路径。

### 修复：在 Rule 层加铁律

既然问题出在"日常对话不触发外派"，解决方式就是把外派条件写进每次对话都会注入的 Rule 里，而不是只写在 Skill 的 `/army` 流程中：

```mermaid
flowchart LR
  subgraph Before["修复前"]
    direction TB
    B1["Rule: 只有路由\n不强制外派"]
    B2["/army: 有分工自检\n但需要用户触发"]
    B3["日常对话:\n啥都自己做"]
  end

  subgraph After["修复后"]
    direction TB
    A1["Rule: 路由 + 铁律\n≥3 文件同类操作 → 派 cc\n产出 ≥100 行 → 派 cc\n连续 3 个类似步骤 → 停，批量派"]
    A2["/army: 分工自检\n全是「我」→ 必须解释"]
    A3["日常对话:\n铁律自动触发外派"]
  end

  Before -->|"数据驱动\n发现问题"| After

  style Before fill:#FFEBEE,stroke:#C62828
  style After fill:#E8F5E9,stroke:#2E7D32
```

具体改动：
- **Rule 层**：新增铁律——≥3 文件同类操作、产出 ≥100 行、连续 3 个类似编辑步骤时必须外派，不需要 `/army` 也能触发
- **Skill 层（/army 计划阶段）**：新增自检清单——"我"的步骤 ≥5 个要审视，全是"我"做必须解释理由
- **Skill 层（路由矩阵）**：Cursor 自己做的边界从"小"收紧到"≤2 文件、≤50 行改动"，新增 cc/codex 速查条目

**教训：体系设计不能只靠直觉。定期用数据 review 实际执行情况，才能发现"规则写了但没执行"的盲区。**

这也揭示了一个更深层的问题：**AI 的默认行为是"自己做"，你必须用强制规则来覆盖这个默认行为。** 仅仅"建议"它外派是不够的——你需要设定明确的阈值和触发条件，让外派变成无需思考的条件反射。

---

## 九、最终架构：四层分离

经过上述演进，最终形成的架构是四层分离：

```mermaid
flowchart TD
  subgraph Layer1["Layer 1: Rule（每次对话自动注入）"]
    Rule["ai-dispatch.mdc\n~10 行：基础认知 + 路由"]
  end

  subgraph Layer2["Layer 2: Command（用户主动触发）"]
    Cmd["/army\n指向 Skill，启动协作流程"]
  end

  subgraph Layer3["Layer 3: Skill（按需加载）"]
    Main["SKILL.md\n协作流程 / 路由 / 编排"]
    Sub1["cc-reference.md"]
    Sub2["codex-reference.md"]
    Sub3["collaboration.md"]
    Main -.-> Sub1
    Main -.-> Sub2
    Main -.-> Sub3
  end

  subgraph Layer4["Layer 4: _agent_work/（协作产物）"]
    AW1["context/ — 上下文搜集"]
    AW2["plans/ — 分工计划"]
    AW3["reviews/ — review 结果"]
    AW4["logs/ — 执行日志"]
  end

  User["用户对话"] --> Rule
  Rule -->|"用 cc/codex"| Layer3
  User -->|"/army"| Cmd
  Cmd --> Main
  Layer3 -->|"读写中间产物"| Layer4

  style Layer1 fill:#E8F5E9,stroke:#2E7D32
  style Layer2 fill:#E3F2FD,stroke:#1565C0
  style Layer3 fill:#FFF3E0,stroke:#E65100
  style Layer4 fill:#F3E5F5,stroke:#6A1B9A
  style User fill:#F5F5F5
```

设计原则：
- 每次对话必付的成本（Rule）降到最低
- 偶尔需要的能力（Skill）按需加载
- 用户控制协作时机（Command），AI 不自作主张
- 协作产物有固定归属（`_agent_work/`），交接不失灵

---

## 十、从零搭建的步骤

如果你也想搭一套类似的体系，先确认前置条件：
- 至少两个 AI 编程工具已安装可用（一个交互式、一个可 CLI 调用）
- 工具的 API Key / 账号已配置好
- 如有工具依赖网络代理（如 VPN），确保代理可用

然后按以下步骤推进：

```mermaid
flowchart TD
  S1["1. 盘点工具\n谁能交互？谁 token 多？谁推理强？"]
  S2["2. 写极简 Rule\n≤ 10 行，只放认知 + 路由"]
  S3["3. 做协作入口\n定义 /army 命令，不触发不消耗"]
  S4["4. 写 Skill 文档\n主文件 + 子文档，按需加载"]
  S5["5. 约定协作目录\n_agent_work/，不用临时目录"]
  S6["6. 设计降级链路\n每个工具挂了怎么办"]
  S7["7. 让工具 review 自己\n执行者 + 顾问双视角"]
  S8["8. 记录不采纳的建议\n留档备查，未来可能有用"]
  S9["9. 用数据 review 执行情况\n统计各工具占比，发现盲区"]

  S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8 --> S9

  style S1 fill:#E3F2FD
  style S2 fill:#E8F5E9
  style S3 fill:#E3F2FD
  style S4 fill:#FFF3E0
  style S5 fill:#E8F5E9
  style S6 fill:#FFEBEE
  style S7 fill:#F3E5F5
  style S8 fill:#FFF9C4
  style S9 fill:#FFEBEE
```

---

## 十一、总结

这套体系的本质是把**软件工程的分层思想**搬到 AI 工具的使用方式上：

```mermaid
flowchart LR
  subgraph 软件工程类比
    PM["产品经理\n理解需求 · 拆解 · 协调"]
    Dev["开发团队\n量大 · 能并行 · 按指令做"]
    Expert["技术专家\n少而精 · 深度判断"]
  end

  subgraph Agent 军团
    Cursor["调度者\nCursor Agent"]
    CC["执行者\nClaude Code"]
    Codex["顾问\nCodex CLI"]
  end

  PM ---|"≈"| Cursor
  Dev ---|"≈"| CC
  Expert ---|"≈"| Codex

  style PM fill:#E3F2FD
  style Dev fill:#FFF3E0
  style Expert fill:#F3E5F5
  style Cursor fill:#E3F2FD,stroke:#1565C0
  style CC fill:#FFF3E0,stroke:#E65100
  style Codex fill:#F3E5F5,stroke:#6A1B9A
```

演进过程的核心取舍：

```mermaid
timeline
  title 架构演进时间线
  V1 : 全写在 Rule 里
     : 直觉最简单
     : ❌ 太长，AI 过度热心
  V2 : Rule + Skill 分层
     : 解决 token 浪费
     : ❌ AI 判断协作时机不靠谱
  V3 : 加 /army 命令
     : 用户控制协作时机
     : ❌ Skill 又太长了
  V4 : Skill 拆子文档
     : 按需加载
     : ❌ 交接失灵
  V5 : 协作文件规范化
     : _agent_work/ 固定目录
     : ❌ 只有成功路径
  V6 : 补齐失败处理与并行编排
     : 检测→执行→验收→降级
     : ❌ 调度者做了 95% 的活
  V7 : 数据驱动优化
     : 回溯统计 → Rule 加铁律 → 强制外派
     : ✅ 当前架构
```

每一步都是在解决上一步暴露的问题。没有一开始就设计好的完美架构——都是用出来的。
