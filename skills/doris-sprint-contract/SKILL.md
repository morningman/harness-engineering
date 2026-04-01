---
name: doris-sprint-contract
description: Negotiate completion criteria between Generator and Evaluator before starting a coding sprint. Use before implementing each task/sprint in a Doris development workflow to define what "done" means.
---

# Doris Sprint Contract

## Purpose

Before starting any coding sprint/task, this skill establishes a **contract** between the Generator (coder) and Evaluator (QA) on what "done" means. This prevents:

1. **Scope creep**: Task grows beyond original intent
2. **Incomplete work**: Missing edge cases or tests
3. **Evaluation mismatch**: Evaluator expects something different from what was built

## When to Use

- Before implementing each task in `doris-task-executor`
- Before each sprint in a multi-sprint development workflow
- When starting a standalone development task with clear deliverables

## Prerequisites

**Before starting contract negotiation**, ensure relevant `AGENTS.md` files have been loaded (via `doris-agents-discovery` skill or `doris-environment-check`). The module conventions from AGENTS.md **must be incorporated** into the contract's completion criteria.

```bash
# Verify AGENTS.md files are available for the modules this sprint touches
find . -name "AGENTS.md" -type f | sort
# Read each relevant AGENTS.md and extract rules applicable to this sprint
```

## Contract Negotiation Process

### Phase 1: Generator Proposes

The Generator (coding agent) drafts a Sprint Contract:

```markdown
## Sprint Contract - [Task Name]

### 目标 (Objective)
[一句话描述本 Sprint 要完成什么]

### 交付物 (Deliverables)
- [ ] [具体的代码产出 1]
- [ ] [具体的代码产出 2]
- [ ] [具体的文件变更]

### 完成标准 (Definition of Done)
- [ ] 编译通过: [具体编译命令]
- [ ] 单元测试: [需要通过的测试]
- [ ] 功能验证: [如何验证功能正确]
- [ ] 代码规范: [需符合的规范]

### 验证步骤 (Verification Steps)
1. [具体的验证命令和期望结果]
2. [具体的验证命令和期望结果]
3. ...

### 范围边界 (Scope Boundaries)
**本 Sprint 包含:**
- [明确包含的内容]

**本 Sprint 不包含:**
- [明确排除的内容]

### AGENTS.md 模块约定 (必填)
- **已加载的 AGENTS.md**: [列出路径]
- **关键约束**:
  - [ ] [从 AGENTS.md 提取的必须遵守的规则 1]
  - [ ] [从 AGENTS.md 提取的规则 2]
  - [ ] ...

### 依赖 (Dependencies)
- [前置条件或依赖的其他 Sprint]

### 预估 (Estimates)
- 修改文件数: ~N
- 新增行数: ~N
- 预计复杂度: 低/中/高
```

### Phase 2: Evaluator Reviews

The Evaluator (QA agent) reviews the contract and may request modifications:

**Evaluator检查:**
1. **完成标准是否可验证？** — 每个标准是否有对应的验证命令
2. **范围是否合理？** — 不太大（一个 sprint 应该 < 500 行修改）也不太小
3. **遗漏的检查项？** — 是否缺少边界条件、异常处理、兼容性等标准
4. **测试覆盖是否充分？** — 新增代码是否有测试计划
5. **AGENTS.md 约束是否包含？** — 相关模块的 AGENTS.md 规则是否已纳入契约

**Evaluator可能添加:**
- 额外的验证步骤
- 遗漏的边界条件
- 性能相关的验证
- 兼容性检查项

### Phase 3: Reach Agreement

Generator 和 Evaluator 达成一致后，Contract 被存储：

```bash
# 存储位置
contracts/sprint-N-[task-name].md
```

## Doris-Specific Contract Rules

### FE Sprint Contracts

必须包含:
- [ ] `mvn package -pl fe-core -DskipTests` 编译通过
- [ ] 相关 FE 单测通过（指定测试类）
- [ ] 新增公共方法有 JavaDoc
- [ ] 异常类型使用正确（AnalysisException / DdlException 等）

### BE Sprint Contracts

必须包含:
- [ ] `./build.sh --be` 编译通过
- [ ] GTest 通过（指定测试文件）
- [ ] 内存安全（无 raw new/delete 或有说明）
- [ ] Status 返回值处理正确

### Connector Sprint Contracts

必须包含:
- [ ] FE + BE（如涉及）编译通过
- [ ] Read Path 或 Write Path 功能完整
- [ ] 类型映射覆盖常用类型
- [ ] 连接/认证失败的错误处理

## Contract Templates

### Template 1: 新增功能

```markdown
## Sprint Contract - [功能名称]

### 目标
为 Doris 添加 [功能描述]

### 交付物
- [ ] [新增类/接口名] 实现
- [ ] [相关修改的现有类]
- [ ] [单元测试文件]
- [ ] [文档更新]（如需要）

### 完成标准
- [ ] FE 编译通过: `cd fe && mvn package -pl fe-core -DskipTests`
- [ ] 新增单元测试全部通过
- [ ] 现有单元测试无回归
- [ ] 新增的公共 API 有 JavaDoc/Doxygen
- [ ] 无 API breaking change（新增属性有默认值）

### 验证步骤
1. `cd fe && mvn package -pl fe-core -DskipTests` → BUILD SUCCESS
2. `cd fe && mvn test -pl fe-core -Dtest=[TestClass]` → Tests: X, Failures: 0
3. 代码检查: [具体检查内容]

### 范围边界
**包含:** [功能核心实现 + 基本测试]
**不包含:** [性能优化, 文档国际化, 高级配置项]
```

### Template 2: 重构

```markdown
## Sprint Contract - [重构描述]

### 目标
将 [模块/类] 从 [旧模式] 重构到 [新模式]

### 交付物
- [ ] 新的 [类名] 替代旧的 [类名]
- [ ] 现有调用方更新
- [ ] 旧代码标记为 @Deprecated 或删除
- [ ] 测试更新

### 完成标准
- [ ] 功能等价: 重构前后行为一致
- [ ] 编译通过
- [ ] 所有现有测试通过（功能回归零容忍）
- [ ] 新增测试验证新模式
- [ ] 无性能退化（如关键路径）

### 验证步骤
1. 编译: `cd fe && mvn package -pl fe-core -DskipTests`
2. 全量单测: `cd fe && mvn test -pl fe-core`
3. 功能等价验证: [具体验证方式]
```

### Template 3: Bug 修复

```markdown
## Sprint Contract - [Bug 描述]

### 目标
修复 [问题描述]

### 交付物
- [ ] Bug 修复代码
- [ ] 回归测试（确保该 Bug 不再出现）
- [ ] 相关的其他防御性修复（如有）

### 完成标准
- [ ] 编译通过
- [ ] Bug 场景不再复现
- [ ] 回归测试通过
- [ ] 无其他功能回归

### 验证步骤
1. 编译: [命令]
2. 回归测试: [命令] → 新增的测试用例通过
3. Bug 验证: [复现步骤 → 确认已修复]
```

## Integration

- **Uses**: `doris-agents-discovery` (loads AGENTS.md before contract negotiation)
- **Used by**: `doris-feature`, `doris-refactor`, `doris-bugfix` workflows
- **Consumed by**: `doris-harness-evaluator` (evaluates against contract + AGENTS.md)
- **Stored in**: `contracts/` directory for the project
- **Tracked in**: `harness-progress.txt` or `.harness/progress.md`
