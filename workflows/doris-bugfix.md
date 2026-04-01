---
description: Workflow for fixing Doris bugs with regression tests using Harness Engineering methodology
---

# /doris-bugfix: Bug 修复工作流

使用 Harness Engineering 方法论修复 Doris Bug，确保修复正确且不引入回归。

## 前置条件
- Bug 描述清晰（复现步骤、期望行为、实际行为）
- 在 Doris 代码仓库根目录

## 工作流步骤

### Step 1: 环境自检
// turbo
使用 `doris-environment-check` skill 执行环境自检。

### Step 1.5: 加载模块约定
// turbo
使用 `doris-agents-discovery` skill 发现并加载 Bug 所在模块的 `AGENTS.md`。

```bash
find . -name "AGENTS.md" -type f | sort
```

提取与 Bug 修复相关的模块约束，特别关注:
- 错误处理规范（异常类型、日志规范等）
- 测试约定（回归测试要求）
- 兼容性要求

### Step 2: Bug 分析
使用 `doris-debugging` skill:
- 理解 Bug 的症状和影响
- 定位 Bug 的根因（Root Cause）
- 分析影响范围（是否影响其他功能）
- 确定修复策略

**Bug 分析模板:**
```markdown
## Bug 分析
- **症状**: [用户看到的问题]
- **复现步骤**: [最小复现路径]
- **根因**: [代码层面的原因]
- **影响范围**: [其他可能受影响的功能]
- **修复策略**: [计划如何修复]
- **风险评估**: 低/中/高
```

### Step 3: 编写回归测试（TDD 方式）
// turbo
**先写测试，后修代码：**

1. 编写能复现 Bug 的单元测试
2. 运行测试，确认测试失败（证明 Bug 存在）
3. 记录测试名称

```bash
# 运行新测试，确认失败
cd fe && mvn test -pl fe-core -Dtest=NewRegressionTest#testBugScenario
# 期望: Tests run: 1, Failures: 1
```

### Step 4: Sprint 契约
使用 `doris-sprint-contract` skill (使用 Bug 修复模板):
- 完成标准: Bug 不再复现 + 回归测试通过
- 范围: 仅修复 Bug，不做额外重构

### Step 5: 修复实现
- 按最小改动原则修复 Bug
- 优先修改根因，而非打补丁
- 考虑是否需要防御性编程（其他类似位置）

### Step 6: 验证
使用 `doris-harness-evaluator` skill:

// turbo
**验证序列:**
```bash
# 1. 编译
cd fe && mvn package -pl fe-core -DskipTests

# 2. 回归测试通过
cd fe && mvn test -pl fe-core -Dtest=NewRegressionTest#testBugScenario
# 期望: Tests run: 1, Failures: 0

# 3. 全量单测无回归
cd fe && mvn test -pl fe-core
# 期望: 无新增失败
```

**AGENTS.md 合规检查:**
- 确认修复代码符合模块 AGENTS.md 中的规范要求
- 特别检查错误处理、日志、异常类型是否符合模块约定

### Step 7: 收尾
使用 `doris-branch-finish` skill:
- PR 描述包含:
  - Bug 描述和影响
  - 根因分析
  - 修复方案
  - 回归测试说明
  - Cherry-pick 信息（如需 backport 到旧版本）

**PR 描述模板:**
```markdown
## Problem
[Bug 的症状和影响]

## Root Cause
[代码层面的根因分析]

## Solution
[修复方案及设计决策]

## Test
- 新增回归测试: [TestClass#testMethod]
- 全量单测通过: [测试结果]

## Checklist
- [ ] 回归测试验证 Bug 已修复
- [ ] 全量单测无回归
- [ ] 编译通过
- [ ] 是否需要 cherry-pick 到旧版本: Yes/No
```
