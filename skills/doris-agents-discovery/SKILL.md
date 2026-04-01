---
name: doris-agents-discovery
description: Discover and load AGENTS.md files from the Doris codebase to apply module-specific development conventions. Use at the start of any Doris development task and before evaluating code changes. AGENTS.md files contain per-module rules for development, testing, and code style that MUST be followed.
---

# Doris AGENTS.md Discovery

## Purpose

The Doris codebase contains `AGENTS.md` files distributed across module directories. These files define **module-specific development conventions** including:

- Coding standards and patterns unique to that module
- Required testing procedures
- Architecture constraints
- Review checklists
- Common pitfalls and anti-patterns

These files are **authoritative and take precedence** over generic project-level rules when working within a specific module. This skill discovers, loads, and surfaces the relevant `AGENTS.md` content based on the files being modified.

## When to Use

- **Always** at the start of any Doris development session (as part of environment check)
- **Before planning** — to understand module constraints before task decomposition
- **Before coding** — to ensure implementation follows module conventions
- **During evaluation** — to check compliance with module-specific rules
- **During code review** — to apply module-specific review criteria

## Discovery Algorithm

### Step 1: Identify Modified Files

Determine which files will be (or have been) modified:

```bash
# For existing changes
git diff --name-only origin/master...HEAD

# Or for planned changes (from the task description / plan)
# Extract file paths from the plan document
```

### Step 2: Find Relevant AGENTS.md Files

For each modified file, walk UP the directory tree to collect all `AGENTS.md` files from the file's location to the repository root:

```bash
# Given a modified file path, find all AGENTS.md files in its ancestor directories
# Example: for be/src/runtime/memory/mem_tracker.cpp
#   Check: be/src/runtime/memory/AGENTS.md
#   Check: be/src/runtime/AGENTS.md        ← exists
#   Check: be/src/AGENTS.md
#   Check: be/AGENTS.md
#   Check: AGENTS.md                       ← exists (root)

# Automated discovery for all modified files:
find_agents_for_file() {
    local filepath="$1"
    local dir=$(dirname "$filepath")
    while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
        if [ -f "$dir/AGENTS.md" ]; then
            echo "$dir/AGENTS.md"
        fi
        dir=$(dirname "$dir")
    done
    # Also check root
    if [ -f "AGENTS.md" ]; then
        echo "AGENTS.md"
    fi
}
```

**Shortcut: Discover ALL AGENTS.md in the repository:**

```bash
find . -name "AGENTS.md" -type f | sort
```

Then filter to only those relevant to the current task's module scope.

### Step 3: Load and Deduplicate

1. Collect all unique `AGENTS.md` paths found in Step 2
2. Sort by specificity (most specific / deepest path first)
3. Read each file
4. Build a consolidated "Module Conventions" summary

### Step 4: Classify by Scope

Organize discovered AGENTS.md by scope:

| Scope | Path Pattern | Example |
|-------|-------------|---------|
| **Root** | `AGENTS.md` | 项目级通用规范 |
| **Component** | `{fe,be,cloud}/AGENTS.md` | 组件级规范 |
| **Module** | `fe/fe-core/AGENTS.md` | 模块级规范 |
| **Sub-module** | `fe/fe-core/.../datasource/AGENTS.md` | 子模块级别规范 |
| **Feature** | `be/src/storage/index/inverted/AGENTS.md` | 特定功能域规范 |

**Rule of specificity**: More specific (deeper) AGENTS.md rules take precedence over general (higher-level) ones when there is a conflict.

## Output Format

After discovery, output a structured summary:

```markdown
## 📋 AGENTS.md 模块约定加载报告

### 发现的 AGENTS.md 文件
| # | 路径 | 范围 | 适用于本次任务 |
|---|------|------|---------------|
| 1 | AGENTS.md | Root (项目级) | ✅ |
| 2 | fe/AGENTS.md | Component (FE) | ✅ |
| 3 | fe/fe-core/AGENTS.md | Module (FE-Core) | ✅ |
| 4 | fe/fe-core/.../datasource/AGENTS.md | Sub-module | ✅ |
| 5 | be/src/runtime/AGENTS.md | Module (BE-Runtime) | ⏭️ 不涉及 |

### 关键约定摘要

#### 📁 AGENTS.md (Root)
[摘要: 项目级通用约定]

#### 📁 fe/fe-core/AGENTS.md
[摘要: FE-Core 模块约定]

#### 📁 fe/fe-core/.../datasource/AGENTS.md
[摘要: 数据源模块约定]

### ⚠️ 本次开发必须遵循的关键约束
1. [从 AGENTS.md 提取的关键约束 1]
2. [从 AGENTS.md 提取的关键约束 2]
3. ...
```

## Scope-Based Filtering Rules

### For FE tasks
Load AGENTS.md from:
- `AGENTS.md` (root)
- `fe/AGENTS.md`
- `fe/fe-core/AGENTS.md`
- Plus any sub-module AGENTS.md matching the modified file paths (e.g., `datasource/`, `nereids/`, `transaction/`, `backup/`, `persist/`)

### For BE tasks
Load AGENTS.md from:
- `AGENTS.md` (root)
- Plus any sub-module AGENTS.md matching the modified file paths (e.g., `core/`, `io/`, `runtime/`, `storage/`, `common/`, `cloud/`, `exec/`)

### For Cloud tasks
Load AGENTS.md from:
- `AGENTS.md` (root)
- Plus any sub-module AGENTS.md matching the modified file paths (e.g., `recycler/`, `meta-service/`, `meta-store/`)

### For cross-component tasks
Load ALL relevant AGENTS.md files across components.

## Integration with Other Skills

- **doris-environment-check**: Calls this skill during Step 5 (Task Scope Analysis) to preload relevant AGENTS.md
- **doris-sprint-contract**: Includes AGENTS.md constraints as mandatory contract items
- **doris-harness-evaluator**: Checks compliance against AGENTS.md rules during scoring
- **Workflows**: All workflows call this skill before planning and before evaluation
- **CLI commands**: `/plan` and `/implement` reference this skill for context loading

## AGENTS.md Change Detection

Since AGENTS.md files change over time:

1. **Always re-read at session start** — never cache or assume previous content is current
2. **Re-read before evaluation** — rules may have changed between planning and evaluation
3. **Diff-aware**: If git shows AGENTS.md was modified in the current branch, highlight this to the developer:
   ```bash
   git diff origin/master...HEAD -- '**/AGENTS.md'
   ```
