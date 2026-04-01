---
name: doris-verification
description: Verify Doris code changes before claiming completion. Run compilation and tests, check output, then make claims with evidence. Use before committing, creating PRs, or claiming any task is done.
---

# Doris 验证（完成前检查）

## Purpose

在声称任务完成之前，**必须实际运行验证命令并确认结果**。
不允许在没有证据的情况下声称"已完成"。

## 核心原则

```
没有运行验证命令 = 不能声称通过
```

## 验证流程

### 声称前必须执行：

1. **确定验证命令** — 什么命令能证明这个声称？
2. **运行命令** — 完整运行，不跳过
3. **读取输出** — 检查退出码、失败数、错误信息
4. **确认结果** — 输出是否支持声称？
   - 如果不支持 → 说明实际状态
   - 如果支持 → 带证据声称

### Doris 常用验证命令

| 声称 | 验证命令 | 通过标准 |
|------|---------|---------|
| FE 编译通过 | `cd fe && mvn package -pl fe-core -DskipTests` | 输出含 `BUILD SUCCESS` |
| FE 单测通过 | `cd fe && mvn test -pl fe-core -Dtest=ClassName` | `Failures: 0, Errors: 0` |
| FE 全量单测 | `cd fe && mvn test -pl fe-core` | 无新增失败 |
| BE 编译通过 | `cd be && ./build.sh --be` | 编译无错误退出 |
| BE 单测通过 | `cd be && ./run-ut.sh --test TestName` | 所有 test PASSED |
| 无回归 | 对比基线测试结果 | 通过数 ≥ 基线 |

### 危险信号 — 立即停止

如果发现自己在想：
- "应该能通过"
- "我很自信"
- "就这一次跳过"
- "Linter 通过了所以编译也能通过"
- 任何使用 "应该"、"可能"、"看起来" 的描述

**→ 停下来，运行验证命令。**

### 正确示例

```
✅ [运行 mvn package] [看到: BUILD SUCCESS] "FE 编译通过"
❌ "应该能通过" / "看起来没问题"

✅ [运行 mvn test] [看到: Tests: 34, Failures: 0] "34 个测试全部通过"
❌ "测试应该能通过"
```
