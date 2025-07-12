#!/bin/bash
# 脚本文件清理 - 保留核心脚本，清理重复和临时脚本

set -e

echo "🧹 脚本文件清理分析..."

cd /workspaces/legezhixiao

# 定义要保留的核心脚本
CORE_SCRIPTS=(
    # Backend启动脚本
    "backend/start.sh"
    "backend/start-fixed.sh"
    
    # 核心部署脚本  
    "scripts/setup-docker-mirrors.sh"
    "scripts/fix-docker-network.sh"
    "scripts/cleanup-project.sh"
    "scripts/deployment-ready-check.sh"
    "scripts/validate-project.sh"
    
    # 清理脚本
    "scripts/auto-cleanup.sh"
    "scripts/cleanup-files.sh"
)

# 定义要清理的临时/重复脚本
TEMP_SCRIPTS=(
    # 根目录临时脚本
    "health-check.sh"
    "mongodb-diagnose.sh" 
    "quick-deploy.sh"
    "quick-start.sh"
    "start.sh"
    "test-docker-compose.sh"
    "test-nginx.sh"
    "test-ports.sh"
    
    # 重复的backend启动脚本
    "backend/start-ultimate.sh"
    
    # scripts目录下的重复/临时脚本
    "scripts/check-backend-health.sh"
    "scripts/check_deployment.sh"
    "scripts/check_local.sh"
    "scripts/ci-container-diagnostics.sh"
    "scripts/clean-mongodb-volume.sh"
    "scripts/config-consistency-check.sh"
    "scripts/configure-docker-mirrors.sh"
    "scripts/deploy-fix.sh"
    "scripts/deploy-with-token.sh"
    "scripts/deploy.sh"
    "scripts/deployment-monitor.sh"
    "scripts/deployment-status.sh"
    "scripts/detailed-config-comparison.sh"
    "scripts/detect-docker-network.sh"
    "scripts/detect-network.sh"
    "scripts/direct-deploy.sh"
    "scripts/docker-logs-fix-verification.sh"
    "scripts/env-config-check.sh"
    "scripts/fix-summary-report.sh"
    "scripts/fix-summary.sh"
    "scripts/github-deploy.sh"
    "scripts/install-docker.sh"
    "scripts/local-ssh-install.sh"
    "scripts/mongodb-backend-fix-diagnosis.sh"
    "scripts/mongodb-health-check.sh"
    "scripts/monitor-deployment.sh"
    "scripts/one-click-install.sh"
    "scripts/pre-deploy-check.sh"
    "scripts/production-diagnostics.sh"
    "scripts/quick-deploy-diagnosis.sh"
    "scripts/quick-install-with-key.sh"
    "scripts/setup-github-actions.sh"
    "scripts/simple-network-check.sh"
    "scripts/ssh-install-docker.sh"
    "scripts/ssh-key-config-check.sh"
    "scripts/ssh-key-fix-summary.sh"
    "scripts/test-github-token.sh"
    "scripts/test-network-local.sh"
    "scripts/test-network.sh"
    "scripts/test_github_token.sh"
    "scripts/verify-fixes.sh"
    "scripts/workflow-cleanup-report.sh"
)

echo "📊 脚本清理前统计:"
BEFORE_SCRIPTS=$(find . -type f -name "*.sh" -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)
echo "- 脚本文件总数: $BEFORE_SCRIPTS"

echo ""
echo "✅ 保留的核心脚本:"
for script in "${CORE_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  📝 $script"
    fi
done

echo ""
echo "🗑️  准备清理的脚本:"
CLEANUP_COUNT=0
for script in "${TEMP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ❌ $script"
        CLEANUP_COUNT=$((CLEANUP_COUNT + 1))
    fi
done

echo ""
echo "⚠️  即将清理 $CLEANUP_COUNT 个脚本文件"
echo "🔧 开始清理..."

# 执行清理
for script in "${TEMP_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        echo "  ✅ 已删除: $script"
    fi
done

echo ""
echo "📊 脚本清理后统计:"
AFTER_SCRIPTS=$(find . -type f -name "*.sh" -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | wc -l)
echo "- 脚本文件总数: $AFTER_SCRIPTS"
echo "- 清理脚本数: $CLEANUP_COUNT"
echo "- 减少脚本: $((BEFORE_SCRIPTS - AFTER_SCRIPTS))"

echo ""
echo "📂 剩余脚本文件:"
find . -type f -name "*.sh" -not -path "./*/node_modules/*" -not -path "./.git/*" -not -path "./.venv/*" | sort

echo ""
echo "🎉 脚本清理完成!"
echo "✨ 保留了核心部署和管理脚本"
