# /review-fix - 审查模块 → 修复问题

对指定 Doris 代码模块进行全面审查，发现问题后系统性修复。

## 用法

```
/review-fix <模块路径或模块描述>
```

**示例:**
```
/review-fix fe/fe-core/src/main/java/org/apache/doris/datasource/maxcompute/
/review-fix "BE 存储层的倒排索引模块"
/review-fix be/src/storage/index/inverted/
```

## Phase 1: 审查

1. **环境自检**:
   ```bash
   git status
   git branch --show-current
   ```

2. **加载模块约定 (AGENTS.md)**:
   ```bash
   find . -name "AGENTS.md" -type f | sort
   ```
   沿目标模块目录树向上查找所有 AGENTS.md，提取模块级约束。

3. **深度审查模块**:
   - 分析代码结构、规模
   - 逐维度审查: 正确性 / 架构 / 错误处理 / 质量 / 测试 / 性能 / AGENTS.md 合规
   - 建立编译和测试基线

4. **生成审查报告**:
   - 问题按 🔴 Critical / 🟡 Major / 🔵 Minor 分级
   - 每个问题附文件路径、行号、修复建议
   - 保存到 `reports/review-YYYY-MM-DD-[module].md`
   - **与用户确认修复范围后进入 Phase 2**

## Phase 2: 修复

5. **制定修复计划**: 将审查问题转化为 Task 列表（Critical 优先）

6. **增量修复** (每个 Task 循环):
   - Sprint 契约 → 实现 → 编译 → 测试 → 评估
   - 每步 < 500 行改动
   - 更新 `harness-progress.txt`

7. **最终验证**:
   ```bash
   cd fe && mvn package -pl fe-core -DskipTests
   cd fe && mvn test -pl fe-core
   ```
   对比基线，确保测试只增不减。

8. **收尾**: 生成 PR 描述（含审查报告引用 + 修复摘要）
