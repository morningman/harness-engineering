---
name: doris-requirement-analysis
description: Analyze and explore requirements for a Doris development task. Use before planning to understand user intent, constraints, and design. Replaces generic brainstorming with Doris-specific requirement analysis.
---

# Doris 需求分析

## Purpose

在编码前，通过结构化的需求分析理解任务范围、用户场景和技术挑战。
产出功能规格文档，作为后续计划制定的输入。

## When to Use

- 新功能开发（`/doris-feature` Step 2）
- 重构分析（`/doris-refactor` Step 2）
- 任何需要理解需求再动手的场景

## 流程

### Step 1: 探索项目上下文

```bash
# 检查当前代码结构
ls -la fe/fe-core/src/main/java/org/apache/doris/
ls -la be/src/

# 查看最近的提交
git log --oneline -20

# 查看相关文件
find . -name "*.java" | grep -i <关键词>
find . -name "*.cpp" | grep -i <关键词>
```

### Step 2: 理解需求

逐个分析以下问题（一次一个）：

1. **目标用户是谁？** — DBA / 数据分析师 / 开发者
2. **用户场景是什么？** — 具体的使用例子（SQL 语句、操作步骤）
3. **影响哪些组件？** — FE / BE / Connector / 文档
4. **有没有类似的现有实现？** — 参考代码路径
5. **有什么约束和限制？** — 兼容性、性能、安全性
6. **AGENTS.md 中有什么相关约定？** — 模块级规范

### Step 3: 分析技术方案

提出 2-3 个技术方案，包含：
- 方案描述
- 优点和缺点
- 推荐理由

### Step 4: 产出功能规格

产出功能规格文档 `specs/YYYY-MM-DD-feature-name.md`，包含：

```markdown
# 功能规格: [名称]

## 元信息
- 作者: [name]
- 日期: YYYY-MM-DD
- 状态: Draft / Review / Approved

## 1. 概述
### 1.1 背景
### 1.2 目标
### 1.3 非目标

## 2. 用户场景
### 场景 1: [描述]
[SQL 示例或操作步骤]

## 3. 技术设计
### 3.1 架构变化
### 3.2 FE 修改
### 3.3 BE 修改（如涉及）
### 3.4 关键类和接口

## 4. 兼容性
### 4.1 向后兼容
### 4.2 性能影响

## 5. 测试策略
### 5.1 单元测试
### 5.2 回归测试

## 6. AGENTS.md 约束
[列出从 AGENTS.md 提取的、与本需求相关的模块约定]
```

### Step 5: 确认规格

向用户确认规格文档，获得批准后进入计划制定阶段。

## Doris 特定关注点

### Catalog / 外部数据源
- 需要同时考虑 read path 和 write path
- 考虑多种数据格式（Parquet, ORC, CSV）
- JNI 调用的内存管理

### Planner / 优化器
- Nereids 是主推优化器，新功能优先在 Nereids 实现
- 遵循 Visitor/Rewrite 模式
- 代价模型修改需要性能数据支撑

### 存储 / 执行
- Pipeline Operator 模式
- 向量化列式处理
- 内存安全（MemTracker）

## Key Principles

- **一次一个问题** — 不要一次问多个问题
- **YAGNI** — 去掉不必要的功能
- **先理解再动手** — 确认理解了需求再开始设计
- **结合 AGENTS.md** — 设计必须符合模块约定
