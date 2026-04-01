---
name: doris-environment-check
description: Standardized environment self-check for Doris development. Run at the start of any Doris coding session to verify branch state, compilation environment, and resume previous progress. Use when starting any Doris development task.
---

# Doris Environment Check

## Purpose

Perform a standardized environment self-check before starting any Doris development work. This ensures:

1. The working environment is healthy and ready
2. Previous progress is recovered if resuming work
3. The baseline compiles successfully before making changes
4. The developer has full awareness of the current state

## When to Use

- **Always** at the start of a Doris development session
- When resuming work after a break
- When switching between tasks/branches
- When a compilation or test unexpectedly fails

## Self-Check Flow

Execute these checks in order. If any critical check fails, stop and report the issue.

### Step 1: Working Directory & Branch

```bash
# Confirm working directory
pwd

# Check current branch
git branch --show-current

# Check for uncommitted changes
git status --short

# Recent commit history
git log --oneline -10
```

**Report:**
- Current directory: `___`
- Current branch: `___`
- Uncommitted changes: Yes/No (list if yes)
- Last commit: `___`

### Step 2: Progress Recovery

Check for progress tracking files from a previous session:

```bash
# Look for harness progress files
ls -la harness-progress.txt 2>/dev/null
ls -la .harness/ 2>/dev/null
ls -la progress/*.md 2>/dev/null

# Look for sprint contracts
ls -la contracts/ 2>/dev/null

# Look for implementation plans
ls -la plans/ 2>/dev/null
```

**If progress files exist:**
1. Read and summarize the last recorded progress
2. Identify the next task to do
3. Confirm with the user before resuming

**If no progress files:**
1. This is a fresh start
2. Proceed to environment checks

### Step 3: Compilation Environment

#### FE Environment

```bash
# Check Java version
java -version 2>&1

# Check Maven version
mvn -version 2>&1

# Verify FE baseline compiles (quick check)
cd fe && mvn compile -pl fe-core -q 2>&1 | tail -5
```

**Expected:**
- Java: 8 or 11+
- Maven: 3.6+
- FE compile: SUCCESS

#### BE Environment (if BE work planned)

```bash
# Check C++ compiler
gcc --version 2>&1 | head -1
# or
clang --version 2>&1 | head -1

# Check CMake
cmake --version 2>&1 | head -1

# Check if third-party libraries are built
ls -la be/output/ 2>/dev/null
```

**Expected:**
- GCC: 11+ or Clang: 15+
- CMake: 3.19+
- Third-party libs built

### Step 4: Doris Instance (if needed)

```bash
# Check if FE is running
curl -s http://127.0.0.1:8030/api/bootstrap 2>/dev/null | head -1

# Check if BE is running
curl -s http://127.0.0.1:8040/api/health 2>/dev/null | head -1

# Check MySQL connectivity
mysql -h 127.0.0.1 -P 9030 -u root -e "SELECT 1" 2>/dev/null
```

**Report:** Running / Not running / Not needed

### Step 5: Task Scope Analysis

Based on the user's task, identify:

1. **Affected components**: FE / BE / Connector / Docs
2. **Affected modules**: Catalog / Planner / Scanner / etc.
3. **Key files to modify**: (list them)
4. **Related test files**: (list them)
5. **Compilation commands needed**: (list them)

### Step 6: AGENTS.md 模块约定加载

**关键步骤** — 根据 Step 5 识别的影响范围，发现并加载相关的 `AGENTS.md` 文件。

```bash
# 发现仓库中所有 AGENTS.md
find . -name "AGENTS.md" -type f | sort
```

**筛选逻辑:**
- 根据 Step 5 中识别的 **受影响模块路径**，过滤出相关的 AGENTS.md
- 按就近原则排序（越接近待修改文件的 AGENTS.md 优先级越高）
- **必须读取**: 根目录 `AGENTS.md`（如存在）及所有匹配的子模块 AGENTS.md

**对每个相关的 AGENTS.md:**
1. 读取完整内容
2. 提取关键约束和规范
3. 标记与当前任务直接相关的条目

> [!IMPORTANT]
> AGENTS.md 文件会不定期更新。每次 session 都必须重新读取，不要使用缓存或假设内容不变。

## Output Format

```markdown
## 🔍 Doris 环境自检报告

### 环境状态
| 检查项 | 状态 | 详情 |
|--------|------|------|
| 工作目录 | ✅ | /path/to/doris |
| 当前分支 | ✅ | feature/xxx |
| 未提交修改 | ⚠️/✅ | 有/无 |
| Java 环境 | ✅/❌ | version |
| Maven 环境 | ✅/❌ | version |
| FE 基线编译 | ✅/❌ | SUCCESS/FAILURE |
| BE 环境 (可选) | ✅/❌/⏭️ | version or N/A |

### 上次进度
- 进度文件: [有/无]
- 已完成: [task list]
- 下一步: [next task]

### 本次任务范围
- 影响组件: FE / BE / Connector
- 关键文件: [file list]
- 编译命令: [commands]
- 测试命令: [commands]

### 📋 AGENTS.md 模块约定
| # | 路径 | 范围 | 已加载 |
|---|------|------|--------|
| 1 | AGENTS.md | Root | ✅ |
| 2 | fe/fe-core/AGENTS.md | FE-Core | ✅ |
| 3 | ... | ... | ... |

**关键约束摘要:**
1. [从 AGENTS.md 提取的关键约束]
2. [...]

### 建议
- [任何环境问题的修复建议]
```

## Error Handling

| 问题 | 处理 |
|------|------|
| Git 仓库未初始化 | 提示用户 clone Doris 仓库 |
| Java 未安装 | 提示安装 JDK 8/11 |
| Maven 未安装 | 提示安装 Maven 3.6+ |
| FE 编译失败 | 可能是未 pull 最新代码，提示 `git pull` |
| BE 编译环境缺失 | 提示运行 `./build.sh --build-third-party` |
| 上次进度文件损坏 | 从 git log 恢复状态 |

## Integration

- **Triggers**: At the start of any `doris-feature`, `doris-refactor`, `doris-bugfix` workflow
- **Calls**: `doris-agents-discovery` skill (for loading module-level AGENTS.md conventions)
- **Output feeds into**: `doris-requirement-analysis` or `doris-plan-writer` skills (with AGENTS.md constraints)
- **Can be triggered independently**: `/doris-check` or as part of `/check` CLI command
