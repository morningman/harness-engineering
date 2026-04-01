---
description: Workflow for reviewing Doris code changes using Harness Engineering evaluation criteria
---

# /doris-review: Doris 代码审查工作流

使用 Harness Engineering 评分标准，对 Doris 代码变更进行结构化审查。

## 前置条件
- 有待审查的代码变更（PR 或本地分支 diff）
- 在 Doris 代码仓库根目录

## 工作流步骤

### Step 1: 获取变更范围
// turbo
```bash
# 如果是审查 PR
git fetch origin pull/PRID/head:pr-PRID
git diff main...pr-PRID --stat

# 如果是审查本地分支
git diff origin/master...HEAD --stat
```

识别:
- 变更文件列表和行数
- 影响的模块（FE/BE/Connector/Docs）
- 关键修改点

### Step 2: 加载评估标准和模块约定

根据变更范围，加载对应的评估标准:
- FE 代码 → `criteria/doris-fe-quality.md`
- BE 代码 → `criteria/doris-be-quality.md`

**加载相关 AGENTS.md 模块约定:**

```bash
# 发现所有 AGENTS.md
find . -name "AGENTS.md" -type f | sort
```

根据变更文件的目录路径，筛选并读取相关的 AGENTS.md。这些模块约定将作为审查的额外检查项。

### Step 3: 编译验证 (如果有代码环境)
// turbo
```bash
# FE
cd fe && mvn package -pl fe-core -DskipTests

# BE (可选)
cd be && ./build.sh --be
```

### Step 4: 结构化审查

对代码变更逐项评审:

#### 4.1 正确性审查
- 逻辑正确性: 代码是否实现了预期功能
- 边界条件: 空值、溢出、并发等
- 错误处理: 异常是否合适处理

#### 4.2 架构审查
- 是否符合现有模式 (Visitor/Pipeline/Scanner)
- 类和方法的职责是否清晰
- 模块边界是否合理

#### 4.3 质量审查
- 代码风格一致性
- 测试覆盖
- 文档完整性

#### 4.4 兼容性审查
- API 向后兼容
- 配置兼容
- 数据格式兼容

#### 4.5 AGENTS.md 合规性审查
- 检查代码变更是否符合相关模块的 AGENTS.md 约定
- 特别关注: 架构模式、命名规范、测试要求、错误处理的模块级规则
- 在审查报告中标注任何不符合 AGENTS.md 的地方

### Step 5: 生成审查报告

```markdown
# Doris 代码审查报告

## 📋 变更概要
- **PR/分支**: [name]
- **修改文件数**: N
- **新增/删除**: +X / -Y
- **影响模块**: FE / BE / Connector

## 📊 评分

| 维度 | 分数 | 备注 |
|------|------|------|
| 正确性 | ?/10 | [简要说明] |
| 架构对齐 | ?/10 | [简要说明] |
| 代码质量 | ?/10 | [简要说明] |
| 测试覆盖 | ?/10 | [简要说明] |
| 兼容性 | ?/10 | [简要说明] |
| 文档 | ?/10 | [简要说明] |
| AGENTS.md 合规 | ?/10 | [已加载的 AGENTS.md 列表及合规情况] |
| **综合** | **?/10** | |

## ✅ 优点
1. [具体的正面反馈]

## ⚠️ 需要修改
1. [具体的问题和修改建议]

## 💡 改进建议（非阻塞）
1. [优化建议]

## 🎯 结论
- [ ] ✅ Approve - 可以合并
- [ ] 🔄 Request Changes - 需要修改后重新审查
- [ ] ❌ Reject - 需要重新设计
```

### Step 6: 输出
- 审查报告保存到 `reports/review-YYYY-MM-DD-[name].md`
- 如果是 GitHub PR，可将关键反馈作为 PR comment
