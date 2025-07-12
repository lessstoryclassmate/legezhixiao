#!/bin/bash
# 自动文件清理脚本 - 直接清理临时文件

set -e

echo "🧹 自动清理临时文件..."

PROJECT_ROOT="/workspaces/legezhixiao"
cd "$PROJECT_ROOT"

# 定义临时文件列表
TEMP_FILES=(
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
    "backend-diagnose.sh"
    "check-ports.sh"
    "check_env_consistency.py"
    "project-structure-report.txt"
)

echo "📊 清理前统计:"
BEFORE_COUNT=$(find . -type f -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)
echo "- 总文件数: $BEFORE_COUNT"

CLEANED_COUNT=0
echo "🗑️  正在清理临时文件:"
for file in "${TEMP_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✅ 已删除: $file"
        CLEANED_COUNT=$((CLEANED_COUNT + 1))
    fi
done

# 清理空目录
find . -type d -empty -not -path "./.git/*" -not -path "./*/node_modules/*" -exec rmdir {} \; 2>/dev/null || true

echo ""
echo "📊 清理后统计:"
AFTER_COUNT=$(find . -type f -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)
echo "- 总文件数: $AFTER_COUNT"
echo "- 清理文件数: $CLEANED_COUNT"
echo "- 减少文件: $((BEFORE_COUNT - AFTER_COUNT))"

echo ""
echo "🎉 文件清理完成!"
echo "✨ 项目结构已优化"
