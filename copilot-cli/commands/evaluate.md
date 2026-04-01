# /evaluate - 评估 Doris 代码变更

对当前代码变更进行全面的 Harness Engineering 评估。

## 流程

1. **识别变更范围**:
   ```bash
   git diff --name-only origin/master...HEAD
   ```

2. **加载评估标准**:
   - FE 代码 → `criteria/doris-fe-quality.md`
   - BE 代码 → `criteria/doris-be-quality.md`


3. **加载模块约定**:
   ```bash
   find . -name "AGENTS.md" -type f | sort
   ```
   根据变更文件路径，筛选并读取相关的 AGENTS.md

4. **编译验证**:
   ```bash
   # FE
   cd fe && mvn package -pl fe-core -DskipTests
   # BE (如涉及)
   cd be && ./build.sh --be
   ```

5. **测试验证**:
   ```bash
   # FE 单测
   cd fe && mvn test -pl fe-core
   # BE 单测 (如涉及)
   cd be && ./run-ut.sh
   ```

6. **按标准打分**: 对每个维度 1-10 评分

7. **AGENTS.md 合规检查**: 检查代码是否符合相关模块的 AGENTS.md 约定

8. **输出报告**: 保存为 `reports/evaluation-YYYY-MM-DD.md`

## 评估判定

- 综合分 ≥ 7.5/10 → ✅ 通过
- 综合分 < 7.5/10 → ❌ 不通过（附改进建议）
- 任何维度 < 阈值 → ❌ 不通过（标注具体问题）
- 编译失败 → ❌ 直接不通过
