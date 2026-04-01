---
name: doris-branch-finish
description: Complete development work and prepare for merge or PR. Use when all tasks are done, tests pass, and you need to decide how to integrate the work into the main branch.
---

# Doris 开发收尾

## Purpose

开发完成后，引导用户选择集成方式（Merge / PR / 保留分支），并生成 PR 描述。

## When to Use

- `/doris-feature` Step 5: 收尾
- `/doris-refactor` Step 7: 收尾
- `/doris-bugfix` Step 7: 收尾
- 任何开发完成需要创建 PR 的时候

## 流程

### Step 1: 最终验证

**在收尾前必须确认测试通过：**

```bash
# FE 编译
cd fe && mvn package -pl fe-core -DskipTests
# 期望: BUILD SUCCESS

# FE 全量单测
cd fe && mvn test -pl fe-core
# 期望: 无失败

# BE 编译（如涉及）
cd be && ./build.sh --be
```

**如果测试失败，停止。先修复再继续。**

### Step 2: 确定基线分支

```bash
# 确认基线分支
git merge-base HEAD master 2>/dev/null || git merge-base HEAD main 2>/dev/null
```

### Step 3: 生成 PR 描述

根据 git diff 和评估报告，生成 Doris 风格的 PR 描述：

```markdown
## Proposed changes

[概述本次修改的目的和主要变化]

## Types of changes

- [ ] Bugfix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation
- [ ] Code refactoring

## Checklist

- [ ] I have added tests to cover my changes
- [ ] All new and existing tests pass
- [ ] If this change adds a new feature, I have updated the documentation
- [ ] This change is backward compatible

## Further comments

### 评估报告摘要
| 维度 | 评分 |
|------|------|
| 编译正确性 | X/10 |
| 单元测试 | X/10 |
| 架构对齐 | X/10 |
| **综合** | **X/10** |

### 涉及的 AGENTS.md 约定
[列出相关的 AGENTS.md 文件和合规情况]
```

### Step 4: 呈现选项

```
实现完成。请选择集成方式:

1. 推送并创建 Pull Request
2. 本地合并到基线分支
3. 保留分支（稍后处理）

选择哪个?
```

### Step 5: 执行选择

#### Option 1: 创建 PR
```bash
git push -u origin <branch-name>
# 如果有 gh CLI
gh pr create --title "<title>" --body "<PR 描述>"
```

#### Option 2: 本地合并
```bash
git checkout master
git pull
git merge <feature-branch>
# 验证合并后测试
cd fe && mvn test -pl fe-core
git branch -d <feature-branch>
```

#### Option 3: 保留
报告分支名和当前状态即可。

### Step 6: 更新进度

```
# Harness Progress (最终)
Plan: plans/YYYY-MM-DD-plan-name.md
Status: COMPLETED
Tasks: N/N completed
Final Score: X.X/10
PR: #XXXX (if created)
```
