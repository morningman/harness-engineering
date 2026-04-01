---
description: Workflow for reviewing a Doris code module to discover issues, then systematically fixing them
---

# /doris-review-fix: 模块审查 → 修复工作流

先对指定代码模块进行全面审查，发现质量问题和改进点，再系统性地逐项修复。

## 前置条件
- 在 Doris 代码仓库根目录
- 明确要审查的目标模块（如 `fe/fe-core/src/main/java/org/apache/doris/datasource/maxcompute/`）

## 工作流步骤

### Phase 1: 审查发现问题

#### Step 1: 环境自检
// turbo
使用 `doris-environment-check` skill 执行环境自检。

#### Step 1.5: 加载模块约定
// turbo
使用 `doris-agents-discovery` skill 发现并加载目标模块的 `AGENTS.md`。

```bash
# 发现所有 AGENTS.md
find . -name "AGENTS.md" -type f | sort

# 重点: 沿目标模块向上查找所有 AGENTS.md
# 例如: 审查 be/src/storage/index/ 模块时，加载:
#   - be/src/storage/index/inverted/AGENTS.md
#   - be/src/storage/AGENTS.md
#   - AGENTS.md (root)
```

#### Step 2: 模块深度审查

**2a. 代码结构分析**

```bash
# 统计模块规模
find <module-path> -name "*.java" -o -name "*.cpp" -o -name "*.h" | wc -l
cloc <module-path>

# 查看文件列表
find <module-path> -type f | sort
```

**2b. 按维度逐项审查**

使用 `doris-harness-evaluator` 的评审维度，但应用到**已有代码**（而非变更）：

1. **代码正确性** — 逻辑 Bug、边界条件、空值处理
2. **架构对齐** — 是否符合 AGENTS.md 中定义的模式（如 JniScanner/Visitor/Pipeline）
3. **错误处理** — 异常类型、日志规范、资源释放
4. **代码质量** — 重复代码、过长方法、命名规范
5. **测试覆盖** — 是否有对应的单测、覆盖率是否充分
6. **性能** — 热路径是否有不必要的开销
7. **AGENTS.md 合规** — 对照模块级约定逐项检查

**2c. 编译验证 (建立基线)**
// turbo
```bash
# FE 编译基线
cd fe && mvn package -pl fe-core -DskipTests 2>&1 | tail -5

# 运行模块相关测试，记录基线
cd fe && mvn test -pl fe-core -Dtest="**/ModuleName*Test" 2>&1 | tee baseline-test-results.txt
```

#### Step 3: 生成审查报告

输出结构化报告，**将发现的问题按优先级分类**：

```markdown
# 模块审查报告: [模块名]

## 📋 模块概要
- **路径**: [module-path]
- **文件数**: N
- **代码行数**: N
- **测试文件数**: N

## 🔴 Critical — 必须修复的问题
1. [问题描述] — [文件:行号]
   原因: [为什么是 Critical]
   建议: [具体修复方案]

## 🟡 Major — 建议修复的问题  
1. [问题描述] — [文件:行号]
   建议: [具体修复方案]

## 🔵 Minor — 可以改进的地方
1. [问题描述] — [文件:行号]
   建议: [具体改进方案]

## 📊 维度评分
| 维度 | 当前分数 | 目标分数 | 差距 |
|------|----------|----------|------|
| 代码正确性 | ?/10 | 9 | |
| 架构对齐 | ?/10 | 8 | |
| 错误处理 | ?/10 | 8 | |
| 代码质量 | ?/10 | 8 | |
| 测试覆盖 | ?/10 | 8 | |
| 性能 | ?/10 | 8 | |
| AGENTS.md 合规 | ?% | 100% | |

## 🔧 修复计划
基于以上发现，拟按以下顺序修复:
- Task 1: [Critical 问题修复]
- Task 2: [Critical 问题修复]
- Task 3: [Major 问题修复]
- ...
```

审查报告保存到: `reports/review-YYYY-MM-DD-[module-name].md`

> **与用户确认**: 在进入 Phase 2 之前，向用户展示审查报告，确认修复范围和优先级。

---

### Phase 2: 系统性修复

#### Step 4: 制定修复计划

使用 `doris-plan-writer` skill，基于审查报告生成修复计划：

- 将审查发现的问题转化为 Task 列表
- 按优先级排序: Critical → Major → Minor
- 每个 Task 约束在 < 500 行改动
- 确保每个 Task 可独立编译和测试

计划保存到: `plans/YYYY-MM-DD-fix-[module-name].md`

#### Step 5: 增量修复（对每个 Task 循环）

##### 5a. Sprint 契约
使用 `doris-sprint-contract` skill:
- 明确本次修复的目标和范围
- 定义完成标准: 编译通过 + 测试不退化 + 解决指定问题

##### 5b. 实现修复
使用 `doris-task-executor` skill:
- 按最小改动原则修复
- 每修一个问题 git commit
- commit message: `[module](scope) fix: 描述具体修复`
- 更新 `harness-progress.txt`

##### 5c. 评估
使用 `doris-harness-evaluator` skill:
- 编译验证
- 回归测试（对比 Step 2c 的基线，测试只增不减）
- AGENTS.md 合规检查
- 未通过 → 回到 5b 修改

#### Step 6: 最终验证
// turbo
```bash
# 全量编译
cd fe && mvn package -pl fe-core -DskipTests

# 全量测试
cd fe && mvn test -pl fe-core 2>&1 | tee final-test-results.txt

# 对比基线
diff <(grep "Tests run:" baseline-test-results.txt) \
     <(grep "Tests run:" final-test-results.txt)
```

#### Step 7: 收尾

使用 `doris-branch-finish` skill:
- PR 描述包含:
  - 模块审查动机
  - 发现的问题清单（附审查报告引用）
  - 修复方案摘要
  - 测试基线对比
  - AGENTS.md 合规状态

## 子代理使用方式 (Copilot CLI)

在 Copilot CLI 中，Phase 1 和 Phase 2 可以利用子代理分工：

```bash
# Phase 1: 使用 doris-researcher 子代理进行深度分析
copilot "分析 fe/fe-core/src/.../datasource/maxcompute/ 模块的架构和质量"
# → 自动委派给 doris-researcher（只读分析）

# Phase 1: 使用 doris-evaluator 子代理进行标准化评估
copilot "评估 maxcompute 模块的代码质量和 AGENTS.md 合规性"
# → 自动委派给 doris-evaluator（只读评估）

# Phase 2: 使用 doris-implementer 子代理进行修复
copilot "根据审查报告修复 maxcompute 模块的 Critical 问题"
# → 自动委派给 doris-implementer（代码修改）
```
