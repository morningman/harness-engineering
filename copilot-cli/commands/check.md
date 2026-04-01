# /check - Doris 环境自检

对当前 Doris 开发环境进行标准化自检。

## 检查项

### 1. 工作目录
```bash
pwd
git branch --show-current
git status --short
```

### 2. 最近修改
```bash
git log --oneline -10
```

### 3. 进度恢复
```bash
cat harness-progress.txt 2>/dev/null || echo "No progress file found"
```

### 4. 编译环境
```bash
java -version 2>&1 | head -1
mvn -version 2>&1 | head -1
```

### 5. FE 编译检查
```bash
cd fe && mvn compile -pl fe-core -q 2>&1 | tail -3
```

### 6. AGENTS.md 模块约定发现
```bash
# 发现仓库中所有的 AGENTS.md 文件
find . -name "AGENTS.md" -type f | sort

# 检查是否有 AGENTS.md 在当前分支上被修改
git diff origin/master...HEAD -- '**/AGENTS.md' 2>/dev/null
```

简要列出发现的 AGENTS.md 文件及其覆盖范围。

### 7. Doris 实例状态 (可选)
```bash
curl -s http://127.0.0.1:8030/api/bootstrap 2>/dev/null | head -1 || echo "FE not running"
```

## 输出

一份简洁的环境状态报告，包含:
- ✅ 正常项
- ⚠️ 警告项（不影响工作但需注意）
- ❌ 错误项（需要修复才能开始）
- 📋 AGENTS.md 发现情况（列出发现的模块约定文件）
