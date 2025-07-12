#!/bin/bash
# 文件清理脚本 - 清理临时和冗余文件
# 保留核心项目文件，清理开发过程中的临时文件

set -e

echo "🧹 开始文件清理分析..."

PROJECT_ROOT="/workspaces/legezhixiao"
cd "$PROJECT_ROOT"

# 定义可以清理的临时文件模式
TEMP_FILES_TO_CLEAN=(
    # 临时状态报告文件
    "CI_FIX_COMPLETE.md"
    "DEPLOYMENT_FIX_COMPLETE.md" 
    "DEPLOYMENT_STATUS.md"
    "DEPLOY_ACTION_LIST.md"
    "DEPLOY_CLOUD_UPDATE.md"
    "DEPLOY_NOW.md"
    "DEPLOY_WORKFLOWS_EXPLANATION.md"
    "ENVIRONMENT_VARIABLES_CHECK.md"
    "ENV_CONSISTENCY_REPORT.md"
    "ENV_VARIABLES_CHECK_RESULT.md"
    "ESLINT_FIX_COMPLETE.md"
    "FINAL_ENV_VALIDATION.md"
    "NGINX_TEST_REPORT.md"
    "PORT_8000_ANALYSIS.md"
    "PORT_CONFIG_REPORT.md"
    "PROJECT_STATUS_SUMMARY.md"
    "PUSH_COMPLETE.md"
    "VSCODE_STYLE_IMPLEMENTATION_COMPLETE.md"
    
    # 临时脚本文件
    "backend-diagnose.sh"
    "check-ports.sh"
    "check_env_consistency.py"
    
    # 临时配置文件
    "project-structure-report.txt"
)

# 定义要保留的核心文件
CORE_FILES=(
    "README.md"
    ".gitignore"
    "docker-compose.production.yml"
    "docker-compose.yml"
    ".env.example"
    ".env.template"
)

echo "📊 清理前文件统计:"
echo "- 总文件数: $(find . -type f -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)"
echo "- Markdown文件: $(find . -type f -name "*.md" -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)"

# 备份重要文件列表
echo "📋 准备清理的临时文件:"
CLEANED_COUNT=0
for file in "${TEMP_FILES_TO_CLEAN[@]}"; do
    if [ -f "$file" ]; then
        echo "  🗑️  $file"
        ((CLEANED_COUNT++))
    fi
done

echo ""
echo "⚠️  即将清理 $CLEANED_COUNT 个临时文件"
echo "💾 核心文件将被保留："
for file in "${CORE_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    fi
done

echo ""
read -p "🤔 确认清理这些临时文件吗? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "🧹 开始清理..."
    
    # 清理临时文件
    for file in "${TEMP_FILES_TO_CLEAN[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "  ✅ 已删除: $file"
        fi
    done
    
    # 清理空目录
    echo "📁 清理空目录..."
    find . -type d -empty -not -path "./.git/*" -not -path "./*/node_modules/*" -exec rmdir {} \; 2>/dev/null || true
    
    echo ""
    echo "📊 清理后文件统计:"
    echo "- 总文件数: $(find . -type f -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)"
    echo "- Markdown文件: $(find . -type f -name "*.md" -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)"
    
    echo ""
    echo "🎉 文件清理完成!"
    echo "✨ 项目结构更加简洁"
    
else
    echo "❌ 已取消清理操作"
fi

# 显示清理后的项目结构
echo ""
echo "📂 当前项目结构概览:"
tree -I 'node_modules|__pycache__|*.pyc|.git|.venv' -L 2 . 2>/dev/null || {
    find . -maxdepth 2 -type d -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | sort
}
