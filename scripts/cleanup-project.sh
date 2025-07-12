#!/bin/bash
# 项目结构清理和验证脚本
# 用于克隆模式部署前的完整性检查

set -e

echo "🧹 开始项目结构清理和验证..."

# 定义项目根目录
PROJECT_ROOT="/workspaces/legezhixiao"
cd "$PROJECT_ROOT"

# 1. 清理空文件 (排除node_modules)
echo "📂 检查并处理空文件..."
EMPTY_FILES=$(find . -name "node_modules" -prune -o -type f -size 0 -print 2>/dev/null || true)

if [ -n "$EMPTY_FILES" ]; then
    echo "⚠️  发现空文件:"
    echo "$EMPTY_FILES"
    
    # 询问是否删除空文件 (自动模式下直接删除)
    echo "🗑️  自动删除空文件..."
    echo "$EMPTY_FILES" | xargs rm -f 2>/dev/null || true
    echo "✅ 空文件清理完成"
else
    echo "✅ 未发现空文件"
fi

# 2. 验证关键文件存在性
echo "🔍 验证关键文件..."

CRITICAL_FILES=(
    "backend/main.py"
    "backend/requirements.txt"
    "backend/app/core/database.py"
    "backend/app/core/config.py"
    "frontend/package.json"
    "frontend/src/main.ts"
    "docker-compose.production.yml"
    ".github/workflows/deploy.yml"
)

MISSING_FILES=()
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    elif [ ! -s "$file" ]; then
        echo "⚠️  关键文件为空: $file"
    else
        echo "✅ $file"
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo "❌ 缺失关键文件:"
    printf '%s\n' "${MISSING_FILES[@]}"
    exit 1
fi

# 3. 验证Docker配置文件语法
echo "🐳 验证Docker配置..."
if command -v docker-compose &> /dev/null; then
    if docker-compose -f docker-compose.production.yml config &> /dev/null; then
        echo "✅ Docker Compose配置有效"
    else
        echo "❌ Docker Compose配置语法错误"
        docker-compose -f docker-compose.production.yml config
        exit 1
    fi
else
    echo "⚠️  Docker Compose未安装，跳过语法检查"
fi

# 4. 验证Python依赖
echo "🐍 验证Python依赖..."
if [ -f "backend/requirements.txt" ]; then
    if python3 -m pip check &> /dev/null; then
        echo "✅ Python依赖检查通过"
    else
        echo "⚠️  Python依赖可能有冲突"
        python3 -m pip check || true
    fi
fi

# 5. 验证Node.js依赖
echo "📦 验证Node.js依赖..."
if [ -f "frontend/package.json" ]; then
    cd frontend
    if npm ls &> /dev/null; then
        echo "✅ Node.js依赖检查通过"
    else
        echo "⚠️  Node.js依赖可能有问题"
        npm ls || true
    fi
    cd ..
fi

# 6. 检查可执行脚本权限
echo "🔧 检查脚本权限..."
SCRIPTS=(
    "backend/start.sh"
    "backend/start-fixed.sh"
    "backend/start-ultimate.sh"
    "scripts/setup-docker-mirrors.sh"
    "scripts/fix-docker-network.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ ! -x "$script" ]; then
            echo "🔧 修复脚本权限: $script"
            chmod +x "$script"
        fi
        echo "✅ $script"
    fi
done

# 7. 生成项目结构报告
echo "📊 生成项目结构报告..."
REPORT_FILE="project-structure-report.txt"

{
    echo "项目结构报告 - $(date)"
    echo "========================="
    echo ""
    echo "项目统计:"
    echo "- Python文件: $(find . -name "*.py" -not -path "./*/node_modules/*" | wc -l)"
    echo "- TypeScript文件: $(find . -name "*.ts" -o -name "*.tsx" -not -path "./*/node_modules/*" | wc -l)"
    echo "- JavaScript文件: $(find . -name "*.js" -o -name "*.jsx" -not -path "./*/node_modules/*" | wc -l)"
    echo "- 配置文件: $(find . -name "*.json" -o -name "*.yml" -o -name "*.yaml" -not -path "./*/node_modules/*" | wc -l)"
    echo ""
    echo "目录结构:"
    tree -I 'node_modules|__pycache__|*.pyc|.git' -L 3 . 2>/dev/null || {
        find . -type d -not -path "./*/node_modules/*" -not -path "./.git/*" | head -20
    }
} > "$REPORT_FILE"

echo "✅ 项目结构报告已生成: $REPORT_FILE"

# 8. 最终状态检查
echo "🎯 最终验证..."
if [ -f "docker-compose.production.yml" ] && [ -f "backend/main.py" ] && [ -f "frontend/package.json" ]; then
    echo "✅ 项目结构完整，适合克隆部署"
    echo "🚀 可以执行部署操作"
    exit 0
else
    echo "❌ 项目结构不完整，请检查缺失文件"
    exit 1
fi
