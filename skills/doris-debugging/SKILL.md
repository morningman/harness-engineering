---
name: doris-debugging
description: Systematic debugging for Doris bugs and test failures. Use when encountering any bug or unexpected behavior to find root cause before proposing fixes.
---

# Doris 系统化调试

## Purpose

遇到 Bug 或测试失败时，**先找根因，再修复**。禁止猜测性修复。

## 核心原则

```
没有根因分析 = 不能提出修复方案
```

## 四阶段调试流程

### Phase 1: 根因调查

**在尝试任何修复之前：**

1. **仔细阅读错误信息**
   - 完整阅读堆栈跟踪
   - 记录行号、文件路径、错误码
   - Doris FE: 关注 `AnalysisException` / `UserException` / `DdlException` 的区别
   - Doris BE: 关注 `Status` 返回值和错误码

2. **稳定复现**
   - 最小复现路径是什么？
   - 每次都能触发吗？
   - 具体的 SQL 或操作步骤

3. **检查最近变更**
   ```bash
   git log --oneline -20
   git diff HEAD~5
   ```

4. **追踪数据流**
   - 错误值从哪里来？
   - 什么调用链传递了错误值？
   - 沿调用链向上追溯到源头

### Phase 2: 模式分析

1. **找到类似的正常工作的代码**
   ```bash
   # 在 Doris 代码库中搜索类似实现
   grep -r "类似的方法名" fe/fe-core/src/
   ```

2. **对比差异**
   - 正常和异常代码有什么不同？
   - 列出所有差异，无论多小

3. **检查 AGENTS.md**
   - 相关模块的 AGENTS.md 是否有关于此类问题的说明？

### Phase 3: 假设与验证

1. **形成单一假设**
   - "我认为 X 是根因，因为 Y"
   - 写下来，要具体

2. **最小化测试**
   - 做最小的改动来验证假设
   - 一次只改一个变量

3. **验证**
   - 通过 → Phase 4
   - 失败 → 新假设，回到 Phase 3

### Phase 4: 修复实现

1. **先写回归测试**
   ```bash
   # 验证测试会失败（证明 Bug 存在）
   cd fe && mvn test -pl fe-core -Dtest=RegressionTest#testBugScenario
   # 期望: Failures: 1
   ```

2. **修复根因**
   - 一次只改一个地方
   - 不做额外修改（"顺便" 改的东西）

3. **验证修复**
   ```bash
   # 回归测试通过
   cd fe && mvn test -pl fe-core -Dtest=RegressionTest#testBugScenario
   # 期望: Failures: 0
   
   # 全量测试无回归
   cd fe && mvn test -pl fe-core
   ```

4. **如果 3 次修复都失败**
   - 停下来
   - 可能是架构问题，不是简单 Bug
   - 和用户讨论是否需要重新设计

## Bug 分析模板

```markdown
## Bug 分析
- **症状**: [用户看到的问题]
- **复现步骤**: [最小复现路径]
- **根因**: [代码层面的原因]
- **影响范围**: [其他可能受影响的功能]
- **修复策略**: [计划如何修复]
- **风险评估**: 低/中/高
```

## 危险信号 — 停下来

- "快速修一下，以后再调查"
- "试试改 X 看看能不能行"
- "同时改几个地方，跑一次测试"
- "我不完全理解但这可能行"
- 已经试了 2+ 次修复都失败

**→ 回到 Phase 1，重新分析。**
