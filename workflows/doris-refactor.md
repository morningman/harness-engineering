---
description: Workflow for refactoring Doris code using Harness Engineering to ensure functional equivalence
---

# /doris-refactor: 重构工作流

使用 Harness Engineering 方法论，安全地重构 Doris 代码，确保功能等价。

## 前置条件
- 在 Doris 代码仓库根目录
- 明确的重构目标和范围

## 工作流步骤

### Step 1: 环境自检
// turbo
使用 `doris-environment-check` skill 执行环境自检。

### Step 1.5: 加载模块约定
// turbo
使用 `doris-agents-discovery` skill 发现并加载重构涉及模块的 `AGENTS.md`。

```bash
find . -name "AGENTS.md" -type f | sort
```

提取与重构相关的约束，特别关注:
- 架构模式约定（确保重构后仍符合模块架构规范）
- 命名规范和代码风格要求
- 测试约定（重构后的测试要求）

### Step 2: 重构分析
使用 `doris-requirement-analysis` skill:
- 分析当前代码结构和问题
- 确定目标架构/模式
- 识别所有受影响的文件和调用链
- 评估风险点（兼容性、性能、稳定性）
- 产出重构规格: `specs/YYYY-MM-DD-refactor-name.md`

**重构特殊关注:**
- 确认旧代码是否有外部依赖（其他模块、插件、API）
- 是否需要保留旧接口做兼容过渡
- 是否有性能敏感路径

### Step 3: 建立基线
// turbo
**关键步骤 — 在重构前记录基线结果:**

```bash
# 运行现有测试，记录通过的测试列表
cd fe && mvn test -pl fe-core 2>&1 | tee baseline-test-results.txt

# 记录基线测试数量
grep "Tests run:" baseline-test-results.txt | tail -1
```

保存基线信息:
- 当前通过的测试列表和数量
- 关键功能的行为记录
- 性能基线（如涉及热路径）

### Step 4: 制定增量计划
使用 `doris-plan-writer` skill:
- 将重构分解为最小安全步骤（每步改名/移动/替换尽量独立）
- 确保每步完成后系统仍可编译、测试通过
- 标注是否需要保留旧接口（@Deprecated 过渡期）

**重构计划模式:**
```
Step 1: 创建新的替代类/接口（不修改旧代码）
Step 2: 在新类中实现目标逻辑
Step 3: 添加新类的单元测试
Step 4: 逐个切换调用方到新类
Step 5: 标记旧代码为 @Deprecated 或删除
Step 6: 最终验证和清理
```

### Step 5: 增量重构（对每个 Step 重复）

#### 5a. Sprint 契约
使用 `doris-sprint-contract` skill (使用重构模板):
- **必须包含**: 功能等价性验证
- **必须包含**: 回归测试 0 失败

#### 5b. 实现
- 按步骤执行重构
- 每个步骤完成后 git commit
- commit message: `[module](scope) refactor: step N - description`

#### 5c. 评估（严格模式）
使用 `doris-harness-evaluator` skill:
- **额外检查**: 与基线对比，测试数量只增不减
- **额外检查**: 无新增的编译警告
- **AGENTS.md 合规检查**: 重构后的代码必须符合模块 AGENTS.md 约定
- **零容忍**: 任何测试回归或 AGENTS.md 严重违规直接 FAIL

### Step 6: 功能等价验证
// turbo
```bash
# 运行完整测试套件
cd fe && mvn test -pl fe-core 2>&1 | tee refactor-test-results.txt

# 对比基线
diff <(grep "Tests run:" baseline-test-results.txt) \
     <(grep "Tests run:" refactor-test-results.txt)
```

- 通过的测试数量 >= 基线
- 无新增失败
- 无性能退化（如有 benchmark）

### Step 7: 收尾
使用 `doris-branch-finish` skill:
- PR 描述包含:
  - 重构动机（为什么重构）
  - 重构方法（新模式 vs 旧模式）
  - 功能等价证明（测试报告对比）
  - 性能影响说明
  - 迁移指南（如有 breaking change）
