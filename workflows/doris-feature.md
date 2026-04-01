---
description: Complete workflow for developing a new Doris feature using Harness Engineering methodology
---

# /doris-feature: 新功能开发工作流

使用 Harness Engineering 方法论，端到端开发一个 Doris 新功能。

## 前置条件
- 在 Doris 代码仓库根目录
- 有明确的功能需求描述

## 工作流步骤

### Step 1: 环境自检
// turbo
使用 `doris-environment-check` skill 执行环境自检。
确认分支、编译环境、前次进度。

### Step 1.5: 加载模块约定
// turbo
使用 `doris-agents-discovery` skill 发现并加载相关的 `AGENTS.md` 文件。

```bash
find . -name "AGENTS.md" -type f | sort
```

根据功能需求涉及的模块路径，筛选相关的 AGENTS.md 并读取其内容。
提取关键约束，在后续的需求探索和计划制定中引用这些约束。

### Step 2: 需求探索
使用 `doris-requirement-analysis` skill 探索需求:
- 理解功能的用户场景
- 分析影响的模块（FE/BE/Connector）
- 识别关键技术挑战
- 产出功能规格文档: `specs/YYYY-MM-DD-feature-name.md`

### Step 3: 制定计划
使用 `doris-plan-writer` skill 生成开发计划:
- 将功能分解为可管理的增量任务（每个任务 < 500 行修改）
- 识别任务间的依赖关系
- 为每个任务标注影响范围（FE/BE/Connector）
- 添加编译验证步骤
- **确保计划符合 AGENTS.md 中的模块约束**
- 产出计划文档: `plans/YYYY-MM-DD-feature-name.md`

### Step 4: 增量实现（对每个 Task 重复）

#### 4a. Sprint 契约
使用 `doris-sprint-contract` skill:
- 定义本 Task 的完成标准
- 明确交付物、验证步骤、排除项
- 存储契约: `contracts/sprint-N-task-name.md`

#### 4b. 编码实现
使用 `doris-task-executor` skill 逐任务执行:
- 按契约规定的范围实现
- 每个逻辑单元完成后 git commit
- 遵循 Doris 根目录 AGENTS.md 中的编码规范
- **遵循相关 AGENTS.md 中的模块级约定**

#### 4c. 评估
使用 `doris-harness-evaluator` skill:
- 编译验证
- 运行相关单元测试
- 按评分标准打分
- **检查 AGENTS.md 合规性**
- 如不通过: 根据反馈修复并重新评估（最多 3 次）
- 如通过: 进入下一个 Task

### Step 5: 收尾
使用 `doris-verification` skill 做最终验证:
// turbo
- 全量编译: `cd fe && mvn package -pl fe-core -DskipTests`
- 全量单测: `cd fe && mvn test -pl fe-core` (如 BE 修改则也编译 BE)
- 代码规范检查

使用 `doris-branch-finish` skill:
- 生成 PR 描述（包含功能说明、测试结果、评估报告摘要）
- 决定是创建 PR 还是直接合并

### Step 6: 更新进度
更新 `harness-progress.txt`:
```
[YYYY-MM-DD HH:MM] Feature: [name]
Status: COMPLETED
Tasks: [N/N completed]
Final Score: [X.X/10]
PR: #XXXX (if created)
```
