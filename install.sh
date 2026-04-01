#!/bin/bash
# Doris Harness Engineering - 安装脚本
# 将 skills, workflows, 评估标准部署到目标 Doris 仓库

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取本脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Doris Harness Engineering - 安装脚本        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}用法: ./install.sh <doris-repo-path> [options]${NC}"
    echo ""
    echo "参数:"
    echo "  <doris-repo-path>  Doris 代码仓库根目录路径"
    echo ""
    echo "选项:"
    echo "  --symlink          使用软链接而非复制（方便开发）"
    echo "  --cli-only         仅安装 Copilot CLI 集成"
    echo "  --skills-only      仅安装 Antigravity Skills"
    echo "  --dry-run          仅显示将要执行的操作"
    exit 1
fi

DORIS_REPO="$1"
USE_SYMLINK=false
CLI_ONLY=false
SKILLS_ONLY=false
DRY_RUN=false

# 解析选项
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --symlink)
            USE_SYMLINK=true
            shift
            ;;
        --cli-only)
            CLI_ONLY=true
            shift
            ;;
        --skills-only)
            SKILLS_ONLY=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            exit 1
            ;;
    esac
done

# 验证 Doris 仓库
if [ ! -d "$DORIS_REPO" ]; then
    echo -e "${RED}错误: 目录不存在: $DORIS_REPO${NC}"
    exit 1
fi

if [ ! -d "$DORIS_REPO/fe" ] && [ ! -d "$DORIS_REPO/be" ]; then
    echo -e "${YELLOW}警告: 在 $DORIS_REPO 中未找到 fe/ 或 be/ 目录${NC}"
    echo -e "${YELLOW}确定这是 Doris 代码仓库吗？${NC}"
    read -p "继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}目标仓库: $DORIS_REPO${NC}"
echo ""

# 安装函数
install_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} $desc: $src → $dst"
        return
    fi
    
    # 创建目标目录
    mkdir -p "$(dirname "$dst")"
    
    if [ "$USE_SYMLINK" = true ]; then
        # 删除旧的链接或文件
        rm -f "$dst"
        ln -s "$src" "$dst"
        echo -e "  ${GREEN}✅${NC} $desc (symlink)"
    else
        cp "$src" "$dst"
        echo -e "  ${GREEN}✅${NC} $desc (copy)"
    fi
}

install_dir() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} $desc: $src → $dst"
        return
    fi
    
    if [ "$USE_SYMLINK" = true ]; then
        rm -rf "$dst"
        ln -s "$src" "$dst"
        echo -e "  ${GREEN}✅${NC} $desc (symlink)"
    else
        rm -rf "$dst"
        cp -r "$src" "$dst"
        echo -e "  ${GREEN}✅${NC} $desc (copy)"
    fi
}

# ========================================
# Phase 1: Copilot CLI 集成
# ========================================
if [ "$SKILLS_ONLY" = false ]; then
    echo -e "${BLUE}▸ Phase 1: 安装 Copilot CLI 集成${NC}"
    
    # 安装 CLI commands
    for cmd in plan implement evaluate refactor check review-fix; do
        install_file \
            "$SCRIPT_DIR/copilot-cli/commands/$cmd.md" \
            "$DORIS_REPO/.claude/commands/$cmd.md" \
            "CLI command: /$cmd"
    done
    
    # 安装 Custom Agents (子代理)
    echo -e "${BLUE}  ▸ 安装 Copilot CLI 子代理${NC}"
    for agent in "$SCRIPT_DIR/copilot-cli/agents"/*.agent.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent")
            install_file \
                "$agent" \
                "$DORIS_REPO/.github/agents/$agent_name" \
                "Custom Agent: ${agent_name%.agent.md}"
        fi
    done
    
    echo ""
fi

# ========================================
# Phase 2: Antigravity Skills
# ========================================
if [ "$CLI_ONLY" = false ]; then
    echo -e "${BLUE}▸ Phase 2: 安装 Antigravity Skills${NC}"
    
    # 获取 Antigravity Skills 目录
    ANTIGRAVITY_SKILLS_DIR="$HOME/.gemini/antigravity/skills"
    
    if [ ! -d "$ANTIGRAVITY_SKILLS_DIR" ]; then
        echo -e "${YELLOW}  Antigravity skills 目录不存在，创建: $ANTIGRAVITY_SKILLS_DIR${NC}"
        mkdir -p "$ANTIGRAVITY_SKILLS_DIR"
    fi
    
    for skill_dir in "$SCRIPT_DIR/skills"/*/; do
        skill_name=$(basename "$skill_dir")
        install_dir \
            "$skill_dir" \
            "$ANTIGRAVITY_SKILLS_DIR/$skill_name" \
            "Skill: $skill_name"
    done
    
    echo ""
fi

# ========================================
# Phase 3: Antigravity Workflows
# ========================================
if [ "$CLI_ONLY" = false ]; then
    echo -e "${BLUE}▸ Phase 3: 安装 Antigravity Workflows${NC}"
    
    ANTIGRAVITY_WORKFLOWS_DIR="$HOME/.gemini/antigravity/global_workflows"
    
    if [ ! -d "$ANTIGRAVITY_WORKFLOWS_DIR" ]; then
        mkdir -p "$ANTIGRAVITY_WORKFLOWS_DIR"
    fi
    
    for workflow in "$SCRIPT_DIR/workflows"/*.md; do
        workflow_name=$(basename "$workflow")
        install_file \
            "$workflow" \
            "$ANTIGRAVITY_WORKFLOWS_DIR/$workflow_name" \
            "Workflow: /${workflow_name%.md}"
    done
    
    echo ""
fi

# ========================================
# Phase 4: 评估标准和模板
# ========================================
echo -e "${BLUE}▸ Phase 4: 安装评估标准和模板${NC}"

install_dir \
    "$SCRIPT_DIR/criteria" \
    "$DORIS_REPO/.harness/criteria" \
    "评估标准"

install_dir \
    "$SCRIPT_DIR/templates" \
    "$DORIS_REPO/.harness/templates" \
    "文档模板"

echo ""

# ========================================
# 完成
# ========================================
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ 安装完成！                               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "已安装到: $DORIS_REPO"
echo ""
echo -e "${BLUE}使用方式:${NC}"
echo ""
echo "  Copilot CLI:"
echo "    cd $DORIS_REPO"
echo "    claude /plan \"描述你的开发任务\""
echo "    claude /check"
echo ""
echo "  Antigravity IDE:"
echo "    /doris-feature \"描述你的新功能\""
echo "    /doris-refactor \"描述重构目标\""
echo "    /doris-bugfix \"描述Bug\""
echo ""

if [ "$USE_SYMLINK" = true ]; then
    echo -e "${YELLOW}注意: 使用了软链接模式。修改 harness-engineering 仓库的文件会自动生效。${NC}"
fi
