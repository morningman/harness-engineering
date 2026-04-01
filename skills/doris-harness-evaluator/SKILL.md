---
name: doris-harness-evaluator
description: Independently evaluate Doris code changes by compiling, running tests, and scoring against Doris-specific quality criteria. Use when code implementation is complete and needs QA evaluation before merge.
---

# Doris Harness Evaluator

## Purpose

This skill provides an **independent QA evaluation** for Doris code changes. Unlike simple code review (which only does static analysis), this evaluator:

1. **Actually compiles** the code to verify correctness
2. **Runs related unit tests** to check for regressions
3. **Scores against criteria** using Doris-specific evaluation standards
4. **Outputs a structured report** with pass/fail determination

## When to Use

- After completing a Sprint/Task in a development workflow
- Before creating a PR or merging code
- When `doris-verification` skill flags potential issues
- When the user explicitly asks to evaluate their Doris code changes

## Evaluation Flow

```
1. Identify Scope
   ↓
2. Compile Verification
   ↓
3. Test Execution
   ↓
4. Criteria Scoring
   ↓
5. Report Generation
```

## Step 1: Identify Scope

Determine what was changed and select the appropriate criteria:

```bash
# Check what files were modified
git diff --name-only HEAD~1

# Or diff against the base branch
git diff --name-only origin/master...HEAD
```

**Scope classification:**
- Modified files under `fe/` → Load `criteria/doris-fe-quality.md`
- Modified files under `be/` → Load `criteria/doris-be-quality.md`


Multiple criteria sets can be loaded if changes span multiple areas.

**Additionally, discover relevant AGENTS.md:**

```bash
# Find all AGENTS.md files in the repository
find . -name "AGENTS.md" -type f | sort

# Check if any AGENTS.md were modified in this branch
git diff origin/master...HEAD -- '**/AGENTS.md'
```

For each modified file, walk UP the directory tree to find the nearest `AGENTS.md` files.
These contain module-specific rules that the code must comply with.

> [!IMPORTANT]
> AGENTS.md files are authoritative module-level conventions. Always re-read them before evaluation — they may have changed since the last session.

## Step 2: Compile Verification

### FE Changes

```bash
cd fe && mvn package -pl fe-core -DskipTests 2>&1
```

**Pass**: Output contains `BUILD SUCCESS`
**Fail**: Any compilation error → Score = 0, evaluation stops

### BE Changes

```bash
cd be && ./build.sh --be 2>&1
```

**Pass**: Build completes without errors
**Fail**: Any compilation error → Score = 0, evaluation stops

> [!IMPORTANT]
> Compilation is a **hard gate**. If compilation fails, the overall evaluation fails immediately regardless of other scores. Fix compilation errors first.

## Step 3: Test Execution

### Identify Related Tests

```bash
# For FE: Find test files that match modified source files
# Example: If OdbcScanNode.java was modified, look for OdbcScanNodeTest.java
find fe/fe-core/src/test -name "*Test.java" | grep -i <modified-class-name>

# For BE: Find GTest files
find be/test -name "*_test.cpp" | grep -i <modified-class-name>
```

### Run Tests

```bash
# FE: Run specific test class
cd fe && mvn test -pl fe-core -Dtest=ClassName

# FE: Run specific test method
cd fe && mvn test -pl fe-core -Dtest=ClassName#methodName

# BE: Run specific UT
cd be && ./run-ut.sh --test TestName
```

### Record Results

- Total tests run
- Tests passed
- Tests failed (with failure messages)
- Tests skipped
- New tests added (compare with base branch)

## Step 4: Criteria Scoring

Load the appropriate criteria file(s) and score each dimension.

For each dimension:
1. Read the criteria checks
2. Evaluate the code against each check
3. Assign a score (1-10)
4. Compare against threshold
5. Calculate weighted score

### Scoring Process

```
For each criterion in loaded criteria:
  score = evaluate(criterion.checks, modified_code)
  weighted_score = score * criterion.weight
  passed = score >= criterion.threshold
  
overall_score = sum(weighted_scores)
overall_passed = all(dimension_passed) AND overall_score >= 7.5
```

### AGENTS.md Compliance Scoring

In addition to criteria-based scoring, check compliance with loaded `AGENTS.md` rules:

```
For each loaded AGENTS.md:
  Extract actionable rules (coding conventions, testing requirements, etc.)
  Check each rule against the modified code
  Record: compliant / non-compliant / not-applicable

agents_compliance_rate = compliant_count / (compliant_count + non_compliant_count)
```

**AGENTS.md compliance is a quality modifier:**
- 100% compliance: no score adjustment
- 80-99% compliance: -0.5 from overall score + list non-compliant items
- <80% compliance: -1.0 from overall score + list all violations as blocking issues

