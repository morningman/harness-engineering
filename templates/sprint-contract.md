# Sprint 契约模板

```markdown
## Sprint Contract - [Sprint N: Task Name]

### 日期
- 创建: YYYY-MM-DD
- 协商完成: YYYY-MM-DD

### 目标 (Objective)
[一句话描述本 Sprint 要完成什么]

### 背景 (Context)
[为什么需要做这个，属于哪个更大的开发计划]
- 所属计划: [plans/xxx.md]
- 前置 Sprint: [sprint-N-1 的结果]

### 交付物 (Deliverables)
- [ ] [新增文件: path/to/NewClass.java]
- [ ] [修改文件: path/to/ExistingClass.java - 具体修改内容]
- [ ] [新增测试: path/to/NewClassTest.java]
- [ ] [其他交付物]

### 完成标准 (Definition of Done)

#### 硬性标准 (Hard Gates)
- [ ] 编译通过: `cd fe && mvn package -pl fe-core -DskipTests`
- [ ] 相关单测通过: `cd fe && mvn test -pl fe-core -Dtest=XXX`
- [ ] 现有单测无回归: 全量测试通过数 >= 基线

#### 质量标准 (Quality Gates)
- [ ] 新增公共方法都有 JavaDoc
- [ ] 异常处理: 使用正确的异常类型，不吞异常
- [ ] 命名规范: 遵循 Doris 命名规范
- [ ] 无冗余代码: 不复制粘贴

#### 功能标准 (Functional Gates)
- [ ] [具体功能验证 1]
- [ ] [具体功能验证 2]

### 验证步骤 (Verification Steps)
1. 编译: `cd fe && mvn package -pl fe-core -DskipTests`
   - 期望: BUILD SUCCESS
2. 单测: `cd fe && mvn test -pl fe-core -Dtest=[TestClass]`
   - 期望: Tests: X, Failures: 0
3. 功能验证: [具体的功能验证步骤]
   - 期望: [期望结果]

### 范围边界 (Scope Boundaries)

**本 Sprint 包含 (In Scope):**
- [明确包含的内容 1]
- [明确包含的内容 2]

**本 Sprint 不包含 (Out of Scope):**
- [明确排除的内容 1]
- [明确排除的内容 2]

### 依赖 (Dependencies)
- [前置条件或依赖]

### 风险 (Risks)
- [潜在风险 1]: [应对策略]
- [潜在风险 2]: [应对策略]

### 预估 (Estimates)
- 新增文件: ~N
- 修改文件: ~N
- 新增行数: ~N
- 复杂度: 低 / 中 / 高

---

### 协商记录 (Negotiation Log)

**Generator 提议 (v1):**
[初始提议内容]

**Evaluator 反馈:**
[修改建议]

**最终达成一致:**
[最终版本的关键决定]

---
*Contract Status: ✅ AGREED / 🔄 NEGOTIATING*
```
