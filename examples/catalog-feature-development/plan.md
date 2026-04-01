# 开发计划: Catalog 属性统一模型

## 需求概述
为所有 External Catalog 建立统一的缓存属性配置模型，消除各 Catalog 配置不一致的问题。

## 影响范围
- FE: `fe-core/.../catalog/` (属性模型), `fe-core/.../datasource/` (各 Catalog 适配)
- BE: 无
- 文档: 各 Catalog 文档更新

## 任务分解

### Task 1: 创建 CatalogCacheProperties 统一属性类
- **描述**: 定义统一的缓存属性名称、默认值和验证逻辑
- **文件**: 
  - 新增: `fe-core/.../catalog/CatalogCacheProperties.java`
  - 新增: `fe-core/.../catalog/CatalogCachePropertiesTest.java`
- **依赖**: 无
- **验证**:
  - `cd fe && mvn package -pl fe-core -DskipTests`
  - `cd fe && mvn test -pl fe-core -Dtest=CatalogCachePropertiesTest`
- **预估**: ~200 行

### Task 2: 实现属性别名机制
- **描述**: 支持旧属性名到新属性名的自动映射，保持向后兼容
- **文件**:
  - 修改: `CatalogCacheProperties.java`
  - 新增: `PropertyAliasTest.java`
- **依赖**: Task 1
- **预估**: ~150 行

### Task 3: 适配各 External Catalog
- **描述**: 修改 Hive, Iceberg, MaxCompute, Paimon, Hudi Catalog 使用统一属性模型
- **文件**:
  - 修改: 各 Catalog 的 Properties 处理逻辑
  - 修改: 各 Catalog 的单测
- **依赖**: Task 2
- **预估**: ~300 行

### Task 4: 更新文档
- **描述**: 统一各 Catalog 文档中的缓存属性说明
- **文件**: docs/ 下各 Catalog 文档
- **依赖**: Task 3
- **预估**: ~200 行
