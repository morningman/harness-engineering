# 开发计划: JDBC Connector Read Path 重构到 JniScanner 模式

## 需求概述
将 JDBC Connector 的 Read Path 从 BaseJdbcExecutor 继承模式迁移到 JniScanner 模式，统一 Connector 架构。

## 影响范围
- FE: `fe-core/.../datasource/jdbc/` (ScanNode 改造)
- BE: 无重大修改（复用 JniScanner 框架）
- Java: `fe-core/.../jni/` (新增 JdbcJniScanner)
- 文档: 无（用户无感知）

## 任务分解

### Task 1: 创建 JdbcJniScanner 基础框架
- **描述**: 创建 `JdbcJniScanner` 类，实现 `JniScanner` 接口的基本框架（open/getNext/close 方法签名）
- **文件**: 
  - 新增: `fe-core/src/main/java/org/apache/doris/jni/JdbcJniScanner.java`
  - 新增: `fe-core/src/test/java/org/apache/doris/jni/JdbcJniScannerTest.java`
- **依赖**: 无
- **验证**:
  - 编译: `cd fe && mvn package -pl fe-core -DskipTests`
  - 测试: `cd fe && mvn test -pl fe-core -Dtest=JdbcJniScannerTest`
- **预估改动**: ~150 行

### Task 2: 实现 JDBC 连接与数据读取逻辑
- **描述**: 在 `JdbcJniScanner` 中实现实际的 JDBC 连接建立、SQL 执行、ResultSet 读取逻辑
- **文件**:
  - 修改: `fe-core/.../jni/JdbcJniScanner.java`
  - 新增: `fe-core/.../jni/JdbcJniScannerTest.java` (补充测试)
- **依赖**: Task 1
- **验证**:
  - 编译: `cd fe && mvn package -pl fe-core -DskipTests`
  - 测试: `cd fe && mvn test -pl fe-core -Dtest=JdbcJniScannerTest`
- **预估改动**: ~300 行

### Task 3: 实现类型转换逻辑
- **描述**: 迁移 `BaseJdbcExecutor` 中的各数据库类型转换逻辑到 JdbcJniScanner
- **文件**:
  - 修改: `fe-core/.../jni/JdbcJniScanner.java`
  - 新增: `fe-core/.../jni/JdbcTypeMappingTest.java`
- **依赖**: Task 2
- **验证**:
  - 编译: `cd fe && mvn package -pl fe-core -DskipTests`
  - 测试: `cd fe && mvn test -pl fe-core -Dtest=JdbcTypeMappingTest`
- **预估改动**: ~250 行

### Task 4: 更新 ScanNode 接入新 Scanner
- **描述**: 修改 `JdbcScanNode` 使用 `JdbcJniScanner` 替代 `BaseJdbcExecutor` 的 read 调用
- **文件**:
  - 修改: `fe-core/.../datasource/jdbc/JdbcScanNode.java`
  - 修改: `fe-core/.../plan/nodes/scan/ExternalScanNode.java` (如需要)
- **依赖**: Task 3
- **验证**:
  - 编译: `cd fe && mvn package -pl fe-core -DskipTests`
  - 测试: `cd fe && mvn test -pl fe-core` (全量 FE 测试)
- **预估改动**: ~200 行

### Task 5: 清理旧 Read Path 代码
- **描述**: 清理 `BaseJdbcExecutor` 中不再需要的 read 相关代码，保留 write 功能
- **文件**:
  - 修改: `fe-core/.../external/jdbc/BaseJdbcExecutor.java`
  - 修改: 各数据库 Executor（MySQLJdbcExecutor 等）
- **依赖**: Task 4
- **验证**:
  - 编译: `cd fe && mvn package -pl fe-core -DskipTests`
  - 测试: `cd fe && mvn test -pl fe-core` (全量 FE 测试，确保无回归)
- **预估改动**: ~100 行 (删除为主)

## 风险点
1. **类型转换兼容性**: 不同数据库的类型映射复杂，迁移时可能遗漏特殊类型
   - 应对: 逐数据库类型建立完整的类型映射测试
2. **性能回归**: JniScanner 路径的性能可能与原 BaseJdbcExecutor 不同
   - 应对: 在 Task 4 完成后进行性能基准测试

## 时间线
- Task 1: 0.5 天
- Task 2: 1 天
- Task 3: 1 天
- Task 4: 0.5 天
- Task 5: 0.5 天
- 总计: ~3.5 天
