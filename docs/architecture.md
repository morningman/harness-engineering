# Doris Harness Engineering — 架构与工作流详解

> 本文档完整介绍 Doris Harness Engineering 框架的运行方式、内部机制和核心概念。

---

## 一、设计哲学

### 1.1 为什么需要 Harness Engineering？

在使用 AI Agent 进行大型代码库（如 Apache Doris，100 万+ 行代码）的日常开发时，常见的失败模式有：

| 失败模式 | 症状 | 根因 |
|----------|------|------|
| **一步到位** | AI 试图一次生成整个功能代码，结果编译失败 | 缺少增量分解 |
| **自我满足** | AI 说"已完成"，但代码含隐藏 bug | Generator 和 Evaluator 是同一个角色 |
| **范围蔓延** | 修一个 bug 却改了十个文件 | 没有预先协商"完成"的定义 |
| **规范遗忘** | 代码风格或架构模式不符合项目约定 | 缺少模块级约定感知 |

Harness Engineering 源自 [Anthropic 的文章](https://www.anthropic.com/engineering/harness-design-long-running-apps)，核心思想是：**构建约束框架（Harness），让 AI Agent 在约束内高效工作，而不是无约束地自由发挥**。

### 1.2 三大核心原则

```
┌────────────────────────────────────────────────────────────┐
│                  Harness Engineering 三原则                  │
├────────────────────┬────────────────────┬──────────────────┤
│  增量式任务分解     │  生成-评估分离      │  契约驱动开发     │
│  (Incremental      │  (Generator-       │  (Contract-      │
│   Decomposition)   │   Evaluator Split) │   Driven Dev)    │
├────────────────────┼────────────────────┼──────────────────┤
│ 大任务分解为多个    │ 写代码和评估代码   │ 在编码前，明确    │
│ < 500 行的小任务   │ 是两个独立角色     │ "完成"的精确定义  │
│ 每个任务可独立      │ Evaluator 不妥协   │ 包含验证命令和    │
│ 编译和测试         │ 客观打分           │ 通过/失败标准     │
└────────────────────┴────────────────────┴──────────────────┘
```

## 二、系统架构

### 2.1 四层架构

```
┌─────────────────────────────────────────────────────────┐
│                    开发者 / 用户                          │
│           (Antigravity IDE / Copilot CLI)                │
└────────────────────────┬────────────────────────────────┘
                         │ 触发
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 1: 入口层 — Workflows & CLI Commands              │
│                                                          │
│  /doris-feature  /doris-refactor  /doris-bugfix          │
│  /doris-review   /plan  /implement  /evaluate  /check    │
│                                                          │
│  定义端到端的编排流程，何时调用哪个 Skill                    │
└────────────────────────┬────────────────────────────────┘
                         │ 调用
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: 能力层 — Skills                                │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │ environment  │ │ agents       │ │ sprint           │ │
│  │ -check       │ │ -discovery   │ │ -contract        │ │
│  │              │ │              │ │                  │ │
│  │ 环境自检     │ │ AGENTS.md    │ │ 契约协商         │ │
│  │ 进度恢复     │ │ 发现与加载    │ │ 完成标准定义     │ │
│  └──────────────┘ └──────────────┘ └──────────────────┘ │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │ harness      │ │ requirement  │ │ plan             │ │
│  │ -evaluator   │ │ -analysis    │ │ -writer          │ │
│  │              │ │              │ │                  │ │
│  │ 独立 QA 评估 │ │ 需求探索     │ │ 计划生成         │ │
│  │ 编译+测试+   │ │ 场景分析     │ │ 任务分解         │ │
│  │ 评分         │ │              │ │                  │ │
│  └──────────────┘ └──────────────┘ └──────────────────┘ │
│                                                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │
│  │ task         │ │ verification │ │ branch           │ │
│  │ -executor    │ │              │ │ -finish          │ │
│  │              │ │              │ │                  │ │
│  │ 逐任务执行   │ │ 完成前验证   │ │ PR / 合并收尾    │ │
│  │ 进度恢复     │ │ 证据驱动     │ │                  │ │
│  └──────────────┘ └──────────────┘ └──────────────────┘ │
│                                                          │
│  ┌──────────────┐                                        │
│  │ debugging    │  所有 Skill 均以 doris- 前缀命名        │
│  │              │  框架完全自包含，无外部依赖              │
│  │ 系统化调试   │                                        │
│  └──────────────┘                                        │
└────────────────────────┬────────────────────────────────┘
                         │ 读取
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 3: 知识层 — 项目上下文 & 评估标准                   │
│                                                          │
│  ┌─────────────┐  ┌──────────────────┐  ┌────────────┐  │
│  │ AGENTS.md   │  │ criteria/*.md    │  │ AGENTS.md  │  │
│  │ (Doris 根   │  │                  │  │ (Doris 仓库 │  │
│  │  目录，项目  │  │ FE/BE/Connector/ │  │  各模块)    │  │
│  │  级规范)    │  │ Doc 评分标准      │  │            │  │
│  │ 编译命令    │  │ 权重+阈值+检查项  │  │ 模块级约定  │  │
│  │ 代码规范    │  │                  │  │            │  │
│  └─────────────┘  └──────────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
┌─────────────────────────────────────────────────────────┐
│  Layer 4: 产出层 — 开发过程文件                           │
│                                                          │
│  specs/        plans/        contracts/      reports/    │
│  功能规格      开发计划       Sprint 契约     评估报告     │
│                                                          │
│  harness-progress.txt — 进度跟踪文件                      │
└─────────────────────────────────────────────────────────┘
```

### 2.2 两个开发环境的适配

本框架同时支持两个 AI 开发环境：

| 环境 | 入口 | 部署方式 |
|------|------|----------|
| **Antigravity IDE** | `/doris-feature` 等 Workflows | Skills → `~/.gemini/antigravity/skills/`<br/>Workflows → `~/.gemini/antigravity/global_workflows/` |
| **Copilot CLI** | `claude /plan` 等 Commands | Commands → `.claude/commands/` |

两者共享同一套 **评估标准（`criteria/`）** 和 **模板（`templates/`）**，只是触发方式不同。

## 三、核心组件详解

### 3.1 AGENTS.md — 分层级项目知识源

Doris 代码库根目录的 `AGENTS.md` 作为项目级规范，AI Agent 启动时自动加载。它提供：

```
Doris 根目录 AGENTS.md
├── 项目概述（Doris 是什么）
├── 代码结构（FE/BE/Connector 目录树）
├── 编译命令（FE mvn / BE build.sh / 回归测试）
├── 代码规范（Java 风格 / C++ 风格 / Git 提交格式）
└── 开发注意事项（模块级约定指引）
```

框架**不单独维护** CLAUDE.md 等额外的知识注入文件，而是直接依赖 Doris 社区维护的 AGENTS.md 体系。
这确保了知识源的唯一性和时效性——不会出现框架与代码库规范不同步的问题。

### 3.2 AGENTS.md — 模块级约定系统

Doris 代码库中各模块可能包含 `AGENTS.md` 文件，定义该模块特有的开发约定。这是一个**分布式知识系统**：

```
doris/
├── AGENTS.md                           ← 项目级规范（最低优先级）
├── fe/
│   ├── AGENTS.md                       ← FE 组件级规范
│   └── fe-core/
│       ├── AGENTS.md                   ← FE-Core 模块规范
│       └── src/main/java/.../
│           ├── datasource/AGENTS.md    ← 数据源子模块规范
│           └── nereids/AGENTS.md       ← Nereids 优化器规范
├── be/
│   └── src/
│       ├── runtime/AGENTS.md           ← BE Runtime 规范
│       ├── storage/
│       │   ├── AGENTS.md               ← 存储模块规范
│       │   └── index/inverted/AGENTS.md ← 倒排索引规范（最高优先级）
│       └── ...
└── cloud/
    └── src/
        ├── meta-service/AGENTS.md
        └── meta-store/AGENTS.md
```

**发现算法**：对于每个待修改的文件，沿目录树向上查找所有祖先目录的 `AGENTS.md`。例如修改 `be/src/storage/index/inverted/reader.cpp` 时：

```
be/src/storage/index/inverted/AGENTS.md  ← 最高优先级
be/src/storage/AGENTS.md                 ← 次之
AGENTS.md                                ← 最低优先级
```

**就近原则**：如果不同层级的 AGENTS.md 有冲突规则，**越接近修改文件的规则优先级越高**。

### 3.3 Skills — 可复用的能力单元

框架包含 **10 个自定义 Skill**（全部以 `doris-` 前缀命名），无任何外部 Skill 依赖：

#### doris-environment-check

```
作用: 开发 session 启动时的标准化自检
触发: 所有 Workflow 的 Step 1

检查项:
  1. 工作目录 & 分支状态
  2. 上次进度恢复（读取 harness-progress.txt）
  3. 编译环境（Java/Maven/GCC/CMake）
  4. Doris 实例状态（可选）
  5. 任务范围分析
  6. AGENTS.md 模块约定发现与加载  ← 新增

输出: 结构化的环境自检报告
```

#### doris-agents-discovery

```
作用: 发现并加载 Doris 代码库中的 AGENTS.md 文件
触发: 环境自检 Step 6 / 所有 Workflow 的 Step 1.5

算法:
  1. find . -name "AGENTS.md" → 发现所有文件
  2. 根据修改文件路径 → 向上遍历目录树
  3. 分类（Root / Component / Module / Sub-module）
  4. 按就近原则排序
  5. 读取内容并提取关键约束

输出: AGENTS.md 加载报告 + 关键约束摘要
```

#### doris-sprint-contract

```
作用: 在每个 Sprint/Task 开始前，协商完成标准
触发: 每个 Task 的 Step 4a

过程:
  ┌──────────────┐         ┌──────────────┐
  │  Generator   │ ──(1)─→ │  提出契约草案 │
  │  (编码角色)   │         │  - 目标       │
  │              │         │  - 交付物     │
  │              │         │  - 完成标准   │
  │              │         │  - AGENTS.md  │
  │              │         │    约束项     │
  └──────────────┘         └──────┬───────┘
                                  │
                            (2)   ▼
  ┌──────────────┐         ┌──────────────┐
  │  Evaluator   │ ←──(3)─ │  审查契约     │
  │  (评估角色)   │ ──(4)─→ │  - 验证性?   │
  │              │         │  - 范围合理?  │
  │              │         │  - 遗漏检查?  │
  │              │         │  - AGENTS.md? │
  └──────────────┘         └──────┬───────┘
                                  │
                            (5)   ▼
                           ┌──────────────┐
                           │  存储契约文件 │
                           │  contracts/  │
                           │  sprint-N-   │
                           │  task.md     │
                           └──────────────┘

三层完成标准:
  - 硬性标准: 编译通过、单测无回归（必须 100% 通过）
  - 质量标准: 评分 ≥ 7.5（加权评分）
  - 功能标准: 按契约验证步骤确认功能正确
```

#### doris-harness-evaluator

```
作用: 独立 QA 评估（编译 + 测试 + 评分 + AGENTS.md 合规）
触发: 每个 Task 完成后的 Step 4c

评估流程:
  ┌─────────────────────────────────────────────┐
  │ Step 1: 识别变更范围                          │
  │   git diff → 确定 FE/BE/Connector/Doc       │
  │   发现相关 AGENTS.md                         │
  ├─────────────────────────────────────────────┤
  │ Step 2: 编译验证 (Hard Gate)                  │
  │   FE: mvn package -pl fe-core -DskipTests   │
  │   BE: ./build.sh --be                       │
  │   失败 → 直接 FAIL，停止评估                   │
  ├─────────────────────────────────────────────┤
  │ Step 3: 测试执行                              │
  │   运行相关单测，记录通过/失败/跳过/新增         │
  │   任何回归 → 直接 FAIL                        │
  ├─────────────────────────────────────────────┤
  │ Step 4: 标准化评分                            │
  │   加载 criteria/ 下对应标准                    │
  │   每个维度: 1-10 评分 × 权重                   │
  │   综合分 < 7.5 → FAIL                        │
  ├─────────────────────────────────────────────┤
  │ Step 5: AGENTS.md 合规检查                    │
  │   检查代码是否符合模块约定                      │
  │   合规率 100%  → 无调整                       │
  │   合规率 80-99% → -0.5 分                    │
  │   合规率 < 80%  → -1.0 分                    │
  ├─────────────────────────────────────────────┤
  │ Step 6: 生成评估报告                          │
  │   reports/evaluation-YYYY-MM-DD.md           │
  └─────────────────────────────────────────────┘

评分维度 (FE 示例):
  ┌────────────────┬───────┬───────┬────────┐
  │ 维度           │ 权重  │ 阈值  │ 说明    │
  ├────────────────┼───────┼───────┼────────┤
  │ 编译正确性     │ 0.30  │ 10    │ 硬性门槛│
  │ 单元测试       │ 0.25  │ 8     │        │
  │ API 兼容性     │ 0.15  │ 8     │        │
  │ 架构对齐       │ 0.15  │ 7     │        │
  │ 代码风格       │ 0.05  │ 6     │        │
  │ 错误处理       │ 0.10  │ 7     │        │
  └────────────────┴───────┴───────┴────────┘
```

### 3.4 Workflows — 端到端编排

框架提供 4 个预定义的工作流，每个工作流编排不同的 Skill 组合：

#### /doris-feature — 新功能开发

```
Step 1   ─→ 环境自检 (doris-environment-check)
Step 1.5 ─→ 加载模块约定 (doris-agents-discovery)
Step 2   ─→ 需求探索 (doris-requirement-analysis)
Step 3   ─→ 制定计划 (doris-plan-writer)
Step 4   ─→ 增量实现（对每个 Task 循环）
  ├── 4a: Sprint 契约 (doris-sprint-contract)
  ├── 4b: 编码实现 (doris-task-executor, 遵循 AGENTS.md 各级规范)
  └── 4c: 评估 (doris-harness-evaluator) → 未通过则回到 4b
Step 5   ─→ 最终验证 (doris-verification)
Step 6   ─→ 收尾 (doris-branch-finish)
```

#### /doris-refactor — 重构

```
与 feature 类似，但新增：
  - Step 3: 建立基线（记录重构前的测试结果和性能数据）
  - Step 5c: 严格模式评估（测试只增不减，零容忍回归）
  - Step 6: 功能等价验证（与基线对比）
```

#### /doris-bugfix — 修 Bug

```
特殊之处：
  - Step 2: Bug 分析 (doris-debugging)
  - Step 3: TDD 方式 — 先写失败的回归测试，再修复代码
  - Sprint 契约使用 Bug 修复模板（范围：仅修复 Bug，不做额外重构）
  - 验证：回归测试通过 + 全量测试无新增失败
```

#### /doris-review — 代码审查

```
不涉及代码生成，仅执行：
  - 获取变更范围
  - 加载评估标准 + AGENTS.md 模块约定
  - 编译验证（如果有环境）
  - 结构化审查（正确性/架构/质量/兼容性/AGENTS.md 合规）
  - 生成评分报告
```

### 3.5 CLI Commands — Copilot CLI 快捷命令

用于在 Copilot CLI (`claude`) 中触发框架功能：

| 命令 | 作用 | 等价 Workflow 步骤 |
|------|------|-------------------|
| `/plan` | 分析需求 → 加载 AGENTS.md → 任务分解 → 生成计划文件 | Step 2-3 |
| `/implement` | 读取计划 → 加载 AGENTS.md → 逐 Task 实现 → 进度跟踪 | Step 4 |
| `/evaluate` | 识别变更 → 加载 AGENTS.md → 编译+测试+评分+合规检查 | Step 4c |
| `/check` | 快速环境自检 + AGENTS.md 发现 | Step 1 |
| `/refactor` | 结构化重构（等价于精简版 /doris-refactor） | 全流程 |

### 3.6 Sub-Agent Architecture — 子代理编排

Copilot CLI 支持 **Custom Agents（自定义子代理）**，每个子代理以 `.agent.md` 文件定义，部署在 `.github/agents/` 或 `~/.copilot/agents/` 目录下。Harness 框架利用这一机制实现真正的 **Generator-Evaluator 分离**：

#### 3.6.1 三个自定义子代理

```
copilot-cli/agents/
├── doris-evaluator.agent.md    ← Evaluator: 独立 QA 评估（只读）
├── doris-implementer.agent.md  ← Generator: 代码实现（可写）
└── doris-researcher.agent.md   ← Researcher: 代码库探索（只读）
```

| 子代理 | 角色 | 工具权限 | 核心职责 |
|--------|------|----------|----------|
| **doris-evaluator** | Evaluator | `read`, `search`, `execute` | 编译验证、测试、评分、AGENTS.md 合规 |
| **doris-implementer** | Generator | `read`, `edit`, `search`, `execute` | 增量编码、编译、进度更新 |
| **doris-researcher** | Researcher | `read`, `search` | 代码架构分析、调用链追踪 |

#### 3.6.2 子代理工作机制

```
┌─────────────────────────────────────────────────────────┐
│  主代理（Main Agent / Orchestrator）                      │
│  持有完整上下文和所有工具                                 │
│                                                          │
│  当用户发出任务请求时:                                    │
│  ┌─────────────────────────────────────────────────────┐│
│  │ 1. Intent Matching — 运行时分析用户意图               ││
│  │    匹配子代理的 description 字段                      ││
│  │                                                      ││
│  │ 2. Agent Selection — 选择最匹配的子代理               ││
│  │    (如 "评估代码" → doris-evaluator)                  ││
│  │                                                      ││
│  │ 3. Isolated Execution — 子代理在独立上下文中运行       ││
│  │    ┌─────────────────┐  ┌─────────────────┐         ││
│  │    │ doris-evaluator │  │ doris-implementer│         ││
│  │    │ 独立上下文窗口   │  │ 独立上下文窗口   │         ││
│  │    │ tools: read,    │  │ tools: read,     │         ││
│  │    │  search, exec   │  │  edit, search,   │         ││
│  │    │                 │  │  execute         │         ││
│  │    │ 不能修改代码    │  │ 可以修改代码     │         ││
│  │    └─────────────────┘  └─────────────────┘         ││
│  │                                                      ││
│  │ 4. Event Streaming — 生命周期事件回传                 ││
│  │    subagent.started → subagent.completed/failed      ││
│  │                                                      ││
│  │ 5. Result Integration — 子代理输出整合到主代理        ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

#### 3.6.3 触发方式

子代理可通过以下方式触发：

```bash
# 方式 1: 自动推断 — Copilot 根据 description 匹配
copilot "评估当前分支的代码修改质量"
→ 自动委派给 doris-evaluator

# 方式 2: 显式指定
copilot "使用 doris-implementer 代理实现 Task 3"

# 方式 3: 命令行参数
copilot --agent doris-evaluator --prompt "评估 fe/ 下的改动"

# 方式 4: 交互模式 /agent 命令
# 输入 /agent → 从列表中选择子代理 → 输入任务
```

#### 3.6.4 设计原则

**为什么使用子代理而不是角色切换？**

| 维度 | 单代理角色切换 | 子代理架构 |
|------|---------------|-----------|
| 上下文隔离 | ❌ 共享同一上下文 | ✅ 独立上下文窗口 |
| 工具约束 | ❌ 所有工具均可用 | ✅ 按角色限制工具 |
| 客观性 | ❌ 自己评估自己 | ✅ Evaluator 无法修改代码 |
| 上下文效率 | ❌ 评估内容占据主上下文 | ✅ 卸载到子代理上下文 |

**关键约束**:
- `doris-evaluator` 只有 `read`/`search`/`execute` 权限 — **无法编辑文件**，确保评估的客观性
- `doris-researcher` 只有 `read`/`search` 权限 — **无法执行命令或编辑**，纯分析角色
- 子代理的 `description` 决定自动委派的准确性，必须足够具体

#### 3.6.5 与 Antigravity IDE Skills 的对应关系

```
┌────────────────────────────────────────────────────────────┐
│          统一能力模型 (Unified Capability Model)             │
│                                                             │
│  Copilot CLI                    Antigravity IDE             │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │ doris-evaluator  │ ◄──────► │ doris-harness-       │    │
│  │   .agent.md      │  同一     │   evaluator/SKILL.md │    │
│  │                  │  评估     │                      │    │
│  │  (子代理, 只读)  │  逻辑     │  (Skill, 指导主代理)  │    │
│  └──────────────────┘          └──────────────────────┘    │
│                                                             │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │ doris-implementer│ ◄──────► │ doris-task-          │    │
│  │   .agent.md      │          │   executor/SKILL.md  │    │
│  └──────────────────┘          └──────────────────────┘    │
│                                                             │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │ doris-researcher │ ◄──────► │ doris-requirement-   │    │
│  │   .agent.md      │          │   analysis/SKILL.md  │    │
│  └──────────────────┘          └──────────────────────┘    │
└────────────────────────────────────────────────────────────┘
```

## 四、完整工作流示例

以下展示"为 MaxCompute Connector 添加 JniScanner 读路径"这个任务的完整执行过程：

### Phase 1: 启动

```
用户输入: /doris-feature "为 MaxCompute Connector 添加 JniScanner 读路径"

┌─ Step 1: 环境自检 ──────────────────────────────┐
│ ✅ 工作目录: /workspace/doris                     │
│ ✅ 分支: feature/maxcompute-jniscanner            │
│ ✅ Java 11.0.21, Maven 3.9.6                     │
│ ✅ FE 编译基线: BUILD SUCCESS                     │
│ ⏭️ 无上次进度文件                                 │
└────────────────────────────────────────────────────┘

┌─ Step 1.5: AGENTS.md 加载 ──────────────────────┐
│ 发现 20 个 AGENTS.md，筛选出 4 个相关文件:         │
│  1. AGENTS.md (Root)                             │
│  2. fe/AGENTS.md (Component)                     │
│  3. fe/fe-core/AGENTS.md (Module)                │
│  4. fe/fe-core/.../datasource/AGENTS.md (Sub)    │
│                                                   │
│ 关键约束:                                         │
│  - Connector 必须使用 JniScanner 模式              │
│  - 数据源新增属性必须有默认值                       │
│  - 类型映射必须覆盖全部基础类型                     │
└────────────────────────────────────────────────────┘
```

### Phase 2: 规划

```
┌─ Step 2: 需求探索 ──────────────────────────────┐
│ 产出: specs/2026-04-01-maxcompute-jniscanner.md  │
│ - 用户场景: MaxCompute Catalog 读取查询           │
│ - 影响: FE (ScanNode) + Java (JdbcJniScanner)   │
│ - 挑战: MaxCompute SDK 的类型映射                 │
└────────────────────────────────────────────────────┘

┌─ Step 3: 制定计划 ──────────────────────────────┐
│ 产出: plans/2026-04-01-maxcompute-jniscanner.md  │
│ Task 1: 创建 MaxComputeJniScanner 基础框架       │
│ Task 2: 实现数据读取逻辑                          │
│ Task 3: 实现类型转换                              │
│ Task 4: 集成到 ScanNode                          │
│ Task 5: 清理旧代码                               │
│ (每个 Task 约束于 AGENTS.md 规范)                 │
└────────────────────────────────────────────────────┘
```

### Phase 3: 增量实现（以 Task 1 为例）

```
┌─ Step 4a: Sprint 契约 ──────────────────────────┐
│ 文件: contracts/sprint-1-scanner-framework.md     │
│                                                   │
│ 目标: 创建 MaxComputeJniScanner 基础框架          │
│ 硬性标准:                                         │
│   [x] mvn package -pl fe-core -DskipTests ✅     │
│   [x] MaxComputeJniScannerTest 通过 ✅           │
│ AGENTS.md 约束:                                   │
│   [x] 使用 JniScanner 接口 (datasource AGENTS.md) │
│   [x] 新增属性有默认值 (fe-core AGENTS.md)        │
│                                                   │
│ 契约状态: ✅ AGREED                              │
└────────────────────────────────────────────────────┘

┌─ Step 4b: 编码实现 ────────────────────────────── │
│ 新增: MaxComputeJniScanner.java (~150 行)         │
│ 新增: MaxComputeJniScannerTest.java (~80 行)      │
│ git commit                                        │
└────────────────────────────────────────────────────┘

┌─ Step 4c: 评估 ────────────────────────────────── │
│ 编译:  BUILD SUCCESS ✅                          │
│ 测试:  Tests: 3, Failures: 0 ✅                  │
│                                                   │
│ 评分:                                             │
│  编译正确性: 10/10 × 0.30 = 3.00                  │
│  单元测试:   9/10 × 0.25 = 2.25                  │
│  API 兼容性: 10/10 × 0.15 = 1.50                  │
│  架构对齐:   9/10 × 0.15 = 1.35                  │
│  代码风格:   8/10 × 0.05 = 0.40                  │
│  错误处理:   8/10 × 0.10 = 0.80                  │
│  综合: 9.30/10 ✅                                │
│                                                   │
│ AGENTS.md 合规: 100% ✅                          │
│                                                   │
│ 结果: PASS → 进入 Task 2                         │
└────────────────────────────────────────────────────┘
```

### Phase 4: 收尾

```
┌─ Step 5: 最终验证 ──────────────────────────────┐
│ 全量编译: BUILD SUCCESS ✅                       │
│ 全量单测: Tests: 1234, Failures: 0 ✅           │
└────────────────────────────────────────────────────┘

┌─ Step 6: 收尾 ──────────────────────────────────┐
│ 生成 PR 描述 + 评估报告附件                       │
│ 更新 harness-progress.txt:                       │
│   Feature: MaxCompute JniScanner                 │
│   Status: COMPLETED                              │
│   Tasks: 5/5 completed                           │
│   Final Score: 9.15/10                           │
│   PR: #12345                                     │
└────────────────────────────────────────────────────┘
```

## 五、评估体系详解

### 5.1 三类评估标准

| 标准 | 文件 | 适用范围 | 核心维度 |
|------|------|----------|----------|
| FE 质量 | `criteria/doris-fe-quality.md` | Java 代码 | 编译、单测、API 兼容、架构对齐、风格、错误处理 |
| BE 质量 | `criteria/doris-be-quality.md` | C++ 代码 | + 内存管理、性能影响 |

### 5.2 Evaluator 内置的 Doris 模式检查

`criteria/doris-patterns.yaml` 定义了 Doris 项目特有的代码模式：

```yaml
fe_patterns:
  nereids_optimizer    # 新功能优先在 Nereids 中实现
  catalog_properties   # Catalog 新增属性必须有默认值
  exception_hierarchy  # 使用正确的异常类型层次
  visitor_pattern      # Planner 使用 Visitor 模式

be_patterns:
  status_return        # 使用 Status 作为错误返回值
  pipeline_operator    # 算子遵循 Pipeline Operator 模式
  memory_tracker       # 内存分配使用 MemTracker
  vectorized_processing # 使用向量化列式处理

connector_patterns:
  jni_scanner          # 读取使用 JniScanner 模式
  jni_writer           # 写入使用 JniWriter 模式
  type_mapping         # 类型映射完整覆盖
  connection_error     # 连接错误有清晰分类
```

### 5.3 AGENTS.md 合规评分

AGENTS.md 合规性作为**评分修正器**（Quality Modifier）影响最终分数：

```
最终分 = 标准化评分 + AGENTS.md 修正

合规率 100%:   修正 = 0.0   (无影响)
合规率 80-99%: 修正 = -0.5  (轻微扣分)
合规率 < 80%:  修正 = -1.0  (重大扣分，可能导致不通过)
```

## 六、进度恢复机制

### 6.1 进度文件

```markdown
# Harness Progress
Plan: plans/2026-04-01-maxcompute-jniscanner.md
Started: 2026-04-01 10:00
Last Updated: 2026-04-01 14:30

## Completed Tasks
- [x] Task 1: MaxComputeJniScanner 基础框架 (commit: abc1234)
- [x] Task 2: 数据读取逻辑 (commit: def5678)

## Current Task
- [ ] Task 3: 类型转换 (in progress)

## Remaining Tasks
- [ ] Task 4: ScanNode 集成
- [ ] Task 5: 清理旧代码
```

### 6.2 恢复流程

当 AI Agent 启动新 session 时：

```
1. doris-environment-check 检测到 harness-progress.txt
2. 读取进度文件，识别"当前 Task"和"剩余 Task"
3. 向用户确认是否继续上次进度
4. 如果继续 → 跳转到对应的 Task Step 4
5. 如果重新开始 → 归档旧进度文件
```

## 七、文件部署拓扑

`install.sh` 将框架文件部署到三个位置：

```
┌── 目标 1: Doris 仓库 (每个仓库独立) ─────────────┐
│                                                    │
│  doris/                                            │
│  ├── .claude/commands/      ← CLI 自定义命令        │
│  │   ├── plan.md                                   │
│  │   ├── implement.md                              │
│  │   ├── evaluate.md                               │
│  │   ├── refactor.md                               │
│  │   └── check.md                                  │
│  ├── .github/agents/        ← Copilot 子代理       │
│  │   ├── doris-evaluator.agent.md   (QA 评估)     │
│  │   ├── doris-implementer.agent.md (代码实现)     │
│  │   └── doris-researcher.agent.md  (代码探索)     │
│  └── .harness/              ← 评估标准和模板        │
│      ├── criteria/                                 │
│      └── templates/                                │
│                                                    │
└────────────────────────────────────────────────────┘

┌── 目标 2: Antigravity 全局配置 (用户级) ──────────┐
│                                                    │
│  ~/.gemini/antigravity/                            │
│  ├── skills/                                       │
│  │   ├── doris-environment-check/                  │
│  │   ├── doris-agents-discovery/                   │
│  │   ├── doris-harness-evaluator/                  │
│  │   ├── doris-sprint-contract/                    │
│  │   ├── doris-requirement-analysis/               │
│  │   ├── doris-plan-writer/                        │
│  │   ├── doris-task-executor/                      │
│  │   ├── doris-verification/                       │
│  │   ├── doris-debugging/                          │
│  │   └── doris-branch-finish/                      │
│  └── global_workflows/                             │
│      ├── doris-feature.md                          │
│      ├── doris-refactor.md                         │
│      ├── doris-bugfix.md                           │
│      └── doris-review.md                           │
│                                                    │
└────────────────────────────────────────────────────┘

┌── 目标 3: Doris 仓库内（已有，非本框架管理）──────┐
│                                                    │
│  doris/                                            │
│  ├── AGENTS.md                                     │
│  ├── fe/AGENTS.md                                  │
│  ├── be/src/runtime/AGENTS.md                      │
│  └── ...                                           │
│  (由 Doris 社区维护，框架仅读取不写入)               │
│                                                    │
└────────────────────────────────────────────────────┘
```

## 八、扩展与自定义

### 8.1 添加新的评估标准

在 `criteria/` 下创建新文件，定义评分维度、权重和阈值。Evaluator 根据文件变更路径自动加载对应标准。

### 8.2 添加新的工作流

在 `workflows/` 下创建新的 `.md` 文件，使用 YAML frontmatter 定义 `description`。工作流可以引用任意 Skill 组合。

### 8.3 添加新的 CLI 命令

在 `copilot-cli/commands/` 下创建新的 `.md` 文件。文件名即为命令名（如 `foo.md` → `claude /foo`）。

### 8.4 更新 AGENTS.md

AGENTS.md 由 Doris 社区维护，放在各模块目录下。框架的 `doris-agents-discovery` Skill 会自动发现新增或修改的 AGENTS.md，无需修改框架代码。

---

## 附录：组件交互矩阵

| 组件 | 读取 | 写入 | 调用 | 被调用 |
|------|------|------|------|--------|
| **AGENTS.md (根目录)** | Agent 启动时加载 | Doris 社区维护 | - | 所有组件 |
| **AGENTS.md** | agents-discovery | Doris 社区维护 | - | 所有 Workflow/Evaluator |
| **environment-check** | 环境状态, progress | 自检报告 | agents-discovery | 所有 Workflow Step 1 |
| **agents-discovery** | AGENTS.md 文件 | 约定加载报告 | - | environment-check, 所有 Workflow |
| **requirement-analysis** | 代码结构, AGENTS.md | specs/ | agents-discovery | Workflow Step 2 |
| **plan-writer** | specs/, AGENTS.md | plans/ | - | Workflow Step 3 |
| **sprint-contract** | AGENTS.md 约束 | contracts/ | agents-discovery | Workflow Step 4a |
| **task-executor** | plans/, contracts/ | progress | sprint-contract, evaluator | Workflow Step 4b |
| **harness-evaluator** | criteria/, AGENTS.md | reports/ | agents-discovery | Workflow Step 4c |
| **verification** | - | - | - | Step 5 最终验证 |
| **debugging** | 代码, 日志 | Bug 分析 | - | bugfix Step 2 |
| **branch-finish** | evaluator reports | PR 描述 | verification | Workflow Step 5/6 |
| **Workflows** | plans/, contracts/ | specs/, plans/, progress | 所有 Skills | 用户触发 |
| **CLI Commands** | plans/, progress | 同 Workflows | - | 用户触发 |
