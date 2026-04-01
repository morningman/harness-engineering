# Doris Harness Engineering Framework

> 将 Anthropic Harness Engineering 设计原则落地到 Apache Doris 日常开发工作流

## 概述

Doris Harness Engineering 是一套 AI-assisted 开发框架，将 Anthropic 博客中的 Harness Engineering 核心理念——增量式任务分解、生成-评估分离、契约驱动开发——适配到 Apache Doris 数据库的日常开发流程中。

框架不是一个独立的程序，而是一组 **Skills + Workflows + CLI Commands + 评估标准**，注入到现有的 AI 编程助手（Antigravity IDE / Copilot CLI）中，增强开发者的日常工作流。

## 核心能力

| 能力 | 描述 |
|------|------|
| 🧠 **项目知识注入** | 通过 Doris 代码库根目录的 AGENTS.md 自动为 AI Agent 提供项目级规范 |
| 📋 **Sprint 契约** | 在编码前，明确"完成"的定义，Generator 和 Evaluator 预协商 |
| 🔍 **独立评估** | 独立的 Evaluator Agent 进行编译验证、测试运行和标准化评分 |
| 🏗️ **环境自检** | 每次启动时标准化自检，确认环境健康、恢复上次进度 |
| 📊 **评分体系** | Doris 特定的代码正确性、质量、架构对齐评分标准 |
| 📁 **AGENTS.md 感知** | 自动发现并加载代码库中各模块的 AGENTS.md 约定，确保开发符合模块级规范 |

> 📖 **深入了解**：请阅读 [架构与工作流详解](docs/architecture.md) 了解完整的运行机制。

## 项目结构

```
harness-engineering/
├── README.md                           # 本文件
├── install.sh                          # 安装脚本（部署到目标 Doris 仓库）
│
├── skills/                             # Antigravity IDE Skills（全部自包含）
│   ├── doris-harness-evaluator/        # 独立评估 Skill
│   ├── doris-environment-check/        # 环境自检 Skill
│   ├── doris-agents-discovery/         # AGENTS.md 发现与加载 Skill
│   ├── doris-sprint-contract/          # Sprint 契约 Skill
│   ├── doris-requirement-analysis/     # 需求分析 Skill
│   ├── doris-plan-writer/              # 计划生成 Skill
│   ├── doris-task-executor/            # 任务执行 Skill
│   ├── doris-verification/             # 完成前验证 Skill
│   ├── doris-debugging/                # 系统化调试 Skill
│   └── doris-branch-finish/            # 开发收尾 Skill
│
├── workflows/                          # Antigravity IDE Workflows
│   ├── doris-feature.md                # /doris-feature 新功能开发
│   ├── doris-refactor.md               # /doris-refactor 重构工作流
│   ├── doris-bugfix.md                 # /doris-bugfix 修 Bug 工作流
│   ├── doris-review.md                 # /doris-review 代码审查
│   └── doris-review-fix.md             # /doris-review-fix 审查→修复
│
├── copilot-cli/                        # Copilot CLI 集成
│   ├── commands/                       # 自定义 slash commands
│   │   ├── plan.md
│   │   ├── implement.md
│   │   ├── evaluate.md
│   │   ├── refactor.md
│   │   ├── check.md
│   │   └── review-fix.md
│   └── agents/                         # 自定义子代理 (Custom Agents)
│       ├── doris-evaluator.agent.md    # 独立 QA 评估子代理（只读）
│       ├── doris-implementer.agent.md  # 代码实现子代理
│       └── doris-researcher.agent.md   # 代码库探索子代理（只读）
│
├── criteria/                           # 共享评估标准定义
│   ├── doris-fe-quality.md             # FE (Java) 质量标准
│   └── doris-be-quality.md             # BE 质量标准
│
├── templates/                          # 共享模板
│   ├── progress-tracker.md             # 进度跟踪模板
│   ├── evaluation-report.md            # 评估报告模板
│   ├── sprint-contract.md              # Sprint 契约模板
│   └── feature-spec.md                 # 功能规格模板
│
└── examples/                           # 使用示例
    ├── jdbc-connector-refactoring/     # JDBC Connector 重构示例
    └── catalog-feature-development/    # Catalog 新功能示例
```

## 快速开始

### 安装到 Doris 仓库

```bash
# 克隆本仓库
git clone <repo-url> harness-engineering

# 运行安装脚本，将 skills/workflows 部署到 Doris 仓库
./install.sh /path/to/your/doris-repo
```

### 在 Antigravity IDE 中使用

Skills 和 Workflows 安装后会自动被 Antigravity IDE 识别：

```
# 启动新功能开发
/doris-feature "为 MaxCompute Connector 添加 JniScanner 读路径"

# 启动重构任务
/doris-refactor "将 JDBC Connector 从继承模式迁移到 JniScanner 模式"

# 修复 Bug
/doris-bugfix "修复 Hive Catalog 在 Kerberos 环境下的认证失败问题"
```

### 在 Copilot CLI 中使用

```bash
cd ~/workspace/doris

# 使用自定义 commands
claude /plan "重构 JDBC Connector read path 到 JniScanner 模式"
claude /implement plans/2026-04-01-jdbc-read-refactoring.md
claude /evaluate
claude /check

# 使用子代理 (Custom Agents)
# 方式 1: 自动推断 — Copilot 根据意图自动委派
copilot "评估当前分支的代码修改质量"     # → doris-evaluator
copilot "分析 FE Catalog 模块的架构设计"  # → doris-researcher

# 方式 2: 显式指定子代理
copilot --agent doris-evaluator --prompt "评估 fe/ 改动"

# 方式 3: 交互模式
# 输入 /agent → 选择子代理 → 输入任务
```

## 文档

- **[架构与工作流详解](docs/architecture.md)** — 完整的运行机制、内部架构、评估体系说明
- [Harness Engineering 框架分析](docs/harness-engineering-analysis.md) — 理论基础
- [Doris 适配方案设计](docs/doris-harness-framework-design.md) — 设计决策

## 许可

Apache License 2.0
