# 功能规格: JDBC Connector Read Path 重构到 JniScanner 模式

## 元信息
- 作者: morningman
- 日期: 2026-04-01
- 状态: Example
- 相关 Issue: N/A (示例文档)

---

## 1. 概述

### 1.1 背景
当前 JDBC Connector 的 Read Path 使用基于继承的 `BaseJdbcExecutor` 模式。这与 Doris 其他外部数据源 Connector（如 MaxCompute, Hive）使用的 `JniScanner` 模式不一致，导致：
- 代码维护成本高（两套模式并存）
- 无法复用 JniScanner 框架的优化（向量化读取、内存管理）
- 新增 JDBC 数据源时需要理解特殊的继承模式

### 1.2 目标
将 JDBC Connector 的 Read Path 从 `BaseJdbcExecutor` 继承模式迁移到 `JniScanner` 模式，与其他 Connector 架构统一。

### 1.3 非目标
- 不修改 Write Path（本次仅 Read Path）
- 不修改 JDBC 连接池实现
- 不新增 JDBC 数据源支持

## 2. 用户场景

### 场景 1: 通过 JDBC Catalog 查询外部数据库
**用户**: DBA / 数据分析师
**操作**: 
```sql
CREATE CATALOG mysql_catalog PROPERTIES (
    "type" = "jdbc",
    "jdbc.driver_url" = "mysql-connector-java-8.0.30.jar",
    "jdbc.driver_class" = "com.mysql.cj.jdbc.Driver",
    "jdbc.url" = "jdbc:mysql://host:3306/db",
    "jdbc.user" = "root",
    "jdbc.password" = "password"
);

SELECT * FROM mysql_catalog.db.table WHERE id > 100;
```
**期望结果**: 查询行为不变，性能不退化

## 3. 技术设计

### 3.1 架构变化

```
Before (继承模式):
  VJdbcScanNode → BaseJdbcExecutor → MysqlJdbcExecutor
                                    → PostgresJdbcExecutor
                                    → OracleJdbcExecutor

After (JniScanner 模式):
  VJniScanNode → JniScanner → JdbcJniScanner (Java)
                              ├── open(): 建立 JDBC 连接
                              ├── getNext(): 通过 ResultSet 读取数据
                              └── close(): 关闭连接
```

### 3.2 FE 修改
- 修改 `JdbcScanNode` 使用 `JniScanner` 参数传递方式
- 更新 `ExternalScanNode` 的 Scanner 注册

### 3.3 BE 修改
- 无重大修改（复用现有 JniScanner 框架）

### 3.4 Java 侧修改
- 新增 `JdbcJniScanner` 实现 JniScanner 接口
- 迁移 `BaseJdbcExecutor` 中的读取逻辑
- 保留 `BaseJdbcExecutor` 的 Write 功能

## 4. 兼容性

### 4.1 向后兼容
- SQL 语法: ✅ 完全兼容
- 配置: ✅ 完全兼容（所有 Properties 保持不变）
- API: ✅ 完全兼容

### 4.2 性能影响
- 预期: 通过 JniScanner 的向量化读取，性能应持平或略有提升
- 需要 benchmark 验证

## 5. 测试策略

### 5.1 单元测试
- `JdbcJniScannerTest`: 测试 open/getNext/close 生命周期
- `JdbcTypeMappingTest`: 测试各数据库类型映射

### 5.2 回归测试
- 现有 JDBC 回归测试套件全部通过
- 支持的数据库: MySQL, PostgreSQL, Oracle, SQLServer
