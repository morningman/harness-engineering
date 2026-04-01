# /implement - 执行 Doris 开发计划

根据给定的开发计划文件，逐个 Task 执行实现。

## 流程

1. **读取计划**: 解析计划文件中的任务列表
2. **检查进度**: 读取 `harness-progress.txt` 确认已完成的 Task
3. **加载模块约定**: 发现并读取相关 `AGENTS.md` 文件
   ```bash
   find . -name "AGENTS.md" -type f | sort
   ```
4. **对每个待完成的 Task**:
   a. 定义 Sprint 契约（完成标准，包含 AGENTS.md 约束）
   b. 编码实现（遵循 AGENTS.md 模块约定）
   c. 编译验证
   d. 运行单测
   e. AGENTS.md 合规检查
   f. Git commit
   g. 更新进度文件
5. **最终验证**: 全量编译 + 全量单测
6. **生成报告**: 输出实现报告

## 使用方式

```bash
claude /implement plans/YYYY-MM-DD-plan-name.md
```

## 实现原则

- **增量**: 一次只做一个 Task，完成后再做下一个
- **可验证**: 每个 Task 完成后必须编译通过 + 相关测试通过
- **可追踪**: 每个 Task 完成后更新进度文件并 git commit
- **可恢复**: 如果中断，下次通过进度文件恢复

## 进度文件格式

```
# Harness Progress
Plan: plans/YYYY-MM-DD-plan-name.md
Started: YYYY-MM-DD HH:MM
Last Updated: YYYY-MM-DD HH:MM

## Completed Tasks
- [x] Task 1: description (commit: abc1234)
- [x] Task 2: description (commit: def5678)

## Current Task
- [ ] Task 3: description (in progress)

## Remaining Tasks
- [ ] Task 4: description
- [ ] Task 5: description
```
