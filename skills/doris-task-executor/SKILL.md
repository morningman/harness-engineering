---
name: doris-task-executor
description: Execute Doris development plans by implementing tasks incrementally. Use when you have a plan and need to implement it task by task with verification between each task.
---

# Doris 任务执行器

## Purpose

按计划逐任务执行开发，每个任务完成后进行验证和 git 提交。
替代独立的 subagent-driven-development 模式，提供适合 Doris 开发的增量执行流程。

## When to Use

- 有开发计划（`plans/*.md`）需要执行时
- `/doris-feature` Step 4: 增量实现
- `/doris-refactor` Step 5: 增量实现

## 执行流程

### Step 1: 加载计划

```bash
# 读取计划文件
cat plans/YYYY-MM-DD-plan-name.md
```

提取所有 Task，记录：
- Task 名称和描述
- 涉及的文件路径
- 验证命令
- 依赖关系

### Step 2: 检查进度

```bash
# 读取进度文件
cat harness-progress.txt 2>/dev/null || echo "无上次进度"
```

跳过已完成的 Task。

### Step 3: 逐任务执行

对每个待完成的 Task 重复以下循环：

```
┌─ 契约协商 ─────────────────────────────────┐
│ 使用 doris-sprint-contract 定义完成标准       │
│ 包含: 文件范围 + 验证命令 + AGENTS.md 约束    │
└─────────────────────────────────────────────┘
        │
        ▼
┌─ 编码实现 ─────────────────────────────────┐
│ 按契约范围编码                              │
│ 遵循 AGENTS.md 各级规范                    │
│ 每个逻辑单元编码后自我检查                    │
└─────────────────────────────────────────────┘
        │
        ▼
┌─ 编译验证 ─────────────────────────────────┐
│ 运行编译命令，确认 BUILD SUCCESS            │
│ 如果失败 → 修复编译错误 → 重新编译           │
└─────────────────────────────────────────────┘
        │
        ▼
┌─ 测试验证 ─────────────────────────────────┐
│ 运行单元测试，确认无失败                     │
│ 如果失败 → 修复测试 → 重新运行               │
└─────────────────────────────────────────────┘
        │
        ▼
┌─ 评估 ─────────────────────────────────────┐
│ 使用 doris-harness-evaluator 评分           │
│ 通过(≥7.5) → Git commit → 更新进度         │
│ 未通过 → 修复 → 重新评估（最多 3 次）        │
└─────────────────────────────────────────────┘
        │
        ▼
   下一个 Task
```

### Step 4: Git Commit

每个 Task 完成后：

```bash
git add -A
git commit -m "[module](scope) task N: description"
```

Commit Message 格式:
- `[FE](catalog) add MaxComputeJniScanner`
- `[BE](runtime) fix memory leak in mem tracker`
- `[Connector](jdbc) migrate to JniScanner pattern`

### Step 5: 更新进度

每个 Task 完成后更新 `harness-progress.txt`：

```
# Harness Progress
Plan: plans/YYYY-MM-DD-plan-name.md
Started: YYYY-MM-DD HH:MM
Last Updated: YYYY-MM-DD HH:MM

## Completed Tasks
- [x] Task 1: [name] (commit: abc1234, score: 9.0)
- [x] Task 2: [name] (commit: def5678, score: 8.5)

## Current Task
- [ ] Task 3: [name] (in progress)

## Remaining Tasks
- [ ] Task 4: [name]
- [ ] Task 5: [name]
```

### Step 6: 最终验证

所有任务完成后：

```bash
# 全量编译
cd fe && mvn package -pl fe-core -DskipTests

# 全量单测
cd fe && mvn test -pl fe-core

# BE 编译（如涉及）
cd be && ./build.sh --be
```

确认所有测试通过，无回归。

## 异常处理

| 情况 | 处理方式 |
|------|---------|
| 编译失败 | 修复编译错误，重新编译（不计入评估次数） |
| 测试失败 | 分析失败原因，修复后重新测试 |
| 评估 3 次未通过 | 停止该 Task，向用户报告问题 |
| 发现计划需要调整 | 停止执行，向用户说明并讨论计划修改 |
| 发现新的依赖 | 记录到 Task 中，如果影响当前 Task 则先解决依赖 |

## Key Principles

- **一次一个 Task** — 不跳跃执行
- **验证后才提交** — 编译+测试通过后才 git commit
- **进度持久化** — 每个 Task 完成后更新进度文件
- **失败上报** — 3 次评估未通过时不强行继续
