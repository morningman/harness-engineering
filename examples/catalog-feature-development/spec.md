# 功能规格: Catalog 属性统一模型

## 元信息
- 作者: morningman
- 日期: 2026-04-01
- 状态: Example
- 相关 Issue: N/A (示例文档)

---

## 1. 概述

### 1.1 背景
当前 Doris 的多个 External Catalog（Hive, Iceberg, MaxCompute, Paimon, Hudi）各自管理缓存属性配置，
导致配置名称不一致、默认值不统一、文档分散。需要建立一个统一的属性模型。

### 1.2 目标
- 建立统一的缓存属性配置模型
- 所有 External Catalog 共享相同的缓存配置语义
- 保持向后兼容（旧配置名仍可使用）

### 1.3 非目标
- 不修改缓存实现逻辑
- 不修改 Internal Catalog

## 2. 用户场景

### 场景 1: 创建使用统一缓存配置的 Catalog
```sql
CREATE CATALOG hive_catalog PROPERTIES (
    "type" = "hms",
    "hive.metastore.uris" = "thrift://host:9083",
    -- 统一的缓存属性
    "metadata_cache_ttl_seconds" = "600",
    "metadata_cache_max_size" = "10000",
    "metadata_cache_refresh_interval_seconds" = "300"
);
```

## 3. 技术设计

### 3.1 FE 修改
- 新增: `CatalogCacheProperties` 通用缓存属性类
- 修改: 各 Catalog 使用统一属性模型
- 修改: 属性别名机制（旧名 → 新名映射）

### 3.2 兼容性
- 旧属性名继续可用（通过别名映射）
- 新属性有合理默认值

## 4. 测试策略
- 统一属性模型的单元测试
- 各 Catalog 的属性兼容性测试
- 旧属性名的别名解析测试
