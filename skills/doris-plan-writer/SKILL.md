---
name: doris-plan-writer
description: Create structured, incremental development plans for Doris tasks. Use after requirement analysis to decompose features into manageable tasks with verification steps.
---

# Doris 计划生成

## Purpose

将功能规格分解为可管理的增量开发计划。每个 Task 是一个可独立编译和测试的增量单元（< 500 行修改）。

## When to Use

- 新功能开发（`/doris-feature` Step 3）
- 重构任务（`/doris-refactor` Step 4）
- 任何需要分解为多步骤的开发任务

## 流程

### Step 1: 范围检查

如果规格覆盖多个独立子系统，应拆分为多个独立计划。每个计划应产出可工作、可测试的软件。

### Step 2: 文件结构规划

在定义任务前，先梳理涉及的文件：

- 哪些文件需要新建
- 哪些文件需要修改
- 哪些文件是测试文件
- 文件放在什么位置（参考 Doris 根目录 AGENTS.md 中的代码结构和各模块 AGENTS.md 的约定）

### Step 3: 增量任务分解

将实现分解为增量任务。每个任务应：

- **独立可编译** — 完成后 `mvn package` 或 `./build.sh` 通过
- **独立可测试** — 有对应的单元测试
- **范围可控** — < 500 行修改
- **有明确的验证命令** — 具体的编译和测试命令
- **符合 AGENTS.md 约定** — 遵循模块级规范

### Step 4: 写入计划文件

保存为 `plans/YYYY-MM-DD-plan-name.md`：

````markdown
# 开发计划: [功能名称]

## 需求概述
[一段话描述需求]

## 影响范围
- FE: [受影响的模块]
- BE: [受影响的模块]
- Connector: [受影响的 Connector]
- 文档: [需要更新的文档]

## AGENTS.md 约束
[列出相关的 AGENTS.md 文件和关键约束]

## 任务分解

### Task 1: [任务名称]

**文件:**
- 新增: `exact/path/to/file.java`
- 修改: `exact/path/to/existing.java`
- 测试: `exact/path/to/test.java`

**步骤:**
- [ ] 创建基础框架代码
- [ ] 编写对应单元测试
- [ ] 编译验证: `cd fe && mvn package -pl fe-core -DskipTests`
- [ ] 测试验证: `cd fe && mvn test -pl fe-core -Dtest=TestClass`
- [ ] Git commit: `[module](scope) description`

**依赖:** 无
**预估改动:** ~N 行

### Task 2: [任务名称]
...

## 风险点
1. [风险 1 和应对策略]

## 时间线
- Task 1: [预估]
- 总计: [总预估]
````

## 任务分解原则

### Doris FE 任务分解模式

```
Step 1: 创建新的类/接口（不修改现有代码）
Step 2: 实现核心逻辑
Step 3: 添加单元测试
Step 4: 集成到调用方
Step 5: 清理旧代码（如重构）
```

### Doris BE 任务分解模式

```
Step 1: 定义头文件（.h）和接口
Step 2: 实现核心逻辑（.cpp）
Step 3: 添加 GTest
Step 4: 集成到 Pipeline/Operator
Step 5: 清理旧代码
```

### Connector 任务分解模式

```
Step 1: JniScanner/JniWriter 基础框架
Step 2: 数据读取/写入逻辑
Step 3: 类型映射
Step 4: ScanNode/SinkNode 集成
Step 5: 错误处理和边界条件
```

## 验证命令清单

每个 Task 必须包含以下对应的验证命令：

| 组件 | 编译命令 | 测试命令 |
|------|---------|---------|
| FE | `cd fe && mvn package -pl fe-core -DskipTests` | `cd fe && mvn test -pl fe-core -Dtest=ClassName` |
| BE | `cd be && ./build.sh --be` | `cd be && ./run-ut.sh --test TestName` |
| 回归 | N/A | `cd regression-test && ./run-regression-test.sh --suite suite_name` |

## Key Principles

- **精确文件路径** — 每个任务指明具体的文件路径
- **完整验证命令** — 每个任务包含编译和测试命令
- **DRY / YAGNI** — 不做不必要的抽象或功能
- **TDD 优先** — 先写测试，再实现
- **频繁提交** — 每个任务完成后 git commit