Report format:
```markdown
### AGENTS.md 合规性检查
| AGENTS.md 文件 | 规则数 | 合规 | 不合规 | 不适用 |
|---------------|--------|------|--------|--------|
| AGENTS.md (root) | N | N | N | N |
| fe/fe-core/AGENTS.md | N | N | N | N |
| ... | ... | ... | ... | ... |
| **合规率** | | **N%** | | |

#### 不合规项:
1. [AGENTS.md 路径] 规则: "..." → 违反: "..."
2. ...
```

## Step 5: Report Generation

Generate a structured evaluation report using this template:

```markdown
# Doris 代码评估报告

## 📋 基本信息
- **评估时间**: YYYY-MM-DD HH:MM
- **修改分支**: branch-name
- **修改范围**: FE / BE / Connector / 文档
- **修改文件数**: N
- **新增行数 / 删除行数**: +X / -Y

## 🔨 编译验证
| 组件 | 命令 | 结果 | 耗时 |
|------|------|------|------|
| FE | `mvn package -pl fe-core -DskipTests` | ✅ PASS / ❌ FAIL | Xs |
| BE | `./build.sh --be` | ✅ PASS / ❌ FAIL / ⏭️ N/A | Xs |

## 🧪 测试验证
| 组件 | 运行 | 通过 | 失败 | 跳过 | 新增 |
|------|------|------|------|------|------|
| FE | N | N | N | N | N |
| BE | N | N | N | N | N |

### 失败测试详情
(如有)

## 📊 评分明细

### FE 评分 (如适用)
| 维度 | 分数 | 阈值 | 权重 | 加权分 | 状态 |
|------|------|------|------|--------|------|
| ... | ... | ... | ... | ... | ✅/❌ |

### BE 评分 (如适用)
| 维度 | 分数 | 阈值 | 权重 | 加权分 | 状态 |
|------|------|------|------|--------|------|
| ... | ... | ... | ... | ... | ✅/❌ |

## 🎯 综合评定
- **综合分**: X.X / 10
- **结果**: ✅ 通过 / ❌ 不通过

## 💡 改进建议
1. [具体的改进建议]
2. [具体的改进建议]

## 📝 评估者备注
[对本次评估的额外说明]
```

## Decision Logic

```
IF compilation fails:
  → FAIL immediately, provide compilation error details
  
IF any test regression (previously passing test now fails):
  → FAIL, provide regression details

IF overall_score < 7.5:
  → FAIL, provide per-dimension breakdown with improvement guidance

IF any single dimension < threshold:
  → FAIL, highlight the failing dimension(s)

OTHERWISE:
  → PASS with score and congratulatory feedback
```

## Integration with Other Skills

- **Input from**: `doris-sprint-contract` (completion criteria to verify against)
- **Input from**: `doris-agents-discovery` (AGENTS.md module conventions to check compliance)
- **Triggers after**: `doris-verification` (as a more comprehensive check)
- **Output to**: `doris-branch-finish` (evaluation report included in PR)
- **Iterates with**: `doris-task-executor` (if evaluation fails, generator gets feedback)

## Sub-Agent Architecture (Copilot CLI)

在 Copilot CLI 环境下，本 Skill 的评估逻辑通过 **自定义子代理 (Custom Agent)** 实现真正的 Generator-Evaluator 分离：

```
copilot-cli/agents/
├── doris-evaluator.agent.md    ← QA 评估子代理（只读，不修改代码）
├── doris-implementer.agent.md  ← 代码实现子代理（Generator 角色）
└── doris-researcher.agent.md   ← 代码分析子代理（只读探索）
```

### 工作原理

Copilot CLI 的子代理机制（基于 Copilot SDK `customAgents` API）提供：

1. **隔离的上下文窗口** — 子代理在独立的上下文中运行，不会污染主代理的上下文
2. **受限的工具集** — `doris-evaluator` 仅有 `read`、`search`、`execute` 权限，无法修改代码
3. **自动委派** — Copilot 运行时根据用户意图的 `description` 匹配自动选择子代理
4. **生命周期事件** — `subagent.started`、`subagent.completed`、`subagent.failed` 事件流

### 触发方式

```bash
# 方式 1: 自动推断（Copilot 根据 description 自动匹配）
copilot "评估当前分支的代码修改质量"

# 方式 2: 显式指定
copilot "使用 doris-evaluator 代理评估 fe/ 目录的改动"

# 方式 3: 命令行参数
copilot --agent doris-evaluator --prompt "评估当前 PR"

# 方式 4: 交互模式
# 输入 /agent → 选择 Doris QA Evaluator
```

### 与 Antigravity IDE 的映射关系

| Copilot CLI 子代理 | Antigravity Skill | 角色 |
|-------------------|-------------------|------|
| `doris-evaluator.agent.md` | `doris-harness-evaluator` | Evaluator（只读 QA） |
| `doris-implementer.agent.md` | `doris-task-executor` | Generator（代码实现） |
| `doris-researcher.agent.md` | `doris-requirement-analysis` | 需求分析 & 代码探索 |
