## Sprint Contract - Sprint 1: 创建 JdbcJniScanner 基础框架

### 日期
- 创建: 2026-04-01
- 协商完成: 2026-04-01

### 目标 (Objective)
创建 JdbcJniScanner 类的基础框架，定义 open/getNext/close 生命周期方法，确保编译通过并有基础单元测试。

### 背景 (Context)
本 Sprint 是 JDBC Read Path 重构计划的第一步，需要先搭建新 Scanner 的骨架代码。
- 所属计划: plans/2026-04-01-jdbc-read-refactoring.md
- 前置 Sprint: 无（第一个 Sprint）

### 交付物 (Deliverables)
- [x] 新增: `fe-core/src/main/java/org/apache/doris/jni/JdbcJniScanner.java`
  - 实现 JniScanner 接口
  - 定义成员变量（连接信息、查询参数）
  - 实现 open() 空方法
  - 实现 getNext() 空方法（返回 0 行）
  - 实现 close() 空方法
- [x] 新增: `fe-core/src/test/java/org/apache/doris/jni/JdbcJniScannerTest.java`
  - 测试构造函数
  - 测试生命周期 open → getNext → close
  - 测试参数解析

### 完成标准 (Definition of Done)

#### 硬性标准 (Hard Gates)
- [x] 编译通过: `cd fe && mvn package -pl fe-core -DskipTests`
- [x] 相关单测通过: `cd fe && mvn test -pl fe-core -Dtest=JdbcJniScannerTest`
- [x] 现有单测无回归

#### 质量标准 (Quality Gates)
- [x] JdbcJniScanner 类有完整的 JavaDoc
- [x] open/getNext/close 方法有文档注释
- [x] 遵循 Doris 命名规范（camelCase）

#### 功能标准 (Functional Gates)
- [x] JdbcJniScanner 正确实现 JniScanner 接口
- [x] 构造函数正确解析 JDBC 连接参数

### 验证步骤 (Verification Steps)
1. 编译: `cd fe && mvn package -pl fe-core -DskipTests`
   - 结果: BUILD SUCCESS ✅
2. 单测: `cd fe && mvn test -pl fe-core -Dtest=JdbcJniScannerTest`
   - 结果: Tests: 3, Failures: 0 ✅
3. 代码检查: 确认类正确继承 JniScanner
   - 结果: ✅

### 范围边界 (Scope Boundaries)

**本 Sprint 包含 (In Scope):**
- JdbcJniScanner 类的基础框架（方法签名 + 空实现）
- 基础单元测试
- JavaDoc 注释

**本 Sprint 不包含 (Out of Scope):**
- 实际的 JDBC 连接逻辑
- 数据读取和类型转换
- ScanNode 集成

### 预估 (Estimates)
- 新增文件: 2
- 修改文件: 0
- 新增行数: ~150
- 复杂度: 低

---

### 协商记录 (Negotiation Log)

**Generator 提议 (v1):**
- 创建 JdbcJniScanner 基础框架
- 完成标准: 编译通过 + 有基础单测

**Evaluator 反馈:**
- 需要增加: 确认 open/getNext/close 生命周期方法已定义
- 需要增加: 构造函数参数解析的测试
- 建议: 在 open() 中先打日志，方便后续调试

**最终达成一致 (v2):**
- 采纳 Evaluator 的所有建议
- 增加了生命周期方法和参数解析的测试

---
*Contract Status: ✅ AGREED*
